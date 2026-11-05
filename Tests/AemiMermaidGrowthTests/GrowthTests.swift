import AemiMetrics
import AemiTestKit
import Testing

@testable import AemiMermaidLayout
@testable import AemiMermaidScene
@testable import AemiMermaidSyntax
@testable import AemiMermaidText

/// The cost of reading, laying out and drawing, against the size of the diagram (ADR 0002): chains, trees, random sparse graphs and many clusters at 100, 200, 400 and
/// 800 nodes. Instructions of the thread, not time, so the figure does not depend on the machine's load. A doubling of the size that more than triples the
/// cost is a quadratic step; the survey's slowest renderers were that.
@Suite("Cost grows with the diagram, not with its square", .serialized)
struct GrowthTests {
    private static let sizes = [100, 200, 400, 800]

    private static func chain(_ n: Int) -> String {
        "flowchart TD\n" + (0 ..< n - 1).map { "n\($0) --> n\($0 + 1)" }.joined(separator: "\n")
    }

    private static func tree(_ n: Int) -> String {
        "flowchart TD\n" + (1 ..< n).map { "n\(($0 - 1) / 2) --> n\($0)" }.joined(separator: "\n")
    }

    private static func sparse(_ n: Int) -> String {
        var random = SeededRNG(seed: 42)
        var lines = (1 ..< n).map { "n\(Int.random(in: 0 ..< $0, using: &random)) --> n\($0)" }
        for _ in 0 ..< n / 4 {
            lines.append("n\(Int.random(in: 0 ..< n, using: &random)) --> n\(Int.random(in: 0 ..< n, using: &random))")
        }
        return "flowchart TD\n" + lines.joined(separator: "\n")
    }

    private static func clusters(_ n: Int) -> String {
        var lines = ["flowchart TD"]
        for group in 0 ..< n / 4 {
            lines.append("subgraph g\(group)")
            lines.append("a\(group) --> b\(group) --> c\(group) --> d\(group)")
            lines.append("end")
            if group > 0 { lines.append("d\(group - 1) --> a\(group)") }
        }
        return lines.joined(separator: "\n")
    }

    private func instructions(_ source: String) -> Double {
        let bytes = Array(source.utf8)
        let limits = MermaidLimits(
            maxSourceBytes: 4_000_000,
            maxNodes: 5000,
            maxEdges: 20_000,
            maxVirtualNodes: 500_000
        )
        var scene = DiagramScene()
        let renderer = TextRenderer()
        let begin = ProcessProbe.snapshot()
        if case .flowchart(let diagram) = MermaidParse.parse(bytes, limits: limits).result {
            _ = FlowLayout.lay(diagram, limits: limits, into: &scene)
            _ = renderer.rows(scene)
        }
        let delta = ProcessProbe.delta(from: begin, to: ProcessProbe.snapshot())
        return Double(delta.instructions)
    }

    // Hosted CI runners are virtual machines with no performance counters: they count no instructions, which says nothing of the cost.
    @Test(
        .enabled(if: ProcessProbe.snapshot().instructions > 0, "instructions are not counted on this machine"),
        arguments: [
            ("chain", GrowthTests.chain), ("tree", GrowthTests.tree), ("sparse", GrowthTests.sparse),
            ("clusters", GrowthTests.clusters)
        ]
    )
    func `a doubling of the nodes costs less than triple`(name: String, make: @Sendable (Int) -> String) throws {
        // The least of three runs: another test running on another thread can only add to a count, so the least is the run it disturbed least.
        let costs = Self.sizes.map { size in (0 ..< 3).map { _ in instructions(make(size)) }.min() ?? 0 }
        try #require(costs.allSatisfy { $0 > 0 }, "a measured run counted no instructions")
        for (index, pair) in zip(costs, costs.dropFirst()).enumerated() {
            #expect(
                pair.1 / pair.0 < 3.2,
                "\(name): \(Self.sizes[index]) to \(Self.sizes[index + 1]) nodes cost \(pair.1 / pair.0) times as much"
            )
        }
    }
}
