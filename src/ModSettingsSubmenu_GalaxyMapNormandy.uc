Class ModSettingsSubmenu_GalaxyMapNormandy extends ModSettingsSubmenu
    config(UI);

// The Galaxy Map Normandy page of LE1CP's Mod Settings Menu (pause wheel, Mod Settings), opened from a row that
// ConfigDelta-GalaxyMapNormandy.m3cd adds to LE1CP's root page. One row per setting shows its value; its action opens
// the setting's step page. The menu calls OnRefreshMenu before it lists a page's menuItems (on opening the page, after
// every action, on coming back from a step page), so the rows are rebuilt there from the stored values. The words are
// strings of the mod's GlobalTlk, one file per language in src/tlk/. The menu shows a row's s field if it has text, else
// its sr field, so a word that should follow the language is never a literal in an s field: it goes in the sr field, or
// in the s field as string($id). The mod's name is $74220000: the page title, each step page's subtitle, and the root
// row in the .m3cd. A row's value on the right is the percent pattern $74220028 with the digits put in (PercentPattern,
// PercentText), so a language writes its percent its own way. The Mass relay movie row has no step page: its action
// turns the cinematic on or off, and its value is the game's own On and Off in the mod's strings ($74220032, $74220033).

var transient int RelayRow;
var transient int RestoreRow;

public function bool OnRefreshMenu(Object outerMenu)
{
    local Class<GalaxyMapNormandySettings> S;
    local ModSettingItemData Relay;
    local ModSettingItemData Item;
    local string Pattern;

    S = Class'GalaxyMapNormandySettings';
    Pattern = Class'ModSettingsSubmenu_GalaxyMapNormandyStep'.static.PercentPattern();
    menuItems.Length = 0;
    AddSetting(S.default.FlightVolumeId, $74220023, $74220024, Pattern);
    RelayRow = menuItems.Length;
    Relay.srLeftText = $74220030;
    if (S.static.IsRelayMovieOn())
    {
        Relay.srRightText = $74220032;
    }
    else
    {
        Relay.srRightText = $74220033;
    }
    Relay.srDescriptionTitleText = $74220030;
    Relay.srDescriptionText = $74220031;
    menuItems.AddItem(Relay);
    AddSetting(S.default.ClusterSpeedId, $74220001, $74220002, Pattern);
    AddSetting(S.default.ClusterTurnId, $74220003, $74220004, Pattern);
    AddSetting(S.default.ClusterResponseId, $74220005, $74220006, Pattern);
    AddSetting(S.default.ClusterSizeId, $74220007, $74220008, Pattern);
    AddSetting(S.default.SystemSpeedId, $74220009, $74220010, Pattern);
    AddSetting(S.default.SystemTurnId, $74220011, $74220012, Pattern);
    AddSetting(S.default.SystemResponseId, $74220013, $74220014, Pattern);
    AddSetting(S.default.SystemSizeId, $74220015, $74220016, Pattern);
    RestoreRow = menuItems.Length;
    Item.srLeftText = $74220017;
    Item.srDescriptionTitleText = $74220017;
    Item.srDescriptionText = $74220018;
    menuItems.AddItem(Item);
    return FALSE;
}

// Pattern is the percent pattern, read once per refresh (PercentPattern).
public function AddSetting(int Id, stringref Label, stringref Description, string Pattern)
{
    local ModSettingItemData Item;
    local ModSettingsSubmenu_GalaxyMapNormandyStep Page;

    Page = new (Self) Class'ModSettingsSubmenu_GalaxyMapNormandyStep';
    Page.SettingId = Id;
    Page.SettingDescription = Description;
    Page.srTitle = Label;
    Page.srSubtitle = srTitle;
    Item.srLeftText = Label;
    Item.sRightText = Class'ModSettingsSubmenu_GalaxyMapNormandyStep'.static.PercentText(Pattern,
        Class'GalaxyMapNormandySettings'.static.GetShownPercent(Id));
    Item.srDescriptionTitleText = Label;
    Item.srDescriptionText = Description;
    Item.submenuInstance = Page;
    menuItems.AddItem(Item);
}

// The menu then applies the row (it writes nothing: no plot ids on it) and refreshes the page.
public function bool OnActionButtonPressed(Object outerMenu, int selectionIndex)
{
    if (selectionIndex == RelayRow)
    {
        Class'GalaxyMapNormandySettings'.static.SetRelayMovie(!Class'GalaxyMapNormandySettings'.static.IsRelayMovieOn());
    }
    else if (selectionIndex == RestoreRow)
    {
        Class'GalaxyMapNormandySettings'.static.ResetAll();
    }
    return FALSE;
}

defaultproperties
{
    srTitle = $74220000
    srSubtitle = $74220019
}
