# Tuning

The director is the actor that runs the ship, its sound and the mouse while the galaxy map is open. Its class is
`GalaxyMapNormandyDirector`, in [`src/GalaxyMapNormandyDirector.uc`](../src/GalaxyMapNormandyDirector.uc). Every value
on this page is a property of that class, and its default is in the `defaultproperties` block at the end of the file.

You can try a value in a running game, where the change lasts for a while. To keep it, you change its default and
build the mod again. The eight in-game settings work on top of some of these values.

Speeds are in the game's distance units per second. Sizes in pixels are for a screen 1080 pixels high, and they scale
with the height of your screen.

## In-game settings

The Galaxy Map Normandy page of the Mod Settings Menu has four settings for each map level. Each one multiplies a
director value.

| Setting | At cluster level | In system view |
|---|---|---|
| Flight speed | `ClusterFlightSpeed` | `SystemFlightSpeed` |
| Turn rate | `TurnSpeed` | `SystemTurnSpeed` |
| Ship response | `ChaseSpeed` | `SystemChaseSpeed` |
| Ship size | `ShipScale` | `SystemShipScale` |

Each setting is a percent of the default: 50, 75, 100, 125, 150 or 200. The director reads the eight settings once,
each time the map opens. It multiplies a value by its setting whenever it uses the value, and never writes the result
back. So a value you change in a running game still gets the setting on top. [using.md](using.md) shows the settings
pages and says where the game keeps them.

Flight speed reaches further than the other settings. The flight speed value times its setting is the speed scale of
that map level, which the director keeps in `SpeedScale`. The speed scale multiplies the game's own cursor speed, the
galaxy camera's `m_fMovementScalar`. That speed moves the map cursor for the controller and for the mouse. The game
gets its own value back when the map shows the galaxy level or a planet, or closes. The speed scale also multiplies
these values:

- `ClusterMaxSpeed` and `SystemMaxSpeed`, the ship's top speeds.
- `FullSpeed` and `SystemFullSpeed`, the speeds where the flight sound reaches its top pitch and volume.
- `FlyClusterSpeed` and `FlySystemSpeed`, the top speeds of the mouse's heading model.

Turn rate scales the turn of the nose toward the ship's motion. While the mouse flies the ship in the heading model,
the nose turns at `FlyTurnRate` instead, and no setting changes that.

## Try a value in a running game

### What you need

- MeleBridge for LE1 (`MeleBridge.asi`), an ASI mod from the toolkit. It lets tools read and write objects in the
  running game. There is no prebuilt download. The
  [MeleBridge README](https://github.com/Maxgoods62/mele-maxgoods-toolkit/blob/main/tools/mele-bridge/README.md) shows
  how to build it and install it into `Game\ME1\Binaries\Win64\ASI`, with the game closed.
- mele-mcp, the toolkit's MCP server. Its `live_find`, `live_get` and `live_set` tools talk to MeleBridge.
  `./build.sh` builds a copy into `build/tools/mele-mcp`. You call the tools from an MCP client, which is a program
  that calls a server's tools, or from WSL with the toolkit's `mcp_call.py` script.
- The game running, with a save loaded on the Normandy. The LE1 Community Patch's Sideloader loads the director's
  level, `GalaxyMapNormandy_NOR10`, with every level whose name starts with `BIOA_NOR10`.

Both tools come from [mele-maxgoods-toolkit](https://github.com/Maxgoods62/mele-maxgoods-toolkit). Its
[getting started page](https://github.com/Maxgoods62/mele-maxgoods-toolkit/blob/main/docs/getting-started.md) covers
the server, how to register it in a client, and the bridge. The
[mele-mcp README](https://github.com/Maxgoods62/mele-maxgoods-toolkit/blob/main/tools/mele-mcp/README.md#live-objects-melebridge)
lists every live tool.

### Find the director

Call `live_find` with `game` set to `LE1` and `className` set to `GalaxyMapNormandyDirector`. It returns the
director's path:

```
GalaxyMapNormandy_NOR10.TheWorld.PersistentLevel.GalaxyMapNormandyDirector_0
```

### Set a value

Call `live_set` with `game`, `objectPath` (the path above), `property` (the name of the value) and `value` (the new
value as JSON). From WSL, run this in this repository's folder after `./build.sh`. `<toolkit>` is your
mele-maxgoods-toolkit checkout.

```bash
MELE_DLL="$(wslpath -w build/tools/mele-mcp/MeleMcp.dll)" \
python3 -I <toolkit>/tools/mele-mcp/scripts/mcp_call.py live_set \
  '{"game": "LE1",
    "objectPath": "GalaxyMapNormandy_NOR10.TheWorld.PersistentLevel.GalaxyMapNormandyDirector_0",
    "property": "ChaseSpeed", "value": 5.0}'
```

This halves `ChaseSpeed`, so the ship trails further behind the cursor at cluster level. If `dotnet.exe` is not on
your `PATH`, also set `MELE_DOTNET` to the WSL path of the Windows `dotnet.exe`, as in `build.env.example`.

`live_get` with the same `game` and `objectPath` reads every value back. Add `property` to read only one. A part of a
colour takes a path such as `ShipGlow.B`. Booleans are `true` or `false`, and text goes in quotes.

### How long a change lasts

`live_set` changes only the game's memory. Nothing is written to a file.

- A change holds until the Normandy's level loads again, for example when you leave the ship or load a save. The
  director then starts again from its class defaults, because the level gives it no values of its own.
- Each time the map opens, the director reads the settings again. `SetupFlightSound` then sets the sound values for
  the chosen flight sound, which are listed under [Values set when the map opens](#values-set-when-the-map-opens).
  Change those while the map is open. The change lasts until the map closes.
- `ShipGlow` and `ShipLightBrightness` are read when the ship is made. That happens the first time the map shows
  cluster or system level after it opens. Close the map and open it again to see a change.
- Turn `bMousePointer`, `bTakeLeftButton` or `bHideRing` off with the map closed. With the map open, the left button,
  the arrow and the ring keep their old state until the map shows the galaxy level or a planet, or closes.
- While the game window is not in focus, LE1 stops its world, and the director with it. A change shows once you click
  back into the game. The toolkit's `live_keep_ticking` tool stops that pause while it is on, so the world keeps
  running with the game in the background. It is off each time the game starts.

## Make a change permanent

1. Change the value's line in the `defaultproperties` block of `src/GalaxyMapNormandyDirector.uc`.
2. Run `./build.sh`.
3. Install `dist/Galaxy Map Normandy` again with ME3Tweaks Mod Manager (M3), with the game closed.

[building.md](building.md) covers the build and the install.

`build.sh` reads `FlightSound` from its line in `defaultproperties`, and it builds only that variant's sound. Keep that
line as `FlightSound = <number>`: only spaces before it, one space on each side of `=`, and nothing after the number.
Otherwise `build.sh` stops with `no FlightSound in the director's defaultproperties`.

The sound values of variants 1 to 5 are written in the code of `SetupFlightSound`. To change one for good, edit the
variant's branch in that function. `SetupFlightSound` starts each time from the defaults of the engine loop and its
timings, then sets the variant's own values. So those defaults reach the original sound, and `LoopFadeIn` and
`LoopFadeOut` also reach variants 1 and 2. `SetupFlightSound` sets the whoosh and drive values itself, so their lines
in `defaultproperties` have no effect.

## Ship

| Value | Default | Unit | What it does |
|---|---|---|---|
| `ShipScale` | `0.06` | factor | Ship size at cluster level |
| `SystemShipScale` | `0.0375` | factor | Ship size in system view |
| `YawOffset` | `-16384` | rotation units | Turns the mesh so its nose points forward |
| `bHideRing` | `TRUE` | on or off | Hides the orange cursor ring under the ship |
| `ShipGlow` | `{R = 1.5, G = 1.5, B = 1.65, A = 1.0}` | linear colour | Ambient glow on the ship |
| `ShipLightBrightness` | `1.0` | factor | Brightness of the ship's own light |

The ship's draw scale is its size value times the draw scale of the cursor ring, divided by 1.5. The Ship size
setting multiplies the size value. In system view the planets are smaller next to the cursor than the systems are at
cluster level, so the ship is smaller there too.

A full turn is 65536 rotation units, so `-16384` is a quarter turn.

The ship has its own sky light, `GalaxyMapNormandyShipLight`. It sits on a lighting channel that only the ship's mesh
has, so it lights nothing else. `ShipLightBrightness` sets its brightness. `ShipGlow` is the ambient glow of the
ship's light environment, the part of the engine that lights one moving actor. Both are read when the ship is made.

## Ship motion

At cluster level and in system view, the game moves the map cursor for the controller and for the mouse's virtual
stick. The ship chases the cursor and turns toward where it flies.

| Value | Default | Unit | What it does |
|---|---|---|---|
| `ChaseSpeed` | `10.0` | interp speed | How tightly the ship follows the cursor, cluster level |
| `TurnSpeed` | `6.0` | interp speed | How fast the nose turns, cluster level |
| `SystemChaseSpeed` | `10.0` | interp speed | `ChaseSpeed` in system view |
| `SystemTurnSpeed` | `12.0` | interp speed | `TurnSpeed` in system view |
| `ClusterMaxSpeed` | `1300.0` | units/s | Ship top speed, cluster level |
| `SystemMaxSpeed` | `250.0` | units/s | Ship top speed, system view |
| `ClusterFlightSpeed` | `0.5625` | fraction | Game cursor speed, cluster level |
| `SystemFlightSpeed` | `0.75` | fraction | Game cursor speed, system view |

`ChaseSpeed` and `TurnSpeed` are speeds for the engine's `VInterpTo` and `RInterpTo` functions. Each frame, these move
the ship's place or its heading part of the way to the target. A higher value closes the gap faster. The Ship
response and Turn rate settings multiply them. Outside the heading model, the nose only turns while the ship moves
faster than `MoveSpeedStop`.

In system view the camera follows the cursor, so a slow turn shows as the ship swinging around the middle of the
screen. This is why `SystemTurnSpeed` is higher.

The top speeds are a last guard: the ship never flies faster, whatever moves the cursor. The speed scale multiplies
them. `ClusterFlightSpeed` and `SystemFlightSpeed` are fractions of the game's own cursor speed.
[In-game settings](#in-game-settings) says what else they scale.

## Sound

The ship starts to fly when its speed goes above `MoveSpeedStart`. It stops after `StopDelay` seconds below
`MoveSpeedStop`, so a short wobble neither restarts nor cuts the sound. A start plays the whoosh, if the ship has
rested, and starts the loops: the engine, and with variants 1 to 5 the drive too. The loops get higher and louder as
the ship goes faster. When the ship stops, they fade out and the whoosh plays to its end.

### Flight and timing

| Value | Default | Unit | What it does |
|---|---|---|---|
| `FlightSound` | `5` | 0 to 5 | Which flight sound plays |
| `MoveSpeedStart` | `20.0` | units/s | Above it, the ship starts to fly |
| `MoveSpeedStop` | `10.0` | units/s | Below it, the ship counts as slow |
| `StopDelay` | `0.15` | seconds | Time spent slow before the flight stops |
| `RestBeforeSound` | `0.6` | seconds | Rest needed before a start plays the whoosh |
| `FullSpeed` | `550.0` | units/s | Speed where the loops reach their top |
| `FlightSystemFullSpeed` | `120.0` | units/s | Full speed in system view, variants 1 to 5 |
| `bLoopRestart` | `TRUE` | on or off | Restarts each loop with a crossfade |

`FlightSound` 0 is the original sound. Variants 1 to 5 are other mixes of the same travel sound: 1 is the ME3 mix, 2
the ME2 mix, 3 Deep rumble, 4 Soft hum and 5 Bright thrusters. [ASSETS.md](ASSETS.md#flight-sound-variants) describes
them. `build.sh` builds the original sound and the variant that `FlightSound` names, and no other. So a new variant
needs a new build. A live change takes effect the next time the map opens. If you set a variant the build left out,
the director plays the original sound.

The loops start on every start of a flight. The whoosh plays only after the ship has rested for `RestBeforeSound`.
After the map changes level, the first start always plays it.

The loops follow the ship's speed as a share of full speed. The speed scale multiplies `FullSpeed`. In system view,
`SystemFullSpeed` takes its place when it is above 0. Variants 1 to 5 set it to `FlightSystemFullSpeed`, because the
ship flies far slower in system view. They copy it when the map opens, so a live change to `FlightSystemFullSpeed`
shows the next time the map opens. To try a value with the map open, set `SystemFullSpeed`.

LE1's sound engine, ISACT, plays the wave of a loop only once. With `bLoopRestart` on, the director starts the loop
again on a second sound before the end, and crossfades the two.

### Values set when the map opens

Each time the map opens, `SetupFlightSound` sets these values for the chosen flight sound. A live change lasts until
the map closes. The defaults below are the values of the original sound.
[Make a change permanent](#make-a-change-permanent) says which of them the variants keep.

| Value | Default | Unit | What it does |
|---|---|---|---|
| `LoopPitchMin` | `0.95` | factor | Engine pitch at rest |
| `LoopPitchMax` | `1.1` | factor | Engine pitch at full speed |
| `LoopVolumeMin` | `0.75` | factor | Engine volume at rest |
| `LoopVolumeMax` | `1.0` | factor | Engine volume at full speed |
| `LoopCurve` | `0` | 0, 1 or 2 | How the engine rises with speed |
| `LoopFadeIn` | `0.15` | seconds | Fade-in of the loops |
| `LoopFadeOut` | `0.5` | seconds | Fade-out of the loops |
| `LoopRestartTime` | `2.2` | seconds | Play time before a loop restarts |
| `LoopCrossfade` | `0.3` | seconds | Length of a restart's crossfade |
| `SystemFullSpeed` | `0.0` | units/s | Full speed in system view, 0 for `FullSpeed` |
| `Loop2PitchMin` | `1.0` | factor | Drive pitch at rest |
| `Loop2PitchMax` | `1.0` | factor | Drive pitch at full speed |
| `Loop2VolumeMin` | `1.0` | factor | Drive volume at rest |
| `Loop2VolumeMax` | `1.0` | factor | Drive volume at full speed |
| `Loop2Curve` | no line, so `0` | 0, 1 or 2 | How the drive rises with speed |
| `WhooshClusterPitch` | `1.0` | factor | Whoosh pitch, cluster level |
| `WhooshSystemPitch` | `1.0` | factor | Whoosh pitch, system view |
| `WhooshClusterVolume` | `1.0` | factor | Whoosh volume, cluster level |
| `WhooshSystemVolume` | `1.0` | factor | Whoosh volume, system view |

Pitch and volume are multipliers, and 1.0 leaves the sound as it is. The drive plays only with variants 1 to 5.
Variants 1, 2 and 5 have a second drive sound for system view, and variants 3 and 4 play one drive at both levels.

`LoopCurve` and `Loop2Curve` shape the rise of a loop from rest to full speed. 0 is a straight line between the two
multipliers. 1 rises fast and then levels off, like the Log3 curve of Wwise, the sound engine of ME2 and ME3. 2
follows a quarter of a sine wave, like the Sine curve of Wwise. Curves 1 and 2 work on the pitch in cents and on the
volume in decibels, as Wwise does.

`LoopRestartTime` counts the loop's own play time, so a loop at a higher pitch reaches it sooner. The loop waves of
the variants are 16 seconds long, so the variants restart them after 15.5. `LoopFadeOut` also fades the loops and the
whoosh when the map closes.

## Mouse

With `bMousePointer` on, the mouse works as in ME2. An arrow pointer moves freely, holding the left button flies the
ship toward it, and a short click selects.

| Value | Default | Unit | What it does |
|---|---|---|---|
| `bMousePointer` | `TRUE` | on or off | The ME2 control with an arrow pointer |
| `bTakeLeftButton` | `TRUE` | on or off | Frees the left button for flying |
| `ClickTime` | `0.25` | seconds | A shorter press is a click |
| `PointerGain` | `1.0` | pixels per count | Arrow speed |
| `PointerSignX` | `1.0` | 1 or -1 | Direction of the mouse's X axis |
| `PointerSignY` | `-1.0` | 1 or -1 | Direction of the mouse's Y axis |
| `PointerSize` | `24.0` | pixels | Arrow size |
| `PointerMargin` | `8.0` | pixels | Closest the arrow gets to the screen edge |
| `PointerFill` | `{R = 255, G = 255, B = 255, A = 255}` | colour | Arrow fill, white |
| `PointerOutline` | `{R = 0, G = 0, B = 0, A = 255}` | colour | Arrow outline, black |
| `bVirtualStick` | `TRUE` | on or off | Flies through the game's stick control |
| `StickRadius` | `150.0` | pixels | Arrow distance for a full stick |
| `MouseStickCluster` | `1.75` | stick | Largest virtual stick, cluster level |
| `MouseStickSystem` | `0.85` | stick | Largest virtual stick, system view |

With `bMousePointer` off, the mouse control of the normal game stays, slowed down by the
[limiter](#limiter-bmousepointer-off). The Enter Orbit button needs `bMousePointer` on.

In the normal game, a press of the left button selects what is highlighted. That would zoom in at the start of every
flight. With `bTakeLeftButton` on, the director blanks that binding at cluster and system level, and a press shorter
than `ClickTime` selects instead. The binding comes back at the galaxy level and in the planet view, and when the map
closes. It also comes back while another panel, such as the travel prompt, is on top. With `bTakeLeftButton` off,
every press selects.

`PointerGain` 1 moves the arrow one pixel for each raw count from the mouse, like a desktop pointer without
acceleration. The arrow appears on the map cursor when the mouse moves. Moving the controller stick hides it until the
mouse moves again. -1 in `PointerSignX` or `PointerSignY` turns that axis around.

While the left button is held, a virtual stick points from the map cursor toward the arrow. The ship stays close to
the cursor. The game's cursor control then moves the cursor as it does for the controller. With the arrow
`StickRadius` pixels from the cursor, the stick is a full controller stick, 1.0. Further out the stick grows, up to
`MouseStickCluster` or `MouseStickSystem`. Closer in it shrinks, so the ship slows down as it reaches the arrow. The
Flight speed setting scales this too, through the game's cursor speed. With `bVirtualStick` off, the
[heading model](#heading-model-bvirtualstick-off) flies the cursor instead.

### Enter Orbit button

The button sits at the bottom centre of the screen. It shows when the ship is on something the map can enter, as the
controller's A prompt does. It stays hidden while the game shows the controller prompts, and those stay until you
click or press a key. Moving the mouse alone does not end them.

| Value | Default | Unit | What it does |
|---|---|---|---|
| `bEnterButton` | `TRUE` | on or off | Shows the button |
| `ButtonWidth` | `307.0` | pixels | Button width |
| `ButtonHeight` | `49.0` | pixels | Button height |
| `ButtonBottom` | `54.0` | pixels | Gap below the button |
| `ButtonFadeTime` | `0.3` | seconds | Fade to the hover look and back |
| `ButtonTextScale` | `0.5` | factor | Label size |
| `ButtonTextOffset` | `8.0` | pixels | Moves the label right of centre |
| `ButtonText` | `{R = 102, G = 204, B = 255, A = 255}` | colour | Label colour, light blue |
| `ButtonTextHover` | `{R = 255, G = 255, B = 255, A = 255}` | colour | Label colour under the pointer, white |
| `OrbitLabel` | `"Enter Orbit"` | text | Label in system view |
| `SystemLabel` | `"Enter System"` | text | Label at cluster level |
| `ScanLabel` | `"Scan"` | text | Label on something still to scan |

The director turns `bEnterButton` off if the button's textures or its font do not load. It checks this the first
time it makes the ship after the level loads.

A press on the button counts only if you also release it on the button, however long you hold it. A click there does
what the A prompt does. On something still to scan, it scans.

The hover look is the brown and gold panel, and the normal look is blue. The label is drawn with the font
`EngineFonts.LargeFont`, and `ButtonTextScale` scales it. `ButtonTextOffset` moves the label right, away from the
button's cut corner at the bottom left.

The labels hold the English words. In French, German, Italian, Spanish and Polish games, the director replaces them
with that language's words when it first makes the ship after the level loads. Russian and Japanese games keep the
English words, because the font has Latin letters only. So a new default label shows only in English, Russian and
Japanese games.

### Heading model (`bVirtualStick` off)

With `bVirtualStick` off, the director flies the map cursor itself while the left button is held. The nose turns
toward the arrow at a limited rate and the ship thrusts along it, so a reversal is a tight U-turn. It brakes to stop
on the arrow, and it coasts to a stop when you let go.

| Value | Default | Unit | What it does |
|---|---|---|---|
| `FlyClusterSpeed` | `150.0` | units/s | Top speed, cluster level |
| `FlySystemSpeed` | `105.0` | units/s | Top speed, system view |
| `FlyAccelTime` | `0.35` | seconds | From rest to top speed |
| `FlyDecelTime` | `0.5` | seconds | From top speed to rest |
| `FlyTurnRate` | `440.0` | degrees/s | How fast the nose turns |
| `FlyTurnSpeedMin` | `0.6` | fraction | Least share of top speed while turning |

The speed scale multiplies both top speeds. The ship flies slower the further its nose points from the arrow, but
never below `FlyTurnSpeedMin` times its top speed. `FlyDecelTime` also sets how hard the ship brakes on its way to the
arrow. In this model the nose follows the flight heading, so `TurnSpeed` and the Turn rate setting do not apply while
the mouse flies the ship.

### Limiter (`bMousePointer` off)

With `bMousePointer` off, the game moves the cursor by the raw counts from the mouse. That makes the mouse much faster
than the controller. The limiter scales the counts down and caps their rate.

| Value | Default | Unit | What it does |
|---|---|---|---|
| `bLimitMouse` | `TRUE` | on or off | Turns the limiter on |
| `MouseScale` | `0.4` | factor | Factor on the raw mouse counts |
| `MouseMaxRate` | `480.0` | counts/s | Cap on the scaled counts |

## Values to read

The director writes these values itself. `live_get` reads them while the Normandy is loaded, and they start over when
its level loads again.

| Value | What it holds |
|---|---|
| `TickCount` | Frames the director has run |
| `LastSpeed` | Ship speed in the last frame, in units/s, height left out |
| `PeakSpeed` | Highest `LastSpeed` so far |
| `PeakMouseRate` | Highest raw mouse rate the limiter has seen, in counts/s |
| `SpeedScale` | The speed scale of the current map level |
| `ClusterSpeedScale`, `ClusterTurnScale`, `ClusterResponseScale`, `ClusterSizeScale` | The cluster settings as multipliers |
| `SystemSpeedScale`, `SystemTurnScale`, `SystemResponseScale`, `SystemSizeScale` | The system settings as multipliers |
| `bFlying` | `true` while the ship counts as flying |
| `FlySpeed` | Speed of the heading model, in units/s |
| `VirtualStickX`, `VirtualStickY` | The virtual stick before its cap (1 is a full stick) |
| `LoadedFlightSound` | The flight sound now loaded, -1 before the first |

A setting multiplier is the stored percent divided by 100, so 1.0 is 100 %. `PeakSpeed` and `PeakMouseRate` keep
their highest value. Set one to 0 with `live_set` to measure again.
`PeakMouseRate` grows only while the limiter runs, with `bMousePointer` off and `bLimitMouse` on.
