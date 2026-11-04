# 0007: Parallel edges have ports, and a label sits on its own edge

**Status:** accepted (2026-11-04).

## Context

In the first layouts every edge used the centre of its node, so two edges between the same pair (a link and the link back, as in every state machine) were drawn on top of each other, and the labels
of the edges leaving a node were stacked beside one shared line: a reader could not tell which label belonged to which edge, and a label could stick out of the chart and be cut off.

## Decision

1. **Ports.** Two or three edges between the same two nodes leave and arrive in columns of their own, spread across the width of the nodes (two cells apart at most, three edges keep one on the
   centre). Nothing changes for a pair joined once, for nodes too narrow to hold two lines, or for diamonds, whose outline meets a line only at its tip.
2. **A label takes the side its edge turns to**: left of the line when the target is to the left (above it, when ranks run left to right and the target is above), otherwise right, and past a sibling
   line when it has one. The chart grows on the side where a label sticks out (the `overhang`), so no label is cut off.
3. **An edge runs on to the border of the shape it touches**, with a marker or without, in the vector and CoreGraphics backends: a plain link no longer stops a cell short.

## Consequences

Edges that cross between different pairs still share centres; ports for every edge (ordered by target, so lines do not cross) are the next step and need the same `portShift` per hop.
