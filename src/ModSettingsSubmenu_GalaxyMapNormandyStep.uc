Class ModSettingsSubmenu_GalaxyMapNormandyStep extends ModSettingsSubmenu
    config(UI);

// The step list of one Galaxy Map Normandy setting. The current step is green; the action button stores the selected
// step in the gamer profile and saves it, then the menu refreshes the list. Back returns to the settings page. The flight
// sound volume has its own list, VolumeSteps; the other settings use Steps.

var transient int SettingId;
var transient stringref SettingDescription;
var transient bool bOpened;
var array<int> Steps;
var array<int> VolumeSteps;

public static function string PercentText(int Id)
{
    return string(Class'GalaxyMapNormandySettings'.static.GetShownPercent(Id)) @ "%";
}

public function bool OnRefreshMenu(Object outerMenu)
{
    local ModSettingItemData Item;
    local ModSettingItemData Blank;
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
    menuItems.Length = 0;
    for (I = 0; I < Steps.Length; I++)
    {
        Item = Blank;
        Item.sLeftText = string(Steps[I]) @ "%";
        if (Steps[I] == 100)
        {
            Item.sLeftText @= string($74220020);
        }
        Item.srDescriptionTitleText = srTitle;
        Item.srDescriptionText = SettingDescription;
        if (Steps[I] == Current)
        {
            Item.greenHighlight = TRUE;
            Item.srRightText = $74220021;
            // Open the list on the current step. The menu shows 13 rows and scrolls to scrollIndex after it selects a
            // row, so a step below the first 13 (the volume list's 130 % and 140 %) needs the scroll too.
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
