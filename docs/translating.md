# Translating Galaxy Map Normandy

This page is for modders who want Galaxy Map Normandy in their own language. Every word the mod shows in game, its
name included, is a string in its talk files, so a translation needs no change to the mod. A translation is your own
mod: you ship it, and this mod never includes your text.

[Translating my mods](https://github.com/Maxgoods62/mele-maxgoods-toolkit/blob/main/docs/translating.md) says how to
build that mod in LE1. Galaxy Map Normandy is a mod with talk files: your mod holds copies of its files for your
language, under the same names, at a mount above 7422 that no other mod uses.

## What a translation mod holds

1. Take this mod's files for your language from `DLC_MOD_GalaxyMapNormandy/CookedPCConsole`, in the mod's download or
   in your game's `BioGame/DLC` folder ([the files](#the-files)).
2. Open each file in Legendary Explorer and replace the text of the ids you translate, in both of its talk tables,
   `GlobalTlk_tlk` and `GlobalTlk_tlk_M`.
3. Make a DLC folder of your own ([the DLC folder](https://github.com/Maxgoods62/mele-maxgoods-toolkit/blob/main/docs/translating.md#the-dlc-folder)), whose mount is above 7422, this
   mod's mount, and used by no other mod. Put your files in its `CookedPCConsole`, with exactly the names of the files
   they replace.
4. Install your mod with M3, with the game closed. Galaxy Map Normandy stays installed.

## The files

The game reads the file of its text language.

| Language | Code | File |
|---|---|---|
| English | none | `DLC_MOD_GalaxyMapNormandy_GlobalTlk.pcc` |
| French | FR, FE | `DLC_MOD_GalaxyMapNormandy_GlobalTlk_FR.pcc`, `DLC_MOD_GalaxyMapNormandy_GlobalTlk_FE.pcc` |
| German | DE, GE | `DLC_MOD_GalaxyMapNormandy_GlobalTlk_DE.pcc`, `DLC_MOD_GalaxyMapNormandy_GlobalTlk_GE.pcc` |
| Italian | IT, IE | `DLC_MOD_GalaxyMapNormandy_GlobalTlk_IT.pcc`, `DLC_MOD_GalaxyMapNormandy_GlobalTlk_IE.pcc` |
| Spanish | ES | `DLC_MOD_GalaxyMapNormandy_GlobalTlk_ES.pcc` |
| Polish | PL, PLPC | `DLC_MOD_GalaxyMapNormandy_GlobalTlk_PL.pcc`, `DLC_MOD_GalaxyMapNormandy_GlobalTlk_PLPC.pcc` |
| Russian | RU, RA | `DLC_MOD_GalaxyMapNormandy_GlobalTlk_RU.pcc`, `DLC_MOD_GalaxyMapNormandy_GlobalTlk_RA.pcc` |
| Japanese | JA | `DLC_MOD_GalaxyMapNormandy_GlobalTlk_JA.pcc` |

This mod's build makes the files from one `src/tlk/<language>.tsv` per language (`INT.tsv` for English, `FR.tsv` for
both French files) with the toolkit's `lectool tlkpackage`, which writes both talk tables.

## The string ids

[src/tlk/INT.tsv](../src/tlk/INT.tsv) lists every id with its English text, one per line (the id, a tab, the text),
and the other files in `src/tlk/` hold the same ids in each language. The table below says where each one shows.

Each setting has a name and a description. The name shows on the setting's row, as the title of the pane on the right
and as the title of its step page. The description shows in the pane on the right.

| Id | Where it shows | English |
|---|---|---|
| 74220000 | the mod's name: its row in Mod Settings, the title of the pane on the right for that row, the title of the mod's page, the subtitle of each step page | Galaxy Map Normandy |
| 74220001 | a setting's name | Cluster: flight speed |
| 74220002 | its description | How fast the ship flies at cluster level, with the controller and with the mouse. The map cursor, and so what is selected, moves at the same speed. |
| 74220003 | a setting's name | Cluster: turn rate |
| 74220004 | its description | How fast the ship's nose turns toward where it flies at cluster level. |
| 74220005 | a setting's name | Cluster: ship response |
| 74220006 | its description | How closely the ship follows the map cursor at cluster level. Lower values let it glide behind; higher values keep it on the cursor. |
| 74220007 | a setting's name | Cluster: ship size |
| 74220008 | its description | Size of the ship at cluster level. |
| 74220009 | a setting's name | System: flight speed |
| 74220010 | its description | How fast the ship flies in system view, with the controller and with the mouse. The camera follows the ship there, so the view moves faster too. |
| 74220011 | a setting's name | System: turn rate |
| 74220012 | its description | How fast the ship's nose turns toward where it flies in system view. |
| 74220013 | a setting's name | System: ship response |
| 74220014 | its description | How closely the ship follows the map cursor in system view. Lower values let it glide behind; higher values keep it on the cursor. |
| 74220015 | a setting's name | System: ship size |
| 74220016 | its description | Size of the ship in system view. |
| 74220017 | the last row of the settings page | Restore defaults |
| 74220018 | its description | Sets every setting on this page back to 100%. |
| 74220019 | the subtitle of the settings page | Changes show the next time the map opens. |
| 74220020 | no longer used: leave it out, and never give the number to a new string | |
| 74220021 | right of the step in use | Current |
| 74220022 | the description of the mod's row in Mod Settings | Flight speed, turn rate, response and size of the ship on the galaxy map, at cluster level and in system view, and the volume of its flight sound. The same for every save. |
| 74220023 | a setting's name | Flight sound volume |
| 74220024 | its description | How loud the ship's flight sound is on the galaxy map, at both levels: the whoosh, the engine and the drive. 0% turns it off. |
| 74220025 | the Enter button at cluster level | Enter System |
| 74220026 | the Enter button in system view | Enter Orbit |
| 74220027 | the Enter button on something still to scan | Scan |
| 74220028 | a percent: each setting's value and each step | {0}% |
| 74220029 | the 100% step, the default | {0}% (default) |

In 74220028 and 74220029, `{0}` is the number. Write a percent as the game does in your language: English writes 100%,
French 100 % with a no-break space (U+00A0) before the %. Never use U+202F, the narrow no-break space: the game's fonts
lack it.

The mod's name is also the subtitle of each step page, a line about 459 pixels wide: keep it about as long as "Galaxy
Map Normandy".

Ids 74220030 to 74229999 are kept for this mod's later strings, and 74220020 is retired: leave them out of your
files.

## When a string is missing

The game log below is `Logs\DebugLogger.log` in `Binaries\Win64`, written when a logger ASI such as LE1DebugLogger is
installed.

These two cases come from the code and have not been tested in the game. If 74220028 or 74220029 has no `{0}`, the
pages use the English pattern, and the game log has a line that contains `Percent pattern`. If 74220025, 74220026 or
74220027 is empty, the button shows the English word, and the game log has a line that contains
`Enter button: strings`.

## What has been tested

On 2026-11-09, in LE1:

- A translation mod built as above, at mount 7480 with a test copy of the English file, replaced the mod's name, a
  setting's name and the percents in an English game. A French game kept this mod's French text, since the
  translation mod had no French file.
- A test text for the mod's name in this mod's own Russian files showed on its row in Mod Settings, in the pane on the
  right and on the titles of its pages. The French and Japanese files showed their own percents and words.

Still untested: two translation mods for the same language, a lower mount, a DLC that defines the same ids in files
of other names, and the two cases under [When a string is missing](#when-a-string-is-missing).
