public import AemiMermaidScene
public import AemiMermaidSyntax

/// One entry for every kind of diagram: the layout that fits what the parse produced.
public enum MermaidLayout {
    /// Lays out `result` into `scene`, no wider than `maxWidth` cells if one is given. A refused parse is `.source(.empty)` here: the host keeps the reason it was refused.
    public static func lay(
        _ result: MermaidParse.Result,
        metrics: MermaidMetrics = MermaidMetrics(),
        maxWidth: Int? = nil,
        limits: MermaidLimits = .terminal,
        into scene: inout DiagramScene
    ) -> MermaidLayoutOutcome {
        switch result {
            case .flowchart(let diagram):
                FlowLayout.lay(diagram, metrics: metrics, maxWidth: maxWidth, limits: limits, into: &scene)
            case .sequence(let diagram): SequenceLayout.lay(diagram, metrics: metrics, maxWidth: maxWidth, into: &scene)
            case .pie(let diagram): PieLayout.lay(diagram, metrics: metrics, maxWidth: maxWidth, into: &scene)
            case .refused: .source(.empty)
        }
    }
}
