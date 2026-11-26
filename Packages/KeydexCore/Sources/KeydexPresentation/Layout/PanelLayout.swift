import CoreGraphics
import KeydexDomain

/// How the groups of a catalog are arranged in the panel, and the resulting panel size.
public struct PanelLayout: Equatable, Sendable {
    /// A menu, or the part of it shown in one column.
    public struct Block: Equatable, Sendable, Identifiable {
        public let title: String
        /// True when this block continues a menu started in the previous column.
        public let isContinuation: Bool
        public let shortcuts: [Shortcut]
        public let id: String
    }

    public let columns: [[Block]]
    public let columnWidth: CGFloat
    /// Height of the column area if it were fully shown.
    public let contentHeight: CGFloat
    /// True when the content is taller than the screen allows and must scroll.
    public let needsScrolling: Bool
    public let panelSize: CGSize

    /// Arranges `groups` so the panel fits in `availableSize`: the widest columns that fit
    /// without scrolling, in as few columns as possible. Scrolls only as a last resort.
    public init(groups: [ShortcutGroup], availableSize: CGSize) {
        let widths = PanelMetrics.columnWidths
        let candidates = widths.lazy.map { Self(groups: groups, availableSize: availableSize, columnWidth: $0) }
        self = candidates.first { !$0.needsScrolling } ?? Self(
            groups: groups, availableSize: availableSize, columnWidth: widths[widths.count - 1]
        )
    }

    private init(groups: [ShortcutGroup], availableSize: CGSize, columnWidth: CGFloat) {
        let maxBodyHeight = max(availableSize.height - PanelMetrics.chromeHeight, PanelMetrics.rowHeight)
        let maxColumns = Int(
            (availableSize.width - 2 * PanelMetrics.padding + PanelMetrics.columnSpacing)
                / (columnWidth + PanelMetrics.columnSpacing)
        )
        let plan = ColumnFlowPlanner.plan(
            rowCounts: groups.map(\.shortcuts.count),
            metrics: PanelMetrics.flowMetrics,
            maxColumns: max(1, maxColumns),
            maxHeight: Int(maxBodyHeight)
        )
        columns = plan.columns.map { segments in
            segments.map { segment in
                let group = groups[segment.group]
                return Block(
                    title: group.title,
                    isContinuation: segment.rows.lowerBound > 0,
                    shortcuts: Array(group.shortcuts[segment.rows]),
                    id: "\(group.id)-\(segment.rows.lowerBound)"
                )
            }
        }
        self.columnWidth = columnWidth
        contentHeight = CGFloat(plan.height)
        needsScrolling = contentHeight > maxBodyHeight

        let columnCount = CGFloat(max(columns.count, 1))
        let width = 2 * PanelMetrics.padding
            + columnCount * columnWidth
            + (columnCount - 1) * PanelMetrics.columnSpacing
        panelSize = CGSize(
            width: width,
            height: PanelMetrics.chromeHeight + min(contentHeight, maxBodyHeight)
        )
    }
}
