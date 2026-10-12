---
title: CI tuning blog post — outline
date: 2026-10-12
tags: [ci, blog, testing, github-actions]
---

# CI tuning blog post: outline

The story runs from April to October 2026. It has two phases. In the first, from April to August, the team made changes by intuition and got real but limited wins. In the second, during the week of 2026-10-08, the team measured first and the wall clock roughly halved. That contrast works well as the spine of the post.

**Headline numbers** (green master pushes, first job start to last job end):

- **Before:** median 878s (14.6 min), range 631–1071s, across 19 green x64 runs (Oct 2–9). The queue wait reached 13.7 min.
- **After:** median 469s (7.8 min), range 442–482s, across 8 green runs (Oct 9–12). The queue wait is 5s at most.
- Full table under **Results** at the end.

Primary sources: `docs/plans/2026-10-08-ci-runtime-research.md`, `docs/plans/2026-10-08-ci-runtime-followups-design.md`, `docs/plans/2026-10-08-timing-balanced-shards-design.md`, PRs #4128, #4130, #4150, #4153, #4161, #4162, #4163, #4166.

---

## 1. Cold open: "We sharded it, and it still got slower"

- Quote the question at the top of the research doc: "Our CI takes 10+ minutes… as they grow, the shards take longer."
- Show a table of the six runs measured before tuning. One run had a 151s system shard and a 770s system shard in the same run.
- Thesis: sharding by file count only makes the imbalance smaller relative to the total. It doesn't remove it.

## 2. Prehistory: tuning by intuition (Apr–Aug)

Short section. Each of these was a reasonable call and worth keeping.

**April, #2167 (`3f610cd5a` and its siblings):**

- The CI push trigger targeted `main`, but the default branch is `master`.
- System tests were split into their own job.
- MySQL moved to tmpfs with `innodb_flush_log_at_trx_commit=0` and `sync_binlog=0`. `innodb_doublewrite` was tried and reverted, because it can only be set at startup (`f0c6828cc`).
- SimpleCov was disabled in CI and apt packages were cached.
- 3 unit shards via `awk NR % 3` (`edb6959dd`).
- Workers went 4 → 2 to match the 2-core runner.

**August, `5db710ca8` / `8fadb82b4`:**

- Added cancel-in-progress per PR. Stacked-branch restacks were re-running every branch above the edit.
- System tests sharded 2 ways: 13m04s and 7m10s, against a 19–22m unsharded baseline.
- The commit message explains why it went to 4 shards rather than balancing: balancing "would need timing data that drifts". This is the decision October reversed.

**Other August changes:**

- Draft PRs skip the expensive jobs (`583a9c8bc`).
- The two oversized system files were split by hand so the modulo split could deal them across shards (`c2fbe85c4`). `template_queue_viewer_test` had 119 tests.

**Reliability changes:**

- A 25-minute job timeout after a hung run burned 3h+ (`355c64eb1`).
- `--fail-fast` was dropped because it hid every failure behind the first flake.

## 3. Phase two: measure before touching anything (#4124 research, 2026-10-08)

- **Method:** six green master runs, timings pulled from the jobs API at step level. The `gh api` re-fetch command is in the doc, so readers can reproduce it.

**Findings:**

- The test step takes 450–510s and setup takes about 130s. Most of the time is spent running tests.
- System shard 3 had 306 tests while its siblings had about 150. Of those 306, 135 came from one file.
- Cost per test: about 0.18 worker-seconds for a unit test and about 4.8 for a system test, roughly 25×.
- Setup breakdown (mean of 42 jobs):
  - MySQL container: 31s
  - Uncached Manticore install: 30s
  - Tailwind: 16s
  - apt: 17s

**Hidden bugs the research found:**

- **Concurrency group.** Every master push shared `ci-refs/heads/master`. A group holds only one pending run, so bursts of merges cancelled the runs in the middle. That broke the workflow comment's own promise that master runs are never cancelled.
- **Slowpoke was silent under `parallelize`.** Minitest's `after_run` skips any process that didn't install it (`minitest.rb:78-81`), so the parent's tracker was always empty. The SOP also pointed at a file that doesn't exist, and `test_helper` pinned a threshold that made `SLOWPOKE_THRESHOLD` a no-op.
- **Levers ranked by seconds saved per unit of effort.** Seven levers made the list. Rejected: path filtering (it leaves required checks unreported), `fail-fast`, and building Tailwind once and passing it along (the added job dependency cancels out the saving).

## 4. Lever 1: shards balanced by measured duration (#4128)

**Tools: no new gem. Knapsack is archived, and Knapsack Pro is paid.**

- `e8d2e0297`: a reporter in the parent process records per-file durations. Results already come back from the workers over DRb with `time` and `source_location`. Time is charged to the class's file, so a shared module's tests count toward the `_test.rb` file that runs them. It only runs when `TEST_TIMINGS_OUT` is set.
- `bin/test-shard`: greedy longest-first assignment to the lightest shard. Files without a timing get the median. An empty shard fails loudly, because `bin/test` with no paths runs the whole suite.
- `bin/test-timings`: refreshes `test/timings.json` from CI artifacts. SOP: `docs/sop/refresh-test-timings.md`.

**Iterating on the weights (good material for the post):**

| Run | Weights | Unit spread | System spread | Slowest job |
|---|---|---|---|---|
| 37826952108 | count split | 1.55× | 2.35× | 802s |
| 37828875386 | 1 run | 1.05× | 1.52× | 832s |
| 37831133921 | mean of 2 runs | 1.19× | 1.89× | 747s |

**Key insight (`bf7fb1de9`):**

- Every file on one system shard ran at about 0.65× its weight, and every file on another at about 1.24×.
- Files on the same shard moved together, so the cause was the runner, not the files. Headless Chrome on 2 CPUs is CPU-starved.
- Static weights can't fix that. The weights became the median of several runs.
- Example of the noise: `home_responsive_test` ran 244s in one run and 447s in the next.

## 5. Self-hosted runners vs. larger hosted runners

**Self-hosted (#4150, closed without merging):**

- Multipass VMs ci-1..3 with a provisioning script (`31187f851`).
- Practical problems:
  - Each MySQL service binds port 3306, so you get one runner per VM.
  - A private gem-repo token was left behind in `~/.gitconfig`.
  - Docker images and caches piled up, so a nightly cleanup cron was needed.
- Result: tests ran at about 60% of hosted speed. The host was itself a KVM VM (nested virtualization) on a 2017 Xeon Gold 6130, and it was oversubscribed.
- Lesson: one box doesn't scale out to several developers pushing all day.

**4-core ARM hosted runner group (#4153):**

- `PARALLEL_WORKERS` went 2 → 4.

| | 2-core x64 | 4-core ARM |
|---|---|---|
| `test (0)`, the same 5,391 tests | 501s | 264s |
| Full run, start to finish | 12–24 min | 10.4 min |
| Total job time | ~72 min | ~54 min |

- First balanced run on ARM (37977923797): unit 1.05×, **system 1.14×**, slowest job 525s. This confirmed that the system-shard variance came from CPU starvation.
- The x64 timings were kept as weights and as the baseline. The relative cost of each file carried over to ARM.

## 6. The cost of moving to ARM: new failure modes

This could be its own section, since the problems are unusual.

- **No Chrome:** Google publishes no Chrome for Linux ARM64. CI switched to the Chromium snap, wiring up `BROWSER_PATH` for FerrumPdf and `CHROMEDRIVER_PATH` (`c3bd22370`).
- **Load-order bug:** a `NameError` killed every system shard until `selenium-webdriver` was required first (`904153680`).
- **Docker Hub 429s:** the hosted ARM runners pull anonymously from shared IPs. MySQL is now pulled from the ECR Public mirror (#4163).
- **Snap Store HTTP 408:** handled with a retry (`c8d286ba1`, #4165 still open).

## 7. Setup trimming: one cache that worked, one that didn't (#4130)

- **Manticore through `cache-apt-pkgs-action`:**
  - Needs `execute_install_scripts: true`, because restoring the cache only restores files.
  - Cost went from about 19s on ARM to 5–7s.
  - That's about 13s per job, well short of the 30s target. The target came from x64 numbers, and the ARM install was already faster.
- **Chromium snap cache, a negative result worth writing about:**
  - The install pulls 8 extra snaps, about 1.3 GB.
  - A cache hit took 63–67s, against 57–61s from the Store.
  - The time goes into snapd restarting and mounting snaps, not downloading. The DIAGNOSTIC commits are kept in the history as the record.
  - Follow-up #4156 (open): a prebuilt Debian image with native Chromium.
- **Concurrency fix:** non-PR runs are now keyed per run. No more queueing or silently cancelled master runs.

## 8. Making tests cheaper: measure, then decide go or no-go (#4127 → #4161)

- **Instrumentation on a throwaway branch:** a `factory_bot.run_factory` subscriber, a clock around `sign_in_system_test`, and one run with Sphinx real-time callbacks off.
- **The bar for a go:** more than 30s off a shard, or a correctness hazard removed. Two identical baseline runs differed by 37s, which set the noise floor.

**Results:**

- **Sign-in through the form: 46% of system-test time.** Measured as 208 sign-ins taking 169.6s out of 365 worker-seconds.
  - Verdict: go, in #4162, using Warden `login_as`.
  - The real-form path was kept for named `using_session` browsers. Warden's pending login is claimed by whichever browser makes the next request.
  - New `two_factor_sign_in_test.rb`: before this, no browser test exercised 2FA.
  - Side effects that surfaced:
    - Tests that had assumed they started on the dashboard now visit it.
    - A localStorage write needed a page loaded first, so the test loads `/robots.txt`.
    - Capybara's reset never cleared sessionStorage, which led to a `before_teardown` hook.
  - **Result:** the system test step dropped from 253–282s to 176–231s.
- **Factories: 65% of unit-test time.** `capture_image` alone accounts for 36%, at about 13ms per attach.
  - Swapping in a 1×1 PNG saved nothing, so the cost is per attach, not per byte.
  - Verdict: go, with a shared blob (#4159, open).
  - Dropping the staff images was deferred to #4160, because it reverses decision #3534.
- **Sphinx real-time writes: 3%,** inside the noise. Verdict: no-go.
- **Lesson:** the design doc refused to file E, F or G before the measurements came in. G would have been a large diff for a gain lost in the noise.

## 9. Flakes are CI time too

- `2d97fa746`: leaked `using_session` browsers grew Chrome by about 130 processes until the runner was killed mid-shard.
- **#4166, three flakes:**
  - Stale category-children responses wiped the user's selection. This was a real production bug, also reachable by an operator double-clicking.
  - Puma accepted requests that slipped past Capybara's wait, which caused "Cannot expire connection, it is not currently leased". Fixed by waiting for Puma's busy threads to reach zero.
  - A layout shift in the initial panel.
- Possible angle: faster runners and balanced shards change timing, which surfaces races that were always there.

## 10. Steps added to CI along the way (sidebar)

- `db_drifts`: regenerates the schema and annotations and fails on a dirty tree (`5293a6284`).
- Slim bracket-class detector, which catches a pattern Claude tends to generate (#2499).
- `bin/flay` gate: blocks only newly added copies, compared against the PR's base (`7e17fb04b`).
- Brakeman runs only on PRs that change dependencies, plus weekly (`45362e33b`).
- Slack alerts when scheduled CI fails (`a9aac2e71`).
- Nightly E2E runs Playwright in 2 shards and never blocks a merge. Parallelism comes from more servers, not more workers (`ecc2fbdaf`).
- A broken third-party apt repo no longer fails the shards (`3ee6f2444`).
- MySQL runs with two-character FULLTEXT tokens, which required a conf.d edit and a restart (#4103).

## 11. Results, and what's left

- Present the headline before/after numbers above, plus the queue wait going from 6–14 min to 0.
- **Breakdown by cause:**
  - Balancing removed the spread.
  - ARM 4-core roughly halved the per-shard time.
  - `login_as` took about 70s off the system shards.
  - The unit shards are now the critical path (about 300s).
- **Still open:**
  - #4159, the shared blob: about 34s per unit shard projected.
  - #4156, the prebuilt image: removes about 60s of Chromium install.
  - A fourth unit shard, gated on unit shards being the slowest jobs by more than 60s.
  - #4160.

## 12. Takeaways (candidate closing)

1. Measure the critical path before you add shards; more shards only hid the imbalance.
2. Find out who sees the numbers, and whether they're telling the truth. Slowpoke was silent under parallel workers.
3. Weights are noisy, so use the median, and check whether the noise is really the machine.
4. Hardware is a lever, but it depends on whether the hardware can scale out, not just how fast it is. That's why self-hosted lost.
5. Negative results deserve a commit. The snap cache and the Sphinx no-go are both on record.
6. Set the go/no-go bar above the noise floor before you measure.

---

## Results: master CI, 2026-10-02 → 2026-10-12

Source: the GitHub jobs API for the last 40 `push` runs of `ci.yml` on master, pulled 2026-10-12. Wall time runs from the first job's start to the last job's end. Test-step times are the "Run (system) tests" step, so they leave out setup. Spread is the slowest shard divided by the fastest shard in the same run.

### Green runs, medians per era

| | x64, 2-core, count split | ARM 4-core + balanced shards + `login_as` |
|---|---|---|
| Runs | 19 (Oct 2–9) | 8 (Oct 9–12) |
| **Wall clock, median** | **878s (14.6 min)** | **469s (7.8 min)** |
| Wall clock, range | 631–1071s | 442–482s |
| Slowest unit test step, median | 610s | 316s |
| Slowest system test step, median | 748s | 214s |
| Unit shard spread, median | 1.41× | 1.13× |
| System shard spread, median | 2.31× | 1.17× |
| Setup per shard job | 101–181s | 126–169s |
| Total job time per run, median | 75 min | 48.5 min |
| Queue wait before first job, max | **823s (13.7 min)** | 5s |

- **Wall clock: −47%**, from about 14.6 min to about 7.8 min.
- **Variance is gone.** The x64 range spans 440s; the current range spans 40s. The predictability is as much of a story as the speed.
- **The critical path moved.** Before, `system_test (1)` or `system_test (3)` was the slowest job in most runs. Now it's always a unit shard: `test (0)` or `test (1)`, at 442–480s. That's why #4159 (cheaper factories) and the fourth unit shard come next.
- **Runner minutes fell by a third** (75 → 48.5 job-minutes per run), even though the ARM runners are larger. Per-minute pricing differs between the two runner types, so this isn't a cost figure.
- **Setup got slightly slower on ARM**, roughly +20s, because of the Chromium snap install (~60s). #4156 targets it.

### Intermediate data points (one run each)

| Run | State | Wall | Slowest unit / system step |
|---|---|---|---|
| 37993765213 | ARM, count split, form sign-in | 569s | 344s / 420s (system 2.20× spread) |
| 37995666366 | + balanced shards + `login_as` (first green run) | 462s | 300s / 209s |

So ARM alone took the median wall from 878s to 569s. Balancing and `login_as` together took it from 569s to about 465s. There's no green master run with balancing but without `login_as`; run 37994670679 had that combination but failed in `system_test (0)`. The ARM-only balanced PR run 37977923797 (slowest job 525s, per the research doc) fills that gap.

### Queueing and cancellation (before #4130)

- In the x64 era, 7 of 26 runs waited more than 5 minutes for their first job: 344s, 785s, 608s, 463s, 823s, 658s, 372s, and 1041s on run 37837403227.
- 37682120803 and 37682444319 (Oct 7) were cancelled without running.
- Since #4130, every run has started within 36s, and nothing has been cancelled.

### Reliability (be honest about it in the post)

| Era | Runs | Failed | Cancelled |
|---|---|---|---|
| x64 | 28 | 7 | 2 |
| ARM / current | 12 | 5 | 0 |

The ARM-era failures, by first failing step:
- **37992340042:** all jobs died in *Initialize containers*. Docker Hub returned 429, fixed by moving MySQL to the ECR mirror (#4163).
- **37995693357:** *Install Chromium (ARM64)*, the snap retry case (#4165).
- **37994670679, 38272704503, 38276750075:** test failures in `system_test (0)`, and one also in `test (2)`. Not investigated here. Worth checking whether they're the same flake before the post claims the flake fixes in #4166 worked: 38272704503 and 38276750075 came after #4166 merged.

### Run IDs

- **x64 green:** 37061776307, 37068399924, 37068556885, 37335216277, 37335846455, 37354506784, 37378199391, 37394482161, 37395824329, 37483008250, 37496540190, 37651684718, 37682039114, 37682857559, 37821904653, 37823479145, 37837330294, 37845845745, 37961674417
- **Current green:** 37995666366, 37996249520, 38270071132, 38285091845, 38285579873, 38285795603, 38287304113, 38288723083
- **Re-fetch:** `gh api "repos/<org>/<repo>/actions/workflows/ci.yml/runs?branch=master&event=push&per_page=40"`, then `gh api "repos/<org>/<repo>/actions/runs/<id>/jobs?per_page=50"`.

## Caveats

- None of these post-#4162 numbers are in `docs/plans/2026-10-08-ci-runtime-research.md` yet; #4162's test plan has that box unchecked. Record them there before the post cites the doc.
- The "wall" figure here includes every job (lint, scans, db_drifts), but the shard jobs set it in every run.
