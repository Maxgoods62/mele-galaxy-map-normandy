Class ModSettingsSubmenu_GalaxyMapNormandyStep extends ModSettingsSubmenu
    config(UI);

// The step list of one Galaxy Map Normandy setting. The current step is green; the action button stores the selected
// step in the gamer profile and saves it, then the menu refreshes the list. Back returns to the settings page. The flight
// sound volume has its own list, VolumeSteps; the other settings use Steps. A step reads as the pattern $74220028, the
// 100 step as $74220029, with the digits put in (PercentPattern, PercentText).

var transient int SettingId;
var transient stringref SettingDescription;
var transient bool bOpened;
var array<int> Steps;
var array<int> VolumeSteps;

// How the player's language writes a percent. String 74220028 holds the pattern, {0} standing for the number ("{0}%"
// in English, "{0} %" with a no-break space in French), and 74220029 the pattern of the default step
// ("{0}% (default)"). A pattern without {0} (the string table gave nothing) falls back to English, and the log says so.
// A page reads its patterns once per refresh, so a missing pattern logs one line per refresh, not one per row.
public static function string PercentPattern(optional bool bDefault)
{
    local string Pattern;
    local string English;

    if (bDefault)
    {
        Pattern = string($74220029);
        English = "{0}% (default)";
    }
    else
    {
        Pattern = string($74220028);
        English = "{0}%";
    }
    if (InStr(Pattern, "{0}") < 0)
    {
        LogInternal("Percent pattern '" $ Pattern $ "' has no {0}: the English pattern stands in", 'GalaxyMapNormandy');
        Pattern = English;
    }
    return Pattern;
}

// A pattern from PercentPattern with the digits put in. The code builds only the digits.
public static function string PercentText(string Pattern, int Percent)
{
    return Repl(Pattern, "{0}", string(Percent));
}

public function bool OnRefreshMenu(Object outerMenu)
{
    local ModSettingItemData Item;
    local ModSettingItemData Blank;
    local string Pattern;
    local string DefaultPattern;
    local int Current;
    local int I;

    if (!bOpened && SettingId == Class'GalaxyMapNormandySettings'.default.FlightVolumeId)
    {
        Steps.Length = 0;
        for (I = 0; I < VolumeSteps.Length; I++)
        {
            Steps.AddItem(VolumeSteps[I]);
        }
    }
    Current = Class'GalaxyMapNormandySettings'.static.GetShownPercent(SettingId);
    Pattern = PercentPattern();
    DefaultPattern = PercentPattern(TRUE);
    menuItems.Length = 0;
    for (I = 0; I < Steps.Length; I++)
    {
        Item = Blank;
        if (Steps[I] == 100)
        {
            Item.sLeftText = PercentText(DefaultPattern, Steps[I]);
        }
        else
        {
            Item.sLeftText = PercentText(Pattern, Steps[I]);
        }
        Item.srDescriptionTitleText = srTitle;
        Item.srDescriptionText = SettingDescription;
        if (Steps[I] == Current)
        {
            Item.greenHighlight = TRUE;
            Item.srRightText = $74220021;
            // Open the list on the current step. The menu shows 13 rows and scrolls to scrollIndex after it selects a
            // row, so a step below the first 13 (the volume list's 130% and 140%) needs the scroll too.
            if (!bOpened)
            {
                selectedIndex = I;
                scrollIndex = Max(0, I - 12);
            }
        }
        menuItems.AddItem(Item);
    }
    bOpened = TRUE;
    return FALSE;
}

public function bool OnActionButtonPressed(Object outerMenu, int selectionIndex)
{
    if (selectionIndex >= 0 && selectionIndex < Steps.Length
        && Class'GalaxyMapNormandySettings'.static.SetShownPercent(SettingId, Steps[selectionIndex]))
    {
        Class'GalaxyMapNormandySettings'.static.SaveProfile();
    }
    return FALSE;
}

defaultproperties
{
    Steps = (50, 75, 100, 125, 150, 200)
    VolumeSteps = (0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140)
}
