---
description: "Plan one issue: task file, implementation plan, then a branch"
argument-hint: "<issue number>"
---

# Task Plan

Plan one issue's implementation: explore → task file → human approval → branch. Planning only — execution is `/implement`. Pass the issue number: `/task_plan 1613`.

## Instructions

### Step 1: Fetch issue details

```bash
gh issue view $ARGUMENTS --repo PositiveControl/markevans
gh issue view $ARGUMENTS --repo PositiveControl/markevans --json comments --jq '.comments[] | "[\(.createdAt)] \(.author.login): \(.body)"'
gh api graphql -f query='{ repository(owner: "PositiveControl", name: "markevans") { issue(number: <ISSUE_NUMBER>) { parent { number title body } subIssues(first: 20) { nodes { number title state } } } } }'
```

**Shape check:** issue has no acceptance criteria, >5 acceptance bullets, size XL, or open sub-issues → stop, route to `/feature_plan $ARGUMENTS`. Oversized work never enters task planning.

### Step 2: Read the design doc

Issue has a parent (or links a design doc)? Read the matching `docs/plans/*-design.md` first — constraints, rejected alternatives, and slice boundaries are already decided there. Do not re-litigate them.

### Step 3: Explore the codebase

1. Search `docs/` for docs, patterns, gotchas in the affected area
2. Find relevant models, controllers, views, services, Stimulus controllers
3. Read key files — understand current behavior
4. Find existing tests for the affected area
5. Check for an existing `.llm/tasks/` file for this issue number (exists → consider `/implement $ARGUMENTS` instead)

Be thorough — understanding current code is critical for a good plan. Use a dedicated search pass (a subagent, if your tool has them) or plain glob/grep/read. Blocked on a decision the issue doesn't answer? Suggest `/grill "<the decision>"` for something this session can settle with the user, or `/segue <question>` for something needing its own session.

### Step 4: Create the task file

Create `.llm/tasks/<issue_number>_<snake_case_slug>.md` from `.llm/tasks/task_template.md`:

- **Goal**: from issue body
- **Background/Context**: synthesized from issue, comments, design doc, exploration
- **Requirements & Acceptance Criteria**: from the issue (in scope AND out of scope explicit)
- **Base**: `main`, unless the issue body, its parent, or the design doc names a feature branch `feature/<slug>` — then that. Every later command diffs and opens the PR against this line
- **Next Actions**: concrete implementation steps — files to modify, approach, test strategy. **Last action is always the QA walkthrough** (`docs/system/qa_walkthrough.md`): which `step`s the change adds to `script/qa/<feature>.rb` (or a new script), or the one-line reason there is nothing to show (no user-facing change; API-only app). `/pr_submit` Step 3b checks this landed
- **References**: issue, parent, design doc, key source files

Conventions live in `CLAUDE.md` — the task file references it, never copies rules.

### Step 5: GATE — present the plan for approval

1. **Issue**: number, title, brief description
2. **Approach**: high-level fix/feature description
3. **Files to change**: each file + brief change description
4. **New tests**: coverage to add
5. **Size forecast**: estimated added lines and files vs the 200–1,500 / 25 target — over → propose a split now
5b. **Walkthrough**: the steps the change adds to the QA walkthrough, or why it has nothing to show — the developer can strike it here
6. **Risks/Questions**: anything needing clarification
7. **Flagged decisions**: architecture choices or new patterns (ALWAYS need user approval)

**Wait for approval** — approve, adjust, or answer questions before proceeding. More than a couple of flagged decisions, or risks nobody can price → `/grill "<the issue title>"` and come back to this gate.

### Step 6: Set up for implementation

After approval:

**Clean working tree:** `git status` — uncommitted changes → ask user: stash or commit first.

**Feature branch, if the task file's `Base:` names one and it is not on the remote yet** — this is the feature's first slice, so create it and open its draft PR:

```bash
git checkout main && git pull
git checkout -b feature/<slug> && git push -u origin feature/<slug>
gh pr create --draft --base main --head feature/<slug> --title "ME | <PARENT> | <feature title>" --body "$(cat <<'EOF'
## Feature
<one line, and a link to docs/plans/<design doc>>

## Slices
- [ ] #<sub-issue> — <slice title>
- [ ] …

Closes #<PARENT>
EOF
)"
```

`<PARENT>` is the parent issue under `github-projects`. Under `labels` there is none — use the slug in the title and drop the `Closes` line. Under `beads` drop the `Closes` line too; the epic is reconciled by `/pick`. Slice PRs never carry `Closes`; this body collects them as slices land (`WORKFLOW.md`, *Feature branches*).

**Slice branch:**

The `<ID>` segment is the tracker's identifier — a bare number under `github-projects` and `labels` (`1613`), or the bead ID under `beads` (`bd-a3f2dd`, from `tst-a3f2dd` with the prefix normalised to `bd-`). It is the thread ID that ties branch, task file, and PR together. `<BASE>` is the task file's `Base:` line.

```bash
git branch --list "me/<ID>/*"
```
- Exists → `git checkout me/<ID>/<slug>`
- Not → `git fetch origin <BASE> && git checkout -b me/<ID>/<short-slug> origin/<BASE>`

**Mark In Progress** — tier `labels`:

`github-projects`:
```bash
gh api graphql -f query='{ repository(owner: "PositiveControl", name: "markevans") { issue(number: <ISSUE_NUMBER>) { projectItems(first: 5) { nodes { id project { title } } } } } }'
gh project item-edit --project-id n/a --id <ITEM_ID> --field-id n/a --single-select-option-id n/a
```

`beads`:
```bash
bd update <ID> --claim
```
Atomic — sets assignee to you and status to `in_progress`, and **fails if someone else already claimed it**. A failure here is real information: stop and pick different work rather than forcing it.

`labels`:
```bash
gh issue edit <ISSUE_NUMBER> --add-label "status:in-progress" --remove-label "status:todo"
```

### Next step

```
Plan approved and branch ready. Run: /implement <ISSUE_NUMBER>
```

## Reference
- Repo: PositiveControl/markevans
- Task template: .llm/tasks/task_template.md
- Branch convention: `me/<id>/<slug>` — `<id>` is a number, or `bd-<hash>` under tier `beads`
- Feature branch: `feature/<slug>`, named in the design doc and sub-issue bodies; base for every slice of a multi-slice feature
- Project ID: n/a · Status field ID: n/a
- Tracker tier: `labels`
- Status option IDs (tier `github-projects`): Blocked=n/a, Todo=n/a, In Progress=n/a, Up for Review=n/a, Done=n/a
- Sizing: PR target 200–1,500 added lines / ≤25 files
