# session68 — finish `FIX-02` half (a), and `CHG-01` with it

Read `agents/sessions.md` and `agents/validation.md` first, then the predecessor report
[`../session67/report.md`](../session67/report.md).

Baseline: **1050 / 0 / 0 / 10** (LuaJIT 2.1 in the container). A different count is a finding, not a
go-signal.

## Carryover — what changed under you

Session67 closed **eight of the eleven rows** in `FIX-02` half (a): `-22`+`-13`, `-25`, `-06`, `-23`,
`-03`, `-04`, `-24`. **`ACTIVE` in `technical_debt/input.md` is now empty**, and the section says so
in words. One spec was added (`tests/input/input_config_key_agreement_spec.lua`, +2 tests); no other
production or test code moved, and `controller.lua` was touched for comments only.

- **Every one of those eight rows was mis-sized** — larger (more sites than the cell named) or
  smaller (already fixed). The prompt's *"a count in a row is a lower bound"* is the operating
  condition of this sprint, not a caution. **Re-derive every sizing before working the row.**
- **Three rows turned out to sit on design questions**, and twice the owner reframed before I did:
  `-22` (retire the rule rather than amend the spec to match it), `-06` (a rename that needs a design
  decision first — filed BACKLOG, not done), `-24` (mark historical rather than correct). **A wrong
  sentence about a rule is a reason to re-examine the rule.** Expect this and surface the category
  question with the fix.
- **Three BACKLOG entries were filed** — the read-only content getter, the `release_keyboard_route`
  naming, and `@field` annotations disagreeing with their own constructors (`general.md`).

## Your task

**Finish half (a), in this order:** `FIX-02-05` → `FIX-02-17` → `CHG-01`, then the
`smoke_checklists.md` slice of `FIX-02-09`. This is a working session; execute.

**`FIX-02-05` is the largest row in the half and gates the rest.** Its cell says *"20 resolved
entries"*; there are **51**, counted 2026-09-02. Each is base-checked. It **must precede
`CHG-01-03`**, which names it as its feeder. The roadmap records the owner's fallback if it proves
too large to run before the sitting — read that before you start, not after.

**`CHG-01` gates `ACC-02` and every slice cut**, and is the last thing in the brace doing so. It is
four steps and includes the `1.0.0-rc` version question, which is an **owner call** — raise it, do
not settle it. `FIX-02-17` feeds it, so they are one sitting.

**The `-09` slice goes last in the half** because it is a vocabulary sweep and the rows before it are
still writing prose onto that floor. Do not pre-empt its (b)-half scope.

## Standing constraints

- Suite green at every commit, count stated in the message; commit at the seam, one concern each;
  **never push** — the platform repo or either nested one.
- A behaviour change is **never** documented in the commit message alone.
- **A finding goes to the debt ledger the moment it is found.** Fixed the same day, the record is the
  RETIRED entry; it lands in the ledger either way.
- **Before filing a surface finding, check whether a decision or a rule already draws that line.**
  Session67 found `technical_debt/general.md` already held a class it was about to re-file, and added
  a worked instance instead. **Read the ledger, not the commit trail.**
- **A line citation is verified by resolving the exact line, or not at all.** An errored or
  unsupported query is not an empty result. Expect drift: every citation `FIX-02-03` and `-04`
  touched had moved.
- **A citation sweep's scope is where the citations are, not where the code is.** `FIX-02-06` swept
  three sites and `FIX-02-04` — a row filed for something else — found a fourth, in pointer
  annotation text. **A claim spreads by being restated in passing.**
- **Dropping a slug from a heading owes a citation sweep in the same commit** (`roadmap.md` §5).
- **Prove a mechanical edit, do not eyeball it** — and read a substitution to the end of the
  *sentence*, not the end of the token it replaced. Session66 recorded this as F5; session67 made the
  same error anyway and caught it by re-reading the rendered paragraph, not the diff.
- **Run the example, do not reason about it.** A guide example that was reasoned about was wrong; the
  same example, executed in a scratch spec first, was right.
- Stage explicit paths. `git add -A` in `/repo` commits the nested example repos as gitlinks.
- Say **widget**, not "field" or "overlay" — and *the widget is shown*, not *the field is open*.
  Session67 broke this twice while writing **about** the widget; that is where it happens.
- Comments cite canonical `doc/…` and a **named section**, never `wip/77`. Check the heading exists
  before citing it.
- The owner also works in this tree. Never sweep their unrelated working-tree changes into a commit.

## Sub-agents — read this before you spawn anything

**Two Opus sub-agent spawns took the container's host down** on 2026-09-02 (100% CPU, maximum disk
read, active swapping, hard reboot within ~20 seconds, nothing written). Diagnosis:
[`validation/notes/S67-subagent-host-crash.md`](../../../validation/notes/S67-subagent-host-crash.md).

- **Every spawn prompt gets an explicit leaf-agent clause** — *"do not use the `Agent` tool, work
  sequentially"* — stated **with its reason**, or the agent routes around it as fussiness.
- **Scope the agent's searches.** Never recurse from `/repo` root: 63 MB of `.git`, 28 MB of binary
  assets under `src/assets/`, a tarball and five nested repositories. Prefer `git grep`.
- **`lua-lsp` is one shared server** — instruct serial queries.
- **Sonnet is the only configuration observed to survive** here (nine and eleven minutes, two
  spawns). Prefer it; it also found a real error in the persistent corpus.
- **The container still has no memory or CPU ceiling** (`memory.max` = `cpu.max` = `max`), so a
  runaway takes the host, not the box. **Owner's call, open** — compose stack under
  `implementation/docker`.
- The general hygiene rule that failed: saying *"you inherit none of the repo's CLAUDE.md"* and then
  restating a subset is a **licence to do anything unrestated**. Restate the constraints on the
  agent's **behaviour**, not only on its conclusions.

## Environment facts, stated because they qualify every claim you will make

- **The container runs LuaJIT 2.1; the owner runs PUC Lua.** Container-green is not their-machine
  green. State the interpreter behind any suite claim.
- **`lua-lsp` was healthy in session67** — `diagnostics` clean, `references` correct on two symbols.
  But it **under-reported twice**: an empty `references` on `UserInputController:set_eval` read as
  dead code, and grep proved three callers. **Empty is a hint, never proof of absence.**
- **Markdown is not bound by the 64-character limit** — `agents/rules.md` scopes it to *coding*.
  Comment blocks in `.lua` are.

## Open with the owner, deliberately not taken

- **`design/` amendment for `FIX-02-22`** — recommendation on disk
  ([`validation/notes/FIX-02-22-frozen-design-sites.md`](../../../validation/notes/FIX-02-22-frozen-design-sites.md)):
  **do not amend.** `D-CFG-BOUNDARY` establishes the deviation by quoting the round-2 sentence
  **verbatim**, so rewriting the spec breaks that citation on purpose. Fallback offered: one
  precedence line at the top of `design/spec.md` instead of five edits. **Owner-gated either way.**
- **The container resource ceiling** — see above.
- **F6, inherited from session66** — `ROADMAP.md`'s section bodies no longer run in sequence order
  (`DOC-01` → `ACC-02` → `ACC-03` → `REC-01` → `MERGE-01`). The sequence line is correct; the move is
  a large diff in a file the owner reads, so it is theirs to call. **Do not take it unprompted.**

## Your predecessor's work was cold-reviewed before you got it

[`validation/outcomes/S67-cold-peer-review.md`](../../../validation/outcomes/S67-cold-peer-review.md),
commission in `validation/prompts/`. **Verdict: the work holds** — ~two dozen claims resolved against
source, all as stated. Two low findings, both applied: a date over-generalised from four mermaid
files to seven (it had reached the persistent corpus), and a miscount in the commission's own
summary. Neither changed a disposition.

**The one thing it says that this prompt cannot:** the session had both halves of the date fact in
hand — *"four added 2024-07-29"* and *"three committed as unfinished docs"* — and merged them into
one wrong sentence anyway. **A claim assembled from two true facts is not thereby true.**
