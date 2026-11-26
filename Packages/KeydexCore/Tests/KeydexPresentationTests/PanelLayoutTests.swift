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
        #expect(layout.panelSize.width == 2 * PanelMetrics.padding + PanelMetrics.columnWidth)
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
        #expect(layout.columns.flatMap { $0 }.map(\.menuIndex) == Array(0..<10), "Menu order is preserved")
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
