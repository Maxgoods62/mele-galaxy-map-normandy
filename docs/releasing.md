# Releasing Galaxy Map Normandy

GitHub can't build this mod, because the build reads the game files. The 7z for players holds content taken from the
games, so it goes on Nexus Mods only. The GitHub release holds one file, `SHA256SUMS`, with the hash of that 7z, and
notes. [`scripts/release.sh`](../scripts/release.sh) checks every step and publishes the release.

## First setup

Run `scripts/protect-repo.sh` once, right after the repo goes public and before the first release.

| Setting | What it stops |
|---|---|
| Immutable releases | No one can change a published release's files or move its tag. A deleted release's tag name can't be used again. |
| Ruleset `release tags are final` | No one can move or delete a `v*` tag, the admin included. |
| Ruleset `only admins create release tags` | Only the admin can create a `v*` tag. |
| Ruleset `main` | No one can force-push to `main` or delete it. Direct pushes stay allowed. |
| Actions policy | Only GitHub's own actions, pinned to a commit, can run, and a fork's pull request needs approval to run one. The repo has no workflows, so this only limits a workflow added later. |

The script skips its Pages step here, because the repo has no workflow. The toolkit repo, mele-maxgoods-toolkit, must
be public too: under the GPL, the tools that build the mod must be public. `publish` refuses otherwise.

## Publish a version

The version is `modver` in `mod/moddesc.ini`, and the tag is `v` and that version, as in `v0.27`.

1. Create the Nexus page. Set `modsite` in `mod/moddesc.ini` to its URL, and replace `NEXUS_PAGE_URL` in `README.md`
   with it. Date the version's heading in `CHANGELOG.md` with the day you publish: `## v<version> (YYYY-MM-DD)`. Set
   `TOOLKIT_COMMIT` in `build.sh` to the toolkit commit you build with, which must be on the toolkit's `main` on
   GitHub. Commit and push `main`.
2. Run `./build.sh`, then `scripts/release.sh check v<version>`.
3. In M3, delete the mod's old folder from the mod library, copy `dist/Galaxy Map Normandy` there, and refresh the mod
   library. A copy on top of the old folder can ship stale files. Then use Mod Utils > Deploy mod to 7z file for
   distribution, which needs Developer mode in M3's settings and M3's backup of LE1. Keep the file name that M3
   proposes, `GalaxyMapNormandy_<version>.7z`, because `SHA256SUMS` names that file. Read every warning: only errors
   stop the Deploy button.
4. Run `scripts/release.sh archive v<version> <7z>`. It checks that M3 made the 7z and that it holds exactly
   `dist/Galaxy Map Normandy`.
5. Install the 7z with M3 and test it in the game.
6. Upload the 7z to the Nexus page. Download it back once.
7. Run `scripts/release.sh publish v<version> <deployed 7z> <downloaded 7z>`. It runs every check again, compares the
   two files, writes `dist/release/SHA256SUMS` and `dist/release/notes.md`, and asks you to type the tag. Then GitHub
   creates the release and its tag on the commit you pushed. If GitHub refuses, no tag is left behind.
8. Once the Nexus page is public, register the DLC folder name and the mount priority with M3: Mod Utils > Submit mod
   information to ME3Tweaks. Then update the Compatibility section of `README.md`. The form reads the mod's name from
   `NameStrRef` in the `[GUI]` section of `AutoLoad.ini`. This mod has none yet, so the form lists nothing for it.
   Adding one needs a name string in every `src/tlk/*.tsv` file and a test in the game.

## What the hash proves

The hash proves that a file from Nexus is the one the maintainer published. The release is immutable, so its
`SHA256SUMS` file can't change, though its notes can. It does not prove that the 7z was built from the tag, or that the
PC and the game files used for the build were clean. Each build gives the packages new bytes, so a rebuild can't check
it either.

## Check a download

Nexus renames the file you download, so compare the hash value, not the file name. `sha256sum -c` looks for the file by
its name, so it fails on a renamed download. In PowerShell:

```powershell
(Get-FileHash -Algorithm SHA256 -LiteralPath "<file>").Hash.ToLower()
```

The result must match the hash in the release's `SHA256SUMS` file, not a copy of it in the notes. To check that this
`SHA256SUMS` is the release's own, use the [GitHub CLI](https://cli.github.com), signed in with `gh auth login`:

```bash
gh release download v<version> -R Maxgoods62/mele-galaxy-map-normandy -p SHA256SUMS
gh release verify-asset v<version> SHA256SUMS -R Maxgoods62/mele-galaxy-map-normandy
```

Without the GitHub CLI, hash the `SHA256SUMS` file itself and compare that with the digest the release page shows next
to it: that digest is the hash of `SHA256SUMS`, not of the 7z. `gh release verify-asset` on the 7z always fails,
because the 7z is not on GitHub.
