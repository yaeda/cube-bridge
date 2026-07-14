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
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: self)
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

extension SparkleUpdater: SPUStandardUserDriverDelegate {
    nonisolated func standardUserDriverWillShowReleaseNotesText(
        _ releaseNotesAttributedString: NSAttributedString,
        forUpdate update: SUAppcastItem,
        withBundleDisplayVersion bundleDisplayVersion: String,
        bundleVersion: String
    ) -> NSAttributedString? {
        Self.releaseNotesNewerThanInstalledVersion(releaseNotesAttributedString, installedVersion: bundleVersion)
    }

    private nonisolated static func releaseNotesNewerThanInstalledVersion(
        _ releaseNotesAttributedString: NSAttributedString,
        installedVersion: String
    ) -> NSAttributedString {
        let fullText = releaseNotesAttributedString.string as NSString
        guard let cutoffLocation = firstInstalledOrOlderSectionLocation(in: fullText as String, installedVersion: installedVersion)
        else {
            return releaseNotesAttributedString
        }

        let visibleRange = NSRange(location: 0, length: cutoffLocation)
        let filteredReleaseNotes = releaseNotesAttributedString.attributedSubstring(from: visibleRange)
        return filteredReleaseNotes.trimmingTrailingWhitespaceAndNewlines()
    }

    private nonisolated static func firstInstalledOrOlderSectionLocation(
        in releaseNotesText: String,
        installedVersion: String
    ) -> Int? {
        let comparator = SUStandardVersionComparator()
        var cutoffLocation: Int?

        releaseNotesText.enumerateSubstrings(in: releaseNotesText.startIndex..., options: .byLines) { line, lineRange, _, stop in
            guard let line, let version = releaseNoteVersion(from: line) else {
                return
            }

            let comparison = comparator.compareVersion(version, toVersion: installedVersion)
            if comparison != .orderedDescending {
                cutoffLocation = NSRange(lineRange, in: releaseNotesText).location
                stop = true
            }
        }

        return cutoffLocation
    }

    private nonisolated static func releaseNoteVersion(from line: String) -> String? {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"^(?:#+\s*)?(?:Version\s+)?v?(\d+(?:\.\d+){1,2}(?:[-+][0-9A-Za-z.-]+)?)\b"#
        guard let match = trimmedLine.range(of: pattern, options: .regularExpression) else {
            return nil
        }

        let matchedText = String(trimmedLine[match])
        let prefixPattern = #"^(?:#+\s*)?(?:Version\s+)?v?"#
        return matchedText.replacingOccurrences(of: prefixPattern, with: "", options: .regularExpression)
    }
}

extension NSAttributedString {
    fileprivate func trimmingTrailingWhitespaceAndNewlines() -> NSAttributedString {
        let trailingWhitespaceRange = (string as NSString).range(of: #"\s+\z"#, options: .regularExpression)
        guard trailingWhitespaceRange.location != NSNotFound else {
            return self
        }

        let trimmedLength = trailingWhitespaceRange.location
        return attributedSubstring(from: NSRange(location: 0, length: trimmedLength))
    }
}
