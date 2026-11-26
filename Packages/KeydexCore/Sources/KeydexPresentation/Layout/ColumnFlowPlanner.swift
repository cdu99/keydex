/// Consecutive rows of one group placed in a column.
struct FlowSegment: Equatable {
    let group: Int
    let rows: Range<Int>
}

/// Flows groups of rows through columns like a newspaper: top to bottom, then left to right,
/// so menus stay in the app's order. A long group may continue in the next column (with its
/// title repeated), which packs far better than keeping each group whole.
enum ColumnFlowPlanner {
    struct Metrics {
        var titleHeight: Int
        var rowHeight: Int
        var groupSpacing: Int
        /// A split never leaves fewer rows than this on either side.
        var minimumRowsPerSegment = 2
    }

    struct Plan: Equatable {
        let columns: [[FlowSegment]]
        /// Height of the tallest column.
        let height: Int
    }

    /// Uses as few columns as possible to stay within `maxHeight`, balanced so they have
    /// similar heights. If `maxColumns` is not enough, returns the tightest `maxColumns` flow.
    static func plan(rowCounts: [Int], metrics: Metrics, maxColumns: Int, maxHeight: Int) -> Plan {
        guard rowCounts.contains(where: { $0 > 0 }) else { return Plan(columns: [], height: 0) }
        var plan = tightestFlow(rowCounts: rowCounts, metrics: metrics, columns: 1)
        for columnCount in 1...max(1, maxColumns) {
            plan = tightestFlow(rowCounts: rowCounts, metrics: metrics, columns: columnCount)
            if plan.height <= maxHeight { break }
        }
        return plan
    }

    /// Smallest column height whose flow needs at most `columns` columns (binary search:
    /// a taller column height never needs more columns).
    static func tightestFlow(rowCounts: [Int], metrics: Metrics, columns: Int) -> Plan {
        var low = metrics.titleHeight + metrics.minimumRowsPerSegment * metrics.rowHeight
        var high = max(low, flow(rowCounts: rowCounts, metrics: metrics, columnHeight: .max).height)
        while low < high {
            let middle = (low + high) / 2
            if flow(rowCounts: rowCounts, metrics: metrics, columnHeight: middle).columns.count <= columns {
                high = middle
            } else {
                low = middle + 1
            }
        }
        return flow(rowCounts: rowCounts, metrics: metrics, columnHeight: low)
    }

    /// Greedy fill of columns of at most `columnHeight`.
    static func flow(rowCounts: [Int], metrics: Metrics, columnHeight: Int) -> Plan {
        var builder = FlowBuilder(metrics: metrics, columnHeight: columnHeight)
        for (group, rowCount) in rowCounts.enumerated() where rowCount > 0 {
            builder.place(group: group, rowCount: rowCount)
        }
        return builder.plan
    }
}

/// Mutable state of one greedy flow.
private struct FlowBuilder {
    let metrics: ColumnFlowPlanner.Metrics
    let columnHeight: Int
    private var columns: [[FlowSegment]] = [[]]
    private var heights: [Int] = [0]

    init(metrics: ColumnFlowPlanner.Metrics, columnHeight: Int) {
        self.metrics = metrics
        self.columnHeight = columnHeight
    }

    var plan: ColumnFlowPlanner.Plan {
        ColumnFlowPlanner.Plan(columns: columns, height: heights.max() ?? 0)
    }

    mutating func place(group: Int, rowCount: Int) {
        let minimum = metrics.minimumRowsPerSegment
        var start = 0
        while start < rowCount {
            let remaining = rowCount - start
            let fitting = rowsFittingInCurrentColumn()
            if fitting >= remaining {
                append(group: group, rows: start..<rowCount)
                return
            }
            // Split only if both parts keep enough rows.
            let splitAt = min(fitting, remaining - minimum)
            if splitAt >= minimum {
                append(group: group, rows: start..<(start + splitAt))
                start += splitAt
            } else if currentColumnIsEmpty {
                // Column too short for the minimum: place what we can so the flow progresses.
                let forced = max(1, min(fitting, remaining))
                append(group: group, rows: start..<(start + forced))
                start += forced
            }
            if start < rowCount { startNewColumn() }
        }
    }

    private var currentColumnIsEmpty: Bool { columns[columns.count - 1].isEmpty }

    private var spacingBeforeNextSegment: Int { currentColumnIsEmpty ? 0 : metrics.groupSpacing }

    private func rowsFittingInCurrentColumn() -> Int {
        guard columnHeight != .max else { return .max }
        let available = columnHeight - heights[heights.count - 1] - spacingBeforeNextSegment - metrics.titleHeight
        return max(0, available / metrics.rowHeight)
    }

    private mutating func append(group: Int, rows: Range<Int>) {
        heights[heights.count - 1] += spacingBeforeNextSegment + metrics.titleHeight + rows.count * metrics.rowHeight
        columns[columns.count - 1].append(FlowSegment(group: group, rows: rows))
    }

    private mutating func startNewColumn() {
        columns.append([])
        heights.append(0)
    }
}
