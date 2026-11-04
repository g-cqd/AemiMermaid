/// A parsed flowchart: flat arrays, indices not references, and one arena for all its text.
public struct FlowchartDiagram: Sendable, Equatable {
    public var direction: FlowDirection = .topDown
    public var nodes: [FlowNode] = []
    public var edges: [FlowEdge] = []
    public var clusters: [FlowCluster] = []
    public var labels = LabelArena()
}
