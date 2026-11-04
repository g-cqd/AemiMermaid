public import AemiMermaidScene

/// A node of a flowchart.
public struct FlowNode: Sendable, Equatable {
    /// The node's id as written, in the diagram's label arena.
    public var id: LabelRef
    /// What the node shows; its id when the diagram gave it no text.
    public var label: LabelRef
    public var shape: FlowShape
    /// The index of the cluster that holds the node, or -1.
    public var cluster: Int32
}
