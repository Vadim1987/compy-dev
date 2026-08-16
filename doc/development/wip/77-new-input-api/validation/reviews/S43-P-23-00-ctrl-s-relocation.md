# P-23-00 — can Ctrl+S leave the pre-dispatch gate? Feasibility

Owner's proposal, 2026-08-16: Ctrl+S does not belong at the pre-dispatch level.
The stop-a-run meaning belongs to **ProjectInputController**, enforced *before*
the chain is walked; the editor's two meanings belong to **EditorController**,
which may later express them in shortcut syntax. Also: make both **exclusive**,
per the least-privilege ground of Decision 33.

**Verdict: yes, and it is small.** Two insertions and one deletion. No
rebuilding. The risks are real but nameable, and each has a test that settles it.

## Why it is small — the route is already guaranteed

The relocation only works if the right controller is guaranteed to own the
keyboard in the state that needs it. It is:

- `run_project` sets `app_state = 'running'`, runs the project's top-level code,
  and on success calls `set_user_handlers` → `set_handlers` → **`occupy_input`**
  (`controller.lua:236-250, 301-306`), which points `love.keypressed` at
  `ProjectInputController` **unconditionally** — not only when the project
  defined handlers.
- So for every state the gate's Ctrl+S acts on (`running`), **PIC owns the
  keyboard**. The failure path is the only exception and it releases the route
  *and* leaves `project_open` (`consoleController.lua:318-324`), a state the gate
  never acted on anyway.
- The window between `app_state = 'running'` and `occupy_input` is not
  observable: top-level project code runs to completion inside one `love.update`,
  so no event is polled during it.
- `editor` state is the console route, and `EditorController:keypressed` already
  owns Ctrl-gated branches of exactly this kind (`editorController.lua:817-823`,
  `ctrl+m` / `ctrl+f`). Two more are idiomatic there.

## The shape

**P-23-01 — the run-stop half.** `ProjectInputController` gains a
platform-reservation check ahead of the three-consumer walk. The natural seam is
`_dispatch` (`projectInputController.lua:173-178`) or the generated channel
method (`:188-194`): if the platform claims this event+trigger, run the platform
action, report consumed, and **do not walk the chain** — which is precisely
"enforced before chain invocation", and keeps the non-overridability P15 pinned:
a project binding `ctrl+s` still cannot take it.

Scope it to `app_state == 'running'`, exactly as the gate does today. **Do not**
extend it to `project_open`: a non-blocking project keeps the route there, and
Ctrl+S does nothing in that state today. Widening it would be a new behaviour
nobody asked for.

**P-23-02 — the editor half.** `EditorController:keypressed` takes `ctrl+s` →
close buffer and `ctrl+shift+s` → finish edit. The gate's `k == "s"` block
(`controller.lua:810-822`) is then deleted whole.

**Exclusivity, both halves.** `only_mods(true,false,false)` for `ctrl+s` and
`only_mods(true,false,true)` for `ctrl+shift+s`. This closes the wrinkle P-21
left: today the running branch does not test Shift at all, so Ctrl+Shift+S stops
a run as a side effect rather than by intent.

## Risks, each with the test that settles it

1. **Teardown from inside the route boundary.** Today `stop_project_run` is
   called from `handlers.keypressed`, *outside* `with_canvas_and_errors`. Moved
   into PIC it runs **inside** that wrapper, tearing down the very route the call
   is executing in. The wrapper holds `pic` as an upvalue and returns normally,
   so this should be safe — and mid-event teardown is already the norm
   (`quickswitch` does `stop_project_run` then `edit`). **Test:** press Ctrl+S
   during a run and assert the project stopped, the route released, and no
   handler from the dead project survives.
2. **A project that binds `ctrl+s` must still lose.** **Test:** register a
   project shortcut on `ctrl+s`, press it while running, assert the run stopped
   and the project's function did **not** fire.
3. **The editor's two meanings must not swap or leak into other states.**
   **Test:** the two existing cases from P-21-06 move to whatever layer now owns
   them, plus one asserting Ctrl+S in `ready`/`project_open` still does nothing.
4. **Coverage moves, it does not vanish.** The live cases added in P-21-02 and
   P-21-06 for row 4 currently drive the gate. They must be re-pointed, not
   deleted, and the suite arithmetic must reconcile in the commit message.

## What this does not touch

The other eight reservations stay in the gate. Nothing here reopens Decision 33 —
it *applies* its least-privilege ground one level further: a reservation that
only ever means something inside one route does not need the power of running
before every route.

**Cost to state in the PR:** this moves a framework behaviour between layers,
which a reviewer will notice. The justification is the same one Decision 33
carries, and the paragraph belongs beside it in
`../notes/S43-pr-lines-owed.md` when the step lands.
