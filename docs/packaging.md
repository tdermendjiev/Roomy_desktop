# Packaging and releases

Everything lives in `packaging/`. CI runs the same scripts (`.github/workflows/ci.yml`, `release.yml`).

| Artifact | How | Where |
|---|---|---|
| macOS app | Xcode archive, Developer ID, notarize (see `DISTRIBUTION.md`) | getroomy.dev downloads |
| macOS CLI (universal) | `packaging/scripts/build-macos.sh` → codesign with `$DEVELOPER_ID_APPLICATION` → notarize tarball | GitHub release, Homebrew |
| Linux CLI (static) | `packaging/scripts/build-linux.sh` (amd64, arm64) | GitHub release tarball |
| .deb / .rpm / .apk | `packaging/scripts/package-linux.sh <version> <arch>` via [nfpm](https://nfpm.goreleaser.com) and `packaging/nfpm.yaml` | GitHub release |
| Container image | `packaging/docker/Dockerfile` (multi-stage, static binary on ubuntu:24.04) | `ghcr.io/azbouki/roomy` |
| Homebrew | `packaging/homebrew/roomy.rb` in the tap `azbouki/homebrew-roomy` | `brew install azbouki/roomy/roomy` |
| SBOM | `packaging/scripts/sbom.py <version>` (CycloneDX 1.5 from `Package.resolved`) | GitHub release |
| Checksums + signature | `packaging/scripts/sign.sh dist/release` (SHA256SUMS, GPG detached signature, optional cosign) | GitHub release |

## Release checklist

1. Bump `RoomyCoreInfo.version` (`RoomyCore/Sources/RoomyCore/RoomyCore.swift`), `MARKETING_VERSION` in the Xcode project, `catalogVersion` in `builtin-rules.json` if rules changed, `CHANGELOG.md`, the landing page version strings.
2. `cd RoomyCore && swift test`; `xcodebuild -project Roomy.xcodeproj -scheme Roomy test -only-testing:RoomyTests`.
3. Tag `vX.Y.Z` and push. The release workflow builds Linux amd64/arm64 packages, the macOS universal CLI (signed and notarized when secrets are set), the container image, SBOM, checksums and signatures, and creates the GitHub release.
4. Update the Homebrew formula `url`/`sha256` (the workflow log prints them; `packaging/scripts/release.sh` does locally).
5. Archive, notarize and upload the Mac app per `DISTRIBUTION.md`; deploy the landing page (`npm run deploy:landing`).

## Secrets used by CI

`DEVELOPER_ID_P12`, `DEVELOPER_ID_P12_PASSWORD`, `DEVELOPER_ID_APPLICATION`, `NOTARY_KEY_ID`, `NOTARY_ISSUER_ID`, `NOTARY_KEY_P8` (macOS signing/notarization), `GPG_KEY_ID`, `GPG_PRIVATE_KEY` (checksum signature). All optional; steps are skipped when unset.

## systemd units

`roomy-fleet@.service` + `roomy-fleet@.timer` (oneshot every 6h, `SuccessExitStatus=4` so a held lock is not a failure) and `roomy-fleet-serve@.service` (long-running with metrics). Instance = Unix user.

`roomy-hub.service` runs the hub as a `DynamicUser` with state in `/var/lib/roomy-hub`, listen address and title from `/etc/roomy/hub.env`, tokens from `/etc/roomy/hub.agent.token` and `/etc/roomy/hub.admin.token`. The Docker image runs it with `hub serve --listen 0.0.0.0:9478 --data-dir /data` (expose 9478, mount `/data`).

## Config in packages

`/etc/roomy/policy.json` is marked `config|noreplace`: package upgrades never overwrite a tuned policy. `/etc/roomy/license.key` is read if present.
