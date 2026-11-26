/// Keeps the last catalog read for each running app, so the panel can appear instantly,
/// and reads fresh ones off the main thread.
///
/// Reading an app's menus runs on that app's main thread (≈140 ms for IntelliJ), so reads
/// are coalesced: concurrent refreshes of the same app share a single read.
public actor ShortcutCatalogStore {
    private let source: any ShortcutSource
    private let capacity: Int
    private var catalogs: [Int32: ShortcutCatalog] = [:]
    /// Process IDs from least to most recently used.
    private var recency: [Int32] = []
    private var readsInFlight: [Int32: Task<Result<ShortcutCatalog, ShortcutSourceError>, Never>] = [:]

    /// - Parameter capacity: number of apps kept; the least recently used is dropped first.
    public init(source: any ShortcutSource, capacity: Int = 12) {
        self.source = source
        self.capacity = max(1, capacity)
    }

    /// The last catalog read for `app`, possibly stale, or `nil` if it was never read.
    public func cachedCatalog(for app: AppInfo) -> ShortcutCatalog? {
        // A reused process ID belongs to another app: never show its shortcuts.
        guard let catalog = catalogs[app.processID], catalog.app == app else { return nil }
        touch(app.processID)
        return catalog
    }

    /// Forgets every cached catalog, e.g. when sheets changed: the next read is fresh.
    public func removeAll() {
        catalogs.removeAll()
        recency.removeAll()
    }

    /// Reads the current catalog of `app` and caches it.
    public func refresh(_ app: AppInfo) async throws(ShortcutSourceError) -> ShortcutCatalog {
        let read = readsInFlight[app.processID] ?? startRead(of: app)
        return try await read.value.get()
    }

    private func startRead(of app: AppInfo) -> Task<Result<ShortcutCatalog, ShortcutSourceError>, Never> {
        let source = source
        let read = Task.detached(priority: .userInitiated) {
            Result { () throws(ShortcutSourceError) in try source.catalog(for: app) }
        }
        readsInFlight[app.processID] = read
        Task { await self.finish(read, for: app.processID) }
        return read
    }

    private func finish(_ read: Task<Result<ShortcutCatalog, ShortcutSourceError>, Never>, for processID: Int32) async {
        let result = await read.value
        readsInFlight[processID] = nil
        if case let .success(catalog) = result {
            store(catalog)
        }
    }

    private func store(_ catalog: ShortcutCatalog) {
        catalogs[catalog.app.processID] = catalog
        touch(catalog.app.processID)
        while recency.count > capacity {
            catalogs[recency.removeFirst()] = nil
        }
    }

    private func touch(_ processID: Int32) {
        recency.removeAll { $0 == processID }
        recency.append(processID)
    }
}
