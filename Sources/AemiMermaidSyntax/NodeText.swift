internal import Foundation

/// The text of the nodes a translator is writing, gathered along the source: a name, then lines added to it, in the order the names first appeared. A class's members, an
/// entity's attributes and a state's description all end as `name["name<br/>line<br/>line"]` at the end of the flowchart text.
struct NodeText {
    private var lines: [String: [String]] = [:]
    private var order: [String] = []

    /// Notes that `name` exists, and adds `line` to its text if there is one.
    mutating func add(_ name: String, _ line: String?) {
        if lines[name] == nil {
            lines[name] = []
            order.append(name)
        }
        if let line, !line.isEmpty { lines[name]?.append(line) }
    }

    /// The block whose body is being read (`class Name {` … `}`), if any.
    private var open: String?

    /// Starts reading the body of the block `name`; its lines are `absorb`ed until a line that is only `}`.
    mutating func begin(_ name: String) {
        add(name, nil)
        open = name
    }

    /// Takes `line` as part of the open block's body, through `transform`; false if no block is open. A line that is only `}` closes it.
    mutating func absorb(_ line: String, transform: (String) -> String = { $0 }) -> Bool {
        guard let current = open else { return false }
        if line == "}" {
            open = nil
        } else if !line.isEmpty, !line.hasPrefix("%%") {
            add(current, transform(line))
        }
        return true
    }

    /// `name : text`: adds the text to the name's lines. False if the line has no colon.
    mutating func describe(_ line: String, identifier: (String) -> String) -> Bool {
        guard let colon = line.firstIndex(of: ":") else { return false }
        add(
            identifier(String(line[line.startIndex ..< colon])),
            String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
        )
        return true
    }

    /// One flowchart line for each name, naming the node with its text.
    func flowchartLines(quoted: (String) -> String) -> [String] {
        order.map { name in "\(name)[" + quoted(([name] + (lines[name] ?? [])).joined(separator: "<br/>")) + "]" }
    }
}
