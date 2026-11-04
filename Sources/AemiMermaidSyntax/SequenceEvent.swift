public import AemiMermaidScene

/// One thing that happens in a sequence diagram, in order.
public struct SequenceEvent: Sendable, Equatable {
    public enum Kind: UInt8, Sendable, Equatable {
        case message
        case noteLeft, noteRight, noteOver
        case activate, deactivate
        /// A fragment opens: `block` says which, `text` is its heading.
        case blockStart
        /// A fragment goes on with another branch (`else`, `and`, `option`).
        case blockBranch
        case blockEnd
    }

    public enum Block: UInt8, Sendable, Equatable, CaseIterable {
        case loop, alt, opt, par, critical, `break`, rect, box
    }

    public var kind: Kind
    /// The participant a message comes from, a note is beside or starts over, or an activation is of.
    public var from: Int32
    /// The participant a message goes to, or a note over two ends at.
    public var to: Int32
    public var arrow: SequenceArrow
    public var block: Block
    /// `+` after a message's arrow activates its target (1), `-` deactivates its sender (-1).
    public var activation: Int8
    public var text: LabelRef
}
