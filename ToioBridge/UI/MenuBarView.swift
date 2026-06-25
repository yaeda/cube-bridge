import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var manager: CubeManager
    @State private var commandStatus = "Ready"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ToioBridge")
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(manager.bluetoothStateDescription == "Powered On" ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }

            Text("Bluetooth: \(manager.bluetoothStateDescription)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let cube = manager.connectedCubes.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cube.name)
                        .font(.subheadline)
                    Text("ID: \(cube.displayID)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Button("Forward") {
                        runCommand {
                            try await manager.move(cubeID: cube.id, left: 50, right: 50, durationMs: 500)
                        }
                    }
                    Button("Stop") {
                        runCommand {
                            try await manager.stop(cubeID: cube.id)
                        }
                    }
                    Button("Lamp") {
                        runCommand {
                            try await manager.setLamp(cubeID: cube.id, red: 0, green: 160, blue: 255, durationMs: 1000)
                        }
                    }
                }
            } else {
                Text("No cube connected")
                    .foregroundStyle(.secondary)
            }

            Text(commandStatus)
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Button(manager.isScanning ? "Stop Scanning" : "Start Scanning") {
                manager.isScanning ? manager.stopScanning() : manager.startScanning()
            }

            Button("Quit ToioBridge") {
                NSApp.terminate(nil)
            }
        }
        .padding()
        .frame(width: 280)
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
