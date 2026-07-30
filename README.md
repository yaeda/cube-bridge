# CubeBridge

CubeBridge is a macOS menu bar app that connects to toio Core Cube devices over Bluetooth Low Energy and exposes cube controls to Apple Shortcuts using App Intents.

## Requirements

- macOS 13 or later
- Xcode 26 or later
- A toio Core Cube with Bluetooth enabled

## Setup

1. Open `CubeBridge.xcodeproj` in Xcode.
2. Select the `CubeBridge` scheme.
3. If you only need to build the app, use the default local signing settings.
4. If you need signed App Intents behavior for Shortcuts testing, configure local signing as described below.
5. Build and run the app.
6. Grant Bluetooth permission when macOS prompts for it.

The app appears in the menu bar for scanning, connecting, and sending commands.

### Local Signing

The public project intentionally does not commit a personal or organization Apple Developer Team ID. Local signing values should live outside git.

For Xcode GUI development:

```sh
cp Config/Signing.local.xcconfig.example Config/Signing.local.xcconfig
```

Then edit `Config/Signing.local.xcconfig` and set your own team:

```xcconfig
CODE_SIGN_STYLE = Manual
DEVELOPMENT_TEAM = YOURTEAMID
CODE_SIGN_IDENTITY = Apple Development
PROVISIONING_PROFILE_SPECIFIER =
```

`Config/Signing.local.xcconfig` is ignored by git. The default `Manual` signing style keeps Xcode's "Automatically manage signing" checkbox off. Keep `PROVISIONING_PROFILE_SPECIFIER` blank unless Xcode requires a specific manual provisioning profile. Avoid choosing a Team directly in Xcode's Signing & Capabilities editor if that creates a `CubeBridge.xcodeproj/project.pbxproj` diff with your personal Team ID.

For one-off command line builds, pass the same values without editing any project files:

```sh
xcodebuild \
  -project CubeBridge.xcodeproj \
  -scheme CubeBridge \
  -destination 'platform=macOS' \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM=YOURTEAMID \
  CODE_SIGN_IDENTITY='Apple Development' \
  build
```

Never commit signing secrets such as `.p12` files, provisioning profiles, App Store Connect API keys, or `AuthKey_*.p8` files.

## Releases

Releases are managed by Release Please. Conventional Commit messages merged into
`main` update the release PR. The bootstrap version in the repository is
`0.0.0`; the first Release Please PR proposes `v1.0.0`. Merging a release PR
updates `version.txt`, `CHANGELOG.md`, and the Xcode marketing/build versions,
then creates a `v*` git tag and a draft GitHub Release. The release workflow
builds a signed, notarized `CubeBridge-v*.dmg`, uploads it to that GitHub
Release, generates a Sparkle appcast at
`https://yaeda.github.io/cube-bridge/appcast.xml`, and publishes the release
after the appcast is deployed.

The app uses Sparkle 2 for update checks. Release notes are maintained manually
in four repository GitHub Wiki pages:

- `Release-Notes-Latest-en` contains only the latest English release.
- `Release-Notes-Latest-ja` contains only the latest Japanese release.
- `Release-Notes-Full-en` contains the complete English release history, newest
  first.
- `Release-Notes-Full-ja` contains the complete Japanese release history,
  newest first.

The appcast passes the two Latest pages to Sparkle as raw Markdown. CubeBridge
uses Sparkle's standard update UI and does not parse, trim, or otherwise modify
the release-note body. Each Latest page must end with a Markdown link to the
rendered Full page in the same language:

- English: `https://github.com/yaeda/cube-bridge/wiki/Release-Notes-Full-en`
- Japanese: `https://github.com/yaeda/cube-bridge/wiki/Release-Notes-Full-ja`

Sparkle supports one full-release-notes URL, so the appcast points it to the
rendered Wiki Home at `https://github.com/yaeda/cube-bridge/wiki`. Configure
Wiki Home once as a language selector linking to both rendered Full pages.

Before merging a Release Please PR, replace both Latest pages with the single
new release and prepend that release to both Full pages. Write the English
release notes for users, then translate and edit the Japanese version rather
than copying `CHANGELOG.md` verbatim. The first Markdown heading in each Latest
page and the corresponding Full page must include the target version. The
release workflow verifies all four raw pages, Wiki Home, target versions, and
Latest-to-Full links before building the signed app.

Configure these repository secrets before merging the first release PR:

- `APPLE_TEAM_ID`
- `DEVELOPER_ID_APPLICATION_CERTIFICATE_BASE64`
- `DEVELOPER_ID_APPLICATION_CERTIFICATE_PASSWORD`
- `KEYCHAIN_PASSWORD`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_P8_BASE64`
- `SPARKLE_PUBLIC_ED_KEY`
- `SPARKLE_PRIVATE_ED_KEY_BASE64`

Optional: set `RELEASE_PLEASE_TOKEN` to a classic PAT or GitHub App token with
repository contents and pull request permissions if Release Please-created PRs
must trigger additional workflows. Without it, the workflow falls back to
`GITHUB_TOKEN`.

The Sparkle private EdDSA key should be base64-encoded before storing it in
`SPARKLE_PRIVATE_ED_KEY_BASE64`; only the public key is embedded in release
builds.

## Using The App

1. Turn on a toio Core Cube.
2. Launch CubeBridge.
3. Wait for the cube to appear in the menu bar cube list.
4. Click `Connect`.
5. Optionally enable `Launch at Login` in the menu bar so CubeBridge is ready for Shortcuts after login.
6. Use `Check for Updates...` to manually check the Sparkle appcast for updates.
7. Use `Identify` in the menu bar to confirm which connected cube is which.

## Using Apple Shortcuts

After installing and running CubeBridge once, open the Shortcuts app and search for `toio` or `CubeBridge`. On some macOS versions, the actions may appear in search before CubeBridge appears in the Apps list.

The MVP registers these actions:

- `Move toio Cube`
- `Stop toio Cube`
- `Set toio Lamp`
- `Turn Off toio Lamp`

Each action can accept a connected cube. If no cube is selected, CubeBridge uses the first connected cube. If no cube is connected, the Shortcut returns a readable error message.

## Known Limitations

- Shortcuts App Intents require the app to be signed with a valid local Apple Development identity during local development.
- Shortcuts can launch the app, but a cube must already be connected before a command can run.
- Motor and lamp controls are implemented; sound characteristic discovery and command helpers are prepared, but sound Shortcuts are deferred.
- BLE write-without-response operations cannot report device-side write failures.
- Hardware behavior must be validated with a physical toio Core Cube.

## Future Extensions

- Add sound effect and MIDI note Shortcuts.
- Add persistent cube aliases.
- Add reconnect-on-launch for known cubes.
- Add URL scheme and localhost HTTP API adapters using the same command layer.
- Add richer multi-cube selection and batch commands.
