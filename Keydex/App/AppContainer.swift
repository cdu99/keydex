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
    let sheets: DirectorySheetProvider
    private let sheetsWatcher: DirectoryWatcher

    /// Where users write their own sheets (created if missing).
    static let userSheetsDirectory = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/keydex", isDirectory: true)
    private static let bundledSheetsDirectory = Bundle.main.resourceURL!
        .appendingPathComponent("sheets", isDirectory: true)

    init() {
        let activeAppProvider = WorkspaceActiveAppTracker()
        let permission = AXPermissionService()
        try? FileManager.default.createDirectory(at: Self.userSheetsDirectory, withIntermediateDirectories: true)
        let sheets = DirectorySheetProvider(directories: [Self.bundledSheetsDirectory, Self.userSheetsDirectory])
        let store = ShortcutCatalogStore(source: SheetAugmentedShortcutSource(
            menus: AXMenuShortcutSource(),
            sheetProviders: [sheets]
        ))
        let gestureTiming = GestureTimingPreference(store: UserDefaultsGestureTimingStore())
        let panelController = ShortcutPanelController(viewModel: ShortcutPanelViewModel(
            activeAppProvider: activeAppProvider,
            permission: permission,
            store: store,
            performer: AXMenuActionPerformer()
        ))

        self.sheets = sheets
        // Saving a sheet applies at the next glance, without relaunching.
        sheetsWatcher = DirectoryWatcher(directory: Self.userSheetsDirectory) {
            sheets.reload()
            Task { await store.removeAll() }
        }
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
