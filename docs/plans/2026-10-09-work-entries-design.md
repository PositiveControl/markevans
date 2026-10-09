# Work entries — design

Status: Approved (G1, 2026-10-09)
Date: 2026-10-09
Slug: work-entries
**Feature branch:** feature/work-entries
Issue: #42 (slices #43, #44, #45, #46)

Make each `/work/:id` page more than a static case study. The reader should be
able to *see* the work move, the way the home page shows the chain, and
come away with what it taught: the learnings, the surprises, the takeaways.

## Problem

A project page today (`docs/system/site-pages.md`) is a name, a summary, links,
and two sections of prose: *The project* and *How it was built*. After #38 the
first section is real copy cut from the CV; the second is still a placeholder
for every project.

Readers are hiring managers first and engineers on the hiring team second (home
thread design, section 2). A hiring manager scans for judgement: what went
wrong, what was noticed, what changed because of it. An engineer wants to see
the work happen. A page of prose gives neither of them much. The home page
already proves the site can *show* a delivery chain. Project pages only
*describe* one.

Two things are missing:

1. **Something to step through.** The reader should be able to play or step
   through how a project was built, not just read a paragraph about it.
2. **Findings set apart from narrative.** Learnings, surprises and takeaways
   are the most useful thing a case study can say, and today they would be
   buried in paragraphs.

## Constraints

- **Content is files** (`docs/rules/content-is-files.md`). Every word comes from
  `content/`; templates hold layout and structural labels.
- **No invented content** (`docs/rules/no-invented-content.md`). A finding, a
  step, a number or an artifact comes from a repo or from Mark. Until then it
  stays in `[brackets]`, and the placeholder gate blocks production. This
  is the main cost of the feature: the machinery is cheap, and the content
  is Mark's to write.
- **Color means role** (`docs/rules/color-means-role.md`). Command teal, human
  amber and machine green are taken. A finding's kind cannot have a color of
  its own. It is shown by a shape and a word, in ink
  (`docs/rules/never-color-alone.md`).
- **Every element answers** and **motion budget**. Nothing decorative, nothing
  that moves without a state change. No autoplaying video.
- **One playback state** (`docs/rules/one-playback-state.md`). A project page
  that plays a thread uses the same `playback` controller, not a second player.
- **Stimulus budget.** The home thread design caps the site at three or fewer
  Stimulus controllers of its own (`playback` and `filter` today). This feature
  adds none. It reuses `playback` and generalises `filter`.
- **Works without scripts.** As on `/`, a project page reads as a complete
  document with scripts off.
- **Depends on #38.** `content/work.yml` is rewritten there (keys, the
  IDLEmpire rename, real copy). This feature builds on that file, so it
  starts after #38 merges.
- Not paginated, no database, no accounts: unchanged from the site pages.

## Approach

Three additions to a project entry, each optional per project, so a project
with nothing to show yet simply shows less.

### 1. Findings: learnings, surprises, takeaways

A new optional `findings:` list on each project in `content/work.yml`:

```yaml
findings:
  - kind: surprise          # learning | surprise | takeaway
    title: "A single clean critic pass was not convergence"
    body: "…serif paragraph in Mark's voice…"
    evidence:               # optional; a real link, or [bracketed]
      label: "PR #142"
      url: https://github.com/…
    step: implement         # optional; a step key in this project's thread
```

- `Portfolio` validates the list, with the same error collection as today:
  known kinds, required title and body, URL rules from `SitePage.links`, and a
  `step` that names a real step in the project's thread.
- `FindingsComponent` renders them as a section after *The project*. Each
  finding shows its kind as a mono label word plus a shape (the shape set is
  for the G1 review; something like ◇ learning, ! surprise, → takeaway, all in
  ink), a serif title and body, and the evidence link in mono.
- **Interactive:** a row of kind toggles (All, Learnings, Surprises,
  Takeaways) dims the findings that don't match and never hides them. This is
  exactly the controller filter's contract. `filter_controller.js` is
  generalised from "lane" to any data attribute (`data-filter-key-value`).
  It stays one controller. The toggles render hidden without scripts, as the
  lane filter's do.
- Accessibility: kinds are words, so a screen reader hears "Surprise". The
  toggles are `aria-pressed` buttons. The list is a `ul` with an accessible
  name.

### 2. A project's own delivery thread (the demo)

A new optional `thread:` key on a project names a file in `content/threads/`.
That file uses the same schema `DeliveryThread` already validates.
`content/threads/harness.yml`, for example, would be the harness's real path
from issue to merge.

- The project page renders the thread with the existing components: chart
  cell, strip, step body, and the controls in a compact bar. The scope, the
  log and the strip bay stay home-page only. On a project page the thread is
  evidence for the case study, and the console would crowd it. The playback
  controller already treats those targets as optional (`hasScopeTarget`,
  `hasLogEmptyTarget`), so this should need no new state.
- Without scripts it reads as a document, every strip open, as `/` does.
- `DeliveryThread::ROUTED` stops being a constant list. It becomes `home` plus
  every thread a project names, so `content:schema` fails the build when a
  project points at a missing thread.
- *How it was built* stays as the prose lead-in above the thread. A project
  with no thread keeps the paragraph alone.

This is what "demoable" means in this design: the reader replays the
build itself, not a video of the product. It uses machinery the site already
has, and it matches the site's thesis: every change planned, gated, reviewed
and shipped the same way.

### 3. Findings pinned to where they happened

When a finding names a `step`:

- The finding's mono label links to `#<step key>`. The playback controller
  already opens a step from its hash, paused and scrolled into view.
- That step's body shows a one-line marker in mono with the finding's kind
  word and title, linking back to the finding (`#finding-<n>`). It goes in
  the same slot as the existing optional note.

So the reader can go both ways: from "what was surprising" to the moment it
happened, and from a moment in the build to what it taught.

### On `/work` (the index)

Each project in the list gains one quiet mono line under its summary, with
the count of each kind (e.g. `2 learnings · 1 surprise`) and `thread` if
it has one. The words come from the data, not from template copy. The index
stays a list. It does not become a dashboard.

## Rejected alternatives

- **Screen recordings or GIF demos as the main demo.** They autoplay or need a
  poster and controls. They go stale as the product changes, and they weigh
  far more than the rest of the site. They show the product, not the
  judgement. A recorded video can be added later as an ordinary link in
  `links:`.
- **Live embedded demos** (an in-browser kraM REPL via WASM, a harness
  sandbox). Each is a project of its own, one per project, with its own
  runtime and security surface. Out of scope. A project's own site link is
  the "try it".
- **A color per finding kind.** Breaks `color-means-role`: the three colors
  already mean command, human gate and machine gate.
- **Findings as a free-form section with headings** (`heading: Surprises`).
  These are not typed, so they can't be filtered, counted or pinned to a
  step, and every project would format them differently.
- **A separate `content/findings/*.yml` per project.** Splits one project
  across files for no gain. The project entry is the unit a reviewer reads.
- **A new Stimulus controller for the finding filter.** Same contract as the
  lane filter; generalising it keeps the controller budget.
- **Showing the full home console (scope, log, bay) on every project page.**
  Four consoles of the same chain read as a template. The thread rows carry
  the evidence.

## Settled at G1

Mark approved the design as written on 2026-10-09, so each question that was
open takes this doc's default:

1. **"Demoable" is the replayed delivery thread.** Product media and live
   demos are deferred.
2. **Which projects get a thread is decided by the content, not the code.** Slice 3
   ships one project's thread as a `[bracketed]` skeleton. A thread is written
   only for a project with real history to read it from (issues, PRs, gates).
   A project without one shows findings alone.
3. **Three kinds: learning, surprise, takeaway.** Narrowing to two later is a
   schema change in one file.
4. **The kind shapes are picked in slice 1's review.** The rule: each is
   distinct in greyscale from the four fix symbols (open, solid and dashed
   triangles; the scope's square and rotated square).
5. **The `/work` index shows counts per kind**, and `thread` when there is
   one (slice 4).

Deferred, explicitly: product media (screenshots, video), live demos, and
views across projects (e.g. "every surprise across all projects").

## Decomposition

Multi-slice. Lands on `feature/work-entries`, after #38 merges to `main`.

| # | Slice | Delivers | Size |
|---|---|---|---|
| 1 | Findings (#43) | `findings:` schema in `Portfolio` (kinds, evidence, errors), `FindingsComponent` with kind shape and word, the section on the project page, `[bracketed]` findings in `content/work.yml` for each project, component, loader and integration tests, axe at 390 and 1400 px | ~600–800 |
| 2 | Finding filter (#44) | Generalise `filter_controller.js` to any key; kind toggles on the project page; lane filter on `/` unchanged (its system tests stay green); system test for dim-not-hide and no-script | ~300–450 |
| 3 | Project thread (#45) | `thread:` key, `DeliveryThread::ROUTED` derived from projects, the thread on the project page with a compact controls bar (no scope, log or bay), no-script document, `content:schema` coverage, one project's thread file as `[bracketed]` skeleton, system tests for play, step and hash | ~900–1,300 |
| 4 | Pinned findings and index (#46) | `step:` on a finding validated against the thread, two-way links, the marker in the step body, the `/work` index line, docs completed, QA walkthrough | ~400–600 |

Writing the content (real findings, real threads) is Mark's work and is not
a slice. Each slice ships placeholders the gate will hold until they are
written. Slices land in order: 2 needs 1's findings, 3 is independent of
both but follows them, and 4 needs 1 and 3.

## Docs impact

| File | Change |
|---|---|
| `docs/system/site-pages.md` | Update: `findings` and `thread` keys on `content/work.yml`, the new component, the `/work` index line, the 404 and schema notes |
| `docs/system/home-thread-playback.md` | Update: the controller also plays a project's thread; which targets are optional; the filter's generalised key |
| `docs/system/project-entries.md` | **Create**: how a project page is assembled (findings, thread, pins), the kind shapes and words, no-script behaviour |
| `docs/sop/write-a-project-entry.md` | **Create**: writing findings and a project thread from a repo's real history without inventing anything; the gates to run |
| `docs/rules/content-is-files.md` | Update its list of content files to include project threads |
| `docs/plans/2026-10-03-home-thread-design.md` | Note in section 6 that playback has a second consumer |
