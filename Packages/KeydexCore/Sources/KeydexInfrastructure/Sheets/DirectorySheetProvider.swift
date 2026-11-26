import Foundation
import KeydexDomain
import Synchronization

/// Sheets read from Markdown files (`*.md`) in a list of folders.
///
/// Folders are read in order and a later file replaces an earlier one with the same name, so
/// a user can override a bundled sheet by saving their own version under the same name.
/// Files are parsed on `reload()` only; `sheets()` returns the cached result.
public final class DirectorySheetProvider: ShortcutSheetProviding {
    public struct LoadedFile: Equatable, Sendable {
        public let url: URL
        public let sheet: ShortcutSheet
        public let issues: [ShortcutSheetParser.Issue]
    }

    private let directories: [URL]
    private let loaded = Mutex<[LoadedFile]>([])

    public init(directories: [URL]) {
        self.directories = directories
        reload()
    }

    public func sheets(for app: AppInfo) -> [ShortcutSheet] {
        sheets.filter { $0.applies(to: app) }
    }

    /// Every loaded sheet, whatever its apps.
    public var sheets: [ShortcutSheet] {
        loaded.withLock { $0.map(\.sheet) }
    }

    /// Every loaded file with its parsing issues, for diagnostics.
    public var files: [LoadedFile] {
        loaded.withLock { $0 }
    }

    public func reload() {
        var byName: [String: URL] = [:]
        var order: [String] = []
        for directory in directories {
            for url in Self.markdownFiles(in: directory) {
                let name = url.lastPathComponent.lowercased()
                if byName[name] == nil { order.append(name) }
                byName[name] = url
            }
        }
        let files = order.compactMap { byName[$0] }.compactMap(Self.load)
        loaded.withLock { $0 = files }
    }

    private static func markdownFiles(in directory: URL) -> [URL] {
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
        )) ?? []
        return contents
            .filter { $0.pathExtension.lowercased() == "md" }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    private static func load(_ url: URL) -> LoadedFile? {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let id = url.deletingPathExtension().lastPathComponent
        let result = ShortcutSheetParser.parse(text, id: id)
        return LoadedFile(url: url, sheet: result.sheet, issues: result.issues)
    }
}
