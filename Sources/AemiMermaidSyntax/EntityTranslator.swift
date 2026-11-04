internal import Foundation

/// `erDiagram` as a flowchart: an entity is a node whose text is its name and its attributes, one to a line; a relationship is an edge with its label and the cardinalities of
/// its two ends (`||--o{` is `1 : 0..*`), dotted when it is a non-identifying one (`..`).
struct EntityTranslator: LineTranslator {
    private var notes = NodeText()

    private mutating func add(_ name: String, _ attribute: String?) { notes.add(name, attribute) }

    /// The cardinality a two-character end stands for: `||` one, `|o` and `o|` zero or one, `}o` and `o{` zero or more, `}|` and `|{` one or more.
    private static func cardinality(_ end: String) -> String {
        switch end {
            case "||": "1"
            case "|o", "o|": "0..1"
            case "}o", "o{": "0..*"
            case "}|", "|{": "1..*"
            default: "?"
        }
    }

    mutating func translate(_ raw: String) -> String {
        let line = raw.trimmingCharacters(in: .whitespaces)
        if notes.absorb(line, transform: { $0.replacingOccurrences(of: "\"", with: "'") }) { return "" }
        if line.isEmpty || line.hasPrefix("%%") || line.hasPrefix("direction ") || line.hasPrefix("title") { return "" }
        if line.hasPrefix("erDiagram") { return "flowchart LR" }
        if line.hasSuffix("{") {
            let name = Self.identifier(String(line.dropLast()).trimmingCharacters(in: .whitespaces))
            notes.begin(name)
            return ""
        }
        let words = line.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true).map(String.init)
        guard words.count == 3, words[1].count == 6,
            words[1].dropFirst(2).prefix(2) == "--" || words[1].dropFirst(2).prefix(2) == ".."
        else { return "$$" }
        let token = Array(words[1])
        let left = Self.identifier(words[0])
        var tail = words[2]
        var label = ""
        if let colon = tail.firstIndex(of: ":") {
            label = tail[tail.index(after: colon)...].trimmingCharacters(in: CharacterSet(charactersIn: " \""))
            tail = String(tail[tail.startIndex ..< colon])
        }
        let right = Self.identifier(tail.trimmingCharacters(in: .whitespaces))
        add(left, nil)
        add(right, nil)
        let ends = Self.cardinality(String(token[0 ... 1])) + " : " + Self.cardinality(String(token[4 ... 5]))
        let text = (label.isEmpty ? "" : label + " ") + "[" + ends + "]"
        return "\(left) \(token[2] == "." ? "-.-" : "---")|\(text.replacingOccurrences(of: "|", with: "/"))| \(right)"
    }

    mutating func finish() -> [String] { notes.flowchartLines(quoted: Self.quoted) }
}
