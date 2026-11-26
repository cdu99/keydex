import KeydexDomain
@testable import KeydexPresentation
import Testing

@MainActor
@Suite("Shortcut panel view model")
struct ShortcutPanelViewModelTests {
    private func makeViewModel(
        app: AppInfo? = Fixtures.app,
        granted: Bool = true,
        result: Result<[ShortcutGroup], ShortcutSourceError> = .success([Fixtures.group("Fichier", index: 1, rows: 3)])
    ) -> (ShortcutPanelViewModel, StubPermission) {
        let permission = StubPermission(granted: granted)
        let viewModel = ShortcutPanelViewModel(
            activeAppProvider: StubActiveApp(app),
            permission: permission,
            store: ShortcutCatalogStore(source: StubShortcutSource(result: result)),
            performer: RecordingPerformer()
        )
        return (viewModel, permission)
    }

    @Test("Loads the active app's shortcuts and lays them out")
    func loads() async {
        let (viewModel, _) = makeViewModel()
        await viewModel.prepare(mode: .glance, availableSize: Fixtures.screen)
        guard case let .loaded(catalog, layout) = viewModel.content else {
            Issue.record("Expected loaded content, got \(viewModel.content)")
            return
        }
        #expect(catalog.app == Fixtures.app)
        #expect(viewModel.preferredSize == layout.panelSize)
        #expect(viewModel.mode == .glance)
    }

    @Test("Remembers the presentation mode")
    func mode() async {
        let (viewModel, _) = makeViewModel()
        await viewModel.prepare(mode: .sticky, availableSize: Fixtures.screen)
        #expect(viewModel.mode == .sticky)
    }

    @Test("Asks for the permission instead of reading when it is missing")
    func permissionMissing() async {
        let (viewModel, permission) = makeViewModel(granted: false)
        await viewModel.prepare(mode: .glance, availableSize: Fixtures.screen)
        #expect(viewModel.content == .permissionRequired)
        #expect(viewModel.preferredSize == PanelMetrics.messageSize)

        viewModel.requestPermission()
        #expect(permission.requestCount == 1)
        #expect(permission.openedSettings)
    }

    @Test("Without active app, says so")
    func noActiveApp() async {
        let (viewModel, _) = makeViewModel(app: nil)
        await viewModel.prepare(mode: .glance, availableSize: Fixtures.screen)
        #expect(viewModel.content == .noActiveApp)
    }

    @Test("An app without any shortcut gets a dedicated message")
    func noShortcuts() async {
        let (viewModel, _) = makeViewModel(result: .success([]))
        await viewModel.prepare(mode: .glance, availableSize: Fixtures.screen)
        #expect(viewModel.content == .noShortcuts(Fixtures.app))
    }

    @Test("Cached shortcuts are shown at once, then replaced by fresh ones")
    func cachedThenRefreshed() async throws {
        let source = MutableShortcutSource(groups: [Fixtures.group("Fichier", index: 1, rows: 3)])
        let store = ShortcutCatalogStore(source: source)
        _ = try await store.refresh(Fixtures.app)
        let viewModel = ShortcutPanelViewModel(
            activeAppProvider: StubActiveApp(Fixtures.app),
            permission: StubPermission(granted: true),
            store: store,
            performer: RecordingPerformer()
        )
        source.groups = [Fixtures.group("Fichier", index: 1, rows: 5)]

        await viewModel.prepare(mode: .glance, availableSize: Fixtures.screen)
        #expect(viewModel.shownShortcutCount == 3, "Cached content first")

        for _ in 0..<200 where viewModel.shownShortcutCount != 5 {
            try await Task.sleep(for: .milliseconds(1))
        }
        #expect(viewModel.shownShortcutCount == 5, "Then the refreshed content")
    }

    @Test("Read errors become a readable message")
    func failure() async {
        let (viewModel, _) = makeViewModel(result: .failure(.appNotResponding))
        await viewModel.prepare(mode: .glance, availableSize: Fixtures.screen)
        guard case let .failed(app, message) = viewModel.content else {
            Issue.record("Expected failure, got \(viewModel.content)")
            return
        }
        #expect(app == Fixtures.app)
        #expect(message.contains("ne répond pas"))
    }
}

private extension ShortcutPanelViewModel {
    var shownShortcutCount: Int? {
        if case let .loaded(catalog, _) = content { catalog.shortcutCount } else { nil }
    }
}
