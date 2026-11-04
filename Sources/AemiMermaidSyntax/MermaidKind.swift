/// The kind of diagram a source declares in its first line.
public enum MermaidKind: UInt8, Sendable, Equatable {
    case flowchart, sequence
    /// Diagrams read by translating them into a flowchart: states and transitions, classes and relations, entities and relationships (ADR 0005).
    case state, classes, entities
    case pie

    /// The kind and the direction named by a header line (`flowchart LR`, `graph TD`, `sequenceDiagram`), or nil.
    public static func header(_ line: ArraySlice<UInt8>) -> (kind: MermaidKind, direction: FlowDirection)? {
        let words = line.split(whereSeparator: { $0 == 0x20 || $0 == 0x09 })
        guard let first = words.first else { return nil }
        let name = String(decoding: first, as: UTF8.self)
        switch name {
            case "sequenceDiagram": return (.sequence, .topDown)
            case "stateDiagram", "stateDiagram-v2": return (.state, .topDown)
            case "classDiagram", "classDiagram-v2": return (.classes, .topDown)
            case "erDiagram": return (.entities, .topDown)
            case "pie": return (.pie, .topDown)
            case "flowchart", "graph", "flowchart-v2":
                guard words.count > 1 else { return (.flowchart, .topDown) }
                switch String(decoding: words[words.startIndex + 1], as: UTF8.self) {
                    case "TD", "TB": return (.flowchart, .topDown)
                    case "BT": return (.flowchart, .bottomUp)
                    case "LR": return (.flowchart, .leftRight)
                    case "RL": return (.flowchart, .rightLeft)
                    default: return nil
                }
            default: return nil
        }
    }
}
