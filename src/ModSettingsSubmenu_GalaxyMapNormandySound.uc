Class ModSettingsSubmenu_GalaxyMapNormandySound extends ModSettingsSubmenu
    config(UI);

// The Flight sound list of the Galaxy Map Normandy page: the original sound and the five variants. The current one is
// green; the action button stores the picked one in the gamer profile, saves it and plays a short sample of it (the
// cue GalaxyMapNormandy_SFX.c_flight<n>_preview). Back returns to the settings page.

var transient bool bOpened;
var transient AudioComponent PreviewSound;
var array<stringref> Names;
var array<stringref> Descriptions;

public static function int Current()
{
    local Class<GalaxyMapNormandySettings> S;

    S = Class'GalaxyMapNormandySettings';
    return Clamp(S.static.GetPercent(S.default.SoundId), 0, S.default.SoundCount - 1);
}

public static function stringref CurrentName()
{
    return default.Names[Current()];
}

public function bool OnRefreshMenu(Object outerMenu)
{
    local ModSettingItemData Item;
    local ModSettingItemData Blank;
    local int Picked;
    local int I;

    Picked = Current();
    menuItems.Length = 0;
    for (I = 0; I < Names.Length; I++)
    {
        Item = Blank;
        Item.srLeftText = Names[I];
        if (I == 0)
        {
            Item.sLeftText = string(Names[I]) @ string($74220020);
        }
        Item.srDescriptionTitleText = Names[I];
        Item.srDescriptionText = Descriptions[I];
        if (I == Picked)
        {
            Item.greenHighlight = TRUE;
            Item.srRightText = $74220021;
            // Open the list on the current sound.
            if (!bOpened)
            {
                selectedIndex = I;
            }
        }
        menuItems.AddItem(Item);
    }
    bOpened = TRUE;
    return FALSE;
}

public function bool OnActionButtonPressed(Object outerMenu, int selectionIndex)
{
    local Class<GalaxyMapNormandySettings> S;

    S = Class'GalaxyMapNormandySettings';
    if (selectionIndex >= 0 && selectionIndex < Names.Length && S.static.SetPercent(S.default.SoundId, selectionIndex))
    {
        S.static.SaveProfile();
        PlayPreview(selectionIndex);
    }
    return FALSE;
}

// Leaving the page cuts the sample: if the game holds paused sounds while its menu is open, the sample must not play
// on its own when the player goes back to the game.
public function bool OnBackButtonPressed(Object outerMenu)
{
    if (PreviewSound != None)
    {
        PreviewSound.Stop();
    }
    return FALSE;
}

// A few seconds of the sound: its whoosh, its loops at full speed and their fade-out, baked into one wave.
public function PlayPreview(int Variant)
{
    local WorldInfo WI;
    local PlayerController PC;
    local SoundCue Cue;

    WI = Class'WorldInfo'.static.GetWorldInfo();
    if (WI == None)
    {
        return;
    }
    PC = WI.GetALocalPlayerController();
    Cue = SoundCue(DynamicLoadObject("GalaxyMapNormandy_SFX.c_flight" $ string(Variant) $ "_preview", Class'SoundCue'));
    if (PC == None || Cue == None)
    {
        return;
    }
    if (PreviewSound != None)
    {
        PreviewSound.Stop();
    }
    PreviewSound = PC.CreateAudioComponent(Cue, FALSE, TRUE);
    if (PreviewSound != None)
    {
        PreviewSound.bAllowSpatialization = FALSE;
        PreviewSound.Play();
    }
}

defaultproperties
{
    Names = ($74220025, $74220027, $74220029, $74220031, $74220033, $74220035)
    Descriptions = ($74220026, $74220028, $74220030, $74220032, $74220034, $74220036)
}
