# R4/U2 — compy.input surface rename sweep in TEST files (Sonnet worker prompt of record)

**Model:** sonnet (explicit). **Phase:** #77 input-API redesign, Phase R4, unit U2.
**Nature:** mechanical rename sweep in test files ONLY, verified by the busted suite.

## Standing hygiene (you do NOT inherit repo CLAUDE.md — stated explicitly)
- **lua-lsp MCP server is available** (`mcp__lua-lsp__definition`/`references`/`hover`/
  `diagnostics`). This task is string-level renames in test files; grep is your main tool,
  but if you edit any `.lua` and then want diagnostics, `sleep 1` first (the server
  re-indexes). You do not need to edit any `src/` file — if you think you do, STOP and report.
- Run the suite with `busted tests` from `/repo`.

## Background (what already changed — do NOT re-do)
The `compy.input` project-facing surface has been reshaped (src/ already done + committed
core is in the working tree) from a flat surface into **three frozen sub-tables**:
`shortcuts`, `hooks`, `callbacks`. The container and each sub-table's identity are frozen
(assigning them raises loudly: `compy.input: '<k>' is not assignable`); leaves are writable.
The old flat field names on the surface are GONE. Test files that still use the old names
are now failing. **Your job: rename every genuine compy.input-surface field access in the
TEST files to the new shape, so the suite returns to green. Rename only — change no
behavior.**

## The rename mapping (apply ONLY to a compy.input surface object — see disambiguation)
| old (flat surface field) | new |
|---|---|
| `<surf>.handlers` | `<surf>.shortcuts` |
| `<surf>.on_key_pressed`  | `<surf>.hooks.keypressed` |
| `<surf>.on_text_input`   | `<surf>.hooks.textinput` |
| `<surf>.on_key_released` | `<surf>.hooks.keyreleased` |
| `<surf>.on_text_entered` | `<surf>.callbacks.on_text_entered` |
| `<surf>.on_limit_reached`| `<surf>.callbacks.on_limit_reached` |
| `<surf>.validator`       | `<surf>.callbacks.validator` |
| `<surf>.highlighter`     | `<surf>.callbacks.highlighter` |
| `<surf>.before_submit`   | `<surf>.callbacks.before_submit` |
| `<surf>.after_submit`    | `<surf>.callbacks.after_submit` |
| `<surf>.before_cancel`   | `<surf>.callbacks.before_cancel` |
| `<surf>.after_cancel`    | `<surf>.callbacks.after_cancel` |

A `<surf>` (surface object) is the value returned by `F.activate_project(...)` or
`F.compy_input()` (usually a local named `input`), or a literal `compy.input`.

## DISAMBIGUATION — what must NOT be renamed (critical; these are false friends)
1. **`love.handlers` / `session.handlers` / `F.session.handlers` / `h.handlers`** — the
   LÖVE gateway table, unrelated to compy.input. LEAVE untouched.
2. **Config-table keys inside `show{...}` / `configure{...}` / `F.show_widget{...}`** — the
   show/configure config protocol stays FLAT. e.g.
   `F.show_widget({ on_text_entered = fn, validator = fn, highlighter = fn })` is UNCHANGED.
   Only *direct field assignments/reads on the surface object* rename (`input.validator = fn`
   → `input.callbacks.validator = fn`), not keys inside a `{ ... }` passed to show/configure.
3. **UserInputController INSTANCE fields** — `F.singleton.validator`,
   `F.singleton.on_text_entered`, `F.singleton.on_limit_reached`, `singleton.*`, `w.on_*`,
   etc., are on a `UserInputController` object (the widget), NOT the surface. LEAVE flat.
4. **The `natives` argument to `F.activate_project({ keypressed = fn, mousepressed = fn })`**
   — that table's keys are love event names (a userlove table), NOT surface fields. LEAVE.

If you are unsure whether a given occurrence is a surface access or a false friend, decide by
what the base identifier holds (a surface from F.activate_project/F.compy_input/compy.input →
rename; anything else → leave), and note the ambiguous one in your report.

## Candidate files (the suite is the authority; sweep every genuine surface access)
Currently RED: `tests/input/input_events_spec.lua`, `input_widgets_callbacks_spec.lua`,
`input_reconfigure_spec.lua`, `input_route_lifecycle_spec.lua`, `input_routing_spec.lua`.
Also check for surface accesses (many occurrences there are `love.handlers`/config-keys — 
leave those): `keys_pressed_spec.lua`, `input_shortcuts_click_spec.lua`,
`input_widget_lifecycle_spec.lua`, `input_nfr_forward_spec.lua`.
Do NOT touch: `tests/helpers/input_fixture.lua` (already migrated), `tests/helpers/
input_session.lua`, `tests/mock.lua`, `tests/interpreter/*` (all `love.handlers`), any
`src/` file, and any `src/examples/*` (examples are a separate later step).

## HARD RULES
- **Rename only.** Do NOT change any assertion, any control flow, any test description/name,
  or any show()/configure() config-table key. Behavior is 100% preserved this unit.
- The frozen guard makes a wrong surface write **raise loudly** — so mistakes surface as
  errors, not silent passes. Use that.
- **If, after renaming correctly, any test still FAILS or ERRORS, STOP and report it — do NOT
  edit the assertion to make it pass.** A residual failure means either a rename is wrong or
  there is a real regression; either way it is mine to judge, not yours to paper over.
- Target: `busted tests` → **819 successes / 0 failures / 0 errors / 4 pending** (baseline
  815 + 4 new AC tests already added in `tests/input/input_redesign_ac_spec.lua`, which you
  must NOT modify).

## Deliverable
1. The renamed test files (working tree).
2. A short report written to
   `doc/development/wip/77-new-input-api/validation/outcomes/R4-U2-rename-sweep.md`:
   files touched, occurrence counts renamed vs left-as-false-friend (with a line or two on
   any ambiguous call you resolved), and the final `busted tests` tally. Return a 3-5 line
   summary.
