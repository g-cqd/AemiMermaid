# 0005: State, class and entity diagrams are read as flowcharts; a pie chart is bars

**Status:** accepted (2026-11-04).

## Context

State, class and entity-relationship diagrams are, for a layout, graphs of boxes joined by labelled edges. A second parser, a second graph model and a second layout for each would repeat
the flowchart engine's bounds, label cleaning, subgraphs, width fit and tests three times.

## Decision

1. **A line translator in front of the flowchart parser.** `StateTranslator`, `ClassTranslator` and `EntityTranslator` write the source as flowchart text, one line out for each line in, so a
   diagnostic names the line the author wrote; `finish()` adds the nodes whose text was gathered on the way (a class's members, an entity's attributes, a state's description) as lines at the
   end. The flowchart parser then does what it does for any flowchart: limits, label cleaning, layout, width fit.
2. **Generated text cannot become syntax.** Identifiers keep letters, digits and underscores; labels are quoted with the quote and the line ending taken out; a `|` in an edge text becomes `/`.
   A hostile member such as `+x"] --> Evil["pwned` stays a label (a test).
3. **What each kind becomes.** States: nodes, `[*]` a start (●) or an end (◉) node, composite states subgraphs, `<<choice>>` a diamond, `<<fork>>` and `<<join>>` small boxes. Classes: a node whose
   lines are the name, the annotation and the members; inheritance and realisation put the parent on top with the arrow, composition and aggregation a circle at the whole, dependencies dotted;
   cardinalities and the label join into the edge's text. Entities: a node with the attributes, left to right, relationships with `[1 : 0..*]` for the two ends' cardinalities, dotted when non-identifying.
4. **A pie chart is a parse of its own** (`PieDiagram`) laid out as bars in cells (`PieLayout`): a row for each slice, a bar of block characters, its share and, with `showData`, its value. A vector
   backend draws sectors from the same slices.
5. **Not drawn yet:** Gantt, mindmap, journey, timeline, git graph; edges to a subgraph's own box; a class diagram's namespaces; notes in state diagrams (read and left out).

## Consequences

The three kinds cost about 100 lines each and share every guarantee of the flowchart engine. A visual feature of a kind that the flowchart cannot draw (compartments with a rule between the name and the
members, a filled diamond) waits for the vector backend or a cell-level feature of the flowchart nodes.
