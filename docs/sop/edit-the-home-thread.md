# Edit the home thread

**Status:** Complete

The home page plays one thread: the steps of a feature moving through the
delivery chain. Every word, kind and branch line on it comes from
`content/threads/home.yml` (`docs/rules/content-is-files.md`). This is how to
change a step, and what checks the change before it ships.

---

## The file

```yaml
id: home                  # must match the filename
title: "…"
steps:
  - key: task_plan        # unique and stable: code and links refer to it
    name: "/task_plan"    # shown on the strip, in mono
    kind: command         # command | human | machine | optional
    lane: agent           # human | agent | ci — who acts
    bay: "In Progress"    # Todo | In Progress | Up for Review | Done
    outcome: "…"          # one line, shown when the strip is done
    body: "…"             # the serif paragraph
    git:
      on: feature         # main | feature | side — the line this step sits on
      event: fork         # optional: start | fork | merge | loop | end
      from: main          # the line a fork, merge or loop leaves from
      label: "feature/[slug]"   # optional: printed where the line starts
    groups:
      - title: "Produces"
        rows:
          - k: "…"        # mono key
            v: "…"        # serif value
    artifact:             # optional
      source: "…"
      body: "…"
    note: "…"             # optional, italic, in Mark's voice
    seconds: 8            # optional; a step plays for 6 s otherwise
```

`kind` decides the strip's color and shape: a command, a human gate (amber), an
automated gate (green) or an optional step (dashed). Pick it for what the step
*is*, not for how it should look (`docs/rules/color-means-role.md`).

## The git block

The chart is drawn from these alone, never from a step's position
(`docs/rules/topology-from-data.md`):

- **main** runs through every row. Exactly one step has `event: start` and
  exactly one has `event: end`.
- **fork** starts a branch: `on: feature, event: fork, from: main`. Every fork
  needs a later `event: merge` whose `from` is that branch.
- **loop** is a side thread that leaves and rejoins within one row:
  `on: side, event: loop, from: <the line it leaves>`. It needs no merge.
- A step with no `event` continues the line it is `on`.

Reordering steps is safe as long as those still hold. The loader says so if
they do not.

`on:` may be written bare. YAML reads a bare `on` key as the boolean `true`,
and the loader accepts that rather than make you quote it.

## Content not written yet

Anything not known goes in square brackets, `"[n]"`, `"[Your note]"`, or as
TBD. Never a plausible number (`docs/rules/no-invented-content.md`).

## Check it

```bash
bin/test test/lib/delivery_thread_test.rb   # the schema: loads every thread file
bin/rails content:placeholders              # what is still in [brackets] or TBD
bin/gates                                   # literal colors, among the other gates
```

The schema runs on every load, so a broken file also fails anything that reads
it, and the whole suite. Errors name the file and the step, all at once:

```
home.yml: g3: kind "robot" is not one of command, human, machine, optional
```

## What runs where

| Check | When | Fails on |
|---|---|---|
| Thread schema (`DeliveryThread`) | Every load, so tests and CI | An `id` that is not the filename; a missing or unknown key; a step key used twice; a value outside the lists above; not one start and one end; a fork that never merges |
| Placeholders (`content:placeholders`) | Production build only, ahead of `assets:precompile` | `[…]` or TBD anywhere in `content/`. A bracket followed by `(` is a markdown link |
| Literal colors (`bin/gates`) | Pre-push and CI | A hex value or a CSS color function (`rgb(`, `hsl(`, `oklch(` …) in components, styles or scripts outside `app/assets/tailwind/tokens.css` |

The placeholder check is kept out of push and CI on purpose: `home.yml` carries
placeholders until the example feature is written, and a gate that fails every
push gets bypassed. It stops the deploy instead, which is the point at which a
placeholder would become a claim on the live site.
