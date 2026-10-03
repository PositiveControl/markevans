# Home thread playback

**Status:** Current through #16 (playback core). #18 adds follow, yield on
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

Nothing else holds state. The scope, the strips and the chart all render from
these values, and the page renders without scripts as a document (below).

## How state reaches the page

`render()` writes the values onto the page as attributes and words. It never
writes a class: the templates style from these attributes with Tailwind's
`in-data-*` variants, which match any ancestor (`docs/rules/tailwind-build.md`).

| Written on | Attribute or text | Read by |
|---|---|---|
| `main` | `data-playing` while playing | Play's icon, the sweep and the remaining-time line (`in-data-playing:`) |
| `main` | `--pace`, `--leader-angle` | The line's duration; the leader's rotation |
| Each row (`data-playback-target="row"`) | `data-state`: `pending`, `active` or `done` | Strip ground, outline and Rmk line; the chart's dimming and ring |
| Each row | `data-open`: `true` or `false` | The body's roll-up |
| Each strip button | `aria-expanded`; enabled on connect | Assistive tech |
| Each status cell | The status word | Read as text |
| Each scope target | `data-state`, `aria-current="step"` on the active one | The target's mark fill |
| Scope readout | Number and name, Ctl · Bay, status word, `data-kind` | The centre block |
| Play button | `aria-label`: Play, Pause or Replay | Assistive tech |

The status word is the active step's state in words (`docs/rules/never-color-alone.md`):

| State | Command or optional | Gate (human or machine) |
|---|---|---|
| Pending | pending | pending |
| Active, playing | active | hold |
| Active, paused | paused | paused |
| Done | done | cleared |

A row's seconds come from the server as `style="--seconds: N"` (`Step#duration`,
6 unless the step sets `seconds`). The clock reads it, and so does the line.

## The step clock

The active step plays for its seconds × `pace` ms. Pausing keeps what is left.
A new step, a restart or a pace change starts it full. When it runs out, the
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
| Timer ends on the last step | Stops; Play becomes Replay | #16 |
| Play or pause pressed | Toggles playing. Play on the last step (Replay) clears reopened strips and plays from step 1 | #16 |
| Step back, step forward | Moves one step and pauses | #16 |
| A target or pending strip selected | Jumps there and pauses. A target is a link to its step; the controller cancels the navigation | #16 (docked mark: #18) |
| A done strip selected | Opens or closes it. Playback state unchanged | #16 |
| Reader scrolls by wheel, touch or keys | Pauses | #18 |
| Tab becomes hidden | Pauses. Does not resume by itself | #16 |
| Restart | Step 1, reopened strips cleared, paused | #16 |
| Page loads with a step hash | That step active, paused, scrolled into view | #18 |

## Without scripts

The controller never connects, so nothing above is written and the templates
fall back to the document reading (design doc, section 6):

- Every body is open, because no `data-open` is set.
- Strips render in the done colours, `disabled`, with an empty status cell.
- Scope targets are plain links to each step's `#key`.
- The sweep, leader, centre block and controls carry the `hidden` attribute.
  On connect the controller removes it from every `live` target and enables
  the strips.

## Motion

Roll-up, 200 ms. Leader, 300 ms. Row dimming, 150 ms. All ease out
(`docs/rules/motion-budget.md`). The sweep turns once every 6 s while playing,
and under reduced motion it is hidden and the roll-up is instant. JavaScript's
own reduced-motion handling stops at not starting on view; the rest (instant
scroll) is #18.

An upcoming row dims its chart lines and fix to 35%, but not the chart's
labels. Text at that opacity fails axe's contrast check.

## Tests

| File | Covers |
|---|---|
| `test/system/home_playback_test.rb` | One test per row built here; gate words; the line running and freezing; chart dimming and ring; every control at least 44 px; axe while playing, paused and without scripts |
| `test/application_system_test_case.rb` | `assert_accessible` (axe-core-api, single-frame), and `without_scripts`, which blocks every `.js` URL over CDP. Chrome's own script switch also blocks axe |
| `test/components/{strip,step_body,controls,scope,chart_cell}_component_test.rb` | The markup each state is styled from |
| `test/integration/home_page_test.rb` | The page as served: disabled strips, empty status cells, hidden controls, targets as links, each row's seconds |

System tests are not part of `bin/test` or CI. Run them with
`bin/rails test:system`. They set `pace` to 50, so a 6 s step takes 300 ms.
