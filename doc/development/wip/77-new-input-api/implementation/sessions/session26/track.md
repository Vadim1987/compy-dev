# session26 — track

## 2026-08-03 — boot

- Booted per `agents/validation.md` boot ritual + `agents/sessions.md`.
  Re-entrance guardrail: `session26/` held only `prompt.md` — no `track.md`,
  no `report.md` → **fresh start**; this entry opens the track.
- HEAD `22ba5b07` (`docs(input): record three owner rulings given at the
  wrap`), branch `feature/77-newapi-analysis-s20260615`. `git status` clean
  apart from the sanctioned untracked scratch (`claude.sh`, `src/STEPS.md`,
  `input-pr-slices.tar.gz`, `doc/tall_blocks.md`, `doc/development/wip/
  {clarification,personal-notes,pull-26}/`) and the three nested example
  repos (`src/examples/{balloons,keyboard,maze}` — not anomalies, owner
  2026-07-31).
- Read: `agents/validation.md`, `agents/sessions.md`, `session26/prompt.md`,
  `session25/{prompt,report,track}.md`.
- Baseline `busted tests` → **904 / 0 / 0 / 3**, exactly the count the
  session26 prompt states. (`agents/validation.md`'s fallback line still says
  854/0/0/4 — the prompt is authoritative per that same section; noting, not
  "fixing".)
- Task per prompt: **wait for the human** — session26 specifies no work of its
  own, by the owner's instruction at the session25 wrap (*"tell your successor
  to move on in coordination with me"*). On instruction: record it in track
  (verbatim if a ruling), name which open item it lands in **before** touching
  files, then act. Do not start Phase G, the wrapper rename, or a fix sweep
  unprompted.
- Reported the orientation to the owner; awaiting instructions.

## 2026-08-03 — owner reorders: code-moving work before the smoke test

- Owner: *"3 before 1 otherwise I will have to smoketest twice."* — the
  deferred wrapper rename (open item 3: `forward_*`, `userlove`, the
  `*_native` trio) moves ahead of the owner's smoke test (item 1). Lands in
  **the ordering of the plan**, not in any single item's content: the earlier
  ruling only said the rename happens "just before the PR", which left it
  ambiguous against the smoke test.
- Raised back, not acted on: **item 2 (the bare-`*` raise) is also production
  code** and by the same principle belongs before the smoke test. Measured
  first — no example registers a bare `*` (`keyboard/input.lua:84` is
  `alt+*`, a class), so it cannot change what the smoke test sees today; the
  argument for pulling it in is that it touches `check_combo` at all, not a
  known effect.
- Owner also asked to be reminded of the **three stakeholder-deferred
  questions**, saying they may rule them out. All three are owner-ruled
  (2026-07-31) "leave as-is, refer to stakeholders", all three are
  **pre-feature behaviour**, and all three sit in `technical_debt/input.md`
  under Open decisions: the raise-surface asymmetry (:267), the error lock
  (:293), and `repl` not evaluating (:334). Presented with their options and
  recommendations; ruling is theirs.

## 2026-08-03 — owner rules the three out of the plan; bare-`*` pulled forward

- Owner ruling, verbatim: *"well those three stakeholder-deferred must be in
  technical debt (they have bad impact on usability) with suggested fixes
  awaiting stakeholders approval past main PR. reason: stop bloating the scope
  of PR, and allow stakeholders a chance to contest fixes (in case those
  glitches had some real unobvious reason behind them). So, if they are in the
  tech debt in the same form, they could be dropped from the current
  development plan and we won't revise them until after PR."*
  → **Open item 6 leaves the plan.** Condition attached: they must already be
  in debt *in that form*.
- Checked the condition rather than asserting it. Two nits, neither fatal:
  (i) all three read **"Revisit: stakeholder review of the PR"**, which can be
  read as *during* review / before merge — the ruling says *past* the PR;
  (ii) the raise-asymmetry and the error lock carry **Recommended:** lines,
  `repl` carries options with **no recommendation**. Raised to the owner as a
  wording-alignment offer, not executed.
- Owner: *"Regarding bare-'\*' raise -- yes, lets implement it before
  smoketesting too just to stop code fluctuations."* → open item 2 joins item
  3 ahead of the smoke test. Rationale recorded because it generalises: the
  smoke test is priced per run, so **everything that moves code lands first**.
- Owner: *"Now, lets focus on renaming."* → open item 3 is the active task.
  Survey delivered before touching files (below).

### rename survey — findings that need an owner ruling

- Blast radius is **`src/controller/controller.lua` only**: every symbol in
  the cluster is `local`. Public `Controller.{set,save,restore,clear}_user_
  handlers` are NOT in scope and keep their names, so **no test and no other
  source file changes** (`tests/helpers/input_fixture.lua:222` and
  `consoleController.lua:124,995,1159` all bind the public names).
- **The two recorded candidate sets disagree, and the debt entry is wrong on
  fact.** `technical_debt/input.md:784` describes `forward_*` as routing "to
  the currently-active keyboard route" and proposes `route_keypressed`; the
  in-code note (`controller.lua:145`) proposes `to_widget_*`. Measured:
  `get_user_input()` (`:21`) returns `love.state.user_input` — the active
  input **widget**, gated off under `inspect` — so the call never selects a
  route; it hands the event to the widget *inside* the console route, which
  is exactly what the header comment at `:26` already says ("Intra-route
  forward"). `to_widget_*` is accurate, `route_*` is not.
- **`userlove` is factually wrong at one of its two entry callsites.**
  `restore_user_handlers` (`:1181`) passes `Controller._userhandlers` — a
  saved-handler table, not a sandboxed `love` table. `set_user_handlers`
  (`consoleController.lua:124`) passes the real `env['love']`. So the
  parameter is a handler *source*, and `project_love` (the recorded
  candidate) would be wrong half the time.
- **The `*_native` trio overlaps a second, separate debt entry** (`:39`,
  "Project-handler wrapping: dedup the guard, drop the misleading
  `keyboard_` name"), which asks for a guard dedup as well as a rename. That
  entry's own note says it was carved out *specifically* to avoid blessing
  the smell with fresh names. Flagged: rename-only vs rename+dedup is the
  owner's call, and if both, they are two commits.

## 2026-08-03 — owner: is `forward_*` the pre-PIC lockout gate, surviving?

- Owner's hypothesis: *"it looks literally symmetrical with what we had on the
  project route before ProjectInputController became alive. And I wonder is it
  a leftover of the change supposed to be done but which landed less
  universally than it should?"*
- **Checked against the PR base rather than agreed with. They are right on the
  shape, and it is sharper than "leftover".**
- Pre-feature (`3256aac`): the gate lived in **`love.handlers.*`**, above both
  routes — `local ui = get_user_input(); if ui then ui.C:keypressed(k) else
  if love.keypressed then return love.keypressed(k) end end`. The console's
  own default (`set_love_keypressed`, old `:162`) had **no widget check at
  all** — it ran the debug hotkeys and then `CC:keypressed(k)`
  unconditionally.
- Today: the handlers-level gate for the three keyboard channels is **gone by
  design** — `controller.lua:987-995` says so explicitly ("Widgets are
  reached inside the route, never gated here"). But the same boolean gate was
  **re-expressed one level down, inside the console route**, as `forward_*`.
  So it was relocated, not removed.
- **This contradicts Decision 1 in its own words.** `decisions/input.md:88`:
  *"Widget visibility is state on the widget, never a routing condition"*;
  `:95`: *"the overlay gate is gone."* `if forward_keypressed(k, isr) then
  return end` is widget presence acting as a routing condition. The project
  route got the real answer (the PIC chain, consume semantics); the console
  route kept the old shape.
- **Blast radius measured, and it is small — which is presumably why it
  survived review.** Shadowed when a project overlay is up on the console
  route: `CC:keypressed`'s ctrl+L, ctrl+alt+t, pageup/pagedown history, the
  error-lock clear, Enter→evaluate, and the editor fork. NOT shadowed: the
  power shortcuts (ctrl+t / ctrl+pause / ctrl+q / ctrl+s in
  `handlers.keypressed`, ctrl+escape in `handlers.keyreleased`) sit **above**
  `love.keypressed` entirely, and the ctrl+shift debug toggles were lifted
  **above** the forward call (`:461-484`) where pre-feature they sat below the
  gate. The editor fork is not reachable in practice: ctrl+t calls
  `stop_project_run` → `hide_overlay()` before entering the editor.
- **Not the same thing, do not conflate:** `handlers.mousepressed` (`:1036`)
  still reads `get_user_input()` directly, but it **broadcasts** — widget
  *and* slot occupant both fire. That is ruling 9's ratified out-of-scope
  asymmetry, not the exclusive gate.
- Consequence for the active task: **the rename is now blocked on a ruling.**
  `to_widget_*` would name and bless a gate Decision 1 says is gone. Presented
  to the owner; ruling theirs.

## 2026-08-03 — full chain traced and materialized

- Owner asked for the whole path, generation to consumer. Written to
  `validation/notes/S26-event-chain.md` — every line reference verified in
  code at `22ba5b07`, not recalled.
- Two things the trace turned up that the discussion had not:
  - **Tier 1 (`love.handlers.*`) is structurally un-shadowable** and holds
    ctrl+t / ctrl+pause / ctrl+q / ctrl+s (and ctrl+escape on keyreleased).
    `love.handlers` is frozen at `:1144` (`table.protect`). That is why the
    console-route gate has almost no observable blast radius — the power
    shortcuts were never behind it.
  - **The editor is not a slot occupant**, only a fork inside
    `CC:keypressed` (`consoleController.lua:1387`). So "three sibling
    routes" is true of the design, not yet of the code —
    `occupy_keyboard:236` already admits this.
- Also noted while reading: `handlers.mousepressed:1040-1041` carries an
  empty `else` branch — dead syntax, cosmetic, not fixed (report-don't-fix).

## 2026-08-03 — four follow-ups; the chain note gains an addendum

Owner asked: could the console run the project's chain instead of the gate;
what installed the checked widget pre-feature; is the console's own
UserInputController that widget; what are the five things behind the gate;
and how does the console take over on suspend/raise. All answered in
`validation/notes/S26-event-chain.md` §Addendum, verified in code.

- **The console's own line is NOT the gated widget** — and this is the
  correction that matters, because I left it off the first diagram. Two
  instances exist: `consoleController.lua:44`
  (`UserInputController(M.input):always_shown()`, never registered) and a
  project overlay via `show()`. The console line lives *below*
  `CC:keypressed`, not in the chain.
- **Pre-feature the installer was also the project** — old
  `consoleController.lua:562` `input()`, called only from
  `input_code`/`input_text`/`validated_input`/`user_input`. So the actor
  never changed; the API and the gate's location did.
- **The suspend path answers why the gate is invisible on that route.**
  `suspend_run` → app_state `'snapshot'` → `love.update:715` screenshots →
  `CC:suspend()` sets `'inspect'`, arms the console line's error lock with
  the raise message, saves the project's handlers and reinstalls the console
  defaults. Under `'inspect'` `get_user_input()` returns nil
  (`controller.lua:22`), so `forward_*` reports false and `CC:keypressed`
  runs in full — which is exactly what the just-armed error lock needs.
- **The unification the owner sketched already has its seam cut.**
  `dispatch` (`pic.lua:90`) is deliberately a free function over plain
  tables + a widget reference, its own doc comment saying "so any adopter
  (not only the project overlay) can reuse it over its own instance"; and
  `build_widget_api` (`consoleController.lua:630`) is parameterized by
  resolvers for the same stated reason. Two independent seams pointing the
  same way.
- But it is **not** covered by the standing "Future input unification" entry
  (`technical_debt/input.md:26`) — that one is about **pointer** only. A
  console-route chain would be a new entry. Flagged, not written: recording
  it is a ruling.

## 2026-08-03 — owner asks where the pre-feature project route was mounted

- Hypothesis: *"we carved out project route to be directly installable into
  love.handlers and kept all if-dispatching machinery inside the controller
  intact… pre-feature project route was mounted somewhere around 'editor
  fork'?"*
- **Checked; the answer is no, and the correction is worth keeping.**
  Pre-feature `set_handlers` (`3256aac` `controller.lua:73`) did
  `love[key] = CC:wrap_handler(new, wrap)` inside `hook_if_differs` — the
  project's own handler went **straight onto the `love.keypressed` slot**,
  the same slot it occupies today. It was never inside `CC:keypressed`.
- Two further corrections to the framing: (i) the project route does not
  install into `love.handlers` — that is tier 1, frozen at `:1144`, and
  neither route touches it; the route installs into `love.keypressed`,
  tier 2. (ii) Pre-feature there was **no project route at all** — one slot
  held either the console's handler or the project's raw handler, with the
  widget gate above both. "Route" is Decision 1's vocabulary, introduced by
  this feature.
- **Where the intuition is exactly right:** the feature built a real
  dispatcher for ONE occupant of the slot (PIC, with the project's old raw
  handler demoted to the `hooks` tier and seeded by the *same*
  `orig ~= new` guard) and left the other occupant as the hand-rolled
  if-chain — then bolted the removed gate onto the front of it.
- Corroborating detail found while checking: pre-feature `_supported`
  (`3256aac:28`) ran keyboard AND pointer through one `hook_if_differs`.
  The feature split them into `_keyboard`/`_pointer` (`:89`/`:95`), which is
  precisely why two wrapper builders now exist carrying a duplicated guard —
  the debt entry at `technical_debt/input.md:39`. The split is the cause of
  that debt, not a coincidence.

## 2026-08-03 — owner reasons the gate to near-dead; CONFIRMED by enumeration

- Owner: *"if project is running it occupies the slot. if project is not
  running, then no project widget could be up. what does the console check
  then?"* — and separately, why the editor forks instead of occupying a slot.
- **Enumerated every app_state rather than reasoning about it. The owner is
  right: the gate is dead in every normal state and live in exactly one
  error path.** Table in `validation/notes/S26-event-chain.md` §Addendum 2.
  The two interlocks that make it dead were not designed as a pair but
  behave like one:
  - `run_project:278` only releases the route when `user_is_interactive()`
    is false, and that predicate (`controller.lua:1157`) is
    `love.state.user_input ~= nil or user_pointer` — so the route is handed
    back **precisely when no overlay is up**.
  - `suspend()` never hides the overlay, but `get_user_input()`'s
    `'inspect'` gate (`controller.lua:22`, Decision 12) makes it invisible
    anyway; `stop_project_run` hides it outright (`:1274`).
- **The one live path:** project top-level calls `compy.input.show{}` then
  raises → `run_user_code`'s pcall fails → `run_project:265`
  `release_keyboard_route` (which does NOT touch `love.state.user_input`,
  `controller.lua:814`) → console owns the slot, app_state is
  `'project_open'` not `'inspect'`, overlay still registered → **the gate
  fires.** Its only live behaviour is to send keystrokes to the overlay of a
  project that failed to load, while the user faces a console that "gave no
  signal they were still inside a project" — the exact complaint in the
  raise-asymmetry entry deferred to stakeholders this session.
- Also confirmed: `build_widget_api` has **one** adopter
  (`consoleController.lua:746`, the project overlay). The reuse seam exists
  and is unused; the console never calls `show()` on its own line.
- **Editor fork: ratified deferral, not oversight.** `decisions/input.md:97`
  — *"The three routes are siblings. Today the editor is still reached
  through the console route's internal fork rather than as a fully
  independent third sibling; converging the console and editor onto the same
  chain the project route already uses is deliberately left as a follow-on…
  The project route is the proving ground for the shape."* The owner has
  re-derived the follow-on Decision 1 names.
- **Consequence for the rename ruling:** option 2 (delete the gate) is much
  cheaper than I priced it last turn. Removing near-dead code whose only
  live path is a defect is not the risky pre-smoke-test change I described.
  Revised recommendation given.

## 2026-08-03 — PLAN RUN: three commits, gate gone

Owner: *"ok, lets plan the fix and run the plan now."*

De-risked first with a throwaway probe (gate forced to `return false`,
suite run, probe reverted): **901/3/0/3** — only three rows depended on it,
and none of them was pinning the gate.

- **`e7ae8953` — production fix.** Breaking test first, in
  `input_route_lifecycle_spec.lua` (new describe "teardown after a top-level
  raise"), driving the REAL `run_project` with only the loader stubbed. Both
  rows red before: row 2 reproduced the swallowed `show()` verbatim —
  `WARN: show ignored — overlay already active`, widget still holding the
  failed run's `'x'` instead of `'two'`. Fix: `hide_overlay()` after
  `release_keyboard_route` in the failed-run branch; `hide_overlay` moved
  above `run_project` for lexical scope, body unchanged. 904 → 906.
- **`26971c49` — fixture fidelity.** The three probe failures were in
  `input_cursor_text_spec.lua`; they showed an overlay and typed with NO
  route active, so delivery rode the gate. Switched to
  `F.activate_project()` — same surface returned, plus the route a real
  project's overlay is fed through. No assertion changed. 906, unchanged.
- **`7be800f6` — the gate deleted.** Three `forward_*` gone, three console
  defaults call `CC:<event>` unconditionally. `get_user_input()` kept — draw
  and the pointer broadcast still use it. 906, unchanged.

Docs kept honest in the same commit rather than left dangling: the
`forward_*`/`userlove` entry loses the deleted half (and its factual error —
it described routing "to the currently-active keyboard route" when the call
went to the console route's active *widget*); "On the console route, a hidden
widget's input falls to the console line" is now **RESOLVED by
construction**; two `internals/user_input.md` passages rewritten.

### Left for the owner, not folded in

- **Two rows now pass vacuously.** `input_widget_lifecycle_spec.lua`, "a
  hidden widget does not consume" (`#disputable`): with no widget step on the
  console route, a *shown* widget behaves the same as a hidden one there, so
  the rows no longer discriminate. Re-siting them on the project route
  changes what they assert (no console fallback there), so it is a decision,
  not a move. Recorded in the resolved debt entry under "Left over".
- **The raise path still leaves shortcuts, hooks and widget callbacks live**
  — `clear_user_handlers` is never called there. Hiding the overlay was
  enough to remove the gate; the rest of Decision 11's teardown invariant on
  that path is a separate concern and a separate commit.
- **The rename surface is now much smaller:** `userlove` plus the `*_native`
  trio, all still file-local to `controller.lua`.

## 2026-08-03 — teardown completed; owner's inspectability check answered

- Owner: *"any reason to not teardown them? … there is no inspectability on
  raise, its only activates by purpose not on crash, correct? … if just
  technically deferred fix, lets run it."*
- **Half right, and the half that matters is right.** `inspect` IS reached on
  a crash — `user_error_handler` (`controller.lua:81-87`) calls
  `suspend_run`, alongside the deliberate ctrl+pause route (`:881`). But NOT
  on a **top-level** raise: `run_user_code` catches it with a bare
  `pcall(f)` (`consoleController.lua:118`), not
  `xpcall(f, user_error_handler)`, so `suspend_run` is never called and the
  state never becomes `'inspect'`. On the path being fixed the project is
  **dead, not suspended** — there is nothing to inspect, so inspectability is
  no argument for keeping its participants alive.
- **Deferred fix, not a decision.** Decision 11's teardown invariant already
  ratifies the outcome verbatim ("No callback, combo entry, or widget
  configuration survives the project that installed it"), so this implements
  a ruling rather than making one. Ran it.
- **`f0999d94`** — `clear_user_handlers(self)` after `hide_overlay()` in the
  failed-run branch. Test first: the raising project's top-level installs a
  shortcut, a hook and two widget callbacks; all four asserted gone. Red
  before, green after. 906 → 907.
- **One sub-question deliberately left open**, because it IS a decision and
  not mine: whether a failed load should fire `compy.before_exit`.
  `stop_project_run` does; this path does not, on the reasoning that the hook
  belongs to a run that started. Noted in the commit and in the code comment.

## 2026-08-03 — owner endorses the before_exit call; checking it found a leak

- Owner: *"judgment on non firing before_exit — makes sense to me if it
  happens on the 'project never started properly' path. no proper start, no
  contract is expected to run. let me know if I am mistaken."*
- **Not mistaken, and stronger than judgment: the frozen spec already says
  so.** `design/spec/M6-02-before-exit.md` §Contract: *"Fires: on project stop
  — whether triggered by user action (Ctrl+Esc), framework-controlled stop, or
  normal exit. Guaranteed to fire for framework-invoked stop paths;
  **crash/hard-kill is not covered** (Layer 2 scope)."* So excluding it was
  implementing the ratified contract, not exercising taste.
- **But checking it turned up a real leak, and it is a different question.**
  The slot is a closure behind the compy namespace's `__newindex`
  (`consoleController.lua:807-818`) and is restored to the default **only** in
  `stop_project_run` (`:1294`); `clear_user_handlers` never touches it. So a
  project that set `before_exit` in top-level and then raised left its
  function in the slot, where it fired at the **next** project's stop — a dead
  project's teardown running against a live project's state.
- **`226628ae`** — reset, not fired. `default_before_exit` moved above
  `run_project` for lexical scope, joining `hide_overlay`. Test with its
  control built in: install the failed project's hook, run and stop a second
  project, assert the first did not fire. Red before, green after.
  907 → 908.
- Worth keeping: the owner's framing ("no proper start, no contract") is right
  about *firing* and would have been wrong if applied to *resetting* — the
  slot is state, not a contract, and state has to go regardless. Two questions
  wearing one name.
- **Residual, pre-existing, not introduced here:** the hook's whole purpose is
  restoring global device state a project mutated imperatively
  (`setKeyRepeat`, `setTextInput`, raw audio — the spec's "T3 leak"). A
  top-level raise after such a mutation still leaks it into the next run. The
  spec names that Layer 2 and excludes it, so it is a ratified gap; recording
  it as debt is a ruling, not mine.

## 2026-08-03 — owner rules the global-state leak into debt

- Owner: *"on dirty global state in case of project raise before project can
  clear itself — mark as tech debt. we need to implement proper force-reset,
  later."* Also asked whether "a dead project's teardown running against a
  live project's state" was still open — **it was not**; that sentence was
  describing the defect `226628ae` had just fixed, in the same message that
  reported the fix. Clarified.
- **`60b3127a`** — two Standing entries in `technical_debt/input.md`.
  - The leak itself, with the shape the owner specified: a **framework-owned
    force-reset** on every run-ending path, independent of
    `compy.before_exit`, on the reasoning that a crashed project cannot be
    trusted to clean up after itself — which is exactly why its own hook is
    the wrong instrument. Both rulings that keep it standing are recorded
    (hook scoped to stop paths by design; firing a partially-initialised
    project's teardown ruled against, owner 2026-08-03), and the fixed part
    is separated from the standing part so a reader does not re-open it.
  - **Found while writing the first:** `compy.before_exit` is a public,
    project-settable slot that appears in **neither** `doc/input_api.md` nor
    `decisions/input.md`. Its only specification lives in `wip/77`, which is
    scheduled for deletion — and the strategic frame requires the PR to be
    reviewable from `doc/input_api.md` plus the description alone. The debt
    entry above also depends on that contract being findable. Flagged for a
    pre-PR decision; not written, because what `input_api.md` says is the
    owner's call.

## 2026-08-03 — owner: "just document it, now"

- **`65ed04bf`** — `doc/input_api.md` gains "Stop hook — `compy.before_exit`",
  placed before Migration. Contract established from **code**, not from the
  frozen spec, since the spec is scheduled for deletion: the fire site
  (`stop_project_run:1287`, before the framework's own teardown), the reset
  (`:1294`), the slot mechanism (namespace `__newindex` closure), and the stop
  paths enumerated by grepping `stop_project_run`/`quit_project` callers.
- Placed on `compy`, not `compy.input`, and the guide says why — it is a
  project-RUN hook, not an input-channel callback, and a reader who finds it
  under the input API would reasonably expect it to behave like one.
- **Every doc clause is pinned, and the new one was mutation-checked.** The
  strongest claim — *does not fire when the project's own code raises* — had
  no coverage: the existing row pinned only that the hook does not SURVIVE.
  Widened that row to two checkpoints (not fired at the raise; still not
  fired at a later run's stop, which is the control) rather than adding a
  duplicate. Then mutated the production path to fire the hook on the
  failed-run branch and confirmed the row goes red. Suite unchanged at 908.
- Standing lesson applied without being told: a row asserting an absence gets
  a mutation check and a control. This is the fourth time this phase a green
  row would otherwise have been blind.
- Debt entry from `60b3127a` closed as RESOLVED in the same commit.

## 2026-08-03 — owner challenges the two-wrapper split; it exposes a real defect

- Owner: *"if surrounding code does not care about result we still can use
  function that returns it. it just gets dropped on call site. minus one
  function variant?"*
- **Right on the principle, and my earlier framing was wrong.** I had said the
  two builders "differ in one thing only — the return value". A returning
  function IS usable where the return is ignored, so return policy alone never
  justified two functions.
- **Checking what else differs found a production defect.**
  `chain_native` binds CC in a closure —
  `xpcall(fn, function(m) user_error_handler(CC, m) end, ...)` — correct.
  `wrap` (`controller.lua:95-105`) passes the handler **directly**:
  `xpcall(f, user_error_handler, ...)`. xpcall invokes a message handler with
  ONE argument, but the signature is `(CC, msg)` — so `CC` binds to the error
  string, `msg` is nil, `'user error: ' .. msg` raises *inside* the message
  handler, and xpcall swallows it. Nothing reaches `suspend_run`.
- **Measured, not reasoned** (throwaway spec, run and deleted):
  - raise in a project **pointer handler** → handler runs, error vanishes,
    `app_state` stays `'running'`. No error window, no console line.
  - raise in a project **`love.update`** → same. This is the most likely
    place for a real game bug to be.
  - raise in a **keypressed hook** → suspends correctly (the `chain_native`
    path).
  - `_G.web` is falsy on this build, so the broken branch is the live one.
- **The ledger is wrong because of it.** The raise-asymmetry entry says
  "Raised from a `love.*` handler or hook: `wrap` → `user_error_handler` →
  `suspend_run(msg)` → the error window". True only for the keyboard chain.
- **Blast radius of a fix:** `wrap` has 3 call sites (`:136` via
  `wrapped_native`, `:658` loader, `:676` project update) and `wrap_handler`
  has 3 (`:136`, plus `:629`/`:641` — the compy single/double click
  handlers). All are the same one-line error-handler arity bug.
- **Direction of the answer to the owner's question:** yes, one variant can
  go — but `chain_native` is the correct one and `wrap` is the broken one, so
  the collapse should go toward `chain_native`'s shape, which fixes pointer
  and update as a side effect. The `_G.web` branch is the one thing that must
  be carried over or ruled on. Presented; ruling theirs.

## 2026-08-03 — owner rules the bug out; option 1 executed

- Owner: *"if we just discovered old behaviour which is certainly a bug, I do
  not see a point in preserving it under the premise 'behaviour change was not
  approved by stakeholders'."* Chose variant #1 (fix, then collapse), asked
  for the exact diff or a commit range.
- Worth recording as a **limit on a rule this session applied twice**: the
  pre-feature→debt reflex (used for the three stakeholder items, and which I
  had just cited back at them) applies to *behaviour someone might have
  wanted*, not to a certain defect. I priced the two the same and the owner
  separated them.
- **`2554d2e3` — the fix.** Five production lines: `wrap` gets an `on_error`
  closure binding CC, used by both branches. Tests first, three rows — pointer
  and update red, keyboard green as the control that the other two are not
  asserting something impossible; each asserts the handler RAN before raising
  so a skipped handler cannot pass by never reaching its error.
  - Fixture gap surfaced by the fix, not a production issue: with `suspend_run`
    finally reached, `love.update` walks into the snapshot branch in the same
    tick and the gfx mock had no `captureScreenshot`. Added as a no-op that
    never invokes its callback — which models the real gap between
    `suspend_run` and `suspend`, and matches how the existing inspect row
    already drives `CC:suspend()` by hand. 908 → 911.
- **`f1dc6aee` — the collapse.** Three functions become two:
  `wrapped_native`/`keyboard_native` → `project_handler` (the guard, once),
  `chain_native` → `chain_project_handler` (the wrapper, once). `hook_pointer`
  and `project_handlers` share it; the pointer site drops the return, which
  `love.handlers` and the poll loop discard anyway. `CC:wrap_handler` survives
  for the compy click handlers. 911, unchanged.
  - **The web branch is carried, not dropped** — the conservative reading of
    the owner's "carry it into the unified wrapper, or rule it obsolete". Cost
    of carrying it: `wrap`'s web branch had to start answering `ok, r` instead
    of bare `r` so the two branches agree. Safe because every caller discards
    the result; it also makes the `@return` annotation true of both branches
    for the first time, closing the second half of the arity debt entry.
  - **`userlove` deliberately NOT renamed** — that ruling is still open. Only
    names that could not survive a merge changed.
- Debt entry "Project-handler wrapping" closed; its stale body folded into the
  resolution rather than left carrying line numbers the commit invalidated.
- Still open for the owner: the `userlove` rename, the bare-`*` raise, the two
  vacuous `#disputable` rows, and the smoke test.

## 2026-08-03 — owner asks if the web branch compensates for a real runtime

- Owner, while inspecting the diff: *"is there a chance that web branch
  describes a different assembly of love2d (or assembly for a different
  runtime — i.e. browser's JS engine, not node) where signature of error
  handling differs really, and browser's branch compensates for that?"*
- **Yes, and the mechanism is sharper than a differing error signature.**
  `xpcall(f, h, ...)` forwarding arguments to `f` is a LuaJIT / Lua 5.2
  extension. **PUC Lua 5.1 takes exactly two arguments and drops the rest**,
  so `f` runs with nil for every parameter. `pcall(f, ...)` forwards on both.
  Measured in this container: LuaJIT → `1, 2`; 5.1 semantics → `nil, nil`.
  `_G.web` comes from `OS.get_name() == 'Web'` (`main.lua:182`), a platform
  check — consistent with a different interpreter, which is what love.js is.
- **This retroactively made the conservative call the correct one.** I carried
  the web branch through the collapse because the owner had not ruled it
  obsolete, not because I knew it was load-bearing. It is. A comment saying
  so now sits on the branch itself — the thing a future cleanup reads before
  deleting it.
- **And it reframes what `f1dc6aee` actually did.** Pre-feature there was
  exactly ONE `xpcall` in `controller.lua`, inside `wrap`'s guarded branch.
  `56c4284f` (the dispatch chain) added a **second, bare** one in
  `chain_native`, so on the Web build every adopted project keyboard handler
  would have been invoked with nil for key, held keys and isrepeat. The
  collapse removed it; the count is back to one. **A feature-era Web
  regression, repaired as a side effect of a refactor aimed at something
  else** — and one this feature introduced, which no check could see.
- **`39a34762`** — the rationale in code plus two ledger updates: a new entry
  for the absent Web coverage (with the regression as its worked example and
  a cheap guard named: forbid bare `xpcall`-with-arguments in `src/`, a grep
  would have caught it), and the arity entry updated since its second half
  was fixed by the collapse.
- Behavioural note: this is the second time this session the owner has found a
  real defect by asking whether a thing I described as redundant might exist
  for a reason. The first was the console-route gate.

## 2026-08-03 — the error boundary belongs above the chain; three findings

- Probed the chain's error protection at the owner's prompting
  (*"maybe we do need to wrap dispatch function instead?"*). **Only one of
  three tiers is protected**, and it is the legacy one:
  | tier | raise |
  |---|---|
  | `shortcuts[event][combo]` | escapes the chain entirely, no suspend |
  | `hooks[event]` assigned directly — the DOCUMENTED API | escapes entirely |
  | `hooks[event]` seeded from the project's own `love.*` | suspends |
  `dispatch` (`projectInputController.lua:90`) contains no pcall/xpcall at
  all; it inherits whatever its participants happen to carry.
- **And the protected tier behaves wrongly anyway:** measured a raising hook
  with a shown widget — `suspend_run` fires, the wrapper returns nil, the walk
  CONTINUES, and the widget received the character (`[z]`). A crashed
  project's overlay processed the event that crashed it.
- **Owner corrected a question of mine, rightly.** I asked whether a raise
  should report consumed or not. *"On a raise, interception happens above the
  level where decision 'was it consumed' is taken. The code raises before
  consumption result is analyzed."* Correct — with the boundary at the
  invocation site the error unwinds past the whole chain, no verdict is ever
  produced, and `love.*` ignores returns anyway. My question presupposed the
  wrapper sitting *inside* the walk, which is the shape we are removing.
- **Their follow-up assumption checked, and it has a hole.** "Project is
  suspended and put into inspect mode" holds for `'running'` only:
  `suspend_run` (`consoleController.lua:1201`) early-returns unless
  app_state is exactly `'running'`. Measured — a raise while `'project_open'`
  (the retained-route pen-and-paper state, ruling (a)) leaves app_state
  `'project_open'`: it prints and the project carries on. Pre-existing, not
  introduced by any redesign here.
- **Owner's architectural read:** the pointer/keyboard split was justified by
  dispatch shape and lifecycle, but the thing actually duplicated across it is
  **canvas + error wrapping** — *"so maybe its time to send all events to pic?
  with a single point of canvas/error wrapping (like it likely was
  pre-feature)"*. Pre-feature confirmed: one `CC:wrap_handler(new, wrap)` for
  every event in `hook_if_differs`.
- Two readings, and they must be separated: unifying the **boundary** is cheap
  and touches no ratified decision; routing pointer **through the chain**
  collides with Decision 11 (pointer stays hooked in `project_open` while
  keyboard disconnects — "the asymmetry is intentional and load-bearing")
  and with ruling 9 (pointer is a broadcast; the mirror consume-chain is
  deferred, not pre-PR).
- **Decision 10 supports unwrapping the seeded handlers**, checked rather than
  assumed: it ratifies *seeding* semantics only, and its stated intent is that
  project handlers are "ordinary chain participants". Wrapping seeded ones
  while direct ones go raw is what makes them un-ordinary — the asymmetry
  found above. The code comment's "pure wrap" is the decision's historical
  name, and the decision says its substance changed.

## 2026-08-03 — Decision 11's asymmetry is feature-invented; owner rules to unify

- Archaeology, decisive. Pre-feature `set_default_handlers` is called from
  exactly **two** sites — `suspend()` and `stop_project_run()` — and
  `run_project`'s success branch at `project_open` releases **nothing**. So
  before this feature keyboard and pointer both stayed installed until suspend
  or stop: **there was no lifecycle asymmetry at all.**
  `release_keyboard_route` arrived with `386cfe1d` (this feature), keyboard
  only. Decision 11's "**Why:** this is the established platform behaviour"
  does not survive contact with `3256aac` on that point.
- Its stated rationale is circular: pen-and-paper projects stayed interactive
  pre-feature *because nothing was released*. The feature added a release that
  would have broken them, then exempted pointer to protect them.
- **And the asymmetry is now vacuous.** Since ruling (a), release fires only
  when `not user_is_blocking()` and `not user_is_interactive()` — and
  `user_is_interactive()` is `love.state.user_input ~= nil or user_pointer`.
  So at the only moment the release runs, the project has **no pointer
  handlers to exempt**. The row pinning it
  (`project_open_liveness_spec.lua`, "pointer stays hooked…") calls
  `release_keyboard_route` directly, bypassing that condition — it pins the
  mechanism, not a reachable state.
- **Owner's ruling:** *"if (b) was invented inside this feature its not a
  dogma set-in-stone… so I'd decide to unify completely."* Reasoning recorded
  because it generalises: no contract was formalized pre-feature (all
  contracts here were de-facto behaviour canonicalized), so if no current code
  notices, nothing is violated; and **not adding complexity to the pre-feature
  engine is itself the good outcome**. My counter-arguments (no pointer hooks
  table, no shortcuts tier, no trigger concept) are all **self-inflicted**
  feature-era limits, which is not an argument for keeping them.
- Measured in support: **no example pointer handler returns a value** (`life`,
  `sapper`, `tixy`, `paint`, `pong` — pong's is a bare early `return`), and
  the return is discarded today anyway. So the consume contract costs nothing
  now. The one real delivery change is **order**: today `handlers.mousepressed`
  runs the widget FIRST then the slot occupant; the chain puts the widget
  LAST. Both still fire either way.
- Owner's combo proposal needs **no grammar change**: the trigger token is
  just a string, so a button name serialises through the existing
  `combo_string` unchanged (`ctrl` + a click trigger). Payload = the event's
  own arguments plus `keys_pressed` and `isrepeat`, matching the keyboard
  channels.

### `compy.singleclick` — the owner's concern, answered

- **It predates the PR base; this feature never touched it.** At `3256aac`
  the synthesis block in `set_love_update` and `get_compy_handler` are
  **byte-identical** to today, already reading `compy.singleclick` rather
  than `love.singleclick`. So the remount the owner remembers happened
  *before* the feature, and is not ours to answer for.
- **The fossil that proves the `love.*` past:** `Controller._defaults`
  carries `singleclick`/`doubleclick` stubs, and **nothing reads them** —
  both `_defaults[key]` sites iterate `_supported` (+ `draw`), which excludes
  the clicks. Dead vestige from when they were real `love.*` events.
- Demoting them to hooks fits the unification and would remove two bespoke
  top-level `compy.*` members — but it is a **public API change** needing a
  decision, a guide entry and a migration line, unlike the rest of the
  unification which is internal.

## 2026-08-03 — owner asks whether the half-teardown is deliberate. It is not.

- Owner: *"i wonder, is it by purpose? maybe there's a need to keep
  interactivity/inspectability?"* — checked for evidence of intent rather
  than inferring, and the answer is settled by a **ratified decision**, not
  by my judgment.
- **Decision 11 carries a teardown invariant** (`decisions/input.md`,
  "Consequence — a teardown invariant"): *"No callback, combo entry, or
  widget configuration survives the project that installed it… a
  disconnected route's participants receive nothing, and **a widget whose
  owning route is inactive goes unhonoured**."* The top-level-raise path
  violates all three clauses: callbacks and combo entries survive (no
  `clear_user_handlers` → no `reset_compy_input`/`reset_widget_outputs`),
  the widget configuration survives, and the widget whose route is inactive
  is not merely honoured — via the gate it is the ONLY thing honoured.
- **History says partial fix, not design.** `release_keyboard_route` on that
  branch was added by THIS feature, `386cfe1d` ("route connection lifecycle,
  before_exit (M5c chunk 4)"), whose own message reads *"Restore keyboard/
  text slots at the running boundary, **extend stop teardown** to reset
  compy.input participants"* — the commit did both jobs but applied the
  teardown half only to the stop path. At `3256aac` the raise branch had
  **neither**: no release, no hide, so the dead project's own handler stayed
  in the slot. The feature improved the path and stopped halfway.
- **If inspectability were the goal the design already has its answer**, and
  it is not this: Decision 12 (`inspect`) keeps the widget *drawn* but
  unhonoured for input, and Decision 11 names it "the model case" of an
  unhonoured widget. The raise path uses neither that gate nor the hide.
- **Reproducible user-visible consequence, and the strongest evidence of
  oversight:** `show()` is a no-op while `self.shown`
  (`userInputController.lua:301-307`, Decision 3 — it logs a warning and
  returns). So re-running the failed project leaves the surviving widget in
  place and the new `show{}` is swallowed. That is verbatim the failure
  `hide_overlay`'s own comment was written to prevent
  (`consoleController.lua:1255-1259`, "a stopped project's overlay silently
  swallowing the next project's") — the helper exists, and is applied on one
  path only.
- Verdict reported to the owner: not deliberate; a ratified invariant with
  one path left unconverted. Ruling still theirs.

## 2026-08-03 — steps 5-7 landed; sub-agent used once, verified

- Owner ruled the full unification and asked for the plan recorded then
  executed. Plan: `validation/reviews/S26-pointer-unification-plan.md`.
- **`b1885568`** — clicks become ordinary events. The timer synthesises and
  then EMITS `love.handlers.singleclick(x, y)`; `compy.singleclick` /
  `.doubleclick` are gone, and with them `get_compy_handler`, the dead
  `_defaults` click stubs and the fixture's `set_compy_handler`. paint and
  sapper migrated in the SAME commit so no commit leaves an example broken.
  Two examples, not the three the owner recalled — `life`, `tixy` and `pong`
  use raw `love.mouse*`.
- **`1c05f358`** — the bare `*` raise, the last ruled-but-unimplemented item.
  Two rows: the raise, and a control that `shift+*` is still accepted —
  without it the check could pass by rejecting classes generally, which a
  bare `has_error` cannot see.
- **`8d6f289d`** — Decision 25 written, Decision 11 amended with its evidence,
  two debt entries closed, `doc/input_api.md` given "Pointer and click hooks"
  plus migration rows.
- **`0ec50309`** — internals docs + `types.lua`, delegated to a **Sonnet**
  sub-agent (explicit model), prompt and outcome on disk per hygiene (c).
  Scope respected exactly: five files, nothing staged, nothing committed. Its
  biggest catch was one I had not flagged for it — the
  `running → project_open` paragraph in `internals/user_input.md` described
  the retired lifecycle in detail.
- **Verifying the agent's work found a defect of MINE**, which is the argument
  for verifying rather than trusting: `ConsoleController:wrap_handler` had
  been dead since `b1885568` (its last callers were the click lookups), while
  one commit earlier I had written that it "survives for the compy click
  handlers". Removed in **`624bdd77`**; the debt entry corrected rather than
  deleted. Two things corrected in the agent's own output as well: a swept
  passage still routed pointer handlers through `wrap_handler`, and
  `configure`'s type reused the show config verbatim though it rejects
  `force`.
- Agent reported `lua-lsp` unreachable for its whole run (broken pipe on every
  diagnostics call) — the same failure session25 saw. Its claims were
  cross-checked against source reads instead.
- Owner's account of the failure mode recorded verbatim at their request:
  `validation/notes/S26-owner-on-the-failure-mode.md` (`ee8fc4f2`).
- Suite **922 / 0 / 0 / 3**. Nothing pushed anywhere. Next: the owner's smoke
  test.
