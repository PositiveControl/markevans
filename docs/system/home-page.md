# Home page — the thread

`GET /` shows one feature moving through the delivery chain: fifteen flight
strips, one per step, each above an explanation of what the step does. The
design is `docs/plans/2026-10-03-home-thread-design.md`; this doc is how it is
built today. It replaced a single-page portfolio (registry `Portfolio`, a
command palette, scroll reveals), which was deleted in #21.

Without scripts the page reads as a document (design doc, section 6): every
strip open, in order, with no status word and no controls. With scripts the
`playback` controller plays it from the scope, one step at a time, and the
strip bay and the log read out where it is and what it has produced. The page
follows the active strip, pauses the moment the reader scrolls, and docks a
bar of controls at the top once the scope is out of view; each step has a
hash, and the keyboard drives it. The `filter` controller drops back every
controller's rows but one. How both work
is `docs/system/home-thread-playback.md`. Beside each strip the chart cell
draws that row of the git graph. What later slices add is in the table at the
end.

## Where the content lives

Every word on the page except the site name comes from
`content/threads/home.yml` (`docs/rules/content-is-files.md`):

| Key | Shown as |
|---|---|
| `headline` | The page's `h1`, and its meta description |
| `intro` | The paragraph under the headline |
| `steps[]` | One row each, in file order |

`DeliveryThread.fetch(:home)` reads and validates the file
(`app/lib/delivery_thread.rb`). A broken file raises at the first read, and
`bin/rails content:check` fails a production build on a schema error or a
`[placeholder]`. How to change a step: `docs/sop/edit-the-home-thread.md`.

## Structure

`HomeController#index` sets `@thread`; `app/views/home/index.html.slim` lays
it out in `max-w-page` (1320 px) containers. A `div` wrapping `main` and the
footer carries the `playback` and `filter` controllers, so the footer's key
list is in their reach:

| Region | What | From |
|---|---|---|
| Header | The site name, linking to `/`. Nav links arrive with their pages | the view |
| Top row, left (`max-w-column`, 400 px; stacked above the right below 900 px) | The scope, with the controls in its lower gap, then the strip bay, the controller filter and the legend | `ScopeComponent`, `ControlsComponent`, `StripBayComponent`, `ControllerFilterComponent`, `LegendComponent` |
| Top row, right | Headline and intro, then the log | the thread file, `LogComponent` |
| Docked bar (fixed, top) | Controls, the active step's number and name, a strip bay (from 1280 px), a mark per step (from 1024 px); shown only while the scope is out of view | `DockedBarComponent` |
| Thread | Per step (`@thread.cells`): the `aria-hidden` chart cell (`w-column`, or the 84 px `w-gutter` below 900 px), then 20 px across (`pl-strip-gap`) the strip and its body. The row's `id` is the step key, and the step's hash; `-scroll-mt-1`, under the page's 96 px `scroll-pt-16`, puts its strip 96 px down when the page goes to it. It is a playback and a filter `row` target and carries `--seconds`, `data-bay` and `data-lane` | `ChartCellComponent`, `StripComponent`, `StepBodyComponent` |
| Footer | The site's signature and line, from the mock, and the keyboard's keys, hidden until playback connects; the gate count is the thread's | the view |

| Component | Renders |
|---|---|
| `LegendComponent` | The four fix symbols, then the three line styles and the scope target, each named in words |
| `FixMarkComponent` | One fix triangle by step kind: filled for a gate, open for a command, open and dashed for an optional step. Drawn by the legend and the chart |
| `ChartCellComponent` | One row of the git graph from the step's `git` block and its `DeliveryThread::Cell`: main, the branches running through, the fork or merge elbow, the loop bracket, the fix, the branch label, and the sector band, with a dashed edge and label where the bay changes. While playing, an upcoming row's graph dims and the active fix wears a ring |
| `StripComponent` | An `h3` holding the strip as a button: number, command name, Ctl (lane), Bay, the status cell, the Rmk line with the outcome, and the remaining-time line. Ground by kind; dashed border for an optional step. Disabled until playback connects; pending, active and done looks come from the row's `data-state` |
| `StepBodyComponent` | The serif body, then each group as a mono label over a `dl` of mono key and serif value, then the optional artifact (source line and `pre` on `bg-card`) and the optional italic note. Rolls up when its row's `data-open` is false |
| `ScopeComponent` | The radar scope: route ring, crosshair, one target per step on a 270 degree arc (a link to the step), the leader, the centre block, the sweep. All but the ring, crosshair and targets render hidden until playback connects |
| `ControlsComponent` | Restart, step back, play or pause, step forward: 44 px round icon buttons, hidden until playback connects |
| `StripBayComponent` | Todo, In Progress, Up for Review, Done (`DeliveryThread::BAYS`) in four equal cells; the active step's bay fills ink. Hidden until playback connects |
| `ControllerFilterComponent` | All, Human, Agent, CI as 44 px toggles with `aria-pressed`, labelled Controller. Hidden until the filter connects |
| `DockedBarComponent` | A second view of playback: `ControlsComponent`, the step's number and name, `StripBayComponent`, and per step a 44 px link drawn as its scope target. Hidden until playback connects, then shown only while the page is `data-docked` |
| `LogComponent` | Header: Log, gates cleared out of the thread's gate count (`Step#gate?`), artifacts made. Body: an entry per step, newest first, each hidden until its step is done, behind a one-line empty state; scrolls inside 220 px and takes focus. Hidden until playback connects |

Components take a `DeliveryThread::Step` and hold no copy. Their tests build
steps inline rather than reading `home.yml`, so they show every word comes from
the data.

### The chart

A step's `git` block describes only its own row. `Sequence#cells` walks the
steps once and pairs each with what its neighbours decide: `through`, the
branches other than main that run the row's full height (the feature line
between its fork and merge), and `sector`, the bay when it differs from the row
above. `ChartCellComponent` reads only the step and that cell, never a row
index or a step key (`docs/rules/topology-from-data.md`), so reordering the
file redraws the graph.

Lines are 2 px borders placed absolutely. Their positions come from the chart
tokens in `tokens.css`: `--spacing-lane-main`, `-feature` and `-side` (44, 150
and 256 px from 900 px, 14, 38 and 62 px below it), `--spacing-fix` (34 px, the fix's centre), `--spacing-elbow`
(14 px), `--spacing-loop-inset` (10 px), `--spacing-chart-label` (20 px) and
`--spacing-line-half` (1 px, which centres an elbow's 2 px arm on the fix).
They are combined in each line's inline `style` with `var()` and `calc()`.
Tops and bottoms hang off the row's edges, so the lines stretch when a row
grows. The sector's dashed edge is its own line rather than the cell's border,
so main runs unbroken from row to row. Each piece carries a `data-chart` name
(`main`, `through`, `branch`, `elbow`, `loop`, `fix`, `label`, `sector`,
`sector-edge`), and the cell carries `data-git-event`. Tests and the
walkthrough select on these names.

## Narrow screens

The page is built mobile first (`docs/rules/tailwind.md`) around one
breakpoint, `--breakpoint-chart` (900 px), which gives the `chart:` variant.
Below it is a phone's layout; from it, the desktop's (design doc, section 4):

| Part | Below 900 px | From 900 px |
|---|---|---|
| Page padding | 18 px (`px-3`) | 48 px (`chart:px-8`) |
| Top row | Stacked: the scope column (full width, at most 400 px) above the headline | Side by side |
| Chart cell | The 84 px gutter (`w-gutter`), lanes at 14, 38 and 62 px; no sector or branch labels | The 400 px column, lanes at 44, 150 and 256 px, labelled |
| Strip | Number and name on the first line; Ctl, Bay and status in thirds on the second | One row of ruled cells at their widths |

The lanes are CSS variables the chart cell reads with `var()`, so they change
with the width in `tokens.css` (an `@variant chart` block on `:root`) rather
than in a utility. The docked bar has its own steps (`lg:`, `xl:`), set by what
fits in one 44 px row (`docs/system/home-thread-playback.md`, *The docked
bar*). At 390 px nothing scrolls sideways; `test/system/home_narrow_test.rb`
holds that with and without scripts.

## Design system

`app/assets/tailwind/tokens.css` is the design doc's section 3 as Tailwind
theme variables, and `application.css` only imports it. Tailwind's own palette,
faces, sizes, radii, shadows and widths are cleared, so a utility either names
a token or does not exist (`docs/rules/tokens-only.md`; `bin/gates` fails on a
literal color anywhere else).

- **Color is role.** Command, human gate and automated gate each have a color
  and a tint; ink, quiet, rule and the grounds are neutral
  (`docs/rules/color-means-role.md`). There is no dark theme.
- **Type is speaker.** Newsreader (serif) is a person explaining; IBM Plex Mono
  is a command, path, label or machine output
  (`docs/rules/typeface-means-speaker.md`). Both are self-hosted; the layout
  preloads Newsreader roman and Plex Mono 400 and 500.
- **Widths are named.** The strip's cells (`w-step-number`, `w-step-control`,
  `w-step-bay`, `w-step-status`), the row key (`w-row-key`) and the reading
  measures (`max-w-measure`, `max-w-artifact`, `max-w-detail`) are tokens, not
  bracket values.

The template's stock `AlertComponent`, `ErrorSummaryComponent` and
`EmptyStateComponent` are drawn from the same tokens: one neutral box, the
alert's variant named in words.

## Budget

The page stays light, and everything it loads comes from this host (design
doc, section 7). `test/integration/page_budget_test.rb` measures what the page
references as it is served:

| Limit | Measured | Today |
|---|---|---|
| Scripts, 60 kB gzipped | Every entry in the page's importmap and every `script src`, fetched and gzipped. Turbo is most of it | 49.3 kB |
| Fonts, 120 kB | Every font (woff, woff2, ttf, otf, eot) the stylesheets' `url()`s name | 102.7 kB |
| No third party | Every stylesheet, preload, script, image and frame the HTML names, every importmap entry, and every `url()` and `@import` in the page's stylesheets and in each local sheet they import, however deep: no other host | — |

A kB is 1,000 bytes. A new pin, controller or font counts the moment the page
references it. `test/system/page_requests_test.rb` checks the same third-party
rule against every request the browser made, which catches one a script or
stylesheet starts on its own. The integration test runs in `bin/test`, the
system test in `bin/rails test:system`, and both in CI's `test` job. Neither is
in `bin/gates`: Turbo and Stimulus are served from gems, so measuring them
needs Rails.

## Not built yet

| Piece | Slice |
|---|---|
| Narrow screens (84 px gutter, chart labels hidden) | 6 |
| Work, Workflow, Background, Contact; header nav; Person JSON-LD | 7 |

## Tests

| File | Covers |
|---|---|
| `test/integration/home_page_test.rb` | Headline and intro from the file, steps in file order, a chart cell per row drawing the file's forks, merges, loops, sectors and labels, legend, the no-script page (disabled strips, hidden controls, bay, filter, log and docked bar, targets as links), each row's seconds, bay and lane, the log's gate total, the footer and its key list, self-hosted fonts, nothing of the old page |
| `test/integration/page_budget_test.rb`, `test/system/page_requests_test.rb` | The budget (above) |
| `test/system/home_playback_test.rb` | Playback, the bay, the filter, the log, follow, yield, the docked bar, the hash and the keyboard in a browser, and axe while playing, paused, filtered, docked and without scripts (`bin/rails test:system`; see `home-thread-playback.md`) |
| `test/components/{strip,step_body,legend,fix_mark,controls,strip_bay,controller_filter,log}_component_test.rb` | Each component from inline steps |
| `test/components/{scope,docked_bar}_component_test.rb` | Targets, arc and marks from a fixture thread |
| `test/components/chart_cell_component_test.rb` | Fork, merge, loop, lines through, sectors and labels, from the fixture threads in `test/fixtures/files/threads/`; reordering one redraws the graph |
| `test/lib/delivery_thread_test.rb` | The loader, the schema and `cells` |
| `test/assets/tokens_test.rb` | The tokens match the design doc; fonts on disk match those declared |
| `test/integration/seo_test.rb` | Meta description, canonical URL, WebSite JSON-LD |

Walk it in a browser: `bin/qa-walkthrough home_thread`.
