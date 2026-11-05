Class GalaxyMapNormandySettings extends Object
    abstract;

// The player's choices from the Galaxy Map Normandy page of LE1CP's Mod Settings Menu (pause wheel, Mod Settings). They
// live in the gamer profile's IntStats list (saved in Save\ME1\PROFILE\GamerProfile.pcsav), so one choice holds for
// every career and save. LE1CP keeps its FOV there, in slot 0; this mod uses slots 100 to 107, far from the low slots
// LE1CP would take next. Each value is a percent of the director's default; 0 or no slot means 100.
// Compiled into the startup package for the director, and copied into the menu package for its pages.

var int ClusterSpeedId;
var int ClusterTurnId;
var int ClusterResponseId;
var int ClusterSizeId;
var int SystemSpeedId;
var int SystemTurnId;
var int SystemResponseId;
var int SystemSizeId;

public static function BioGamerProfile GetProfile()
{
    local BioWorldInfo WI;

    WI = BioWorldInfo(Class'WorldInfo'.static.GetWorldInfo());
    if (WI == None)
    {
        return None;
    }
    return WI.GetBioGamerProfile();
}

// The stored percent, or 0. A profile not read from disk yet falls back to the save system's copy of the file.
public static function int GetPercent(int Id)
{
    local BioGamerProfile Profile;
    local SFXEngine Engine;

    Profile = GetProfile();
    if (Profile != None && Profile.IntStats.Length > 0)
    {
        if (Id < Profile.IntStats.Length)
        {
            return Profile.IntStats[Id];
        }
        return 0;
    }
    Engine = Class'SFXEngine'.static.GetEngine();
    if (Engine != None && Engine.CurrentSaveGame != None && Id < Engine.CurrentSaveGame.ProfileRecord.IntStats.Length)
    {
        return Engine.CurrentSaveGame.ProfileRecord.IntStats[Id];
    }
    return 0;
}

public static function float GetMultiplier(int Id)
{
    local int Percent;

    Percent = GetPercent(Id);
    if (Percent <= 0)
    {
        return 1.0;
    }
    return float(Percent) / 100.0;
}

// A profile not read from disk yet has an empty IntStats list (LE1CP's LoadIntStats always leaves one slot) or no careers
// while the save system's record has some.
public static function bool LooksUnread(BioGamerProfile Profile, SFXSaveGame Save)
{
    return (Profile.IntStats.Length == 0 && Save.ProfileRecord.IntStats.Length > 0)
        || (Profile.lstCharacterProfiles.Length == 0 && Save.ProfileRecord.lstCharacterProfiles.Length > 0);
}

// Saving a profile that was never read from disk would replace the player's achievements, options and career list.
// LE1CP reads it from the save system's record first when its IntStats list is empty (BioSFHandler_PCOptions_Persistent:
// EnsureProfileInitialized). This does the same when the profile looks unread, so a profile already read is never
// replaced, and says no when it still looks unread. Writing IntStats into an unread profile would also hide it from
// LE1CP's check.
public static function bool EnsureProfileLoaded()
{
    local BioGamerProfile Profile;
    local SFXEngine Engine;

    Profile = GetProfile();
    Engine = Class'SFXEngine'.static.GetEngine();
    if (Profile == None || Engine == None || Engine.CurrentSaveGame == None)
    {
        return FALSE;
    }
    if (LooksUnread(Profile, Engine.CurrentSaveGame))
    {
        Engine.CurrentSaveGame.LoadGamerProfile(Profile);
    }
    return !LooksUnread(Profile, Engine.CurrentSaveGame);
}

// Changes the profile in memory; SaveProfile writes it to disk.
public static function bool SetPercent(int Id, int Percent)
{
    local BioGamerProfile Profile;

    if (!EnsureProfileLoaded())
    {
        return FALSE;
    }
    Profile = GetProfile();
    if (Profile.IntStats.Length <= Id)
    {
        Profile.IntStats.Length = Id + 1;
    }
    Profile.IntStats[Id] = Percent;
    return TRUE;
}

// Writes the profile file now, as the Options screen does when it applies a change (LE1CP's FOV slider too). A handler
// made here works without the screen (tested live 2026-10-30). The game writes the file on its own only now and then,
// not on every exit, and SFXEngine.QueueSaveGameCommand(SaveGame_SaveGamerProfile) only fills the save system's record.
public static function SaveProfile()
{
    local BioSFHandler_PCOptions Handler;
    local WorldInfo WI;

    WI = Class'WorldInfo'.static.GetWorldInfo();
    if (WI == None)
    {
        return;
    }
    Handler = new Class'BioSFHandler_PCOptions';
    Handler.oWorldInfo = WI;
    Handler.SaveProfile();
}

public static function ResetAll()
{
    if (SetPercent(default.ClusterSpeedId, 0) && SetPercent(default.ClusterTurnId, 0)
        && SetPercent(default.ClusterResponseId, 0) && SetPercent(default.ClusterSizeId, 0)
        && SetPercent(default.SystemSpeedId, 0) && SetPercent(default.SystemTurnId, 0)
        && SetPercent(default.SystemResponseId, 0) && SetPercent(default.SystemSizeId, 0))
    {
        SaveProfile();
    }
}

defaultproperties
{
    ClusterSpeedId = 100
    ClusterTurnId = 101
    ClusterResponseId = 102
    ClusterSizeId = 103
    SystemSpeedId = 104
    SystemTurnId = 105
    SystemResponseId = 106
    SystemSizeId = 107
}
