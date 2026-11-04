public import AemiMermaidScene
public import AemiMermaidSyntax

/// Lays a flowchart out in character cells (ADR 0004): the layered method, phase by phase on flat arrays, each phase bounded by the size of the graph and the limits.
///
/// 1. cycles are broken by reversing the edges a depth-first walk finds going back; 2. each node takes the rank after its latest predecessor; 3. an edge that crosses
/// ranks gets a virtual node on each; 4. the order of the nodes in each rank is improved by sweeps of the median of their neighbours; 5. nodes are placed along the order
/// axis by the least squares fit to their neighbours that keeps them apart; 6. the lanes edges need between ranks fix the rank axis; 7. edges are routed with
/// horizontal and vertical segments only.
public enum FlowLayout {
    /// Lays `diagram` out into `scene`, no wider than `maxWidth` cells if one is given.
    ///
    /// A chart too wide for the width turns left to right into top down, then wraps its labels narrower, and only then is refused.
    public static func lay(
        _ diagram: FlowchartDiagram,
        metrics: MermaidMetrics = MermaidMetrics(),
        maxWidth: Int? = nil,
        limits: MermaidLimits = .terminal,
        into scene: inout DiagramScene
    ) -> MermaidLayoutOutcome {
        guard !diagram.nodes.isEmpty else { return .source(.empty) }
        var attempts: [(FlowDirection, Int)] = [(diagram.direction, metrics.maxLabelColumns)]
        if maxWidth != nil {
            if !diagram.direction.isVertical { attempts.append((.topDown, metrics.maxLabelColumns)) }
            for columns in [24, 16, 10] where columns < metrics.maxLabelColumns {
                attempts.append((diagram.direction.isVertical ? diagram.direction : .topDown, columns))
            }
        }
        var needed = 0
        for (direction, labelColumns) in attempts {
            var chart = diagram
            chart.direction = direction
            var tuned = metrics
            tuned.maxLabelColumns = labelColumns
            let run = FlowLayoutRun(chart, metrics: tuned, limits: limits)
            if let refusal = run.refusal { return .source(refusal) }
            run.emit(into: &scene)
            guard let maxWidth, Int(scene.width) > maxWidth else {
                return .drawn(width: Int(scene.width), height: Int(scene.height))
            }
            needed = needed == 0 ? Int(scene.width) : Swift.min(needed, Int(scene.width))
        }
        scene.reset()
        return .source(.tooWide(needed: needed, available: maxWidth ?? 0))
    }
}
