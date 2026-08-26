# ARC-01 — cold second opinion on per-project-run widget lifetime

**Method note.** This was written without reading anything under
`doc/development/wip/77-new-input-api/` other than this output path — no
proposal text, no prior session reasoning. Everything below is derived from
`src/`, `tests/`, `doc/development/decisions/input.md`,
`doc/development/internals/user_input.md`, `doc/input_api.md`, and two
`git show`s of the two cited fix commits. `lua-lsp` was down; all
call-site claims are grep-over-`src/`-and-`tests/` plus a full read of
every hit, not LSP references.

## Verdict

**Sound, but not now** — the idea is architecturally coherent and could be
made to work, but it costs materially more than framed, its riskiest wiring
point is undiscussed, and the smaller alternative (a single `reset_config`)
already fully closes the reported defect class without touching a ratified
decision.

## The strongest case against, stated first

1. **It doesn't fix anything the smaller alternative doesn't already fix.**
   The actual defect — a hand-maintained wipe list
   (`reset_widget_outputs`, `src/controller/controller.lua:348-358`) that
   can drift out of step with `apply_config`
   (`src/controller/userInputController.lua:253-269`) — is fully closed by
   giving `apply_config` a symmetric `reset_config` and calling *that*
   instead of hand-listing fields. The widget-lifetime change solves a
   different, aesthetic problem ("this store shouldn't need wiping at all")
   that nobody asked for, in a phase explicitly scoped to not add moving
   parts beyond "simpler and more robust."
2. **It reopens a heavily-worded, ratified decision** — Decision 3
   (`doc/development/decisions/input.md:166-184`) — during a stress-test
   phase, on a branch already 86+ commits behind upstream. Even a
   defensible reading of Decision 3 is a negotiation cost this phase
   wasn't budgeted for.
3. **The "one coupling" framing undersells the real fix.** Making
   `get_compy_input()` resolve the widget dynamically is not a two-line
   patch (see Q3). It also does not address a construction-ordering hazard
   that exists independently of the "dynamic resolution" idea (see "What
   the proposal missed," item 1) — the closure that captures the widget
   runs once, at application boot, provably before any project has ever
   run.
4. **Choosing the wrong lifecycle seam silently reproduces the bug being
   fixed.** `restart()` and the Ctrl+T quickswitch path stop and re-run a
   project **without** calling `open_project`/`close_project` (evidence in
   Q4). Construct-at-open would leave every restart of an already-open
   project sharing one stale widget — the exact defect shape of
   `bd2a5d49`/`8a9022ec`, relocated rather than removed.
5. **The test cost lands up front, its coverage lands late.** 101
   `F.widget` touchpoints in `tests/` (verified by count, see Sizing) sit
   downstream of a fixture that only exercises `CC:run_project(...)` in 4
   places across 2 files. Most of the churn wouldn't exercise the new
   reconstruct/destroy cycle at all unless deliberately added to.

None of this makes the idea wrong in principle. It makes it *not now, not
at this size*.

## Q1 — Is the Decision 3 reading sound?

**Defensible on the stated mechanism, risky on the stated text.** Decision
3's "Why" clause names one specific failure mode: allocating a fresh object
graph **per input session** on a memory-constrained device, where the
"common pattern is repeated prompting" (`decisions/input.md:173-177`). "An
already-active session" (line 183) is the show()/hide() unit — the loop a
project runs when it prompts repeatedly. A per-project-run boundary reuses
the *same* instance across every session inside a run, so it satisfies the
literal hot-loop concern: no allocation on the prompting cadence, only on
the human-timescale cadence of starting/restarting a project.

But the decision's **Decision** clause and its **Consequence** clause read
narrower than that: "created once **at load**" and "**Four** instances
exist... never one further" (lines 168-169, 179-184), enumerated by name
(project/`main.lua`, console, editor input, editor search). That text
reads as an exhaustive, closed set fixed at boot, not "one per coarser
unit, wherever that unit is." A stakeholder who wrote "at load" literally
will read a per-run rebuild as reaching past what was ratified, not as
honoring it at a wider grain — especially since the second stated reason
("hide and bring back with state intact... the state was never destroyed,"
line 175-176) was written against a world where "state" spans the whole
app lifetime, and the proposal silently narrows that guarantee to "within
one run" without saying so.

**Verdict on this sub-question: the reading is *arguable*, not *obviously
honest***. It should go back to whoever owns Decision 3 as an explicit
amendment proposal, not be treated as already covered by the existing text.

## Q2 — Is per-run construction actually simpler?

**No — it trades a small, visible cost (a hand-kept wipe list) for a
larger, less visible one.** Concretely, what has to change beyond deleting
`reset_widget_outputs`:

- **A construction site has to move.** Today the M/V/C triple is built
  once in `love.load()` (`src/main.lua:370-379`), with an explicit,
  documented reason for doing it *before* `ConsoleController` is
  constructed: "so the project env's compy.input (built during
  ConsoleController construction) can bind to the widget's OWN callbacks
  table at that moment" (`main.lua:362-369`). Moving construction to
  `run_project`/`stop_project_run` (`consoleController.lua`) means CC needs
  a way to build a fresh `UserInputModel`/`UserInputController`/
  `UserInputView` triple itself — `baseconf`/`viewconf`/`InputEvalText`
  currently exist only as `main.lua` locals; CC would need them threaded in
  (via `self.cfg`, which does carry `cfg.view`, or a new field/factory).
  Not large, but new surface, not a deletion.
- **`get_compy_input()`'s closure has to be rewritten, not just its
  contents refreshed** (see Q3) — this is real code in
  `consoleController.lua`, the file the sizing claim treats as the
  smallest-touch one.
- **A boot-vs-first-run ordering hazard has to be solved** (see "What the
  proposal missed," item 1) — currently unaddressed in the framing I was
  given.
- **The consumers that already resolve the widget dynamically stay
  fine and don't need touching** — this cuts the other way, and is worth
  crediting: `ProjectInputController:_dispatch`
  (`projectInputController.lua:155-159`) re-reads
  `love.state.user_input_controller` on every event, and
  `build_widget_api`'s `get_widget`/`get_active` closures
  (`consoleController.lua:808-814`) already do the same. Most of the
  widget-access surface is already reconstruction-safe today; only the
  callbacks/pending capture is not.

Net: real simplification in one place (the wipe list), real new complexity
in at least two others (construction wiring, closure rewrite) plus one
unresolved hazard. Not a wash in the *good* direction.

## Q3 — Is dynamic resolution of `callbacks`/`pending` sound, and what does it cost?

**The coupling is correctly identified but the fix is bigger than "resolve
dynamically" suggests, and it doesn't reach the deepest version of the
problem.**

`get_compy_input()` (`consoleController.lua:775-817`) captures
`widget.callbacks` and `widget.pending` **by value, once**, into a `state`
table (lines 790-805: `callbacks = widget.callbacks`, `pending =
widget.pending`), and `build_input_surface`
(`consoleController.lua:512-527`) captures `state.callbacks` again, by
value, into its own `resolve` table (line 521: `callbacks =
state.callbacks`). Every subsequent read of `compy.input.callbacks` goes
through `build_frozen_view`'s `__index`
(`consoleController.lua:443-447`), which is re-invoked on every access —
but it returns `resolve.callbacks`, a plain table reference frozen at
construction, not a re-derived one. Four functions read/write through
`state.callbacks`/`state.pending` directly as tables, not as resolvers:
`merge_callback_keys` (line 617-622), `consume_pending` (line 632-637),
`stash_hidden_configure` (line 648-653), and `api_show` (line 661-668,
via `state.pending`). Making this dynamic means turning all of these from
"read/write a captured table" into "read/write through a resolver called
at each access" — a shape change to five functions, not a one-line swap of
a captured value for a captured function.

**Whether the identity ruling survives:** yes, *if done correctly*. The
owner ruling — `compy.input.callbacks` **is** the widget's own
`self.callbacks` table, not a copy (`userInputController.lua:38-40`,
restated at `internals/user_input.md:684-687`) — is preserved by dynamic
resolution as long as every read (both the config-table sugar path via
`show{on_text_entered=...}` and the direct `compy.input.callbacks.X = fn`
path) resolves through the *same* live getter at the moment of access,
during a run where the widget instance doesn't change mid-run (it
doesn't, under the proposal — reconstruction only happens at run
boundaries). This is achievable, but it is exactly the kind of "every call
site has to agree" invariant that's easy to get subtly wrong across five
functions, and there is no existing test that exercises **two** widget
generations against the **same** `compy_namespace` instance to catch a
regression here (see Q6 / Sizing).

## Q4 — Which seam: project *open* or project *run*?

**Must be run/stop (`ConsoleController:run_project` /
`ConsoleController:stop_project_run`), not open/close
(`ConsoleController:open_project` / `ConsoleController:close_project`) —
and this isn't a style preference, open-seam construction is provably
wrong.**

- `ConsoleController:restart()` (`consoleController.lua:1179-1182`) is
  exactly `self:stop_project_run(); self:run_project()` — it never touches
  `open_project`/`close_project`.
- `run_project(name)` itself only calls `open_project` when there is no
  current project or a *different* name is requested
  (`consoleController.lua:277-283`); re-running the same open project
  skips it.
- `controller.lua`'s `reserved_quickswitch` (lines 793-808, Ctrl+T) also
  calls `stop_project_run()` then either `edit()`/`run_project()` directly,
  bypassing open/close.

If widget construction were tied to `open_project`, every one of these
paths — restart, quickswitch back into a run — would keep serving the
**same** widget instance across multiple runs of the same project,
reproducing precisely the "state that should have died with the project
didn't" defect shape from `bd2a5d49`/`8a9022ec`, just moved one level up.
`stop_project_run` (`consoleController.lua:1336-1348`) is also where
teardown already lives today (`hide_input_widget`,
`clear_user_handlers` → `reset_compy_input` + `reset_widget_outputs`), so
pairing construction with `run_project` keeps construct/destroy
symmetric with the code that already exists at that boundary.

## Q5 — What breaks that the proposal (as framed to me) hasn't mentioned?

1. **A construction-ordering hazard, not just a stale-reference one.**
   `get_compy_input()` runs exactly once, inside `prepare_project_env`
   (`consoleController.lua:1005-1114`), which `ConsoleController.new`
   calls a single time at construction (`consoleController.lua:79-80`).
   `ConsoleController` itself is constructed once, at application boot
   (`main.lua:383`) — **before any project has ever run**. Today this
   works only because `main.lua` deliberately provisions the widget
   *before* CC, with the ordering comment saying so explicitly
   (`main.lua:362-369`, "provisioned FIRST — before the console — so the
   project env's compy.input... can bind to the widget's OWN callbacks
   table at that moment"). If widget construction moves to
   `run_project()`, then at CC-construction time (still at boot, still
   before the first run) `love.state.user_input_controller` is `nil`, and
   the eager dereference in `get_compy_input()`
   (`local widget = love.state.user_input_controller; ...  callbacks =
   widget.callbacks`) indexes `nil` and raises immediately, every boot.
   This isn't fixed by making `callbacks`/`pending` resolve dynamically at
   read time — the crash is at **construction** time, before any read
   happens. Confirmed independently in
   `doc/development/internals/user_input.md:710-716`: "`compy.input` is a
   table created **once for the application**, not once per project... it
   is built inside `prepare_project_env`, which `ConsoleController.new`
   calls a single time at construction." Solving this requires either
   keeping a placeholder widget alive at boot (partially reintroducing
   the singleton the proposal wants to remove) or making the whole
   surface tolerate a genuinely absent widget through the first
   `run_project()` — a real design decision, not a detail.
2. **`UserInputView:draw()`'s identity-based redraw skip.**
   `src/view/input/userInputView.lua:294`: `if self.controller ~=
   love.state.user_input_controller then self.controller:update_view() end`
   — the comment above it (lines 285-292) says the **boot-provisioned**
   instance is "the one view that skips this continuous per-frame
   `update_view()`," an explicit perf/memory optimization. This keeps
   working correctly under reconstruction only if every reconstruction
   updates `love.state.user_input_controller` and rebuilds the matching
   view in lockstep — plausible, but nothing in the framing given to me
   says this was checked, and it's exactly the kind of thing that silently
   degrades (view redraws every frame again, or compares against a stale
   pointer) rather than erroring.
3. **Console and editor widgets are unaffected — worth confirming
   explicitly, not assuming.** The console's own widget is a *separate*
   `UserInputController` built once in `ConsoleController.new`
   (`consoleController.lua:44`, `local IC =
   UserInputController(M.input):always_shown()`), never assigned to
   `love.state.user_input_controller`. Per Decision 3's Consequence clause
   (`decisions/input.md:179-184`), only the project's instance is in
   scope. Confirmed no code path in `editorController.lua` or
   `consoleController.lua`'s console wiring reads
   `love.state.user_input_controller` for its own widget. Not broken, but
   worth stating as verified rather than assumed.
4. **The test fixture already contains a second, unrelated widget-swap
   pattern that any fixture rewrite must not collide with.**
   `tests/helpers/input_fixture.lua`'s `F.show_selectable_widget`
   (lines 250-264) directly swaps `love.state.user_input_controller` to a
   test-local widget for selection tests, and `F.reset` (lines 270-296)
   explicitly restores it (`love.state.user_input_controller = widget`,
   line 274) before calling `CC:stop_project_run()`. This is independent
   evidence that the codebase already treats
   `love.state.user_input_controller` as swappable in tests — a useful
   precedent for how the reconstruction path could be tested, but also a
   second seam a fixture rewrite has to reconcile, not just the `build_widget`
   call in `F.setup`.

## Q6 / Sizing check

**Test number confirmed exactly; production number plausible but likely
optimistic once the ordering hazard is priced in.**

- `grep -c "F\.widget" tests` → **101**, matching the claim precisely.
- Only **4** call sites across **2** files in `tests/` invoke
  `CC:run_project(...)` at all (`grep -rn run_project tests`) — meaning
  the overwhelming majority of the 101 `F.widget` touchpoints exercise
  code paths (`F.show_widget`, `F.activate_project`, direct widget calls)
  that don't go through the real `run_project()`/`stop_project_run()`
  lifecycle today. `F.activate_project`
  (`tests/helpers/input_fixture.lua:238-242`) sets `app_state` and calls
  `Controller.set_user_handlers` directly — it does **not** call
  `run_project`. If the new construct/destroy logic lives inside
  `run_project`, most of the existing 101 touchpoints would need updating
  for API-shape consistency (`F.widget` becoming a function, or a
  metatable-backed proxy) without actually exercising the new lifecycle
  path — meaning the 101-count churn is real, but the *coverage* of the
  new behavior it's supposedly validating is not, unless new cases are
  deliberately added. "Concentrated at one fixture seam" is right in that
  all touches funnel through `input_fixture.lua`, but the fix likely also
  touches `F.reset` and `F.show_selectable_widget`, not only `F.setup`'s
  `build_widget`.
- Production "~5 files, net deletion" is plausible in file *count*
  (`main.lua`, `consoleController.lua`, `controller.lua`,
  `userInputController.lua`, possibly `projectInputController.lua` for
  awareness even though `_dispatch` needs no change) but I'd push back on
  "net deletion": `controller.lua` loses `reset_widget_outputs` (~10
  lines, real win) and `userInputController.lua`'s `reset_callbacks`/
  `clear_pending` (`userInputController.lua:480-494`) could shrink or go,
  but `consoleController.lua`'s `get_compy_input`/`build_input_surface`
  rewrite (Q3) is very likely a **net addition** there once the resolver
  plumbing and the boot-ordering fix are written, and `main.lua` gains
  wiring it doesn't have today (passing config/evaluator through to a
  CC-owned construction point). I'd expect this to land closer to a wash
  than a net deletion in production code, before counting the
  `doc/development/decisions/input.md` amendment this needs — which is a
  real cost the "5 files" framing doesn't count at all, since it isn't
  code.

## What I could not verify

- I do not have the actual proposal text (by design — the boundary
  excluded `doc/development/wip/77-new-input-api/`), so I can't confirm
  whether it already has an answer for the boot-ordering hazard (Q5.1) or
  the open-vs-run seam choice (Q4) that simply wasn't included in the
  summary handed to me. Everything above is assessed against what the
  current code and ratified decisions actually say, not against an
  unseen counter-argument.
- I did not attempt an implementation spike, so I can't rule out further
  snags inside `model/input/userInputModel.lua` (not read in full) that a
  fresh-per-run model might hit — e.g., history state, evaluator
  attachment order — beyond what `apply_config`/`reset_callbacks`/
  `clear_pending` already show.
- I verified the 101/4 counts by grep and by reading every matching file
  in `tests/helpers/`, but did not read all 101 individual call sites'
  surrounding test bodies — only the fixture that defines the shape they
  share.
- Baseline suite confirmed as described: `busted tests` → `970 successes /
  0 failures / 0 errors / 10 pending`, matching the prompt's stated
  baseline exactly; I made no code changes, so this remains the state I
  found, not something I altered.
