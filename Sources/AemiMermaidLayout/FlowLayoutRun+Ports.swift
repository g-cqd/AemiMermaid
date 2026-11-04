internal import AemiMermaidSyntax

extension FlowLayoutRun {
    /// Phase 5b: the edges that leave a node, and those that arrive at it, each get a column of their own (a port), so they are separate lines and not one.
    ///
    /// Without ports every edge uses the centre of its node: two edges between the same pair are drawn on top of each other, and two edges into one node merge into one thick arrow. The
    /// departures of a node are put in the order of the columns their next hop is in, and so are the arrivals by where they come from, so the lines do not cross. Up to two cells either side
    /// of the centre per step, as far as the node is wide; a node too narrow for it, and a diamond (whose outline meets a line only at its tip), keep one column.
    mutating func assignPorts() {
        portStart = [Int32](repeating: 0, count: graph.chains.count)
        portEnd = [Int32](repeating: 0, count: graph.chains.count)
        var departures: [Int32: [Int]] = [:]
        var arrivals: [Int32: [Int]] = [:]
        for (edge, chain) in graph.chains.enumerated() where chain.count >= 2 && chain[0] != chain[chain.count - 1] {
            departures[chain[0], default: []].append(edge)
            arrivals[chain[chain.count - 1], default: []].append(edge)
        }
        for (node, edges) in departures {
            let ports = spread(edges, at: node) { graph.center(graph.chains[$0][1]) }
            for (edge, shift) in ports { portStart[edge] = shift }
        }
        for (node, edges) in arrivals {
            let ports = spread(edges, at: node) { graph.center(graph.chains[$0][graph.chains[$0].count - 2]) }
            for (edge, shift) in ports { portEnd[edge] = shift }
        }
    }

    /// The columns of `edges`, all at `node` on one side, in the order of `neighbour`: pairs of an edge and its distance from the node's centre.
    private func spread(_ edges: [Int], at node: Int32, neighbour: (Int) -> Int32) -> [(Int, Int32)] {
        let count = Int32(edges.count)
        guard count >= 2, Int(node) < diagram.nodes.count, diagram.nodes[Int(node)].shape != .diamond else { return [] }
        let half = Swift.min(2, (graph.sizeB[Int(node)] - 3) / (2 * (count - 1)))
        guard half >= 1 else { return [] }
        let ordered = edges.sorted { (neighbour($0), $0) < (neighbour($1), $1) }
        return ordered.enumerated().map { ($1, (2 * Int32($0) - (count - 1)) * half) }
    }

    /// The column an edge uses at the start of hop `hop` (its first hop leaves from a port) and at its end (its last hop arrives at one).
    func column(_ edge: Int, hop: Int, ends: Bool) -> Int32 {
        let chain = graph.chains[edge]
        let node = chain[ends ? hop + 1 : hop]
        if ends { return graph.center(node) + (hop == chain.count - 2 ? portEnd[edge] : 0) }
        return graph.center(node) + (hop == 0 ? portStart[edge] : 0)
    }
}
