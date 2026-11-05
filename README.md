# Galaxy Map Normandy (LE1)

A mod for Mass Effect 1 in the Legendary Edition. On the galaxy map, a lit SR-1 Normandy replaces the orange cursor
ring at cluster and system level, as in ME2 and ME3. It follows the cursor and turns toward where it flies. Its sound
comes from the ME3 travel sound. A whoosh plays when the ship sets off, then an engine and a drive rise with its speed.
The mouse works as in ME2, with its Enter Orbit button. The controller works as before. The game's 2D "you are here"
marker is gone at every level of the map; the name labels stay. Apart from that, the galaxy level and the
planet view are as in the normal game.

Download the 7z file from the [Nexus Mods page](NEXUS_PAGE_URL) and install it with ME3Tweaks Mod Manager (M3).
You can also build the mod from this repository and your own game files ([docs/building.md](docs/building.md)). The
version is `modver` in [`mod/moddesc.ini`](mod/moddesc.ini); the history is in [CHANGELOG.md](CHANGELOG.md).

## Requirements

| Need | Why |
|---|---|
| Mass Effect Legendary Edition | the mod changes its first game, LE1 |
| LE1 Community Patch 2.0 or later | its Sideloader loads the mod's level with the Normandy, and its Mod Settings Menu holds the mod's settings |
| [ME3Tweaks Mod Manager](https://github.com/ME3Tweaks/ME3TweaksModManager) | installs the mod |

Building the mod needs more: the LE2 and LE3 files, WSL and the build tools ([docs/building.md](docs/building.md)).

## Install

1. Close the game.
2. Drop the 7z file on the M3 window. Or use Mod Management > Import Mod > Import mod from .7z/.rar/.zip/.exe/.me2mod
   and pick the file. Click Import mods.
3. Select Galaxy Map Normandy in the mod library and click Apply Mod.

To install a build of your own, see [docs/building.md](docs/building.md#install-your-build).

## Uninstall

Close the game. In M3, select your LE1 game, click Manage Target to open Installation Information, and remove
`DLC_MOD_GalaxyMapNormandy` from the list of installed DLC mods.

## Controls

At cluster and system level:

| Input | What it does |
|---|---|
| Move the mouse | moves an arrow pointer, which starts on the ship |
| Hold the left mouse button | the ship flies toward the arrow and slows down as it gets close |
| Click the left mouse button (shorter than 0.25 s) | selects the highlighted object, as a click does in the normal game |
| Click the button at the bottom centre | the same, as LE2's Enter Orbit button does; a press on it does not fly the ship |
| Controller | unchanged: the stick moves the cursor and the ship follows it; moving the stick hides the arrow until the mouse moves again |

With the mouse, the button shows when the ship is on something the map can enter, as the A prompt does. It reads
Enter System on a system at cluster level, Enter Orbit on a planet in system view, and Scan on a planet still to be
scanned. A touch of the controller swaps it for the controller's prompts, and a click or a key brings it back. Its
words are LE2's, in English, French, German, Italian, Spanish and Polish (without accents: the font drawing them has
none). Russian and Japanese games get English for the same reason.

While another panel is open, such as the travel prompt, the arrow and the button are hidden. The left button then works
as in the normal game. At galaxy level the mouse and the left button work as in the normal game too.

## Settings

Pause the game, open **Mod Settings** (the LE1 Community Patch's Mod Settings Menu) and pick **Galaxy Map Normandy**.
The pages follow the game's text language: English, French, German, Italian, Spanish, Polish, Russian or Japanese. No
native speaker has reviewed the translations. For cluster level and for system view, you can set:

| Setting | What it changes |
|---|---|
| Flight speed | how fast the ship and the map cursor move, with the controller and with the mouse |
| Turn rate | how fast the ship's nose turns toward where it flies |
| Ship response | how closely the ship follows the cursor: lower glides behind it, higher stays on it |
| Ship size | the ship's size |

Each setting opens a list of steps from 50 % to 200 % of the default. **Restore defaults** puts all eight back to
100 %. The choices are kept in the game's gamer profile (`Save\ME1\PROFILE\GamerProfile.pcsav` in your documents), so
they are the same for every career and save. They apply the next time the galaxy map opens.

## Compatibility

- The mod adds the DLC folder `DLC_MOD_GalaxyMapNormandy` (mount priority 7422). It does not touch the galaxy map files
  that the LE1 Community Patch overrides (`BIOA_NOR10_03_GM_LAY`, `BIOA_NOR10_03_DSG`).
- It has not been tested together with other galaxy map mods.
- The mount priority and the DLC folder name are not registered with ME3Tweaks yet.

## Known issues

- In system view the game's camera follows the cursor. The ship stays near the middle of the screen while the system
  moves under it. ME2 keeps that view still.
- The selection follows the hidden cursor, and the ship eases after it. On a fast move the highlight can change a
  moment before the ship gets there.

## Docs

| Doc | What it holds |
|---|---|
| [docs/building.md](docs/building.md) | how to build the mod, and what to do when the build stops |
| [docs/how-it-works.md](docs/how-it-works.md) | how the mod works, and what each file in this repository holds |
| [docs/tuning.md](docs/tuning.md) | the ship, sound and mouse values beyond the in-game settings, and how to try them in a running game |
| [docs/ASSETS.md](docs/ASSETS.md) | which game files the build reads and what it does with them |
| [docs/releasing.md](docs/releasing.md) | how a version is published, and how to check a download |

## Credits

- BioWare and Electronic Arts: Mass Effect Legendary Edition. The mod holds content taken from the games: the SR-1
  model (LE1's `BIOA_ICE20_11_LAY.pcc`), the ME2 PC button art (LE2's `Startup_INT.pcc`), the ME3 galaxy map travel
  sound (LE3's `SFXGame.pcc`), and two LE1 interface sounds used as templates (`snd_gui.pcc`). The build reads them
  from an installed copy of the games.
- The LE1 Community Patch team, for the Sideloader that loads the mod's level and the Mod Settings Menu. The mod's menu
  package holds a copy of the menu's page class (`ModSettingsSubmenu`), as other mods' settings pages do. The build
  takes it from an installed Community Patch.
- ME3Tweaks: ME3Tweaks Mod Manager, and [Legendary Explorer](https://github.com/ME3Tweaks/LegendaryExplorer), whose
  LegendaryExplorerCore library the build tools use.
- [mele-maxgoods-toolkit](https://github.com/Maxgoods62/mele-maxgoods-toolkit): the build tools
  ([lectool](https://github.com/Maxgoods62/mele-maxgoods-toolkit/blob/main/tools/lectool/README.md) and mele-mcp)
  and the in-game bridge used for tuning.
- vgmstream and FFmpeg, which decode and encode the sound.

## License

The files in this repository are under the GNU General Public License v3.0 ([LICENSE](LICENSE)). The game content in
the built mod and the Community Patch's class are not: see [NOTICE](NOTICE).
