Class ModSettingsSubmenu_GalaxyMapNormandy extends ModSettingsSubmenu
    config(UI);

// The Galaxy Map Normandy page of LE1CP's Mod Settings Menu (pause wheel, Mod Settings), opened from a row that
// ConfigDelta-GalaxyMapNormandy.m3cd adds to LE1CP's root page. One row per setting shows its value; its action opens
// the setting's step page. The menu calls OnRefreshMenu before it lists a page's menuItems (on opening the page, after
// every action, on coming back from a step page), so the rows are rebuilt there from the stored values.

var transient int RestoreRow;

public function bool OnRefreshMenu(Object outerMenu)
{
    local Class<GalaxyMapNormandySettings> S;
    local ModSettingItemData Item;

    S = Class'GalaxyMapNormandySettings';
    menuItems.Length = 0;
    AddSetting(S.default.ClusterSpeedId, "Cluster: flight speed",
        "How fast the ship flies at cluster level, with the controller and with the mouse. The map cursor, and so what is selected, moves at the same speed.");
    AddSetting(S.default.ClusterTurnId, "Cluster: turn rate",
        "How fast the ship's nose turns toward where it flies at cluster level.");
    AddSetting(S.default.ClusterResponseId, "Cluster: ship response",
        "How closely the ship follows the map cursor at cluster level. Lower values let it glide behind; higher values keep it on the cursor.");
    AddSetting(S.default.ClusterSizeId, "Cluster: ship size", "Size of the ship at cluster level.");
    AddSetting(S.default.SystemSpeedId, "System: flight speed",
        "How fast the ship flies in system view, with the controller and with the mouse. The camera follows the ship there, so the view moves faster too.");
    AddSetting(S.default.SystemTurnId, "System: turn rate",
        "How fast the ship's nose turns toward where it flies in system view.");
    AddSetting(S.default.SystemResponseId, "System: ship response",
        "How closely the ship follows the map cursor in system view. Lower values let it glide behind; higher values keep it on the cursor.");
    AddSetting(S.default.SystemSizeId, "System: ship size", "Size of the ship in system view.");
    RestoreRow = menuItems.Length;
    Item.sLeftText = "Restore defaults";
    Item.sDescriptionTitleText = "Restore defaults";
    Item.sDescriptionText = "Sets every setting on this page back to 100 %.";
    menuItems.AddItem(Item);
    return FALSE;
}

public function AddSetting(int Id, string Label, string Description)
{
    local ModSettingItemData Item;
    local ModSettingsSubmenu_GalaxyMapNormandyStep Page;

    Page = new (Self) Class'ModSettingsSubmenu_GalaxyMapNormandyStep';
    Page.SettingId = Id;
    Page.SettingDescription = Description;
    Page.sTitle = Label;
    Page.sSubtitle = sTitle;
    Item.sLeftText = Label;
    Item.sRightText = Class'ModSettingsSubmenu_GalaxyMapNormandyStep'.static.PercentText(Id);
    Item.sDescriptionTitleText = Label;
    Item.sDescriptionText = Description;
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
    sSubtitle = "The same for every save. Changes show the next time the galaxy map opens."
}
