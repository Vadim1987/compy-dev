# S36 — Does Decision 30 survive its corrected premise? (cold, session36)

**Verdict: YES, WITH QUALIFICATIONS.** Decision 30 stands. The corrected premise is real but
narrower than the challenge implies, and it argues for an *addition* (a device-backed
convenience proxy, already proposed and recorded — `doc/development/technical_debt/input.md`,
"PROPOSAL: `compy.input.keys`") rather than a *reversal*. Reversing now would also undo work
that has already fully landed — see "Cost of reversal," which is bigger than the commission's
framing suggests.

Suite baseline reproduced: `busted tests` → **942 successes / 0 failures / 0 errors / 10
pending** (matches expectation exactly).

---

## The corrected premise, checked directly

**"Nothing uses it" is false as a bare factual claim** — `src/examples/keyboard` read
`compy.input.keys_pressed` (11 call sites via its `INPUT` proxy, per S35's site enumeration)
and had built an equivalent-shaped mirror (`INPUT.held`) in its own `79260c5` before the
framework offered `keys_pressed` (platform commit `2a156025`, "M1 — keys_pressed table and
combo_string helper").

**But this was not new information to the decision.** `implementation/sessions/session31/track.md`
— the same session that ruled Decision 30 — is also the session that produced
`validation/outcomes/S31-example-adoption-impact.md`, the per-example census that documents
keyboard's dependency in detail and explicitly says (line ~646 of that file): *"[keyboard]
also justifies `keys_pressed` being readable outside an event, via `help.lua:11`'s
arbitrary-key read that `Key.*` cannot express."* The session's own informal verdict, recorded
in `track.md` before the wrap, names **"the keyboard example is the real casualty"** as a
named weak spot of the ruling. So the premise the owner is now asking me to re-test as
"unknown to the decision" was in fact on the table, in writing, at ruling time. What changed
between then and now is not the discovery of new evidence — it is emphasis: the owner is
asking whether that known cost was weighed correctly, not whether it was missed.

**Decision 30's own text does not claim "nothing uses it."** Rule 1 says the tracked set
"was never a requirement — no stakeholder requirement asks for it." That is a narrower,
different, and defensible claim: *usage* and *stakeholder requirement* are not the same
thing, and the decision never asserted the former. The commission's framing conflates them;
worth flagging as the one place the challenge itself overstates.

---

## The five claims, checked in code and git history (not accepted from the author)

All five checked against the keyboard example's own nested-repo history (`cd
src/examples/keyboard && git log`) and against the platform's history, not accepted from any
prior session's summary.

1. **TRUE.** `git grep -c keys_pressed 3256aac -- src/` → 0 hits, whole tree (re-confirmed;
   matches S32's finding). First platform occurrence: `2a156025` ("M1 — keys_pressed table
   and combo_string helper"), well inside this feature's own commit range.

2. **TRUE.** The keyboard repo's `79260c5` ("Initial implementation of the new arch",
   2026-06-08) already contains a full `INPUT.held` mirror updated in `appKeypressed`/
   `appKeyreleased`, with no reference to `compy` anywhere. `4814407` ("feat: run on the Compy
   input API instead of hand-rolling it", 2026-08-03) is the migration onto
   `compy.input.keys_pressed` — its own commit message: *"No more mirror. INPUT.held/shift/
   ctrl/alt were maintained on every press and release; INPUT is now a proxy reading the
   framework's held set live."* Per S31, this adoption was **voluntary** — the pre-adoption
   `love.keypressed`/`keyreleased`/`textinput` handlers seed into the framework's hook chain
   unmodified, so nothing forced the migration.

3. **TRUE, and this is the load-bearing discovery of this review.** `79260c5:input.lua`'s own
   header: *"repeats are filtered here by edge tracking: a key already in INPUT.held is a
   repeat and is ignored completely"*, and `appKeypressed` literally opens `if INPUT.held[k]
   then return end`. The inference **did** make the Alt-keys scene deaf on the device: commit
   `3a9d48c` ("fix(alt): accept the first glyph of a press, whatever order it arrives in",
   2026-08-07) fixes exactly this, with its own commit message stating the mechanism: *"desktop
   LOVE sends the keypress before the glyph, so a key is always held at its own first
   textinput. Every fresh target was thrown away as a repeat."* **The fix that resolved this
   bug did NOT reach for held-state at all, from any source** — mirror, framework-tracked set,
   or device poll would all have suffered the identical ordering ambiguity. The fix introduced
   `spendGlyph`/`GLYPH_CLAIMED`, a project-owned explicit per-key claim flag, cleared on keyup,
   decoupled from "is it held" entirely. This is direct evidence that held-state *inference*
   was the wrong tool for this job regardless of which surface backs it — not evidence that a
   framework-tracked held set specifically was needed.

4. **TRUE**, verified against the actual post-dissolution migration, not just against current
   reads. `05cedec` ("fix(input): the framework tracks no held keys; ask the keyboard",
   2026-08-10) is the keyboard repo's own migration off `compy.input.keys_pressed` onto
   `Key.*`/`love.keyboard.isDown`, and it is HEAD of that nested repo today — the dissolution
   is **fully executed**, not hypothetical. Every one of the eleven surviving reads converts
   cleanly: `INPUT.shift/ctrl/alt` → `Key.shift()/ctrl()/alt()` (modifier folds, feeding the
   reserved-chord shortcuts and the key-cap renderer's draw-time reads); Caps reconciliation
   reads `INPUT.shift`, same path; `help.lua`'s `helpHeld()` — the one non-modifier read
   (`INPUT.held.h`) — becomes a direct `love.keyboard.isDown("h")`, called from a function that
   gates a **held overlay drawn every frame** (decoration/draw-time, the carve-out Decision 30
   rule 2/3 explicitly grants). No crash, no behavioural loss reported in the migration commit;
   the commit message states the check performed ("loading both files against a fake device:
   each l/r pair folds, Ctrl+Alt+H is not Alt+H, and neither modHeld nor INPUT.held survives").

5. **TRUE**, and independently corroborated by the owner's own later proposal doc
   (`technical_debt/input.md`, "PROPOSAL: compy.input.keys", commit `226a973a`, 2026-08-10):
   it lists "an enumerator — list every key currently held" as the *one* capability a device
   poll cannot provide, names it explicitly as an **optional, later** extension, and states
   nothing currently needs it. No example, including keyboard post-migration, calls for
   enumeration anywhere.

---

## The need the example was actually reaching for

Not a framework-tracked, event-sourced set. Two distinct needs got fused in the example's
history and need separating, exactly as Decision 30's own "why the combo mechanism survives"
paragraph separates dispatch from state-source:

- **Repeat/edge detection** (the *original*, `79260c5`-era reason `INPUT.held` existed at
  all) — this need is real, but held-state inference (from any source) is structurally the
  wrong tool for it, proven by the codebase's own bug-and-fix (`3a9d48c`). The right tool is
  LÖVE's `isrepeat` flag for `keypressed` (which Decision 9/30 already deliver as the hook's
  third argument) and an explicit per-key claim for `textinput`, which carries no such flag
  and never will regardless of what backs held-state. This part of the convergence argument
  does not support reinstating `keys_pressed` — it was never the right fix even when
  `keys_pressed` existed (the example used its *own* mirror for this from day one, migrated to
  `compy.input.keys_pressed` in `4814407`, and the ordering bug was present and unfixed the
  whole time `keys_pressed` was available to fix it with — it wasn't).
- **A convenience surface for "is this key held," foldable and readable outside an event** —
  this is the real, still-standing need, evidenced by convergence (keyboard built the shape
  twice; maze wrote its own `is_shift_down()`; turtle/clock/sapper spell out `Key.*` /
  `love.keyboard.isDown` at call sites — all independently confirmed in `S31-example-adoption-
  impact.md` and now in `technical_debt/input.md`'s proposal entry). But the *backing store*
  this need requires is unconstrained by the evidence — every one of those call sites is
  satisfied today by a stateless device poll, folded through `Key.*`. Nothing in the keyboard
  example's post-dissolution code (`05cedec`) needed history; it needed **now**. The proposal
  already on disk (`compy.input.keys`, `226a973a`) answers exactly this shape without
  reinstating a tracked model, and explicitly frames itself as compatible with, not a reversal
  of, Decision 30: *"Decision 30 removed a model kept beside the device; this proposal removes
  the need to ever expose which one is in use."*

So the "convergence" the owner reads as a symptom is real, but it is a symptom of a missing
**ergonomic sugar layer**, not a missing **tracked model**. The decision that dissolved the
tracked model survives; a separate, smaller, additive proposal is the correct response to the
convergence evidence, and it is already written down.

---

## Weighing the items the commission calls out explicitly

- **The reversed two-clocks argument (Decision 29 vs 30).** Checked against `src/harmony`:
  `patch_isDown` (`src/harmony/init.lua:242-254`) monkey-patches `love.keyboard.isDown` itself
  to consult its own fake `held` table before falling through to the real device, and
  `love_key` pushes real LÖVE key events too — so Harmony drives both the poll and the event
  stream consistently under Decision 30's device-truth model, exactly as it did under
  Decision 29's event-tracked model. No skew found; the reversal does not visibly cost
  anything in `harmony`. The batch-skew risk Decision 30 accepts is real but is stated as
  **unmeasured**, symmetric with the staleness risk it replaces (also unmeasured) — this
  review did not find a way to measure either from static analysis, and says so rather than
  picking a side without data.
- **Staleness (the withdrawn P9d).** The focus-loss staleness bug applied to the framework's
  tracked set specifically (`Controller.keys_pressed`, no clear on focus loss,
  `controller.lua:731` `SKIPPED` focus channel, confirmed unchanged in the current tree). Device
  polling cannot go stale in the same sense — `love.keyboard.isDown` always answers from the
  live device — so this consequence is a genuine, structural win for Decision 30's shape, not
  merely a bug that got worked around; it is a bug that stopped being possible.
- **Cost of reversal — bigger than the commission's "~16 commits" framing.** Recent `git log`
  shows the dissolution is **already fully executed**, not partway: `b0130412` ("the matcher
  asks the keyboard, not the tracked set"), `91fbf07e` ("the gateway stops keeping a held-key
  set"), `9cb5b636` ("the held-key surface is gone, seam and all"), plus example conversions
  (`5c3ca84b` turtle/clock, `cc434f9b` sapper) and the keyboard nested repo's own `05cedec`.
  `grep -rln "keys_pressed" src/ tests/` returns **zero files** at HEAD. Reversing now means:
  re-adding `Controller.keys_pressed`, its writers on every keypress/keyrelease, the memoised
  `held_keys()` proxy machinery, the sandbox field plumbing, re-migrating `combo_string`/
  `any_mod`'s signature back, restoring ~38 deleted/rewritten test assertions across three
  spec files, and re-migrating `src/examples/keyboard` (and partially turtle/clock/sapper) back
  onto a tracked-set shape — undoing real, reviewed, green work across the platform repo and a
  nested example repo with its own independent history. This is categorically larger than "16
  commits depend on the answer"; the dependent work already merged the answer into the tree.

---

## What is genuinely lost, and who notices

- **Enumeration** ("list every currently-held key") — nothing in the platform or any example
  needs this today (claim 5, confirmed). Noticed by: nobody currently; a future project doing
  something like a piano-roll or multi-key gesture recognizer might.
- **A syntactic convenience** — before the dissolution, `compy.input.keys_pressed['x']` was a
  ready-made project-facing surface; today the same question is `Key.x_fold()` for modifiers or
  a raw `love.keyboard.isDown('x')` for anything else, both fine but slightly more code at each
  call site, and not centrally documented as a single idiom. This is exactly the gap the
  `compy.input.keys` proposal (`226a973a`) targets. Noticed by: every input-heavy project
  author, mildly, which is the convergence evidence itself.
- **A single centralized fix point for focus-loss-style staleness** — moot for the device-poll
  design (nothing to go stale), but the *pattern* Decision 30's own rule 4 recommends
  (a project-maintained flag-shortcut) reintroduces a small-scale version of the same staleness
  class, per-project rather than framework-wide (already flagged in
  `validation/reviews/S32-decision30-challenge-fable.md`, A3, which this review independently
  corroborates rather than re-derives). Noticed by: a project author who builds the rule-4 flag
  pattern and never wires a focus-loss clear for it — a narrow, optional-to-hit case.

## What I could not determine

- **Batch-skew frequency in practice.** Neither this review nor any prior session measured how
  often two key events land in one LÖVE frame under real play; the comparison against the
  staleness bug it replaces remains an argument, not data, on both sides.
- **Whether `compy.input.keys` (the pending proposal) will ship as designed.** It is recorded
  as "not this release" and carries three open design questions (name-space collision, silent
  nil, property-vs-call) that are unresolved as of this review. Its existence is what makes
  "Decision 30 survives" the right verdict rather than "the convergence evidence is being
  ignored" — but if the proposal is later dropped without another resolution, the convergence
  evidence would then be sitting unanswered, which a future reviewer should re-check.
- **Whether every one of turtle/clock/sapper's post-dissolution reads is optimal style** (some
  are flagged in `technical_debt/input.md`, "Examples are not onboarded," as "a rung below the
  one the API offers") — out of scope for this question (that's an onboarding-quality question,
  not a does-Decision-30-survive question), noted only so it isn't mistaken for a Decision 30
  defect.
