---
id: topology-from-data
title: "The chart is drawn from each step's git block, never from a row index or step key"
applies_to: ["app/components/chart_cell_component*"]
triggers: ["git", "fork", "merge", "loop", "branch", "lane", "spine"]
see_also: ["content-is-files"]
modes: [ web ]
tokens: 250
current_state: diverges
---

# topology-from-data

The chart is drawn from each step's git block. No row index or step key appears in component code.

## Why

The example thread will change. The graph must redraw from the YAML alone.

## Wrong

```
if index == 4 then draw_fork
```

## Right

```
if step.git.event == "fork" then draw_fork(from: step.git.from)
```

## Enforcement

Component tests for fork, merge and loop; the schema gate checks every fork has a merge.

## Where this app is

There is no `ChartCellComponent` yet. Slice 2 adds it with component tests for fork, merge and loop; slice 1's schema gate checks every fork has a merge.
