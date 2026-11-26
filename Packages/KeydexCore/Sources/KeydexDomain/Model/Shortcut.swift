/// A keyboard shortcut and the action it triggers in an app.
public struct Shortcut: Hashable, Sendable, Identifiable {
    /// Name of the action, as shown in the app's menu.
    public let title: String
    public let keyCombo: KeyCombo
    /// Whether the action can be performed right now (unavailable items are greyed out).
    public let isEnabled: Bool
    public let menuPath: MenuPath

    public var id: MenuPath { menuPath }

    public init(title: String, keyCombo: KeyCombo, isEnabled: Bool, menuPath: MenuPath) {
        self.title = title
        self.keyCombo = keyCombo
        self.isEnabled = isEnabled
        self.menuPath = menuPath
    }
}
