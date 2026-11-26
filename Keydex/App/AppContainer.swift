import Foundation
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
    let sheetLibrary: SheetLibrary

    /// Where users write their own sheets (created if missing).
    static let userSheetsDirectory = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/keydex", isDirectory: true)
    private static let bundledSheetsDirectory = Bundle.main.resourceURL!
        .appendingPathComponent("sheets", isDirectory: true)

    init() {
        let activeAppProvider = WorkspaceActiveAppTracker()
        let permission = AXPermissionService()
        let sheetLibrary = SheetLibrary(bundledFolder: Self.bundledSheetsDirectory, userFolder: Self.userSheetsDirectory)
        let store = ShortcutCatalogStore(source: SheetAugmentedShortcutSource(
            menus: AXMenuShortcutSource(),
            sheetProviders: [sheetLibrary.provider]
        ))
        let gestureTiming = GestureTimingPreference(store: UserDefaultsGestureTimingStore())
        let panelController = ShortcutPanelController(viewModel: ShortcutPanelViewModel(
            activeAppProvider: activeAppProvider,
            permission: permission,
            store: store,
            performer: AXMenuActionPerformer()
        ))

        // Saving a sheet applies at the next glance, without relaunching.
        sheetLibrary.onChange = { Task { await store.removeAll() } }
        self.sheetLibrary = sheetLibrary
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
