/// A keyboard shortcut and the action it triggers.
///
/// Most shortcuts are read from an app's menus and can be run by pressing their menu item.
/// Others are only documented (in sheets): they can be shown and searched, not run.
public struct Shortcut: Hashable, Sendable, Identifiable {
    public let id: String
    /// Name of the action.
    public let title: String
    public let keyCombo: KeyCombo
    /// Whether the action can be performed right now (unavailable items are greyed out).
    public let isEnabled: Bool
    /// Where the action sits within its group (e.g. its submenus), shown before its title.
    public let context: [String]
    /// The menu item that runs the action, or `nil` if the shortcut is only documented.
    public let menuPath: MenuPath?

    /// A shortcut read from an app's menu.
    public init(title: String, keyCombo: KeyCombo, isEnabled: Bool, menuPath: MenuPath) {
        id = "menu:" + menuPath.components.map { "\($0.index):\($0.title)" }.joined(separator: "/")
        self.title = title
        self.keyCombo = keyCombo
        self.isEnabled = isEnabled
        context = menuPath.submenuTitles
        self.menuPath = menuPath
    }

    /// A shortcut documented outside the app's menus (e.g. in a sheet).
    public init(id: String, title: String, keyCombo: KeyCombo, context: [String] = []) {
        self.id = id
        self.title = title
        self.keyCombo = keyCombo
        isEnabled = true
        self.context = context
        menuPath = nil
    }

    /// Whether Keydex can run the action itself (only menu items can be pressed).
    public var isPerformable: Bool {
        menuPath != nil
    }
}
