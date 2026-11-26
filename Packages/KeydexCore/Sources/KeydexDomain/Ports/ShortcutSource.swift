/// Provides the shortcuts of an app (from its menus, from user files…).
public protocol ShortcutSource: Sendable {
    /// Reads the shortcuts of `app`. May block: call it off the main thread.
    func catalog(for app: AppInfo) throws(ShortcutSourceError) -> ShortcutCatalog
}

public enum ShortcutSourceError: Error, Equatable, Sendable {
    /// Keydex has not been granted the Accessibility permission.
    case accessibilityNotGranted
    /// The app did not answer in time (busy, frozen…).
    case appNotResponding
    /// The app exposes no menu bar (background app, some games…).
    case noMenuBar
}
