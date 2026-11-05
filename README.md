# Galaxy Map Normandy (LE1)

A mod for Mass Effect 1 in the Legendary Edition. On the galaxy map, a lit SR-1 Normandy replaces the orange cursor
ring at cluster and system level, as in ME2 and ME3. It follows the cursor and turns toward where it flies. Its sound
comes from the ME3 travel sound. A whoosh plays when the ship sets off, then an engine and a drive rise with its speed.
The mouse works as in ME2, with its Enter Orbit button. The controller works as before. The game's 2D "you are here"
marker is gone at every level of the map; the name labels stay. Apart from that, the galaxy level and the
planet view are as in the normal game.

There is no release yet. You build the mod from this repository and your own game files, then install it with
ME3Tweaks Mod Manager (M3). The version is `modver` in [`mod/moddesc.ini`](mod/moddesc.ini); the history is in
[CHANGELOG.md](CHANGELOG.md).

## Requirements

| Need | Why |
|---|---|
| Mass Effect Legendary Edition, with the LE1, LE2 and LE3 files in its folder | the mod is for LE1; the build takes the button's art from LE2's `Startup_INT.pcc` and the travel sound from LE3's `SFXGame.pcc` |
| LE1 Community Patch 2.0 or later | its Sideloader loads the mod's level with the Normandy; `moddesc.ini` requires `DLC_MOD_LE1CP` 2.0 or later |
| [ME3Tweaks Mod Manager](https://github.com/ME3Tweaks/ME3TweaksModManager) | installs the mod; `moddesc.ini` targets moddesc version 9.2 |
| Windows with WSL, and the build tools listed in [docs/building.md](docs/building.md) | the mod is built on your machine |

## Install

1. Build the mod as [docs/building.md](docs/building.md) explains. The build writes the M3 mod folder to
   `dist/Galaxy Map Normandy/`.
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

## Credits

- BioWare and Electronic Arts: Mass Effect Legendary Edition. The build copies these from your own install: the SR-1
  model (LE1's `BIOA_ICE20_11_LAY.pcc`), the ME2 PC button art (LE2's `Startup_INT.pcc`), the ME3 galaxy map travel
  sound (LE3's `SFXGame.pcc`), and two LE1 interface sounds used as templates (`snd_gui.pcc`).
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
