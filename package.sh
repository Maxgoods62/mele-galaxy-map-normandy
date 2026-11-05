#!/usr/bin/env bash
# Zip the M3 mod folder for local tests: dist/GalaxyMapNormandy-v<modver>.zip and its checksum in dist/SHA256SUMS. The
# zip holds the folder "Galaxy Map Normandy" alone: moddesc.ini at its root, as ME3Tweaks Mod Manager imports it, and
# the LICENSE folder (LICENSE, NOTICE) and README.txt that build.sh puts there. The mod is for LE1 only, so no folder is
# named after the game.
#   ./package.sh              run ./build.sh first
#   ./package.sh --no-build   zip the dist/Galaxy Map Normandy that is already there
# The zip contains content derived from the game files (NOTICE). The public archive is the 7z that M3's own deployment
# makes (docs/releasing.md).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAME="Galaxy Map Normandy"
DIST="$HERE/dist"
MOD="$DIST/$NAME"
PACKAGES=(Startup_MOD_GalaxyMapNormandy GalaxyMapNormandy_NOR10 GalaxyMapNormandy_SFX ModSettings_Submenus_GalaxyMapNormandy
    DLC_MOD_GalaxyMapNormandy_GlobalTlk DLC_MOD_GalaxyMapNormandy_GlobalTlk_{DE,ES,FE,FR,GE,IE,IT,JA,PL,PLPC,RA,RU})

die() { echo "package.sh: $*" >&2; exit 1; }

command -v python3 >/dev/null || die "python3 not found"
case "$*" in
    "") "$HERE/build.sh" ;;
    --no-build) ;;
    *) die "usage: ./package.sh [--no-build]" ;;
esac

modver="$(sed -n 's/^modver=//p' "$HERE/mod/moddesc.ini" | tr -d '\r')"
[[ "$modver" =~ ^[0-9A-Za-z._-]+$ ]] || die "no usable modver in mod/moddesc.ini: '$modver'"

# mod_files: the files of mod/ that build.sh copies, NUL-separated and relative to mod/: in a git checkout the files git
# sees, committed or new, and not those it ignores.
mod_files() {
    if [[ "$(git -C "$HERE" rev-parse --show-toplevel 2> /dev/null)" -ef "$HERE" ]]; then
        git -C "$HERE" ls-files -z --cached --others --exclude-standard -- mod | sed -z 's|^mod/||' | sort -zu \
            | while IFS= read -r -d '' f; do if [[ -f "$HERE/mod/$f" ]]; then printf '%s\0' "$f"; fi; done
    else
        (cd "$HERE/mod" && find . -type f -print0 | sed -z 's|^\./||')
    fi
}

# With --no-build the folder may be an older build: each of those files of mod/ must be there unchanged, the packages
# and the two license texts present, and nothing else.
[[ -d "$MOD" ]] || die "no $MOD: run ./package.sh without --no-build"
LIST="$(mktemp)"
trap 'rm -f "$LIST"' EXIT
mod_files > "$LIST"
n=0
while IFS= read -r -d '' rel; do
    [[ -f "$MOD/$rel" ]] || die "missing $NAME/$rel"
    cmp -s "$HERE/mod/$rel" "$MOD/$rel" || die "$NAME/$rel differs from mod/$rel: run ./package.sh without --no-build"
    n=$((n + 1))
done < "$LIST"
for p in "${PACKAGES[@]}"; do
    [[ -s "$MOD/DLC_MOD_GalaxyMapNormandy/CookedPCConsole/$p.pcc" ]] || die "missing or empty $p.pcc in $NAME"
done
for f in LICENSE NOTICE; do
    [[ -s "$HERE/$f" ]] || die "missing $f"
    cmp -s "$HERE/$f" "$MOD/LICENSE/$f" || die "$NAME/LICENSE/$f is missing or differs from $f: run ./package.sh without --no-build"
done
(( $(find "$MOD" -type f | wc -l) == n + ${#PACKAGES[@]} + 2 )) \
    || die "$NAME holds files that build.sh does not put there: run ./package.sh without --no-build"

ZIP="GalaxyMapNormandy-v$modver.zip"
rm -f "$DIST/$ZIP" "$DIST/$ZIP.tmp" "$DIST/SHA256SUMS"
python3 -I - "$DIST/$ZIP.tmp" "$DIST" "$NAME" <<'EOF'
import os, sys, zipfile
out, dist, name = sys.argv[1:]
files = []
for root, dirs, names in os.walk(os.path.join(dist, name)):
    dirs.sort()
    files += [os.path.join(root, n) for n in sorted(names)]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for f in files:
        z.write(f, os.path.relpath(f, dist))
with zipfile.ZipFile(out) as z:
    bad = z.testzip()
    if bad:
        sys.exit("package.sh: bad CRC for " + bad)
EOF
mv "$DIST/$ZIP.tmp" "$DIST/$ZIP"
(cd "$DIST" && sha256sum "$ZIP" > SHA256SUMS)

python3 -I -m zipfile -l "$DIST/$ZIP"
cat "$DIST/SHA256SUMS"
