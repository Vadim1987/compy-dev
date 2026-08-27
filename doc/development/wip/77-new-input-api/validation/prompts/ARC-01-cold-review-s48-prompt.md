# Cold peer review — the input widget's per-run lifetime (session48)

_Prompt of record. Spawned 2026-08-27, model **sonnet** (explicit). Deliverable:
`validation/outcomes/ARC-01-cold-review-s48.md`._

---

You are a cold reviewer on the `compy` LÖVE2D project (repo root `/repo`, your cwd). You are being
asked to peer-review a focused change that is already committed on the current branch. You did not
write it and you have no stake in it. **Review it as you would a colleague's PR: your job is to find
what is wrong, not to confirm what is right.**

## What to review — three commits

```
e684458b  feat(input): compy.input resolves the widget's stores instead of capturing them
314fca05  feat(input): the project widget is built at the run seam and dropped at the stop
e28a20f6  docs(decisions): amend Decision 3 for a per-run widget, scope Decision 7's "frozen"
```

Read them with `git show <sha>`. The change in one sentence: **the project's input widget used to be
a single instance created at application boot; it is now created when a project run starts and
destroyed when the run stops.** The third commit is the ratified spec amendment authorizing it.

## What you must NOT read — this is what makes you cold

Do not open any of these; they contain the author's own reasoning and would make your review an echo:

- `doc/development/wip/77-new-input-api/ROADMAP.md`
- `doc/development/wip/77-new-input-api/implementation/sessions/session48/**`
- `doc/development/wip/77-new-input-api/validation/reviews/ARC-01-03-ledger-amendments-draft.md`
- `doc/development/wip/77-new-input-api/validation/notes/ARC-01-01-*`

**Do read** the ratified spec — `doc/development/decisions/input.md` (especially Decisions 3, 7 and
11) and `doc/development/internals/user_input.md` — plus any code you need. The spec is the
standard you are reviewing against.

**Do not trust the commit messages.** They are the author's claims. Verify each one in code. Two
verdicts on this project have been overturned by someone actually checking, and both checks were
against the PR base — `git show 3256aac:<path>` gives you any file as it was before this feature.

## The questions that matter most

1. **Is the lifetime correct at every seam?** Find every path that starts or ends a project run —
   including `restart()`, the `Ctrl+T` quickswitch, `quit_project`, a top-level raise, suspend and
   `inspect` — and check whether the widget is built exactly once per run and destroyed exactly
   once. **A path that destroys a live project's widget, or leaves a dead project's widget alive,
   is the finding this review exists to catch.** Pay attention to non-blocking projects that settle
   in `'project_open'` and keep running there (`src/examples/sapper` is one): their widget must
   survive that state.
2. **Is anything still holding the old widget?** The surface `compy.input` is built once for the
   application and now resolves the widget's stores per access. Look for any remaining capture — a
   local, an upvalue, a table field, a closure — that would outlive one run. Grep is the right
   opening move; `lua-lsp` (below) is how you prove it.
3. **Nil between runs.** `love.state.user_input_controller` is nil when no project is running. Every
   consumer must survive that. **Careful:** on the project dispatch path a raise is caught by
   `with_canvas_and_errors` (`controller.lua`) and routed to `suspend_run`, so an error there does
   NOT fail a test and does NOT crash the app — "the suite is green" is not evidence on that path.
4. **The tests.** Are the new cases load-bearing, or do they pass for reasons unrelated to what they
   claim? A good check is to break the production line a test covers and confirm that test fails.
   Also: several existing cases were *rewritten* in `314fca05` — check whether each rewrite still
   asserts a real guarantee, or whether it was weakened to fit the new behaviour. **A test that was
   quietly made vacuous is a finding.**
5. **The spec amendment.** Does `e28a20f6` actually license what the code does, and does the code do
   what it says? Is anything in the ledger or `internals/user_input.md` now stale — a passage still
   describing a boot-provisioned widget, a file/line reference that no longer resolves?
6. **Allocation.** The amendment claims per-run allocation is *less* than the pre-feature code did.
   Check that against `3256aac` yourself.

## House rules you are working under

- **Coding rules:** `/repo/agents/rules.md` — hard limits (line ≤64 chars, function body ≤14 lines,
  params ≤4, nesting ≤4), formatting, and the design principles. Comment rules:
  `/repo/agents/rules/commenting.md` — comments must carry information the code cannot, and
  `INTERIM:`/`REMARK:` markers must be zero in `src/` and `tests/`.
- **Tests:** `busted tests` from `/repo`. Baseline on this branch is **978 / 0 / 0 / 10**. A
  different count is itself a finding.
- **`lua-lsp` MCP is available** — a bridge to `lua-language-server` over a real AST of the `/repo`
  workspace: `definition`, `references`, `hover`, `diagnostics`. Use it for correctness questions,
  not as an optimization: grep finds candidates, the LSP resolves them and proves "who calls this".
  For "is anything still holding the old widget", `references` is the right tool and grep is the
  completeness backstop — Lua is dynamically typed, so LSP results can be incomplete; cross-check.
  If you edit any `.lua` file, `sleep 1` before querying the LSP again so it re-indexes.
- **Do not fix anything.** No commits, no pushes, no edits to `src/` or `tests/` that you leave
  behind. You may edit temporarily to test a hypothesis — a mutation, a probe spec — but restore
  the tree (`git checkout -- src/ tests/`) and say in your report what you tried. Never
  `git add <directory>`; the working tree has untracked scratch that must not be touched.

## Your deliverable

Write **`/repo/doc/development/wip/77-new-input-api/validation/outcomes/ARC-01-cold-review-s48.md`**
and make it the real report — your final chat message is discarded, the file is what survives.

Structure it as:

- **Verdict** — one of *approve* / *approve with fixes* / *do not merge*, in the first line, with
  one sentence of why.
- **Findings**, most severe first. For each: what is wrong, **the concrete path that reaches it**
  (inputs/state → wrong outcome), how you verified it, and what you would do about it. Distinguish
  what you **proved** from what you **suspect** — say which.
- **What you checked and found sound.** A reviewer who only lists problems tells the author nothing
  about coverage. Name the seams you walked and the claims you verified.
- **Anything you could not determine**, and what would settle it.

If you find nothing serious, say so plainly — a clean review that names what it checked is a useful
result. Do not invent findings to look thorough, and do not soften a real one to be agreeable.
