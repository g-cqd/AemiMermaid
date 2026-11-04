public import AemiMermaidScene
public import AemiMermaidSyntax

/// Lays a sequence diagram out in character cells (ADR 0004): participants in columns, one or more rows for each event in order, fragments as frames around the rows they
/// hold. Two passes over the events, no recursion: the first fixes the column gaps from the widest text between two columns, the second gives each event its rows.
public enum SequenceLayout {
    public static func lay(
        _ diagram: SequenceDiagram,
        metrics: MermaidMetrics = MermaidMetrics(),
        maxWidth: Int? = nil,
        into scene: inout DiagramScene
    ) -> MermaidLayoutOutcome {
        guard !diagram.participants.isEmpty else { return .source(.empty) }
        scene.reset()
        let count = diagram.participants.count
        func text(_ ref: LabelRef) -> [ArraySlice<UInt8>] {
            diagram.labels.slice(ref).split(separator: 0x0A, omittingEmptySubsequences: false)
        }
        func width(_ ref: LabelRef) -> Int { text(ref).map { metrics.width(of: $0) }.max() ?? 0 }

        // Pass 1: the columns. A box is as wide as its label; the gap between two columns grows to fit the widest text of a message that spans it.
        var boxes = diagram.participants.map { width($0.label) + 4 }
        var gaps = [Int](repeating: 6, count: Swift.max(0, count - 1))
        for index in 0 ..< count - 1 {
            gaps[index] = Swift.max(gaps[index], (boxes[index] + 1) / 2 + (boxes[index + 1] + 1) / 2 + 2)
        }
        var rightMargin = 2
        for event in diagram.events where event.kind == .message {
            let need = width(event.text) + (diagram.autonumber ? 4 : 0) + 4
            let low = Int(Swift.min(event.from, event.to))
            let high = Int(Swift.max(event.from, event.to))
            if low == high {
                if low + 1 < count {
                    gaps[low] = Swift.max(gaps[low], need + 4)
                } else {
                    rightMargin = Swift.max(rightMargin, need + 4)
                }
            } else {
                var have = gaps[low ..< high].reduce(0, +)
                if have < need {
                    gaps[high - 1] += need - have
                    have = need
                }
            }
        }
        for event in diagram.events where event.kind == .noteOver && event.from != event.to {
            let low = Int(Swift.min(event.from, event.to))
            let high = Int(Swift.max(event.from, event.to))
            let need = width(event.text) + 4
            if gaps[low ..< high].reduce(0, +) < need { gaps[high - 1] += need - gaps[low ..< high].reduce(0, +) }
        }
        var centers: [Int] = [boxes[0] / 2 + 2]
        for index in 1 ..< count { centers.append(centers[index - 1] + gaps[index - 1]) }
        // A note to the left of a column needs the room: everything moves right by what the widest lacks.
        var shift = 0
        for event in diagram.events where event.kind == .noteLeft {
            shift = Swift.max(shift, width(event.text) + 4 + 2 - centers[Int(event.from)])
        }
        if shift > 0 { centers = centers.map { $0 + shift } }
        let widest = centers[count - 1] + (boxes[count - 1] + 1) / 2 + rightMargin
        var total = widest
        for (index, event) in diagram.events.enumerated() where event.kind == .noteLeft || event.kind == .noteRight {
            _ = index
            let wide = width(event.text) + 4
            total = Swift.max(
                total,
                event.kind == .noteRight ? centers[Int(event.from)] + 2 + wide + 1 : centers[Int(event.from)] + 1
            )
        }
        let run = SequenceRun(diagram: diagram, metrics: metrics, centers: centers, boxes: boxes, width: total)
        let plan = run.plan(into: &scene)
        run.emit(plan, into: &scene)
        boxes.removeAll()
        if let maxWidth, Int(scene.width) > maxWidth {
            let needed = Int(scene.width)
            scene.reset()
            return .source(.tooWide(needed: needed, available: maxWidth))
        }
        return .drawn(width: Int(scene.width), height: Int(scene.height))
    }
}
