/// A point of a path.
public struct ScenePoint: Sendable, Equatable {
    public var x: Int32
    public var y: Int32

    public init(x: Int32, y: Int32) {
        self.x = x
        self.y = y
    }
}
