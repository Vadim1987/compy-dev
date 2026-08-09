# S32 — map of the release plan and its TF2 spinoff

Produced session32 (2026-08-09) at the owner's request, after the two plans were
cross-linked (`541e10b1`, corrected by `f42d0648`). **Not a new plan** — a read of the
two existing ones: [`../plan.md`](../plan.md) (parent, ends in release) and
[`../reviews/S27-triage-and-plan.md`](../reviews/S27-triage-and-plan.md) (spinoff,
P0–P13).

Status vocabulary: **DONE** · **PART DONE** · **OPEN** (in flight) · **NOT STARTED** ·
**GATED** (blocked on a named gate) · **PROMOTED** (moved altitude) · **WITHDRAWN?**
(claimed dissolved by Decision 30, to be confirmed item-by-item in this session's Part 2).

---

- **Phase A — Mechanical integrity** · DONE
  - **A1** — spec-reference sweep: comments cite the persistent docs corpus with named
    sections, not `wip/` drafts · DONE (`outcomes/A1-spec-ref-sweep.md`)
  - **A2** — test-fidelity audit + fixes; the S7 precondition · DONE
    (`outcomes/A2-test-fidelity.md`)
- **Phase DI — Doc integrity: "doc A" disposition** · DONE
  - **DI1** — doc-A fidelity audit, per-section verdict table · DONE
    (`outcomes/DI1-docA-fidelity.md`, `DI1-a-evidence.md`, `DI1-b-evidence.md`)
  - **DI2** — owner ruling on promotion form (promote / merge / no-promotion) · DONE
  - **DI3** — execute the ruling; retarget the doc-A citation family · DONE
    (`outcomes/DI3-execution.md`)
- **Phase TF — Test-fidelity deepening, owner in the loop** · **OPEN — this is where we are**
  - **TF1** — split `tests/input/input_contracts_spec.lua` into human-reviewable files ·
    DONE (`outcomes/S15-TF1-split-execution.md`)
  - **TF2** — owner human review of the split suite (owner-gated, interactive) · **OPEN**
    - **C1 pre-gate** — documentation authority/provenance sweep before opening TF2 · DONE
      (`outcomes/S22-terra-C1-authority-sweep.md`)
    - **RAN** — session24 take-01 triage (`reviews/S24-TF2-take01-triage.md`); owner smoke
      test session26 (`reviews/S26-TF2-smoketest-results.txt`)
    - **Output: 187 remarks** — far past the near-empty bucket TF3 predicted
    - **→ SPINOFF SPRINT (below).** TF2 closes when the spinoff closes.
  - **TF3** — evaluate hints + triage · **absorbed by the spinoff**, not run under this name
- **Phase R — Redesign (inserted between TF and B)** · **CLOSED and accepted** (session18,
  owner, commit `affc932`)
  - **R1/R2** — delta-design + delta-spec · DONE (Fable, session16)
  - **R3** — owner confirm-gate · DONE
  - **R4** — tests-first execution, 8 ordered units (tier-1 removal → submit/cancel flip →
    `hooks[event]` unification → `callbacks` membership → console patch → rename sweep →
    docs) · DONE
  - **R5** — dispatch + widget-method-surface extraction · DONE
  - *Gate met by grep, not LSP — `lua-lsp` returned phantom refs all session.*

---

## ↳ SPINOFF SPRINT — `reviews/S27-triage-and-plan.md` (child of TF2)

187 remarks → 12 workstreams → the P0–P13 execution spine. **Ordering rule: code first,
tests second, docs third, comments last.**

- **P0** — answer the S0s; verify R044/R068/R033/R171 against `3256aac`; reproduce
  SM1/SM3/SM4/SM5 · DONE (`notes/S27-P0-evidence.md`)
- **P1** — owner rulings gating everything: W2, W5, W6, W1's Decision 9 · DONE
  - **W6** — "is the widget a special chain tier?" · **dispositioned here as NOT DOING**
    (R080 declined, with reasons — §3)
- **P2** — **W1** signature unification: drop `keys_pressed` from the hook/shortcut payload ·
  DONE (`c4f5a92f`, corrected `a1952721`) — the one silent breakage,
  `examples/keyboard/input.lua:142`, named by line
- **P3** — **W3** click events become first-class; one event list, generic seeding and wipe ·
  DONE (`069b93e9`)
- **P4** — **W2** pointer shortcut tier, modifier-only combos + `mouse2` as trigger · DONE
  (`5d144f37`, extended `1a414dbb`) → Decision 27
- **P5** — **W5** `before_submit` veto + callback defaults · DONE (`15679f9d`)
- **P6** — **W4** dispatch/wiring collapse, one dispatch and one wiring loop · DONE
  (`bb6569a2`)
- **P7** — **W7** `consoleController`/`userInputController` structure + the 16-line rule ·
  DONE (`99f883d0`…`75c0d9ea`)
- **P7b** — teardown ownership, `framework_before_exit` · DONE (`ab2d45eb`) → Decision 28
- **P8** — **W8** test-suite restructuring · **PART DONE**
  - done: R058/R059/R060/R061 (tracer + matrix supersession), R067, R068, R070
  - **left: R057, R074, R078, R079, R047, R063, R064, R069, R075**
  - gate: do not restructure tests before the code stops moving
- **P9** — **W11** examples and the three nested repos, one commit per repo · **PART DONE**
  - SM1/SM2 ruled no-change · SM3b explained · SM4 pinned by a suite row · SM5 fixed
    (`3a9d48c`) · **SM3a open, needs one runtime check** (`notes/S28-smoke-findings.md`)
  - gate: nested repos carry **no automated tests** — committing is not verification; a
    smoke re-pass is the gate. Never pushed.
- **P9b** — **keyboard: judgement decoupled from delivery order** · **NEXT TO EXECUTE —
  the one functional blocker the owner ever named.** `textinput` becomes the only judge;
  two fields (`lastText`, `blocked`); subtracts `spendGlyph`, `GLYPH_CLAIMED`,
  `upRecent`, `INPUT_UP_GRACE`. Design of record:
  `doc/development/internals/examples/keyboard.md`. **Decision 30 does not touch this.**
- **P9c** — the two order-dependent test cases this branch owns (fail under `--shuffle`) ·
  OPEN, before the PR. Suite-wide order dependence is pre-existing and explicitly out of
  scope.
- **P9d** — clear `keys_pressed` on focus loss · **WITHDRAWN?** — a property of the tracked
  set; Decision 30 dissolves the set
- **P9e** — the gateway's own gates read the event set, not the device · **WITHDRAWN?** —
  Decision 30 **inverts its premise**: polling at the gate is now correct, not a violation
- **P10** — **W9** doc structure + decision ledger, and **W10** batches 1, 2, 4 (retire
  "overlay" ~17; no-historical-contrast ~10; vocabulary) · NOT STARTED
  - **hard constraint: tombstone decisions, never renumber** — 179 comments cite decisions
    by number (69 in `src/`, 110 in `tests/`)
- **P11** — **W12** comment sweep against `agents/rules/commenting.md`, then slices, then
  cold revalidation ×2 · NOT STARTED
  - carries **W10 batch 3 — comment bloat (~50 remarks)**, step (e) of the commission,
    deliberately last so comments are cut after the code stops moving
  - gate: `grep -rn 'INTERIM:\|REMARK:' src/ tests/` must return **nothing** — currently
    **22** in the platform + **5** in `src/examples/`
  - **known gap:** Appendix A enumerates W10 as one block of 92 ids; the ~50 comment-bloat
    subset is **never separately listed**, so the subset has to be re-derived first
- ~~**P12**~~ — upstream reconciliation · **PROMOTED** to the parent as **Phase U**
- **P13** — harmony reconciliation (second implementation of the input surface: own
  `love.run`, own held table, patched `isDown`) · **OPEN QUESTION** — was coupled to P9e;
  if P9e's premise is gone, does P13 follow P12 up, survive here, or dissolve? Not settled
  by the P12 promotion.

**Workstreams with no P row of their own:** W6 (declined at P1). All others are carried by
the P rows above.

---

## ↰ back to the parent, after TF2 closes

- **THE GATE — rule on the B→C→D collapse** · **PENDING.** Proposed in
  `notes/post-R-replan-hypothesis.md`, gated on TF2/TF3 by
  `reviews/S18-post-R-replan-reconciliation.md`. Likely finding: B, C and D are already
  satisfied by the cleanup the spinoff performed — **in which case these parent phases
  collapse.** A ruling, not a foregone conclusion.
  - **Phase B** — convergence check vs `design/` and stakeholder intent; three buckets
    (satisfied / deviated / scaffolding-suspect) · NOT STARTED, GATED ·
    `reviews/convergence-check.md` does not exist
  - **Phase C** — **C1** principle sheet (≲8 owner questions) + **C2** disposition table
    (every Pass-2 row → principle → action) · NOT STARTED, GATED · neither file exists
  - **Phase D** — owner ruling sitting, one principle at a time, batch approval prohibited ·
    NOT STARTED, GATED
  - **Phase E** — execution of the dispositioned actions, incl. the
    `internals/user_input.md` rewrite (the doc stakeholders are pointed at from the PR) ·
    NOT STARTED
- **Phase F** — final revalidation against stakeholder intent **and** the meta-requirements
  (clarity, stability, robustness, minimalism); anything failed goes back to D as a named
  question · NOT STARTED · `reviews/final-revalidation.md` does not exist
- **Phase U** — upstream reconciliation and downstream compatibility (promoted from P12,
  2026-08-09) · NOT STARTED · **blocks the real PR, needs its own plan**
  - platform repo, possibly an advanced fork of it
  - the three nested example repos — `balloons`, `maze`, `keyboard`, each its own remote
    and its own PR
  - not attempted before the snapshots are stable
- **Phase G — PR assembly** · NOT STARTED · per `implementation/pr-assembly-guide.md`
  - **slice regeneration LAST**, after the tree settles; Set 4 to be cut as
    `4a-balloons` / `4b-maze` / `4c-keyboard`
  - PR description: intent → design → ratified deviations → justification table → open
    questions
  - reviewability gate: reviewable from `doc/input_api.md` + the PR description **alone**
  - `wip/77` deletion: owner-gated, after the PR is up

---

## Not yet placed anywhere — session32's Part 2 business

Work that Decision 30 creates or that the current prompt names, with **no id in either
plan**:

- **`tests/mock.lua`'s single-arg `isDown` → variadic** — must land FIRST, own commit, own
  breaking test; until then no suite result about modifiers is trustworthy
- **The dissolution itself** — `keys_pressed` removed from production, tests and docs
- **Two must-fix `is_shown()` guards** — `turtle` and `maze`; **maze quits on Shift+Escape
  while its prompt is shown, and maze is student-facing**
- **`doc/input_api.md:268` is false** — claims a hook receives the held table as a second
  argument; `:390` and the code disagree
- **Rule 3's gate: name the layer and give it a shortcuts table** — owner to rule whether
  it lands in this PR
- **Sort `keyboard`'s polls** into decoration/drawing (stays, legitimate) vs judgement
  (converts to combos)
