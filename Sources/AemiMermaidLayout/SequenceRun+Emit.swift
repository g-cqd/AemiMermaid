internal import AemiMermaidScene
internal import AemiMermaidSyntax

extension SequenceRun {
    /// The display list: frames, lifelines and participant boxes, bars, then the events.
    func emit(_ plan: SequencePlan, into scene: inout DiagramScene) {
        scene.width = Int32(width)
        scene.height = Int32(plan.bottom + 1)
        for var frame in plan.frames {
            frame.order = Int32(scene.shapes.count)
            scene.shapes.append(frame)
        }
        for (index, participant) in diagram.participants.enumerated() {
            let boxWidth = boxes[index]
            scene.shapes.append(
                SceneShape(
                    kind: participant.isActor ? .actor : .rectangle,
                    role: .node,
                    x: Int32(centers[index] - boxWidth / 2),
                    y: Int32(plan.top),
                    width: Int32(boxWidth),
                    height: 3,
                    text: scene.addLabel(diagram.labels.slice(participant.label)),
                    order: Int32(scene.shapes.count)
                )
            )
            let life = [
                ScenePoint(x: Int32(centers[index]), y: Int32(plan.top + 3)),
                ScenePoint(x: Int32(centers[index]), y: Int32(plan.bottom))
            ]
            scene.addPath(life, role: .muted, stroke: .dashed)
        }
        for bar in plan.bars where bar.to >= bar.from {
            let x = Int32(centers[bar.participant])
            scene.addPath(
                [ScenePoint(x: x, y: Int32(bar.from)), ScenePoint(x: x, y: Int32(bar.to))],
                role: .activation,
                stroke: .thick
            )
        }
        for item in plan.items {
            switch item {
                case .shape(var shape):
                    shape.order = Int32(scene.shapes.count)
                    scene.shapes.append(shape)
                case .path(let points, let stroke, let end):
                    scene.addPath(points, role: .edge, stroke: stroke, end: end)
                case .text(let text): scene.texts.append(text)
            }
        }
        for branch in plan.branches {
            let x = Int32(branch.depth)
            let row = Int32(branch.row)
            scene.addPath(
                [ScenePoint(x: x, y: row), ScenePoint(x: Int32(width) - 1 - x, y: row)],
                role: .cluster,
                stroke: .dashed
            )
            guard !branch.text.isEmpty else { continue }
            let text = scene.addLabel(Array("[".utf8 + branch.text + "]".utf8)[...])
            scene.texts.append(SceneText(x: x + 2, y: row + 1, anchor: .leading, role: .clusterTitle, text: text))
        }
        if let title = diagram.title, !title.isEmpty {
            scene.texts.append(
                SceneText(
                    x: Int32(width / 2),
                    y: 0,
                    anchor: .center,
                    role: .clusterTitle,
                    text: scene.addLabel(diagram.labels.slice(title))
                )
            )
        }
    }
}
