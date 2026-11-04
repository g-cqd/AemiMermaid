internal import AemiMermaidScene

extension SequenceParser {
    private func blank(_ ref: LabelRef = .empty) -> SequenceEvent {
        SequenceEvent(kind: .message, from: -1, to: -1, arrow: .solid, block: .loop, activation: 0, text: ref)
    }

    /// The participant named by `id`, created if it is new; nil past the limit.
    mutating func participant(
        _ id: ArraySlice<UInt8>,
        label labelBytes: ArraySlice<UInt8>? = nil,
        isActor: Bool = false
    ) -> Int32? {
        let symbol = symbols.symbol(id)
        if participantOf.get(symbol) >= 0 {
            if let labelBytes {
                diagram.participants[Int(participantOf.get(symbol))].label = label(labelBytes)
                diagram.participants[Int(participantOf.get(symbol))].isActor = isActor
            }
            return participantOf.get(symbol)
        }
        guard diagram.participants.count < limits.maxNodes else {
            refuse(.nodes, figure: diagram.participants.count + 1)
            return nil
        }
        let idRef = label(id)
        let index = Int32(diagram.participants.count)
        diagram.participants.append(
            SequenceParticipant(id: idRef, label: labelBytes.map { label($0) } ?? idRef, isActor: isActor)
        )
        participantOf.set(symbol, index)
        return index
    }

    /// A statement that starts with a keyword; true if the line was one.
    mutating func readKeyword() -> Bool {
        readDeclaration() || readSetting() || readActivation() || readNoteKeyword() || readFragment()
    }

    /// `participant`, `actor`, and the statements that are read and ignored.
    private mutating func readDeclaration() -> Bool {
        for kind in ["participant", "actor"] where take(kind) {
            let text = rest()
            var id = text
            var title: ArraySlice<UInt8>?
            if let split = Self.range(of: " as ", in: text) {
                id = text[text.startIndex ..< split.lowerBound]
                title = text[split.upperBound...]
            }
            if id.isEmpty { unsupported() } else { _ = participant(id, label: title, isActor: kind == "actor") }
            return true
        }
        for word in ["create", "destroy", "link", "links", "properties", "details"] where take(word) {
            pos = end
            return true
        }
        return false
    }

    /// `autonumber` and `title`.
    private mutating func readSetting() -> Bool {
        if take("autonumber") {
            diagram.autonumber = true
            pos = end
            return true
        }
        guard take("title") else { return false }
        skipSpaces()
        if pos < end, source[pos] == UInt8(ascii: ":") { pos += 1 }
        diagram.title = label(rest())
        return true
    }

    /// `activate A` and `deactivate A`.
    private mutating func readActivation() -> Bool {
        let isDeactivate = take("deactivate")
        guard isDeactivate || take("activate") else { return false }
        let id = rest()
        guard !id.isEmpty, let who = participant(id) else {
            unsupported()
            return true
        }
        var event = blank()
        event.kind = isDeactivate ? .deactivate : .activate
        event.from = who
        add(event)
        return true
    }

    private mutating func readNoteKeyword() -> Bool {
        guard take("Note") || take("note") else { return false }
        readNote()
        return true
    }

    /// `loop`, `alt` and the other fragments, their branches and `end`.
    private mutating func readFragment() -> Bool {
        for block in SequenceEvent.Block.allCases where take(String(describing: block)) {
            guard depth < limits.maxNesting else {
                refuse(.nesting, figure: depth + 1)
                return true
            }
            depth += 1
            var event = blank(label(rest()))
            event.kind = .blockStart
            event.block = block
            add(event)
            return true
        }
        for word in ["else", "and", "option"] where take(word) {
            var event = blank(label(rest()))
            event.kind = .blockBranch
            if depth == 0 { reader.diagnostics.add(.init(kind: .strayEnd, line: line)) } else { add(event) }
            return true
        }
        guard take("end") else { return false }
        if depth == 0 {
            reader.diagnostics.add(.init(kind: .strayEnd, line: line))
        } else {
            depth -= 1
            var event = blank()
            event.kind = .blockEnd
            add(event)
        }
        pos = end
        return true
    }

    mutating func add(_ event: SequenceEvent) { diagram.events.append(event) }

    private static func range(of needle: String, in text: ArraySlice<UInt8>) -> Range<Int>? {
        let bytes = Array(needle.utf8)
        guard text.count >= bytes.count else { return nil }
        var index = text.startIndex
        while index + bytes.count <= text.endIndex {
            if text[index ..< (index + bytes.count)].elementsEqual(bytes) { return index ..< (index + bytes.count) }
            index += 1
        }
        return nil
    }

    /// `Note left of A: text`, `Note right of A: text`, `Note over A,B: text`.
    private mutating func readNote() {
        var event = blank()
        skipSpaces()
        if take("left") {
            skipSpaces()
            _ = take("of")
            event.kind = .noteLeft
        } else if take("right") {
            skipSpaces()
            _ = take("of")
            event.kind = .noteRight
        } else if take("over") {
            event.kind = .noteOver
        } else {
            return unsupported()
        }
        skipSpaces()
        var colon = pos
        while colon < end, source[colon] != UInt8(ascii: ":") { colon += 1 }
        guard colon < end else { return unsupported() }
        let names = source[pos ..< colon].split(separator: UInt8(ascii: ","), omittingEmptySubsequences: false)
        func trimmed(_ part: ArraySlice<UInt8>) -> ArraySlice<UInt8> {
            var slice = part
            while slice.first == 0x20 { slice = slice.dropFirst() }
            while slice.last == 0x20 { slice = slice.dropLast() }
            return slice
        }
        guard let first = names.first, !trimmed(first).isEmpty, let from = participant(trimmed(first)) else {
            return unsupported()
        }
        event.from = from
        event.to = from
        if names.count > 1, let second = participant(trimmed(names[names.startIndex + 1])) { event.to = second }
        pos = colon + 1
        event.text = label(rest())
        add(event)
    }

    private func arrow(at index: Int) -> (SequenceArrow, Int)? {
        func at(_ offset: Int) -> UInt8 { index + offset < end ? source[index + offset] : 0 }
        guard at(0) == UInt8(ascii: "-") else { return nil }
        let dashed = at(1) == UInt8(ascii: "-")
        let base = dashed ? 2 : 1
        switch at(base) {
            case UInt8(ascii: ">"):
                if at(base + 1) == UInt8(ascii: ">") { return (dashed ? .dashedArrow : .solidArrow, base + 2) }
                return (dashed ? .dashed : .solid, base + 1)
            case UInt8(ascii: "x"): return (dashed ? .dashedCross : .solidCross, base + 1)
            case UInt8(ascii: ")"): return (dashed ? .dashedAsync : .solidAsync, base + 1)
            default: return nil
        }
    }

    /// `A->>B: text`, `A-->>+B: text`, `A-x-B`.
    mutating func readMessage() {
        var cursor = pos
        var found: (SequenceArrow, Int)?
        while cursor < end {
            if source[cursor] == UInt8(ascii: "-"), let arrow = arrow(at: cursor) {
                found = arrow
                break
            }
            if source[cursor] == UInt8(ascii: ":") { break }
            cursor += 1
        }
        guard let (arrow, length) = found else { return unsupported() }
        var from = source[pos ..< cursor]
        while from.last == 0x20 || from.last == 0x09 { from = from.dropLast() }
        pos = cursor + length
        var event = blank()
        if pos < end, source[pos] == UInt8(ascii: "+") {
            event.activation = 1
            pos += 1
        } else if pos < end, source[pos] == UInt8(ascii: "-") {
            event.activation = -1
            pos += 1
        }
        skipSpaces()
        var colon = pos
        while colon < end, source[colon] != UInt8(ascii: ":") { colon += 1 }
        var target = source[pos ..< colon]
        while target.last == 0x20 || target.last == 0x09 { target = target.dropLast() }
        guard !from.isEmpty, !target.isEmpty else { return unsupported() }
        guard messages < limits.maxMessages else { return refuse(.messages, figure: messages + 1) }
        guard let sender = participant(from), let receiver = participant(target) else { return }
        messages += 1
        event.from = sender
        event.to = receiver
        event.arrow = arrow
        pos = colon < end ? colon + 1 : end
        event.text = label(rest())
        add(event)
    }
}
