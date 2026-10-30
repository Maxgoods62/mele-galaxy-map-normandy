# Galaxy Map Normandy (LE1)

A mod for Mass Effect 1 in the Legendary Edition. On the galaxy map, a lit SR-1 Normandy takes the place of the orange
cursor ring at cluster and system level, as in ME2 and ME3. It follows the cursor, turns toward where it flies and
plays the ME3 travel sound: a whoosh when it sets off, then an engine loop whose pitch and volume rise with its speed.
The mouse works as in ME2, and the controller keeps LE1's own control. The galaxy level and the planet view stay
vanilla.

There is no release yet. You build the mod from this repository and your own game files, then install it with
ME3Tweaks Mod Manager (M3). The version is `modver` in [`mod/moddesc.ini`](mod/moddesc.ini); the history is in
[CHANGELOG.md](CHANGELOG.md).

## Requirements

| Need | Why |
|---|---|
| Mass Effect Legendary Edition, with the LE1 and LE3 files in its folder | the mod is for LE1; the build takes the travel sound from LE3's `SFXGame.pcc` |
| LE1 Community Patch 2.0 or later | its Sideloader loads the mod's level with the Normandy; `moddesc.ini` requires `DLC_MOD_LE1CP` 2.0 or later |
| [ME3Tweaks Mod Manager](https://github.com/ME3Tweaks/ME3TweaksModManager) | installs the mod; `moddesc.ini` targets moddesc version 9.2 |
| Windows with WSL, and the build tools listed in [docs/building.md](docs/building.md) | the mod is built on your machine |

## Install

1. Build the mod. [docs/building.md](docs/building.md) has the details; the short version, in WSL:

   ```bash
   cp build.env.example build.env    # once: your Legendary Edition folder, dotnet.exe, vgmstream
   ./build.sh
   ```

   `build.sh` writes the M3 mod folder to `dist/Galaxy Map Normandy/`.
2. Copy `dist/Galaxy Map Normandy` into the `LE1` folder of M3's mod library.
3. Close the game. In M3, refresh the mod library, select Galaxy Map Normandy and click Apply Mod.

## Uninstall

Close the game. In M3, select your LE1 game, click Manage Target to open Installation Information, and remove
`DLC_MOD_GalaxyMapNormandy` from the list of installed DLC mods.

## Controls

At cluster and system level:

| Input | What it does |
|---|---|
| Move the mouse | moves an arrow pointer, which starts on the ship |
| Hold the left mouse button | the ship flies toward the arrow and slows down as it gets close |
| Click the left mouse button (shorter than 0.25 s) | selects the highlighted object, as a vanilla click does |
| Controller | unchanged: the stick moves the cursor and the ship follows it; moving the stick hides the arrow until the mouse moves again |

While another panel has focus, such as the travel prompt, the arrow is hidden and the left button works as in vanilla.
At galaxy level the mouse and the left button work as in vanilla.

## Settings

Pause the game, open **Mod Settings** (the LE1 Community Patch's Mod Settings Menu) and pick **Galaxy Map Normandy**.
For cluster level and for system view, you can set:

| Setting | What it changes |
|---|---|
| Flight speed | how fast the ship and the map cursor move, with the controller and with the mouse |
| Turn rate | how fast the ship's nose turns toward where it flies |
| Ship response | how closely the ship follows the cursor: lower glides behind it, higher stays on it |
| Ship size | the ship's size |

Each setting opens a list of steps from 50 % to 200 % of the default. **Restore defaults** puts all eight back to
100 %. The choices are kept in the game's gamer profile (`Save\ME1\PROFILE\GamerProfile.pcsav` in your documents), so
they are the same for every career and save. They apply the next time the galaxy map opens.

## How it works

The mod replaces no file, handler or function of the game. Its startup package holds three UnrealScript classes. A small
level, `GalaxyMapNormandy_NOR10`, holds one `GalaxyMapNormandyDirector` actor. The LE1 Community Patch's Sideloader
loads that level whenever a level whose name starts with `BIOA_NOR10` loads, so the actor is there whenever the galaxy
map can open.

Every frame while the map is open, the director reads the cursor from the galaxy map camera, moves the ship after it
and drives the sound from the ship's speed. With the mouse, it draws the arrow and, while the left button is held,
feeds the game a virtual stick from the ship toward the arrow. The game then moves the cursor exactly as it does for
the controller. The ship carries its own sky light, because nothing else lights it out in the map scene.

## Compatibility

- The mod adds the DLC folder `DLC_MOD_GalaxyMapNormandy` (mount priority 7422). It does not touch the galaxy map files
  that the LE1 Community Patch overrides (`BIOA_NOR10_03_GM_LAY`, `BIOA_NOR10_03_DSG`).
- It has not been tested together with other galaxy map mods.
- The mount priority and the DLC folder name are not registered with ME3Tweaks yet.

## Known issues

- In system view the vanilla camera follows the cursor, so the ship stays near the middle of the screen while the
  system moves under it. ME2 keeps that view still.
- The selection follows the hidden cursor, and the ship eases after it. On a fast move the highlight can change a
  moment before the ship gets there.
- At cluster level LE1's own small 2D Normandy icon still marks the system you are in, while the 3D ship shows where
  you point.

## Tuning

Beyond the in-game settings, the ship's size, speed, turn rates, sound and mouse feel are plain properties of `GalaxyMapNormandyDirector`, with
their defaults at the end of [`src/GalaxyMapNormandyDirector.uc`](src/GalaxyMapNormandyDirector.uc).
[docs/tuning.md](docs/tuning.md) lists them and shows how to change them in a running game.

## Files

| Path | What |
|---|---|
| `src/GalaxyMapNormandyDirector.uc` | the actor that runs every frame while the map is open: ship, sound, mouse control, tuning fields |
| `src/GalaxyMapNormandyShipLight.uc` | the ship's own sky light (lighting channel `Unnamed_6`) |
| `src/GalaxyMapNormandySettings.uc` | reads and writes the player's settings in the gamer profile, for the director and the menu |
| `src/ModSettingsSubmenu_GalaxyMapNormandy.uc`, `src/ModSettingsSubmenu_GalaxyMapNormandyStep.uc` | the settings page and the step list in the LE1 Community Patch's Mod Settings Menu |
| `mod/` | the M3 mod folder without its packages: `moddesc.ini`, `AutoLoad.ini`, `ConfigDelta-GalaxyMapNormandy.m3cd` (the Sideloader level and the Mod Settings Menu row) |
| `build.sh`, `build.env.example` | the build ([docs/building.md](docs/building.md)) |
| `package.sh` | zips the built mod folder for local tests ([Package](docs/building.md#package)) |
| [`docs/ASSETS.md`](docs/ASSETS.md) | which game files the build reads and what it does with them |

The four `.pcc` packages are build output, and `GalaxyMapNormandy_SFX.pcc` holds BioWare content, so none of them is
in git.

## Credits

- BioWare and Electronic Arts: Mass Effect Legendary Edition. From your own install, the build copies the SR-1 model
  (the docked Normandy's static mesh in `BIOA_ICE20_11_LAY.pcc`), the ME3 galaxy map travel sound (LE3's
  `Wwise_Generic_Galaxy_Map` bank in `SFXGame.pcc`) and two LE1 interface sound cues, used as templates
  (`snd_gui.pcc`).
- The LE1 Community Patch team, for the Sideloader that loads the mod's level and the Mod Settings Menu. The build
  copies the menu's page class (`ModSettingsSubmenu`) from your installed Community Patch into the mod's menu package,
  as other mods' settings pages do.
- ME3Tweaks: ME3Tweaks Mod Manager, and [Legendary Explorer](https://github.com/ME3Tweaks/LegendaryExplorer), whose
  LegendaryExplorerCore library the build tools use.
- [mele-maxgoods-toolkit](https://github.com/Maxgoods62/mele-maxgoods-toolkit): the build tools
  ([lectool](https://github.com/Maxgoods62/mele-maxgoods-toolkit/blob/main/tools/lectool/README.md) and mele-mcp)
  and the in-game bridge used for tuning.
- vgmstream and FFmpeg, which decode and encode the sound.

## License

The files in this repository are under the GNU General Public License v3.0 ([LICENSE](LICENSE)). The game content the
build reads, and the content `GalaxyMapNormandy_SFX.pcc` takes from it, are not: see [NOTICE](NOTICE).
