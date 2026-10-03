---
id: content-is-files
title: "Step copy, topology and artifacts live in content/threads/*.yml, not templates"
applies_to: ["content/**", "app/components/**", "app/views/**"]
triggers: ["copy", "step text", "thread", "yaml"]
see_also: ["no-invented-content", "topology-from-data"]
modes: [ web ]
tokens: 270
current_state: diverges
---

# content-is-files

Step copy, topology and artifacts live in content/threads/*.yml. Templates hold layout only.

## Why

A content change is then a small reviewable diff, and the schema gate can check it.

## Wrong

```
p The agent explores the codebase and drafts a design doc.
```

## Right

```
p = step.body
```

## Enforcement

Gated: the thread schema gate validates every thread file.

## Where this app is

`content/threads/home.yml` exists but nothing reads it, and the thread schema gate does not exist. The current home page keeps its copy in `app/lib/portfolio.rb` and the `app/views/home/` partials. Slice 1 adds the schema gate and renders the thread from the file.
