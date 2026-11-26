import KeydexDomain
import Testing

private struct MenuStub: ShortcutSource {
    let result: Result<[ShortcutGroup], ShortcutSourceError>
    func catalog(for app: AppInfo) throws(ShortcutSourceError) -> ShortcutCatalog {
        try ShortcutCatalog(app: app, groups: result.get())
    }
}

private struct SheetsStub: ShortcutSheetProviding {
    let markdown: [String]
    func sheets() -> [ShortcutSheet] {
        markdown.enumerated().map { ShortcutSheetParser.parse($1, id: "sheet\($0)").sheet }
    }
}

@Suite("Menus completed by sheets")
struct SheetAugmentedShortcutSourceTests {
    private let ghostty = AppInfo(processID: 1, bundleIdentifier: "com.mitchellh.ghostty", name: "Ghostty")
    private let menuGroup = ShortcutGroup(title: "File", menuIndex: 1, shortcuts: [
        Shortcut(title: "New Tab", keyCombo: KeyComboParser.parse("⌘T")!, isEnabled: true,
                 menuPath: MenuPath([.init(index: 1, title: "File"), .init(index: 0, title: "New Tab")])),
    ])
    private let zsh = "# zsh\napps: Ghostty\n## Mots\n- `⌃W` Effacer le mot précédent\n- `⌘T` Doublon du menu"
    private let safariOnly = "# Safari\napps: Safari\n- `⌘L` Barre d'adresse"
    private let system = "# macOS\n## Bureaux\n- `⌃←` Bureau précédent"

    private func catalog(menus: Result<[ShortcutGroup], ShortcutSourceError>, sheets: [String]) throws -> ShortcutCatalog {
        try SheetAugmentedShortcutSource(menus: MenuStub(result: menus), sheetProviders: [SheetsStub(markdown: sheets)])
            .catalog(for: ghostty)
    }

    @Test("Menus come first, then the sheets that apply to the app")
    func order() throws {
        let groups = try catalog(menus: .success([menuGroup]), sheets: [system, zsh, safariOnly]).groups
        #expect(groups.map(\.title) == ["File", "zsh · Mots", "macOS · Bureaux"])
        #expect(groups.map(\.kind) == [.menu, .sheet, .sheet])
    }

    @Test("A sheet entry already provided by a menu is dropped")
    func dedup() throws {
        let groups = try catalog(menus: .success([menuGroup]), sheets: [zsh]).groups
        #expect(groups[1].shortcuts.map(\.title) == ["Effacer le mot précédent"])
    }

    @Test("A sheet for this app wins over a sheet for every app on the same keys")
    func appSpecificWins() throws {
        let systemText = "# macOS\n## Texte\n- `⌃W` Fermer la fenêtre\n- `⌃E` Fin de paragraphe"
        let groups = try catalog(menus: .success([]), sheets: [systemText, zsh]).groups
        #expect(groups.map(\.title) == ["zsh · Mots", "macOS · Texte"])
        #expect(groups[1].shortcuts.map(\.title) == ["Fin de paragraphe"])
    }

    @Test("Without a menu bar, the sheets are still shown")
    func noMenuBar() throws {
        let groups = try catalog(menus: .failure(.noMenuBar), sheets: [zsh]).groups
        #expect(groups.map(\.title) == ["zsh · Mots"])
    }

    @Test("Other errors are not hidden by sheets")
    func otherErrors() {
        #expect(throws: ShortcutSourceError.accessibilityNotGranted) {
            try catalog(menus: .failure(.accessibilityNotGranted), sheets: [zsh])
        }
    }
}
