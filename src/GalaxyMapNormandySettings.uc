Class GalaxyMapNormandySettings extends Object
    abstract;

// The player's choices from the Galaxy Map Normandy page of LE1CP's Mod Settings Menu (pause wheel, Mod Settings). They
// live in the gamer profile (BioGamerProfile.IntVariables, saved in Save\ME1\PROFILE\GamerProfile.pcsav), so one choice
// holds for every career and save. Each value is a percent of the director's default; 0 or no entry means 100. The keys
// are plot int ids of this mod's block, so nothing else should use them, but this never writes the plot table.
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
    local int I;

    Profile = GetProfile();
    if (Profile != None)
    {
        I = Profile.IntVariables.Find('PMIndex', Id);
        if (I != -1)
        {
            return Profile.IntVariables[I].Value;
        }
    }
    Engine = Class'SFXEngine'.static.GetEngine();
    if (Engine != None && Engine.CurrentSaveGame != None)
    {
        I = Engine.CurrentSaveGame.ProfileRecord.IntVariables.Find('PMIndex', Id);
        if (I != -1)
        {
            return Engine.CurrentSaveGame.ProfileRecord.IntVariables[I].Value;
        }
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

// Saving a profile that was never read from disk would replace the player's achievements, options and career list.
// LE1CP reads it from the save system's record first when it looks unread (BioSFHandler_PCOptions_Persistent:
// EnsureProfileInitialized). This reads it only when it lacks careers the record has, so a profile already read is
// never replaced, and says no when the profile still has fewer careers than the record.
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
    if (Profile.lstCharacterProfiles.Length == 0 && Engine.CurrentSaveGame.ProfileRecord.lstCharacterProfiles.Length > 0)
    {
        Engine.CurrentSaveGame.LoadGamerProfile(Profile);
    }
    return Profile.lstCharacterProfiles.Length >= Engine.CurrentSaveGame.ProfileRecord.lstCharacterProfiles.Length;
}

// Changes the profile in memory; SaveProfile writes it to disk.
public static function bool SetPercent(int Id, int Percent)
{
    local BioGamerProfile Profile;
    local ProfileINT Entry;
    local int I;

    if (!EnsureProfileLoaded())
    {
        return FALSE;
    }
    Profile = GetProfile();
    I = Profile.IntVariables.Find('PMIndex', Id);
    if (I == -1)
    {
        Entry.PMIndex = Id;
        Entry.Value = Percent;
        Profile.IntVariables.AddItem(Entry);
    }
    else
    {
        Profile.IntVariables[I].Value = Percent;
    }
    return TRUE;
}

public static function SaveProfile()
{
    local SFXEngine Engine;

    Engine = Class'SFXEngine'.static.GetEngine();
    if (Engine != None)
    {
        Engine.QueueSaveGameCommand(ESFXSaveGameAction.SaveGame_SaveGamerProfile);
    }
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
    ClusterSpeedId = 8429
    ClusterTurnId = 8430
    ClusterResponseId = 8431
    ClusterSizeId = 8432
    SystemSpeedId = 8433
    SystemTurnId = 8434
    SystemResponseId = 8435
    SystemSizeId = 8436
}
