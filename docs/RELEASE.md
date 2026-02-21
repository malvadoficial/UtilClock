# Release Guide

## Prerequisites

- `gh auth status` is logged in to `malvadoficial`.
- A Developer ID Application certificate is installed in keychain.
- A notary profile exists in keychain (`xcrun notarytool store-credentials <PROFILE_NAME> ...`).

## Steps

1. Update changelog and set Xcode version (`MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`).
2. Commit changes on `main`, create tag `vX.Y.Z`, and push with tags.
3. Build signed Release app (`xcodebuild ... CODE_SIGN_IDENTITY="Developer ID Application: ..."`).
4. Create and sign DMG.
5. Submit DMG to Apple notarization and wait for success.
6. Staple notarization ticket to DMG.
7. Verify with `spctl -a -vvv --type open <DMG>`.
8. Create GitHub Release and upload stapled DMG.

## Expected artifact

- `ReleaseBuild/dist/UtilClock-vX.Y.Z-macOS-notary.dmg`
