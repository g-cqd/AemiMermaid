/// A diagram that keeps its text in one ``LabelArena``.
protocol LabelledDiagram {
    var labels: LabelArena { get set }
}

extension FlowchartDiagram: LabelledDiagram {}
extension SequenceDiagram: LabelledDiagram {}
