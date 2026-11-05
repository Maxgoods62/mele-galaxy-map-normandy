# Game assets

The mod uses BioWare content: the SR-1 Normandy model, the ME2 PC button art and the ME3 galaxy map travel sound. None
of it is in this repository. `.gitignore` keeps out every package and sound file (`*.pcc`, `*.wav`, `*.ogg`, `*.wem`, `*.7z`) and the
`build/` and `dist/` folders. `build.sh` reads the content from your own Legendary Edition install and builds it into
`GalaxyMapNormandy_SFX.pcc`.

## Files the build reads

LE1 files are in `<LE folder>\Game\ME1\BioGame\CookedPCConsole`, LE2 files in
`<LE folder>\Game\ME2\BioGame\CookedPCConsole`, LE3 files in `<LE folder>\Game\ME3\BioGame\CookedPCConsole`.

| Game | File | What the build takes | Used for |
|---|---|---|---|
| LE3 | `SFXGame.pcc` | export 53327, the Wwise bank `Wwise_Generic_Galaxy_Map`: its embedded sounds 256246750, 191335730 and 634254545 | the whoosh (256246750) and the two layers of the engine loop (191335730, 634254545), in the original sound and in the five variants |
| LE2 | `Startup_INT.pcc` | the texture `GUI_SF_PC_SharedAssets.PC_SharedAssets_I3` | the Enter Orbit button, recoloured as `EnterButton_Normal` and `EnterButton_Hover` |
| LE1 | `snd_gui.pcc` | the cues `c_snd_guiswish` (one mono wave) and `c_galaxymap_enter` (one stereo wave) | templates for the new cues (`c_galaxymap_enter` for every flight sound variant) |
| LE1 | `BIOA_ICE20_11_LAY.pcc` | export 31, the docked Normandy's static mesh `ice20_normandy`, with its materials and textures | the ship, as `SR1_Normandy` |
| LE1 Community Patch | `ModSettingsMenu.pcc`, in `<LE folder>\Game\ME1\BioGame\DLC\DLC_MOD_LE1CP\CookedPCConsole` | the class `ModSettingsSubmenu`, decompiled to UnrealScript | compiled into `ModSettings_Submenus_GalaxyMapNormandy.pcc` as the base class of the settings pages; the game uses the Community Patch's own class in memory |

The three LE3 sounds are what ME3's `Play_gui_galaxy_travel_start` event plays.

## The whoosh: `c_travel_whoosh`

1. vgmstream decodes `256246750.wem` to WAV (`-i`: no loop).
2. ffmpeg applies a gain of 0.8 (`volume=0.8`) and writes 16-bit PCM.
3. ffmpeg mixes it down to mono (`-ac 1`), because the template wave is mono.
4. ffmpeg encodes it as Ogg Vorbis at quality 8 (`libvorbis -q:a 8`): `travel_whoosh.ogg`.
5. `lectool buildsound` clones `c_snd_guiswish` as `c_travel_whoosh`, puts the Ogg file into the cloned wave (1
   channel, 44,100 Hz), sets the cue's volume to 0.5 and removes the template's pitch setting (2 in `c_snd_guiswish`).

## The engine loop: `c_travel_loop`

1. vgmstream decodes `191335730.wem` and `634254545.wem` to WAV.
2. Layer A, `191335730`: cut at sample 111,744, where its last sound ends (2.534 s at 44.1 kHz).
3. Layer B, `634254545`: cut at sample 97,088 to drop the encoder padding at its end, stretched with
   `atempo=0.86885` to the length of layer A, copied from its one channel to both sides, then cut or padded to 111,744
   samples.
4. ffmpeg mixes the two layers without normalising (`amix=inputs=2:normalize=0`), applies a gain of 0.8 and cuts the
   mix to 111,744 samples.
5. A short Python step makes the seam loop cleanly: the last 20 ms (882 samples) are crossfaded linearly into the first
   20 ms, then cut off. The loop is 110,862 samples long (2.514 s), in stereo.
6. ffmpeg encodes it as Ogg Vorbis at quality 8: `travel_loop.ogg`.
7. `lectool buildsound` clones `c_galaxymap_enter` as `c_travel_loop`, puts the Ogg file into the cloned wave (2
   channels, 44,100 Hz), sets the cue's volume to 0.5, removes any pitch setting of the template and adds a looping
   node (`--loop`).

In the game the looping node alone plays the wave only once, so the director restarts the loop itself, with a
crossfade (`bLoopRestart` in [tuning.md](tuning.md)).

## Flight sound variants

The menu's Flight sound page offers the original sound above (`c_travel_whoosh`, `c_travel_loop`) and five variants,
1 to 5, built from the same three decoded LE3 sounds by
[`src/sound/flight_sounds.py`](../src/sound/flight_sounds.py) (Python standard library and ffmpeg).

ME2 and ME3 play these sounds through Wwise, which pitches, filters and loops each one live. The bank's settings for
`Play_gui_galaxy_travel_start`, read from LE3's `SFXGame.pcc` and LE2's `SFXGame.pcc` (bank `Wwise_Generic_Galaxy_Map`):

- the whoosh, pitched -278 cents, then +331 cents at cluster level and -199 cents in system view;
- the engine, 191335730, looping, at -3 dB (LE2: -7 dB). The ship's thrust moves it from -869 to -328 cents and from
  -3.4 to +0.1 dB;
- the drive, 634254545, twice: at -341 cents at cluster level and -2400 cents (two octaves down) in system view;
- a low-pass filter (Wwise value 38) over the whoosh and the engine;
- in LE2 only, a short reverb on the galaxy map's bus (0.5 s). LE3's is at -35 dB, so it is not heard.

LE1's sound engine can do none of this live but pitch and volume. So `flight_sounds.py` bakes the pitch, the filter
and the reverb into the waves, and the director does the rest (`SetupFlightSound` in [tuning.md](tuning.md)). Pitch in
cents changes speed too, as in Wwise. The Wwise low-pass value is turned into a one-pole filter frequency by an
approximation (`WwiseLpfHz`): Wwise's own table is not public.

| Variant | Name in the menu | What it is |
|---|---|---|
| 1 | Mass Effect 3 | ME3's settings above |
| 2 | Mass Effect 2 | the same, with the engine at -7 dB and ME2's 0.5 s reverb |
| 3 | Deep rumble | engine -600 cents, the drive at -2400, -1200 and -341 cents together, 0.9 s reverb |
| 4 | Soft hum | quieter (-15 LUFS), more filtered, engine -700 cents, the drive at -2400 and -1200 cents, 1.2 s reverb |
| 5 | Bright thrusters | less filtered, engine -150 cents, the drive at -341 and 0 cents (-1200 and -341 in system view), wide in stereo |

For each variant the script writes:

- `c_flight<n>_engine` and `c_flight<n>_drive`: two loops, 16 s each, whose last 0.3 s are crossfaded into their
  start. The director plays both while the ship flies.
- `c_flight<n>_drive_system` (variants 1, 2 and 5): the drive for system view.
- `c_flight<n>_whoosh`: the start of a flight, played once.
- `c_flight<n>_preview`: 3 to 4 s of one flight (whoosh, engine, fade-out) for the menu to play when the player picks
  the sound. `c_flight0_preview` is the same for the original sound.

Every loop pair is set to the loudness of the original loop at full speed (-11.6 LUFS, Soft hum -15 LUFS). No wave
peaks above -1 dBFS: the gain this holds back goes into the cue's volume instead (0.5, as the original cues, up to
1.0). The script writes `manifest.tsv` (cue, wave, channels, frames, cue volume, loop or once), and `build.sh` encodes
each wave as Ogg Vorbis at quality 6 and runs `lectool buildsound` with `c_galaxymap_enter` as the template, adding the
looping node to the loops. An LE1 wave is named `<bank>:<title>`, and the game plays the sound whose title, in the
wave's ISACT content index, is the part after the colon, so that part must stay the template's (`c_galaxymap_enter`).
`--unique-wave` puts the cue's name before the colon (`c_flight1_engine:c_galaxymap_enter`), so each cue gets its own
wave: a second cue built from the template under the template's wave name would get the first one's wave back.
`c_travel_loop` is built last and keeps `snd_gui:c_galaxymap_enter`. The waves are stereo throughout.

To listen outside the game: `python3 -I src/sound/flight_sounds.py build/sound <folder> --previews <folder>` writes
`flight0.wav` to `flight5.wav`, each a flight at cluster level then one in system view, at the game's levels.

## The ship: `SR1_Normandy`

`lectool portmesh` copies export 31 of `BIOA_ICE20_11_LAY.pcc` into `GalaxyMapNormandy_SFX.pcc` at the top level,
named `SR1_Normandy`, with its materials, their textures and the materials' local shaders if the source package has
any. The build stops if LegendaryExplorerCore reports a broken material. The ship keeps its own materials; the director
lights it with its own sky light at run time.

## The button: `EnterButton_Normal`, `EnterButton_Hover`

1. `lectool texpng` writes the LE2 texture as PNG (1024x128). The panel, its bevel, the cut corner and the hexagons are
   all in the image.
2. ffmpeg mirrors it (`hflip`). The texture has the cut corner at the bottom right; LE2 shows it mirrored.
3. ffmpeg makes two images of it. In both, `colorchannelmixer` turns the copper to grey and `curves` maps that grey to a
   colour. For `EnterButton_Normal` that colour is the blue of LE1's Back button in `GUI_SF_GalaxyMap.pcc`, from `#2e95c0`
   to `#84c6e1`, with LE2's alpha. `EnterButton_Hover` is a solid panel in the colours of LE1's button under the pointer:
   brown from `#543218` in the middle to `#7f5a25` at the ends, LE2's art over it, and gold corners. Canvas raises the
   colours of a texture that is not sRGB to 1/2.2, so its last step undoes that.
4. `lectool addtexture` puts each PNG into `GalaxyMapNormandy_SFX.pcc` as a new UI texture, with one mip and stored in the
   package, as LE2's are. `EnterButton_Normal` is DXT5, as LE2's is. `EnterButton_Hover` is uncompressed: its colours are
   so dark before Canvas lifts them that DXT5 bands them.

The button's words are in the director: LE2's strings 260735 (Enter Orbit), 136218 (Enter System) and 136916 (Scan).
The label is drawn with the game's own `EngineFonts.LargeFont`.

## Where the content ends up

`GalaxyMapNormandy_SFX.pcc` holds the cues, the mesh and the button's textures. It is built on your machine, lands in
`dist/Galaxy Map Normandy/DLC_MOD_GalaxyMapNormandy/CookedPCConsole/` and is for your own use with your own copy of
the game ([NOTICE](../NOTICE)). The other packages hold this repository's compiled classes and strings, a copy of the
LE1 Community Patch's `ModSettingsSubmenu` class, and an otherwise empty level with one actor.
