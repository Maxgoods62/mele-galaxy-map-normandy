# Building Galaxy Map Normandy

`build.sh` builds the whole mod from this repository and your own game files. It writes only into `build/` and
`dist/` (both ignored by git) and only reads the game files. The result is the M3 mod folder
`dist/Galaxy Map Normandy/`, which you install with ME3Tweaks Mod Manager while the game is closed.

## What you need

| What | Setting | Notes |
|---|---|---|
| Windows with WSL | | `build.sh` is a bash script. It runs the Windows tools through WSL interop and converts paths with `wslpath`. |
| `python3`, `ffmpeg` and `git` in WSL | | `build.sh` stops if one of them is not on `PATH`. `ffmpeg` needs the `libvorbis` encoder. |
| The Windows .NET SDK 10.0.402 or a later 10.0 SDK, and the .NET 8 runtime | `MELE_DOTNET` | The toolkit's `global.json` files pin SDK 10.0.402 (`rollForward: latestFeature`). lectool and mele-mcp target `net8.0-windows` and run on .NET 8. The first build restores NuGet packages. |
| vgmstream | `MELE_VGMSTREAM` | `vgmstream-cli` in WSL, or the Windows `vgmstream.exe` that Legendary Explorer ships in `exec/vgmstream/`. |
| A [mele-maxgoods-toolkit](https://github.com/Maxgoods62/mele-maxgoods-toolkit) checkout with its LegendaryExplorerCore submodule | `MELE_TOOLKIT` | A checkout with `tools/lectool` (with its `addtexture` and `tlkpackage` commands) and mele-mcp 0.1.0 or later (`<Version>` in `tools/mele-mcp/src/MeleMcp/MeleMcp.csproj`). `build.sh` does not check the version; it stops if `addtexture` adds nothing or `tlkpackage` writes nothing. |
| The LE1 Community Patch 2.0 or later, installed in LE1 | | The build copies the menu's page class from its `ModSettingsMenu.pcc`. |
| LE1, LE2 and LE3 in one Legendary Edition folder | `MELE_LE_DIR` | The build reads LE1's `snd_gui.pcc` and `BIOA_ICE20_11_LAY.pcc`, LE2's `Startup_INT.pcc` and LE3's `SFXGame.pcc` ([ASSETS.md](ASSETS.md)). |

To get the toolkit:

```bash
git clone https://github.com/Maxgoods62/mele-maxgoods-toolkit.git
git -C mele-maxgoods-toolkit submodule update --init
```

## Settings

`build.sh` reads its settings from the environment, or from `build.env` next to it. `build.env` is not in git;
start from the example:

```bash
cp build.env.example build.env
```

```bash
# Copy to build.env (not in git) and fix the paths. Windows paths for MELE_LE_DIR; WSL paths for the programs.
MELE_LE_DIR='C:\Program Files (x86)\Steam\steamapps\common\Mass Effect Legendary Edition'
MELE_DOTNET='/mnt/c/Program Files/dotnet/dotnet.exe'
MELE_VGMSTREAM='/mnt/c/<ME3Tweaks Mod Manager data>/ExternalTools/Legendary Explorer/exec/vgmstream/vgmstream.exe'
# MELE_TOOLKIT=../../mele-maxgoods-toolkit   # a mele-maxgoods-toolkit checkout (default: ../../mele-maxgoods-toolkit from build.sh's folder)
```

`build.sh` sources `build.env` before it applies its defaults, so a value in `build.env` replaces the same variable
from the environment.

| Variable | Default | Meaning |
|---|---|---|
| `MELE_LE_DIR` | none: `build.sh` stops without it | The Legendary Edition folder (the one that holds `Game\ME1`, `Game\ME2` and `Game\ME3`), as a Windows path |
| `MELE_DOTNET` | `dotnet.exe` on `PATH` | The Windows `dotnet.exe`, as a WSL path |
| `MELE_VGMSTREAM` | `vgmstream-cli` | vgmstream. A path that ends in `.exe` gets Windows paths for its files. |
| `MELE_TOOLKIT` | `../../mele-maxgoods-toolkit`, from this repository's folder | A mele-maxgoods-toolkit checkout. The default fits a layout with `<folder>/mele-maxgoods-toolkit` and `<folder>/mods/galaxy-map-normandy`. A relative path you set is read from the folder you run `build.sh` in, so an absolute path is safer. |

## Run

```bash
./build.sh
```

Each step starts with a header line (`== classes`, `== menu`, `== strings`, `== level`, `== sound`, `== sfx`, `== dist`, and `== building <tool>`
when a tool is rebuilt), followed by some of lectool's output. At the end it prints the Windows path of the mod
folder with its `modver`, and the files in its `CookedPCConsole` folder.

## What each step does

### Checks

`build.sh` stops before it builds anything if `MELE_LE_DIR` is not set, if `python3`, `ffmpeg`, `git`, `MELE_DOTNET`
or `MELE_VGMSTREAM` is missing, if `MELE_TOOLKIT` has no `tools/lectool/lectool.csproj`, or if the toolkit's
LegendaryExplorerCore submodule (`tools/mele-mcp/external/LegendaryExplorer`) is not checked out.

### Tools

lectool (`tools/lectool/lectool.csproj`) and mele-mcp (`tools/mele-mcp/src/MeleMcp/MeleMcp.csproj`) are built from the
toolkit with `dotnet build -c Release` into `build/tools/lectool/` and `build/tools/mele-mcp/`. Only the compiler's
error lines are shown. Each tool gets a stamp file, `build/tools/<name>.stamp`, with the toolkit's commit and a hash of
the toolkit's `git status` listing and `git diff HEAD`. A tool is rebuilt only when the stamp changes, so a new commit or
any edit to a tracked file triggers it, but a further edit to an untracked file does not. Delete `build/tools/` to force
a rebuild.

Every lectool command writes its output to `build/lectool.out` and LegendaryExplorerCore's log to `build/lectool.err`.
`MELE_LE_DIR` is passed on to it, so LegendaryExplorerCore uses that game folder instead of the one it finds in the
registry.

### 1. Classes: `Startup_MOD_GalaxyMapNormandy.pcc`

`lectool compileclass` compiles `src/GalaxyMapNormandySettings.uc`, `src/GalaxyMapNormandyShipLight.uc` and
`src/GalaxyMapNormandyDirector.uc` against the game's own script packages. The new file holds the three classes under a
package export `GalaxyMapNormandy`, and an
`ObjectReferencer` named `CombinedStartupReferencer` that keeps them loaded (the layout of the LE1 Community Patch's own
startup packages). `AutoLoad.ini` loads the file when the game starts (`GlobalPackage1=Startup_MOD_GalaxyMapNormandy`),
so the classes are in memory before any level uses them.

### 2. Menu: `ModSettings_Submenus_GalaxyMapNormandy.pcc`

The settings pages, in `src/ModSettingsSubmenu_GalaxyMapNormandy.uc` and `src/ModSettingsSubmenu_GalaxyMapNormandyStep.uc`.
Their base class is the LE1 Community Patch's `ModSettingsSubmenu`: mele-mcp's `export_decompile` reads it from your
installed Community Patch into `build/ModSettingsSubmenu.uc`, and the package carries that copy, as other mods' pages do.
The Mod Settings Menu loads the file by path when the player opens the page.

### 3. Strings: `DLC_MOD_GalaxyMapNormandy_GlobalTlk*.pcc`

The words of the settings pages, and the description of their row on the Mod Settings Menu's first page, are strings
74220001 to 74220022 (7422 is the mod's `ModMount`). `src/tlk/<language>.tsv` holds them, one per line: the id, one tab,
the text, in UTF-8. `lectool tlkpackage` writes one package per language with the exports `GlobalTlk_tlk` and
`GlobalTlk_tlk_M`, and stops if a language lacks an id of `INT.tsv` or has one more.

`AutoLoad.ini` names the English package (`GlobalTalkTable1=DLC_MOD_GalaxyMapNormandy_GlobalTlk.GlobalTlk_tlk`), and the
game adds its language to the file name. `INT.tsv` makes the file without a suffix, the other seven the files `_FR`,
`_DE`, `_IT`, `_ES`, `_PL`, `_RU` and `_JA`. The game also looks for `_FE`, `_GE`, `_IE`, `_RA` and `_PLPC`, which show
the text of `_FR`, `_DE`, `_IT`, `_RU` and `_PL`: `build.sh` copies them, as the LE1 Community Patch's own files are.

The page's subtitle (74220019) sits in a one-line field that clips at about 459 pixels at 14 px: about 40 characters.

To add a string, give it the next id in every `.tsv` file and use it in the `.uc` file as `$<id>`.

### 4. Level: `GalaxyMapNormandy_NOR10.pcc`

mele-mcp's `level_new` tool, called through the toolkit's `tools/mele-mcp/scripts/mcp_call.py`, creates an empty level;
its reply goes to `build/level_new.json`. `lectool addactor` then adds one `GalaxyMapNormandyDirector` actor at the
level's origin, with its class defaults. In the game it is
`GalaxyMapNormandy_NOR10.TheWorld.PersistentLevel.GalaxyMapNormandyDirector_0`.

The Sideloader config in `mod/` makes the LE1 Community Patch load this level whenever a level whose name starts with
`BIOA_NOR10` loads:

```ini
[BioGame.ini SFXGame.SideloaderFramework]
+Levels=(LevelName="GalaxyMapNormandy_NOR10", LoadIfPrefix=("BIOA_NOR10"))
```

### 5. Sound: `build/sound/`

`lectool wwise` (with `LECGAME=LE3`) reads LE3's `SFXGame.pcc` export 53327 and writes the three embedded sounds that
`WEMIDS` names as `.wem` files. `build.sh` checks from lectool's output that the export is the
`Wwise_Generic_Galaxy_Map` bank. vgmstream decodes the three files to WAV. ffmpeg makes the whoosh and the engine loop
from them, a short Python step crossfades the loop's seam, and ffmpeg encodes both as Ogg Vorbis: `travel_whoosh.ogg`
and `travel_loop.ogg`. [ASSETS.md](ASSETS.md) has every gain, trim and length.

### 6. SFX package: `GalaxyMapNormandy_SFX.pcc`

`lectool buildsound` runs twice. Each run clones a cue from LE1's `snd_gui.pcc` and puts one of the Ogg files into its
wave:

| New cue | Donor cue | Channels | Notes |
|---|---|---|---|
| `c_travel_whoosh` | `c_snd_guiswish` | 1 | 44,100 Hz, volume 0.5 |
| `c_travel_loop` | `c_galaxymap_enter` | 2 | 44,100 Hz, volume 0.5; `--loop` adds a looping node |

The cloned wave keeps the donor's name (`snd_gui:c_snd_guiswish`, `snd_gui:c_galaxymap_enter`); only its sound data,
length and channel count change.

`lectool portmesh` then ports the SR-1 static mesh (export 31 of LE1's `BIOA_ICE20_11_LAY.pcc`) with its materials and
textures as `SR1_Normandy`. The build stops if LegendaryExplorerCore reports a broken material.

For the button, `lectool texpng` (with `LECGAME=LE2`) writes LE2's button texture as PNG into `build/button/`, ffmpeg
mirrors it and makes LE1's blue and brown versions of it, and `lectool addtexture` adds the two as `EnterButton_Normal`
and `EnterButton_Hover`.

The director loads these five objects by name at run time: `GalaxyMapNormandy_SFX.SR1_Normandy`,
`GalaxyMapNormandy_SFX.c_travel_whoosh`, `GalaxyMapNormandy_SFX.c_travel_loop`,
`GalaxyMapNormandy_SFX.EnterButton_Normal` and `GalaxyMapNormandy_SFX.EnterButton_Hover`.

### 7. Mod folder: `dist/Galaxy Map Normandy/`

`build.sh` deletes the old folder, copies `mod/` and adds the packages:

```
dist/Galaxy Map Normandy/
    moddesc.ini
    DLC_MOD_GalaxyMapNormandy/
        AutoLoad.ini
        CookedPCConsole/
            ConfigDelta-GalaxyMapNormandy.m3cd
            DLC_MOD_GalaxyMapNormandy_GlobalTlk.pcc
            DLC_MOD_GalaxyMapNormandy_GlobalTlk_<language>.pcc (12 files)
            GalaxyMapNormandy_NOR10.pcc
            GalaxyMapNormandy_SFX.pcc
            ModSettings_Submenus_GalaxyMapNormandy.pcc
            Startup_MOD_GalaxyMapNormandy.pcc
```

## Output files

| Path | What |
|---|---|
| `build/tools/lectool/`, `build/tools/mele-mcp/` | the two tools, and their `.stamp` files next to them |
| `build/Startup_MOD_GalaxyMapNormandy.pcc` | the compiled classes |
| `build/ModSettings_Submenus_GalaxyMapNormandy.pcc`, `build/ModSettingsSubmenu.raw`, `build/ModSettingsSubmenu.uc` | the menu package, and the Community Patch's class as read and as compiled |
| `build/tlk/` | the 13 GlobalTlk packages |
| `build/GalaxyMapNormandy_NOR10.pcc`, `build/level_new.json` | the level, and mele-mcp's reply |
| `build/sound/` | the extracted `.wem` files, the decoded and mixed `.wav` files, the two `.ogg` files |
| `build/button/` | LE2's button texture as PNG (`le2.png`), and the two recoloured copies |
| `build/GalaxyMapNormandy_SFX.pcc` | the two cues, the SR-1 mesh and the button's textures |
| `build/lectool.out`, `build/lectool.out.raw`, `build/lectool.err` | the last lectool command's output, and LegendaryExplorerCore's log |
| `dist/Galaxy Map Normandy/` | the M3 mod folder |
| `dist/GalaxyMapNormandy-v<modver>.zip`, `dist/SHA256SUMS` | the zip that `package.sh` writes, and its checksum ([Package](#package)) |

The startup package rebuilds byte for byte from the same sources. The level and the SFX package come out with
different bytes on every run (the package GUID, the Ogg stream serial) and the same content. A comment-only change in a
`.uc` file changes the compiled startup package by a few bytes, because the compiler keeps line information.

## Changing the mod

Edit `src/*.uc` or `mod/`, run `./build.sh` again and apply the new `dist/Galaxy Map Normandy` with M3, game closed.
To try values before you rebuild, see [tuning.md](tuning.md).

## Package

`./package.sh` runs `build.sh`, then writes `dist/GalaxyMapNormandy-v<modver>.zip` (the `Galaxy Map Normandy` folder,
with `NOTICE` and `LICENSE` added to it) and its checksum in `dist/SHA256SUMS`. With `--no-build` it zips the folder
already in `dist/`, and stops if a file there is missing, added, or differs from `mod/`. M3 imports the zip if you drop
it on its window, with a warning that the mod was not deployed through M3. The zip holds content derived from your game
files ([NOTICE](../NOTICE)), so keep it for your own tests. The Nexus archive is the 7z that M3 makes: turn on Developer
mode in M3's settings, then use Mod Utils > Deploy mod to 7z file for distribution, which checks the mod first and needs
M3's backup of LE1.

## Troubleshooting

The messages come from `build.sh`'s own checks. With your own settings, the program names in them are the values you
set.

| Message | What to do |
|---|---|
| `MELE_LE_DIR: set MELE_LE_DIR to the Legendary Edition folder, as a Windows path` | Set `MELE_LE_DIR` in `build.env` or the environment. |
| `python3 not found`, `ffmpeg not found`, `git not found` | Install it in WSL. |
| `dotnet.exe not found: set MELE_DOTNET to the Windows dotnet.exe (.NET SDK 10.0.402 or later, as the toolkit's global.json asks)` | Set `MELE_DOTNET` to the WSL path of `dotnet.exe`. |
| `vgmstream-cli not found: set MELE_VGMSTREAM (Legendary Explorer ships exec/vgmstream/vgmstream.exe)` | Install `vgmstream-cli` in WSL, or set `MELE_VGMSTREAM` to a `vgmstream.exe`. |
| `no toolkit at <path>: set MELE_TOOLKIT to a mele-maxgoods-toolkit checkout` | Clone mele-maxgoods-toolkit and set `MELE_TOOLKIT` to it. |
| `the toolkit's LEC submodule is missing: git -C '<path>' submodule update --init` | Run the command it shows. |
| `lectool did not build`, `mele-mcp did not build` | The compiler's error lines are printed above it. Check the SDK version, network access for the NuGet restore, and the submodule. |
| `lectool <command> failed` | lectool's output and the last 20 lines of LegendaryExplorerCore's log are printed above it; the full log is `build/lectool.err`. Check that `MELE_LE_DIR` is the right folder and that the game files are there. |
| `could not read ModSettingsSubmenu from LE1CP's ModSettingsMenu.pcc`, `LE1CP's ModSettingsMenu.pcc has no class ModSettingsSubmenu` | Install the LE1 Community Patch 2.0 or later in the game the build reads. |
| `lectool wrote no <language> strings: the toolkit needs tlkpackage` | The toolkit checkout is older than the mod: update it. |
| `level_new failed` | mele-mcp's reply is printed above it (also in `build/level_new.json`). |
| `SFXGame.pcc export 53327 is not the Wwise_Generic_Galaxy_Map bank` | The build finds the bank by export number in LE3's `SFXGame.pcc`. A different `SFXGame.pcc` (another game version, or one a mod has changed) can move it. |
| `WEM <id> was not in the bank` | Same cause: the bank does not hold the sound the build expects. |
| `broken material in the SR-1 port` | The `BROKEN material` lines above it name the material LegendaryExplorerCore reports as broken. |
