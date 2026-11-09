#!/usr/bin/env bash
# Check and publish a release of Galaxy Map Normandy. Its archive is the 7z that ME3Tweaks Mod Manager's deployment
# makes, uploaded to Nexus Mods only. The GitHub release holds SHA256SUMS for that 7z, and notes. How my mods are
# released and checked: docs/releasing.md in mele-maxgoods-toolkit.
#   scripts/release.sh check v<modver>                        every gate before M3's deployment
#   scripts/release.sh archive v<modver> <7z>                 the deployed 7z holds exactly dist/Galaxy Map Normandy
#   scripts/release.sh publish v<modver> <7z> <downloaded>    all gates, then the GitHub release once you confirm
# Needs git, gh (logged in as the repo's admin), python3 and a 7z reader: 7zz, 7z, bsdtar or Windows' tar.exe. The
# toolkit is MELE_TOOLKIT, read as build.sh reads it. Writes only dist/release/, and the release on GitHub. It never runs
# git tag, git push or gh release delete: GitHub creates the tag when the release publishes.
#
# Once, right after the repo goes public and before the first release: run scripts/protect-repo.sh. It skips its Pages
# step here, because this repo has no workflow. The toolkit repo must be public too, because the GPL needs the tools
# that build the mod to be public: publish refuses otherwise.
#
# The steps for a version. The tag is v and modver from mod/moddesc.ini, as in v1.0.
#  1. Set modver in mod/moddesc.ini to the new version. For the first release, create the Nexus page, set modsite in
#     mod/moddesc.ini to its URL, and put that URL in place of NEXUS_PAGE_URL in README.md. Date the version's heading in CHANGELOG.md with the day you publish: ## v<modver> (YYYY-MM-DD). Set
#     TOOLKIT_COMMIT in build.sh to the toolkit commit you build with, which must be on the toolkit's main on GitHub.
#     Commit and push main.
#  2. Run ./build.sh, then scripts/release.sh check v<modver>.
#  3. In M3, delete the mod's old folder from the mod library, copy dist/Galaxy Map Normandy there, and refresh the mod
#     library: a copy on top of the old folder can ship stale files. Then use Mod Utils > Deploy mod to 7z file for
#     distribution, which needs Developer mode in M3's settings and M3's backup of LE1. Keep the file name M3 proposes,
#     GalaxyMapNormandy_<modver>.7z, because SHA256SUMS names that file. Read every warning: only errors stop Deploy.
#  4. Run scripts/release.sh archive v<modver> <7z>.
#  5. Install the 7z with M3 and test it in the game.
#  6. Upload the 7z to the Nexus page. Download it back once.
#  7. Run scripts/release.sh publish v<modver> <deployed 7z> <downloaded 7z>. It runs every check again, compares the two
#     files, writes dist/release/SHA256SUMS and dist/release/notes.md, and asks you to type the tag. GitHub then creates
#     the release and its tag on the commit you pushed. If GitHub refuses, no tag is left behind.
#  8. Once the Nexus page is public, register the DLC folder name and the mount priority with M3: Mod Utils > Submit mod
#     information to ME3Tweaks. Then update the Compatibility section of README.md. The form lists the DLC folder only
#     if AutoLoad.ini has a NameStrRef in its [GUI] section. This mod's is 74220000, the mod's name in src/tlk/*.tsv.
#     The form sends modname from mod/moddesc.ini as the mod's name.
set -euo pipefail

REPO=Maxgoods62/mele-galaxy-map-normandy
TOOLKIT_REPO=Maxgoods62/mele-maxgoods-toolkit
NAME="Galaxy Map Normandy"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$HERE/dist/$NAME"
STAMP="$HERE/dist/build.stamp"
OUT="$HERE/dist/release"
# The packages build.sh writes into the mod folder, as package.sh lists them.
PACKAGES=(Startup_MOD_GalaxyMapNormandy GalaxyMapNormandy_NOR10 GalaxyMapNormandy_SFX ModSettings_Submenus_GalaxyMapNormandy
    DLC_MOD_GalaxyMapNormandy_GlobalTlk DLC_MOD_GalaxyMapNormandy_GlobalTlk_{DE,ES,FE,FR,GE,IE,IT,JA,PL,PLPC,RA,RU})
USAGE="usage: scripts/release.sh check v<modver>
       scripts/release.sh archive v<modver> <7z from M3's Deploy mod>
       scripts/release.sh publish v<modver> <7z from M3's Deploy mod> <the same 7z downloaded back from Nexus>
The steps are at the top of scripts/release.sh."

die() { echo "release.sh: $*" >&2; exit 1; }

# manifest_hash <folder>: the SHA-256 of the sorted list of its files with their own SHA-256, as build.sh writes it
# into dist/build.stamp.
manifest_hash() { (cd "$1" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 -r sha256sum) | sha256sum | cut -c1-64; }

# listing <folder>: its folders and its files with their SHA-256, sorted, to compare two trees.
listing() { (cd "$1" && { find . -type d | sed 's|$|/|'; find . -type f -print0 | xargs -0 -r sha256sum; } | LC_ALL=C sort); }

# stamp_get <key>: its value in dist/build.stamp, or "(twice)" when the stamp has the key more than once.
stamp_get() {
    local v
    v="$(sed -n "s/^$1=//p" "$STAMP")"
    if [[ "$v" == *$'\n'* ]]; then v="(twice)"; fi
    printf '%s' "$v"
}

version_ge() { [[ "$1" =~ ^[0-9]+(\.[0-9]+)*$ && "$(printf '%s\n' "$2" "$1" | sort -V | head -1)" == "$2" ]]; }

abspath() { if [[ "$1" == /* ]]; then printf '%s' "$1"; else printf '%s' "$PWD/$1"; fi; }

# github_tag <tag>: prints refs/tags/<tag> when the repo on GitHub has that tag, and nothing when it has not. It fails
# when gh can't read the tags. origin may be a mirror or another clone, so the tag gates ask GitHub too.
github_tag() { gh api "repos/$REPO/git/matching-refs/tags/$1" --jq ".[]|select(.ref==\"refs/tags/$1\")|.ref"; }

# moddesc_coder <7z>: reads the 7z's header, as M3 does on import. Exits 0 when the root moddesc.ini is stored with
# the Copy method alone (uncompressed), 1 when it is compressed, and 2 with a message when the header can't be read or
# has no moddesc.ini at the root.
moddesc_coder() {
    python3 -I - "$1" <<'EOF'
import lzma, struct, sys


class R:
    def __init__(self, b):
        self.b, self.i = b, 0

    def byte(self):
        v = self.b[self.i]
        self.i += 1
        return v

    def take(self, n):
        if self.i + n > len(self.b):
            raise ValueError("short")
        v = self.b[self.i:self.i + n]
        self.i += n
        return v

    def num(self):
        first, v = self.byte(), 0
        for k in range(8):
            if not first & (0x80 >> k):
                return v | ((first & ((0x80 >> k) - 1)) << (8 * k))
            v |= self.byte() << (8 * k)
        return v

    def bits(self, n):
        out, b, mask = [], 0, 0
        for _ in range(n):
            if not mask:
                b, mask = self.byte(), 0x80
            out.append(bool(b & mask))
            mask >>= 1
        return out

    def defined(self, n):
        return [True] * n if self.byte() else self.bits(n)


def streams(r):
    pack_pos, folders, nsub = 0, [], None
    while True:
        t = r.byte()
        if t == 0:
            return pack_pos, folders, nsub if nsub is not None else [1] * len(folders)
        if t == 6:  # PackInfo
            pack_pos, n = r.num(), r.num()
            while (t := r.byte()) != 0:
                if t == 9:
                    [r.num() for _ in range(n)]
                elif t == 10:
                    [r.take(4) for d in r.defined(n) if d]
                else:
                    raise ValueError("pack info")
        elif t == 7:  # UnPackInfo
            if r.byte() != 11:
                raise ValueError("folder")
            nf = r.num()
            if r.byte() != 0:
                raise ValueError("external")
            for _ in range(nf):
                coders, tin, tout = [], 0, 0
                for _ in range(r.num()):
                    flag = r.byte()
                    if flag & 0x80:
                        raise ValueError("alternative coders")
                    cid = bytes(r.take(flag & 0x0F))
                    nin, nout = (r.num(), r.num()) if flag & 0x10 else (1, 1)
                    props = bytes(r.take(r.num())) if flag & 0x20 else b""
                    coders.append((cid, props))
                    tin, tout = tin + nin, tout + nout
                bound = [(r.num(), r.num())[1] for _ in range(tout - 1)]
                if tin - (tout - 1) > 1:
                    [r.num() for _ in range(tin - (tout - 1))]
                folders.append({"coders": coders, "tout": tout, "bound": bound})
            if r.byte() != 12:
                raise ValueError("unpack sizes")
            for fo in folders:
                sizes = [r.num() for _ in range(fo["tout"])]
                fo["size"] = next(s for k, s in enumerate(sizes) if k not in fo["bound"])
            t = r.byte()
            if t == 10:
                for fo, d in zip(folders, r.defined(nf)):
                    fo["crc"] = d
                    if d:
                        r.take(4)
                t = r.byte()
            if t != 0:
                raise ValueError("unpack info")
        elif t == 8:  # SubStreamsInfo
            nsub = [1] * len(folders)
            t = r.byte()
            if t == 13:
                nsub = [r.num() for _ in range(len(folders))]
                t = r.byte()
            if t == 9:
                for n in nsub:
                    [r.num() for _ in range(n - 1)]
                t = r.byte()
            while t != 0:
                if t != 10:
                    raise ValueError("substreams")
                unknown = sum(n for fo, n in zip(folders, nsub) if not (n == 1 and fo.get("crc")))
                [r.take(4) for d in r.defined(unknown) if d]
                t = r.byte()
        else:
            raise ValueError("streams info %d" % t)


# decode: an encoded header, packed with Copy, LZMA or LZMA2 alone, as 7-Zip and py7zr write it.
def decode(data, pack_pos, fo):
    if len(fo["coders"]) != 1:
        raise ValueError("header coders")
    cid, props = fo["coders"][0]
    packed = data[32 + pack_pos:]
    if cid == b"\x00":
        return packed[:fo["size"]]
    if cid == b"\x03\x01\x01":
        d = props[0]
        filt = {"id": lzma.FILTER_LZMA1, "dict_size": struct.unpack("<I", props[1:5])[0],
                "lc": d % 9, "lp": d // 9 % 5, "pb": d // 45}
    elif cid == b"\x21":
        p = props[0]
        filt = {"id": lzma.FILTER_LZMA2, "dict_size": (2 | (p & 1)) << (p // 2 + 11) if p < 40 else 0xFFFFFFFF}
    else:
        raise ValueError("header coder")
    out = lzma.LZMADecompressor(lzma.FORMAT_RAW, filters=[filt]).decompress(packed, max_length=fo["size"])
    if len(out) != fo["size"]:
        raise ValueError("header size")
    return out


def main(path):
    data = open(path, "rb").read()
    if data[:6] != b"7z\xbc\xaf\x27\x1c":
        raise ValueError("signature")
    off, size = struct.unpack_from("<QQ", data, 12)
    r = R(data[32 + off:32 + off + size])
    t = r.byte()
    while t == 23:  # EncodedHeader
        pack_pos, folders, _ = streams(r)
        r = R(decode(data, pack_pos, folders[0]))
        t = r.byte()
    if t != 1:
        raise ValueError("header")
    folders, nsub, names, empty = [], [], [], []
    while (t := r.byte()) != 0:
        if t == 4:
            _, folders, nsub = streams(r)
        elif t == 5:
            n = r.num()
            empty = [False] * n
            while (p := r.byte()) != 0:
                q = R(r.take(r.num()))
                if p == 14:
                    empty = q.bits(n)
                elif p == 17:
                    if q.byte() != 0:
                        raise ValueError("external names")
                    names = bytes(q.b[1:]).decode("utf-16-le").split("\0")[:n]
        else:
            raise ValueError("header %d" % t)
    # The files with data, in order, fill the folders' substreams.
    owner = []
    for k, n in enumerate(nsub):
        owner += [k] * n
    it = iter(owner)
    for name, e in zip(names, empty):
        k = None if e else next(it)
        if name == "moddesc.ini":
            if k is None:
                raise ValueError("empty moddesc.ini")
            return 0 if [c for c, _ in folders[k]["coders"]] == [b"\x00"] else 1
    raise ValueError("no moddesc.ini at the root")


try:
    sys.exit(main(sys.argv[1]))
except (ValueError, IndexError, StopIteration, lzma.LZMAError, struct.error, UnicodeDecodeError) as e:
    print("7z header: %s" % e)
    sys.exit(2)
EOF
}

# reader: sets READER to the first 7z reader found. Windows' tar.exe is bsdtar with LZMA, reached through WSL interop.
reader() {
    local t
    for t in 7zz 7z bsdtar; do
        if command -v "$t" > /dev/null; then READER="$t"; return 0; fi
    done
    if command -v tar.exe > /dev/null && [[ "$(tar.exe --version 2> /dev/null)" == *bsdtar* ]]; then
        READER=tar.exe
        return 0
    fi
    return 1
}

# extract <7z> <empty folder>: with $READER, into a new folder that the compare then reads.
extract() {
    case "$READER" in
        7zz|7z) "$READER" x -y -bd -bso0 "-o$2" -- "$1" ;;
        bsdtar) bsdtar -xf "$1" -C "$2" ;;
        tar.exe) tar.exe -xf "$(wslpath -w "$1")" -C "$(wslpath -w "$2")" ;;
    esac
}

# The gates. Each runs in a subshell with set -e, so a command that fails ends that gate only. problem lists one
# failed check; a gate fails when it lists any.
problem() { echo "  - $*"; problems=$((problems + 1)); }
failed=()
gate() {    # gate <name> <function> [args]
    local rc
    echo "== $1"
    set +e
    # Not from stdin: a Windows program run through interop (tar.exe) reads it, and would eat publish's answer.
    (set -e; problems=0; "${@:2}") < /dev/null
    rc=$?
    set -e
    if (( rc != 0 )); then failed+=("$1"); echo "  FAILED: $1"; fi
}
finish() { (( ${#failed[@]} == 0 )) || die "$tag refused by: ${failed[*]}"; }

gate_tag() {
    [[ "$tag" == "v$modver" ]] || problem "tag $tag is not v<modver>: mod/moddesc.ini has modver=$modver"
    (( problems == 0 ))
}

gate_repo() {
    local st branch head origin v
    st="$(git -C "$HERE" status --porcelain --ignore-submodules=none)"
    [[ -z "$st" ]] || problem "the working tree has changes (git status): commit them, or remove them"
    branch="$(git -C "$HERE" symbolic-ref -q --short HEAD)" || branch="a detached HEAD"
    [[ "$branch" == main ]] || problem "on $branch, not on main: git switch main"
    head="$(git -C "$HERE" rev-parse HEAD)"
    if git -C "$HERE" fetch -q origin; then
        origin="$(git -C "$HERE" rev-parse -q --verify refs/remotes/origin/main)" || origin="nothing"
        [[ "$head" == "$origin" ]] || problem "HEAD $head is not origin/main ($origin): push main, or pull it"
    else
        problem "git fetch origin failed: check the network and your access to GitHub"
    fi
    # origin may be a mirror or another clone: main on GitHub must be HEAD too.
    if v="$(gh api "repos/$REPO/git/ref/heads/main" --jq .object.sha)"; then
        [[ "$v" == "$head" ]] || problem "HEAD $head is not main on GitHub ($v): push main to github.com/$REPO"
    else
        problem "could not read main of $REPO on GitHub: log in with gh auth login, or check the network"
    fi
    (( problems == 0 ))
}

gate_tag_unused() {
    local rc=0 hits
    if git -C "$HERE" rev-parse -q --verify "refs/tags/$tag" > /dev/null; then
        problem "tag $tag exists in this clone: the release makes its own tag. If it was never pushed: git tag -d $tag"
    fi
    git -C "$HERE" ls-remote --exit-code --tags origin "refs/tags/$tag" > /dev/null || rc=$?
    case "$rc" in
        0) problem "tag $tag exists on origin, and a release would keep its commit: release the next version" ;;
        2) ;;
        *) problem "git ls-remote origin failed (exit $rc): check the network and your access to GitHub" ;;
    esac
    # GitHub ignores --target for a tag that exists, so GitHub itself must not have it either.
    if hits="$(github_tag "$tag")"; then
        [[ -z "$hits" ]] || problem "tag $tag exists on GitHub in $REPO, and a release would keep its commit: release the next version"
    else
        problem "could not read the tags of $REPO on GitHub: log in with gh auth login, or check the network"
    fi
    if hits="$(gh release list -R "$REPO" -L 1000 --json tagName --jq ".[]|select(.tagName==\"$tag\")|.tagName")"; then
        [[ -z "$hits" ]] || problem "$REPO has a release or a draft for $tag: release the next version, or delete the draft"
    else
        problem "gh release list failed: log in with gh auth login, or check the network"
    fi
    (( problems == 0 ))
}

# changelog_heads: the headings of the tag. changelog_entry: the lines under it, up to the next heading, without the
# blank lines around them.
changelog_heads() { tr -d '\r' < "$HERE/CHANGELOG.md" | awk -v h="## $tag" '$0 == h || index($0, h " ") == 1'; }
changelog_entry() {
    tr -d '\r' < "$HERE/CHANGELOG.md" | awk -v h="## $tag" '
        $0 == h || index($0, h " ") == 1 { on = 1; next }
        on && /^## / { exit }
        on { line[++n] = $0; if ($0 ~ /[^[:space:]]/) { if (!first) first = n; last = n } }
        END { for (i = first; first && i <= last; i++) print line[i] }'
}

gate_changelog() {
    local heads n re
    heads="$(changelog_heads)"
    n="$(grep -c . <<< "$heads" || true)"
    if (( n == 0 )); then
        problem "CHANGELOG.md has no heading for $tag: add ## $tag (YYYY-MM-DD) with its entry"
    elif (( n > 1 )); then
        problem "CHANGELOG.md has $n headings for $tag: keep one"
    else
        re="^## ${tag//./\\.} \(([0-9]{4}-[0-9]{2}-[0-9]{2})\)$"
        if [[ ! "$heads" =~ $re || "$(date -d "${BASH_REMATCH[1]}" +%F 2> /dev/null)" != "${BASH_REMATCH[1]}" ]]; then
            problem "CHANGELOG.md has '$heads': write ## $tag (YYYY-MM-DD), dated the day you publish"
        fi
        [[ -n "$(changelog_entry)" ]] || problem "CHANGELOG.md has nothing under ## $tag: write its entry"
    fi
    (( problems == 0 ))
}

gate_text() {
    local f
    for f in README.md mod/README.txt; do
        if [[ ! -f "$HERE/$f" ]]; then
            problem "$f is missing"
        elif grep -q NEXUS_PAGE_URL "$HERE/$f"; then
            problem "$f still holds NEXUS_PAGE_URL: put the Nexus page's URL in its place"
        fi
    done
    if [[ "$modsite" =~ ^https://www\.nexusmods\.com/masseffectlegendaryedition/mods/[0-9]+$ ]]; then
        grep -qE "${modsite//./\\.}([^0-9]|$)" "$HERE/README.md" || problem "README.md does not link $modsite"
    else
        problem "mod/moddesc.ini has modsite=$modsite: set it to the Nexus page," \
            "https://www.nexusmods.com/masseffectlegendaryedition/mods/<id>"
    fi
    (( problems == 0 ))
}

gate_toolkit() {
    local st head v
    [[ "$TOOLKIT_COMMIT" =~ ^[0-9a-f]{40}$ ]] || { problem "build.sh has no single TOOLKIT_COMMIT=<40 hex digits> line"; return 1; }
    [[ "$(git -C "$TOOLKIT" rev-parse --show-toplevel 2> /dev/null)" -ef "$TOOLKIT" ]] \
        || { problem "no git checkout of the toolkit at $TOOLKIT: set MELE_TOOLKIT, as for build.sh"; return 1; }
    st="$(git -C "$TOOLKIT" status --porcelain --ignore-submodules=none)"
    [[ -z "$st" ]] || problem "the toolkit at $TOOLKIT has changes (git status there): commit and push them, or remove them"
    head="$(git -C "$TOOLKIT" rev-parse HEAD)"
    [[ "$head" == "$TOOLKIT_COMMIT" ]] \
        || problem "the toolkit is at $head, build.sh has TOOLKIT_COMMIT=$TOOLKIT_COMMIT: check out that commit, or change the pin"
    if git -C "$TOOLKIT" fetch -q origin; then
        git -C "$TOOLKIT" merge-base --is-ancestor "$TOOLKIT_COMMIT" refs/remotes/origin/main 2> /dev/null \
            || problem "TOOLKIT_COMMIT $TOOLKIT_COMMIT is not on the toolkit's origin/main: push it to main first"
    else
        problem "git fetch origin failed in the toolkit: check the network and your access to GitHub"
    fi
    # The notes link the commit on GitHub, and the toolkit's origin may be another clone: ask GitHub itself.
    if v="$(gh api "repos/$TOOLKIT_REPO/compare/$TOOLKIT_COMMIT...main" --jq .status)"; then
        [[ "$v" == identical || "$v" == ahead ]] \
            || problem "TOOLKIT_COMMIT $TOOLKIT_COMMIT is not on main of $TOOLKIT_REPO on GitHub (compare: $v): push it there"
    else
        problem "GitHub has no TOOLKIT_COMMIT $TOOLKIT_COMMIT in $TOOLKIT_REPO, or gh could not read it: push it to" \
            "the toolkit's main, and log in with gh auth login"
    fi
    (( problems == 0 ))
}

# dirty_ok <key> <what> <fix>: the stamp's count of uncommitted changes is 0.
dirty_ok() {
    local v
    v="$(stamp_get "$1")"
    case "$v" in
        0) ;;
        changed) problem "$2 changed during the build ($1=changed): run ./build.sh again, and leave $2 alone meanwhile" ;;
        *) problem "the build was made with uncommitted changes in $2 ($1=$v): $3, then run ./build.sh" ;;
    esac
}

gate_stamp() {
    local head v
    [[ -f "$STAMP" ]] || { problem "no dist/build.stamp: run ./build.sh"; return 1; }
    [[ -d "$DIST" ]] || { problem "no dist/$NAME: run ./build.sh"; return 1; }
    head="$(git -C "$HERE" rev-parse HEAD)"
    v="$(stamp_get modver)"
    [[ "$v" == "$modver" ]] || problem "the build is modver $v, mod/moddesc.ini has $modver: run ./build.sh"
    v="$(stamp_get mod_commit)"
    [[ "$v" == "$head" ]] || problem "the build is from commit $v, HEAD is $head: run ./build.sh"
    dirty_ok mod_dirty "the repo" "commit them"
    v="$(stamp_get toolkit_commit)"
    [[ "$v" == "$TOOLKIT_COMMIT" ]] || problem "the build used toolkit $v, not TOOLKIT_COMMIT: run ./build.sh with the toolkit there"
    dirty_ok toolkit_dirty "the toolkit" "commit them in the toolkit"
    v="$(stamp_get le1cp)"
    version_ge "$v" 2.0 || problem "the build read LE1 Community Patch '$v': it needs 2.0 or later in the game build.sh reads"
    v="$(stamp_get files)"
    [[ "$v" == "$(manifest_hash "$DIST")" ]] || problem "dist/$NAME changed after the build: run ./build.sh"
    dist_is_head
    (( problems == 0 ))
}

# dist_is_head: dist/$NAME holds the files of mod/ and LICENSE and NOTICE as HEAD has them, the packages, and nothing
# else. The stamp's dirty count can't see a file git ignores, or an edit that git update-index --skip-worktree or
# --assume-unchanged hides; this sees both.
dist_is_head() {
    local want have f
    want="$({ git -C "$HERE" ls-tree -r --name-only HEAD -- mod | sed 's|^mod/||'
        printf '%s\n' LICENSE/LICENSE LICENSE/NOTICE
        printf 'DLC_MOD_GalaxyMapNormandy/CookedPCConsole/%s.pcc\n' "${PACKAGES[@]}"; } | LC_ALL=C sort)"
    have="$(cd "$DIST" && find . ! -type d | sed 's|^\./||' | LC_ALL=C sort)"
    if [[ "$want" != "$have" ]]; then
        problem "dist/$NAME does not hold exactly the files of mod/ at HEAD, LICENSE, NOTICE and the packages" \
            "(< missing, > extra): run ./build.sh"
        diff <(printf '%s\n' "$want") <(printf '%s\n' "$have") | sed -n '/^[<>]/s/^/      /p' | head -20 || true
        return 0
    fi
    [[ -z "$(find "$DIST" ! -type f ! -type d)" ]] || problem "dist/$NAME holds links or other entries that are not files"
    while IFS= read -r f; do
        cmp -s <(git -C "$HERE" cat-file --filters "HEAD:mod/$f") "$DIST/$f" \
            || problem "dist/$NAME/$f is not mod/$f as committed: run ./build.sh. If git status shows no change, git" \
                "update-index --no-skip-worktree --no-assume-unchanged mod/$f shows the hidden one"
    done < <(git -C "$HERE" ls-tree -r --name-only HEAD -- mod | sed 's|^mod/||')
    for f in LICENSE NOTICE; do
        cmp -s <(git -C "$HERE" cat-file --filters "HEAD:$f") "$DIST/LICENSE/$f" \
            || problem "dist/$NAME/LICENSE/$f is not $f as committed: run ./build.sh"
    done
}

gate_kit() {
    local root kit="$TOOLKIT/tools/release-kit/kit.sh"
    root="${KIT_ROOT:-$(dirname "$TOOLKIT")}"
    [[ "$root/mods/galaxy-map-normandy" -ef "$HERE" ]] \
        || { problem "$root/mods/galaxy-map-normandy is not this repo: set KIT_ROOT to the folder that holds it"; return 1; }
    [[ -f "$kit" ]] || { problem "no $kit: set MELE_TOOLKIT"; return 1; }
    KIT_ROOT="$root" KIT_REF=main bash "$kit" check mods/galaxy-map-normandy \
        || problem "kit.sh check failed: kit.sh apply mods/galaxy-map-normandy, then commit what it wrote"
    KIT_ROOT="$root" KIT_REF=main bash "$kit" scan mods/galaxy-map-normandy \
        || problem "kit.sh scan failed: take what it lists out of main"
    (( problems == 0 ))
}

gate_archive() {    # gate_archive <7z>
    local z="$1" rc msg
    [[ -f "$STAMP" ]] || { problem "no dist/build.stamp: run ./build.sh"; return 1; }
    [[ -d "$DIST" && "$(stamp_get files)" == "$(manifest_hash "$DIST")" ]] \
        || { problem "dist/$NAME does not match dist/build.stamp: run ./build.sh, then deploy again"; return 1; }
    [[ -f "$z" ]] || { problem "no file $z"; return 1; }
    [[ "$z" == *.7z ]] || { problem "$z is not a .7z file: give the 7z that M3's Deploy mod wrote"; return 1; }
    [[ "$(basename "$z")" == "GalaxyMapNormandy_$modver.7z" ]] \
        || problem "the 7z is named $(basename "$z"), not GalaxyMapNormandy_$modver.7z as M3 proposes: SHA256SUMS" \
            "names that file, so rename it"
    [[ "$(head -c 6 "$z" | od -An -tx1 | tr -d ' \n')" == 377abcaf271c ]] \
        || { problem "$z is not a 7z archive: its first bytes are not the 7z signature"; return 1; }
    # M3's Deploy mod stores moddesc.ini uncompressed (7z's Copy method). When it is compressed, M3 tells every player
    # who imports the 7z that the mod was not deployed properly.
    rc=0
    msg="$(moddesc_coder "$z")" || rc=$?
    case "$rc" in
        0) ;;
        1) problem "moddesc.ini is compressed in $z, so M3's Deploy mod did not make it, and M3 would warn players" \
               "that the mod was not deployed properly: deploy it with M3" ;;
        *) problem "M3 would not take $z as deployed by M3 (${msg:-exit $rc}): deploy it with M3" ;;
    esac
    reader || { problem "no 7z reader: install 7zz (7-Zip) or bsdtar, or run this in WSL, where Windows has tar.exe"; return 1; }
    # Not local: the trap runs when the gate's subshell ends, after this function has returned.
    unpacked="$(mktemp -d)"
    trap 'rm -rf "$unpacked"' EXIT
    mkdir "$unpacked/root"
    extract "$z" "$unpacked/root" || { problem "$READER could not extract $z"; return 1; }
    [[ -z "$(cd "$unpacked/root" && find . ! -type f ! -type d)" ]] || problem "the 7z holds entries that are not files or folders"
    if ! diff <(listing "$unpacked/root") <(listing "$DIST") > "$unpacked/diff"; then
        problem "the 7z's root is not dist/$NAME (< in the 7z, > in dist). Replace the mod in M3's library, then deploy again:"
        sed -n '1,40s/^/      /p' "$unpacked/diff"
    fi
    (( problems == 0 ))
}

gate_download() {   # gate_download <deployed 7z> <downloaded 7z>
    [[ -f "$2" ]] || { problem "no file $2: download the 7z back from the Nexus page once"; return 1; }
    [[ ! "$1" -ef "$2" ]] || { problem "$2 is the deployed file itself: give the copy you downloaded from Nexus"; return 1; }
    cmp -s "$1" "$2" || problem "the file from Nexus differs from the deployed 7z: upload the deployed 7z again, then download it again"
    (( problems == 0 ))
}

ruleset_check() {   # ruleset_check <name> [<current_user_can_bypass wanted>]
    local id v
    if ! id="$(gh api "repos/$REPO/rulesets?per_page=100" --jq ".[]|select(.name==\"$1\")|.id")"; then
        problem "could not list the rulesets of $REPO"
        return 0
    fi
    [[ "$id" =~ ^[0-9]+$ ]] || { problem "$REPO has no ruleset '$1': run scripts/protect-repo.sh"; return 0; }
    # The list leaves current_user_can_bypass null: only the ruleset's own page has it.
    if ! v="$(gh api "repos/$REPO/rulesets/$id" --jq '.enforcement + " " + (.current_user_can_bypass // "null")')"; then
        problem "could not read the ruleset '$1' of $REPO"
        return 0
    fi
    [[ "${v%% *}" == active ]] || problem "the ruleset '$1' is not active ($v): run scripts/protect-repo.sh"
    if [[ -n "${2:-}" && "${v#* }" != "$2" ]]; then
        problem "you can't bypass the ruleset '$1' (current_user_can_bypass=${v#* }), so GitHub would refuse the tag:" \
            "log in to gh as the repo's admin"
    fi
}

gate_github() {
    local v
    if v="$(gh api "repos/$REPO" --jq .private)"; then
        [[ "$v" == false ]] || problem "$REPO is not public (private=$v): make it public, then run scripts/protect-repo.sh"
    else
        problem "could not read $REPO: log in with gh auth login, or check the network"
    fi
    if v="$(gh api "repos/$REPO/immutable-releases" --jq .enabled)"; then
        [[ "$v" == true ]] || problem "immutable releases are off in $REPO: run scripts/protect-repo.sh"
    else
        problem "could not read the immutable releases setting of $REPO: log in to gh as the repo's admin"
    fi
    if v="$(gh api "repos/$TOOLKIT_REPO" --jq .private)"; then
        [[ "$v" == false ]] || problem "$TOOLKIT_REPO is not public: under the GPL the tools that build the mod must be public"
    else
        problem "could not read $TOOLKIT_REPO: log in with gh auth login, or check the network"
    fi
    ruleset_check "release tags are final"
    ruleset_check "only admins create release tags" always
    (( problems == 0 ))
}

checks() {
    gate tag gate_tag
    gate repo gate_repo
    gate tag-unused gate_tag_unused
    gate changelog gate_changelog
    gate release-text gate_text
    gate toolkit gate_toolkit
    gate stamp gate_stamp
    gate kit gate_kit
}

# notes <SHA-256 of the 7z>: the release notes.
notes() {
    local file="GalaxyMapNormandy_$modver.7z"
    cat <<EOF
$(changelog_entry)

## Download

Galaxy Map Normandy is on Nexus Mods: <$modsite>. Install its 7z file with ME3Tweaks Mod Manager.

This release holds no mod files. Its one file, \`SHA256SUMS\`, holds the SHA-256 hash of the 7z uploaded to Nexus:

| File uploaded to Nexus | SHA-256 |
|---|---|
| \`$file\` | \`$1\` |

## Check your download

Nexus gives the file another name when you download it, so compare the hash value, not the file name.
\`sha256sum -c\` looks for the file by its name, so it fails on a renamed download. In PowerShell:

\`\`\`powershell
(Get-FileHash -Algorithm SHA256 -LiteralPath "<file>").Hash.ToLower()
\`\`\`

The result must be the hash in this release's \`SHA256SUMS\` file. The table above copies it, but release notes can be
edited and the file can't.

To check that this \`SHA256SUMS\` is the one this release published, use the [GitHub CLI](https://cli.github.com),
signed in with \`gh auth login\`:

\`\`\`bash
gh release download $tag -R $REPO -p SHA256SUMS
gh release verify-asset $tag SHA256SUMS -R $REPO
\`\`\`

Without the GitHub CLI, hash the \`SHA256SUMS\` file you downloaded with the same PowerShell command. Compare that with
the digest the release page shows next to \`SHA256SUMS\`. That digest is the hash of \`SHA256SUMS\`, not of the 7z.
\`gh release verify-asset\` on the 7z itself always fails: the 7z is not on GitHub, so it is not part of this release.

## What the hash proves

It proves that your file is the one the maintainer published on Nexus. The release is immutable, so its
\`SHA256SUMS\` file can't change. It does not prove that the 7z was built from this tag, or that the PC and the game
files used for the build were clean. A new build can't check it either: the packages come out with different bytes on
every build.

## Build

The maintainer built this 7z on their own PC and deployed it with ME3Tweaks Mod Manager.

- Mod commit: \`$(stamp_get mod_commit)\`
- [mele-maxgoods-toolkit](https://github.com/$TOOLKIT_REPO) commit: \`$(stamp_get toolkit_commit)\`
- LE1 Community Patch read by the build: $(stamp_get le1cp)
EOF
}

# retry <command>: up to 5 tries, 5 s apart, for checks that can lag behind the publish.
retry() {
    local i
    for i in 1 2 3 4 5; do
        if "$@"; then return 0; fi
        if (( i < 5 )); then sleep 5; fi
    done
    return 1
}

publish() {    # publish <deployed 7z> <downloaded 7z>
    local z="$1" sha hash answer out st v rc=0 post=0
    sha="$(git -C "$HERE" rev-parse HEAD)"
    checks
    gate archive gate_archive "$z"
    gate download gate_download "$z" "$2"
    gate github gate_github
    finish

    hash="$(sha256sum < "$z" | cut -c1-64)"
    mkdir -p "$OUT"
    rm -f "$OUT/SHA256SUMS" "$OUT/notes.md"
    printf '%s  %s\n' "$hash" "GalaxyMapNormandy_$modver.7z" > "$OUT/SHA256SUMS"
    notes "$hash" > "$OUT/notes.md"

    cat <<EOF

Every gate passed. Ready to publish:
  release   $tag of $REPO, with SHA256SUMS
  commit    $sha (main, the same as origin/main)
  7z        $(basename "$z"), SHA-256 $hash
  notes     dist/release/notes.md: read it before you answer
Once published, $tag and its SHA256SUMS can't change, and the tag name can't be used again.
EOF
    printf 'Type %s to publish: ' "$tag"
    IFS= read -r answer || die "no answer: run publish on a terminal and type $tag. Nothing was published"
    if [[ ! -t 0 ]]; then echo "$answer"; fi
    [[ "$answer" == "$tag" ]] || die "you typed '$answer', not $tag. Nothing was published"

    # --target is ignored for a tag that exists, so look once more, just before the release makes it.
    st="$(git -C "$HERE" status --porcelain --ignore-submodules=none)"
    [[ "$(git -C "$HERE" rev-parse HEAD)" == "$sha" && -z "$st" ]] || die "the repo changed: run publish again"
    git -C "$HERE" ls-remote --exit-code --tags origin "refs/tags/$tag" > /dev/null || rc=$?
    (( rc == 2 )) || die "tag $tag is on origin now, or git ls-remote failed (exit $rc). Nothing was published"
    if ! v="$(github_tag "$tag")" || [[ -n "$v" ]]; then
        die "tag $tag is on GitHub now, or gh could not read the tags of $REPO. Nothing was published"
    fi

    echo "== gh release create $tag"
    if ! out="$(cd "$HERE" && gh release create "$tag" dist/release/SHA256SUMS -R "$REPO" --target "$sha" \
            --title "$NAME $tag" --notes-file dist/release/notes.md 2>&1)"; then
        printf '%s\n' "$out" >&2
        # gh deletes the draft it made when the upload or the publish fails. When that delete fails too, it says so.
        if grep -q 'cleaning up draft failed' <<< "$out"; then
            die "GitHub refused the release, and gh could not delete the draft it had made. No tag was made, but a" \
                "draft for $tag may be left: delete it on https://github.com/$REPO/releases, then run publish again"
        elif grep -q 'tag_name was used by an immutable release' <<< "$out"; then
            die "a deleted immutable release used $tag, so GitHub keeps that name forever: release the next version"
        elif grep -q 'creations being restricted' <<< "$out"; then
            die "GitHub refused to create tag $tag: the admin bypass of 'only admins create release tags' did not" \
                "apply. Nothing was left behind, no tag and no release. Log in to gh as the repo's admin, then run" \
                "publish again"
        fi
        die "gh release create failed (above). A failed create leaves no tag. If gh release list -R $REPO shows a" \
            "draft for $tag, delete that draft on GitHub before you run publish again"
    fi
    printf '%s\n' "$out"

    # The release is final now: these only report.
    echo "== checks after the publish"
    if v="$(gh api "repos/$REPO/git/ref/tags/$tag" --jq .object.sha)" && [[ "$v" == "$sha" ]]; then
        echo "  ok: tag $tag is $sha"
    else
        echo "  - tag $tag on GitHub is not $sha: $v"; post=$((post + 1))
    fi
    if v="$(gh api "repos/$REPO/releases/tags/$tag" --jq .immutable)" && [[ "$v" == true ]]; then
        echo "  ok: the release is immutable"
    else
        echo "  - the release is not immutable: $v"; post=$((post + 1))
    fi
    if retry gh release verify "$tag" -R "$REPO"; then echo "  ok: gh release verify"
    else echo "  - gh release verify $tag failed"; post=$((post + 1)); fi
    if (cd "$HERE" && retry gh release verify-asset "$tag" dist/release/SHA256SUMS -R "$REPO"); then
        echo "  ok: gh release verify-asset SHA256SUMS"
    else
        echo "  - gh release verify-asset $tag SHA256SUMS failed"; post=$((post + 1))
    fi
    if git -C "$HERE" fetch -q --tags origin; then echo "  ok: git fetch --tags"
    else echo "  - git fetch --tags origin failed"; post=$((post + 1)); fi
    if (( post > 0 )); then
        echo "published $tag, but $post checks after it failed: look at https://github.com/$REPO/releases/tag/$tag"
    else
        echo "published $tag: https://github.com/$REPO/releases/tag/$tag"
    fi
}

main() {
    local cmd="${1:-}" t kit
    case "$cmd" in
        -h|--help) echo "$USAGE"; exit 0 ;;
        check) (( $# == 2 )) || die "$USAGE" ;;
        archive) (( $# == 3 )) || die "$USAGE" ;;
        publish) (( $# == 4 )) || die "$USAGE" ;;
        *) die "$USAGE" ;;
    esac
    tag="$2"
    # The tag goes into jq filters and regular expressions, so its form is checked before anything else.
    [[ "$tag" =~ ^v[0-9]+\.[0-9]+$ ]] || die "the tag '$tag' is not v<major>.<minor>: use v and modver from mod/moddesc.ini"
    for t in git sha256sum cmp; do command -v "$t" > /dev/null || die "$t not found: install it"; done
    if [[ "$cmd" != archive ]]; then command -v gh > /dev/null || die "gh not found: install the GitHub CLI"; fi
    if [[ "$cmd" != check ]]; then command -v python3 > /dev/null || die "python3 not found: install it"; fi

    modver="$(sed -n 's/^modver=//p' "$HERE/mod/moddesc.ini" | tr -d '\r')"
    modsite="$(sed -n 's/^modsite=//p' "$HERE/mod/moddesc.ini" | tr -d '\r')"
    # MELE_TOOLKIT from the environment, or from build.env, which wins as it does for build.sh.
    kit="$(if [[ -f "$HERE/build.env" ]]; then . "$HERE/build.env"; fi; printf '%s' "${MELE_TOOLKIT:-}")"
    TOOLKIT="${kit:-$HERE/../../mele-maxgoods-toolkit}"
    if [[ -d "$TOOLKIT" ]]; then TOOLKIT="$(cd "$TOOLKIT" && pwd)"; fi
    TOOLKIT_COMMIT="$(sed -n 's/^TOOLKIT_COMMIT=\([0-9a-f]\{40\}\)$/\1/p' "$HERE/build.sh")"

    case "$cmd" in
        check)
            checks
            finish
            echo "$tag passes every gate. Next: M3's Deploy mod, then scripts/release.sh archive $tag <7z>"
            ;;
        archive)
            gate tag gate_tag
            gate archive gate_archive "$(abspath "$3")"
            finish
            echo "the 7z holds exactly dist/$NAME. Its SHA-256: $(sha256sum < "$3" | cut -c1-64)"
            echo "Next: install it with M3 and test it in the game, upload it to Nexus, download it back once"
            ;;
        publish)
            publish "$(abspath "$3")" "$(abspath "$4")"
            ;;
    esac
}

# Sourced (by a test), it only defines the functions.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi
