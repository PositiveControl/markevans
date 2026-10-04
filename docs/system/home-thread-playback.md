# Home thread playback

**Status:** Current through #19 (narrow screens).

How the home thread plays. The design is section 6 of
`docs/plans/2026-10-03-home-thread-design.md`; the page around it is
`docs/system/home-page.md`.

## One controller, three values

`app/javascript/controllers/playback_controller.js` sits on a `div` wrapping
the page's `main` and its footer, so the footer's key list is in its reach,
and owns all playback state (`docs/rules/one-playback-state.md`):

| Value | Type | Means |
|---|---|---|
| `step` | Number | The active step's index, from 0 |
| `playing` | Boolean | Whether the step clock runs |
| `open` | Array | Indexes of done strips the reader has reopened |
| `pace` | Number | Milliseconds per second of step time, default 1000. Only system tests change it |

Nothing else holds playback state. The scope, the strips, the chart, the bay,
the log and the docked bar all render from these values, and the page renders without
scripts as a document (below). The controller filter's lane is held apart
(The filter, below).

## How state reaches the page

`render()` writes the values onto the page as attributes and words. It never
writes a class: the templates style from these attributes with Tailwind's
`in-data-*` variants, which match any ancestor (`docs/rules/tailwind-build.md`).

| Written on | Attribute or text | Read by |
|---|---|---|
| The wrapper | `data-playing` while playing | Play's icon, the sweep and the remaining-time line (`in-data-playing:`) |
| The wrapper | `data-ended` once the last step's time has run out | `connect()`, after a cache restore: the clock is not an attribute, so this is how a played-out thread comes back played out |
| The wrapper | `data-docked` while the scope is out of view. Where the reader is looking, not playback state: an `IntersectionObserver` on the scope sets it | The docked bar (`in-data-docked:block`) |
| The wrapper | `--pace`, `--leader-angle` | The line's duration; the leader's rotation |
| Each row (`data-playback-target="row"`) | `data-state`: `pending`, `active` or `done` | Strip ground, outline and Rmk line; the chart's dimming and ring |
| Each row | `data-open`: `true` or `false` | The body's roll-up |
| Each strip button | `aria-expanded`; enabled on connect | Assistive tech |
| Each status cell | The status word | Read as text |
| Each scope target and docked mark | `data-state`, `aria-current="step"` on the active one | The mark's fill |
| Scope readout | Number and name, Ctl · Bay, status word, `data-kind` | The centre block; the docked bar repeats number and name |
| Every play button (scope and docked bar) | `aria-label`: Play, Pause or Replay | Assistive tech |
| The URL | `#<step key>` on each step change, with `history.replaceState` | A link to the step (The step hash, below) |
| Each strip bay's cell matching the active row's `data-bay` | `data-current`, `aria-current="true"` | The ink fill (`data-current:`) |
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
`app/javascript/controllers/filter_controller.js`, sits on the wrapper beside
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
| Step timer ends | Next step active; the previous strip rolls up; the page follows | #16; follow, #18 |
| Timer ends on the last step | Stops; Play becomes Replay. The step stays active, and the log lists it and counts its gate and artifact | #16; the log, #17 |
| Play or pause pressed | Toggles playing. Play scrolls back to the active strip first. Play on the last step (Replay) clears reopened strips and plays from step 1 | #16; scroll back, #18 |
| Step back, step forward | Moves one step and pauses | #16 |
| A target, docked mark or pending strip selected | Jumps there and pauses. A target or mark is a link to its step; the controller cancels the navigation, and the page goes to the step. A strip is already in view | #16; docked mark and going there, #18 |
| A done strip selected | Opens or closes it. Playback state unchanged | #16 |
| Reader scrolls by wheel, touch or keys | Pauses, and drops a follow on its way. Before playback first starts it counts as nothing: that scroll is how the thread comes into view. The wheel or touch scroll that started it does not pause until it goes quiet for 300 ms, though it drops a follow and a waiting `g` | #18; arrival, #19 |
| Tab becomes hidden | Pauses. Does not resume by itself | #16 |
| Restart | Step 1, reopened strips cleared, paused | #16 |
| Page restored from Turbo's cache | Comes back on the step it left, paused, and does not start on view: the values persist in data attributes, so `connect()` sets playing false and counts rows that already carry a `data-state` as a page the reader has been on. A thread that had played out (`data-ended`) comes back played out, its last step still in the log | #16; played out, #17 |
| Page loads with a step hash | That step active, paused, scrolled into view; it does not start on view | #18 |
| Scope leaves view | The docked bar shows; it hides when the scope is back | #18 |
| A key (The keyboard, below) | Space as Play or pause, `j` as step forward, `k` as step back, `g` then a number as a target | #18 |

## Follow and yield

The page follows the active strip while it plays: on each step the clock
moves to, `follow()` scrolls the row to the top of the viewport. The page
keeps 96 px clear at its top (`scroll-pt-16` on `<html>`), rows carry
`-scroll-mt-1` (-6 px), and the strip sits 6 px into its row, so its top lands
96 px down, clear of the docked bar. Play scrolls back to the active strip
before it starts the clock, and an explicit jump (a scope target, a docked
mark, `g` then a number) goes to its step. Back, forward, `j`, `k` and strips
leave the page where it is. Nothing else moves the page. The same
96 px padding lands an element focused by Tab below the docked bar too (WCAG
2.4.11).

A step change renders a moment later, because Stimulus hears a value change
as an attribute change, and the body above the new strip then rolls up over
200 ms. Aiming before either would land the strip too high, so `follow()`
waits a frame, then for every running `grid-template-rows` transition to
finish, then scrolls: smoothly, or at once under reduced motion. If the step
changes or the reader takes over in the meantime, the scroll is dropped.

Reader input always wins (`docs/rules/playback-yields.md`). The wrapper listens
on the window for `wheel`, `touchmove`, a `pointerdown` on `<html>` (a press on
the page's scrollbar, in Chrome and Safari) and the keys that scroll a page
(arrows, Page Up and Down, Home, End, Shift+Space, and Space on a focused
link), and each pauses and drops a follow on its way. A scroll with no input
behind it, from moving focus or find-in-page, is not heard. It is the reader's input, not the
`scroll` event, so the controller's own scrolls never count. `touchmove` rather
than `touchstart`, so a tap on a done strip mid-play leaves playback alone.
Before playback has first started, a scroll is how the thread comes into view,
so it counts as nothing. Where the thread starts below the fold, as on a
phone, the wheel or touch scroll that brings it into view starts it and then
goes on for a moment, momentum included. That is still the reader arriving,
not taking over: `scroll()`, which `wheel` and `touchmove` call, lets their
input pass without pausing until it has been quiet for 300 ms
(`SCROLL_QUIET`), and the next one yields. It still drops a follow on its way
and a waiting `g`: only the pause is spared. The grace applies only when a
wheel or touch scroll heard in the last 300 ms is what started playback, so a
thread already in view on load has none. Keys and a press on the scrollbar
call `yield()` directly and pause at once. Nothing resumes by itself; the
reader presses Play.

## The docked bar

`DockedBarComponent` sits fixed at the top of the wrapper: the four controls,
the active step's number and name, a strip bay, and one 44 px mark per step,
each a link to its step like a scope target and drawn the same way. Every
part is a target playback already renders, so it is a second view, not a
second player (`docs/rules/one-playback-state.md`). It shows only while the
wrapper carries `data-docked`, so while the scope is in view its copies of the
controls are out of the tab order. It is one 44 px row at every width, under
the 96 px the page follows to, so something gives way as the window narrows:
the bay shows from 1280 px (`xl:`), the marks from 1024 px (`lg:`; fifteen of
them and the controls need about 880 px), and the name is cut to one line
(`truncate`). On a phone the bar is the controls and the step's name, and the
strips are the way to jump. `test/system/home_narrow_test.rb` holds it under
96 px at 390, 1024, 1100 and 1400 px.

## The step hash

Each step's hash is its row's `id`, the step key: the scope targets already
link there without scripts. A step change rewrites the URL with
`history.replaceState(history.state, "", "#<key>")`: the back button still
leaves the page, and Turbo's entry in `history.state` is kept. A fresh load
writes nothing until the step changes.

Loading the page with a step's hash opens that step, paused. The reader chose
it, so the thread does not start on view. The browser scrolls to the hash
before playback closes the bodies above it, so `connect()` follows to the step
again, at once.

## The keyboard

Listed in the page's footer, which renders the list hidden until playback
connects:

| Key | Does |
|---|---|
| Space | Play or pause, as the play button. On a focused button or `summary` it presses that instead. On a focused link it scrolls the page, as a browser does, so it pauses like a scroll key |
| `j` | Step forward |
| `k` | Step back |
| `g` then 1 to the gate count | Jumps to that gate, in thread order, and the page goes there. Any other key after `g` drops it and keeps its own meaning, and so does a number after 1.5 s or after a scroll |

Keys typed in a text field (`input`, `textarea`, `select`, contenteditable)
are the field's, and any key held with Ctrl, Alt or Cmd passes through. The
gate count comes from the strips' `data-gate`; the footer prints it from the
thread.

## Without scripts

The controller never connects, so nothing above is written and the templates
fall back to the document reading (design doc, section 6):

- Every body is open, because no `data-open` is set.
- Strips render in the done colours, `disabled`, with an empty status cell.
- Scope targets are plain links to each step's `#key`.
- The sweep, leader, centre block, controls, strip bay, log, docked bar and
  the footer's key list carry the `hidden` attribute. On connect the controller removes it from every `live`
  target and enables the strips.
- The controller filter is hidden too, and the filter controller reveals its
  own `live` target. No row carries `data-dim`.
- No hash is written. A link to a step's hash scrolls there, with every body
  open.

## Motion

The first render is the page taking its starting state, not a change, so it
does not animate. `connect()` holds `data-settling` on the wrapper until the browser
has drawn it, and the roll-up, the row dimming and the leader are
`in-data-settling:transition-none`.

Roll-up, 200 ms. Leader, 300 ms. Row dimming and the bay's fill, 150 ms. All ease out
(`docs/rules/motion-budget.md`). The sweep turns once every 6 s while playing,
and under reduced motion it is hidden and the roll-up is instant. The follow's
scroll is smooth, and instant under reduced motion. Under reduced motion the
thread loads paused: it does not start on view. Fades (the row dimming, the
bay's fill) still run: they move no layout.

An upcoming row dims its chart lines and fix to 35%, but not the chart's
labels. Text at that opacity fails axe's contrast check.

## Tests

| File | Covers |
|---|---|
| `test/system/home_playback_test.rb` | One test per row built here; gate words; the line running and freezing; chart dimming and ring; the bay following a jump; the filter dimming without hiding; the log's order, counts, empty state and 220 px scroll; the follow landing at 96 px; wheel, touch, key and scrollbar yields; the 96 px scroll padding; the docked bar driving state; the hash written and read; each key; reduced motion; every control, docked ones too, at least 44 px; axe while playing, paused, filtered, docked and without scripts |
| `test/system/home_narrow_test.rb` | The narrow layout (`docs/system/home-page.md`, *Narrow screens*): no sideways scroll at 390 px with and without scripts, the 84 px gutter and its lanes, the stacked top row, 44 px targets, the docked bar under 96 px at four widths, and the arriving scroll that does not pause |
| `test/application_system_test_case.rb` | `assert_accessible` (axe-core-api, single-frame), and `without_scripts`, which blocks every `.js` URL over CDP. Chrome's own script switch also blocks axe |
| `test/components/{strip,step_body,controls,scope,chart_cell,strip_bay,controller_filter,log,docked_bar}_component_test.rb` | The markup each state is styled from |
| `test/integration/home_page_test.rb` | The page as served: disabled strips, empty status cells, hidden controls, bay, filter, log and docked bar, targets as links, each row's seconds, bay and lane, the wrapper, the footer and its hidden key list |

System tests are not part of `bin/test`; CI's `test` job runs them. Locally,
`bin/rails test:system`. They set `pace` to 50, so a 6 s step takes 300 ms.
They select the wrapper as `[data-controller~=playback]`, click the scope's
controls rather than the docked bar's unless a test says otherwise, and wait
for the page to stop scrolling before a click, since a follow can slide
another strip under the pointer.
