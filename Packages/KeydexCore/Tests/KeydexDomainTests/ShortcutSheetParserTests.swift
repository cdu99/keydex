import KeydexDomain
import Testing

@Suite("Reading shortcut sheets")
struct ShortcutSheetParserTests {
    private let zsh = """
    # zsh
    apps: Ghostty, Terminal, com.googlecode.iterm2

    Line editing shortcuts of zsh (emacs mode).

    ## Mots
    - `⌃W` Effacer le mot précédent
    - `⌥D` — Effacer le mot suivant
    - ⌥B  Mot précédent

    ## Ligne
    | Touches | Action |
    |---|---|
    | `⌃A` | Début de ligne |
    | ctrl+e | Fin de ligne |
    """

    @Test("Title, apps, sections and entries in every supported form")
    func fullSheet() {
        let result = ShortcutSheetParser.parse(zsh, id: "zsh")
        #expect(result.issues.isEmpty)
        let sheet = result.sheet
        #expect(sheet.title == "zsh")
        #expect(sheet.apps == ["Ghostty", "Terminal", "com.googlecode.iterm2"])
        #expect(sheet.sections.map(\.title) == ["Mots", "Ligne"])
        #expect(sheet.sections[0].entries.map(\.title) == ["Effacer le mot précédent", "Effacer le mot suivant", "Mot précédent"])
        #expect(sheet.sections[0].entries.map(\.keyCombo.displayString) == ["⌃W", "⌥D", "⌥B"])
        #expect(sheet.sections[1].entries.map(\.keyCombo.displayString) == ["⌃A", "⌃E"])
    }

    @Test("Unreadable entries are reported with their line, the rest is kept")
    func issues() {
        let result = ShortcutSheetParser.parse("# Test\n- `⌘?!` Bad keys\n- `⌘K` Good\n- no separator here", id: "test")
        #expect(result.sheet.sections.first?.entries.map(\.title) == ["Good"])
        #expect(result.issues.map(\.line) == [2, 4])
    }

    @Test("Without a title, the id is used; entries before any section form an untitled one")
    func defaults() {
        let sheet = ShortcutSheetParser.parse("- `⌘K` Clear", id: "my-app").sheet
        #expect(sheet.title == "my-app")
        #expect(sheet.sections.count == 1)
        #expect(sheet.sections[0].title == nil)
        #expect(sheet.groups.map(\.title) == ["my-app"])
    }

    @Test("A sheet applies to its apps by name or bundle id, ignoring case; without apps, to every app")
    func applies() {
        let sheet = ShortcutSheetParser.parse(zsh, id: "zsh").sheet
        let ghostty = AppInfo(processID: 1, bundleIdentifier: "com.mitchellh.ghostty", name: "Ghostty")
        let iterm = AppInfo(processID: 2, bundleIdentifier: "com.googlecode.iterm2", name: "iTerm")
        let safari = AppInfo(processID: 3, bundleIdentifier: "com.apple.Safari", name: "Safari")
        #expect(sheet.applies(to: ghostty))
        #expect(sheet.applies(to: iterm))
        #expect(!sheet.applies(to: safari))
        #expect(ShortcutSheetParser.parse("# macOS", id: "macos").sheet.applies(to: safari))
    }

    @Test("Sections become sheet groups of documented (not performable) shortcuts")
    func groups() {
        let groups = ShortcutSheetParser.parse(zsh, id: "zsh").sheet.groups
        #expect(groups.map(\.title) == ["zsh · Mots", "zsh · Ligne"])
        #expect(groups.allSatisfy { $0.kind == .sheet })
        #expect(groups.flatMap(\.shortcuts).allSatisfy { !$0.isPerformable })
        #expect(Set(groups.flatMap(\.shortcuts).map(\.id)).count == 5, "Unique ids")
    }
}
