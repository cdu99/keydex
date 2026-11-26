/// What the user typed in the search field, interpreted.
///
/// Modifier words and symbols ("cmd", "⇧", "alt", "ctrl"…) require those modifiers.
/// Every other term must match the action's name (its menu, submenu or title) or its key:
/// - "copy", "copier"          → actions whose name contains the term;
/// - "⌘⇧F", "cmd shift f"      → with modifiers, a single character only designates the key;
/// - "f5", "esc", "gauche"     → key names also match.
public struct ShortcutQuery: Equatable, Sendable {
    public let requiredModifiers: ModifierSet
    /// Normalized terms other than modifiers.
    public let terms: [String]

    public init(_ text: String) {
        var modifiers: ModifierSet = []
        var terms: [String] = []
        for token in Self.tokens(of: text) {
            if let modifier = KeySearchNames.modifiersByToken[token] {
                modifiers.insert(modifier)
            } else {
                terms.append(token)
            }
        }
        requiredModifiers = modifiers
        self.terms = terms
    }

    public var isEmpty: Bool {
        requiredModifiers.isEmpty && terms.isEmpty
    }

    /// Keeps the matching shortcuts, in their menu order; drops menus left empty.
    public func filter(_ groups: [ShortcutGroup]) -> [ShortcutGroup] {
        guard !isEmpty else { return groups }
        return groups.compactMap { group in
            let shortcuts = group.shortcuts.filter { matches($0, inMenu: group.title) }
            return shortcuts.isEmpty ? nil : ShortcutGroup(title: group.title, menuIndex: group.menuIndex, shortcuts: shortcuts)
        }
    }

    public func matches(_ shortcut: Shortcut, inMenu menuTitle: String) -> Bool {
        guard shortcut.keyCombo.modifiers.isSuperset(of: requiredModifiers) else { return false }
        let keyNames = KeySearchNames.names(of: shortcut.keyCombo.key)
        let name = SearchText.normalize(([menuTitle] + shortcut.menuPath.submenuTitles + [shortcut.title]).joined(separator: " "))
        return terms.allSatisfy { term in
            if keyNames.contains(term) { return true }
            let designatesKeyOnly = !requiredModifiers.isEmpty && term.count == 1
            return !designatesKeyOnly && Self.name(name, contains: term)
        }
    }

    /// A single letter only matches the start of a word ("f" finds "Find", not "Left").
    private static func name(_ name: String, contains term: String) -> Bool {
        guard term.count == 1 else { return name.contains(term) }
        return name.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).contains { $0.hasPrefix(term) }
    }

    private static func tokens(of text: String) -> [String] {
        var spaced = ""
        for character in text {
            if KeySearchNames.glueableSymbols.contains(character) {
                spaced += character == "+" ? " " : " \(character) "
            } else {
                spaced.append(character)
            }
        }
        return spaced.split(whereSeparator: \.isWhitespace).map { SearchText.normalize(String($0)) }
    }
}
