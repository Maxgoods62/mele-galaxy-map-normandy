# Changelog

The builds under "Development builds" were made for testing between 2026-10-28 and 2026-11-06. The last of them, v0.27,
became v1.0 with the changes marked v1.0 in that list. The version number is `modver` in `mod/moddesc.ini`.

## v1.3 (2026-11-08)

The game's own Enter Orbit button, and two small fixes.

- The Enter Orbit button (Enter System or Scan) is now LE1's own galaxy map button, the one the planet view shows as
  Zoom Out. It has LE1's art, hover look and font, and it sits in the map's own layers, under the labels and rings.
  Before, the mod drew a copy of LE2's button over the map with a font of its own: the panel was see-through at rest,
  two layers showed while it changed to the hover look, and a mod that changes the interface font, such as Myriad Pro
  Begone, did not change its words. The words are Mass Effect 2's, now in Russian and Japanese too. Reported on Nexus.
- The Enter Orbit button (Enter System or Scan) reacts to the arrow you see. Before, it went by where the arrow was one
  frame earlier, so a click released just after the arrow left the button could still count.
- The engine and drive sounds no longer cut out for a moment on a long flight with several quick slowdowns. They kept
  playing while the ship slowed, but that time was not counted, so their next restart could come after the sound ended.
- Building the mod no longer needs LE2: the button art is not read from it any more.

## v1.2 (2026-11-08)

A volume setting for the flight sound.

- Flight sound volume, the first row of the Galaxy Map Normandy page in Mod Settings, sets how loud the ship's flight
  sound is: the whoosh as it sets off, the engine and the drive, at cluster level and in system view. It goes from 0 %
  to 140 % in steps of 10 %. 100 % is the sound of v1.1, and 0 % turns the sound off. Restore defaults sets it back
  to 100 %.

## v1.1 (2026-11-07)

Two fixes on the galaxy map.

- The game's "you are here" marker, a small ship outline in a ring, shows again at galaxy level, as in the normal game.
  It stays hidden at cluster and system level, where the Normandy flies in its place. v1.0 hid it at every level.
- When you zoom from the galaxy into the cluster where the Normandy is, the zoom now flies to the Normandy's system and
  the ship starts there. In v1.0 the zoom went to the cluster's first system: with the Normandy at Strenuus, in the
  Horse Head Nebula, the ship showed at Pax. This works for systems added by DLC too, such as Asgard in the Exodus
  Cluster. If the zoom ever ends somewhere else, the cursor and the ship move to the Normandy's system.

## v1.0 (2026-11-06)

The first version made for players. On the LE1 galaxy map, a lit SR-1 Normandy takes the place of the orange cursor ring
at cluster and system level, with engine glow and trails as in ME2 and a sound made from the ME3 travel sound. The mouse
works as in ME2, with an arrow pointer and an Enter Orbit button, and the controller works as before. In the LE1
Community Patch's Mod Settings Menu you can set the ship's speed, turn rate, response and size. It needs Mass Effect
Legendary Edition, the LE1 Community Patch 2.0 or later and ME3Tweaks Mod Manager.

## Development builds

- v1.0: a quick click on something to select no longer moves the ship. Before, the ship set off as soon as the button
  went down, so a click shorter than 0.25 s could move the map cursor, and the selection with it, before it selected.
  Now, when a press starts on something a click selects, the ship waits 0.25 s before it flies. Anywhere else it still
  sets off at once. Each frame adds 0.05 s at most to the press, so a slow frame no longer turns a click into a short
  flight. Tested in game (2026-11-06): quick clicks on a planet and on a system select them and the ship stays still; a
  hold from a planet flies after the wait; a click in open space makes a short move and selects nothing.
- v1.0: `AutoLoad.ini` has a `[GUI]` section with `NameStrRef` 74220000, and every `src/tlk/*.tsv` file has the mod's
  name, Galaxy Map Normandy, untranslated, under that id. M3's Submit mod information form lists the mod only with it.
  Tested in game (2026-11-06): the game boots and the map works.
- v1.0: `NOTICE` names the LE3 engine trail, and it limits "personal use" to the game content in the built packages. The
  README and `README.txt` say that all of the code is written by an LLM. M3's description is a short summary.
  `README.txt` mentions the engine glow and trails, and it links the GitHub releases, which name the source of each
  version.
  `.gitignore` keeps out more game and binary file types.
- v0.27: engine glow and trails in flight (2026-11-06). The director raises the SR-1 material's own nozzle glow
  (`Vfx_engine`) on the ship's copy of the material, and puts four copies of the ME3 galaxy map Normandy's engine trail
  on the nozzles: halos at rest, and beams that grow with speed, as in ME2. `build.sh` copies the trail from LE3 with
  the toolkit's new `lectool portfx`, which also copies the LE3 material and textures that LE1 can't load. Tested in
  game (2026-11-06).
- v0.27: every start of a flight plays the whoosh. Before, it played only after a rest of 0.6 s (`RestBeforeSound`, now
  0), so a quick stop and start lost Bright thrusters' whoosh (2026-11-06). A whoosh still playing from the start before
  fades out over `LoopFadeOut` on its own component instead of being cut. LE1's `Play()` keeps the fade of a `FadeOut`
  called on a stopped component, so the next sound faded out in 0.4 s and stopped: since the close fade above, the first
  whoosh after reopening the map was silent. `PlayCue` now clears the fade before each play.
- v0.27: a slower ship at cluster level. 100 % Cluster flight speed is now the old 75 %, picked in playtests:
  `ClusterFlightSpeed` 0.5625 (was 0.75). System view keeps its speed.
- v0.27: the docs are rewritten from the code. `docs/using.md` is new, the full guide for players. `docs/releasing.md`
  is gone: the release steps are at the top of `scripts/release.sh`, and the toolkit's `docs/releasing.md` says how
  my mods are released and checked. The README is under 5000 characters.
- v0.27: the release files. `scripts/release.sh` checks a release, checks the 7z that M3 deploys against the build, and
  publishes a GitHub release that holds only `SHA256SUMS` for that 7z (its steps are at the top of the script).
  `build.sh` pins the toolkit commit (`TOOLKIT_COMMIT`) and writes `dist/build.stamp`: the mod's and the toolkit's
  commits, their uncommitted changes, the LE1 Community Patch version it read and a hash of the built files.
  `moddesc.ini`'s `[UPDATES]` section puts a `LICENSE` folder and `README.txt` in the 7z that M3 deploys, and M3 does
  not install them in the game. The zip of `package.sh` holds them inside the mod folder. `build.sh` copies only the
  files of `mod/` that git sees, and its count of uncommitted changes includes edits that git hides. `release.sh` checks
  the built folder against the commit, asks GitHub itself for `main`, the tag and the toolkit commit, and checks that M3
  made the 7z, under the name M3 proposes.
- v0.27: closing the map fades the engine, the drive and the whoosh out over `LoopFadeOut` (0.4 s for Bright thrusters).
  Before, the loops stopped at once and the whoosh played on into the close. `build.sh` stops when lectool gives a
  flight sound cue no wave of its own (a toolkit without `buildsound --unique-wave`) and when `FlightSound` names no
  variant, and it rebuilds a tool whose built file is missing. The README is shorter: how the mod works and its files
  moved to `docs/how-it-works.md`. In game: the close fade works (2026-11-05).
- v0.26: the ship plays Bright thrusters, the variant liked best in playtests, and the Flight sound row, its page and
  its strings are gone. The director's `FlightSound` (5) picks the sound, and `build.sh` builds only that variant's
  cues, so the sound package is about 2.8 MB smaller. `flight_sounds.py` still defines all five variants, and the
  original sound is still built as the fallback. In game: not tested yet.
- v0.25: a Flight sound row on the settings page picks one of six ship sounds: the original one (the default) or five
  new ones built from the same three LE3 sounds by `src/sound/flight_sounds.py`. Mass Effect 3 and Mass Effect 2 follow
  those games' own mix, read from their Wwise banks: everything pitched down and filtered, an engine note that rises
  with speed on Wwise's curve, a second loop (the drive) two octaves lower in system view, and for ME2 its short reverb.
  Deep rumble, Soft hum and Bright thrusters are variations on them. LE1 cannot pitch, filter or loop these live as
  Wwise does, so the pitch, filter and reverb are baked into 16 s loop waves and the director plays two loops at once
  with their own pitch and volume curves. Picking a sound plays a 3 to 4 s sample of it. The choice is kept in gamer
  profile slot 108. Every variant cue is built on the same template cue, so `lectool buildsound --unique-wave` gives
  each its own wave, named `<cue>:<template title>`: an LE1 wave is named `<bank>:<title>`, and the game plays the sound
  whose title, in the wave's ISACT content index, is the part after the colon. The first build renamed the waves without
  the colon and every cue was silent, the original sound's too (2026-11-05); the original cues keep the template's wave
  names, as in v0.24. In game, first build (career save, galaxy map in system view): the row and the list show, a pick
  writes the profile file, the map loads the picked sound's cues with its values, and a flight starts the whoosh and
  both loops, all silent. In playtests of the fixed build, the original sound and the variants all played (2026-11-05).
- v0.24: the settings pages and their row on the Mod Settings Menu's first page are translated: French, German, Italian,
  Spanish, Polish, Russian and Japanese, with the game's own words where it has them. The mod now has a GlobalTlk, one
  package per language file name the game looks for, built from `src/tlk/<language>.tsv`. The row's title, the mod's
  name, stays in English. The page's subtitle is one sentence shorter: two did not fit its one-line field in any
  language. "The same for every save" stays in the row's description. In game: the page, a step list and the row
  read correctly in French, Japanese and Russian.
- v0.23: the button no longer shows on top of the controller's prompts. A touch of the controller hides it; a click or
  a key brings it back. In game: works.
- v0.22: under the pointer the button is a solid brown panel with gold corners, as LE1's own buttons are, instead of an
  almost transparent amber. In game: works.
- v0.21: a mouse player gets LE2's button at the bottom centre of the screen when the ship is on something the map can
  enter: Enter System at cluster level, Enter Orbit in system view, Scan on a planet still to be scanned. It shows when
  the controller's A or Y prompt does, turns amber under the pointer and acts on a click, as a press of A does. A press
  on it does not fly the ship. Its art is LE2's PC button, read from your LE2 at build time and recoloured with the blue
  and amber of LE1's Back button, and its words are LE2's own translations. In game: works.
- v0.20: LE1's own "you are here" marker (the 2D ship outline and the ring around it) no longer shows, at any level of
  the map. The director sets the `LocationShip` clip of the map movie to zero alpha; the name labels stay.
  In game: the marker stayed gone at every level, after reopening the map and after travel, with no flash on opening.
- v0.18: each change in the menu writes the profile file at once, through the Options screen's own save
  (`BioSFHandler_PCOptions.SaveProfile`), as the LE1 Community Patch's FOV slider does. v0.17 queued the engine's
  profile save command, which only fills the save system's in-memory record; the game writes the file on its own only
  now and then, so a change could be lost when the game quit. In game: a pick wrote the file at once and was still set
  after a restart and another save.
- v0.17: the settings are kept in the gamer profile's `IntStats` list, slots 100 to 107, where the LE1 Community Patch
  keeps its FOV. The v0.15 and v0.16 builds kept them in its `IntVariables` list, and the profile file never held them.
- v0.16: the values picked in playtests of the v0.15 menu are the new defaults, so 100 % in the menu is the old 75 %
  flight speed, 125 % ship response and 75 % ship size, at cluster level and in system view: `ClusterFlightSpeed` and
  `SystemFlightSpeed` 0.75 (new), `ChaseSpeed` and `SystemChaseSpeed` 10, `ShipScale` 0.06, `SystemShipScale` 0.0375.
  Turn rates unchanged.
- v0.15: a Galaxy Map Normandy page in the LE1 Community Patch's Mod Settings Menu. Flight speed, turn rate, ship
  response and ship size, each for cluster level and system view, in steps from 50 % to 200 %, kept in the gamer profile
  for every save. Flight speed scales the galaxy camera's `m_fMovementScalar`, so the controller and the mouse speed up
  alike. In game: the menu works, and playtests tried several values.
- v0.14, rebuilt from the repo (2026-10-29): `build.sh` builds the mod from this repository and your own game files. The
  mod itself does not change: a rebuild has the same exports and the same decoded sound as v0.14. `moddesc.ini` has a
  description for players, the LE1 Community Patch 2.0 or later as the required DLC, and this repository as the mod
  site. In game: the rebuilt mod works.

### v0.14

- The mouse's virtual stick caps come from live tests: `MouseStickCluster` 1.75, so the ship is faster at cluster
  level, and `MouseStickSystem` 0.85.

### v0.13

- Virtual stick: while the left button is held, the mouse feeds a virtual controller stick, from the ship toward the
  arrow, into the game's own cursor control. The mouse now moves the ship exactly as the controller does.
- The v0.12 heading model stays in the code behind `bVirtualStick`.
- In game: right in system view, too slow at cluster level.

### v0.12

- Heading model: the nose turns toward the arrow at a limited rate (`FlyTurnRate`) and the ship thrusts along it, so a
  reversal is a tight U-turn.
- Smaller ship at cluster level (`ShipScale` 0.08) and a lower cluster speed (`FlyClusterSpeed` 150).
- In game: turns were better, but the mouse still did not feel like the controller.

### v0.11

- The arrow reads the mouse every frame and is kept as a screen position, so it moves smoothly. The vanilla game only
  passes the mouse on when its counts change from one frame to the next.
- In game: almost right in system view. Reversals slid through a stop, and at cluster level the ship was too fast and
  too big.

### v0.10

- While another panel has focus, such as the travel prompt, the arrow is hidden and the left button works as in
  vanilla.
- In game: the travel prompt worked. The arrow felt laggy, and the ship was too fast.

### v0.9

- ME2 mouse control: an arrow pointer; holding the left button flies the cursor toward it; a click shorter than 0.25 s
  selects. The left button's own binding is cleared at cluster and system level.
- In game: the travel prompt could not be clicked.

### v0.8

- The raw mouse counts are scaled (`MouseScale` 0.4) and capped (`MouseMaxRate`) before the game moves the cursor.
- In game: better, but a far target still took several swipes.

### v0.7

- The controller stick fields are rescaled while the mouse moves, to slow the mouse down.
- In game: no change, because the mouse does not go through those fields.

### v0.6

- `bLoopRestart` is on by default: the engine loop restarts on a second sound with a crossfade, so it lasts as long as
  the ship flies.
- Smaller ship in system view (`SystemShipScale` 0.05).
- The ISACT loop flag of v0.5 is gone.
- The ship's speed is capped (`ClusterMaxSpeed` 1300, `SystemMaxSpeed` 250).
- In game: the sound worked. With the mouse, the hidden cursor and the system view still moved much too fast.

### v0.5

- The ship has its own sky light (`GalaxyMapNormandyShipLight`, lighting channel `Unnamed_6`).
- Turns in system view are twice as fast (`SystemTurnSpeed` 12). `FullSpeed` is 550.
- An ISACT loop flag on the loop's wave.
- New `bLoopRestart` (off by default) restarts the engine loop with a crossfade.
- In game: the ship was much better lit. The loop flag did not make the loop repeat; `bLoopRestart`, switched on live,
  did.

### v0.4

- The cursor ring's mesh is hidden while the ship shows.
- The sound is split as in ME3: a whoosh when the ship starts to fly after a rest of at least 0.6 s, and an engine loop
  that fades in, follows the ship's speed in pitch and volume, and fades out when it stops.
- In game: the loop stopped after about 3 s, the ship looked nearly black, and turns felt rough in system view.

### v0.3

- The code moved into an actor, `GalaxyMapNormandyDirector`, in a small level, `GalaxyMapNormandy_NOR10`, that the LE1
  Community Patch's Sideloader loads with the Normandy. The vanilla galaxy map handler stays, so zooming out of the
  planet view works again. The mod requires the LE1 Community Patch from this version on.
- In game: the ship and its sound showed up at cluster level. The orange ring still showed, and the travel sound
  played as one 2.5 s clip on every small move.

### v0.2

- First script build: a subclass of the galaxy map's handler ran the code every frame.
- In game: zooming out of the planet view stopped working.
