# S35 — cold revalidation of the tests step and the platform step

**Model: Sonnet (passed explicitly). READ-ONLY except your own report.** You are a sub-agent of the
compy `/repo` session. You do **not** inherit that session's context, and that is the point: you are
here because the session that wrote this code cannot be its own judge. Working directory `/repo`.
Tests: `busted tests` (mock LÖVE, no display needed).

## What you are reviewing

A range of commits that executed two planned steps of a feature. **The span is
`a510f88a..0a84e817`** (inclusive of `a510f88a`). Get it with
`git log --oneline a510f88a~1..0a84e817` and read every diff with `git show <sha>`.

The code commits, in order, are:

- `a510f88a` a docs correction (a suite count quoted in a guide)
- `3f946640`, `354a1267` plan-document edits
- `46952e4c` a new test file for the framework's own shortcuts
- `d630d12f`…`e3d94104`…`2aaf07c1` **belong to the PREVIOUS span but are the same work** — also
  review them: `git log --oneline d630d12f~1..2aaf07c1`. Together these are "the tests step".
- `ac33ccb5`, `b0130412`, `91fbf07e`, `9cb5b636`, `c6d05685` **the platform step**
- `9e241aaf`, `0a84e817`, `fb42b138`, `d2df5872` plan/track bookkeeping — read them for **claims**,
  but they are not themselves the work

**So the full review scope is `d630d12f~1..0a84e817`.**

## THE RULE THAT MAKES THIS REVIEW WORTH ANYTHING

**Commit messages are the author's claims, not evidence.** They are unusually detailed in this
range, and a reviewer who reads them and nods has validated nothing. For every factual claim that
matters, **check the code, the docs, or the test run yourself**. Where a message says "X was
removed", grep for X. Where it says "behaviour is identical", reason about the code paths. Where it
says "the count reconciles", run the suite.

Be willing to conclude that something is wrong. A report that finds nothing is only useful if you
can show what you checked.

## The mandate the work was supposed to serve

Read these, in this order, before looking at any diff:

1. **`agents/validation.md`** — the phase's frame. Note especially the **strategic frame** section:
   stakeholders asked for a *simpler and more robust input API*; the PR must be reviewable from
   `doc/input_api.md` plus the PR description alone, and must not carry moving parts or vocabulary
   beyond that ask without a one-line justification. Note also the commit rules: **one concern per
   commit**, suite green and stated at every commit, a production fix commits **with** its breaking
   test.
2. **`doc/development/decisions/input.md`** — the ratified ledger. **Decision 30** (the held-key set
   is dissolved; modifier state is read from the device), **Decision 31** (the modifier set is
   closed: ctrl/alt/shift), and for context Decisions 8, 13, 20, 21, 26.
3. **`doc/development/wip/77-new-input-api/validation/reviews/S27-triage-and-plan.md`** — the plan.
   **§11.4.1 is the tests step (P14c) and §11.4.2 is the platform step (P14d); those two sections
   are the commissioned mandate**, including their explicit "what this step must NOT do" lists. The
   §4 table rows for P14c/P14d/P15 carry further detail. **Ignore §§6–14 except where a step points
   at them** — they are dated reasoning, not the operative instruction.

## The four questions, in priority order

**1. OMISSION — did the work skip something the step required?**
Walk §11.4.1 and §11.4.2 clause by clause and confirm each one landed. The platform step enumerates
its sites by role (bookkeeping, the field, the view and its memoisation, the sandbox exposure, the
consumer, the builder's parameter, the declarations and prose, and the `gui` row). For each: is it
actually gone or actually rewired, in the code, today? Both steps also carry doc obligations
(markers cleared, debt entries deleted, citations moved) — verify those in the files.

**2. EXCESS — did the work change anything it was not asked to change?**
This is the harder half and the one the author is least able to see. Go through the diffs looking
for edits that serve no clause of the mandate: renamed things that did not need renaming, comments
rewritten beyond the change, behaviour altered as a side effect, files touched for tidiness. The
strategic frame is the test: does each change make the system more predictable, or merely more
elaborate? **Anything you cannot trace to a clause of the steps or a ledger decision is a finding**,
even if it looks like an improvement.

Note specifically: the working tree contains in-code `REMARK:` markers that belong to the project
owner and must **not** have been swept into these commits. Check whether any were removed or edited.

**3. APPROPRIATENESS — are the changes the right shape?**
Judge the remove-versus-rewire calls, the test deletions (did the suite lose the ability to catch
something, and was that sanctioned and stated?), and whether any doc passage that had its `PENDING`
marker removed is **actually true of the tree now** — read the passage and check it, do not assume.

**4. THE THREE DECLARED DEVIATIONS — judge them independently.**
The author states three departures. Form your own view on each; agreeing is a useful result, and so
is disagreeing:

- a planned test-deletion range (`input_events_spec.lua:781-901`) was **not** used, on the grounds
  that it over-reached into unrelated live test cases. Was the narrower cut right, and is anything
  now missing that the wider cut would have removed correctly?
- a test case the step said to **delete** (the `gui` combo case) was **rewritten** instead.
- three test cases that registered a project shortcut on `ctrl+s` were changed to use `ctrl+j`,
  on the grounds that the framework's own gateway claims `ctrl+s` and the cases only passed because
  the test fixture never held modifiers on the device. **Check this one carefully**: is that
  characterisation of the production behaviour actually correct, and is changing the test the right
  response rather than a way of making an inconvenient failure disappear?

## Two behavioural questions worth their own attention

- **The guard hoist.** `find_shortcut` (`src/controller/projectInputController.lua`) previously
  built a combo string, looked it up, and only then returned nil for a modifier's own press. It now
  returns early. The claim is that this is behaviour-identical because no combo naming a modifier as
  its trigger can ever be registered. **Verify that claim** against combo registration
  (`src/util/key.lua`, `check_combo` / `normalize_combo` and their callers). If a modifier-triggered
  combo CAN reach the table by any route, the hoist changed behaviour.
- **The fixture now holds modifiers on the mock device.** `tests/helpers/input_session.lua` and
  `tests/helpers/input_fixture.lua`. Does this make any existing assertion weaker or vacuous — a
  test that now passes for a different reason than it used to, or one that could no longer fail?

## Tools

**grep is your completeness backstop.** A `lua-lsp` MCP server (definitions / references /
diagnostics over a real AST) is available and is good for "who calls this"; this repo has a standing
finding that its references **miss** occurrences routed through metatable `__index` dispatch on
string keys, so never trust a thin LSP result — confirm with grep. Run `busted tests` yourself
rather than trusting a stated count.

## Deliverable

Write to
`/repo/doc/development/wip/77-new-input-api/validation/outcomes/S35-p14cd-cold-revalidation.md`:

- **Verdict** — one paragraph, up front. Is this work sound as it stands?
- **Omissions** — anything required and missing.
- **Excess** — anything changed without mandate, however small.
- **Appropriateness** — shape judgements, including any lost coverage.
- **The three deviations** — your independent view of each.
- **The two behavioural questions** — your answers, with the reasoning.
- **What I checked and found correct** — so the parent does not re-derive it.
- **What I could not determine** — be explicit rather than silent.

Quote file paths and line numbers. Order findings by consequence, not by discovery order.

**Do NOT edit any file except your report. Do NOT run any git write command** (no `add`, `commit`,
`checkout`, `stash`, `restore`). Do not modify tests to "check" something — reason instead.
