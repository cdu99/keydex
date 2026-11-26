/// The modifier keys of a keyboard shortcut.
public struct ModifierSet: OptionSet, Hashable, Sendable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let function = ModifierSet(rawValue: 1 << 0)
    public static let control = ModifierSet(rawValue: 1 << 1)
    public static let option = ModifierSet(rawValue: 1 << 2)
    public static let shift = ModifierSet(rawValue: 1 << 3)
    public static let command = ModifierSet(rawValue: 1 << 4)

    /// Modifiers in the order macOS displays them: fn ⌃ ⌥ ⇧ ⌘.
    static let displayOrder: [(modifier: ModifierSet, symbol: String)] = [
        (.function, "fn"),
        (.control, "⌃"),
        (.option, "⌥"),
        (.shift, "⇧"),
        (.command, "⌘"),
    ]

    /// Symbols of the modifiers in this set, in the standard macOS order.
    public var symbols: [String] {
        Self.displayOrder.filter { contains($0.modifier) }.map(\.symbol)
    }
}
