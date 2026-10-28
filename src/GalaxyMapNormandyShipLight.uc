Class GalaxyMapNormandyShipLight extends SkyLightComponent;

// Galaxy Map Normandy: the sky light that lights the ship. The Normandy's own sky light only reaches actors in the
// NOR10 design levels, and Spawn puts the ship in the hub's persistent level, which has no light out in the map scene.
// Lighting channels are const at runtime, so this class sets them: Unnamed_6 only, which the ship's mesh gets too.

defaultproperties
{
    Brightness = 1.0
    LowerBrightness = 0.3
    CastShadows = FALSE
    CastStaticShadows = FALSE
    CastDynamicShadows = FALSE
    bCastCompositeShadow = FALSE
    bAffectCompositeShadowDirection = FALSE
    LightingChannels = {
                        bInitialized = TRUE,
                        BSP = FALSE,
                        Static = FALSE,
                        Dynamic = FALSE,
                        CompositeDynamic = FALSE,
                        Skybox = FALSE,
                        Unnamed_1 = FALSE,
                        Unnamed_2 = FALSE,
                        Unnamed_3 = FALSE,
                        Unnamed_4 = FALSE,
                        Unnamed_5 = FALSE,
                        Unnamed_6 = TRUE,
                        Cinematic_1 = FALSE,
                        Cinematic_2 = FALSE,
                        Cinematic_3 = FALSE,
                        Cinematic_4 = FALSE,
                        Cinematic_5 = FALSE,
                        Cinematic_6 = FALSE,
                        Cinematic_7 = FALSE,
                        Cinematic_8 = FALSE,
                        Cinematic_9 = FALSE,
                        Cinematic_10 = FALSE,
                        Gameplay_1 = FALSE,
                        Gameplay_2 = FALSE,
                        Gameplay_3 = FALSE,
                        Gameplay_4 = FALSE,
                        Crowd = FALSE
                       }
}
