public import AemiMermaidScene

/// The cleaned text of a diagram's labels, one after the other: UTF-8 that holds no control, no bidirectional control and no invalid sequence, with `\n` for a
/// line break. A label is a ``LabelRef`` into it; nothing downstream copies a label or has to clean one again.
public struct LabelArena: Sendable, Equatable {
    public private(set) var bytes: [UInt8] = []

    public init() {}

    /// Cleans `raw` (see ``LabelSanitizer``) and appends it.
    /// - Returns: the label, and what the cleaning had to do.
    public mutating func add(_ raw: ArraySlice<UInt8>, maxBytes: Int) -> (
        ref: LabelRef, outcome: LabelSanitizer.Outcome
    ) {
        let start = bytes.count
        let outcome = LabelSanitizer.clean(raw, maxBytes: maxBytes, into: &bytes)
        return (LabelRef(offset: UInt32(clamping: start), length: UInt32(clamping: bytes.count - start)), outcome)
    }

    /// Appends text that is already clean (a generated label such as an id used as a title).
    public mutating func addClean(_ text: [UInt8]) -> LabelRef {
        let start = bytes.count
        bytes.append(contentsOf: text)
        return LabelRef(offset: UInt32(clamping: start), length: UInt32(clamping: text.count))
    }

    public func slice(_ ref: LabelRef) -> ArraySlice<UInt8> {
        let start = Int(ref.offset)
        return bytes[start ..< Swift.min(bytes.count, start + Int(ref.length))]
    }

    public func string(_ ref: LabelRef) -> String { String(decoding: slice(ref), as: UTF8.self) }
}
