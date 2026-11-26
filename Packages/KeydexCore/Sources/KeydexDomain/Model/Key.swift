/// The non-modifier key of a keyboard shortcut.
public enum Key: Hashable, Sendable {
    /// A key that produces a character, stored as displayed on the keycap (e.g. "C", "/", "1").
    case character(String)
    /// A key without a printable character (arrows, return, F-keys…).
    case special(SpecialKey)

    /// How the key is shown on a Mac keyboard and in macOS menus.
    public var symbol: String {
        switch self {
        case let .character(character): character
        case let .special(special): special.symbol
        }
    }
}

/// Keys that have no printable character.
public enum SpecialKey: Hashable, Sendable {
    case returnKey, enter, tab, backTab, space
    case delete, forwardDelete, escape, clear
    case leftArrow, rightArrow, upArrow, downArrow
    case home, end, pageUp, pageDown
    case help, capsLock, eject
    case function(Int)

    /// Symbol used by macOS for this key.
    public var symbol: String {
        switch self {
        case .returnKey: "↩"
        case .enter: "⌤"
        case .tab: "⇥"
        case .backTab: "⇤"
        case .space: "Espace"
        case .delete: "⌫"
        case .forwardDelete: "⌦"
        case .escape: "⎋"
        case .clear: "⌧"
        case .leftArrow: "←"
        case .rightArrow: "→"
        case .upArrow: "↑"
        case .downArrow: "↓"
        case .home: "↖"
        case .end: "↘"
        case .pageUp: "⇞"
        case .pageDown: "⇟"
        case .help: "?⃝"
        case .capsLock: "⇪"
        case .eject: "⏏"
        case let .function(number): "F\(number)"
        }
    }
}
