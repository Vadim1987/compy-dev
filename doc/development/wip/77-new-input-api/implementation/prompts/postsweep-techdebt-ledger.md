# Post-sweep — establish the tech-debt ledger directory + input-subsystem ledger

_Commissioned by the opus-sweeper PM (session06), 2026-07-13. You are a **cold implementor**
(Sonnet, `agents/dev.md` charter). Repo root = cwd. This is a **doc migration + generation** task,
fact-grounded in already-verified sources. Commit locally; never push; never touch `wip/77` source
docs (you READ them) or nested checkouts' `.git`._

## Why this task exists

The input feature's design/debt corpus under `doc/development/wip/77-new-input-api/` will be
**deleted before the PR** (history survives locally, is NOT pushed). Any durable tech-debt / open
decisions recorded there must be **captured in the permanent corpus first**. The owner's ruling:
evolve the flat `doc/development/technical_debt.md` into a **`doc/development/technical_debt/`
directory** of **per-subsystem ledgers** (one dir, not one file, so future subsystems each get their
own), and fold the input feature's **open rulings + postponed items** into the input ledger.

## What to do — migrate losslessly, then generate the input ledger

**Step 1 — establish the directory by migrating the existing flat register (lose nothing).**
`doc/development/technical_debt.md` today is a flat multi-subsystem register with three parts:
"## Input API (issue 77)" (one standing entry: `keys_pressed` stale on focus loss), a pointer to the
wip ledger, and "## Pre-existing" (two entries: `gfx` implicit global, `table.protect` no-op). Convert:
- Create **`doc/development/technical_debt/README.md`** — the register's intro (carry over the
  existing preamble: "running list of known debt … remove an entry when paid", the tone/intent
  pointer to `conventions/architecture_principles.md` + `../../agents/rules.md`) **plus** a short
  index of the per-subsystem ledgers in the dir.
- Create **`doc/development/technical_debt/general.md`** — the "Pre-existing" entries (`gfx` global,
  `table.protect` no-op) moved **verbatim in substance** (re-tense / de-feature-number only as needed;
  do not rewrite the technical content).
- Create **`doc/development/technical_debt/input.md`** — the input-subsystem ledger (Step 2).
- Then **`git rm doc/development/technical_debt.md`** (its content is now fully in the directory).
- **No inbound doc links point at the flat file** (verified: only `agents/review.md` uses the generic
  `<FEATURE>/implementation/technical_debt.md` pattern, unrelated) — so no link fix-ups are needed.
  Do a final `grep -rn "technical_debt.md" doc/ agents/ --include=*.md` to confirm nothing dangles at
  the deleted flat path; if something does, fix the reference to point at the directory.

**Step 2 — generate `technical_debt/input.md`, the input-subsystem ledger.** Absorb, de-duplicate,
and record as standing debt / open decisions (matter-of-fact, one entry each: *Where · State · Why it
stands · Revisit*), pulling from these sources (all under `wip/77` — read them, they're about to be
deleted):
- The **standing input entry** from the flat file: `keys_pressed` goes stale on focus loss. (Keep.)
- The **8 open owner rulings** — `reviews/owner-rulings-verified.md` (PM-verified, with code cites):
  `compy.keys_pressed` not exposed to projects; `eval`/`result` config-key deviation; combo-tier
  key-repeat fires every repeat (unruled); `multiline` unimplemented; silent config-key drop in
  `show{}`; held-key proxy index-only on LuaJIT; no public `is_active()` visibility query; the
  in-code `REVIEW:` annotation sweep (31 markers in `controller.lua` + `projectInputController.lua`).
  These are the owner's **open decisions** — record each as an open item awaiting a ruling; do NOT
  resolve them.
- The **confirmed dead code**: `love.handlers.userinput` (`controller.lua:976-981`) is unreachable —
  nothing pushes `'userinput'` since the oneshot mechanism was removed. (Standing; safe to delete.)
- The **still-OPEN / accepted / anticipated** items from the wip interim ledger
  `implementation/technical_debt.md` (446 lines) that survive the feature as standing properties —
  e.g. the "Accepted deviations (ship as-is)", the "Anticipated — revisit at the named point", and
  any "open" boundary still open (turtle Esc-clears-in-place, editor cursor-set-outside-API, `F.reset`
  exceeding the 14-line limit, `combo_string` per-call allocation, `gui_k` no consumer, editor buffer
  not cleared on Escape, etc.). **Skip everything marked `Closed`/`~~struck~~`** — those are done.
  Use judgment: only carry items that are still true against the landed code (spot-check the cite);
  if unsure, keep it and mark it "verify".

## HARD framing constraints (the owner was explicit)

- **NO feature/issue/milestone numbers.** Strip "#77 / issue 77 / feature 77 / M2-01 / M4-0 / M5c /
  M8 / Gate N / rc20260712 / sweep". Re-frame every carried item as a timeless property of the input
  subsystem ("the combo dispatch fires on every key-repeat because …"), not "M-something left this
  open". A reader who never heard of the feature project must understand each entry.
- **NO links into `wip/77/`** (being deleted): absorb the content, drop the pointer. Cross-reference
  only permanent-corpus docs + `src/`.
- **Describe, don't rule.** Open owner rulings are recorded as *open*, never decided by you.
- Preserve the register's existing tone (matter-of-fact context, not a defect list).

## Deliverables & boundaries

- The 3 new files + the `git rm` of the flat file. Commit locally (Conventional Commits, e.g.
  `docs(debt): migrate technical-debt register to a per-subsystem directory + input ledger`).
  Doc set in one commit is fine. **No push.**
- Do **not** edit `internals/user_input.md`, `doc/input_api.md`, the decisions doc (a sibling
  subagent owns `doc/development/decisions/`), any `.lua`, or any `wip/77` source. Do **not** delete
  `wip/77`. Do **not** touch nested checkouts' `.git`. Report-don't-fix: a code bug you spot goes in
  the ledger, you don't fix it.
- Final message to the PM (concise): the commit hash, the count of input-ledger entries by class
  (standing / open-owner-ruling / anticipated), confirmation that the flat file's content is fully
  migrated (nothing lost) and that `grep` finds no feature numbers and no `wip/77` links in the new
  files. Do not paste the docs back.
