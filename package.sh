#!/usr/bin/env bash
# Zip the M3 mod folder: dist/GalaxyMapNormandy-v<modver>.zip and its checksum in dist/SHA256SUMS. The zip holds the
# folder "Galaxy Map Normandy" (moddesc.ini at its root, as ME3Tweaks Mod Manager imports it) with NOTICE and LICENSE.
#   ./package.sh              run ./build.sh first
#   ./package.sh --no-build   zip the dist/Galaxy Map Normandy that is already there
# The zip contains content derived from the player's own game files (NOTICE). It is for local testing: a public copy
# goes only to Nexus, after asking ME3Tweaks, as the 7z that M3's own deployment makes (docs/building.md).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAME="Galaxy Map Normandy"
DIST="$HERE/dist"
MOD="$DIST/$NAME"
PACKAGES=(Startup_MOD_GalaxyMapNormandy GalaxyMapNormandy_NOR10 GalaxyMapNormandy_SFX ModSettings_Submenus_GalaxyMapNormandy)

die() { echo "package.sh: $*" >&2; exit 1; }

command -v python3 >/dev/null || die "python3 not found"
case "$*" in
    "") "$HERE/build.sh" ;;
    --no-build) ;;
    *) die "usage: ./package.sh [--no-build]" ;;
esac

modver="$(sed -n 's/^modver=//p' "$HERE/mod/moddesc.ini" | tr -d '\r')"
[[ "$modver" =~ ^[0-9A-Za-z._-]+$ ]] || die "no usable modver in mod/moddesc.ini: '$modver'"

# With --no-build the folder may be an older build: each file of mod/ must be there unchanged, the packages
# present, and nothing else.
[[ -d "$MOD" ]] || die "no $MOD: run ./package.sh without --no-build"
while IFS= read -r -d '' f; do
    rel="${f#"$HERE/mod/"}"
    [[ -f "$MOD/$rel" ]] || die "missing $NAME/$rel"
    cmp -s "$f" "$MOD/$rel" || die "$NAME/$rel differs from mod/$rel: run ./package.sh without --no-build"
done < <(find "$HERE/mod" -type f -print0)
for p in "${PACKAGES[@]}"; do
    [[ -s "$MOD/DLC_MOD_GalaxyMapNormandy/CookedPCConsole/$p.pcc" ]] || die "missing or empty $p.pcc in $NAME"
done
(( $(find "$MOD" -type f | wc -l) == $(find "$HERE/mod" -type f | wc -l) + ${#PACKAGES[@]} )) \
    || die "$NAME holds files that build.sh does not put there: run ./package.sh without --no-build"
for f in NOTICE LICENSE; do [[ -s "$HERE/$f" ]] || die "missing $f"; done

ZIP="GalaxyMapNormandy-v$modver.zip"
rm -f "$DIST/$ZIP" "$DIST/$ZIP.tmp" "$DIST/SHA256SUMS"
python3 -I - "$DIST/$ZIP.tmp" "$DIST" "$NAME" "$HERE/NOTICE" "$HERE/LICENSE" <<'EOF'
import os, sys, zipfile
out, dist, name, *extra = sys.argv[1:]
files = []
for root, dirs, names in os.walk(os.path.join(dist, name)):
    dirs.sort()
    files += [os.path.join(root, n) for n in sorted(names)]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for f in files:
        z.write(f, os.path.relpath(f, dist))
    for f in extra:
        z.write(f, name + "/" + os.path.basename(f))
with zipfile.ZipFile(out) as z:
    bad = z.testzip()
    if bad:
        sys.exit("package.sh: bad CRC for " + bad)
EOF
mv "$DIST/$ZIP.tmp" "$DIST/$ZIP"
(cd "$DIST" && sha256sum "$ZIP" > SHA256SUMS)

python3 -I -m zipfile -l "$DIST/$ZIP"
cat "$DIST/SHA256SUMS"
