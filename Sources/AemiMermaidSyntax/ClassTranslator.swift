internal import Foundation

/// `classDiagram` as a flowchart: a class is a node whose text is its name, its annotation and its members, one to a line; relations are edges (inheritance and realisation point at
/// the parent, composition and aggregation start with a circle at the whole, dependencies are dotted), their cardinalities and label joined into the edge's text.
struct ClassTranslator: LineTranslator {
    private var notes = NodeText()
    private let direction: String

    init(direction: String) { self.direction = direction }

    private mutating func add(_ name: String, _ member: String?) {
        notes.add(name, member.map { $0.replacingOccurrences(of: "~", with: "") })
    }

    /// The relations, longest first, as the flowchart link for a left class A and a right class B, and whether the edge is drawn from B to A. The class a head or a
    /// marker belongs to is the one at the top: a parent, a whole.
    private static let relations: [(token: String, link: String, reversed: Bool)] = [
        ("<|--", "<---", false), ("--|>", "<---", true), ("<|..", "<-.-", false), ("..|>", "<-.-", true),
        ("*--", "o---", false), ("--*", "o---", true),
        ("o--", "o---", false), ("--o", "o---", true), ("<--", "<---", false), ("-->", "-->", false),
        ("<..", "<-.-", false), ("..>", "-.->", false),
        ("--", "---", false), ("..", "-.-", false)
    ]

    mutating func translate(_ raw: String) -> String {
        let line = raw.trimmingCharacters(in: .whitespaces)
        if notes.absorb(line, transform: { $0.hasPrefix("<<") ? "«" + $0.dropFirst(2).dropLast(2) + "»" : $0 }) {
            return ""
        }
        if line.isEmpty || line.hasPrefix("%%") { return "" }
        if line.hasPrefix("classDiagram") { return "flowchart " + direction }
        if ["direction ", "note ", "click ", "link ", "callback ", "style ", "cssClass ", "classDef "]
            .contains(where: line.hasPrefix)
        {
            return ""
        }
        if line.hasPrefix("class ") {
            var rest = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            let opens = rest.hasSuffix("{")
            if opens { rest = String(rest.dropLast()).trimmingCharacters(in: .whitespaces) }
            let name = Self.identifier(rest.split(separator: "[").first.map(String.init) ?? rest)
            if opens { notes.begin(name) } else { add(name, nil) }
            return ""
        }
        if line.hasPrefix("<<"), let close = line.range(of: ">>") {
            let name = Self.identifier(String(line[close.upperBound...]))
            add(name, "«" + line[line.index(line.startIndex, offsetBy: 2) ..< close.lowerBound] + "»")
            return ""
        }
        for relation in Self.relations {
            guard let at = line.range(of: " " + relation.token + " ") ?? line.range(of: relation.token) else {
                continue
            }
            return edge(line, at: at, relation)
        }
        if notes.describe(line, identifier: Self.identifier) { return "" }
        return "$$"
    }

    /// `A "1" <|-- "*" B : label`.
    private mutating func edge(
        _ line: String,
        at range: Range<String.Index>,
        _ relation: (token: String, link: String, reversed: Bool)
    ) -> String {
        func split(_ side: Substring) -> (name: String, cardinality: String) {
            var text = side.trimmingCharacters(in: .whitespaces)
            var cardinality = ""
            if let first = text.firstIndex(of: "\""), let last = text.lastIndex(of: "\""), first < last {
                cardinality = String(text[text.index(after: first) ..< last])
                text.removeSubrange(first ... last)
            }
            return (Self.identifier(text.trimmingCharacters(in: .whitespaces)), cardinality)
        }
        let left = split(line[line.startIndex ..< range.lowerBound])
        let (rightText, label) = Self.splitLabel(line[range.upperBound...])
        let right = split(rightText[...])
        add(left.name, nil)
        add(right.name, nil)
        var text = [left.cardinality, label, right.cardinality].filter { !$0.isEmpty }.joined(separator: " ")
        text = text.replacingOccurrences(of: "|", with: "/")
        let (from, to) = relation.reversed ? (right.name, left.name) : (left.name, right.name)
        return "\(from) \(relation.link)" + (text.isEmpty ? "" : "|\(text)|") + " \(to)"
    }

    mutating func finish() -> [String] { notes.flowchartLines(quoted: Self.quoted) }
}
