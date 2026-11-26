@testable import KeydexInfrastructure
import KeydexDomain
import Testing

@Suite("Mapping a menu bar reading to shortcut groups")
struct MenuShortcutMapperTests {
    private let menuBar: [MenuItemSnapshot] = [
        MenuItemSnapshot(title: "Apple", children: [
            MenuItemSnapshot(title: "Forcer à quitter…", commandCharacter: "\u{1B}", commandModifiers: 2),
        ]),
        MenuItemSnapshot(title: "Fichier", children: [
            MenuItemSnapshot(title: "Nouveau", commandCharacter: "n", commandModifiers: 0),
            MenuItemSnapshot(title: ""), // separator
            MenuItemSnapshot(title: "Imprimer…", commandCharacter: "p", commandModifiers: 0, isEnabled: false),
            MenuItemSnapshot(title: "Partager"), // no shortcut, no submenu
        ]),
        MenuItemSnapshot(title: "Aide", children: [
            MenuItemSnapshot(title: "Rechercher"), // no shortcut at all: group dropped
        ]),
        MenuItemSnapshot(title: "Fenêtre", children: [
            MenuItemSnapshot(title: "Placer", children: [
                MenuItemSnapshot(title: "Gauche", commandGlyph: 0x64, commandModifiers: 8 | 4),
                MenuItemSnapshot(title: "Gauche", commandGlyph: 0x64, commandModifiers: 8 | 4), // duplicate
            ]),
            MenuItemSnapshot(title: "Réduire", commandCharacter: "m", commandModifiers: 0),
        ]),
    ]

    private var groups: [ShortcutGroup] { MenuShortcutMapper.groups(fromMenuBar: menuBar) }

    @Test("Groups follow menu bar order and keep their menu index; empty menus are dropped")
    func groupOrder() {
        #expect(groups.map(\.title) == ["Apple", "Fichier", "Fenêtre"])
        #expect(groups.map(\.id) == ["menu:0", "menu:1", "menu:3"])
    }

    @Test("Separators and items without shortcut are skipped; disabled items are kept, greyed")
    func itemsOfAMenu() {
        let file = groups[1].shortcuts
        #expect(file.map(\.title) == ["Nouveau", "Imprimer…"])
        #expect(file.map(\.isEnabled) == [true, false])
        #expect(file[1].keyCombo.displayString == "⌘P")
    }

    @Test("Submenus are flattened depth-first and remember their path")
    func submenus() {
        let window = groups[2].shortcuts
        #expect(window.map(\.title) == ["Gauche", "Réduire"])
        #expect(window[0].context == ["Placer"])
        #expect(window[0].menuPath?.components.map(\.index) == [3, 0, 0])
        #expect(window[0].keyCombo.displayString == "⌃←")
    }
}
