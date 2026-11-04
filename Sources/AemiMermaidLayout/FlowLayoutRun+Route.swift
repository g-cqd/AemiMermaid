internal import AemiMermaidScene
internal import AemiMermaidSyntax

extension FlowLayoutRun {
    private func labelExtent(_ edge: Int) -> Int {
        let label = diagram.edges[edge].label
        guard !label.isEmpty else { return 0 }
        let lines = LabelLines(diagram.labels.slice(label), maxColumns: metrics.maxLabelColumns, metrics: metrics)
        return diagram.direction.isVertical ? lines.lines.count : lines.width + 2
    }

    /// Phase 6: the lanes each channel between two ranks needs, and with them where each rank starts along the rank axis.
    ///
    /// A hop of an edge from rank r to r+1 that changes order position needs a horizontal run (a lane) in the channel below r; runs that overlap take different
    /// lanes, found by colouring the intervals greedily from the left. The channel is: rows for the label, one row for each lane, one for the arrow.
    mutating func planChannels() {
        let rankCount = graph.layers.count
        var hops = [[(edge: Int, hop: Int, low: Int32, high: Int32)]](repeating: [], count: rankCount)
        hopLane = graph.chains.map { [Int](repeating: -1, count: Swift.max(0, $0.count - 1)) }
        // The label of each edge's first hop gets a slot in its channel: a row of its own across, a column of its own when ranks run left to right, so labels
        // never meet. `slot` is where it starts among the stub rows, `stub` how many rows there are before the lanes.
        var stub = [Int](repeating: 1, count: rankCount)
        var used = [Int](repeating: 0, count: rankCount)
        labelSlot = [Int](repeating: 0, count: graph.chains.count)
        for (edge, chain) in graph.chains.enumerated() where chain.count >= 2 && chain[0] != chain[chain.count - 1] {
            for hop in 0 ..< (chain.count - 1) {
                let from = graph.center(chain[hop])
                let to = graph.center(chain[hop + 1])
                let rank = Int(graph.rank[Int(chain[hop])])
                if from != to { hops[rank].append((edge, hop, Swift.min(from, to), Swift.max(from, to))) }
                if hop == 0, labelExtent(edge) > 0 {
                    if diagram.direction.isVertical {
                        labelSlot[edge] = used[rank]
                        used[rank] += labelExtent(edge)
                    } else {
                        labelSlot[edge] = used[rank]
                        used[rank] += 1
                        stub[rank] = Swift.max(stub[rank], labelExtent(edge))
                    }
                }
            }
        }
        lanes = []
        for rank in 0 ..< rankCount {
            var laneEnd: [Int32] = []
            for run in hops[rank].sorted(by: { ($0.low, $0.high, $0.edge) < ($1.low, $1.high, $1.edge) }) {
                var lane = 0
                while lane < laneEnd.count, laneEnd[lane] + 2 > run.low { lane += 1 }
                if lane == laneEnd.count { laneEnd.append(run.high) } else { laneEnd[lane] = run.high }
                hopLane[run.edge][run.hop] = lane
            }
            lanes.append(laneEnd.count)
        }
        if diagram.direction.isVertical {
            for rank in 0 ..< rankCount { stub[rank] = Swift.max(stub[rank], used[rank]) }
        }
        stubRows = stub
        var cursor: Int32 = 0
        rankStart = []
        rankSize = []
        channel = []
        for rank in 0 ..< rankCount {
            var size: Int32 = 0
            for node in graph.layers[rank] { size = Swift.max(size, graph.sizeA[Int(node)]) }
            if size == 0 { size = 1 }
            rankStart.append(cursor)
            rankSize.append(size)
            let height = Int32(stub[rank] + lanes[rank] + 1 + metrics.rankGap)
            channel.append(height)
            cursor += size + (rank + 1 < rankCount ? height : 0)
            for node in graph.layers[rank] where graph.sizeA[Int(node)] > 0 { graph.posA[Int(node)] = rankStart[rank] }
        }
        // A node that points at itself loops out through the channel after its rank, which the last rank does not have.
        extent.a = cursor + (graph.chains.contains { $0.count >= 2 && $0[0] == $0[$0.count - 1] } ? 3 : 0)
    }

    private func simplify(_ points: [(a: Int32, b: Int32)]) -> [(a: Int32, b: Int32)] {
        var result: [(a: Int32, b: Int32)] = []
        for point in points {
            if let last = result.last, last == point { continue }
            if result.count >= 2 {
                let before = result[result.count - 2]
                let last = result[result.count - 1]
                if (before.a == last.a && last.a == point.a) || (before.b == last.b && last.b == point.b) {
                    result.removeLast()
                }
            }
            result.append(point)
        }
        return result
    }

    /// Phase 7: every edge as a run of points joined by segments along the two axes.
    mutating func routeEdges() {
        routes = []
        labelAt = []
        for (edge, chain) in graph.chains.enumerated() {
            var points: [(a: Int32, b: Int32)] = []
            var label: (a: Int32, b: Int32)?
            if chain.count >= 2, chain[0] == chain[chain.count - 1] {
                let node = Int(chain[0])
                let end = graph.posA[node] + graph.sizeA[node]
                let side = graph.posB[node] + graph.sizeB[node] - 1
                points = [(end - 2, side), (end - 2, side + 1), (end, side + 1), (end, side - 1)]
                label = (end, side + 2)
            } else {
                for hop in 0 ..< (chain.count - 1) {
                    let from = chain[hop]
                    let to = chain[hop + 1]
                    let rank = Int(graph.rank[Int(from)])
                    let fromB = graph.center(from)
                    let toB = graph.center(to)
                    let channelStart = rankStart[rank] + rankSize[rank]
                    let leave: Int32 =
                        from < Int32(graph.realCount)
                        ? graph.posA[Int(from)] + graph.sizeA[Int(from)] - 1 : rankStart[rank]
                    let arrive: Int32 = to < Int32(graph.realCount) ? graph.posA[Int(to)] - 1 : rankStart[rank + 1]
                    points.append((leave, fromB))
                    if hopLane[edge][hop] >= 0 {
                        let row = channelStart + Int32(stubRows[rank]) + Int32(hopLane[edge][hop])
                        points.append((row, fromB))
                        points.append((row, toB))
                    }
                    points.append((arrive, toB))
                    if hop == 0, !diagram.edges[edge].label.isEmpty {
                        label =
                            diagram.direction.isVertical
                            ? (channelStart + Int32(labelSlot[edge]), fromB + 2)
                            : (channelStart + 1, fromB - 1 - Int32(labelSlot[edge]))
                    }
                }
            }
            routes.append(simplify(points))
            labelAt.append(label)
        }
    }
}
