import AppIntents
import Foundation

struct TurnOffLampIntent: AppIntent {
    static var title: LocalizedStringResource = "Turn Off toio Lamp"
    static var description = IntentDescription("Turn off the lamp on a connected toio Core Cube.")
    static var openAppWhenRun = true
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    static var supportedModes: IntentModes { .foreground(.dynamic) }

    @Parameter(title: "Cube")
    var cube: CubeEntity?

    @MainActor
    func perform() async throws -> some IntentResult {
        do {
            try await CubeManager.shared.turnOffLamp(cubeID: cube?.id)
            return .result(dialog: "Turned off toio Lamp.")
        } catch {
            AppLogger.intents.error("TurnOffLampIntent failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
}
