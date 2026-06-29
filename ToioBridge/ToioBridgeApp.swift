import SwiftUI

@main
struct ToioBridgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var cubeManager = CubeManager.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(cubeManager)
        } label: {
            Label(
                "ToioBridge",
                systemImage: cubeManager.connectedCubes.isEmpty ? "cube" : "cube.fill"
            )
        }
        .menuBarExtraStyle(.window)

        WindowGroup("ToioBridge") {
            SettingsView()
                .environmentObject(cubeManager)
        }
    }
}
