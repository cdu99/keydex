import CoreGraphics
import KeydexDomain

/// How the groups of a catalog are arranged in the panel, and the resulting panel size.
public struct PanelLayout: Equatable, Sendable {
    public let columns: [[ShortcutGroup]]
    /// Height of the column area if it were fully shown.
    public let contentHeight: CGFloat
    /// True when the content is taller than the screen allows and must scroll.
    public let needsScrolling: Bool
    public let panelSize: CGSize

    /// Arranges `groups` in as few columns as possible so the panel fits in `availableSize`.
    public init(groups: [ShortcutGroup], availableSize: CGSize) {
        let maxBodyHeight = max(availableSize.height - PanelMetrics.chromeHeight, PanelMetrics.rowHeight)
        let maxColumns = Int(
            (availableSize.width - 2 * PanelMetrics.padding + PanelMetrics.columnSpacing)
                / (PanelMetrics.columnWidth + PanelMetrics.columnSpacing)
        )
        let plan = ColumnPlanner.plan(
            heights: groups.map { Double(PanelMetrics.groupHeight(rowCount: $0.shortcuts.count)) },
            spacing: Double(PanelMetrics.groupSpacing),
            maxColumns: max(1, maxColumns),
            maxHeight: Double(maxBodyHeight)
        )
        columns = plan.columns.map { Array(groups[$0]) }
        contentHeight = CGFloat(plan.height)
        needsScrolling = contentHeight > maxBodyHeight

        let columnCount = CGFloat(max(columns.count, 1))
        let width = 2 * PanelMetrics.padding
            + columnCount * PanelMetrics.columnWidth
            + (columnCount - 1) * PanelMetrics.columnSpacing
        panelSize = CGSize(
            width: width,
            height: PanelMetrics.chromeHeight + min(contentHeight, maxBodyHeight)
        )
    }
}
