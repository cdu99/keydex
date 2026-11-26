/// Provides shortcut sheets (user files, bundled sheets, sheets generated from an app's
/// own configuration…).
public protocol ShortcutSheetProviding: Sendable {
    /// The sheets that apply to `app`. Called on every catalog read, off the main thread:
    /// keep it cheap, or cache.
    func sheets(for app: AppInfo) -> [ShortcutSheet]
}
