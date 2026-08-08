# S27 — remark triage and execution plan

**Input:** `../outcomes/S27-remark-inventory.md` (187 remarks, ids R001–R187,
verbatim, extracted by a read-only sub-agent) and
`../reviews/S26-TF2-smoketest-results.txt` (the owner's smoke test).
**Commission:** `../prompts/S27-human-commission.md`.
**Author:** session27 (parent). Severity and workstream assignment are this
session's judgment; the inventory's "provisional kind" was a hint only and is
overridden wherever it disagrees.

Every id is assigned to exactly one workstream (coverage table, Appendix A).

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
| **P8** | W8 — test restructuring. **PART DONE**: R058/R059/R060/R061 (tracer + matrix supersession), R067 (NFR narrowing), R068 (blind row), R070 (before_exit contract). **Left:** R057 (three-surface grouping), R074/R078/R079 (merge / dissolve), R047, R063, R064, R069, R075 | P2–P7 | do NOT restructure tests before the code stops moving |
| P9 | W11 — examples and nested repos, one commit per repo | P2–P5 | **[REV]** the three nested repos carry **no automated tests** — one static spec doc, no runnable suite. Committing is not verification: a smoke re-pass on the channels W1/W2/W3 touch is the gate, `examples/keyboard` at minimum. Never pushed. **[S28] PART DONE** — SM1/SM2 ruled no-change, SM3b explained, SM4 pinned by a suite row, SM5 fixed (`3a9d48c`); SM3a left open, needs one runtime check. Evidence: `../notes/S28-smoke-findings.md` |
| **P9b** | **keyboard: judgement decoupled from delivery order** (owner design, 2026-08-07) — **NEXT TO EXECUTE**. **[S29] The design was rewritten on 2026-08-08 and the old one discarded** — see §7 amendment 3. Now: `textinput` is the **only** judge; two fields (`lastText`, `blocked`); writes blocked across the win transition; `keypressed` feeds the non-printing targets into the same judging function; `keyreleased` holds no judgement state; **no clock, no grace window, no held-set read**. Subtracts `spendGlyph`, `GLYPH_CLAIMED`, `INPUT.upRecent`, `INPUT_UP_GRACE` and `altPlayKey`'s judging path | P9 | design of record, in the **persistent** corpus: `doc/development/internals/examples/keyboard.md`. Nested repo, **no suite** — reasoned, not proven; smoke checklist is in the design note. No platform change. **[S29]** One game-side change comes with it: `gaugePick` must not present the same character twice in a row |
| **P9c** | **[S29] The two order-dependent rows this feature owns** (owner, 2026-08-08). Under `--shuffle`, `inbound events — Ctrl+Esc quits the app when nothing is left to go back to` and `inbound events — shortcuts and clicks — a shortcut fires but does not consume (#disputable)` fail. Find what state each depends on and who leaves it; fix or document per row | P9b | **before the PR.** The suite-wide order dependence is separate and pre-dates the branch — filed as persistent debt (`technical_debt/general.md`, "The test suite passes only in declaration order") and explicitly **not** in scope here. In scope: only rows this branch adds |
| P10 | W9 + W10 (1,2,4) — docs, ledger, vocabulary | P2–P9 | docs describe the final code, so they come after it. **Tombstone decisions, never renumber** |
| P11 | W12 — comment sweep, slices, revalidation ×2 | P10 | the commission's (e)–(9) |

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
