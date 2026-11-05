# Builds the waves of the flight sound variants (docs/ASSETS.md, "Flight sound variants") from the three LE3 travel
# sounds that build.sh decoded: the whoosh 256246750, the engine loop 191335730 and the drive loop 634254545.
#   python3 -I flight_sounds.py <folder with the decoded WAVs> <output folder> [--variants 5] [--previews <folder>]
# Writes one 16-bit WAV per cue into the output folder and manifest.tsv (cue name, file, channels, frames, cue
# volume, loop or once), which build.sh reads to make the cues. --variants takes a comma-separated list of variant
# numbers (default: all five); build.sh passes the director's FlightSound. --previews also writes, per variant, a WAV
# of one flight at cluster level and one in system view, to listen to outside the game (flight0.wav is the original
# sound).
#
# ME2 and ME3 play these sounds through Wwise (the event Play_gui_galaxy_travel_start), which pitches, filters and
# loops each one live. LE1's ISACT cannot, so the pitch and the low-pass filter are baked into the waves here, and the
# director (GalaxyMapNormandyDirector.SetupFlightSound) does the live part: a pitch and volume curve on ship speed, and
# a choice of wave by map level. Pitch is in cents and changes speed too, as in Wwise. LPF is Wwise's 0-100 low-pass
# value, mapped to a one-pole filter (WwiseLpfHz: an approximation; Wwise's own table is not public).
# Needs ffmpeg on PATH; nothing but the standard library.
import math
import os
import struct
import subprocess
import sys
import wave

RATE = 44100
WHOOSH, ENGINE, DRIVE = '256246750', '191335730', '634254545'
LOOP_SECONDS = 16.0     # length of each loop wave; the director restarts it before the end
SEAM_SECONDS = 0.3      # the end of a loop wave is crossfaded into its start
CLIP_SEAM_SECONDS = 0.01  # each source loop is made seamless before it is repeated
LOOP_LUFS = -11.6       # loudness of the engine loop of the original sound (v0.24), at full speed
SOFT_LUFS = -15.0
CUE_VOLUME = 0.5        # the original sound's cue volume

# A component: (source, pitch in cents, Wwise LPF value, gain in dB, Haas delay of the right channel in ms).
# A cue is the sum of its components, then the variant's reverb if it has one: (reverb time in s, ratio of the low
# reverb time to the high one, wet level in dB against the dry sound). The variant numbers match the director's
# FlightSound and SetupFlightSound.
VARIANTS = {
    # 1: Mass Effect 3's own mix. Whoosh and engine sit under a mixer with LPF 38. The engine is pitched -328 cents at
    # full thrust (the director lowers it to -869 cents at rest); the drive is pitched -404 + 63 cents (fuel full) at
    # cluster level and -2400 cents in system view, where Wwise swaps the two copies with an LPF curve. Gains: the
    # sound's own volume plus its thrust curve at full thrust (engine -3 + 0.11 dB, drive 0 - 1.34 dB).
    1: dict(lufs=LOOP_LUFS,
            whoosh=[(WHOOSH, -278, 38, 0.0, 0)],
            engine=[(ENGINE, -328, 38, -2.89, 0)],
            drive=[(DRIVE, -341, 0, -1.34, 0)],
            drive_system=[(DRIVE, -2400, 0, -1.34, 0)]),
    # 2: Mass Effect 2's mix, the same as ME3's but for the engine's own volume (-7 dB instead of -3).
    # ME2's galaxy map bus also has a Matrix Reverb on it, wet at 0 dB: reverb time 0.5 s, high ratio 2 (ME3's is
    # at -35 dB, so left out of variant 1).
    2: dict(lufs=LOOP_LUFS, reverb=(0.5, 2.0, 0.0),
            whoosh=[(WHOOSH, -278, 38, 0.0, 0)],
            engine=[(ENGINE, -328, 38, -6.89, 0)],
            drive=[(DRIVE, -341, 0, -1.34, 0)],
            drive_system=[(DRIVE, -2400, 0, -1.34, 0)]),
    # 3: Deep rumble: a lower, darker engine, and the drive at three octaves' worth of depth at every level.
    3: dict(lufs=LOOP_LUFS, reverb=(0.9, 2.5, -6.0),
            whoosh=[(WHOOSH, -477, 45, 0.0, 0)],
            engine=[(ENGINE, -600, 48, -4.0, 0)],
            drive=[(DRIVE, -2400, 0, 0.0, 0), (DRIVE, -1200, 10, -6.0, 9), (DRIVE, -341, 20, -5.0, 14)]),
    # 4: Soft hum: quiet and muffled, a faint whoosh, the deep drive in front.
    4: dict(lufs=SOFT_LUFS, reverb=(1.2, 3.0, -4.0),
            whoosh=[(WHOOSH, -477, 60, -9.0, 0)],
            engine=[(ENGINE, -700, 62, -8.0, 0)],
            drive=[(DRIVE, -2400, 15, 0.0, 0), (DRIVE, -1200, 30, -7.0, 11)]),
    # 5: Bright thrusters: less filtering, a higher engine note with a wider sweep, a wide drive.
    5: dict(lufs=LOOP_LUFS, reverb=(0.35, 1.5, -10.0),
            whoosh=[(WHOOSH, 53, 12, 1.0, 0)],
            engine=[(ENGINE, -150, 18, -2.0, 0)],
            drive=[(DRIVE, -341, 10, -2.0, 12), (DRIVE, 0, 25, -10.0, 7)],
            drive_system=[(DRIVE, -1200, 10, -2.0, 12), (DRIVE, -341, 25, -9.0, 7)]),
}

# What the director does live at full speed, for the previews: whoosh pitch and volume per level
# (cluster, system), and the drive cue the system view uses. Mirrors SetupFlightSound.
PREVIEW_WHOOSH = {1: ((1.2109, 0.734), (0.8916, 0.693)), 2: ((1.2109, 0.734), (0.8916, 0.693)),
                  3: ((1.0, 1.0), (1.0, 1.0)), 4: ((1.0, 1.0), (1.0, 1.0)), 5: ((1.0, 1.0), (0.94, 1.0))}


def WwiseLpfHz(value):
    return 20000.0 * math.pow(10.0, -3.0 * value / 100.0)


def ffmpeg(*args):
    subprocess.run(['ffmpeg', '-v', 'error', '-y'] + list(args), check=True)


def read_float(path, channels=2):
    """Any WAV as a list of float samples per channel, decoded by ffmpeg to `channels` channels."""
    out = subprocess.run(['ffmpeg', '-v', 'error', '-i', path, '-f', 'f32le', '-ac', str(channels), '-'],
                         check=True, capture_output=True).stdout
    data = struct.unpack('<%df' % (len(out) // 4), out)
    return [list(data[c::channels]) for c in range(channels)]


def write_float(path, chans):
    n = len(chans[0])
    inter = [chans[c][i] for i in range(n) for c in range(len(chans))]
    raw = struct.pack('<%df' % len(inter), *inter)
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'f32le', '-ar', str(RATE), '-ac', str(len(chans)),
                    '-i', '-', '-c:a', 'pcm_f32le', path], input=raw, check=True)


def write_pcm16(path, chans):
    n = len(chans[0])
    ch = len(chans)
    ints = []
    for i in range(n):
        for c in range(ch):
            v = int(round(chans[c][i] * 32767.0))
            ints.append(32767 if v > 32767 else -32768 if v < -32768 else v)
    with wave.open(path, 'wb') as w:
        w.setnchannels(ch)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(struct.pack('<%dh' % len(ints), *ints))


def lufs(path):
    r = subprocess.run(['ffmpeg', '-hide_banner', '-nostats', '-i', path, '-af', 'ebur128', '-f', 'null', '-'],
                       capture_output=True, text=True)
    tail = r.stderr[r.stderr.rfind('Summary'):]
    for line in tail.splitlines():
        line = line.strip()
        if line.startswith('I:'):
            return float(line.split()[1])
    raise RuntimeError('no loudness for ' + path)


def seamless(chans, xf):
    """The last xf samples crossfaded linearly into the first xf, then cut off: the clip repeats without a click."""
    out = []
    for a in chans:
        m = len(a) - xf
        head = a[:m]
        for i in range(xf):
            t = i / xf
            head[i] = a[i] * t + a[m + i] * (1.0 - t)
        out.append(head)
    return out


def trim_silence(chans):
    """Drop the run of exact zeros at the end (the drive loop has 20 ms of them, which Wwise would not loop)."""
    n = len(chans[0])
    while n > 0 and all(c[n - 1] == 0.0 for c in chans):
        n -= 1
    return [c[:n] for c in chans]


def component(wavdir, tmp, comp, frames, key):
    """One source, pitched, made seamless, repeated to `frames` samples, filtered and gained; stereo."""
    src, cents, lpf, gain, haas_ms = comp
    pitched = os.path.join(tmp, '%s_pitch.wav' % key)
    rate = RATE * math.pow(2.0, cents / 1200.0)
    ffmpeg('-i', os.path.join(wavdir, src + '.wav'), '-af',
           'asetrate=%.6f,aresample=%d:filter_size=64' % (rate, RATE) if cents else 'anull',
           '-c:a', 'pcm_f32le', pitched)
    clip = trim_silence(read_float(pitched, 1 if src == DRIVE else 2))
    clip = seamless(clip, int(RATE * CLIP_SEAM_SECONDS))
    period = len(clip[0])
    reps = frames // period + 2
    tiled = [(c * reps) for c in clip]
    if len(tiled) == 1:
        d = int(RATE * haas_ms / 1000.0)
        left = tiled[0][period:period + frames]
        right = tiled[0][period - d:period - d + frames]
        tiled = [left, right]
    else:
        tiled = [c[period:period + frames] for c in tiled]
    raw = os.path.join(tmp, '%s_tiled.wav' % key)
    write_float(raw, tiled)
    filt = os.path.join(tmp, '%s_filt.wav' % key)
    chain = []
    if lpf > 0:
        chain.append('lowpass=f=%.1f:p=1' % WwiseLpfHz(lpf))
    chain.append('volume=%.3fdB' % gain)
    ffmpeg('-i', raw, '-af', ','.join(chain), '-c:a', 'pcm_f32le', filt)
    return read_float(filt)


def mix(parts):
    out = [list(parts[0][0]), list(parts[0][1])]
    for p in parts[1:]:
        for c in range(2):
            a, b = out[c], p[c]
            out[c] = [x + y for x, y in zip(a, b)]
    return out


def loop_seam(chans, body, xf):
    """`chans` holds body + xf samples: the extra xf are crossfaded (equal power) into the start, so the wave loops."""
    out = []
    for a in chans:
        head = a[:body]
        for i in range(xf):
            t = (i + 0.5) / xf
            head[i] = a[i] * math.sin(t * math.pi / 2) + a[body + i] * math.cos(t * math.pi / 2)
        out.append(head)
    return out


def scale(chans, g):
    return [[x * g for x in c] for c in chans]


def peak(chans):
    return max(max(abs(x) for x in c) for c in chans)


def reverb_ir(seconds, hf_ratio, seed):
    """A stereo impulse response like a feedback delay network's: dense noise that decays to -60 dB in `seconds` below
    about 1 kHz and `hf_ratio` times faster above, different noise on each side."""
    import random
    rnd = random.Random(seed)
    n = int(RATE * seconds * 1.2)
    low_rt, high_rt = seconds, seconds / hf_ratio
    a = math.exp(-2.0 * math.pi * 1000.0 / RATE)
    out = []
    for c in range(2):
        lp = 0.0
        ir = []
        for i in range(n):
            x = rnd.uniform(-1.0, 1.0)
            lp = (1.0 - a) * x + a * lp
            t = i / RATE
            ir.append(lp * math.exp(-6.9078 * t / low_rt) + (x - lp) * math.exp(-6.9078 * t / high_rt))
        for i in range(min(n, int(RATE * 0.002))):
            ir[i] *= i / (RATE * 0.002)
        out.append(ir)
    return out


def rms(chans):
    return math.sqrt(sum(x * x for c in chans for x in c) / max(1, sum(len(c) for c in chans)))


def reverb(tmp, chans, rev, key):
    """The dry sound plus its convolution with reverb_ir, the wet part scaled to `wet` dB against the dry by
    measurement, so the result does not hang on how this ffmpeg's afir scales an impulse response."""
    seconds, hf_ratio, wet_db = rev
    dry = os.path.join(tmp, key + '_dry.wav')
    irp = os.path.join(tmp, key + '_ir.wav')
    wetp = os.path.join(tmp, key + '_wet.wav')
    write_float(dry, chans)
    write_float(irp, reverb_ir(seconds, hf_ratio, 1))
    graph = '[0:a][1:a]afir=dry=1:wet=1:%s:irfmt=input[o]'
    for opt in ('gtype=none', 'irnorm=-1'):
        r = subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', dry, '-i', irp, '-filter_complex', graph % opt,
                            '-map', '[o]', '-c:a', 'pcm_f32le', wetp], capture_output=True)
        if r.returncode == 0:
            break
    else:
        raise RuntimeError('ffmpeg afir failed: ' + r.stderr.decode(errors='replace')[-400:])
    wet = read_float(wetp)
    n = len(chans[0])
    wet = [(c + [0.0] * n)[:n] for c in wet]
    g = rms(chans) / max(rms(wet), 1e-9) * math.pow(10.0, wet_db / 20.0)
    return [[d + w * g for d, w in zip(chans[c], wet[c])] for c in range(2)]


def build_cue(wavdir, tmp, comps, frames, key):
    return mix([component(wavdir, tmp, comp, frames, '%s_%d' % (key, i)) for i, comp in enumerate(comps)])


def main():
    wavdir, outdir = sys.argv[1], sys.argv[2]
    previews = sys.argv[sys.argv.index('--previews') + 1] if '--previews' in sys.argv else None
    wanted = set(VARIANTS)
    if '--variants' in sys.argv:
        wanted = {int(x) for x in sys.argv[sys.argv.index('--variants') + 1].split(',') if x.strip()}
    tmp = os.path.join(outdir, 'tmp')
    os.makedirs(tmp, exist_ok=True)
    body = int(RATE * LOOP_SECONDS)
    xf = int(RATE * SEAM_SECONDS)
    manifest = []
    report = []
    for n, v in sorted(VARIANTS.items()):
        if n not in wanted:
            continue
        cues = {}
        volumes = {}
        rev = v.get('reverb')
        warm = int(RATE * rev[0] * 1.2) if rev else 0
        for part in ('engine', 'drive', 'drive_system'):
            if part in v:
                key = 'v%d_%s' % (n, part)
                chans = build_cue(wavdir, tmp, v[part], warm + body + xf, key)
                if rev:
                    chans = [c[warm:] for c in reverb(tmp, chans, rev, key)]
                cues[part] = loop_seam(chans, body, xf)
        cues['whoosh'] = whoosh(wavdir, tmp, v['whoosh'], 'v%d_whoosh' % n)
        if rev:
            tail = int(RATE * rev[0] * 1.2)
            cues['whoosh'] = reverb(tmp, [c + [0.0] * tail for c in cues['whoosh']], rev, 'v%d_whoosh' % n)
        # Loudness: the engine and the cluster drive together, as they play at full speed, at the variant's target.
        probe = os.path.join(tmp, 'v%d_probe.wav' % n)
        write_float(probe, mix([cues['engine'], cues['drive']]))
        g = math.pow(10.0, (v['lufs'] - lufs(probe)) / 20.0)
        # Each wave peaks at -1 dBFS at most; what that holds back goes into its cue's volume instead (the original
        # sound's cues have 0.5), up to 1.0. So every cue keeps its share of the target loudness.
        limit = math.pow(10.0, -1.0 / 20.0)
        for part, chans in cues.items():
            wave_gain = min(g, limit / peak(chans))
            volume = CUE_VOLUME * g / wave_gain
            if volume > 1.0:
                report.append('v%d %s: %.1f dB short of the loudness target' % (n, part, 20 * math.log10(volume)))
                volume = 1.0
            name = 'c_flight%d_%s' % (n, part)
            path = os.path.join(outdir, name + '.wav')
            write_pcm16(path, scale(chans, wave_gain))
            manifest.append((name, path, 2, len(chans[0]), volume, part != 'whoosh'))
            volumes[part] = volume
        report.append('v%d: gain %+.1f dB; cue volumes %s' % (
            n, 20 * math.log10(g), ', '.join('%s %.2f' % kv for kv in sorted(volumes.items()))))
        if previews:
            write_preview(n, outdir, previews, tmp, volumes)
    if previews:
        write_original_preview(wavdir, previews)
    with open(os.path.join(outdir, 'manifest.tsv'), 'w') as f:
        for name, path, ch, frames, volume, loop in manifest:
            f.write('%s\t%s\t%d\t%d\t%.3f\t%s\n' % (name, os.path.basename(path), ch, frames, volume,
                                                    'loop' if loop else 'once'))
    for line in report:
        print(line)


def whoosh(wavdir, tmp, comps, key):
    """The whoosh is a one-shot: no loop, its own length (the source's, after pitching)."""
    parts = []
    for i, comp in enumerate(comps):
        src, cents, lpf, gain, haas_ms = comp
        out = os.path.join(tmp, '%s_%d.wav' % (key, i))
        chain = []
        if cents:
            chain.append('asetrate=%.6f,aresample=%d:filter_size=64' % (RATE * math.pow(2.0, cents / 1200.0), RATE))
        if lpf > 0:
            chain.append('lowpass=f=%.1f:p=1' % WwiseLpfHz(lpf))
        chain.append('volume=%.3fdB' % gain)
        ffmpeg('-i', os.path.join(wavdir, src + '.wav'), '-af', ','.join(chain), '-c:a', 'pcm_f32le', out)
        parts.append(read_float(out))
    n = max(len(p[0]) for p in parts)
    parts = [[c + [0.0] * (n - len(c)) for c in p] for p in parts]
    return mix(parts)


def write_preview(n, outdir, previews, tmp, volumes):
    """One flight at cluster level, then one in system view: whoosh, 6 s of engine at full speed, 0.5 s fade. The
    levels are the game's: the cue volumes are applied, as the original sound's 0.5 is in flight0.wav."""
    os.makedirs(previews, exist_ok=True)
    def load(part):
        p = os.path.join(outdir, 'c_flight%d_%s.wav' % (n, part))
        return scale(read_float(p), volumes[part]) if os.path.exists(p) else None
    engine, drive, drive_sys = load('engine'), load('drive'), load('drive_system')
    total = [[], []]
    for view in (0, 1):
        pitch, vol = PREVIEW_WHOOSH[n][view]
        wfile = os.path.join(tmp, 'v%d_prev_whoosh%d.wav' % (n, view))
        ffmpeg('-i', os.path.join(outdir, 'c_flight%d_whoosh.wav' % n), '-af',
               'asetrate=%.3f,aresample=%d,volume=%.4f' % (RATE * pitch, RATE, vol * volumes['whoosh']),
               '-c:a', 'pcm_f32le', wfile)
        d = drive_sys if view == 1 and drive_sys else drive
        total = append_flight(total, read_float(wfile), [[e + x for e, x in zip(engine[c], d[c])] for c in range(2)])
    write_pcm16(os.path.join(previews, 'flight%d.wav' % n), total)


def write_original_preview(wavdir, previews):
    """The original sound (v0.24): its mono whoosh and its 2.5 s loop, repeated; the same at both levels."""
    w = read_float(os.path.join(wavdir, 'travel_whoosh.wav'))
    loop = read_float(os.path.join(wavdir, 'travel_loop.wav'))
    loop = [c * 4 for c in loop]
    total = [[], []]
    for view in (0, 1):
        total = append_flight(total, scale(w, CUE_VOLUME), scale(loop, CUE_VOLUME))
    write_pcm16(os.path.join(previews, 'flight0.wav'), total)


def append_flight(total, whoosh_wave, engine):
    flight, fade_in, fade_out = int(RATE * 6.0), int(RATE * 0.15), int(RATE * 0.5)
    seg = [[0.0] * (int(RATE * 0.3) + flight + fade_out + RATE) for _ in range(2)]
    start = int(RATE * 0.3)
    for c in range(2):
        for i in range(flight + fade_out):
            g = min(1.0, i / fade_in) if i < flight else max(0.0, 1.0 - (i - flight) / fade_out)
            seg[c][start + i] = engine[c][i] * g
        for i in range(min(len(whoosh_wave[c]), len(seg[c]) - start)):
            seg[c][start + i] += whoosh_wave[c][i]
    return [total[c] + seg[c] for c in range(2)]


if __name__ == '__main__':
    main()
