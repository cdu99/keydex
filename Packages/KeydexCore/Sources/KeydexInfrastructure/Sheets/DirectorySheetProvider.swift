import Foundation
import KeydexDomain
import Synchronization

/// Sheets read from Markdown files (`*.md`) in a list of folders.
///
/// Folders are read in order and a later file replaces an earlier one with the same name, so
/// a user can override a bundled sheet by saving their own version under the same name.
/// Files are parsed on `reload()` only.
///
/// A sheet that declares a `command` is completed, for the app it applies to, with the sheet
/// the command prints (see `SheetCommandRunner`). Only the folders given here (the bundled
/// sheets and the user's own) can declare commands. The output is kept for
/// `commandCacheDuration`, so the prefetch and the glance do not both run it.
public final class DirectorySheetProvider: ShortcutSheetProviding {
    public struct LoadedFile: Equatable, Sendable {
        public let url: URL
        public let sheet: ShortcutSheet
        public let issues: [ShortcutSheetParser.Issue]
    }

    private let directories: [URL]
    private let loaded = Mutex<[LoadedFile]>([])
    private let runner: SheetCommandRunner
    private let commandCacheDuration: TimeInterval
    private let generated = Mutex<[String: (date: Date, sections: [ShortcutSheet.Section])]>([:])

    public init(directories: [URL], commandTimeout: TimeInterval = 2, commandCacheDuration: TimeInterval = 2) {
        self.directories = directories
        runner = SheetCommandRunner(timeout: commandTimeout)
        self.commandCacheDuration = commandCacheDuration
        reload()
    }

    public func sheets(for app: AppInfo) -> [ShortcutSheet] {
        files.filter { $0.sheet.applies(to: app) }.map { file in
            guard let command = file.sheet.command else { return file.sheet }
            return file.sheet.appending(generatedSections(of: file, command: command, for: app))
        }
    }

    /// Sections printed by the sheet's command for `app`; none if the command fails.
    private func generatedSections(of file: LoadedFile, command: String, for app: AppInfo) -> [ShortcutSheet.Section] {
        let key = "\(file.url.path)#\(app.processID)"
        if let cached = generated.withLock({ $0[key] }), Date().timeIntervalSince(cached.date) < commandCacheDuration {
            return cached.sections
        }
        let output = runner.run(command, in: file.url.deletingLastPathComponent(), for: app)
        let sections = output.map { ShortcutSheetParser.parse($0, id: file.sheet.id).sheet.sections } ?? []
        generated.withLock { $0[key] = (Date(), sections) }
        return sections
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
        generated.withLock { $0.removeAll() }
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
