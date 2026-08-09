# S31 — is the surface justified by the bug it fixes? (Fable consultation #2)

**Task:** test whether the modal-widget bug is fixable with far less surface
than was built, weigh the adoption census, and deliver a recommendation with
a spine. Read-only. Model Fable, explicitly passed. `busted tests`
reconfirmed at 955 / 0 / 0 / 3, twice, before and after this pass.

## Verdict, upfront: PARTLY justified — and the split is sharper than the
## prompt's own framing suggests

The shipped surface decomposes into two tiers that the evidence treats very
differently. I did not invent this split for convenience; it falls out of
tracing the actual dispatch code and the actual per-example usage, and it
survives every check below.

- **Tier A — routing + lifecycle.** Decision 1 (route-centric dispatch, the
  widget stops gating) plus the widget lifecycle/callback API (Decisions 3,
  4, 5, 6, 7, 15, 18: `show`/`hide`/`configure`/`is_shown` and the
  `callbacks` table) plus one plumbing correction (LÖVE's full
  `(key, scancode, isrepeat)` argument list is forwarded to `love.keypressed`
  again, instead of the base gateway's truncation to `(key)` alone). **This
  tier is justified by the motivating bug.** It fixes all three structural
  faults the decision record names (`doc/development/decisions/input.md:66-76`:
  polling not events, keyboard lockout, no show/hide without teardown), and
  every example that actually exercises a widget (guess, repl, valid,
  balloons, tixy, maze, turtle) is testing this tier.
- **Tier B — the combo/held-key layer.** `compy.input.shortcuts` + combo
  strings + class matching (Decisions 8, 21, 22, 23) and
  `compy.input.keys_pressed` as a globally readable view (Decision 20).
  **This tier is not justified by the bug it is credited with fixing.** It
  is not required for the modal-widget fix (§1 below), and — this is the
  finding the prompt's hypothesis undersold — it is **not what fixed the one
  broken keyboard subgame either** (§3). Its own strongest evidence
  (`examples/keyboard`) is a project that **never shows an input widget at
  all**, so it cannot be evidence for the bug fix by construction (§4). Its
  value is real but narrow: one voluntary adopter, one genuinely
  irreplaceable capability (an arbitrary-key draw-time read), and a
  documented separate design goal ("stop `if Key.shift()` cascades
  sprawling") the owner has already ruled does not decide the
  event-vs-poll question.

**Recommendation: ship both tiers as built — do not revert code — but stop
letting Tier B's completeness gate release, and correct the record that
credits it with fixing bugs it did not fix.** Full reasoning and the
strongest argument against this follow.

---

## 1. Is Decision 1 alone sufficient for combos to reach a project while the widget is shown? Traced, yes.

**Base (`git show 3256aac:src/controller/controller.lua:625-636`),
verbatim:**

```lua
local user_input = get_user_input()
if user_input then
  user_input.C:keypressed(k)
else
  if love.keypressed then return love.keypressed(k) end
end
```

Widget shown → the project's `love.keypressed` is **never called** — not "it
runs and loses a race," it is not invoked at all. That is the entire bug.
Note also: only `k` is forwarded — no scancode, no `isrepeat`. Pointer events
were **not** gated this way at base (`3256aac:controller.lua`,
`handlers.mousepressed`: both `user_input.C:mousepressed(...)` **and**
`love.mousepressed(...)` run, unconditionally) — so the keyboard/text
lockout was always the asymmetric case, not the norm, confirming Decision
1's own framing.

**HEAD (`src/controller/controller.lua:787-897`,
`src/controller/projectInputController.lua:132-142`):** the gateway now
forwards `love.keypressed(k, sc, isr)` (full LÖVE argument list) to the
active route unconditionally; the project route's `love.keypressed` is
`ProjectInputController`'s dispatch, whose `dispatch()` function runs
`hooks[event]` — seeded once from the project's own captured `love.keypressed`
— **before** checking the widget, regardless of whether the widget is
shown:

```lua
local function dispatch(shortcuts, hooks, widget, event, trigger, ...)
  local sc = find_shortcut(shortcuts[event], trigger)
  if sc and sc(...) then return true end
  local hk = hooks[event]
  if hk and hk(...) then return true end
  if widget and widget:is_shown() then
    widget[event](widget, ...)
    return true
  end
  return false
end
```

Strip the `sc`/`shortcuts` branch (lines 1-2 of the body) and the mechanism
is unchanged for the bug in question: `hooks[event]` — the captured project
handler — always runs; the widget only runs (and only then reports
"consumed") after it, mirroring exactly what pointer events already did at
base. **The true minimum for the modal-bug fix is two changes, both
independent of `compy.input.shortcuts`, `compy.input.keys_pressed`, and even
of exposing `hooks` as an assignable project-facing table:**

1. Stop diverting keyboard/text to "widget instead of project" — call the
   project's captured handler unconditionally, then the widget if shown
   (symmetric with what pointer channels already did).
2. Stop truncating LÖVE's argument list when forwarding to `love.keypressed`
   — pass `(k, sc, isr)`, not `(k)`. This is a plumbing correction, not new
   API; `love.keypressed` was always the project's extension point.

Once (1) holds, the project's **pre-existing** `Key.ctrl()/alt()/shift()`
(`src/util/key.lua:141-164`, confirmed byte-for-byte unchanged in logic
against `3256aac:src/util/key.lua:1-40`, only the combo apparatus is new)
answers "which modifiers are down" exactly as it always did — verified in
use as project code today at `tixy/main.lua:197`, `paint/main.lua:407`,
`sapper/main.lua:672,690,697,701`, `pong/strategy.lua:35`, all pre-dating
this branch. **The hypothesis's first claim holds under direct trace, not
merely by assumption.**

What Decision 10's full contract (`hooks[event]` as an *assignable,
re-bindable, nil-clearable* project-facing table) buys beyond the minimum is
the ability to rebind or clear a handler at runtime and to make what is
active legible by inspecting one table. Real, but it is convenience over the
alternative of "the framework silently keeps calling whatever `love.keypressed`
was at capture time" — not required for the bug.

---

## 2. What does `compy.input.shortcuts` + combo strings buy that the minimum does not?

Traced against every current consumer, not asserted:

- **`examples/keyboard`'s reserved chords** (`shift+escape`, `ctrl+alt+up`,
  `ctrl+alt+down`, `alt+*`, `alt+p`, `input.lua:83-95`) replace a hand-rolled
  `reservedChord()`/`appChord()` cascade (23 lines,
  pre-adoption `4814407^:input.lua`). Every one of those five bindings is
  expressible today as an `if`/`elseif` inside a single `hooks.keypressed`
  using the pre-existing `Key.ctrl()/alt()/shift()` — which is *exactly*
  what the pre-adoption code did. The combo table is strictly a nicer way to
  write the same logic (a class marker instead of an "and not Ctrl" hand
  test) — declarative sugar, not new capability.
- **`examples/turtle`'s echo-guard**
  (`compy.input.shortcuts.textinput["i"]`, `main.lua:53-58`) looks load-
  bearing (it is the one non-keyboard, in-tree use of `shortcuts`) but is
  not: it consumes-on-truthy, which `hooks[event]` already provides
  (Decision 2's truthy-consume rule applies uniformly to hooks and
  shortcuts alike). The same guard is one `if t == "i" and echo_pending
  then ... return true end` inside `hooks.textinput`. Shortcuts did not add
  a consumption mechanism here; hooks already had one.
- **`tixy`'s and `sapper`'s left-on-the-table mouse combos** (census,
  `S31-example-adoption-impact.md`) are genuine, real wins **not yet
  taken** — 11→3 lines and 9→2 lines respectively. This is the strongest
  case *for* shortcuts on its own ergonomic merits, and it is honestly
  unrealized value, not a fixed bug.

**Conclusion: `shortcuts` + combo strings are not necessary for any shipped
behaviour.** Every current use is substitutable with the minimum (hooks +
`Key.*`), at a real but bounded cost in verbosity. This matches the
hypothesis and the owner's own framing precisely: it is ergonomics for
"stop `if Key.shift()` cascades sprawling," motivated by a goal the owner
has separately ruled does not decide the event-vs-poll question.

---

## 3. What does `compy.input.keys_pressed` buy — and the correction to the prompt's own premise

`src/examples/keyboard/input.lua:47`'s draw-time read is real
(`INPUT.shift` read from `keyboard_view.lua:171,178` via `love.draw` →
`drawStep` → ... → `drawKeyboard`, chain confirmed in the predecessor
review, S31-boundary-challenge, falsification 6 and scoping judgement A).
But cross-checked directly:

- **The modifier reads (`INPUT.shift/ctrl/alt`) were already expressible
  with `Key.shift()/ctrl()/alt()`** — a device poll from `draw` answers a
  legitimate "now" question, and this is exactly what
  `S31-boundary-challenge-fable.md` already established (scoping judgement
  A, "the draw-time modifier reads... were always expressible with
  `Key.shift()`"). `keys_pressed` did not create this capability.
- **The one thing `Key.*` genuinely cannot do, and `keys_pressed` uniquely
  can, is `help.lua:11`'s arbitrary non-modifier key read**
  (`INPUT.held.h`) — `Key.*` only ever answers about ctrl/alt/shift, never
  an arbitrary key, and there was no other way to ask outside an event
  before Decision 20. This is the API's one genuinely irreplaceable draw-
  time capability, and it is exercised at exactly one call site in the
  whole corpus.

**The sharper finding, not in the prompt's framing: `keys_pressed` is not
merely "ergonomics layered on top" here — it was, briefly, the *cause* of
the one broken subgame, not its fix.** Traced through the keyboard repo's
own history:

- **Pre-adoption** (`4814407^:input.lua`, `4814407^:alt.lua`), the game
  already hand-maintained its own held-key mirror (`INPUT.held`) and
  asserted a fixed keypressed-before-textinput order in its own comments
  (`"the IDE delivers textinput BEFORE the matching keypress"`,
  `4814407^:input.lua:12`). **The ordering bug pre-dates the platform API
  entirely** — it is not something the new surface introduced or was needed
  to fix; it is a bug in the project's own assumption, present before this
  feature existed.
- **After adopting Decision 20**, `input.lua`'s `inputStale()` read
  `INPUT.held` — now sourced from `compy.input.keys_pressed` via the
  `INPUT` proxy (`input.lua:57`) — to decide whether a `textinput` glyph was
  a stale repeat. This is precisely the wrong tool for that question: an
  event-tracked held-key set answers "is this key down," not "did this
  glyph and this keypress arrive in the order I assumed," and the commit
  that fixed it (`3a9d48c`, `keyboard` repo) says so explicitly: *"The held
  set cannot answer this: the two channels have no fixed order... So the
  glyph is judged by whether its producing key is HELD — which is what
  compy.input.keys_pressed answers"* was the diagnosis of what was **wrong**,
  not what fixed it.
- **The actual fix (`f938fbc` + `3a9d48c`, `keyboard` repo) is two things,
  neither of which is `compy.input.shortcuts` or `compy.input.keys_pressed`:**
  (a) restoring LÖVE's native `isrepeat` as the hook's third argument
  (`appKeypressed(k, _, isr)`) — the §1 plumbing fix, not new API; and (b) a
  project-local claim-tracking scheme (`GLYPH_CLAIMED`, `spendGlyph`,
  `input.lua:154-160`) that answers "has this key's glyph already been
  judged since its last release" — ordinary project code, buildable
  identically against the *pre-adoption* `INPUT.held` mirror, with zero
  platform surface required.

**So the owner's own blocker accounting — "only one keyboard subgame was
actually broken... relying on keypressed/textinput delivery order" — is
correct as a description of what broke, but the platform's Tier B surface
did not fix it and was, for one release, the thing that broke it.** The fix
is `isrepeat` threading (Tier A's plumbing correction) plus project code.
This is the single most consequential correction this session makes to the
prompt's own framing.

---

## 4. Lifecycle controls/callbacks — which parts, and are they separable?

Decisions 3 (shared instance), 4 (callbacks replace polling), 5 (two
directions/surfaces), 6 (submit/cancel flows), 7 (frozen container, writable
leaves), 15 (raise on unrecognised config), 18 (`is_shown()`): concretely
`compy.input.show/hide/configure/is_shown/clear/get_cursor/set_cursor/set_text`
and `compy.input.callbacks.{on_text_entered, before_submit, after_submit,
before_cancel, after_cancel, on_limit_reached, validator, highlighter}`.

**These are the owner's stated win** ("more controls/callbacks on input
solicitation") and they are architecturally and evidentially separate from
Tier B:

- Different sub-tables (`compy.input.show`/`callbacks` vs.
  `compy.input.shortcuts`/`fn`), different decision numbers, different test
  files (`input_widget_callbacks_spec.lua`, `input_widget_control_spec.lua`,
  `input_route_lifecycle_spec.lua` vs. `input_shortcuts_click_spec.lua`,
  `keys_pressed_spec.lua`).
- In `dispatch()` (§1), the shortcuts tier is the **first** of three
  independent, early-return branches — dropping it touches nothing about
  hooks or the widget branch below it. Structurally cheap to separate, and
  already effectively separate in the source.
- Evidentially: every example that uses **only** this tier (guess, repl,
  valid, balloons) lands positive-to-mild-overhead (−14, −2, −1, ~0 net).
  None is negative. The one negative case in the whole census (turtle,
  +13 lines) is **overwhelmingly attributable to this tier's own
  completeness gap** (the missing `is_shown()` guard, +2-4 lines) plus the
  platform-inherent echo-guard (a consequence of LÖVE's own unordered
  keypressed/textinput delivery, not of Tier B) — not to Tier B's
  ergonomics. Cutting Tier B would not remove turtle's cost; only finishing
  Tier A's own `is_shown()` guard does.

**Separable, and already the stronger, better-evidenced half of the
surface.**

---

## Judging the turtle/maze "intended effect, not regression" reading

The owner's reading (`S31-owner-attestation-where-we-are.md:102-107`) — that
turtle and maze's behaviour changes are Decision 1's intended effect, not
accidental regressions — **holds, and is not session rationalisation: it is
ratified in the decision record itself**, independently of this session's
reasoning. `doc/development/decisions/input.md:480-483` (Decision 10,
"Consequence, accepted"): *"Because project handlers fire while the widget
is shown, the two examples that combined a project handler with widget
solicitation changed behaviour and were migrated alongside the change.
Breaking-and-fixing the affected examples was the explicit expectation, not
a regression to avoid."* That sentence was written before this session and
describes exactly turtle and maze's situation. **This is a real ruling on
record, not this session inferring intent after the fact.**

What is *not* settled by that ruling: turtle and maze **have not finished**
the migration the ruling anticipates — both are missing the `is_shown()`
guard the same decision's text says is now "the project's new
responsibility." That gap is real, cheap (2-4 lines per example, confirmed
by direct read: `turtle/main.lua:33-45` has no guard at all;
`maze/main.lua:568-577` same), and — per the census — leaves the primary
student-facing examples **shipped broken today** (Shift+Escape quits maze
mid-typing; Space toggles turtle's debug overlay mid-typing). This is Tier
A's own unfinished homework and belongs on the must-fix list regardless of
any Tier B decision.

---

## Weighing the adoption census against the tier split

Re-sorted by which tier an example actually exercises (not by the census's
original per-example order):

| Uses only Tier A (lifecycle) | Net | Uses Tier B (shortcuts/keys_pressed) | Net |
|---|---|---|---|
| guess | −14, positive | keyboard (5 shortcuts + keys_pressed) | −19, positive, but **never shows a widget — not evidence of the bug fix** |
| repl | −6→−2ish, positive | turtle (1 shortcut, echo-guard) | +13, negative, **but attributable to Tier A's own is_shown() gap, not Tier B** |
| valid | −1, overhead | tixy, sapper (opportunity, not yet taken) | 0 realized, real potential (−8, −7) |
| balloons | ~0, mild negative (indirection, 2 follow-up fixes) | | |
| maze (+ shortcuts opportunity not taken) | −12 *if finished*, positive | | |

**No example that uses only Tier A is negative.** The one sharply negative
example (turtle) uses Tier B narrowly (one substitutable shortcut) and its
cost is overwhelmingly a Tier A completeness gap. **Tier B's sole strong,
clean positive (keyboard) is not testing the bug the surface exists to fix**
— it is a project with no input widget at all, so its −19 lines says
something true and good about the combo/held-key ergonomics on their own
terms, but nothing about whether the modal-widget fix needed them.

Two further facts from the prompt, checked and confirmed, that bear on cost
rather than justification:

- **`compy.singleclick`/`doubleclick` retirement fails silently** for any
  code (in-tree or out-of-tree) still assigning to those names — confirmed
  at `consoleController.lua:861-871`, the `compy` namespace's `__newindex`
  `rawset`s anything but `before_exit`/`input` with no diagnostic. This is
  a real correctness gap, independent of the Tier A/B question, and it is
  the kind of failure mode ("dead clicks, no error") that should not ship
  without at least a documented known-issue, regardless of scope decisions
  made elsewhere.
- **`textinput` carries no `isrepeat`**, confirmed at
  `projectInputController.lua:51` and by LÖVE's own `love.textinput(t)`
  signature — the claim that full adoption lets `keyboard` delete
  `spendGlyph`/`GLYPH_CLAIMED`/`upRecent`/`INPUT_UP_GRACE` is false; that
  machinery survives adoption permanently (~20 lines) because it answers a
  platform limitation no API surface can remove. This is not a shipped-
  surface defect; it is a fact to document, not a bug to chase.

---

## 1. Is the built surface justified by the bug it fixes?

**Partly, cleanly split by tier:**

- **Tier A (routing fix + lifecycle/callback API) — yes, justified.** It is
  the mechanism that fixes the modal lockout (§1, traced in code against
  base), it delivers the owner's second stated win ("more controls/callbacks
  on input solicitation") as the *same* mechanism, not a separate one, and
  every example that exercises it lands positive-to-mild-overhead with no
  exception.
- **Tier B (shortcuts/combo strings/keys_pressed) — no, not justified by
  this bug.** It is not required for the modal-lockout fix (§1), it did not
  fix the one broken keyboard subgame — it was, briefly, implicated in
  causing that subgame's failure (§3) — and its one strong adopter
  (`keyboard`) never shows an input widget and so cannot be evidence for
  the bug fix by construction. Tier B is justified, if at all, on its own
  separate merits: one voluntary, real −19-line win; one irreplaceable
  narrow capability (arbitrary-key draw-time reads); and two credible,
  unrealized opportunities (tixy, sapper). That is a legitimate but much
  thinner justification than "the bug it fixes," and it is exactly the
  ergonomics-not-the-fix reading the hypothesis proposed.

## 2. If scope should be reduced, what exactly is cut, and what does cutting cost?

**I recommend against literally reverting Tier B code.** I priced it and it
costs more than it saves:

- **Entangled history.** The keyboard repo's fix for the one broken
  subgame (isrepeat threading, which Tier A needs to keep) and its Tier B
  adoption (shortcuts, keys_pressed) are interleaved across the same
  commits and the same file (`input.lua`) in its own history
  (`5de5a6d`, `f938fbc`, `3a9d48c`, `032265d`, `ced8f40`). Untangling one
  without the other is a real, non-mechanical editing task in a repo this
  session was told not to touch, with no test suite to catch a mistake.
- **Reverting keyboard's Tier B adoption regresses its own strongest
  number.** Its −19 lines depends on the combo-class replacement for
  `reservedChord()`/`appChord()`; reverting would restore ~23 hand-rolled
  lines, turning the platform's single best adoption story into a wash or
  worse.
- **Platform-side removal is bounded but not free.** `util/key.lua`'s
  combo apparatus (~120 net-new lines beyond the pre-existing
  `is_shift/is_ctrl/is_alt/shift/ctrl/alt` functions), the `shortcuts`
  branch in `projectInputController.lua`'s `dispatch()`/`find_shortcut()`
  (~20 lines), `consoleController.lua`'s `build_shortcuts_surface`/
  `INPUT_FN` combinators (~60 lines), plus `tests/input/input_shortcuts_click_spec.lua`
  (297 lines) and `tests/input/keys_pressed_spec.lua` (138 lines) and
  portions of `input_events_spec.lua`/`input_nfr_mechanism_spec.lua` (1293 +
  165 lines, mixed with Tier A coverage — not cleanly separable without
  reading every case) would all need surgical, verified removal. Call it
  300-400 platform lines and 400-600 test lines requiring careful,
  individually-checked removal — non-trivial, bounded, and **carries fresh
  regression risk in an area that currently passes 955/0/0/3 clean.**
- **Doc cost.** Decisions 8, 20, 21, 22, 23 in the frozen decision record
  would need explicit retirement notices (not silent deletion — Decision
  14's own rule against silently changing recorded behaviour would apply to
  un-recording it too), `doc/input_api.md` rewritten, and the P9d/P9e/P13
  technical-debt entries — all of which are specifically about Tier B (the
  held-key set and the gates that read it) — would become either moot or
  need re-scoping.

**A scope reduction that costs this much to execute, this late, against
code that is already tested and already established as forward-compatible
(the predecessor consultation, `S31-boundary-challenge-fable.md`, held that
verdict against direct falsification attempts) is not a net reduction.**

**What I recommend cutting instead is scope of *obligation*, not scope of
*code*:** stop treating Tier B's completeness as a release blocker. P9d
(focus-loss staleness) and P9e (gate-seam migration onto the held set) are
both, confirmed directly (`technical_debt/input.md:29-79`), about
`Controller.keys_pressed` and the shortcut-matching gates — pure Tier B.
Neither threatens the modal-bug fix or the lifecycle API if deferred; both
can move to "before the *next* PR" with no risk to the justification this
session traces. That is a real, free scope reduction: it removes work from
the release-blocker list without touching a line of shipped code, because
the thing it removes was never load-bearing for what the release claims to
fix.

## 3. What is the minimum shippable feature?

**Fixes (a) the modal-widget bug, (b) the one broken keyboard subgame, (c)
leaves the examples no worse than base — this is Tier A, verified
sufficient for all three by direct trace, not assumption:**

1. Decision 1's routing change: call the project's captured keyboard/text
   handler unconditionally (mirroring what pointer channels already did at
   base), then the widget if shown — no diversion, no gate.
2. Restore LÖVE's full `(key, scancode, isrepeat)` argument list on the
   forward to `love.keypressed` (currently truncated to `(key)` at base) —
   this alone, plus ordinary project code (a claim-tracking scheme like
   `GLYPH_CLAIMED`), is what actually fixed the one broken subgame; no
   combo table or held-key view is required for it.
3. The widget lifecycle/callback API (Decisions 3-7, 15, 18): `show`,
   `hide`, `configure`, `is_shown`, and the `callbacks` table. This is what
   guess/repl/valid/balloons/maze/turtle all actually exercise, and it is
   uniformly positive-to-mild-overhead.
4. **The two `is_shown()` guards** (turtle, maze) that (1) creates an
   obligation for — 2-4 lines each — must land before ship, or two
   primary student-facing examples ship broken relative to base, which (c)
   explicitly forbids.
5. **A diagnostic, or at minimum a documented known-issue, for the
   `compy.singleclick`/`doubleclick` silent break** — independent of the
   Tier question, this is a real regression for any out-of-tree code that
   still assigns those globals, and it fails with no error today.

**`compy.input.shortcuts`, combo strings, and `compy.input.keys_pressed` are
not in this minimum.** They may ship anyway (see recommendation above), but
they are not what the minimum needs.

## 4. The strongest argument against this recommendation

**Keeping Tier B shipped as permanent, documented, tested 1.0 surface — even
while declaring its completeness non-blocking — does not actually reduce the
owner's stated risk, and may make it worse.** The owner's own test for any
deferral is explicit: *"does shipping this now commit us to anything we
would have to undo later?"* (`S31-owner-attestation-where-we-are.md:69-70`).
I applied that test to the *deferred backend items* (P9d/P9e/P13, per the
predecessor consultation) and found it satisfied. I did not apply it with
equal weight to **Tier B's project-facing surface itself**. Once
`compy.input.shortcuts` and `compy.input.keys_pressed` ship as 1.0,
documented, with combo-string syntax and class-matching semantics fixed in
`doc/input_api.md`, **any future project — in-tree or, per this project's
own stated audience, out-of-tree student code — may start depending on
those exact semantics.** If the P9e gate-seam problem (reserved power keys
racing project shortcuts on two different clocks, confirmed not-clean but
pre-existing in the predecessor review) turns out to need a shape change
rather than the additive fix currently planned — something neither
consultation has proven impossible, only not-yet-required — walking it back
after real adoption is a strictly harder, more disruptive change than
deferring the whole tier to a follow-up PR would have been. My recommendation
optimizes for the mechanical cost of unpicking code *today*, which favors
"keep it, don't block on it." But the owner's own risk framing is about
*commitment*, not *mechanical revert cost*, and shipping Tier B as
permanent public surface — even one this session finds unforced and
narrowly justified — **is** a commitment, in exactly the sense the owner
asked this session to rule out for the backend items. I judge the
mechanical case (§2) strong enough to recommend shipping anyway, but this is
the place a reasonable reader could weigh the owner's own stated test
differently than I did and conclude the safer cut is real: ship Tier A now,
hold Tier B (including `examples/keyboard`'s adoption of it) for a follow-on
PR where its combo-string vocabulary and class-matching rules can still be
changed without breaking anyone.

---

## Summary table

| Question | Answer |
|---|---|
| Decision 1 alone sufficient for combos to reach the project? | Yes, traced against base and HEAD. True minimum is smaller than Decision 1's full implementation: no assignable `hooks` table is required, only "call the captured handler unconditionally." |
| Does `shortcuts` + combo strings buy anything necessary? | No — every current use (keyboard's reserved chords, turtle's echo-guard) is substitutable with `hooks` + pre-existing `Key.*`. Real, unrealized value at tixy/sapper. |
| Does `keys_pressed` buy anything necessary? | One narrow, real capability (arbitrary-key draw-time reads, `help.lua:11`). It was also, briefly, the *cause* of the one broken subgame, not its fix — the actual fix is `isrepeat` threading + project code. |
| Are the lifecycle controls separable and are they the owner's win? | Yes and yes — architecturally separate, evidentially the stronger half (no negative examples), and the actual mechanism behind "more controls/callbacks on input solicitation." |
| Is the turtle/maze "intended effect" reading correct? | Yes — ratified on record at Decision 10's own "Consequence, accepted" text, predating this session. Both examples are still unfinished (missing `is_shown()` guards) and ship broken today regardless of that ruling. |
| Is the built surface justified by the bug? | Partly. Tier A (routing + lifecycle): yes. Tier B (combo/held-key): not by this bug — justified only by its own separate, thinner merits. |
| Cut code? | No — recommended against; costs more than it saves given entangled history, a regression to keyboard's own best number, and fresh risk to a currently-clean 955/0/0/3 suite. |
| Cut obligation? | Yes — P9d/P9e/P13 are Tier B-only debt and can defer freely with zero risk to the bug-fix justification. |
| Must-fix before ship regardless | Two `is_shown()` guards (turtle, maze — 2-4 lines each) and a diagnostic or documented known-issue for the silent `compy.singleclick`/`doubleclick` break. |
