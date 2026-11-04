/// The graph a flowchart layout works on: real nodes, then the virtual nodes that give long edges a place on each rank they cross. Everything is an array of
/// indices; the two axes are the rank axis (A) and the order axis (B), whatever the direction of the chart.
struct FlowGraph {
    var realCount = 0
    var count: Int { rank.count }
    var rank: [Int32] = []
    /// Extent along the rank axis and along the order axis; a virtual node has none along the rank axis and one along the order axis.
    var sizeA: [Int32] = []
    var sizeB: [Int32] = []
    /// The nodes of each rank in order, and the index of each node in its rank.
    var layers: [[Int32]] = []
    var position: [Int32] = []
    var posA: [Int32] = []
    var posB: [Int32] = []
    /// The neighbours one rank above and one below, per node.
    var upper: [[Int32]] = []
    var lower: [[Int32]] = []
    /// For each edge of the diagram, the nodes it passes from the lower-numbered rank to the higher, and whether the edge was turned round to make the graph acyclic.
    var chains: [[Int32]] = []
    var reversed: [Bool] = []

    mutating func addNode(rank rankNumber: Int, sizeA a: Int, sizeB b: Int) -> Int32 {
        self.rank.append(Int32(clamping: rankNumber))
        sizeA.append(Int32(clamping: a))
        sizeB.append(Int32(clamping: b))
        position.append(0)
        posA.append(0)
        posB.append(0)
        upper.append([])
        lower.append([])
        return Int32(self.rank.count - 1)
    }

    func center(_ node: Int32) -> Int32 { posB[Int(node)] + (sizeB[Int(node)] - 1) / 2 }
}
