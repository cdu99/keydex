/// Provides shortcut sheets (user files, bundled sheets, sheets generated from an app's
/// own configuration…).
public protocol ShortcutSheetProviding: Sendable {
    /// The current sheets. Called on every catalog read: keep it cheap, or cache.
    func sheets() -> [ShortcutSheet]
}
