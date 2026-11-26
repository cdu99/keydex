import KeydexDomain
import Observation

/// Loads and exposes the shortcuts of the last active app for the shortcut list window.
@MainActor
@Observable
final class ShortcutListViewModel {
    enum State {
        case idle
        case permissionRequired
        case loading(AppInfo)
        case loaded(ShortcutCatalog, loadDuration: Duration)
        case failed(AppInfo, message: String)
    }

    private(set) var state: State = .idle

    /// The app whose shortcuts are listed; observing it lets the view reload on app switch.
    var activeApp: AppInfo? { activeAppProvider.activeApp }

    @ObservationIgnored private let activeAppProvider: any ActiveAppProviding
    @ObservationIgnored private let permission: any AccessibilityPermissionProviding
    @ObservationIgnored private let loadCatalog: LoadShortcutCatalog
    @ObservationIgnored private let diagnosticsReport: @Sendable (AppInfo) async -> String

    init(
        activeAppProvider: any ActiveAppProviding,
        permission: any AccessibilityPermissionProviding,
        loadCatalog: LoadShortcutCatalog,
        diagnosticsReport: @escaping @Sendable (AppInfo) async -> String
    ) {
        self.activeAppProvider = activeAppProvider
        self.permission = permission
        self.loadCatalog = loadCatalog
        self.diagnosticsReport = diagnosticsReport
    }

    func reload() async {
        guard permission.isGranted else {
            state = .permissionRequired
            return
        }
        guard let app = activeAppProvider.activeApp else {
            state = .idle
            return
        }
        state = .loading(app)
        let clock = ContinuousClock()
        let start = clock.now
        do {
            let catalog = try await loadCatalog(for: app)
            state = .loaded(catalog, loadDuration: clock.now - start)
        } catch {
            state = .failed(app, message: Self.message(for: error))
        }
    }

    /// Raw Accessibility dump of the current app's menus, for troubleshooting.
    func diagnostics() async -> String? {
        guard let app = activeAppProvider.activeApp else { return nil }
        return await diagnosticsReport(app)
    }

    private static func message(for error: ShortcutSourceError) -> String {
        switch error {
        case .accessibilityNotGranted: "L'accès Accessibilité n'est pas autorisé."
        case .appNotResponding: "L'app ne répond pas. Réessaie dans un instant."
        case .noMenuBar: "Cette app n'a pas de barre de menus lisible."
        }
    }
}
