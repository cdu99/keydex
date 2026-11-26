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

    /// Search text typed in the sticky panel.
    public var query = "" {
        didSet { if query != oldValue { applyQuery(selectingFirstResult: true) } }
    }

    /// Layout of what the panel shows: all shortcuts, or only those matching `query`.
    public private(set) var displayedLayout: PanelLayout?
    /// Shortcut highlighted for keyboard navigation, if any.
    public private(set) var selection: Shortcut.ID?
    /// Changes each time a sticky panel opens, so the view can focus its search field.
    public private(set) var searchSession = 0

    /// Asks the panel controller to close the panel.
    @ObservationIgnored public var onClose: (() -> Void)?

    @ObservationIgnored private let activeAppProvider: any ActiveAppProviding
    @ObservationIgnored private let permission: any AccessibilityPermissionProviding
    @ObservationIgnored private let store: ShortcutCatalogStore
    @ObservationIgnored private let performer: any ShortcutActionPerforming
    @ObservationIgnored private var availableSize: CGSize = .zero
    @ObservationIgnored private var backgroundRefresh: Task<Void, Never>?

    /// Time for the user's app to get the keyboard back before its menu item is pressed.
    private static let focusReturnDelay = Duration.milliseconds(80)

    public init(
        activeAppProvider: any ActiveAppProviding,
        permission: any AccessibilityPermissionProviding,
        store: ShortcutCatalogStore,
        performer: any ShortcutActionPerforming
    ) {
        self.activeAppProvider = activeAppProvider
        self.permission = permission
        self.store = store
        self.performer = performer
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
        query = ""
        selection = nil
        if mode == .sticky { searchSession += 1 }
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

    /// Closes the panel (✕, Escape).
    public func close() {
        onClose?()
    }

    // MARK: Search and keyboard navigation

    /// Shortcuts shown, in reading order (column by column, top to bottom).
    public var displayedShortcuts: [Shortcut] {
        displayedLayout?.columns.flatMap { $0 }.flatMap(\.shortcuts) ?? []
    }

    public enum Direction: Sendable { case previous, next }

    public func moveSelection(_ direction: Direction) {
        let shortcuts = displayedShortcuts
        guard !shortcuts.isEmpty else { return }
        guard let current = shortcuts.firstIndex(where: { $0.id == selection }) else {
            selection = (direction == .next ? shortcuts.first : shortcuts.last)?.id
            return
        }
        let next = direction == .next ? current + 1 : current - 1
        selection = shortcuts[(next + shortcuts.count) % shortcuts.count].id
    }

    public func select(_ shortcut: Shortcut) {
        selection = shortcut.id
    }

    public func performSelection() {
        guard let shortcut = displayedShortcuts.first(where: { $0.id == selection }) else { return }
        perform(shortcut)
    }

    /// Closes the panel, gives the keyboard back to the app, then triggers the action in it.
    public func perform(_ shortcut: Shortcut) {
        guard case let .loaded(catalog, _) = content else { return }
        close()
        let app = catalog.app
        let performer = performer
        Task.detached(priority: .userInitiated) {
            try? await Task.sleep(for: Self.focusReturnDelay)
            // Failures (item gone, app busy) leave the app unchanged, like a no-op menu click.
            try? performer.perform(shortcut, in: app)
        }
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
        applyQuery(selectingFirstResult: false)
    }

    /// Lays out the shortcuts matching `query` inside the panel's current size, so the
    /// window does not jump around while typing.
    private func applyQuery(selectingFirstResult: Bool) {
        guard case let .loaded(catalog, fullLayout) = content else {
            displayedLayout = nil
            return
        }
        let searchQuery = ShortcutQuery(query)
        displayedLayout = searchQuery.isEmpty
            ? fullLayout
            : PanelLayout(groups: searchQuery.filter(catalog.groups), availableSize: fullLayout.panelSize)

        let shortcuts = displayedShortcuts
        if selectingFirstResult {
            selection = searchQuery.isEmpty ? nil : shortcuts.first?.id
        } else if !shortcuts.contains(where: { $0.id == selection }) {
            selection = nil
        }
    }

    private static func message(for error: ShortcutSourceError) -> String {
        switch error {
        case .accessibilityNotGranted: "L'accès Accessibilité n'est pas autorisé."
        case .appNotResponding: "L'app ne répond pas. Réessaie dans un instant."
        case .noMenuBar: "Cette app n'a pas de barre de menus lisible."
        }
    }
}
