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

**Open for the owner:** delete Decision 9 entirely (R099) or keep it, rewritten
to record that the argument was *considered and dropped*? My recommendation is
**keep, one paragraph** — the ledger's value is that a future reader stops
re-proposing it.

### W2 — Pointer shortcuts: modifier-only combos · **S1**

**Members:** R037, R115, R131, R145, R152, R177.

Six remarks in two docs and one source file say the same thing, and the owner
named it in-session as something believed agreed that is not in the code. It is
not: `find_shortcut` returns nil for a missing table, pointer channels pass
`trigger = nil`, and `doc/input_api.md` §"Pointer and click hooks" argues
affirmatively that pointer shortcuts *cannot* exist because "a combo needs a
key to name."

**Verdict: accept, and the doc's argument is wrong.** A combo does not need a
trigger key — `combo_string('*', keys)` already builds a triggerless class key
for the `alt+*` wildcard, so the machinery exists. Pointer combos are the same
serialisation with the modifier set and no trigger.

**Genuinely open, and I want the owner's call (R037 asks both):**
- **Button in the combo.** `ctrl+mouse1` vs a modifier-only `ctrl+*` that any
  button matches. Naming buttons makes right-click bindable — which is exactly
  what the paint smoke-test finding (SM1) needs — but it introduces a second
  trigger vocabulary alongside key names.
- **Which channels get a tier.** `mousepressed` clearly. `mousemoved` and
  `wheelmoved` are less obvious and a shortcut firing per motion event is a
  performance question, not a design one.

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
anything, and `hook_pointer` reads as a leftover. `ProjectInputController`
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

Confirmed in code: `submit()` calls `run_callback(self, 'before_submit', …)`
and **discards the return**, while `cancel()` honours `before_cancel`'s truthy
return as a veto. The docs describe the asymmetry as deliberate ("veto
reserved, unbuilt (R9)"). The owner's position across three remarks is that a
callback documented as vetoing must veto.

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
refuse to stop" says no. **I recommend no**, and fixing the doc that calls it
"deferred functionality".

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
possible source is `is_shown()`. I may be wrong, and this is one I want a cold
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
project widget?), R135 ("projects cannot install evaluator objects" — projects
*can* configure a validator), R110 (a note calling `dispatch` non-reusable when
it is), R127 (`before_exit` cannot guarantee teardown if the project raises —
identified in session24, never written down). Each is a factual claim to check
in code and correct.

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
| SM3 | maze: Ctrl shadows the screen; nav symbols glitch when launched from another project | **S0** — "launched from another project" is a route-teardown smell, exactly the class session26 fixed four of |
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

| # | Phase | Depends on | Gate |
|---|---|---|---|
| P0 | Answer the S0s: verify R044, R068, R033/R171 against `3256aac` and the current tree; reproduce SM1, SM3, SM4, SM5 | — | evidence note on disk before any fix |
| P1 | **Owner rulings** on the W2 open questions (button in combo; which channels), W5 (`before_exit`), W6 (R080), W1 (delete Decision 9?) | P0 | **blocks P2** |
| P2 | W1 — signature unification, incl. `ignore_repeat` and the examples | P1 | breaking test first |
| P3 | W3 — one event list, seeding and wipe generic | P2 | |
| P4 | W2 — pointer shortcut tier | P1, P3 | |
| P5 | W5 — `before_submit` veto + callback defaults | P1 | |
| P6 | W4 — dispatch/wiring collapse | P2–P5 | behaviour-preserving; suite is the proof |
| P7 | W7 — controller structure, incl. the 16-line rule in `agents/rules.md` | P6 | |
| P8 | W8 — test restructuring | P2–P7 | do NOT restructure tests before the code stops moving |
| P9 | W11 — examples and nested repos, one commit per repo | P2–P5 | each nested repo committed in its own repo, never pushed |
| P10 | W9 + W10 (1,2,4) — docs, ledger, vocabulary | P2–P9 | docs describe the final code, so they come after it |
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

## Appendix A — id → workstream coverage

W1 R009 R036 R096 R097 R098 R099 R112 R114 R146 R176
W2 R037 R115 R131 R145 R152 R177
W3 R022 R027 R029 R030 R035 R154
W4 R021 R023 R024 R025 R026 R028 R031 R033 R171
W5 R038 R121 R122 R158 R160 R161 R181
W6 R080 R086
W7 R004 R005 R006 R008 R011 R012 R014 R015 R016 R017 R018 R019 R020 R039
   R040 R041 R042 R043 R044 R045
W8 R047 R057 R058 R059 R060 R061 R063 R064 R067 R068 R069 R070 R074 R075
   R078 R079
W9 R093 R094 R105 R107 R109 R110 R127 R134 R135 R165 R166 R167 R168 R169
   R170 R172
W11 R118 R120 R123 R124 R125 R183 R184 R185 R186 R187 + SM1–SM5
W10 every id not listed above (92): R001 R002 R003 R007 R010 R013 R032 R034
   R046 R048 R049 R050 R051 R052 R053 R054 R055 R056 R062 R065 R066 R071
   R072 R073 R076 R077 R081 R082 R083 R084 R085 R087 R088 R089 R090 R091
   R092 R095 R100 R101 R102 R103 R104 R106 R108 R111 R113 R116 R117 R119
   R126 R128 R129 R130 R132 R133 R136 R137 R138 R139 R140 R141 R142 R143
   R144 R147 R148 R149 R150 R151 R153 R155 R156 R157 R159 R162 R163 R164
   R173 R174 R175 R178 R179 R180 R182
