# session32 — track

## 2026-08-09 — boot

- Booted per `agents/validation.md` → `agents/sessions.md`. **Fresh start**:
  session32 held only `prompt.md`; no `track.md` / `report.md` (sessions §2 row 1).
- HEAD `a83a77f3` "docs(input): correct Decision 30 rule 3 — the gate is a layer,
  not an exempt list", branch `feature/77-newapi-analysis-s20260615`. Working tree:
  only the known untracked scratch (`claude.sh`, `src/STEPS.md`,
  `input-pr-slices.tar.gz`, `doc/tall_blocks.md`,
  `doc/development/wip/{clarification,personal-notes,pull-26}/`) plus the three
  nested example repos (`src/examples/{balloons,keyboard,maze}`). **No tracked
  modifications.**
- **Baseline confirmed: `busted tests` → 955 / 0 / 0 / 3.** Matches the prompt.
- Read in full: `agents/validation.md`, `agents/sessions.md`,
  `agents/rules/revalidation.md`, this prompt, session31's `report.md` +
  `prompt.md` + `track.md`.
- Note: session31's track records **four owner corrections applied post-wrap** to
  this prompt and to Decision 30 (commit `a83a77f3`) — the booted prompt already
  carries them. Immutable from now on.
- Mode declared before starting: **Part 1 = research/revalidation** (recheck the
  ruling), **Part 2 = evaluation + replanning**. Execution is *not* commissioned;
  the dissolution itself is a later session's mode unless the owner rules
  otherwise. Boundary to watch: the mock.lua variadic fix and the two `is_shown()`
  guards are execution work sitting inside a replanning session.
- Task as understood, stated to the owner before proceeding — see the four points
  reported in chat (recheck Decision 30's rationale; the `mock.lua:30` single-arg
  `isDown` caveat; Rule 3's gate-as-a-layer; "pre-existing" against `3256aac`;
  then item-by-item walk of `S27-triage-and-plan.md` §4 and a replan proposal for
  the owner's ruling). **Rulings are the owner's; none are mine.**

## 2026-08-09 — owner reframes: the replan must land inside the release plan

- Owner's adjustment (no part of the boot statement disproved): the whole
  `keys_pressed` affair started as **fixing glitches in the keyboard example** and
  questioning its input handling, inside a **bigger pre-release plan** — example
  regressions, smoke testing, prose readability, PR slice reassembly. The planning
  half of this session must be **part of that plan, which ends in release**, so the
  trajectory is not lost.
- **Found it:** `validation/plan.md` — the validation→release plan (A → DI → TF → R
  → B → C → D → E → F → G), produced session10 (Fable) from the owner's
  `plan_notes.txt`. Ends at **Phase G, PR assembly**.
- **Last written by session22**, commit `583fdcd8` (2026-07-29 22:49), "gate TF2 on
  authority sweep". **Frozen for ten sessions.** Its live position still read "TF2
  pending"; baseline still 854/0/0/4.
- **The gap, verified:** TF2 actually ran (S24 take-01 triage, S26 owner smoke
  test); Phase B/C/D's named artifacts (`convergence-check.md`,
  `principle-sheet.md`, `disposition-table.md`) never existed; P12/P13 exist only in
  the child; `S27-triage-and-plan.md` §4 (P0–P13) has been the operative plan since
  session27 with nothing recording the substitution.
- **Owner's recollection confirmed and sharpened** — the B/C/D collapse was proposed
  in `notes/post-R-replan-hypothesis.md` and gated on TF2/TF3 by
  `reviews/S18-post-R-replan-reconciliation.md:44`. TF2's bucket came back at **187
  remarks** instead of near-empty. So **the S27 sprint IS that collapse**, executed
  at workstream altitude — the spinoff is the plan working, not drifting.
- **OWNER RULING (2026-08-09):** different altitudes → **link, do not merge**. Mark
  the spinoff in the parent at TF2, mark the parent in the spinoff, clear the
  spinoff, return to the parent when done. **Upstream reconciliation belongs in the
  bigger plan.**
- Executed as commit `541e10b1` (docs only, suite untouched at 955/0/0/3): parent
  status block + TF2 marked RAN/SPUN OFF; child gains §0 naming its parent and the
  return path; **P12 promoted to the parent as Phase U**, inserted between F and G
  (named, not lettered — B–G labels are load-bearing across frozen prompts).
  **P13 deliberately left open** — it was coupled to P9e, whose premise Decision 30
  affects; that disposition is Part 2's business, not a side effect of the promotion.
- Mode note: this is a small execution unit inside a replanning session. Bounded and
  owner-ruled, so the boundary is not crossed at scale — recorded so the successor
  can judge for itself.

## 2026-08-09 — cold check 1 spawned (mechanical, Sonnet, explicit model)

Prompt of record: `../../../validation/prompts/S32-decision30-evidence-bundle.md`;
deliverable `../../../validation/outcomes/S32-decision30-evidence-bundle.md`.
Read-only, four tasks: (1) `tests/mock.lua:30` single-arg `isDown` vs variadic
`Key.*` **and its blast radius over the suite's modifier assertions**; (2) the
pre-dispatch **gate layer** in `controller.lua` — full enumeration of its
combinations and polls, and verification of the "no shortcuts table exists at that
position" mechanism claim; (3) **pre-existing checks against `3256aac`** for every
claim Decision 30 leans on; (4) re-count the dissolution surface. Ordered first
because the judgement half of Part 1 — does Decision 30 still read honestly —
cannot be answered while it is unknown whether the suite can speak about modifiers
at all.

## 2026-08-09 — check 1 returns; the FIRST-ness of the mock fix is REFUTED

Deliverable: `../../../validation/outcomes/S32-decision30-evidence-bundle.md`
(Sonnet, read-only, suite re-observed 955/0/0/3, no file touched but its own).
**Load-bearing claims re-verified by me in code, not taken at face value.**

**1. `mock.lua:30` single-arg `isDown`: claim TRUE, consequence FALSE.**
Literally true and uniform across all three accessors (`key.lua:141/151/161`,
each `isDown(unpack(<pair>))` with the left variant first). **But the suite
cannot reach a state where left and right differ**, so the variadic form is
*extensionally equal* to today's over every state any test can construct:
- `mods` (`mock.lua:17-21`) maps only `C→lctrl`, `S→lshift`, `M→lalt`.
- `keystroke` (`:59-73`) writes `held[m]` **only** for `mods` tokens; any other
  token is dispatched as a keypress and **never** written to `held` — so
  `mock.keystroke('rctrl')` goes to the event stream, not the poll table.
- `held` is a module-local (`:5-15`); exports are `mock_love`, `keystroke`,
  `textinput`, `release_keys` only (`:92-97`). No test installs its own keyboard
  `isDown` (`input_fixture.lua:56` is `love.mouse`).
- Every `rctrl/rshift/ralt` mention in `tests/` is Population B
  (`keys_pressed_spec.lua:116` builds a **local** `{rctrl=true}` for
  `combo_string`; `input_nfr_mechanism_spec.lua:108` uses `F.session.press`).
→ **Making it variadic changes ZERO test results.** All four checks re-run by me.

**2. And it is PRE-EXISTING** — `git diff 3256aac -- tests/mock.lua` does not
touch `held`, `mods`, `release_keys` or the `isDown` line. Never edited on this
branch.

**→ The sequencing constraint dissolves.** Session31's "must land FIRST or every
later modifier result is unreliable", carried into my prompt, **does not hold**.
Nothing about the dissolution needs to wait for it. Two further consequences I
draw (owner's to rule):
- **It is not a 1-line fix.** A breaking test needs a right-hand modifier, which
  the mock's API cannot express — so the unit is `mods`-table/API surface **plus**
  the variadic body **plus** the test. Bigger than advertised.
- **Its value is prospective, not retrospective.** Decision 30 moves combo truth
  to the poll, so combo tests must migrate Population B → Population A. The
  left-only limitation starts to matter *after* the dissolution, exactly where
  combos get tested. Argues for doing it — but as part of the dissolution, not
  ahead of it. `harmony/init.lua:243-253` already carries a correct variadic
  pattern to copy.

**3. Gate confirmed as characterised** — `controller.lua:787-915`, **12
combinations** (11 keypressed + Ctrl+Escape on keyreleased `:907-910`), **11
`Key.*` call instances**, zero raw `isDown`, **no shortcuts table**; nearest is
`projectInputController.lua:132`, reached only via `love.keypressed(...)` at
`:894-896`. LSP-traced chain, grep-backstopped.
- **Boundary finding the ruling's wording does not cover:** `set_love_keypressed`
  (`:514`, `:531` — debug toggles, termdebug) holds two more `Key.*` reads but is
  **downstream** — it is one of the things dispatch dispatches *to* (the console's
  own route). Rule 3 says the exception is "upstream of route dispatch", so these
  two are **ordinary call-site smells, not gate members**. Needs an owner call.

**4. `error_explorer.lua:418` is PRE-EXISTING at base** (verbatim). Session31 sold
it as "the real gap, one line, closes the whole centralization guarantee". By the
same pre-existing logic that removed the polled gates from this feature's scope,
it is arguably out of scope too. Owner's call; flagged, not decided.

**5. NEW ITEM nobody has drawn.** `src/probe/input_probe.lua:1-2` says of itself:
*"DIAGNOSTIC, TEMPORARY. Delete when the polling-vs-tracking question is ruled
on."* **Decision 30 ruled it.** The probe is now deletable by its own terms —
and it is one of the three modifier-poll sites outside the seam. Verified the
header myself. Not in any plan; goes to Part 2.

**6. Counts.** `src/` 22/7 files and `tests/` 38 exact; `technical_debt/` 15 and
`input_api.md` 8 exact. **`internals/user_input.md` is 10, not the claimed 12** —
verified myself; the claim is simply wrong. `decisions/input.md` is 17, not 15,
fully explained: Decision 30's own prose added 2 after the snapshot.

## 2026-08-09 — owner directs the conceptual check; Fable spawned (explicit model)

Owner: check whether Decision 30 was right **conceptually**, not only against codebase
stats; and **if Fable comes out supporting it, ask for implementation recommendations
too**. Then decide next step — *"likely we will actualize spinoff plan."* So Part 2's
item-by-item walk is queued behind this, by owner sequencing.

Prompt of record: `../../../validation/prompts/S32-decision30-challenge-fable.md`;
deliverable `../../../validation/reviews/S32-decision30-challenge-fable.md`. Framed as
an **attack**, two questions, (2) conditional on (1).

**What I put in the brief, deliberately:**
- Decision 30 verbatim + all four rules + the core rationale.
- **The refutation of Decision 30's own "prerequisite, not an option" paragraph** — the
  decision as written overstates the mock fix as a blocker. Fable must factor in that a
  paragraph of the object under review is already known wrong.
- **The sharpest objection I can construct**, posed as a hypothesis to test, not asserted:
  Decision 30 may have **removed the only non-smell way to answer a held-state question
  inside a project hook**. The owner themselves killed the earlier "cut" proposal with
  *"without exposing `keys_pressed`, how does a project branch inside a hook?"*; the
  documented answer was `keys_pressed` (`input_api.md:372/390`). Decision 30 now answers
  it with `Key.*` — which its **own rule 3 calls a smell at a call site** — offering
  rule 4's flag-shortcut as the escape. Plus the **asymmetry**: the gate may poll and is
  told to build a table; projects are told polling is a smell and now have nothing else.
  Counterweighted with the owner's decoration-vs-judgement rule, which may dissolve part
  of it.
- **Counterweights on both sides at full strength**, so the deck is not stacked: for —
  reconcile-requires-polling, the non-self-healing phantom, dispatch value being separable,
  neither pre-existing fake could drive the set. Against — two unmeasured frequency claims
  pointing opposite ways, the suite going quieter, the source-agnostic proxy meaning
  shipping either way commits little, ~30 sessions of cost, keyboard's shrinking saving.
- The **stakeholder mandate as owner-confirmed** (FR-5/6/7 edit-area-scoped, NFR-2 narrow,
  FR-6 does mandate Ctrl-combo notification, FR-11/12 expressiveness targets) — judge
  against that, not an idealised architecture.
- The red-flag checklist, each item requiring a stated judgement.
- Question 2's concrete asks: ordering, the test migration (two disjoint ways to say "ctrl
  is held" that disagree), the gate's own table, the probe's self-declared deletion, the
  pre-existing `error_explorer` bypass, and what the PR description must say.
- Required closer: **the strongest argument against its own conclusion** — that section
  changed the owner's course in both prior Fable consultations.

## 2026-08-09 — owner corrects MY objection; a real doc defect falls out of it

**Owner's correction, and they are right.** I framed rule 4 as an escape from a hole
rule 3 opens. **Rule 4 is the mechanism, not a patch.** A tiny non-consuming shortcut
sets a **feature flag**; the hook runs its logic against flags. The point is
**decoupling project logic from hardware polls entirely** — under Decision 30 hardware
state reaches the system **only** through the combo string the matcher builds (rule 2).
So there is no forced-to-poll gap and no gate-vs-project asymmetry of the kind I
described. My "sharpest objection" was largely a strawman.

**Owner's conditional — "if this recommendation is not part of the decision, it was
documented improperly" — answered:** it **is** part of the decision and correctly stated
there, `decisions/input.md:1249-1253`, as "the recommended shape". The decision ledger is
fine.

**But the defect exists one level out, and it is worse where it lands.** Verified by
grep: the flag pattern appears **nowhere** in the persistent corpus — not in
`doc/input_api.md`, not in `internals/user_input.md`. Only those three decision lines.
Meanwhile `doc/input_api.md` §"Held keys" (`:365-395`) **still teaches the superseded
answer at length**: "The held set below is for what a combo cannot express", a worked
`love.draw` keycap example, and "a handler that wants held state reads
`compy.input.keys_pressed` the same way a `love.draw` does". **The PR is meant to be
reviewable from `doc/input_api.md` + the description alone**, so this is the copy that
matters. The section needs **replacing** with combo-first / flag-shortcut teaching, not
merely purging of `keys_pressed` mentions. → unplaced-items list, P10-class.

**Correction sent to the running Fable agent** so it does not spend its strength on the
strawman: told it the objection is substantially answered, invited it to test only the
*residual* honest form (is a flag set on `keypressed` / cleared on `keyreleased` itself a
small project-side tracked set, reintroducing at project scope the drift the decision
rejects at framework scope? can a modifier-only keyboard trigger even carry such a
shortcut?) — **in code, not by assumption** — and handed it the doc defect as a known
input for question 2.

## 2026-08-09 — Fable returns: Decision 30 SURVIVES. Three claims re-verified by me

Deliverable: `../../../validation/reviews/S32-decision30-challenge-fable.md`.

**Verdict: survives.** Rests on three legs, strongest first:
1. **The tracked set was already failing, and the failure was already documented** —
   `technical_debt/input.md` recorded both "the gateway asks the device a question about
   an event" (two clocks) and "the held-key set is never cleared on focus loss" **before**
   Decision 30 existed. The core rationale is therefore not a fresh abstract argument but
   **the generalisation of two already-found, already-scheduled defects**; choosing the
   authority over the cache resolves both at once instead of patching each. Doc-verified.
2. **The matcher is source-blind by construction** — `combo_string`/`any_mod` take a plain
   table and index by raw key name; Decisions 8/21/26/27 standing is **structurally
   forced**, not asserted.
3. **The mandate never asked for the tracked set** — FR-5/6/7 edit-area scoped, NFR-2
   narrow; the capability entered via Decisions 20/21, from the assistant/owner exchange.

**Three claims I re-verified in code myself:**
- `controller.lua:395-418` — `combo_string(k, keys_pressed)` reads
  `keys_pressed[m[1]] or keys_pressed[m[2]]`; **never calls `Key.*`**. `any_mod` likewise. ✓
- `projectInputController.lua:101-111` — `find_shortcut` builds
  `combo_string(trigger, keys)` first, and falls through to the class key
  `combo_string('*', keys)` only when `sc` is nil **and** the trigger is not itself a
  modifier. ✓
- `controller.lua:752` — `--- SKIPPED focus`. ✓

**Two corrections/additions that change implementation, not the verdict:**

**A. Decision 30's "prerequisite" paragraph may name the WRONG subsystem.** Since
`combo_string` looks `m[1]` and `m[2]` up **separately**, the natural device-backed matcher
is a per-key proxy (`__index = function(_,k) return love.keyboard.isDown(k) end`), which
resolves through the mock's **single-key** `isDown(k)` — exactly the granularity it already
needs. Under that shape the mock's single-arg limit **never bites the matcher**; the real
prerequisite becomes **extending `mock.lua`'s `mods` token map (`:17-21`) with right-hand
variants** (the `held` table `:5-15` already has the slots). **This is a DESIGN FORK, not a
settled fact:** route the matcher through `Key.ctrl()/alt()/shift()` for symmetry with the
gate instead, and the variadic-`isDown` concern reattaches for real. Fable's recommendation
is the per-key lookup; it says name the fork in the PR either way.

**B. Rule 4's honest residual — two consequences Decision 30 does not name, and should.**
Fable built the pattern out rather than arguing it:
- a project flag set on `keypressed` / cleared on `keyreleased` **is itself a small
  event-tracked boolean** with the same *kind* of drift, at per-project/per-flag rather than
  system-wide scale — and the framework's own **centralised** focus-loss fix disappears
  along with the set it was fixing (focus stays `SKIPPED`, no hook offered).
- **A genuinely NEW fragility, verified:** the flag-shortcut is filtered through the
  **modifier-sensitive** matcher, so `shortcuts.keypressed['a']` silently fails to fire —
  and the flag silently fails to update — whenever an unrelated modifier happens to be held.
  Raw `keys_pressed['a']` tracked the key **unconditionally**. Not a drop-in replacement.
- Modifier-as-trigger flags: **moot, not broken** — press/release serialise asymmetrically,
  but that asymmetry is **pre-existing** (`:788` writes before `:894-896` dispatch, `:906`
  before `:912-913`), and rule 2 gives modifier truth directly anyway.

**C. Independent doc defect found:** **Decision 21's worked example is stale prose** — it
says a hook "receives the held-key view", but **Decision 26 already removed that argument**
(`dispatch` passes varargs only). Two supersessions compounding on one uncorrected
sentence; misleads a reader today regardless of Decision 30.

**Q2 recommendations (Fable's, owner's to rule):** device-backed source lands **first**, at
the single call site `find_shortcut:103-110` · then write-side + dead machinery removal
(`:788,906,498`, `held_keys()` `:420-443,501`, sandbox field `consoleController:539-540`) ·
then `examples/keyboard` · then tests · **probe: delete now** (self-declared) · **gate's own
table: follow-up, NOT this PR** (mixes "revert a decision" with "add architecture" in one
diff, and a table invites a false promise of overridability) · **`error_explorer.lua:418`:
out of scope, but name it in the PR** so it does not read as a missed occurrence.

**Test migration, mapped:** `keys_pressed_spec.lua` first describe (`:52-96`) **delete**;
**second describe (`:98-138`) keeps UNCHANGED** — it tests the source-blind matcher against
a synthetic table. Fable reads that as evidence Decision 30 is cleanly implementable: the
tests that matter most for combo correctness need zero edits. `input_nfr_mechanism_spec.lua`
`:66-105` delete, `:123-165` keep; `input_events_spec.lua` `:781-905` delete, with
`:557,616,734,857-861` needing individual rewrites (some assert a write-before-dispatch
ordering that simply ceases to be meaningful).

**Its strongest counter-argument to itself** (honest, and downgraded from its first draft):
student games are exactly the class where "is X held while Y fires" is ordinary, not edge —
so every project rebuilding the flag pattern **re-derives, unassisted, a version of the
focus-loss bug the debt register had already scheduled to fix once, centrally.** Smaller and
optional, but *"smaller and optional is not absent"*, and a platform whose stated goal is
**simpler and more robust** has moved a known fixable-once bug from where maintainers patch
it for everyone to where each student patches it for themselves — and most will not know
until it bites them once, silently.

## 2026-08-09 — owner downgrades Fable's residual (a): ownership is the disanalogy

**Owner:** yes, a project flag is tracked state — *"as any local state variable would be.
But it's owned by the project, which can consume and alter it as needed. Platform-owned
`keys_pressed` was global, long-living state, read-only for projects — very different
beast."*

**Correct, and it inverts Fable's comparison rather than softening it.** The structural
critique Decision 30 makes of a stateful model bites hardest on state that is
**long-lived, globally shared, and unrepairable by whoever reads it**. The flag is none of
those: **project-owned, project-scoped, and writable by its owner**, so a project can
clear or rebuild it on any event, mode change or heuristic it likes. A project observing a
phantom in `keys_pressed` had **no repair path at all** — read-only by contract
(writes raise). So the flag is not "the same bug at smaller scale"; it is a **strictly
better-positioned** kind of state than the thing it replaces.

**What survives the correction, stated for fairness:**
- The project cannot hook **focus** either — the gateway installs no focus handler
  (`controller.lua:752` `SKIPPED focus`), so repair must be logic-driven, not focus-driven.
  A real limit on the repair path, not a defeat of it.
- **Residual (b) is untouched by the ownership argument** — the modifier-sensitivity
  fragility is about whether the flag *updates at all*, not about whether it can be
  repaired once wrong. `shortcuts.keypressed['a']` silently not firing under an unrelated
  held modifier remains the one genuinely new trap, and remains PR-description material.

**Consequence for Fable's closing counter-argument:** it leaned on projects "re-deriving,
unassisted, the same bug the debt register scheduled to fix centrally." Under the owner's
correction that is **overstated** — it is not the same bug, because ownership, lifetime and
mutability all differ. Its force reduces to: *a project author must think about clearing
their own flag*, which is ordinary local-state discipline, not an inherited platform defect.
