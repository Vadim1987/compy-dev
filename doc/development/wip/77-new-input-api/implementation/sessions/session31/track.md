# session31 — track

## 2026-08-09 — boot

- Booted per `agents/validation.md` → `agents/sessions.md`. **Fresh start**:
  session31 held only `prompt.md`; no `track.md` / `report.md` (sessions §2 row 1).
- HEAD `2dd94148` "docs(session30): wrap — report, operational-modes rule,
  session31 prompt", branch `feature/77-newapi-analysis-s20260615`. Working tree:
  only the known untracked scratch (`claude.sh`, `src/STEPS.md`,
  `input-pr-slices.tar.gz`, `doc/tall_blocks.md`,
  `doc/development/wip/{clarification,personal-notes,pull-26}/`) plus the three
  nested example repos (`src/examples/{balloons,keyboard,maze}`). **No tracked
  modifications.**
- **Baseline confirmed: `busted tests` → 955 / 0 / 0 / 3.** Matches the prompt.
- Read in full: `agents/validation.md`, `agents/sessions.md`,
  `agents/rules/revalidation.md`, this prompt, session30's `report.md` +
  `prompt.md` + `track.md`.
- Mode declared before starting: **evaluation + replanning**. Execution is
  explicitly not this session's mode (session31 prompt, and the new
  "Operational modes" section of `agents/validation.md`).
- Task as understood, stated to the owner before proceeding:
  **part 1** — run the red-flag checklist over session30's findings and
  re-verify its load-bearing facts (70-site census, zero-device-polls on the
  project-facing path, empty `git diff 3256aac HEAD -- src/harmony/`);
  **part 2** — present the A/B/C decomposition and the Q0–Q5 agenda to the
  owner for rulings, with B gated on whether the probe has been run on the
  device. Rulings are the owner's; none are mine.

## 2026-08-09 — owner attestation + charter amendment

- Owner gave a full account of how the thread reached here (smoketest regressions
  → tactical keyboard/textinput fix rejected → hallucinated design → session29
  cleanup → harmony discovery → the polling-clock question). **Materialised
  verbatim-in-substance** at `../../../validation/notes/S31-owner-attestation-where-we-are.md`
  at their explicit instruction.
- **Charter amendment:** cold checks may be **Opus** where judgement-heavy, not
  Sonnet-only. Explicit-model rule unchanged.
- **The real ask of this session, in the owner's framing:** can an *operational
  boundary* be drawn that ships the new input API now (postponing editor/console
  rebuild and the polling problem to separate PRs) **without risk of redoing the
  shipped work**. The failure they name: shipping an API that later proves
  unsupportable or un-enrollable into editor/console/harmony.

## 2026-08-09 — three corrections to session30, all code-verified

1. **The polled gates are pre-existing verbatim.** All 10 `Key.ctrl/alt/shift()`
   sites in `controller.lua` exist at `3256aac` (base lines 163,180,531,553,564,
   571,580,585,586,643); `keys_pressed` does **not** exist at base. So the
   polling problem predates the feature entirely and is not a regression it
   introduces. Strongest single fact for the boundary.
2. **Session30's census was wrongly scoped.** It counted 70 sites over 5
   controllers; whole-`src` is **76**, six of them in `src/examples/`
   (sapper ×4, tixy, paint). Its conclusion — "zero frame-time or draw-time
   keyboard polls, so Decision 29 clause 3's justification is theoretical" — is
   **overturned**: projects poll at frame time (`examples/pong/strategy.lua:35`
   paddle movement, `examples/clock/main.lua:68`, `examples/maze/main.lua:517,564`)
   and `examples/keyboard/input.lua:47` states outright that it reads
   `INPUT.shift` **from draw** (`keyboard_view.lua:171,178`), resolving to
   `compy.input.keys_pressed`. **The owner's 2.2(a) caveat was right and
   sessions 29/30 did overlook it** — but it cuts the opposite way: keyboard's
   draw-time read is of the *event set*, which is only possible because the API
   exposes it outside an event. The held set is load-bearing for the deliverable.
3. **The seam is not clean, though it is not new.** `find_shortcut`
   (`projectInputController.lua:101-112`) is genuinely poll-free — confirmed,
   reads `Controller.keys_pressed` + `Key.is_mod` only. But `handlers.keypressed`
   (`controller.lua:788`) sets the set and then runs **device-polled** power
   shortcuts (quickswitch Ctrl+T `:791`, Ctrl+Alt+R/P `:840,845`) **upstream of
   project dispatch**, and `keyreleased:907` polls Ctrl for Ctrl+Esc. A
   wrong-clock false positive there can steal a keystroke from a running project
   (tap `t`, Ctrl arrives same batch → project run stops). Pre-existing, so
   risk-accepted rather than architecture-clean — the owner should sign the
   boundary knowing that.

## 2026-08-09 — Fable consultation spawned

Model **Fable**, explicit. Prompt of record:
`../../../validation/prompts/S31-boundary-challenge-fable.md`; deliverable
`../../../validation/reviews/S31-boundary-challenge-fable.md`. Task: **attack**
the load-bearing claim that every deferred item is purely additive under the
shipped surface (`hooks` / `shortcuts` / `keys_pressed`), plus judge the two
mis-scoped session30 findings. Chosen as an attack on my own reading rather than
a cold generation of it — being wrong here is exactly the "big mistake" the
owner named.

## 2026-08-09 — Fable verdict: claim HOLDS, with two precision corrections

Deliverable: `../../../validation/reviews/S31-boundary-challenge-fable.md`.
Attacked all five falsifiers against code; **could not break** the additivity
claim. Load-bearing points it established:

- `keys_pressed` **shape is safe**: Decision 29 already rules out l/r folding;
  P9d writes through the existing `Controller.keys_pressed[k] = nil` convention
  (`controller.lua:906`); the `__pairs` iteration limit is on the **project-facing
  proxy only**, not the backing table a framework-side recovery would use.
- **P13 additive and harmony-side only** — traced `love_key`/`love_event`
  (`harmony/init.lua:272-293`): non-modifier keys already reach
  `Controller.keys_pressed` through the real gateway today, so extending that to
  modifiers needs no new surface.
- **Sub-claim 3 softened, and correctly.** The widget parameter belongs to
  `dispatch(...)` (`projectInputController.lua:132`), **not** `find_shortcut`,
  which reads `Controller.keys_pressed` as a module global and has **exactly one
  caller** (`ProjectInputController:_dispatch`). The reuse seam is **sound design,
  not yet empirically exercised by a second adopter** — a weaker guarantee than I
  stated to the owner, and the honest form of it.
- **Confirms** the pre-existing-gate seam is genuinely not clean, and byte-for-byte
  pre-existing at `3256aac`.

**Two of my four frame-time citations were wrong — verified myself, Fable is
right:** `clock/main.lua:68` reaches the poll via `color_cycle(k)` called from
`love.keyreleased:80`, and `maze/main.lua:564 is_shift_down` is called from a
key handler at `:569`. Both **event-time**. Genuinely frame-time: only
`pong/strategy.lua:35` and `maze/main.lua:517` (`poll_tab_progression`, called
from `love.update:530`, edge-detecting a device poll). The scoping overturn
stands on those two plus `keyboard/input.lua:47`'s draw-time read of
`compy.input.keys_pressed` — which Fable rates the strongest evidence, and it is.

**Process gap Fable flagged, independent of any ruling:**
`technical_debt/input.md` and the P9d/P9e/P13 phase-table rows still say
"Scheduled: before the PR" while the proposed charter ships now and defers them.
Needs reconciling either way.

## 2026-08-09 — owner reframes: net adoption impact is the quality metric

**Owner ruling in effect — the probe will NOT be run.** Delivering code to the
device and collecting numbers costs owner time, spent on a problem already agreed
deferred. Accepted, and it costs nothing: the measurement can only inform *how*
to fix the polling problem, never *whether* to defer a defect that is verbatim
pre-existing at `3256aac`. Module **B stays unruled** — as designed.

**The reframing, and it moves the axis of evaluation.** The owner's metric is the
**net impact of adopting the new API across the examples**:

- positive = simplification, or increased stability/correctness;
- negative = unjustified complication or destabilisation (argues against);
- **mild negative (overhead)** = adopting *solely* to avoid breaking, no benefit;
- bad outcome = shipping the API with examples left broken or un-improved.

Not all examples are equal: **`keyboard` and `maze` are primary student-facing**;
lesser examples may be temporarily broken *if* eventually fixable *and* the
platform-level benefit outweighs the deferral.

**My earlier answer was drawn on the wrong axis** — I answered the *risk*
question (does shipping force rework) when the owner is asking the *value*
question (is what ships worth shipping). The boundary analysis stands; the
ship-set drawn from it does not, because it was sized by risk, not impact.

**Structural fact verified, and it reshapes the ledger:** `seed_hooks`
(`projectInputController.lua:65-71`) seeds a project's own `love.keypressed` /
`textinput` / … into `hooks[event]` when no explicit hook is set. **Legacy
examples keep working untouched.** Consequences:

1. The owner's **"overhead" category is nearly empty** — nothing must adopt to
   survive, so every adoption decision is decidable on pure impact.
2. The "shipping breaks examples" fear is largely not real. Exceptions are the
   census's job to find; `keyboard` is *already* broken on device (the original
   bug), which is not new breakage.
3. Worth stating in the PR description: the API is **additive and opt-in**, so
   adoption is a value judgement, never a survival tax.
   **Caveat:** I verified the seeding mechanism, not end-to-end delivery
   equivalence — shortcuts run ahead of hooks and the pre-existing power gates
   ahead of everything, so per-example checking is still required.

**Category I would add to the owner's four:** an example that *correctly should
not adopt* is a **positive**, not a gap. `pong/strategy.lua:35` (frame-time,
level-triggered paddle movement) is the likely case — continuous reads are served
badly by events. An API that can point at when *not* to use it reads as designed
rather than evangelised, and converts a hole in the adoption story into a
documentation asset.

**Census spawned** (model **Opus**, explicit — judgement-bearing):
prompt `../../../validation/prompts/S31-example-adoption-impact.md`,
deliverable `../../../validation/outcomes/S31-example-adoption-impact.md`.
Covers all 14 examples: surface used today, timing class of every non-event read
(resolved **by callers**, the trap that caught the last pass), breakage-if-unadapted,
impact in the owner's categories, verdict. **No decomposition will be re-proposed
until it returns** — the ship set is now an impact question and I do not have the
evidence yet.

## 2026-08-09 — census returns: my backward-compat claim is REFUTED

Deliverable: `../../../validation/outcomes/S31-example-adoption-impact.md`
(Opus, read-only, suite re-confirmed 955/0/0/3).

**I was wrong, and it is verified.** I told the owner legacy examples "keep
working untouched" because `seed_hooks` seeds `love.*` into `hooks[event]`.
`seed_hooks` preserves **delivery** but not **ordering relative to the widget**:

- **Base** (`3256aac:controller.lua`, keypressed tail): `if user_input then
  user_input.C:keypressed(k) else if love.keypressed then ... end` —
  **either/or**. Widget shown ⇒ the project handler is **not called**.
- **HEAD** (`dispatch`, `projectInputController.lua:132-142`): shortcut → **hook**
  → widget. The hook runs **first and unconditionally**.

So every project holding both a `love.keypressed` handler and the input widget
changes behaviour. **Two live regressions, both re-verified by me:**

- **turtle** — `main.lua:33-40`: Space toggles `debug`, Shift+R recentres; prompt
  shown at `:83`. Typing a space into the TURTLE prompt now toggles the debug
  overlay. Its own comment at `:73-77` ("would work the same written as
  `compy.input.hooks.*`") is now **false**.
- **maze** — `main.lua:568-577` + `SYSTEM_KEYS.escape` (`:552`) →
  `love.event.quit()`. `escape` alone returns early; **Shift+Escape falls through
  and quits the app** while the maze prompt is shown. **Student-facing.**

Neither is visible in any migration diff — neither migration touched those
handlers. Fix is a 2-4 line `is_shown()` guard each.

**One census claim CORRECTED.** It said `compy.singleclick` is rawset and read by
nobody, so "paint and sapper die with no error at all". They do not: both already
use `compy.input.hooks.singleclick` on this branch (`paint:356`, `sapper:671`), a
live derived channel (`controller.lua:74-76`, `projectInputController.lua:38`,
synthesised at `:572`). At base both used `function compy.singleclick(x, y)` —
they were migrated in-tree. **The real finding underneath is different and
arguably worse:** `compy.singleclick`/`doubleclick` were a project API at base and
are **retired**; in-tree examples were migrated, **out-of-tree student projects
were not, and they fail silently** — the assignment lands on the namespace and
nothing reads it. Backward-compat break with **no diagnostic**.

**API gap that undercuts P9b's premise — verified.** `textinput` hook payload is
`function(t) return t end` (`projectInputController.lua:51`); no `isrepeat`, and
LÖVE's own `love.textinput(t)` carries none to pass through. `keyboard/input.lua:134`
says exactly this. So **keyboard must KEEP** `spendGlyph` / `GLYPH_CLAIMED` /
`upRecent` / `INPUT_UP_GRACE` (~20 lines) even after full adoption. The premise
that adoption subtracts that machinery **does not hold**; deriving the flag
platform-side *is* the ordering problem this whole thread started from.

**Scorecard on the owner's metric (census):** positive — keyboard (−19 lines,
and adoption was *not forced*), guess (−14), repl, tixy (correctness), maze *if
finished*. Overhead (~0 net) — paint, sapper, valid, balloons. **Negative** —
turtle, **+13 lines on a 58-line beginner example** plus echo-guard ceremony.
`pong` confirmed **do-not-adopt** (fixed-timestep level-triggered polling,
state-keyed bindings); near-misses `life` (hold-to-reset) and `paint` (cursor
position) have **no API equivalent** — `keys_pressed` is keyboard-only.

**This is the Fable trigger I pre-registered to the owner:** net impact outside
keyboard/guess is thin, one example is a net negative, and the flagship's headline
subtraction is gone. "Is the feature worth its change surface" is now a genuine
judgement call with a costly wrong answer.

## 2026-08-09 — owner supplies the motivating bug; it inverts the census reading

Attestation appended to `../../../validation/notes/S31-owner-attestation-where-we-are.md`.
**Modal input widget**: once shown it consumed keyboard events wholesale, no
modifier combo could reach the project, text was poll-only, lifecycle limited to
self-closing on one-shot input. **Corroborated, not merely accepted:**
`decisions/input.md:73` records the same defect and **Decision 1** is stated at
`:95` as *"the single structural change the subsystem exists for."*

**This inverts how turtle and maze are counted.** They are **not** accidental
regressions — they are the **intended effect** of Decision 1. Both were written
*against* the modal bug and relied on the widget swallowing their keys. The
`is_shown()` guard is the project's responsibility under the fixed contract.
Changes the narrative and the PR description; does **not** change the todo — maze
quitting on Shift+Escape is student-facing and must be fixed before ship either way.

**The scope question now has a sharp, uncomfortable shape.** If the widget stops
swallowing, a project's existing `love.keypressed` fires and it reads
`Key.ctrl/alt/shift()` exactly as it always did — so **the motivating bug may be
fixable with zero new project-facing API**. On that reading `hooks` / `shortcuts` +
combo strings / `keys_pressed` are **ergonomics layered on the fix**, motivated by
the separate "stop `if Key.shift()` cascades" goal the owner already ruled does
**not** decide the source question. **Hypothesis, handed to Fable to test — not
asserted.**

**Sharpest supporting point, from the owner's own blocker accounting:** the one
thing actually broken was the keyboard **alt** subgame (`keypressed`/`textinput`
order). The census established the API **cannot** remove the machinery that
handles it — `textinput` carries no `isrepeat`. So **the one functional blocker
is not fixed by the platform feature**; it is fixed by the example's rewrite.
That strengthens the reduction case materially.

**Argument for reduction independent of the API's merits:** the owner's other two
blockers were **readability of the change** and **upstream catch-up**. Both get
strictly worse as surface grows, and both improve directly under a cut.

**Counterweight, to keep honest:** unpicking is not free — ~30 sessions of work,
examples already migrated, reverting carries its own risk and review burden. A
reduction costing more than shipping is not a reduction. Fable is quantifying it.

**Fable #2 spawned** (explicit model): prompt
`../../../validation/prompts/S31-scope-reduction-fable.md`, deliverable
`../../../validation/reviews/S31-scope-reduction-fable.md`. Question: is the built
surface **justified** by the bug it fixes; if partly, which parts; what is the
minimum shippable feature; and the strongest argument against its own answer.

## 2026-08-09 — Fable #2 + owner's stakeholder correction: the cut has a shape

Deliverable: `../../../validation/reviews/S31-scope-reduction-fable.md`.

**Fable's two hard claims, both re-verified by me:**

- **`keyboard` uses the widget NOWHERE** — zero hits for
  `compy.input.show/hide/is_shown/callbacks` in the whole example. So Tier B's one
  strong adopter **cannot be evidence for the modal-widget fix**, by construction.
  The seven actual widget users are `turtle`, `maze`, `tixy`, `balloons`, `valid`,
  `guess`, `repl` — and `guess`/`repl`/`tixy` are census positives, which supports
  Tier A on its own evidence.
- **keyboard's ordering machinery predates API adoption.** `git show 4814407^:input.lua`
  already carries `INPUT.held`, `upRecent`, `INPUT_UP_GRACE` and the stale filter.
  The adoption commit `4814407` is the **owner's own**: *"This game predates the API
  and grew its own equivalents… the game's behaviour is meant to be unchanged."*
  The real fixes came after, as `f938fbc` (restore LÖVE's `(k, sc, isr)`) and
  `3a9d48c` (accept the first glyph whatever order it arrives in).

**Fable's recommendation:** do not revert code (entangled history; would regress
keyboard's own best number; risks a clean 955/0/0/3) — but **stop letting Tier B
completeness gate release**. P9d/P9e/P13 confirmed Tier-B-only debt. Must-fix
regardless: the two `is_shown()` guards and a diagnostic for the retired
`compy.singleclick`. **Its own strongest counter-argument:** keeping Tier B as
permanent documented 1.0 surface is *itself* a commitment the owner's
"would-we-undo-this" test should be applied to — it weighted revert cost over
commitment risk.

## 2026-08-09 — owner: stakeholder intent, and two findings downgraded

Owner directed me to the frozen `design/` stakeholder inputs. **They settle the
scope question in a direction neither I nor Fable had evidence for.**
`design/requirements.md` "What was requested":

- *"cannot react to keyboard events while a prompt is on screen"* — the modal bug.
- **"Event notifications instead of polling — callbacks for submit (Enter),
  non-text key events (**Ctrl combos**, navigation, function keys)…"** — so the
  **combo/shortcut surface is stakeholder-requested**, not assistant-invented
  scope. Tier B1 is justified by the mandate itself.
- **"Consistency — expressive enough that the REPL and editor *could* be
  re-implemented on it (a completeness target, not a commitment to rewrite)."**
  → **Deferring P9e and the 76 sites is exactly what was asked for.** The
  stakeholders wanted sufficiency, never the rewrite.

Owner adds: stakeholders were **ready to accept regressions in non-critical
examples**, and *"they also wanted a more ergonomic API on the same surface."*
So `turtle`'s +13 lines is acceptable collateral; **`maze` is not** (student-facing).

**Two findings downgraded on owner ruling:**
- **`textinput` has no `isrepeat`** — owner already has a design: compare against
  the previous textinput, *"honest enough"* on repeat. Closable; a heuristic, and
  an example-side fix either way. No longer a blocker on P9b's premise.
- **`compy.singleclick` retirement** — *"pure ergonomics"*, already moved once
  from `love.` to `compy.`, movable again; shim cheap if ever needed; **no known
  student projects using it**. Downgraded to low priority.

**Where that leaves the cut — my proposal, owner's ruling.** The mandate covers
Tier A **and** Tier B1 (shortcuts/combos). The one piece traceable to **neither**
the stakeholder ask nor the modal bug is **`compy.input.keys_pressed` as public
API** (Decision 20). It is also the piece carrying **all** the unresolved debt:
staleness/P9d, recovery/Q1, serialised form/Q4, repeat counting/Q5, P9e, P13, and
the whole polling-clock question hang off the exposed held set. **Cut = keep the
event-tracked set internally (combo strings need it), stop exposing it publicly.**
Cost, stated honestly: `keyboard` reads it from draw (`input.lua:57`,
`keyboard_view.lua:171,178`) and would keep the mirror it had before — eroding
part of its −19. That trade is the owner's to make.

## 2026-08-09 — owner asks two planning questions; both answered NO, on evidence

**Owner's framing check:** *"almost all correct and within mandate, except
exposure of `keys_pressed`?"* — **Yes**, with one addition: their deliberate
abstention from enrolling controller/editor was not merely acceptable, it is
**literally the mandate** (`design/requirements.md`: expressive enough that REPL
and editor *could* be re-implemented — *"a completeness target, not a commitment
to rewrite"*). That deferral needs a **citation**, not a justification.

**Q1 — sweep examples to replace `Key.*` with combos? NO.** By the owner's own
metric this is the mild-negative "overhead" category made systematic. The census
scores the candidates: `paint` and `sapper` (the `Key.*` users, all event-time)
convert at **~0 net lines**; `tixy` is the only correctness gain; `pong` is
**do-not-adopt** (fixed-timestep level-triggered); `life` and `paint` have **no
API equivalent** at all — `keys_pressed` is keyboard-only, and less so if we cut
its exposure. Convert only census-positives. Additional reason: the examples are
the **demonstration surface** — a mixed set showing combos where combos fit and
polling where polling fits teaches the boundary better than uniform conversion,
and gives `doc/input_api.md` a concrete "when not to use this".

**Q2 — wrap remaining `Key.*` in the new API for a centralized channel? NO, and
the reason is that the seam already exists.** Verified: `src/util/key.lua:141-164`
defines `shift()` / `ctrl()` / `alt()` as **three one-line functions**, and all 76
call sites go through them. Swapping polling for a tracked-table query later is a
**three-function edit in one file** — a wrapper would centralize what is already
centralized, add project-facing surface that changes no behaviour today
(overhead), and pull in the opposite direction from the `keys_pressed` cut: both
are "answer a held question outside an event", so adding one while removing the
other is incoherent.

**The real gap, and it is one line.** The guarantee the owner wants is that no
platform code bypasses that seam. Verified: outside `util/key.lua`, `harmony/`,
`probe/`, `examples/` and the metalua string fixtures, there is **exactly one**
raw platform-side poll — `src/lib/error_explorer.lua:418`
(`key == 'c' and love.keyboard.isDown('lctrl','rctrl')`). Closing that plus a grep
guard buys the whole centralization guarantee at **zero API surface**. Examples
are exempt by ruling — projects get the real `love` table and physical querying is
a permitted project channel (owner, session30).

## 2026-08-09 — owner refutes my cut; I withdraw it. Two corrections + a doc bug

**1. "Projects get the real `love` table" — I was WRONG.** Verified against
`doc/development/internals/project_sandbox_env.md`: a project runs in a
`setfenv`'d env whose `love` is a **deep clone with fresh identity**, but
`table.clone` returns non-tables as-is, so **every leaf function is the same C
function**. Precise statement: *a project's `love` table is sandboxed; the
functions in it are not.* Consequences — `love.keyboard.isDown` called from a
project **is** the real engine call (polling works); but a project *assigning*
`love.keypressed` writes into its **own clone**, harvested by
`save_user_handlers` (`consoleController.lua:824`) and re-installed as a **hook**,
never as a global handler. My session30-derived shorthand was wrong on the table
and right only on the consequence.

**2. The cut is DEAD, and the owner killed it with one question.** *"Without
exposing `keys_pressed`, how does a project branch inside a hook?"* The documented
answer is `keys_pressed` itself — `doc/input_api.md:372`: *"The held set below is
for what a combo cannot express"*; `:390`: *"a handler that wants held state reads
`compy.input.keys_pressed` the same way a `love.draw` does."* And it **is**
traceable to the mandate after all: the stakeholder ask is **"event notifications
instead of polling"**, so answering in-hook modifier questions with `Key.ctrl()`
would fail the ask for everything a shortcut cannot express. **`keys_pressed`
exposure is load-bearing, not ergonomics. Proposal withdrawn.**

**3. Why not build combo strings by polling `Key.*` instead (owner's follow-up)?**
Three reasons, stated with their strength:
- **Mandate** — polling to build the framework's own combo answer reintroduces
  precisely what the ask names.
- **Clock** — the event set is exact at the moment of the event; polling asks a
  second question whose answer may have moved (tap `s`, Ctrl arrives in the same
  batch → plain `s` fires as `ctrl+s`). **Honest caveat: structurally verified,
  never measured** — the owner declined measurement, correctly, so this is a
  structural argument, not an empirical one.
- **Cost** — the info is already in hand: `handlers.keypressed` sets
  `keys_pressed[k] = true` as its first statement, free. `combo_string` is 6 table
  lookups; polling would be 3 `isDown(unpack(...))` calls with unpack allocation
  **per event**, and `technical_debt/input.md` already flags combo-string
  allocation.
- **Decisive structurally:** removing the set saves **two lines** and costs three
  call sites a poll. No simplification is available — only a clock downgrade.

**4. DOC BUG found, and it resolves Q3.** `doc/input_api.md:268` claims a hook
*"receives the held-key table as its second argument on all three channels"*.
`:390` says the opposite (*"LÖVE's own arguments and nothing added"*), and **the
code agrees with `:390`**: `dispatch` calls `sc(...)` and `hk(...)` — varargs only,
nothing added (`projectInputController.lua:133-136`). So **`:268` is stale/false**.
Q3 (the trailing argument) is therefore **already no-change in code**; what remains
is a doc fix. The owner's own `REMARK` at `:263` — *"we may decide not to deliver
keys_pressed as an argument… lets popularize [`compy.input.keys_pressed`]"* —
is already the implemented state.

## 2026-08-09 — owner's two closing claims: one half-right, one wrong (good news)

**Claim A — staleness is an accepted documented low-probability risk, fix later.**
**Half right.** Documented ✓ (`technical_debt/input.md`), and the entry even
pre-refuses the owner's own earlier suggestion: *"do not rebuild combos from
`Key.*` to dodge the staleness… would trade a bounded, fixable staleness for an
unbounded, unfixable one."* **But two corrections:**
- **"Low probability" is unestablished.** Severity is high — one phantom modifier
  silently disables **every unmodified shortcut on every channel**. Probability is
  unmeasured (owner declined, correctly). High-severity / unknown-probability.
- **"Invent a fix later (e.g. capture refocus)" — that fix is P9d and it is
  already scheduled BEFORE the PR**, per the debt entry itself. What defers is the
  **general recovery path (Q1)** for causes other than focus loss. Accurate form:
  *known cause fixed now; residual staleness from unknown causes is the accepted
  documented risk.*

**Claim B — the mandate tells us to sweep all examples onto combos or
`keys_pressed`.** **No.** `requirements.md` asks for the API to exist and be
expressive; nothing mandates converting examples, and a blanket sweep is the
owner's own "overhead" category (agreed one exchange ago). **The narrower sweep
that does survive their metric:** *event-time device polls inside project handlers
→ `keys_pressed`* — a correctness gain at ~0 lines, because the poll answers an
event-time question with a frame-time source. Candidates: `turtle:34,92`,
`clock` (via `color_cycle` from `keyreleased`), `maze is_shift_down`,
`sapper` ×4, `tixy`, `paint`. **Frame-time polls stay:** `pong/strategy.lua:35`,
`maze/main.lua:517`.

**Claim C — it will require updating harmony. WRONG, and verified.** Harmony does
drive examples (`scenarios/examples.lua`), but the **only** modifier chord it
sends there is `C-S-q` (4×), and `C-S-q` is a **gateway gate** — `controller.lua:813-831`
(`Key.ctrl()` → `k == "q"` → `Key.shift()`), not an example binding. Same for
`console.lua`'s `C-l`. Every key harmony sends that an **example** interprets is a
plain key (`return`, `space`, `i`, `down`), and harmony pushes those as **real
events**, so they already reach `Controller.keys_pressed`.
→ **Converting examples is independent of harmony.** The harmony change is needed
only when the gateway's own gates stop polling — i.e. **P9e**, deferred. **P13
stays coupled to P9e and defers with it**, exactly as session30 concluded.
*Caveat: harmony is outside CI and outside busted; this is read, not executed.*

## 2026-08-09 — owner catches TWO overstatements of mine. Both conceded.

**1. I over-read the mandate. Conceded.** Owner asked whether "polling" in the
stakeholder ask meant only the **modal text widget's** polled reference. Read
`design/requirements.md` §2.3/§3 in full — **they are right**:
- **FR-5/6/7 are all scoped to the edit area**: notification on submit,
  notification of *"a key event … that does not produce a text character **in the
  edit area**"*, boundary hit **in the edit area**. These are **widget callbacks**.
- **NFR-2**: event-driven *"rather than requiring the project to poll **a reference
  for results**"* — the **narrow** sense. It is **not** a general prohibition on
  `love.keyboard.isDown`.

So my claim that answering in-hook modifier questions with `Key.ctrl()` "would
fail the stakeholder ask" was **wrong**. Corrected position:
- Tier A (modal fix + widget lifecycle/config): **mandated** (problem statement,
  FR-1..4, FR-8..10).
- **Ctrl-combo notification while the edit area is active: mandated (FR-6).**
  The generalisation to a **project-wide** shortcut table beyond the widget is
  **ours** — defensible, but larger than the ask.
- **`compy.input.keys_pressed` exposure: NOT mandated.** It is defensible on the
  owner's own ground — *more predictable than lifetime polling* — and on
  coherence (the in-hook answer should not run on a different clock from the
  combo answer). **A design argument, not a mandate argument.** I should have
  said that the first time.
- **FR-11/FR-12 are explicitly "expressiveness targets, not a commitment to
  rewrite"** — deferring console/editor is textbook-correct, not a concession.

**2. Event buffering in production — owner's challenge lands. Conceded.**
Verified: the **only** `love.run` in `src/` is `harmony/init.lua:104`, installed
inside harmony's conditional init (`love.harmony` exists only under
`love src harmony`). **Production runs LÖVE's stock `love.run`, which is upstream
and NOT in this tree.** Consequences:
- Session30's "the batched-pump mechanism is **code-verified**" was verified
  against a **dev-only** loop. Overstated for production.
- The production claim rests on LÖVE 11.5's default `love.run` (pump the queue,
  then dispatch one at a time) — **documented upstream behaviour, unverifiable
  here**, and unmeasured by choice.
- Net: the clock argument is **upstream-documented + unmeasured**, not
  code-verified. Weaker than it has been presented in three sessions.

**3. Staleness causes — owner substantially right, one real qualification.**
Confirmed only two writers, so the set **is** the event stream; and
`love.handlers.keypressed/keyreleased` are installed **once** at the gateway
(`setup_callback_handlers`), so no route or state transition can swallow a
release. Their reasoning holds. **But:**
- Focus-**out** holding a key, released outside → **phantom** (false positive).
  This is the case P9d addresses, and the timestamp sweep they propose fixes it.
- Focus-**in** with a modifier **already held** → **false negative**: the set says
  not-held while it is. Effect is the mirror image — `ctrl+s` fails to fire and a
  plain `s` runs instead. **The owner's "reverse path self-heals via key repeat"
  holds for ordinary keys but is doubtful for modifiers, which commonly do not
  auto-repeat** — platform-dependent, and exactly what the probe would settle.
  **A timestamp sweep does not fix this**: a key never recorded has no stale entry
  to expire. Flagged as *uncertain*, not asserted.

## 2026-08-09 — the structural comparison, done properly; and harmony's two suppressions

**Structural profile — the frame the thread has been missing:**

| | device polling | event tracking |
|---|---|---|
| error source | state read at dispatch for an event queued earlier | set diverges when an event is never delivered |
| direction | both (false +/−) | both (phantom on focus-out; missing on focus-in) |
| **duration** | **transient** — bounded by one batch | **unbounded** — until that key is pressed/released again |
| **accumulation** | **none, stateless** | **accumulates, stateful** |
| dissolved by user retry? | **yes** | false negative **yes**; **phantom NO** |

**So the owner's "event-tracked precision has no practical value" is HALF right, and
the wrong half cuts against event tracking.** Retry dissolves polling errors in both
directions and dissolves event-tracking false negatives. Retry does **not** dissolve
an event-tracking **phantom** — the user retries `s`, it fails identically every
time, because the phantom `lalt` is still there, and no natural user action clears
it (pressing/releasing that exact modifier is not an obvious response to "my
shortcuts stopped working").

→ **P9d is not a small fix. It is what removes event tracking's only
non-self-healing failure mode.** That promotes it from "tidy before PR" to "the
thing that makes the model's structural profile acceptable at all". **Recorded as
the strongest argument yet for keeping P9d in scope.**

**Combos on mouse/pointer — the owner's worry is real but cuts FOR what they built.**
Keyboard and mouse share one SDL queue, so `love.event.poll()` yields them in queue
order. Under **event tracking**, at dispatch of a `mousepressed` the set holds
exactly the keys whose `keypressed` was queued **before** it — precisely the right
answer to *"was Ctrl held when the user clicked"*. Under **polling** we get "what is
held now, after the whole batch", which does not answer that question at all. So
extending combos to the pointer channels **strengthens** the event-tracked case.

**textinput is the genuine exception, and narrower than it looks.** The unordered
pair is `keypressed`/`textinput` **for the same key**. Modifiers were pressed much
earlier (hold Shift, then type), so they are reliably in the set. **The ordering
hazard is about the triggering key, not the modifiers** — which is exactly the
keyboard-example bug and exactly why `spendGlyph` exists. The thread had not drawn
this distinction.

**Side-question answered: harmony performs TWO different suppressions, neither of
which is "suppressing modifier events".**
1. **Modifier events: it never generates them.** `love_key('C-S-s')` sets
   `held[m] = true` per modifier and emits **no event**; only the non-modifier key
   gets `love_event('keypressed'/'keyreleased')` (`init.lua:275-292`). Nothing to
   suppress — it simply does not emit.
2. **Real physical input: dropped when locked.** `harmonius_run` honours only
   `sazed_`-prefixed events; everything else hits the `else` branch where only
   `quit` and `keypressed('escape')` survive (as quit) and **all other real events
   are discarded** (`init.lua:69-77`).
3. **The physical poll is suppressed too when locked**: `patch_isDown` returns true
   for its own `held`, and falls through to the real `down(...)` only `if not lock`
   (`:249`).
→ Locked harmony is a **complete replacement of the input surface** — no real
events, no real polls, only its own table plus synthetic non-modifier events. That
is why it is a second implementation, and why its synthetic modifiers exist **only**
in the poll channel.

## 2026-08-09 — owner challenges Decision 29 at its root. Sound; not reversed; exit path found.

**Harmony: owner right, and stronger than they put it.** Harmony's modifiers exist
**only** in the poll channel, so it **cannot exercise the combo mechanism at all**.
Nothing breaks today — every chord it sends (`C-S-q`, `C-l`, `C-S-s`, `C-f`…) is
resolved by the **gateway's polled gates**, and the one real shortcut it triggers
(turtle's `compy.input.shortcuts.textinput["i"]`) carries **no modifier**, so
`combo_string('i', {})` = `'i'` matches. So: an **unexercised capability gap**, not
a live failure — but harmony can never test the new mechanism, a real cost for a
tool whose job is driving the app.

**The owner's fundamental objection, in its sharpest form (sharper than they put
it):** the only way to detect drift in the event model is to compare against the
device poll. **If reconciliation requires polling, the device is the authority and
the tracked set is a cache of it** — and a cache that needs the authority to
validate it is strictly more machinery than asking the authority. **This is the
strongest single argument against Decision 29 made in this thread.**

**Two places I over-credited event tracking last message. Corrected:**
- **ctrl+click / pointer combos** — the failure needs the modifier state to *change
  within the batch*; Ctrl is held throughout a ctrl+click. Same rare window as
  everywhere else. My "strengthens the event-tracked case" was **overstated**;
  it is neutral.
- **Draw-time reads** (keyboard's key-cap renderer) — polling is arguably
  **better**: a key-cap display should show what is physically held *now*, and
  there is no event to align with. Point to the owner.

**Frequency: the owner's analysis is reasonable but unmeasured — symmetrically.**
Two keydowns inside one 16 ms frame needs a fast burst; deliberate combo use holds
the modifier for hundreds of ms. Their cases (a) unusual hit-and-release and
(b) engine stall are the right ones. But having flagged session30's skew as
unmeasured, the same standard applies here: argument, not data. **Asymmetry that
does favour them: polling's errors are ephemeral, so being wrong costs less.**

**DECISIVE, verified: the surface is SOURCE-AGNOSTIC, so shipping commits nothing.**
`keys_pressed` is handed out as a memoised read-only proxy
(`controller.lua:428-441`) with `__index = backing`. Swapping the source to polling
= change `__index` to a **function** calling `love.keyboard.isDown(k)` — ~3 lines,
one function, project-facing contract **identical** (`keys_pressed['lshift']` →
truthy, writes raise). `combo_string`/`any_mod` read the backing table directly and
need the same swap, also small. `__pairs` is already inert on LuaJIT, so no loss.
→ **Not a "would we have to undo it" case. A swappable implementation behind a
stable API.**

**Recommendation to the owner: do not reverse now.** Cost is ~30 sessions of built
work, migrated examples and a green suite, to remove an unmeasured risk that P9d
already de-fangs. Instead:
1. **Ship P9d** — kills the only non-self-healing failure mode.
2. **Record the owner's objection as a first-class standing counter-argument** in
   `decisions/input.md` beside Decision 29, including the reconcile-requires-polling
   point — as a recorded design tension, not as debt.
3. **Record the swap path explicitly** (proxy `__index` + `combo_string` + `any_mod`)
   so a future session neither re-derives it nor believes it is locked in.
**Caveat stated to the owner:** if reversal is a live option, the cheapest moment is
**before** further example migration, so it should be decided **this session**, not
deferred — the cost only grows.

## 2026-08-09 — owner's fixture proposal: correct, AND ALREADY BUILT

Owner asked whether a poll-derived design just needs the fixture to mock `Key` the
way harmony does, with `press('ctrl')` mutating mocked state. **Yes — and it
already exists.** `tests/mock.lua:60-70` `keystroke(s, …)` is harmony's `love_key`
**verbatim in shape**: split on `-`, `held[m] = true` for each modifier with **no
event emitted**, dispatch the real key; plus `release_keys()` at `:49`. The only
fix needed is **one line** — `mock.lua:30` `isDown = function(k) return held[k] end`
is **single-arg**, so `Key.ctrl()` (= `isDown('lctrl','rctrl')`) only ever consults
the left key.

**Corollary that favours the owner's position:** this is a **third** implementation
of the input surface — harmony fakes the poll, `mock.lua` fakes the poll, and
production now carries a tracked set beside the poll. **Two of the three fakes are
poll-shaped and both predate the feature.** The ecosystem around this codebase
already speaks "poll"; the feature introduced the only thing that does not.

**LIVE FIXTURE HAZARD, independent of the decision.** `keystroke('C-s')` sets
modifiers **only** in `held` and emits no modifier event, so
`Controller.keys_pressed` never sees them. Any combo test must therefore set
`keys_pressed` directly (38 references in `tests/`, plus
`helpers/input_fixture.lua:272`). **The suite has two disjoint ways to say "ctrl is
held" that do not agree**, and a test author must know which one their code under
test reads. Fixture-fidelity debt (S7 territory) either way.

**Honest counterweight to the owner's proposal:** a poll fixture **cannot reproduce
the batch-skew bug** — set `held`, dispatch, and the mock is always self-consistent
because SDL timing is not modelled. So under polling the failure mode becomes
**untestable**. Under event tracking the stale-set bug **is** testable (push
`keypressed` with no `keyreleased`). This sharpens A's testability argument: it is
not "the state is injectable", it is **"A's failure mode is expressible in a test
and polling's is not"** — which matters only if a guard would ever be written for
an ephemeral, self-healing error.

**Migration cost of the swap:** 38 `keys_pressed` test references +
`input_fixture.lua:272` move to driving `held`, against a 955-green suite. Not
huge, not trivial.

## 2026-08-09 — OWNER RULING: Decision 30. Recorded and committed.

Owner ruled and instructed me to write it down. Materialised as **Decision 30**
in `doc/development/decisions/input.md`, **superseding Decisions 13, 20 and 29**
(the three held-key-set decisions), which now carry `— SUPERSEDED by Decision 30`
in their headings. **Decisions 8, 21, 26, 27 stand unchanged** — only the *source*
the matcher reads changes, not the combo vocabulary or the argument contract.
Committed `9733d2d3`, docs only, suite **955 / 0 / 0 / 3**.

**The four rules as ruled** (owner numbered two items "3"; recorded as 3 and 4):
1. Device polling is the single source of held-modifier truth; `keys_pressed`
   **dissolved from all occurrences**, production and test. It was an
   **implementation-time** decision, never a requirement — reverted on that basis.
2. `Key.*` is **legitimate inside the shortcut matcher** that builds the combo
   string — the one place a direct read is not merely permitted but correct.
3. `Key.*` **at a call site remains a smell**, to be replaced by the shortcuts
   mechanism — for introspectability and the related reasons named this session.
   **One standing exception:** the framework's own gate for global power-like
   combos, upstream of route dispatch.
4. Where a shortcut does not fit: **a tiny shortcut sets a feature flag and does
   not consume its triggering event**; the hook runs the heavy logic against
   **flags**, not hardware state.

**Rationale as recorded:** stateful model over an entity we do not control, which
can neither be prevented from drifting nor reconciled — and the only way to detect
its drift is to poll, making the device the authority and the set a cache of it.

**Consequences written down honestly, not softened:** batch-skew accepted and
**unmeasured** (as was the staleness it replaces); the failure mode is **no longer
expressible in a test**; `tests/mock.lua`'s single-argument `isDown` **must** become
variadic before the suite can be trusted about modifiers; and P9d / P9e / P13 / Q1 /
Q4 / Q5 are **withdrawn, not deferred** — they were properties of the tracked set.

**MODE BOUNDARY — flagged to the owner.** Recording the ruling is this session's
work (evaluation + replanning). **Executing the dissolution is execution mode** and
is large: `keys_pressed` appears **22× in `src/`** (7 files incl.
`examples/keyboard/input.lua`), **38× in `tests/`**, **15× in decisions**, **12× in
internals**, **15× in technical_debt**, **8× in `doc/input_api.md`**. That belongs
to a fresh session, not to this context.

## 2026-08-09 — WRAPPED

Owner called the wrap and set the successor's nature: **recheck + replan**, on the
grounds that this replanning attempt turned into more analysis — *expected*, in
their words, because **replanning is unblocked iteratively by eliminating
uncertainty.** Recorded as their framing, not mine.

Suite **955 / 0 / 0 / 3** throughout. Two commits: `9733d2d3` (Decision 30) and
this wrap. Nothing pushed.

Informal verdict given to the owner on request: **strong decision, weakly evidenced
on the technical claim it appears to rest on, strongly evidenced on the
architectural one it actually rests on.** Named as weak spots: two unmeasured
frequency claims pointing opposite ways; the suite gets *quieter* (staleness was
testable, skew is not); Rule 3's exception is under-specified and will erode;
the keyboard example is the real casualty. Feasible, and the sequencing constraint
is that **`mock.lua`'s variadic fix must land first** or every later modifier
result is unreliable.

Distilled into `report.md`; successor commissioned as session32 and the pointer
repointed. Track kept raw per `agents/sessions.md` §3.

## Sub-agents

Three, all with prompt of record and deliverable on disk:
- **Fable** — boundary/additivity challenge → `validation/reviews/S31-boundary-challenge-fable.md`.
  Verdict: claim holds; corrected my `find_shortcut`/`dispatch` widget-parameter slip.
- **Opus** — per-example adoption census → `validation/outcomes/S31-example-adoption-impact.md`.
  Found the widget-ordering behaviour change I had wrongly ruled out.
- **Fable** — scope-reduction consultation → `validation/reviews/S31-scope-reduction-fable.md`.
  Established the Tier A/B split, that `keyboard` uses the widget nowhere, and that
  its ordering machinery predates API adoption.

One census claim was **wrong** and corrected in-session (`compy.singleclick` as
silently dead in paint/sapper — both had already migrated to
`compy.input.hooks.singleclick`); the real finding underneath was out-of-tree
projects failing silently. Sub-agent output was useful and not taken at face value.
