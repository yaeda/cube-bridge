import AppIntents
import Foundation

struct MoveCubeIntent: AppIntent {
    static var title: LocalizedStringResource = "Move toio Cube"
    static var description = IntentDescription("Move a connected toio Core Cube with left and right motor speeds.")
    static var openAppWhenRun = true
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0, *)
    static var supportedModes: IntentModes { .foreground(.dynamic) }

    @Parameter(title: "Cube")
    var cube: CubeEntity?

    @Parameter(title: "Left Motor Speed", default: 50)
    var leftMotorSpeed: Int

    @Parameter(title: "Right Motor Speed", default: 50)
    var rightMotorSpeed: Int

    @Parameter(title: "Duration milliseconds", default: 500)
    var durationMilliseconds: Int

    @MainActor
    func perform() async throws -> some IntentResult {
        do {
            try await CubeManager.shared.move(
                cubeID: cube?.id,
                left: leftMotorSpeed,
                right: rightMotorSpeed,
                durationMs: durationMilliseconds
            )
            return .result(dialog: "Moved toio Cube.")
        } catch {
            AppLogger.intents.error("MoveCubeIntent failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
}
