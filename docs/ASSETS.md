# Game assets

The mod uses BioWare content: the SR-1 Normandy model and the ME3 galaxy map travel sound. None of it is in this
repository. `.gitignore` keeps out every package and sound file (`*.pcc`, `*.wav`, `*.ogg`, `*.wem`, `*.7z`) and the
`build/` and `dist/` folders. `build.sh` reads the content from your own Legendary Edition install and builds it into
`GalaxyMapNormandy_SFX.pcc`.

## Files the build reads

LE1 files are in `<LE folder>\Game\ME1\BioGame\CookedPCConsole`, LE3 files in
`<LE folder>\Game\ME3\BioGame\CookedPCConsole`.

| Game | File | What the build takes | Used for |
|---|---|---|---|
| LE3 | `SFXGame.pcc` | export 53327, the Wwise bank `Wwise_Generic_Galaxy_Map`: its embedded sounds 256246750, 191335730 and 634254545 | the whoosh (256246750) and the two layers of the engine loop (191335730, 634254545) |
| LE1 | `snd_gui.pcc` | the cues `c_snd_guiswish` (one mono wave) and `c_galaxymap_enter` (one stereo wave) | templates for the two new cues |
| LE1 | `BIOA_ICE20_11_LAY.pcc` | export 31, the docked Normandy's static mesh `ice20_normandy`, with its materials and textures | the ship, as `SR1_Normandy` |

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

## Where the content ends up

`GalaxyMapNormandy_SFX.pcc` holds the two cues and the mesh. It is built on your machine, lands in
`dist/Galaxy Map Normandy/DLC_MOD_GalaxyMapNormandy/CookedPCConsole/` and is for your own use with your own copy of
the game ([NOTICE](../NOTICE)). The other two packages hold only this repository's compiled classes and an otherwise
empty level with one actor.
