# Translating Galaxy Map Normandy

This page is for modders who want Galaxy Map Normandy in their own language. Every word the mod shows in game, its
name included, is a string in its talk files, so a translation needs no change to the mod. A translation is your own
mod: you ship it, and this mod never includes your text.

## What a translation mod holds

The mod has one file of talk tables per language code. A translation mod holds new copies of the files of its
language, with the same names, in a DLC folder of its own that LE1 mounts above this mod. When two DLC folders hold a
file of the same name, LE1 loads the copy from the higher mount.

1. Take this mod's files for your language from `DLC_MOD_GalaxyMapNormandy/CookedPCConsole`, in the mod's download or
   in your game's `BioGame/DLC` folder ([the files](#the-files)).
2. Open each file in Legendary Explorer and replace the text of the ids you translate, in both of its talk tables,
   `GlobalTlk_tlk` and `GlobalTlk_tlk_M`.
3. Make a DLC folder `DLC_MOD_<Name>`, where `<Name>` is your mod's name without spaces (M3's Starter Kit can make it).
   Its `AutoLoad.ini` needs:

   ```ini
   [ME1DLCMOUNT]
   ModName=<Name>
   ModMount=<mount>
   ```

   `<mount>` is a number above 7422, this mod's mount, that no other mod uses. With a lower mount the game keeps this
   mod's text, and nothing says so.
4. Put your files in its `CookedPCConsole`, with exactly the names of the files they replace.
5. Install your mod with M3, with the game closed. Galaxy Map Normandy stays installed.

Your file replaces this mod's file whole: a string you leave out shows the text of your file, not this mod's. So start
from this mod's file, and change only the strings you translate.

## The files

The game reads the file of its text language. Some languages have two codes, and their two files are copies: ship
both.

| Language | Code | File |
|---|---|---|
| English | INT | `DLC_MOD_GalaxyMapNormandy_GlobalTlk.pcc` |
| French | FR, FE | `DLC_MOD_GalaxyMapNormandy_GlobalTlk_FR.pcc`, `DLC_MOD_GalaxyMapNormandy_GlobalTlk_FE.pcc` |
| German | DE, GE | `DLC_MOD_GalaxyMapNormandy_GlobalTlk_DE.pcc`, `DLC_MOD_GalaxyMapNormandy_GlobalTlk_GE.pcc` |
| Italian | IT, IE | `DLC_MOD_GalaxyMapNormandy_GlobalTlk_IT.pcc`, `DLC_MOD_GalaxyMapNormandy_GlobalTlk_IE.pcc` |
| Spanish | ES | `DLC_MOD_GalaxyMapNormandy_GlobalTlk_ES.pcc` |
| Polish | PL, PLPC | `DLC_MOD_GalaxyMapNormandy_GlobalTlk_PL.pcc`, `DLC_MOD_GalaxyMapNormandy_GlobalTlk_PLPC.pcc` |
| Russian | RU, RA | `DLC_MOD_GalaxyMapNormandy_GlobalTlk_RU.pcc`, `DLC_MOD_GalaxyMapNormandy_GlobalTlk_RA.pcc` |
| Japanese | JA | `DLC_MOD_GalaxyMapNormandy_GlobalTlk_JA.pcc` |

Each file holds two talk tables, `GlobalTlk_tlk` and `GlobalTlk_tlk_M`. The game reads the first for a female
Shepard and the second for a male one, so both need every id. This mod's build makes the files from
`src/tlk/<code>.tsv` with the toolkit's `lectool tlkpackage`, which writes both tables.

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
lack it. The mod's name is the subtitle of each step page, a line that fits about 459 pixels, so keep it about as long
as "Galaxy Map Normandy".

Ids 74220030 to 74229999 are kept for this mod's later strings, and 74220020 is retired: leave them out of your
files.

## When a string is missing

If 74220028 or 74220029 has no `{0}`, the pages use the English pattern, and the game log has a line that starts with
`Percent pattern`. If 74220025, 74220026 or 74220027 is empty, the button shows the English word, and the game log has
a line that starts with `Enter button: strings`.

## What has been tested

On 2026-11-09, in LE1: a test text for the mod's name in this mod's own Russian files showed on its row in Mod
Settings, in the pane on the right and on the titles of its pages. The French and Japanese files showed their own
percents and words. Still untested: a translation mod in a DLC folder of its own, as described above, and a DLC that
defines the same ids in files of other names.
