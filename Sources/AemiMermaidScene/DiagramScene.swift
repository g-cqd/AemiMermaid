/// What a layout draws: a display list in draw order and the text it needs, in units a backend maps to cells or points (ADR 0004). Shapes and paths are
/// lists; a path is a run of points. The scene owns its text, so a backend needs nothing from the parser.
public struct DiagramScene: Sendable, Equatable {
    public var width: Int32 = 0
    public var height: Int32 = 0
    public var shapes: [SceneShape] = []
    public var points: [ScenePoint] = []
    public var paths: [ScenePath] = []
    public var texts: [SceneText] = []
    /// The text of every shape and every ``SceneText``: UTF-8, `\n` between the lines of a label.
    public private(set) var labels: [UInt8] = []

    public init() {}

    /// Empties the scene and keeps the room it grew, so a layout into the same scene allocates nothing once it is warm.
    public mutating func reset() {
        (width, height) = (0, 0)
        shapes.removeAll(keepingCapacity: true)
        points.removeAll(keepingCapacity: true)
        paths.removeAll(keepingCapacity: true)
        texts.removeAll(keepingCapacity: true)
        labels.removeAll(keepingCapacity: true)
    }

    /// Adds label bytes to the arena.
    public mutating func addLabel(_ bytes: ArraySlice<UInt8>) -> SceneText.Ref {
        let start = labels.count
        labels.append(contentsOf: bytes)
        return SceneText.Ref(offset: UInt32(clamping: start), length: UInt32(clamping: bytes.count))
    }

    public func bytes(_ ref: SceneText.Ref) -> ArraySlice<UInt8> {
        let start = Int(ref.offset)
        return labels[start ..< Swift.min(labels.count, start + Int(ref.length))]
    }

    public func string(_ ref: SceneText.Ref) -> String { String(decoding: bytes(ref), as: UTF8.self) }

    /// Adds a path of `points`.
    public mutating func addPath(
        _ route: [ScenePoint],
        role: SceneRole,
        stroke: SceneStroke = .solid,
        start: SceneMarker = .none,
        end: SceneMarker = .none
    ) {
        paths.append(
            ScenePath(
                first: Int32(clamping: points.count),
                count: Int32(clamping: route.count),
                role: role,
                stroke: stroke,
                startMarker: start,
                endMarker: end
            )
        )
        points.append(contentsOf: route)
    }
}
