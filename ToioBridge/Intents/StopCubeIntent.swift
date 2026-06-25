import AppIntents
import Foundation

struct StopCubeIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop toio Cube"
    static var description = IntentDescription("Stop a connected toio Core Cube.")
    static var openAppWhenRun = true

    @Parameter(title: "Cube")
    var cube: CubeEntity?

    func perform() async throws -> some IntentResult {
        do {
            try await CubeManager.shared.stop(cubeID: cube?.id)
            return .result(dialog: "Stopped toio Cube.")
        } catch {
            AppLogger.intents.error("StopCubeIntent failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
}
