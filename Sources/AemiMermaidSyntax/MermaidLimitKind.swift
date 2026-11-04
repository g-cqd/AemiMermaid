/// Which limit a diagram hit.
public enum MermaidLimitKind: UInt8, Sendable, Equatable {
    case sourceBytes, nodes, edges, labelBytes, nesting, messages, lineBytes, virtualNodes
}
