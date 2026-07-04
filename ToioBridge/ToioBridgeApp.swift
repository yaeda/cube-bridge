import SwiftUI

@main
struct ToioBridgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var cubeManager = CubeManager.shared
    @StateObject private var sparkleUpdater = SparkleUpdater()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(cubeManager)
                .environmentObject(sparkleUpdater)
        } label: {
            Label(
                "ToioBridge",
                systemImage: cubeManager.connectedCubes.isEmpty ? "cube" : "cube.fill"
            )
        }
        .menuBarExtraStyle(.window)
    }
}
