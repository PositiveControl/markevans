---
id: topology-from-data
title: "The chart is drawn from each step's git block, never from a row index or step key"
applies_to: ["app/components/chart_cell_component*"]
triggers: ["git", "fork", "merge", "loop", "branch", "lane", "spine"]
see_also: ["content-is-files"]
modes: [ web ]
tokens: 280
current_state: matches
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

`test/components/chart_cell_component_test.rb` covers fork, merge and loop from fixture threads, and shows that reordering a thread redraws the graph. The schema gate checks every fork has a merge. The context a git block cannot carry (the lines running through a row, where a sector starts) comes from `DeliveryThread::Sequence#cells`, so the component never needs a neighbour or a position.

