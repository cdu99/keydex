/// A keyboard shortcut: modifiers plus one key (e.g. ⌥⌘F).
public struct KeyCombo: Hashable, Sendable {
    public let modifiers: ModifierSet
    public let key: Key

    public init(modifiers: ModifierSet, key: Key) {
        self.modifiers = modifiers
        self.key = key
    }

    /// One symbol per keycap, in macOS order: modifiers first (fn ⌃ ⌥ ⇧ ⌘), then the key.
    public var keycaps: [String] {
        modifiers.symbols + [key.symbol]
    }

    /// The combo as macOS writes it in menus, e.g. "⌥⌘F".
    public var displayString: String {
        keycaps.joined()
    }
}
