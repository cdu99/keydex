/// Words and symbols a user may type to designate a key or a modifier, in English
/// and French, including Windows/Linux habits ("ctrl", "alt", "suppr", "échap").
enum KeySearchNames {
    static let modifiersByToken: [String: ModifierSet] = {
        let names: [(ModifierSet, [String])] = [
            (.command, ["⌘", "cmd", "command", "commande"]),
            (.shift, ["⇧", "shift", "maj"]),
            (.option, ["⌥", "opt", "option", "alt"]),
            (.control, ["⌃", "^", "ctrl", "control", "ctl"]),
            (.function, ["fn", "🌐", "globe"]),
        ]
        return Dictionary(uniqueKeysWithValues: names.flatMap { modifier, tokens in
            tokens.map { (SearchText.normalize($0), modifier) }
        })
    }()

    /// Symbols that may be glued to other characters in a query ("⌘⇧F").
    static let glueableSymbols: Set<Character> = ["⌘", "⇧", "⌥", "⌃", "+", "←", "→", "↑", "↓", "↩", "⎋", "⌫", "⌦", "⇥"]

    /// Names (normalized) by which `key` can be searched.
    static func names(of key: Key) -> Set<String> {
        let raw: [String] = switch key {
        case let .character(character): [character]
        case let .special(special): names(of: special)
        }
        return Set(raw.map(SearchText.normalize))
    }

    private static func names(of key: SpecialKey) -> [String] {
        switch key {
        case .returnKey: ["↩", "return", "enter", "entree"]
        case .enter: ["⌤", "enter", "entree"]
        case .tab: ["⇥", "tab"]
        case .backTab: ["⇤", "tab"]
        case .space: ["space", "espace", "spc"]
        case .delete: ["⌫", "delete", "backspace", "effacer"]
        case .forwardDelete: ["⌦", "suppr", "del", "forwarddelete"]
        case .escape: ["⎋", "esc", "escape", "echap"]
        case .clear: ["⌧", "clear"]
        case .leftArrow: ["←", "left", "gauche"]
        case .rightArrow: ["→", "right", "droite"]
        case .upArrow: ["↑", "up", "haut"]
        case .downArrow: ["↓", "down", "bas"]
        case .home: ["↖", "home", "debut"]
        case .end: ["↘", "end", "fin"]
        case .pageUp: ["⇞", "pageup", "pgup"]
        case .pageDown: ["⇟", "pagedown", "pgdn"]
        case .help: ["help", "aide"]
        case .capsLock: ["⇪", "capslock", "verrmaj"]
        case .eject: ["⏏", "eject"]
        case let .function(number): ["f\(number)"]
        }
    }
}
