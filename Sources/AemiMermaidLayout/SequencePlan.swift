internal import AemiMermaidScene

/// What the rows pass of a sequence layout found, in the order the events came: everything the display list needs.
struct SequencePlan {
    /// One thing to draw for an event.
    enum Item {
        case shape(SceneShape)
        case path(points: [ScenePoint], stroke: SceneStroke, end: SceneMarker)
        case text(SceneText)
    }

    /// An activation bar on a participant's lifeline, from row `from` to row `to`.
    struct Bar {
        var participant: Int
        var from: Int
        var to: Int
    }

    /// The dashed line between two branches of a fragment, and the text under it.
    struct Branch {
        var row: Int
        var depth: Int
        var text: [UInt8]
    }

    var frames: [SceneShape] = []
    var items: [Item] = []
    var bars: [Bar] = []
    var branches: [Branch] = []
    var top = 0
    var bottom = 0
}
