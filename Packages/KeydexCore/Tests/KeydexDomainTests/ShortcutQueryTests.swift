import KeydexDomain
import Testing

@Suite("Searching shortcuts")
struct ShortcutQueryTests {
    private static func shortcut(_ title: String, _ modifiers: ModifierSet, _ key: Key, submenu: String? = nil) -> Shortcut {
        var components: [MenuPath.Component] = [.init(index: 0, title: "Menu")]
        if let submenu { components.append(.init(index: 0, title: submenu)) }
        components.append(.init(index: 0, title: title))
        return Shortcut(title: title, keyCombo: KeyCombo(modifiers: modifiers, key: key), isEnabled: true, menuPath: MenuPath(components))
    }

    private let find = shortcut("Find", .command, .character("F"))
    private let findInFiles = shortcut("Find in Files…", [.shift, .command], .character("F"))
    private let copy = shortcut("Copier", .command, .character("C"))
    private let left = shortcut("Left", [.function, .control], .special(.leftArrow), submenu: "Move & Resize")
    private let escape = shortcut("Fermer", .option, .special(.escape))
    private let reload = shortcut("Reload", .command, .special(.function(5)))

    private func results(_ query: String) -> [String] {
        let all = [find, findInFiles, copy, left, escape, reload]
        return all.filter { ShortcutQuery(query).matches($0, inMenu: "Menu") }.map(\.title)
    }

    @Test("An empty query matches everything")
    func emptyQuery() {
        #expect(ShortcutQuery("  ").isEmpty)
        #expect(results("").count == 6)
    }

    @Test("Names match regardless of case and accents")
    func byName() {
        #expect(results("find") == ["Find", "Find in Files…"])
        #expect(results("COPIER") == ["Copier"])
        #expect(results("fermér") == ["Fermer"])
    }

    @Test("Every term must match")
    func allTerms() {
        #expect(results("find files") == ["Find in Files…"])
    }

    @Test("Submenu titles are searchable")
    func bySubmenu() {
        #expect(results("resize") == ["Left"])
    }

    @Test("Modifier symbols glued to a key search by keys", arguments: ["⌘⇧F", "⇧⌘F", "cmd shift f", "Cmd+Shift+F", "maj cmd f"])
    func byKeys(query: String) {
        #expect(results(query) == ["Find in Files…"])
    }

    @Test("With modifiers, a single letter designates the key, not a word")
    func letterWithModifiersIsKey() {
        #expect(results("⌘F") == ["Find", "Find in Files…"])
        #expect(results("cmd c") == ["Copier"])
    }

    @Test("Without modifiers, a single letter matches the start of words")
    func singleLetterMatchesWordStart() {
        #expect(results("f") == ["Find", "Find in Files…", "Fermer"])
    }

    @Test("Windows and Linux words for modifiers work", arguments: [("alt esc", "Fermer"), ("ctrl fn left", "Left")])
    func windowsWords(query: String, expected: String) {
        #expect(results(query) == [expected])
    }

    @Test("Key names and symbols match special keys", arguments: [
        ("echap", "Fermer"), ("⎋", "Fermer"), ("f5", "Reload"), ("gauche", "Left"), ("←", "Left"),
    ])
    func specialKeys(query: String, expected: String) {
        #expect(results(query) == [expected])
    }

    @Test("Modifiers alone list the shortcuts using them")
    func modifiersOnly() {
        #expect(results("⌃") == ["Left"])
        #expect(results("opt") == ["Fermer"])
    }

    @Test("Filtering keeps menu order and drops empty menus")
    func filterGroups() {
        let groups = [
            ShortcutGroup(title: "Fichier", menuIndex: 1, shortcuts: [copy]),
            ShortcutGroup(title: "Édition", menuIndex: 2, shortcuts: [find, escape, findInFiles]),
        ]
        let filtered = ShortcutQuery("find").filter(groups)
        #expect(filtered.map(\.title) == ["Édition"])
        #expect(filtered[0].shortcuts.map(\.title) == ["Find", "Find in Files…"])
    }

    @Test("The menu title is searchable too")
    func byMenuTitle() {
        let groups = [ShortcutGroup(title: "Fenêtre", menuIndex: 5, shortcuts: [left])]
        #expect(ShortcutQuery("fenetre").filter(groups).count == 1)
    }
}
