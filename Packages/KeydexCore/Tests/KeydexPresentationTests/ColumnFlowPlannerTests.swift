@testable import KeydexPresentation
import Testing

@Suite("Flowing menus through columns")
struct ColumnFlowPlannerTests {
    /// Round numbers: a title is 10 pt, a row 10 pt, no spacing.
    private let metrics = ColumnFlowPlanner.Metrics(titleHeight: 10, rowHeight: 10, groupSpacing: 0)

    @Test("Everything stays in one column when it fits")
    func singleColumn() {
        let plan = ColumnFlowPlanner.plan(rowCounts: [3, 2], metrics: metrics, maxColumns: 4, maxHeight: 100)
        #expect(plan.columns == [[FlowSegment(group: 0, rows: 0..<3), FlowSegment(group: 1, rows: 0..<2)]])
        #expect(plan.height == 70)
    }

    @Test("A tall menu continues in the next column, keeping the order")
    func continuation() {
        let plan = ColumnFlowPlanner.plan(rowCounts: [10], metrics: metrics, maxColumns: 3, maxHeight: 70)
        #expect(plan.columns == [
            [FlowSegment(group: 0, rows: 0..<5)],
            [FlowSegment(group: 0, rows: 5..<10)],
        ])
        #expect(plan.height == 60, "Balanced: 5 rows + title in each column")
    }

    @Test("Uses the fewest columns that fit, balanced")
    func fewestBalancedColumns() {
        let plan = ColumnFlowPlanner.plan(rowCounts: [4, 4, 4, 4], metrics: metrics, maxColumns: 4, maxHeight: 100)
        #expect(plan.columns.count == 2)
        #expect(plan.height == 100)
    }

    @Test("A split never leaves a single row on either side")
    func noOrphanRows() {
        // From 3 rows per column up; with only 2, a 3-row menu cannot be split cleanly.
        for height in stride(from: 40, through: 200, by: 10) {
            let plan = ColumnFlowPlanner.flow(rowCounts: [3, 7, 5, 2], metrics: metrics, columnHeight: height)
            let segments = plan.columns.flatMap { $0 }
            let splitGroups = Dictionary(grouping: segments, by: \.group).filter { $0.value.count > 1 }
            for (_, parts) in splitGroups {
                #expect(parts.allSatisfy { $0.rows.count >= 2 }, "height \(height): \(parts)")
            }
        }
    }

    @Test("Every row is placed exactly once, in order")
    func completeness() {
        let rowCounts = [5, 0, 28, 15, 27, 18, 21, 1]
        let plan = ColumnFlowPlanner.plan(rowCounts: rowCounts, metrics: metrics, maxColumns: 4, maxHeight: 400)
        let segments = plan.columns.flatMap { $0 }
        for (group, count) in rowCounts.enumerated() {
            let rows = segments.filter { $0.group == group }.flatMap { Array($0.rows) }
            #expect(rows == Array(0..<count), "group \(group)")
        }
        #expect(segments.map(\.group) == segments.map(\.group).sorted(), "Groups stay in order")
    }

    @Test("When the maximum number of columns is not enough, the flow is taller than allowed")
    func overflow() {
        let plan = ColumnFlowPlanner.plan(rowCounts: [30, 30], metrics: metrics, maxColumns: 2, maxHeight: 100)
        #expect(plan.columns.count == 2)
        #expect(plan.height > 100)
    }

    @Test("Spacing counts between segments of a column, not before the first one")
    func spacing() {
        let spaced = ColumnFlowPlanner.Metrics(titleHeight: 10, rowHeight: 10, groupSpacing: 5)
        let plan = ColumnFlowPlanner.plan(rowCounts: [2, 2], metrics: spaced, maxColumns: 1, maxHeight: 1000)
        #expect(plan.height == 65)
    }

    @Test("No rows, no columns")
    func empty() {
        #expect(ColumnFlowPlanner.plan(rowCounts: [0, 0], metrics: metrics, maxColumns: 3, maxHeight: 100).columns.isEmpty)
    }
}
