# Archive — decisions vacuumed from the ledger

**What this is.** Entries removed from `doc/development/decisions/input.md` and kept here rather
than deleted, under `agents/rules/ledgers.md` — *"vacuuming is a move, not a deletion"*. Nothing in
this file rules anything. It exists for three reasons the owner stated on 2026-09-02: **traceability**
of what the ledger used to contain, **evidence of the scope of work actually done** — a vacuumed
entry is a piece of work that happened and left no other trace — and **retrospective analysis**,
which needs the drafts and not only the result.

**It leaves the release on purpose.** This file lives under `wip/`, so it goes when the feature's
working tree is deleted. Until then it can be carried in a copy of the branch alongside `wip/` by
anyone who wants the history. **The persistent corpus is the ledger; this is not a second one** —
if the two ever disagree, the ledger is right and this is a record of something that stopped being
true.

**How to read a number here.** These entries predate the numbers→names conversion of 2026-09-01
(`DEC-01`), so they cite each other and their successors by number. The crosswalk at the end of
`decisions/input.md` translates every one of them.

---

## Vacuumed 2026-09-01 at `DEC-01-04` (`9c8cc631`), archived retroactively 2026-09-02

All six were retired entries that no longer ruled anything, and none came from a stakeholder — the
condition `ledgers.md` §2 puts on the sweep. **They were deleted outright**, because the move-to-archive
mechanic did not exist yet; it was added the next day and this section is what it would have produced.
Their content, where it was worth keeping, was rehomed first: the held-key arc into
`D-ASK-THE-DEVICE`, the `inspect` narrative into `internals/user_input.md`.


Decisions that no longer rule anything. Five of the six were superseded in full by a later
decision, named right in the retired heading; the sixth, Decision 12, is kept as a correction —
its own heading says NOT A DECISION — because in-tree comments cite it by number even though it
never ruled anything. Each entry below keeps its original number and its full text unchanged;
follow the heading's own pointer to see what stands in its place.

## Decision 9 — uniform signatures and `isrepeat` threading — SUPERSEDED by Decision 26

**SUPERSEDED, 2026-08-07** — see Decision 26. The number is kept so the citations that name it
still resolve; the content below is what was decided, not what the code does.

**Decision (superseded).** Every participant on a channel receives the same signature, the widget
included: keypressed carries `(k, keys_pressed, isrepeat)`, textinput `(text, keys_pressed)`,
keyreleased `(k, keys_pressed)`. On the project route, `isrepeat` is threaded through every
component of the chain (Decision 2).

**Why it was decided.** A single signature per channel is the uniformity that lets the widget be
just another participant rather than a special case. `isrepeat` was restored so a project can
distinguish a held-key repeat from a fresh press.

**Why it did not survive.** The signature was uniform across compy's three keyboard/text channels
and different from LÖVE's on all of them, while pointer channels already passed LÖVE's arguments
verbatim — so "uniform" held within a subset and broke at its edge. Decision 20 then made
`compy.input.keys_pressed` globally readable, which is where a project must read it anyway (a
per-frame draw has no event argument), leaving the threaded copy with no job. Decision 26 keeps
the uniformity and drops the invention: every consumer gets LÖVE's own list.

**What survives.** `isrepeat` still reaches every consumer, in LÖVE's own third position. And
`shortcuts` dispatch still does not gate on it — a shortcut fires on every repeat, and a binding
that wants once per physical press wraps itself in `compy.input.fn.ignore_repeat` (Decision 22),
which is the wrapper that replaced the deferred marker this entry once pointed at.

## Decision 12 — `inspect` is a mode-to-route line — NOT A DECISION, de-facto behaviour

**Retired in place, 2026-08-25**, against the rule that behaviour the platform
always had was never a decision to record. Suspending a project restored every
handler to the console before this feature and still does. The number is kept
because decisions are cited by number — seven comments cite this one — and the
description is kept because it is worth having; it just is not a ruling.

**The behaviour.** `inspect` (a paused or broken-into project) is **the console
route active, bound over the project's environment**. The project route is
disconnected exactly as the connection rule (Decision 11) describes, and the
project's own widget is unhonoured because its owning route is inactive. That
makes it a live debugger console rather than a separate idle one, and it needs
no rules of its own. The narrative belongs to
`internals/user_input.md`; this entry exists for the citations.

## Decision 13 — the held-key set is exposed read-only, callback-only — SUPERSEDED by Decision 30

**Decision.** Downstream consumers never touch the live held-key table. Every chain signature's
second argument is a **read-only pressed-keys view**: reads pass through to the live set, writes
raise. There is no project-facing way to *poll* held keys outside a callback — the view only ever
arrives as a callback argument.

**Why.** The held set is framework-owned state maintained at the gateway; letting project code
mutate it would corrupt every downstream consumer. Read-only access covers the legitimate need
(a callback asking "is Ctrl down?") without exposing the write. Keeping it callback-only rather
than pollable is consistent with the callback-over-poll principle (Decision 4) — there is no
per-frame "is this key down?" surface by design.

**Recorded honestly:** on the shipping LuaJIT/Lua 5.1 runtime the view is index-only in
practice — `pairs()` ignores the metamethod that would make it iterable, so iteration yields
nothing; indexing works. The iteration support is kept for a future 5.2+ host. See the
technical-debt register.

**Allocation note.** The implementation caches the view while the backing
held-key table has the same identity, so normal dispatch does not allocate a
proxy per event. This is a non-functional requirement, not a project-facing
identity guarantee: a callback may rely on the view being read-only and
current, never on object equality across calls.

## Decision 16 — defer future input unification — SUPERSEDED by Decision 25 and Decision 27

**Retired in place, 2026-08-25.** The number is kept because decisions are cited
by number; the content below no longer describes the system.

This entry deferred pointer unification and said, in as many words, *do not add
click entries to the hooks table and do not route pointer events through
keyboard/text dispatching*. The feature does both: `hooks.singleclick` and
`hooks.doubleclick` are ordinary events (Decision 25), and every pointer channel
runs the same dispatch with a shortcuts tier of its own (Decision 27).

**Which unification, though — the distinction this entry is kept for.** The
**event axis** is unified: one channel list, one dispatch, one combo vocabulary
with the button as a trigger. **Routing** across console, editor and project is
**still deferred** — three controllers still own their own wiring, and that
migration is Decision 1's, not this one's. A reader who takes "unification is
deferred" from the heading alone gets the wrong half.

## Decision 20 — a project can read the held-key set outside an event — SUPERSEDED by Decision 30


**Status: implemented** (owner ruling, 2026-08-03).

**Decision.** `compy.input.keys_pressed` is the read-only pressed-keys view
(Decision 13), readable at any time — not only as a dispatch argument. Reads
pass through to the live held set; assignment raises. It resolves on every
access rather than being captured once, so it cannot go stale when the backing
table's identity changes.

**Why.** The same reason as Decision 18: a project's `love` is a sandboxed deep
clone, so it cannot reach the real held set on its own. Until now the view
arrived only as argument 2 of a shortcut/hook/widget call, which serves a
project that *reacts* to keys and fails one that *renders* them: a per-frame
`love.draw` runs between events with no argument in hand.

**The consumer that settled it.** `examples/keyboard` maintains its own
`INPUT.held` / `INPUT.shift` mirror, updated on every press and release, and
reads it during draw to decide whether to render shifted key labels
(`keyboard_view.lua`). It is a hand-built copy of a table the framework already
owns, and it exists because there was no way to ask.

**Placement.** On `compy.input`, beside `is_shown()`, rather than as a new
top-level `compy.keys_pressed`: it is input state, the input guide is where a
reader looks for it, and `compy`'s other members are subsystems. The ruling was
to expose the table; this placement is the implementation's choice.

**Not a new capability.** It is the same view, with the same read-through and
write-raise contract, reachable from a second place. Iteration remains inert on
the shipping LuaJIT runtime (`pairs` ignores `__pairs`), so it is index-only —
`keys_pressed['lctrl']`, not a loop over held keys.

## Decision 29 — event-tracked keys are the framework's truth; combos are the project's tool — SUPERSEDED by Decision 30

**Decision.** Three statements, in force together.

1. **The framework reads held state from the event-tracked set.** `Controller.keys_pressed` is
   maintained at the top of `love.handlers.keypressed` / `keyreleased`, before any downstream
   handler runs, and it is what every **event-time** question is answered from — combo
   serialisation first among them. The framework does not consult the device for a question about
   an event.
2. **A project expresses chords through combos.** `shortcuts[channel][combo]` is the primary way a
   project reacts to a modified event. It is declarative, it is folded (`ctrl`, never `lctrl`), and
   it is one vocabulary across every channel (Decision 27).
3. **The direct reads remain, as secondary channels — for wherever combo and shortcut logic does
   not fit.** A per-frame draw with no event in hand is the clearest case (Decision 20), not the
   only one: anything asking about held state in a shape a declarative combo cannot express reads
   `compy.input.keys_pressed`, or the physical device queries where the event-tracked set cannot
   answer. Neither is deprecated, and neither is second-class — they are second *choice*, after the
   declarative route has been considered and found not to fit.

**Why the framework must use the event-tracked set, and this is the load-bearing part.** The two
sources answer on **different clocks**. `love.keyboard.isDown` reports the device *now*. The
event-tracked set reports what was held *at the event being dispatched*. LÖVE pumps the entire
event queue and then dispatches its events one at a time, so with a press and a release queued in
the same frame, a device poll taken while dispatching the **press** already reports the key
released. A combo built that way would be built from the future.

This is why the set exists at all, and the reason survives Decision 26 removing it from the
payload: what a handler is *handed* and what the framework must *track* are different questions.
Dropping the argument did not remove the need for the tracking.

**Why a project should reach for a combo first.** A modified event asked about imperatively becomes
a cascade — `if not shift and not alt and not ctrl then` — restated at every call site, with the
folding hand-rolled each time. The combo says the same thing once, as data, in the vocabulary the
framework already serialises. The direct reads are for what a combo cannot express: held state
during a draw, and the physical distinction between the two keys of a modifier pair.

**Consequence, accepted.** The set can go stale where the device cannot: a key released while the
window is unfocused never delivers its release. That is bounded and fixable in the framework
(`technical_debt/input.md`), and the fix is to clear the set — **not** to rebuild combos on the
device poll, which would trade a bounded staleness for the unbounded one described above.

**Consequence, accepted.** `keys_pressed` stays keyed by LÖVE key name, unfolded: `lshift` and
`rshift` are separate entries. Folding is lossy in the direction a keyboard renderer needs — it
wants the cap that is actually down — and physical→logical is one `or` while the reverse is
impossible. Folded names live in the combo vocabulary, which is where the folding is wanted.

**Consequence, and the one part of the above the surface does not deliver.** "Filter or iterate the
held set" reads as a natural use of a table, and it does not work: the read-only view is an empty
proxy carrying `__index` and `__pairs`, and the shipping LuaJIT/Lua 5.1 runtime ignores `__pairs`,
so `pairs(compy.input.keys_pressed)` yields nothing. The view is index-only in practice.
`../../input_api.md` states the limitation, so a reader is warned rather than misled — but the
surface is a table that cannot be read as one. Whether to give it a real snapshot accessor or to
declare it index-only by design is **unruled**, and recorded in `technical_debt/input.md`.

---

## Superseded content of `D-AUTO-HIDE`, vacuumed 2026-09-01 (`d0f4e66c`)

Not a whole entry — the decision is live and is `D-AUTO-HIDE`. What is archived is the **overruled
half**: a key ruled as `oneshot` and a `show`-only category, both ruled and overruled on 2026-08-30,
neither ever released. The live entry was 132 lines of which 24 were the churn; it is 77 now, stated
as one decision (*`auto_hide` replaces `oneshot`*) on the owner's framing that this is a single
decision from a stakeholder's perspective.

**Kept because it is the clearest surviving example of the shape `DEC-02` exists to remove** — a
decision written as a diff against itself, with a header announcing its own amendment, an edge
quoted verbatim as SUPERSEDED and then contradicted, and a ground corrected mid-sentence. Eleven
citations in `src/`, `tests/` and the corpus had learned to cite it that way.

The full pre-rewrite text follows.

## D-AUTO-HIDE — `auto_hide`: a widget that closes itself on submit

**Status: implemented** (owner ruling 2026-08-30; built at `FEAT-01-02`). `T-ONESHOT` is retired.
The edges below were recommendations when this entry was written and are **rulings** as of
`FEAT-01-01` — three ratified as recommended, one **reversed**.

**Amended the same day, by the owner** (`FEAT-02`; `T-ONESHOT-SCOPE`): the key was **ruled as
`oneshot` and is named `auto_hide`**, and it is a **widget property**, not a `show`-only one. Two
things below are superseded — edge 1 in full, and the *familiar name* half of the first ground. The
superseded text is kept as ruled and marked; the *Amendment* section states what replaces it.
Attestation: `wip/77-new-input-api/validation/notes/owner-attestation-oneshot-widget-property.md`.

**Decision.** `show{ auto_hide = true }` takes the widget down after a successful submit, without
the project installing a lifecycle callback to do it. It is sugar over what a project can already
write, and it is restored deliberately: it was dropped in-flight to avoid over-sugaring the
surface, and that call is reversed here.

**Why — two facts that settle it together.** The **capability** `oneshot` named **preceded this
feature**: the API being replaced had it, so this is a restoration, not an invention. *(**Ground
amended 2026-08-30** — as first written this sentence continued "and a migrating project author
meets a familiar name instead of a pattern they must reconstruct". That half does not hold; see the
*Amendment*. The restoration argument stands, the familiarity claim is withdrawn.)* And it was
**asked for by a second developer** — the author of the `serial` API (owner attestation; that
surface is not in this repo, so the request is not checkable here) — which makes it a request from
outside the input work rather
than an ergonomic preference of the input work's own. A returning capability that an independent
consumer asks for does not need a third argument. *(They asked for it as `oneshot` and will not find
that name — the one real cost of the rename, stated in the Amendment below.)*

**The third one is real anyway: the one-line question.** A project whose subject is *not* user
input — a game, a tool, a demo — wants to ask the user something and get on with it. With
`auto_hide` that is a single call carrying a prompt and a callback, and **no boilerplate at all**:
nothing to install beforehand, nothing to tear down after. Without it, the same project must also
assign `after_submit = function() compy.input.hide() end`, a hook that exists purely for its side
effect and that the author has to know to write. The cost of *not* having the flag falls hardest on
exactly the projects least equipped to pay it.

**On counting examples — don't.** In this tree only `turtle` closes on submit, and it keeps an
`after_submit` regardless to re-arm an echo guard, so a census of `src/examples/` scores the flag
at one call saved. That census measures the wrong thing: the shipped examples were written *for*
the API as it stands, and four of them (`valid`, `repl`, `guess`, `balloons`) demonstrate the
repeated-prompting pattern deliberately, which is the pattern `auto_hide` is not for. The evidence
for a convenience is who asks for it and what it costs the project that lacks it — both recorded
above.

**The edges, ruled (owner, 2026-08-30 — `FEAT-01-01`).** Evidence and the questions as they were
put: `wip/77-new-input-api/validation/reviews/FEAT-01-01-oneshot-ruling-sheet.md`.

- **SUPERSEDED 2026-08-30 — see the *Amendment*. As ruled:** *"**A `show`-only key, spent by the
  `show` that reads it.** `oneshot` describes* this *prompting session, not a standing project
  preference, which puts it on the same side of D-CFG-BOUNDARY's boundary as `text`, `cursor` and
  `force`. A sticky `oneshot` would also be the more surprising of the two, since a later bare
  `show()` would close on submit for reasons written elsewhere. Consequently `configure{oneshot}`
  **raises**, like the other three, and a bare `show()` clears it."* The flag is now project-owned
  and persistent, and `configure` takes it.
- **Submit only — cancel is already not a close.** `cancel_flow` clears and leaves the widget
  standing (D-NO-FW-TIER), and no `auto_hide` reading should quietly change what Escape does. **The
  asymmetry is documented, not hidden** (`FEAT-01-05`): a project that installs nothing and relies
  on `auto_hide` alone has no dismissal path — its user's Escape clears the content and the widget
  stays up. A project that wants Escape to close writes `after_cancel = function() hide() end`, the
  same one-liner on the other channel.
- **It composes with `after_submit`; it does not refuse one.** The project's callback runs first and
  the close follows it, so a project can both react to the submission and have the widget go down.
  Refusing the combination would force exactly the boilerplate this decision exists to remove.
- **It closes on a CLEAN submit only — a raised callback leaves the widget standing.** This
  **reverses** the recommendation this entry carried, on evidence gathered when the recommendation
  was checked for buildability. The recommendation's ground was *"the submit chain runs under an
  error boundary"*; the boundary is real but it wraps the **route entry**
  (`controller.lua`, `with_canvas_and_errors`), not the chain, and deliberately so. A raise in
  `on_text_entered` therefore already unwinds past `after_submit` today, so honouring the edge
  meant new machinery inside `submit_flow` — a protected call and a re-raise — for a case where the
  first failure is **not** silent: the project suspends and its error is reported. The widget's
  fate now matches what the hand-written `after_submit = hide` would have done, which is the
  behaviour this whole decision is sugar for. *A widget standing behind a reported error is the
  smaller of the two failures, not a second one.*

**Amendment (owner, 2026-08-30 — `FEAT-02`).** Ruled the same day as the edges above, on the peer
review of the implementation. **Two things change: the key's name, and which call may set it.**

1. **It is `auto_hide`, not `oneshot`.** The flag is a persistent behaviour **mode**, and `oneshot`
   names a single occurrence — the ambiguity would otherwise have to be warned about in the guide,
   and renaming deletes the warning instead of writing it. `auto_hide` reads as a mode and matches
   the surface's own verbs: `compy.input` has `show` and `hide`, and `close` appears nowhere on it.
2. **The first ground above is corrected, not deleted.** *"A migrating project author meets a
   familiar name"* is false. At the PR base (`3256aac`) `oneshot` was an **internal model
   constructor argument** — it suppressed history, pushed the `userinput` event for the retired poll
   idiom, and switched the view's draw path — so it meant *"this is the transient prompt widget, not
   the console's permanent one"*. **No project ever wrote it or read it**; `is_oneshot()` was a view
   helper, not a project surface. What is restored is the **capability**, and that argument stands
   untouched. The name has no claim on anyone's memory, and the token is not free in-tree either —
   the profiler owns it (`Prof.start_oneshot`, `love.PROFILE.oneshot`). Evidence:
   `wip/77-new-input-api/validation/notes/oneshot-at-the-pr-base.md`.
3. **It is a widget property, settable at `show` and `configure`** — set-if-given, `false` to unset
   (D-CFG-BOUNDARY, statement 3, so the disarm idiom needs no new vocabulary), and **persistent until
   replaced**, exactly like `validator`. The show-only category exists to protect what the **user**
   owns; `force` sits in it because it is *meaningless* at `configure`, not because it is protected
   from it. **`auto_hide` is machinery, and the user does not own lifecycle** — it was admitted on a
   resemblance to two keys it does not resemble.
4. **The persistence is ruled, not incidental.** `auto_hide` configures a **type of behaviour**, not
   one show/hide cycle, so it is an ordinary project-owned setting and gets **no category of its
   own**: no clearing rule, no consumption semantics, nothing that behaves unlike `validator`. A
   later bare `show()` **inherits** it. A project that wants a continuous session after an
   auto-hiding one writes `auto_hide = false` at either call. *This reverses the superseded edge's
   last clause, which had a bare `show()` clear it.*
5. **No reader is added.** `is_auto_hiding()` and a `config` namespace were both proposed and
   refused: disarming is unconditional, so there is nothing to ask before acting. The line, general
   beyond this key: **a read-only query earns its place when the framework can change the value, not
   when only the project can.** That is why `is_shown()` exists — shownness moves for reasons a
   project cannot derive — and why this flag has no getter.

**What it fixes.** Today `configure` refuses the key, so disarming a live one requires `show{force}`
— a full re-setup that **clears the user's draft** (statement 4 of D-CFG-BOUNDARY). Worse than it
sounds: the project cannot put the draft back, because the widget surface has **no text getter** and
a project's `love` is a sandboxed clone (D-ONE-STATE-ASK). Changing your mind about the flag destroyed
content nobody could read. That is the defect, and statement 3 above is the fix.

**What it does NOT fix, said so nobody expects it to.** A callback doing `show{force = true,
auto_hide = true}` from inside the submit chain re-arms the flag, and the close belonging to the
submit already in progress still fires — the close reads the flag at the **end** of the submit it is
running (see the placement note in `submit_flow`). Owning the close by the submit that armed it
needs a generation token, and that state was judged not worth it. **The escape is to pass
`auto_hide = false` on the follow-up**, or to re-show after the widget is down; `doc/input_api.md`
says so. *(Leaving the follow-up plain is NOT an escape — silence stopped being a disarm the moment
the flag became persistent, which is the same amendment. Corrected 2026-08-30, the day it was
written, on a cold peer review.)*

**Consequence.** `show` **and `configure`** grow one key, so `doc/input_api.md`, the config-key
lists and the CHANGELOG all move together (`FEAT-01-05` documented the key; `FEAT-02` renames it and
documents the persistence; `CHG-01` carries it). Nothing existing changes behaviour: absent the key,
submit behaves exactly as it does today. The guide's worked example for it should be the one-line
question, since that is the case the flag is for.

