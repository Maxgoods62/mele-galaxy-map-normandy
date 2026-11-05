# Changelog

No version has been released yet. Every version below was a development build, made and installed in the game on
2026-10-28. The version number is `modver` in `mod/moddesc.ini`.

## Unreleased

- v0.26: the ship plays Bright thrusters, the variant the player liked best, and the Flight sound row, its page and
  its strings are gone. The director's `FlightSound` (5) picks the sound, and `build.sh` builds only that variant's
  cues, so the sound package is about 2.8 MB smaller. `flight_sounds.py` still defines all five variants, and the
  original sound is still built as the fallback. In game: not tested yet.
- v0.25: a Flight sound row on the settings page picks one of six ship sounds: the original one (the default) or five
  new ones built from the same three LE3 sounds by `src/sound/flight_sounds.py`. Mass Effect 3 and Mass Effect 2 follow
  those games' own mix, read from their Wwise banks: everything pitched down and filtered, an engine note that rises
  with speed on Wwise's curve, a second loop (the drive) two octaves lower in system view, and for ME2 its short
  reverb. Deep rumble, Soft hum and Bright thrusters are variations on them. LE1 cannot pitch, filter or loop these
  live as Wwise does, so the pitch, filter and reverb are baked into 16 s loop waves and the director plays two loops
  at once with their own pitch and volume curves. Picking a sound plays a 3 to 4 s sample of it. The choice is kept in
  gamer profile slot 108. Every variant cue is built on the same template cue, so `lectool buildsound --unique-wave` gives
  each its own wave, named `<cue>:<template title>`: an LE1 wave is named `<bank>:<title>`, and the game plays the
  sound whose title, in the wave's ISACT content index, is the part after the colon. The first build renamed the waves
  without the colon and every cue was silent, the original sound's too (user, 2026-11-05); the original cues keep the
  template's wave names, as in v0.24. In game, first build (career save, galaxy map in system view):
  the row and the list show, a pick writes the profile file, the map loads the picked sound's cues with its values,
  and a flight starts the whoosh and both loops, all silent. The fixed build works: the player heard the original
  sound and the variants (2026-11-05).
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
  on it does not fly the ship. Its art is LE2's PC button, read from the player's LE2 at build time and recoloured with
  the blue and amber of LE1's Back button, and its words are LE2's own translations. In game: works.
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
- v0.16: the values the player picked in the v0.15 menu are the new defaults, so 100 % in the menu is the old 75 %
  flight speed, 125 % ship response and 75 % ship size, at cluster level and in system view: `ClusterFlightSpeed` and
  `SystemFlightSpeed` 0.75 (new), `ChaseSpeed` and `SystemChaseSpeed` 10, `ShipScale` 0.06, `SystemShipScale` 0.0375.
  Turn rates unchanged.
- v0.15: a Galaxy Map Normandy page in the LE1 Community Patch's Mod Settings Menu. Flight speed, turn rate, ship
  response and ship size, each for cluster level and system view, in steps from 50 % to 200 %, kept in the gamer
  profile for every save. Flight speed scales the galaxy camera's `m_fMovementScalar`, so the controller and the mouse
  speed up alike. In game: the menu works; the player tried several values.
- `build.sh` builds the mod from this repository and the player's own game files. The mod itself does not change: a
  rebuild has the same exports and the same decoded sound as v0.14.
- `moddesc.ini`: a description for players, the LE1 Community Patch 2.0 or later as the required DLC, and this
  repository as the mod site.
- In game: the rebuilt mod works.

## v0.14

- The mouse's virtual stick caps come from live tests: `MouseStickCluster` 1.75, so the ship is faster at cluster
  level, and `MouseStickSystem` 0.85.

## v0.13

- Virtual stick: while the left button is held, the mouse feeds a virtual controller stick, from the ship toward the
  arrow, into the game's own cursor control. The mouse now moves the ship exactly as the controller does.
- The v0.12 heading model stays in the code behind `bVirtualStick`.
- In game: right in system view, too slow at cluster level.

## v0.12

- Heading model: the nose turns toward the arrow at a limited rate (`FlyTurnRate`) and the ship thrusts along it, so a
  reversal is a tight U-turn.
- Smaller ship at cluster level (`ShipScale` 0.08) and a lower cluster speed (`FlyClusterSpeed` 150).
- In game: turns were better, but the mouse still did not feel like the controller.

## v0.11

- The arrow reads the mouse every frame and is kept as a screen position, so it moves smoothly. The vanilla game only
  passes the mouse on when its counts change from one frame to the next.
- In game: almost right in system view. Reversals slid through a stop, and at cluster level the ship was too fast and
  too big.

## v0.10

- While another panel has focus, such as the travel prompt, the arrow is hidden and the left button works as in
  vanilla.
- In game: the travel prompt worked. The arrow felt laggy, and the ship was too fast.

## v0.9

- ME2 mouse control: an arrow pointer; holding the left button flies the cursor toward it; a click shorter than 0.25 s
  selects. The left button's own binding is cleared at cluster and system level.
- In game: the travel prompt could not be clicked.

## v0.8

- The raw mouse counts are scaled (`MouseScale` 0.4) and capped (`MouseMaxRate`) before the game moves the cursor.
- In game: better, but a far target still took several swipes.

## v0.7

- The controller stick fields are rescaled while the mouse moves, to slow the mouse down.
- In game: no change, because the mouse does not go through those fields.

## v0.6

- `bLoopRestart` is on by default: the engine loop restarts on a second sound with a crossfade, so it lasts as long as
  the ship flies.
- Smaller ship in system view (`SystemShipScale` 0.05).
- The ISACT loop flag of v0.5 is gone.
- The ship's speed is capped (`ClusterMaxSpeed` 1300, `SystemMaxSpeed` 250).
- In game: the sound worked. With the mouse, the hidden cursor and the system view still moved much too fast.

## v0.5

- The ship has its own sky light (`GalaxyMapNormandyShipLight`, lighting channel `Unnamed_6`).
- Turns in system view are twice as fast (`SystemTurnSpeed` 12). `FullSpeed` is 550.
- An ISACT loop flag on the loop's wave.
- New `bLoopRestart` (off by default) restarts the engine loop with a crossfade.
- In game: the ship was much better lit. The loop flag did not make the loop repeat; `bLoopRestart`, switched on live,
  did.

## v0.4

- The cursor ring's mesh is hidden while the ship shows.
- The sound is split as in ME3: a whoosh when the ship starts to fly after a rest of at least 0.6 s, and an engine loop
  that fades in, follows the ship's speed in pitch and volume, and fades out when it stops.
- In game: the loop stopped after about 3 s, the ship looked nearly black, and turns felt rough in system view.

## v0.3

- The code moved into an actor, `GalaxyMapNormandyDirector`, in a small level, `GalaxyMapNormandy_NOR10`, that the LE1
  Community Patch's Sideloader loads with the Normandy. The vanilla galaxy map handler stays, so zooming out of the
  planet view works again. The mod requires the LE1 Community Patch from this version on.
- In game: the ship and its sound showed up at cluster level. The orange ring still showed, and the travel sound
  played as one 2.5 s clip on every small move.

## v0.2

- First script build: a subclass of the galaxy map's handler ran the code every frame.
- In game: zooming out of the planet view stopped working.
