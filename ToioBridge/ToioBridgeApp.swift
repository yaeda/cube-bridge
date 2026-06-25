import SwiftUI

@main
struct ToioBridgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var cubeManager = CubeManager.shared

    var body: some Scene {
        MenuBarExtra("ToioBridge", systemImage: "dot.radiowaves.left.and.right") {
            MenuBarView()
                .environmentObject(cubeManager)
        }
        .menuBarExtraStyle(.window)

        WindowGroup("ToioBridge") {
            SettingsView()
                .environmentObject(cubeManager)
        }
    }
}
