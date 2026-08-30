# Sub-agent prompt of record — cold peer review of `FEAT-01`

**Commissioned:** session57, 2026-08-30, at the owner's direction. **Model:** Opus (judgment work —
this review can overturn a ruling, so it is not Sonnet's tier). **Deliverable:**
`doc/development/wip/77-new-input-api/validation/outcomes/FEAT-01-peer-review.md`.

**Why cold:** the parent session wrote every line under review, including the sheet that framed the
owner's ruling. A reviewer who reads the parent's reasoning inherits its blind spots. So the
reviewer is pointed at the **ledger and the code**, and is told explicitly what not to open.

---

The prompt as issued:

---

You are reviewing a completed sprint in a LÖVE2D project at `/repo` (branch
`feature/77-newapi-analysis-s20260615`). You are a **cold peer reviewer**: you did not write any of
this and you have no stake in it. Your job is to find what is wrong with it, and to say plainly if
nothing is.

## What was built

`FEAT-01`, two changes to the project-facing input API:

1. **`oneshot`** — `compy.input.show{ oneshot = true }` takes the input widget down after a
   successful submit, so a project needing one answer installs no lifecycle callback.
2. **The payload split** — `on_text_entered` now receives the submitted content as one joined
   string; `after_submit` still receives the list of lines. Breaking change on a documented
   callback.

## Read these — they are the specification

- `doc/development/decisions/input.md`, **Decision 36** (`oneshot`, including its four **ruled**
  edges) and **Decision 37** (the payload split). These are the owner's rulings and are the standard
  you review against.
- `doc/input_api.md` — the project-author guide. It is what a stakeholder reviews the PR from.
- `doc/development/internals/user_input.md` — the submit/cancel section.
- `CHANGELOG.md` — `CURRENT_SCOPE`, the `Added` and `Changed` sections.
- `doc/development/technical_debt/input.md` — `T-ONESHOT` and `T-PLAINTEXT-ENTERED` are now under
  `## RETIRED`.

## Do NOT read these — they would make you warm

- `implementation/sessions/session57/` (the parent's prompt and track)
- `validation/reviews/FEAT-01-ledger-executability.md`
- `validation/reviews/FEAT-01-01-oneshot-ruling-sheet.md`

If you find yourself needing one of them to judge something, say so in your report instead of
opening it — that itself is a finding about the work's self-sufficiency.

## The diff under review

`git diff 02cc51f9..HEAD` in `/repo` (twelve commits). Two more commits live in **nested repos with
their own remotes**: `src/examples/maze` (`d2be028`) and `src/examples/balloons` (`6d6c6e3`).
Read the commit messages — this project holds them to a high standard and they are part of the work.

## What to check, in rough priority order

1. **Correctness.** Does `oneshot` do what Decision 36's ruled edges say, in every case, including
   the ones no test covers? Does the payload split leave any consumer, in `src/` or `tests/` or the
   nested repos, reading an argument that is no longer the shape it expects? Lua strings index to
   `nil` rather than raising, so a missed consumer fails **silently** — hunt for one.
2. **Test honesty.** Do the tests pin the claims, or do they pass for a reason other than the one
   they name? Would any of them still pass with the production change reverted?
3. **The reversed edge.** Decision 36 originally recommended that `oneshot` close even when a
   callback raised; the owner ruled the opposite. Read the reasoning in the decision and check it
   against the code — is the claim about where the error boundary sits actually true?
4. **Documentation fidelity.** Is anything in `doc/input_api.md` now false, or newly ambiguous? Can
   a project author who reads only that guide use both features correctly? Is there anywhere the
   guide still describes the old payload?
5. **Scope and restraint.** The stakeholder ask was a *simpler and more robust* input API. Does
   this work add moving parts beyond it? Is any part of it more elaborate than the problem?
6. **Commit hygiene.** One concern per commit; a behaviour change documented in a document and not
   only in a commit message; suite count stated and reconciling arithmetically.

## Verify in code, do not take anyone's word

The `lua-lsp` MCP server is available: definitions, references, diagnostics and rename over a real
AST of the `/repo` workspace. **Use it** — grep to find candidates, then the LSP to resolve a symbol
and to prove "who calls this". Lua is dynamically typed, so LSP references can be incomplete: treat
them as a strong hint and use grep as the completeness backstop. After editing any `.lua` file,
`sleep 1` before querying refs/diagnostics so the server re-indexes.

Run the suite yourself: `busted tests` from `/repo` (expected: 1020 successes / 0 failures / 0
errors / 10 pending — the 10 pending are an owner ruling, and an eleventh would be a finding).
Note: this container runs **PUC Lua**, not LuaJIT.

**Do not change any file** other than your report. If you believe something must change, say what
and why; the parent session will act on it.

## Your report

Write to `doc/development/wip/77-new-input-api/validation/outcomes/FEAT-01-peer-review.md`.

Open with a one-line verdict: **approve** / **approve with comments** / **request changes**. Then
the findings, each with: what is wrong, the evidence (file and line, or a command and its output),
how it fails in practice, and how confident you are. Rank by severity.

**A finding you are not sure about is still worth reporting — say so and give your reasoning.** A
report that finds nothing is a legitimate outcome and is more useful than an invented defect;
padding a review with speculation wastes the parent's verification budget. Be specific about which
claims you verified in code and which you took from a document.
