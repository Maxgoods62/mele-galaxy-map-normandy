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
// A mouse player also gets ME2's Enter System, Enter Orbit and Scan button when the ship is on something the map can
// enter. It is LE1's own button, the Back button's symbol, put into the map's movie (UpdateEnterButton).
// The player can scale speed, turn rate, response and size per level, and the flight sound volume, in LE1CP's Mod
// Settings Menu (ReadSettings).
// The flight sound is the variant that FlightSound names, or the original sound if that variant does not load. build.sh
// builds only these two (SetupFlightSound, LoadFlightSound).

// The Enter button's clip in the map's movie. SetEnterButton makes every change and the movie calls each one needs.
enum EEnterButtonState
{
    EBS_None,
    EBS_Hidden,
    EBS_FadingOut,
    EBS_Shown,
    EBS_Hover,
    EBS_Shrinking
};

var transient BioCameraBehaviorGalaxy GalaxyCam;
var transient BioSFHandler_GalaxyMap Handler;
var transient Actor Ring;
var transient DynamicSMActor_Spawnable Ship;
var transient StaticMesh ShipMesh;
var transient SoundCue WhooshCue;
var transient SoundCue LoopCue;
var transient SoundCue LoopSystemCue;
var transient SoundCue Loop2Cue;
var transient SoundCue Loop2SystemCue;
var transient SoundCue PlayingLoopCue;
var transient SoundCue PlayingLoop2Cue;
var transient AudioComponent WhooshSound;
var transient AudioComponent OldWhooshSound;
var transient AudioComponent LoopSound;
var transient AudioComponent OldLoopSound;
var transient AudioComponent Loop2Sound;
var transient AudioComponent OldLoop2Sound;
var transient GalaxyMapNormandyShipLight ShipLight;
var transient MaterialInstanceConstant ShipMaterial;
var transient ParticleSystem EngineFX;
var transient array<ParticleSystemComponent> EngineTrails;
var transient float EngineThrust;
var transient float LoopAge;
var transient float Loop2Age;
var transient bool bWhooshPlaying;
// The flight sound: 0 the original sound (v0.24), 1 to 5 the variants of src/sound/flight_sounds.py. build.sh reads
// this value from defaultproperties and builds only that variant's cues.
var int FlightSound;
var transient int LoadedFlightSound;
var transient bool bFlying;
var transient float SlowTime;
var transient float PeakSpeed;
var transient Vector LastShipLocation;
var transient float RestTime;
var transient float LastSpeed;
var transient int LastState;
var transient int SystemWorld;
var transient Actor SystemActor;
var transient bool bCheckZoomEnd;
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
var transient Actor PressSelected;
var transient bool bPressCanSelect;
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
var transient float FlightVolumeScale;
var transient float SpeedScale;
var transient bool bMovementScaled;
var transient float VanillaMovementScalar;
var transient EEnterButtonState EnterState;
var transient BioSFPanel ButtonPanel;
var transient int ButtonAttaches;
var transient float NextAttachTime;
var transient string ShownLabel;
var transient float ButtonWiden;
var transient float ShrinkTime;
var transient float FieldMid;
var transient float FieldScale;
var transient bool bPointerInButtonRect;
var transient bool bHoverSoundDue;
var transient string SystemText;
var transient string OrbitText;
var transient string ScanText;
var transient bool bPointerOnButton;
var transient bool bButtonPressed;

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
var int LoopCurve;
var float SystemFullSpeed;
var float Loop2PitchMin;
var float Loop2PitchMax;
var float Loop2VolumeMin;
var float Loop2VolumeMax;
var int Loop2Curve;
var float WhooshClusterPitch;
var float WhooshSystemPitch;
var float WhooshClusterVolume;
var float WhooshSystemVolume;
var float FlightSystemFullSpeed;
var bool bHideRing;
var LinearColor ShipGlow;
var float ShipLightBrightness;
var bool bEngineTrails;
var array<Vector> EngineNozzles;
var Rotator EngineTrailRotation;
var float EngineTrailScale;
var float EngineTrailLength;
var float EngineGlowRest;
var float EngineGlowFlight;
var float EngineRiseTime;
var float EngineFallTime;
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
// Where the button sits, in the movie's stage units (1280 x 720, shown whole and centred on the screen): ButtonCentreX
// is the middle of the art, ButtonY the top of the clip. ButtonDepth is the clip's depth in the movie, read when the
// clip is attached (each opening of the map): 999000 is under the map's labels and rings, as LE1's own buttons are,
// 1500000 over them. The planet panel (2000000) covers either.
var float ButtonCentreX;
var float ButtonY;
var int ButtonDepth;
// A label wider than ButtonLabelRoom stage units widens the art, up to ButtonMaxWiden times (1 turns it off).
var float ButtonLabelRoom;
var float ButtonMaxWiden;
// At most ButtonAttachTries attaches per opening of the map, ButtonAttachDelay seconds apart; then no button.
var int ButtonAttachTries;
var float ButtonAttachDelay;
// The longest wait, in seconds, for the shrink back from the hover look to end.
var float ButtonShrinkTime;
var string ButtonHoverSound;
// English words for when the mod's strings give nothing; ReadLabels logs it.
var string OrbitLabel;
var string SystemLabel;
var string ScanLabel;
// What the movie holds (GUI_SF_GalaxyMap's GalaxyMap movie, the same in LE1CP): the symbol of LE1's Back button and its
// geometry in the clip's units. backAnim is a fade wrapper (frames fadeIn, solid, fadeOut, invisible) around backBtn
// (normal, grow, mouseOn, shrink, mouseOff...), whose art is ButtonArtWidth x ButtonArtHeight at (ButtonArtLeft,
// ButtonArtTop) from the clip's origin, the art's right edge. Its label is the text field backBtn.buttonText.text,
// $AeroLight 12 in #66ccff, centred; ButtonFieldMid and ButtonFieldScale are its middle in its parent's units and its
// _xscale, read again at each attach. backBtn stops on ButtonMouseOffFrame (_currentframe counts from 1) when its
// shrink ends. ButtonFadeBackFrames gives, for each fadeOut frame (11 to 18), the fadeIn frame with about the same alpha,
// so a fade out turned back fades in from where it was. LE1's clip has _yscale ButtonYScale. Change ButtonSymbol and
// ButtonName with the map closed: a clip attached under the old name would stay in the movie.
var string ButtonSymbol;
var string ButtonName;
var float ButtonArtLeft;
var float ButtonArtTop;
var float ButtonArtWidth;
var float ButtonArtHeight;
var float ButtonYScale;
var float ButtonFieldMid;
var float ButtonFieldScale;
var int ButtonMouseOffFrame;
var array<int> ButtonFadeBackFrames;
var float StageWidth;
var float StageHeight;

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
    UpdateLocationMarker(GalaxyCam.m_nCurrentState);
    if (GalaxyCam.m_nCurrentState == 1)
    {
        SelectCurrentSystem();
    }
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
    // The safety net of SelectCurrentSystem: once the zoom from galaxy level into the Normandy's cluster is over
    // (CheckZoomEnd).
    if (GalaxyCam.m_nCurrentState != LastState)
    {
        bCheckZoomEnd = LastState == 1 && GalaxyCam.m_nCurrentState == 2 && IsNormandyCluster(GalaxyCam.m_pSelectedCluster);
    }
    if (bCheckZoomEnd && GalaxyCam.m_fZoomTime == 0.0)
    {
        bCheckZoomEnd = FALSE;
        CheckZoomEnd();
    }
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
        HideEnterButton(TRUE);
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
        EngineThrust = 0.0;
        UpdateEngines(0.0);
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
    UpdateEngines(DeltaTime);
}

// The engines follow the flight sound: thrust rises to the speed fraction the loops use (SpeedAlpha) while the ship
// flies, and falls to 0 once it stops. It brightens the SR-1's own engine glow (its material's Vfx_engine, which LE1's
// cinematics also use) and lengthens the beam of each engine's trail (the effect's Size parameter, as in ME2).
public function UpdateEngines(float DeltaTime)
{
    local float Target;
    local float Time;
    local Vector Size;
    local int I;

    Target = 0.0;
    if (bFlying)
    {
        Target = SpeedAlpha(GalaxyCam != None && GalaxyCam.m_nCurrentState == 3);
    }
    Time = EngineRiseTime;
    if (Target < EngineThrust)
    {
        Time = EngineFallTime;
    }
    if (Time <= 0.0)
    {
        EngineThrust = Target;
    }
    else
    {
        EngineThrust += FClamp(Target - EngineThrust, -DeltaTime / Time, DeltaTime / Time);
    }
    if (ShipMaterial != None)
    {
        ShipMaterial.SetScalarParameterValue('Vfx_engine', Lerp(EngineGlowRest, EngineGlowFlight, EngineThrust));
    }
    Size.X = 1.0;
    Size.Y = 1.0;
    Size.Z = EngineTrailLength * EngineThrust;
    for (I = 0; I < EngineTrails.Length; I++)
    {
        EngineTrails[I].SetVectorParameter('Size', Size);
    }
}

// ME2's galaxy map Normandy: each engine carries Normandy_Engine_Trails, a blue glow, a hot core and a light beam,
// copied by build.sh from ME3's galaxy map as GalaxyMapNormandy_SFX.EngineTrail. The components sit on the ship, so
// EngineNozzles are in the SR-1 mesh's units and the effect scales with the ship. The ship's material gets its own
// instance so its engine glow can change.
public function SetupEngines()
{
    local ParticleSystemComponent Trail;
    local int I;

    ShipMaterial = Ship.StaticMeshComponent.CreateAndSetMaterialInstanceConstant(0);
    EngineThrust = 0.0;
    EngineTrails.Length = 0;
    if (!bEngineTrails)
    {
        return;
    }
    if (EngineFX == None)
    {
        EngineFX = ParticleSystem(DynamicLoadObject("GalaxyMapNormandy_SFX.EngineTrail", Class'ParticleSystem'));
    }
    if (EngineFX == None)
    {
        return;
    }
    for (I = 0; I < EngineNozzles.Length; I++)
    {
        Trail = new (Ship) Class'ParticleSystemComponent';
        Trail.SetTemplate(EngineFX);
        Trail.SetTranslation(EngineNozzles[I]);
        Trail.SetRotation(EngineTrailRotation);
        Trail.SetScale(EngineTrailScale);
        Ship.AttachComponent(Trail);
        EngineTrails.AddItem(Trail);
    }
}

// Starts above MoveSpeedStart, stops after StopDelay below MoveSpeedStop: a short wobble neither restarts nor cuts it.
// Up to two loops play while the ship flies (the engine, and for the variants also the drive), each with its own
// cue per map level and its own pitch and volume curve on speed (SetupFlightSound).
public function UpdateFlightSound(float DeltaTime)
{
    local float Alpha;
    local bool bSystem;
    local bool bSlow;

    bSystem = GalaxyCam != None && GalaxyCam.m_nCurrentState == 3;
    if (!bFlying)
    {
        RestTime += DeltaTime;
        if (LastSpeed > MoveSpeedStart)
        {
            bFlying = TRUE;
            SlowTime = 0.0;
            if (RestTime >= RestBeforeSound)
            {
                PlayWhoosh(bSystem);
            }
            PlayingLoopCue = LoopCue;
            if (bSystem && LoopSystemCue != None)
            {
                PlayingLoopCue = LoopSystemCue;
            }
            PlayingLoop2Cue = Loop2Cue;
            if (bSystem && Loop2SystemCue != None)
            {
                PlayingLoop2Cue = Loop2SystemCue;
            }
            Alpha = SpeedAlpha(bSystem);
            if (PlayCue(LoopSound, PlayingLoopCue, 1.0, 1.0))
            {
                ShapeLoop(LoopSound, LoopCurve, Alpha, LoopPitchMin, LoopPitchMax, LoopVolumeMin, LoopVolumeMax);
                LoopSound.FadeIn(LoopFadeIn, 1.0);
            }
            if (PlayCue(Loop2Sound, PlayingLoop2Cue, 1.0, 1.0))
            {
                ShapeLoop(Loop2Sound, Loop2Curve, Alpha, Loop2PitchMin, Loop2PitchMax, Loop2VolumeMin, Loop2VolumeMax);
                Loop2Sound.FadeIn(LoopFadeIn, 1.0);
            }
            LoopAge = 0.0;
            Loop2Age = 0.0;
        }
        return;
    }
    RestTime = 0.0;
    bSlow = LastSpeed < MoveSpeedStop;
    if (bSlow)
    {
        SlowTime += DeltaTime;
        if (SlowTime >= StopDelay)
        {
            StopFlying();
            return;
        }
    }
    else
    {
        SlowTime = 0.0;
    }
    // Like ME3's thrust RTPC: the loops get higher and louder as the ship goes faster. While the ship is slow they keep
    // their pitch and volume, but they still play, so their age runs on: a restart left for later would come after the
    // end of the wave.
    Alpha = SpeedAlpha(bSystem);
    if (LoopSound != None && PlayingLoopCue != None)
    {
        if (!bSlow)
        {
            ShapeLoop(LoopSound, LoopCurve, Alpha, LoopPitchMin, LoopPitchMax, LoopVolumeMin, LoopVolumeMax);
        }
        LoopAge += DeltaTime * LoopSound.PitchMultiplier;
        if (bLoopRestart && LoopAge >= LoopRestartTime)
        {
            RestartLoop(LoopSound, OldLoopSound, PlayingLoopCue);
            LoopAge = 0.0;
        }
    }
    if (Loop2Sound != None && PlayingLoop2Cue != None)
    {
        if (!bSlow)
        {
            ShapeLoop(Loop2Sound, Loop2Curve, Alpha, Loop2PitchMin, Loop2PitchMax, Loop2VolumeMin, Loop2VolumeMax);
        }
        Loop2Age += DeltaTime * Loop2Sound.PitchMultiplier;
        if (bLoopRestart && Loop2Age >= LoopRestartTime)
        {
            RestartLoop(Loop2Sound, OldLoop2Sound, PlayingLoop2Cue);
            Loop2Age = 0.0;
        }
    }
}

// Each start plays the whoosh on the other of two components: the last whoosh, maybe still playing after a quick stop
// and start, fades out over LoopFadeOut instead of being cut. A whoosh that has ended keeps that FadeOut until its
// next play, where PlayCue clears it.
public function PlayWhoosh(bool bSystem)
{
    local AudioComponent Ending;
    local float Pitch;
    local float Volume;

    Pitch = WhooshClusterPitch;
    Volume = WhooshClusterVolume;
    if (bSystem)
    {
        Pitch = WhooshSystemPitch;
        Volume = WhooshSystemVolume;
    }
    Volume *= FlightVolumeScale;
    if (WhooshSound != None)
    {
        Ending = WhooshSound;
        WhooshSound = OldWhooshSound;
        OldWhooshSound = Ending;
        OldWhooshSound.FadeOut(LoopFadeOut, 0.0);
    }
    if (PlayCue(WhooshSound, WhooshCue, Pitch, Volume))
    {
        bWhooshPlaying = TRUE;
    }
}

// The ship's speed as a fraction of full speed at this level of the map: what ME2 and ME3 feed their thrust RTPC.
public function float SpeedAlpha(bool bSystem)
{
    local float Full;

    Full = FullSpeed;
    if (bSystem && SystemFullSpeed > 0.0)
    {
        Full = SystemFullSpeed;
    }
    return FClamp(LastSpeed / FMax(Full * SpeedScale, 1.0), 0.0, 1.0);
}

// Curve 0 is a straight line between the multipliers (the original sound). Curves 1 and 2 are Wwise's Log3 and Sine
// curves, run on the pitch in cents and the volume in dB, as Wwise runs an RTPC curve. The player's flight sound volume
// scales the result, never the tuning values, so 0 % gives a gain of 0 (silent) and the curve's log stays defined. LE1
// caps cue volume times component volume at 1.0 per sound. At 140 % Bright thrusters (loop cues 0.5, whoosh 0.678) and
// the original sound (0.5) stay under it; the whoosh of variant 2 reaches it at about 136 % and of variant 3 at 118 %.
public function ShapeLoop(AudioComponent Sound, int Curve, float Alpha, float PitchMin, float PitchMax, float VolumeMin,
    float VolumeMax)
{
    local float T;

    if (Curve == 0)
    {
        Sound.PitchMultiplier = Lerp(PitchMin, PitchMax, Alpha);
        Sound.VolumeMultiplier = Lerp(VolumeMin, VolumeMax, Alpha) * FlightVolumeScale;
        return;
    }
    T = Alpha;
    if (Curve == 1)
    {
        T = 1.0 - (1.0 - Alpha) * (1.0 - Alpha) * (1.0 - Alpha);
    }
    else if (Curve == 2)
    {
        T = Sin(Alpha * 1.5707964);
    }
    Sound.PitchMultiplier = PitchMin * Exp(T * Loge(PitchMax / PitchMin));
    Sound.VolumeMultiplier = VolumeMin * Exp(T * Loge(VolumeMax / VolumeMin)) * FlightVolumeScale;
}

// ISACT plays a loop wave once (neither the cue's SoundNodeLooping nor the loop flag of the wave's sound event makes
// it repeat), so start it again on a second component and crossfade. Ending's VolumeMultiplier already holds the
// player's flight sound volume (ShapeLoop), so it is copied as it is.
public function RestartLoop(out AudioComponent Current, out AudioComponent Old, SoundCue Cue)
{
    local AudioComponent Ending;

    Ending = Current;
    Current = Old;
    Old = Ending;
    if (Old != None)
    {
        Old.FadeOut(LoopCrossfade, 0.0);
    }
    if (PlayCue(Current, Cue, Ending.PitchMultiplier, Ending.VolumeMultiplier))
    {
        Current.FadeIn(LoopCrossfade, 1.0);
    }
}

// The loops fade out; the whoosh plays out, as with ME3's travel_stop.
public function StopFlying()
{
    if (bFlying)
    {
        if (LoopSound != None)
        {
            LoopSound.FadeOut(LoopFadeOut, 0.0);
        }
        if (Loop2Sound != None && PlayingLoop2Cue != None)
        {
            Loop2Sound.FadeOut(LoopFadeOut, 0.0);
        }
    }
    bFlying = FALSE;
    SlowTime = 0.0;
}

// The values of flight sound Variant (FlightSound): 0 is the original sound, the other five are built from ME2's and
// ME3's travel sound by src/sound/flight_sounds.py, whose waves bake in what this cannot do live (pitch, filters,
// reverb). The values here are the live part. Variant 0 takes this class's defaults.
public function SetupFlightSound(int Variant)
{
    WhooshClusterPitch = 1.0;
    WhooshSystemPitch = 1.0;
    WhooshClusterVolume = 1.0;
    WhooshSystemVolume = 1.0;
    LoopPitchMin = default.LoopPitchMin;
    LoopPitchMax = default.LoopPitchMax;
    LoopVolumeMin = default.LoopVolumeMin;
    LoopVolumeMax = default.LoopVolumeMax;
    LoopCurve = default.LoopCurve;
    Loop2PitchMin = 1.0;
    Loop2PitchMax = 1.0;
    Loop2VolumeMin = 1.0;
    Loop2VolumeMax = 1.0;
    Loop2Curve = 0;
    LoopFadeIn = default.LoopFadeIn;
    LoopFadeOut = default.LoopFadeOut;
    LoopRestartTime = default.LoopRestartTime;
    LoopCrossfade = default.LoopCrossfade;
    SystemFullSpeed = default.SystemFullSpeed;
    if (Variant <= 0)
    {
        return;
    }
    // The variants' loop waves are 16 s long.
    LoopRestartTime = 15.5;
    LoopCrossfade = 0.4;
    SystemFullSpeed = FlightSystemFullSpeed;
    if (Variant <= 2)
    {
        // ME3 (1) and ME2 (2): the whoosh's pitch and volume per level (SystemOrCluster RTPC), the engine's pitch
        // -869 to -328 cents and volume -3.4 to +0.1 dB on a Log3 curve, the drive's volume -7.2 to -1.3 dB on a Sine
        // curve (Thrust RTPC). The waves are at full thrust.
        WhooshClusterPitch = 1.2109;
        WhooshSystemPitch = 0.8916;
        WhooshClusterVolume = 0.734;
        WhooshSystemVolume = 0.693;
        LoopPitchMin = 0.7317;
        LoopPitchMax = 1.0;
        LoopVolumeMin = 0.67;
        LoopVolumeMax = 1.0;
        LoopCurve = 1;
        Loop2VolumeMin = 0.511;
        Loop2Curve = 2;
    }
    else if (Variant == 3)
    {
        // Deep rumble: slow to swell and to die away.
        LoopPitchMin = 0.84;
        LoopPitchMax = 1.0;
        LoopVolumeMin = 0.6;
        LoopVolumeMax = 1.0;
        LoopCurve = 1;
        Loop2PitchMin = 0.94;
        Loop2VolumeMin = 0.55;
        Loop2Curve = 2;
        LoopFadeIn = 0.4;
        LoopFadeOut = 1.2;
        LoopCrossfade = 0.5;
    }
    else if (Variant == 4)
    {
        // Soft hum: little change with speed, long fades.
        LoopPitchMin = 0.9;
        LoopPitchMax = 1.0;
        LoopVolumeMin = 0.6;
        LoopVolumeMax = 1.0;
        LoopCurve = 1;
        Loop2VolumeMin = 0.6;
        Loop2Curve = 2;
        LoopFadeIn = 0.7;
        LoopFadeOut = 1.6;
        LoopCrossfade = 0.6;
    }
    else
    {
        // Bright thrusters: a wide sweep with speed, quick fades.
        WhooshSystemPitch = 0.94;
        LoopPitchMin = 0.75;
        LoopPitchMax = 1.04;
        LoopVolumeMin = 0.55;
        LoopVolumeMax = 1.0;
        LoopCurve = 2;
        Loop2PitchMin = 0.9;
        Loop2PitchMax = 1.02;
        Loop2VolumeMin = 0.5;
        Loop2Curve = 2;
        LoopFadeIn = 0.08;
        LoopFadeOut = 0.4;
    }
}

// The cues of FlightSound, loaded once and held here (a cue nobody references is collected about a minute after
// DynamicLoadObject). A variant that does not load falls back to the original sound.
public function LoadFlightSound()
{
    local string Prefix;

    if (LoadedFlightSound == FlightSound && WhooshCue != None && LoopCue != None)
    {
        return;
    }
    LoopSystemCue = None;
    Loop2Cue = None;
    Loop2SystemCue = None;
    if (FlightSound > 0)
    {
        Prefix = "GalaxyMapNormandy_SFX.c_flight" $ string(FlightSound) $ "_";
        WhooshCue = SoundCue(DynamicLoadObject(Prefix $ "whoosh", Class'SoundCue'));
        LoopCue = SoundCue(DynamicLoadObject(Prefix $ "engine", Class'SoundCue'));
        Loop2Cue = SoundCue(DynamicLoadObject(Prefix $ "drive", Class'SoundCue'));
        if (FlightSound != 3 && FlightSound != 4)
        {
            Loop2SystemCue = SoundCue(DynamicLoadObject(Prefix $ "drive_system", Class'SoundCue'));
        }
        if (WhooshCue == None || LoopCue == None || Loop2Cue == None)
        {
            FlightSound = 0;
            SetupFlightSound(0);
            Loop2Cue = None;
            Loop2SystemCue = None;
        }
    }
    if (FlightSound == 0)
    {
        WhooshCue = SoundCue(DynamicLoadObject("GalaxyMapNormandy_SFX.c_travel_whoosh", Class'SoundCue'));
        LoopCue = SoundCue(DynamicLoadObject("GalaxyMapNormandy_SFX.c_travel_loop", Class'SoundCue'));
    }
    LoadedFlightSound = FlightSound;
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
    FlightVolumeScale = float(S.static.GetShownPercent(S.default.FlightVolumeId)) / 100.0;
    SetupFlightSound(FlightSound);
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
// braking to stop on it, and coasts to a stop once released. The cursor is the ship, as in ME2: selection and the
// system camera follow it. The left button's binding (select what is highlighted, on press) is taken in cluster and
// system view, and a short click selects instead. A press on something a click would select may still be a click, so
// there the cursor waits until the press is longer than ClickTime. A quick click then selects that object and the ship
// stays where it is. Anywhere else the ship flies from the first frame of the press.
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
        // What a click would act on: the object the cursor is on when the button goes down, if Select takes it (the
        // Enter button's test). A planet still to be scanned counts, since a click scans it.
        PressSelected = GalaxyCam.m_pSelectedObject;
        bPressCanSelect = PressSelected != None && !PressSelected.bStatic && !PressSelected.bTickIsDisabled;
    }
    if (bHeld)
    {
        // One long frame (a hitch) adds 0.05 s at most, so it cannot turn a quick click into a flight. DeltaTime is the
        // world's frame time. Timing the press with WorldInfo.RealTimeSeconds would not help: a hitch takes real time
        // too.
        LeftHeldTime += FMin(DeltaTime, 0.05);
    }
    else if (bLeftHeld)
    {
        // As on any button, a press on it only counts if it is also released on it, however long it took. Any other
        // click selects only if the cursor is still on what it was on at the press: a press off anything to select
        // flies the ship from its first frame, and the ship may reach an object before the release.
        bClick = LeftHeldTime < ClickTime && GalaxyCam.m_pSelectedObject == PressSelected;
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
        PressSelected = None;
        bPressCanSelect = FALSE;
    }
    bLeftHeld = bHeld;
    bFly = bHeld && !bButtonPressed && (!bPressCanSelect || LeftHeldTime >= ClickTime);
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
// The pointer moves before the Enter button tests it, so a press or release in the next Tick (UpdatePointer) counts
// where the player saw the arrow. The arrow draws over the movie, so over the button too.
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
    local bool bArrow;
    local bool bInRect;

    C = H.Canvas;
    if (C == None)
    {
        return;
    }
    bArrow = GalaxyCam != None && Ring != None && bPointerActive && GalaxyCam.m_nCurrentState >= 2 && GalaxyCam.m_nCurrentState <= 3;
    Scale = float(C.SizeY) / 1080.0;
    if (bArrow)
    {
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
    }
    bInRect = bArrow && bPointerPlaced && EnterState != EEnterButtonState.EBS_None && PointerOnEnterButton(C, Spot.X, Spot.Y);
    if (bInRect && !bPointerInButtonRect)
    {
        bHoverSoundDue = TRUE;
    }
    else if (!bInRect)
    {
        bHoverSoundDue = FALSE;
    }
    bPointerInButtonRect = bInRect;
    bPointerOnButton = bInRect && IsEnterButtonShown();
    if (!bArrow)
    {
        return;
    }
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

// ME2's Enter System, Enter Orbit and Scan button, for what the pad's A and Y prompts offer. The test is the one native
// code runs before it obeys A: m_pSelectedObject is the object the map cursor is in range of, bStatic or bTickIsDisabled
// mark one that cannot be entered (an asteroid belt), and bHidden one still to be scanned, which a click scans instead
// (the pad's Y prompt). The button is LE1's own Back button: its symbol, attached to the map's movie at each opening
// (EnsureEnterButton), brings LE1's art, $AeroLight label, hover look and fades, and sits in the movie's layers, so
// windows on top of the map cover it. It fades out when the ship leaves what it was on. It hides at once while the map
// zooms or is paused, while the panel is in gamepad mode (the pad's prompts show then; a mouse move alone does not end
// that mode, a click or a key does) and whenever the pointer is released (ReleasePointer): another window has the focus
// (the galaxy movie draws over the Mod Settings Menu's background), galaxy level, planet view, where LE1 shows its own
// buttons. Under the arrow it grows to LE1's brown and gold with LE1's hover sound, as the movie's own buttons do, and
// shrinks back once the arrow leaves. DrawPointer tests the arrow against it (bPointerOnButton).
public function UpdateEnterButton(float DeltaTime)
{
    local Actor Selected;
    local string Label;
    local bool bInstant;

    if (!bEnterButton)
    {
        HideEnterButton(TRUE);
        return;
    }
    EnsureEnterButton();
    Selected = GalaxyCam.m_pSelectedObject;
    bInstant = GalaxyCam.m_fZoomTime != 0.0 || GalaxyCam.m_bPaused || Handler.oPanel.bUsingGamepad;
    if (!bInstant && Selected != None && !Selected.bStatic && !Selected.bTickIsDisabled)
    {
        Label = SystemText;
        if (GalaxyCam.m_nCurrentState == 3)
        {
            Label = OrbitText;
        }
        if (Selected.bHidden)
        {
            Label = ScanText;
        }
    }
    if (Label == "" || EnterState == EEnterButtonState.EBS_None)
    {
        HideEnterButton(bInstant);
        return;
    }
    SetEnterLabel(Label);
    if (bPointerOnButton)
    {
        SetEnterButton(EEnterButtonState.EBS_Hover);
    }
    else if (EnterState == EEnterButtonState.EBS_Hover)
    {
        SetEnterButton(EEnterButtonState.EBS_Shrinking);
    }
    else if (EnterState == EEnterButtonState.EBS_Shrinking)
    {
        ShrinkTime += DeltaTime;
        if (ShrinkEnded())
        {
            SetEnterButton(EEnterButtonState.EBS_Shown);
        }
    }
    else
    {
        SetEnterButton(EEnterButtonState.EBS_Shown);
    }
}

// Each opening of the map loads a new movie in a new panel, so the clip is attached again when the panel changes, and
// again if it left the movie under the same panel. Both count against ButtonAttachTries per panel: a movie that refuses
// the clip costs a few calls, then has no button.
public function EnsureEnterButton()
{
    local BioSFPanel Panel;

    Panel = Handler.oPanel;
    if (Panel != ButtonPanel)
    {
        // The old panel is not the map's any more, so this makes no call on it.
        SetEnterButton(EEnterButtonState.EBS_None);
        ButtonPanel = Panel;
        ButtonAttaches = 0;
        NextAttachTime = 0.0;
    }
    if (Panel == None)
    {
        return;
    }
    if (EnterState != EEnterButtonState.EBS_None && !Panel.IsAvailable(ButtonPath()))
    {
        LogInternal("Enter button: " $ ButtonPath() $ " left the map's movie", 'GalaxyMapNormandy');
        SetEnterButton(EEnterButtonState.EBS_None);
    }
    if (EnterState != EEnterButtonState.EBS_None || !Panel.bInitialized || ButtonAttaches >= ButtonAttachTries
        || WorldInfo.RealTimeSeconds < NextAttachTime)
    {
        return;
    }
    ButtonAttaches++;
    NextAttachTime = WorldInfo.RealTimeSeconds + ButtonAttachDelay;
    SetEnterButton(EEnterButtonState.EBS_Hidden);
}

// The one place the button's state changes, with the movie calls of each change. Every call goes to the panel the clip
// was attached to, and only while it is still the map's panel (LiveButtonPanel); without it the state drops to None
// with no call, as the clip went with the movie.
//   None: no clip. From a live panel the clip is hidden first, in case it is still there.
//   Hidden: attached and not drawn. From None it attaches the clip (AttachEnterButton); else _visible off, at once.
//   FadingOut: the wrapper's fadeOut, which stops at alpha 0. From Hidden it stays Hidden.
//   Shown: from Hidden or FadingOut, drawn again with backBtn on its normal frame and the wrapper's fadeIn
//     (ShowEnterButton); from Hover or Shrinking, backBtn on its normal frame.
//   Hover: backBtn's grow (to brown and gold, label to white) and the hover sound; from hidden, shown first.
//   Shrinking: backBtn's shrink, only from Hover. UpdateEnterButton moves it on to Shown when the shrink ends.
public function SetEnterButton(EEnterButtonState NewState)
{
    local BioSFPanel Panel;
    local EEnterButtonState OldState;

    if (NewState == EnterState)
    {
        return;
    }
    OldState = EnterState;
    Panel = LiveButtonPanel();
    if (NewState == EEnterButtonState.EBS_None || Panel == None)
    {
        if (Panel != None && OldState != EEnterButtonState.EBS_Hidden)
        {
            Panel.SetClipVisibility(ButtonPath(), FALSE);
        }
        EnterState = EEnterButtonState.EBS_None;
        ShownLabel = "";
        ButtonWiden = 1.0;
        ShrinkTime = 0.0;
        bPointerOnButton = FALSE;
        return;
    }
    if (OldState == EEnterButtonState.EBS_None)
    {
        if (NewState == EEnterButtonState.EBS_Hidden && AttachEnterButton(Panel))
        {
            EnterState = EEnterButtonState.EBS_Hidden;
        }
        return;
    }
    if (NewState == EEnterButtonState.EBS_Hidden)
    {
        Panel.SetClipVisibility(ButtonPath(), FALSE);
        bPointerOnButton = FALSE;
    }
    else if (NewState == EEnterButtonState.EBS_FadingOut)
    {
        if (OldState == EEnterButtonState.EBS_Hidden)
        {
            return;
        }
        Panel.GotoLabelAndPlay(ButtonPath(), "fadeOut");
        bPointerOnButton = FALSE;
    }
    else if (NewState == EEnterButtonState.EBS_Shown)
    {
        if (OldState == EEnterButtonState.EBS_Hidden || OldState == EEnterButtonState.EBS_FadingOut)
        {
            ShowEnterButton(Panel, OldState);
        }
        else
        {
            Panel.GotoLabelAndStop(ButtonPath() $ ".backBtn", "normal");
            RestoreEnterLabel(Panel);
        }
    }
    else if (NewState == EEnterButtonState.EBS_Hover)
    {
        if (OldState == EEnterButtonState.EBS_Hidden || OldState == EEnterButtonState.EBS_FadingOut)
        {
            ShowEnterButton(Panel, OldState);
        }
        Panel.GotoLabelAndPlay(ButtonPath() $ ".backBtn", "grow");
        // Once per entry of the arrow (DrawPointer): a button that hides and shows again under a still arrow is quiet.
        if (bHoverSoundDue)
        {
            bHoverSoundDue = FALSE;
            Handler.PlayGuiSoundString(ButtonHoverSound);
        }
    }
    else if (NewState == EEnterButtonState.EBS_Shrinking)
    {
        if (OldState != EEnterButtonState.EBS_Hover)
        {
            return;
        }
        Panel.GotoLabelAndPlay(ButtonPath() $ ".backBtn", "shrink");
        ShrinkTime = 0.0;
    }
    EnterState = NewState;
}

// Hidden at once or faded out, if there is a clip at all.
public function HideEnterButton(bool bInstant)
{
    bPointerOnButton = FALSE;
    if (EnterState == EEnterButtonState.EBS_None)
    {
        return;
    }
    if (bInstant)
    {
        SetEnterButton(EEnterButtonState.EBS_Hidden);
    }
    else
    {
        SetEnterButton(EEnterButtonState.EBS_FadingOut);
    }
}

// The panel the clip is in, while it is still the map's: a closed map's panel loses its movie, and Handler.oPanel turns
// None (OnPanelRemoved) or names the next one.
public function BioSFPanel LiveButtonPanel()
{
    if (ButtonPanel == None || Handler == None || Handler.oPanel != ButtonPanel)
    {
        return None;
    }
    return ButtonPanel;
}

public function string ButtonPath()
{
    return "_root." $ ButtonName;
}

public function bool IsEnterButtonShown()
{
    return EnterState == EEnterButtonState.EBS_Shown || EnterState == EEnterButtonState.EBS_Hover
        || EnterState == EEnterButtonState.EBS_Shrinking;
}

// backBtn's shrink stops on its mouseOff frame (ButtonMouseOffFrame), which lacks the normal frame's border, so the
// button then goes back to normal. The wait is capped (ButtonShrinkTime) in case the frame never reads back.
public function bool ShrinkEnded()
{
    local BioSFPanel Panel;

    Panel = LiveButtonPanel();
    return Panel == None || ShrinkTime >= ButtonShrinkTime
        || Panel.GetVariableInt(ButtonPath() $ ".backBtn._currentframe") >= ButtonMouseOffFrame;
}

// _root.attachMovie(ButtonSymbol, ButtonName, ButtonDepth) through the panel. The panel answers '' for a clip (tested
// 2026-11-08), so the attach counts as done when the movie has a clip of that name at that path. The symbol plays its
// own fadeIn, so the clip starts hidden. Nothing in the movie's script knows the clip: LE1's button manager drives only
// the buttons it registered, so the hidden system cursor never hovers it. A clip with a name already in the movie would
// replace that one; ButtonName is the mod's own.
public function bool AttachEnterButton(BioSFPanel Panel)
{
    local array<ASParams> Args;
    local string Field;

    if (ButtonName == "")
    {
        return FALSE;
    }
    Args.Length = 3;
    Args[0].Type = ASParamTypes.ASParam_String;
    Args[0].sVar = ButtonSymbol;
    Args[1].Type = ASParamTypes.ASParam_String;
    Args[1].sVar = ButtonName;
    Args[2].Type = ASParamTypes.ASParam_Integer;
    Args[2].nVar = ButtonDepth;
    Panel.InvokeMethodArgs("_root.attachMovie", Args);
    if (!Panel.IsAvailable(ButtonPath()) || Panel.GetVariableString(ButtonPath() $ "._name") != ButtonName)
    {
        // Whatever the call left at that path goes, so no unplaced clip stays in the movie.
        if (Panel.IsAvailable(ButtonPath()))
        {
            Panel.InvokeMethod(ButtonPath() $ ".removeMovieClip");
        }
        if (ButtonAttaches >= ButtonAttachTries)
        {
            LogInternal("Enter button: _root.attachMovie(" $ ButtonSymbol $ ", " $ ButtonName $ ", " $ ButtonDepth
                $ ") made no clip in " $ ButtonAttaches $ " tries, no button in this map", 'GalaxyMapNormandy');
        }
        return FALSE;
    }
    Panel.SetClipVisibility(ButtonPath(), FALSE);
    // The field's own scale and middle, before autoSize: autoSize keeps the middle where the field has it at each new
    // text, and LayoutEnterLabel puts it back there after any change of scale.
    Field = ButtonPath() $ ".backBtn.buttonText.text";
    FieldScale = Panel.GetVariableFloat(Field $ "._xscale");
    FieldMid = Panel.GetVariableFloat(Field $ "._x") + Panel.GetVariableFloat(Field $ "._width") / 2.0;
    if (FieldScale <= 0.0 || FieldMid <= 0.0)
    {
        FieldScale = ButtonFieldScale;
        FieldMid = ButtonFieldMid;
    }
    Panel.SetVariableString(Field $ ".autoSize", "center");
    ShownLabel = "";
    ButtonWiden = 1.0;
    PlaceEnterButton(Panel);
    LogInternal("Enter button: " $ ButtonPath() $ " attached at depth " $ ButtonDepth $ ", label field middle " $ FieldMid
        $ ", _xscale " $ FieldScale, 'GalaxyMapNormandy');
    return TRUE;
}

// From hidden: placed again (so tunables changed live apply), drawn again, backBtn back to its normal frame, then the
// wrapper's 0.3 s fadeIn, which stops on its solid frame. A fade out still under way turns back from the fadeIn frame
// of about the same alpha (ButtonFadeBackFrames), so a selection that drops for a moment does not make it blink.
public function ShowEnterButton(BioSFPanel Panel, EEnterButtonState OldState)
{
    local array<ASParams> Args;
    local int Frame;

    PlaceEnterButton(Panel);
    Panel.SetClipVisibility(ButtonPath(), TRUE);
    Panel.GotoLabelAndStop(ButtonPath() $ ".backBtn", "normal");
    RestoreEnterLabel(Panel);
    if (OldState == EEnterButtonState.EBS_FadingOut)
    {
        Frame = Panel.GetVariableInt(ButtonPath() $ "._currentframe") - 11;
        if (Frame >= 0 && Frame < ButtonFadeBackFrames.Length)
        {
            Args.Length = 1;
            Args[0].Type = ASParamTypes.ASParam_Integer;
            Args[0].nVar = ButtonFadeBackFrames[Frame];
            Panel.InvokeMethodArgs(ButtonPath() $ ".gotoAndPlay", Args);
            return;
        }
    }
    Panel.GotoLabelAndPlay(ButtonPath(), "fadeIn");
}

// The art's middle on ButtonCentreX, ButtonWiden times as wide.
public function PlaceEnterButton(BioSFPanel Panel)
{
    Panel.SetVariableFloat(ButtonPath() $ "._xscale", 100.0 * ButtonWiden);
    Panel.SetVariableFloat(ButtonPath() $ "._yscale", ButtonYScale);
    Panel.SetClipLocation(ButtonPath(), EnterButtonX(), ButtonY);
}

// The clip's x: its origin is the art's right edge.
public function float EnterButtonX()
{
    return ButtonCentreX - ButtonWiden * (ButtonArtLeft + ButtonArtWidth / 2.0);
}

// Set only when it changes: the movie keeps it while the clip is hidden.
public function SetEnterLabel(string Label)
{
    local BioSFPanel Panel;

    Panel = LiveButtonPanel();
    if (Panel != None && EnterState != EEnterButtonState.EBS_None && Label != ShownLabel)
    {
        LayoutEnterLabel(Panel, Label);
    }
}

// The label goes into the field as plain text, and the field's autoSize fits the field to it. A label wider than
// ButtonLabelRoom (the longest French and German words) widens the whole clip a little through its _xscale; the field
// gets the inverse scale, so the letters keep their shape. Then the field's middle goes back to FieldMid, every time:
// autoSize keeps the middle the field had before the new text, which a change of scale moved. Only our clip and the
// field are scaled: LE1's timelines tween backBtn (the fades) and buttonText (the hover colour), and a clip that script
// moves or scales no longer follows its timeline. textWidth is in the field's own units, _x and _width in its parent's.
public function LayoutEnterLabel(BioSFPanel Panel, string Label)
{
    local string Field;
    local float Width;
    local float Widen;

    Field = ButtonPath() $ ".backBtn.buttonText.text";
    Panel.SetVariableString(Field $ ".text", Label);
    Width = Panel.GetVariableFloat(Field $ ".textWidth") * FieldScale / 100.0;
    Widen = 1.0;
    if (ButtonLabelRoom > 0.0)
    {
        Widen = FClamp(Width / ButtonLabelRoom, 1.0, FMax(ButtonMaxWiden, 1.0));
    }
    Panel.SetVariableFloat(Field $ "._xscale", FieldScale / Widen);
    Panel.SetVariableFloat(Field $ "._x", FieldMid - Panel.GetVariableFloat(Field $ "._width") / 2.0);
    ShownLabel = Label;
    if (Widen != ButtonWiden)
    {
        LogInternal("Enter button: '" $ Label $ "' is " $ Width $ " units wide, art widened " $ Widen $ " times",
            'GalaxyMapNormandy');
        ButtonWiden = Widen;
        PlaceEnterButton(Panel);
    }
}

// After a jump back to backBtn's normal frame. Flash keeps a child that the frame also holds, so the label stays; if
// this movie rebuilt the field instead, it would show the movie's own word, so the label is laid out again.
public function RestoreEnterLabel(BioSFPanel Panel)
{
    if (ShownLabel != "" && Panel.GetVariableString(ButtonPath() $ ".backBtn.buttonText.text.text") != ShownLabel)
    {
        LayoutEnterLabel(Panel, ShownLabel);
    }
}

// Whether the arrow's tip (screen pixels) is on the art. The movie shows its 1280 x 720 stage whole, as large as the
// screen allows and centred (showAll), so the tip goes to stage units first.
public function bool PointerOnEnterButton(Canvas C, float PointerX, float PointerY)
{
    local float Scale;
    local float StageX;
    local float StageY;
    local float Left;
    local float Top;

    Scale = FMin(float(C.SizeX) / StageWidth, float(C.SizeY) / StageHeight);
    if (Scale <= 0.0)
    {
        return FALSE;
    }
    StageX = (PointerX - (float(C.SizeX) - StageWidth * Scale) / 2.0) / Scale;
    StageY = (PointerY - (float(C.SizeY) - StageHeight * Scale) / 2.0) / Scale;
    Left = EnterButtonX() + ButtonWiden * ButtonArtLeft;
    Top = ButtonY + ButtonYScale / 100.0 * ButtonArtTop;
    return StageX >= Left && StageX <= Left + ButtonWiden * ButtonArtWidth && StageY >= Top
        && StageY <= Top + ButtonYScale / 100.0 * ButtonArtHeight;
}

// The button's words are Mass Effect 2's own, from the mod's strings (src/tlk), so the game's language picks them and
// the movie's font draws every one of them. An empty string gets the English default, and the log says so.
public function ReadLabels()
{
    SystemText = string($74220025);
    OrbitText = string($74220026);
    ScanText = string($74220027);
    if (SystemText == "" || OrbitText == "" || ScanText == "")
    {
        LogInternal("Enter button: strings 74220025-74220027 gave '" $ SystemText $ "', '" $ OrbitText $ "', '"
            $ ScanText $ "': English stands in for each empty one", 'GalaxyMapNormandy');
    }
    if (SystemText == "")
    {
        SystemText = SystemLabel;
    }
    if (OrbitText == "")
    {
        OrbitText = OrbitLabel;
    }
    if (ScanText == "")
    {
        ScanText = ScanLabel;
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
    PressSelected = None;
    bPressCanSelect = FALSE;
    PendingMouseX = 0.0;
    PendingMouseY = 0.0;
    bHeadingSet = FALSE;
    FlySpeed = 0.0;
    bButtonPressed = FALSE;
    bPointerInButtonRect = FALSE;
    bHoverSoundDue = FALSE;
    HideEnterButton(TRUE);
}

// The movie's "you are here" marker (ship outline and ring, one clip) makes no sense next to a ship that flies, so it is
// hidden at cluster and system level (MapState 2 and 3) and shown at galaxy level and in planet view, as in the normal
// game. The movie keeps rewriting the clip's _visible and position but never touches its _alpha (100 in a new movie). The
// name label is another clip. Each opening of the map loads a new movie, so this runs every frame. Keep the oPanel check:
// SetVariableFloat has no null check of its own, and oPanel is what turns None when the game closes the movie.
public function UpdateLocationMarker(int MapState)
{
    local float Alpha;

    if (Handler == None)
    {
        Handler = FindGalaxyHandler(BioPlayerController(GetALocalPlayerController()));
        if (Handler == None)
        {
            return;
        }
    }
    Alpha = 100.0;
    if (MapState == 2 || MapState == 3)
    {
        Alpha = 0.0;
    }
    if (Handler.oPanel != None)
    {
        Handler.oPanel.SetVariableFloat("_root.LocationShip._alpha", Alpha);
    }
}

// Zooming in from galaxy level, the game aims the zoom and puts the cursor on m_pSelectedSystem, or on the cluster's first
// system when it is None, as it is at galaxy level. The ship starts on the cursor, so it showed on the first system even
// when the Normandy was at another one of that cluster. While the cluster that holds the Normandy is highlighted at galaxy
// level, this sets m_pSelectedSystem to the Normandy's system, so the game zooms to it; on any other cluster it is None
// again. The game lays the cluster out, then reads the system actor's location, so the actor has to be one of that
// cluster's: one of another cluster stays hidden at the origin, and the zoom flew there (Exodus Cluster, 2026-11-07, when
// the tag alone picked Strenuus' actor for Asgard). Tested live (2026-11-07): set by hand at galaxy level, the zoom flew
// to Strenuus, not Pax; with Strenuus' actor moved 170 units off at galaxy level, the zoom still flew to Strenuus.
public function SelectCurrentSystem()
{
    local Actor Wanted;

    if (IsNormandyCluster(GalaxyCam.m_pSelectedObject))
    {
        Wanted = SystemActor;
    }
    if (GalaxyCam.m_pSelectedSystem != Wanted)
    {
        GalaxyCam.m_pSelectedSystem = Wanted;
    }
}

// Whether Cluster is the map's actor of the cluster that holds the Normandy. Also brings SystemActor up to date: it is
// kept for one Active_World, and Cleanup clears them with the map level whose actors they hold.
public function bool IsNormandyCluster(Actor Cluster)
{
    local BioWorldInfo BioWorld;
    local int ActiveWorld;

    BioWorld = BioWorldInfo(WorldInfo);
    if (Cluster == None || BioWorld == None || BioWorld.GetGlobalVariables() == None)
    {
        return FALSE;
    }
    ActiveWorld = BioWorld.GetGlobalVariables().GetInt(13);
    if (!(string(Cluster.Tag) ~= ("Cluster" $ TwoDigits(ActiveWorld / 10000))))
    {
        return FALSE;
    }
    if (ActiveWorld != SystemWorld)
    {
        SystemWorld = ActiveWorld;
        SystemActor = None;
        FindSystem(ActiveWorld);
    }
    return TRUE;
}

// Plot int 13 (Active_World) is cluster * 10000 + system * 100 + planet. Those numbers are the Label of the cluster row
// (Cluster08) and of the system row (System02) in the galaxy map tables, which hold the DLC rows too (Asgard, row 2009,
// is Exodus Cluster's System02). The system row names its actor: an InterpActor of the map level named after the row's
// Name string id (Strenuus 135810, a DLC one may carry a suffix, 176126_243) and tagged with its Label. Sets SystemActor,
// or leaves it None.
public function FindSystem(int ActiveWorld)
{
    local Bio2DA Clusters;
    local Bio2DA Systems;
    local string RowClusterLabel;
    local string RowSystemLabel;
    local string ActorName;
    local name Label;
    local int ClusterRow;
    local int Row;
    local int Cluster;
    local int NameRef;
    local InterpActor SystemItem;

    Clusters = GalaxyCam.m_pClusterTable;
    Systems = GalaxyCam.m_pSystemTable;
    if (Clusters == None || Systems == None || (ActiveWorld / 100) % 100 == 0)
    {
        return;
    }
    RowClusterLabel = "Cluster" $ TwoDigits(ActiveWorld / 10000);
    RowSystemLabel = "System" $ TwoDigits((ActiveWorld / 100) % 100);
    ClusterRow = -1;
    for (Row = 0; Row < Clusters.GetNumRows(); Row++)
    {
        if (Clusters.GetNameEntryIN(Row, 'Label', Label) && string(Label) ~= RowClusterLabel)
        {
            ClusterRow = Clusters.GetRowNumber(Row);
            break;
        }
    }
    for (Row = 0; ClusterRow >= 0 && Row < Systems.GetNumRows(); Row++)
    {
        if (Systems.GetNameEntryIN(Row, 'Label', Label) && string(Label) ~= RowSystemLabel
            && Systems.GetIntEntryIN(Row, 'Cluster', Cluster) && Cluster == ClusterRow)
        {
            if (!Systems.GetIntEntryIN(Row, 'Name', NameRef))
            {
                return;
            }
            break;
        }
    }
    if (ClusterRow < 0 || Row >= Systems.GetNumRows())
    {
        return;
    }
    foreach DynamicActors(Class'InterpActor', SystemItem)
    {
        ActorName = string(SystemItem.Name);
        if (string(SystemItem.Tag) ~= RowSystemLabel && (ActorName == string(NameRef) || Left(ActorName, Len(string(NameRef)) + 1) == (string(NameRef) $ "_")))
        {
            SystemActor = SystemItem;
            return;
        }
    }
}

// After a zoom into the Normandy's cluster, the cursor must sit on the Normandy's system, where the game laid it out. It
// does not when SelectCurrentSystem found no system (the game zoomed to the first one), when the layout put the system
// somewhere else (a map changed by another mod), or when the game did not use m_pSelectedSystem.
// Then the cursor and the ship go to the system at once, and the camera pans to it, as it follows the cursor: the first
// fix of this bug, which works whatever the game did. Tested live (2026-11-07) with SystemActor cleared at galaxy level:
// the zoom went to Pax, then the cursor and the ship moved to Strenuus. Without FindSystem's actor, the system is the one actor of the laid
// out cluster with its tag (System02): the other clusters' systems wait hidden. A hidden system is not a place to go to.
public function CheckZoomEnd()
{
    local Actor Wanted;
    local InterpActor Item;

    Wanted = SystemActor;
    if ((Wanted == None || Wanted.bHidden) && (SystemWorld / 100) % 100 != 0)
    {
        Wanted = None;
        foreach DynamicActors(Class'InterpActor', Item)
        {
            if (!Item.bHidden && string(Item.Tag) ~= ("System" $ TwoDigits((SystemWorld / 100) % 100)))
            {
                Wanted = Item;
                break;
            }
        }
    }
    if (Wanted == None || Wanted.bHidden || VSize(Ring.Location - Wanted.Location) <= 1.0)
    {
        return;
    }
    LogInternal("Zoom ended " $ VSize(Ring.Location - Wanted.Location) $ " units from the Normandy's system " $ Wanted.Name
        $ " (Active_World " $ SystemWorld $ "), cursor moved there", 'GalaxyMapNormandy');
    Ring.SetLocation(Wanted.Location);
    bPointerPlaced = FALSE;
    if (Ship != None)
    {
        Ship.SetLocation(Wanted.Location);
        LastShipLocation = Wanted.Location;
    }
}

public function string TwoDigits(int Number)
{
    if (Number < 10)
    {
        return "0" $ string(Number);
    }
    return string(Number);
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
    LoadFlightSound();
    ReadLabels();
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
    SetupEngines();
    UpdateEngines(0.0);
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
public function bool PlayCue(out AudioComponent Sound, SoundCue Cue, float Pitch, float Volume)
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
    // Play keeps the fade of a FadeOut called while the component was stopped (a whoosh that had ended, faded by
    // PlayWhoosh or Cleanup): the new sound fades from its first frame and stops at the fade's end, which a 0.4 s fade
    // makes silent. Only a Stop that ends a fade clears it, so clear it here (proven live, 2026-11-06).
    Sound.FadeInStartTime = 0.0;
    Sound.FadeInStopTime = -1.0;
    Sound.FadeInTargetVolume = 1.0;
    Sound.FadeOutStartTime = 0.0;
    Sound.FadeOutStopTime = -1.0;
    Sound.FadeOutTargetVolume = 1.0;
    Sound.SoundCue = Cue;
    Sound.PitchMultiplier = Pitch;
    Sound.VolumeMultiplier = Volume;
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
    // The button drops to None, which hides the clip only while its panel is still the map's (LiveButtonPanel): once the
    // map is closed, the movie and the clip are gone and no call is made. Then the panel is forgotten.
    SetEnterButton(EEnterButtonState.EBS_None);
    ButtonPanel = None;
    ShowRing();
    ReleasePointer();
    UnregisterPointerDraw();
    // The loops fade out as when the ship stops (StopFlying fades only what still flies, so it can run every tick). The
    // whoosh fades too, once per play: Cleanup runs every tick while the map is closed, and a FadeOut called again
    // starts over from full volume. The whoosh before it already fades (PlayWhoosh).
    StopFlying();
    if (bWhooshPlaying)
    {
        bWhooshPlaying = FALSE;
        WhooshSound.FadeOut(LoopFadeOut, 0.0);
    }
    RestoreMovementScalar();
    bSettingsRead = FALSE;
    SystemWorld = 0;
    SystemActor = None;
    bCheckZoomEnd = FALSE;
    Ring = None;
    GalaxyCam = None;
    Handler = None;
    if (Ship != None)
    {
        Ship.Destroy();
        Ship = None;
    }
    EngineTrails.Length = 0;
    ShipMaterial = None;
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
    ClusterFlightSpeed = 0.5625
    SystemFlightSpeed = 0.75
    YawOffset = -16384
    MoveSpeedStart = 20.0
    MoveSpeedStop = 10.0
    StopDelay = 0.15
    RestBeforeSound = 0.0
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
    LoopCurve = 0
    SystemFullSpeed = 0.0
    FlightSystemFullSpeed = 120.0
    WhooshClusterPitch = 1.0
    WhooshSystemPitch = 1.0
    WhooshClusterVolume = 1.0
    WhooshSystemVolume = 1.0
    FlightVolumeScale = 1.0
    Loop2PitchMin = 1.0
    Loop2PitchMax = 1.0
    Loop2VolumeMin = 1.0
    Loop2VolumeMax = 1.0
    FlightSound = 5
    LoadedFlightSound = -1
    bHideRing = TRUE
    ShipGlow = {R = 1.5, G = 1.5, B = 1.65, A = 1.0}
    ShipLightBrightness = 1.0
    bEngineTrails = TRUE
    EngineNozzles = ({X = 19.3, Y = -166.0, Z = 48.1}, {X = -19.3, Y = -166.0, Z = 48.1}, {X = 38.4, Y = -166.0, Z = 35.9}, {X = -38.4, Y = -166.0, Z = 35.9})
    EngineTrailRotation = {Pitch = 0, Yaw = 16384, Roll = 0}
    EngineTrailScale = 1.5
    EngineTrailLength = 1.0
    EngineGlowRest = 1.0
    EngineGlowFlight = 12.0
    EngineRiseTime = 0.3
    EngineFallTime = 0.6
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
    ButtonCentreX = 640.0
    ButtonY = 655.1
    ButtonDepth = 999000
    ButtonLabelRoom = 135.0
    ButtonMaxWiden = 1.25
    ButtonAttachTries = 3
    ButtonAttachDelay = 1.0
    ButtonShrinkTime = 1.0
    ButtonHoverSound = "PCMouseHover"
    OrbitLabel = "Enter Orbit"
    SystemLabel = "Enter System"
    ScanLabel = "Scan"
    ButtonSymbol = "backAnim"
    ButtonName = "gmnEnter"
    ButtonArtLeft = -188.0
    ButtonArtTop = 1.2
    ButtonArtWidth = 187.8
    ButtonArtHeight = 26.9
    ButtonYScale = 103.0
    ButtonFieldMid = 55.75
    ButtonFieldScale = 107.2
    ButtonMouseOffFrame = 20
    ButtonFadeBackFrames = (6, 4, 3, 3, 2, 2, 1, 1)
    StageWidth = 1280.0
    StageHeight = 720.0
    ButtonWiden = 1.0
    SpeedScale = 1.0
    TickGroup = ETickingGroup.TG_PostAsyncWork
}
