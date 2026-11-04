internal import AemiMermaidScene
internal import AemiMermaidSyntax

extension FlowLayoutRun {
    private mutating func renumber() {
        for layer in graph.layers {
            for (index, node) in layer.enumerated() { graph.position[Int(node)] = Int32(index) }
        }
    }

    /// The crossings between rank `rank` and the one below: the inversions among the lower ends of the edges taken in the order of their upper ends, counted with a
    /// Fenwick tree. O(edges log nodes).
    private func crossings(below rank: Int) -> Int {
        guard rank + 1 < graph.layers.count else { return 0 }
        var sequence: [Int32] = []
        for node in graph.layers[rank] {
            let ends = graph.lower[Int(node)].map { graph.position[Int($0)] }.sorted()
            sequence.append(contentsOf: ends)
        }
        var tree = [Int](repeating: 0, count: graph.layers[rank + 1].count + 2)
        var total = 0
        for (seen, value) in sequence.enumerated() {
            var index = Int(value) + 1
            var notGreater = 0
            while index > 0 {
                notGreater += tree[index]
                index -= index & -index
            }
            total += seen - notGreater
            index = Int(value) + 1
            while index < tree.count {
                tree[index] += 1
                index += index & -index
            }
        }
        return total
    }

    private func totalCrossings() -> Int {
        var total = 0
        for rank in 0 ..< graph.layers.count { total += crossings(below: rank) }
        return total
    }

    /// Phase 4: sweeps down and up, each rank sorted by the median position of its neighbours on the rank just swept, then a pass of swaps of adjacent nodes
    /// that remove crossings. A fixed number of sweeps, the best order kept. O(sweeps x (nodes + edges) log).
    mutating func orderNodes() {
        renumber()
        var best = graph.layers
        var bestCrossings = totalCrossings()
        var sweep = 0
        while sweep < 24, bestCrossings > 0 {
            let down = sweep % 2 == 0
            let ranks =
                down
                ? Array(1 ..< Swift.max(1, graph.layers.count))
                : Array((0 ..< Swift.max(0, graph.layers.count - 1)).reversed())
            for rank in ranks { sortByMedian(rank, neighbours: down ? graph.upper : graph.lower) }
            transpose()
            let now = totalCrossings()
            if now < bestCrossings {
                bestCrossings = now
                best = graph.layers
            }
            sweep += 1
        }
        graph.layers = best
        renumber()
    }

    private mutating func sortByMedian(_ rank: Int, neighbours: [[Int32]]) {
        var keyed: [(key: Int, old: Int32, node: Int32)] = []
        keyed.reserveCapacity(graph.layers[rank].count)
        for node in graph.layers[rank] {
            let positions = neighbours[Int(node)].map { Int(graph.position[Int($0)]) }.sorted()
            let key: Int
            if positions.isEmpty {
                key = Int(graph.position[Int(node)]) * 2
            } else if positions.count % 2 == 1 {
                key = positions[positions.count / 2] * 2
            } else {
                key = positions[positions.count / 2 - 1] + positions[positions.count / 2]
            }
            keyed.append((key, graph.position[Int(node)], node))
        }
        keyed.sort { ($0.key, $0.old) < ($1.key, $1.old) }
        graph.layers[rank] = keyed.map(\.node)
        for (index, node) in graph.layers[rank].enumerated() { graph.position[Int(node)] = Int32(index) }
    }

    /// Crossings between the edges of `left` and `right` towards the neighbours in `neighbours`, as they stand.
    private func crossingPairs(_ left: Int32, _ right: Int32, _ neighbours: [[Int32]]) -> Int {
        var count = 0
        for a in neighbours[Int(left)] {
            for b in neighbours[Int(right)] where graph.position[Int(a)] > graph.position[Int(b)] { count += 1 }
        }
        return count
    }

    private mutating func transpose() {
        for rank in 0 ..< graph.layers.count {
            var improved = true
            var rounds = 0
            while improved, rounds < 3 {
                improved = false
                rounds += 1
                var index = 0
                while index + 1 < graph.layers[rank].count {
                    let left = graph.layers[rank][index]
                    let right = graph.layers[rank][index + 1]
                    let straight = crossingPairs(left, right, graph.upper) + crossingPairs(left, right, graph.lower)
                    let swapped = crossingPairs(right, left, graph.upper) + crossingPairs(right, left, graph.lower)
                    if swapped < straight {
                        graph.layers[rank].swapAt(index, index + 1)
                        graph.position[Int(left)] = Int32(index + 1)
                        graph.position[Int(right)] = Int32(index)
                        improved = true
                    }
                    index += 1
                }
            }
        }
    }
}
