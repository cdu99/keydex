import Foundation

/// The shortcut sheets Keydex knows, for the user to see what is loaded and what runs.
@MainActor
public protocol SheetLibraryProviding: AnyObject {
    var summaries: [SheetSummary] { get }
    /// Where the user writes their own sheets.
    var userFolder: URL { get }
    func openUserFolder()
}

/// What a loaded sheet file contains, for display.
public struct SheetSummary: Equatable, Sendable, Identifiable {
    /// The file name, unique among loaded sheets.
    public let id: String
    public let title: String
    /// Apps it applies to; empty means every app.
    public let apps: [String]
    /// The command generating part of it, if any (it runs on the user's Mac).
    public let command: String?
    public let shortcutCount: Int
    /// Lines that could not be read.
    public let issueCount: Int
    /// Shipped with Keydex, or written by the user.
    public let isBundled: Bool

    public init(id: String, title: String, apps: [String], command: String?, shortcutCount: Int, issueCount: Int, isBundled: Bool) {
        self.id = id
        self.title = title
        self.apps = apps
        self.command = command
        self.shortcutCount = shortcutCount
        self.issueCount = issueCount
        self.isBundled = isBundled
    }
}
