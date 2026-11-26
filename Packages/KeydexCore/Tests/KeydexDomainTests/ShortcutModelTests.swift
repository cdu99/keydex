import KeydexDomain
import Testing

@Suite("Shortcut model")
struct ShortcutModelTests {
    private let path = MenuPath([
        .init(index: 5, title: "Fenêtre"),
        .init(index: 3, title: "Déplacer et redimensionner"),
        .init(index: 0, title: "Gauche"),
    ])

    @Test("Submenu titles exclude the top-level menu and the item itself")
    func submenuTitles() {
        #expect(path.submenuTitles == ["Déplacer et redimensionner"])
        #expect(MenuPath([.init(index: 1, title: "Fichier"), .init(index: 0, title: "Ouvrir")]).submenuTitles.isEmpty)
    }

    @Test("Appending builds the path of a child item")
    func appending() {
        let parent = MenuPath([.init(index: 1, title: "Fichier")])
        #expect(parent.appending(index: 2, title: "Ouvrir").components.map(\.title) == ["Fichier", "Ouvrir"])
    }

    @Test("A catalog counts shortcuts across groups")
    func catalogCount() {
        let shortcut = Shortcut(
            title: "Gauche",
            keyCombo: KeyCombo(modifiers: [.function, .control], key: .special(.leftArrow)),
            isEnabled: true,
            menuPath: path
        )
        let app = AppInfo(processID: 1, bundleIdentifier: "com.example", name: "Example")
        let catalog = ShortcutCatalog(app: app, groups: [
            ShortcutGroup(title: "Fenêtre", menuIndex: 5, shortcuts: [shortcut, shortcut]),
            ShortcutGroup(title: "Aide", menuIndex: 6, shortcuts: [shortcut]),
        ])
        #expect(catalog.shortcutCount == 3)
        #expect(!catalog.isEmpty)
        #expect(ShortcutCatalog(app: app, groups: []).isEmpty)
    }

    @Test("Menu shortcuts can be run and show their submenus; documented ones cannot be run")
    func origins() {
        let menuShortcut = Shortcut(
            title: "Gauche",
            keyCombo: KeyCombo(modifiers: [.function, .control], key: .special(.leftArrow)),
            isEnabled: true,
            menuPath: path
        )
        #expect(menuShortcut.isPerformable)
        #expect(menuShortcut.context == ["Déplacer et redimensionner"])

        let documented = Shortcut(id: "zsh/mots/1", title: "Effacer le mot précédent",
                                  keyCombo: KeyCombo(modifiers: .control, key: .character("W")), context: ["Mots"])
        #expect(!documented.isPerformable)
        #expect(documented.isEnabled)
        #expect(documented.id != menuShortcut.id)
    }
}
