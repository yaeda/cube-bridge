# ToioBridge

ToioBridge is a macOS menu bar app that connects to toio Core Cube devices over Bluetooth Low Energy and exposes cube controls to Apple Shortcuts using App Intents.

## Requirements

- macOS 13 or later
- Xcode 26 or later
- A toio Core Cube with Bluetooth enabled

## Setup

1. Open `ToioBridge.xcodeproj` in Xcode.
2. Select the `ToioBridge` scheme.
3. If Xcode asks for signing settings, choose your local team or "Sign to Run Locally".
4. Build and run the app.
5. Grant Bluetooth permission when macOS prompts for it.

The app appears in the menu bar and also opens a simple main window for scanning, connecting, and sending test commands.

## Using The App

1. Turn on a toio Core Cube.
2. Launch ToioBridge.
3. Wait for the cube to appear in the discovered cube list.
4. Click `Connect`.
5. Use the motor and lamp controls in the app window or menu bar.

## Using Apple Shortcuts

After building and running ToioBridge once, open the Shortcuts app and search for `toio` or `ToioBridge`. On some macOS versions, the actions may appear in search before ToioBridge appears in the Apps list.

The MVP registers these actions:

- `Move toio Cube`
- `Stop toio Cube`
- `Set toio Lamp`
- `Turn Off toio Lamp`

Each action can accept a connected cube. If no cube is selected, ToioBridge uses the first connected cube. If no cube is connected, the Shortcut returns a readable error message.

## Known Limitations

- The MVP focuses on one connected cube, although the model supports multiple connected cubes.
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
