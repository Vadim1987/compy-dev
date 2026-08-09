# session32 — report

**Commissioned:** recheck Decision 30 before anything is built on it, then replan.
Both halves done. **Decision 30 survives the recheck**; the plan is actualised against
it and ratified by the owner.

Suite **955 / 0 / 0 / 3** throughout. Five commits, all docs. Nothing pushed.
Two sub-agents, prompts and deliverables on disk.

## The recheck — the ruling stands, one of its paragraphs does not

Two cold checks, both with prompt of record and deliverable on disk:

- **Mechanical** (Sonnet) — `validation/outcomes/S32-decision30-evidence-bundle.md`
- **Judgement** (Fable) — `validation/reviews/S32-decision30-challenge-fable.md`

**Verdict: Decision 30 survives.** Its strongest leg is *not* the one it leads with:
the tracked set's two defects were **already documented in `technical_debt/input.md`
before Decision 30 existed**, so the core rationale is the generalisation of two
found-and-scheduled bugs rather than a fresh abstract argument. Its other legs — the
matcher being source-blind by construction, and the mandate never asking for the tracked
set — both hold in code.

**What did not survive, and it was carried into this session's own prompt as a
constraint:** Decision 30's *"Consequence — a prerequisite, not an option"* paragraph.
The premise is true (`mock.lua:30`'s `isDown` is single-argument, `Key.*` is variadic);
**the consequence is false.** No test can construct a state where left and right
modifiers differ — `mods` maps only to left variants, `keystroke` writes `held` only for
`mods` tokens, `held` is a module-local, no test installs its own keyboard `isDown` — so
a variadic mock **changes zero test results**. The single-arg `isDown` is also
**pre-existing and untouched by this branch**. The "must land FIRST" sequencing
constraint dissolved.

Every load-bearing claim from both agents was re-verified by me in code before use.
One of my own hypotheses (that the debt register's "retired polling idiom" entry would
invert under Decision 30) was **checked and found wrong** before it reached the plan —
that idiom is the `user_input()` poll-loop, not device polling.

## Two things nobody had drawn

- **P13's premise largely dissolves, in Decision 30's favour.** Harmony patches
  `love.keyboard.isDown`; the matcher now reads the device; so **harmony can drive the
  combo mechanism it previously could not**. Neither cold check found this. The owner
  reduced P13 to revalidation.
- **Rule 4 has no presence in the persistent corpus at all** — it exists only in the
  decision ledger, while `doc/input_api.md` §"Held keys" still teaches the superseded
  answer at length. The PR is meant to be reviewable from that document alone.

## Corrections the owner made to me — both improved the result

1. **The B→C→D collapse is a gated decision, not a fact.** I wrote that the S27 spinoff
   *is* the collapsed pass. It is not: we are still clearing TF2, and whether the parent's
   phases collapse is ruled **at the gate**, when TF2 closes. Corrected in `f42d0648`.
2. **Rule 4 is the mechanism, not a patch.** My "sharpest objection" — that Decision 30
   removed the only non-smell way to answer a held-state question in a hook — was
   substantially a strawman, corrected mid-flight to the running Fable agent. Its honest
   residual is narrower and survives: a flag-shortcut is filtered through the
   **modifier-sensitive** matcher, so `shortcuts.keypressed['a']` silently fails to fire
   when an unrelated modifier is held. Raw `keys_pressed['a']` tracked unconditionally.
3. **Project-owned flags are not the same bug scaled down.** `keys_pressed` was global,
   long-lived and read-only, so a project seeing a phantom had **no repair path at all**.
   This downgraded Fable's closing counter-argument.

## The plan — linked, not merged; then actualised

**`validation/plan.md` had not been written to since session22** (`583fdcd8`, 2026-07-29)
while ten sessions ran against it. Owner ruling: the release plan and the S27 spinoff sit
at **different altitudes** and are **linked, never merged**. Both now name each other;
the working discipline is *clear the sprint → close TF2 → rule on the collapse → F → U → G*.
**P12 promoted** out of the spinoff into the parent as **Phase U** — it was never a
remark, it is a release precondition.

`S27-triage-and-plan.md` gained **§11**: the item-by-item walk, every row dispositioned.
**P9d and P9e withdrawn** (P9e's premise *inverted* — gate polling is now correct).
**P8's nine remaining ids need a per-id check** that this session did not perform and did
not assume. New rows **P14a–P14e** in the owner's ordering — **docs → tests → platform
code → examples** — which deliberately reverses §4's "code first, docs third" rule,
coherently, because that rule assumed a moving code shape and the shape is now settled.

**Four owner rulings shaped P14:** the debt register **rides with the docs step** (debt
created by the spec is still debt); the **design fork gets its own step and is deferred**
until it actually blocks, so unblocked work clears first; **P13 reduced to revalidation**;
**rule 3's gate table is out of this PR and may never be built** — which exposed that
Decision 30 stated a commitment the owner does not hold, softened in place (`36de0eaa`).

## Where execution starts

**P9b** — the keyboard `textinput` heal. Unblocked, independent of everything Decision 30
touches, and the one functional blocker the owner ever named. Also unblocked: SM3a's
runtime check, the probe deletion, P8's per-id check, and all of P14a bar one internals
passage.

## Non-obvious points worth carrying

- The **design fork** (per-key device lookup vs routing through `Key.*`) is deferred, not
  settled. The two shapes need **different mock fixes**, and Decision 30's text names the
  one *not* recommended. Raising it early is friction; forgetting it is a silent wrong turn.
- `keys_pressed_spec.lua:98-138` **needs zero edits** under the dissolution — it drives
  the source-blind matcher. That is the cheapest available evidence that the ruling is
  cleanly implementable.
- The comment-bloat subset (~50 ids) inside W10's block of 92 is **never separately
  enumerated** and must be re-derived before P11.
- `internals/user_input.md` holds **10** `keys_pressed` occurrences, not the 12 quoted in
  three successive documents.
