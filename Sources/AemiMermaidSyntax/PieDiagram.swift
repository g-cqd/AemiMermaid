public import AemiMermaidScene

/// A parsed pie chart.
public struct PieDiagram: Sendable, Equatable {
    public struct Slice: Sendable, Equatable {
        public var label: LabelRef
        public var value: Double
    }

    public var title: LabelRef?
    /// `showData`: the values are shown beside the percentages.
    public var showData = false
    public var slices: [Slice] = []
    public var labels = LabelArena()
}

extension PieDiagram: LabelledDiagram {}
