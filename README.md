# Galaxy Map Normandy

Galaxy Map Normandy is a mod for Mass Effect 1 in the Legendary Edition (LE1). On the galaxy map, a lit SR-1 Normandy
takes the place of the orange cursor ring, as in Mass Effect 2 and 3. It shows at cluster and system level. The ship
follows the cursor and turns toward where it flies. Its engines glow and trail blue light as in Mass Effect 2, and its
sound is made from the Mass Effect 3 travel sound. The mouse works as in Mass Effect 2, with its Enter Orbit button.
The controller keeps the normal game's controls.

Download the 7z file from the
[Nexus Mods page](https://www.nexusmods.com/masseffectlegendaryedition/mods/3538). You can also build the mod from this
repo with your own game files ([docs/building.md](docs/building.md)).

All of the code here was written by an LLM, Claude Opus 5.5, through Claude Code, from my instructions. I decide what
to build and I test the results in the game.

## Requirements

- Mass Effect Legendary Edition. The mod changes only the first game.
- The LE1 Community Patch 2.0 or later. Its Sideloader loads the mod while you are on the Normandy, and its Mod Settings
  Menu holds the mod's settings. M3 does not install the mod without it.
- [ME3Tweaks Mod Manager](https://github.com/ME3Tweaks/ME3TweaksModManager) (M3).

## Install

1. Close the game.
2. Drop the 7z file on the M3 window, or import it with Mod Management > Import Mod.
3. Select Galaxy Map Normandy in the mod library and click Apply Mod.

## Uninstall

Close the game. In M3, select your LE1 game, click Manage Target and remove `DLC_MOD_GalaxyMapNormandy` from the
installed DLC mods.

## Controls

At cluster and system level:

| Input | What it does |
|---|---|
| Move the mouse | moves an arrow pointer |
| Hold the left mouse button | the ship flies toward the arrow |
| Click the left mouse button | selects what is highlighted |
| Click the Enter Orbit button | does what the button says |
| Controller | the normal game's controls |

A click is a press shorter than 0.25 s. When the ship is on something to select, it waits that long before it flies.
Any press counts on the Enter Orbit button, which shows at the bottom of the screen when the ship is on something you
can enter. At galaxy level and in planet view, the map works as in the normal game, and the 2D "you are here" marker
shows at galaxy level. At cluster and system level the ship takes its place, and the name labels stay. All controls:
[docs/using.md](docs/using.md#controls).

## Settings

Pause the game, open Mod Settings and pick Galaxy Map Normandy. You can set the ship's flight speed, turn rate,
response and size, from 50 % to 200 %, and the volume of its flight sound, from 0 % to 140 %. Cluster level and system
view have separate settings, except for the volume. Your choices hold for
every save and apply the next time the map opens. Details: [docs/using.md](docs/using.md#settings).

## Compatibility

- The mod adds the DLC folder `DLC_MOD_GalaxyMapNormandy`, with mount priority 7422.
- It leaves alone the galaxy map files that the Community Patch changes, such as `BIOA_NOR10_03_GM_LAY`.
- It works with Galaxy Map Trackers (LE1).
- The DLC folder name and the mount priority are not registered with ME3Tweaks yet.

## Known issues

- In system view the game's camera follows the cursor, so the ship stays near the middle of the screen. Mass Effect 2
  keeps that view still.
- The selection follows the hidden map cursor, and the ship eases after it. On a fast move, the highlight can change a
  moment before the ship gets there.

## Docs

| Doc | What it holds |
|---|---|
| [docs/using.md](docs/using.md) | the full guide for players |
| [docs/building.md](docs/building.md) | how to build the mod |
| [docs/tuning.md](docs/tuning.md) | the values beyond the in-game settings |
| [docs/how-it-works.md](docs/how-it-works.md) | how the mod works, and its files |
| [docs/ASSETS.md](docs/ASSETS.md) | the game files the build reads |
| [Releasing my mods](https://github.com/Maxgoods62/mele-maxgoods-toolkit/blob/main/docs/releasing.md) | how releases are made, and how to check a download |
| [CHANGELOG.md](CHANGELOG.md) | the changes in each version |

## Credits

- BioWare and Electronic Arts, for Mass Effect Legendary Edition. The built mod holds content read from your games:
  the SR-1 model from LE1, the travel sound and engine trail from LE3 and two LE1 interface sounds used as templates
  ([docs/ASSETS.md](docs/ASSETS.md)). The Enter Orbit button is LE1's own galaxy map button, with Mass Effect 2's words.
- The LE1 Community Patch team, for the Sideloader and the Mod Settings Menu. The mod's settings pages include a copy
  of that menu's page code.
- ME3Tweaks, for M3 and [Legendary Explorer](https://github.com/ME3Tweaks/LegendaryExplorer), whose core library the
  build tools use.
- [mele-maxgoods-toolkit](https://github.com/Maxgoods62/mele-maxgoods-toolkit), for the build tools and the in-game
  bridge used for tuning.
- vgmstream and FFmpeg, which decode and encode the sound.

## License

GPL-3.0 ([LICENSE](LICENSE)), except the game content and the Community Patch code in the built mod ([NOTICE](NOTICE)).
