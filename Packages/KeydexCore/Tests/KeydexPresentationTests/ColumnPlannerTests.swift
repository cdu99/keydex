@testable import KeydexPresentation
import Testing

@Suite("Splitting groups into columns")
struct ColumnPlannerTests {
    @Test("Everything stays in one column when it fits")
    func singleColumn() {
        let plan = ColumnPlanner.plan(heights: [100, 50, 80], spacing: 10, maxColumns: 4, maxHeight: 500)
        #expect(plan.columns == [0..<3])
        #expect(plan.height == 250)
    }

    @Test("Uses the fewest columns that fit the height, keeping the order")
    func fewestColumns() {
        let plan = ColumnPlanner.plan(heights: [100, 100, 100, 100], spacing: 0, maxColumns: 4, maxHeight: 250)
        #expect(plan.columns == [0..<2, 2..<4])
        #expect(plan.height == 200)
    }

    @Test("Balances columns instead of filling the first one to the brim")
    func balanced() {
        let plan = ColumnPlanner.balancedPartition(heights: [10, 10, 10, 10, 60], spacing: 0, columns: 2)
        #expect(plan.columns == [0..<4, 4..<5])
        #expect(plan.height == 60)
    }

    @Test("When nothing fits, splits over the maximum number of columns")
    func overflow() {
        let plan = ColumnPlanner.plan(heights: [300, 300, 300], spacing: 0, maxColumns: 2, maxHeight: 200)
        #expect(plan.columns.count == 2)
        #expect(plan.height == 600)
    }

    @Test("Never uses more columns than blocks")
    func moreColumnsThanBlocks() {
        let plan = ColumnPlanner.plan(heights: [500, 500], spacing: 0, maxColumns: 6, maxHeight: 100)
        #expect(plan.columns == [0..<1, 1..<2])
    }

    @Test("Spacing counts between blocks of a column, not before the first one")
    func spacing() {
        let plan = ColumnPlanner.plan(heights: [40, 40], spacing: 20, maxColumns: 1, maxHeight: 1000)
        #expect(plan.height == 100)
    }

    @Test("No blocks, no columns")
    func empty() {
        #expect(ColumnPlanner.plan(heights: [], spacing: 10, maxColumns: 3, maxHeight: 100).columns.isEmpty)
    }
}
