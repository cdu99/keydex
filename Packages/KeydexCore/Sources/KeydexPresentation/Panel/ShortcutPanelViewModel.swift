import CoreGraphics
import KeydexDomain
import Observation

/// State of the shortcut panel: which app it shows, and how.
@MainActor
@Observable
public final class ShortcutPanelViewModel {
    public enum Mode: Sendable {
        /// Shown while ⌘ is held, hidden on release. Never takes the keyboard.
        case glance
        /// Stays open until closed explicitly (✕, Escape, click outside).
        case sticky
    }

    public enum Content: Equatable {
        case noActiveApp
        case permissionRequired
        case loading(AppInfo)
        case loaded(ShortcutCatalog, PanelLayout)
        case noShortcuts(AppInfo)
        case failed(AppInfo, message: String)
    }

    public private(set) var mode: Mode = .glance
    public private(set) var content: Content = .noActiveApp

    @ObservationIgnored private let activeAppProvider: any ActiveAppProviding
    @ObservationIgnored private let permission: any AccessibilityPermissionProviding
    @ObservationIgnored private let loadCatalog: LoadShortcutCatalog

    public init(
        activeAppProvider: any ActiveAppProviding,
        permission: any AccessibilityPermissionProviding,
        loadCatalog: LoadShortcutCatalog
    ) {
        self.activeAppProvider = activeAppProvider
        self.permission = permission
        self.loadCatalog = loadCatalog
    }

    /// Size the panel window should have for the current content.
    public var preferredSize: CGSize {
        if case let .loaded(_, layout) = content { layout.panelSize } else { PanelMetrics.messageSize }
    }

    /// Loads the shortcuts of the active app and lays them out to fit `availableSize`.
    public func prepare(mode: Mode, availableSize: CGSize) async {
        self.mode = mode
        guard permission.isGranted else {
            content = .permissionRequired
            return
        }
        guard let app = activeAppProvider.activeApp else {
            content = .noActiveApp
            return
        }
        content = .loading(app)
        do {
            let catalog = try await loadCatalog(for: app)
            content = catalog.isEmpty
                ? .noShortcuts(app)
                : .loaded(catalog, PanelLayout(groups: catalog.groups, availableSize: availableSize))
        } catch {
            content = .failed(app, message: Self.message(for: error))
        }
    }

    public func requestPermission() {
        permission.requestAccess()
        permission.openSystemSettings()
    }

    private static func message(for error: ShortcutSourceError) -> String {
        switch error {
        case .accessibilityNotGranted: "L'accès Accessibilité n'est pas autorisé."
        case .appNotResponding: "L'app ne répond pas. Réessaie dans un instant."
        case .noMenuBar: "Cette app n'a pas de barre de menus lisible."
        }
    }
}
