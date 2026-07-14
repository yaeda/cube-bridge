import AppIntents
import Foundation

struct SetLampIntent: AppIntent {
    static var title: LocalizedStringResource = "Set toio Lamp"
    static var description = IntentDescription("Set the lamp color on a connected toio Core Cube.")
    static var openAppWhenRun = true
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    static var supportedModes: IntentModes { .foreground(.dynamic) }

    @Parameter(title: "Cube")
    var cube: CubeEntity?

    @Parameter(title: "Red", default: 0)
    var red: Int

    @Parameter(title: "Green", default: 160)
    var green: Int

    @Parameter(title: "Blue", default: 255)
    var blue: Int

    @Parameter(title: "Duration milliseconds", default: 1000)
    var durationMilliseconds: Int

    @MainActor
    func perform() async throws -> some IntentResult {
        do {
            try await CubeManager.shared.setLamp(
                cubeID: cube?.id,
                red: red,
                green: green,
                blue: blue,
                durationMs: durationMilliseconds
            )
            return .result(dialog: "Set toio Lamp.")
        } catch {
            AppLogger.intents.error("SetLampIntent failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
}
