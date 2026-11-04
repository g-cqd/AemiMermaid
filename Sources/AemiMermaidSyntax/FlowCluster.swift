public import AemiMermaidScene

/// A `subgraph` of a flowchart.
public struct FlowCluster: Sendable, Equatable {
    public var id: LabelRef
    public var title: LabelRef
    /// The cluster that holds this one, or -1.
    public var parent: Int32
}
