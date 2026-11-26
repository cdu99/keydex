/// Splits a sequence of blocks into columns, keeping their order (top to bottom, then left
/// to right, like a newspaper) so menus stay where the user expects them.
enum ColumnPlanner {
    struct Plan: Equatable {
        /// Indices of the blocks in each column.
        let columns: [Range<Int>]
        /// Height of the tallest column.
        let height: Double
    }

    /// Uses as few columns as possible while staying within `maxHeight`. If even
    /// `maxColumns` columns are too tall, returns the most balanced `maxColumns` split.
    static func plan(heights: [Double], spacing: Double, maxColumns: Int, maxHeight: Double) -> Plan {
        guard !heights.isEmpty else { return Plan(columns: [], height: 0) }
        let columnLimit = max(1, min(maxColumns, heights.count))
        var plan = balancedPartition(heights: heights, spacing: spacing, columns: 1)
        for columnCount in 1...columnLimit {
            plan = balancedPartition(heights: heights, spacing: spacing, columns: columnCount)
            if plan.height <= maxHeight { break }
        }
        return plan
    }

    /// Contiguous split into at most `columns` columns minimizing the tallest one.
    /// The optimum is the height of some contiguous run of blocks, so we binary-search
    /// the smallest such height a greedy fill can respect.
    static func balancedPartition(heights: [Double], spacing: Double, columns: Int) -> Plan {
        let candidates = contiguousRunHeights(heights, spacing: spacing).sorted()
        var low = 0
        var high = candidates.count - 1
        while low < high {
            let middle = (low + high) / 2
            if greedyFill(heights, spacing: spacing, limit: candidates[middle]).columns.count <= columns {
                high = middle
            } else {
                low = middle + 1
            }
        }
        return greedyFill(heights, spacing: spacing, limit: candidates[low])
    }

    private static func contiguousRunHeights(_ heights: [Double], spacing: Double) -> Set<Double> {
        var runs = Set<Double>()
        for start in heights.indices {
            var height = -spacing
            for end in start..<heights.count {
                height += heights[end] + spacing
                runs.insert(height)
            }
        }
        return runs
    }

    /// Fills columns in order, starting a new one when the next block would exceed `limit`.
    private static func greedyFill(_ heights: [Double], spacing: Double, limit: Double) -> Plan {
        var columns: [Range<Int>] = []
        var start = 0
        var columnHeight = 0.0
        var tallest = 0.0
        for (index, height) in heights.enumerated() {
            let grown = index == start ? height : columnHeight + spacing + height
            if grown > limit, index > start {
                columns.append(start..<index)
                tallest = max(tallest, columnHeight)
                start = index
                columnHeight = height
            } else {
                columnHeight = grown
            }
        }
        columns.append(start..<heights.count)
        tallest = max(tallest, columnHeight)
        return Plan(columns: columns, height: tallest)
    }
}
