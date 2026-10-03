---
id: typeface-means-speaker
title: "Serif is a person explaining; mono is a command, path, machine output or label"
applies_to: ["app/components/**", "content/**"]
triggers: ["serif", "mono", "font", "typeface", "Newsreader", "Plex"]
see_also: ["tokens-only"]
modes: [ web ]
tokens: 250
current_state: diverges
---

# typeface-means-speaker

Serif is a person explaining. Mono is a command, a file path, machine output or a label.

## Why

The reader can tell who is speaking without a caption. Mixing them removes that.

## Wrong

```
A command name set in serif inside a sentence heading.
```

## Right

```
/task_plan in mono on the strip; its explanation in serif beneath.
```

## Enforcement

Prose only.

## Where this app is

Newsreader is self-hosted and `--font-serif` / `--font-mono` are tokens, but no strips exist yet and the old page still sets everything in IBM Plex. #21 builds the static strips and step bodies.
