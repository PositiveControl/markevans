# Workflow configuration

Written by `/workflow_setup` on 2026-10-03. Re-running the wizard reads this file as its defaults.

| Token | Value |
|---|---|
| `TRACKER` | `labels` |
| `GITHUB_ORG` | `PositiveControl` (personal account: GraphQL uses `user(login:)`) |
| `GITHUB_REPO` | `markevans` |
| `BRANCH_PREFIX` | `me` |
| `PR_TITLE_PREFIX` | `ME` |
| `REVIEW_LABEL` | `ready for review` |
| `PERSONA` | `Staff Rails Engineer, TDD advocate` |
| `FAST_CI_CHECKS` | `scan_ruby, scan_js, lint, gates` |
| `FAST_CI_CHECKS_JQ` | `"scan_ruby","scan_js","lint","gates"` |
| `SLOW_CI_CHECKS` | `test` |
| `PROJECT_NUMBER`, `PROJECT_NAME`, `PROJECT_ID`, `STATUS_FIELD_ID`, `STATUS_*` | `n/a` (tier `labels`) |
| Default branch | `main` |
| Lint (changed files) | `bin/rubocop --force-exclusion` |
| Lint auto-fix | `bin/rubocop -a` |
| Tests | `bin/test` |
| System tests | `bin/rails test:system` |
| Security scan | `bin/brakeman -q --no-pager` |
| Iteration filter in `/pick` | off |

Status labels: `status:todo`, `status:in-progress`, `status:up-for-review`, `status:blocked`, `status:done`.
`lighthouse` is a weekly workflow, neither fast nor slow, and is not polled.
