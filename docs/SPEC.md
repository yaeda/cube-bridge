# ToioBridge MVP Specification

## Overview

ToioBridge is a macOS 13+ SwiftUI menu bar app that controls toio Core Cube devices over Bluetooth Low Energy and exposes cube commands to Apple Shortcuts through App Intents.

The app bundle identifier is `io.github.yaeda.ToioBridge`.

## MVP Behavior

- The app runs as a menu bar agent app that does not appear in Dock or Command-Tab.
- The app offers a user-controlled "Launch at Login" setting in the menu bar using the main app login item service.
- The menu bar extra shows the `cube` SF Symbol when no cube is connected and `cube.fill` when one or more cubes are connected.
- The UI shows Bluetooth state, discovered toio Core Cube devices, connection controls, connected cube details, and an identify control for each ready connected cube.
- The menu bar UI shows up to three discovered cubes inline and exposes additional discovered cubes through a "More" row with a scrollable subpanel.
- The menu bar UI can identify a ready connected cube by playing a short sound, lighting the lamp, and making a small in-place movement.
- The menu bar UI exposes a "Check for Updates..." command backed by Sparkle 2.
- BLE scanning starts after `CBCentralManager` reaches `poweredOn`.
- Cubes are discovered by scanning with the toio service UUID filter. Names are not used for discovery because users can change them.
- The app also checks macOS-retrieved peripherals connected with the toio service UUID, so cubes already connected at the system level can appear in the list.
- Cube display IDs use the three-character suffix from standard toio names, or the first five characters of the peripheral UUID for custom names. Internal identification continues to use the full peripheral UUID.
- The app discovers the toio service and motor, indicator, and sound characteristics.
- The app can move, stop, set the lamp, and turn off the lamp for a connected cube.
- The menu bar UI sends identify commands from each ready cube row.
- Shortcuts exposes native App Intents for move, stop, set lamp, and turn off lamp.
- For local development, Shortcuts execution expects ToioBridge to be signed with a valid local Apple Development identity; ad-hoc signing can prevent Shortcuts from communicating with the app.
- When a Shortcut omits the cube parameter, the first connected cube is used.
- If Bluetooth is unavailable, permission is denied, no cube is connected, or a characteristic is unavailable, the app returns a user-readable error.

## Update Distribution

- The app checks for updates with Sparkle 2 using the appcast at `https://yaeda.github.io/toio-bridge/appcast.xml`.
- Sparkle update archives are full signed and notarized `.dmg` files hosted as GitHub Release assets.
- The Sparkle appcast is hosted on GitHub Pages and points each update enclosure at the matching GitHub Release `.dmg`.
- Sparkle release notes are raw Markdown files hosted from the repository GitHub Wiki.
- Each appcast item links English and Japanese release notes with `sparkle:releaseNotesLink` and `xml:lang`.
- ToioBridge adapts full Markdown release notes through Sparkle's standard user driver delegate so the update UI only shows sections newer than the installed bundle version.
- Release Please PRs include a checklist requiring maintainers to manually write the English Wiki release notes, translate and edit the Japanese Wiki release notes, and verify both raw Wiki URLs before merge.
- Wiki release notes should be written for users rather than copied directly from `CHANGELOG.md`; each fixed-language page should contain the full release history so multi-version upgrades can be filtered locally.
- The release workflow verifies the English and Japanese raw Wiki release-note URLs before deploying the appcast and publishing the GitHub Release.

## Signing Configuration

- The committed Xcode project must not contain a personal or organization Apple Developer Team ID.
- Public defaults are provided by `Config/Signing.xcconfig`.
- Developers may copy `Config/Signing.local.xcconfig.example` to `Config/Signing.local.xcconfig` for local signing; that local file is ignored by git.
- Local signing uses manual signing by default so Xcode's "Automatically manage signing" checkbox remains off.
- Manual provisioning profile selection is optional and should be configured only in the ignored local signing file when Xcode requires it.
- Command line builds may override `CODE_SIGN_STYLE`, `DEVELOPMENT_TEAM`, and `CODE_SIGN_IDENTITY` without modifying the Xcode project.
- Signing secrets and credentials, including `.p12`, provisioning profiles, and `AuthKey_*.p8`, must not be committed.
- Sparkle EdDSA private keys must not be committed; the public key is injected into release builds through `SPARKLE_PUBLIC_ED_KEY`.

## BLE UUIDs

- Service: `10B20100-5B3B-4571-9508-CF3EFCD7BBAE`
- Motor: `10B20102-5B3B-4571-9508-CF3EFCD7BBAE`
- Indicator: `10B20103-5B3B-4571-9508-CF3EFCD7BBAE`
- Sound: `10B20104-5B3B-4571-9508-CF3EFCD7BBAE`

## Command Constraints

- Motor speed inputs are `-100...100`.
- Motor and lamp durations are `0...2550` milliseconds and are encoded in 10 millisecond units.
- RGB values are `0...255`.
- Motor stop writes both motors with speed `0`.

## Validation

- Unit tests cover command byte encoding and input validation.
- Xcode build and test should pass with the `ToioBridge` scheme.
- Release automation should validate that generated appcasts contain the GitHub Release `.dmg` URL, `sparkle:edSignature`, `length`, the expected Sparkle version, and English/Japanese release-note links.
- Full BLE and Shortcuts behavior requires manual testing on macOS with a physical toio Core Cube.
