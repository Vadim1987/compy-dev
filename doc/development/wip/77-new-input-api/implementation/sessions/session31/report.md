# session31 — report

**Commissioned:** evaluate session30's findings critically, then replan with the
owner. **Execution was explicitly not this session's mode.**

The replanning turned into further analysis — expected, and the owner named the
mechanism: *replanning is unblocked iteratively by eliminating uncertainty.* What
it produced is larger than a plan: **an owner ruling that reverses the feature's
central implementation decision.**

Suite **955 / 0 / 0 / 3** throughout. One commit (`9733d2d3`), docs only. Nothing
pushed. Two Fable consultations and one Opus census, all with prompts and
deliverables on disk.

## The ruling — Decision 30

`doc/development/decisions/input.md`, **superseding Decisions 13, 20 and 29** (all
three now carry `— SUPERSEDED` in their headings). **Decisions 8, 21, 26, 27 stand
unchanged** — only the *source* the combo matcher reads changes.

1. **Device polling is the single source of held-modifier truth.**
   `keys_pressed` is dissolved from all occurrences. It was an
   **implementation-time** decision, never a stakeholder requirement, and is
   reverted on that basis.
2. `Key.*` is **legitimate inside the shortcut matcher**.
3. `Key.*` **at a call site stays a smell**, replaced by shortcuts — for
   introspectability. One standing exception: the framework's gate for global
   power-like combos. **That exception is under-specified and needs a ruling.**
4. Where a shortcut does not fit: **a tiny shortcut sets a feature flag without
   consuming its event**; the hook runs heavy logic against flags, not hardware.

**Rationale:** a stateful model over an entity we do not control, which can
neither be prevented from drifting nor reconciled — and the only way to detect its
drift is to poll, which makes the device the authority and the tracked set a cache
of it.

**Withdrawn, not deferred:** P9d, P9e, P13, Q1, Q4, Q5 — all properties of the
tracked set.

## What made the ruling possible — the corrections

Six load-bearing claims fell this session. Each was verified in code, not inherited.

- **The polled gates are verbatim pre-existing** at `3256aac` (all 10 in
  `controller.lua`); `keys_pressed` does not exist at base. The polling problem is
  not this feature's.
- **Session30's census was mis-scoped** — 70 sites over 5 controllers, but 76 over
  `src/`. Its "zero frame-time keyboard polls, so Decision 29 clause 3 is
  theoretical" is overturned: `pong/strategy.lua:35` and `maze/main.lua:517` are
  frame-time, and `keyboard/input.lua:47` reads held state **from draw**.
- **`seed_hooks` does NOT mean "legacy examples keep working"** — my claim, refuted
  by the census. It preserves delivery, not ordering against the widget. Base was
  **either/or** (widget shown ⇒ project handler not called); HEAD runs the hook
  first, unconditionally. `turtle` and `maze` change behaviour today.
  **Reclassified after the owner supplied the motivating bug:** these are not
  regressions but the *intended effect* of Decision 1 — both examples were written
  against the modal-widget bug.
- **Event buffering is NOT code-verified in production.** The only `love.run` in
  `src/` is harmony's, dev-only. Production runs LÖVE's stock loop — upstream,
  unverifiable here. Session30's "code-verified" was overstated.
- **I over-read the mandate.** `requirements.md` FR-5/6/7 are scoped to the **edit
  area**; NFR-2's "polling" is the narrow sense (polling a reference for results).
  `keys_pressed` exposure was **never mandated**. FR-11/12 make console/editor
  deferral textbook-correct, not a concession.
- **`tests/mock.lua` already implements harmony's poll-fake** (`keystroke`, `:60-70`).
  So the codebase held **two** poll-shaped fakes predating the feature, and the
  tracked set was the only source of truth neither could drive.

## Evidence artifacts

- `validation/notes/S31-owner-attestation-where-we-are.md` — the owner's account of
  how the thread reached here, plus the modal-widget bug addendum.
- `validation/outcomes/S31-example-adoption-impact.md` — per-example census (Opus).
  Scorecard: positive keyboard/guess/repl/tixy; **overhead** paint/sapper/valid/
  balloons; **negative** turtle (+13 lines on a 58-line example); **do-not-adopt**
  pong. `life`/`paint` have no API equivalent.
- `validation/reviews/S31-boundary-challenge-fable.md` — additivity claim holds.
- `validation/reviews/S31-scope-reduction-fable.md` — Tier A/B split; `keyboard`
  uses the widget **nowhere**; its ordering machinery **predates** API adoption.

## Open, and the successor's business

- **Executing the dissolution.** `keys_pressed`: 22× `src/` (7 files),
  38× `tests/`, 15× decisions, 12× internals, 15× technical_debt, 8× `input_api.md`.
  **`tests/mock.lua`'s single-arg `isDown` must go variadic FIRST** — until it does,
  the suite cannot report truthfully on modifiers.
- **Rule 3's exception needs a precise list** of framework-gate combos.
- **Two must-fix regressions regardless:** `is_shown()` guards for `turtle` and
  `maze` (maze quits on Shift+Escape while its prompt is shown — student-facing).
- **`doc/input_api.md:268` is false** — claims a hook receives the held table as a
  second argument; `:390` and the code say nothing is added. Q3 is already
  no-change in code.
- **`compy.singleclick` retirement** fails silently for out-of-tree projects.
  Owner ruled it low priority: pure ergonomics, shim cheap, no known users.
- **Slices and PR description remain stale.** Regeneration stays last.
