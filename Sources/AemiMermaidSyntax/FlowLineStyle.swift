/// How an edge's line is drawn.
public enum FlowLineStyle: UInt8, Sendable, Equatable {
    /// `-->` and `---`
    case solid
    /// `-.->`
    case dotted
    /// `==>`
    case thick
    /// `~~~`: it holds the layout and is not drawn.
    case invisible
}
