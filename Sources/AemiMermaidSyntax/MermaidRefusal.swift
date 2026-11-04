/// Why a source is not drawn as a diagram: the host shows it as the text it is.
public enum MermaidRefusal: Equatable, Sendable {
    /// The first line names no diagram kind this engine draws.
    case unknownKind
    /// A limit was passed; the figure says how far.
    case limit(MermaidLimitKind, figure: Int)
    /// No node, state or participant at all.
    case empty
}
