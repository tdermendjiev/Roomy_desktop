# Direct distribution (getroomy.dev)

Roomy ships outside the Mac App Store. The Xcode project is configured for:

- **Minimum macOS:** 13.0
- **Architectures (Release):** Universal — Apple Silicon (`arm64`) + Intel (`x86_64`)
- **Hardened Runtime:** enabled on Release (required for notarization)

## After your Apple Developer account is ready

1. Xcode → **Roomy** target → **Signing & Capabilities** → Team: **Azbouki**, certificate: **Developer ID Application**.
2. **Product → Archive** → **Distribute App** → **Developer ID** → export `Roomy.app`.
3. Notarize and staple (see [Apple: Notarizing macOS software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)).
4. Zip the stapled app and upload to `landing/downloads/` on Firebase Hosting.
5. Point Download buttons on getroomy.dev to the zip URL and run `npm run deploy:landing`.

## Verify a Release build locally

```bash
xcodebuild -scheme Roomy -configuration Release -destination 'generic/platform=macOS' build
```

Check the binary:

```bash
APP=$(find ~/Library/Developer/Xcode/DerivedData -name Roomy.app -path '*/Release/*' | head -1)
lipo -archs "$APP/Contents/MacOS/Roomy"
plutil -extract LSMinimumSystemVersion raw "$APP/Contents/Info.plist"
```

Expect: `arm64 x86_64` and `13.0`.
