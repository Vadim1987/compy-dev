# BUG-01-01 — cold review commission (session47, 2026-08-26)

**Model:** Sonnet (explicit). **Deliverable:** `validation/outcomes/BUG-01-01-cold-fix-review.md`.
Prompt of record per sub-agent hygiene (c). The prompt handed to the agent follows verbatim.

---

You are reviewing a focused two-commit PR against a LÖVE2D/Lua codebase at `/repo` (branch
`feature/77-newapi-analysis-s20260615`). Review it as a stranger would: **you did not write it and
you have no stake in it being right.**

## The PR

The diff, with full commit messages, is at:
`/tmp/claude-1000/-repo/ef2c515e-51a4-4fd8-bcad-e09071cce248/scratchpad/coldrev/pr.diff`

Two commits matter — `bd2a5d49` (the production fix + its test + doc updates) and `abadf244` (a
technical-debt ledger correction). A third, `3b0e9f61`, is bookkeeping and is **out of scope**.

## Hard boundary — what you must NOT read

**Do not read anything under `doc/development/wip/77-new-input-api/`.** That directory holds the
author's own analysis, session notes and planning documents. Reading them tells you what the author
*concluded*, and a review against the answer key reports what the author did rather than whether it
was right. If you find yourself in that tree, back out.

Everything else in `/repo` is fair game and you are expected to use it: `src/`, `tests/`, `doc/`
outside that one subtree — in particular `doc/input_api.md`,
`doc/development/internals/user_input.md`, `doc/development/decisions/input.md`,
`doc/development/technical_debt/input.md`.

## Tooling

- **The `lua-lsp` MCP server is DOWN** (the language server died on 2026-08-25 and the bridge was
  killed). Do not try to use it. **Use `grep`/`rg` and read the files.** Where you would normally
  ask the LSP "who calls this", grep the whole of `src/` and `tests/` and read each hit — Lua is
  dynamically typed and a name-only match is a hint, not a fact.
- Run the suite with `busted tests` from `/repo`. It needs no display. Expect
  `969 successes / 0 failures / 0 errors / 10 pending`. **The 10 pending are deliberate** (an owner
  ruling: 3 routing-grid cells that are not black-box observable, 7 framework-reserved combos) —
  they are not your finding. An 11th would be.
- **Counting greps: never pipe to `| head`.** It has silently undercounted defects in this codebase
  twice. Use `grep -c` or read the whole output.

## What the PR claims

The commit messages state the defect, the reasoning and the fix. **Treat every claim in them as an
assertion to verify against the code, not as context to accept.** A commit message that describes
the tree accurately is evidence; one that does not is itself a finding. Checking a description
against reality has already caught real defects in this project.

## What to review, in priority order

1. **Is the diagnosis true?** The PR claims a private store had application lifetime because the
   closure that owns it is built exactly once, and that env cloning does not separate instances
   (the surface is metatable-only and `table.clone` preserves the metatable). Verify both claims in
   code — the call graph and the clone helper. If either is false the whole fix is misaimed.
2. **Does the fix actually close the hole, on every path?** Find every path that ends a project run,
   not only the one the test drives. If any of them reaches the old state and not the new teardown,
   say so with the path.
3. **Did the fix open a new hole?** The store moved onto an object with application lifetime of its
   own. Ask what happens across hide/show *within* one run, across a failed run, and if the object
   is ever replaced. Check every construction site of that object for the new field.
4. **Is the test honest?** Would it fail without the production change? Does it assert at a seam a
   project can actually observe, or does it reach into internals? Does it prove the thing the
   commit message says it proves?
5. **Is the sibling claim true?** The PR asserts that the neighbouring stores in the same table do
   *not* share the defect because teardown already covers them. Verify, don't assume — this is the
   claim that justified keeping the fix small.
6. **Documentation.** The PR edits a decisions ledger, an internals guide and a debt register. Do
   those edits match what the code now does? Is anything now stale or contradicted elsewhere?
7. **House rules.** Lines ≤64 chars, function bodies ≤14 lines, ≤4 params, nesting ≤4. Comments must
   carry information the code cannot (`/repo/agents/rules/commenting.md` if you want the full gate).
   Comments must cite persistent docs (`doc/…`), never `doc/development/wip/…`.

## Two judgment questions, stated plainly

- **Was the design choice right?** The draft could instead have stayed in its original closure with
  a teardown handle published to the framework. The author chose to move it onto the widget,
  arguing it sits beside an existing store with identical lifetime and adds no public surface. This
  API's explicit mandate is *fewer* moving parts. Is the choice defensible, and would you have made
  a different one? Say which and why.
- **Is the vocabulary sound?** The word "draft" is used throughout. Judge whether it reads clearly
  to someone meeting this code for the first time. (It is already under separate review — you are
  not settling it, just reporting how it reads to a stranger.)

## Deliverable

Write your review to `/repo/doc/development/wip/77-new-input-api/validation/outcomes/BUG-01-01-cold-fix-review.md`
(writing there is fine — the read ban is about not *consuming* that tree).

Structure it as:

- **Verdict** — one of `approve` / `approve with changes` / `request changes`, one sentence.
- **Claims checked** — a table: claim from the commit message → verified / contradicted / could not
  check, with the file:line that settles it.
- **Findings** — each with severity (major / minor / nit), the file:line, and a concrete failure
  scenario (inputs or sequence → wrong result). **A finding with no failure scenario is an opinion;
  mark it as one.**
- **The two judgment questions** — answered directly.
- **What you could not check** and why.

Be specific and be willing to approve. Inventing findings to look thorough is worse than a short
review: this project would rather ship a clean "approve" than chase a phantom. Equally, if the fix
is wrong, say so plainly.
