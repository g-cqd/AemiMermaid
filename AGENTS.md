# Working in AemiMermaid

Mermaid diagrams read, laid out and drawn by our own code. Read `docs/adr/0001-the-engine.md` first.

- **No recursion, no failure.** Any bytes give a parse result; nesting is a counter or an explicit stack with a limit in `MermaidLimits`. A new loop needs its bound.
- **Linear time.** `GrowthTests` fits instructions against size; a change that makes a doubling cost more than three times fails it. Fix the cause (the test found a drifting
  chain on its first run).
- **Text is cleaned on the way in and again on the way out.** `LabelSanitizer` for the source, the cell writer for the scene. Never hand a label to a terminal without the second.
- **Roles, not colours.** A scene says what a shape is for; a backend picks the style.
- **A test that cannot fail says nothing.** `SceneLinterTests` shows the linter finds what it is for; a new rule gets a failing case first.
- **Dependencies:** packages from `g-cqd`, `Aemi-Studio`, `apple` and `swiftlang` only. The external Mermaid renderers are oracles in scripts.
- Style: Aemi's `.swift-format` and `.swiftlint.yml`; one primary type per file; files under 250 lines; docs say why, not what.
