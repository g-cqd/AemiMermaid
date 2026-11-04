# 0001: The engine

**Status:** accepted (2026-11-04). **Context:** ask's roadmap 0196 to 0198; the research note and the plan (mermaid, Markdown viewer and Quick Look).

## Decision

1. **Our own engine.** The survey found six renderers that pass ESC and BEL through, none that bounds nesting, and four that scale worse than linearly. We read, lay out and draw
   ourselves, and use the others only as oracles in scripts.
2. **UTF-8 bytes in, flat arrays out.** A source is read line by line into arrays of small structs (nodes, edges, clusters; participants and events) and one arena of cleaned label
   bytes. No tree of objects, no recursion; subgraphs and fragments are a counter or a stack bounded by `maxNesting`.
3. **Degradation by rule.** A line outside the accepted subset is dropped with a diagnostic (kind, line, column) and the rest stands; a header that is unknown, a limit that is passed,
   or a diagram with nothing in it is refused and the host shows the source. At most sixteen diagnostics are kept and the rest are counted.
4. **Layout in phases on flat arrays** (flowchart): cycles broken by a depth-first walk; ranks by the longest path; a virtual node for each rank an edge crosses, capped by `maxVirtualNodes`;
   the order of each rank improved by median sweeps and adjacent swaps, a fixed number of them, the best order kept; positions by the least squares fit that keeps nodes apart (pooling
   adjacent violators, linear); lanes between ranks by greedy interval colouring; edges routed along the two axes; the direction applied at the end by swapping and flipping axes. Sequence
   diagrams: columns from the widest text between them, rows in event order, fragments as frames.
5. **Width as a limit.** A chart too wide turns left to right into top down, then wraps its labels narrower (24, 16, 10 columns), then is refused with the width it needed.
6. **Not yet:** network simplex ranking and Brandes and Köpf placement (the measured layouts are acceptable; they are an experiment, not a promise), edges to a subgraph's box, state, class,
   ER, pie and Gantt.

## Consequences

The first growth test run found a chain that drifted a cell a rank (a rounding of the centre in the placement), which made the picture quadratic in its size; the fit now uses the same integer
centre as the rest of the layout. Every limit and every phase is a place a test can hit.
