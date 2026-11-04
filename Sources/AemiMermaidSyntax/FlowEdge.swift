public import AemiMermaidScene

/// An edge of a flowchart, from node `from` to node `to` (indices into ``FlowchartDiagram/nodes``).
public struct FlowEdge: Sendable, Equatable {
    public var from: Int32
    public var to: Int32
    public var line: FlowLineStyle
    public var head: FlowEnd
    public var tail: FlowEnd
    /// How many ranks the edge asks to span: 1 for `-->`, 2 for `--->`, and so on.
    public var length: UInt8
    public var label: LabelRef
}
