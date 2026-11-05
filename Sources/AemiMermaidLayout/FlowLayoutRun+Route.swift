internal import AemiMermaidScene
internal import AemiMermaidSyntax

extension FlowLayoutRun {
    private func labelExtent(_ edge: Int) -> Int {
        let label = diagram.edges[edge].label
        guard !label.isEmpty else { return 0 }
        let lines = LabelLines(diagram.labels.slice(label), maxColumns: metrics.maxLabelColumns, metrics: metrics)
        return diagram.direction.isVertical ? lines.lines.count : lines.width + 2
    }

    /// Where an edge's label goes, and the room it needs: beside the line on the side its edge turns to, or on the other side when that would be off the chart.
    private mutating func labelPlace(_ edge: Int, from: Int32, towardsLow: Bool, channelStart: Int32) -> (
        a: Int32, b: Int32
    ) {
        let width = Int32(labelWidth(edge))
        let slot = Int32(labelSlot[edge])
        let low = towardsLow
        if diagram.direction.isVertical {
            // Against its own line: right-aligned on the left of it, or starting just right of it. Its edge has a column of its own, so nothing is in the way.
            labelTrailing[edge] = low
            let b = low ? from - 1 : from + 2
            extent.b = Swift.max(extent.b, low ? from : b + width)
            overhang = Swift.max(overhang, low ? width + 1 - from : -b)
            return (channelStart + slot, b)
        }
        let b = low ? from - 1 - slot : from + 1 + slot
        extent.b = Swift.max(extent.b, b + 1)
        overhang = Swift.max(overhang, -b)
        return (channelStart + 1, b)
    }

    /// Whether the text of `edge`'s label, at `place` on the given side of its line, would sit on a vertical run of any other edge.
    private func labelCrosses(_ edge: Int, at place: (a: Int32, b: Int32), trailing: Bool) -> Bool {
        let width = Int32(labelWidth(edge))
        let (low, high) = trailing ? (place.b - width, place.b) : (place.b, place.b + width)
        for (other, route) in routes.enumerated() where other != edge {
            for (from, to) in zip(route, route.dropFirst()) where from.b == to.b && from.b >= low && from.b < high {
                if Swift.min(from.a, to.a) <= place.a && place.a <= Swift.max(from.a, to.a) { return true }
            }
        }
        return false
    }

    /// Once every edge is routed: a label that would sit on another edge's line goes to the other side of its own, if that side is clear.
    private mutating func clearLabels() {
        for edge in routes.indices {
            guard let place = labelAt[edge], !diagram.edges[edge].label.isEmpty,
                labelCrosses(edge, at: place, trailing: labelTrailing[edge])
            else { continue }
            let flipped = !labelTrailing[edge]
            let width = Int32(labelWidth(edge))
            let line = labelTrailing[edge] ? place.b + 1 : place.b - 2
            let moved = (a: place.a, b: flipped ? line - 1 : line + 2)
            guard !labelCrosses(edge, at: moved, trailing: flipped) else { continue }
            labelAt[edge] = moved
            labelTrailing[edge] = flipped
            extent.b = Swift.max(extent.b, flipped ? line : moved.b + width)
            overhang = Swift.max(overhang, flipped ? width + 1 - line : -moved.b)
        }
    }

    private func labelWidth(_ edge: Int) -> Int {
        LabelLines(
            diagram.labels.slice(diagram.edges[edge].label),
            maxColumns: metrics.maxLabelColumns,
            metrics: metrics
        )
        .width
    }

    /// The frames (clusters, with those that hold them) of the real nodes in each rank.
    private func frames(inRank rank: Int) -> Set<Int> {
        var found: Set<Int> = []
        for node in graph.layers[rank] where Int(node) < diagram.nodes.count {
            var cluster = Int(diagram.nodes[Int(node)].cluster)
            while cluster >= 0, found.insert(cluster).inserted { cluster = Int(diagram.clusters[cluster].parent) }
        }
        return found
    }

    /// How many frames end with `rank` or begin with the one after it.
    private func framesChanging(after rank: Int) -> Int {
        let here = frames(inRank: rank)
        let next = frames(inRank: rank + 1)
        return here.subtracting(next).count + next.subtracting(here).count
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
                let from = column(edge, hop: hop, ends: false)
                let to = column(edge, hop: hop, ends: true)
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
            // A frame is drawn two cells outside its nodes: the channel leaves room for the border of each frame that ends above it and each that begins below it.
            let frames = rank + 1 < rankCount ? 2 * framesChanging(after: rank) : 0
            let height = Int32(stub[rank] + lanes[rank] + 1 + metrics.rankGap + frames)
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
        labelTrailing = [Bool](repeating: false, count: graph.chains.count)
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
                    let fromB = column(edge, hop: hop, ends: false)
                    let toB = column(edge, hop: hop, ends: true)
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
                        // The label goes on the side its edge turns to: left of the line when the target is to the left (above it when the target is above).
                        let towardsLow = toB < fromB || (toB == fromB && portStart[edge] < 0)
                        label = labelPlace(edge, from: fromB, towardsLow: towardsLow, channelStart: channelStart)
                    }
                }
            }
            routes.append(simplify(points))
            labelAt.append(label)
        }
        if diagram.direction.isVertical { clearLabels() }
    }
}
