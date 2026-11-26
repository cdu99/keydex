import CoreGraphics

/// Fixed dimensions of the shortcut panel.
///
/// Rows have a fixed height, so the size of every group is known before rendering. The
/// panel can then be laid out (and the window sized) in one pass, without measuring views.
public enum PanelMetrics {
    public static let padding: CGFloat = 18
    public static let headerHeight: CGFloat = 36
    public static let headerSpacing: CGFloat = 14
    /// Preferred column widths, widest first. Narrower columns are only used when the
    /// wide ones would not fit the screen, to fit more columns instead of scrolling.
    public static let columnWidths: [CGFloat] = [268, 236, 212]
    public static let columnSpacing: CGFloat = 22
    public static let groupSpacing: CGFloat = 14
    public static let groupTitleHeight: CGFloat = 20
    public static let rowHeight: CGFloat = 19
    public static let cornerRadius: CGFloat = 22
    /// Size of the panel when it shows a message instead of shortcuts.
    public static let messageSize = CGSize(width: 400, height: 190)

    static func groupHeight(rowCount: Int) -> CGFloat {
        groupTitleHeight + CGFloat(rowCount) * rowHeight
    }

    static let flowMetrics = ColumnFlowPlanner.Metrics(
        titleHeight: Int(groupTitleHeight),
        rowHeight: Int(rowHeight),
        groupSpacing: Int(groupSpacing)
    )

    /// Height taken by everything but the columns.
    static let chromeHeight: CGFloat = 2 * padding + headerHeight + headerSpacing
}
