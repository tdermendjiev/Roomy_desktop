#!/usr/bin/env bash
# Export the open-source subset of this repository to a checkout of github.com/tdermendjiev/Roomy.
#
#   packaging/scripts/export-os.sh ../Roomy           # sync the working tree into the checkout and commit
#   packaging/scripts/export-os.sh ../Roomy v1.3.0    # ...and tag it; prints the push commands (nothing is pushed)
#
# Published:  RoomyCore/ (engine, CLI, fleet, hub, tests), docs/, packaging/, .github/workflows/,
#             AGENTS.md, CHANGELOG.md, THIRD_PARTY_NOTICES.md; README and LICENSE come from packaging/oss/.
# Private:    the Mac app (Roomy/, Roomy.xcodeproj, RoomyTests), landing/, EULA.md, LICENSE, tools/licensetool,
#             skills/, DISTRIBUTION.md, HOSTING.md, design documents, anything agent- or assistant-specific.
set -euo pipefail
SRC="$(cd "$(dirname "$0")/../.." && pwd)"
DEST="${1:?path to a checkout of the public repo}"
TAG="${2:-}"

[ -d "$DEST/.git" ] || { echo "$DEST is not a git checkout; run: git clone git@github.com:tdermendjiev/Roomy.git $DEST" >&2; exit 1; }
[ -f "$SRC/packaging/oss/LICENSE" ] || { echo "packaging/oss/LICENSE is missing; the public repo needs a license" >&2; exit 1; }
if [ -n "$TAG" ] && git -C "$DEST" rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  echo "the public repo already has tag $TAG" >&2; exit 1
fi

# The checkout is a pure mirror: anything already there that is not part of the export goes away (history keeps it).
find "$DEST" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +

RSYNC=(rsync -a --delete --exclude .build --exclude .swiftpm --exclude .DS_Store --exclude 'xcuserdata' --exclude '.claude' --exclude '.cursor')
for d in RoomyCore docs packaging .github; do
  mkdir -p "$DEST/$d"
  "${RSYNC[@]}" "$SRC/$d/" "$DEST/$d/"
done
rm -rf "$DEST/packaging/oss" "$DEST/packaging/scripts/export-os.sh"   # private-tree tooling is not published
cp "$SRC/AGENTS.md" "$SRC/CHANGELOG.md" "$SRC/THIRD_PARTY_NOTICES.md" "$DEST/"
cp "$SRC/packaging/oss/README.md" "$DEST/README.md"
cp "$SRC/packaging/oss/LICENSE" "$DEST/LICENSE"
[ -f "$SRC/.gitignore" ] && cp "$SRC/.gitignore" "$DEST/.gitignore"

# Nothing private may slip through.
for p in Roomy Roomy.xcodeproj landing tools EULA.md; do
  [ -e "$DEST/$p" ] && { echo "refusing: $p ended up in the export" >&2; exit 1; }
done
KEY_PAT='BEGIN.*PRIVATE KEY'
ATTR_PAT='Co-Authored-By|Generated with \['
if grep -rIlE --exclude-dir=.git -e "$KEY_PAT" "$DEST" | grep -q .; then
  echo "refusing: a private key is in the export" >&2; exit 1
fi
# No tool attribution or assistant-specific files leave the private tree.
if grep -rIlE --exclude-dir=.git -e "$ATTR_PAT" "$DEST" | grep -q .; then
  grep -rInE --exclude-dir=.git -e "$ATTR_PAT" "$DEST" >&2
  echo "refusing: attribution text in the export" >&2; exit 1
fi

cd "$DEST"
git add -A
if git diff --cached --quiet; then
  echo "public repo: nothing changed"
else
  SRC_REV="$(git -C "$SRC" rev-parse --short HEAD)"
  git commit -q -m "Sync from Roomy_desktop ${SRC_REV}${TAG:+ ($TAG)}"
  echo "public repo: committed $(git rev-parse --short HEAD)"
fi
if [ -n "$TAG" ]; then
  git tag -a "$TAG" -m "roomy $TAG"
  echo "public repo: tagged $TAG"
  echo
  echo "To release (the tag push starts .github/workflows/release.yml in the public repo):"
  echo "  git -C $DEST push origin HEAD && git -C $DEST push origin $TAG"
else
  echo "To publish: git -C $DEST push origin HEAD"
fi
