import KeydexDomain
import Observation

/// Reads the shortcuts of the app the user switches to, so they are cached before ⌘ is held.
///
/// Reading runs on the target app's main thread, so it waits until the user has settled on
/// the app (`settleDelay`): quickly cycling through apps with ⌘Tab reads nothing.
@MainActor
public final class ActiveAppPrefetcher {
    private let activeAppProvider: any ActiveAppProviding
    private let permission: any AccessibilityPermissionProviding
    private let store: ShortcutCatalogStore
    private let settleDelay: Duration
    private var pendingRead: Task<Void, Never>?

    /// Called on the main actor after an app's shortcuts were read into the cache.
    public var onPrefetch: ((AppInfo) -> Void)?

    public init(
        activeAppProvider: any ActiveAppProviding,
        permission: any AccessibilityPermissionProviding,
        store: ShortcutCatalogStore,
        settleDelay: Duration = .seconds(1)
    ) {
        self.activeAppProvider = activeAppProvider
        self.permission = permission
        self.store = store
        self.settleDelay = settleDelay
    }

    public func start() {
        prefetchActiveApp()
    }

    private func prefetchActiveApp() {
        let app = withObservationTracking {
            activeAppProvider.activeApp
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in self?.prefetchActiveApp() }
        }
        schedule(app)
    }

    private func schedule(_ app: AppInfo?) {
        pendingRead?.cancel()
        guard let app else { return }
        pendingRead = Task { [weak self, settleDelay, store] in
            try? await Task.sleep(for: settleDelay)
            guard !Task.isCancelled, self?.permission.isGranted == true else { return }
            guard (try? await store.refresh(app)) != nil, !Task.isCancelled else { return }
            self?.onPrefetch?(app)
        }
    }
}
