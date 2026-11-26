/// Reads a key combination written by a person, as in sheets: "⌃W", "ctrl+w",
/// "cmd shift f", "⌥⌘←", "fn ctrl left", "⌘+", "f5".
public enum KeyComboParser {
    /// The combination, or `nil` if the text does not name exactly one key.
    public static func parse(_ text: String) -> KeyCombo? {
        var modifiers: ModifierSet = []
        var keys: [Key] = []
        for token in KeyTokenizer.tokens(of: text) {
            if let modifier = KeySearchNames.modifiersByToken[token] {
                modifiers.insert(modifier)
            } else if let key = key(named: token) {
                keys.append(key)
            } else {
                return nil
            }
        }
        // "+" separates keys, so a trailing one is the "+" key itself ("⌘+", "cmd++").
        if keys.isEmpty, text.trimmingCharacters(in: .whitespaces).hasSuffix("+") {
            keys.append(.character("+"))
        }
        guard keys.count == 1, let key = keys.first else { return nil }
        return KeyCombo(modifiers: modifiers, key: key)
    }

    private static func key(named token: String) -> Key? {
        if let special = KeySearchNames.specialKeysByName[token] {
            return .special(special)
        }
        guard token.count == 1 else { return nil }
        return .character(token.uppercased())
    }
}
