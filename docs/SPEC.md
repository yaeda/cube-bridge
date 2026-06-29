# ToioBridge MVP Specification

## Overview

ToioBridge is a macOS 13+ SwiftUI menu bar app that controls toio Core Cube devices over Bluetooth Low Energy and exposes cube commands to Apple Shortcuts through App Intents.

The app bundle identifier is `io.github.yaeda.ToioBridge`.

## MVP Behavior

- The app runs as a normal macOS app with a menu bar extra and a simple main window.
- The menu bar extra shows the `cube` SF Symbol when no cube is connected and `cube.fill` when one or more cubes are connected.
- The UI shows Bluetooth state, discovered toio Core Cube devices, connection controls, connected cube details, motor controls, and lamp controls.
- The menu bar UI can send quick forward, stop, and lamp commands to each ready connected cube.
- BLE scanning starts after `CBCentralManager` reaches `poweredOn`.
- Cubes are discovered by scanning with the toio service UUID filter. Names are not used for discovery because users can change them.
- The app also checks macOS-retrieved peripherals connected with the toio service UUID, so cubes already connected at the system level can appear in the list.
- The app discovers the toio service and motor, indicator, and sound characteristics.
- The app can move, stop, set the lamp, and turn off the lamp for a connected cube.
- The main window lets the user choose a target connected cube for motor and lamp commands; if no explicit target is selected, the first connected cube is used.
- Shortcuts exposes native App Intents for move, stop, set lamp, and turn off lamp.
- For local development, Shortcuts execution expects ToioBridge to be signed with a valid local Apple Development identity; ad-hoc signing can prevent Shortcuts from communicating with the app.
- When a Shortcut omits the cube parameter, the first connected cube is used.
- If Bluetooth is unavailable, permission is denied, no cube is connected, or a characteristic is unavailable, the app returns a user-readable error.

## Signing Configuration

- The committed Xcode project must not contain a personal or organization Apple Developer Team ID.
- Public defaults are provided by `Config/Signing.xcconfig`.
- Developers may copy `Config/Signing.local.xcconfig.example` to `Config/Signing.local.xcconfig` for local signing; that local file is ignored by git.
- Local signing uses manual signing by default so Xcode's "Automatically manage signing" checkbox remains off.
- Manual provisioning profile selection is optional and should be configured only in the ignored local signing file when Xcode requires it.
- Command line builds may override `CODE_SIGN_STYLE`, `DEVELOPMENT_TEAM`, and `CODE_SIGN_IDENTITY` without modifying the Xcode project.
- Signing secrets and credentials, including `.p12`, provisioning profiles, and `AuthKey_*.p8`, must not be committed.

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
- Full BLE and Shortcuts behavior requires manual testing on macOS with a physical toio Core Cube.
