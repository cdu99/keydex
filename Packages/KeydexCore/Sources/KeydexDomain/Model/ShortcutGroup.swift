/// Shortcuts that belong to the same top-level menu (File, Edit, View…).
public struct ShortcutGroup: Hashable, Sendable, Identifiable {
    public let title: String
    /// Position of the menu in the menu bar, which keeps groups in the app's own order.
    public let menuIndex: Int
    public let shortcuts: [Shortcut]

    public var id: Int { menuIndex }

    public init(title: String, menuIndex: Int, shortcuts: [Shortcut]) {
        self.title = title
        self.menuIndex = menuIndex
        self.shortcuts = shortcuts
    }
}
