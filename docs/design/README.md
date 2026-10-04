# Design reference

`home-mock.dc.html` is the source of the decided home page mock (option 4:
the left column is the chart). It is a reference, not a starting point:

- It depends on the design canvas runtime (`support.js`) and will not render
  if opened directly in a browser.
- Read it for exact values: inline styles carry every measurement, and the
  `data()` method carries the step copy (already moved to
  `content/threads/home.yml`). `renderVals()` shows how each state is styled
  and how the git lines are drawn.
- Do not copy its structure. `docs/plans/2026-10-03-home-thread-design.md`
  says how to rebuild it.

Add screenshots of the mock here (playing, paused, a gate on hold, a done
strip reopened) so the design is visible without the canvas.
