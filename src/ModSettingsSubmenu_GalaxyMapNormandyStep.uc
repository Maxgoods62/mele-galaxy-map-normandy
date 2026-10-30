Class ModSettingsSubmenu_GalaxyMapNormandyStep extends ModSettingsSubmenu
    config(UI);

// The step list of one Galaxy Map Normandy setting. The current step is green; the action button stores the selected
// step in the gamer profile and saves it, then the menu refreshes the list. Back returns to the settings page.

var transient int SettingId;
var transient string SettingDescription;
var transient bool bOpened;
var array<int> Steps;

public static function string PercentText(int Id)
{
    local int Percent;

    Percent = Class'GalaxyMapNormandySettings'.static.GetPercent(Id);
    if (Percent <= 0)
    {
        Percent = 100;
    }
    return string(Percent) @ "%";
}

public function bool OnRefreshMenu(Object outerMenu)
{
    local ModSettingItemData Item;
    local ModSettingItemData Blank;
    local int Current;
    local int I;

    Current = Class'GalaxyMapNormandySettings'.static.GetPercent(SettingId);
    if (Current <= 0)
    {
        Current = 100;
    }
    menuItems.Length = 0;
    for (I = 0; I < Steps.Length; I++)
    {
        Item = Blank;
        Item.sLeftText = string(Steps[I]) @ "%";
        if (Steps[I] == 100)
        {
            Item.sLeftText @= "(default)";
        }
        Item.sDescriptionTitleText = sTitle;
        Item.sDescriptionText = SettingDescription;
        if (Steps[I] == Current)
        {
            Item.greenHighlight = TRUE;
            Item.sRightText = "Current";
            // Open the list on the current step.
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
    if (selectionIndex >= 0 && selectionIndex < Steps.Length
        && Class'GalaxyMapNormandySettings'.static.SetPercent(SettingId, Steps[selectionIndex]))
    {
        Class'GalaxyMapNormandySettings'.static.SaveProfile();
    }
    return FALSE;
}

defaultproperties
{
    Steps = (50, 75, 100, 125, 150, 200)
}
