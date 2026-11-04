# 0004: The scene and the cell backend

A layout produces a `DiagramScene`: shapes (boxes with a kind and a role), paths (runs of points joined by horizontal and vertical segments, with markers and a stroke), texts, and the
arena of their bytes, in cells (or any unit a metrics value defines). Roles say what each is for; a backend picks styles. The cell backend keeps, for each cell, the directions its lines leave it
in by weight, and chooses the box-drawing character when the rows are read, so lines that meet make the right corner, tee or cross whichever was drawn first; a character put in a cell wins
over its lines. Rounded corners, double lines (subroutine, double circle), dashed lines (dotted links, frames, lifelines) and heavy lines (thick links, activations) are flags and weights on that
grid. `MermaidMetrics.columns` is the host's width function (ask passes TerminalKit's `UnicodeWidth`), so the diagram agrees with the terminal about where the cursor is.
