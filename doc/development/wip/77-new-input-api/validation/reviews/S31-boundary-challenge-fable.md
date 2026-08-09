# S31 — boundary challenge (Fable consultation): verdict

**Task:** attack the claim "every deferred item is purely additive under the
shipped API surface; shipping now cannot force shipped work to be redone."
Read-only. Model Fable, explicitly passed. `busted tests` reconfirmed at
955 / 0 / 0 / 3 before writing this.

## Verdict: the claim HOLDS. I could not break it.

I could not find a deferred item — staleness reconcile, gateway-gate
migration (P9e), harmony reconciliation (P13), or a general recovery path —
that forces a change to `compy.input.hooks`, `compy.input.shortcuts`
(combo-string vocabulary or table shape), or `compy.input.keys_pressed`
(shape, semantics, or iteration contract). Every deferred item I could find
evidence for is either (a) a write into the *existing* backing table using
the *existing* write convention, or (b) entirely on the other side of a
boundary the project-facing surface never crosses (framework-internal gate
logic, or a dev-only automation harness).

That said, I found two real, worth-recording problems: one is a **citation
error inside this very investigation's own evidence trail** (not the claim
itself — a factual slip in how the frame-time-polling counter-example was
cited), and one is an **imprecision in sub-claim 3's own wording** (it
attributes a widget parameter to the wrong function). Neither breaks
additivity. Both are corrected below with file:line.

---

## Falsification attempts

### 1. Does any deferred fix change `keys_pressed`'s shape or semantics?

**Attempted, could not break it.** Decision 29's own "Consequences" section
(`doc/development/decisions/input.md:1202-1210`) already rules out the two
shapes that would matter:

- Folding l/r modifier pairs is explicitly rejected: *"`keys_pressed` stays
  keyed by LÖVE key name, unfolded: `lshift` and `rshift` are separate
  entries... Folded names live in the combo vocabulary, which is where the
  folding is wanted."* This is a ratified decision, not an open question —
  no deferred item threatens it.
- The staleness fix (focus-loss clear, plan row **P9d**,
  `doc/development/technical_debt/input.md:37-59`) is explicitly specced as
  *"clear the set when the window loses focus... No API change, and no
  project has to know it happened."* Mechanically this is the same write
  primitive already in production: `Controller.keys_pressed[k] = nil`
  (`src/controller/controller.lua:906`, the existing `keyreleased` write).
  Shape unchanged: `{ rawkeyname -> true }`, absent = not held.
- The `__pairs`/iteration limitation
  (`doc/development/technical_debt/input.md:81-97`) is a limit on the
  **frozen proxy** handed to projects (`held_keys()`,
  `src/controller/controller.lua:429-443`), not on the backing table
  `Controller.keys_pressed` itself, which is a plain Lua table the framework
  can `pairs()` freely. Any future framework-side reconcile (comparing the
  held set against `love.keyboard.isDown` and correcting drift) operates on
  the backing table directly and never needs the proxy's iteration — so the
  proxy's known limitation does not block it. This is the falsifier
  scenario the prompt names explicitly ("iteration the read-only proxy
  cannot provide") and it does not apply: the recovery path is
  framework-internal, not project-facing.

**Verdict on this branch: holds.**

### 2. Does any deferred fix change the combo-string vocabulary or shortcut table shape?

**Attempted, could not break it.** None of the four deferred items (staleness
recovery, P9e gate migration, P13 harmony reconciliation, general
recovery) touch `Key.mod_triples`, `normalize_combo`, or
`Key.new_handler_table` (`src/util/key.lua:16-21, 66-74, 111-118`). P9e
(below) would migrate the gateway's *own* gates onto reading the held set
directly, not onto the combo table — it doesn't need new vocabulary, since
the triggers involved (`t`, `r`, `p`, `pause`, `q`, `s`, `escape`, `f10`) are
already legal combo triggers and the modifiers involved are already in
`mod_triples`. No vocabulary gap.

**Verdict on this branch: holds.**

### 3. Can editor/console enrollment reuse the event set without rewriting project-facing dispatch?

**Attempted, could not break it — with one wording correction.** The claim
attributes the "free function over plain tables + a widget reference" shape
to `find_shortcut`. Checked directly
(`src/controller/projectInputController.lua:101-111`):

```lua
local function find_shortcut(tbl, trigger)
  if not tbl then return end
  local keys = Controller.keys_pressed
  ...
```

`find_shortcut(tbl, trigger)` takes **no widget parameter** — it reads
`Controller.keys_pressed`, `Controller.any_mod`, `Controller.combo_string`
as **module globals**, not as injected arguments. The widget-taking free
function is `dispatch(shortcuts, hooks, widget, event, trigger, ...)`
(`:132-142`), which calls `find_shortcut` internally. This is a precision
correction to sub-claim 3's wording, not a break of it: `dispatch` genuinely
is parameterized over plain tables (`shortcuts`, `hooks`) plus a `widget`
reference, and is exactly what a second adopter (editor/console) would call.

The global reach inside `find_shortcut` is not a reuse hazard either: there
is exactly one held-key set for the whole application
(`Controller.keys_pressed`, a true singleton — one keyboard, one focus).
Any adopter reusing `dispatch`/`find_shortcut` gets the *same* correct,
event-tracked state automatically; it would only be a problem if different
adopters legitimately needed different held-key sources, which they don't.

One real gap, not a break: `dispatch`/`find_shortcut` currently have
**exactly one caller** — `ProjectInputController:_dispatch`
(`projectInputController.lua:149-153`), confirmed by grep across `src/`.
Editor and console do not call it today; they still poll `Key.ctrl/alt/shift`
directly (see the 76-site census below). So "the reuse seam is already
designed in" is a structurally sound, plausible design intent — parameters
are generic, the widget arg is optional (`if widget and widget:is_shown()`,
`:137`, so `nil` is handled) — but it is **untested by a second caller**.
That is a real gap in the evidence for sub-claim 3, worth naming, but it is
a gap in *proof*, not a demonstrated *break*: nothing about editor/console's
current shape (both are ordinary Lua objects; nothing about their
`Key.*`-polling style structurally prevents building an adapter that hands
`dispatch` their own shortcuts/hooks tables and, optionally, `nil` for
widget) rules it out.

**Verdict on this branch: holds, with an open (not failing) reuse proof.**

### 4. Does harmony enrollment force a surface change?

**Attempted, could not break it.** Confirmed directly:

- `git diff 3256aac HEAD -- src/harmony/` is empty (reconfirmed independently
  in this session).
- `src/harmony/init.lua:242-253` (`patch_isDown`) shadows
  `love.keyboard.isDown` with a hand-set `held` table
  (`:174-184`, eight modifier keys) for **polling** consumers.
- `src/harmony/init.lua:272-293` (`love_key`) shows the split precisely: a
  **modifier** token sets `held[m] = true` directly with **no event pushed**
  (`:281`); a **non-modifier** key goes through
  `love_event('keypressed', v)` / `love_event('keyreleased', v)` (`:283,285`),
  which is `love.event.push(...)` (`:158`) — and harmony's own overridden
  `love.run` (`harmonius_run`, `:37-105`) drains that queue with
  `love.handlers[n](a,b,c,d,e,f)` (`:67`), which **is** the real gateway
  entry (`Controller`'s `handlers.keypressed`/`keyreleased`,
  `controller.lua:787,905`) — i.e. non-modifier keys injected by harmony
  **already** land in `Controller.keys_pressed` today.
- So the deferred fix (P13: "harmony pushes real modifier events instead of
  patching `isDown`") is symmetric with what harmony already does for every
  other key — it would just extend `love_key`'s non-modifier branch to
  modifiers too, still going through `love.event.push` →
  `love.handlers[...]` → the same two write sites
  (`controller.lua:788,906`). No new table, no new surface member, harmony-
  side only, exactly as claimed.
- Confirmed the plan record treats it as additive, not a swap: *"The phase is
  additive: keep the patch, add event injection"*
  (`doc/development/wip/77-new-input-api/implementation/sessions/session30/track.md`,
  §9 amendment 3) — the owner explicitly overturned a prior assistant
  recommendation to *delete* `patch_isDown`, on the grounds that physical
  querying is a permitted project channel (Decision 29 clause 3) and the
  sandbox hands projects the real `love` table, so the patch must stay to
  keep virtualizing every channel a script may use.

**Verdict on this branch: holds.**

### 5. Do the pre-existing polled upstream gates make the *combination* worse than either tier alone?

**Attempted. Did not find a regression the feature introduces — but found the
seam is genuinely not clean, and that risk is worth the owner's eyes even
though it predates the branch.**

Confirmed pre-existing, verbatim: all 10 `Key.ctrl/alt/shift()` sites in
`controller.lua` exist at `3256aac` at base lines
163,180,531,553,564,571,580,585,586,643 — checked directly against
`git show 3256aac:src/controller/controller.lua` — same logic bodies, same
order, only shifted line numbers (HEAD: 514,531,791,813,824,831,840,845,846,907).
`Controller.keys_pressed` does not exist at base at all.

The interaction: `handlers.keypressed` writes
`Controller.keys_pressed[k] = true` (`:788`) **before** running `quickswitch`
(Ctrl+T, `:791`), `project_state_change` (Ctrl+Q/S/Pause/Shift+R, `:812-838`),
`restart` (Ctrl+Alt+R, `:840`) and `profile` (Ctrl+Alt+P, `:845`) — all of
which poll the **device** (`Key.ctrl/alt/shift`), not the set just written.
Those gates can mutate `love.state.app_state` (e.g. `CC:stop_project_run()`)
and then, unconditionally, the same function forwards to
`love.keypressed(k, sc, isr)` (`:894-896`) — whichever route is active
*after* the mutation. A device poll taken mid-batch-dispatch can report a
modifier "from the future" (Decision 29's own framing,
`doc/development/decisions/input.md:1186-1194`): tap `s`, then Ctrl arrives
in the same pumped batch → `Key.ctrl()` during `s`'s dispatch already reads
true → `project_state_change` fires `CC:stop_project_run()` on a plain `s`
the user never modified.

**Is this worse than either tier alone, or new?** I checked both directions
and could not find a regression:

- **Not new.** At base, the same gates ran first, could mutate
  `app_state`/reinstall handlers, and *then* the same function decided
  whether to forward to `user_input.C:keypressed(k)` or
  `love.keypressed(k)` (`/tmp` base dump, block preceding
  `handlers.keyreleased` — same "gate runs, mutates, then routes" order).
  So "a stale-clock gate can steal a keystroke that would otherwise have
  reached the project" is exactly as true at `3256aac` as at HEAD.
- **Not compounded.** Where the new event-tracked tier *would* have gotten
  the same keystroke right (`find_shortcut` at event time reads the correct,
  non-future-skewed `Controller.keys_pressed`, confirmed in §3 above), the
  gate still runs first and can preempt it — but that is "the new tier adds
  no defense against an old bug it sits behind," not "the combination is
  worse than either alone." The project's shortcut dispatch is simply never
  reached in that narrow window, same as its pre-feature raw handler
  wasn't.

So sub-claim 5 holds as stated — this is accepted, pre-existing risk, not a
regression. But I want to be explicit that "the seam is clean" is **not**
what holds — only "the feature didn't make the seam worse" does. The
gateway's own gates and the project-facing dispatch chain answer the same
kind of question (which modifiers are held for *this* event) from two
different clocks, upstream/downstream of each other, and nothing currently
stops a project relying on `compy.input.shortcuts['ctrl+t']` from being
silently preempted by the reserved system gate for the exact same physical
chord regardless of clock correctness on either side. This is named in the
project's own plan (`P9e`, `doc/development/technical_debt/input.md:61-79`)
as debt to close, and the fix (**"the gates take the held set the handler
already has"**, same doc) is framework-internal and additive to the surface
— consistent with the claim — but it is not yet closed, and shipping now
means shipping with the seam still open. Not a break of additivity. A fair
thing to make sure the owner is signing knowingly (and per session31's own
track.md, they already are — see below).

**Verdict on this branch: holds — pre-existing, not worsened, not new.**

### 6. Anything in the shipped API that assumes the held set is reliable in a way a recovery path would break?

**Attempted, could not break it.** `doc/input_api.md:365-396` ("Held keys")
documents `compy.input.keys_pressed` as *"a read-only table of the keys held
right now"* — present tense, no persistence guarantee across a focus blip or
any other interval. A focus-loss clear is consistent with, not a violation
of, that documented contract. No shipped example or test asserts a key stays
`true` across a window-focus loss (checked: no test under `tests/input/`
references focus events at all — the three pending tests in
`tests/input/input_routing_spec.lua` are about console/editor/touch routing,
not focus/staleness).

**Verdict: holds.**

---

## The two scoping judgements

### A. Does the whole-`src` census (76, six in examples) overturn the "theoretical" verdict?

**Yes, it overturns the verdict — but the strongest evidence for that isn't
quite the citation the prompt (and session31's own track.md) gives, and one
of the four cited line numbers is a misattribution.** Both points, checked
directly:

**The census count is right.** `grep -rn "Key\.\(ctrl\|alt\|shift\)("
src --include=*.lua | wc -l` → **76**. By directory:
`src/controller` → 70 (matches the earlier census), `src/examples/sapper` →
4, `src/examples/tixy` → 1, `src/examples/paint` → 1 → **6 in examples**,
total 76. Confirmed exactly as claimed.

**But none of those 6 additional `Key.*` sites are frame-time either** —
checked each: `sapper/main.lua:672,690,697,701` are inside
`compy.input.hooks.singleclick`/`doubleclick` and `love.mousepressed`
(event-time); `tixy/main.lua:197` is inside `love.mousepressed`
(event-time); `paint/main.lua:407` is inside `love.keypressed`
(event-time). So **extending the `Key.*` census alone still finds zero
frame/draw-time instances** — the census's own methodology (grep for
`Key.ctrl/alt/shift`) cannot by itself overturn the "theoretical" verdict,
because that specific API is genuinely never called at frame time anywhere
in the tree, platform or project.

**What actually overturns it is two things outside that grep, and they are
not equally solid:**

1. **`src/examples/keyboard/input.lua:47`, verified, is the real, dispositive
   counter-example.** The comment states outright: *"it reads INPUT.shift
   from draw, where there is no event argument to consult"* — and I traced
   the call chain directly: `INPUT.shift` (`input.lua:58`) →
   `modHeld("lshift","rshift")` (`input.lua:108-113`) → reads
   `compy.input.keys_pressed` directly (`input.lua:109`) → consumed by
   `capsEffectiveUpper()`/`kbLabel()` (`keyboard_view.lua:171,178`) → called
   from `drawKey` (`keyboard_view.lua:248-249`), a drawing function invoked
   off `love.draw` (`main.lua:117`) via the keycap renderer. This is not
   theoretical — it is a **live, shipped, draw-time read of the exact
   surface member (`compy.input.keys_pressed`) the claim is about**, and it
   is *why the surface exists*: Decision 20's own "consumer that settled it"
   (`doc/development/decisions/input.md:815-819`) names this exact file —
   *"examples/keyboard maintains its own INPUT.held / INPUT.shift mirror...
   and reads it during draw... a hand-built copy of a table the framework
   already owns."* This overturns "the platform contains zero frame-time or
   draw-time keyboard polls, so Decision 29 clause 3's justification is
   theoretical" cleanly: the flagship case Decision 29 clause 3 names (a
   draw with no event in hand) is not a hypothetical, it shipped, and it
   consumes the very API surface under discussion.

2. **The other three citations in the prompt/session31's track.md
   (`examples/pong/strategy.lua:35`, `examples/clock/main.lua:68`,
   `examples/maze/main.lua:517,564`) are half right.** Checked each call
   site, not just the function definition:
   - `pong/strategy.lua:35` (`love.keyboard.isDown("up")`/`"down"`) —
     genuinely frame-time: `strategy.manual` is called as `S.strategy.fn(S,
     sdt)` from inside `function love.update(dt)` (`pong/main.lua:373,388`).
     **Correct citation.**
   - `maze/main.lua:517` (`love.keyboard.isDown("tab")`, inside
     `poll_tab_progression`) — genuinely frame-time: called at
     `main.lua:530`, directly inside `function love.update(dt)`
     (`:526-538`). **Correct citation.**
   - `clock/main.lua:68` (`local function shift() return
     love.keyboard.isDown(...) end`) — **not frame-time.** Its only call
     sites are `:72` and `:81`, both inside `color_cycle(k)`, called from
     `function love.keyreleased(k)` (`:79-86`). This is an **event-time**
     poll, structurally identical in kind to the 76-site `Key.*` census
     (just spelled with raw `love.keyboard.isDown` instead of `Key.shift()`).
     **Misattributed as frame-time.**
   - `maze/main.lua:564` (`function is_shift_down()`) — **not frame-time.**
     Its only call site is `:569`, inside `function love.keypressed(k)`
     (`:568-571`). Same correction: **event-time**, not frame-time.

   So of the four line citations offered as "projects poll at frame time,"
   two are genuine frame-time polls and two are event-time polls
   mis-cited as frame-time. This is a real inaccuracy in the evidence trail
   this session itself produced (`session31/track.md:55-56` repeats the same
   four citations verbatim from the S31 prompt) — worth correcting even
   though it doesn't change the bottom line.

**Net judgement: the "theoretical" verdict is overturned, correctly — but on
the strength of one dispositive example (`examples/keyboard`, reading
`compy.input.keys_pressed` itself, at draw time — the exact surface member
in question) plus two genuine (not four) raw-`isDown` frame-time polls in
other projects (which poll non-modifier keys, so they're adjacent evidence
of frame-time device-state reads in this codebase generally, not
direct evidence about `Key.ctrl/alt/shift` or `compy.input.keys_pressed`
specifically). The citation list should be corrected to drop or re-label
`clock/main.lua:68` and `maze/main.lua:564` as event-time, not frame-time.**

### B. Is the seam between the polled tier and the event-tracked tier actually clean?

**No — confirmed not clean, and this matches session31's own track.md
correction (§"three corrections to session30," item 3), independently
re-derived here rather than taken on faith.** See falsification attempt 5
above for the full trace. Summary: `find_shortcut` itself is genuinely
poll-free (reads only `Controller.keys_pressed` + `Key.is_mod`, confirmed at
`projectInputController.lua:101-111`) — the event-tracked *tier* is clean in
isolation. What is not clean is that the **gateway function that writes the
event-tracked set also runs the device-polled reserved-shortcut gates, in
the same function, before forwarding** (`controller.lua:787-897`), so a
wrong-clock false positive upstream can consume a keystroke before the
correct-clock tier downstream ever sees it. This is real, pre-existing (not
introduced by this branch — verified in attempt 5), and named as
open debt (`P9e`) rather than closed. "Not clean" and "not a regression"
are both true at once; they answer different questions.

---

## What this session is not seeing (or: what I'd flag if I had to pick one thing)

1. **The plan documents disagree with the operational boundary being
   asked about, and nobody has reconciled them yet.**
   `doc/development/technical_debt/input.md:58,77-79` and
   `doc/development/wip/77-new-input-api/validation/reviews/S27-triage-and-plan.md:549-550`
   both say P9d/P9e are **"Before the PR"** ("Scheduled: before the PR").
   The S31 charter (`validation/notes/S31-owner-attestation-where-we-are.md:59-62`)
   is explicitly asking whether they can be shipped **after**, in separate
   PRs. That's a legitimate replan the owner is entitled to make — but as of
   this session, `technical_debt/input.md` and the phase table still read as
   if P9d/P9e/P13 are pre-PR blockers. If the owner rules "ship now, defer
   these," those two documents need an explicit amendment (not just this
   review's verdict) or a future reader will treat them as still-blocking
   and be confused about why the PR shipped without them.

2. **Sub-claim 1 undercounts the shipped surface, which is a red flag worth
   naming even though it doesn't break anything.** The claim frames the
   shipped surface as `hooks` / `shortcuts` / `keys_pressed`. Reading
   `consoleController.lua:527-543,712-787`, the actual shipped
   `compy.input` surface also includes `callbacks`, `fn`
   (`consume`/`side_run` combinators), and the widget-control methods
   (`show`/`hide`/`is_shown`/`get_cursor`/`set_cursor`/`set_text`/
   `configure`/`clear`). None of the deferred items touch any of these — the
   staleness/harmony/gate-migration items are all about the held-key/combo
   tier specifically — so this doesn't change the verdict. But a claim that
   understates its own surface before arguing "nothing on the surface has to
   change" is a shape worth double-checking every time it recurs: the
   argument is only as strong as the inventory of what's being defended, and
   a wider future audit should re-derive the full surface from
   `consoleController.lua` rather than from this claim's abbreviated list.

3. **The `find_shortcut`/`dispatch` reuse seam (falsification 3) is
   architecturally sound but empirically unexercised** — one caller,
   confirmed by grep across `src/`. That's fine for a "purely additive,
   nothing has to be redone" claim (nothing about it would need to change to
   add a second caller), but it means sub-claim 3 is currently a *design*
   claim, not yet a *proven* one. Worth a cheap validation before it's
   treated as settled: a throwaway adapter that calls `dispatch` from, say,
   a test double standing in for the console, to prove the widget-optional
   path (`if widget and widget:is_shown()`) really does degrade gracefully
   with `widget == nil` for a channel that has none.

---

## Summary

| # | Falsification target | Result |
|---|---|---|
| 1 | `keys_pressed` shape/semantics change | Not found. Holds (Decision 29 rules it out; P9d writes via the existing convention). |
| 2 | Combo vocabulary / shortcut table shape change | Not found. Holds. |
| 3 | Editor/console enrollment forces a dispatch rewrite | Not found. Holds — reuse seam is real (`dispatch`, not `find_shortcut`, carries the widget param) but unexercised by a second caller. |
| 4 | Harmony enrollment touches the surface | Not found. Holds — confirmed empty `git diff 3256aac HEAD -- src/harmony/`, confirmed additive mechanism. |
| 5 | Polled+event-tracked combination worse than either alone | Not found. Holds — seam is genuinely not clean, but pre-existing and unworsened, both verified against base. |
| 6 | Shipped API assumes held-set reliability a recovery path must break | Not found. Holds. |
| A | Census scoping ("theoretical" verdict) | Overturned — correctly, but 2 of the 4 supporting citations (`clock/main.lua:68`, `maze/main.lua:517,564`→ only `:517`) are event-time, not frame-time; the dispositive evidence is `examples/keyboard/input.lua:47`'s draw-time read of `compy.input.keys_pressed` itself. |
| B | Seam cleanliness | Confirmed not clean — pre-existing, named debt (P9e), not a regression. |

**Bottom line: the claim holds. I attacked all five falsifiers and both
scoping judgements directly against code and could not produce a case where
a deferred item forces shipped work to be redone.** The two things worth
carrying forward are process, not code: get `technical_debt/input.md` and
the P9d/P9e/P13 phase-table rows to agree with whatever the owner rules
about "ship now, defer later" (finding 1 above), and correct the two
mis-cited frame-time line references before they propagate further
(scoping judgement A).
