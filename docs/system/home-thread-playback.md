# Home thread playback

**Status:** Current through #17 (bay, filter and log). #18 adds follow, yield on
scroll, the docked bar, the step hash and the keyboard; rows marked *#18* below
are not built yet.

How the home thread plays. The design is section 6 of
`docs/plans/2026-10-03-home-thread-design.md`; the page around it is
`docs/system/home-page.md`.

## One controller, three values

`app/javascript/controllers/playback_controller.js` sits on the page's `main`
and owns all playback state (`docs/rules/one-playback-state.md`):

| Value | Type | Means |
|---|---|---|
| `step` | Number | The active step's index, from 0 |
| `playing` | Boolean | Whether the step clock runs |
| `open` | Array | Indexes of done strips the reader has reopened |
| `pace` | Number | Milliseconds per second of step time, default 1000. Only system tests change it |

Nothing else holds playback state. The scope, the strips, the chart, the bay
and the log all render from these values, and the page renders without
scripts as a document (below). The controller filter's lane is held apart
(The filter, below).

## How state reaches the page

`render()` writes the values onto the page as attributes and words. It never
writes a class: the templates style from these attributes with Tailwind's
`in-data-*` variants, which match any ancestor (`docs/rules/tailwind-build.md`).

| Written on | Attribute or text | Read by |
|---|---|---|
| `main` | `data-playing` while playing | Play's icon, the sweep and the remaining-time line (`in-data-playing:`) |
| `main` | `data-ended` once the last step's time has run out | `connect()`, after a cache restore: the clock is not an attribute, so this is how a played-out thread comes back played out |
| `main` | `--pace`, `--leader-angle` | The line's duration; the leader's rotation |
| Each row (`data-playback-target="row"`) | `data-state`: `pending`, `active` or `done` | Strip ground, outline and Rmk line; the chart's dimming and ring |
| Each row | `data-open`: `true` or `false` | The body's roll-up |
| Each strip button | `aria-expanded`; enabled on connect | Assistive tech |
| Each status cell | The status word | Read as text |
| Each scope target | `data-state`, `aria-current="step"` on the active one | The target's mark fill |
| Scope readout | Number and name, Ctl · Bay, status word, `data-kind` | The centre block |
| Play button | `aria-label`: Play, Pause or Replay | Assistive tech |
| The strip bay cell matching the active row's `data-bay` | `data-current`, `aria-current="true"` | The ink fill (`data-current:`) |
| Each log entry (`data-index` below the step, or every one once the last step's time has run out) | `hidden` removed; the rest hidden | The log, newest first |
| Log empty line | `hidden` once any step is done | The one-line empty state |
| Log header | Gates cleared and artifacts made: the shown entries with `data-gate` or `data-artifact` true | Read as text |

The status word is the active step's state in words (`docs/rules/never-color-alone.md`):

| State | Command or optional | Gate (human or machine) |
|---|---|---|
| Pending | pending | pending |
| Active, playing | active | hold |
| Active, paused | paused | paused |
| Done | done | cleared |

Which steps are gates the server decides (`Step#gate?`) and writes as
`data-gate` on each strip and scope target; the controller reads it rather
than keeping its own list of gate kinds.

A row's seconds come from the server as `style="--seconds: N"` (`Step#duration`,
6 unless the step sets `seconds`). The clock reads it, and so does the line.

The log's entries are rendered by the server, one per step in reverse order,
with the word its strip ends on (cleared for a gate, done otherwise) and its
outcome. The controller only shows them, so it builds no markup.

## The filter

The controller filter is not playback state: picking a lane leaves the step,
playing and reopened strips as they were. A second controller,
`app/javascript/controllers/filter_controller.js`, sits on `main` beside
`playback` and owns one value, `lane` (`all`, `human`, `agent` or `ci`;
default `all`). Its `render()` writes `aria-pressed` on each option and
`data-dim` on every row whose `data-lane` does not match. Nothing is hidden: a
dimmed row's chart graph drops to 40 percent, its strip loses its ground and
strong rule, and its strip and body text turn quiet. Text at 40 percent would
fail axe's contrast check. An upcoming row's strip already wears those
colors, so filtering it out shows only in its graph, which drops from 35
percent to 15.

## The step clock

The active step plays for its seconds × `pace` ms. Pausing keeps what is left,
and so does going to the step that is already active: selecting it again, or
back on the first step and forward on the last. A new step, a restart or
a pace change starts it full. When it runs out, the
next step becomes active. On the last step it stops, and Play reads Replay.

The remaining-time line is the same clock drawn in CSS: `animate-remaining` in
`app/assets/tailwind/application.css` empties a 2 px ink line over
`--seconds × --pace`. Its `animation-play-state` follows `data-playing`, so it
freezes when paused. When the clock restarts on the same step, the controller
rewinds the line's animation.

## Event table

| Event | Result | Built |
|---|---|---|
| Page loads with no hash | Step 1 active, not playing | #16 |
| Thread first scrolls into view | Starts playing, unless reduced motion is set or the reader has already used a control. An `IntersectionObserver` on the thread section; it fires once | #16 |
| Step timer ends | Next step active; the previous strip rolls up | #16 (the page follows: #18) |
| Timer ends on the last step | Stops; Play becomes Replay. The step stays active, and the log lists it and counts its gate and artifact | #16; the log, #17 |
| Play or pause pressed | Toggles playing. Play on the last step (Replay) clears reopened strips and plays from step 1 | #16 |
| Step back, step forward | Moves one step and pauses | #16 |
| A target or pending strip selected | Jumps there and pauses. A target is a link to its step; the controller cancels the navigation | #16 (docked mark: #18) |
| A done strip selected | Opens or closes it. Playback state unchanged | #16 |
| Reader scrolls by wheel, touch or keys | Pauses | #18 |
| Tab becomes hidden | Pauses. Does not resume by itself | #16 |
| Restart | Step 1, reopened strips cleared, paused | #16 |
| Page restored from Turbo's cache | Comes back on the step it left, paused, and does not start on view: the values persist in data attributes, so `connect()` sets playing false and counts rows that already carry a `data-state` as a page the reader has been on. A thread that had played out (`data-ended`) comes back played out, its last step still in the log | #16; played out, #17 |
| Page loads with a step hash | That step active, paused, scrolled into view | #18 |

## Without scripts

The controller never connects, so nothing above is written and the templates
fall back to the document reading (design doc, section 6):

- Every body is open, because no `data-open` is set.
- Strips render in the done colours, `disabled`, with an empty status cell.
- Scope targets are plain links to each step's `#key`.
- The sweep, leader, centre block, controls, strip bay and log carry the
  `hidden` attribute. On connect the controller removes it from every `live`
  target and enables the strips.
- The controller filter is hidden too, and the filter controller reveals its
  own `live` target. No row carries `data-dim`.

## Motion

The first render is the page taking its starting state, not a change, so it
does not animate. `connect()` holds `data-settling` on `main` until the browser
has drawn it, and the roll-up, the row dimming and the leader are
`in-data-settling:transition-none`.

Roll-up, 200 ms. Leader, 300 ms. Row dimming and the bay's fill, 150 ms. All ease out
(`docs/rules/motion-budget.md`). The sweep turns once every 6 s while playing,
and under reduced motion it is hidden and the roll-up is instant. JavaScript's
own reduced-motion handling stops at not starting on view; the rest (instant
scroll) is #18.

An upcoming row dims its chart lines and fix to 35%, but not the chart's
labels. Text at that opacity fails axe's contrast check.

## Tests

| File | Covers |
|---|---|
| `test/system/home_playback_test.rb` | One test per row built here; gate words; the line running and freezing; chart dimming and ring; the bay following a jump; the filter dimming without hiding; the log's order, counts, empty state and 220 px scroll; every control at least 44 px; axe while playing, paused, filtered and without scripts |
| `test/application_system_test_case.rb` | `assert_accessible` (axe-core-api, single-frame), and `without_scripts`, which blocks every `.js` URL over CDP. Chrome's own script switch also blocks axe |
| `test/components/{strip,step_body,controls,scope,chart_cell,strip_bay,controller_filter,log}_component_test.rb` | The markup each state is styled from |
| `test/integration/home_page_test.rb` | The page as served: disabled strips, empty status cells, hidden controls, bay, filter and log, targets as links, each row's seconds, bay and lane |

System tests are not part of `bin/test`; CI's `test` job runs them. Locally,
`bin/rails test:system`. They set `pace` to 50, so a 6 s step takes 300 ms.
