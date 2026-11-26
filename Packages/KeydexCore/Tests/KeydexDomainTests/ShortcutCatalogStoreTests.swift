import Foundation
import KeydexDomain
import Synchronization
import Testing

/// Counts reads, and can block them until released, to observe coalescing.
private final class CountingSource: ShortcutSource {
    private let reads = Mutex(0)
    private let failure: ShortcutSourceError?
    private let delay: TimeInterval

    init(failure: ShortcutSourceError? = nil, delay: TimeInterval = 0) {
        self.failure = failure
        self.delay = delay
    }

    var readCount: Int { reads.withLock { $0 } }

    func catalog(for app: AppInfo) throws(ShortcutSourceError) -> ShortcutCatalog {
        reads.withLock { $0 += 1 }
        if delay > 0 { Thread.sleep(forTimeInterval: delay) } // Simulates a slow app.
        if let failure { throw failure }
        return ShortcutCatalog(app: app, groups: [])
    }
}

@Suite("Shortcut catalog store")
struct ShortcutCatalogStoreTests {
    private let finder = AppInfo(processID: 1, bundleIdentifier: "com.apple.finder", name: "Finder")
    private let safari = AppInfo(processID: 2, bundleIdentifier: "com.apple.Safari", name: "Safari")

    @Test("Nothing is cached before the first read")
    func emptyAtFirst() async {
        let store = ShortcutCatalogStore(source: CountingSource())
        #expect(await store.cachedCatalog(for: finder) == nil)
    }

    @Test("A refresh reads the app and caches the result")
    func refreshCaches() async throws {
        let source = CountingSource()
        let store = ShortcutCatalogStore(source: source)
        let catalog = try await store.refresh(finder)
        #expect(catalog.app == finder)
        try await waitUntilCached(finder, in: store)
        #expect(await store.cachedCatalog(for: finder) == catalog)
        #expect(source.readCount == 1)
    }

    @Test("Concurrent refreshes of the same app share one read")
    func coalescing() async throws {
        let source = CountingSource(delay: 0.1)
        let store = ShortcutCatalogStore(source: source)
        async let first = store.refresh(finder)
        async let second = store.refresh(finder)
        _ = try await (first, second)
        #expect(source.readCount == 1)
    }

    @Test("Failed reads are not cached")
    func failuresNotCached() async {
        let store = ShortcutCatalogStore(source: CountingSource(failure: .appNotResponding))
        await #expect(throws: ShortcutSourceError.appNotResponding) { try await store.refresh(finder) }
        #expect(await store.cachedCatalog(for: finder) == nil)
    }

    @Test("A process ID reused by another app never returns the old app's shortcuts")
    func reusedProcessID() async throws {
        let store = ShortcutCatalogStore(source: CountingSource())
        _ = try await store.refresh(finder)
        try await waitUntilCached(finder, in: store)
        let other = AppInfo(processID: finder.processID, bundleIdentifier: "com.example", name: "Other")
        #expect(await store.cachedCatalog(for: other) == nil)
    }

    @Test("The least recently used app is dropped beyond capacity")
    func eviction() async throws {
        let store = ShortcutCatalogStore(source: CountingSource(), capacity: 1)
        _ = try await store.refresh(finder)
        try await waitUntilCached(finder, in: store)
        _ = try await store.refresh(safari)
        try await waitUntilCached(safari, in: store)
        #expect(await store.cachedCatalog(for: finder) == nil)
    }

    /// The cache is filled right after the read completes, on the store's actor.
    private func waitUntilCached(_ app: AppInfo, in store: ShortcutCatalogStore) async throws {
        for _ in 0..<100 where await store.cachedCatalog(for: app) == nil {
            try await Task.sleep(for: .milliseconds(1))
        }
    }
}
