public import AemiMermaidScene

/// A parsed sequence diagram.
public struct SequenceDiagram: Sendable, Equatable {
    public var participants: [SequenceParticipant] = []
    public var events: [SequenceEvent] = []
    public var title: LabelRef?
    public var autonumber = false
    public var labels = LabelArena()
}
