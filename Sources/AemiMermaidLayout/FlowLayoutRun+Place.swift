internal import AemiMermaidScene
internal import AemiMermaidSyntax

extension FlowLayoutRun {
    /// The smallest sum of squares fit of positions `target` to a non-decreasing sequence, by pooling adjacent violators: a stack of blocks, each a sum and a count.
    /// O(n).
    private static func pool(_ target: [Double]) -> [Double] {
        var sums: [Double] = []
        var counts: [Int] = []
        for value in target {
            sums.append(value)
            counts.append(1)
            while sums.count > 1,
                sums[sums.count - 2] / Double(counts[counts.count - 2]) > sums[sums.count - 1]
                    / Double(counts[counts.count - 1])
            {
                let sum = sums.removeLast()
                let count = counts.removeLast()
                sums[sums.count - 1] += sum
                counts[counts.count - 1] += count
            }
        }
        var result: [Double] = []
        result.reserveCapacity(target.count)
        for (sum, count) in zip(sums, counts) {
            result.append(contentsOf: repeatElement(sum / Double(count), count: count))
        }
        return result
    }

    private func gap(_ left: Int32, _ right: Int32) -> Int32 {
        Int32(left >= Int32(graph.realCount) || right >= Int32(graph.realCount) ? 1 : metrics.nodeGap)
    }

    /// Puts the nodes of one rank where they are nearest their neighbours' centres without touching: the fit of `pool` to the wanted positions, less the room each
    /// node's predecessors need.
    private mutating func fit(_ rank: Int, towards neighbours: [[Int32]]) {
        let layer = graph.layers[rank]
        guard !layer.isEmpty else { return }
        var offset: [Int32] = [0]
        for index in 1 ..< layer.count {
            offset.append(offset[index - 1] + graph.sizeB[Int(layer[index - 1])] + gap(layer[index - 1], layer[index]))
        }
        var wanted: [Double] = []
        for (index, node) in layer.enumerated() {
            let near = neighbours[Int(node)]
            // The centre is a whole cell, `(size - 1) / 2` in integers, as `FlowGraph.center` says: the same half here, or a chain drifts a cell a rank.
            let size = Double((graph.sizeB[Int(node)] - 1) / 2)
            let desired: Double
            if near.isEmpty {
                desired = Double(graph.posB[Int(node)])
            } else {
                var sum = 0.0
                for other in near { sum += Double(graph.center(other)) }
                desired = sum / Double(near.count) - size
            }
            wanted.append(desired - Double(offset[index]))
        }
        let fitted = Self.pool(wanted)
        var previousEnd = Int32.min
        for (index, node) in layer.enumerated() {
            var place = Int32(fitted[index].rounded()) + offset[index]
            if index > 0 { place = Swift.max(place, previousEnd + gap(layer[index - 1], node)) }
            graph.posB[Int(node)] = place
            previousEnd = place + graph.sizeB[Int(node)]
        }
    }

    /// Phase 5: the first positions pack each rank to the left; then sweeps down and up fit each rank to the one before it.
    mutating func placeNodes() {
        for layer in graph.layers {
            var cursor: Int32 = 0
            for (index, node) in layer.enumerated() {
                if index > 0 { cursor += gap(layer[index - 1], node) }
                graph.posB[Int(node)] = cursor
                cursor += graph.sizeB[Int(node)]
            }
        }
        for pass in 0 ..< 8 {
            if pass % 2 == 0 {
                for rank in 1 ..< Swift.max(1, graph.layers.count) { fit(rank, towards: graph.upper) }
            } else {
                for rank in (0 ..< Swift.max(0, graph.layers.count - 1)).reversed() { fit(rank, towards: graph.lower) }
            }
        }
        let low = graph.posB.min() ?? 0
        for node in 0 ..< graph.count { graph.posB[node] -= low }
        var high: Int32 = 0
        for node in 0 ..< graph.count { high = Swift.max(high, graph.posB[node] + graph.sizeB[node]) }
        // A node that points at itself loops out beside its far side, which may be the last node's.
        extent.b = high + (graph.chains.contains { $0.count >= 2 && $0[0] == $0[$0.count - 1] } ? 2 : 0)
    }
}
