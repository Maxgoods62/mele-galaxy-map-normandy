# Building Galaxy Map Normandy

`build.sh` builds the mod from this repo and your own copy of the games. It runs in WSL and only reads the game
files. In this repo it writes only into `build/` and `dist/`, which git ignores. The result is the folder
`dist/Galaxy Map Normandy`, which you install with ME3Tweaks Mod Manager (M3) while the game is closed.

## What you need

| What | Used for |
|---|---|
| Windows with WSL | `build.sh` is a bash script that runs Windows programs through WSL. |
| `python3`, `ffmpeg` and `git` in WSL | `build.sh` stops without them. |
| .NET SDK 10.0.402 or a later 10.0 SDK, for Windows | Building lectool and mele-mcp |
| .NET 8 runtime, x64, for Windows | Running lectool and mele-mcp |
| vgmstream | Decoding the LE3 sounds |
| A git clone of the toolkit, with its submodule | lectool and mele-mcp, the build's tools |
| LE1 and LE3 in one Legendary Edition folder | The build reads files from both games. |
| LE1 Community Patch 2.0 or later, installed in LE1 | The settings pages are built on its Mod Settings Menu. |

Python needs only its standard library, and ffmpeg needs the `libvorbis` encoder. The .NET 10 SDK does not include
the .NET 8 runtime. The first build downloads NuGet packages, so it needs network access. vgmstream can be
`vgmstream-cli` in WSL, or the Windows `vgmstream.exe` that Legendary Explorer ships in `exec/vgmstream/`.

### Game files

The build reads `BIOA_ICE20_11_LAY.pcc` and `snd_gui.pcc` from LE1, and `SFXGame.pcc`, `Startup.pcc` and
`BioA_Nor_203aGalaxyMap.pcc` from LE3. Each one is in `Game\ME<n>\BioGame\CookedPCConsole` in the
Legendary Edition folder. From the Community Patch folder, `Game\ME1\BioGame\DLC\DLC_MOD_LE1CP`, it reads
`CookedPCConsole\ModSettingsMenu.pcc` and `_metacmm.txt`. [ASSETS.md](ASSETS.md#files-the-build-reads) says what it does
with each one.

### The toolkit

The build's tools, [lectool](https://github.com/Maxgoods62/mele-maxgoods-toolkit/blob/main/tools/lectool/README.md) and
[mele-mcp](https://github.com/Maxgoods62/mele-maxgoods-toolkit/blob/main/tools/mele-mcp/README.md), come from
[mele-maxgoods-toolkit](https://github.com/Maxgoods62/mele-maxgoods-toolkit). Clone it with its submodule,
LegendaryExplorerCore (LEC), the library both tools are built on:

```bash
git clone https://github.com/Maxgoods62/mele-maxgoods-toolkit.git
git -C mele-maxgoods-toolkit submodule update --init
```

By default `build.sh` looks for the toolkit at `../../mele-maxgoods-toolkit` from this repo's folder. That is
`<folder>/mele-maxgoods-toolkit` when this repo is `<folder>/mods/galaxy-map-normandy`. Set `MELE_TOOLKIT` for any
other place.

`TOOLKIT_COMMIT` near the top of `build.sh` is the toolkit commit that releases are built with. `build.env` can't
change it. At another commit, the build goes on and prints a note, so a recent checkout works for a test build.
Uncommitted changes in the toolkit print nothing: the tools are built with them, and the build stamp counts them.
`scripts/release.sh` refuses both kinds of build. To build at the pinned commit, run this in this repo's folder:

```bash
git -C <toolkit> checkout "$(sed -n 's/^TOOLKIT_COMMIT=//p' build.sh)"
git -C <toolkit> submodule update --init
```

## Settings

`build.sh` reads its settings from `build.env` next to it, or from the environment. `build.env` is not in git. Copy
the example and fix its paths:

```bash
cp build.env.example build.env
```

| Variable | Default | Path | What |
|---|---|---|---|
| `MELE_LE_DIR` | None: required | Windows | The Legendary Edition folder |
| `MELE_DOTNET` | `dotnet.exe` on `PATH` | WSL | The Windows `dotnet.exe` |
| `MELE_VGMSTREAM` | `vgmstream-cli` on `PATH` | WSL | vgmstream |
| `MELE_TOOLKIT` | `../../mele-maxgoods-toolkit` from this repo | WSL | The toolkit clone |

`MELE_LE_DIR` is the folder that holds `Game\ME1`, `Game\ME2` and `Game\ME3`. `build.env` is a bash file that
`build.sh` sources first, so a variable set there replaces the same one from the environment. When
`MELE_VGMSTREAM` ends in `.exe`, the build passes it Windows paths. A relative `MELE_TOOLKIT` is read from the folder
you run `build.sh` in, so an absolute path is safer.

## Run

```bash
./build.sh
```

It takes no options. Each step prints a header line, such as `== classes`. Lines that start with `note:` are about the
toolkit commit, the patch version or a file left out. At the end, a `built` line gives the Windows path of the mod
folder and its `modver`. The files of its `CookedPCConsole` folder and the `stamp:` lines follow.

The tools are rebuilt only when the toolkit's commit or one of its files changed since the last build. New files count,
and so do files whose edits git hides with `git update-index`. A file that git ignores does not, so delete
`build/tools/` to force a rebuild after you edit one. A toolkit that is not a git checkout gets its tools built every
time.

## What the build makes

| Header | Output | What it is |
|---|---|---|
| `== building <tool>` | `build/tools/lectool/`, `build/tools/mele-mcp/` | The two tools, when rebuilt |
| `== classes` | `build/Startup_MOD_GalaxyMapNormandy.pcc` | The mod's classes, loaded at game start |
| `== menu` | `build/ModSettings_Submenus_GalaxyMapNormandy.pcc` | The settings pages |
| `== strings` | `build/tlk/` | The mod's name, the menu's text, the number patterns and the button's words, 13 packages |
| `== level` | `build/GalaxyMapNormandy_NOR10.pcc` | A small level that holds the director |
| `== sound` | `build/sound/` | The travel sound and the flight sound waves |
| `== sfx` | `build/GalaxyMapNormandy_SFX.pcc` | The sound cues, the SR-1 model and the engine trail |
| `== dist` | `dist/Galaxy Map Normandy/` | The M3 mod folder |
| None, last | `dist/build.stamp` | What the build was made from |

The `.uc` files in `src/` are UnrealScript, the game's script language. mele-mcp decompiles the menu's base class
from your installed Community Patch into `build/ModSettingsSubmenu.uc`
([ASSETS.md](ASSETS.md#the-community-patch-settings-page-class)). The strings come from `src/tlk/<language>.tsv`, and
each file must have exactly the ids of `INT.tsv`. Each package holds the talk tables `GlobalTlk_tlk` and
`GlobalTlk_tlk_M`, both with every id ([how-it-works.md](how-it-works.md#translate-the-mod)).

The flight sound waves belong to the variant that `FlightSound` names. That value is in the defaultproperties block,
the class defaults at the end of `src/GalaxyMapNormandyDirector.uc`. With `FlightSound = 0` the build makes none.
[ASSETS.md](ASSETS.md#flight-sound-variants) says how the sounds and the model are made.

`build/` also keeps each step's work files. `build/lectool.out` holds the output of the last lectool command that
worked. The last command's raw output, even if it failed, is in `build/lectool.out.raw`, and its log in
`build/lectool.err`. In `dist/`, `package.sh` writes its zip and `SHA256SUMS`, and `scripts/release.sh` writes
`release/`.

### The mod folder

The dist step deletes the old mod folder and makes it again:

```text
dist/Galaxy Map Normandy/
    moddesc.ini
    README.txt
    LICENSE/
        LICENSE
        NOTICE
    DLC_MOD_GalaxyMapNormandy/
        AutoLoad.ini
        CookedPCConsole/
            ConfigDelta-GalaxyMapNormandy.m3cd
            DLC_MOD_GalaxyMapNormandy_GlobalTlk*.pcc (13 files)
            GalaxyMapNormandy_NOR10.pcc
            GalaxyMapNormandy_SFX.pcc
            ModSettings_Submenus_GalaxyMapNormandy.pcc
            Startup_MOD_GalaxyMapNormandy.pcc
```

It copies the files of `mod/` that git sees, committed or new. A file that git ignores, such as a stray `.pcc`, is left
out with a note. Without git, every file of `mod/` is copied. M3 refuses to load the mod when `README.txt` or the
`LICENSE` folder is missing, because the `[UPDATES]` section of `moddesc.ini` names them.

### The build stamp

`dist/build.stamp` says what the build was made from, one `key=value` per line. `modver` comes from
`mod/moddesc.ini`. `mod_commit` and `toolkit_commit` are the two commits. `mod_dirty` and `toolkit_dirty` count their
uncommitted changes, with submodules and the edits that git hides (`git update-index --skip-worktree` or
`--assume-unchanged`). `le1cp` is the patch version or `unknown`, and `files` is one SHA-256 over every file of the mod
folder.

A count is `changed` when that repo changed during the build. Without git, this repo's commit and count are `none`. A
build that stops leaves no stamp. `scripts/release.sh` checks the stamp against the repo, the toolkit and the mod
folder.

## Change the mod

Edit `src/` or `mod/`, run `./build.sh` again and install the new folder as below. [tuning.md](tuning.md) shows how to
try the director's values in a running game first. [how-it-works.md](how-it-works.md) says what each file holds.

## Install your build

1. Close the game.
2. In M3's mod library, open the `LE1` folder. Delete the old `Galaxy Map Normandy` folder if there is one. A copy on
   top of it can leave old files behind.
3. Copy `dist/Galaxy Map Normandy` into that `LE1` folder. The `built` line of the build gives its Windows path.
4. In M3, refresh the mod library, select Galaxy Map Normandy and click Apply Mod.

## Package

`./package.sh` runs `build.sh`, then zips the mod folder into `dist/GalaxyMapNormandy-v<modver>.zip` and writes its
checksum into `dist/SHA256SUMS`. The zip holds the `Galaxy Map Normandy` folder alone, with `moddesc.ini` at its top.
If you drop the zip on M3's window, M3 imports it with a warning that the mod was not deployed through M3.

`./package.sh --no-build` zips the folder already in `dist/`. It stops if a file there is missing or extra, or differs
from `mod/`, `LICENSE` or `NOTICE`. It also stops when `dist/build.stamp` is missing: the last build stopped, and the
folder may be the build before it.

The zip holds content made from your game files ([NOTICE](../NOTICE)), so keep it for your own tests. Players get the
7z that M3's Deploy mod makes, on Nexus Mods only.

## Releases

`scripts/release.sh` checks and publishes a release, and its steps are at the top of the script. The toolkit page
[Releasing my mods](https://github.com/Maxgoods62/mele-maxgoods-toolkit/blob/main/docs/releasing.md) says how my mods
are released, and how to check a download.

## Troubleshooting

`build.sh`'s own messages start with `build.sh:`. When a message names a program or a path, it shows the value you set.

- `MELE_LE_DIR: set MELE_LE_DIR to the Legendary Edition folder, as a Windows path`: set it in `build.env`.
- `<program> not found`: install `python3`, `ffmpeg`, `git` or `vgmstream-cli` in WSL, or set `MELE_DOTNET` or
  `MELE_VGMSTREAM` as the message says.
- `no toolkit at <path>` or `the toolkit's LEC submodule is missing`: clone the toolkit as above, or fix
  `MELE_TOOLKIT`. A toolkit copied without git builds, but its tools are rebuilt each time and `scripts/release.sh`
  refuses the build.
- `lectool did not build` or `mele-mcp did not build`: the build shows only the compiler lines that contain ` error `.
  An error `CS0121` about `CopyTo` means an SDK older than 10. Also check the SDK, the network for the first NuGet
  download, and the submodule. For the whole output, run `dotnet.exe build lectool.csproj -c Release` in the toolkit's
  `tools/lectool`, or `dotnet.exe build src/MeleMcp/MeleMcp.csproj -c Release` in `tools/mele-mcp`.
- `lectool <command> failed`: lectool's output and the end of its log are printed above it, and the whole log is in
  `build/lectool.err`. For `compileclass`, the `log:` lines show the script errors. For `tlkpackage`, a `.tsv` file
  lacks an id of `INT.tsv` or has an extra one. For other commands, check `MELE_LE_DIR` and the game files. If the
  first command fails with a message about .NET, install the .NET 8 x64 runtime.
- `could not read ModSettingsSubmenu ...` or `... has no class ModSettingsSubmenu`: install the LE1 Community Patch 2.0
  or later in the game that `MELE_LE_DIR` names. If it is there, the lines above say why mele-mcp failed.
- `note: no LE1 Community Patch version ...`: the build can't read `_metacmm.txt`, so the stamp says `le1cp=unknown`.
  Check the patch install.
- `lectool wrote no <language> strings` or `lectool gave <cue> no wave of its own`: the
  toolkit is older than the mod. Check out `TOOLKIT_COMMIT`.
- `level_new failed`: mele-mcp's reply is printed above it and kept in `build/level_new.json`.
- `SFXGame.pcc export 53327 is not the Wwise_Generic_Galaxy_Map bank` or `WEM <id> was not in the bank`: the build
  finds the sound bank by its export number, its place in the package. Another game version, or a mod that changed
  LE3's `SFXGame.pcc`, can move it.
- `no EngineTrail`: the toolkit has no `lectool portfx`, so check out `TOOLKIT_COMMIT`. If it has, export 757 of
  LE3's `BioA_Nor_203aGalaxyMap.pcc` is not the engine trail: another game version or a mod moved it.
- `ERROR ... can't load it` or `ERROR broken material` from portfx: an object of the engine trail did not come across
  from LE3. The line names it.
- `no FlightSound in the director's defaultproperties`: the build reads the line `FlightSound = <n>` near the end of
  `src/GalaxyMapNormandyDirector.uc`. Keep that form: only spaces before it, one space on each side of `=`, and nothing
  after the number.
- `flight_sounds.py: no flight sound variant <n>`: set `FlightSound` to one of the numbers the message lists.
- `broken material in the SR-1 port`: the `BROKEN material` lines above it name the material that LEC reports as broken.
- `no moddesc.ini among the files of mod/ that git sees`: `mod/moddesc.ini` is missing, or git ignores it.
- ffmpeg stops on the `libvorbis` encoder: install an ffmpeg that has it.
- `package.sh: ... run ./package.sh without --no-build`: the folder in `dist/` does not match the sources, or the last
  build stopped before its end. Run `./package.sh` alone.
