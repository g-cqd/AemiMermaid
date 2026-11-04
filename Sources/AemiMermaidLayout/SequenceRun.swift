internal import AemiMermaidScene
internal import AemiMermaidSyntax

/// The second pass of a sequence layout: rows for each event. The display list is made from the result by `emit`.
struct SequenceRun {
    let diagram: SequenceDiagram
    let metrics: MermaidMetrics
    let centers: [Int]
    let boxes: [Int]
    let width: Int

    /// A fragment that has opened and not yet closed.
    private struct Open {
        var row: Int
        var block: SequenceEvent.Block
        var title: [UInt8]
    }

    /// The state of the walk over the events.
    private struct Walk {
        var plan = SequencePlan()
        var open: [Open] = []
        var activations: [[Int]]
        var cursor = 0
        var messageNumber = 0
    }

    private func lines(_ ref: LabelRef) -> [ArraySlice<UInt8>] {
        diagram.labels.slice(ref).split(separator: 0x0A, omittingEmptySubsequences: false)
    }

    func plan(into scene: inout DiagramScene) -> SequencePlan {
        var walk = Walk(activations: [[Int]](repeating: [], count: diagram.participants.count))
        walk.plan.top = diagram.title.map { $0.isEmpty ? 0 : 2 } ?? 0
        walk.cursor = walk.plan.top + 3
        for event in diagram.events {
            switch event.kind {
                case .message: message(event, &walk, &scene)
                case .noteLeft, .noteRight, .noteOver: note(event, &walk, &scene)
                case .activate: walk.activations[Int(event.from)].append(walk.cursor)
                case .deactivate:
                    if let start = walk.activations[Int(event.from)].popLast() {
                        walk.plan.bars.append(
                            .init(participant: Int(event.from), from: start, to: Swift.max(start, walk.cursor - 1))
                        )
                    }
                case .blockStart:
                    walk.open.append(
                        Open(row: walk.cursor, block: event.block, title: Array(diagram.labels.slice(event.text)))
                    )
                    walk.cursor += 2
                case .blockBranch:
                    walk.plan.branches.append(
                        .init(row: walk.cursor, depth: walk.open.count, text: Array(diagram.labels.slice(event.text)))
                    )
                    walk.cursor += 2
                case .blockEnd:
                    close(&walk, &scene)
                    walk.cursor += 1
            }
        }
        for (index, starts) in walk.activations.enumerated() {
            for begin in starts {
                walk.plan.bars.append(.init(participant: index, from: begin, to: Swift.max(begin, walk.cursor - 1)))
            }
        }
        // Anything left open is closed at the end.
        while !walk.open.isEmpty {
            close(&walk, &scene)
            walk.cursor += 1
        }
        walk.plan.bottom = walk.cursor
        return walk.plan
    }

    /// A message: its text above its line, a self message looping out to the right.
    private func message(_ event: SequenceEvent, _ walk: inout Walk, _ scene: inout DiagramScene) {
        let from = centers[Int(event.from)]
        let to = centers[Int(event.to)]
        walk.messageNumber += 1
        var text = Array(diagram.labels.slice(event.text))
        if diagram.autonumber { text = Array("\(walk.messageNumber). ".utf8) + text }
        let textRows = Swift.max(1, text.split(separator: 0x0A, omittingEmptySubsequences: false).count)
        let stroke: SceneStroke = event.arrow.isDashed ? .dashed : .solid
        let line = walk.cursor + textRows
        if event.activation == 1 { walk.activations[Int(event.to)].append(line) }
        func point(_ x: Int, _ y: Int) -> ScenePoint { ScenePoint(x: Int32(x), y: Int32(y)) }
        if event.from == event.to {
            let loop = [point(from, line), point(from + 3, line), point(from + 3, line + 1), point(from + 1, line + 1)]
            walk.plan.items.append(.path(points: loop, stroke: stroke, end: marker(event.arrow)))
            walk.plan.items.append(
                .text(
                    .init(
                        x: Int32(from + 5),
                        y: Int32(walk.cursor),
                        anchor: .leading,
                        role: .label,
                        text: scene.addLabel(text[...])
                    )
                )
            )
            walk.cursor += textRows + 2
        } else {
            let step = to > from ? -1 : 1
            walk.plan.items.append(
                .path(points: [point(from, line), point(to + step, line)], stroke: stroke, end: marker(event.arrow))
            )
            walk.plan.items.append(
                .text(
                    .init(
                        x: Int32((from + to) / 2),
                        y: Int32(walk.cursor),
                        anchor: .center,
                        role: .label,
                        text: scene.addLabel(text[...])
                    )
                )
            )
            walk.cursor += textRows + 1
        }
        if event.activation == -1, let start = walk.activations[Int(event.from)].popLast() {
            walk.plan.bars.append(.init(participant: Int(event.from), from: start, to: walk.cursor - 1))
        }
    }

    /// A note beside a column or over one or two.
    private func note(_ event: SequenceEvent, _ walk: inout Walk, _ scene: inout DiagramScene) {
        let content = lines(event.text)
        let textWidth = content.map { metrics.width(of: $0) }.max() ?? 0
        let boxWidth = textWidth + 4
        let first = centers[Int(event.from)]
        let second = centers[Int(event.to)]
        let x: Int
        var noteWidth = boxWidth
        switch event.kind {
            case .noteLeft: x = Swift.max(0, first - 1 - boxWidth)
            case .noteRight: x = first + 2
            default:
                noteWidth = Swift.max(boxWidth, abs(second - first) + 4)
                x = Swift.max(0, (first + second) / 2 - noteWidth / 2)
        }
        let shape = SceneShape(
            kind: .note,
            role: .note,
            x: Int32(x),
            y: Int32(walk.cursor),
            width: Int32(noteWidth),
            height: Int32(content.count + 2),
            text: scene.addLabel(diagram.labels.slice(event.text)),
            order: 0
        )
        walk.plan.items.append(.shape(shape))
        walk.cursor += content.count + 2
    }

    /// The end of a fragment: a frame from its first row to the current one, headed by its kind and text.
    private func close(_ walk: inout Walk, _ scene: inout DiagramScene) {
        guard let block = walk.open.popLast() else { return }
        let depth = walk.open.count
        let heading =
            String(describing: block.block)
            + (block.title.isEmpty ? "" : " [" + String(decoding: block.title, as: UTF8.self) + "]")
        walk.plan.frames.append(
            SceneShape(
                kind: .frame,
                role: .cluster,
                x: Int32(1 + depth),
                y: Int32(block.row),
                width: Int32(Swift.max(4, width - 2 * (1 + depth))),
                height: Int32(walk.cursor - block.row + 1),
                text: scene.addLabel(Array(heading.utf8)[...]),
                order: 0
            )
        )
    }

    private func marker(_ arrow: SequenceArrow) -> SceneMarker {
        switch arrow {
            case .solid, .dashed: .none
            case .solidArrow, .dashedArrow: .arrow
            case .solidCross, .dashedCross: .cross
            case .solidAsync, .dashedAsync: .async
        }
    }
}
