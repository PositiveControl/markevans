---
id: playback-yields
title: "Reader input always wins: scroll, tab switch or selecting a step pauses, and nothing auto-resumes"
applies_to: ["app/javascript/**"]
triggers: ["autoplay", "scroll", "resume", "pause", "visibility"]
see_also: ["one-playback-state", "motion-budget"]
modes: [ web ]
tokens: 250
current_state: diverges
---

# playback-yields

Reader input always wins. Scrolling, leaving the tab or selecting a step pauses. Nothing resumes by itself.

## Why

A page that moves under a reader who has taken over is the fastest way to lose them.

## Wrong

```
Resuming playback after five seconds without input.
```

## Right

```
Staying paused until the reader presses Play.
```

## Enforcement

System tests: scroll during play pauses; no timer restarts it.

## Where this app is

Playback does not exist yet. Slice 3 adds pause on selection and tab hide; slice 4 adds pause on scroll and the system tests that no timer resumes it.
