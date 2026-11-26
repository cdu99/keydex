import KeydexDomain
import KeydexPresentation
import Observation
import Testing

@MainActor
@Observable
private final class ObservableActiveApp: ActiveAppProviding {
    var activeApp: AppInfo?
}

@MainActor
@Suite("Prefetching the active app")
struct ActiveAppPrefetcherTests {
    private let other = AppInfo(processID: 7, bundleIdentifier: "com.example.other", name: "Other")

    private func waitUntil(_ condition: () async -> Bool) async throws {
        for _ in 0..<300 where !(await condition()) {
            try await Task.sleep(for: .milliseconds(1))
        }
    }

    @Test("The app the user settles on is read and cached")
    func prefetchesSettledApp() async throws {
        let activeApp = ObservableActiveApp()
        let store = ShortcutCatalogStore(source: StubShortcutSource(result: .success([])))
        let prefetcher = ActiveAppPrefetcher(
            activeAppProvider: activeApp, permission: StubPermission(granted: true),
            store: store, settleDelay: .milliseconds(10)
        )
        prefetcher.start()
        activeApp.activeApp = Fixtures.app

        try await waitUntil { await store.cachedCatalog(for: Fixtures.app) != nil }
        #expect(await store.cachedCatalog(for: Fixtures.app) != nil)
    }

    @Test("Apps only passed through (⌘Tab) are not read")
    func skipsAppsPassedThrough() async throws {
        let activeApp = ObservableActiveApp()
        let store = ShortcutCatalogStore(source: StubShortcutSource(result: .success([])))
        let prefetcher = ActiveAppPrefetcher(
            activeAppProvider: activeApp, permission: StubPermission(granted: true),
            store: store, settleDelay: .milliseconds(50)
        )
        prefetcher.start()
        activeApp.activeApp = other
        try await Task.sleep(for: .milliseconds(5))
        activeApp.activeApp = Fixtures.app

        try await waitUntil { await store.cachedCatalog(for: Fixtures.app) != nil }
        #expect(await store.cachedCatalog(for: other) == nil)
    }

    @Test("Nothing is read without the Accessibility permission")
    func requiresPermission() async throws {
        let activeApp = ObservableActiveApp()
        let store = ShortcutCatalogStore(source: StubShortcutSource(result: .success([])))
        let prefetcher = ActiveAppPrefetcher(
            activeAppProvider: activeApp, permission: StubPermission(granted: false),
            store: store, settleDelay: .milliseconds(1)
        )
        prefetcher.start()
        activeApp.activeApp = Fixtures.app
        try await Task.sleep(for: .milliseconds(50))
        #expect(await store.cachedCatalog(for: Fixtures.app) == nil)
    }
}
