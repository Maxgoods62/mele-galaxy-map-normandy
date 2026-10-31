Class GalaxyMapNormandyDirector extends Actor
    placeable;

// Galaxy Map Normandy: while the galaxy map is open, a lit SR-1 follows the map cursor (the orange ring) at cluster and
// system level and turns toward where it flies. Its sound works like ME3's travel_start/travel_stop events: a whoosh
// when it starts to fly, and an engine loop that lasts as long as it flies, then fades out. The ship brings its own
// sky light (GalaxyMapNormandyShipLight): nothing else lights the hub's persistent level out in the map scene.
// One of these sits in GalaxyMapNormandy_NOR10, a level LE1CP's Sideloader loads with the Normandy's levels, so the
// vanilla galaxy map handler stays in place (a handler subclass broke zooming out of the planet view).
// With the mouse it plays like ME2: an arrow pointer moves freely, and holding the left button flies the ship (the map
// cursor) toward it; a short click selects what the ship is on. The pad keeps LE1's own control (UpdatePointer).
// A mouse player also gets ME2's Enter Orbit button when the ship is on something the map can enter (UpdateEnterButton).
// The player can scale speed, turn rate, response and size per level in LE1CP's Mod Settings Menu (ReadSettings).

var transient BioCameraBehaviorGalaxy GalaxyCam;
var transient BioSFHandler_GalaxyMap Handler;
var transient Actor Ring;
var transient DynamicSMActor_Spawnable Ship;
var transient StaticMesh ShipMesh;
var transient SoundCue WhooshCue;
var transient SoundCue LoopCue;
var transient AudioComponent WhooshSound;
var transient AudioComponent LoopSound;
var transient AudioComponent OldLoopSound;
var transient GalaxyMapNormandyShipLight ShipLight;
var transient float LoopAge;
var transient bool bFlying;
var transient float SlowTime;
var transient float PeakSpeed;
var transient Vector LastShipLocation;
var transient float RestTime;
var transient float LastSpeed;
var transient int LastState;
var transient int TickCount;
var transient bool bRingHiddenByUs;
var transient float PeakMouseRate;
var transient bool bPointerActive;
var transient bool bPointerPlaced;
var transient Vector PointerWorld;
var transient float PointerScreenX;
var transient float PointerScreenY;
var transient float VirtualStickX;
var transient float VirtualStickY;
var transient float PendingMouseX;
var transient float PendingMouseY;
var transient Vector FlyHeading;
var transient bool bHeadingSet;
var transient float FlySpeed;
var transient bool bLeftHeld;
var transient float LeftHeldTime;
var transient bool bLeftBindTaken;
var transient string SavedLeftBind;
var transient BioPlayerInput BindInput;
var transient BioHUD PointerHUD;
var transient bool bShowHUDForcedByUs;
var transient bool bSettingsRead;
var transient float ClusterSpeedScale;
var transient float ClusterTurnScale;
var transient float ClusterResponseScale;
var transient float ClusterSizeScale;
var transient float SystemSpeedScale;
var transient float SystemTurnScale;
var transient float SystemResponseScale;
var transient float SystemSizeScale;
var transient float SpeedScale;
var transient bool bMovementScaled;
var transient float VanillaMovementScalar;
var transient Texture2D ButtonNormal;
var transient Texture2D ButtonHover;
var transient Font ButtonFont;
var transient string EnterLabel;
var transient bool bPointerOnButton;
var transient bool bButtonPressed;
var transient float ButtonFade;

// Tuning; all can be changed live on this actor while the map is open.
var float ShipScale;
var float SystemShipScale;
var float ChaseSpeed;
var float TurnSpeed;
var float SystemChaseSpeed;
var float SystemTurnSpeed;
var float ClusterMaxSpeed;
var float SystemMaxSpeed;
var float ClusterFlightSpeed;
var float SystemFlightSpeed;
var int YawOffset;
var float MoveSpeedStart;
var float MoveSpeedStop;
var float StopDelay;
var float RestBeforeSound;
var float LoopFadeIn;
var float LoopFadeOut;
var float FullSpeed;
var float LoopPitchMin;
var float LoopPitchMax;
var float LoopVolumeMin;
var float LoopVolumeMax;
var bool bLoopRestart;
var float LoopRestartTime;
var float LoopCrossfade;
var bool bHideRing;
var LinearColor ShipGlow;
var float ShipLightBrightness;
var bool bLimitMouse;
var float MouseScale;
var float MouseMaxRate;
var bool bMousePointer;
var bool bTakeLeftButton;
var float PointerGain;
var float PointerSignX;
var float PointerSignY;
var float PointerSize;
var float PointerMargin;
var Color PointerFill;
var Color PointerOutline;
var float FlyClusterSpeed;
var float FlySystemSpeed;
var float FlyAccelTime;
var float FlyDecelTime;
var float FlyTurnRate;
var float FlyTurnSpeedMin;
var bool bVirtualStick;
var float StickRadius;
var float MouseStickCluster;
var float MouseStickSystem;
var float ClickTime;
var bool bEnterButton;
var float ButtonWidth;
var float ButtonHeight;
var float ButtonBottom;
var float ButtonFadeTime;
var float ButtonTextScale;
var float ButtonTextOffset;
var Color ButtonText;
var Color ButtonTextHover;
var string OrbitLabel;
var string SystemLabel;
var string ScanLabel;

// After the player controller has read this frame's input, before the camera moves the cursor (LimitMouse).
public event function PostBeginPlay()
{
    Super.PostBeginPlay();
    SetTickGroup(ETickingGroup.TG_PostAsyncWork);
}

public event function Tick(float DeltaTime)
{
    local SFXGameModeGalaxy Mode;
    local Actor NewRing;
    local Vector NewLocation;
    local Vector Velocity;
    local Rotator Facing;
    local Vector Step;
    local float Chase;
    local float Turn;
    local float Scale;
    local float MaxSpeed;

    TickCount++;
    Mode = FindGalaxyMode();
    if (Mode == None || !Mode.bIsActive || Mode.GalaxyCam == None)
    {
        Cleanup();
        return;
    }
    if (GalaxyCam != Mode.GalaxyCam)
    {
        RestoreMovementScalar();
    }
    GalaxyCam = Mode.GalaxyCam;
    if (!bSettingsRead)
    {
        ReadSettings();
    }
    HideLocationMarker();
    NewRing = GalaxyCam.m_pCrossHairObject;
    if (NewRing != Ring)
    {
        ShowRing();
        Ring = NewRing;
    }
    // 1 galaxy, 2 cluster, 3 system, 4 planet; the ship only flies at cluster and system level.
    if (Ring == None || GalaxyCam.m_nCurrentState < 2 || GalaxyCam.m_nCurrentState > 3)
    {
        RestoreMovementScalar();
        ShowRing();
        ReleasePointer();
        if (Ship != None)
        {
            Ship.SetHidden(TRUE);
        }
        StopFlying();
        LastState = GalaxyCam.m_nCurrentState;
        return;
    }
    if (Ship == None && !SpawnShip())
    {
        return;
    }
    HideRing();
    // In system view the camera follows the cursor, so a slow turn shows as the ship swinging around the screen centre;
    // the planets there are also smaller next to the cursor than the systems are at cluster level. The player's settings
    // (ReadSettings) scale each value. Flight speed has no value of its own: ClusterFlightSpeed and SystemFlightSpeed are
    // fractions of the game's cursor speed, and also scale the speed caps and the sound's pitch curve.
    SpeedScale = ClusterFlightSpeed * ClusterSpeedScale;
    Chase = ChaseSpeed * ClusterResponseScale;
    Turn = TurnSpeed * ClusterTurnScale;
    Scale = ShipScale * ClusterSizeScale;
    if (GalaxyCam.m_nCurrentState == 3)
    {
        SpeedScale = SystemFlightSpeed * SystemSpeedScale;
        Chase = SystemChaseSpeed * SystemResponseScale;
        Turn = SystemTurnSpeed * SystemTurnScale;
        Scale = SystemShipScale * SystemSizeScale;
    }
    ScaleMovementScalar(SpeedScale);
    MaxSpeed = ClusterMaxSpeed * SpeedScale;
    if (GalaxyCam.m_nCurrentState == 3)
    {
        MaxSpeed = SystemMaxSpeed * SpeedScale;
    }
    if (bMousePointer)
    {
        UpdatePointer(DeltaTime);
    }
    else
    {
        LimitMouse(DeltaTime);
    }
    Ship.SetDrawScale(Scale * Ring.DrawScale / 1.5);
    if (GalaxyCam.m_nCurrentState != LastState || Ship.bHidden || DeltaTime <= 0.0)
    {
        // New level of the map: start on the cursor instead of flying in from the old scene.
        LastState = GalaxyCam.m_nCurrentState;
        Ship.SetLocation(Ring.Location);
        Ship.SetHidden(FALSE);
        LastShipLocation = Ring.Location;
        RestTime = RestBeforeSound;
        StopFlying();
        return;
    }
    NewLocation = VInterpTo(Ship.Location, Ring.Location, DeltaTime, Chase);
    // A last guard on top of LimitMouse: the ship never outruns these speeds, whatever moves the cursor.
    Step = NewLocation - Ship.Location;
    if (VSize(Step) > MaxSpeed * DeltaTime)
    {
        NewLocation = Ship.Location + Normal(Step) * MaxSpeed * DeltaTime;
    }
    Ship.SetLocation(NewLocation);
    Velocity = (NewLocation - LastShipLocation) / DeltaTime;
    Velocity.Z = 0.0;
    LastShipLocation = NewLocation;
    LastSpeed = VSize(Velocity);
    PeakSpeed = FMax(PeakSpeed, LastSpeed);
    // With the heading model (bVirtualStick off) the nose is the flight heading, which already turns at a limited rate
    // (UpdatePointer); otherwise it eases toward the ship's motion, as with the pad.
    if (bPointerActive && bHeadingSet)
    {
        Facing = Rotator(FlyHeading);
        Facing.Pitch = 0;
        Facing.Roll = 0;
        Facing.Yaw += YawOffset;
        Ship.SetRotation(Facing);
    }
    else if (LastSpeed > MoveSpeedStop)
    {
        Facing = Rotator(Velocity);
        Facing.Pitch = 0;
        Facing.Roll = 0;
        Facing.Yaw += YawOffset;
        Ship.SetRotation(RInterpTo(Ship.Rotation, Facing, DeltaTime, Turn));
    }
    UpdateFlightSound(DeltaTime);
}

// Starts above MoveSpeedStart, stops after StopDelay below MoveSpeedStop: a short wobble neither restarts nor cuts it.
public function UpdateFlightSound(float DeltaTime)
{
    local float Alpha;

    if (!bFlying)
    {
        RestTime += DeltaTime;
        if (LastSpeed > MoveSpeedStart)
        {
            bFlying = TRUE;
            SlowTime = 0.0;
            if (RestTime >= RestBeforeSound)
            {
                PlayCue(WhooshSound, WhooshCue);
            }
            if (PlayCue(LoopSound, LoopCue))
            {
                LoopSound.FadeIn(LoopFadeIn, 1.0);
            }
            LoopAge = 0.0;
        }
        return;
    }
    RestTime = 0.0;
    if (LastSpeed < MoveSpeedStop)
    {
        SlowTime += DeltaTime;
        if (SlowTime >= StopDelay)
        {
            StopFlying();
        }
        return;
    }
    SlowTime = 0.0;
    // Like ME3's speed RTPC: the engine loop gets a little higher and louder as the ship goes faster.
    if (LoopSound != None)
    {
        Alpha = FClamp(LastSpeed / (FullSpeed * SpeedScale), 0.0, 1.0);
        LoopSound.PitchMultiplier = Lerp(LoopPitchMin, LoopPitchMax, Alpha);
        LoopSound.VolumeMultiplier = Lerp(LoopVolumeMin, LoopVolumeMax, Alpha);
        LoopAge += DeltaTime * LoopSound.PitchMultiplier;
        if (bLoopRestart && LoopAge >= LoopRestartTime)
        {
            RestartLoop();
        }
    }
}

// ISACT plays the loop wave once (neither the cue's SoundNodeLooping nor the loop flag of the wave's sound event makes
// it repeat), so start it again on a second component and crossfade.
public function RestartLoop()
{
    local AudioComponent Ending;

    Ending = LoopSound;
    LoopSound = OldLoopSound;
    OldLoopSound = Ending;
    if (OldLoopSound != None)
    {
        OldLoopSound.FadeOut(LoopCrossfade, 0.0);
    }
    if (PlayCue(LoopSound, LoopCue))
    {
        LoopSound.FadeIn(LoopCrossfade, 1.0);
    }
    LoopAge = 0.0;
}

// The engine loop fades out; the whoosh plays out, as with ME3's travel_stop.
public function StopFlying()
{
    if (bFlying && LoopSound != None)
    {
        LoopSound.FadeOut(LoopFadeOut, 0.0);
    }
    bFlying = FALSE;
    SlowTime = 0.0;
}

// The galaxy game mode holds the map camera, and the camera holds the cursor actor (m_pCrossHairObject).
public function SFXGameModeGalaxy FindGalaxyMode()
{
    local BioPlayerController PC;

    PC = BioPlayerController(GetALocalPlayerController());
    if (PC == None || PC.GameModeManager == None || PC.GameModeManager.GameModes.Length <= 9)
    {
        return None;
    }
    return SFXGameModeGalaxy(PC.GameModeManager.GameModes[9]);
}

// The player's settings from LE1CP's Mod Settings Menu (GalaxyMapNormandySettings), read once each time the map opens:
// the menu cannot be open at the same time.
public function ReadSettings()
{
    local Class<GalaxyMapNormandySettings> S;

    S = Class'GalaxyMapNormandySettings';
    ClusterSpeedScale = S.static.GetMultiplier(S.default.ClusterSpeedId);
    ClusterTurnScale = S.static.GetMultiplier(S.default.ClusterTurnId);
    ClusterResponseScale = S.static.GetMultiplier(S.default.ClusterResponseId);
    ClusterSizeScale = S.static.GetMultiplier(S.default.ClusterSizeId);
    SystemSpeedScale = S.static.GetMultiplier(S.default.SystemSpeedId);
    SystemTurnScale = S.static.GetMultiplier(S.default.SystemTurnId);
    SystemResponseScale = S.static.GetMultiplier(S.default.SystemResponseId);
    SystemSizeScale = S.static.GetMultiplier(S.default.SystemSizeId);
    bSettingsRead = TRUE;
}

// The native camera moves the cursor by stick + m_fCursorDelta times m_fMovementScalar, so scaling it speeds up the pad
// and the mouse's virtual stick alike. Only at cluster and system level; the galaxy level keeps its own speed.
public function ScaleMovementScalar(float Multiplier)
{
    if (!bMovementScaled)
    {
        VanillaMovementScalar = GalaxyCam.m_fMovementScalar;
        bMovementScaled = TRUE;
    }
    GalaxyCam.m_fMovementScalar = VanillaMovementScalar * Multiplier;
}

public function RestoreMovementScalar()
{
    if (bMovementScaled && GalaxyCam != None)
    {
        GalaxyCam.m_fMovementScalar = VanillaMovementScalar;
    }
    bMovementScaled = FALSE;
}

// BioPlayerInput.PreProcessInput sends the mouse to the GUI as raw counts (no sensitivity, deadzone or limit), and the
// galaxy handler keeps them in m_fCursorDeltaX/Y until the cursor has moved by them, after the camera update, then clears
// them: a flick moved the cursor and the system camera at 670 units/s against the stick's 110 (observed: 200 counts
// moved the ring 106 units in system view). The pad uses m_fLeftStickX/Y, which this never touches. The director ticks
// in between (TG_PostAsyncWork), so it scales this frame's counts and caps their rate.
public function LimitMouse(float DeltaTime)
{
    local Vector Delta;
    local float MaxCounts;

    if (!bLimitMouse || DeltaTime <= 0.0)
    {
        return;
    }
    if (Handler == None)
    {
        Handler = FindGalaxyHandler(BioPlayerController(GetALocalPlayerController()));
        if (Handler == None)
        {
            return;
        }
    }
    Delta.X = Handler.m_fCursorDeltaX;
    Delta.Y = Handler.m_fCursorDeltaY;
    if (VSize(Delta) <= 0.0)
    {
        return;
    }
    PeakMouseRate = FMax(PeakMouseRate, VSize(Delta) / DeltaTime);
    Delta *= MouseScale;
    MaxCounts = MouseMaxRate * DeltaTime;
    if (VSize(Delta) > MaxCounts)
    {
        Delta = Normal(Delta) * MaxCounts;
    }
    Handler.m_fCursorDeltaX = Delta.X;
    Handler.m_fCursorDeltaY = Delta.Y;
}

// ME2's mouse control. The native camera Tick (after this one) moves the cursor by m_fCursorDeltaX/Y, the raw mouse
// counts, then clears them; this takes the counts for the pointer instead (DrawPointer moves it on screen). While the
// left button is held, a virtual stick toward the pointer goes into m_fCursorDelta, so the cursor moves as with the
// pad (bVirtualStick); with bVirtualStick off, this moves the cursor itself: it turns and flies toward the pointer,
// braking to stop on it, and coasts to a stop once released. The cursor is the ship, as in ME2: selection and the system camera follow it. The
// left button's binding (select what is highlighted, on press) is taken in cluster and system view, and a short click
// selects instead.
// The pad's stick (m_fLeftStickX/Y) is left alone: moving it hands the cursor back to the native control.
public function UpdatePointer(float DeltaTime)
{
    local BioPlayerController PC;
    local BioPlayerInput Input;
    local Vector ToTarget;
    local Vector X;
    local Vector Y;
    local Vector Z;
    local Rotator Nose;
    local float MaxSpeed;
    local float Rate;
    local float Distance;
    local float TargetSpeed;
    local float Heading;
    local float Turn;
    local float MaxTurn;
    local float MaxStick;
    local Vector Stick;
    local bool bHeld;
    local bool bFly;
    local bool bClick;

    PC = BioPlayerController(GetALocalPlayerController());
    if (PC == None || DeltaTime <= 0.0)
    {
        return;
    }
    if (Handler == None)
    {
        Handler = FindGalaxyHandler(PC);
        if (Handler == None)
        {
            return;
        }
    }
    // A message box (the travel prompt) or any other panel on top needs the vanilla left button and no pointer.
    if (!GalaxyPanelHasFocus(PC))
    {
        ReleasePointer();
        return;
    }
    RegisterPointerDraw(PC);
    TakeLeftButton(PC);
    if (GalaxyCam.m_nCurrentState != LastState)
    {
        bPointerPlaced = FALSE;
        bHeadingSet = FALSE;
        FlySpeed = 0.0;
    }
    if (Handler.m_fLeftStickX != 0.0 || Handler.m_fLeftStickY != 0.0)
    {
        bPointerActive = FALSE;
        bHeadingSet = FALSE;
        FlySpeed = 0.0;
    }
    // The pointer reads this frame's raw counts from LastAxisBuffer: the GUI event behind m_fCursorDelta is only sent
    // when the counts differ from the last frame's, so a steady movement (1, 1, 1...) would lose most of its frames.
    Input = BioPlayerInput(PC.PlayerInput);
    if (Input != None && (Input.LastAxisBuffer[4] != 0.0 || Input.LastAxisBuffer[5] != 0.0))
    {
        if (!bPointerActive)
        {
            bPointerActive = TRUE;
            bPointerPlaced = FALSE;
        }
        PendingMouseX += Input.LastAxisBuffer[4];
        PendingMouseY += Input.LastAxisBuffer[5];
    }
    Handler.m_fCursorDeltaX = 0.0;
    Handler.m_fCursorDeltaY = 0.0;
    UpdateEnterButton(DeltaTime);
    bHeld = PC.PlayerInput.PressedKeys.Find('LeftMouseButton') != -1;
    if (bHeld && !bLeftHeld)
    {
        bButtonPressed = bPointerOnButton;
    }
    if (bHeld)
    {
        LeftHeldTime += DeltaTime;
    }
    else if (bLeftHeld)
    {
        // As on any button, a press on it only counts if it is also released on it, however long it took.
        bClick = LeftHeldTime < ClickTime;
        if (bButtonPressed)
        {
            bClick = bPointerOnButton;
        }
        if (bClick && bLeftBindTaken && Handler.oPanel != None)
        {
            Handler.oPanel.InvokeMethod("selectHighlightedGalaxy");
        }
        LeftHeldTime = 0.0;
        bButtonPressed = FALSE;
    }
    bLeftHeld = bHeld;
    bFly = bHeld && !bButtonPressed;
    if (!bPointerActive || !bPointerPlaced || GalaxyCam.m_bPaused || GalaxyCam.m_fZoomTime > 0.0)
    {
        return;
    }
    // The pad's feel comes from the native control plus the ship's chase (ChaseSpeed, TurnSpeed): the cursor answers
    // the stick at once and the ship eases after it. A virtual stick from the ship toward the arrow (DrawPointer) goes
    // through the same path: m_fCursorDelta is added to the stick before the native move.
    if (bVirtualStick)
    {
        if (bFly)
        {
            Stick.X = VirtualStickX;
            Stick.Y = VirtualStickY;
            MaxStick = MouseStickCluster;
            if (GalaxyCam.m_nCurrentState == 3)
            {
                MaxStick = MouseStickSystem;
            }
            if (VSize(Stick) > MaxStick)
            {
                Stick = Normal(Stick) * MaxStick;
            }
            Handler.m_fCursorDeltaX = Stick.X;
            Handler.m_fCursorDeltaY = Stick.Y;
        }
        return;
    }
    MaxSpeed = FlyClusterSpeed * SpeedScale;
    if (GalaxyCam.m_nCurrentState == 3)
    {
        MaxSpeed = FlySystemSpeed * SpeedScale;
    }
    PlaneAxes(X, Y, Z);
    if (!bHeadingSet)
    {
        // Start from where the ship's nose points (the mesh is turned by YawOffset).
        Nose.Yaw = Ship.Rotation.Yaw - YawOffset;
        FlyHeading = Vector(Nose);
        FlyHeading = Normal(FlyHeading - Z * (FlyHeading Dot Z));
        bHeadingSet = TRUE;
    }
    ToTarget = PointerWorld - Ring.Location;
    ToTarget -= Z * (ToTarget Dot Z);
    Distance = VSize(ToTarget);
    TargetSpeed = 0.0;
    if (bFly && Distance > 1.0)
    {
        // ME2's ship: the nose turns toward the pointer at a limited rate and the ship thrusts along it, slower the
        // further off it points, so a reversal is a tight U-turn rather than a slide backwards through a stop.
        Heading = Atan2(FlyHeading Dot Y, FlyHeading Dot X);
        Turn = Atan2(ToTarget Dot Y, ToTarget Dot X) - Heading;
        while (Turn > 3.14159265)
        {
            Turn -= 6.28318531;
        }
        while (Turn < -3.14159265)
        {
            Turn += 6.28318531;
        }
        MaxTurn = FlyTurnRate * 3.14159265 / 180.0 * DeltaTime;
        Heading += FClamp(Turn, -MaxTurn, MaxTurn);
        FlyHeading = X * Cos(Heading) + Y * Sin(Heading);
        // Brake on the way in so the ship stops on the pointer instead of overshooting it.
        TargetSpeed = MaxSpeed * FClamp(FlyHeading Dot Normal(ToTarget), FlyTurnSpeedMin, 1.0);
        TargetSpeed = FMin(TargetSpeed, Sqrt(2.0 * MaxSpeed / FlyDecelTime * Distance));
    }
    Rate = MaxSpeed / FlyDecelTime;
    if (TargetSpeed > FlySpeed)
    {
        Rate = MaxSpeed / FlyAccelTime;
    }
    FlySpeed += FClamp(TargetSpeed - FlySpeed, -Rate * DeltaTime, Rate * DeltaTime);
    if (FlySpeed > 0.0)
    {
        Ring.SetLocation(Ring.Location + FlyHeading * FlySpeed * DeltaTime);
    }
}

// The plane the native control moves the cursor on: the camera's yaw, tilted by the level's planar pitch. Z is its normal.
public function PlaneAxes(out Vector X, out Vector Y, out Vector Z)
{
    local Rotator Plane;

    Plane.Yaw = GalaxyCam.m_pov.Rotation.Yaw;
    Plane.Pitch = int(GalaxyCam.m_fPlanarPitch);
    GetAxes(Plane, X, Y, Z);
}

// Drawn by BioHUD.DrawHUD every frame (after the camera update): moves the pointer by the mouse counts on screen, keeps
// it on screen and draws an arrow there, like a desktop pointer that only the mouse moves. The ship's target is the
// spot under it on the cursor's plane, found again every frame, so it follows the view while the system camera moves.
public function DrawPointer(BioHUD H)
{
    local Canvas C;
    local Vector Screen;
    local Vector Origin;
    local Vector Direction;
    local Vector X;
    local Vector Y;
    local Vector Z;
    local Vector Offset;
    local Vector2D Spot;
    local float Scale;
    local float Denom;
    local float Limit;

    C = H.Canvas;
    if (C != None && EnterLabel != "")
    {
        DrawEnterButton(C);
    }
    if (C == None || GalaxyCam == None || Ring == None || !bPointerActive || GalaxyCam.m_nCurrentState < 2 || GalaxyCam.m_nCurrentState > 3)
    {
        return;
    }
    Scale = float(C.SizeY) / 1080.0;
    // Kept as a fraction of the screen, so a resolution change does not throw it off.
    if (!bPointerPlaced)
    {
        Screen = C.Project(Ring.Location);
        PointerScreenX = Screen.X / float(C.SizeX);
        PointerScreenY = Screen.Y / float(C.SizeY);
        bPointerPlaced = TRUE;
    }
    // PointerGain 1 moves the arrow 1 pixel per raw count at 1080p, as a desktop pointer without acceleration.
    Spot.X = PointerScreenX * float(C.SizeX) + PendingMouseX * PointerGain * PointerSignX * Scale;
    Spot.Y = PointerScreenY * float(C.SizeY) + PendingMouseY * PointerGain * PointerSignY * Scale;
    PendingMouseX = 0.0;
    PendingMouseY = 0.0;
    Spot.X = FClamp(Spot.X, PointerMargin * Scale, float(C.SizeX) - PointerMargin * Scale);
    Spot.Y = FClamp(Spot.Y, PointerMargin * Scale, float(C.SizeY) - PointerMargin * Scale);
    PointerScreenX = Spot.X / float(C.SizeX);
    PointerScreenY = Spot.Y / float(C.SizeY);
    DrawArrow(C, Spot.X, Spot.Y, PointerSize * Scale);
    // The virtual stick: a full pad deflection when the arrow is StickRadius pixels from the ship, more further out (up
    // to MouseStickCluster/System), less closer, so the ship slows into the arrow as with a stick eased back. Screen
    // up is the stick's +Y.
    Screen = C.Project(Ring.Location);
    VirtualStickX = (Spot.X - Screen.X) / (StickRadius * Scale);
    VirtualStickY = (Screen.Y - Spot.Y) / (StickRadius * Scale);
    C.DeProject(Spot, Origin, Direction);
    PlaneAxes(X, Y, Z);
    Denom = Direction Dot Z;
    if (Abs(Denom) > 0.0001)
    {
        PointerWorld = Origin + Direction * (((Ring.Location - Origin) Dot Z) / Denom);
    }
    // The native control keeps the cursor within 1.2 orbit distances of the centre object; so does the target.
    if (GalaxyCam.m_pCenterObject != None && GalaxyCam.m_fMaxOrbitDistance > 0.0)
    {
        Offset = PointerWorld - GalaxyCam.m_pCenterObject.Location;
        Limit = 1.2 * GalaxyCam.m_fMaxOrbitDistance;
        if (VSize(Offset) > Limit)
        {
            PointerWorld = GalaxyCam.m_pCenterObject.Location + Normal(Offset) * Limit;
        }
    }
}

// ME2's Enter Orbit button, for what the pad's A prompt offers. The test is the one native code runs before it obeys A:
// m_pSelectedObject is the object the map cursor is in range of, bStatic or bTickIsDisabled mark one that cannot be
// entered (an asteroid belt), and bHidden one still to be scanned, which a click scans instead (the pad's Y prompt). The
// pad's prompts show while the panel is in gamepad mode, so the button stays away unless the mouse is in use.
public function UpdateEnterButton(float DeltaTime)
{
    local Actor Selected;
    local float Step;

    Selected = GalaxyCam.m_pSelectedObject;
    EnterLabel = "";
    if (bEnterButton && Selected != None && !Selected.bStatic && !Selected.bTickIsDisabled && GalaxyCam.m_fZoomTime == 0.0 && !GalaxyCam.m_bPaused && (bPointerActive || !Handler.oPanel.bUsingGamepad))
    {
        EnterLabel = SystemLabel;
        if (GalaxyCam.m_nCurrentState == 3)
        {
            EnterLabel = OrbitLabel;
        }
        if (Selected.bHidden)
        {
            EnterLabel = ScanLabel;
        }
    }
    if (EnterLabel == "")
    {
        bPointerOnButton = FALSE;
    }
    Step = DeltaTime / ButtonFadeTime;
    if (bPointerOnButton)
    {
        ButtonFade = FMin(ButtonFade + Step, 1.0);
    }
    else
    {
        ButtonFade = FMax(ButtonFade - Step, 0.0);
    }
}

// Drawn before the arrow, so the arrow stays on top; the arrow's own move this frame reaches the hover test next frame.
// As in ME2 the button sits at the bottom centre. It fades from LE1's blue to the brown and gold of LE1's buttons under the
// pointer.
public function DrawEnterButton(Canvas C)
{
    local Font OldFont;
    local float Scale;
    local float X;
    local float Y;
    local float Width;
    local float Height;
    local float PointerX;
    local float PointerY;
    local float TextWidth;
    local float TextHeight;
    local float TextScale;

    Scale = float(C.SizeY) / 1080.0;
    Width = ButtonWidth * Scale;
    Height = ButtonHeight * Scale;
    X = (float(C.SizeX) - Width) / 2.0;
    Y = float(C.SizeY) - (ButtonHeight + ButtonBottom) * Scale;
    PointerX = PointerScreenX * float(C.SizeX);
    PointerY = PointerScreenY * float(C.SizeY);
    bPointerOnButton = bPointerActive && bPointerPlaced && PointerX >= X && PointerX <= X + Width && PointerY >= Y && PointerY <= Y + Height;
    if (ButtonFade < 1.0)
    {
        C.SetDrawColor(255, 255, 255, byte(255.0 * (1.0 - ButtonFade)));
        C.SetPos(X, Y);
        C.DrawTile(ButtonNormal, Width, Height, 0.0, 0.0, float(ButtonNormal.SizeX), float(ButtonNormal.SizeY));
    }
    if (ButtonFade > 0.0)
    {
        C.SetDrawColor(255, 255, 255, byte(255.0 * ButtonFade));
        C.SetPos(X, Y);
        C.DrawTile(ButtonHover, Width, Height, 0.0, 0.0, float(ButtonHover.SizeX), float(ButtonHover.SizeY));
    }
    OldFont = C.Font;
    C.Font = ButtonFont;
    TextScale = ButtonTextScale * Scale;
    C.StrLen(EnterLabel, TextWidth, TextHeight);
    C.DrawColor = ButtonText;
    if (bPointerOnButton)
    {
        C.DrawColor = ButtonTextHover;
    }
    C.SetPos(X + (Width - TextWidth * TextScale) / 2.0 + ButtonTextOffset * Scale, Y + (Height - TextHeight * TextScale) / 2.0);
    C.DrawText(EnterLabel, FALSE, TextScale, TextScale);
    C.Font = OldFont;
}

// The button's words are ME2's own translations. No script call gives the game's language, so its word for the pad's A
// prompt tells. The font behind DrawText has Latin-1 letters only: Polish goes without its accents, and Russian and
// Japanese keep the English default. The compiler writes string literals as ASCII, hence the Chr calls.
public function ReadLabels()
{
    switch (Left(string(stringref(136218)), 4))
    {
        case "Voya":
            OrbitLabel = "Entrer dans l'orbite";
            SystemLabel = "Entrer dans le syst" $ Chr(232) $ "me";
            ScanLabel = "Scanner";
            break;
        case "Reis":
            OrbitLabel = "Umlaufbahn anfliegen";
            SystemLabel = "System anfliegen";
            ScanLabel = "Scannen";
            break;
        case "Viag":
            OrbitLabel = "Entra nell'orbita";
            SystemLabel = "Entra nel sistema";
            ScanLabel = "Scansione";
            break;
        case "Viaj":
            OrbitLabel = "Entrar en " $ Chr(243) $ "rbita";
            SystemLabel = "Entrar en el sistema";
            ScanLabel = "Explorar";
            break;
        case "Podr":
            OrbitLabel = "Wejdz na orbite";
            SystemLabel = "Przejdz do ukladu";
            ScanLabel = "Skanuj";
            break;
        default:
    }
}

// A plain arrow pointer, tip at (X, Y): filled row by row, then outlined.
public function DrawArrow(Canvas C, float X, float Y, float Size)
{
    local float Row;
    local float Right;

    for (Row = 0.0; Row <= Size; Row += 1.0)
    {
        Right = Row;
        if (Row > 0.7 * Size)
        {
            Right = 0.7 * Size * (Size - Row) / (0.3 * Size);
        }
        C.Draw2DLine(X, Y + Row, X + Right, Y + Row, PointerFill);
    }
    C.Draw2DLine(X, Y, X, Y + Size, PointerOutline);
    C.Draw2DLine(X, Y, X + 0.7 * Size, Y + 0.7 * Size, PointerOutline);
    C.Draw2DLine(X + 0.7 * Size, Y + 0.7 * Size, X, Y + Size, PointerOutline);
}

// DrawHUD runs the HUD's debug-draw list only while bShowHUD is set; the map may have it off.
public function RegisterPointerDraw(BioPlayerController PC)
{
    local BioHUD H;

    H = BioHUD(PC.myHUD);
    if (H == None || H == PointerHUD)
    {
        return;
    }
    UnregisterPointerDraw();
    if (!H.IsDrawing(DrawPointer))
    {
        H.ToggleDebugDraw(DrawPointer);
    }
    if (!H.bShowHUD)
    {
        H.bShowHUD = TRUE;
        bShowHUDForcedByUs = TRUE;
    }
    PointerHUD = H;
}

public function UnregisterPointerDraw()
{
    if (PointerHUD != None)
    {
        if (PointerHUD.IsDrawing(DrawPointer))
        {
            PointerHUD.ToggleDebugDraw(DrawPointer);
        }
        if (bShowHUDForcedByUs)
        {
            PointerHUD.bShowHUD = FALSE;
        }
    }
    bShowHUDForcedByUs = FALSE;
    PointerHUD = None;
}

// Pressing the left button selects what is highlighted (the native handler calls selectHighlightedGalaxy), which would
// zoom in at the start of every flight. Its static binding is blanked while the map is at cluster or system level.
public function TakeLeftButton(BioPlayerController PC)
{
    local BioPlayerInput Input;
    local int Idx;

    if (!bTakeLeftButton || bLeftBindTaken)
    {
        return;
    }
    Input = BioPlayerInput(PC.PlayerInput);
    if (Input == None)
    {
        return;
    }
    Idx = Input.StaticPCBinds.Find('Name', 'LeftMouseButton');
    if (Idx == -1)
    {
        return;
    }
    SavedLeftBind = Input.StaticPCBinds[Idx].Command;
    Input.StaticPCBinds[Idx].Command = "";
    BindInput = Input;
    bLeftBindTaken = TRUE;
}

public function RestoreLeftButton()
{
    local int Idx;

    if (bLeftBindTaken && BindInput != None)
    {
        Idx = BindInput.StaticPCBinds.Find('Name', 'LeftMouseButton');
        if (Idx != -1)
        {
            BindInput.StaticPCBinds[Idx].Command = SavedLeftBind;
        }
    }
    bLeftBindTaken = FALSE;
    BindInput = None;
}

public function bool GalaxyPanelHasFocus(BioPlayerController PC)
{
    local BioSFManager Manager;

    Manager = PC.GetScaleFormManager();
    return Manager != None && Handler.oPanel != None && Manager.m_FocusPanel == Handler.oPanel && !Handler.m_bWaitingForMsgBox;
}

// Outside cluster and system view: vanilla left button, no pointer.
public function ReleasePointer()
{
    RestoreLeftButton();
    bPointerActive = FALSE;
    bPointerPlaced = FALSE;
    bLeftHeld = FALSE;
    LeftHeldTime = 0.0;
    PendingMouseX = 0.0;
    PendingMouseY = 0.0;
    bHeadingSet = FALSE;
    FlySpeed = 0.0;
    EnterLabel = "";
    bPointerOnButton = FALSE;
    bButtonPressed = FALSE;
    ButtonFade = 0.0;
}

// The movie's "you are here" marker (ship outline and ring, one clip) makes no sense next to a ship that flies. The movie
// keeps rewriting the clip's _visible and position but never touches its _alpha. The name label is another clip. Each
// opening of the map loads a new movie, so this runs every frame. Keep the oPanel check: SetVariableFloat has no null
// check of its own, and oPanel is what turns None when the game closes the movie.
public function HideLocationMarker()
{
    if (Handler == None)
    {
        Handler = FindGalaxyHandler(BioPlayerController(GetALocalPlayerController()));
        if (Handler == None)
        {
            return;
        }
    }
    if (Handler.oPanel != None)
    {
        Handler.oPanel.SetVariableFloat("_root.LocationShip._alpha", 0.0);
    }
}

// The galaxy map's handler is a script handler of one of the open Scaleform panels.
public function BioSFHandler_GalaxyMap FindGalaxyHandler(BioPlayerController PC)
{
    local BioSFManager Manager;
    local BioSFPanel Panel;
    local BioSFHandler PanelHandler;

    if (PC == None)
    {
        return None;
    }
    Manager = PC.GetScaleFormManager();
    if (Manager == None)
    {
        return None;
    }
    foreach Manager.m_lstPanels(Panel)
    {
        if (Panel == None)
        {
            continue;
        }
        if (BioSFHandler_GalaxyMap(Panel.m_DefaultHandler) != None)
        {
            return BioSFHandler_GalaxyMap(Panel.m_DefaultHandler);
        }
        foreach Panel.ScriptHandlers(PanelHandler)
        {
            if (BioSFHandler_GalaxyMap(PanelHandler) != None)
            {
                return BioSFHandler_GalaxyMap(PanelHandler);
            }
        }
    }
    return None;
}

// Spawned at runtime (not placed) so the ship gets its own light environment, lit by our sky light and the glow.
public function bool SpawnShip()
{
    local LightingChannelContainer Channels;

    if (ShipMesh == None)
    {
        ShipMesh = StaticMesh(DynamicLoadObject("GalaxyMapNormandy_SFX.SR1_Normandy", Class'StaticMesh'));
    }
    if (WhooshCue == None)
    {
        WhooshCue = SoundCue(DynamicLoadObject("GalaxyMapNormandy_SFX.c_travel_whoosh", Class'SoundCue'));
    }
    if (LoopCue == None)
    {
        LoopCue = SoundCue(DynamicLoadObject("GalaxyMapNormandy_SFX.c_travel_loop", Class'SoundCue'));
    }
    if (ButtonFont == None)
    {
        ButtonNormal = Texture2D(DynamicLoadObject("GalaxyMapNormandy_SFX.EnterButton_Normal", Class'Texture2D'));
        ButtonHover = Texture2D(DynamicLoadObject("GalaxyMapNormandy_SFX.EnterButton_Hover", Class'Texture2D'));
        // By name: Engine.GetLargeFont hands back the small font, as the game's ini sets it.
        ButtonFont = Font(DynamicLoadObject("EngineFonts.LargeFont", Class'Font'));
        bEnterButton = bEnterButton && ButtonNormal != None && ButtonHover != None && ButtonFont != None;
        ReadLabels();
    }
    if (ShipMesh == None)
    {
        return FALSE;
    }
    Ship = Spawn(Class'DynamicSMActor_Spawnable', , , Ring.Location, Ring.Rotation, , , TRUE);
    if (Ship == None)
    {
        return FALSE;
    }
    Ship.SetCollision(FALSE, FALSE, FALSE);
    Ship.SetStaticMesh(ShipMesh);
    AttachShipLight();
    Channels = Ship.StaticMeshComponent.LightingChannels;
    Channels.Unnamed_6 = TRUE;
    Ship.StaticMeshComponent.SetLightingChannels(Channels);
    Ship.LightEnvironment.AmbientGlow = ShipGlow;
    Ship.ReattachComponent(Ship.LightEnvironment);
    Ship.SetHidden(TRUE);
    return TRUE;
}

// The light sits on this actor and reaches only the Unnamed_6 lighting channel, which only the ship's mesh has.
public function AttachShipLight()
{
    if (ShipLight == None)
    {
        ShipLight = new (self) Class'GalaxyMapNormandyShipLight';
    }
    if (!ShipLight.bAttached)
    {
        AttachComponent(ShipLight);
    }
    ShipLight.SetLightProperties(ShipLightBrightness);
}

// Plays a cue from the start on its own component (made once and kept: the game reuses AudioComponent names).
public function bool PlayCue(out AudioComponent Sound, SoundCue Cue)
{
    if (Cue == None)
    {
        return FALSE;
    }
    if (Sound == None)
    {
        Sound = CreateAudioComponent(Cue, FALSE, TRUE);
        if (Sound == None)
        {
            return FALSE;
        }
    }
    Sound.Stop();
    Sound.Play();
    return TRUE;
}

// Native code sets the ring actor's bHidden back every frame, so hide its mesh component instead.
public function HideRing()
{
    if (bHideRing && Ring != None && !bRingHiddenByUs)
    {
        SetRingMeshHidden(TRUE);
        bRingHiddenByUs = TRUE;
    }
}

// Only undo our own hiding.
public function ShowRing()
{
    if (Ring != None && bRingHiddenByUs)
    {
        SetRingMeshHidden(FALSE);
    }
    bRingHiddenByUs = FALSE;
}

public function SetRingMeshHidden(bool bNewHidden)
{
    local DynamicSMActor RingMesh;

    RingMesh = DynamicSMActor(Ring);
    if (RingMesh != None && RingMesh.StaticMeshComponent != None)
    {
        RingMesh.StaticMeshComponent.SetHidden(bNewHidden);
    }
}

public function Cleanup()
{
    ShowRing();
    ReleasePointer();
    UnregisterPointerDraw();
    StopFlying();
    if (LoopSound != None)
    {
        LoopSound.Stop();
    }
    if (OldLoopSound != None)
    {
        OldLoopSound.Stop();
    }
    RestoreMovementScalar();
    bSettingsRead = FALSE;
    Ring = None;
    GalaxyCam = None;
    Handler = None;
    if (Ship != None)
    {
        Ship.Destroy();
        Ship = None;
    }
    if (ShipLight != None && ShipLight.bAttached)
    {
        DetachComponent(ShipLight);
    }
}

public event function Destroyed()
{
    Cleanup();
    Super.Destroyed();
}

defaultproperties
{
    ShipScale = 0.06
    SystemShipScale = 0.0375
    ChaseSpeed = 10.0
    TurnSpeed = 6.0
    SystemChaseSpeed = 10.0
    SystemTurnSpeed = 12.0
    ClusterMaxSpeed = 1300.0
    SystemMaxSpeed = 250.0
    ClusterFlightSpeed = 0.75
    SystemFlightSpeed = 0.75
    YawOffset = -16384
    MoveSpeedStart = 20.0
    MoveSpeedStop = 10.0
    StopDelay = 0.15
    RestBeforeSound = 0.6
    LoopFadeIn = 0.15
    LoopFadeOut = 0.5
    FullSpeed = 550.0
    LoopPitchMin = 0.95
    LoopPitchMax = 1.1
    LoopVolumeMin = 0.75
    LoopVolumeMax = 1.0
    bLoopRestart = TRUE
    LoopRestartTime = 2.2
    LoopCrossfade = 0.3
    bHideRing = TRUE
    ShipGlow = {R = 1.5, G = 1.5, B = 1.65, A = 1.0}
    ShipLightBrightness = 1.0
    bLimitMouse = TRUE
    MouseScale = 0.4
    MouseMaxRate = 480.0
    bMousePointer = TRUE
    bTakeLeftButton = TRUE
    PointerGain = 1.0
    PointerSignX = 1.0
    PointerSignY = -1.0
    PointerSize = 24.0
    PointerMargin = 8.0
    PointerFill = {R = 255, G = 255, B = 255, A = 255}
    PointerOutline = {R = 0, G = 0, B = 0, A = 255}
    FlyClusterSpeed = 150.0
    FlySystemSpeed = 105.0
    FlyAccelTime = 0.35
    FlyDecelTime = 0.5
    FlyTurnRate = 440.0
    FlyTurnSpeedMin = 0.6
    bVirtualStick = TRUE
    StickRadius = 150.0
    MouseStickCluster = 1.75
    MouseStickSystem = 0.85
    ClickTime = 0.25
    bEnterButton = TRUE
    ButtonWidth = 307.0
    ButtonHeight = 49.0
    ButtonBottom = 54.0
    ButtonFadeTime = 0.3
    ButtonTextScale = 0.5
    ButtonTextOffset = 8.0
    ButtonText = {R = 102, G = 204, B = 255, A = 255}
    ButtonTextHover = {R = 255, G = 255, B = 255, A = 255}
    OrbitLabel = "Enter Orbit"
    SystemLabel = "Enter System"
    ScanLabel = "Scan"
    SpeedScale = 1.0
    TickGroup = ETickingGroup.TG_PostAsyncWork
}
