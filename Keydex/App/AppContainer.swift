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
    let gestureTiming: GestureTimingPreference
    let settings: SettingsViewModel
    private let gestureCoordinator: CommandGestureCoordinator
    private let prefetcher: ActiveAppPrefetcher

    init() {
        let activeAppProvider = WorkspaceActiveAppTracker()
        let permission = AXPermissionService()
        let store = ShortcutCatalogStore(source: AXMenuShortcutSource())
        let gestureTiming = GestureTimingPreference(store: UserDefaultsGestureTimingStore())
        let panelController = ShortcutPanelController(viewModel: ShortcutPanelViewModel(
            activeAppProvider: activeAppProvider,
            permission: permission,
            store: store,
            performer: AXMenuActionPerformer()
        ))

        self.activeAppProvider = activeAppProvider
        self.permission = permission
        self.panelController = panelController
        self.gestureTiming = gestureTiming
        settings = SettingsViewModel(
            gestureTiming: gestureTiming,
            launchAtLogin: SMAppServiceLaunchAtLogin(),
            permission: permission
        )
        gestureCoordinator = CommandGestureCoordinator(
            timing: gestureTiming,
            inputMonitor: NSEventInputMonitor(),
            permission: permission,
            panelController: panelController
        )
        gestureCoordinator.start()
        prefetcher = ActiveAppPrefetcher(activeAppProvider: activeAppProvider, permission: permission, store: store)
        prefetcher.onPrefetch = { [panelController] _ in panelController.prerender() }
        prefetcher.start()
    }
}
