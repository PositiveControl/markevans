---
title: CI gates blog post — outline
date: 2026-10-12
tags: [ci, blog, gates, github-actions, code-quality]
---

# CI gates: from Rails defaults to `bin/gates` (outline)

Companion to `2026-10-12-ci-tuning-blog-outline.md`. That post covers speed. This one covers the
checks that are not tests. Tests ask "does it work?" Gates ask "is it the shape we agreed to?"
Today they live in two places:

- **The `ci.yml` jobs that are not tests:**
  - `scan_ruby` runs brakeman.
  - `scan_js` runs importmap audit.
  - `lint` runs rubocop, flay and the Slim/Tailwind check.
  - `db_drifts` runs migrations from scratch and checks schema drift.
- **`gates.yml`:** runs `bin/gates --strict` and `bin/lint-docs`.

---

## 1. Cold open: two candidates

**Option A.**
- A PR goes red on flay, which names `application_controller.rb` and `two_factor_protection.rb`.
- The branch never opened either file, and nothing the author could edit would turn it green.
- The PR's base was the `feature/3290-promo-codes` integration branch, but CI diffed against
  master (`524df669e`).

**Option B.**
- On Oct 2, `bin/lint-docs` landed on master and went red on its own merge commit.
- The cause was a doc line saying "the #3875 rules", which it read as a claim that 3,875 rules <!-- lint-docs:ignore: quotes another repo -->
  exist.
- It failed 15 runs in total (4 on master, 11 on PRs from four other people) before the fix
  (`0b0f08812`, #4047).

**Thesis.** A gate is worth having only if three things hold:
1. It fails on what the branch did, not on what it inherited.
2. It is cheap to run.
3. Its red is believed.

Most changes in this history move one of those three.

---

## 2. Era 0: the Rails 8 defaults (Mar 2025)

- `ba0ff471c` (2025-03-05) shipped the generated `ci.yml`:
  - `scan_ruby`: `bin/brakeman --no-pager`
  - `scan_js`: `bin/importmap audit`
  - `lint`: `bin/rubocop -f github`, run on the whole repo
- These gates were defaults nobody chose. They are worth naming in the post because every later
  change reacts to one of them.

## 3. Era 1: making the defaults livable (May 2025)

**Rubocop on the diff only.** Five commits on 2025-05-27 iterate on the lint command:
- `f36b82fb4`, `9ee1e1c5c`, `7bc325dc2` and `499bb3abf`, ending in `b73a91edd` "Take 10". A good
  human beat for the post.
- Final form: `git diff-tree ... origin/master HEAD | xargs ls -1 | xargs bin/rubocop --force-exclusion`.
- **Lesson:** a gate that fails on inherited debt gets ignored or deleted. Scope it to the diff.

**Brakeman noise.**
- First tried `-w2`, medium confidence or higher (`a5d75ecbb`).
- Next day it went back to the default level, plus `config/brakeman.ignore` (`2413d2c61`).
- **Lesson:** suppress specific findings with fingerprints, not a whole confidence level.

## 4. Era 2: gates for bugs that kept recurring (Feb–May 2026)

**Weekly freshness for brakeman** (`61072abb1`, 2026-02-27).
- Added a Monday 11:00 UTC cron.
- `--ensure-latest` runs only on that schedule, so a new brakeman release can't break a random PR.

**`db_drifts` job** (`5293a6284`, `333deb51b` and `ff6bc33e0`, 2026-03-04, Matías).
- It does `rm db/schema.rb`, then `db:create db:migrate`, then `git diff --exit-code`.
- That catches `schema.rb` drift and stale `annotaterb` model annotations in one check.
- Migration output is collapsed so the drift is the only thing you see (#1893).
- **Worked example:** `4c82f4063` (2026-07-01).
  - A revert branch's schema had been dumped from a drifted local database.
  - It carried phantom tables and columns (`region`, `grading_company`), collation flips and a
    nullability change, none of them backed by a migration.

**Slim/Tailwind bracket check** (#2499, `0316e182a`, 2026-05-18, Matías).
- `.min-h-[20px]` in Slim shorthand renders as `class="min-h-" 20px`, and everything after the
  `]` becomes text.
- The commit says it directly: "Claude seems to like generating that". This is the **first gate
  aimed at agent output**.
- It fixed 8 existing views in the same PR.
- The check is a `grep` with a `::error::` message that shows the fix.
- Later mirrored into the local `post_edit` hook (see §9).

**Rubocop tuning** (`e450567f6`, Isaac): the space-inside-brackets cops were disabled.

## 5. Era 3: what gates cost, and the hole that left (Aug 2026)

**Brakeman only when dependencies change** (`45362e33b`, 2026-08-10).
- The reason given: "we don't want to have a feature PR fail due to Brakeman", since the weekly
  run already covers code.
- A step diffs `Gemfile.lock` against the PR base, or `event.before` on push. With nothing to
  diff against, it scans.

**Slack alerts for scheduled failures** (`a9aac2e71`, 2026-08-11). Weekly brakeman failures had
gone unnoticed.

**The hole, shown by the data.**
- `df990996c`: adding the flay gem moved `Gemfile.lock`, which made brakeman run on a PR.
- That run surfaced a `LinkToHref` warning on `NfcTag#short_link` that master had carried,
  unscanned, since the NFC feature landed.
- Then **Oct 5**:
  1. The scheduled run 37300787414 went red after a brakeman release.
  2. Every PR that touched the lockfile that day went red too: `bh/slab-glb-model` (×3),
     `bh/3995/legacy_data_import` and `bh/gemfile-lock-darwin-27`.
  3. The fix was #4046 (`ead593857`), which upgraded Brakeman to 8.1.0 and added **93 lines** to
     `brakeman.ignore`.
- **Discussion point:** the gate moved from every PR to weekly. That cut PR noise, but findings
  now arrive in batches and get waved through as ignore entries.

## 6. Era 4: flay, the first gate designed from data (Sep 2026)

Commit `7e17fb04b` (2026-09-03). The design write-up is `docs/system/flay_duplication_gate.md`.

**Why not rubocop.**
- `rubocop-rails-omakase` turns on no Metrics cops.
- The `Lint/Duplicate*` cops each look at a single expression.
- So a method body pasted from another file is invisible to it, and that is the copy an agent
  makes when it doesn't know a helper already exists.

**Why a wrapper around flay.**
- Flay always exits 0, and its whole-repo score moves with every unrelated edit: 31,420 across
  388 groups on 2026-09-03.
- `bin/flay` runs flay on a `git archive` of the base and on the working tree. It diffs the
  multiset of (structural hash, file) pairs and reports only what the base lacks.
- There is no baseline file to maintain.

**What fails and what warns.**
- **Fails:** IDENTICAL matches, and Similar `defn`/`defs`/`class`/`module` matches (a copy that
  was renamed).
- **Warns:** any other Similar shape. These were mostly `rate_limit`/logger one-liners and
  `respond_to` blocks.
- The mass threshold stays at flay's default of 16, because the real hits sat between 16 and 31.

**Backtested before shipping.**
- It was run against 50 consecutive merges. 5 failed and 7 more warned.
- That works out to about **one real copy caught per 12 PRs and one wrong red per 25**.
- The verdict table in the doc is good material for the post: `require_auctions_enabled`, the
  identical `user_params`, and the `role_descriptions` data-table false positive.

**Deliberately not a required check.**
- A human who reads the output and sees a data table can merge over it.
- The doc's plan: "Revisit after a quarter by counting overrides against catches". That review
  is due around **Dec 3**.

**The base fix** (`524df669e`, 2026-09-15). This is the cold open.
- CI now passes `BASE: origin/${{ github.base_ref || 'master' }}`.
- `bin/flay` fetches whatever `BASE` names, since a missing ref reads as an empty tree, which
  would report every duplicate in the repo as new.
- The commit left the rubocop step alone even though it has the same master assumption: "green
  today, so it is left as it is". It is still unfixed.

**Wired in on both sides:** the CI `lint` job, `/run_lint` and `/pr_submit`.

## 7. Era 5: `bin/gates`, rules turned into checks (Oct 2026)

It arrived with the Rocket Sheep v1.1.1 update (`dce99ff7a`, 2026-10-02, PR #4033).

**The admission bar.** From the header and `docs/rules/pattern-budget.md`:
- A convention is gated only if a machine can decide it without judgment, such as a grep, a
  directory listing or a diff.
- "Nothing here decides whether code is good."
- "A reviewer can check it in a diff" is the bar a rule has to clear.

**The four checks.** Each one names its rule doc and the fix.
1. **Rejected patterns.**
   - Flags `accepts_nested_attributes_for`, `SimpleDelegator`, `Dry::` and `Interactor` in
     `app/`, and `dry-*`/`interactor` gems in the Gemfile.
   - Comment lines are skipped, so a rule quoted in a comment doesn't trip the gate that quotes it.
2. **Pattern budget.** Every directory under `app/` must be a Rails directory, one of the six
   budgeted ones, or named by an ADR.
3. **Command mirror.** `diff -rq .claude/commands .cursor/commands`.
4. **Unindexed foreign keys.**
   - It parses `db/schema.rb` with no database. Every `add_foreign_key` column must lead some
     index.
   - When it has to guess a column name, it prefers a miss to a false positive.

**Grandfathering by count, not by line.**
- `GRANDFATHERED` allows the 11 existing `accepts_nested_attributes_for` calls per file:
  `item.rb` 8, and `offer_item.rb`, `return.rb` and `user.rb` 1 each.
- A new call fails. Removing one should lower its allowance.
- It carries a `ponytail:` note: a count means a call that moves within its file still passes.

**`--strict` semantics.**
- Locally, a gate that crashes is skipped with a warning, because "a broken gate must never
  wedge a push".
- In CI it raises: "CI must never go green on a gate that did not run".

**One script, three callers.**
- The pre-push hook. It is opt-in through `git config core.hooksPath bin/hooks`.
  - `adf393851` corrected the hook comment that claimed this was set up for you.
  - The adoption follow-ups doc records it as "available, not installed".
- `gates.yml` in CI.
- The autopilot runs it before landing a slice: `bin/autopilot:1980`, "bin/gates is red".

**Cheap by construction.**
- It is stdlib Ruby with no bundle (`bundler-cache: false`).
- **Median green run: 18s** across 313 runs, with the 10th–90th percentile at 15–25s.

**Honest limits.** Worth a paragraph in the post:
- It is green partly because of grandfathering.
  - ADR 0007 names every directory, including `app/concerns/` and `app/constraints/`, which
    "should not exist".
- The gate's built-in budget is the template's, not this app's.
  - It would let through a new `app/forms/`, `app/policies/`, `app/lib/` or `app/components/`.
  - ADR 0007 forbids those, so "a reviewer has to catch it" (`docs/rules/pattern-budget.md`,
    "Where this app is").

## 8. `bin/lint-docs` joins the gates job

**Docs are inputs for agents.** The script's header says it: "Prose that disagrees with the tree
is worse than no prose, because the agent has no way to tell." Its checks cover:
- rule frontmatter
- index routing
- read-cost token figures
- command paths and routers
- counts quoted in prose
- one-line index entries

**Wiring.**
- **Same day as `bin/gates`** (`adf393851`): the commit says it "only ran when someone remembered
  it". It is stdlib Ruby, so it joined the gates job.
  - That commit also aligned `gates.yml` with `ci.yml`: `checkout@v6`, the `ready_for_review`
    trigger, per-PR concurrency and `contents: read`.
- **`if: !cancelled()`** (`8592617ef`) makes it report even when `bin/gates` fails, so a single
  push shows both.

**The first false positive.**
- It is described in the cold open: `docs/system/mail_in_catalog_search.md:431` "claims 3875
  rules, there are 35".
- It was red on master 4 times and on 11 PR runs, Oct 2–5 (sampled 5 logs; all show this finding).
- The fix is a lookbehind, `(?<![#\d])`, so the match doesn't just start one digit later
  (`0b0f08812`).

**Local divergences.**
- Check 12, which looks for real hosts and IPs in a public repo, is skipped here. The repo is
  private and its SOPs name its own hosts on purpose.
- `1975b06ee` made the whole-repo scans read only files git tracks, because `tmp/` holds autopilot
  scratch like "the 10 commands". <!-- lint-docs:ignore: quotes another repo -->

**Check 13: one-line index entries** (#4123, Spencer).
- `.llm/README.md` had grown to 193K characters.
- The restore added a ratcheting allowance, `MULTILINE_INDEX_ALLOWANCE` (46 and 82): the same
  grandfather-by-count idea `bin/gates` uses.
- If you shorten an old entry, the check fails until the allowance is lowered, so the count only
  goes down.
- It is already catching real drift:
  - 38269897517: 47 entries against 46 allowed.
  - 38284175773: one over on both indexes.
  - 37975111411: 127 against 46, a branch carrying the pre-restore README.

## 9. The local mirrors (shift-left)

**Same check, earlier in the loop.**
- The `post_edit` Claude Code hook catches the Tailwind bracket bug as the agent edits.
- The first version flagged any line opening with `.class[`, which is also Slim's multi-line
  attribute wrapper. That bounced every agent edit to 11 existing views.
- `8ce6ae2a8` switched it to **CI's pattern**.
- **Lesson:** a local mirror must use the CI gate's exact rule, or it disagrees with the gate it
  mirrors.

**Command-level coverage.**
- `/run_lint` and `/pr_submit` run flay.
- `/pr_submit` treats a red gate as a hard stop.
- `pr_submit` Step 2 skips the suite for docs-only changes, but "lint, flay, brakeman and
  `bin/gates` still run" (`docs/system/workflow-optimizations.md`).

## 10. Gates through the runner changes (tie-in to the tuning post)

- **Self-hosted experiment:** `9b5049780` moved `gates.yml` too (`runs-on: self-hosted`). It was
  abandoned with #4150.
- **Concurrency fix (#4125, `b254511e1`):** applied to both workflows. Master runs are keyed on
  `run_id`, so a burst of pushes no longer cancels pending gate runs.
- **What stayed put:** `gates.yml` is still on `ubuntu-26.04` x64 while `ci.yml` moved to the ARM 4-core
  runner group. Gates run in 18s, so there was nothing to gain. Worth one line in
  the post: not everything needs the bigger runner.

## 11. Results

**Window and method.**
- **CI:** 1,000 `ci.yml` runs, 2026-09-10 → 2026-10-12, across 247 PR branches. The failed step
  in every failed run was classified.
- **Gates:** every `gates.yml` run, 359 in total, 2026-10-02 → 2026-10-12.
- Data is in `scratchpad/ci/ci_fail_steps.tsv` and `gates_runs.tsv`.

| Gate | Red runs | What it caught |
|---|---|---|
| flay (`lint`) | 20 (14 branches, 1 master push 35885341287) | copied Ruby. 3 of them predate the `BASE` fix, on the step's old name "vs master" |
| db_drifts | 9 (6 branches) | `bh/3549/AllCards` 4× in one afternoon, 2026-09-11 |
| brakeman (`scan_ruby`) | 7 PR + 2 scheduled | the Oct 5 release, plus `bh/hybridgrading-site` |
| rubocop | **0** | diff-scoped since May 2025. Raises the question of whether it ever fires |
| Slim/Tailwind check | **0** | the `post_edit` hook catches it first? (unverified) |
| `bin/gates` | 4 of 359 | **all 4 were the command mirror**: `pr_review_batch` ×2 and `check_schema_drift`, from new or edited commands not copied to `.cursor/` |
| `bin/lint-docs` | 19 of 359 | 15 were the #3875 false positive, then index entries over their allowance (check 13) |
| infrastructure (`Set up Ruby`, `Initialize containers`) | 12 | not gate failures. Docker 429s etc., fixed in the tuning post (#4163) |

**Reading the table.**
- The rejected-patterns, pattern-budget and foreign-key checks have **never fired**. Either
  they deter people from writing those patterns, or they're cheap insurance. At 18s a run, either
  reading is fine.
- The command mirror is the only `bin/gates` check that fails, and it fails on a chore a tool
  could do. Candidate: have `/workflow_setup` or a hook do the copy instead of gating on it.
- **Nothing is required.** `gh api .../branches/master/protection` returns "Branch protection has
  been disabled on this repository."
  - Every gate is advisory, which flay's doc chose on purpose.
  - The master flay red shows a merge going over a red gate.
- Weekly brakeman: 2 of the 5 scheduled runs in the window failed.

## 12. Takeaways (candidates)

1. **Scope to the diff, and to the right base.** These all fix the same problem: rubocop's
   "Take 10", flay's `BASE`, and grandfathering by count.
2. **Grandfather with a ratchet, not an exemption.** The count may only go down: `GRANDFATHERED`
   and `MULTILINE_INDEX_ALLOWANCE`.
3. **Backtest a gate before you ship it.** Flay's 50-merge replay gave a real catch and
   false-red rate, which set the expectation for "advisory, not required".
4. **The gate's cost decides where it runs.** Brakeman on every PR made PR runs noisy; weekly
   brakeman lets findings pile up into an Oct 5 batch.
5. **Gates for agents.** Three gates exist because of LLM output or LLM inputs: Tailwind
   brackets ("Claude seems to like generating that"), flay (the helper it didn't know about) and
   lint-docs (docs as agent inputs).
6. **A broken gate must not block a push, and CI must not pass a gate that didn't run.**
   `--strict` encodes both.
7. **A local mirror must use the CI gate's exact rule** (the `post_edit` fix).

## 13. Open threads to mention or resolve before publishing

- Rubocop still diffs against master on stacked or integration PRs (memory:
  `ci-gates-assume-master-base`).
- The pattern-budget gate uses the template's directory set, not this app's.
- The pre-push hook is opt-in, so who actually has it on?
- The flay quarter review is due around Dec 3: count overrides against catches.
- Should `gates.yml` and `lint` become required once branch protection comes back?
- Verify the "0 Tailwind reds" claim: is it the hook catching them, or nobody writing them?
