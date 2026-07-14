import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var manager: CubeManager
    @EnvironmentObject private var sparkleUpdater: SparkleUpdater
    @StateObject private var loginItemManager = LoginItemManager()
    @State private var cubeCommandStatuses: [String: String] = [:]
    @State private var isMoreCubesPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("ToioBridge")
                    .font(.headline)
                Spacer()
                Text(appVersion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let bluetoothIssueMessage {
                Label(bluetoothIssueMessage, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
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
                        ForEach(visibleCubes) { cube in
                            MenuBarCubeRow(cube: cube, commandStatus: cubeCommandStatuses[cube.id]) { operation in
                                runCommand(cubeID: cube.id, status: "Identifying...", operation)
                            }
                            .environmentObject(manager)
                        }

                        if !moreCubes.isEmpty {
                            MoreCubesRow(count: moreCubes.count, isPresented: $isMoreCubesPresented)
                                .popover(isPresented: $isMoreCubesPresented, arrowEdge: .trailing) {
                                    MoreCubesPanel(
                                        cubes: moreCubes,
                                        commandStatuses: cubeCommandStatuses
                                    ) { cubeID, operation in
                                        runCommand(cubeID: cubeID, status: "Identifying...", operation)
                                    }
                                    .environmentObject(manager)
                                }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Divider()

            MenuCommandRow(title: manager.isScanning ? "Stop Scanning" : "Start Scanning") {
                manager.isScanning ? manager.stopScanning() : manager.startScanning()
            }

            Divider()

            HStack {
                Text("Launch at Login")
                Spacer()
                Toggle(
                    "Launch at Login",
                    isOn: Binding(
                        get: { loginItemManager.isLaunchAtLoginEnabled },
                        set: { loginItemManager.setLaunchAtLoginEnabled($0) }
                    )
                )
                .labelsHidden()
                .toggleStyle(.switch)
            }

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

            Divider()

            MenuCommandRow(title: "Check for Updates...", isDisabled: !sparkleUpdater.canCheckForUpdates) {
                sparkleUpdater.checkForUpdates()
            }

            MenuCommandRow(title: "Quit ToioBridge") {
                NSApp.terminate(nil)
            }
        }
        .padding()
        .frame(width: 320)
        .onAppear {
            loginItemManager.refresh()
        }
    }

    private var visibleCubes: [ToioCube] {
        Array(manager.discoveredCubes.prefix(3))
    }

    private var moreCubes: [ToioCube] {
        Array(manager.discoveredCubes.dropFirst(3))
    }

    private func runCommand(cubeID: String, status: String, _ operation: @escaping () async throws -> Void) {
        guard cubeCommandStatuses[cubeID] != status else {
            return
        }

        cubeCommandStatuses[cubeID] = status
        Task {
            do {
                try await operation()
                cubeCommandStatuses.removeValue(forKey: cubeID)
            } catch {
                cubeCommandStatuses[cubeID] = "Identify Failed"
            }
        }
    }

    private var appVersion: String {
        guard
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            !version.isEmpty,
            !version.contains("$(")
        else {
            return "v0.0.0"
        }

        return "v\(version)"
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

}

private struct MenuCommandRow: View {
    let title: String
    var isDisabled = false
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
            }
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background {
                if isHovered && !isDisabled {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.primary.opacity(0.08))
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .foregroundStyle(isDisabled ? .secondary : .primary)
        .onHover { isHovered = $0 }
        .padding(.horizontal, -6)
    }
}

private struct CubeIconButton: View {
    let title: String
    let systemImage: String
    var isDisabled = false
    var helpText: String?
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
                .background {
                    if isHovered && !isDisabled {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.primary.opacity(0.08))
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .foregroundStyle(isDisabled ? .secondary : .primary)
        .help(helpText ?? title)
        .accessibilityLabel(title)
        .onHover { isHovered = $0 }
    }
}

private struct CubeTextButton: View {
    let title: String
    var isDisabled = false
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 6)
                .frame(minHeight: 28)
                .contentShape(Rectangle())
                .background {
                    if isHovered && !isDisabled {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.primary.opacity(0.08))
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .foregroundStyle(isDisabled ? .secondary : .primary)
        .onHover { isHovered = $0 }
    }
}

private struct MoreCubesRow: View {
    let count: Int
    @Binding var isPresented: Bool
    @State private var isHovered = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            HStack(spacing: 8) {
                Text("More")
                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background {
                if isHovered || isPresented {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.primary.opacity(0.08))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show \(count) more cubes")
        .padding(.horizontal, -6)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                isPresented = true
            }
        }
    }
}

private struct MoreCubesPanel: View {
    @EnvironmentObject private var manager: CubeManager
    let cubes: [ToioCube]
    let commandStatuses: [String: String]
    let runIdentify: (String, @escaping () async throws -> Void) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("More Cubes")
                .font(.headline)

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(cubes) { cube in
                        MenuBarCubeRow(cube: cube, commandStatus: commandStatuses[cube.id]) { operation in
                            runIdentify(cube.id, operation)
                        }
                        .environmentObject(manager)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(width: 320, height: panelHeight)
    }

    private var panelHeight: CGFloat {
        min(CGFloat(cubes.count) * 41 + 51, 360)
    }
}

private struct MenuBarCubeRow: View {
    @EnvironmentObject private var manager: CubeManager
    @ObservedObject var cube: ToioCube
    let commandStatus: String?
    let runIdentify: (@escaping () async throws -> Void) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(cube.name)
                        .lineLimit(1)
                    Text("ID: \(cube.displayID)  \(statusText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                HStack(spacing: 4) {
                    if cube.connectionState == .ready {
                        CubeIconButton(
                            title: "Identify",
                            systemImage: "hand.point.right",
                            isDisabled: isIdentifyDisabled,
                            helpText: identifyHelpText
                        ) {
                            runIdentify {
                                try await manager.identify(cubeID: cube.id)
                            }
                        }
                    }

                    if cube.connectionState == .connected || cube.connectionState == .ready {
                        CubeTextButton(title: "Disconnect") {
                            manager.disconnect(cube)
                        }
                    } else {
                        CubeTextButton(
                            title: cube.connectionState == .connecting ? "Connecting" : "Connect",
                            isDisabled: cube.connectionState == .connecting
                        ) {
                            manager.connect(cube)
                        }
                    }
                }
            }
        }
    }

    private var statusText: String {
        commandStatus ?? cube.connectionState.rawValue
    }

    private var isIdentifyDisabled: Bool {
        commandStatus == "Identifying..." || cube.soundCharacteristic == nil
    }

    private var identifyHelpText: String {
        if commandStatus == "Identifying..." {
            return "Identify in progress"
        }

        return cube.soundCharacteristic == nil ? "Identify unavailable until sound is ready" : "Identify"
    }
}
