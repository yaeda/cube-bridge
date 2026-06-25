import SwiftUI

struct CubeListView: View {
    @EnvironmentObject private var manager: CubeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cubes")
                    .font(.headline)
                Spacer()
                Button(manager.isScanning ? "Stop Scan" : "Scan") {
                    manager.isScanning ? manager.stopScanning() : manager.startScanning()
                }
            }

            if manager.discoveredCubes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No Cubes Found")
                        .font(.headline)
                    Text("Turn on a toio Core Cube and keep it nearby.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 180)
            } else {
                List(manager.discoveredCubes) { cube in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(cube.name)
                                .font(.body)
                            Text("ID: \(cube.displayID)  RSSI: \(cube.rssi)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let lastErrorMessage = cube.lastErrorMessage {
                                Text(lastErrorMessage)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }

                        Spacer()

                        Text(cube.connectionState.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)

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
                    .padding(.vertical, 4)
                }
                .frame(minHeight: 220)
            }
        }
    }
}
