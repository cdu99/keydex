/// Triggers the action of a shortcut in its app, as if the user chose it in the menu.
public protocol ShortcutActionPerforming: Sendable {
    /// May block: call it off the main thread.
    func perform(_ shortcut: Shortcut, in app: AppInfo) throws(ShortcutActionError)
}

public enum ShortcutActionError: Error, Equatable, Sendable {
    case accessibilityNotGranted
    /// The shortcut is only documented: it is not a menu item Keydex can press.
    case notPerformable
    /// The menu item is gone (menus changed since they were read).
    case itemNotFound
    /// The app refused or did not answer.
    case actionFailed
}
