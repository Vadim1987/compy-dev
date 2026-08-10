# S35 — build the missing suite for the framework's own (global / platform) shortcuts

**Model: Sonnet (passed explicitly).** You are a sub-agent of the compy `/repo` session. You do
**not** inherit the parent's context or the repo's CLAUDE.md; this file is your whole briefing.
Working directory `/repo`. Run tests with `busted tests` (uses a mock LÖVE — no display needed).

## The subject

compy is a LÖVE2D framework. `src/controller/controller.lua`'s `setup_callback_handlers` installs
the **gateway** — `love.handlers.keypressed` / `keyreleased` — which is the single entry point for
every keyboard event. Before an event is forwarded to whatever route is active (console, editor,
or a running project), the gateway runs a set of **framework-owned shortcuts**: quickswitch,
restart, quit, stop, reset, profiler, and so on. The corpus calls these **global shortcuts**
(`doc/development/internals/user_input.md`, "Dispatch chain"; `doc/development/tests.md`).

They are gated on a **device poll** — `Key.ctrl()`, `Key.alt()`, `Key.shift()`, which read
`love.keyboard.isDown` — not on any event-tracked state.

**The gap you are filling:** almost none of them is tested, and nothing anywhere asserts that a
project cannot take one of these combos for itself.

## What is already tested — DO NOT duplicate, DO NOT move, DO NOT rewrite

- `tests/input/input_shortcuts_click_spec.lua`, group *"global shortcuts do not consume the key
  (#disputable)"* — two cases: `C-pause` fires suspend and the key still reaches the route; and
  `#play` mode narrows the set (restart fires, quit does not).
- `tests/input/project_open_liveness_spec.lua` — two `Ctrl+Esc` cases.

**These four cases are off limits.** Two of them are known to be order-dependent under `--shuffle`
and are owned by a separate, already-planned work item. Your work is **purely additive, in a new
file**. Do not edit any existing test file, and do not touch anything under `src/`.

## The enumeration — verify every line of it against the code before you use it

This list was read off `src/controller/controller.lua` by the parent session. **Treat it as a
strong hint, not as truth: check each entry against the code yourself, and report any
disagreement** (a missing entry, a wrong condition, an entry that does not exist). A disagreement
is a valuable finding, not a nuisance.

**`handlers.keypressed`, dev mode (`cfg.mode ~= 'play'`), in this firing order:**

1. `restart()` — `Key.ctrl() and Key.alt() and k == 'r'` → `CC:restart()`
2. `quickswitch()` — `Key.ctrl() and not Key.alt() and k == 't'`, and then it **branches on
   `love.state.app_state`**: `running` / `inspect` / `project_open` → `stop_project_run()` then
   `edit(...)`; `editor` **and** the editor is in normal mode → `finish_edit()` then
   `run_project()`
3. `profile()` — **only when `love.PROFILE` is truthy**: `ctrl+alt+p` → `Prof.start_oneshot()`,
   `ctrl+alt+shift+p` → `Prof.stop_profiler()`; and **`k == 'f10'` with NO modifier at all** →
   cycles `love.PROFILE.fpsc`
4. `project_state_change()` — all under `Key.ctrl()`: `pause` → `suspend_run`; `q` →
   `quit_project`; `s` → `stop_project_run` when `app_state == 'running'`, or in `editor` state
   `finish_edit()` when shift is held else `close_buffer()`; and `Key.shift() and k == 'r'` →
   `CC:reset()`

**`handlers.keypressed`, play mode:** only `restart()` and `profile()` run (plus a `shutdown`
quit). Quickswitch and the project-state group do **not**.

**`handlers.keyreleased`:** `Key.ctrl() and k == 'escape'` → `love.event.quit()`. Note this one
fires on RELEASE.

## What to assert — three claims, and the third has a trap in it

Write **one case per reserved combo** for claim A, then the claim-B and claim-C cases. Prefer few,
sharp cases over many similar ones.

**A. The effect happens.** In dev mode, with the app in a state where the shortcut applies,
pressing the combo produces its observable effect. Assert the **outcome at a public seam**
(`love.state.app_state`, a controller method's observable result, `love.PROFILE.fpsc`), never a
spy on a method name where an outcome is available.

**B. A project cannot suppress it.** With a project active and a project shortcut registered on
**the same combo** (e.g. `input.shortcuts.keypressed['ctrl+t']`), the platform effect **still
happens**. This is the claim nothing in the suite makes today, and it is the reason this file
exists. Two or three representative combos are enough — this is a property of the gateway's
structure (it runs before forwarding), not of each individual binding.

**C. The framework does not consume the key — but do NOT assert a false symmetry.** The corpus
says a global shortcut fires its effect and the key still reaches the active route. That is true
of the *forwarding*, but several of these effects **tear the route down** (`stop_project_run`,
`quit_project`, quickswitch, restart): the project's own handler then legitimately never runs, and
that is the world changing, not suppression.

So: assert "the project's binding also ran" **only** for a combo whose effect leaves the route
alive, and for a route-destroying combo assert what actually happens and **say so in a comment**.
If you cannot determine which category a combo is in, put it in your report rather than guessing.

## How to drive the tests

- Use the shared fixture: `local F = require('tests.helpers.input_fixture')`, with
  `setup(F.setup)`, `teardown(F.teardown)`, `before_each(F.reset)` — copy the preamble of
  `tests/input/input_shortcuts_click_spec.lua`.
- **`F.session.press(k)` now holds the key down on the mock device as well as feeding the
  gateway** (a change that landed today), so `F.session.press('lctrl')` then `F.session.press('t')`
  gives you a real Ctrl+T as the gates see it. `mock.keystroke('C-t', F.session.press, false)` is
  the older combo driver and also works. `F.reset()` lifts all held keys between cases.
- `F.activate_project()` returns the project's `compy.input` table (with `.shortcuts` and
  `.hooks`) — that is how you register the competing project binding for claim B.
- **`love.PROFILE` is `false` in the fixture**, so the profiler shortcuts and `f10` are unreachable
  until a case sets it. Set it locally and restore it, the way the existing `#play` case
  saves/restores `love.handlers`.
- Some effects quit or tear down: `love.event.quit` is a no-op stub in the fixture. Check what the
  fixture provides before assuming an effect is observable.

## What this suite must NOT do

- **No bloat.** Do not write 105 cases for a rule that one case states. Claim B is a property of
  the gateway, not of each combo.
- **No implementation-detail assertions.** Not "this internal function was called" where an
  observable outcome exists.
- **No changes to production code.** If a test cannot be made to pass, that is a **finding to
  report**, not a licence to edit `src/`. Report it and leave the case out (or leave it as a
  `pending` with a comment saying why — but tell the parent, because the suite's pending count is
  tracked).
- **No new `INTERIM:` or `REMARK:` markers** — the project is clearing those before its PR.
- **Comments cite persistent docs** (`doc/...`), never `doc/development/wip/...`, and cite a
  **named section**, not a line number.

## Repo conventions you must follow

Read `agents/rules.md` (hard limits: line ≤ 64 chars, function body ≤ 14 lines, ≤ 4 params,
nesting ≤ 4; formatting and naming) and `agents/rules/commenting.md` (a comment must carry
information the code cannot; size discipline). Match the surrounding style of the existing input
specs — they are the model for structure, describe naming and comment density.

Tooling note: a **`lua-lsp` MCP server** is available (definitions / references / diagnostics /
hover over a real AST of the workspace). Use it to resolve symbols and check who calls what;
**grep is the completeness backstop** — this repo has a standing finding that LSP references miss
occurrences routed through metatable `__index` string-key dispatch. After editing a `.lua` file,
`sleep 1` before querying the LSP (it re-indexes).

## Deliverables

1. **The suite**: a new file `tests/input/input_global_shortcuts_spec.lua`, carrying the
   file-level `#input` tag like its siblings.
2. **`busted tests` green**, with the success/failure/pending counts stated in your report. The
   suite is at **940 successes / 0 failures / 0 errors / 3 pending** before your work; your report
   must reconcile the new number arithmetically (how many cases you added).
3. **A report** at
   `/repo/doc/development/wip/77-new-input-api/validation/outcomes/S35-global-shortcuts-suite.md`:
   what you added and why each case earns its place; **every disagreement with the enumeration
   above**; which combos you found route-destroying versus route-preserving; anything you could
   not test and why; and any behaviour you found that looks wrong but that you did **not** change.

**Do NOT run any `git` write command** — no `add`, no `commit`, no `push`, no `checkout`. Leave
your work in the working tree; the parent session reviews and commits it.
