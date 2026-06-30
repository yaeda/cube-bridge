# ToioBridge

ToioBridge is a macOS menu bar app that connects to toio Core Cube devices over Bluetooth Low Energy and exposes cube controls to Apple Shortcuts using App Intents.

## Requirements

- macOS 13 or later
- Xcode 26 or later
- A toio Core Cube with Bluetooth enabled

## Setup

1. Open `ToioBridge.xcodeproj` in Xcode.
2. Select the `ToioBridge` scheme.
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

`Config/Signing.local.xcconfig` is ignored by git. The default `Manual` signing style keeps Xcode's "Automatically manage signing" checkbox off. Keep `PROVISIONING_PROFILE_SPECIFIER` blank unless Xcode requires a specific manual provisioning profile. Avoid choosing a Team directly in Xcode's Signing & Capabilities editor if that creates a `ToioBridge.xcodeproj/project.pbxproj` diff with your personal Team ID.

For one-off command line builds, pass the same values without editing any project files:

```sh
xcodebuild \
  -project ToioBridge.xcodeproj \
  -scheme ToioBridge \
  -destination 'platform=macOS' \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM=YOURTEAMID \
  CODE_SIGN_IDENTITY='Apple Development' \
  build
```

Never commit signing secrets such as `.p12` files, provisioning profiles, App Store Connect API keys, or `AuthKey_*.p8` files.

## Using The App

1. Turn on a toio Core Cube.
2. Launch ToioBridge.
3. Wait for the cube to appear in the menu bar cube list.
4. Click `Connect`.
5. Optionally enable `Launch at Login` in the menu bar so ToioBridge is ready for Shortcuts after login.
6. Use the motor and lamp controls in the menu bar.

## Using Apple Shortcuts

After installing and running ToioBridge once, open the Shortcuts app and search for `toio` or `ToioBridge`. On some macOS versions, the actions may appear in search before ToioBridge appears in the Apps list.

The MVP registers these actions:

- `Move toio Cube`
- `Stop toio Cube`
- `Set toio Lamp`
- `Turn Off toio Lamp`

Each action can accept a connected cube. If no cube is selected, ToioBridge uses the first connected cube. If no cube is connected, the Shortcut returns a readable error message.

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
