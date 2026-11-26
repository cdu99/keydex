import KeydexDomain

/// Builds shortcut groups from a raw menu bar reading: one group per top-level menu,
/// in menu bar order, with the items in menu order (submenus flattened depth-first).
enum MenuShortcutMapper {
    static func groups(fromMenuBar menuBar: [MenuItemSnapshot]) -> [ShortcutGroup] {
        menuBar.enumerated().compactMap { index, menu in
            guard !menu.title.isEmpty else { return nil }
            let root = MenuPath([.init(index: index, title: menu.title)])
            var seen = Set<DedupKey>()
            let shortcuts = collectShortcuts(in: menu.children, under: root)
                .filter { seen.insert(DedupKey(title: $0.title, keyCombo: $0.keyCombo)).inserted }
            guard !shortcuts.isEmpty else { return nil }
            return ShortcutGroup(title: menu.title, menuIndex: index, shortcuts: shortcuts)
        }
    }

    private static func collectShortcuts(in items: [MenuItemSnapshot], under parent: MenuPath) -> [Shortcut] {
        items.enumerated().flatMap { index, item -> [Shortcut] in
            guard !item.title.isEmpty else { return [] } // Separators have no title.
            let path = parent.appending(index: index, title: item.title)
            let own = AXKeyDecoder.keyCombo(of: item).map {
                Shortcut(title: item.title, keyCombo: $0, isEnabled: item.isEnabled, menuPath: path)
            }
            return [own].compactMap { $0 } + collectShortcuts(in: item.children, under: path)
        }
    }

    /// Some apps list the same item twice (e.g. dynamic alternates): keep the first.
    private struct DedupKey: Hashable {
        let title: String
        let keyCombo: KeyCombo
    }
}
