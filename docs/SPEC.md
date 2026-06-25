# ToioBridge MVP Specification

## Overview

ToioBridge is a macOS 13+ SwiftUI menu bar app that controls toio Core Cube devices over Bluetooth Low Energy and exposes cube commands to Apple Shortcuts through App Intents.

The app bundle identifier is `io.github.yaeda.ToioBridge`.

## MVP Behavior

- The app runs as a normal macOS app with a menu bar extra and a simple main window.
- The UI shows Bluetooth state, discovered toio Core Cube devices, connection controls, connected cube details, motor controls, and lamp controls.
- BLE scanning starts after `CBCentralManager` reaches `poweredOn`.
- Cubes are discovered by the toio service UUID and by `toio-` local-name fallback.
- The app discovers the toio service and motor, indicator, and sound characteristics.
- The app can move, stop, set the lamp, and turn off the lamp for a connected cube.
- Shortcuts exposes native App Intents for move, stop, set lamp, and turn off lamp.
- When a Shortcut omits the cube parameter, the first connected cube is used.
- If Bluetooth is unavailable, permission is denied, no cube is connected, or a characteristic is unavailable, the app returns a user-readable error.

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
