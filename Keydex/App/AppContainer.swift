import KeydexDomain
import KeydexInfrastructure

/// Composition root: the only place where concrete implementations are chosen
/// and wired together. The rest of the app depends on Domain abstractions.
@MainActor
final class AppContainer {
    let activeAppProvider: any ActiveAppProviding
    let permission: any AccessibilityPermissionProviding
    let shortcutList: ShortcutListViewModel

    init() {
        let activeAppProvider = WorkspaceActiveAppTracker()
        let permission = AXPermissionService()
        let diagnostics = MenuBarDiagnostics()

        self.activeAppProvider = activeAppProvider
        self.permission = permission
        shortcutList = ShortcutListViewModel(
            activeAppProvider: activeAppProvider,
            permission: permission,
            loadCatalog: LoadShortcutCatalog(source: AXMenuShortcutSource()),
            diagnosticsReport: { await diagnostics.report(for: $0) }
        )
    }
}
