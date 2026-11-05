internal import AemiMermaidSyntax

extension FlowLayoutRun {
    /// Phase 4b: the nodes of a cluster sit together in every rank, and clusters keep one order across ranks, so the frames drawn round them do not run into one another.
    ///
    /// The ordering above knows nothing of clusters. Each cluster is given a place, the mean of where its nodes stand (as a fraction of their rank), and each rank is sorted by the
    /// places of the clusters a node is in, outermost first, then by where the node stands: a node outside every cluster keeps its fraction as its place. O(nodes log nodes x depth).
    mutating func groupClusters() {
        guard !diagram.clusters.isEmpty else { return }
        let count = diagram.clusters.count
        var sum = [Double](repeating: 0, count: count)
        var members = [Double](repeating: 0, count: count)
        func fraction(_ node: Int32, in rank: Int) -> Double {
            (Double(graph.position[Int(node)]) + 0.5) / Double(graph.layers[rank].count)
        }
        for rank in graph.layers.indices {
            for node in graph.layers[rank] where Int(node) < diagram.nodes.count {
                var cluster = Int(diagram.nodes[Int(node)].cluster)
                while cluster >= 0 {
                    sum[cluster] += fraction(node, in: rank)
                    members[cluster] += 1
                    cluster = Int(diagram.clusters[cluster].parent)
                }
            }
        }
        let place = (0 ..< count).map { members[$0] > 0 ? sum[$0] / members[$0] : 0 }
        for rank in graph.layers.indices {
            var keyed: [(key: [Double], node: Int32)] = []
            keyed.reserveCapacity(graph.layers[rank].count)
            for node in graph.layers[rank] {
                var path: [Double] = []
                if Int(node) < diagram.nodes.count {
                    var cluster = Int(diagram.nodes[Int(node)].cluster)
                    while cluster >= 0 {
                        path.append(place[cluster])
                        cluster = Int(diagram.clusters[cluster].parent)
                    }
                    path.reverse()
                }
                path.append(fraction(node, in: rank))
                keyed.append((path, node))
            }
            keyed.sort { $0.key.lexicographicallyPrecedes($1.key) }
            graph.layers[rank] = keyed.map(\.node)
        }
        for layer in graph.layers {
            for (index, node) in layer.enumerated() { graph.position[Int(node)] = Int32(index) }
        }
    }

    /// Phase 5a: two siblings (clusters, or a cluster and a node, inside the same cluster or at the top) whose ranks overlap are pushed apart along the order axis until the frames
    /// round them clear each other. Placement fits nodes to their neighbours and does not know clusters; this is where a frame gets a place of its own.
    ///
    /// Siblings are taken left to right and each is moved just far enough from those before it that share a rank with it: O(siblings squared) for each cluster, bounded by the limits on
    /// clusters; the parent before the children, so a child moved with its parent is then separated from its own siblings.
    mutating func separateClusters() {
        guard !diagram.clusters.isEmpty else { return }
        let count = diagram.clusters.count
        var nodesIn = [[Int32]](repeating: [], count: count)
        var direct = [[Int32]](repeating: [], count: count + 1)  // the last slot: no cluster
        for node in 0 ..< diagram.nodes.count {
            var cluster = Int(diagram.nodes[node].cluster)
            direct[cluster >= 0 ? cluster : count].append(Int32(node))
            while cluster >= 0 {
                nodesIn[cluster].append(Int32(node))
                cluster = Int(diagram.clusters[cluster].parent)
            }
        }
        var children = [[Int]](repeating: [], count: count + 1)
        for (index, cluster) in diagram.clusters.enumerated() {
            children[cluster.parent >= 0 ? Int(cluster.parent) : count].append(index)
        }
        // Levels of frames inside each cluster, itself included: a frame is two cells out for each.
        var levels = [Int](repeating: 1, count: count)
        for index in (0 ..< count).reversed() where diagram.clusters[index].parent >= 0 {
            let parent = Int(diagram.clusters[index].parent)
            levels[parent] = Swift.max(levels[parent], levels[index] + 1)
        }
        var queue = [count]
        var head = 0
        while head < queue.count {
            let parent = queue[head]
            head += 1
            var items: [(nodes: [Int32], margin: Int32)] = direct[parent].map { ([$0], 0) }
            for child in children[parent] {
                items.append((nodesIn[child], Int32(2 * levels[child])))
                queue.append(child)
            }
            separate(&items)
        }
        let low = graph.posB.min() ?? 0
        for node in 0 ..< graph.count { graph.posB[node] -= low }
        var high: Int32 = 0
        for node in 0 ..< graph.count { high = Swift.max(high, graph.posB[node] + graph.sizeB[node]) }
        extent.b = high + (graph.chains.contains { $0.count >= 2 && $0[0] == $0[$0.count - 1] } ? 2 : 0)
    }

    private mutating func separate(_ items: inout [(nodes: [Int32], margin: Int32)]) {
        guard items.count >= 2 else { return }
        struct Box {
            var low: Int32
            var high: Int32
            var firstRank: Int32
            var lastRank: Int32
            var margin: Int32
        }
        func box(_ item: (nodes: [Int32], margin: Int32), _ graph: FlowGraph) -> Box {
            var result = Box(low: .max, high: .min, firstRank: .max, lastRank: .min, margin: item.margin)
            for node in item.nodes {
                result.low = Swift.min(result.low, graph.posB[Int(node)])
                result.high = Swift.max(result.high, graph.posB[Int(node)] + graph.sizeB[Int(node)])
                result.firstRank = Swift.min(result.firstRank, graph.rank[Int(node)])
                result.lastRank = Swift.max(result.lastRank, graph.rank[Int(node)])
            }
            return result
        }
        let present = items.filter { !$0.nodes.isEmpty }
        let ordered = present.sorted {
            box($0, graph).low + box($0, graph).high < box($1, graph).low + box($1, graph).high
        }
        var placed: [Box] = []
        for item in ordered {
            var current = box(item, graph)
            var shift: Int32 = 0
            for before in placed where before.firstRank <= current.lastRank && current.firstRank <= before.lastRank {
                shift = Swift.max(shift, before.high + before.margin + current.margin + 1 - current.low)
            }
            if shift > 0 {
                for node in item.nodes { graph.posB[Int(node)] += shift }
                current.low += shift
                current.high += shift
            }
            placed.append(current)
        }
    }
}
