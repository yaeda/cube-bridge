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
                Label("Bluetooth: \(manager.bluetoothStateDescription)", systemImage: "dot.radiowaves.left.and.right")
                Label("Permission: \(manager.authorizationDescription)", systemImage: "lock")
                if let cube = manager.connectedCubes.first {
                    Label("Connected: \(cube.name) (\(cube.displayID))", systemImage: "cube")
                } else {
                    Label("No connected cube", systemImage: "cube.transparent")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

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
                                    left: Int(leftSpeed.rounded()),
                                    right: Int(rightSpeed.rounded()),
                                    durationMs: motorDuration
                                )
                            }
                        }
                        Button("Stop") {
                            runCommand {
                                try await manager.stop()
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
                                    red: Int(red.rounded()),
                                    green: Int(green.rounded()),
                                    blue: Int(blue.rounded()),
                                    durationMs: lampDuration
                                )
                            }
                        }
                        Button("Turn Off") {
                            runCommand {
                                try await manager.turnOffLamp()
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
