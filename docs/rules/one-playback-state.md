---
id: one-playback-state
title: "Step index, playing and reopened strips live in the playback controller only"
applies_to: ["app/javascript/**"]
triggers: ["stimulus", "controller", "state", "step index", "playing"]
see_also: ["playback-yields", "stimulus"]
modes: [ web ]
tokens: 220
current_state: matches
---

# one-playback-state

Step index, playing, and reopened strips live in the playback controller only. Every view renders from its values.

## Why

The scope, the strips, the log, the bay and the docked bar all show the same step. Two sources of truth will disagree.

## Wrong

```
The scope controller keeping its own currentIndex.
```

## Right

```
The scope reading stepValue from the playback controller via an outlet or event.
```

## Enforcement

Prose only; covered by the system tests for the event table.
