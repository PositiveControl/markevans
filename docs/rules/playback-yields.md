---
id: playback-yields
title: "Reader input always wins: scroll, tab switch or selecting a step pauses, and nothing auto-resumes"
applies_to: ["app/javascript/**"]
triggers: ["autoplay", "scroll", "resume", "pause", "visibility"]
see_also: ["one-playback-state", "motion-budget"]
modes: [ web ]
tokens: 450
current_state: matches
---

# playback-yields

Reader input always wins. Scrolling by wheel, touch, keys or the scrollbar, leaving the tab or selecting a step pauses. Nothing resumes by itself.

One exception, and it is not the reader taking over: where the thread starts below the fold, the wheel or touch scroll that brings it into view starts it, and that same scroll does not pause it until it goes quiet for 300 ms. It still drops a follow and a waiting `g`. Keys and the scrollbar pause at once. `scroll()` in the playback controller is this exception, not a breach (`docs/system/home-thread-playback.md`, *Follow and yield*).

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

System tests in `test/system/home_playback_test.rb`, and the arriving scroll in `test/system/home_narrow_test.rb`: a wheel, a touch scroll, a scroll key, a press on the scrollbar, leaving the tab and selecting a step each pause, and nothing resumes after two steps' time. Playback hears the reader's input, not the `scroll` event, so its own follow never counts as one (`docs/system/home-thread-playback.md`, *Follow and yield*). That also means a scroll with no input behind it, from moving focus or find-in-page, does not pause.
