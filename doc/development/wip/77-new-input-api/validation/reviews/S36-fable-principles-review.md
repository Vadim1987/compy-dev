# Oracle review — input-usage principles (Fable, session 36)

Reviewing `S36-input-usage-principles.md` (owner §1, assistant §2, knock-on §3), against
`doc/development/wip/77-new-input-api/validation/prompts/S36-fable-principles-review.md`.
Read whole, including the owner's live amendment to §2.2 C3 (relayed mid-review; judged as the
file now stands). Facts below were checked against `src/util/key.lua`,
`src/controller/controller.lua`, `src/controller/projectInputController.lua`,
`doc/input_api.md`, `doc/development/decisions/input.md`, `doc/development/technical_debt/
input.md`, `doc/development/wip/77-new-input-api/validation/reviews/S27-triage-and-plan.md`
(the live plan, for P10/P16-P19), and a real `love 11.5` process run headless (not the
`tests/mock.lua` fake). `busted tests`: 942 / 0 / 0 / 10, as expected.

---

## Verdicts

- **Principles (P1-P4, P5.2): RATIFY, with one required addition to §3** — an explicit
  amendment note against Decision 30 point 3 (below). They are true as far as I could stress
  them, internally coherent, and every attempt I made to construct a legitimate counterexample
  (a safe mirrored pair, a shortcut that should legitimately hold continuous state) failed against
  the actual `combo_string`/`find_shortcut` mechanics. That the search came up empty is itself
  evidence the principles are close to airtight for anything routed through `shortcuts`.
- **P5.1 (`Key.pressed(...)`): DO NOT RATIFY FOR THIS RELEASE.** Right idea, wrong release. Ship
  the diagnosis (prose, P5's threefold complaint) now; defer the primitive. Reasoning below —
  the assistant's strongest argument for urgency (§2.3) does not hold up, and there is a directly
  on-point precedent, one day old, for deferring exactly this shape of proposal.
- **Exclusivity (C2, as amended by the owner's C3 correction): AGREE — permissive by default,
  `*` for exclusivity**, delegating set membership to the framework's own closed modifier list
  rather than hard-coding it at the call site. Argued below. This is recorded for whenever P5.1
  ships, not ratified as active surface now.

---

## Q1 — Do the principles hold together, and are they true?

**Mechanically verified, not just plausible.** `find_shortcut` (`projectInputController.lua:104`)
does exact-combo-then-class lookup; `combo_string` (`controller.lua:402`) re-reads *every*
currently-held generic modifier at serialisation time, not just the one a caller cares about. That
single fact is what makes P2/P3 true rather than merely cautious: a modifier held or released
**anywhere else** in the chord changes the string a mirrored binding's other half must match,
so no mirrored pair over `shortcuts` can be made safe by writing it more carefully — the failure
is structural, not a bug in any one example.

**Evidence for P2, checked, with its provenance sharpened:**
- **Live, shipped, currently broken:** `doc/input_api.md` "Shortcuts that set a flag"
  (`shortcuts.keypressed['space']` / `shortcuts.keyreleased['space']`, lines 433-438) — press
  Space, press Ctrl, release Space serialises `'ctrl+space'`, the `'space'` release binding is
  missed, `drawing` sticks `true`. This is the **documented, recommended pattern**, and it has
  the defect it is supposed to solve.
- **Live, shipped, currently broken:** `src/examples/sapper/main.lua:671-705`. Verified this is
  not hypothetical: `mousereleased` increments `click_count` unconditionally (`controller.lua:
  913-918`), regardless of modifiers; the derived `singleclick`/`doubleclick` hooks re-poll
  `Key.shift()/alt()/ctrl()` when they fire, up to `click_delay` (0.4s) later. Hold Shift, click
  (→ `single()` runs via `love.mousepressed`), release Shift inside the window → the hook's guard
  now reads "nothing held" and **fires `single()` a second time**. This is documented as standing,
  open debt (`technical_debt/input.md`, "sapper's modifier click path...", lines 1050-1077) and as
  its own unstarted plan step (`S27-triage-and-plan.md` P19, "decides whether to convert... and
  how to close the residual hole").
- **Illustrative, not found live:** the `alt+h` pair. No such registration exists anywhere in
  `src/examples` (grepped) — it is technical_debt/input.md's own worked example of why the
  mirrored-pair shape fails (`keypressed['alt+h']`/no expressible release), and the *actual*
  shipped code for this exact interaction (`keyboard/help.lua:helpHeld`) already avoids it by
  polling. **The commission's framing ("three defects found... each an instance of P2") reads as
  three independent live findings; only two are.** The third is a correct, pre-existing proof, not
  a lesser one — but the provenance should be kept as strict here as the document asks it to be
  kept between owner and assistant.

**P1** ("stateless transition" = the *trigger* is one-shot, not that its effect is temporary) is
coherent and does real work: it correctly assigns "move while W is held" to P4 (poll), not to a
shortcut pair, and nothing in the tree suggests a case where a mirrored shortcut pair should hold
continuous state instead of polling.

**P4** is consistent with Decision 30 points 1-2 (device is the modifier authority) but sits in
real tension with **Decision 30 point 3**, a ratified, standing decision naming `Key.*` at a call
site "a smell" that "should be replaced by the shortcuts mechanism." P1+P4 say the opposite for a
real class of cases (continuous state, physical checks): polling there is not a smell, it is
correct. **I read the new framing as better than Decision 30.3's blanket rule** — it resolves
exactly the tension `doc/input_api.md`'s existing "Held keys" ladder already shows signs of
(rung 2, `Key.*`, is described there as "usually describing a binding it has not written yet,"
which P1-P4 now correctly narrows to *transition* logic only). But it is a partial reversal of a
named, ratified decision, and the document under review does not say so anywhere — see Q5.

**What is missing (Q4), beyond what §2 already names (C3b's three boundary cases):**

1. **A third axis the principles don't cover: *when* you read state relative to a delayed or
   derived event.** P1-P5 answer "which paradigm" (shortcut vs. poll); sapper's live bug is not a
   paradigm question — the current code already polls (P4-compliant) and still breaks, because the
   poll runs at *derived-event-fire time*, after the double-click window, not at the moment the
   user acted. No amount of picking the right paradigm at the call site fixes a check made at the
   wrong time. This deserves its own line in the promoted text, separate from P1-P4, or a project
   author who follows every principle correctly will still ship sapper's bug.
2. **Project-level re-invention of the tracked-set Decision 30 killed at the framework level.**
   `src/examples/maze/macro.lua:74,89` (`macro_state.shift_held`, maintained across
   `keypressed`/`keyreleased` against a static key table) and, per its own code comment,
   `keyboard/input.lua`'s `INPUT` proxy *used to be* exactly this before it was rewritten onto
   `Key`. This is the same failure shape Decision 30 removed from the framework, recurring in
   project code, and it is neither a "shortcut" (P2) nor "device polling" (P4) — it's a third
   thing the principles have no name for and should.
3. **Focus loss** is cited as rationale for P2/P3 but the principles give no recovery guidance
   (poll on refocus? nothing needed, since polling is self-healing by P4's own argument — but that
   connection is left for the reader to make).
4. **Test/production parity for the "loud failure" property P5.1's whole safety case rests on.**
   Verified: `tests/mock.lua`'s `isDown` (line 39) never raises, for any key, valid or not — it is
   a plain table lookup. Real LÖVE, verified live (below), *does* raise. If P5.1 ever ships, a
   typo in a project's `Key.pressed(...)` call would be silently swallowed by `busted tests` and
   only surface against the real engine — the opposite of what C1 claims the design buys. Same
   gap, narrower, in `harmony/init.lua`'s `patch_isDown`: it only re-raises when `not lock`.

## Q2 — Is P5.1 justified in this release?

**C1's core factual claim is true — verified against the real engine, not the mock:**

```
$ xvfb-run -a love .   (LÖVE 11.5)
love.keyboard.isDown('shfit')          → false, "Invalid key constant: shfit"
love.keyboard.isDown('ctrl')           → false, "Invalid key constant: ctrl"
love.keyboard.isDown('lctrl','rctrl')  → true, false   (no raise)
```

So the pass-through design is real and is a genuine correctness win over the sibling
`compy.input.keys` **table** proposal (`technical_debt/input.md`, "PROPOSAL: `compy.input.keys`,
a held-state surface...", 2026-08-10), whose own design-questions section names "silent nil" as
an open problem it does not solve. C1/C4's argument that the variadic query subsumes and beats the
table is sound, **as a design comparison** — I agree with it.

**§2.3's argument for shipping it *now* does not hold, and is self-contradictory on its own
terms.** It claims the four-guard respelling gives "no derived-click channel, no swallow, **no
synthesis-time modifier hole**, **no behaviour change at all**." Those two clauses cannot both be
true: if the four boolean chains are respelled with identical semantics at the identical call
sites (which is what "no behaviour change at all" means), then whatever bug existed in that
behaviour before — including the synthesis-time modifier hole, which is *part of the current
behaviour*, confirmed live above — is still there afterward. A pure respelling cannot remove a
bug it doesn't touch. Confirmed independently against the plan: `S27-triage-and-plan.md`'s P19
row (owner, 2026-08-10, one day before this proposal) treats "decide whether to convert" and "how
to close the residual hole" as two separate, still-open questions for sapper's own author — the
project's own planning document does not believe respelling closes the hole either.

What P5.1 *does* deliver for sapper is real but smaller than claimed: the sprawl/reinvention
complaint (P5's actual diagnosis) is answered — four chains become four one-line calls. That is a
readability win, not a correctness one, and it does not need to ship as code to be worth having;
it can ship as **prose recommending the shape**, with the primitive itself deferred, exactly as
P5.2 already recommends doing for the vertical-sprawl half of the same problem ("a
recommendation, not a mechanism").

**The direct precedent the commission asks me to weigh against, found in the tree:** the sibling
`compy.input.keys` proposal — same underlying need, evidenced the same way ("every input-heavy
project re-derives this") — was explicitly ruled **"Not this release"** by the owner one day
earlier, on exactly the mandate this commission restates: *"It is new API surface, and the
feature's mandate is a simpler and more robust input API, not a larger one."* P5.1's own
justification ("reduces boilerplate," "fewer moving parts," "extra cheap — a few lines") is the
same shape of argument that proposal made and that did not carry the day. Nothing in P5.1 answers
*why this release* beyond "it's cheap" and "it's better-designed than the table" — both true, and
neither is the axis the prior ruling turned on. Recommendation: record the design (variadic
tokens, loud pass-through as a documented contract, `*` for exclusivity, module not table) in the
technical debt register so it is not re-derived, superseding the table shape of the existing
entry, and revisit it alongside `compy.states` and the held-chord gap — which is where the
register already keeps this class of proposal.

## Q3 — the exclusivity question

**Agree with the amended position: permissive by default, `Key.pressed('shift','*')` for
"shift and nothing else," delegating membership to the framework's own list rather than
enumerating it.** Checked `check_combo`/`split_combo` (`key.lua:44-100`): the closed modifier set
lives in exactly one place (`mod_triples`/`mod_order`), which is precisely what changed eight days
ago (Decision 31 dropped `gui`). A call site spelling `Key.pressed('!ctrl','!alt','!shift')`
hard-codes that set's membership into project code the way `mod_order` used to be hard-coded
before Decision 31 consolidated it; `*` reading the same list `combo_string`/`check_combo` already
use does not. This is the stronger, correctness-based argument the amendment lands on, and I
concur it beats the brevity argument it replaced. I also agree with deferring the broader
`![a-z]`/class mini-language the owner floated — that is new vocabulary needing a defined story
(non-Latin layouts named correctly as the sticking point), which is exactly the kind of unjustified
extra moving part the frame is supposed to catch, and nothing in evidence asks for it yet.

## What the assistant got wrong or should sharpen

1. **§2.3's central urgency claim is factually self-contradictory** — see Q2. This is the most
   consequential correction in this review: it is the argument the commission specifically flags
   as carrying weight toward shipping P5.1 now, and it does not survive checking the tree the
   claim is about (sapper) or the plan's own P19 row.
2. **§2.1 cites Decision 30 only for its device-is-the-authority half (points 1-2) and misses that
   P1+P4 sit against Decision 30 point 3**, a *named, standing* decision calling `Key.*` at a call
   site "a smell" to be replaced by shortcuts. §2.1 frames P1+P4 as "resolving a tension," which
   undersells it — they partially **reverse** a ratified rule. See Q5.
3. **"Three independent findings... each an instance of P2"** bundles two live, shipped bugs with
   one illustrative, mechanically-derived (but never-shipped) example, presented with equal
   weight. Doesn't weaken P2 — the mechanical proof is sound — but the document elsewhere insists
   on strict provenance and this claim doesn't meet its own bar.
4. Minor, not an error once read charitably: "**Key.any_mod()**... what the matcher already has
   internally" — the matcher's existing helper is `Controller.any_mod()` (`controller.lua:417`),
   not something already on `Key`. Reads correctly as "lift this into `Key`," but as written it
   could be misread as already existing there.
5. Did not surface the test/mock parity gap (`tests/mock.lua`'s `isDown` never raises) that
   undercuts the "loud failure, verified" property `busted tests` would actually exercise if
   P5.1 ships. Worth adding to C3b as a fourth boundary item, or as its own prerequisite the way
   Decision 30 recorded the mock's variadic fix as one.

## Q5 — contradictions with ratified decisions

- **Decision 30, point 3** ("`Key.*` at a call site remains a smell... should be replaced by the
  shortcuts mechanism") is **contradicted, not merely extended**, by P1+P4's affirmative
  endorsement of device polling for continuous/physical-state cases. I judge the new framing
  correct — but the review document does not state the supersession anywhere, and the commission
  is explicit that this is a finding, not a footnote, even where the reversal is the right call.
  **If ratified, this needs an explicit amendment note in `decisions/input.md`** (the way Decision
  31 states "Amends Decision 8"), narrowing Decision 30.3 to P1-shaped one-off transitions rather
  than leaving two documents giving opposite blanket advice about the same `Key.*` calls.
- **Decision 30, point 4** ("a shortcut sets a flag, it does not grow") is **reinforced**, not
  contradicted, by P5.2 — same shape, generalised from shortcuts specifically to hook/update logic
  broadly. No issue.
- **Decisions 8, 21, 26, 31**: no contradiction found. P5.1's design, if built as amended (variadic
  tokens, `*` reading the shared modifier list, pass-through raising), is consistent with all four
  — checked `check_combo`'s bare-`'*'` refusal (Decision 21) against the query's proposed `'*'`
  acceptance: that is a **stated, deliberate asymmetry** (C3 says so explicitly), which is exactly
  what the commission's own rule for legitimate supersession asks for.

## What I could not determine

- Whether an actual implementation of the mouse-button pass-through (C3b) would raise reliably.
  Checked what's available today: `love.mouse.isDown` does **not** raise on an out-of-range button
  number (`love.mouse.isDown(99)` → `false`, no error) and raises a *different*, unrelated error
  for a string argument (`bad argument #1... number expected, got string`). So even a careful
  implementation routing `'mouse1'` tokens to `love.mouse.isDown` would **not** inherit the loud
  failure guarantee the keyboard path gets for free — a real asymmetry C3b doesn't quite reach,
  but there is no implementation yet to test directly, only the two device primitives it would be
  built from.
- Whether the owner intends `compy.states`/the held-chord proposal to eventually be the real fix
  for sapper's residual hole. The plan (P19) explicitly leaves this open ("if the answer is 'the
  platform carries the press's modifiers,' that is release-shaped and gets promoted to the parent
  plan") — consistent with what I found, not a gap in this review.
- I did not line-by-line audit every example (`pong`, `life`, `paint`, `tixy`, `turtle`, `clock`,
  `guess`, `valid`, `repl`, `sine`) against P1-P5; I checked the ones named in the review/plan
  (`sapper`, `maze`, `keyboard/help.lua`, `maze/macro.lua`) since those are the ones the document
  under review and the live plan already put in evidence.
