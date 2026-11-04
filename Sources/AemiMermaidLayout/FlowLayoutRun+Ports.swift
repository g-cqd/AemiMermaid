internal import AemiMermaidSyntax

extension FlowLayoutRun {
    /// Phase 5b: edges between the same two nodes (a link and the link back, or two links the same way) leave and arrive in columns of their own, so they are two lines and not one.
    ///
    /// A node's edges otherwise all use its centre. Up to three edges between a pair are spread across the node's width, a cell or two apart, when both nodes are wide enough and neither
    /// is a diamond (whose outline only meets a line at its tip).
    mutating func assignPorts() {
        portShift = [Int32](repeating: 0, count: graph.chains.count)
        var groups: [UInt64: [Int]] = [:]
        for (edge, chain) in graph.chains.enumerated() where chain.count >= 2 && chain[0] != chain[chain.count - 1] {
            let (low, high) = (Swift.min(chain[0], chain[chain.count - 1]), Swift.max(chain[0], chain[chain.count - 1]))
            groups[UInt64(low) << 32 | UInt64(high), default: []].append(edge)
        }
        for (_, edges) in groups where edges.count >= 2 && edges.count <= 3 {
            let first = graph.chains[edges[0]]
            let (from, to) = (Int(first[0]), Int(first[first.count - 1]))
            guard from < diagram.nodes.count, to < diagram.nodes.count, diagram.nodes[from].shape != .diamond,
                diagram.nodes[to].shape != .diamond
            else { continue }
            let room = (Swift.min(graph.sizeB[from], graph.sizeB[to]) - 3) / 2
            let spread = Swift.min(2, room)
            guard spread >= 1 else { continue }
            // Two edges go either side of the centre, three also keep one on it.
            let shifts: [Int32] = edges.count == 2 ? [-spread, spread] : [-spread, 0, spread]
            for (index, edge) in edges.sorted().enumerated() { portShift[edge] = shifts[index] }
        }
    }

    /// The column an edge uses at the start of hop `hop` (its first hop leaves from a port) and at its end.
    func column(_ edge: Int, hop: Int, ends: Bool) -> Int32 {
        let chain = graph.chains[edge]
        let node = chain[ends ? hop + 1 : hop]
        let isPort = ends ? hop == chain.count - 2 : hop == 0
        return graph.center(node) + (isPort ? portShift[edge] : 0)
    }
}
