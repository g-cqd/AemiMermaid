internal import AemiMermaidScene
internal import AemiMermaidSyntax

/// One layout of one chart in one direction: the state the phases share.
struct FlowLayoutRun {
    let diagram: FlowchartDiagram
    let metrics: MermaidMetrics
    let limits: MermaidLimits
    var graph = FlowGraph()
    var refusal: MermaidLayoutRefusal?
    /// The lines of each node's label, and the width of the widest.
    var lines: [LabelLines] = []
    var textWidth: [Int] = []
    /// Lanes needed in the channel after each rank, and its height in cells along the rank axis.
    var lanes: [Int] = []
    var channel: [Int32] = []
    /// Where each edge's hops get their lane (-1: straight), the rows the label of an edge takes before its lanes, and where each rank starts and how big it is.
    var hopLane: [[Int]] = []
    var stubRows: [Int] = []
    var labelSlot: [Int] = []
    /// How far each edge's first and last hop are from the centre of their node, along the order axis.
    var portShift: [Int32] = []
    var rankStart: [Int32] = []
    var rankSize: [Int32] = []
    /// The route of each edge as points in (rank axis, order axis) cells, and where its label goes.
    var routes: [[(a: Int32, b: Int32)]] = []
    var labelAt: [(a: Int32, b: Int32)?] = []
    var extent = (a: Int32(0), b: Int32(0))
    /// How far a label sticks out before the first cell of the order axis: the chart grows by that much on that side.
    var overhang: Int32 = 0

    init(_ diagram: FlowchartDiagram, metrics: MermaidMetrics, limits: MermaidLimits) {
        self.diagram = diagram
        self.metrics = metrics
        self.limits = limits
        measure()
        breakCycles()
        guard refusal == nil else { return }
        rankNodes()
        addVirtualNodes()
        guard refusal == nil else { return }
        orderNodes()
        placeNodes()
        assignPorts()
        planChannels()
        routeEdges()
    }

    /// The box each node needs: its text, a border and a space inside it on each side; the diamond-like shapes take more.
    private mutating func measure() {
        let vertical = diagram.direction.isVertical
        for node in diagram.nodes {
            let label = LabelLines(
                diagram.labels.slice(node.label),
                maxColumns: metrics.maxLabelColumns,
                metrics: metrics
            )
            lines.append(label)
            textWidth.append(label.width)
            let extra: Int
            switch node.shape {
                case .diamond, .hexagon, .circle, .doubleCircle, .stadium, .cylinder: extra = 2
                default: extra = 0
            }
            let width = label.width + 4 + extra
            let height = label.lines.count + 2 + (node.shape == .cylinder ? 1 : 0)
            _ = graph.addNode(rank: 0, sizeA: vertical ? height : width, sizeB: vertical ? width : height)
        }
        graph.realCount = diagram.nodes.count
    }
}
