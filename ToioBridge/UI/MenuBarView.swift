import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var manager: CubeManager
    @StateObject private var loginItemManager = LoginItemManager()
    @State private var commandStatus = "Ready"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ToioBridge")
                    .font(.headline)
                Spacer()
            }

            if let bluetoothIssueMessage {
                Label(bluetoothIssueMessage, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

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
                    ScrollView(.vertical) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(manager.discoveredCubes) { cube in
                                MenuBarCubeRow(cube: cube, runCommand: runCommand)
                                    .environmentObject(manager)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: cubeListHeight)
                }
            }

            if commandStatus != "Ready" {
                Text(commandStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Toggle(
                "Launch at Login",
                isOn: Binding(
                    get: { loginItemManager.isLaunchAtLoginEnabled },
                    set: { loginItemManager.setLaunchAtLoginEnabled($0) }
                )
            )
            .toggleStyle(.switch)

            if let loginItemStatusMessage = loginItemManager.statusMessage {
                Text(loginItemStatusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let loginItemErrorMessage = loginItemManager.errorMessage {
                Text(loginItemErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button(manager.isScanning ? "Stop Scanning" : "Start Scanning") {
                manager.isScanning ? manager.stopScanning() : manager.startScanning()
            }

            Button("Quit ToioBridge") {
                NSApp.terminate(nil)
            }
        }
        .padding()
        .frame(width: 320)
        .onAppear {
            loginItemManager.refresh()
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

    private var cubeListHeight: CGFloat {
        let rowHeights = manager.discoveredCubes.map { cube in
            cube.connectionState == .ready ? CGFloat(76) : CGFloat(48)
        }
        let spacing = CGFloat(max(manager.discoveredCubes.count - 1, 0) * 8)
        return min(rowHeights.reduce(0, +) + spacing, 280)
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
