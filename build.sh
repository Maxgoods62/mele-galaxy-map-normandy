#!/usr/bin/env bash
# Build Galaxy Map Normandy from this repo's sources and the player's own game files, then put the M3 mod folder in
# dist/Galaxy Map Normandy (moddesc.ini at its root). Install that folder with ME3Tweaks Mod Manager, game closed.
#   ./build.sh            build everything
# Runs in WSL. The tools are Windows programs: lectool and mele-mcp are built from the toolkit (MELE_TOOLKIT) into
# build/tools, vgmstream decodes the LE3 travel sound. Settings come from the environment or from build.env (not in
# git, see build.env.example). Nothing is written outside build/ and dist/; the game files are only read.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$HERE/build.env" ]]; then . "$HERE/build.env"; fi

TOOLKIT="${MELE_TOOLKIT:-$HERE/../../mele-maxgoods-toolkit}"
DOTNET="${MELE_DOTNET:-dotnet.exe}"
VGMSTREAM="${MELE_VGMSTREAM:-vgmstream-cli}"
LE_DIR="${MELE_LE_DIR:?set MELE_LE_DIR to the Legendary Edition folder, as a Windows path}"
LE1="$LE_DIR\\Game\\ME1\\BioGame\\CookedPCConsole"
LE2="$LE_DIR\\Game\\ME2\\BioGame\\CookedPCConsole"
LE3="$LE_DIR\\Game\\ME3\\BioGame\\CookedPCConsole"
BUILD="$HERE/build"
DIST="$HERE/dist/Galaxy Map Normandy"
COOKED="$DIST/DLC_MOD_GalaxyMapNormandy/CookedPCConsole"

# The three LE3 sources of Play_gui_galaxy_travel_start, in SFXGame.pcc's Wwise_Generic_Galaxy_Map bank: the whoosh,
# then the two layers of the engine loop (docs/ASSETS.md).
BANK_UINDEX=53327
WHOOSH=256246750
LOOP_A=191335730
LOOP_B=634254545
# The SR-1 static mesh in BIOA_ICE20_11_LAY.pcc (ice20_normandy).
SR1_UINDEX=31
# LE2's PC button in its Startup_INT.pcc, and ffmpeg curves of its brightness for the colours of LE1's buttons: the blue
# of the galaxy map's Back button, and the art over the brown panel a button shows under the pointer (docs/ASSETS.md).
BUTTON_ART=GUI_SF_PC_SharedAssets.PC_SharedAssets_I3
BUTTON_BLUE="r='0/0.05 0.65/0.18 0.8/0.52':g='0/0.15 0.65/0.58 0.8/0.78':b='0/0.19 0.65/0.75 0.8/0.88'"
BUTTON_BROWN="r='0/0.3 0.65/0.4 0.74/0.52 0.8/1':g='0/0.18 0.65/0.26 0.74/0.36 0.8/0.86':b='0/0.08 0.65/0.1 0.74/0.14 0.8/0.34'"

win() { wslpath -w "$1"; }
die() { echo "build.sh: $*" >&2; exit 1; }

for t in python3 ffmpeg git; do command -v "$t" >/dev/null || die "$t not found"; done
command -v "$DOTNET" >/dev/null || die "$DOTNET not found: set MELE_DOTNET to the Windows dotnet.exe (.NET SDK 10.0.402 or later, as the toolkit's global.json asks)"
command -v "$VGMSTREAM" >/dev/null || die "$VGMSTREAM not found: set MELE_VGMSTREAM (Legendary Explorer ships exec/vgmstream/vgmstream.exe)"
[[ -f "$TOOLKIT/tools/lectool/lectool.csproj" ]] || die "no toolkit at $TOOLKIT: set MELE_TOOLKIT to a mele-maxgoods-toolkit checkout"
[[ -f "$TOOLKIT/tools/mele-mcp/external/LegendaryExplorer/LegendaryExplorer/LegendaryExplorerCore/LegendaryExplorerCore.csproj" ]] \
    || die "the toolkit's LEC submodule is missing: git -C '$TOOLKIT' submodule update --init"

mkdir -p "$BUILD/tools" "$BUILD/sound" "$BUILD/button"

# Tools: rebuilt when the toolkit's commit or working tree changed since the last build.
stamp="$(git -C "$TOOLKIT" rev-parse HEAD) $({ git -C "$TOOLKIT" status --porcelain; git -C "$TOOLKIT" diff HEAD --submodule=diff; } | md5sum | cut -c1-8)"
build_tool() {    # build_tool <name> <project dir> <csproj> <output file>
    local out="$BUILD/tools/$1"
    if [[ -f "$out/$4" && -f "$out.stamp" && "$(cat "$out.stamp")" == "$stamp" ]]; then return; fi
    echo "== building $1"
    rm -rf "$out" "$out.stamp"
    (cd "$2" && "$DOTNET" build "$3" -c Release -nologo -v q -o "$(win "$out")" | tr -d '\r' | grep -E ' error ' | sort -u) || true
    [[ -f "$out/$4" ]] || die "$1 did not build"
    chmod +x "$out/$4"    # a file Windows writes on the WSL disk has no exec bit
    echo "$stamp" > "$out.stamp"
}
build_tool lectool "$TOOLKIT/tools/lectool" lectool.csproj lectool.exe
build_tool mele-mcp "$TOOLKIT/tools/mele-mcp" src/MeleMcp/MeleMcp.csproj MeleMcp.dll
LECTOOL="$BUILD/tools/lectool/lectool.exe"

# lectool <command> <args>: its output lands in $OUT; LEC's own log (stderr) is shown only on a failure.
OUT="$BUILD/lectool.out"
lectool() {
    if ! MELE_LE_DIR="$LE_DIR" WSLENV="MELE_LE_DIR:LECGAME:WEMDIR:WEMIDS${WSLENV:+:$WSLENV}" "$LECTOOL" "$@" \
            > "$OUT.raw" 2> "$BUILD/lectool.err"; then
        tr -d '\r' < "$OUT.raw"; tr -d '\r' < "$BUILD/lectool.err" | tail -20 >&2
        die "lectool $1 failed"
    fi
    tr -d '\r' < "$OUT.raw" > "$OUT"
}

# mcp <tool> <json>: one call of the mele-mcp built above.
mcp() {
    MELE_DOTNET="$DOTNET" MELE_DLL="$(win "$BUILD/tools/mele-mcp/MeleMcp.dll")" MELE_LE_DIR="$LE_DIR" \
        python3 -I "$TOOLKIT/tools/mele-mcp/scripts/mcp_call.py" "$@"
}
json() { python3 -I -c 'import json, sys; it = iter(sys.argv[1:]); print(json.dumps(dict(zip(it, it))))' "$@"; }

# 1. Startup_MOD_GalaxyMapNormandy.pcc: the classes, loaded at startup through AutoLoad.ini.
echo "== classes"
lectool compileclass "$(win "$BUILD/Startup_MOD_GalaxyMapNormandy.pcc")" GalaxyMapNormandy \
    "$(win "$HERE/src/GalaxyMapNormandySettings.uc")" "$(win "$HERE/src/GalaxyMapNormandyShipLight.uc")" \
    "$(win "$HERE/src/GalaxyMapNormandyDirector.uc")"
grep -E '^log:|\sClass\s' "$OUT" || true

# 2. ModSettings_Submenus_GalaxyMapNormandy.pcc: the settings pages in LE1CP's Mod Settings Menu, which loads them from
# this file by path when the player opens them. Their base class is LE1CP's ModSettingsSubmenu: the file carries a copy,
# as other mods' pages do, decompiled from the player's LE1CP so that its layout matches. The copy, and the copy of
# GalaxyMapNormandySettings, are ForcedExports: the game uses the class already in memory.
echo "== menu"
MSM_PCC="$LE_DIR\\Game\\ME1\\BioGame\\DLC\\DLC_MOD_LE1CP\\CookedPCConsole\\ModSettingsMenu.pcc"
mcp export_decompile "$(json package "$MSM_PCC" export ModSettingsSubmenu)" > "$BUILD/ModSettingsSubmenu.raw" \
    || { cat "$BUILD/ModSettingsSubmenu.raw" >&2; die "could not read ModSettingsSubmenu from LE1CP's ModSettingsMenu.pcc"; }
head -1 "$BUILD/ModSettingsSubmenu.raw" | grep -q ' Class ModSettingsSubmenu$' \
    || { head -5 "$BUILD/ModSettingsSubmenu.raw" >&2; die "LE1CP's ModSettingsMenu.pcc has no class ModSettingsSubmenu"; }
tail -n +2 "$BUILD/ModSettingsSubmenu.raw" > "$BUILD/ModSettingsSubmenu.uc"
lectool compileclass "$(win "$BUILD/ModSettings_Submenus_GalaxyMapNormandy.pcc")" GalaxyMapNormandyMenu \
    "$(win "$HERE/src/ModSettingsSubmenu_GalaxyMapNormandy.uc")" "$(win "$HERE/src/ModSettingsSubmenu_GalaxyMapNormandyStep.uc")" \
    --pkg=ModSettingsMenu "$(win "$BUILD/ModSettingsSubmenu.uc")" \
    --pkg=GalaxyMapNormandy "$(win "$HERE/src/GalaxyMapNormandySettings.uc")" \
    --unforce=GalaxyMapNormandyMenu --no-referencer
grep -E '^log:|\sClass\s' "$OUT" || true

# 3. DLC_MOD_GalaxyMapNormandy_GlobalTlk*.pcc: the menu's words, a package per file name the game looks for. Each text
# language has its own src/tlk/<language>.tsv, and every one must have the ids of INT.tsv. The file without a suffix is
# English. The game's FE, GE, IE, RA and PLPC show the text of FR, DE, IT, RU and PL: copies, as in LE1CP.
echo "== strings"
TLK="$BUILD/tlk"
rm -rf "$TLK"
mkdir -p "$TLK"
tlk_file() { echo "$TLK/DLC_MOD_GalaxyMapNormandy_GlobalTlk$1.pcc"; }
tlk() {    # tlk <file suffix> <language>
    lectool tlkpackage "$(win "$(tlk_file "$1")")" "$(win "$HERE/src/tlk/$2.tsv")" --ids-from "$(win "$HERE/src/tlk/INT.tsv")"
    # lectool exits 0 on a command it does not know.
    grep -F 'strings' "$OUT" || die "lectool wrote no $2 strings: the toolkit needs tlkpackage"
}
tlk "" INT
for lang in FR DE IT ES PL RU JA; do tlk "_$lang" "$lang"; done
cp "$(tlk_file _FR)" "$(tlk_file _FE)"
cp "$(tlk_file _DE)" "$(tlk_file _GE)"
cp "$(tlk_file _IT)" "$(tlk_file _IE)"
cp "$(tlk_file _RU)" "$(tlk_file _RA)"
cp "$(tlk_file _PL)" "$(tlk_file _PLPC)"

# 4. GalaxyMapNormandy_NOR10.pcc: an empty level with one director actor, sideloaded with the Normandy by LE1CP.
echo "== level"
rm -f "$BUILD/GalaxyMapNormandy_NOR10.pcc"
mcp level_new "$(json path "$(win "$BUILD/GalaxyMapNormandy_NOR10.pcc")")" \
    > "$BUILD/level_new.json" || { cat "$BUILD/level_new.json" >&2; die "level_new failed"; }
lectool addactor "$(win "$BUILD/GalaxyMapNormandy_NOR10.pcc")" GalaxyMapNormandy GalaxyMapNormandyDirector
cat "$OUT"

# 5. The travel sound, from the player's LE3: extract the three WEMs, decode them, mix them (docs/ASSETS.md).
echo "== sound"
S="$BUILD/sound"
rm -rf "$S"
mkdir -p "$S"
LECGAME=LE3 WEMDIR="$(win "$S")" WEMIDS="$WHOOSH,$LOOP_A,$LOOP_B" lectool wwise "$LE3\\SFXGame.pcc" "$BANK_UINDEX"
grep -E '^bank .*Wwise_Generic_Galaxy_Map' "$OUT" \
    || die "SFXGame.pcc export $BANK_UINDEX is not the Wwise_Generic_Galaxy_Map bank"
for id in "$WHOOSH" "$LOOP_A" "$LOOP_B"; do
    [[ -f "$S/$id.wem" ]] || die "WEM $id was not in the bank"
    if [[ "$VGMSTREAM" == *.exe ]]; then
        "$VGMSTREAM" -i -o "$(win "$S/$id.wav")" "$(win "$S/$id.wem")" > /dev/null
    else
        "$VGMSTREAM" -i -o "$S/$id.wav" "$S/$id.wem" > /dev/null
    fi
done
ff() { ffmpeg -v error -y "$@"; }
# Whoosh: layer gain 0.8, then mono (its donor wave is mono).
ff -i "$S/$WHOOSH.wav" -af "volume=0.8" -c:a pcm_s16le "$S/whoosh_stereo.wav"
ff -i "$S/whoosh_stereo.wav" -ac 1 -c:a pcm_s16le "$S/travel_whoosh.wav"
# Loop: LOOP_A cut at its last sound; LOOP_B without its encoder padding, stretched to the same length, on both
# sides; mixed at 0.8 each.
ff -i "$S/$LOOP_A.wav" -af "atrim=end_sample=111744" "$S/loop_a.wav"
ff -i "$S/$LOOP_B.wav" -af "atrim=end_sample=97088,atempo=0.86885,pan=stereo|c0=c0|c1=c0,atrim=end_sample=111744,apad=whole_len=111744" "$S/loop_b.wav"
ff -i "$S/loop_a.wav" -i "$S/loop_b.wav" \
    -filter_complex "[0][1]amix=inputs=2:normalize=0,volume=0.8,atrim=end_sample=111744" -c:a pcm_s16le "$S/loop_mix.wav"
# Seamless loop: the last 20 ms are crossfaded into the first 20 ms and cut off.
python3 -I - "$S/loop_mix.wav" "$S/travel_loop.wav" <<'EOF'
import struct, sys, wave
src, dst = sys.argv[1:3]
with wave.open(src) as w:
    n, ch, rate = w.getnframes(), w.getnchannels(), w.getframerate()
    d = struct.unpack('<%dh' % (n * ch), w.readframes(n))
xf = int(rate * 0.02)
m = n - xf
out = []
for c in range(ch):
    a = list(d[c::ch])
    head = a[:m]
    for i in range(xf):
        t = i / xf
        head[i] = int(round(a[i] * t + a[m + i] * (1 - t)))
    out.append(head)
with wave.open(dst, 'wb') as w:
    w.setnchannels(ch); w.setsampwidth(2); w.setframerate(rate)
    w.writeframes(struct.pack('<%dh' % (m * ch), *[s for frame in zip(*out) for s in frame]))
EOF
for f in travel_whoosh travel_loop; do ff -i "$S/$f.wav" -c:a libvorbis -q:a 8 "$S/$f.ogg"; done
frames() { python3 -I -c 'import sys, wave; print(wave.open(sys.argv[1]).getnframes())' "$1"; }
# The flight sound variant the director plays (its FlightSound; 0 is the original sound above), from the same three
# WEMs (docs/ASSETS.md): its waves and manifest.tsv (cue name, wave, channels, frames, cue volume, loop or once).
FLIGHT_SOUND="$(sed -n 's/^ *FlightSound = \([0-9][0-9]*\)$/\1/p' "$HERE/src/GalaxyMapNormandyDirector.uc")"
[[ "$FLIGHT_SOUND" =~ ^[0-9]+$ ]] || die "no FlightSound in the director's defaultproperties"
V="$S/variants"
python3 -I "$HERE/src/sound/flight_sounds.py" "$S" "$V" --variants "$FLIGHT_SOUND"
while IFS=$'\t' read -r name file ch n vol mode; do
    ff -i "$V/$file" -c:a libvorbis -q:a 6 "$V/$name.ogg" < /dev/null
done < "$V/manifest.tsv"

# 6. GalaxyMapNormandy_SFX.pcc: the cues (on cloned LE1 donor cues), the SR-1 mesh and the button's two textures.
echo "== sfx"
SFX="$(win "$BUILD/GalaxyMapNormandy_SFX.pcc")"
rm -f "$BUILD/GalaxyMapNormandy_SFX.pcc"
lectool buildsound "$LE1\\snd_gui.pcc" c_snd_guiswish "$(win "$S/travel_whoosh.ogg")" "$(frames "$S/travel_whoosh.wav")" 1 44100 \
    "$SFX" c_travel_whoosh travel_whoosh 0.5
grep -E '^wave' "$OUT" || true
# The variant's cues, all stereo, on the same template as c_travel_loop: each wave gets its cue's name before the colon
# of its <bank>:<title> name (--unique-wave), so each cue has a wave of its own. c_travel_loop comes last and keeps the
# template's wave name, as in v0.24.
while IFS=$'\t' read -r name file ch n vol mode; do
    lectool buildsound "$LE1\\snd_gui.pcc" c_galaxymap_enter "$(win "$V/$name.ogg")" "$n" "$ch" 44100 \
        "$SFX" "$name" "${name#c_}" "$vol" $([[ "$mode" == loop ]] && echo --loop) --unique-wave < /dev/null
    # lectool exits 0 on an option it does not know: without --unique-wave, every cue here would play one shared wave.
    grep -E '^wave' "$OUT" | grep -F "$name:" \
        || die "lectool gave $name no wave of its own: the toolkit needs buildsound --unique-wave"
done < "$V/manifest.tsv"
lectool buildsound "$LE1\\snd_gui.pcc" c_galaxymap_enter "$(win "$S/travel_loop.ogg")" "$(frames "$S/travel_loop.wav")" 2 44100 \
    "$SFX" c_travel_loop travel_loop 0.5 --loop
grep -E '^wave' "$OUT" || true
lectool portmesh "$LE1\\BIOA_ICE20_11_LAY.pcc" "$SR1_UINDEX" "$SFX" SR1_Normandy
if grep -E 'BROKEN' "$OUT"; then die "broken material in the SR-1 port"; fi
# The button: LE2 shows it mirrored, with the cut corner at the bottom left (docs/ASSETS.md).
B="$BUILD/button"
rm -f "$B"/*
LECGAME=LE2 lectool texpng "$LE2\\Startup_INT.pcc" "$BUTTON_ART" "$(win "$B/le2.png")"
GREY=colorchannelmixer=.299:.587:.114:0:.299:.587:.114:0:.299:.587:.114:0
# Under the pointer: a solid panel, lighter toward its ends, with gold along the cut corner and in the opposite corner.
# These are the colours seen on screen. Canvas raises a texture's colours to 1/2.2 unless it is sRGB, so the last step
# undoes that, which leaves colours so dark that DXT5 bands them: this image is stored uncompressed.
ENDS='abs(2*X/W-1)'
GOLD='gte(Y,43)*(between(X-4-1.264*(Y-43),0,64)+gte(X+1.264*(Y-43)-1017,0))'
DOWN='(Y-43)/80'
PANEL="geq=r='84+43*$ENDS':g='50+40*$ENDS':b='24+13*$ENDS':a='min(255,alpha(X,Y)*12)'"
CORNERS="geq=r='if($GOLD,240-29*$DOWN,r(X,Y))':g='if($GOLD,210-56*$DOWN,g(X,Y))':b='if($GOLD,100-57*$DOWN,b(X,Y))':a='alpha(X,Y)'"
UNDO="lutrgb=r='255*pow(val/255,2.2)':g='255*pow(val/255,2.2)':b='255*pow(val/255,2.2)'"
button() {    # button <new name> <filters> [addtexture option]
    ff -i "$B/le2.png" -filter_complex "[0:v]hflip,format=rgba,$2" -pix_fmt rgba "$B/$1.png"
    lectool addtexture "$SFX" "$1" "$(win "$B/$1.png")" ${3:-}
    # lectool exits 0 on a command it does not know.
    grep -F "$1" "$OUT" || die "lectool added no $1: the toolkit needs addtexture"
}
button EnterButton_Normal "$GREY,curves=interp=pchip:$BUTTON_BLUE"
button EnterButton_Hover "split[p][a];[p]$PANEL[p];[a]$GREY,curves=interp=pchip:$BUTTON_BROWN,lutrgb=a='min(255,val*2.5)'[a];[p][a]overlay=format=rgb,format=rgba,$CORNERS,$UNDO" --argb

# 7. The M3 mod folder.
echo "== dist"
rm -rf "$DIST"
mkdir -p "$DIST"
cp -r "$HERE/mod/." "$DIST/"
cp "$BUILD"/{Startup_MOD_GalaxyMapNormandy,ModSettings_Submenus_GalaxyMapNormandy,GalaxyMapNormandy_NOR10,GalaxyMapNormandy_SFX}.pcc "$TLK"/*.pcc "$COOKED/"
echo "built $(win "$DIST") (modver $(sed -n 's/^modver=//p' "$HERE/mod/moddesc.ini" | tr -d '\r'))"
ls -l "$COOKED" | tail -n +2
