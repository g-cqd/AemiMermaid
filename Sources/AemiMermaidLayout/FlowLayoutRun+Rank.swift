internal import AemiMermaidSyntax

extension FlowLayoutRun {
    /// The nodes an edge joins, in the direction it is laid out: turned round if it was reversed to break a cycle.
    func ends(of edge: Int) -> (from: Int32, to: Int32) {
        let value = diagram.edges[edge]
        return graph.reversed[edge] ? (value.to, value.from) : (value.from, value.to)
    }

    /// Phase 1: a depth-first walk with an explicit stack; an edge that reaches a node still on the stack closes a cycle, and is turned round. O(nodes + edges).
    mutating func breakCycles() {
        let nodeCount = diagram.nodes.count
        let edges = diagram.edges
        graph.reversed = [Bool](repeating: false, count: edges.count)
        var start = [Int](repeating: 0, count: nodeCount + 1)
        for edge in edges where edge.from != edge.to { start[Int(edge.from) + 1] += 1 }
        for node in 0 ..< nodeCount { start[node + 1] += start[node] }
        var fill = start
        var out = [Int32](repeating: 0, count: start[nodeCount])
        for (index, edge) in edges.enumerated() where edge.from != edge.to {
            out[fill[Int(edge.from)]] = Int32(index)
            fill[Int(edge.from)] += 1
        }
        var color = [UInt8](repeating: 0, count: nodeCount)
        var next = start
        var stack: [Int32] = []
        for root in 0 ..< nodeCount where color[root] == 0 {
            color[root] = 1
            stack.append(Int32(root))
            while let node = stack.last {
                let u = Int(node)
                if next[u] < start[u + 1] {
                    let edge = Int(out[next[u]])
                    next[u] += 1
                    let v = Int(edges[edge].to)
                    if color[v] == 1 {
                        graph.reversed[edge] = true
                    } else if color[v] == 0 {
                        color[v] = 1
                        stack.append(Int32(v))
                    }
                } else {
                    color[u] = 2
                    stack.removeLast()
                }
            }
        }
    }

    /// Phase 2: each node's rank is the longest path to it, each edge asking for at least its length. Kahn's order, O(nodes + edges).
    mutating func rankNodes() {
        let nodeCount = diagram.nodes.count
        var start = [Int](repeating: 0, count: nodeCount + 1)
        var indegree = [Int](repeating: 0, count: nodeCount)
        for index in diagram.edges.indices {
            let (from, to) = ends(of: index)
            if from == to { continue }
            start[Int(from) + 1] += 1
            indegree[Int(to)] += 1
        }
        for node in 0 ..< nodeCount { start[node + 1] += start[node] }
        var fill = start
        var out = [Int32](repeating: 0, count: start[nodeCount])
        for index in diagram.edges.indices {
            let (from, to) = ends(of: index)
            if from == to { continue }
            out[fill[Int(from)]] = Int32(index)
            fill[Int(from)] += 1
        }
        var queue: [Int32] = (0 ..< nodeCount).filter { indegree[$0] == 0 }.map { Int32($0) }
        var head = 0
        while head < queue.count {
            let u = Int(queue[head])
            head += 1
            for slot in start[u] ..< start[u + 1] {
                let edge = Int(out[slot])
                let v = Int(ends(of: edge).to)
                graph.rank[v] = Swift.max(graph.rank[v], graph.rank[u] + Int32(diagram.edges[edge].length))
                indegree[v] -= 1
                if indegree[v] == 0 { queue.append(Int32(v)) }
            }
        }
    }

    /// Phase 3: a virtual node on each rank an edge crosses, so every edge is a chain of single steps. The number of them is bounded by `limits.maxVirtualNodes`.
    mutating func addVirtualNodes() {
        var virtual = 0
        graph.chains.reserveCapacity(diagram.edges.count)
        for index in diagram.edges.indices {
            let (from, to) = ends(of: index)
            var chain = [from]
            if from == to {
                chain.append(to)
            } else {
                let low = Int(graph.rank[Int(from)])
                let high = Int(graph.rank[Int(to)])
                virtual += Swift.max(0, high - low - 1)
                if virtual > limits.maxVirtualNodes {
                    refusal = .virtualNodes(virtual)
                    return
                }
                if high - low > 1 {
                    for rank in (low + 1) ..< high { chain.append(graph.addNode(rank: rank, sizeA: 0, sizeB: 1)) }
                }
                chain.append(to)
            }
            graph.chains.append(chain)
        }
        let rankCount = (graph.rank.max().map { Int($0) } ?? 0) + 1
        graph.layers = [[Int32]](repeating: [], count: rankCount)
        for node in 0 ..< graph.count { graph.layers[Int(graph.rank[node])].append(Int32(node)) }
        for chain in graph.chains where chain.count >= 2 && chain[0] != chain[chain.count - 1] {
            for pair in 0 ..< (chain.count - 1) {
                graph.lower[Int(chain[pair])].append(chain[pair + 1])
                graph.upper[Int(chain[pair + 1])].append(chain[pair])
            }
        }
    }
}
