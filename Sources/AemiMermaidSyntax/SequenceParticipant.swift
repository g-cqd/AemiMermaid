public import AemiMermaidScene

/// A participant of a sequence diagram: a column.
public struct SequenceParticipant: Sendable, Equatable {
    public var id: LabelRef
    public var label: LabelRef
    /// Drawn as a person, not a box.
    public var isActor: Bool
}
