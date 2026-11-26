import KeydexDomain
@testable import KeydexPresentation
import Testing

@MainActor
@Suite("Searching and navigating in the sticky panel")
struct PanelSearchTests {
    private let performer = RecordingPerformer()

    /// "Fichier 0…2" (⌘0…⌘2) and "Édition 0…2" (⌘0…⌘2).
    private func makeViewModel() async -> ShortcutPanelViewModel {
        let groups = [Fixtures.group("Fichier", index: 1, rows: 3), Fixtures.group("Édition", index: 2, rows: 3)]
        let viewModel = ShortcutPanelViewModel(
            activeAppProvider: StubActiveApp(Fixtures.app),
            permission: StubPermission(granted: true),
            store: ShortcutCatalogStore(source: StubShortcutSource(result: .success(groups))),
            performer: performer
        )
        await viewModel.prepare(mode: .sticky, availableSize: Fixtures.screen)
        return viewModel
    }

    @Test("Without query, everything is shown and nothing is selected")
    func noQuery() async {
        let viewModel = await makeViewModel()
        #expect(viewModel.displayedShortcuts.count == 6)
        #expect(viewModel.selection == nil)
    }

    @Test("Typing filters the shortcuts and selects the first result")
    func typing() async {
        let viewModel = await makeViewModel()
        viewModel.query = "edition"
        #expect(viewModel.displayedShortcuts.map(\.title) == ["Édition 0", "Édition 1", "Édition 2"])
        #expect(viewModel.selection == viewModel.displayedShortcuts.first?.id)
    }

    @Test("While filtering, the panel keeps its width and fits its height to the results")
    func sizeWhileFiltering() async {
        let groups = (0..<6).map { Fixtures.group("Menu \($0)", index: $0, rows: 12) }
        let viewModel = ShortcutPanelViewModel(
            activeAppProvider: StubActiveApp(Fixtures.app),
            permission: StubPermission(granted: true),
            store: ShortcutCatalogStore(source: StubShortcutSource(result: .success(groups))),
            performer: performer
        )
        await viewModel.prepare(mode: .sticky, availableSize: Fixtures.screen)
        let fullSize = viewModel.preferredSize

        viewModel.query = "menu 1 1"
        #expect(viewModel.preferredSize.width == fullSize.width)
        #expect(viewModel.preferredSize.height < fullSize.height)
        #expect(viewModel.preferredSize.height >= PanelMetrics.messageSize.height)

        viewModel.query = ""
        #expect(viewModel.preferredSize == fullSize)
    }

    @Test("No result shows an empty layout")
    func noResult() async {
        let viewModel = await makeViewModel()
        viewModel.query = "zzz"
        #expect(viewModel.displayedShortcuts.isEmpty)
        #expect(viewModel.selection == nil)
    }

    @Test("Arrows move the selection through results, wrapping around")
    func arrows() async {
        let viewModel = await makeViewModel()
        viewModel.moveSelection(.next)
        #expect(viewModel.selection == viewModel.displayedShortcuts[0].id)
        viewModel.moveSelection(.previous)
        #expect(viewModel.selection == viewModel.displayedShortcuts[5].id, "Wraps to the last")
        viewModel.moveSelection(.next)
        #expect(viewModel.selection == viewModel.displayedShortcuts[0].id, "Wraps to the first")
    }

    @Test("Return performs the selected shortcut after closing the panel")
    func performSelection() async throws {
        let viewModel = await makeViewModel()
        var closed = false
        viewModel.onClose = { closed = true }
        viewModel.query = "fichier 2"
        viewModel.performSelection()
        #expect(closed)
        for _ in 0..<300 where performer.performedTitles.isEmpty {
            try await Task.sleep(for: .milliseconds(1))
        }
        #expect(performer.performedTitles == ["Fichier 2"])
    }

    @Test("Opening the panel again starts a fresh search")
    func freshSearch() async {
        let viewModel = await makeViewModel()
        viewModel.query = "fichier"
        await viewModel.prepare(mode: .sticky, availableSize: Fixtures.screen)
        #expect(viewModel.query.isEmpty)
        #expect(viewModel.displayedShortcuts.count == 6)
    }

    @Test("Documented shortcuts (sheets) can be selected but not run")
    func documentedShortcut() async throws {
        let documented = Shortcut(id: "sheet:zsh:0:0", title: "Effacer le mot", keyCombo: KeyComboParser.parse("⌃W")!)
        let sheetGroup = ShortcutGroup(id: "sheet:zsh:0", title: "zsh · Mots", kind: .sheet, shortcuts: [documented])
        let viewModel = ShortcutPanelViewModel(
            activeAppProvider: StubActiveApp(Fixtures.app),
            permission: StubPermission(granted: true),
            store: ShortcutCatalogStore(source: StubShortcutSource(result: .success([sheetGroup]))),
            performer: performer
        )
        await viewModel.prepare(mode: .sticky, availableSize: Fixtures.screen)
        var closed = false
        viewModel.onClose = { closed = true }
        viewModel.query = "mot"
        #expect(viewModel.selection == documented.id)
        viewModel.performSelection()
        try await Task.sleep(for: .milliseconds(150))
        #expect(!closed)
        #expect(performer.performedTitles.isEmpty)
    }

    @Test("Sheets for every app are not in the glance, but are found by searching")
    func systemSheetsOnlyInSearch() async {
        let capture = Shortcut(id: "sheet:macos:0:0", title: "Capturer l'écran", keyCombo: KeyComboParser.parse("⇧⌘3")!)
        let system = ShortcutGroup(id: "sheet:macos:0", title: "macOS · Captures", kind: .sheet,
                                   appliesToEveryApp: true, shortcuts: [capture])
        let viewModel = ShortcutPanelViewModel(
            activeAppProvider: StubActiveApp(Fixtures.app),
            permission: StubPermission(granted: true),
            store: ShortcutCatalogStore(source: StubShortcutSource(result: .success([Fixtures.group("Fichier", index: 1, rows: 3), system]))),
            performer: performer
        )
        await viewModel.prepare(mode: .sticky, availableSize: Fixtures.screen)
        #expect(!viewModel.displayedShortcuts.contains(capture))
        viewModel.query = "capturer"
        #expect(viewModel.displayedShortcuts == [capture])
    }
}
