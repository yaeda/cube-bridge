import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var manager: CubeManager

    @State private var leftSpeed = 50.0
    @State private var rightSpeed = 50.0
    @State private var motorDuration = 500
    @State private var red = 0.0
    @State private var green = 160.0
    @State private var blue = 255.0
    @State private var lampDuration = 1000
    @State private var selectedCubeID = ""
    @State private var commandStatus = "Ready"

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            CubeListView()

            Divider()

            controlPanel
        }
        .padding(20)
        .frame(minWidth: 680, minHeight: 620)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ToioBridge")
                .font(.largeTitle.bold())
            HStack(spacing: 16) {
                if manager.connectedCubes.isEmpty {
                    Label("No connected cube", systemImage: "cube.transparent")
                } else {
                    Label("Connected: \(manager.connectedCubes.count)", systemImage: "cube")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let bluetoothIssueMessage {
                Label(bluetoothIssueMessage, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if let lastErrorMessage = manager.lastErrorMessage {
                Text(lastErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var controlPanel: some View {
        Grid(alignment: .leading, horizontalSpacing: 32, verticalSpacing: 18) {
            GridRow {
                Picker("Target Cube", selection: $selectedCubeID) {
                    Text("First connected cube").tag("")
                    ForEach(manager.connectedCubes) { cube in
                        Text("\(cube.name) (\(cube.displayID))").tag(cube.id)
                    }
                }
                .disabled(manager.connectedCubes.isEmpty)
                .frame(maxWidth: 320)

                selectedCubeStatus
            }

            GridRow {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Motor")
                        .font(.headline)
                    speedSlider(title: "Left Motor Speed", value: $leftSpeed)
                    speedSlider(title: "Right Motor Speed", value: $rightSpeed)
                    Stepper("Duration: \(motorDuration) ms", value: $motorDuration, in: 0...2550, step: 10)

                    HStack {
                        Button("Move") {
                            runCommand {
                                try await manager.move(
                                    cubeID: targetCubeID,
                                    left: Int(leftSpeed.rounded()),
                                    right: Int(rightSpeed.rounded()),
                                    durationMs: motorDuration
                                )
                            }
                        }
                        Button("Stop") {
                            runCommand {
                                try await manager.stop(cubeID: targetCubeID)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Lamp")
                        .font(.headline)
                    colorSlider(title: "Red", value: $red, tint: .red)
                    colorSlider(title: "Green", value: $green, tint: .green)
                    colorSlider(title: "Blue", value: $blue, tint: .blue)
                    Stepper("Duration: \(lampDuration) ms", value: $lampDuration, in: 0...2550, step: 10)

                    HStack {
                        Button("Set Lamp") {
                            runCommand {
                                try await manager.setLamp(
                                    cubeID: targetCubeID,
                                    red: Int(red.rounded()),
                                    green: Int(green.rounded()),
                                    blue: Int(blue.rounded()),
                                    durationMs: lampDuration
                                )
                            }
                        }
                        Button("Turn Off") {
                            runCommand {
                                try await manager.turnOffLamp(cubeID: targetCubeID)
                            }
                        }
                    }
                }
            }

            GridRow {
                Text(commandStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .gridCellColumns(2)
            }
        }
        .onChange(of: manager.connectedCubes.map(\.id)) { connectedIDs in
            if !selectedCubeID.isEmpty, !connectedIDs.contains(selectedCubeID) {
                selectedCubeID = ""
            }
        }
    }

    private var targetCubeID: String? {
        selectedCubeID.isEmpty ? nil : selectedCubeID
    }

    private var bluetoothIssueMessage: String? {
        if manager.authorizationDescription == "Denied" || manager.authorizationDescription == "Restricted" {
            return "Bluetooth permission is not allowed."
        }

        switch manager.bluetoothStateDescription {
        case "Powered On":
            return nil
        case "Powered Off":
            return "Bluetooth is off."
        case "Unauthorized":
            return "Bluetooth permission is not allowed."
        case "Unsupported":
            return "Bluetooth is not supported on this Mac."
        case "Resetting":
            return "Bluetooth is resetting. Please wait."
        case "Unknown":
            return nil
        default:
            return "Bluetooth is unavailable."
        }
    }

    private var selectedCubeStatus: some View {
        let selectedCube = manager.connectedCubes.first { cube in
            cube.id == selectedCubeID
        } ?? manager.connectedCubes.first

        return Group {
            if let selectedCube {
                Text("Commands target: \(selectedCube.name) (\(selectedCube.displayID))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Commands require a connected cube.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func speedSlider(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading) {
            Text("\(title): \(Int(value.wrappedValue.rounded()))")
                .font(.caption)
            Slider(value: value, in: -100...100, step: 1)
        }
    }

    private func colorSlider(title: String, value: Binding<Double>, tint: Color) -> some View {
        VStack(alignment: .leading) {
            Text("\(title): \(Int(value.wrappedValue.rounded()))")
                .font(.caption)
            Slider(value: value, in: 0...255, step: 1)
                .tint(tint)
        }
    }

    private func runCommand(_ operation: @escaping () async throws -> Void) {
        commandStatus = "Running..."
        Task {
            do {
                try await operation()
                commandStatus = "Done"
            } catch {
                commandStatus = error.localizedDescription
            }
        }
    }
}
