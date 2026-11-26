/// The shortcuts of an app's menus, completed by the sheets that apply to it.
///
/// Menus come first and win: a sheet entry whose keys are already used by a menu item is
/// dropped, so each combination appears once and can be run when it can. Then sheets written
/// for this app come before sheets for every app, and win over them in the same way (in a
/// terminal, ⌃K means what zsh does, not what macOS text fields do). An app without a readable
/// menu bar still shows its sheets.
public struct SheetAugmentedShortcutSource: ShortcutSource {
    private let menus: any ShortcutSource
    private let sheetProviders: [any ShortcutSheetProviding]

    public init(menus: any ShortcutSource, sheetProviders: [any ShortcutSheetProviding]) {
        self.menus = menus
        self.sheetProviders = sheetProviders
    }

    public func catalog(for app: AppInfo) throws(ShortcutSourceError) -> ShortcutCatalog {
        let applicable = sheetProviders.flatMap { $0.sheets(for: app) }
        let appSpecificFirst = applicable.filter { !$0.apps.isEmpty } + applicable.filter(\.apps.isEmpty)
        let sheetGroups = appSpecificFirst.flatMap(\.groups)

        let menuGroups: [ShortcutGroup]
        do {
            menuGroups = try menus.catalog(for: app).groups
        } catch .noMenuBar where !sheetGroups.isEmpty {
            menuGroups = []
        }

        var usedCombos = Set(menuGroups.flatMap(\.shortcuts).map(\.keyCombo))
        let extraGroups = sheetGroups.compactMap { group -> ShortcutGroup? in
            let shortcuts = group.shortcuts.filter { usedCombos.insert($0.keyCombo).inserted }
            return shortcuts.isEmpty ? nil : group.replacingShortcuts(with: shortcuts)
        }
        return ShortcutCatalog(app: app, groups: menuGroups + extraGroups)
    }
}
