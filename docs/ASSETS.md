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
| LE3 | `SFXGame.pcc` | export 53327, the Wwise bank `Wwise_Generic_Galaxy_Map`: its embedded sounds 256246750, 191335730 and 634254545 | the whoosh (256246750) and the two layers of the engine loop (191335730, 634254545) |
| LE2 | `Startup_INT.pcc` | the texture `GUI_SF_PC_SharedAssets.PC_SharedAssets_I3` | the Enter Orbit button, recoloured as `EnterButton_Normal` and `EnterButton_Hover` |
| LE1 | `snd_gui.pcc` | the cues `c_snd_guiswish` (one mono wave) and `c_galaxymap_enter` (one stereo wave) | templates for the two new cues |
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

## The ship: `SR1_Normandy`

`lectool portmesh` copies export 31 of `BIOA_ICE20_11_LAY.pcc` into `GalaxyMapNormandy_SFX.pcc` at the top level,
named `SR1_Normandy`, with its materials, their textures and the materials' local shaders if the source package has
any. The build stops if LegendaryExplorerCore reports a broken material. The ship keeps its own materials; the director
lights it with its own sky light at run time.

## The button: `EnterButton_Normal`, `EnterButton_Hover`

1. `lectool texpng` writes the LE2 texture as PNG (1024x128). The panel, its bevel, the cut corner and the hexagons are
   all in the image.
2. ffmpeg mirrors it (`hflip`). The texture has the cut corner at the bottom right; LE2 shows it mirrored.
3. ffmpeg makes two colours of it: `colorchannelmixer` turns the copper to grey, and `curves` maps that grey to the
   colours of LE1's Back button in `GUI_SF_GalaxyMap.pcc`. Blue runs through `#2e95c0` to `#84c6e1`; the amber it takes
   under the pointer runs through `#e6941a` to `#fedc56`. The alpha stays LE2's.
4. `lectool addtexture` puts each PNG into `GalaxyMapNormandy_SFX.pcc` as a new DXT5 UI texture, with one mip and stored
   in the package, as LE2's are.

The button's words are in the director: LE2's strings 260735 (Enter Orbit), 136218 (Enter System) and 136916 (Scan).
The label is drawn with the game's own `EngineFonts.LargeFont`.

## Where the content ends up

`GalaxyMapNormandy_SFX.pcc` holds the two cues, the mesh and the button's textures. It is built on your machine, lands in
`dist/Galaxy Map Normandy/DLC_MOD_GalaxyMapNormandy/CookedPCConsole/` and is for your own use with your own copy of
the game ([NOTICE](../NOTICE)). The other two packages hold only this repository's compiled classes and an otherwise
empty level with one actor.
