# S27 — remark triage and execution plan

**Input:** `../outcomes/S27-remark-inventory.md` (187 remarks, ids R001–R187,
verbatim, extracted by a read-only sub-agent) and
`../reviews/S26-TF2-smoketest-results.txt` (the owner's smoke test).
**Commission:** `../prompts/S27-human-commission.md`.
**Author:** session27 (parent). Severity and workstream assignment are this
session's judgment; the inventory's "provisional kind" was a hint only and is
overridden wherever it disagrees.

Every id is assigned to exactly one workstream (coverage table, Appendix A).

---

## 0. What this document is, and what it is NOT (added 2026-08-09, session32, owner ruling)

**This is a spinoff sprint, not the release plan.** The release plan is
[`../plan.md`](../plan.md) — the validation-phase plan that ends in **Phase G, PR
assembly**. This document is the honest descendant of that plan's **Phase TF2**: the
owner's human review of the split suite produced 187 remarks instead of the near-empty
bucket TF3 predicted, and they were triaged here.

**So TF2 is not finished — it is being cleared through this sprint.** Nothing downstream of
TF2 in the parent has started.

**What this sprint is NOT: it is not the B→C→D collapse.** That collapse was proposed in
`../notes/post-R-replan-hypothesis.md` and **gated on TF2/TF3** by
`S18-post-R-replan-reconciliation.md`. The gate is still shut. When this sprint closes and TF2
with it, the parent returns to that gate — and the likely finding is that the parent's Phase B
(convergence check), Phase C (principle sheet + disposition table) and Phase D (ruling sitting)
are **already satisfied by the code and architecture cleanup performed here**, in which case
**points of the parent plan collapse**. That is a ruling made *at* the gate. The fact that
`convergence-check.md`, `principle-sheet.md` and `disposition-table.md` do not exist is a
**pending question for that ruling**, not evidence that they were silently replaced.

**The two plans are linked, never merged** (owner ruling, 2026-08-09) — they sit at different
altitudes. The working discipline: **clear this sprint → close TF2 → rule on the collapse →
Phase F onward.** Nothing here overrides the parent; anything that turns out to be
release-shaped rather than remark-shaped is **promoted up**, not carried here.

**First promotion, 2026-08-09:** **P12** (upstream reconciliation) has moved to the parent as
**Phase U**, between F and G. It was never a remark — it is a release precondition. §8's
analysis stands and is not superseded, only re-parented. **P13** (harmony) is coupled to P9e
and is an open disposition question for the session32 replan, not settled by that move.

---

**REVISED 2026-08-07** after two cold reviews —
`../outcomes/S27-triage-factcheck.md` (fact-check against code) and
`../outcomes/S27-plan-review.md` (plan quality). Both were run without sight of
the reasoning that produced this document. Changes are marked **[REV]** and
logged in §5; the corrections they forced were verified in code before being
accepted. Neither review found a structural objection; both found real errors.

---

## 1. The severity scale

Two axes. **Severity** says what kind of thing it is; **gate** says whether the
PR can ship without it.

| S | Meaning | Gate |
|---|---|---|
| **S0** | Possible defect — behaviour that may be wrong, not merely ugly | blocks |
| **S1** | Shape-changing — alters a project-facing contract or the solution's structure | blocks (ruling first) |
| **S2** | Code-structural — real code change, behaviour preserved | should |
| **S3** | Doc-substantive — a permanent doc states something false or stale | blocks (the PR is reviewable from the docs) |
| **S4** | Editorial — verbosity, vocabulary, comment bloat | should (owner asked for it explicitly) |
| **S5** | Question — needs an answer; the answer may or may not produce work | blocks only its own follow-on |

**Why S3 blocks.** The strategic frame says the PR must be reviewable from
`doc/input_api.md` + the PR description alone. A doc that misdescribes the code
is therefore not cosmetic — it is the deliverable being wrong.

---

## 2. Workstreams

Ordered by dependency, not by size. W1–W3 are one architectural movement and
are separated only because they can land as separate commits.

### W1 — Signature unification: drop `keys_pressed` from the payload  · **S1**

**Members:** R009, R036, R096, R097, R098, R099, R112, R114, R146, R176.

Hooks and shortcuts currently receive `(k, keys_pressed, isr)` on keyboard and
`(t, keys_pressed)` on text, while pointer channels receive LÖVE's own
arguments untouched. So the "uniform signature" is uniform across three
channels and different from LÖVE on all of them. Since Decision 20 made
`compy.input.keys_pressed` globally readable, the threaded argument buys
nothing.

**Verdict: accept.** It removes a parameter, removes the divergence from LÖVE,
and makes `dispatch` payload-agnostic — which is the precondition for W2 and
W4. Consequences the owner already spotted: `ignore_repeat` reads `(k, keys,
isr)` and must be re-cut (R009); Decision 9 loses most of its reason to exist
(R099 asks whether to delete it outright).

**Breaking.** Any hook written against the current triple sees its arguments
shift. In-tree that is the examples and the three nested repos; outside the
tree it is nothing, because nothing has shipped. This is the single most
consequential item in the inventory and the one the plan gates first.

**[REV] The migration surface, enumerated rather than gestured at.** Of every
in-tree consumer of `compy.input.hooks` / `.shortcuts`, exactly **one** reads a
dropped positional argument:

| consumer | registration | affected? |
|---|---|---|
| `examples/keyboard/input.lua:142` `appKeypressed(k, _, isr)` | `hooks.keypressed`, `:94` | **YES — silently** |
| `examples/keyboard` `appKeyreleased(k)` `:152`, `appTextinput(t)` `:163` | `:95`, `:96` | no (first arg only) |
| `examples/keyboard` `shortcuts.keypressed[...]` `:78-88` | via `compy.input.fn` | no (combinators, see R009) |
| `examples/turtle/main.lua:54` `shortcuts.textinput['i']` | — | no (takes no args) |
| `examples/sapper/main.lua:671,689`, `examples/paint/main.lua:356,360` | click hooks `(x, y)` | no (pointer payload unchanged) |
| `maze`, `balloons` | never touch hooks/shortcuts | no |

`appKeypressed` is the whole risk, and it fails **silently**: after the drop,
dispatch calls `hooks.keypressed(k, isr)`, the unmigrated function binds
`_ = isr, isr = nil`, and its repeat filter (`if isr and k ~= "capslock" then
return end`) stops firing. No crash, no failing test — held-key repeats simply
stop being filtered. This is the `wrap`-arity failure mode session26 found,
exactly. **P2 names this file and this function; it is not left to "incl. the
examples".**

**[REV] "Equal to LÖVE's" overclaims for `keypressed`.** LÖVE's real signature
is `(key, scancode, isrepeat)`, and the gateway already discards `scancode`
(`controller.lua:499`, `local function keypressed(k, _, isr)`) — recorded in
`technical_debt/input.md`, "Combo triggers are key-name-only". Post-W1
`hooks.keypressed` is `(k, isr)`: **closer** to LÖVE, not identical. Say so in
the docs rather than letting a reader be surprised.

**Open for the owner:** delete Decision 9 entirely (R099) or keep it, rewritten
to record that the argument was *considered and dropped*? My recommendation is
**keep, one paragraph** — the ledger's value is that a future reader stops
re-proposing it.

### W2 — Pointer shortcuts: modifier-only combos · **S1**

**Members:** R037, R115, R131, R145, R152, R177.

Six remarks in **three** docs and one source file say the same thing, and the owner
named it in-session as something believed agreed that is not in the code. It is
not: `find_shortcut` returns nil for a missing table, pointer channels pass
`trigger = nil`, and `doc/input_api.md` §"Pointer and click hooks" argues
affirmatively that pointer shortcuts *cannot* exist because "a combo needs a
key to name."

**Verdict: accept, and the doc's argument is wrong.** A combo does not need a
trigger key — `combo_string('*', keys)` already builds a triggerless class key
for the `alt+*` wildcard, so the machinery exists. Pointer combos are the same
serialisation with the modifier set and no trigger.

**[REV] This is now a recommendation, not a coin flip.** I had framed both
sub-questions as fully open; the cold review pointed out that R115 — a member
of W2's own list — already answers the first one in the owner's own words:
*"combo is constructed from modifier keys pressed, **no trigger key**"*
(`decisions/input.md:1063`). An owner remark is not an automatic mandate, so it
is still re-confirmed at P1, but the plan's own position is:

- **Modifier-only. No button vocabulary.** `ctrl+*` matches a modified pointer
  event on the channel it is registered for. Introducing `ctrl+mouse1` would
  create a second trigger vocabulary alongside key names for one capability.
- **SM1 (paint right-click) does not need the button in the combo.** The button
  is already in the payload — LÖVE's own `mousepressed(x, y, button)` — so a
  hook or a modifier-only shortcut reads it directly. The paint finding is a
  missing handler, not a missing vocabulary.
- **`mousepressed` only**, unless the owner asks otherwise. A shortcut table
  consulted per `mousemoved` is a lookup per motion event, and no finding needs
  it.

### W3 — Click events become first-class · **S1**

**Members:** R022, R027, R029, R030, R035, R154.

`singleclick`/`doubleclick` are dispatched by the generic `pointer_channel`
loop but are absent from `EVENTS`, so `seed_hooks` never seeds them; and
`reset_compy_input` wipes shortcut tables for exactly three hand-listed
keyboard events (R027). Two hand-maintained lists that must agree and do not.

**Verdict: accept.** One list of supported events, derived flag where the
distinction is genuinely needed (synthesis), enumerated nowhere else.

**R030 is answered, not actioned.** A drift between presses drops the derived
event entirely rather than degrading to two singleclicks. That is what
`doc/input_api.md` says it does ("Moving the pointer between the presses
invalidates both"), so it is intended, not a swallow. Recorded as an answer; if
the owner wants a drag to still yield a click, that is a new S1 and belongs
after the PR.

### W4 — One dispatch, one wiring loop · **S2**

**Members:** R021, R023, R024, R025, R026, R028, R031, R033, R171.

`controller.lua` installs and releases handlers one function per event
(`set_love_keypressed`, `set_love_keyreleased`, `set_love_textinput`, …), keeps
an `occupy_keyboard` / `hook_pointer` split that no longer distinguishes
anything, and `hook_pointer` reads as a leftover. **[REV] "Leftover" oversells
it:** `hook_pointer` (`controller.lua:290-303`) installs nothing any more —
`occupy_keyboard` installs every channel including pointer — but it still
computes the `user_pointer` liveness flag, which is live logic. Its *name* is
the lie. Rename and re-site the flag computation; do not delete the function's
body. `ProjectInputController`
likewise keeps `keypressed`/`keyreleased`/`textinput` methods whose only
remaining job is to call `held_keys()` — which W1 deletes.

**Verdict: accept, and it is mostly a consequence of W1.** With the payload
equal to LÖVE's arguments and the combo built inside `dispatch`, the three
keyboard methods collapse into the same `pointer_channel`-style loop, and the
per-event install functions become one loop over the event list. Behaviour
preserving.

**R033/R171 (`handlers.userinput` a dead vestige) needs a reference check
before deletion, not an assumption** — LSP refs plus grep, per the standing
rule. Verifying it is part of the workstream, not a precondition.

### W5 — The callback surface: `before_submit`'s veto · **S1**

**Members:** R038, R121, R122, R158, R160, R161, R181.

Confirmed in code — **[REV] with the method names corrected**, because I had
them wrong and the wrong ones exist:

- `UserInputController:submit_flow` (`:413`) calls
  `run_callback(self, 'before_submit', keys_pressed)` and **discards the
  return**.
- `UserInputController:cancel_flow` (`:430`) honours `before_cancel`'s truthy
  return as a veto.
- There is **no** `UserInputController:submit()`. There **is** a
  `UserInputController:cancel()` (`:205`) which is the console's own
  debug/test-mode unconditional clear-and-hide and does **not** consult
  `before_cancel` at all. An implementer grepping for `cancel()` lands on the
  wrong function and could "fix" the wrong path. The veto lives in
  `cancel_flow`; both flows are reached from `:699` / `:701`.

The docs describe the asymmetry as deliberate ("veto reserved, unbuilt (R9)").
The owner's position across three remarks is that a callback documented as
vetoing must veto.

**Verdict: accept the veto.** It is a two-line change and removes an asymmetry
no one can justify from the outside. It is still **S1** — it changes a
project-facing contract, and a project that returns a truthy value from
`before_submit` today gets a submit; after this it gets nothing.

**Also here:** `before_submit`/`before_cancel` are absent from
`default_callbacks()` (R038) while their `after_*` siblings default to noop —
an inconsistency to resolve the same way in the same commit. And R121/R122 ask
whether callbacks should be settable through `show{}`'s config at all, or only
through `compy.input.callbacks`. **That one I recommend deferring** — it is a
second contract change with no defect behind it, and R121 argues both sides
itself.

**Open for the owner:** does `before_exit` get a suppress/defer return too
(R181)? The docs currently promise it cannot. Symmetry says yes; "a project can
refuse to stop" says no. **I recommend no** — and **[REV] the code makes the
case harder than I first put it.** `ConsoleController:stop_project_run`
(`consoleController.lua:1282-1294`) calls `compy.before_exit()` **unguarded** —
no `pcall` — and every teardown step (`set_default_handlers`, `hide_overlay`,
`clear_user_handlers`, the `before_exit` reset itself) sits *after* it in the
same sequence. A raise there aborts the rest of teardown outright. That is
R127's gap, live and reproducible, not merely undocumented. Handing a project
a suppress/defer return over a stop sequence that is not itself raise-safe
would be backwards. Fix the doc that calls it "deferred functionality"; note
the guard gap where R127 is answered.

### W6 — Is the widget a special chain tier? · **S1**

**Members:** R080, R086.

R080 contests Decision 5: the widget is the only chain participant whose
consumption is decided by its own `is_shown()` rather than by a return value,
and the owner suspects that specialness is a leftover of the hallucinated
design session26 removed. R086 says a paragraph in `decisions/input.md`
describing the old "checked at the end of chain, bypassed if not shown" model
still stands and contradicts the current one.

**Verdict: split them.** R086 is **S3** and unconditional — a stale paragraph
in a permanent doc, fix it. R080 is **S1 and I recommend declining for this
PR**: the widget genuinely is not a function, it is a stateful sink with no
return value to give, and "consumes while shown" is a real property rather than
a leftover. Making it return a boolean would add a return value whose only
possible source is `is_shown()`.

**[REV] Both cold reviews independently confirmed the decline and added two
facts I did not have:**

- **No `UserInputController` event method returns anything today** —
  `keypressed`, `textinput`, `keyreleased`, the four mouse channels and the
  three touch stubs all return nothing; `keypressed`'s own comment records that
  "the old limit-flag return channel is retired". So this is not a small edit
  at the call site: it invents ~10 new boolean contracts, each needing an
  answer to "what does it mean for the widget to decline *this* keystroke".
- **There is no tier after the widget for a manufactured `false` to reach.**
  `dispatch`'s return becomes `love.keypressed`'s return, which LÖVE's event
  pump discards; only tests observe it. Ten new contracts, zero runtime
  difference — strictly more elaborate, not more predictable.

**[REV] And a factual correction to put in front of the owner, not a design
argument.** R080's text is attached to Decision 2 but reasons from "discard
Decision 5" — two different specialnesses. The one session26 found hallucinated
and removed was Decision 2's fourth chain tier (the non-overridable framework
Enter/Escape). Decision 5 is a different rule: widget results travel out
through callbacks because the widget is terminal and nothing above it can read
a return. The suspicion that this is hallucination residue is reasonable given
the history — but the record says only one of the two ever was.

**[REV] R044 joins this workstream** (was W7). The P0 evidence note shows
`always_shown()` and the whole `shown` flag are this feature's — the base
controller had `is_oneshot()` and no flag — and that `hide()` would clear the
flag on any instance it is called on. R080 and R044 are the same question from
two ends: is "shown" the right primitive? They are ruled on together.

The original wording follows; I may be wrong, and this is one I wanted a cold
advisor on before it goes to the owner.

### W7 — `consoleController` / `userInputController` structure · **S2**

**Members:** R004, R005, R006, R008, R011, R012, R014, R015, R016, R017, R018,
R019, R020, R039, R040, R041, R042, R043, R044, R045.

Twenty remarks, one complaint: the file spends a lot of metatable machinery and
copy-pasted key-list validation on things a nil check would do, and its
load-bearing functions (`show`, `hide`) are lambdas inside one large builder.
Three sub-groups:

- **Trivial metatables** (R005, R006, R011, R012, R018, R020) — the owner asks
  whether `__index`/`__newindex` that reproduce default behaviour earn their
  place. Mostly they do not; but `build_shortcuts_surface`'s pass-through is
  what makes the *identity* frozen while leaves stay writable, which is
  Decision 7's actual mechanism. Each needs checking individually against what
  it freezes — a mutation test, not a reading.
- **Key-list duplication** (R014, R015, R016) — `SHOW_KEYS` re-lists names
  already in `OUTPUT_KEYS`/`PENDING_KEYS`, and `CONFIGURE_KEYS` is `SHOW_KEYS`
  minus one entry. Derive them.
- **Naming and extraction** (R004, R017, R039, R042, R043) — `frozen_error` →
  `unassignable_error`, `gate` inlined, `open_fresh` folded into `show`,
  `show`/`hide` promoted out of the builder.

**R044 (`always_shown()`) is S0, not S2** — the owner asks what guarantees the
flag, and notes it did not exist pre-feature. Check it against `3256aac` before
touching anything else in this workstream.

**R045 carries an owner ratification to record:** function bodies up to **16
lines** are tolerable where the alternative is a helper that exists only to
satisfy the limit. That is a change to `agents/rules.md`'s hard limits and must
be written down there, not applied silently.

### W8 — Test-suite shape · **S2**

**Members:** R047, R057, R058, R059, R060, R061, R063, R064, R067, R068, R069,
R070, R074, R075, R078, R079.

The owner's strongest test remark is R059 ("MUST HAVE"): a describe-level
`order` table and standard mock factories, so a reader learns the paradigm once
instead of decoding each case's bespoke universe. R057 proposes the same idea
one level up — three named groups matching the documentation's vocabulary
(inbound interception / widget state / widget-originated events), which is the
same three-surface split R172 proposes for the guide.

**Verdict: accept R057 + R059 as one restructuring**, and let the merge/dissolve
asks (R067, R074, R078, R079) fall out of it rather than be done separately.

**R060 is S0-adjacent and answered first:** "aren't our shortcuts mod-only?" No
— an exact combo of a bare key is legal and documented (`shortcuts.keypressed`
matches the serialised combo, which for an unmodified press is the key itself).
The tests are right. But the question shows the docs do not make this obvious,
which is an S3 on `doc/input_api.md`.

**R068 is S0:** the remark says a reconfigure test may now assert nothing after
the stay-open-by-default change. A test that cannot fail is worse than no test
— this is the same "green and blind" failure mode session26 caught three times.
Mutation-check it before deciding.

### W9 — Doc structure and the decision ledger · **S3**

**Members:** R086 (from W6), R093, R094, R105, R107, R109, R110, R127, R134,
R135, R165, R166, R167, R168, R169, R170, R172.

Two distinct asks.

**(a) The ledger is over-full.** Decisions 6, 7, 12, 15 and 16 are each
challenged as either not-a-decision (documenting pre-existing platform
behaviour), trivial, or already superseded. The owner's test is sharp and I
adopt it: *if the behaviour is what the platform always did, there was no
decision to record.* Decision 16 (R109) is the clearest — event-axis
unification happened, so the entry describing it as deferred is simply wrong.

**(b) Doc accuracy.** R134 (does the click-to-cursor translation apply to a
project widget?), R127 (`before_exit` cannot guarantee teardown if the project
raises — identified in session24, never written down; and the call is
genuinely unguarded, see W5). Each is a factual claim to check in code and
correct.

**[REV] Two entries corrected here, both against me:**

- **R135 is dropped — I was wrong.** I filed "projects cannot install evaluator
  objects" as a stale claim on the grounds that projects can configure a
  validator. The doc's own sentence (`internals/user_input.md:91-92`) already
  distinguishes the two: *"the internal plain evaluator plus project callbacks
  for validation and display. Projects cannot install evaluator objects."* A
  validator is a predicate function; an `Evaluator` (`LuaEval`,
  `LuaEditorEval`, with an `:apply()` method) is a different object a project
  genuinely cannot substitute. The doc is precise. **No action** — R135 moves to
  W10 as answered.
- **R110 is re-kinded, not re-severitied.** The section does not call `dispatch`
  non-reusable; it says in past tense that the mid-feature dispatch *had been*,
  and describes the fix. `dispatch` is a free function today
  (`projectInputController.lua:109`). Its real ask is "cut this stale
  intra-feature history", which is W10's historical-contrast batch. Moved.

**[REV] Two entries promoted into this workstream from W10**, both internal
contradictions of the same class as R086 — which I had split out to S3 while
leaving these at S4:

- **R088** (`decisions/input.md:192`) — Decision 3's *Why* argues for one shared
  instance on memory grounds ("forbids allocating a fresh object graph per input
  session"), while the same file's Implementation note (`:716-718`) states
  "Multiple `UserInputController` instances remain required… and would be
  clobbered by a single shared instance". Four instances exist
  (`main.lua:371`, `consoleController.lua:43`, `editorController.lua:12,16`).
  The owner's remark says exactly this: the prose was pre-implementation
  vision. **S3.**
- **R081** (`decisions/input.md:120`) — Decision 2 says "one chain of three
  components" scoped to keyboard/text, but pointer runs the *same* `dispatch`
  minus the shortcuts tier. As written, a reader concludes pointer is outside
  the chain shape entirely. **S3** — a completeness gap in what a permanent doc
  claims about routing, not a wording preference.

### **[REV] W9 hard constraint: tombstone decisions, never renumber**

This was missing and it is the one genuine "silently invalidated by a later
phase" risk in the plan. **179 comments cite decisions by number** — 69 in
`src/` across seven files and **110 in `tests/`**. Striking Decisions 6, 7, 12,
15, 16 by deleting their sections would renumber everything above the lowest
deletion, invalidating an unknown subset of those 179 citations, each of which
would still read as authoritative.

`decisions/input.md` already holds the safe precedent: Decision 11 was retired
**in place** — number kept, content marked *"SUPERSEDED IN PART, 2026-08-03 —
see Decision 25"* (`:483`). **W9 does the same: numbers are permanent,
content is tombstoned.** This is a constraint on execution, not a preference,
and it is stated here so P10 does not improvise it.

**R168 is a correction to us, and it is right:** `gfx` is not an undeclared free
variable, it is the house alias convention (`agents/rules.md`, "Standard
aliases"). Remove the tech-debt entry.

**R172 (three named API surfaces) is accepted** and pairs with R057/W8 — the
guide, the internals doc and the test suite should use one vocabulary.

### W10 — Editorial · **S4**

**Members:** the remaining 92 ids (Appendix A). Four batches, each one decision
applied N times:

1. **Retire "overlay"** (~17 remarks) → "input widget", or
   `input_widget_overlay` where the console context genuinely needs the word
   (R002). One pass, judgment per site, then a grep for stragglers.
2. **No historical contrast** (~10 remarks) — "no longer", "any more", "used
   to", where the thing being contrasted against is an intermediate shape that
   never shipped. Owner's rule: **if it was not in a released version, write as
   if it never existed.** This is the highest-leverage batch and it is also a
   rule worth stating in `agents/rules/commenting.md`, which already forbids
   narrating history outside an interim marker.
3. **Comment bloat** (~50 remarks) — this is step (e) of the commission, and it
   is now governed by `agents/rules/commenting.md` as rewritten this session.
   Deliberately deferred to its own late pass: comments must be cut *after* the
   code stops moving, or the work is done twice.
4. **Vocabulary** — "callbacks" not "widget-output entries" (R013), "test
   cases" not "rows" (R062), "reserved binding" (R010).

### W11 — Examples and the three nested repos · **S0/S2**

**Members:** R118, R120, R123, R124, R125, R183, R184, R185, R186, R187, plus
the smoke-test findings, which have no remark ids and get their own:

| id | finding | severity |
|---|---|---|
| SM1 | paint: right-clicking a colour does nothing | **S0** — needs W2 (button in combo) or a `mousepressed` hook that reads the button |
| SM2 | sapper: inactive console input strip visible at the bottom | S2 — cosmetic, owner asked "any chance to not show it" |
| SM3a | maze: nav symbols glitch when launched **from another project** | **S0** — owner's hypothesis (2026-08-07): maze switches fonts, and the switch probably only takes on a first start, not after another project. Check font state across a project→project transition before assuming a route bug |
| SM3b | maze: Ctrl alone dims the screen | S2 — owner: likely maze's own UX bug, not the platform. Not critical, but **pin it** rather than leave it unexplained |
| SM4 | keyboard: Ctrl+Alt+arrow difficulty switch does nothing | **S0** — a three-modifier chord; likely a combo-serialisation gap |
| SM5 | keyboard: subgame 4 "alt keys" shows a key and does not react when pressed | **S0** |

SM3–SM5 are in repos we migrated, so they are ours by the standing ruling
(§5 of the assembly guide: *a consequence of our API change is ours to
finish*). SM4 in particular is a platform-behaviour suspicion, not an example
bug, and must be reproduced as a platform test first.

### W12 — Comment sweep, then reassembly · **S4**

Commission steps (e)–(9): sweep every comment in slice scope against
`agents/rules/commenting.md` via a sub-agent, regenerate slices, cold
revalidation of groups 3 and 4, autofix, regenerate, second cold revalidation
presented to the owner unfixed. Unchanged from the commission; sequenced last
because everything above moves the code.

---

## 3. What I recommend NOT doing

Stated explicitly so declining is a decision rather than an omission:

- **R080** — widget as an ordinary chain element (W6). Reasoning above.
- **R121/R122** — removing `after_submit` or forbidding callbacks in `show{}`
  config. A second contract change with no defect behind it, and the remark
  argues both sides.
- **R017's "why not a separate file at all?"** — extracting `show`/`hide` into
  first-class functions: yes. A new module: not in this PR; file moves make
  every slice harder to review for no behavioural gain.
- **R030** — re-firing clicks after drift. Answered as documented behaviour;
  changing it is post-PR.
- **R181** — `before_exit` suppressing the stop.

---

## 4. Execution plan

Each phase ends green, stated, and committed. Production fixes are their own
commits with their breaking test first.

### [S37] Step numbering — cascading, not sibling (owner directive, 2026-08-11)

A step that turns out to hold several tasks **keeps its number and gains
children**: `P18` decomposing into five tasks makes them **P-18-01 … P-18-05**,
not five new sibling steps. **`-00` is reserved for the step's own initial
analysis/planning pass.**

The point is that the hierarchy expands without spawning isolated cycles: five
siblings would each need their own ordering ruling against the others, which has
been this sprint's recurring cost. A child inherits its parent's ordering and its
dependencies; only what differs is stated on the child.

Existing single-level ids (`P9b`, `P14e`, …) are **not renumbered** — they are
cited in frozen prompts, tracks and commit messages. The scheme applies going
forward.

**Status, 2026-08-07 (P0–P6 complete).** The P1 gate was resolved without
escalating, per the owner's standing instruction to escalate only what advisors
cannot settle: W2's vocabulary by the owner's own R115, `before_exit` by the
unguarded teardown, R080 by two independent confirmations, Decision 9 by the
tombstone rule. Two things changed under owner challenge after they landed, and
both are recorded in the ledger rather than only here:

- **Decision 26 supersedes the payload shape twice over.** W1 dropped
  `keys_pressed` *and* `scancode`; the owner asked why scancode was going and the
  answer did not hold — pointer channels already pass LÖVE's list verbatim,
  `istouch` and `presses` included, so dropping scancode made `keypressed` the
  one exception to a rule the system already had. Restored; the fix deleted the
  gateway's last special case.
- **Decision 27 gained the button as a trigger.** The plan recommended
  modifier-only combos with the button read from the payload. The owner
  challenged it: that argument applies verbatim to the keyboard, where the key
  also arrives as an argument and is a trigger anyway, so taken seriously it
  abolishes the shortcuts tier and restores `if button == 2` — the string-tag
  dispatch `agents/rules.md` forbids. `shortcuts.mousepressed['mouse2']` is a
  right-click now, and it is the mechanism SM1 needs.
- **Derived clicks keep `(x, y)`** (owner ruling): they are not LÖVE events and
  have no stock shape to converge on, so they name no button and take modifier
  classes only.

**The pattern in both corrections is the same** and worth carrying into the
remaining phases: an argument of the form *"X is already available elsewhere, so
it need not be here"* proves too much. It was wrong about scancode and wrong
about the button. Check what else the system already does before invoking it.

**A third correction, and a different lesson (owner, 2026-08-07 — Decision 28).**
`before_exit` produced three defects in one session: a nil hook and a raising
hook each abandoned teardown from its first statement, and the second was still
open after the first was "fixed". Each fix guarded the call site, which left the
guarantee as a property of that site's current code. The owner's ruling replaces
it with a structural one: the framework owns a teardown function,
`framework_before_exit`, and the project's hook is called from inside it — no
dispatch, one invocation point, no return value in flight for a later edit to
start honouring. **The generalisable rule: when a guarantee has failed twice at
the same call site, the fix is to remove the site's discretion, not to guard it
again.** Applies to anything remaining that a project can reach and the framework
must not let it steer.

Also intended by that ruling: the framework now has a named seam for teardown of
its own, which is where the force-reset of dirty global device state goes when it
is built (`technical_debt/input.md`, "A project that raises leaves global device
state dirty").

| # | Phase | Depends on | Gate |
|---|---|---|---|
| ~~P0~~ **DONE** | Answer the S0s: verify R044, R068, R033/R171 against `3256aac` and the current tree (**done** — `../notes/S27-P0-evidence.md`); reproduce SM1, SM3, SM4, SM5 | — | evidence note on disk before any fix |
| ~~P1~~ **DONE** | Owner rulings: W2 (confirm modifier-only + `mousepressed` only), W5 (`before_exit` veto — recommend no), W6 (R080 **and R044 together**), W1 (Decision 9 — delete or tombstone) | P0 | **blocks P2** |
| ~~P2~~ **DONE** (`c4f5a92f`, corrected by `a1952721`) | W1 — signature unification, incl. `ignore_repeat` **and `examples/keyboard/input.lua:142` by name** | P1 | breaking test first; the keyboard regression is silent, so it needs its own row |
| ~~P3~~ **DONE** (`069b93e9`) | W3 — one event list, seeding and wipe generic | **[REV] none** | independent of W1 — nothing in W3 touches the payload |
| ~~P4~~ **DONE** (`5d144f37`, extended by `1a414dbb`) | W2 — pointer shortcut tier | P1 | **[REV]** independent of W1 too: pointer already dispatches with `trigger = nil` |
| ~~P5~~ **DONE** (`15679f9d`) | W5 — `before_submit` veto + callback defaults | **[REV] P1, P2** | `before_submit(keys_pressed)` is the parameter P2 removes — **write its tests after P2**, not before |
| ~~P6~~ **DONE** (`bb6569a2`) | W4 — dispatch/wiring collapse | P2–P5 | behaviour-preserving; suite is the proof. `hook_pointer` is renamed, not deleted |
| ~~P7~~ **DONE** | W7 — controller structure + the 16-line rule | P6 | see commits `99f883d0`…`75c0d9ea` |
| **P7b** | **Teardown ownership** (owner, 2026-08-07) — Decision 28 | P7 | **DONE** (`ab2d45eb`) |
| ~~**P8**~~ **DONE [S33]** | W8 — test restructuring. **PART DONE [S28]**: R058/R059/R060/R061 (tracer + matrix supersession), R067 (NFR narrowing), R068 (blind row), R070 (before_exit contract). **[S33] The remaining nine were walked and are ALL DISCHARGED** — `../reviews/S33-p8-walk.md`, per the owner's ruling to walk rather than re-baseline. R047 implemented (`64ac38d0`), R057 landed as the three named surfaces, R063 declined with the evidence written into the file (`1aa01572`), R069 answered *against* the remark (`53abd09e` — the proposed assertion is false), R064/R074/R075/R078 landed as the merge (four specs → two), **R079 answered by rewrite** (`ae176dd1`, with a coverage gap filled and mutation-checked). §6's claim was right; this row was stale; and the "R079 is still open" reading was a **planning-table phrase inherited without checking the commits** — corrected in the walk | P2–P7 | **[S33] closed.** Its purpose as a gate on P14c is discharged, and what it found for P14c is folded into that step |
| P9 | W11 — examples and nested repos, one commit per repo | P2–P5 | **[REV]** the three nested repos carry **no automated tests** — one static spec doc, no runnable suite. Committing is not verification: a smoke re-pass on the channels W1/W2/W3 touch is the gate, `examples/keyboard` at minimum. Never pushed. **[S28] PART DONE** — SM1/SM2 ruled no-change, SM3b explained, SM4 pinned by a suite row, SM5 fixed (`3a9d48c`); SM3a left open, needs one runtime check. Evidence: `../notes/S28-smoke-findings.md`. **[S33] The owner sanctions `xvfb-run` for that check (2026-08-09)** — *"if it is available in the container and if it helps"*. **Both confirmed:** `/usr/bin/xvfb-run` and `/usr/bin/Xvfb` are present, and `xvfb-run -a love src` was used in this session to boot the app headless after the probe deletion. The check is: print the font identity at the start of two consecutive maze runs, with another project run in between, and see whether it changes. **It is a diagnostic, not a fix** — the note is explicit that fixing state-reset code on an unreproduced hypothesis is how the `wrap_handler` mistake happened. **[S34] RUN, 2026-08-10 — the hypothesis does NOT reproduce** (`../notes/S34-sm3a-runtime-check.md`). Driven through harmony (the only way to get two runs in one process): maze → another project → maze, printing the legend font at each maze run. **Same font object, same height, same glyph coverage, same legend width, and byte-identical screenshots** — including with `clock` in the middle, which sets a 172px font and never restores it. The symbols are `legend.txt`, drawn by `draw_legend` with the **ambient** `gfx.getFont()`, so the hypothesis was structurally plausible; what stabilises it is that **the console draws between runs and sets its own font every frame**, which is a consequence of the return path rather than a stated guarantee. Not confirmed and **not closed** — the observation was made interactively and only two intervening projects were tried; it must not authorise a state-reset fix |
| **P9b** **[S36] ABSORBED INTO P18** | **[S36] The keyboard deepfix carries this step** (owner, 2026-08-10): both rewrite `examples/keyboard/input.lua`, so they became one step with one planning pass — see §15.4. **This row is NOT superseded and is not deleted**: it stays as the heal's history, its dependency record and the pointer to its design of record, and everything below still governs how the heal is done. **[S36] The absorption is total** (owner correction, same day): P18 plans both halves in one pass, imposes no order between them, and **may revise this heal's design** — `internals/examples/keyboard.md` is an input, not a frozen mandate, and the owner has said so. A revision goes into that document with its reasoning before the code assumes it. ~~An earlier draft required the heal to land first, committable alone, with its design not reopened; that was overruled — see §15.1b.~~ What survives is scheduling **between** steps: this work blocks the sprint's closure, so it precedes the optional onboarding elsewhere. — **[S35] WHAT THIS IS, corrected (owner, 2026-08-10): a defect in its own right, NOT a part of the `keys_pressed` retirement.** The `textinput` ordering bug exists independently of Decision 30, predates it, and would need fixing if the dissolution had never been proposed. It blocks **the closure of this sprint** — which is a spinoff of the parent's Phase TF2, whose goal is clearing known defects before release (§0) — not the closure of the dissolution. **The orderings below sequence it against the dissolution; they do not make it part of it**, and the phrase *"the reason the sprint exists"* used elsewhere in this document overstates it: this sprint exists to clear 187 triaged remarks, of which this is one, and the most consequential. **[S34] RUNS AFTER THE TESTS AND THE PLATFORM CODE (P14c, P14d), IN ITS OWN SESSION (owner ruling, 2026-08-10)** — extending, not replacing, the [S33] ruling below. The owner's reasoning: *fixing D against outdated platform logic would be conceptually wrong even where the two do not overlap.* P9b would otherwise be designed against a matcher and a held-key surface that the sprint is in the middle of removing. **[S35] RUNS AFTER THE EXAMPLES STEP TOO (owner ruling, 2026-08-10)** — the question below is now closed, the same way it was opened: the examples step edits the very file P9b rewrites, so P9b reasons against a reconciled file rather than one mid-move. **Sequencing is now P14a → P14c → P14d → P14e → P9b.** ~~Open and NOT ruled: whether the examples step (P14e) must also precede it — it edits the very file P9b rewrites (`examples/keyboard/input.lua`), so the same argument applies more directly there than anywhere else; raise it before P9b starts.~~ **[S35] RULED — see §14.3.** **[S33] RUNS AFTER P14a, IN ITS OWN SESSION (owner ruling, 2026-08-09).** Two reasons, both the owner's: the fix **requires a design decision and the validation of that decision**, which does not belong inside a session already carrying the dissolution; and its design reasoning must be done **against the currently-approved design**, so the docs step lands first rather than leaving P9b to reason from prose that still teaches the superseded model. Not deprioritised — it is still the reason the sprint exists. **keyboard: judgement decoupled from delivery order** (owner design, 2026-08-07). **[S29] The design was rewritten on 2026-08-08 and the old one discarded** — see §7 amendment 3. Now: `textinput` is the **only** judge; two fields (`lastText`, `blocked`); writes blocked across the win transition; `keypressed` feeds the non-printing targets into the same judging function; `keyreleased` holds no judgement state; **no clock, no grace window, no held-set read**. Subtracts `spendGlyph`, `GLYPH_CLAIMED`, `INPUT.upRecent`, `INPUT_UP_GRACE` and `altPlayKey`'s judging path | P9 | design of record, in the **persistent** corpus: `doc/development/internals/examples/keyboard.md`. Nested repo, **no suite** — reasoned, not proven; smoke checklist is in the design note. No platform change, and **[S29] no game-side change either** — `gaugeCandidates` already excludes `st.cur`, so back-to-back identical targets are prevented today; the design records it as a precondition rather than asking for one |
| **P9c** | **[S29] The two order-dependent rows this feature owns** (owner, 2026-08-08). Under `--shuffle`, `inbound events — Ctrl+Esc quits the app when nothing is left to go back to` and `inbound events — shortcuts and clicks — a shortcut fires but does not consume (#disputable)` fail. Find what state each depends on and who leaves it; fix or document per test case. **[S33] Say "test cases", not "rows"** (owner, 2026-08-09) | **[S33] P9b AND P14c** — moved: P14c deletes and relocates test cases in these very files, so running this before it would characterise state that is about to change | **before the PR.** The suite-wide order dependence is separate and pre-dates the branch — filed as persistent debt (`technical_debt/general.md`, "The test suite passes only in declaration order") and explicitly **not** in scope here. In scope: only rows this branch adds |
| ~~P9d~~ **WITHDRAWN [S32]** — Decision 30 dissolves the set; see §11.3 | **[S29] Clear `keys_pressed` on focus loss** (owner, 2026-08-08). A key released while the window is unfocused never delivers its release, so the set goes stale and nothing clears it: a combo can carry a modifier nobody is holding, and a renderer polling the set draws a cap lit for ever. The gateway installs no focus handler — its callback table marks focus SKIPPED | — | **Before the PR.** Code, so it lands before P10's prose. Breaking test first; recorded meanwhile in `technical_debt/input.md`, "The held-key set is never cleared on focus loss", which is deleted when the fix lands |
| ~~P9e~~ **WITHDRAWN [S32]** — premise inverted: gate polling is now correct; see §11.3 | **[S29] The gateway's own gates read the event set, not the device** (owner, 2026-08-08). `handlers.keypressed` / `keyreleased` gate power shortcuts on `Key.ctrl()` / `Key.alt()` / `Key.shift()` — a device poll — while `dispatch` beside them builds combos from `keys_pressed`. Decision 29 settles that an event-time question is answered from the event-tracked set; the gateway does not follow its own rule | P9d | **Before the PR.** Code, so before P10. Separate commit from P9d — same file, two concerns. Recorded meanwhile in `technical_debt/input.md`, "The gateway asks the device a question about an event". **[S30] This row breaks the `harmony` scripting mode** — harmony fakes modifiers by patching `love.keyboard.isDown` and never injects modifier *events*, and its `shortcuts.toggle = 'C-t'` drives precisely this `quickswitch` gate. Harmony is outside `busted` and outside CI, so **nothing signals the breakage**. Do not land P9e without reading §10 and sequencing P13 |
| P10 | **[S36] PART DONE, 2026-08-11 — the flag-shortcut member below is DISCHARGED**: §"Shortcuts that set a flag" was **replaced** by §"Choosing the mechanism" (`563b937f`), which states which mechanism answers which question, shows the mirrored pair as a DON'T, and carries Decision 32's no-reconstruction rule; six citations of the old heading were repaired, one of them in the register where it had recommended the antipattern. **Decision 32 landed** (`81e97bab`) with **Decision 30 point 3 amended in place**, and the adoption checklist went to `conventions/input_adoption.md` (`82979e55`). **[S36] Two factual defects found by the disposition pass, neither previously flagged by any marker:** the ledger called the `before_submit` veto *"(still-reserved, unbuilt)"* when it is built and documented (`userInputController.lua:405`, guide §"Submit lifecycle") — **corrected 2026-08-11**; and `internals/event_dispatch_layers.md`'s pointer/keyboard asymmetry passage is reported stale against the register's own *RESOLVED 2026-08-03* entry — **claimed, not yet verified by me, verify before editing**. **What this row still owes:** the reserved-combo section the guide has never had (the P15 row enumerates the set), W9's ledger work, W10 batches 1/2/4, and **the marker question of §16.2, which is this row's real size** — 8 markers in the project guide, 30 in the ledger, 33 in the internals guide. **[S36] NEW MEMBER, and it is a defect in a teaching passage, not a wording one: `doc/input_api.md` §"Shortcuts that set a flag" teaches a pattern whose clearing event can be missed.** Its example binds bare `'space'` on `keypressed` and `keyreleased`; press Space, then press Ctrl, then release Space, and the release serialises as `'ctrl+space'`, so the clearing binding never fires and the flag stays set. The same failure with a modifier in the combo (`'alt+h'`) is **unfixable by any second binding**, since a modifier's own release has no expressible combo (Decision 21). **The section needs the boundary stated — a combo serves an atomic transition, not a held state** — and its example needs either a class-key clearing path or an honest note that the flag is armed by an event and must be cleared by something that cannot be missed. Reasoning and the sketched general mechanism are in `technical_debt/input.md`, "A chord that gates a state while it is held has no vocabulary". Found in session36 while answering why the keyboard example's help overlay still polls | W9 + W10 (1,2,4) — docs, ledger, vocabulary. **[S33] REDUCED — its Decision-30 slice is pulled forward into P14a** (the project-facing "Held keys" rewrite, the flag-shortcut teaching, the `:268` false claim, the debt register, the Decision 21 tombstone). **What remains here:** the W9 ledger work and W10 batches 1 (retire "overlay"), 2 (no historical contrast) and 4 (vocabulary). **[S33] New members found by session32:** `doc/input_api.md` §"Held keys" needs **replacing, not purging**; Decision 21's worked example is stale — it says a hook "receives the held-key view", which Decision 26 already removed. **[S35] One more member, found while commissioning P15: the project-facing guide never says which combos the framework has already taken.** It teaches `shortcuts.keypressed['ctrl+s'] = ...` as an example while the gateway itself claims `ctrl+s`, and claims `f10` — a **bare, unmodified key** — whenever profiling is on. A project author reading only this guide cannot know which of their bindings will never fire. The reserved set is enumerated in the **P15** row; this step gives it a named section in the guide | P2–P9, **[S33] P14a–e** | docs describe the final code, so they come after it. **Tombstone decisions, never renumber**. **[S29]** Decision 29 and the `input_api.md` "Held keys" rewrite landed early by owner instruction — do not redo them |
| P11 | **[S36] THE GATE'S OWN PATTERN IS INCOMPLETE — found 2026-08-11 and fixed at once.** Two markers spelled `REMARK` **without the colon** (`internals/event_dispatch_layers.md`, `internals/user_input.md`), so `grep -rn 'INTERIM:\|REMARK:'` returned clean while they stood. Both were normalised to carry the colon — punctuation only, their text untouched — and **the gate must be run as `grep -rniE 'INTERIM|REMARK'` at least once before it is trusted**, since a gate that cannot see a marker is worse than no gate. Doc-corpus count therefore **86, not 84**. **[S36] MEASURED, 2026-08-11: 27 markers in `src/`+`tests/` and 86 in the persistent doc corpus (113 total).** The gate as written demands zero; **§16.2 puts three readings of that gate to the owner and recommends one** — clear code and the project guide entirely, clear everything factual in the dev-facing docs, and defer the purely editorial remainder as a **named list** rather than as silence. Until that is ruled, this row's size is unknown, and it is the largest block left in the sprint. — W12 — comment sweep, slices, revalidation ×2. **[S33] W10 batch 3 (comment bloat, ~50 ids) belongs here, not P10** — deliberately deferred to a late pass so comments are cut after the code stops moving. **That subset is never separately enumerated inside W10's block of 92 and must be re-derived first** | P10, **[S33] P14a–e** | the commission's (e)–(9). **[S33] the gate is currently FAILING: `grep -rn 'INTERIM:\|REMARK:' src/ tests/` → 22 in the platform and 5 in `src/examples/` (disjoint sets, 27 total; zero `INTERIM:`). It must return nothing before slice regeneration.** **[S33] The gate also covers `PENDING` markers** — including in `doc/`, which the marker sweep has never had to scan before, because P14a puts them there deliberately |
| ~~**P14a–e**~~ **DONE [S36], 2026-08-10** | **[S36] The dissolution is complete: P14e landed in five commits across three repos (§11.4.3's execution note), platform suite 942 / 0 / 0 / 10.** What it declined is enumerated in the persistent debt register and is P16's input. **P9b is next by the standing ruling.** — **The dissolution itself** — docs/spec → tests → platform code → examples, enumerated in §11.4. **[S35] The dissolution ends at P14e.** P9b follows it by ruling but is **not a fifth part of it** — it is a defect of its own that blocks this sprint's closure (see P9b's step). **[S35] P14e is rescoped** to the **three detached example repos** (keyboard, maze, balloons) **and the in-repo examples**, reconciled with the removal and with the corrected recommendation ladder, and it **now precedes P9b** — sequencing **P14a → P14c → P14d → P14e → P9b**. **P14e's operative detail is §11.4.3**, factored out when its row outgrew the table; the dated reasoning for all of session35's amendments is §14. **[S35] The spec itself was corrected before the tests were written** (owner, 2026-08-10): `Key` is the project-facing answer and `love.keyboard` the last resort, and `gui` is removed outright rather than completed — so P14a is reopened for those two edits, and the `gui` decision P14d was carrying is **closed by removal**. **[S33] P14b is RULED** (matcher shape (b), owner 2026-08-09), so a–e are all unblocked. The mock's variadic fix lands first, inside P14c, as its own commit | P8's walk before P14c | §11.4 holds the contents; §11.5 holds the ruling and its costs. Ordering deliberately reverses this table's rule — see §11.2 |
| **P16** **[S36] ONE RULING + ONE READY ITEM** | **[S36] READY, inspected 2026-08-11, not yet executed: `paint`.** It registers `compy.input.hooks.singleclick`/`.doubleclick` explicitly and then declares `love.mousemoved` and `love.keypressed` as globals twenty lines below — the same purpose in two spellings in one file, which is what the guide now tells authors not to do. Converting the two to `compy.input.hooks.*` is mechanical and behaviour-identical (seeding produces the same wiring), and it makes `paint` a referential example of the registration surface. **Caveat to state in the commit:** its `love.mousemoved` polls `love.mouse.isDown(btn)` for the drag — a **mouse** poll, correct as continuous state under Decision 32.4, and untouched by this (`Key.any_pressed` is keyboard-only). **`balloons` was inspected and DEFERRED** — its remark's API half is declined and already satisfied in-project, its simplification half is not demonstrative; both recorded in `technical_debt/input.md`. | **[S36] 2026-08-11: the sweep is spent.** `pong` moved onto `Key.any_pressed` (`c04cbedf`), `clock` was ruled NOT to convert with the reason in the file (`dad70c30`), `turtle` is unchanged **by ruling** (the standing demonstration of the captured `love.*` path), `balloons` was verified clean twice, and the keyboard example's `helpHeld` entry was **inverted by Decision 32** — its poll is correct and the entry is closed, not deferred. **What remains is a single owner ruling:** delete `turtle`'s `ctrl+escape` binding as redundant, since the framework reserves that combo and acts on it without consuming, so both fire to the same end. — **The common sweep — the in-repo examples and `balloons`** (owner, 2026-08-10; **redefined the same day from a single onboarding step, §15.1b**). Works the deferred list P14e wrote into `technical_debt/input.md`, §"Examples are not onboarded onto the new input API" — **that register section is the input and the only input**, so this is not the blanket example sweep that was ruled out. `balloons` is in scope and expected to be a no-op (verified twice as reading no held state); it is named so the coverage is complete. **The escalation rule is what makes it safe to run as a sweep: if a design-heavy decision surfaces in any example, that example gets its own deferred step** — the sweep records it and does not decide it. **Operative detail: §15.2** | **P14e**, which wrote this step's input | **Ordering free** — the file that made ordering a question belongs to the keyboard example, which is no longer in this step |
| **P19** **[S36]** | **The sapper deepfix — the escalation rule's first firing** (owner, 2026-08-10). P14e's conversion of its modifier cascade **was reverted** (`f61ada67`): the shape reading was right, the purpose reading was wrong, and the purpose was recorded nowhere — the modifier-held **press** is a **touch fallback**, where derived clicks are exactly the mechanism it bypasses. The step decides whether to convert at all, and how to close the residual hole if it does; input is the register entry *"sapper's modifier click path is a touch fallback…"*, not the row. **If the answer is "the platform carries the press's modifiers", that is release-shaped and gets PROMOTED to the parent plan, not done here.** In-repo example, but **another author's** — wants their eyes. **Operative detail: §15.2b** | P14e (which reverted into it) | Independent of P16/P17/P18 |
| **P17** **[S36] runs AFTER the upstream pull (§16.3)** | **The maze deepfix** (owner, 2026-08-10). `src/examples/maze` needs more than a rung correction — a `tab` poll with a mirrored flag deriving an edge, two bindings written as one Escape guard, and the macro recorder's own Shift mirror. **Its own planning pass before any code moves.** Detached repo: own remote, **no suite**, smoke by hand is the only gate, **never pushed**. **Operative detail: §15.3** | P14e | Independent of P18 — they share no file, either may go first |
| **P18** **[S36] runs AFTER the upstream pull (§16.3)** | **[S36] Its onboarding half SHRANK under Decision 32:** `helpHeld`'s poll is correct and stays, so what remains is `alt.lua`'s hand-matched Ctrl+Alt+H (a transition, so a shortcut — Decision 32.1), `isMod`'s duplication of `Key.is_mod`, and the owner's intent to dissolve the `INPUT` proxy, which is now a pure alias. — **The keyboard deepfix, which ABSORBS P9b (the `textinput` heal)** (owner, 2026-08-10). One step, because both halves rewrite `examples/keyboard/input.lua` and sequencing them against each other was an open question this removes. **One planning pass covering both halves, and no ordering imposed between them** (owner correction, 2026-08-10): they change the same internal architecture, so sequencing them inside the step would re-create the churn the absorption removes. **The heal's design of record — `internals/examples/keyboard.md` — is an INPUT and MAY be revised here**; it was written before the onboarding facts were known. A revision lands in that document, with its reasoning, before the code that assumes it. Detached repo, **no suite**, **never pushed**. **Operative detail: §15.4** | P14e; **inherits P9b's own dependency** (it runs after the platform code, which is done) | **This is what blocks the sprint's closure**, so it is scheduled **ahead of** P16 and P17, which are optional. Independent of P17 |
| ~~**P15**~~ **DONE [S35], 2026-08-10** | **The framework's own shortcuts get a suite** (owner, 2026-08-10) — **landed `46952e4c`**: two live cases (`ctrl+pause` route-preserving, `ctrl+q` route-destroying) plus **7 `pending`** outlines; suite 940 → **942 / 0 / 0 / 10**. The worker corrected the enumeration on one point: **`f10` has no modifier gate at all**, so it is claimed in every modifier combination, not only bare. — a coverage gap spotted while reviewing the tests step, and confirmed against the code: the gateway reserves ~9 keyboard combos and **three are tested**. `ctrl+pause` has one case, `ctrl+alt+r`/`ctrl+q` appear only as *play-mode narrowing*, `ctrl+escape` has two cases in `project_open_liveness_spec`. **Untested: quickswitch (`ctrl+t`, both app-state branches), `ctrl+s` (stop run / close buffer / `ctrl+shift+s` finish edit), `ctrl+q` in dev, `ctrl+shift+r` reset, `ctrl+alt+r` in dev, the profiler pair, and `f10`** — which is a **bare, unmodified key** the framework takes whenever `love.PROFILE` is on. Nothing anywhere asserts the second half: **that a project registering the same combo cannot take it away.** Additive, in a new `tests/input/input_global_shortcuts_spec.lua`; the four existing cases are **not moved or rewritten** (two of them are P9c's order-dependent pair). Commissioned to a Sonnet worker, prompt of record `../prompts/S35-global-shortcuts-suite.md`, report `../outcomes/S35-global-shortcuts-suite.md`. **The trap it must not fall into is written into the commission** — see §14.6. **[S35] SCOPED DOWN by the owner, 2026-08-10, and the reasoning changes what the step is:** the gateway does **not** suppress a project's binding at all — the only way a project handler fails to run is a **side effect** of a platform action (the route being torn down). So the one property that needs pinning is **that a project cannot suppress a platform combo by naming it**, and that is the whole live content of this suite (two or three representative combos, at least one route-preserving and one route-destroying). **Asserting each combo's own effect is the framework's business and is NOT this PR's duty** — those become **`pending` outlines**, one per reserved combo, each naming in one line the effect a later test would assert. **This deliberately raises the suite's pending count above 3** — a change the boot ritual otherwise treats as a finding, so it is stated here, in the commit, and in `doc/development/tests.md` | independent of P14; **runs before P14d** so the platform step has the net | **Owes a justification-table line** (§11.7): this is coverage the 187-remark mandate did not ask for, and a stakeholder will ask why the PR grows a suite — the answer is now smaller and easier to give, since what lands is one property plus a list of named gaps |
| **PROBE** **[S33]** | **Delete `src/probe/input_probe.lua`.** Its own header: *"DIAGNOSTIC, TEMPORARY. Delete when the polling-vs-tracking question is ruled on."* Decision 30 ruled it. Postdates `3256aac`, opt-in, not on the dispatch chain | — | **its own commit.** Unblocked now; listed as a step because it was previously placed only in §11.4's prose, with no id and no row |
| ~~P12~~ **PROMOTED [S32]** → `../plan.md` **Phase U** (owner, 2026-08-09); id kept, §8 stands | **[S29] Upstream reconciliation and downstream compatibility** (owner, 2026-08-08). Reconcile this branch against the advanced upstreams — the platform repo (and possibly an advanced fork of it) **and** each example repo — then land the coordinated set of PRs | P11 / close-out of the current snapshots | **Blocks the real PR, and needs its own plan.** Not attempted before the snapshots are stable: re-planning against a moving upstream while the design is still settling means doing it twice. See §8 |
| **P13** **[S32] REDUCED TO REVALIDATION** (owner ruling, 2026-08-09) — harmony can now drive combos; §11.3 | **[S30] Harmony reconciliation** (owner ruling, 2026-08-08). `src/harmony` is a scripted-automation mode carrying a **second implementation of the input surface** — its own `love.run`, its own held-modifier table, its own patched `love.keyboard.isDown`. It fakes modifiers to the *poll* and never puts them in the event stream, so every event-side change this feature makes is invisible to it. Inject real modifier `keypressed`/`keyreleased`, **keep** `patch_isDown`, retire the manual `release_keys()` discipline, and build the batch-skew reproduction rig | P9e (which breaks it); independent of P10–P12 | **Own phase, and in the release** — not a platform blocker, but shipping a platform input change that silently breaks the bug-reproduction harness is the loss this row exists to prevent. Like P12 it is **someone else's subsystem** (aldum) and eventually needs them in the loop. See §10 |

**[S33] This table is the single operative list (owner ruling, 2026-08-09).** It had drifted
into a summary while the real state lived in the amendment sections below: session28 declared
an amendment to P8 in §6 and never wrote it into the row, and session32 re-lettered the P14
steps and swept §11.4/§11.5 only. Both times a later session read the stale row and built on
it. **The rule that replaces that: when a step is amended, the amendment goes in the step** —
§§6–12 remain as the dated reasoning behind each change, never as the place the change lives.

**The ordering rule behind this:** code first, tests second, docs third,
comments last. Every phase that moves code invalidates doc prose and comments
written before it; doing prose early means doing it twice. This inverts the
*commit* order (docs → tests → code) deliberately — that is the reviewer's
reading order, not the working order.

**Where this plan can go wrong:** P2 is breaking and touches every hook in the
tree including three repos we do not own the remotes of. If the owner declines
W1, P4, P6 and much of P7 lose their premise and the plan collapses back to
W7–W12. That is why P1 gates.

---

## 5. [REV] Revision log — what the cold reviews changed

Both reviewers worked without sight of this document's reasoning. Neither
raised a structural objection; both found real errors. Every correction below
was re-verified in code before acceptance — including the ones I agreed with.

**Accepted, from the fact-check (`../outcomes/S27-triage-factcheck.md`):**

| # | Correction | Where |
|---|---|---|
| 1 | **R135 was wrong** — the evaluator-objects claim is precise, not stale | W9, id → W10 |
| 2 | **R088 under-rated** — a live contradiction inside `decisions/input.md`, same class as R086 | W10 → W9, S4 → S3 |
| 3 | **R081 under-rated** — Decision 2's "three components" excludes pointer, which runs the same dispatch | W10 → W9, S4 → S3 |
| 4 | **`submit()`/`cancel()` do not exist** — the flows are `submit_flow`/`cancel_flow`, and a *different* `cancel()` exists that skips the veto entirely | W5 |
| 5 | **R110 mis-kinded** — a cut-stale-history ask, not a false claim to correct | W9 → W10 |
| 6 | **W2 spans three doc files, not two** | W2 |
| 7 | **`before_exit` is called unguarded** — no `pcall`; a raise aborts the rest of teardown | W5, R127 |
| 8 | **`hook_pointer` is not dead** — it installs nothing but still computes `user_pointer` liveness; its name is the lie | W4 |

**Accepted, from the plan review (`../outcomes/S27-plan-review.md`):**

| # | Correction | Where |
|---|---|---|
| 9 | **Decision renumbering would break citations** — tombstone in place. The reviewer counted 69 in `src/`; **there are 110 more in `tests/`**, 179 total | W9, P10 |
| 10 | **P5 depends on P2**, not P1 alone — same parameter, same method; its tests must be written after P2 | P5 |
| 11 | **Name the `examples/keyboard` regression** — `appKeypressed(k, _, isr)` breaks silently under W1 | W1, P2 |
| 12 | **Nested repos have no automated tests** — P9's gate must be a smoke re-pass, not a commit | P9 |
| 13 | **W2's button question is already answered by R115** — modifier-only, `mousepressed` only, presented as a recommendation | W2 |
| 14 | **P3 and P4 do not depend on P2** — nothing in W3 or W2 touches the payload W1 changes | phase table |
| 15 | **"Equal to LÖVE's" overclaims** — `scancode` is already discarded at the gateway; post-W1 it is `(k, isr)` | W1 |
| 16 | R080's decline confirmed independently, twice, with two facts I lacked | W6 |

**Rejected, or accepted with a change:** none rejected outright. #9's count was
corrected upward by my own check; #16's confirmation is treated as evidence for
the owner, not as a ruling — R080 is still the owner's call at P1.

**One methodological note for the record.** The `lua-lsp` MCP server was
**unreachable for this entire session** (broken pipe on every call, from the
parent and both sub-agents). Every reference and dead-code claim in this
document, the fact-check and the plan review therefore rests on `grep` alone —
the prescribed backstop, not the prescribed primary tool. `handlers.userinput`
(W4) is the one deletion that turns on a completeness claim; it should be
re-checked with the LSP before it is removed.

---

## Appendix A — id → workstream coverage

W1 R009 R036 R096 R097 R098 R099 R112 R114 R146 R176
W2 R037 R115 R131 R145 R152 R177
W3 R022 R027 R029 R030 R035 R154
W4 R021 R023 R024 R025 R026 R028 R031 R033 R171
W5 R038 R121 R122 R158 R160 R161 R181
W6 R044 R080 R086
W7 R004 R005 R006 R008 R011 R012 R014 R015 R016 R017 R018 R019 R020 R039
   R040 R041 R042 R043 R045
W8 R047 R057 R058 R059 R060 R061 R063 R064 R067 R068 R069 R070 R074 R075
   R078 R079
W9 R081 R088 R093 R094 R105 R107 R109 R127 R134 R165 R166 R167 R168 R169
   R170 R172
W11 R118 R120 R123 R124 R125 R183 R184 R185 R186 R187 + SM1–SM5
W10 every id not listed above (92): R001 R002 R003 R007 R010 R013 R032 R034
   R046 R048 R049 R050 R051 R052 R053 R054 R055 R056 R062 R065 R066 R071
   R072 R073 R076 R077 R082 R083 R084 R085 R087 R089 R090 R091
   R092 R095 R100 R101 R102 R103 R104 R106 R108 R110 R111 R113 R116 R117 R119
   R126 R128 R129 R130 R132 R133 R135 R136 R137 R138 R139 R140 R141 R142 R143
   R144 R147 R148 R149 R150 R151 R153 R155 R156 R157 R159 R162 R163 R164
   R173 R174 R175 R178 R179 R180 R182

**[REV] Moves in this revision:** R044 W7→W6 · R081 W10→W9 · R088 W10→W9 ·
R110 W9→W10 · R135 W9→W10 (answered, no action). Counts unchanged: W9 16,
W10 92.

---

## 6. [S28] Amendments made in session28

The phase table above is the running plan and is amended in place rather than
superseded, per `agents/validation.md` ("Revisions are made *with the owner
in-session* and materialized on disk"). Session27's own text is untouched;
everything session28 changed is marked `[S28]`.

| # | amendment | why |
|---|---|---|
| 1 | **P8 marked done.** R047, R063, R069 answered; R057 landed as three named surfaces; R064/R074/R075/R078 landed as the merge (four input specs → two) | executed 2026-08-07, plan + two cold reviews in `../reviews/S28-merge-plan.md` and `../outcomes/S28-merge-result-review.md` |
| 2 | **P9 marked part-done**, with each smoke finding's disposition named in the row | four of five closed from code at the owner's instruction; SM3a needs the app, which that pass excluded |
| 3 | **P9b added** — the keyboard judgement redesign | owner design given in-session after SM5's fix landed; it supersedes that fix rather than sitting beside it, so it belongs in the plan and not only in a note |

Two rulings from the same session that constrain later phases, recorded here so
a phase does not have to rediscover them:

- **R081's correction is wider than filed** (`../notes/S28-owner-concerns.md`):
  Decision 2's paragraph is stale twice over — the "three components" scope, and
  any claim that pointer channels have no shortcuts tier, which Decision 27
  retired. P10/W9 owns both.
- **`doc/input_api.md` states the two-channel ordering fact inside the
  echo-guard section**, as though it were a fact about opening a widget. It is a
  fact about the channels; a project meeting the other consequence of it has no
  signpost. P10 owns the restatement. **No platform helper** — one example's
  need is not an API.

## 7. [S29] Amendments made in session29

Same rule as §6: the phase table is amended in place, session27's and session28's
text untouched, everything session29 changes marked `[S29]`.

| # | amendment | why |
|---|---|---|
| 1 | **P9c added** — the two order-dependent rows this branch owns | found while revalidating the S28 merge (`../reviews/S29-merge-revalidation.md`): `busted tests --shuffle` fails these two among a few dozen. Owner ruled 2026-08-08 that the suite-wide condition is persistent debt and these two are a scheduled pre-PR look, kept separate so the branch is not asked to fix a pre-existing problem |
| 2 | **Decision 26 completed in code** (`5a83fe8c`) — no phase change, recorded because the ledger entry now describes the tree and did not before | revalidating the two production fixes (`../reviews/S29-production-fixes-revalidation.md`) found `handlers.keyreleased` narrowing LÖVE's list to the key alone: the last channel in the system not passing its arguments verbatim, against Decision 26's own rule and `doc/input_api.md`'s bold statement of it. Base-checked — Decision 26 widened `keypressed` and missed its pair, so the gap is the branch's. Owner ruled widen, 2026-08-08 |
| 3 | **P9b's design discarded and rewritten** (owner ruling, 2026-08-08). The old design is superseded in place in the persistent corpus; the P9b row above carries the new shape | Four-way comparison against the game's own history (`../reviews/S29-p9b-vs-original.md`) plus the design revalidation (`../reviews/S29-p9b-design-revalidation.md`) found it internally contradictory, its rule 4 unimplementable, its rule 5 inert, and — measured against the shipped interim fix — a **regression**: it reintroduced a live held-state read the shipped code had already eliminated. The owner's account: the paradigm and the table-as-state-model were their only original inputs; the rest answered self-inflicted corner-cases |
| 4 | **P12 added — upstream reconciliation** (owner ruling, 2026-08-08), with its rationale in §8 | recorded at the point the assistant got it wrong: it was first written up as a later nice-to-have and "explicitly not a PR blocker". It **blocks** — a platform upgrade that breaks a downstream project cannot ship without a compatibility PR to that project, and two of the three example repos are not ours. Deliberately sequenced after the current snapshots stabilise, and owed its own coordinated plan |
| 5 | **P9d added — clear `keys_pressed` on focus loss** (owner ruling, 2026-08-08) | surfaced while answering whether `keys_pressed` was the right instrument for discouraging direct `Key.*` queries (`../notes/S29-keys-pressed-as-deterrent.md`). The set is event-maintained and the gateway skips the focus callback, so it goes stale on an unfocused release — and `Key.*` polls the device and cannot, which is how the framework's own gates and the project-facing table come to disagree. Owner ruled: record as debt **and** fix before the PR |
| 6 | **Decision 29 ratified, and P9e added** (owner instruction, 2026-08-08) | the owner asked for the rationale behind the held-key set to be documented as a decision rather than left in a session note. Decision 29: the framework answers event-time questions from the event-tracked set, projects express chords through combos, and the direct reads stay as secondary channels. Written with the design half in `internals/user_input.md` and the project-facing half in `input_api.md`, whose "Held keys" section carried two false statements — that `lshift` means either shift, and that the table is passed to handlers, which Decision 26 retired. P9e follows from the decision: the gateway's own gates poll the device where the decision says the event set |

One finding from the same pass that is **not** scheduled, recorded so a later
phase does not rediscover it as new:

- **The merge widened one blast radius.** Four `Log.warn` monkeypatch-and-restore
  rows in `input_widget_control_spec.lua` came from two different source files and
  now share one busted-insulated file scope. All four restore before their own
  assertions, so no test can fail from it today; only an unexpected raise from
  `show`/`configure`/`clear` between patch and restore would leak, and then to
  rows it previously could not reach. Insulation is per-file — verified
  empirically, not inferred. No fix proposed: `finally` is used nowhere else in
  this suite, so guarding four rows against a bug that does not exist would be a
  suite-wide convention change bought for an ideal.

## 8. [S29] P12 — upstream reconciliation, and why it blocks

Owner ruling, 2026-08-08, recorded at the point the assistant got it wrong: this
was first written up as a later nice-to-have and "explicitly not a PR blocker".
**It is a blocker.**

**Why.** W1 changed a project-facing signature. A platform upgrade that breaks a
downstream project cannot ship without a corresponding PR to that project
establishing compatibility. Two of the three example repos are **not ours** —
`dsent/keyboard` and `nagydani/Compy-maze` — so "we fixed it in our checkout" is
not a state anyone else can consume. The platform PR and the example PRs are one
release, not four independent ones.

**What has moved underneath us.** The three nested repos in this tree are
snapshots pinned at the versions the feature was developed against:

| repo | local | tracking | remote |
|---|---|---|---|
| keyboard | `3a9d48c` on branch `newinput` | **none recorded** | `dsent/keyboard` |
| maze | `v3.4`, ahead 3 | `origin/v3.4` | `nagydani/Compy-maze` |
| balloons | `main`, ahead 4 | `origin/main` | `hleb-rubanau/compy-balloons` |

The owner reports upstream `keyboard` now carries **more minigames than this
snapshot has**. Nothing here has been fetched — the ahead-counts are against
last-known refs, and `keyboard`'s branch has no tracking ref at all, so its true
divergence is unknown from inside this tree.

**And it is wider than the examples.** The **platform** repo has advanced too,
possibly along an advanced fork. So the real PR reconciles on three fronts at
once — platform against its own upstream, each example against its upstream, and
the compatibility matrix between them.

**The part that is not a merge.** New upstream minigames were written against the
**pre-migration** input path. Re-integration therefore repeats the audit this
session ran — held-state reads at judging time, repeat inference, signature
arity — over scenes that **do not exist in this tree yet**. Session29's finding
that no *current* scene carries an `inputStale`-shaped defect
(`../reviews/S29-new-design-vs-original.md`, Part 5) says nothing about scenes
added since.

**Sequencing, and why it is last.** Stabilise the snapshots first — that is what
P9b through close-out are for. Re-planning against a moving upstream while the
design is still settling is how the work gets done twice; this session watched a
design accrete for exactly that reason.

**What P12 owes, at minimum:** its own coordinated plan (not a row in this
table); a fetch-and-diff of each upstream, authorised by the owner, since it
touches third-party remotes; the audit above over any new scenes; and a decision
on ordering — whose PR merges first, and what each says about the others.

**Carry it into the PR description's open questions.** The strategic frame says
the PR is reviewable from `doc/input_api.md` plus the description alone; a
reviewer who cannot see that downstream compatibility is a tracked, sequenced
obligation will reasonably assume it was missed.

## 9. [S30] Amendments made in session30

Same rule as §6 and §7: the phase table is amended in place, earlier sessions'
text untouched, everything session30 changes marked `[S30]`.

| # | amendment | why |
|---|---|---|
| 1 | **P13 added — harmony reconciliation** (owner ruling, 2026-08-08), rationale in §10 | surfaced from the owner's own question — *did the shadow held-table predate the feature, and is the feature recreating it a level up?* It predates it verbatim (`4203de7f feat: harmony`, present at PR base `3256aac`, `git diff 3256aac HEAD -- src/harmony/` **empty**) and is **not** a precedent: harmony's table fakes the device for *polling* consumers, where `keys_pressed` mirrors events. The owner's generalisation is the finding: harmony holds a second implementation of the input surface, so every system-wide input change either breaks it or needs matching changes in it |
| 2 | **P9e row amended — it breaks harmony** | `shortcuts.toggle = 'C-t'` (`src/harmony/init.lua:186`, used ×5 in `scenarios/editor.lua`) drives the gateway's own `quickswitch` gate, which is exactly what P9e converts from `Key.ctrl()` to the event set. Harmony's modifiers exist only in its patched `isDown`, so the conversion makes them invisible. **Harmony is referenced nowhere under `tests/` and CI runs only `busted tests -o utfTerminal`** — there is no automated signal, and breakage would be discovered by hand, later, by its author |
| 3 | **An assistant recommendation was overturned by the owner, recorded because the reasoning was wrong in an instructive way** | the assistant proposed *deleting* `patch_isDown` as a net subtraction once harmony injects real events. The owner's correction: physical querying is a **permitted project channel** by our own Decision 29 clause 3, and the sandbox hands projects the real `love` table (`consoleController.lua:40-41`, `:1090-1126` — `project_env` is a clone of `getfenv()`, nothing replaces or restricts `love.keyboard`). A virtualization layer must virtualize every channel its subjects may use, so the patch **stays**. The phase is additive, not a swap |
| 4 | **"wedge" retired from the vocabulary, fixed in place rather than deferred to P10** (owner instruction, 2026-08-08) | the owner caught it becoming load-bearing without ratification. Audit: **zero occurrences at the PR base `3256aac`** — entirely assistant-introduced across sessions 28–29 — and it had already reached three persistent-corpus sites plus a test row title. Worse, it carried **two distinct senses**: *stuck in a wrong state nothing clears* (the held set) and *blocked from completing* (teardown). Replaced with the owner's own word, **"stale"**, for the first and **"block"** for the second, with the permanence spelled out ("and nothing clears it") where it is load-bearing. Fixed **now**, not in P10, on the owner's reasoning that current reasoning is built on current notes and ambiguous vocabulary invites hallucinated architecture |

## 10. [S30] P13 — harmony reconciliation, and why it is in the release

Owner ruling, 2026-08-08: **its own phase, but worth inclusion in the release.**

### What harmony is (nobody's context carried this)

A scripted UI-automation and screenshot harness that drives the real app —
**not** part of `busted tests`. Written entirely by **aldum**, Apr–Nov 2025;
~1150 lines across `src/harmony/init.lua` and four scenario files. Launched by
hand: `justfile:60 dev-harmony` (file-watcher loop) and `justfile:131
one-harmony` → `love src harmony`; `conf.lua:15-16,52-53` maps the argument to
`require("harmony.init")(true)` — the `true` is `lock`, so **the only shipped
wiring is locked**.

Its verification capability is a toehold, not a suite: exactly one `assert` in the
whole subsystem (`scenarios/examples.lua:27`). The owner's reading of its purpose
is **bug reproduction** first, walkthrough capture second.

### The mechanism, and the one asymmetry that matters

- Harmony replaces the main loop (`love.run = harmonius_run`, `init.lua:104`).
  Injected events are pushed as `love.event.push('sazed_' .. name, ...)`
  (`:156`); the loop strips the prefix and calls `love.handlers[n](...)`. **Real
  input events are dropped** when locked — only `quit` and Escape survive
  (`:57-72`). That is what `lock` means: the app disowns the real keyboard.
- `patch_isDown` (`:242-254`) replaces `love.keyboard.isDown` globally; locked, it
  answers **only** from harmony's own eight-entry `held` table (`:174-184`) and
  never consults the device.
- **`love_key` (`:272-293`) splits `'C-S-s'`: the modifiers set `held[m] = true`
  with no event pushed; only the real key gets `keypressed`/`keyreleased`.**

That asymmetry is the whole finding. Faking the poll *sufficed* because
pre-feature every modifier question in the app was `Key.ctrl()` →
`love.keyboard.isDown`. Harmony is therefore a **statement of what the app's input
interface used to be** — a symptom of the polling architecture, not a precedent
for the feature's event-tracked model.

Note also: `held[m] = true` is never cleared automatically — the would-be
auto-release at `:286` is **commented out** — so clearing depends on an explicit
`release_keys()`, which `hm_done` (`:331`) runs at each scenario end. The one real
mid-scenario leak is `scenarios/editor.lua:102` (`S-return`, Shift held until
`:108`). The pre-feature mechanism thus already exhibited the held-set staleness
problem and answered it with a manual reset — the weakest form of a recovery path.

### Why it is not a swap

`Key.*` is **not** a LÖVE contract — it is `src/util/key.lua`, this project's own
helper, whose `shift/ctrl/alt` are thin wrappers over `love.keyboard.isDown`
(`key.lua:141-164`). The contract harmony patches is LÖVE's, which is the right
level: it covers `Key.*` for free and covers whatever a project calls directly.
And projects **may** call it — Decision 29 clause 3 keeps the direct reads as a
legitimate secondary channel, and the sandbox hands them the real `love` table.

So `patch_isDown` and `held` **stay**. What P13 adds is event injection; what it
subtracts is the press/release asymmetry and the manual release discipline.

### Contents

1. `love_key` pushes real `keypressed`/`keyreleased` for modifiers, and
   sets/clears `held` at those same two points. Both consumer kinds then see a
   scripted modifier: event-tracked *and* polling.
2. Press and release become symmetric, so `release_keys()` as a discipline —
   and the commented-out auto-release — can go, and harmony's own table stops
   being able to go stale.
3. **The batch-skew reproduction rig.** Harmony controls both what lands in a
   pump batch and what `isDown` answers, so it can simulate the two-events-in-one-
   frame skew directly and observe whether the app misjudges. It cannot verify
   SDL's own timing (locked, the device is never consulted) — but the app's
   misbehaviour is the thing under test, and this reproduces it **without the
   target device**. Today harmony structurally cannot: its modifiers never enter
   the event stream at all.

### Sequencing and ownership

Ordered after P9e (which is what breaks it) and independent of P10–P12. It is in
the release: the platform PR ships an input change that silently disables the
project's bug-reproduction harness otherwise, and **no automated signal exists**
to catch that — harmony is outside `busted` and outside CI. Like P12 it is
someone else's subsystem and eventually needs aldum in the loop.

---

## 11. [S32] Amendments made in session32 — Decision 30 actualised

### 11.1 Standing of the ruling

Decision 30 was rechecked before anything was built on it, per session32's commission.
Two cold checks, both with prompt of record and deliverable on disk:

- `../outcomes/S32-decision30-evidence-bundle.md` (mechanical) — the gate, the
  `3256aac` pre-existing checks, the dissolution counts.
- `../reviews/S32-decision30-challenge-fable.md` (judgement) — **verdict: Decision 30
  survives.** Its strongest leg is not the one the decision leads with: the tracked set's
  two defects were *already documented in `technical_debt/input.md` before Decision 30
  existed*, so the core rationale is the generalisation of two found-and-scheduled bugs,
  not a fresh abstract argument.

**Two corrections to the decision's own text**, neither reversing it:

1. Its *"Consequence — a prerequisite, not an option"* paragraph is **overstated**. The
   premise (single-arg `isDown` vs variadic `Key.*`) is true; the consequence is false —
   no test can reach a state where left and right differ, so a variadic mock would change
   **zero** test results, and the single-arg `isDown` is **pre-existing, untouched by this
   branch**. It is not a blocker and does not have to land first.
2. It does not name **two real consequences of rule 4**, and should (11.7).

**One owner correction, recorded because it changes how rule 4 is judged (2026-08-09):** a
project-owned flag is tracked state *"as any local state variable would be — but it is
owned by the project, which can consume and alter it as needed. Platform-owned
`keys_pressed` was global, long-living state, read-only for projects — a very different
beast."* The structural critique bites on state that is long-lived, shared and
**unrepairable by its reader**; the flag is none of those, and a project reading a phantom
in `keys_pressed` had **no repair path at all**. The flag is better-positioned state than
what it replaces, not the same bug scaled down.

### 11.2 Ordering for this unit — owner ruling, 2026-08-09

**Docs → tests → platform code → examples.** This **deliberately reverses §4's ordering
rule** (*"code first, tests second, docs third, comments last"*).

**Why the reversal is coherent here, and where it does not apply.** §4's rule exists
because moving code invalidates prose written before it. That premise held while the code
*shape* was still being decided. It does not hold now: Decision 30 settles the shape by
ruling, so writing the doc first is **writing the specification**, and writing tests
against that spec before implementing is `agents/development.md`'s own tests-first mandate.
**Scope: this unit (P14) only.** §4's rule still governs P8, P10 and P11.

**The debt register rides with the docs step — owner ruling, 2026-08-09.** I proposed
placing it last, on the grounds that it records state rather than specification and would
briefly state something false. **Overruled, and the reasoning is better than mine:** *debt
created by the spec is still debt — it can be dissolved later.* Writing the spec is what
creates the debt position; recording it at the same moment keeps the register honest about
what the spec has just committed to, and entries that the code then dissolves are removed
when it does. So the register moves with **P14a**, not after **P14d**.

### 11.3 Item-by-item disposition of the §4 table

The owner's instruction was that "likely dissolved" is a hypothesis **per item**, not a
licence to discard the plan. Every row walked:

| Row | Disposition under Decision 30 |
|---|---|
| **P0–P7b** | **Unaffected.** All DONE; none depended on the tracked set. Note P2/W1 *removed* `keys_pressed` from the hook payload — independent of Decision 30 and consistent with it |
| **P8** | **[S33] CLOSED — all nine walked and discharged** (`../reviews/S33-p8-walk.md`); the text below is the session32 disposition it superseded. **Premise unaffected**, but its nine remaining ids (R057, R074, R078, R079, R047, R063, R064, R069, R075) sit in test-restructuring territory that **P14c now also touches**. **A per-id check against Decision 30 is owed before P14c starts** — not performed this session, and explicitly not assumed. **[S33] The lettering here read `P14b` until 2026-08-09; it always meant the tests step, which `d348b505` re-lettered to P14c.** **[S33] OWNER RULING (2026-08-09): all nine are walked, not re-baselined.** §6 amendment 1 says *"P8 marked done"* and names eight of these nine as discharged — but §4's row was never edited to match, so the two contradict each other and neither has been checked against the tree. The walk **starts from §6's claim as a hypothesis and confirms or refutes it per id**, rather than re-deriving from scratch; R079 is separately held open by `../reviews/S28-merge-plan.md:170` (*"unchanged pending R079 (open ruling)"*) and needs a ruling, not a check |
| **P9** | **Unaffected.** SM3a's open runtime check is a pointer/click finding |
| **P9b** | **UNAFFECTED, and reconfirmed as the reason the sprint exists.** The keyboard `textinput` ordering heal is not a `keys_pressed` problem; `textinput` carries no `isrepeat` and never did. Decision 30 does not touch it. **It must not be eclipsed by the dissolution work** |
| **P9c** | **Unaffected in premise.** But P14c moves and deletes test cases, so **re-check both order-dependent cases after P14c**, not before. **[S33]** same re-lettering correction as the P8 row above |
| **P9d** | **WITHDRAWN.** Clearing the set on focus loss is a property of a set that no longer exists |
| **P9e** | **WITHDRAWN, and its premise is inverted.** P9e said the gateway violates its own rule by polling. Under Decision 30 **polling at the gate is the correct behaviour**; there is nothing to migrate |
| **P10** | **Survives and GROWS.** Its Decision-30 slice is **pulled forward into P14a** under the new ordering; the remainder (W9 ledger work, W10 batches 1/2/4) stays here. New members: `doc/input_api.md` §"Held keys" needs **replacing, not purging**; the flag-shortcut pattern (Decision 30's fourth item) has **no corpus presence at all**; **Decision 21's worked example is stale** — it says a hook "receives the held-key view", which **Decision 26 already removed** |
| **P11** | **Unaffected.** Comment sweep stays last. Gate currently failing: **22** markers in the platform, **5** in `src/examples/` |
| ~~P12~~ | **PROMOTED** to the parent plan as **Phase U** |
| **P13** | **Premise largely DISSOLVES — and in Decision 30's favour.** P13 existed because harmony fakes modifiers to the **poll** and never emits modifier *events*, so every event-side change was invisible to it and it could never exercise the combo mechanism. **Decision 30 makes the matcher read the device** — i.e. `love.keyboard.isDown`, which is exactly what harmony's `patch_isDown` replaces. **Harmony can now drive the combo mechanism it previously could not.** **OWNER RULING (2026-08-09): P13 is REDUCED TO REVALIDATION.** Not a build phase — confirm harmony drives a real combo end-to-end under the device-read matcher, and retire the manual `release_keys()` discipline if that confirms. It stays in the sprint; it does not follow P12 up to the parent. Neither cold check drew this dissolution |

### 11.4 New rows — the dissolution itself

Sub-lettered to encode the owner's ordering. One concern per commit throughout; suite green
and stated at each.

| # | Phase | Contents |
|---|---|---|
| ~~**P14a**~~ **DONE [S34], 2026-08-10** | **Docs — the specification — AND the debt register** | **[S34] Landed in five commits** — `fb81ecc0` project guide, `90935e2c` internals, `8a879534` ledger, `8cae175f` debt register, `70eb4842` the dispatch-layers guide. **Three things the enumeration below did not have.** (1) **A third persistent doc documents the set**: `internals/event_dispatch_layers.md` describes the bookkeeping as one of the two jobs the raw handler does — marked, not rewritten. (2) **Two standing decisions besides 21 still sent the reader to the dissolved surface** — Decision 25's pointer-payload bullet and Decision 26's own statement of what is not in the argument list, the latter while defining the rule that made the argument unnecessary; both corrected in place. (3) **`Key` has no `gui()`**, so the ruled shape has no helper for the fourth row of `mod_triples` — nothing registers a `gui` combo so nothing is broken today, but P14d cannot avoid deciding; the `gui_k` debt entry is reworked to say so and is no longer filed as harmless. **Also settled:** rule 3's gate-table softening was already in the tree from session33 and needed no edit; the project guide's "Held keys" heading is **kept** (two test comments cite it by name) while the internals heading loses the dissolved symbol, and that rename's one citation was fixed in the same commit. **What it hands forward: `PENDING` markers**, one per passage describing behaviour the tree does not have — `input_api.md` "Held keys" (1), `internals/user_input.md` (3: the chain diagram's bookkeeping line, the section preamble, and the `gui()` gap), `event_dispatch_layers.md` (1), and 5 entry-level ones in the debt register whose removal is a deletion, not an edit. Each names the step that clears it | Rewrite `doc/input_api.md` §"Held keys" (**[S33]** `:365-396`, not `:365-395`) as combo-first / flag-shortcut / poll-for-decoration; **teach the flag-shortcut pattern for the first time in the corpus** — it exists nowhere in the permanent docs today, only in Decision 30's fourth item; fix the false claim at `:268` (a hook does *not* receive the held table — **[S33]** `:389-390` and the code agree; the negation is on `:389`); update `internals/user_input.md` (10 occurrences); tombstone-correct **Decision 21**'s stale worked example. **Decisions are tombstoned, never renumbered** (§ W9 hard constraint). **The debt-register update (11.6) rides here** by owner ruling. **[S33] Write the internals prose CONCRETELY** — the shape is ruled (P14b), so the deferral instruction *"write to the level of 'the matcher reads the device'"* is withdrawn along with the trigger it carried. §"Key state" (`internals/user_input.md:241-296`) is rewritten against the real shape: the builder calls `Key.*`, loses its table parameter, and the *"Why the event-tracked set and not `love.keyboard.isDown`"* subsection — the two-clocks argument, cited to Decision 29 — is replaced rather than trimmed. **[S33] NAMING (owner ruling, 2026-08-09): teach the flag-shortcut pattern under a plain descriptive heading — no "rule 4", no "Decision N", no ledger reference.** `doc/input_api.md` has never cited the ledger (zero occurrences of "Decision"), and *"rule 4"* is session shorthand that appears in no document; a stakeholder reading only this guide and the PR description must not meet a numbered rule with no visible list. The worked keycap example that teaches the superseded answer is replaced by one that teaches the flag shortcut. **[S33] PENDING MARKERS (owner ruling, 2026-08-09): this step writes the specification BEFORE the code exists, so every passage describing behaviour the tree does not yet have carries a `PENDING` marker.** Each marker is removed by the step that implements it (P14c/P14d/P14e); they are a working device, and **the gate at P11 will not pass while any survives** |
| ~~**P14b**~~ **RULED [S33]** (owner, 2026-08-09) | **DESIGN RULING — the matcher's device-read shape** | **Shape (b): `combo_string`/`any_mod` call `Key.ctrl()`/`Key.alt()`/`Key.shift()` directly.** Raised early rather than at its trigger, because the internals half of P14a turned out to be blocked from its first paragraph rather than in one corner (§11.5, [S33] note). **This step is closed; P14c and P14d are unblocked and P14a is unblocked in full.** Consequences carried into the rows below: the builder loses its table parameter and every caller changes; the matcher is no longer table-drivable; **the mock's variadic fix is a prerequisite again** and lands first |
| **P14c** | **Tests** | Breaking tests against P14a's spec. **[S33] every range below re-verified against the files; four were wrong and are corrected here** (`../outcomes/S33-p14-citation-verification.md`). **[S33] The mock fix lands FIRST, as its own commit** — `tests/mock.lua`'s `isDown` becomes variadic and its `mods` token map gains `rctrl`/`rshift`/`ralt` (the `held` table already has the slots). Under the ruled shape every modifier assertion routes through the two-argument call, so without it no test can exercise a right-hand modifier at all. `keys_pressed_spec.lua:52-90` **delete** (not `:52-96` — `:91-96` is an unrelated comment); **[S33] `:98-138` must now be REWRITTEN, not kept.** Session32 recorded that these seven test cases need zero edits and read that as evidence the ruling is cleanly implementable; **that property belonged to the rejected shape.** They drive the matcher by passing it a synthetic table, which the ruled shape removes — they are rewritten to set device state through the mock instead. The "zero edits" claim is withdrawn as evidence. `input_nfr_mechanism_spec.lua:66-112` delete (not `:66-105` — **`:105` is the opening line of the fourth test; cutting there orphans its 7-line body**), `:123-165` keep. `input_events_spec.lua:781-901` delete (not `:781-905` — `:902-905` leads in to the next describe); `:557,616,734,857-861` need individual rewrites. **[S33] Three `tests/` occurrences this cell did not name, found by P8's walk** (`../reviews/S33-p8-walk.md`) — the cell covered 35 of 38: **`tests/helpers/input_fixture.lua:272` — `Controller.keys_pressed = { }`, live code in the SHARED fixture reset, on the path of every input test**, which goes with the field; `tests/helpers/input_session.lua:6`, a comment citing *"the `keys_pressed_spec` raw-handler pattern"* that rots when this rewrite empties that spec; and `input_widget_callbacks_spec.lua:537-541`, a comment explaining that the test drives **two distinct modifier tracks** — which the ruled shape collapses into one, so it documents a duplication the ruling removes. **[S33] Also: `keys_pressed_spec.lua` holds two of the three surface `describe`s** (R057's outcome) — deleting the held-key-set one leaves the file's name a misnomer for its only survivor, so the surviving block moves or the file is renamed — some assert a write-before-dispatch ordering that ceases to be meaningful. **Mock fix lands here; which fix it is depends on P14b**. **[S34] Three citation obligations the docs step created or exposed.** `input_nfr_mechanism_spec.lua`'s deleted block is headed by a **comment block immediately above it** (the "Held-key set lifecycle" note, rewritten in `90935e2c` when the internals heading was renamed) — it goes with the test cases it heads, so the deletion starts at that comment, not at the first `it`. **`doc/development/tests.md` and `internals/event_dispatch_layers.md` both name `keys_pressed_spec` by filename** — if this step renames the file (it leaves it misnamed for its survivor, see above), both citations move with it, and they sit in the **persistent** corpus where a dangling one outlives `wip/77`. **This step removes no `PENDING` markers** — the docs markers are keyed to the platform change, not to the tests **[S35] WHAT THIS STEP IS — definition, agreed with the owner 2026-08-10.** The retirement is **a mechanism change plus one contract withdrawal**, so the step is not "update the tests": it is **(1) dissolving the spec of a retired contract** and **(2) making the fixtures carry modifier state themselves**. Detail in §11.4.1. |
| ~~**P14d**~~ **DONE [S35], 2026-08-10** | **Platform code** | **Landed in five commits** — `ac33ccb5` the closed modifier set (Decision 31), `b0130412` the matcher reads the device (carrying the rewritten combo cases as its breaking tests), `91fbf07e` the gateway stops the bookkeeping, `9cb5b636` field/view/memoisation/sandbox/declarations/fixture reset, `c6d05685` the docs become true. Suite 942 / 0 / 0 / 10 throughout. **Two deviations, both stated in their commits:** the `gui` test case was **rewritten, not deleted** — its subject is the complete precedence fold, not `gui`, and it is the only case pinning all modifiers in order at once; and the **guard hint below was found in the P14e cell**, though it is entirely about `find_shortcut`, and was moved here — the exact drift this table's own rule exists to prevent, happening to the rule's own author. **Zero `PENDING` markers remain in the persistent corpus**; four defects in five entries left the debt register. | The device-backed source at the **single** production call site `find_shortcut` (`projectInputController.lua:103-110`); then the write side and dead machinery — `controller.lua:788,906` (writes), `:498` (the field), `held_keys()` + proxy memoisation `:420-443,501`, and the sandbox field in `consoleController.lua:539-540` plus its `held` upvalue plumbing **[S33]** `:829-830` (not `:829-834` — `:833-834` is an unrelated function's comment). **[S33] `combo_string`/`any_mod` DO change now** — this cell previously said they need none, which was true only of the rejected shape. Under the ruling they lose their `keys_pressed` parameter and call `Key.ctrl()`/`Key.alt()`/`Key.shift()` per `COMBO_MODS` triple (`controller.lua:395-418`; the triples already carry the generic name as `m[3]`), and **every caller changes** — inside `find_shortcut` that is three call sites (`any_mod`, and `combo_string` for both the trigger and the `'*'` class key). Cheaper per event as a side effect: an unmodified pointer motion now costs up to 3 device calls instead of 8 (**[S35] 3, not 4** — this cell was written before Decision 31 dropped the `gui` row; the cold revalidation recomputed it against the shipped code). **[S33] Three sites no bullet above accounted for**, found by the citation audit: **`src/types.lua:251`** — `--- @field keys_pressed table` on the `CompyInput` type, which **lies about the API if left**; `src/controller/userInputController.lua:490` — a comment naming the set; and note the files are under **`src/controller/`**, not `src/model/`. **[S34] `Key` exports no `gui()`** beside `ctrl`/`alt`/`shift`, and the ruled shape calls those helpers per modifier row — so this step decides the fourth row of `mod_triples`: add `gui()`, read each pair directly, or drop `gui` from the serialisation and say so. Nothing registers a `gui` combo today, so it is a decision, not a bug. Recorded in the debt register's `gui_k` entry, which no longer reads "harmless". **[S34] This step clears the docs `PENDING` markers** — `input_api.md` "Held keys", the three in `internals/user_input.md`, the one in `event_dispatch_layers.md` — and **deletes** the five marked debt entries rather than editing them **[S35] Do NOT pin the modifier's own press (owner ruling, 2026-08-10).** Pressing left Alt still serialises as `'alt+lalt'` after the change — the device reports the key that is physically down — but that is an **accidental** property, never designed, and it is explicitly not supported. No test asserts it and no document states it; pinning an accident is how it becomes a contract. §14.5. **[S35] WHAT THIS STEP IS — definition, §11.4.2.** The owner's commission: find every mechanism serving `keys_pressed` and remove it; a wrapper is removed or rewired by **what it was for**; the suite holds and the docs become true. **This is where the feature changes** — §11.4.1 dissolved a spec, this brings the mechanism down. Note §11.4.2's commit-shape finding: the rewritten combo cases land **here**, as this step's breaking tests, not in P14c. **[S35] IMPLEMENTATION HINT — take the modifier guard first (owner, 2026-08-10).** `find_shortcut`'s trigger branch currently builds the combo string, misses, and only then returns nil on `Key.is_mod(trigger)`. **No combo string with a modifier as its trigger is ever registrable** — `check_combo` folds every token, finds no trigger and raises *"names no trigger"*, for `'alt+lalt'` and for bare `'lalt'` alike — so that build and lookup can never hit. Hoist the guard to the top of the branch (`if Key.is_mod(trigger) then return end`): behaviour-identical, one build and one lookup saved per modifier press, and the rule is stated instead of emerging from a failed lookup. **This is a tactic, not a contract** — it is not documented in the corpus and no test asserts the saving; see §14.5 for the ruling behind it. **[S35] Consequence of dropping `gui`, landing in the same function:** `lgui`/`rgui` stop being modifier names, so `Key.is_mod('lgui')` is false and `shortcuts.keypressed['lgui']` becomes a **registrable binding that fires on a Super press** — coherent with "gui is just a key now", but new reachable behaviour, so it is named in the `gui` debt entry rather than left to be found. |
| ~~**P14e**~~ **DONE [S36], 2026-08-10** | **[S35] Examples — reconciliation with the removal, detached *and* in-repo** (was: "Examples", keyboard only) | **[S36] Landed in five commits across three repos** — in `keyboard` (detached) `05cedec` the proxy asks `Key`, `modHeld` deleted, `helpHeld` asks the keyboard for `h`, prose re-reasoned; in `maze` (detached) `a045fdb` `is_shift_down()` → `Key.shift()`; in the platform repo `5c3ca84b` turtle + clock, `cc434f9b` the sapper cascade → class shortcuts (**REVERTED `f61ada67`, see §15.2b — the conversion mistook a touch fallback for a hand-written cascade; sapper is escalated to its own step P19**), `3e8d6a5c` the debt-register section that feeds **P16**. `balloons` re-verified clean and closed. Platform suite **942 / 0 / 0 / 10** throughout — no platform code is touched. **Deviations, all stated in their commits:** sapper's two (derived clicks are button-1-on-release after the double-click window, and an unclaimed modified click now acts as a plain click instead of being inert — the widening accepted), and the keyboard example's half-finished uncommitted comment reword, completed rather than reverted. **Two findings outside the mandate, each in its own commit or the register:** `doc/input_api.md` still listed `gui` among the modifiers after Decision 31 closed the set (`5d342bbe`), and turtle binds Ctrl+Escape, which the framework reserves and quits on without consuming. **Smoke gate, and how it was made to mean something:** all five examples load and run under `love src play`; a first pass reported "clean" only because LÖVE's stdout is block-buffered and the timeout kill discarded it — with `stdbuf -oL` a deliberately bad combo registration was confirmed to surface, and only then were the five re-run. The keyboard proxy and `helpHeld` were additionally exercised by loading the real files against a fake device, since reaching a game scene needs keystrokes this container cannot inject. | **[S35] PRECEDES P9b (owner ruling, 2026-08-10)**, settling what §13 left open — sequencing is **P14a → P14c → P14d → P14e → P9b**. **[S35] RESCOPED TWICE (owner, 2026-08-10):** from `keyboard` alone to **all three detached repos** and then to **the in-repo examples too**, reconciled against the `keys_pressed` removal *and* the corrected recommendation ladder (§14.1). **The step outgrew this cell; its operative detail is §11.4.3** — per-repo and per-example scope, what converts and what stays, the one flagged judgement call, and the hint's leads. Nested repos have **no suite**: smoke re-pass is the gate. **Each repo commits on its own; NONE is ever pushed** (`pr-assembly-guide.md` §5) |

#### 11.4.1 [S35] P14c in full — what the tests step is (OPERATIVE)

**This section is the step.** Amendments to the tests step belong here. Agreed with the owner,
2026-08-10, opening from their framing: the retirement is **a mechanism change plus one contract
withdrawal**, so "update the tests" does not describe it.

**The governing principle** (owner): test **observable, contractable behaviour**. Testing
implementation detail is bloat that grows the codebase without buying anything — and testing an
*instance* of a general rule is the same mistake wearing a disguise. This is why the step adds
almost nothing.

##### 1. Dissolve the spec of a retired contract — two kinds, two justifications

- **A withdrawn contract.** `compy.input.keys_pressed` was a **documented project-facing API**, so
  its test cases are its specification: `input_events_spec.lua` (~`:781-901`) pins the participant
  view, the read-from-outside-a-handler case and the write-raises guard. Deleting them dissolves
  **the spec of that contract** — nothing more. **It is not "the dissolution":** the mechanism is
  still standing at this point and comes down in P14d. Read the other way round, this step would
  look like the feature change itself, which it is not.
- **Guards that were never contract.** `input_nfr_mechanism_spec.lua:67-112` — *"the pressed key is
  in the held set"*, *"the released key is gone before dispatch"*, *"reuses the held-key view for
  one backing table"*, *"left/right names stay raw"*. `doc/development/tests.md` itself calls these
  guards that deliberately poke internals. They go because their **subject** is gone, not because a
  contract was withdrawn. **Keep the two apart in the commits**: this half is the one place the
  suite genuinely loses the ability to catch something, which the PR description owes (§11.7).

##### 2. Make the fixtures carry modifier state

Today there are **two tracks**: the mock's `held` table (set by `keystroke('C-s')`) and
`Controller.keys_pressed` (written by the gateway on every keypress). A test that drives a raw
handler — `keys_pressed_spec` does `kp_handler('lctrl')` — gets modifier state **for free** from
the gateway write, without ever touching the mock. **After the change that free ride is gone**:
the device is the only source. The fixture must set device state whenever a test presses a
modifier key, the way hardware does.

Concretely: `tests/mock.lua`'s `isDown` becomes **variadic** and its token map gains right-hand
entries (`rctrl`/`rshift`/`ralt`; `held` already has the slots) — without it **no test can
exercise a right-hand modifier at all**, and the existing *"ctrl+s from rctrl held"* case would
silently stop proving anything. `tests/helpers/input_fixture.lua:272`'s
`Controller.keys_pressed = { }` is live code in the **shared** reset, on every input test's path,
and goes with the field.

**The irony, recorded so it is not re-litigated:** the mock's `held` table is a tracked set, and
that is not a contradiction. Decision 30 objects to a model maintained **beside** the device,
which can drift and needs the device to detect the drift. A mock **is** the device in tests. Same
data shape, opposite epistemic position.

##### 3. Re-drive a contract that survives — not dissolution

The seven combo-serialisation cases pin **Decision 8** (fold, fixed precedence, trigger last),
which Decision 30 leaves untouched. They are rewritten to drive the mock instead of a synthetic
table — **same contract, new driver**. Framing this as "the contract changed" would invite
deleting them. The `gui` case among them is deleted, not rewritten (Decision 31).

##### 4. Housekeeping the step owns

- **The file loses its namesake.** `keys_pressed_spec.lua` keeps only the combo-serialisation
  block, so it is renamed or the block moves — and **two persistent documents name that file**
  (`doc/development/tests.md:45`, `internals/event_dispatch_layers.md:53`), which move with it.
- **[S35] A citation that can go false without a rename.** `event_dispatch_layers.md:53` cites the
  file as a test that *"reproduces this startup wiring directly"*. The surviving cases call
  `Controller.combo_string` directly and need no handler wiring; the `setup_callback_handlers`
  block at the top of the file exists for the describe being deleted. Check that citation against
  what the file still does, not only against its name.
- **[S35] A comment describing a duplication that ends.**
  `input_widget_callbacks_spec.lua:537-541` explains that the test drives **two distinct modifier
  tracks**; after this step there is one.
- `tests/helpers/input_session.lua:6` cites *"the `keys_pressed_spec` raw-handler pattern"* and
  rots with the rename.
- **[S35] `doc/development/tests.md:73` — actualized here, by owner ruling, 2026-08-10** (F7 of
  `S35-spec-revalidation.md`). It describes the NFR guards as *"identity, allocation and
  **held-key-table** checks that deliberately poke internals"* — a three-member list whose third
  member this step deletes. It is **true today**, so it takes no `PENDING` marker; it is corrected
  in the same commit that removes the guards, which is what keeps the two in step. Persistent
  corpus, so a stale enumeration here outlives `wip/77`. Note `tests.md:45` (above) is a *different*
  obligation in the same file — the filename citation, which moves only if the file is renamed.

##### 5. What this step must NOT do

- **No test that the builder calls `Key.ctrl()`** rather than reading a table. That is the
  mechanism, not the contract; the contract is the string that comes out.
- **No test pinning a modifier's own press** (`'alt+lalt'`) — ruled accidental and unsupported,
  §14.5. Pinning an accident is how it becomes a contract.
- **Nothing asserting the guard-hoist** saves a build (§14.5 is a tactic, not a contract).
- **No `gui` cases** (owner, 2026-08-10). That `gui+s` raises is an instance of `check_combo`'s
  one-trigger rule, and that `lgui` binds is an instance of "an ordinary key binds" — already
  covered generically. Adding them argues for 105 more, one per alphanumeric key.
- **No device-level replacements for the deleted NFR guards** "to keep coverage". The coverage was
  of a mechanism that no longer exists; re-creating it grows the suite and proves nothing.

##### 6. Hands off to

**P9c** — the two order-dependent test cases this branch owns are re-checked **after** this step,
because this step moves and deletes test cases in those very files.

#### 11.4.2 [S35] P14d in full — what the platform step is (OPERATIVE)

**This section is the step.** Amendments belong here. Framed from the owner's commission,
2026-08-10: **find every mechanism that serves `keys_pressed` and remove it; code that wraps one
is removed or rewired according to what it was for; the suite must hold and the docs must become
true.** This is the step where the feature actually changes — §11.4.1 dissolves a spec, this
brings the mechanism down.

##### 1. What counts as "a mechanism serving `keys_pressed`" — by role, not by file

The inventory is best read as roles, because the remove/rewire question is answered by role:

- **The bookkeeping** — `controller.lua:788` (set on keypressed) and `:906` (clear on
  keyreleased). The gateway's first line, and the one `event_dispatch_layers.md`'s marker
  predicts will go.
- **The field** — `controller.lua:498`.
- **The read-only view and its memoisation** — `held_keys()` plus the `held_backing`/`held_proxy`
  upvalues, `:420-443`, exported at `:501`.
- **The sandbox exposure** — the `if k == 'keys_pressed'` branch in `build_input_surface`
  (`consoleController.lua:539-540`), its `get_keys` parameter, and the `local held =
  Controller.held_keys` that feeds it (`:829-830`).
- **The consumer** — `find_shortcut` (`projectInputController.lua:103-110`), the **single**
  production read.
- **The builder's parameter** — `combo_string`/`any_mod` (`controller.lua:395-418`) and the
  `COMBO_MODS` alias (`:382`).
- **The declarations and prose** — `src/types.lua:251` (`@field keys_pressed`, which lies about
  the API if left), `userInputController.lua:490`, and the `NOTE` above `combo_string`
  (`:386-393`) that poses an open design question about matching on the set directly — a question
  that stops existing with the parameter.
- **Riding here: the `gui` row** (`../decisions/input.md`, **Decision 31**) — `gui_k`, the fourth
  `mod_triples` row, `mod_rank`, `mod_order`, and the comments naming it, in `src/util/key.lua`.

##### 2. Remove or rewire — decided by what the code was *for*

- **Remove** when the thing exists **because the set exists**: the bookkeeping, the field, the
  view and its memoisation, the sandbox branch, the type field, the comments.
- **Rewire** when the thing has its own purpose and merely *used* the set: `find_shortcut` is for
  matching, so it keeps its job and loses its argument (three call sites inside it);
  `combo_string`/`any_mod` are for serialisation, so they keep their job and ask `Key.*` instead.
- **The adjacent-code rule** (owner): removing a mechanism sometimes takes the code immediately
  around it, and **the call site above is rewired rather than patched**. The clearest case is the
  view: `held_keys()` goes, its two memoisation upvalues go with it, and `build_input_surface`
  is rewired to **not take a `get_keys` parameter at all** rather than to be handed something
  else. A parameter kept alive to receive a replacement is the mechanism surviving under a new
  name.

##### 3. The docs become true here

These are **persistent-corpus** documents, not this sprint's scratch — they outlive `wip/77`, and
this step is where their tense changes:

- **`PENDING` notes become reality**: `doc/input_api.md` "Held keys" (1), the three in
  `internals/user_input.md`, and the one in `internals/event_dispatch_layers.md`. Removing a
  marker is **not** a formality — re-read the passage it covered, because the §"Key state" marker
  deliberately over-covers paragraphs that were already true (§14 / `S35-spec-revalidation.md` F5).
- **Deprecation notes become absence notes**: the five marked debt entries are **deleted**, not
  edited — two of them are one defect recorded twice, so the register loses two entries for one
  fix. The `gui` entry and the service-keys entry are **not** among them: they record decisions,
  not defects.
- **The key-files table** in `internals/user_input.md:860` loses the set from its `controller.lua`
  row (its own marker at `:864` says so).

##### 4. Commit shape — and one finding that moves work between steps

**[S35] The rewritten combo-serialisation cases cannot land in P14c green.** They drive the
matcher through a patched `love.keyboard.isDown`, which today's table-reading builder ignores, so
they fail until this step lands. Two standing rules meet here: *suite green at every commit*, and
*a production fix is its own commit **with** its breaking test*. The second resolves it — **those
rewritten cases belong in this step's commits, as the breaking tests the change answers**, not in
P14c. P14c then keeps only what is green on its own: the deletions, the mock fix, the fixture
change.

Otherwise unchanged: one concern per commit, the count stated and reconciled, and **the single
production call site first**, then the write side, then the dead machinery.

##### 5. What this step must NOT do

- **Do not keep a seam for the set.** No parameter left in place to receive a replacement, no
  accessor renamed rather than deleted.
- **Do not touch `src/harmony/`** (§14 and the S35 investigation). Its gui tokens are
  **pre-existing**, byte-identical at PR base, and were inert before this feature and stay inert
  under Decision 31 — this feature's only obligation to harmony is to remain compatible, which
  `patch_isDown`'s variadic wrapper already satisfies.
- **Do not fix the examples here.** They are P14e, which follows.
- **Do not treat the `NOTE` above `combo_string` as a debt to preserve.** The allocation question
  survives; the *"match on `keys_pressed` directly"* half does not.
- **Do not sweep on the word `held`.** It has **three unrelated meanings** in this tree
  (`../outcomes/S35-dissolution-site-enumeration.md`): the framework's tracked set, the *device
  mocks* in `tests/mock.lua` and `src/harmony/init.lua` — whose `lgui`/`rgui` slots **stay**,
  since a device still has those keys — and `model/input/selection.lua`'s text-selection drag
  state. Only the first is this step's subject.

#### 11.4.3 [S35] P14e in full — the examples reconciliation (OPERATIVE, factored out of the row above)

> **[S36] EXECUTED, 2026-08-10 — five commits, platform suite 942 / 0 / 0 / 10 throughout.**
> `keyboard` (detached) `05cedec`; `maze` (detached) `a045fdb`; platform `5c3ca84b`
> (turtle + clock), `cc434f9b` (sapper), `3e8d6a5c` (the debt-register section).
> `balloons` re-verified clean and closed without an edit. Everything the step listed
> is done, and nothing outside it was swept.
>
> **What the step did not anticipate, recorded here rather than in a dated section:**
> - **`clock`'s helper had a second call site** (`main.lua:78`, `k == "r" and shift()`).
>   The step named one site; deleting the local helper for the named one would have
>   broken the other. There is no suite here — a grep after the edit is what caught it.
> - **The smoke gate was silently toothless at first.** LÖVE's stdout is block-buffered,
>   and the container has no way to end the app cleanly, so `timeout`'s kill discarded
>   the buffer: a project raising at load looked exactly like a healthy one. Confirmed by
>   running a deliberately bad combo registration, which printed nothing. Under
>   `stdbuf -oL` the same bad registration raises visibly, and the five examples were
>   re-run under it. **A successor smoking an example must line-buffer, or it is
>   reading an empty file and calling it clean.**
> - **The keyboard example cannot be smoked past its menu here** — its held-state paths
>   need keystrokes, and no injection tool exists in this container (harmony's scenarios
>   need a seeded project directory it does not have). The proxy and `helpHeld` were
>   exercised instead by loading the real files against a fake device: each l/r pair
>   folds, Ctrl+Alt+H is not Alt+H, and neither `modHeld` nor `INPUT.held` survives.
>   **The interactive checklist is still owed by a human**, and its content is the one
>   already written for P9b (the design note's "Smoke checklist").
> - **Two findings outside the mandate.** `doc/input_api.md` still named `gui` among the
>   modifiers after Decision 31 closed the set — fixed in its own commit `5d342bbe`,
>   since it is a docs defect, not examples work. And `turtle` binds **Ctrl+Escape**,
>   which the framework reserves and quits on **without consuming**, so both fire to the
>   same end; filed in the register as a question of deletion rather than of rung.
> - **An uncommitted half-reword of the keyboard example's capslock comment** was sitting
>   in that repo's working tree. It was completed rather than reverted (it is the same
>   concern as the step's own prose work) and is named in the commit.
>
> **What was declined and where it went:** every conversion the cap excluded is now
> enumerated per site in `doc/development/technical_debt/input.md`, §"Examples are not
> onboarded onto the new input API" — the input to the onboarding work the owner added
> at the top of session36 and **split three ways the same day** (§15.1b): the common
> sweep **P16** (in-repo + `balloons`), the **maze** deepfix P17, and the **keyboard**
> deepfix P18, which absorbs the `textinput` heal.

**This section is the step, not reasoning about it.** It was factored out of §11.4's table when
the row reached 600 words; the row now points here. Amendments to the examples step belong **in
this section**. Provenance and the arguments behind these rulings are in §14 — the dated record —
and specifically §14.1 (the ladder), §14.3 (ordering + in-repo scope) and §14.4 (the hint).

**Order.** `P14a → P14c → P14d → P14e → P9b`. The heal runs after this step (owner, 2026-08-10),
because the two edit the same file and P9b must not be designed around code that is mid-move.

**Mandate.** Reconcile the examples with **two named changes**: the removal of the tracked
held-key set, and the corrected recommendation ladder. **Held-state reads are what is swept, and
nothing else.** An example with none is recorded as clean and closed, not searched. This is not the
blanket example sweep the owner ruled out.

**The ladder** (§14.1), which decides what each read becomes: shortcuts/combos first; `Key.*` in
project code is permitted but a symptom; `love.keyboard.isDown` is the last resort, legitimate
where `Key` has no answer (a key that is not a modifier).

##### The three detached repos

Separate repos, own remotes, own history, **no suite**, and nothing re-checks them when the
platform moves — which is why they need a step at all. **Each commits on its own; none is ever
pushed** (`pr-assembly-guide.md` §5). Smoke re-pass is the gate.

- **`keyboard`** — `input.lua`'s `INPUT.__index` held branch (`:54-62`, the branch itself at
  `:57`), the header prose naming the set (`:43`), and **`modHeld` (`:108-114`), which is DELETED,
  not converted** (owner, 2026-08-10): it re-implements `Key.ctrl()`'s left/right folding over the
  very table being dissolved, so its callers move to `Key.*` or to combos. **[S35] `help.lua:11`**
  (`INPUT.held.h and INPUT.alt and not INPUT.ctrl`) is the only consumer of the `held` branch and
  was not previously named. `keyboard_view.lua:171,178` consume `INPUT.shift` and need no edit of
  their own once the proxy is fixed. **[S35] The proxy is the seam, worth knowing before the file
  is opened:** the cold enumeration (`../outcomes/S35-dissolution-site-enumeration.md`) counts
  **11 read sites** in this example and **9 need no edit at all** — `input.lua:192,193,195,197`,
  `alt.lua:203,230,240` and `keyboard_view.lua:171,178` all read `INPUT.shift`/`.ctrl`/`.alt` and
  are insulated the moment those three proxy branches call `Key.*`. Only **`help.lua:11`**
  (`INPUT.held.h` — the one read that goes through the dissolved surface itself) and `modHeld`
  are edits. **[S33] Sort its reads into decoration/drawing (stays —
  legitimate, owner) vs judgement (converts) before touching any of them.**
- **`maze`** — **`is_shift_down()` (`main.lua:562-565`) is the same duplication in a second repo**:
  `d('lshift') or d('rshift')`, i.e. `Key.shift()` written out by hand. `main.lua:517`'s
  `isDown('tab')` uses the right *API* for a non-modifier key, but **the poll itself is likely a
  combo in disguise** — see the leads below.
- **`balloons`** — **nothing to do**, verified: it touches only the overlay API
  (`terminal.lua:26-38`) and reads no held state. Recorded so the sweep is not re-derived later.

##### The in-repo examples

- **`turtle`** (`main.lua:34` → `Key.shift()`, `:92` → `Key.ctrl()`) and **`clock`**
  (`main.lua:68` → `Key.shift()`) — rung 3 doing rung 2's job. These two were wrongly cited in
  `S35-spec-revalidation.md` as *evidence* the rewritten guide was right; that clean bill is
  withdrawn and they are work items.
- **`pong` stays** — `main.lua:330` polls a variable key, `strategy.lua:35,37` poll `up`/`down`.
  Arbitrary keys are the legitimate last rung, and the README snippet (`:254-255`) teaches the
  same, correctly.
- **`tixy`** (`:197`) and **`paint`** (`:407`) — already at rung 2. No change.
- **`sapper`** (`main.lua:672,690,697,701`) — **[S35] CONVERTS. Owner ruling, 2026-08-10**, which
  supersedes this entry's earlier *"flagged, NOT converted, debt register if declined"*. The
  owner's reading: the machinery **is** a set of combos on the `singleclick`/`doubleclick`
  channel, written out by hand. Verified against the code and the matcher before writing:
  - **What it does today.** `hooks.singleclick`/`hooks.doubleclick` act only when nothing is
    held; `love.mousepressed` adds shift → `single` and ctrl → `doppel`, each spelled as *this
    modifier and none of the other two*.
  - **Why it converts exactly, and this is the point.** The class key folds **every** held
    modifier (`combo_string('*', …)`), so `'shift+*'` matches shift-and-nothing-else — the
    cascade's own semantics, already in the framework and already the thing the guard
    re-implements. Target shape: `shortcuts.singleclick['shift+*']` → `single` and
    `['ctrl+*']` → `doppel`, both consuming; the two hooks lose their guard and become plain
    `single`/`doppel`; `love.mousepressed` goes entirely.
  - **Two deviations to state in the commit rather than discover in the smoke pass.** Derived
    clicks are **button 1 only, counted on release, resolved after the double-click window and
    discarded on drift** (`controller.lua:936-941`), where today's `love.mousepressed` acts on
    **any** button at press time. And the cascade's implicit *"every other combination does
    nothing"* has **no shortcut expression**: an unclaimed modified click (alt alone, ctrl+shift,
    …) falls through to the hook and acts as a plain click, where today it is inert.
    **Recommendation: accept the widening** — alt-click revealing a cell is harmless in this game,
    and re-growing a guard in the hook to preserve inertness would keep the cascade this
    conversion exists to remove. It is a behaviour change either way, so the commit says which.
  - **Not a counter-example to the scope guard** (*small and obviously behaviour-preserving
    conversions only*, above): this one is ruled in by name, and the reasoning it rests on — class
    keys already mean "this set and no other" — is checked, not assumed.
- **`guess`, `life`, `repl`, `sine`, `valid`** — clean, no held-state read.
- **Not in scope:** `keyboard/input.lua:99`'s `love.keyboard.setTextInput` — an IME toggle, not a
  held-state read, and the kind of thing a pattern-driven sweep would wrongly collect.

##### The leads — reads that are combos written out by hand (hint, owner 2026-08-10)

**Leads, not a work list.** Take one only where the conversion is small and obviously
behaviour-preserving; anything larger goes to the debt register with its reasoning. **This must not
turn a reconciliation into an example rewrite.** The discriminator and the reasoning are in §14.4.
**[S35] `sapper` is no longer the exemplar of the deferred case** — it was ruled in on 2026-08-10
(see its entry above); the cap stands on its own reasoning, without a standing instance.

- **`maze/main.lua:514-526`** (`poll_tab_progression`) — polls `tab` per frame, keeps a
  `tab_was_down` mirror, derives an edge. A discrete question answered with frame-time machinery;
  `shortcuts.keypressed['tab']` answers it directly. It also carries **the same bug class the
  sprint is removing**: a flag mirroring a key, with nothing to reconcile it.
- **`maze/main.lua:568-571`** — `love.keypressed(k)` doing `k == 'escape' and not is_shift_down()`
  is `shift+escape` versus `escape`, two bindings. **This supersedes the entry above** that
  converts `is_shift_down()` to `Key.shift()`: that is the middle rung, the combo is the top one.
- **`keyboard/alt.lua:203`** — `k == 'h' and INPUT.ctrl and INPUT.alt`, hand-matching the combo its
  own comment calls *"Ctrl+Alt+H"*.
- **`keyboard/help.lua:11`** — spans frames rather than one event, so the shape is the guide's
  **flag shortcut**, not a plain combo.
- **Excluded on purpose:** `keyboard/input.lua:191-192` (`appTextinput`'s alt/ctrl refusal) is
  **P9b's** to redesign and `textinput` carries no key; `pong`'s paddle polls and the keycap
  renderer are the *correct* poll and are the counter-examples that keep the hint honest.


**Unblocked work that proceeds while P14b waits** (this is the point of deferring it):
**P9b** (the keyboard `textinput` heal — the reason the sprint exists), **P9**'s SM3a
runtime check, the **probe deletion**, **P8**'s per-id check, and all of **P14a** except
the one internals passage named above.

**Also placed, outside P14 because they are not the dissolution:**

- **`src/probe/input_probe.lua` — DELETE.** Its own header: *"DIAGNOSTIC, TEMPORARY. Delete
  when the polling-vs-tracking question is ruled on."* The question is ruled. Postdates
  `3256aac`; opt-in; not on the dispatch chain. Its own commit.
- **Rule 3's gate table — NOT this PR, and possibly not at all (OWNER RULING,
  2026-08-09).** The gate's polls are byte-identical to base and functionally uncontested,
  so nothing forces it; bundling it would mix "revert an implementation-time decision" with
  "add architecture" in one diff, against the reviewability bar. If it were ever built it
  would have to be visibly a **second, privileged table** with its non-overridability
  stated where it lives — otherwise introspectability arrives with a false promise of
  override.
  - **LEDGER TENSION this ruling exposes, needing its own correction.** Decision 30 rule 3
    currently says the gate *"**can build its own table, and should**, for the same
    introspectability reason the rule exists."* The owner's position is now "not this PR
    and maybe not at all". **The decision text therefore states a commitment the owner does
    not hold.** It needs softening in place — "may" rather than "should", or an explicit
    note that the layer is named without obliging the table. **Rides with P14a** (docs),
    since it is a ledger edit. Tombstone rules apply: amend in place, never renumber.
- **`src/lib/error_explorer.lua:418` — out of scope**, pre-existing at base and outside the
  dispatch chain entirely, but **named in the PR description** so a reviewer grepping
  `love.keyboard.isDown` does not read it as a missed occurrence.

### 11.5 The design fork — evidence for P14b's ruling (DEFERRED, raise when it blocks)

`combo_string` looks its two modifier variants up **separately** (`keys_pressed[m[1]] or
keys_pressed[m[2]]`), so the matcher's device-backed form can be either:

- **(a) per-key device lookup** — a static proxy `__index = function(_, k) return
  love.keyboard.isDown(k) end`. Matches the matcher's existing per-key indexing exactly.
  The mock's single-arg `isDown` **never bites**; the prerequisite becomes adding
  right-hand tokens to `tests/mock.lua`'s `mods` map (`:17-21`) — the `held` table
  (`:5-15`) already has the slots. **Recommended.**
- **(b) route through `Key.ctrl()/alt()/shift()`** for symmetry with the gate. Then the
  variadic-`isDown` concern **reattaches for real** and the mock fix becomes load-bearing.

**These need different mock fixes**, and Decision 30's text currently names the one for
fork (b) while (a) is the assistant's recommendation. **Name the fork in the PR either way.**

**This is evidence, not a recommendation to adopt.** The owner ruled (2026-08-09) that the
fork is a **design decision and gets its own step** rather than being rubber-stamped as a
side effect of plan reconciliation — and that it should be raised **when it blocks**, not
up front, so unblocked work clears first. What it blocks: **P14c** (which mock fix is the
real one), **P14d** (it *is* the implementation), and a single internals passage in P14a.

### **[S33] RULED — shape (b), and why it was raised early (owner, 2026-08-09)**

**The trigger fired sooner than "a single internals passage" predicted.** §"Key state"
(`internals/user_input.md:241-296`) documents the builder **by its signature**, including the
parameter the two shapes disagree about, and carries the whole *"Why the event-tracked set and
not `love.keyboard.isDown`"* subsection that Decision 30 reverses. It cannot be written
shape-agnostically without omitting a signature from the one document whose job is signatures.
That passage is the section's centre of gravity, not a corner of it — so the owner took the
ruling up front rather than at the trigger, and the docs step is unblocked in full.

**Ruled: shape (b) — `combo_string`/`any_mod` call `Key.ctrl()`/`Key.alt()`/`Key.shift()`
directly.** Symmetry with the pre-dispatch gate, which already polls that way, and one literal
source of modifier truth rather than an adapter standing in front of it. No proxy to defend in
the PR — which matters, because this feature spends its narrative deleting one.

**What the ruling costs, recorded so it is not rediscovered as a surprise.** Evidence gathered
and verified in code before the ruling, not after:

- **The seven matcher test cases stop being free.** `keys_pressed_spec.lua:98-138` needed zero
  edits under shape (a) — a property session32 cited as evidence the ruling is cleanly
  implementable. That property belonged to (a) alone. They are rewritten.
- **The matcher stops being source-blind**, so it can no longer be driven by a synthetic table;
  proving it works means patching `love.keyboard.isDown`.
- **The mock fix is a prerequisite again**, precisely scoped (see `decisions/input.md`,
  Decision 30's amended "prerequisite" note): existing results do not change, but no test can
  exercise a right-hand modifier until `isDown` is variadic and `mods` gains `rctrl`/`rshift`/
  `ralt`.
- **Wider code diff** — the builder's parameter goes and every caller changes.
- **Cheaper per event**, marginally: an unmodified pointer motion costs up to 4 device calls
  instead of 8.

**Verified and NOT a differentiator: harmony works under both shapes.** `patch_isDown`
(`harmony/init.lua:242-253`) is `function(...)` and loops over every argument, so it answers a
one-key lookup and a two-key `Key.*` call alike. This also **confirms the basis on which P13
was reduced to revalidation** — the reduction does not depend on which shape was chosen.

### 11.6 Technical-debt register — the update, enumerated (rides with P14a)

- **Dissolve** (the set is gone): `:29` "The held-key set is never cleared on focus loss";
  `:61` "The gateway asks the device a question about an event"; `:81` "The held-key
  surface is a table that cannot be iterated"; `:281` "`keys_pressed` can go stale on focus
  loss"; `:442` "Held-key pressed-keys view iteration is index-only".
- **Note while doing it:** `:29` and `:281` are **two entries for the same defect** — a
  pre-existing duplicate in the register, worth stating in the commit so it does not read
  as a miscount.
- **Rework, do not delete** (RESOLVED entries whose resolution is now reversed): `:396`
  "`compy.keys_pressed` is not exposed to projects" — its resolution reads *"owner ruled to
  expose it"*; needs a superseded-by-Decision-30 note in place.
- **Rework** (entries that name `keys_pressed` as the recommended answer). **[S33] Two of the
  three pairs below were misattributed and one entry was missing; corrected against the file**
  (`../outcomes/S33-p14-citation-verification.md`):
  - `:664` combo triggers key-name-only — its own line is `:689`. **Unchanged, correct.**
  - `:719` **multi-trigger combo silently truncated (RESOLVED)** — its line is `:731`, *"a
    project that wants 'a and b held together' reads `compy.input.keys_pressed`"*. **This entry
    was absent from the list entirely**, and it is where that quotation actually lives; the
    recommended answer becomes the flag-shortcut shape.
  - `:738` modifier-class rule (RESOLVED) — its own line is **`:773`**, not `:731`.
  - ~~`:775` keyboard-hooks-only interactivity (`:773`)~~ — **struck.** `:773` belongs to
    `:738` above, and `:775`'s body (`:777-793`) contains **no `keys_pressed` mention at all**,
    so it does not belong in this bucket. If it needs rework it is for another reason.
- **Survives unchanged:** `:795` combo-string allocation (still allocates); `:178` dirty
  global device state on raise. **`:988` "retired polling idiom" also survives and does
  NOT invert** — checked: its retired idiom is the `r = user_input()` **poll-loop**
  (polling a reference for results), not device polling.
- **New entries to consider** (owner's call whether debt or documented-accepted): the
  flag-shortcut modifier-sensitivity trap (11.7); batch-skew as an accepted unmeasured
  risk.
- **Also:** `:58`/`:77`'s "Scheduled: before the PR (plan phase P9d/P9e)" wording is now
  **false** — both phases are withdrawn.

### 11.7 What the PR description owes

- **Removal, not deprecation** — no compatibility shim.
- **Where device polling now lives**: the matcher (framework-internal) and
  decoration/rendering reads (project-legal). Judgement code at a project call site stays
  discouraged **style**, not a blocked capability — say so, because it never was blocked.
- **The gate and `error_explorer.lua:418`** named as known, pre-existing, unchanged.
- **The flag-shortcut pattern stated as a complete mechanism**, so a reviewer does not rediscover the
  strawman objection and conclude the API has a hole. Then its **two honest consequences**:
  (1) a project flag is small tracked state that can go stale on focus loss — mitigated,
  per the owner's correction, by being project-owned and repairable, unlike `keys_pressed`;
  (2) **the genuinely new trap** — a flag-shortcut is filtered through the
  **modifier-sensitive** matcher, so `shortcuts.keypressed['a']` silently fails to fire,
  and the flag silently fails to update, whenever an unrelated modifier is held. Raw
  `keys_pressed['a']` tracked unconditionally.
- **The accepted regressions, plainly**: batch-skew is new, unmeasured and accepted; the
  suite loses the ability to express the old failure mode as a test; `examples/keyboard`
  needs a real migration and its adoption saving shrinks.
- **Console/editor deferral needs a citation, not a justification** —
  `design/requirements.md` FR-11/12: *"expressiveness targets, not a commitment to rewrite."*
- **[S35] The decisions ledger IS stakeholder-visible, and the frame never said otherwise**
  (owner, 2026-08-10). *"Reviewable from `doc/input_api.md` + the PR description alone"* is a
  statement of **sufficiency** — a reviewer must never be forced into `wip/77` — not a statement
  that nothing else is read. `doc/development/decisions/input.md` is in the persistent corpus and
  in this PR's diff, so a stakeholder will open it whenever they feel like it. Two consequences:
  **(a)** any decision this sprint **mints or retracts** is review surface and owes a line in the
  justification table, on the same footing as a new moving part; **(b)** session33's naming ruling
  — the project guide cites no ledger — is about **the guide standing alone**, not about the
  ledger being private, and must not be read as the latter.

## 12. [S33] Amendments made in session33 — revalidation findings and five owner rulings

Session33 revalidated §11 against `agents/rules/revalidation.md` before executing any of it.
The review is `S33-plan-revalidation.md`; the citation audit behind it is
`../outcomes/S33-p14-citation-verification.md`. **Verdict: sound in substance, defective in
navigation** — no disposition in §11 was wrong on the merits, but §11 was written against a
step list that had gone stale, re-lettered mid-session without a sweep, and never propagated
back into the rows an executor reads.

**Per Decision 2 below, the amendments are written INTO the rows; this section is the dated
reasoning, not the place the change lives.**

### 12.1 Corrections applied without a ruling (mechanical restorations)

| # | What | Where |
|---|---|---|
| 1 | **The re-lettering residue.** `d348b505` re-lettered P14a–e and swept §11.4/§11.5 only. Four references in §11.3 kept the old lettering, all meaning the tests step, all reading as the deferred design ruling — so §11.3 gated P8's check on a deferred step while §11.4 listed the same check as unblocked | §11.3 P8, P9c |
| 2 | **Six wrong citations.** Worst: `input_nfr_mechanism_spec.lua:66-105` stops at the **opening line** of the fourth test, so cutting there orphans a 7-line body. Also `keys_pressed_spec.lua:52-90`, `input_events_spec.lua:781-901`, `consoleController.lua:829-830`, `input_api.md:365-396`, the negation on `:389` | §11.4 |
| 3 | **Two misattributed debt pairs, one missing entry.** `:731` belongs to the `:719` entry, not `:738`'s; `:775`'s body names `keys_pressed` nowhere. `:719` — where the *"a and b held together"* quotation actually lives — was absent from the rework list | §11.6 |
| 4 | **Three unnamed code sites.** The 22-occurrence count is exact; the attribution was not. `src/types.lua:251` (`@field keys_pressed` on the `CompyInput` type — it lies about the API if left), `userInputController.lua:490`, and `examples/keyboard/input.lua:109` (`modHeld`, a distinct read site from the `INPUT.__index` branch) | §11.4 P14d/P14e |
| 5 | **The parent plan's Phase U** still asked whether P13 follows P12 upward, which `d348b505` had answered | `../plan.md` |

### 12.2 Owner rulings, 2026-08-09

1. **P8: walk all nine ids; do not re-baseline to R079.** The revalidation found that §6
   amendment 1 (session28) declared *"P8 marked done"* and named eight of the nine as
   discharged, while §4's row — never edited, despite §6 asserting amendment *in place* —
   still listed all nine. Session32 read the unamended row and carried nine forward, into
   §11.3 **and into `../notes/S32-plan-map.md:74`, the map the ruling was taken from**. The
   owner declined to trust the amendment over the row: **both are unverified against the
   tree, so the walk settles it.** It starts from §6's claim as a hypothesis rather than
   re-deriving, and R079 needs a ruling rather than a check.

2. **The step list becomes the single operative list.** §4's table is rewritten so each step
   states what it actually requires now, and gains the P14 steps and the probe deletion as
   real rows. **Root cause named:** two failures found this session — session28's unapplied
   amendment and session32's unswept re-lettering — are one failure, *a document amended in
   one place and read from another*. Two lists that must agree is the arrangement that
   produced both. **Working rule: when a step is amended, the amendment goes in the step.**

3. **The design fork is ruled now, not at its trigger.** The deferral assumed it blocked "only
   one internals passage"; the revalidation found the blocked passage is the internals
   section's centre of gravity (§11.5 [S33]). Rather than split the docs step or write vague
   prose and owe a backfill, the owner took the ruling up front. **The docs step is unblocked
   in full and no backfill is owed.**

4. **Matcher shape: (b) — the builder calls `Key.ctrl()`/`Key.alt()`/`Key.shift()` directly.**
   Recorded in the ledger in place (`../../../decisions/input.md`, Decision 30 rule 2 and the
   amended "prerequisite" note). Costs accepted knowingly: the seven matcher test cases are
   rewritten rather than kept, the matcher stops being source-blind, the mock's variadic fix
   becomes a prerequisite and lands first, and the diff widens. Harmony was checked and works
   under either shape, so it did not bear on the choice — and that check independently
   confirms P13's reduction to revalidation.

5. **The flag-shortcut pattern is taught under a plain descriptive name** — no *"rule 4"*, no
   *"Decision N"*, no ledger reference in `doc/input_api.md`. That guide has never cited the
   ledger, and *"rule 4"* is session shorthand present in no document. Applies to the PR
   description too.

### 12.3 Still open after this session

- **The ~50-id comment-bloat subset** inside W10's block of 92 is never separately enumerated
  and must be re-derived before P11 — recorded here because session32's report carried it and
  no step did.
- **R079** — an open ruling on `project_open_liveness_spec.lua`, inside the P8 walk.
- **The `:775` debt entry** — struck from §11.6's rework list because it names `keys_pressed`
  nowhere. Whether it needs rework for some other reason is unexamined.

### 12.4 Cleared on verification, recorded so it is not re-litigated

- **`keys_pressed` appears nowhere in the tree at PR base `3256aac`** — whole-tree `git grep`,
  machinery sanity-checked, base confirmed an ancestor of HEAD. The tracked set is entirely
  feature-introduced, so **dissolving it cannot regress pre-feature behaviour.** Every
  "pre-existing" check this phase has run overturned something; this one confirms.
- The 22-occurrence / 7-file count, the 10 occurrences in `internals/user_input.md`, the
  marker gate (22 platform + 5 examples, **disjoint**), the mock's ranges, the probe's
  self-declared deletion header, and `error_explorer.lua:418`'s byte-identity at base — all
  exact.
- **LSP missed 4 of the 22 occurrences** (a type annotation, a comment, a computed-string-key
  indirection, and the `compy.input.*` proxy path in the example). Grep as completeness
  backstop was load-bearing, exactly as the standing rule says.

### 12.5 [S33] Executed in session33 after the rulings

| unit | outcome |
|---|---|
| **Probe deletion** (`ba5c94e4`) | `src/probe/input_probe.lua` deleted on its own declared terms. Verified before removal: zero references in `src/`/`tests/`, zero in the **persistent** doc corpus (so no citation dangles), no module loader enumerates `src/`, `src/probe/` held nothing else, and it postdates `3256aac` so its removal cannot touch pre-existing behaviour. Suite green, and the app was booted headless afterwards — a deletion the suite cannot fail on deserves the smoke check |
| **P8's nine-id walk** (`../reviews/S33-p8-walk.md`) | **All nine discharged; P8 is DONE.** §6's claim was right and §4's row was stale. **The walk's real product was three interactions with P14c**, now folded into that step: `input_fixture.lua:272`'s live `Controller.keys_pressed = { }` in the shared reset, a rotting citation in `input_session.lua:6`, and a comment in `input_widget_callbacks_spec.lua` describing **two modifier tracks that the ruled shape collapses into one** — a simplification the shape's cost accounting had not credited it with. Also: deleting the held-key-set `describe` leaves `keys_pressed_spec.lua` misnamed for its survivor |
| **P9b** | **NOT started — owner ruling, 2026-08-09: it needs its own session, possibly its own spinoff**, because the fix requires a design decision *and* the validation of that decision, and neither belongs inside a session already carrying the dissolution. It remains the reason the sprint exists; it is not deprioritised, it is scoped out |

**Method note worth keeping.** The owner ruled *against* the recommendation to re-baseline P8
to R079, on the grounds that §6's claim and §4's row were **both** unverified. The walk then
showed the recommendation rested on a **planning-table phrase inherited without checking the
commit history** — `S28-merge-plan.md:170`'s "pending R079" is a merge-scoping line, and R079
had its own commit the same day. *"Both documents are unverified, so check the tree"* beat
*"this document looks better-sourced than that one"*.

### 12.6 [S33] Three further owner instructions, 2026-08-09 (at the session wrap)

1. **The docs step runs BEFORE P9b's design substep.** Owner's reasoning: *P9b may include
   reasoning which should better be done towards the currently approved design.* P9b's design
   work would otherwise be argued against `doc/input_api.md` and `internals/user_input.md` as
   they stand — still teaching the tracked-set model that Decision 30 reverses. Writing the
   spec first means P9b reasons from the design of record rather than from prose the sprint is
   about to invalidate. **Sequencing: P14a → P9b (own session) → the rest of P14.** Recorded
   in both rows.

2. **Unimplemented prose is marked `PENDING`.** The docs-first ordering means the
   specification is written while the tree still behaves the old way, and a document that
   describes behaviour the code does not have is a document that lies. Every such passage
   carries a `PENDING` marker, removed by the step that implements it. **The P11 gate absorbs
   them** — and note this extends the marker sweep to `doc/`, which it has never had to scan,
   since `INTERIM:`/`REMARK:` have only ever lived in `src/` and `tests/`.

3. **`xvfb-run` is sanctioned for SM3a's runtime check** — *"if it is available in the
   container and if it helps."* **Available:** `/usr/bin/xvfb-run`, `/usr/bin/Xvfb`, and it was
   exercised in this session (`xvfb-run -a love src`, to confirm the app still boots after the
   probe deletion). **Helps:** the check needs the app running twice with another project run
   between, which is exactly what session28's code-only pass could not do. It stays a
   **diagnostic** — it confirms or kills the font hypothesis, and a fix is a separate decision.

## 13. [S34] Amendments made in session34

### 13.1 Owner ruling, 2026-08-10 — the platform code precedes the keyboard heal

Session34 opened with the choice session33 commissioned: which unit runs next. The owner took
**the docs step and the maze font diagnostic** for this session, and ruled additionally on an
ordering that had not been asked about:

> *"later C precedes D — otherwise will be fixing D against outdated platform logic (even if it
> not overlaps, doing so would be conceptually wrong)."*

**In essence:** the keyboard example's `textinput` heal is designed and validated **after** the
tests and the platform code have landed, not merely after the docs. Session33's ruling had put
the docs step first so P9b would reason against the approved *design*; this extends the same
principle to the *code* — reasoning about a fix while the surface it sits on is still the one
being removed is wrong even when the edits do not collide. **Sequencing: P14a → P14c → P14d →
P9b.** The amendment lives in P9b's step in §4; this section is the dated reasoning behind it.

**Left open, deliberately.** The examples step (P14e) edits `examples/keyboard/input.lua` — the
same file P9b rewrites — so the owner's argument applies to it *more* directly than to the
platform code. Whether P14e must also precede P9b was **not ruled** and is raised before P9b
starts rather than settled here by extrapolation.

---

## 14. [S35] Amendments made in session35 — the spec corrections and the detached-examples step

_The amendments live in the steps (§4's P14a–e row, §11.4's P14a/P14d/P14e rows). This section is
the dated reasoning behind them. Evidence: `S35-spec-revalidation.md`, `S35-spec-corrections.md`._

### 14.1 Owner corrections, 2026-08-10 — the recommendation ladder, and `gui`

The docs step wrote the specification before the code, and a cold read by the session that had to
test it found the spec sound but the *recommendation* wrong in two ways. Both are owner
corrections, not findings.

**The ladder.** `love.keyboard.isDown` is the low-level API; `Key` sits above it and already does
the left/right folding, so **`Key` is what a project may consult** — while combos and shortcuts
remain the strongly-preferred mechanism, so that the hardware check does not happen *inside*
project code at all. The rungs are not equal, and the guide must say so:

1. **shortcuts / combos** — the intended mechanism;
2. **`Key.ctrl()`/`Key.alt()`/`Key.shift()` in project code** — permitted, but a **symptom of
   possible technical debt**;
3. **`love.keyboard.isDown`** — an **even stronger symptom, the method of last resort**, with one
   legitimate use: a key that is not a modifier at all, e.g. visualising which key caps are
   pressed. `Key` has no accessor for an arbitrary key, so this rung is necessary, not tolerated.

The rewritten `doc/input_api.md` §"Held keys" teaches rung 3 as *the* answer and never mentions
`Key`. It is corrected under P14a. **Harmony is unaffected** — `patch_isDown`
(`src/harmony/init.lua:242-253`) is variadic and answers `Key.ctrl()`'s two-argument call
correctly; the test mock is the one that is not, which is why the mock fix is a P14c prerequisite.
`Key` is already the established project idiom (`examples/sapper` ×4, `tixy`, `paint`), so this
describes the codebase rather than adding to it.

**`gui` is removed, not completed.** It was never requested; it was added for symmetry with the
table-driven builder that folded whatever it was handed — **the very shape this sprint
dissolves** — so it goes from code, tests and docs, leaving one debt-register line: supportable in
principle, purposefully unsupported. This **closes the decision P14d was carrying** (add `Key.gui()`
vs. read the pair vs. drop it) by dissolving the question, on the same ground Decision 30 gives for
the tracked set: not a requirement, therefore reverted. Two consequences are recorded rather than
hidden — registering a `gui` combo starts failing loudly at `check_combo` (`gui` reads as a second
trigger), and a Super press stops being modifier-shaped, so a registered `'ctrl+*'` class would
catch it where it does not today. **Decision 8 names `gui` in its precedence list**
(`decisions/input.md:392`) and is amended in place, session34's Decision-21 precedent.

### 14.2 Owner instruction, 2026-08-10 — the detached examples get a reconciliation step

`modHeld` (`examples/keyboard/input.lua:108-114`) re-implements `Key.ctrl()`'s folding over the
table being dissolved, so it is **deleted**, not converted. The general point the owner drew from
it: the three example repos are **detached** — separate repos with their own remotes and history,
no suite, and nothing that re-checks them when the platform moves — and the sprint owed no step
that reconciles them with the removal. P14e existed but was scoped to `keyboard` alone, so it is
**rescoped to all three** rather than a new row being added.

This is **not** the blanket example sweep the owner ruled out: the trigger is one named platform
change, and a repo with nothing to reconcile is recorded as clean and closed. The sweep run to
scope it found the reconciliation is real in two repos and empty in the third — `maze`'s
`is_shift_down()` is `Key.shift()` written out by hand, exactly the duplication `modHeld` is, and
`balloons` reads no held state at all.

**Still open, unchanged:** whether P14e must precede P9b (§13). The rescope does not settle it —
it makes the question slightly wider, since P14e now also touches `maze`, which P9b does not.

### 14.3 Owner rulings, 2026-08-10 — the examples step precedes the heal, and reaches in-repo

**The heal runs last.** §13 left open whether the examples step must also precede P9b, and it is
now ruled that it does: **P14a → P14c → P14d → P14e → P9b**. This is the third application of one
argument the owner has now made three times — the heal is designed against the *approved design*
(§12), then against *landed platform code* (§13), and now against *reconciled examples*. It is the
sharpest of the three, because the examples step and the heal edit the same file: without the
ordering, P9b would rewrite `examples/keyboard/input.lua` around a `modHeld` that is on its way
out.

**The step reaches the in-repo examples too.** The reconciliation is no longer detached-only. The
boundary is still not a blanket sweep, and it is worth stating precisely, because "no blanket
example sweep" remains a standing ruling: **what is swept is held-state reads, and the trigger is
two named changes** — the removal of the tracked set, and the corrected ladder. An example is
examined for those reads and for nothing else; one with none is recorded as clean and closed. No
example is reviewed for anything the sprint did not move.

The sweep that scoped it found the in-repo half is small and mostly already correct: `turtle` and
`clock` are the only conversions, `tixy` and `paint` already sit at the right rung, `pong` is
correctly at the last rung because it polls arbitrary keys, and five examples read no held state
at all. **`sapper` is the one judgement call** — four call sites repeating
`not Key.shift() and not Key.alt() and not Key.ctrl()`, which is precisely the cascade the guide
says combos exist to replace. ~~It is flagged rather than converted: it works, the conversion is a
real refactor of an example, and a sprint that removes a moving part should not add one in the
same breath. If it is not taken, it belongs in the debt register with that reasoning.~~
**[S35] RULED IN, later the same day** — the owner's reading is that the machinery *is* a set of
combos on the click channels, and the check that settles it is that a class key folds every held
modifier, so `'shift+*'` already means *shift and nothing else* — the cascade is spelling out a
match the framework performs. My deferral argument was weighed against that and does not survive
it: this is not "a real refactor", it is deleting a hand-rolled copy of the matcher. **The step is
§11.4.3**, including the two deviations the conversion accepts (derived clicks are left-button, on
release, after the window; unclaimed modifier combinations stop being inert).

**Note for the revalidation record:** `turtle` and `clock` were cited in `S35-spec-revalidation.md`
as evidence the rewritten guide was right (*"ask the keyboard is proven in-tree"*). That clean bill
is withdrawn — they were proof the guide taught the wrong rung, and they are now work items in this
step.

### 14.4 [S35] HINT (owner, 2026-08-10) — some of these reads are combos written out by hand

**The leads themselves are operative and live in §11.4.3**, with the examples step. This section is
the dated record: where the hint came from, the rule that makes it falsifiable, and why it is
capped.

The owner's observation was about `maze`'s `tab` poll. The scan it prompted found the same shape in
several places, and it is a **third instance of one pattern this sprint keeps meeting** — an
example re-implementing a framework mechanism over a lower-level API, exactly as `modHeld`
re-implements `Key.ctrl()`'s folding and `is_shift_down()` re-implements `Key.shift()`.

**The discriminator, so the hint stays falsifiable and does not decay into "polling is bad".**
*"Is it held right now"* — continuous, per-frame, no beginning or end — is a **correct** poll, and
the device is the right source for it; that is Decision 30's own argument. *"Did it just happen"*
or *"was it modified"*, reconstructed from a poll, is an **event or a combo written out by hand**.

Two shapes follow from it: a poll plus hand-rolled edge detection is `keypressed` by hand, and a
modifier test inside an event handler is a combo by hand. Both are enumerated in §11.4.3, together
with the reads deliberately **excluded** in each direction — the heal's own territory on one side,
and the genuinely correct polls on the other, which are what keep the rule honest.

**Why it is capped.** A hint like this can quietly turn a reconciliation step into an example
rewrite. The step's mandate remains the removal and the ladder; a lead is taken only where the
conversion is small and obviously behaviour-preserving, and anything else is recorded in the debt
register with its reasoning. **[S35] The example this paragraph originally used — `sapper`'s
cascade — was ruled *into* the step later the same day, so the cap now carries no standing
instance; §11.4.3 holds the ruling and the two behaviour deviations it accepts.**

### 14.5 [S35] Owner ruling, 2026-08-10 — a modifier's own press is accidental and unsupported

`S35-spec-revalidation.md` raised it as a spec gap (F3): nothing says whether pressing left Alt
still serialises as `'alt+lalt'` once the answer comes from the device rather than from the
gateway's first line. **The owner's ruling closes it by refusing the premise** — *"a corner case we
never seriously considered; it became an accidental rule, we do not have to support it."*

**What actually happens, recorded so it is not rediscovered as a defect.** The string is unchanged:
the device reports the key that is physically down at dispatch time, so the row folds to `alt` and
the raw trigger is appended — `'alt+lalt'`. **It matches nothing, and cannot.** `check_combo`
refuses to register `'alt+lalt'` (every token folds to a modifier, so it *"names no trigger"*), and
it refuses bare `'lalt'` for the same reason — which is also what the same-frame-release corner
produces when the poll already answers false. Both candidate strings are unregistrable, so the
lookup misses in every direction. **The class fallback is stopped by a ratified rule, not by an
accident:** Decision 21's own last sentence is *"a class never matches when the trigger is itself a
modifier"*, which `Key.is_mod(trigger)` implements. **[S35 correction]** What is accidental is only
that dispatch builds `'alt+lalt'` at all — that fell out of the gateway writing the set before
dispatch, and nothing ever ruled it.

**Consequences, placed where they act.** The corpus says nothing about this and **no test pins it**
(P14c) — pinning an accident is how it becomes a contract, and this feature has paid for that
before. The matcher may hoist the modifier guard above the string build, since nothing it could
find is registrable (P14d); that is a tactic recorded in the step, deliberately not in the
persistent docs.

**Why this is the right disposition rather than a fix.** Supporting the case would mean inventing a
meaning for a keystroke nobody asked about, in a sprint whose whole argument is that
implementation-time additions no stakeholder requested get reverted rather than completed — the
same ground Decision 30 gives for the tracked set and §14.1 gives for `gui`.

### 14.6 [S35] Owner instruction, 2026-08-10 — the framework's own shortcuts are a coverage gap

Raised by the owner while the tests step was being reviewed: *are any of the platform combos
tested anywhere?* Checked against the code rather than answered from memory, and the answer is
**almost none** — the enumeration and the current coverage are in the **P15** row, which is the
operative step. This section is the dated record of why it is worth doing and what it must avoid.

**Why it earns its place in a sprint that is supposed to be shrinking.** The stakeholder ask is a
*simpler and more robust* input API. The framework silently reserves keyboard combos that a project
cannot have, and until now nothing proved that any of them still works, nor that a project cannot
take one away. That is the robustness half of the ask, untested. It still **owes a
justification-table line**, because it grows the diff beyond the 187 remarks.

**The trap, written into the commission so a worker cannot fall into it.** The corpus says a global
shortcut *"fires its effect and the key still reaches the active route"* — true of the forwarding,
but several of these effects **tear the route down** (`stop_project_run`, `quit_project`,
quickswitch, restart). For those, the project's own handler legitimately never runs. Asserting a
uniform *"both fired"* would encode a falsehood. The honest pair of claims is: **a project cannot
prevent the platform effect**, and, separately, **where the effect leaves the route alive the key
still reaches it**.

**This is how the gap was found, and the provenance matters.** Making the test fixture hold
modifiers on the device (P14c's last commit) turned three cases red: they registered a project
shortcut on **`ctrl+s`** and asserted it fires, which in production it never does — the gateway's
`ctrl+s` stops the running project before dispatch reaches the route. They had passed only because
the fixture's device was blank. A fixture that lies produces tests that agree with it.

**One doc consequence, filed where it belongs, not here.** `doc/input_api.md` teaches
`shortcuts.keypressed['ctrl+s'] = ...` and never says which combos are already spoken for. That is
a gap in the **project-facing guide**, and it rides with **P10**'s doc work — see that row.

**Scoped down the same day, and the owner's reasoning is worth keeping.** Because the gateway
never suppresses — a project handler fails to run only as a **side effect** of a platform action —
the trap above is not something to test around, it is the *reason there is nothing to test on that
side*. What is left is one property: **a project cannot suppress a platform combo by naming it.**
Each combo's own effect is the framework's business, worth testing eventually and **not the duty
of this PR**, so those become `pending` outlines rather than assertions. This keeps a genuine gap
**named in the suite** instead of remembered in a plan document that gets deleted, and it keeps
the diff proportionate to a PR about the project-facing API.

**Consequence to state rather than let a successor find:** the suite's pending count stops being
3. The boot ritual in `agents/validation.md` treats a fourth pending as a finding, precisely so
nobody parks failures there; this is the sanctioned exception, and it is recorded in the step, in
the commit, and in `doc/development/tests.md`, whose pending table is the corpus's own record of
named gaps.

---

## 15. [S36] Amendments made in session36

### 15.1 Owner instruction, 2026-08-10 — the examples get an onboarding step, and P14e feeds it

Stated at the top of session36, while agreeing the reconciliation stays small: *"we'll have to
rewrite examples to onboard them into the new API. But I agree with starting small and sweeping
later. So add another step (for sweeping) into the sprint plan, and it will read from the tech
debt ledger section you fill in this step."*

**What this changes, and what it deliberately does not.** It does **not** reopen the ruling
against a blanket example sweep, and it does not widen P14e by a line. It settles what happens
to everything P14e *declines*: instead of an unbounded "somebody should look at the examples one
day", the declined conversions become an enumerated list in the persistent debt register, and a
planned step reads that list back. The cap on P14e (*small and obviously behaviour-preserving
conversions only*, §11.4.3) therefore gets a destination rather than a shrug — which is the whole
reason it is safe to keep the cap tight.

**Why the debt register and not this plan.** `wip/77` is transient and is not in the PR; the
register is in the persistent corpus and survives the tree's deletion. A deferred-work list that
lives only here would evaporate with the scratch, and the step that reads it would have nothing
to read. The register is also stakeholder-visible, which is correct for this content: it says
plainly that the examples were reconciled with a platform change but not yet re-taught by it.

### 15.1b Owner instruction, 2026-08-10 (same day, after the reconciliation landed) — the sweep splits three ways

Prompted by what the reconciliation and its cold revalidation actually found in `maze`: not a
list of one-line rung corrections, but a frame-time poll with a mirrored flag, two bindings
written as one guard, and a macro recorder keeping its own copy of Shift. The owner's redefinition:

> *"in-repo and balloons get common sweeping step (if design-heavy decisions surface in any
> example, it gets its own deferred step). keyboard and maze each get their own 'deepfix' step
> with separate planning, and keyboard's one absorbs 'healing textinput'."*

**Why this is better than the single sweep it replaces**, stated so a successor does not
re-litigate it:

- **The register's eight sites do not have one weight.** `turtle` and `clock` are rung
  corrections a sweep can carry; the two detached repos hold everything that needs a judgement.
  One step covering both would be planned to the wrong altitude at one end or the other.
- **It dissolves the ordering collision instead of sequencing around it.** The sweep and the
  `textinput` heal were going to edit the same file, `examples/keyboard/input.lua`; the previous
  version of this step raised that as an open question needing a ruling. Absorbed into one
  keyboard step, there is nothing to order.
- **The detached repos have no suite and their own remotes.** Separate planning is what their
  gate actually costs.

~~**The caveat this restructure must carry:** the heal is the sprint's blocking defect while
onboarding is optional, so §15.4 requires the heal to land first inside its step, committable
alone, and forbids reopening its ratified design.~~

**[S36] OVERRULED BY THE OWNER the same day, and the reasoning is the sprint's own.** *"P9b and
P18 target the same shared code, it would be weird to run them independently if both can change
the internal architecture of keyboard. The healing design is not set in stone yet and could be
revised prior to update."*

- **Sequencing them inside the step re-creates the problem the absorption removes.** Landing the
  heal first and then restructuring the same file is the churn the ordering rulings exist to
  prevent — the third application of *"fixing D against outdated logic is conceptually wrong"*
  (§13.1) was about exactly this file.
- **The design of record is an INPUT, not a frozen mandate.** `internals/examples/keyboard.md`
  was written before the onboarding facts were known; forcing the heal to land first would
  prevent the revision those facts might warrant, which is the opposite of what the absorption
  is for.
- **What survives of the caveat is priority, not structure:** the step is still what blocks the
  sprint's closure, so it is **scheduled ahead of the optional onboarding work elsewhere**. That
  is a scheduling statement about steps, not an ordering imposed inside one.

### 15.2 [S36] P16 in full — the common sweep: in-repo examples and balloons (OPERATIVE)

**This section is the step, not reasoning about it.** Amendments to the common sweep belong
**here**; §15.1 and §15.1b are the dated record of why it exists and are never where a change
lives.

**Scope: the in-repo examples and `balloons`.** The two detached repos with real work in them —
`keyboard` and `maze` — are **not** in this step; each has its own (§15.4, §15.3). `balloons` is
in scope and is expected to be a no-op: the reconciliation verified it reads no held state, and
the cold revalidation re-verified that independently. It is named so the sweep's coverage is
complete, not because anything is expected of it.

**The escalation rule, which is what makes this step safe to run as a sweep (owner, 2026-08-10):
if a design-heavy decision surfaces in one of THIS step's examples, that example gets its own
deferred step** — the sweep stops there, records what it met, and does not decide it. This is
P14e's cap with a destination rather than a shrug, and the same discriminator applies: convert
what is small and obviously behaviour-preserving; anything needing a ruling is not this step's
to make.

**[S36] The rule belongs to this step alone (owner correction, 2026-08-10).** It does not apply
to `keyboard` or `maze`: those two **already are** the escalation — each has its own step and its
own planning pass precisely because design-heavy work was found in them. Escalating out of a step
that exists to do design-heavy work would be circular.

> **[S36] PARTLY EXECUTED, 2026-08-11, under the adoption rules** (the principles proposal, §5),
> because the owner reopened this session's example work rather than leaving it to the sweep:
> `bd536eea` adds `Key.any_pressed` (breaking test first; suite 942 → 946) so a project has one
> surface for held state; `c04cbedf` moves `pong`'s three polls and its README snippet onto it;
> `dad70c30` records in `clock` **why its bindings stay in the hook** — converting them narrows
> the trigger and nobody asked for that; `f55ff340` teaches the new rung in the project guide,
> since new public API must not ship undocumented.
> **What remains for this step:** `turtle` (no change — it is the standing demonstration of the
> captured `love.*` path), the widget/validator-surface examples (out of the principles' scope,
> recorded as such), and any example the register still names.

**Input, and the only input.** `doc/development/technical_debt/input.md`, the section
*"Examples are not onboarded onto the new input API"*, written by P14e. Each entry names the
example, the site, the shape it is written in today, the shape the new API offers, and **why
P14e declined it** (too large, not obviously behaviour-preserving, or a behaviour question the
owner has not ruled). The step works that list; it does not re-derive it and it does not search
the examples afresh. **An example the register does not name is out of scope** — the same
discipline P14e runs under.

**What the step is for.** The examples are the API's worked demonstrations, and after the
dissolution several of them still teach the mechanisms the framework now provides: a poll plus a
mirrored flag where a `keypressed` shortcut answers directly, hand-written modifier matching
where a combo or a class key says it, frame-time machinery for a discrete question. Onboarding
them is what makes the examples agree with `doc/input_api.md`'s ladder rather than merely stop
contradicting the removed surface.

**Constraints carried from P14e**, because they are what keep this a sweep and not a rewrite:

- **Per-entry, not per-file.** Each register entry is a unit of work and, where the behaviour
  question is real, its own commit stating the deviation — the discipline `sapper` set.
- **Behaviour deviations are stated up front, never discovered in the smoke pass.** The detached
  repos carry **no test suite**; the app run is the only gate, so what changed must be written
  down before it is run.
- **The three detached repos commit on their own and are NEVER pushed** — `keyboard`, `maze`,
  `balloons` (`pr-assembly-guide.md` §5).
- **An entry may be declined again.** Re-declining is a legitimate outcome; it stays in the
  register with the fuller reasoning this step can now give. What is not legitimate is silently
  dropping it.

**Gate.** Every touched example smoke-runs; the platform suite stays green and stated; each
worked entry is either removed from the register (done) or amended (declined again, with why).

**Ordering — free.** ~~OPEN, needs an owner ruling: this step and the heal edit the same file.~~
**[S36] Dissolved by the split (§15.1b):** the file both wanted is the keyboard example's, and
that repo is no longer in this step at all. Nothing in this step's scope is touched by any other
open step, so it may run whenever the owner wants it — including before the two deepfixes.

### 15.2b [S36] P19 in full — the sapper deepfix (OPERATIVE)

**This section is the step.** Amendments belong here.

**Why it exists: the escalation rule fired, on its first day.** P16's rule — *a design-heavy
decision surfacing in one of the sweep's examples sends that example to its own step* — was
written for exactly this and met it immediately. `sapper` is in-repo, so it would otherwise have
been swept.

**What happened, because the step must not repeat it.** P14e converted sapper's four-site modifier
cascade to class shortcuts on the derived single-click channel, ruled in on the reading that the
cascade was combos written by hand. That reading was right about the **shape** and wrong about the
**purpose**, and the purpose was written down nowhere: **the modifier-held press is a touch
fallback** — on touch devices a single tap is often accidental and a double tap unreliable
(author, 2026-08-10). Derived clicks are button 1, on release, after the double-click window, and
**dropped on drift** — the very mechanism the press path exists to bypass. **The conversion was
reverted** (`f61ada67`); against the example's original import the file now differs only in the
two registration lines the feature changed API-wide.

**[S36] IT ALSO OWNS A LIVE DEFECT, found while reviewing the principles proposal.** Shift-click
flags at press; the derived single click arrives 0.4 s later; if Shift is released inside that
window the derived click is unmodified, passes the hook's own guard, and runs the action again —
and flagging **toggles**, so the cell is un-flagged. **Shift-click appears to do nothing if the
player lets go of Shift promptly.** This is in the example as written, predates the feature, and
is independent of any conversion: it is not a reason to convert, and converting does not fix it.
Enumerated in the register entry below.

**What this step owes.** The full analysis is in the persistent register —
`technical_debt/input.md`, *"sapper's modifier click path is a touch fallback, and converting it
needs the platform's help"* — and it is the input, not this summary:

- the correct shape (press path kept as a class shortcut on the `mousepressed` channel, derived
  echo swallowed, because **consuming a press does not stop the derived click**);
- the **hole that remains** (a derived click samples its modifiers at synthesis time, so a
  modifier released inside the double-click window makes the echo arrive unmodified and act
  twice), and a ruling on which way to close it — a project-side flag, or a platform change
  carrying the originating press's modifiers into the derived event;
- **whether to convert at all.** Leaving it is a legitimate outcome: the guards work, and the
  code is the author's.

**Not a platform step by default.** If the ruling is "the platform carries the press's modifiers",
that is a framework change, outside this feature's mandate, and it is **promoted to the parent
plan** rather than done here (§0's rule for release-shaped work).

**The example belongs to another author** (`918c87f6`, aldum). A behaviour change here is one they
would be the first to notice, so it wants their eyes before it lands — and the PR description owes
a line about it either way (§11.7).

### 15.3 [S36] P17 in full — the maze deepfix (OPERATIVE)

**This section is the step.** Amendments belong here.

**[S37] P-17-00 — merge, evaluate, plan.** The maze upstream (`dsent/dsent/dev`) is fetched and
not merged. Before any of this step is designed: **merge it, evaluate what it changed about input,
and plan from the merged tree** — the same three moves `keyboard` had, in that order, and for the
reason that one proved: there, the reading came first and the merge then landed a defect the
design would otherwise have met afterwards. Precedent and method:
`P-18-00-keyboard-deepfix-design.md` and `S37-keyboard-upstream-input-assessment.md`.

**What it is.** `src/examples/maze` (detached repo, own remote, **no suite**, never pushed) needs
more than a rung correction, which is what the reconciliation found and what prompted the split.
**It gets its own planning pass before any code moves** — this section is the step's charter, not
its design.

**Its material, from the register** (`technical_debt/input.md`, §"Examples are not onboarded onto
the new input API"): the `tab` poll with its `tab_was_down` mirror deriving an edge that
`shortcuts.keypressed['tab']` states directly; Shift+Escape versus bare Escape, which is two
bindings written as one guard and which moves `escape` out of `SYSTEM_KEYS`; and the macro
recorder's own `shift_held` mirror — **listed by adjacency, not by the reconciliation's trigger**
(it reads no device and never touched the framework's set), and not a pure read either, since its
release side runs `finish_recording()`.

**[S36] An owner `REMARK:` in that repo asks this step's question directly** —
`maze/main.lua`, *"can we try using shortcuts/hooks and callbacks more actively?"*. It is the
onboarding question in the owner's own words, standing in the file the step works. **The planning
pass answers it and retires the marker** (markers must be zero before the PR); a second remark in
the same file, about an over-verbose comment, is editorial and belongs to the comment sweep.

**What its planning pass owes before it executes:** what each conversion changes for a player,
whether the poll-to-shortcut moves are behaviour-preserving at frame boundaries, and what the
smoke pass must exercise — because running the app by hand is the only gate this repo has.

**Independent of the keyboard step.** They share no file; either may go first.

### 15.4 [S36] P18 in full — the keyboard deepfix, which absorbs the `textinput` heal (OPERATIVE)

**This section is the step.** Amendments belong here.

**What it is.** `src/examples/keyboard` (detached repo, own remote, **no suite**, never pushed)
gets one step covering both the heal and its onboarding, because both rewrite `input.lua` and
sequencing them against each other was already an open question this split removes. **It gets its
own planning pass** before code moves.

**The absorption is total: one step, one planning pass, one design (owner, 2026-08-10).** The
heal and the onboarding **both change the internal architecture of the same file**, so they are
planned together and neither is sequenced against the other inside the step:

- **The heal's design of record is an INPUT, not a mandate.**
  `doc/development/internals/examples/keyboard.md` — `textinput` is the only judge, two fields,
  writes blocked across the win transition, no clock and no held-set read — was written before
  the onboarding facts were known. **This step MAY revise it**, and the owner has said so
  explicitly: it is not set in stone. What it may not do is drift from it silently — a revision
  lands **in that document, with its reasoning, before the code that assumes it**.
- **No internal ordering is imposed.** The planning pass decides what lands first; the standing
  commit rules still hold (one concern per commit, a production fix with its breaking test).
- **What survives of the priority concern is scheduling between steps, not inside this one:**
  this step is what blocks the sprint's closure, so it goes **ahead of** the optional onboarding
  work in P16 and P17 unless the owner says otherwise.
- **The escalation rule of the common sweep does NOT apply here.** This step *is* the escalation;
  design-heavy work is its subject, not an interruption of it.
- **P9b's own row and history stay** (§4, and §7's rewritten design): amended and pointed here,
  never deleted.
- **The smoke checklist** in the design document is owed by a human either way — this repo has no
  suite.

**Its onboarding material, from the register:** `alt.lua:203` hand-matching the combo its own
comment calls Ctrl+Alt+H; `helpHeld`, which spans frames and is therefore the guide's
flag-shortcut shape rather than a poll; and `isMod`, which re-implements `Key.is_mod` and is used
from three files. The heal rewrites the file all three live in, which is exactly why they are here
and not in the common sweep.

**[S36] And the design question the owner already wrote into the file: `input.lua`'s
`REMARK: WHY WOULD WE DO IT AND WHY USE custom 'INPUT' at all?`**, sitting on the `INPUT` proxy
itself. **The reconciliation is what made it answerable:** the proxy is now three branches
returning `Key.shift()` / `Key.ctrl()` / `Key.alt()`, so "delete it and call `Key.*` at the nine
read sites" is a concrete option where before it wrapped a framework surface that has since been
dissolved. It was deliberately left standing — deciding it is design work, which is this step, not
the reconciliation.

**[S36] OWNER'S INTENT, 2026-08-10: dissolve it.** *"`INPUT` is simply duplicating `Key`."* It is
a pure alias now — it wraps nothing, and every branch returns what `Key` returns. **The work is
ten sites, mechanical:** the three proxy branches plus `input.lua:192,193,195,197`,
`alt.lua:203,230,240` and `keyboard_view.lua:171,178` become `Key.*` calls, and
`help.lua`'s `helpHeld` loses its `INPUT.alt` / `INPUT.ctrl` with them. `INPUT.upRecent` is the
one member that is genuinely the example's own — it survives the dissolution as a plain table (or
moves wherever the heal puts its state), and **the heal may well delete it outright**, since the
ratified design subtracts `INPUT.upRecent` and `INPUT_UP_GRACE`. **Sequence it with the heal
rather than before it.** The marker is retired by the work. The other marker in that file
(`setTextInput`, an IME toggle) is a separate question and is not this step's unless the heal
touches it.

##### [S36] `INPUT.upRecent` — what the proxy's one real member does, traced

Written down because the dissolution above hinges on it and because it is the one member that is
not an alias. **It is a per-key table of the frame on which that key was last released**, and it
serves the Alt-keys scene's glyph judging:

- **Why it exists.** That scene judges what the player typed from `textinput`, and **`textinput`
  carries no `isrepeat` flag** — only `keypressed` gets one, as its third argument. So while a key
  is held the OS emits a stream of identical glyphs and the example must accept exactly one per
  physical press. `GLYPH_CLAIMED[k]` does that: claimed on the first glyph, released on keyup.
- **What `upRecent` adds:** the release boundary. A final repeat glyph can arrive *just after* the
  keyup, when the claim has already been dropped, so it would read as a fresh press and be judged
  as a keystroke nobody made. `spendGlyph` therefore drops any glyph landing within
  `INPUT_UP_GRACE` (= 1) frames of the recorded keyup — a one-frame deadband per key.
- **Its cost, already known:** a genuinely fast re-tap inside that window is dropped too. The
  design note's smoke checklist names it (*"a very fast tap of the target character registers —
  the case the shipped code drops"*).
- **Its clock is `DBG_FRAME`** — a counter incremented in `main.lua`'s update whose other use is
  timestamping debug log lines. A judgement mechanism keyed off a debug counter.
- **Reach, verified rather than assumed:** created at `input.lua:56`, reset at `:101`, written in
  exactly one place (`appKeyreleased`, `:176`), read in exactly one place (`spendGlyph`,
  `:149-150`), and `spendGlyph` has a single production caller (`alt.lua:173`). No `INPUT[...]`
  dynamic access exists anywhere in the repo, and `upRecent` is a **raw field**, so the
  metatable's `__index` never fires for it — it cannot be reached by the string-keyed path that
  serves `shift`/`ctrl`/`alt`. That matters here: string-keyed metatable dispatch is precisely
  what the LSP does not see, so this was checked with grep.
- **Consequence for this step:** the whole apparatus — `upRecent`, `INPUT_UP_GRACE`,
  `GLYPH_CLAIMED`, `spendGlyph` — is one self-contained mechanism serving one scene, which is what
  makes the ratified design's plan to **subtract it wholesale** credible rather than risky. It is
  also a frame-time inference about a key's state, the shape this sprint removed everywhere else.
  **So the proxy dissolution rides with the heal:** if the heal lands first, `upRecent` is gone and
  the proxy has nothing of its own left to preserve.

##### [S36] `helpHeld` — the trap in the obvious conversion, and why it is not a rung swap

The register lists `helpHeld` as *"spans frames, so the flag-shortcut shape is the top rung"*.
That is true and it understates the problem. The obvious conversion —
`shortcuts.keypressed['alt+h']` sets a flag, `shortcuts.keyreleased['alt+h']` clears it — **leaks
on one of the two release orders**, and the leak is not fixable with a second shortcut:

- A combo is serialised from its trigger **plus whatever modifiers are held at that instant**,
  asked of the device. Release `h` first and the event serialises as `'alt+h'`: the binding fires,
  the flag clears. Release **Alt** first and two things happen — `keyreleased('lalt')` is a
  modifier's own release, which `find_shortcut` refuses outright (`Key.is_mod(trigger)`), and the
  later `keyreleased('h')` serialises as plain `'h'`, missing the `'alt+h'` binding. **The flag
  stays set and the overlay sticks.**
- **There is no binding that closes it.** A modifier's own press or release has no expressible
  combo at all (Decision 21's one-trigger rule — `'alt+lalt'` and bare `'lalt'` both raise), so
  "clear when Alt goes up" cannot be written as a shortcut. The available fixes are a
  `keyreleased` **hook** clearing on `not Key.alt()` — a poll in event clothing — or a second bare
  `'h'` clearing path, which is two bindings for one fact.
- **Focus loss leaks the same way**: no release is delivered, so the flag survives with nobody to
  reconcile it — the exact bug class this sprint removed from the platform.
- **What the poll has that the flag does not:** it is a pure function of live device state, so it
  self-heals from both. The overlay's contract is *"up for exactly as long as the keys are"*,
  which is the question a poll answers correctly (Decision 30's own argument, one level down).

**So the step's choice is a design decision, not a rung correction**, and the honest options are:
keep the poll and say why in the file; adopt the flag with a hook-based clearing path stated as
such; or wait for the general mechanism the owner has sketched (`technical_debt/input.md`, *"A
chord that gates a state while it is held has no vocabulary"*), which is explicitly **not this
release**.

##### [S37] P-18-00 — the step's own analysis and design pass, IN PROGRESS

**Document: `../P-18-00-keyboard-deepfix-design.md`** (same directory as this plan's siblings under
`validation/reviews/`). It carries **the agenda for the whole step** — the seven items and the one
explicitly not reopened — and the exposition the owner asked for before any shape is proposed: the
**two `love.textinput` consumers** (`alt.lua` and `words.lua`) read side by side in terms of events,
payloads and named functions. Decisions are recorded there one at a time as the owner takes them;
nothing in it is settled by drafting.

**Its headline, because it decides item 2:** the ratified design's rule *"if `text == lastText`,
stop"* is a **content** test, valid only under the precondition its own document states — *"every
target is a single character… if a later stage ever asks the player to type a word, this design
must be revisited"*. **`words.lua` is that violation and it is now in the tree**: typing `"all"`
would have its second `l` discarded. `spendGlyph` is a **press-identity** test and does not have
that failure, at the cost the document also names. Which property the shared layer provides is
open.

##### [S37] The upstream merge landed first, and it moved this step's material

The gating pull (parent plan, Phase U example half) was ruled to session37 and **executed
2026-08-11**, before any of this step was designed. The full reading of what upstream did to the
input model is `../../validation/reviews/S37-keyboard-upstream-input-assessment.md`; what follows
is only what changes **this step**.

- **`keyboard` @ `17289e9`** — a true merge of `origin/dsent/dev` (36 commits, 24 files,
  +5227/−804), ancestry preserved deliberately so later re-merges stay cheap; the upstream
  snapshot is on its own branch `upstream-dsent-dev-20260811`, and the pre-merge state is
  `05cedec`. No textual conflict: upstream never touched `input.lua` or `help.lua`.
- **THE HEAL NOW HAS TWO `textinput` JUDGES, NOT ONE.** Upstream's new `words.lua` judges typing
  through `textinput`, exactly as `alt.lua` does. The design of record
  (`internals/examples/keyboard.md`) was written when Alt was the only judge and its subtraction
  list (`spendGlyph`, `GLYPH_CLAIMED`, `INPUT.upRecent`, `INPUT_UP_GRACE`) is stated in those
  terms. **Whatever replaces the claim must serve both scenes, or each must carry its own
  judgement state and the document must say so.** This is the revision the step was told it may
  make; it lands in that document, with its reasoning, before the code assumes it.
- **`words.lua` carries an interim call this step is expected to DELETE, not preserve.** It
  arrived calling `inputStale` — the held-key filter this branch removed — so the clean merge
  produced a tree that raised on the first glyph typed. Corrected at **`ca6d5df`** by routing it
  to `spendGlyph`, with the reasoning in the file above the call and the deletion announced
  there. Do not treat that line as settled shape.
- **Counts moved.** The `INPUT` dissolution is **eight sites, not ten** — upstream's `619c8cf`
  deleted the board's shift-label read, taking `keyboard_view.lua`'s second site with it.
  `isMod` is **six call sites across five scene files** (`findkey`, `astrocore`, `hide`, `train`,
  `bubble`, plus `alt`), each paired with a hand-written `k ~= "capslock"` test — one decision to
  make, six places to apply it.
- **`bubble.lua` is new material and is recommended OUT of scope.** It judges a key by **how long
  it is held** (press sets, release scores, update accumulates, timeout pops). It is
  event-derived held state, but with bounded drift, and **it cannot be expressed with anything
  the API offers** — it is an independent second use case for the register's *"a chord that gates
  a state while it is held has no vocabulary"*, found by the example's author. Cite it there;
  do not convert it.
- **One new item, owner's call whether it is this step's:** upstream added
  `love.mouse.setRelativeMode(true)` at boot, commented *"the runner restores it on exit"*, which
  is **false against this branch** — `stop_project_run` makes no `love.mouse` call. The
  example-side half (restore it in a `before_exit`, or stop claiming) is small and fits here; the
  question of whether the framework should tear down device modes is release-shaped and is
  promoted, not answered.

**Independent of the maze step.** They share no file; either may go first.

---

## 16. [S36] REPLAN after Decision 32 (2026-08-11)

The owner ratified the usage principles as **Decision 32** and promoted them to the persistent
corpus. This section replans the remainder against them. **§4 remains the operative table**; this
section is the reasoning, and every change it describes is written into the rows themselves.

### 16.1 What changed under the ratification

- **The examples are no longer "not yet onboarded"; they are dispositioned.** `pong` moved onto
  `Key.any_pressed`; `clock` was ruled *not* to convert, with the reason in the file; `turtle` is
  unchanged by ruling (it is the standing demonstration of the captured `love.*` path); `sapper`
  was reverted and escalated. What the sweep once meant — "work the register list" — is largely
  spent.
- **One filed recommendation was inverted by the ratification**: the keyboard example's help
  overlay was listed as wanting the flag-shortcut shape; under Decision 32.2/32.4 **the poll it
  has is correct**. Register updated; that is now a *closed* entry, not deferred work.
- **The rich query primitive is NOT in this release** (Fable's verdict, owner's ruling).
  `Key.any_pressed` landed — one wrapper so a project has a single surface — and the
  token-language predicate stays a register proposal. **No step owns it.**
- **The guide changed shape**: §"Shortcuts that set a flag" is gone, replaced by §"Choosing the
  mechanism". Later work citing the old heading is citing something that no longer exists.

### 16.2 The remaining work, and what it actually costs

**The dominant cost is prose, not code.** Measured 2026-08-11: **27** `REMARK:`/`INTERIM:` markers
in `src/`+`tests/`, and **84** in the persistent doc corpus — 33 in `internals/user_input.md`, 30
in `decisions/input.md`, 8 in `doc/input_api.md`, the rest one or two per file. The comment gate
says all of them are zero before slice regeneration. **That is the largest single block left, and
it is bigger than everything else in the sprint combined.**

**[S36] RESOLVED IN PRACTICE, 2026-08-11.** The disposition pass (`../outcomes/S36-marker-disposition.md`) bound every marker to a plan, and the owner's own framing settled the rule it used: **prose size has its own sweep in the parent**, so the editorial bulk — one vocabulary sweep, one archaeology sweep, compression — is the parent's, while the code markers, the project guide's, and anything **factually wrong about input behaviour** are this sprint's. That is reading (c) with (b)'s floor. **The binding table is the ruling; this paragraph is its rationale.** The three readings are kept below as the record of what was weighed:

- **(a) Clear all 111.** Truest to the gate as written; the largest cost by far.
- **(b) Split by audience.** Clear `src/`+`tests/` (27) and the project guide (8) before the PR —
  the code, and the one document a stakeholder is promised — and let `internals/` and `decisions/`
  remarks ride a follow-up doc pass named in the PR description.
- **(c) Split by kind.** Clear every marker flagging something **false or misleading**; defer the
  purely editorial ones ("retire this word", "compress this paragraph"). A note-to-self shipping
  is untidy; a false statement shipping is a defect.
- **Assistant's recommendation: (c) with (b)'s floor** — code and guide fully cleared; in the
  dev-facing docs everything factual cleared and the editorial remainder deferred **as a named
  list**, not as silence.

### 16.3 The sequence — and which plan owns each part

**[S36] Corrected 2026-08-11 (owner).** An earlier draft of this section listed parent-plan phases
inside the sprint's own sequence. That is the conflation §0 exists to prevent: **this document is
the spinoff sprint — removing known defects and driving adoption. `../plan.md` is the release
plan.** Both may be altered; neither absorbs the other. What follows is split accordingly.

#### Owned by THIS sprint (defect removal and adoption)

1. **The upstream pull for the two detached example repos comes first** — see the note under
   *Owned by the parent* below. It is the parent's work, but it **gates** steps 2 and 3 here.
2. **P18 — the keyboard deepfix, absorbing the heal.** Still what blocks this sprint's closure.
3. **P17 — maze deepfix** and **P19 — sapper**: independent of each other and of P18. P19 also
   owns a **live defect** found 2026-08-11 (shift-click un-flags itself if Shift is released
   inside the 0.4 s click window).
4. **P16 — closes on one ruling**: whether `turtle`'s `ctrl+escape` binding is deleted as
   redundant, the framework reserving and acting on that combo without consuming it.
5. **P10 — docs and ledger**: the reserved-combo section the guide has never had, W9's ledger
   work, W10 batches 1/2/4, and this sprint's share of the marker question (§16.2).
6. **PROBE** — delete the diagnostic whose own header says to delete it once the polling question
   is ruled. **P9c** — the two order-dependent test cases, now that the suite moves have landed.
   **P13** — harmony revalidation, which matters because harmony is outside `busted` and outside
   CI, so a regression there **ships silently**.
7. **P11 — the comment sweep over `src/` and `tests/`**, which is this sprint's half of the marker
   work: 27 markers, and the gate for them is unambiguous.

**The sprint closes when the above are done.** It does not close on the PR.

#### Owned by the PARENT plan (the release)

- **Phase U, example half — pull and reconcile the two detached repos.** Positioned before this
  sprint's P17/P18 by the owner's intent and the stale-base argument; it is parent work that gates
  sprint work, which is the only crossing point in either direction.
- **Phase U, platform half** — upstream reconciliation of the framework repo, after the tree
  settles.
- **Phase L — ledger compaction** (inserted 2026-08-11).
- **The prose sweep over the persistent docs.** The 84 markers in the doc corpus are largely
  *editorial* — one vocabulary sweep, one archaeology sweep, prose-size complaints — and prose
  size has its own sweep in the parent. **They are the parent's, not this sprint's**, except where
  a marker flags something factually wrong about input behaviour, which is P10's.
- **Phase G — PR assembly**, slice regeneration last, then review and smoke pass. **N+1 PRs**: each
  detached repo opens its own alongside the platform's, and their only gate is a human smoke pass.

### 16.4 What the PR description now owes that it did not before

- A justification line for **`Key.any_pressed`** — new public surface, however small.
- A line for **Decision 32**, a decision this sprint minted, and for the amendment it makes to
  Decision 30 point 3.
- The effect of **Phase L**: if the collapsed decisions are excised, the description says a
  question was asked and answered, rather than leaving five decisions about a withdrawn surface to
  read as churn.
- **`sapper`'s live defect** and whatever P19 rules, since that example belongs to another author.
