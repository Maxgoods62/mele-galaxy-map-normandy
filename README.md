# Galaxy Map Normandy (LE1)

A Mass Effect Legendary Edition mod for ME1. On the galaxy map, a lit SR-1 Normandy flies with the map cursor at
cluster and system level, with the ME3 travel sound (a whoosh, then an engine loop while it flies). The mouse works
as in ME2: an arrow pointer, hold the left button to fly toward it, click to select. The pad keeps LE1's own control.
Requires LE1CP: its Sideloader loads the mod's level with the Normandy. Version: `modver` in `mod/moddesc.ini`.

Design, in-game tests and history: [docs/09](../../docs/09-galaxy-map-normandy.md) (§6.1 delivery, §6.2 mouse).

## Files

| Path | What |
|---|---|
| `src/GalaxyMapNormandyDirector.uc` | The actor that runs every frame while the map is open: ship, sound, mouse control, tuning fields |
| `src/GalaxyMapNormandyShipLight.uc` | The ship's own sky light (lighting channel `Unnamed_6`) |
| `mod/` | The M3 mod folder without its packages: `moddesc.ini`, `AutoLoad.ini`, the Sideloader `.m3cd` |

## Build

```bash
cp build.env.example build.env    # once: your Legendary Edition folder, dotnet.exe, vgmstream
./build.sh
```

`build.sh` runs in WSL and writes the M3 mod folder to `dist/Galaxy Map Normandy/`; install that folder with ME3Tweaks
Mod Manager while the game is closed. It reads your own game files and writes nothing outside `build/` and `dist/`.
It needs:

- a [mele-toolkit](https://github.com/Maxgoods62/mele-toolkit) checkout with its LEC submodule (`MELE_TOOLKIT`, default
  `../../mele-toolkit`); `build.sh` builds lectool and mele-mcp from it into `build/tools`
- the Windows .NET 8 SDK or later (`MELE_DOTNET`), `ffmpeg` and `python3` in WSL
- vgmstream (`MELE_VGMSTREAM`): Legendary Explorer ships it as `exec/vgmstream/vgmstream.exe`
- LE1 and LE3 installed (`MELE_LE_DIR`): the travel sound comes from LE3's `SFXGame.pcc`

## Packages (not in git)

The three packages are build output, and `GalaxyMapNormandy_SFX.pcc` holds BioWare content (the SR-1 mesh, the ME3
travel sound), so none are committed. `build.sh` makes them in this order:

| Package | Steps |
|---|---|
| `Startup_MOD_GalaxyMapNormandy.pcc` | `lectool compileclass` of `src/GalaxyMapNormandyShipLight.uc` and `src/GalaxyMapNormandyDirector.uc` into package `GalaxyMapNormandy` |
| `GalaxyMapNormandy_NOR10.pcc` | mele-mcp `level_new`, then `lectool addactor … GalaxyMapNormandy GalaxyMapNormandyDirector` |
| `GalaxyMapNormandy_SFX.pcc` | `lectool wwise` extracts the three travel sounds from LE3's `Wwise_Generic_Galaxy_Map` bank, vgmstream decodes them, ffmpeg mixes the whoosh and the engine loop; `lectool buildsound` puts them on cues cloned from LE1's `snd_gui.pcc`, and `lectool portmesh` ports the SR-1 from `BIOA_ICE20_11_LAY.pcc` (docs/09 §5.2) |

## Tuning

Every tuning field is a plain property of `GalaxyMapNormandyDirector`; the defaults are at the end of the `.uc`.
MeleBridge's `live_set` changes them in a running game, on this object:
`GalaxyMapNormandy_NOR10.TheWorld.PersistentLevel.GalaxyMapNormandyDirector_0`. The mouse fields are listed in docs/09
§6.2.
