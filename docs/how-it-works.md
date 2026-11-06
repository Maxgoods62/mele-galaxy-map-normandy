# How Galaxy Map Normandy works

This page is for modders. The player guide is [using.md](using.md).

The mod replaces no game file or class. It adds the DLC folder `DLC_MOD_GalaxyMapNormandy` (mount 7422), and its
code is UnrealScript, the game's script language.

## What loads and when

The build makes these packages (`.pcc` files, which hold the game's objects):

| Package | Holds | Loaded |
|---|---|---|
| `Startup_MOD_GalaxyMapNormandy` | the director, the ship light, the settings helper | at startup |
| `DLC_MOD_GalaxyMapNormandy_GlobalTlk*` | the settings strings, one per language code | at startup |
| `GalaxyMapNormandy_NOR10` | an empty level with one director actor | with the Normandy's levels |
| `GalaxyMapNormandy_SFX` | the SR-1 mesh, the button art, the sound cues | by the director |
| `ModSettings_Submenus_GalaxyMapNormandy` | the settings pages | when the player opens them |

`AutoLoad.ini` names the startup package and the talk table, the game's string table. The LE1 Community Patch (LE1CP)
has a Sideloader, which loads extra level files into a map. M3 merges `ConfigDelta-GalaxyMapNormandy.m3cd` into the
game's config at install. It makes the Sideloader load the mod's level with every level whose name starts with
`BIOA_NOR10`.

The director is an actor, an object in a level that runs every frame. It leaves the game's galaxy map handler in
place, because a subclass of that handler broke zooming out of the planet view.

## Each frame while the map is open

The director ticks after the input is read and before the galaxy camera moves the cursor, the orange ring
(`TG_PostAsyncWork`). While the map is closed, it only cleans up.

The map has four levels: galaxy, cluster, system and planet. At cluster and system level, the director spawns the
ship and hides the ring's mesh. It scales the camera's cursor speed (`m_fMovementScalar`) by its own flight speed and
the player's setting. The ship chases the ring under a speed cap and turns toward where it flies.

At every level, the `_alpha` of the map movie's `LocationShip` clip is set to 0. The map's interface is a Scaleform
(Flash) movie, and that clip is the 2D "you are here" marker. The movie keeps setting the clip's visibility, but never
its alpha. The name labels are another clip, so they stay.

### Mouse and controller

The controller keeps the game's own control, and a stick move hides the arrow. Mouse movement goes to the director's
arrow pointer instead of the ring. While the left button is held, the arrow's offset from the ring becomes a virtual
stick. The director writes it where the game reads mouse movement (`m_fCursorDeltaX/Y`). The game then moves the ring
as it does for the controller, so selection and the system camera work as usual.

The left button selects on press, which would zoom in at the start of every flight. At cluster and system level the
director blanks that binding, and a short click selects instead. At other levels, or when another panel has focus,
the binding comes back and the arrow hides.

The Enter Orbit button runs the test the game runs before it obeys the controller's A button. It stays hidden while
the map is in controller mode. Its words are the Mass Effect 2 translations, picked by the game's own word on the A
prompt (string 136218).

## The ship's light

Spawned actors land in the hub's persistent level, and nothing lights that level out in the map scene. The Normandy's
own sky light reaches only the NOR10 design levels. So the ship brings `GalaxyMapNormandyShipLight`, a sky light (a
light with no position) attached to the director. It reaches only the `Unnamed_6` lighting channel, which only the
ship's mesh has. Channels can't change at runtime, so the class sets them in its defaults.

## Settings

Each choice is a percent of the director's default. `GalaxyMapNormandySettings` stores it in slots 100 to 107 of the
gamer profile's `IntStats` list, a list of whole numbers. Slots 100 to 103 hold the cluster flight speed, turn rate,
ship response and ship size, and slots 104 to 107 hold the same four for system view. The game has one profile, so a
choice holds for every career and save. LE1CP keeps its FOV in slot 0. A slot that is 0 or missing means 100 %.

The game writes the profile file only now and then, so the menu writes it after each change, as the Options screen
does. It never saves a profile the game has not read from disk yet, as that would replace the player's options and
careers. The director reads the settings each time the map opens.

The `.m3cd` adds a row to the root page of LE1CP's Mod Settings Menu, and the row names the page class. The pages'
base class is LE1CP's `ModSettingsSubmenu`. The menu package carries a copy of it, and the game still uses the
patch's own class ([ASSETS.md](ASSETS.md#the-community-patch-settings-page-class)).

The strings are in [`src/tlk/`](../src/tlk), one file for each of the eight languages. Each line is a string id, a
tab and the text, in UTF-8, and lines that start with `#` are comments. The ids are 74220001 to 74220022, and they
start with 7422, the mod's mount. Every file must have exactly the ids of `INT.tsv`, or the build stops. The page
classes use a string as `$<id>`, and the row that the `.m3cd` adds uses 74220022 for its description. To add a string,
give it the next free id in all eight files. The game's other language codes FE, GE, IE, RA and PLPC get copies of FR,
DE, IT, RU and PL.

## Sound

The build makes LE1 sound cues from the ME3 galaxy map travel sound. It always makes the original sound
(`c_travel_whoosh`, `c_travel_loop`), and also the variant that the director's `FlightSound` names
([ASSETS.md](ASSETS.md#flight-sound-variants)).

ME2 and ME3 play this sound through Wwise, which pitches and filters it live. LE1 plays sound through ISACT, so
`flight_sounds.py` bakes the fixed pitch, filters and reverb into the variant's waves. The director sets pitch and
volume from the ship's speed. If a variant's cue doesn't load, the director plays the original sound.

A flight starts with a whoosh. The loops rise with speed, and fade out once the ship stops or
the map closes. ISACT plays a loop wave once, so the director restarts each loop with a crossfade.
[tuning.md](tuning.md) has the values.

## Files

| Path | What it holds | More |
|---|---|---|
| `src/GalaxyMapNormandyDirector.uc` | the director, with its values in `defaultproperties` | [tuning.md](tuning.md) |
| `src/GalaxyMapNormandyShipLight.uc` | the ship's sky light | |
| `src/GalaxyMapNormandySettings.uc` | the settings in the gamer profile | |
| `src/ModSettingsSubmenu_*.uc` | the settings page, and the steps of one setting | |
| `src/sound/flight_sounds.py` | the waves of the flight sound variants | [ASSETS.md](ASSETS.md#flight-sound-variants) |
| `src/tlk/*.tsv` | the settings strings, one file per language | |
| `mod/moddesc.ini` | the mod's description for M3 | [building.md](building.md) |
| `mod/README.txt` | the read-me in the download | |
| `mod/.../AutoLoad.ini` | the startup package, the talk table, the mount | |
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
