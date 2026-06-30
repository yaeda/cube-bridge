import Combine
import Foundation
import ServiceManagement

@MainActor
final class LoginItemManager: ObservableObject {
    @Published private(set) var isLaunchAtLoginEnabled = false
    @Published private(set) var statusMessage: String?
    @Published private(set) var errorMessage: String?

    init() {
        refresh()
    }

    func refresh() {
        let status = SMAppService.mainApp.status

        isLaunchAtLoginEnabled = status == .enabled || status == .requiresApproval
        statusMessage = message(for: status)
    }

    func setLaunchAtLoginEnabled(_ isEnabled: Bool) {
        errorMessage = nil

        do {
            let service = SMAppService.mainApp
            let status = service.status

            if isEnabled {
                if status == .notRegistered || status == .notFound {
                    try service.register()
                }
            } else if status == .enabled || status == .requiresApproval {
                try service.unregister()
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        refresh()
    }

    private func message(for status: SMAppService.Status) -> String? {
        switch status {
        case .enabled, .notRegistered:
            return nil
        case .requiresApproval:
            return "Approve ToioBridge in System Settings > General > Login Items."
        case .notFound:
            return "Login item status is unavailable for this build."
        @unknown default:
            return "Login item status is unknown."
        }
    }
}
