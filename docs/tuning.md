# Tuning

Every value that shapes the ship, its sound and the mouse is a plain property of the `GalaxyMapNormandyDirector`
class. The defaults are in the `defaultproperties` block at the end of
[`src/GalaxyMapNormandyDirector.uc`](../src/GalaxyMapNormandyDirector.uc). To change one for good, edit it there,
run `./build.sh` and apply the mod again with M3 ([building.md](building.md)).

## In-game settings

The Galaxy Map Normandy page of the LE1 Community Patch's Mod Settings Menu multiplies some of the defaults below. The
director reads the multipliers each time the map opens (`ReadSettings`).

| Setting (cluster / system) | Multiplies | Gamer profile key (cluster, system) |
|---|---|---|
| Flight speed | `ClusterFlightSpeed` / `SystemFlightSpeed`, which scale the galaxy camera's `m_fMovementScalar` (the game's own cursor speed, for the controller and the mouse alike; put back when the map closes or shows the galaxy level or a planet), `ClusterMaxSpeed` / `SystemMaxSpeed`, `FullSpeed`, `FlyClusterSpeed` / `FlySystemSpeed` | 8429, 8433 |
| Turn rate | `TurnSpeed` / `SystemTurnSpeed` | 8430, 8434 |
| Ship response | `ChaseSpeed` / `SystemChaseSpeed` | 8431, 8435 |
| Ship size | `ShipScale` / `SystemShipScale` | 8432, 8436 |

A value is stored as a percent in the gamer profile's `IntVariables` list (`PMIndex` = the key, `Value` = the percent;
0 or no entry = 100). `GalaxyMapNormandySettings` reads and writes it, and the menu saves the profile after each change.

## Changing values in a running game

mele-mcp's `live_set` tool writes a property of a live object through `MeleBridge.asi`, so you can try a value with the
map open and see the effect at once. Both come from
[mele-maxgoods-toolkit](https://github.com/Maxgoods62/mele-maxgoods-toolkit). `MeleBridge.asi` has no prebuilt
download; the
[mele-bridge README](https://github.com/Maxgoods62/mele-maxgoods-toolkit/blob/main/tools/mele-bridge/README.md)
shows how to build and install it.

The director is this object while a Normandy level is loaded:

```
GalaxyMapNormandy_NOR10.TheWorld.PersistentLevel.GalaxyMapNormandyDirector_0
```

From an MCP client connected to mele-mcp, call `live_set` with `objectPath` set to that path, `property` to the field
name and `value` to the new value as JSON. From WSL, the toolkit's `mcp_call.py` does the same with the mele-mcp that
`build.sh` built. Run it from this repository's folder (`MELE_DOTNET` can be left out when `dotnet.exe` is on `PATH`):

```bash
MELE_DOTNET='/mnt/c/Program Files/dotnet/dotnet.exe' \
MELE_DLL="$(wslpath -w build/tools/mele-mcp/MeleMcp.dll)" \
python3 -I <toolkit checkout>/tools/mele-mcp/scripts/mcp_call.py live_set \
  '{"objectPath": "GalaxyMapNormandy_NOR10.TheWorld.PersistentLevel.GalaxyMapNormandyDirector_0",
    "property": "MouseStickCluster", "value": 1.5}'
```

`live_get` with the same `objectPath` reads the values back. A struct member takes a property path, such as
`ShipGlow.B`. Booleans are `true` or `false`.

- A live change is lost when the level loads again. The director in the level package has no values of its own, so
  it starts with the class defaults.
- `ShipGlow` and `ShipLightBrightness` are read when the ship is created: the first time the map shows cluster or
  system level after it opens. Close the map and open it again to see a change.
- While its window is out of focus, LE1 stops ticking the world, the director included. A change shows once you click
  back into the game.

## Ship

| Field | Default | What it does |
|---|---|---|
| `ShipScale` | 0.06 | Ship size at cluster level. The ship's draw scale is this value times the cursor ring's draw scale divided by 1.5 (the ring's draw scale at cluster and system level). |
| `SystemShipScale` | 0.0375 | The same in system view, where the planets are smaller next to the cursor than the systems are at cluster level. |
| `YawOffset` | -16384 | Added to the ship's yaw (65536 is a full turn), because the mesh's long axis is Y. |
| `bHideRing` | true | Hides the orange cursor ring's mesh while the ship shows. |
| `ShipGlow` | (R 1.5, G 1.5, B 1.65, A 1.0) | Ambient glow of the ship's light environment. Read when the ship is created. |
| `ShipLightBrightness` | 1.0 | Brightness of the ship's own sky light (`GalaxyMapNormandyShipLight`, lighting channel `Unnamed_6`). Read when the ship is created. |

## Ship motion

The game moves the hidden cursor, for the controller and for the mouse's virtual stick alike, and the ship eases after
it.

| Field | Default | What it does |
|---|---|---|
| `ChaseSpeed` | 10.0 | How fast the ship closes in on the cursor at cluster level (the interpolation speed of `VInterpTo`). |
| `TurnSpeed` | 6.0 | How fast the ship turns toward its motion at cluster level (`RInterpTo`). |
| `SystemChaseSpeed` | 10.0 | `ChaseSpeed` in system view. |
| `SystemTurnSpeed` | 12.0 | `TurnSpeed` in system view. The camera follows the cursor there, so a slow turn shows as the ship swinging around the middle of the screen. |
| `ClusterMaxSpeed` | 1300.0 | Top speed of the ship at cluster level, in units per second. A last guard: the ship never goes faster, whatever moves the cursor. |
| `SystemMaxSpeed` | 250.0 | The same in system view. |
| `ClusterFlightSpeed` | 0.75 | The game's own cursor speed at cluster level, as a fraction of vanilla: it scales the galaxy camera's `m_fMovementScalar` for the controller and the mouse alike, and also the speed caps above, `FullSpeed` and `FlyClusterSpeed`. The Flight speed setting multiplies it. |
| `SystemFlightSpeed` | 0.75 | The same in system view (`SystemMaxSpeed`, `FullSpeed`, `FlySystemSpeed`). |

## Sound

The ship "flies" when its speed goes above `MoveSpeedStart`, and stops flying after `StopDelay` seconds below
`MoveSpeedStop`, so a short wobble neither restarts nor cuts the sound.

| Field | Default | What it does |
|---|---|---|
| `MoveSpeedStart` | 20.0 | Speed (units per second) above which the ship starts to fly: the engine loop starts, and the whoosh if the ship rested for `RestBeforeSound`. |
| `MoveSpeedStop` | 10.0 | Speed below which the ship counts as slow. The ship also turns toward its motion only above this speed. |
| `StopDelay` | 0.15 | Seconds below `MoveSpeedStop` before the flight stops: the loop fades out and the whoosh plays to its end. |
| `RestBeforeSound` | 0.6 | Seconds the ship must rest before a start plays the whoosh again. The loop starts in any case. |
| `LoopFadeIn` | 0.15 | Fade-in of the engine loop, in seconds. |
| `LoopFadeOut` | 0.5 | Fade-out of the engine loop, in seconds. |
| `FullSpeed` | 550.0 | Speed at which the loop reaches `LoopPitchMax` and `LoopVolumeMax`. |
| `LoopPitchMin`, `LoopPitchMax` | 0.95, 1.1 | Pitch of the loop from standstill to `FullSpeed`. |
| `LoopVolumeMin`, `LoopVolumeMax` | 0.75, 1.0 | Volume of the loop from standstill to `FullSpeed`. |
| `bLoopRestart` | true | Restarts the loop on a second audio component and crossfades the two. The game plays the loop's wave only once. |
| `LoopRestartTime` | 2.2 | Seconds of playback before the restart, counted at the loop's current pitch. |
| `LoopCrossfade` | 0.3 | Length of the restart's crossfade, in seconds. |

## Mouse

With `bMousePointer` on (the default), the mouse works as in ME2: an arrow pointer, hold the left button to fly, click
to select. Sizes in pixels are for a 1080-pixel-high screen and scale with the screen's height.

| Field | Default | What it does |
|---|---|---|
| `bMousePointer` | true | The ME2 control with an arrow pointer. When false, the vanilla mouse control stays, slowed by the limiter below. |
| `bTakeLeftButton` | true | Clears the left button's binding at cluster and system level, so that a press does not select at the start of every flight. A click shorter than `ClickTime` selects instead. The binding is restored everywhere else. |
| `ClickTime` | 0.25 | A left-button press shorter than this (seconds) selects the highlighted object. |
| `PointerGain` | 1.0 | Pixels the arrow moves per raw mouse count. At 1 it moves like a desktop pointer without acceleration. |
| `PointerSignX`, `PointerSignY` | 1.0, -1.0 | Direction of each mouse axis on screen; -1 flips it. |
| `PointerSize` | 24.0 | Size of the arrow, in pixels. |
| `PointerMargin` | 8.0 | How close to the screen's edge the arrow can go, in pixels. |
| `PointerFill` | white (255, 255, 255, 255) | Fill colour of the arrow. |
| `PointerOutline` | black (0, 0, 0, 255) | Outline colour of the arrow. |
| `bVirtualStick` | true | While the left button is held, a virtual stick from the ship toward the arrow goes into the game's own cursor control, so the mouse moves the ship as the controller does. When false, the heading model below flies the cursor instead. |
| `StickRadius` | 150.0 | Distance in pixels between the arrow and the hidden cursor (which the ship follows closely) that gives a full stick deflection. The stick is larger further out and smaller closer in, so the ship slows down as it reaches the arrow. |
| `MouseStickCluster` | 1.75 | Largest virtual stick at cluster level; 1 is a full controller deflection. 1.75 is about 1,010 units per second, against about 579 for the full stick. |
| `MouseStickSystem` | 0.85 | Largest virtual stick in system view. |

### Heading model (`bVirtualStick` false)

The nose turns toward the arrow at a limited rate and the ship thrusts along it, so a reversal is a tight U-turn.

| Field | Default | What it does |
|---|---|---|
| `FlyClusterSpeed` | 150.0 | Top speed at cluster level, in units per second. |
| `FlySystemSpeed` | 105.0 | Top speed in system view. |
| `FlyAccelTime` | 0.35 | Seconds from standstill to top speed. |
| `FlyDecelTime` | 0.5 | Seconds from top speed to standstill. The ship also brakes on the way in, to stop on the arrow. |
| `FlyTurnRate` | 440.0 | How fast the nose turns, in degrees per second. |
| `FlyTurnSpeedMin` | 0.6 | Share of the top speed left when the nose points away from the arrow. |

### Limiter (`bMousePointer` false)

The game moves the cursor by the raw mouse counts, which makes it much faster than the controller. The limiter scales
and caps them.

| Field | Default | What it does |
|---|---|---|
| `bLimitMouse` | true | Turns the limiter on. |
| `MouseScale` | 0.4 | Factor on the raw mouse counts. |
| `MouseMaxRate` | 480.0 | Largest mouse movement passed on, in counts per second. |

## Values to read

The director writes these fields itself. `live_get` reads them while a Normandy level is loaded.

| Field | What it holds |
|---|---|
| `TickCount` | Number of times the director has ticked. |
| `LastSpeed` | The ship's speed in the last frame, in units per second. |
| `PeakSpeed` | The highest `LastSpeed` so far. |
| `PeakMouseRate` | The highest raw mouse rate the limiter has seen, in counts per second (only while the limiter runs: `bMousePointer` false and `bLimitMouse` true). |
