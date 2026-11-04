internal import Foundation

/// `stateDiagram` as a flowchart: states are nodes, `[*]` a start or an end node, transitions edges with their text, composite states subgraphs, and `<<choice>>`, `<<fork>>` and
/// `<<join>>` small nodes. `direction LR` at the top level sets the chart's direction. Notes and concurrency regions are read and left out.
struct StateTranslator: LineTranslator {
    private var scopes: [String] = ["root"]
    private var notes = NodeText()
    private var inNote = false
    private let direction: String

    /// `direction` is the chart's, found by `StateTranslator.direction(in:)` before the lines are translated.
    init(direction: String) { self.direction = direction }

    private func node(_ token: String, end: Bool) -> String {
        guard token == "[*]" else { return Self.identifier(token) }
        let scope = Self.identifier(scopes[scopes.count - 1])
        return end ? "end_\(scope)(((\"◉\")))" : "start_\(scope)((\"●\"))"
    }

    mutating func translate(_ raw: String) -> String {
        let line = raw.trimmingCharacters(in: .whitespaces)
        if inNote {
            if line.hasPrefix("end note") { inNote = false }
            return ""
        }
        if line.isEmpty || line.hasPrefix("%%") || line == "--" { return "" }
        if line.hasPrefix("stateDiagram") { return "flowchart " + direction }
        if line.hasPrefix("direction ") || line.hasPrefix("classDef ") || line.hasPrefix("class ")
            || line.hasPrefix("style ")
        {
            return ""
        }
        if line.hasPrefix("note ") {
            inNote = !line.contains(":")
            return ""
        }
        if line == "}" {
            if scopes.count > 1 {
                scopes.removeLast()
                return "end"
            }
            return ""
        }
        if line.hasPrefix("state ") { return declaration(String(line.dropFirst(6))) }
        if let arrow = line.range(of: "-->") {
            let from = line[line.startIndex ..< arrow.lowerBound].trimmingCharacters(in: .whitespaces)
            let (rest, text) = Self.splitLabel(line[arrow.upperBound...])
            guard !from.isEmpty, !rest.isEmpty else { return "$$" }
            let link = text.isEmpty ? "-->" : "-->|\(text.replacingOccurrences(of: "|", with: "/"))|"
            return "\(node(from, end: false)) \(link) \(node(rest, end: true))"
        }
        if notes.describe(line, identifier: Self.identifier) { return "" }
        return "$$"
    }

    /// `state "Title" as id`, `state id`, `state id <<choice>>`, `state id {`, `state "Title" as id {`.
    private mutating func declaration(_ rest: String) -> String {
        var text = rest.trimmingCharacters(in: .whitespaces)
        let opens = text.hasSuffix("{")
        if opens { text = String(text.dropLast()).trimmingCharacters(in: .whitespaces) }
        var title: String?
        var id = text
        if text.hasPrefix("\""), let close = text[text.index(after: text.startIndex)...].firstIndex(of: "\"") {
            title = String(text[text.index(after: text.startIndex) ..< close])
            id = String(text[text.index(after: close)...]).trimmingCharacters(in: .whitespaces)
            if id.hasPrefix("as ") { id = String(id.dropFirst(3)).trimmingCharacters(in: .whitespaces) }
        }
        var shape = ""
        for (marker, open, close) in [("<<choice>>", "{", "}"), ("<<fork>>", "[", "]"), ("<<join>>", "[", "]")]
        where id.hasSuffix(marker) {
            id = String(id.dropLast(marker.count)).trimmingCharacters(in: .whitespaces)
            shape = open + "\" \"" + close
        }
        let name = Self.identifier(id)
        if opens {
            scopes.append(name)
            return "subgraph \(name)" + (title.map { " [" + Self.quoted($0) + "]" } ?? "")
        }
        if let title { return name + "[" + Self.quoted(title) + "]" }
        return shape.isEmpty ? name : name + shape
    }

    mutating func finish() -> [String] { notes.flowchartLines(quoted: Self.quoted) }
}
