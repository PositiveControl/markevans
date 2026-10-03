# Home page — the thread

`GET /` shows one feature moving through the delivery chain: fifteen flight
strips, one per step, each above an explanation of what the step does. The
design is `docs/plans/2026-10-03-home-thread-design.md`; this doc is how it is
built today. It replaced a single-page portfolio (registry `Portfolio`, a
command palette, scroll reveals), which was deleted in #21.

What renders now is the page as it reads **without scripts** (design doc,
section 6): every strip open, in order, with no status word and no controls.
Beside each strip the chart cell draws that row of the git graph. Playback and
the scope arrive in later slices of the feature; the table at the end says which.

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
it out in one `max-w-page` (1320 px) container:

| Region | What | From |
|---|---|---|
| Header | The site name, linking to `/`. Nav links arrive with their pages | the view |
| Top row, left (`w-column`, 400 px) | The legend. The scope goes above it with playback | `LegendComponent` |
| Top row, right | Headline and intro | the thread file |
| Thread | Per step (`@thread.cells`): the `aria-hidden` chart cell (`w-column`), then 20 px across (`pl-strip-gap`) the strip and its body. The row's `id` is the step key | `ChartCellComponent`, `StripComponent`, `StepBodyComponent` |

| Component | Renders |
|---|---|
| `LegendComponent` | The four fix symbols, then the three line styles and the scope target, each named in words |
| `FixMarkComponent` | One fix triangle by step kind: filled for a gate, open for a command, open and dashed for an optional step. Drawn by the legend and the chart |
| `ChartCellComponent` | One row of the git graph from the step's `git` block and its `DeliveryThread::Cell`: main, the branches running through, the fork or merge elbow, the loop bracket, the fix, the branch label, and the sector band, with a dashed edge and label where the bay changes |
| `StripComponent` | Number, command name (`h3`), Ctl (lane), Bay, an empty status cell, and the Rmk line with the outcome. Ground by kind; dashed border for an optional step. A heading, not a button, until playback |
| `StepBodyComponent` | The serif body, then each group as a mono label over a `dl` of mono key and serif value, then the optional artifact (source line and `pre` on `bg-card`) and the optional italic note |

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
and 256 px), `--spacing-fix` (34 px, the fix's centre), `--spacing-elbow`
(14 px), `--spacing-loop-inset` (10 px), `--spacing-chart-label` (20 px) and
`--spacing-line-half` (1 px, which centres an elbow's 2 px arm on the fix).
They are combined in each line's inline `style` with `var()` and `calc()`.
Tops and bottoms hang off the row's edges, so the lines stretch when a row
grows. The sector's dashed edge is its own line rather than the cell's border,
so main runs unbroken from row to row. Each piece carries a `data-chart` name
(`main`, `through`, `branch`, `elbow`, `loop`, `fix`, `label`, `sector`,
`sector-edge`), and the cell carries `data-git-event`. Tests and the
walkthrough select on these names.

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

## Not built yet

| Piece | Slice |
|---|---|
| Playback, strip states, roll-up, controls, the scope | 3 (`docs/system/home-thread-playback.md`) |
| Upcoming rows dimmed, the active ring on the fix | 3 |
| Strip bay, controller filter, log; the budget gate | 4 |
| Follow, yield, docked bar, step hash, keyboard | 5 |
| Narrow screens (84 px gutter, chart labels hidden) | 6 |
| Work, Workflow, Background, Contact; header nav; Person JSON-LD | 7 |

## Tests

| File | Covers |
|---|---|
| `test/integration/home_page_test.rb` | Headline and intro from the file, steps in file order, a chart cell per row drawing the file's forks, merges, loops, sectors and labels, legend, no controls, self-hosted fonts, nothing of the old page |
| `test/components/{strip,step_body,legend,fix_mark}_component_test.rb` | Each component from inline steps |
| `test/components/chart_cell_component_test.rb` | Fork, merge, loop, lines through, sectors and labels, from the fixture threads in `test/fixtures/files/threads/`; reordering one redraws the graph |
| `test/lib/delivery_thread_test.rb` | The loader, the schema and `cells` |
| `test/assets/tokens_test.rb` | The tokens match the design doc; fonts on disk match those declared |
| `test/integration/seo_test.rb` | Meta description, canonical URL, WebSite JSON-LD |

Walk it in a browser: `bin/qa-walkthrough home_thread`.
