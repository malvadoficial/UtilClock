# Release Guide

## Prerequisites

- `gh auth status` is logged in to `malvadoficial`.
- A Developer ID Application certificate is installed in keychain.
- A notary profile exists in keychain (`xcrun notarytool store-credentials <PROFILE_NAME> ...`).

## Steps

1. Update changelog and set Xcode version (`MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`).
2. Create a release branch (`codex/release-vX.Y.Z`), commit and push.
3. Open PR to `main` and merge it.
4. Create tag `vX.Y.Z` on `main` and push with tags.
5. Build signed Release app (`xcodebuild ... CODE_SIGN_IDENTITY="Developer ID Application: ..."`).
6. Create and sign DMG.
7. Submit DMG to Apple notarization and wait for success.
8. Staple notarization ticket to DMG.
9. Verify with `spctl -a -vvv --type open <DMG>`.
10. Create GitHub Release and upload stapled DMG.

## Expected artifact

- `ReleaseBuild/dist/UtilClock-vX.Y.Z-macOS-notary.dmg`
