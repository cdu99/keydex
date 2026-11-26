import CoreGraphics
@testable import KeydexPresentation
import Testing

@Suite("Panel layout")
struct PanelLayoutTests {
    @Test("A small app fits in one column, and the panel hugs its content")
    func smallApp() {
        let layout = PanelLayout(groups: [Fixtures.group("Fichier", index: 1, rows: 5)], availableSize: Fixtures.screen)
        #expect(layout.columns.count == 1)
        #expect(!layout.needsScrolling)
        #expect(layout.columnWidth == PanelMetrics.columnWidths[0], "Widest columns when they fit")
        #expect(layout.panelSize.width == 2 * PanelMetrics.padding + layout.columnWidth)
        #expect(layout.panelSize.height == PanelMetrics.chromeHeight + PanelMetrics.groupHeight(rowCount: 5))
    }

    @Test("A big app spreads over several columns and still fits the screen")
    func bigApp() {
        let groups = (0..<10).map { Fixtures.group("Menu \($0)", index: $0, rows: 10) }
        let layout = PanelLayout(groups: groups, availableSize: Fixtures.screen)
        #expect(layout.columns.count > 1)
        #expect(!layout.needsScrolling)
        #expect(layout.panelSize.height <= Fixtures.screen.height)
        #expect(layout.panelSize.width <= Fixtures.screen.width)
        let firstBlocks = layout.columns.flatMap { $0 }.filter { !$0.isContinuation }
        let expectedTitles = (0..<10).map { "Menu \($0)" }
        #expect(firstBlocks.map(\.title) == expectedTitles, "Menu order is preserved")
    }

    @Test("Narrower columns are used when they avoid scrolling")
    func narrowerColumnsInsteadOfScrolling() {
        // Five tall menus need five columns: only the narrowest width fits five in 1200 pt.
        let groups = (0..<5).map { Fixtures.group("Menu \($0)", index: $0, rows: 30) }
        let layout = PanelLayout(groups: groups, availableSize: CGSize(width: 1200, height: 720))
        #expect(!layout.needsScrolling)
        #expect(layout.columns.count == 5)
        #expect(layout.columnWidth == PanelMetrics.columnWidths.last)
    }

    @Test("Finder fits a 14-inch screen without scrolling, its long menus continuing across columns")
    func finderOnSmallScreen() {
        // Finder's menus: 118 shortcuts; usable area of a 1512×982 screen.
        let rowCounts = [5, 5, 28, 15, 27, 18, 21, 1]
        let groups = rowCounts.enumerated().map { Fixtures.group("Menu \($0)", index: $0, rows: $1) }
        let layout = PanelLayout(groups: groups, availableSize: CGSize(width: 1391, height: 800))
        #expect(!layout.needsScrolling)
        let blocks = layout.columns.flatMap { $0 }
        let shownCount = blocks.map(\.shortcuts.count).reduce(0, +)
        let hasContinuation = blocks.contains { $0.isContinuation }
        #expect(hasContinuation)
        #expect(shownCount == 120)
    }

    @Test("When even the widest layout is too tall, the content scrolls within the screen height")
    func overflow() {
        let groups = (0..<4).map { Fixtures.group("Menu \($0)", index: $0, rows: 80) }
        let layout = PanelLayout(groups: groups, availableSize: CGSize(width: 700, height: 600))
        #expect(layout.needsScrolling)
        #expect(layout.panelSize.height == 600)
        #expect(layout.panelSize.width <= 700)
    }
}
