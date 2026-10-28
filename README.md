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

## Packages (not in git)

The three packages are build output, and `GalaxyMapNormandy_SFX.pcc` holds BioWare content (the SR-1 mesh, the ME3
travel sound), so none are committed. They go in `mod/DLC_MOD_GalaxyMapNormandy/CookedPCConsole/`:

| Package | Built with |
|---|---|
| `Startup_MOD_GalaxyMapNormandy.pcc` | `lectool compileclass <out.pcc> GalaxyMapNormandy src/GalaxyMapNormandyShipLight.uc src/GalaxyMapNormandyDirector.uc` |
| `GalaxyMapNormandy_NOR10.pcc` | mele-mcp `level_new`, then `lectool addactor <level.pcc> GalaxyMapNormandy GalaxyMapNormandyDirector` |
| `GalaxyMapNormandy_SFX.pcc` | `lectool portmesh` (the SR-1 from `BIOA_ICE20_11_LAY`) and `lectool buildsound` (docs/09 §5.1, §5.2) |

`lectool` is a helper built on LegendaryExplorerCore; it is not in this repo yet. Install the mod with ME3Tweaks Mod
Manager while the game is closed.

## Tuning

Every tuning field is a plain property of `GalaxyMapNormandyDirector`; the defaults are at the end of the `.uc`.
MeleBridge's `live_set` changes them in a running game, on this object:
`GalaxyMapNormandy_NOR10.TheWorld.PersistentLevel.GalaxyMapNormandyDirector_0`. The mouse fields are listed in docs/09
§6.2.
