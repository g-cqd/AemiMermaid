internal import Foundation

/// A diagram kind read by writing it as a flowchart (ADR 0005): the source goes through a translator, one line in and one line out, so a diagnostic names the line the author
/// wrote, and the flowchart parser then does what it does for any flowchart: limits, cleaning, layout. A translator holds the little state its kind needs (the open composite states,
/// the members of a class) and emits flowchart text only; a line it cannot read becomes an unreadable line, which the flowchart parser reports.
protocol LineTranslator {
    /// The flowchart line for one source line, without a line ending; "" for a line that says nothing. Called for every line in order, the header line included.
    mutating func translate(_ line: String) -> String
    /// Lines to add after the last one: the nodes whose text was gathered along the way.
    mutating func finish() -> [String]
}

extension LineTranslator {
    /// The whole source as flowchart text, line for line, `finish()`'s lines last.
    mutating func run(_ source: [UInt8]) -> [UInt8] {
        var output: [UInt8] = []
        output.reserveCapacity(source.count + source.count / 4)
        var start = 0
        while start <= source.count {
            var stop = start
            while stop < source.count, source[stop] != 0x0A { stop += 1 }
            var text = source[start ..< stop]
            while text.last == 0x0D { text = text.dropLast() }
            output.append(contentsOf: translate(String(decoding: text, as: UTF8.self)).utf8)
            output.append(0x0A)
            start = stop + 1
        }
        for line in finish() {
            output.append(contentsOf: line.utf8)
            output.append(0x0A)
        }
        return output
    }

    /// The direction a diagram asks for at its top level (`direction LR`), or `TD`; composite blocks (`{` to `}`) are looked past.
    static func direction(in source: [UInt8]) -> String {
        var depth = 0
        for raw in String(decoding: source, as: UTF8.self).split(separator: "\n") {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.hasSuffix("{") { depth += 1 }
            if line == "}" { depth = Swift.max(0, depth - 1) }
            if depth == 0, line.hasPrefix("direction ") {
                let value = line.dropFirst(10).trimmingCharacters(in: .whitespaces)
                if ["LR", "RL", "TB", "BT", "TD"].contains(value) { return value }
            }
        }
        return "TD"
    }

    /// `head : label` as the two trimmed halves, cut at the first colon; the label is empty when there is no colon.
    static func splitLabel(_ text: Substring) -> (head: String, label: String) {
        guard let colon = text.firstIndex(of: ":") else { return (text.trimmingCharacters(in: .whitespaces), "") }
        return (
            text[text.startIndex ..< colon].trimmingCharacters(in: .whitespaces),
            text[text.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        )
    }

    /// A label safe to put between quotes in flowchart text: no quote, no line ending.
    static func quoted(_ text: String) -> String {
        "\"" + text.replacingOccurrences(of: "\"", with: "'").replacingOccurrences(of: "\n", with: " ") + "\""
    }

    /// An id safe to write in flowchart text: its letters, digits and underscores; anything else is dropped, and an empty id becomes `_`.
    static func identifier(_ text: String) -> String {
        let kept = text.unicodeScalars.filter { $0.properties.isAlphabetic || ("0" ... "9").contains($0) || $0 == "_" }
        return kept.isEmpty ? "_" : String(String.UnicodeScalarView(kept))
    }
}
