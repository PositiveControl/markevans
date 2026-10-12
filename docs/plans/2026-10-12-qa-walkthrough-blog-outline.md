---
title: QA walkthrough blog post — outline
date: 2026-10-12
tags: [qa, blog, capybara, selenium, review, workflow, llm-agents]
---

# QA walkthroughs: a script that shows the reviewer the feature

Working title options:
- "The PR that walks itself through"
- "Stop reviewing intent from a diff"
- "A demo is not a test, and that's why it finds bugs"

## 1. Cold open (pick one)

- **A: the packing slip** (`b1397731d`, #3837). This walkthrough's captions read the section order back out of `packing_slip_speed_sections`. On its first run the caption contradicted the slip: "No turnaround selected" sorted ahead of "Swap". Both rank at infinity, so the label breaks the tie, and N comes before S. The tests missed it because no test case ever had two untimed sections. Writing the demo found the bug.
- **B: the 25-minute address form** (`59dfd712d`). Looking at one address form meant sitting through a 1,200-line, 45-step script that made a real checkout and a real label purchase, and left a paid order in the dev DB. That's the story behind the split rule.
- **Thesis:** reviewers, human and LLM, were reviewing a change's *intent* from its diff. A walkthrough is the author's demonstration of the change, run in a real browser against real data, with each change outlined and captioned. It costs the reviewer one command.

## 2. The problems it solves

1. **Reviewers don't click through.** Setting up data by hand (an account in the right role, a box at the right step, a funded wallet) is the step everyone skips. The data setup *is* the barrier.
2. **Diffs don't show behaviour.** Turbo streams, multi-actor flows (a customer submits, a receiver handles it, the customer sees the result), and PDFs served inline are invisible in a diff.
3. **QA plans in `docs/qa/` were followed by hand, or not at all.** Their expected figures were typed in as facts that went stale.
4. **LLM-authored PRs arrive at volume.** In week 41, 72 PRs were merged. Reviewer attention became the bottleneck, so the author has to pay the cost of showing the change.
5. **"Works on my machine" for the reviewer.** The dev container has no display, Sphinx isn't running, the login throttle blocks repeat runs, and the DB is behind on migrations. Each one used to kill a run three steps in.

## 3. How it works

### Two primitives on top of `rails runner`
- `step "caption" do … end` announces the step, runs it, paints the caption, and pauses. A step that raises is reported and skipped, so a bad selector costs one screen, not the run.
- `spotlight text: "Shipping", exact: true, note: "…"` outlines the element and scrolls to it. `note:` is the second caption line and says where the number comes from.
- Running inside `rails runner` gives each script ActiveRecord, the app's services, and the FactoryBot factories from `test/factories`. **Data comes from services and factories. The browser only shows the result.**

### Modes (`bin/qa-walkthrough`, 65 lines of sh)
| Mode | Command | What it's for |
|---|---|---|
| Guided | `bin/qa-walkthrough <name>` | Headed Chrome. Enter advances, Esc quits (a raw `getch`, `d967fd543`). |
| Unattended | `QA_AUTO=1 QA_HEADLESS=1 …` | One PNG per step in `tmp/qa_walkthrough/<name>/NN.png`. Exits non-zero on a failed step. |
| Several scripts | `bin/qa-walkthrough a b c` | Runs in order and stops at the first failure. |
| Container → host | `bin/qa-chromedriver` on the host | The window opens on the developer's screen. |
| Console | `QaConsoleWalkthrough` | Models and queries with no page to show. Writes `transcript.txt`. |

### Supporting details worth a paragraph each
- **Container → host browser** (`720f681ba`, `b41178473`, `cf41200b9`).
  - `bin/qa-chromedriver` uses the Selenium Manager inside the selenium-webdriver gem, because Homebrew's chromedriver cask has been disabled over Gatekeeper since 2026-09-01. It serves on :9515.
  - `bin/qa-walkthrough` detects `/.dockerenv`, probes `host.docker.internal:9515/status`, and drives that driver. Screenshots come back over the same connection.
- **Per-actor windows.** `sign_in(user)` opens a Capybara session per email. The first sign-in goes through Devise; after that a switch is free and lands on the page that actor left. Two-sided changes show up as alternating steps.
- **The sign-in race** (#3720 `batch_promise_date`, which failed 2 runs in 3).
  - What happens: Capybara clears cookies, and then a `pending_jingles` fetch that was already in flight writes the old session back. Devise sends the next actor to the previous actor's dashboard.
  - The fix detects this and retries up to 3 times, then raises `SignInFailed`.
- **A fixed frame.** `QA_WINDOW`, default 1920x1080, is applied after every sign-in, so every screenshot is the same 16:9 desktop layout (`457b6ba62`).
- **Caption placement** (`cb427e208`). The caption flips to the top of the viewport when the outlined element reaches into the bottom band. It was checked with a throwaway probe, since "the harness has no test suite and the flip needs a browser".
- **Fake cameras** (`c1e3620b8`, `f5dd3590d`, #4007).
  - Chrome is launched with `--use-file-for-fake-video-capture`. vips draws a card at an exact tilt, and ffmpeg wraps it as a one-frame `.y4m`.
  - `QaFakeCamera.band_edge` reads the stored capture back, so the walkthrough *fails* on a sideways photo instead of hoping the reviewer notices. The screenshots were regenerated and all 5 came out upright.

### The environment preflight: making the environment right rather than documenting it
- **Sphinx** (`7e533c998`). The old `export TS_REALTIME_CALLBACKS=false` "never worked". The export only reached the runner, never the `bin/dev` server where the writes happen, so a decline committed and then returned a 500. `ensure_sphinx!` now handles it:

  | State | What the preflight does | Cost |
  |---|---|---|
  | Daemon already up | Nothing | 0.06s |
  | Daemon cold | Starts `searchd` and populates the item index | ~9s |
  | Schema changed | Repopulates the item index | ~9s |

  The catalog index is skipped on purpose: 125k categories take 2m31s.
- **Login throttle** (`652d01f3e`). Three actors re-signing in twice inside 5 minutes used up `LOGIN_LIMIT_PER_IP`. The switch can only be wired in `bin/dev`, because the counters live in puma's memory.
- **Second runs** (`fa4804935`).
  - FactoryBot sequences restart in every process, but the dev DB keeps every row. A global `after(:build)` suffixes each user's email and username with a per-run id. The `qa-<handle>@example.com` accounts are exempt.
  - Pending migrations are reported up front instead of as a `NoMethodError`.
  - Rule: **run it twice before committing.**
- **`lib/` → `script/`** (`251573df4`, PR #3634 review). `lib` is autoloaded. Eager loading in production would load `FactoryBot::Syntax::Methods`, which only exists in the dev/test bundle, and that fails boot in every process type.

### Tools and libraries
| Tool / library | What it's used for |
|---|---|
| Capybara + selenium-webdriver | Driving the browser. Moved from `:test` to `:development, :test` with `require: false`, so a dev boot doesn't pay for them. |
| Chrome + chromedriver | The browser, with drivers from Selenium Manager |
| FactoryBot (`test/factories`) | Test data |
| ThinkingSphinx | The search index the preflight manages |
| ruby-vips, ffmpeg | Drawing fake camera scenes |
| `io/console` | Raw key reads for Enter/Esc |

No new gems. Everything was already in the Gemfile.

## 4. Rules a script follows (and the incident behind each)

- **No literal for a value a constant owns.** The tiered-shipping script reads `Fulfillment::ShippingFee::RETAIL_RATE` into its captions, so a price change doesn't make the demo lie.
- **Spotlight by text, not by utility classes.** Text survives a restyle; `.flex.gap-2` doesn't.
- **A step that expects an error page says so.** Rails' red dev 404 reads like a crash to anyone watching (#4051, step 1).
- **Every step stands up its own data.** When the mail-in set was split, 5 carrier steps, 3 address steps and 11 checkout steps turned out to depend on the step before them. Expensive fixtures are memoized instead (`paid_order`).
- **Split by what a reviewer is here to see, not by issue number.**

  | Script | Steps | What it spends |
  |---|---|---|
  | `mail_in_address` | 18 | Verification calls only |
  | `mail_in_carrier` | 15 | Rate calls |
  | `mail_in_box` | 11 | Rate calls |
  | `mail_in_checkout` | 13 | The only one that pays |

- **Say what isn't walked** in the header comment: live streams, a second actor's confirmation, a funded balance.
- **No assertions.** It's a demonstration; the system tests own pass/fail. (`band_edge` is the deliberate exception.)

## 5. Enabling developers while implementing

- **The workflow position** (`060fe0aa2`, `628a161aa`):

  ```
  /task_plan → /implement → /dev_qa → /qa_walkthrough → /pr_submit
  ```

  - `/task_plan` sizes the walkthrough step alongside everything else.
  - `/pr_submit` Step 3b gates on it:
    - Steps on the branch → one unattended run.
    - A user-facing diff without steps → ask the developer, with *create* as the default and two named skips.
    - Nothing user-facing → a line in the PR body.
- **Dev QA comes first, and this is the commit worth quoting** (`628a161aa`):
  - The quote: "The workflow had four gates and none of them was a person using the thing."
  - That branch was its own first case. The walkthrough written before the developer had seen the feature found two real bugs, then had to be rewritten after the fix.
  - Now the walkthrough describes what was approved, not what was proposed. `/dev_qa` also borrows the walkthrough's trick: build the data with factories and print the URL, because "A gate the developer has to set up for themselves is a gate they will skip."
- **The agent's self-check.** Unattended mode is how the agent checks its own script: one PNG per step, run twice, no `✗`.
- **Walkthroughs find bugs that tests don't.** Name the commits:
  - `b1397731d`: the packing-slip sort tie.
  - `ae4f1bb94`: #3731 found two holes in the existing `declined_to_grade` walk, including a factory total ($48.60) that described an impossible submission.
  - `341e9041c` (#3505): the searchd 500 after the money moved, and a Turbo confirm returning while its PATCH was still in flight.
  - `71741bf69`: #3763 added a terms checkbox and broke `mail_in_checkout` (all 16 steps) and `promo_codes`, because that slice only ran its own script. Lesson: rerun the scripts that drive the surface you changed, not just your own.
- **Reusable helpers grow on the framework.** `choose_ufunds_and_agree!` exists because the Turbo-stream race between picking a tile and ticking the box got hit twice.

## 6. Enabling reviewers

- **Placement in the PR** (`47c2aaca1`): the walkthrough line goes at the *top* of the PR body. "A run command in the Test plan is a run command nobody runs." That applies even to integration PRs, which are "the PR someone walks before it reaches master".
- **`/pr_review` Step 1b.** If the PR names a walkthrough, the review **stops before reading the diff** and hands the walkthrough to the human. Whatever the human observes goes into the findings, marked as theirs.
- **`/pr_qa`** runs the walkthrough unattended first and starts from its screenshots. The header's "not walked" list is where the hands-on part begins.
- **`bin/review-batch walk <run> <N>`** (#4064) plays every walkthrough a PR body names, 8s per step (`QA_AUTO_DELAY`), against a per-PR worktree server. The rule: "Check every observation against the code before it goes into a review." (A fixed showcase card once looked like a random customer card.)
- **Autopilot** (#4070) runs `bin/dev` on its own port with its own databases, so walkthroughs don't hit the developer's server.
- **Team workflow:** slices self-merge into `feature/*` after an LLM review. The team walks the integration PR. Of the 159 merged PRs that touched `script/qa/`, about half targeted `feature/*` (64) and half targeted master (70).

## 7. Results and hard data (2026-09-04 → 2026-10-12)

| Metric | Value |
|---|---|
| Walkthrough scripts in `script/qa/` | 83, of which 1 is a console walkthrough and 1 uses a fake camera |
| Total `step`s | 642. Largest is `declined_to_grade` (42 steps, 620 lines); median script is 133 lines. |
| QA plans in `docs/qa/` | 49 |
| Script lines | ~14,000 across scripts. Framework went from 149 lines (`lib/qa_walkthrough.rb`, day 1) to 774, plus support files `mail_in` (312), `fake_camera` (101) and console (73). |
| Merged PRs in the window | 273 |
| …that touched `script/qa/` | 159 (58%) |
| …that name `bin/qa-walkthrough` in the body | 159; 133 of those within the first 400 characters |
| …that state "No QA walkthrough" and why | 45 |
| …with neither | ~65. Worth a breakdown before quoting: mostly early weeks and merges? |
| Authors who shipped walkthroughs | All 6 active committers |
| Commits mentioning "walkthrough" | 146 |

Merged PRs per ISO week that name a walkthrough in the body:

| Week | Merged | Name a walkthrough | Share |
|---|---|---|---|
| 36 | 9 | 1 | 11% |
| 37 | 38 | 12 | 32% |
| 38 | 43 | 27 | 63% |
| 39 | 44 | 28 | 64% |
| 40 | 55 | 31 | 56% |
| 41 | 72 | 54 | 75% |

That's the adoption curve. Week 41 is also the highest-volume week.

Cost figures to quote:
- The old mail-in script took ~25 min before the split.
- Sphinx preflight: 0.06s when warm, ~9s when cold.
- Catalog repopulation, which the preflight deliberately avoids: 2m31s.
- Review-batch playback: 8s per step.

## 8. Gotchas and honest limits

- **It drives the dev server on :3000, which serves the main checkout's branch.** Run from a worktree, the page steps exercise the wrong code (#4018). Fix: point `QA_HOST` at a server started from the worktree.
- **Headless Chrome downloads PDFs instead of rendering them**, so the packing-slip screenshots show blank tabs under correct captions. Run that one headed.
- **Records stay in the dev DB.** `rails db:reset` cleans up.
- **The harness has no test suite of its own.** Its changes are checked with throwaway probes.
- **Flakes that are still open:** `apply_code`'s 15s wait in `promo_codes` (`71741bf69`), and the `promo_codes` step 6 balance contradiction.
- **Not a test.** Don't let it drift into one. The value comes from the demo framing (captions state the expected result; notes cite the source).

## 9. Takeaways

1. Make the author pay the cost of showing the change. Reviewer attention is the scarce resource.
2. Fix the environment in the tool; don't document workarounds (Sphinx, the throttle, migrations, the container display).
3. A demo whose captions are computed from the code finds bugs the tests didn't.
4. A human drives the change before anyone writes the walkthrough, or the walkthrough describes a proposal.
5. Put the run command where people look: the top of the PR body, and the first step of the review.

## 10. Open threads / things to verify before publishing

- Of the ~65 PRs with neither a walkthrough nor a stated skip, how many were user-facing?
- Has any reviewer actually run guided mode, versus reading screenshots? There's no telemetry. Consider asking the team.
- Was a bug ever caught *by a reviewer* through a walkthrough, rather than by the author writing one? The commit evidence above is all author-side.
- Rerunning neighbouring scripts (the #3763 lesson) isn't automated. Is it a candidate for `/pr_submit` or CI headless?
- The scripts don't run in CI. A nightly `QA_AUTO=1 QA_HEADLESS=1` sweep would catch rot like `promo_codes`.
- The uncommitted framework edits on `feature/3659-receiving-portal` (note-only spotlight, remote-safe `attach_file`) are still landing.
