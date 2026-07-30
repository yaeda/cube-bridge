import Combine
import Foundation
import Sparkle

@MainActor
final class SparkleUpdater: NSObject, ObservableObject {
    let canCheckForUpdates: Bool

    private var updaterController: SPUStandardUpdaterController?

    override init() {
        guard Self.hasPublicEdKey else {
            canCheckForUpdates = false
            updaterController = nil
            super.init()
            return
        }

        canCheckForUpdates = true
        updaterController = nil
        super.init()
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }

    func checkForUpdates() {
        updaterController?.checkForUpdates(nil)
    }

    private static var hasPublicEdKey: Bool {
        guard let publicKey = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String else {
            return false
        }

        let trimmedKey = publicKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedKey.isEmpty && !trimmedKey.contains("$(")
    }
}
