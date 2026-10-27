#!/usr/bin/env bash
# Regenerate landing/appcast.xml (the Sparkle update feed) from the versioned zips in landing/downloads.
# Usage: tools/mac-release/appcast.sh
# Run after the notarized, stapled Roomy-<version>-macOS-universal.zip is in landing/downloads,
# then deploy the landing site. Signing uses the EdDSA key stored in the login Keychain under
# the account "roomy" (generate_keys --account roomy); its public half is SUPublicEDKey in
# Config/Roomy-Info.plist.
set -euo pipefail
cd "$(dirname "$0")/../.."
PKGS=build/SourcePackages
BIN="$PKGS/artifacts/sparkle/Sparkle/bin"
if [ ! -x "$BIN/generate_appcast" ]; then
  xcodebuild -resolvePackageDependencies -project Roomy.xcodeproj -scheme Roomy -clonedSourcePackagesDirPath "$PKGS" >/dev/null
fi

# Only versioned archives: Roomy-latest.zip duplicates the newest one.
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
# Only builds with Sparkle (1.4.0+) are hosted; older archives live in releases/mac, unhosted,
# because a pre-licensing build run once on a new Mac would grandfather it (Roomy/RoomyLicense.swift).
cp landing/downloads/Roomy-*-macOS-universal.zip "$WORK/"
[ -f landing/appcast.xml ] && cp landing/appcast.xml "$WORK/appcast.xml"

"$BIN/generate_appcast" "$WORK" \
  --account roomy \
  --download-url-prefix "https://getroomy.dev/downloads/" \
  --full-release-notes-url "https://getroomy.dev/release-notes" \
  --link "https://getroomy.dev" \
  --maximum-deltas 0 \
  -o "$WORK/appcast.xml"

cp "$WORK/appcast.xml" landing/appcast.xml
echo "landing/appcast.xml updated:"
grep -E "sparkle:shortVersionString|<sparkle:version>" landing/appcast.xml | sed 's/^ */  /'
