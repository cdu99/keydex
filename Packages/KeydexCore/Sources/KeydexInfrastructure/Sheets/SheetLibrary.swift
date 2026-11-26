import AppKit
import KeydexDomain
import Observation

/// The sheets of Keydex: bundled ones, then the user's (created if missing), reloaded as soon
/// as a file in the user's folder changes.
@MainActor
@Observable
public final class SheetLibrary: SheetLibraryProviding {
    /// Gives the sheets to the catalog.
    public let provider: DirectorySheetProvider
    public let userFolder: URL
    public private(set) var summaries: [SheetSummary] = []

    /// Called after the sheets were reloaded.
    @ObservationIgnored public var onChange: (() -> Void)?
    @ObservationIgnored private var watcher: DirectoryWatcher?
    @ObservationIgnored private let bundledFolder: URL

    public init(bundledFolder: URL, userFolder: URL) {
        self.bundledFolder = bundledFolder
        self.userFolder = userFolder
        try? FileManager.default.createDirectory(at: userFolder, withIntermediateDirectories: true)
        provider = DirectorySheetProvider(directories: [bundledFolder, userFolder])
        summaries = makeSummaries()
        watcher = DirectoryWatcher(directory: userFolder) { [weak self] in self?.reload() }
    }

    public func reload() {
        provider.reload()
        summaries = makeSummaries()
        onChange?()
    }

    public func openUserFolder() {
        NSWorkspace.shared.open(userFolder)
    }

    private func makeSummaries() -> [SheetSummary] {
        let bundledPath = bundledFolder.standardizedFileURL.path
        return provider.files.map { file in
            SheetSummary(
                id: file.url.lastPathComponent,
                title: file.sheet.title,
                apps: file.sheet.apps,
                command: file.sheet.command,
                shortcutCount: file.sheet.sections.reduce(0) { $0 + $1.entries.count },
                issueCount: file.issues.count,
                isBundled: file.url.deletingLastPathComponent().standardizedFileURL.path == bundledPath
            )
        }
    }
}
