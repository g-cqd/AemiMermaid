/// The diagnostics of one diagram, at most sixteen; the rest are counted, not kept, so a hostile input cannot make the list the cost.
public struct MermaidDiagnostics: Sendable, Equatable {
    public static let capacity = 16

    public private(set) var entries: [MermaidDiagnostic] = []
    /// How many diagnostics came after the sixteenth.
    public private(set) var dropped = 0

    public init() {}

    public var isEmpty: Bool { entries.isEmpty }

    public var count: Int { entries.count + dropped }

    public mutating func add(_ diagnostic: MermaidDiagnostic) {
        if entries.count < Self.capacity { entries.append(diagnostic) } else { dropped += 1 }
    }

    public func contains(_ kind: MermaidDiagnostic.Kind) -> Bool { entries.contains { $0.kind == kind } }
}
