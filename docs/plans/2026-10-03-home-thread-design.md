# Home thread — design

Status: Approved (G1, 2026-10-03)
Date: 2026-10-03
Slug: home-thread
**Feature branch:** feature/home-thread

The home page of markevans.io is one real feature moving through the delivery
chain, played as a self-running, steppable sequence of flight strips on a git
spine, with a radar scope as the console.

## 1. Authority

Order of precedence: this doc, then the mock (`docs/design/home-mock.dc.html`),
then anything older.

Take from the mock: layout, tokens, component anatomy, the 15 steps and their
copy, the git topology, strip states, the log.

Do not take from the mock: its markup or its script. It is one file of inline
styles driven by a timer, and it does not run outside the design canvas.
Rebuild it as ViewComponents and Stimulus controllers.

Proposed but not in the mock. Mark was shown these and did not reject them.
Build them unless he says otherwise:

- Playback starts when the thread scrolls into view, not on load.
- The page follows the active strip while playing, and pauses the moment the
  reader scrolls.
- A slim control bar docks at the top when the scope is out of view.
- Each step has its own URL hash.
- Keyboard control, and a complete page with scripts disabled.
- The active strip shows its remaining time as a thin line on its bottom edge.
- Below 900 px the chart narrows to a gutter (section 4).
- Mono face is IBM Plex Mono, as the mock uses.

Still open, do not invent: the example feature that fills the thread, the gate
notes in Mark's voice, the ledger numbers, Background content (CV), what
spamsandwich is. Square brackets in content mark these.

## 2. Context

- Audience: hiring managers first, engineers on the hiring team second.
  There are projects, not clients.
- Positioning line: "I build web products with coding agents under positive
  control: every change planned, gated, reviewed and shipped the same way."
  The home page states that positive control is an air traffic term.
- Routes: `/` (the thread), `/work`, `/work/:project`, `/workflow`,
  `/background` (prints to a one-page CV), `/contact`.
- Stack: Rails 8 from rails-rocket-sheep in web mode; content as YAML and
  Markdown in the repo; three or fewer Stimulus controllers; self-hosted
  fonts; Kamal to Hetzner; domain likely markevans.io. The site has no
  accounts yet. Devise, Petergate and the `User` model stay installed but
  unused: no page, component or controller in this feature depends on them.
- Projects for case studies: rails-rocket-sheep, dopeempire, harness, kraM,
  DailyDrop, spamsandwich.

## 3. Tokens

CSS custom properties on `:root`; only these are exposed to Tailwind. They live in `app/assets/tailwind/tokens.css` as Tailwind theme variables, so each name below carries its namespace there (`--paper` is `--color-paper`, giving `bg-paper`), and the type roles are `--text-headline`, `--text-prose`, `--text-strip`, `--text-key`, `--text-artifact`, `--text-label` and `--text-cell`.

| Token | Value | Role |
| --- | --- | --- |
| `--paper` | `#F7F6F0` | Page ground |
| `--scope` | `#EFEEE6` | Scope face; optional-step strip |
| `--card` | `#FDFDFB` | Artifact block ground |
| `--ink` | `#1B2428` | Text, main line, active outline |
| `--quiet` | `#4A5763` | Labels, pending text, side thread, optional |
| `--command` | `#0F7480` | Command fix, feature branch, links |
| `--command-tint` | `#E4EEF0` | Command strip when active or done |
| `--human` | `#A6651A` | Human gate |
| `--human-tint` | `#F6E9D8` | Human gate strip |
| `--machine` | `#3E7C4F` | Automated gate |
| `--machine-tint` | `#E3EFE6` | Automated gate strip |
| `--rule` | `rgba(27,36,40,0.3)` | Hairlines; 0.55 on active or done strips; 0.15 on the scope crosshair |
| `--sector-1` | `rgba(27,36,40,0.05)` | Sector band: In Progress, Done |
| `--sector-2` | `rgba(27,36,40,0.10)` | Sector band: Up for Review |

No dark theme is designed. Do not add one.

| Role | Face | Size / line height |
| --- | --- | --- |
| Headline | Newsreader 400 | 40 / 48 px, tracking -0.01em |
| Body, step text, notes (italic) | Newsreader 400 | 18 / 30 px |
| Strip command name | IBM Plex Mono 500 | 16 / 24 px |
| Detail row key; artifact | IBM Plex Mono 400 | 14 / 30 px; 14 / 24 px |
| Labels, controls, log, legend | IBM Plex Mono 400, tracking 0.04em | 12 / 18 px |
| Strip cell labels (Ctl, Bay, Rmk) | IBM Plex Mono 400, uppercase | 11 / 16 px |

Space and shape: base unit 6 px (6, 12, 18, 24, 36, 48, 96). Page padding
48 px; content max-width 1320 px. Radius 2 px on boxes; circles only for the
scope, its buttons and the active ring. Lines 1 px; 2 px for git lines and the
active outline. No shadows, no gradients. Touch targets at least 44 px.

| Shape | Meaning |
| --- | --- |
| Open triangle, point down | Command |
| Solid triangle, point down | Gate: amber human, green automated |
| Dashed triangle; dashed strip border | Optional step |
| Solid 2 px line, ink | main |
| Solid 2 px line, command colour | Feature branch |
| Dashed 2 px line, quiet | Side thread that leaves and rejoins |
| Small square or rotated square on the scope | Target: command or gate |
| 32 px ring around a fix | The active step |

## 4. Page structure and components

Three regions inside one 1320 px container:

1. Header. Name left; Work, Workflow, Background, Contact right.
2. Top row. Two columns that wrap. Left, 400 px: the scope console. Right:
   headline, the positive control paragraph, then the log.
3. Thread. One row per step: a 400 px chart cell on the left, a strip on the
   right, 20 px between. The row grows when its strip opens and the chart
   lines stretch with it.

Below 900 px the chart cell narrows to an 84 px gutter with lanes at 14, 38
and 62 px; sector and branch labels are hidden.

| Component | Contract |
| --- | --- |
| `ScopeComponent` | A circle holding: a dashed route ring at 76 percent; a crosshair; 15 targets on a 270 degree arc (first at 135 degrees, last at 45); a leader line from the centre to the active target; a centre block with step number, name, controller, bay and status; four round controls in the gap at the bottom. A sweep line turns once every 6 s while playing and stops when paused. Each target is a button that jumps to its step. |
| `ControlsComponent` | Restart, step back, play or pause, step forward. Icon buttons with `aria-label`. Play is the only filled button. Rendered in the scope and in the docked bar from the same partial. |
| `StripBayComponent` | Four equal cells: Todo, In Progress, Up for Review, Done. The active step's bay is filled ink. |
| `ControllerFilterComponent` | All, Human, Agent, CI as toggles with `aria-pressed`. Non-matching rows drop to 40 percent opacity; never hidden. |
| `LegendComponent` | Two columns: the four fix symbols; the three line styles and the scope target. |
| `LogComponent` | Header: "Log", gates cleared out of 4, artifacts produced. Body: finished steps newest first (number, name, status, outcome). Max height 220 px, scrolls inside. Empty state: one line. |
| `ChartCellComponent` | Draws one row of the git graph from the step's `git` block. Lanes at 44, 150 and 256 px; the fix sits 34 px from the row top. Sector label and dashed top border on the first row of each bay, sector tint behind, branch label where a line starts. Upcoming rows at 35 percent opacity. `aria-hidden`. |
| `StripComponent` | A button of ruled cells: number (44 px), command name (flexible), Ctl (92 px), Bay (132 px), status (96 px). Done strips add a full-width Rmk line with the outcome. |
| `StepBodyComponent` | One serif paragraph, then groups: a mono label over a hairline, then rows of mono key (260 px) and serif value. Optional artifact block (source line, mono body) and optional italic note. |
| `DockedBarComponent` | Not in the mock. Sticks to the top when the scope is out of view: controls, step number and name, strip bay, 15 marks for jumping. As built (#19) it stays one row at every width: the bay and the marks show from 1280 px (`docs/system/home-thread-playback.md`, *The docked bar*). |

Strip states:

| State | Ground | Border | Text | Status word |
| --- | --- | --- | --- | --- |
| Pending | Transparent | 1 px rule at 0.3 | Quiet | pending |
| Active, playing | Kind tint | 1 px rule at 0.55 plus 2 px ink outline | Ink | active; hold on a gate |
| Active, paused | Same | Same | Ink | paused |
| Done | Kind tint | 1 px rule at 0.55 | Ink | done; cleared on a gate |

The active status word takes the step's kind colour. Optional steps use a
dashed border in every state.

## 5. Thread data

`content/threads/home.yml` holds the 15 steps: key, name, kind
(command, human, machine, optional), lane (human, agent, ci), bay, outcome,
body, git (on: main, feature or side; event: start, fork, merge, loop or end;
from; label), groups of key and value rows, and optional artifact, note and
seconds. The file in this bundle is the mock's copy moved over unchanged.

Chart drawing rules:

- main runs through every row. The feature line runs from its fork row to the
  row before its merge.
- A fork draws a 14 px rounded elbow from the parent line into the fix. A
  merge mirrors it.
- A loop draws a dashed bracket from the parent line out to the side lane and
  back, inset 10 px from the row's top and bottom, so it stretches when the
  row opens.
- A row starts a sector when its bay differs from the row above.

## 6. Playback

One Stimulus controller, `playback`, owns three values: step index, playing,
and which finished strips the reader has reopened. Everything else renders
from those.

| Event | Result |
| --- | --- |
| Page loads with no hash | Step 1 active, not playing |
| Thread first scrolls into view | Starts playing, unless reduced motion is set or the reader has already interacted |
| Step timer ends | Next step active; previous strip rolls up; the page follows |
| Timer ends on step 15 | Stops. Play becomes Replay |
| Play or pause pressed | Toggles playing. Play on step 15 restarts from step 1 |
| Step back, step forward | Moves one step and pauses |
| A target, docked mark or pending strip selected | Jumps there and pauses |
| A done strip selected | Opens or closes it. Playback state unchanged |
| Reader scrolls by wheel, touch or keys | Pauses. As built (#19), the wheel or touch scroll that brings the thread into view does not pause until it has been quiet for 300 ms (`docs/system/home-thread-playback.md`, *Follow and yield*) |
| Tab becomes hidden | Pauses. Does not resume by itself |
| Restart | Step 1, reopened strips cleared, paused |
| Page loads with a step hash | That step active, paused, scrolled into view |

- Timing: 6 s per step; a step's `seconds` overrides. Time remaining is a
  2 px ink line along the active strip's bottom edge, emptying left to right,
  frozen when paused.
- Roll-up: animate `grid-template-rows` between `0fr` and `1fr`, 200 ms,
  ease-out. A closed body is `visibility: hidden`.
- Follow: on each automatic step change, scroll so the active strip's top is
  96 px below the viewport top. Smooth, or instant under reduced motion.
  Scrolls the controller starts do not count as reader scrolls.
- Yield: the page never moves while paused except on an explicit jump.
  Resuming scrolls back to the active strip first.
- Docked bar: an IntersectionObserver on the scope toggles it. It is a second
  view of the same state, not a second player.
- Hash: written with `history.replaceState`.
- Keyboard: Space toggles play, `j` next, `k` previous, `g` then 1 to 4 jumps
  to a gate. Ignored while focus is in an input. Listed in the footer.
- Reduced motion: loads paused, no sweep, no smooth scroll, instant roll-up.
- Without scripts: every strip renders open, in order, without a status word.
  Scope targets are links to each step's hash. Controls, filter, log and
  docked bar are not rendered.

## 7. Rules and gates

Twelve conventions ship in `docs/rules/` with this doc. Their frontmatter is a
best guess at the template's fields; conform it and add each to `INDEX.md`.

| Gate | Check | Backs rule |
| --- | --- | --- |
| Placeholder | Fails a production build if content contains a square-bracket placeholder or "TBD" | `no-invented-content` |
| Literal colour | Greps components, styles and scripts for hex or `rgb(` outside the token file | `tokens-only` |
| Thread schema | Required keys; allowed values for kind, lane, bay, git event; exactly one start and one end; every fork has a merge | `content-is-files`, `topology-from-data` |
| Accessibility | axe in system tests on every route, in playing, paused and no-script states | `real-controls`, `never-color-alone` |
| Budget | JavaScript under 60 kB gzipped; fonts under 120 kB; no third-party requests | — |

## 8. Slices

Each lands as its own PR into `feature/home-thread`; the feature PR to `main`
gets the human review. A rule flips from `diverges` to `matches` in the slice
that makes it true.

| # | Slice | Done when | Rules made true | Size |
| --- | --- | --- | --- | --- |
| 1a | Tokens, thread loader and gates (#14) | Token file, Newsreader self-hosted, `DeliveryThread` loader and schema check, placeholder and literal-color gates. No page changes | no-invented-content | ~900 |
| 1b | Static thread page (#21) | The old home page removed, and `/` rendering every strip open with step bodies, header, top row and legend, no scripts. The chart column is an empty 400 px cell. `bin/qa-walkthrough` installed | tokens-only, content-is-files, typeface-means-speaker | ~900 |
| 2 | Chart cell | `ChartCellComponent` draws lanes, fork, merge, loop, sectors and branch labels from each step's `git` block; reordering steps in the YAML redraws the graph; component tests for fork, merge and loop | topology-from-data | ~600 |
| 3 | Playback core | `playback` controller, step timer and remaining-time line, strip states, roll-up, controls, the scope with targets and sweep; the event table rows for play, pause, step, jump, restart, done-strip toggle and tab hidden pass as system tests; axe runs in playing, paused and no-script states | one-playback-state, real-controls, never-color-alone, motion-budget, color-means-role, every-element-answers | ~1,400 |
| 4 | Bay, filter and log | `StripBayComponent`, `ControllerFilterComponent`, `LogComponent` render from playback state; the budget gate (JS under 60 kB gzipped, fonts under 120 kB, no third-party requests) | — | ~600 |
| 5 | Follow, yield and dock | Auto-scroll, pause on reader scroll, docked bar, step hash, keyboard, reduced motion; a reader can scroll away mid-play and still control the flow | playback-yields | ~800 |
| 6 | Narrow screens | The 84 px gutter and stacked top row; no horizontal scroll at 390 px | — | ~400 |
| 7 | Other pages | Work, Workflow, Background (prints to one page), Contact, reusing the components; SEO per page | — | ~1,000 |

## 9. Docs impact

| Doc | Change | Slice |
| --- | --- | --- |
| `docs/system/home-page.md` | Rewritten: the old portfolio page is replaced by the thread | 1b |
| `docs/sop/edit-the-home-thread.md` | New: change a step, its copy or its git block, and what the gates check | 1a |
| `docs/system/home-thread-playback.md` | New: the playback controller, its state and the event table | 3, completed in 5 |
| `docs/sop/add-seo-to-a-page.md` | Updated if the new pages change the procedure | 7 |
