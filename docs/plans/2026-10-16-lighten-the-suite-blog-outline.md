---
title: Lightening the test suite blog post — outline
date: 2026-10-16
tags: [testing, blog, minitest, capybara, selenium, memory, ci]
---

# Lightening the test suite: outline

This is the sequel to the CI tuning post. That post ended with the unit shards as CI's critical path and factories at 65% of unit time. This one picks up on 2026-10-16, when the problem was no longer CI. The autopilot driver's local test runs kept killing MySQL. The work ran for a day in one session. It started with memory and ended with wall time, and every step was measured before it was kept. The spine of the post is that each thing actually changed was found by measuring. The guesses that seemed obvious mostly turned out wrong (eager loading, a slab cache, `reload`, system tests being out of bounds for `before_all`).

**Headline numbers** (project Docker container, 14 cores / 15 GB, same box throughout):

- **Unit suite, 8 workers:** 285s → 210s. Before the memory fixes, an 8-worker run got mysqld OOM-killed (twice on 2026-10-15).
- **System suite, 4 workers:** 295s → 193s (−35%). Lowest memory available during the run went from 2.0 GB to 5.4 GB.
- **CI:** all green, with the shards rebalanced: unit spread 37s → 20s, system 55s → 28s.
- Full tables under **Results** at the end.

Primary sources: `.llm/threads/2026-10-16-lighten-the-suite.md` (the segue: findings and dead ends), `docs/plans/2026-10-08-ci-runtime-research.md` (sections "Local baselines, 2026-10-16" and "System tests"), `docs/rules/testing.md` ("Setup shared by a whole class: before_all"), PRs #4312 and #4313. Commits `a721125ae` (#4312 merge), `6bc1d121c`, `b0f52cf7b`, `e88883de3`, `1acc78d8e`.

---

## 1. Cold open: "mysqld_safe mysqld restarted"

- The autopilot driver ran the full suite after each merge. Twice on 2026-10-15 (21:46 and 23:53), mysqld was OOM-killed eight minutes in. The suite then ran 82 more minutes of connection errors, and the driver blamed the first five tests it saw failing.
- Show the error.log lines and the 6.3 GB of Ruby processes, still climbing, partway through models + services.
- Thesis: the suite didn't need less running locally. It needed to be cheaper for everyone who runs all of it (CI, the driver, a developer with a reason to).

## 2. Ground rules, set before anything changed

- The question went into a segue thread, kept separate from the workstream, with a brief listing six candidates to *measure, not assume*.
- **The rule:** each change is measured against a fixed baseline, on the same box, with the noise floor stated. An earlier CI study had two identical runs 37s apart, so differences under about 15% are noise.
- **The tool:** a memory sampler, `sample.sh`. Every 5s it sums Pss across the test process tree (Chrome included), along with mysqld's RSS and `MemAvailable`. Pss, not RSS, because forked workers share pages and RSS counts them twice. Reused for every measurement in the post.

## 3. Memory: three suspects, one wrong guess (#4312)

**Single-process probe on `item_test.rb`, while the driver was still running:**

- **Active Job's global `:test` adapter leaked.** 19,266 jobs (about 79 per test, 80% `ActiveStorage::TransformJob`) were never cleared outside `ActiveJob::TestHelper` classes. Real, but under the noise at 4 workers. Folded into #4159.
- **SimpleCov:** 9.5s of a 40s file once eager loading was untangled from it, plus about 110 MB written out at exit by every worker.

**4-worker `test/models` matrix (3,979 tests):**

| Config | Time | Peak Pss |
|---|---|---|
| baseline (SimpleCov on) | 128s | 2,468 MB |
| SimpleCov off | 85s | 1,858 MB |
| + eager loading | 100s | 2,371 MB |

- **Wrong guess: eager loading.** The theory was copy-on-write sharing across forked workers. It came out slower and heavier. Keep it CI-only.
- **The late spike.** Logging RSS after every test, in every worker, found it: `Hga::ShowcaseTest#test_every_card_renders_as_a_webp_slab` added **380 MB** of libvips native memory that never came back.
  - `Vips.cache_set_max(0)`: no change, so it wasn't the cache.
  - `MALLOC_ARENA_MAX=2`: 805 → 598 MB.
  - jemalloc: 563 MB.
  - `VIPS_CONCURRENCY=1`: 501 MB.
  - Both settings: **432 MB.**
- **Shipped in #4312:** SimpleCov opt-in (`COVERAGE=1`). `bin/test` exports `VIPS_CONCURRENCY=1` and preloads jemalloc when installed, with the same idiom as `bin/docker-entrypoint`. Result: the 4-worker models peak went from 2.5 GB to 1.7 GB.
- **Aside: one CI run stuck 12 minutes in `apt-get install`.** Adding `libjemalloc2` changed the cache key, and two runners hit a slow mirror. A one-time cost, but a good reminder that the package list is part of the cache key.
- #4312 was merged by accident before the rest landed, so the follow-up went into #4313.

## 4. Wall time: where a heavy controller file spends its time

- **Phase probe on `admin/items_controller_test.rb` (250 tests):** 70.3s total, of which **setup 58.5s (83%)**, factories 57.5s, test bodies 11.4s, `sign_in` 2.4s.
- **Two cheap toggles on the same file:**
  - **Test log debug → warn: 70.3s → 54.6s (−22%).** Formatting and writing every SQL line to `test.log` costs real CPU. A one-line change with `LOG_LEVEL=debug` as the escape hatch.
  - **PaperTrail off: −4%,** inside the noise, and 5 tests fail. No-go.

## 5. `before_all`: build once per worker, not once per test

- **Built by hand first** (`SharedSetup`), to understand what it takes. `ConnectionPool#pin_connection!` counts depth, so a second pin turns the test's transaction into a savepoint, and the hook goes in at `setup_transactional_fixtures`. Result: 70s → 14s.
- **Then test-prof's `before_all`:** the same speed (`test/controllers/admin` went from 65.7s to about 31s at 4 workers, green on three seeds). It also handles Rails' parallel workers through `previous_klass` and `parallelize_teardown`. The hand-rolled version was deleted rather than keeping two mechanisms.
- **Rolled out to 277 unit files** by parallel agents working from one written recipe, with the rule file (`docs/rules/testing.md`) as the spec. Each agent was told explicitly not to run tests while a baseline was running. Story points for the post:
  - **A stored file is outside the transaction.** `category_imports/preview_service_test.rb` failed after one test purged the shared CSV. The rollback restored the row but not the file on disk. This became a rule.
  - **Skip reasons had to be explicit** so an agent knows when it may skip. One of the first set was wrong (system tests; see §8).
- **Unit result:** 285s → 231s, with summed worker time 2,017s → 1,683s.

## 6. The bug a second seed found: `reload` isn't enough

- The first seed was green. The second seed (777) had **two failures that only happen in some test orders**:
  - `auctions_controller_test`: "cannot update a destroyed record". A test destroys a shared record, `destroy` freezes the object, and `reload` doesn't undo that.
  - `catalog_profile_boundaries_test`: it failed on every seed when the file ran alone. Bisecting in alphabetical order found the culprit in five runs. `acts_as_better_tree` memoizes `@ancestors ||= ...` on the record, and `reload` keeps instance variables. One test's broken profile key followed `@card` into the next test.
- **The fix:** `test_helper.rb` re-finds every Active Record object `before_all` captured before each test, through arrays and hashes, with `unscoped`. It costs one query per record, the same as `reload`. The per-file reloads were then deleted from 249 files by script, and the diff shrank from 2,146 to 1,143 added lines.
- **The assertion count:** 70,372 on both seeds against a baseline of 70,384. A per-test diff of the 277 files found all 14 missing assertions in one file, a guard `assert` that now runs once per worker. The other +2 came from tests whose count varies on their own. Good material for an "always explain the number" sidebar.

## 7. System tests: profile before you optimise

- **A first guess, wrong:** HGA slab images were re-rendered every visit because the test cache is a `:null_store`. Measured: only 28 renders, 11s of the 80s, because the browser caches them itself (`expires_in` plus an ETag). Dropped.
- **Instrumented probe (top 10 files, 334s):**
  - page loads 27%
  - unattributed 26%
  - Capybara waits 19%
  - `sleep` 7%
- **Sampling profiler:** every 20ms, the main thread is charged to its innermost `test/` line, skipping the driver-node retry wrapper. It found:
  - **`walk_pointer_down`: 24s of a 38.7s file.** Hundreds of pointer moves, each with Selenium's default 250ms duration. `action(duration: 0)`: 42s → 20s (87s on CI).
  - **"Converge on open" `<details>` loops:** `break if has_css?("...[open]", wait: 1)` before the first click charges every call a full second. Five copies became one `open_details` helper (`wizard_card_tier` 25s → 16s, `wizard_pricing` 13.6s → 10.7s).
  - The deliberate `sleep`s, which simulate a request in flight, were left alone.

## 8. `before_all` in system tests: the rule was wrong

- The rule's skip reason 2 said the browser's server thread uses its own connection and can't see the shared rows. Nobody had checked. In Rails 8 the test pins one connection and Puma's threads share it (the suite's own `application_system_test_case.rb` says so in a comment).
- Tried on `ship_to_me_test`: 20.4s → 16.6s, green. The rule was corrected, and 95 system files were converted the same way as the unit files.

## 9. Memory again: browsers that never close

- The full system run was stopped by Claude Code for low memory (1.5 GB available). Capybara keeps one browser per driver name and per `using_session` name until the worker exits: 3 HGA drivers plus about 10 named sessions.
- **One worker on a mix that switches drivers and sessions:** 95 processes, 4.9 GB peak.
- **`quit_other_browsers`:** after the reset and the Puma idle wait, quit every pooled browser except the one the test used.
  - **First attempt doubled the time (182s → 369s).** `offers_test` already quit its own five named browsers in teardown (#4061). Each test was now building five new sessions only to quit them: 633 quits against 27.
  - The per-file loops were deleted, and the shared helper covers them.
- **Chrome flags, measured on three files:** turning off site isolation took one browser from 1.5 GB to 0.9 GB peak, its 17 processes to 9, and three files ran 10% faster. Five other flag sets made no difference (worth showing that table).
- **Mix result:** 182s / 4.9 GB / 95 processes → 175s / 2.6 GB / 19.

## 10. Shards: the weights go stale when the durations change

- After #4313, CI's shards drifted apart (unit 4:02–4:39, system 2:08–3:03). `test/timings.json` dated from 2026-10-09, and `before_all` changed file durations unevenly.
- Refreshed from the PR's own run with `bin/test-timings <run>`, against the SOP's advice to take the median of five, because the developer chose to. Predicted split: 926/927/925s for unit, 575/575/574/575s for system.
- **Measured on the next run:** unit spread 37s → 20s, system 55s → 28s, and the slowest shard of each 10–19s faster.

## 11. How the work was run (sidebar, optional)

- One session, with a segue thread for thinking and PRs for shipping.
- Parallel subagents with a shared rule file as the spec. Rules learned in one batch went back into the spec for the next: stored files, destroyed records, singleton methods, guard assertions.
- **Guardrails that mattered:**
  - No suite runs while the autopilot driver was running one.
  - `pgrep` before measuring.
  - No `git stash` (a lesson from an earlier incident, kept in memory).
  - Temporary toggles always reverted.
  - zsh's lack of word splitting bit three times and was caught each time.

## 12. Results, and what's left

- Present the headline numbers and the tables below.
- **Still open:**
  - #4159, the shared-blob `capture_image` factory, plus the job-adapter clearing.
  - #4160, staff images opt-in.
  - A timings refresh from master's median after #4313 merges.
  - The HGA responsive tests still visit once per width, which is slow by design.

## 13. Takeaways (candidate closing)

1. Measure memory in Pss with the browser included; RSS lies about forked workers.
2. A native library's memory is invisible to Ruby's GC, so look at per-test RSS deltas, not totals.
3. Every one of today's "obvious" fixes was wrong at least once: eager loading, a slab cache, `reload`, "system tests can't share setup". Each was caught by measuring.
4. Change the seed. Test-order bugs hide behind a green first run.
5. Explain every changed number, down to 12 assertions out of 70,000.
6. Defaults hide fixed costs: a 250ms glide per pointer move, a 1s wait before the first click, a browser per session name forever.
7. When durations change, the weights that balance the shards have to change too.

---

## Results

All local numbers: the project Docker container, 14 cores, 15 GB RAM, MySQL 8.4, measured on 2026-10-16. Memory is Pss of the test process tree (Chrome included), sampled every 5s.

### Full suites

| | Unit, 8 workers | System, 4 workers |
|---|---|---|
| Before (commit `6bc1d121c`, after #4312) | 285s, 18,304 green, peak 6.2 GB, min avail 5.2 GB | 295s, 797 green, peak 10.0 GB, min avail 2.0 GB |
| After (`e88883de3`) | 210s, 18,304 green, peak 7.8 GB, min avail 4.0 GB | **193s**, 797 green, peak 8.7 GB, min avail **5.4 GB** |
| Summed worker time | 2,017s → 1,683s | 1,122s → 747s |

### Unit suite by directory (summed worker time)

| Directory | Before | After |
|---|---|---|
| controllers | 964s | 760s (−21%) |
| models | 300s | 247s (−18%) |
| services | 544s | 484s (−11%) |
| jobs / queries / presenters / integration | 134s | 119s |

### Single files worth naming

| File | Before | After | Change |
|---|---|---|---|
| `admin/items_controller_test.rb` | 70s | 11s | `before_all` |
| `selling/items_controller_test.rb` | 49s | 14s | `before_all` |
| `system/grading/factor_hint_footer_test.rb` | 42s | 20s | no pointer glide |
| `system/auction_real_time_updates_test.rb` | 21s | 12s | `before_all`, browser pool |

### CI (#4313)

| Run | Unit shard steps | System shard steps |
|---|---|---|
| 38955481017 (old weights) | 4:10, 4:02, 4:39 | 3:03, 2:47, 2:08, 3:02 |
| 38957128915 (refreshed weights) | 4:00, 4:20, 4:03 | 2:53, 2:25, 2:28, 2:40 |

### Measured and rejected

- Eager loading for local parallel runs (slower, more memory).
- `Vips.cache_set_max(0)` (no effect).
- PaperTrail off (−4%, inside the noise, and 5 tests fail).
- Warden sign-in for controller tests (`sign_in` is 3% of the heaviest file).
- A memory cache for HGA slabs (the browser already caches them).
- Five other Chrome flag sets.
- A hand-rolled shared-setup helper (same speed as test-prof).

## Open threads to resolve before publishing

- **CI wall-clock before/after on master:** #4313 isn't merged yet. Pull master's numbers after it lands, with the same method as the CI tuning post (first job start to last job end, median of green runs).
- **System assertion count:** 5,269 against 5,275. It's probably guard assertions that moved into `before_all`, but unlike the unit suite it hasn't been diffed per test. Do that before the post claims it.
- **The system suite has had only one full local seed after all changes** (4313). The earlier second seed was stopped for memory before the browser fixes. CI's runs count as more seeds.
- **The unit peak varied between runs** (5.9 GB and 7.8 GB) with no unit code changes. Either explain it or present it as a range.
- **The CI shard weights come from one run.** Show the post-merge median refresh, or mention it.
- **`VIPS_CONCURRENCY=1` and the jemalloc preload are set in `bin/test` only.** Production already preloads jemalloc through `bin/docker-entrypoint`, and its libvips concurrency is unchanged. Say so, so nobody reads it as a production change.
