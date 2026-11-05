# How Galaxy Map Normandy works

The mod replaces no file, handler or function of the game. Its startup package holds three UnrealScript classes. A small
level, `GalaxyMapNormandy_NOR10`, holds one `GalaxyMapNormandyDirector` actor. The LE1 Community Patch's Sideloader
loads that level whenever a level whose name starts with `BIOA_NOR10` loads, so the actor is there whenever the galaxy
map can open.

Every frame while the map is open, the director reads the cursor from the galaxy map camera, moves the ship after it
and drives the sound from the ship's speed. With the mouse, it draws the arrow and the Enter Orbit button and, while the
left button is held, feeds the game a virtual stick from the ship toward the arrow. The game then moves the cursor
exactly as it does for the controller. The ship carries its own sky light, because nothing else lights it out in the
map scene. The director also sets the map movie's `LocationShip` clip to zero alpha, which hides the 2D marker and
leaves its labels alone.

Beyond the in-game settings, the ship's size, speed, turn rates, sound and mouse feel are properties of
`GalaxyMapNormandyDirector`, with their defaults at the end of
[`src/GalaxyMapNormandyDirector.uc`](../src/GalaxyMapNormandyDirector.uc). [tuning.md](tuning.md) lists them and shows
how to change them in a running game.

## Files

| Path | What |
|---|---|
| `src/GalaxyMapNormandyDirector.uc` | the actor that runs every frame while the map is open: ship, sound, mouse control, tuning fields |
| `src/GalaxyMapNormandyShipLight.uc` | the ship's own sky light (lighting channel `Unnamed_6`) |
| `src/GalaxyMapNormandySettings.uc` | reads and writes the player's settings in the gamer profile, for the director and the menu |
| `src/ModSettingsSubmenu_GalaxyMapNormandy.uc`, `src/ModSettingsSubmenu_GalaxyMapNormandyStep.uc` | the settings page and the step list in the LE1 Community Patch's Mod Settings Menu |
| `src/sound/flight_sounds.py` | builds the waves of the flight sound variants; `build.sh` asks only for the one `FlightSound` names ([ASSETS.md](ASSETS.md#flight-sound-variants)) |
| `src/tlk/<language>.tsv` | the settings pages' words in each language: a string id, a tab, the text |
| `mod/` | the M3 mod folder without its packages and license texts: `moddesc.ini`, `README.txt` (the read-me in the 7z), `AutoLoad.ini`, `ConfigDelta-GalaxyMapNormandy.m3cd` (the Sideloader level and the Mod Settings Menu row) |
| `build.sh`, `build.env.example` | the build ([building.md](building.md)) |
| `package.sh` | zips the built mod folder for local tests ([Package](building.md#package)) |
| `scripts/release.sh` | checks a release, checks the 7z that M3 deploys, and publishes the GitHub release ([releasing.md](releasing.md)) |
| `scripts/protect-repo.sh` | locks the GitHub repo for releases, once; rendered from the toolkit's release kit, so it is not edited here |
| `docs/` | this page, [building.md](building.md), [tuning.md](tuning.md), [ASSETS.md](ASSETS.md) (which game files the build reads and what it does with them) and [releasing.md](releasing.md) (how a version is published) |

The `.pcc` packages are build output, and `GalaxyMapNormandy_SFX.pcc` holds BioWare content, so none of them is
in git.
