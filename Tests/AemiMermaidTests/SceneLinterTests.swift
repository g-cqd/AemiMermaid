import Testing

@testable import AemiMermaidScene

/// The linter has to be able to fail, or its silence on the layouts says nothing.
@Suite("The scene linter catches what it is for")
struct SceneLinterTests {
    private func box(_ x: Int32, _ y: Int32, _ role: SceneRole = .node) -> SceneShape {
        SceneShape(kind: .rectangle, role: role, x: x, y: y, width: 5, height: 3, text: .empty, order: 0)
    }

    private func scene(_ shapes: [SceneShape], path: [ScenePoint]? = nil) -> DiagramScene {
        var scene = DiagramScene()
        scene.width = 40
        scene.height = 20
        scene.shapes = shapes
        if let path { scene.addPath(path, role: .edge) }
        return scene
    }

    @Test func `overlapping nodes, a shape outside the scene, and a slanted segment`() {
        #expect(!SceneLinter.problems(scene([box(0, 0), box(3, 1)])).isEmpty)
        #expect(!SceneLinter.problems(scene([box(38, 0)])).isEmpty)
        #expect(!SceneLinter.problems(scene([], path: [ScenePoint(x: 0, y: 0), ScenePoint(x: 3, y: 3)])).isEmpty)
        #expect(SceneLinter.problems(scene([box(0, 0), box(10, 0)])).isEmpty)
    }

    @Test func `an edge through a node it does not touch`() {
        let a = box(0, 0)
        let b = box(0, 12)
        let middle = box(0, 6)
        let path = [ScenePoint(x: 2, y: 2), ScenePoint(x: 2, y: 11)]
        #expect(!SceneLinter.problems(scene([a, middle, b], path: path)).isEmpty)
        #expect(SceneLinter.problems(scene([a, b], path: path)).isEmpty)
    }
}
