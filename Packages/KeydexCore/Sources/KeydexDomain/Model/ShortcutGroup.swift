/// Shortcuts shown together: a top-level menu (File, Edit…) or a section of a sheet.
public struct ShortcutGroup: Hashable, Sendable, Identifiable {
    public enum Kind: Hashable, Sendable {
        /// Read from the app's menu bar.
        case menu
        /// Documented in a sheet (shortcuts that are in no menu).
        case sheet
    }

    public let id: String
    public let title: String
    public let kind: Kind
    public let shortcuts: [Shortcut]

    public init(id: String, title: String, kind: Kind, shortcuts: [Shortcut]) {
        self.id = id
        self.title = title
        self.kind = kind
        self.shortcuts = shortcuts
    }

    /// A top-level menu, identified by its position in the menu bar.
    public init(title: String, menuIndex: Int, shortcuts: [Shortcut]) {
        self.init(id: "menu:\(menuIndex)", title: title, kind: .menu, shortcuts: shortcuts)
    }

    public func replacingShortcuts(with shortcuts: [Shortcut]) -> ShortcutGroup {
        ShortcutGroup(id: id, title: title, kind: kind, shortcuts: shortcuts)
    }
}
