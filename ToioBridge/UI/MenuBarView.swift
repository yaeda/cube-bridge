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

            if manager.connectedCubes.isEmpty {
                Text("No cube connected")
                    .foregroundStyle(.secondary)
            } else {
                Text("Connected cubes: \(manager.connectedCubes.count)")
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Cubes")
                    .font(.subheadline.weight(.semibold))

                if manager.discoveredCubes.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("No cubes found")
                            .foregroundStyle(.secondary)
                        if manager.isScanning {
                            Text("Scanning...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(manager.discoveredCubes.prefix(5))) { cube in
                            MenuBarCubeRow(cube: cube, runCommand: runCommand)
                                .environmentObject(manager)
                        }

                        if manager.discoveredCubes.count > 5 {
                            Text("+ \(manager.discoveredCubes.count - 5) more in the main window")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if commandStatus != "Ready" {
                Text(commandStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button(manager.isScanning ? "Stop Scanning" : "Start Scanning") {
                manager.isScanning ? manager.stopScanning() : manager.startScanning()
            }

            Button("Quit ToioBridge") {
                NSApp.terminate(nil)
            }
        }
        .padding()
        .frame(width: 320)
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

private struct MenuBarCubeRow: View {
    @EnvironmentObject private var manager: CubeManager
    @ObservedObject var cube: ToioCube
    let runCommand: (@escaping () async throws -> Void) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(cube.name)
                        .lineLimit(1)
                    Text("ID: \(cube.displayID)  \(cube.connectionState.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if cube.connectionState == .connected || cube.connectionState == .ready {
                    Button("Disconnect") {
                        manager.disconnect(cube)
                    }
                } else {
                    Button("Connect") {
                        manager.connect(cube)
                    }
                    .disabled(cube.connectionState == .connecting)
                }
            }

            if cube.connectionState == .ready {
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
            }
        }
    }
}
