---
id: content-is-files
title: "Step copy, topology and artifacts live in content/threads/*.yml, not templates"
applies_to: ["content/**", "app/components/**", "app/views/**"]
triggers: ["copy", "step text", "thread", "yaml"]
see_also: ["no-invented-content", "topology-from-data"]
modes: [ web ]
tokens: 310
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

Gated: `DeliveryThread` validates a thread file as it loads it, and `test/lib/delivery_thread_test.rb` loads every file in `content/threads/`.

## Where this app is

`DeliveryThread` reads `content/threads/home.yml` and is the schema gate (`test/lib/delivery_thread_test.rb` loads every thread file), but no page renders from it yet. The current home page keeps its copy in `app/lib/portfolio.rb` and the `app/views/home/` partials. #21 renders the thread from the file and deletes those.
