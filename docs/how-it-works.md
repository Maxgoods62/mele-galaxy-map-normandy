# How Galaxy Map Normandy works

This page is for modders. The player guide is [using.md](using.md).

The mod replaces no game file or class. It adds the DLC folder `DLC_MOD_GalaxyMapNormandy` (mount 7422), and its
code is UnrealScript, the game's script language.

## What loads and when

The build makes these packages (`.pcc` files, which hold the game's objects):

| Package | Holds | Loaded |
|---|---|---|
| `Startup_MOD_GalaxyMapNormandy` | the director, the ship light, the settings helper | at startup |
| `DLC_MOD_GalaxyMapNormandy_GlobalTlk*` | the mod's name, the settings strings and the button's words, one per language code | at startup |
| `GalaxyMapNormandy_NOR10` | an empty level with one director actor | with the Normandy's levels |
| `GalaxyMapNormandy_SFX` | the SR-1 mesh, the engine trail, the sound cues | by the director |
| `ModSettings_Submenus_GalaxyMapNormandy` | the settings pages | when the player opens them |

`AutoLoad.ini` names the startup package and the talk table, the game's string table. Its `NameStrRef` is 74220000,
the string with the mod's name. ME3Tweaks Mod Manager (M3) lists the mod in its Submit mod information form only when
it has one. The LE1 Community Patch (LE1CP) has a Sideloader, which loads extra level files into a map. M3 merges
`ConfigDelta-GalaxyMapNormandy.m3cd` into the game's config at install. It makes the Sideloader load the mod's level
with every level whose name starts with `BIOA_NOR10`.

The director is an actor, an object in a level that runs every frame. It leaves the game's galaxy map handler in
place, because a subclass of that handler broke zooming out of the planet view.

## Each frame while the map is open

The director ticks after the input is read and before the galaxy camera moves the cursor, the orange ring
(`TG_PostAsyncWork`). While the map is closed, it only cleans up.

The map has four levels: galaxy, cluster, system and planet. At cluster and system level, the director spawns the
ship and hides the ring's mesh. It scales the camera's cursor speed (`m_fMovementScalar`) by its own flight speed and
the player's setting. The ship chases the ring under a speed cap and turns toward where it flies.

Zooming in from galaxy level, the game aims the zoom and puts the ring on the camera's `m_pSelectedSystem`, or on the
cluster's first system when that is empty. While the cluster that holds the Normandy is highlighted at galaxy level, the
director sets `m_pSelectedSystem` to the Normandy's system. On any other cluster it is left empty, as in the normal game.

Plot int 13 (`Active_World`, cluster * 10000 + system * 100 + planet) gives the labels of the cluster and system rows in
the galaxy map tables (`Cluster08`, `System02`). The system row names the system's actor (its `Name` string id). The
label alone is not enough: every cluster's second system is tagged `System02`. The game lays the cluster out before it
reads the actor's location, and the systems of other clusters wait hidden at the origin.

When that zoom ends, the director checks that the ring is on the Normandy's system. If it is not (no row found, a
map changed by another mod, or a game path that ignored `m_pSelectedSystem`), the ring and the ship move there and
the camera pans after the ring. Without the tables, the system is the one shown actor with its tag: the systems of the
other clusters are hidden.

At cluster and system level, the `_alpha` of the map movie's `LocationShip` clip is set to 0. At galaxy level and in
planet view it is set back to 100, the value of a new movie. The map's interface is a Scaleform (Flash) movie, and that
clip is the 2D "you are here" marker. The movie keeps setting the clip's visibility, but never its alpha. The name
labels are another clip, so they stay.

### Mouse and controller

The controller keeps the game's own control, and a stick move hides the arrow. Mouse movement goes to the director's
arrow pointer instead of the ring. While the left button is held, the arrow's offset from the ring becomes a virtual
stick. The director writes it where the game reads mouse movement (`m_fCursorDeltaX/Y`). The game then moves the ring
as it does for the controller, so selection and the system camera work as usual.

The left button selects on press, which would zoom in at the start of every flight. At cluster and system level the
director blanks that binding, and a short click selects instead. When a press starts on something a click would
select, the virtual stick waits until the press is longer than a click, so a click leaves the ring where it is.
Anywhere else the stick starts on the first frame. At other levels, or when another panel has focus, the binding comes
back and the arrow hides.

The Enter Orbit button runs the test the game runs before it obeys the controller's A button. It stays hidden while
the map is in controller mode. The button is the map's own Back button: each time the map opens, the director has the
map's Scaleform movie make a copy of that symbol (`_root.attachMovie("backAnim", "gmnEnter", 999000)`). The copy brings
LE1's art, hover look, fades and font (`$AeroLight`, which a font mod such as Myriad Pro Begone may change), and it sits
in the movie's layers, so a window on top of the map covers it. No movie file is changed. The director sets the copy's
place, words and frames through the panel, and tests the arrow against it in the movie's 1280 x 720 stage units. Its
words are Mass Effect 2's, strings 74220025 to 74220027 of the mod's talk tables.

## The ship's light

Spawned actors land in the hub's persistent level, and nothing lights that level out in the map scene. The Normandy's
own sky light reaches only the NOR10 design levels. So the ship brings `GalaxyMapNormandyShipLight`, a sky light (a
light with no position) attached to the director. It reaches only the `Unnamed_6` lighting channel, which only the
ship's mesh has. Channels can't change at runtime, so the class sets them in its defaults.

## The engines

The SR-1's material has its own switch for the glow of the rear nozzles, `Vfx_engine`. The director gives the ship its
own copy of that material, a material instance, and raises the glow while the ship flies.

Four copies of `EngineTrail` sit on the nozzles, as parts of the ship actor, so they follow the ship's size. It is the
engine trail of the Normandy on the Mass Effect 3 galaxy map, which looks like Mass Effect 2's: a halo, a bright core
and a beam. The effect takes the length of its beam from its `Size` parameter, and the director sets that each frame.
At rest the halos stay and the beams are gone. The build copies the effect from LE3
([ASSETS.md](ASSETS.md#the-engine-trail-enginetrail)).

Glow and beams follow the engine's thrust, which follows the ship's speed as a share of full speed, as the flight
sound does. [tuning.md](tuning.md#engines) has the values.

## Settings

Each choice is a percent of the director's default. `GalaxyMapNormandySettings` stores it in slots 100 to 107 and 109
of the gamer profile's `IntStats` list, a list of whole numbers. Slots 100 to 103 hold the cluster flight speed, turn
rate, ship response and ship size, and slots 104 to 107 hold the same four for system view. Slot 109 holds the flight
sound volume plus 1, so that 0 % can be stored. Slot 108 held a setting of a test build: nothing reads it, and Restore
defaults clears it. The game has one profile, so a choice holds for every career and save. LE1CP keeps its FOV in slot
0. A slot that is 0 or missing means 100 %.

The game writes the profile file only now and then, so the menu writes it after each change, as the Options screen
does. It never saves a profile the game has not read from disk yet, as that would replace the player's options and
careers. The director reads the settings each time the map opens.

The `.m3cd` adds a row to the root page of LE1CP's Mod Settings Menu, and the row names the page class. The pages'
base class is LE1CP's `ModSettingsSubmenu`. The menu package carries a copy of it, and the game still uses the
patch's own class ([ASSETS.md](ASSETS.md#the-community-patch-settings-page-class)).

The strings are in [`src/tlk/`](../src/tlk), one file for each of the eight languages. Each line is a string id, a
tab and the text, in UTF-8, and lines that start with `#` are comments. The ids are 74220000 to 74220024, and they
start with 7422, the mod's mount. Every file must have exactly the ids of `INT.tsv`, or the build stops. 74220000 is
the mod's name, for `NameStrRef` in `AutoLoad.ini`. The page classes use a string as `$<id>`, and the row that the
`.m3cd` adds uses 74220022 for its description. To add a string, give it the next free id in all eight files. The
game's other language codes FE, GE, IE, RA and PLPC get copies of FR, DE, IT, RU and PL.

## Sound

The build makes LE1 sound cues from the ME3 galaxy map travel sound. It always makes the original sound
(`c_travel_whoosh`, `c_travel_loop`), and also the variant that the director's `FlightSound` names
([ASSETS.md](ASSETS.md#flight-sound-variants)).

ME2 and ME3 play this sound through Wwise, which pitches and filters it live. LE1 plays sound through ISACT, so
`flight_sounds.py` bakes the fixed pitch, filters and reverb into the variant's waves. The director sets pitch and
volume from the ship's speed, and the Flight sound volume setting scales that volume. If a variant's cue doesn't
load, the director plays the original sound.

A flight starts with a whoosh. The loops rise with speed, and fade out once the ship stops or the map closes. ISACT
plays a loop wave once, so the director restarts each loop with a crossfade. [tuning.md](tuning.md) has the values.

## Files

| Path | What it holds | More |
|---|---|---|
| `src/GalaxyMapNormandyDirector.uc` | the director, with its values in `defaultproperties` | [tuning.md](tuning.md) |
| `src/GalaxyMapNormandyShipLight.uc` | the ship's sky light | |
| `src/GalaxyMapNormandySettings.uc` | the settings in the gamer profile | |
| `src/ModSettingsSubmenu_*.uc` | the settings page, and the steps of one setting | |
| `src/sound/flight_sounds.py` | the waves of the flight sound variants | [ASSETS.md](ASSETS.md#flight-sound-variants) |
| `src/tlk/*.tsv` | the mod's name and the settings strings, one file per language | |
| `mod/moddesc.ini` | the mod's description for M3 | [building.md](building.md) |
| `mod/README.txt` | the read-me in the download | |
| `mod/.../AutoLoad.ini` | the startup package, the talk table, the mod's name, the mount | |
| `mod/.../ConfigDelta-GalaxyMapNormandy.m3cd` | the Sideloader level and the menu row | |
| `build.sh`, `build.env.example` | the build and its settings | [building.md](building.md) |
| `package.sh` | zips the built mod for tests | [building.md](building.md) |
| `scripts/release.sh` | checks and publishes a release; the steps are at the top of the script | |
| `scripts/protect-repo.sh` | locks the GitHub repo once, when it goes public | |
| `docs/`, `README.md` | these pages, and the front page | |
| `CHANGELOG.md` | the version history | [CHANGELOG.md](../CHANGELOG.md) |
| `LICENSE`, `NOTICE` | the GPL, and what it doesn't cover | |
| `.gitignore`, `.github/` | what git leaves out, and the bug report form | |

The toolkit's release kit renders `scripts/protect-repo.sh`, so it is not edited here. The toolkit's
[releasing page](https://github.com/Maxgoods62/mele-maxgoods-toolkit/blob/main/docs/releasing.md) says how the
releases work and how to check a download.

## What is not in git

No package or sound file is in git, and neither are `build/` and `dist/`. The packages are build output, and
`GalaxyMapNormandy_SFX` holds content taken from the games. The menu package holds LE1CP's class. `build.sh` makes
them from the player's own game files, which [ASSETS.md](ASSETS.md) lists. `build.env` holds one machine's paths.
