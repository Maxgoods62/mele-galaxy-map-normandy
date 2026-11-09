# Game assets

Galaxy Map Normandy uses content from LE1 and LE3, words from LE2, and one class of the LE1 Community Patch. None of it
is in this repository, apart from Mass Effect 2's words for the Enter Orbit button in `src/tlk`. `.gitignore` keeps out
game files, sound files, archives and programs (`*.pcc`, `*.tfc`, `*.bik`, `*.isb`, `*.afc`, `*.tlk`, `*.sav`, `*.wav`,
`*.ogg`, `*.wem`, `*.dll`, `*.asi`, `*.exe`, `*.7z`, `*.zip`) and the `build/` and `dist/` folders. Only the files of
`mod/` that git sees go into the mod folder, so a stray `.pcc` there never ships.

[build.sh](../build.sh) reads the content from your installed game and builds it into the mod's packages. It only reads
the game files, and in this repo it writes only into `build/` and `dist/`. [building.md](building.md) explains how to
run the build.

## Files the build reads

`MELE_LE_DIR` tells the build where the Legendary Edition is ([building.md](building.md)). The game files sit in these
folders:

| Game | Folder |
|---|---|
| LE1 | `<Legendary Edition folder>\Game\ME1\BioGame\CookedPCConsole` |
| LE3 | `<Legendary Edition folder>\Game\ME3\BioGame\CookedPCConsole` |
| LE1 Community Patch | `<Legendary Edition folder>\Game\ME1\BioGame\DLC\DLC_MOD_LE1CP` |

| Game | File | What the build takes | Used for |
|---|---|---|---|
| LE3 | `SFXGame.pcc` | three sounds in export 53327 | the flight sound |
| LE1 | `snd_gui.pcc` | two sound cues | templates for the mod's cues |
| LE1 | `BIOA_ICE20_11_LAY.pcc` | export 31, a static mesh | the ship |
| LE3 | `BioA_Nor_203aGalaxyMap.pcc` | export 757, a particle system | the engine trail |
| LE3 | `SFXGame.pcc`, `Startup.pcc` | one material and four textures that the trail uses | the engine trail |
| LE1 Community Patch | `CookedPCConsole\ModSettingsMenu.pcc` | the class `ModSettingsSubmenu` | base class of the settings pages |
| LE1 Community Patch | `_metacmm.txt` | line 2, the patch version | `dist/build.stamp` |

Export 53327 of LE3's `SFXGame.pcc` is the sound bank `Wwise_Generic_Galaxy_Map`. Wwise is the sound engine of LE2 and
LE3. The build takes the sounds 256246750, 191335730 and 634254545 from this bank. They are the three sounds of
`Play_gui_galaxy_travel_start`, the event that starts the galaxy map travel sound in Mass Effect 3.

The two LE1 cues are `c_snd_guiswish` and `c_galaxymap_enter`. Export 31 of `BIOA_ICE20_11_LAY.pcc` is the static mesh
`ice20_normandy`, the SR-1 Normandy. Export 757 of LE3's `BioA_Nor_203aGalaxyMap.pcc` is the particle system
`BioVFX_Env_Galaxymap.Particles.Normandy_Engine_Trails`, the engine trail of the Normandy on the Mass Effect 3 galaxy
map.

From `_metacmm.txt`, the build only copies the version line into `dist/build.stamp`, the record of what a build was
made from.

## LE1 sound cues used as templates

LE1 plays sounds through ISACT, its own sound engine. A sound the game plays by name is a `SoundCue`. The cue leads to
one or more `SoundNodeWave` exports, which hold the audio. The build copies two of LE1's own cues from `snd_gui.pcc`
and puts new audio into them.

| Template | Its wave | Template for |
|---|---|---|
| `c_snd_guiswish` | `snd_gui:c_snd_guiswish`, mono | `c_travel_whoosh` |
| `c_galaxymap_enter` | `snd_gui:c_galaxymap_enter`, stereo | `c_travel_loop` and the variant cues |

`lectool buildsound` makes each new cue. lectool is the toolkit's command-line program for game packages
([its README](https://github.com/Maxgoods62/mele-maxgoods-toolkit/blob/main/tools/lectool/README.md)). For each cue it:

1. copies the template cue to the top level of `GalaxyMapNormandy_SFX.pcc`, under the new name;
2. sets the cue's volume and removes the template's pitch setting (`c_snd_guiswish` has a pitch of 2);
3. with `--loop`, puts a looping node (`SoundNodeLooping`) above the template's first node;
4. puts the Ogg Vorbis file into each wave under the cue, with its frame count, channel count and sample rate.

The sample rate is always 44,100 Hz. Only the audio and its sample details are new. The rest of each wave's ISACT data
comes from the template.

An LE1 wave is named `<bank>:<title>`. The game plays the sound in the wave's ISACT content index whose title is the
part after the colon. So that part must stay the template's. With `--unique-wave`, buildsound puts the new cue's name
before the colon, as in `c_flight5_engine:c_galaxymap_enter`. Each cue then has a wave of its own. Without it, a second
cue from the same template would get the first cue's wave back.

`c_travel_loop` is built last, so it keeps the template's wave name `snd_gui:c_galaxymap_enter`. The build stops if a
variant cue has no wave of its own: that means the toolkit is too old for `--unique-wave`.

## The travel sound from LE3

The original flight sound has two cues: a whoosh when the ship sets off, and an engine loop while it flies. Both come
from the three LE3 sounds. The build first gets them out of the game:

1. `lectool wwise` reads the bank with `LECGAME=LE3` and writes the three sounds as `.wem` files into `build/sound`. The
   build stops if export 53327 is not the bank `Wwise_Generic_Galaxy_Map`, or if a sound is missing from it.
2. vgmstream (`vgmstream-cli`, or the program `MELE_VGMSTREAM` names) decodes each `.wem` file to WAV. Its `-i` option
   ignores loop points, so each sound plays through once.

In the current game files, the decoded sounds are 16-bit at 44,100 Hz:

| Sound | Role | Channels | Frames | Length |
|---|---|---|---|---|
| 256246750 | whoosh | 2 | 88,882 | 2.02 s |
| 191335730 | engine loop | 2 | 111,862 | 2.54 s |
| 634254545 | drive loop | 1 | 98,026 | 2.22 s |

### The whoosh: `c_travel_whoosh`

1. ffmpeg applies a gain of 0.8 (`volume=0.8`).
2. ffmpeg mixes it down to mono (`-ac 1`), because the template's wave is mono.
3. ffmpeg encodes it as Ogg Vorbis at quality 8: `travel_whoosh.ogg`.
4. `lectool buildsound` makes `c_travel_whoosh` from `c_snd_guiswish`, with 1 channel and a cue volume of 0.5.

### The engine loop: `c_travel_loop`

The loop has two layers: layer A is the engine loop (191335730), and layer B is the drive loop (634254545).

1. Layer A is cut at frame 111,744 (2.534 s). Its last sound ends there, and only silence follows.
2. Layer B is cut at frame 97,088. This drops the encoder padding at its end, about 21 ms of silence.
3. ffmpeg stretches layer B with `atempo=0.86885` to the length of layer A. Its one channel goes to both sides, and it
   is cut or padded to exactly 111,744 frames.
4. ffmpeg mixes the two layers without normalising (`amix=inputs=2:normalize=0`), applies a gain of 0.8 and cuts the
   mix to 111,744 frames.
5. A short Python step makes the seam loop cleanly. It crossfades the last 20 ms (882 frames) into the first 20 ms, then
   cuts them off. The loop is now 110,862 frames long (2.514 s), in stereo.
6. ffmpeg encodes it as Ogg Vorbis at quality 8: `travel_loop.ogg`.
7. `lectool buildsound` makes `c_travel_loop` from `c_galaxymap_enter`, with 2 channels, a cue volume of 0.5 and a
   looping node.

## Flight sound variants

[src/sound/flight_sounds.py](../src/sound/flight_sounds.py) defines five more flight sounds, numbered 1 to 5. Each one
is made from the same three decoded LE3 sounds. The director's `FlightSound` value picks the sound the game plays. It is
5, Bright thrusters. The value 0 stands for the original sound above.

build.sh reads `FlightSound` from the director's `defaultproperties` and builds only that variant. It always builds the
original sound too, as the fallback. [tuning.md](tuning.md) explains how to pick another variant.

| Variant | Name | Loudness | Reverb |
|---|---|---|---|
| 1 | Mass Effect 3 | -11.6 LUFS | none |
| 2 | Mass Effect 2 | -11.6 LUFS | 0.5 s, ratio 2, 0 dB |
| 3 | Deep rumble | -11.6 LUFS | 0.9 s, ratio 2.5, -6 dB |
| 4 | Soft hum | -15 LUFS | 1.2 s, ratio 3, -4 dB |
| 5 | Bright thrusters | -11.6 LUFS | 0.35 s, ratio 1.5, -10 dB |

LUFS measures how loud a sound seems. The loudness column is the target for the engine and drive loops together, at
full speed. The original engine loop has -11.6 LUFS at full speed. The reverb column gives the reverb time, the ratio of
the low reverb time to the high one, and the level of the reverb against the dry sound.

Variants 1 and 2 follow the Wwise settings that Mass Effect 3 and Mass Effect 2 give this sound. The comments in
flight_sounds.py list them. Variant 2 differs in two ways: its engine is 4 dB quieter, and it has the reverb of Mass
Effect 2's galaxy map. Mass Effect 3 has that reverb at -35 dB, so variant 1 leaves it out. Variants 3, 4 and 5 are
the mod's own mixes.

### Why the effects are in the waves

Mass Effect 2 and 3 pitch, filter and loop these sounds live, in Wwise. LE1's sound engine cannot apply those
settings. So flight_sounds.py bakes each sound's pitch, low-pass filter and reverb into the waves. The director adds the
part that changes during a flight: pitch and volume curves on the ship's speed.

Pitch is in cents, and 1,200 cents make an octave. The script changes pitch by resampling, so a lower sound also plays
slower, as in Wwise. Wwise gives a low-pass filter as a value from 0 to 100. The script turns it into a one-pole
low-pass filter at `20000 * 10^(-3 * value / 100)` Hz. This formula (`WwiseLpfHz`) is an approximation, since Wwise's
own table is not public.

### The cues of a variant

| Cue | Plays | Loop or once |
|---|---|---|
| `c_flight<n>_whoosh` | when the ship sets off | once |
| `c_flight<n>_engine` | while the ship flies | loop |
| `c_flight<n>_drive` | while the ship flies | loop |
| `c_flight<n>_drive_system` | in system view, in place of the drive | loop |

Only variants 1, 2 and 5 have a `drive_system` cue. Each cue is the sum of one or more parts. A part is one of the three
LE3 sounds with its own pitch, low-pass filter, gain and right-side delay:

| Variant | Cue | Source | Pitch (cents) | Low-pass | Gain (dB) | Right delay (ms) |
|---|---|---|---|---|---|---|
| 1 | whoosh | whoosh | -278 | 38 (1,450 Hz) | 0 | |
| 1 | engine | engine | -328 | 38 (1,450 Hz) | -2.89 | |
| 1 | drive | drive | -341 | none | -1.34 | 0 |
| 1 | drive_system | drive | -2400 | none | -1.34 | 0 |
| 2 | whoosh | whoosh | -278 | 38 (1,450 Hz) | 0 | |
| 2 | engine | engine | -328 | 38 (1,450 Hz) | -6.89 | |
| 2 | drive | drive | -341 | none | -1.34 | 0 |
| 2 | drive_system | drive | -2400 | none | -1.34 | 0 |
| 3 | whoosh | whoosh | -477 | 45 (893 Hz) | 0 | |
| 3 | engine | engine | -600 | 48 (726 Hz) | -4 | |
| 3 | drive | drive | -2400 | none | 0 | 0 |
| 3 | drive | drive | -1200 | 10 (10,000 Hz) | -6 | 9 |
| 3 | drive | drive | -341 | 20 (5,020 Hz) | -5 | 14 |
| 4 | whoosh | whoosh | -477 | 60 (317 Hz) | -9 | |
| 4 | engine | engine | -700 | 62 (276 Hz) | -8 | |
| 4 | drive | drive | -2400 | 15 (7,100 Hz) | 0 | 0 |
| 4 | drive | drive | -1200 | 30 (2,520 Hz) | -7 | 11 |
| 5 | whoosh | whoosh | +53 | 12 (8,730 Hz) | +1 | |
| 5 | engine | engine | -150 | 18 (5,770 Hz) | -2 | |
| 5 | drive | drive | -341 | 10 (10,000 Hz) | -2 | 12 |
| 5 | drive | drive | 0 | 25 (3,560 Hz) | -10 | 7 |
| 5 | drive_system | drive | -1200 | 10 (10,000 Hz) | -2 | 12 |
| 5 | drive_system | drive | -341 | 25 (3,560 Hz) | -9 | 7 |

The low-pass column gives the Wwise value, then the filter frequency it turns into. The whoosh and the engine are
stereo sounds. The drive is mono, so the script makes it stereo, and its right side can lag behind the left by a few
milliseconds. That small delay makes the drive sound wider.

### How a loop is built

The engine, drive and drive_system cues are loops. For each one, the script:

1. resamples each part by its pitch;
2. drops the run of exact zeros at the end of the part (the drive loop ends with a short silence);
3. crossfades the last 10 ms of the part into its first 10 ms, so it repeats without a click;
4. repeats the part to the length the cue needs, with the right-side delay for the drive;
5. applies the low-pass filter, if the part has one, then the gain;
6. adds the parts of the cue together;
7. adds the variant's reverb, if it has one;
8. crossfades the last 0.3 s into the start with an equal-power crossfade.

The cue is 16.3 s long before step 8, which leaves a wave of exactly 16 s (705,600 frames). With a reverb, the cue is
also built longer at its start, by 1.2 times the reverb time. The script cuts that part off after step 7, so the reverb
is already full when the wave starts.

### How a whoosh is built

The whoosh plays once. Each part gets its pitch, low-pass filter and gain, and keeps its own length after pitching. With
a reverb, the script first adds silence at the end, 1.2 times the reverb time, so the reverb can ring out. The whoosh of
a variant is stereo, while the original whoosh is mono.

### The reverb

The script makes its own reverb. Its impulse response is noise that fades to -60 dB in the reverb time below about
1 kHz. Above that, the noise fades faster, by the variant's ratio. Each side gets its own noise, from a fixed seed, so
the noise is the same in every build. ffmpeg's `afir` filter applies it. The script then measures the result and sets
the reverb to its level against the dry sound.

### Loudness and cue volume

The script mixes the engine and drive cues, as they play together at full speed. It measures that mix with ffmpeg's
`ebur128` filter and finds the gain that brings it to the variant's target. Every cue of the variant gets this gain.

No wave may peak above -1 dBFS, which is 1 dB below the loudest a wave can be. When the gain would go past that, the
wave gets less gain, and the cue's volume makes up the rest. Cue volumes start at 0.5, like the original cues, and stop
at 1.0. The script prints the gain and the cue volumes, and a line for any cue that falls short of the target.

### Waves and manifest.tsv

flight_sounds.py writes one WAV per cue into its output folder, named after the cue: 16-bit, stereo, 44,100 Hz. In a
build, that folder is `build/sound/variants`. The script also writes `manifest.tsv` there, one line per cue, with six
columns split by tabs:

| Column | Holds |
|---|---|
| 1 | the cue name, such as `c_flight5_engine` |
| 2 | the wave file |
| 3 | the channels, always 2 |
| 4 | the frames |
| 5 | the cue volume |
| 6 | `loop` or `once` |

build.sh reads `manifest.tsv`. For each line it encodes the WAV as Ogg Vorbis at quality 6. Then it runs
`lectool buildsound` with `c_galaxymap_enter` as the template. It passes the frames, the channels, 44,100 Hz and the cue
volume, plus `--loop` for a loop and always `--unique-wave`.

### What the game plays

The director loads the cues of its `FlightSound` from `GalaxyMapNormandy_SFX.pcc`. It plays the whoosh when the ship
sets off, and the engine and drive loops while the ship flies. In system view it plays the `drive_system` cue in place
of the drive, when the variant has one. Variants 3 and 4 have none, so their drive plays at both map levels.

If the whoosh, engine or drive cue of the variant does not load, the director falls back to the original sound:
`c_travel_whoosh` and `c_travel_loop`.

The director sets the pitch and volume live. In LE1 a loop wave plays only once, even with the looping node, so the
director restarts each loop before its wave ends ([tuning.md](tuning.md#sound)).

### Listen outside the game

After a build, `build/sound` holds the decoded LE3 sounds and the original sound's waves. From the repo folder, this
command builds all five variants and writes a preview of each:

```bash
python3 -I src/sound/flight_sounds.py build/sound build/flight-waves --previews build/flight-previews
```

The previews are `flight0.wav` to `flight5.wav`, and `flight0.wav` is the original sound. Each one is a flight at
cluster level, then a flight in system view. A flight is the whoosh, 6 s of the loops at full speed, then a 0.5 s fade.
The cue volumes and the director's live whoosh settings are applied. The script needs ffmpeg and nothing but Python's
standard library.

## The SR-1 model: `SR1_Normandy`

`lectool portmesh` copies export 31 of LE1's `BIOA_ICE20_11_LAY.pcc` into `GalaxyMapNormandy_SFX.pcc`. The mesh lands at
the top level of the package as `SR1_Normandy`. Its materials and their textures come with it. The materials' local
shaders come too, if the source file has any. The build stops if Legendary Explorer Core, the library lectool is built
on, reports a broken material.

In a build from the current game files, most of the ship's textures name one of LE1's texture cache files, such as
`Textures1` or `CharTextures3`. LE1 keeps most texture images in these TFC files, and the ship's full-size images stay
there. The star cube map that comes with the materials, `StarsCube01_Tex`, is copied whole: six uncompressed faces of
1024x1024, 4 MB each. The first material draws it only on the window strips. `build.sh` then shrinks it with
`lectool cubeshrink` to 256x256 DXT1 faces with mips, 44 KB each: the size its LOD group
(`TEXTUREGROUP_Environment_64`, at most 256) asks for. This takes the package from about 28 MB to 3 MB once loaded.

The ship's materials and textures keep the game's own paths, such as `BIOG_NOR.Base.VEH_NOR_Diff_Stack`: after
`portfx`, `build.sh` runs `lectool forcepackage` on `BIOG_NOR`, which marks them as forced exports, the way the game's
levels store them. When the game already has its own copy in memory, it uses that one. At a dock (Citadel, Feros,
Noveria), opening the map loads the departure scene, which brings the game's copy first. A Normandy retexture that
works by M3 texture override (a `.m3to` file, such as Alliance Vehicle Consistency's blue decals) matches textures by
their full path, so it reaches this ship too. Tested in LE1 with Alliance Vehicle Consistency 1.1, Normandy module, at
Noveria's dock and in space. The shrunk cube map moves out of `BIOG_NOR` to the top level of the package, under the
file's name, so it never stands in for the game's own cube. A level that loads the ship's materials while the map is
open would get ours, with the smaller cube; no level did that in testing. A retexture that replaces level files instead
of using an override reaches the ship only at a dock.

The ship keeps its own materials. At run time the director lights it with its own sky light, and raises the nozzle
glow on its own copy of the first material ([how-it-works.md](how-it-works.md#the-engines)).

## The engine trail: `EngineTrail`

`lectool portfx` copies export 757 of LE3's `BioA_Nor_203aGalaxyMap.pcc` into `GalaxyMapNormandy_SFX.pcc` as
`EngineTrail`, with the materials, the beam mesh `RectangularLightTapered` and the textures it uses, and their shaders.
The effect has three emitters: a halo, a bright core and the beam.

LE3 loads a few of these from files it always keeps loaded, and LE1 has no such copies: the halo material
`Dot_Math_Glow_Cheap` and three textures in `SFXGame.pcc`, and one texture in `Startup.pcc`. portfx copies them from
those LE3 files first, under the same names, so the effect uses the copies. The build stops if lectool reports a broken
material or anything LE1 can't load.

Mass Effect 2's galaxy map has the same kind of trail. Legendary Explorer Core converts shaders only between LE1 and
LE3, so the build takes LE3's copy.

## The Enter Orbit button

The button is not in the mod's packages. It is LE1's own Back button from the galaxy map's Scaleform movie
(`GUI_SF_GalaxyMap.GalaxyMap`, the same in the LE1 Community Patch). Each time the map opens, the director asks that
movie, in memory, for a copy of the button's symbol, `backAnim`. The copy has LE1's art, hover look and font. No file is
read or changed for it, by the build or by the game.

Its words are Mass Effect 2's own, read once from LE2's talk files (strings 136218 Enter System, 260735 Enter Orbit and
136916 Scan) and kept in `src/tlk` as strings 74220025 to 74220027, in each language. The build puts them in the mod's
talk table packages with its other strings. They are game text, so they are not under the GPL either.

## The Community Patch settings page class

The mod's settings pages sit in the Community Patch's Mod Settings Menu. Each page class extends the patch's class
`ModSettingsSubmenu`. So the package with the pages carries a copy of that class, as other mods' settings pages do.

1. build.sh asks mele-mcp, the toolkit's server of package tools, to decompile `ModSettingsSubmenu` from the
   installed patch's `ModSettingsMenu.pcc`. The result is UnrealScript source, in the engine's script language. The
   build stops if that file has no such class.
2. `lectool compileclass` compiles it into `ModSettings_Submenus_GalaxyMapNormandy.pcc`, under a package named
   `ModSettingsMenu`. The same file gets the mod's two page classes, under `GalaxyMapNormandyMenu`. It also gets a copy
   of `GalaxyMapNormandySettings`, under `GalaxyMapNormandy`.
3. The two copies are forced exports: each stands for the class of the same path, so the game uses the class already in
   memory. For `ModSettingsSubmenu` that is the patch's own class. For `GalaxyMapNormandySettings` it is the mod's
   own, from `Startup_MOD_GalaxyMapNormandy.pcc`.

The page classes are not forced (`--unforce=GalaxyMapNormandyMenu`), so the Mod Settings Menu loads them from this
file. The copy comes from your installed patch, so its layout matches the patch you run.

## Where each piece ends up

`GalaxyMapNormandy_SFX.pcc` is the only package with content from the games.
`ModSettings_Submenus_GalaxyMapNormandy.pcc` holds the copy of the Community Patch class `ModSettingsSubmenu`. The
other packages hold only the mod's own work, and [how-it-works.md](how-it-works.md#what-loads-and-when) lists them all.

`GalaxyMapNormandy_SFX.pcc` holds:

- `c_travel_whoosh` and `c_travel_loop`, the original sound;
- the cues of the variant that `FlightSound` picks, such as `c_flight5_whoosh`, `c_flight5_engine`, `c_flight5_drive`
  and `c_flight5_drive_system`;
- `SR1_Normandy`, with its materials and textures;
- `EngineTrail`, with its materials, the beam mesh and textures.

A build puts all the packages in `dist/Galaxy Map Normandy/DLC_MOD_GalaxyMapNormandy/CookedPCConsole/`. The files made
on the way stay in `build/sound`. The archive on Nexus Mods holds the same packages, from the
maintainer's build. Either way, the game content in the built packages is for personal use with a legitimate copy of
the game.

The game content in these packages is not under the GPL: see [NOTICE](../NOTICE).
