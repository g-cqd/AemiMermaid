/// A range of bytes of an arena of text: where it starts and how many there are. A parser's label and a scene's text are both one.
public struct TextRef: Sendable, Equatable {
    public var offset: UInt32
    public var length: UInt32

    public static let empty = TextRef(offset: 0, length: 0)

    public init(offset: UInt32, length: UInt32) {
        self.offset = offset
        self.length = length
    }

    public var isEmpty: Bool { length == 0 }
}
