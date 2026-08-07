# S27 sub-agent prompt of record — cold fact-check of the triage

**Model:** Sonnet. **Spawned:** 2026-08-07, session27. **Nature:** verification
against code. Read-only. Cold — you have not seen the reasoning that produced
the document you are checking, and that is deliberate.

---

You are working in the LÖVE2D project **compy**, repo root `/repo` (your cwd).
This is a **read-only** task: do not edit source, tests or docs; do not commit;
do not push. Your only write is one markdown file, named at the end.

## Situation

A large feature branch (the "new input API", feature #77) is being prepared for
a PR. The project owner reviewed the whole branch and left 187 inline remarks
in the code, tests and docs. A previous agent extracted them verbatim into an
inventory. A triage document then assigned each remark a severity and grouped
them into workstreams with an execution plan.

**Your job is to check whether that triage is factually right.** Not whether it
is well written, not whether you would have grouped things differently —
whether its **claims about the code are true**.

Read, in this order:

1. `doc/development/wip/77-new-input-api/validation/reviews/S27-triage-and-plan.md`
   — the document under review.
2. `doc/development/wip/77-new-input-api/validation/outcomes/S27-remark-inventory.md`
   — the verbatim remarks it triages (ids R001–R187). Large; read Part 1 and
   Part 3 in full, and Part 2 entries as you need them.

Do **not** read the session directories or other review documents first — the
point is that you come to the code cold.

## What to check

### A. Every factual claim about code

The triage asserts things about the implementation. Each is checkable. Examples
of the kind of claim to verify (this list is illustrative, not exhaustive — go
through the document and extract them yourself):

- W1: that hooks/shortcuts receive `(k, keys_pressed, isr)` and that pointer
  channels receive LÖVE's arguments untouched; that `ignore_repeat` reads
  `(k, keys, isr)`.
- W2: that `find_shortcut` returns nil for a missing table, that pointer
  channels pass `trigger = nil`, and — the load-bearing one — that
  `combo_string('*', keys)` already builds a triggerless combo key, i.e. that
  the machinery for a keyless combo exists today.
- W3: that `singleclick`/`doubleclick` are dispatched by the generic pointer
  loop but absent from `EVENTS`, so `seed_hooks` never seeds them; that
  `reset_compy_input` wipes exactly three hand-listed keyboard shortcut tables.
- W5: that `submit()` calls `before_submit` and **discards its return**, while
  `cancel()` honours `before_cancel`'s truthy return as a veto; that
  `before_submit`/`before_cancel` are absent from `default_callbacks()`.
- W6: the claim that the widget has no return value to give and consumes on
  `is_shown()` alone.
- W8: the claim that a bare unmodified key is a legal, documented shortcut
  combo (so the tests registering `shortcuts.keypressed['a']` are correct and
  the owner's R060 question is answered "no, shortcuts are not modifier-only").
- W9: that `gfx` is the house alias convention rather than an undeclared free
  variable; that projects *can* configure a validator (so the doc claim
  "projects cannot install evaluator objects" is stale); that `dispatch` is in
  fact reusable.

For each claim: **state the verdict (CONFIRMED / WRONG / PARTLY), cite the
file:line you checked, and quote the line if it decides the matter.** A verdict
with no citation is worthless to me.

### B. Misfiled severity

The scale is S0 possible defect / S1 shape-changing (contract or structure) /
S2 code-structural, behaviour preserved / S3 doc states something false /
S4 editorial / S5 question.

Look for remarks the triage has **under**-rated — an id filed under W10
(editorial, 92 ids) or W7 (structural) that, read against the code, is actually
a defect or a contract change. This is the single highest-value thing you can
find. Spot-check the W10 list against the inventory text; you do not need to
open all 92, but say how many you checked and how you chose them.

Also look for the opposite: something rated S0/S1 that is plainly cosmetic.

### C. Coverage and internal consistency

- Every id R001–R187 must be assigned to exactly one workstream. (I believe
  this holds; verify it rather than trust it.)
- Does any workstream's membership contradict its own description?
- Does the plan's phase table (§4) have a dependency that runs backwards — a
  phase depending on work scheduled after it?

### D. The declines

§3 lists five things the triage recommends **not** doing. For each, say whether
the stated reason survives contact with the code. R080 (should the input widget
be an ordinary chain element returning a boolean, rather than a special tier
that consumes whenever it is shown?) is the one I most want checked — read
`src/controller/projectInputController.lua`'s `dispatch` and the widget's own
methods before answering.

## Tools

- **The `lua-lsp` MCP server is available to you** — defs / refs / hover /
  diagnostics over a real AST of the `/repo` workspace. This task is exactly
  what it is for: grep to find candidates, then LSP to resolve a symbol, prove
  who calls it, and confirm a function's real signature. Use `references` for
  every "is this still called / is this dead" question. Treat LSP refs as a
  strong hint and grep as the completeness backstop — Lua is dynamically typed
  and refs can be incomplete.
- `git show 3256aac:<path>` shows a file **as it was at the PR base**, before
  this feature. Use it whenever the triage or a remark claims behaviour is
  pre-existing or newly introduced. This check has overturned two ratified
  conclusions on this feature already.
- You may run `busted tests` (expect 923 successes / 0 failures / 0 errors /
  3 pending) if a claim is easier to settle by test than by reading. Do not
  modify any test to do so.

## Deliverable

Write **`/repo/doc/development/wip/77-new-input-api/validation/outcomes/S27-triage-factcheck.md`**:

1. **Verdict summary** — one paragraph: is the triage safe to build on?
2. **Claim table** — claim / verdict / evidence (file:line + quote).
3. **Misfiled** — ids you believe are rated wrong, with the correct rating and
   why. Say how many W10 ids you sampled and how.
4. **Coverage and consistency** — the §C findings.
5. **Declines** — your read on each of the five, R080 first.
6. **Anything else that alarmed you.**

Be blunt. If a claim is wrong, say it is wrong; do not soften it into "could be
clarified". If you could not settle something, say so explicitly rather than
guessing — an honest "unresolved" is more useful than a confident error.
