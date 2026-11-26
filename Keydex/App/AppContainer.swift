import KeydexDomain
import KeydexInfrastructure
import KeydexPresentation

/// Composition root: the only place where concrete implementations are chosen
/// and wired together. The rest of the app depends on Domain abstractions.
@MainActor
final class AppContainer {
    let activeAppProvider: any ActiveAppProviding
    let permission: any AccessibilityPermissionProviding
    let panelController: ShortcutPanelController

    init() {
        let activeAppProvider = WorkspaceActiveAppTracker()
        let permission = AXPermissionService()
        let loadCatalog = LoadShortcutCatalog(source: AXMenuShortcutSource())

        self.activeAppProvider = activeAppProvider
        self.permission = permission
        panelController = ShortcutPanelController(viewModel: ShortcutPanelViewModel(
            activeAppProvider: activeAppProvider,
            permission: permission,
            loadCatalog: loadCatalog
        ))
    }
}
