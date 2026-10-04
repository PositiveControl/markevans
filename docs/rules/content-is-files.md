---
id: content-is-files
title: "Site copy lives in content/ — threads, the work list and pages — not templates"
applies_to: ["content/**", "app/components/**", "app/views/**"]
triggers: ["copy", "step text", "thread", "yaml", "project", "page copy", "case study", "CV"]
see_also: ["no-invented-content", "topology-from-data"]
modes: [ web ]
tokens: 330
current_state: matches
---

# content-is-files

Copy lives in `content/`: step copy, topology and artifacts in `content/threads/*.yml`, the projects in `content/work.yml`, and the other pages' copy in `content/pages/*.yml`. Templates hold layout, and structural labels only: nav, section names like "The chain", accessible names.

## Why

A content change is then a small reviewable diff, and the schema gate can check it.

## Wrong

```
p The agent explores the codebase and drafts a design doc.
```

## Right

```
p = step.body
p = @page.intro
```

## Enforcement

Gated: `DeliveryThread`, `Portfolio` and `SitePage` validate their files as they load them, and `bin/rails content:schema` loads every one, failing the production build on a broken or missing file (`docs/system/site-pages.md`). `test/integration/other_pages_test.rb` and `home_page_test.rb` read each page's copy back from the files.
