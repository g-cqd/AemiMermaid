import Testing

@testable import AemiMermaidLayout
@testable import AemiMermaidScene
@testable import AemiMermaidSyntax

/// Edges between the same two nodes are two lines, and a label is on its own edge and inside the chart (ADR 0007).
@Suite("Edge ports and labels")
struct EdgePortsTests {
    private func scene(_ source: String, width: Int? = 100) -> DiagramScene {
        let parse = MermaidParse.parse(Array(source.utf8), limits: .terminal)
        var scene = DiagramScene()
        _ = MermaidLayout.lay(parse.result, maxWidth: width, into: &scene)
        return scene
    }

    /// The columns of the vertical runs of every path.
    private func verticalColumns(_ scene: DiagramScene) -> [Int32] {
        var columns: [Int32] = []
        for path in scene.paths {
            let points = scene.points[Int(path.first) ..< Int(path.first + path.count)]
            for (a, b) in zip(points, points.dropFirst()) where a.x == b.x && a.y != b.y { columns.append(a.x) }
        }
        return columns
    }

    @Test func `a link and the link back are two lines`() {
        let drawn = scene("flowchart TD\n  A[Idle] --> B[Busy]\n  B --> A")
        let columns = Set(verticalColumns(drawn))
        #expect(columns.count == 2, "\(columns)")
    }

    @Test func `three links between a pair keep a middle one`() {
        let drawn = scene("flowchart TD\n  A[Alpha node] --> B[Beta node]\n  A --> B\n  A --> B")
        #expect(Set(verticalColumns(drawn)).count == 3)
    }

    @Test func `even the narrowest pair gets two lines, and a diamond keeps its tip`() {
        #expect(Set(verticalColumns(scene("flowchart TD\n  A --> B\n  B --> A"))).count == 2)
        let diamond = scene("flowchart TD\n  A{Is it?} --> B[Yes sir]\n  B --> A")
        // Both lines leave the diamond's tip; they part at the other end, which is wide enough for two.
        let tip = Set(diamond.paths.map { diamond.points[Int($0.first)].x })
        #expect(tip.count == 1, "\(tip)")
    }

    @Test func `two edges into one node arrive in columns of their own`() {
        let drawn = scene("flowchart TD\n  A[Start node] --> C[Target node]\n  A --> B[Middle node]\n  B --> C")
        let ends = drawn.paths.map { drawn.points[Int($0.first + $0.count - 1)] }
        let lowest = ends.map(\.y).max() ?? 0
        #expect(Set(ends.filter { $0.y == lowest }.map(\.x)).count == 2, "\(ends)")
    }

    @Test func `the label of a link sits beside its own line`() {
        let drawn = scene("flowchart TD\n  A[Idle] -->|go| B[Busy]\n  B -->|back| A")
        let columns = verticalColumns(drawn).sorted()
        let go = drawn.texts.first { drawn.string($0.text) == "go" }
        let back = drawn.texts.first { drawn.string($0.text) == "back" }
        #expect(go != nil && back != nil)
        guard let go, let back, let left = columns.first, let right = columns.last else { return }
        // The first link's line is the left one: its label is to the left of it, or at least left of the other line's label.
        #expect(Int32(go.x) < right && Int32(back.x) > left)
        #expect(Int32(go.x) < Int32(back.x))
    }

    @Test(arguments: [
        "flowchart TD\n  A -->|a long label here| B\n  B -->|another long label| A",
        "flowchart LR\n  A -->|x| B\n  A -->|y| C\n  C -->|z| A",
        "flowchart TD\n  A[Idle] -->|start| B[Busy]\n  B -->|done| A\n  B -->|fail| C",
        "stateDiagram-v2\n  [*] --> Idle\n  Idle --> Busy: start\n  Busy --> Idle: done"
    ])
    func `every label is inside the chart`(source: String) {
        let drawn = scene(source)
        for text in drawn.texts {
            let width = Int32(drawn.string(text.text).count)
            let left = text.anchor == .leading ? Int32(text.x) : Int32(text.x) - width / 2
            #expect(
                left >= 0 && left + width <= drawn.width,
                "\(drawn.string(text.text)) at \(text.x) in \(drawn.width)"
            )
            #expect(text.y >= 0 && Int32(text.y) < drawn.height)
        }
    }
}

/// Frames round clusters do not run into one another or into the nodes outside them.
@Suite("Cluster frames")
struct ClusterFrameTests {
    private func frames(_ source: String) -> (frames: [SceneShape], others: [SceneShape]) {
        let parse = MermaidParse.parse(Array(source.utf8), limits: .terminal)
        var scene = DiagramScene()
        _ = MermaidLayout.lay(parse.result, maxWidth: 200, into: &scene)
        return (scene.shapes.filter { $0.kind == .frame }, scene.shapes.filter { $0.kind != .frame })
    }

    private func overlap(_ a: SceneShape, _ b: SceneShape) -> Bool {
        a.x < b.x + b.width && b.x < a.x + a.width && a.y < b.y + b.height && b.y < a.y + a.height
    }

    @Test func `two sibling clusters do not overlap`() {
        let found = frames(
            "flowchart LR\n  subgraph A\n    a1 --> a2\n  end\n  subgraph B\n    b1 --> b2\n  end\n  a1 --> b1\n  b2 -.-> w([W])"
        )
        #expect(found.frames.count == 2 && !overlap(found.frames[0], found.frames[1]))
    }

    @Test func `a node outside every cluster is outside every frame`() {
        let found = frames("flowchart TD\n  subgraph C\n    a1 --> a2\n  end\n  u([User]) --> a1\n  a2 --> z([Z])")
        let outside = found.others.filter { shape in
            !found.frames.contains {
                $0.x <= shape.x && shape.x + shape.width <= $0.x + $0.width && $0.y <= shape.y
                    && shape.y + shape.height <= $0.y + $0.height
            }
        }
        #expect(outside.count == 2, "the user and the target are outside, the cluster's two nodes inside")
    }

    @Test func `nested clusters keep their children inside and siblings apart`() {
        let found = frames(
            "flowchart TD\n  subgraph O\n    subgraph P\n      p1 --> p2\n    end\n    subgraph Q\n      q1 --> q2\n    end\n  end\n  p2 --> q1"
        )
        #expect(found.frames.count == 3)
        let inner = found.frames.filter { $0.width < found.frames.map(\.width).max() ?? 0 }
        #expect(inner.count == 2 && !overlap(inner[0], inner[1]))
    }
}
