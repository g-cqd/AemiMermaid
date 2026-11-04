# 0006: The vector backend writes SVG

**Status:** accepted (2026-11-04).

## Context

The cell backend draws diagrams for terminals. A Quick Look preview, a document viewer and a thumbnail need the same diagrams as vector graphics that zoom without loss, in the system font,
with light and dark appearance, with no raster on the way. Quick Look accepts HTML replies, and an SVG in an HTML page is vector, selectable and styled by the page.

## Decision

1. **`AemiMermaidSVG` writes SVG from the scene** the layout already makes: the scene's cells are a grid of 9 by 18 units (a character cell of a 13-point system font), lines run through the middle of
   their cells, markers are polygons at the end of a path that run on to the edge of the cell that holds them. No new layout, no pixel metrics: the diagram is the one the terminal shows, drawn with
   curves, joins and the system font. A pie chart is drawn from its slices as sectors and a legend (`PieSVG`).
2. **Roles are classes of one style sheet** with CSS variables and a light and a dark default (`prefers-color-scheme`); a page that draws several diagrams embeds the sheet once. A theme or an appearance
   change restyles the picture with no layout.
3. **Nothing a label says reaches the markup.** Text goes through `SVGText.escaped` (the five XML characters escaped; scalars XML 1.0 forbids and bidirectional controls dropped); the writer
   emits a fixed set of elements and attributes, no `script`, `foreignObject`, `image`, event handler or link, and a test checks every corpus diagram parses as XML and has none.
4. **Not in this decision:** proportional-font metrics (labels are centred in boxes sized for cells, so a proportional face leaves a little room, never overflow), curved edges, compartments in class
   boxes, a CoreGraphics backend for native views.
