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
    @ObservationIgnored private let store: ShortcutCatalogStore
    @ObservationIgnored private var availableSize: CGSize = .zero
    @ObservationIgnored private var backgroundRefresh: Task<Void, Never>?

    public init(
        activeAppProvider: any ActiveAppProviding,
        permission: any AccessibilityPermissionProviding,
        store: ShortcutCatalogStore
    ) {
        self.activeAppProvider = activeAppProvider
        self.permission = permission
        self.store = store
    }

    /// Size the panel window should have for the current content.
    public var preferredSize: CGSize {
        if case let .loaded(_, layout) = content { layout.panelSize } else { PanelMetrics.messageSize }
    }

    /// Prepares the content for the active app, laid out to fit `availableSize`.
    ///
    /// Returns as soon as something can be shown: cached shortcuts are shown immediately
    /// and refreshed in the background (the menus, or their enabled state, may have
    /// changed). Without a cache, waits for the first read.
    public func prepare(mode: Mode, availableSize: CGSize) async {
        backgroundRefresh?.cancel()
        self.mode = mode
        self.availableSize = availableSize
        guard permission.isGranted else {
            content = .permissionRequired
            return
        }
        guard let app = activeAppProvider.activeApp else {
            content = .noActiveApp
            return
        }
        if let cached = await store.cachedCatalog(for: app) {
            show(cached)
            backgroundRefresh = Task { [weak self] in await self?.refresh(app) }
        } else {
            content = .loading(app)
            await refresh(app)
        }
    }

    /// Stops background work once the panel is hidden.
    public func panelDidClose() {
        backgroundRefresh?.cancel()
        backgroundRefresh = nil
    }

    public func requestPermission() {
        permission.requestAccess()
        permission.openSystemSettings()
    }

    private func refresh(_ app: AppInfo) async {
        do {
            let catalog = try await store.refresh(app)
            guard !Task.isCancelled else { return }
            show(catalog)
        } catch {
            guard !Task.isCancelled else { return }
            // Keep showing cached shortcuts rather than replacing them by an error.
            if case let .loaded(shown, _) = content, shown.app == app { return }
            content = .failed(app, message: Self.message(for: error))
        }
    }

    private func show(_ catalog: ShortcutCatalog) {
        if case let .loaded(shown, _) = content, shown == catalog { return }
        content = catalog.isEmpty
            ? .noShortcuts(catalog.app)
            : .loaded(catalog, PanelLayout(groups: catalog.groups, availableSize: availableSize))
    }

    private static func message(for error: ShortcutSourceError) -> String {
        switch error {
        case .accessibilityNotGranted: "L'accès Accessibilité n'est pas autorisé."
        case .appNotResponding: "L'app ne répond pas. Réessaie dans un instant."
        case .noMenuBar: "Cette app n'a pas de barre de menus lisible."
        }
    }
}
