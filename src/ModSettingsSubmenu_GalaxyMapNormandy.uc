Class ModSettingsSubmenu_GalaxyMapNormandy extends ModSettingsSubmenu
    config(UI);

// The Galaxy Map Normandy page of LE1CP's Mod Settings Menu (pause wheel, Mod Settings), opened from a row that
// ConfigDelta-GalaxyMapNormandy.m3cd adds to LE1CP's root page. One row per setting shows its value; its action opens
// the setting's step page. The menu calls OnRefreshMenu before it lists a page's menuItems (on opening the page, after
// every action, on coming back from a step page), so the rows are rebuilt there from the stored values. The words are
// strings of the mod's GlobalTlk, one file per language in src/tlk/. The menu shows a row's s field if it has text, else
// its sr field. The page title, the mod's name, stays a plain string in every language.

var transient int RestoreRow;

public function bool OnRefreshMenu(Object outerMenu)
{
    local Class<GalaxyMapNormandySettings> S;
    local ModSettingItemData Item;

    S = Class'GalaxyMapNormandySettings';
    menuItems.Length = 0;
    AddSetting(S.default.ClusterSpeedId, $74220001, $74220002);
    AddSetting(S.default.ClusterTurnId, $74220003, $74220004);
    AddSetting(S.default.ClusterResponseId, $74220005, $74220006);
    AddSetting(S.default.ClusterSizeId, $74220007, $74220008);
    AddSetting(S.default.SystemSpeedId, $74220009, $74220010);
    AddSetting(S.default.SystemTurnId, $74220011, $74220012);
    AddSetting(S.default.SystemResponseId, $74220013, $74220014);
    AddSetting(S.default.SystemSizeId, $74220015, $74220016);
    AddSoundRow();
    RestoreRow = menuItems.Length;
    Item.srLeftText = $74220017;
    Item.srDescriptionTitleText = $74220017;
    Item.srDescriptionText = $74220018;
    menuItems.AddItem(Item);
    return FALSE;
}

public function AddSetting(int Id, stringref Label, stringref Description)
{
    local ModSettingItemData Item;
    local ModSettingsSubmenu_GalaxyMapNormandyStep Page;

    Page = new (Self) Class'ModSettingsSubmenu_GalaxyMapNormandyStep';
    Page.SettingId = Id;
    Page.SettingDescription = Description;
    Page.srTitle = Label;
    Page.sSubtitle = sTitle;
    Item.srLeftText = Label;
    Item.sRightText = Class'ModSettingsSubmenu_GalaxyMapNormandyStep'.static.PercentText(Id);
    Item.srDescriptionTitleText = Label;
    Item.srDescriptionText = Description;
    Item.submenuInstance = Page;
    menuItems.AddItem(Item);
}

// The Flight sound row: the current sound's name; its action opens the list of sounds.
public function AddSoundRow()
{
    local ModSettingItemData Item;
    local ModSettingsSubmenu_GalaxyMapNormandySound Page;

    Page = new (Self) Class'ModSettingsSubmenu_GalaxyMapNormandySound';
    Page.srTitle = $74220023;
    Page.sSubtitle = sTitle;
    Item.srLeftText = $74220023;
    Item.srRightText = Class'ModSettingsSubmenu_GalaxyMapNormandySound'.static.CurrentName();
    Item.srDescriptionTitleText = $74220023;
    Item.srDescriptionText = $74220024;
    Item.submenuInstance = Page;
    menuItems.AddItem(Item);
}

// The menu then applies the row (it writes nothing: no plot ids on it) and refreshes the page.
public function bool OnActionButtonPressed(Object outerMenu, int selectionIndex)
{
    if (selectionIndex == RestoreRow)
    {
        Class'GalaxyMapNormandySettings'.static.ResetAll();
    }
    return FALSE;
}

defaultproperties
{
    sTitle = "Galaxy Map Normandy"
    srSubtitle = $74220019
}
