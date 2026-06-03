# Feature #77 — Roadmap Summary

*One-page milestone table. Full milestone detail, file
lists, and estimates are in `roadmap.md`.*

---

## Milestones

| # | Name | Deliverable / Testable Output | Key files |
|---|---|---|---|
| M1 | `keys_pressed` table | Live modifier set maintained; `combo_string()` helper (modifier-first, generic l/r folding); no behaviour change | `controller.lua` |
| M2 | Singleton extraction | Widget created once at startup; `compy.input.show`/`compy.input.hide` on namespace; existing examples and tests pass; no per-session allocation; `oneshot` stays | `main.lua`, `consoleController.lua`, `userInputController.lua`, `compy_namespace.lua` |
| M3 | Legacy API facades | `input_text()` etc. rewired; `write_to_input` wired to `compy.input.set_text`; all existing examples work; deprecation warning in debug mode | `consoleController.lua` |
| M4 | ProjectController + gate removal | New controller owns project-running input; overlay gate removed; all four app modes verified | `controller.lua`, `projectController.lua` (new) |
| M5 | Three-level dispatch | `compy.input.handlers[combo]` (metatable-normalised) and `compy.input.on_key_pressed` work; return-value bubbling stops chain | `projectController.lua`, `compy_namespace.lua` |
| M6 | Before/after chains | Submit/cancel hooks fire; Escape dismisses overlay; `on_limit_reached` fires; `framework_handlers['return']` owns submit; `oneshot` deleted from `userInputModel.lua` | `projectController.lua`, `userInputController.lua`, `userInputModel.lua` |
| M7 | Extended singleton API | `compy.input.configure()`, `compy.input.clear()`, `compy.input.get_cursor()`, `compy.input.set_cursor()`, `compy.input.set_text()` work; live prompt/validator/cursor/text update works | `userInputController.lua`, `compy_namespace.lua` |

---

## Additional scope

| Block | Description |
|---|---|
| Documentation | Update `doc/development/internals/` and `overview.md`; archive stale wip notes |
| Test coverage | Busted tests for keys_pressed (combo format), singleton lifecycle, dispatch chain, legacy compat (incl. write_to_input), spec §7 edge cases |

---

## Estimates at a glance

*Three-point PERT = (O + 4M + P) / 6. Full per-milestone O/M/P
breakdown in `roadmap.md`.*

| | Without LLM | With LLM |
|---|---|---|
| PERT total | ≈ 59 h | ≈ 35 h |
| Main uncertainty | M4 integration (gate removal) — widest pessimistic tail | M2 and M4 (manual verification is fixed cost) |
