---
description: PM verification pass over the Fable intent-alignment verdict's 8 "For the
  owner" rulings — each checked against the landed code, split confirmed-real vs
  claimed-inaccurate. Rulings are the OWNER's to make; this only establishes fact.
status: active
audience: owner
---
# Feature #77 — "For the owner" rulings, verified against code (Task 3)

_PM (Claude Opus 4.8) verification pass, 2026-07-13, over `reviews/intent-alignment-verdict.md`
§4 + "For the owner". Each item traced to source (grep + read of the landed tree at HEAD). These
are **owner design rulings** — this doc establishes the facts, it does not resolve them._

**Result: 7 of 8 confirmed exactly as Fable stated. The one correction is item 8's count (31, not
45). Item 8's doc-bug half is already FIXED (`input_api.md`, commit `8b9820d`).**

| # | Ruling needed | Verdict | Evidence |
|---|---------------|---------|----------|
| 1 | `compy.keys_pressed` — expose to projects, or amend contract to callback-arg-only | ✅ **CONFIRMED** | `get_compy_namespace` (consoleController.lua:552) returns `{terminal, audio, graphics, fonts, input}` + a `before_exit` slot — **no `keys_pressed`**. Framework-side `Controller.keys_pressed` (controller.lua:389) + the callback-arg proxy are the only held-key access. A project cannot poll held keys in `update()`. |
| 2 | `eval`/`result` config keys — bless as public API + record deviation, or realign onto `validator`/`highlighter` | ✅ **CONFIRMED** | `apply_config` accepts `cfg.eval` (userInputController.lua:212) and `cfg.result` (:223); examples `tixy`/`valid`/`guess` pass `eval =`. Neither key is in spec §3's config table (`validator` is). Unrecorded deviation. |
| 3 | Combo-tier key-repeat semantics — shipped unsettled | ✅ **CONFIRMED** | `projectInputController.lua` DEFERRED marker (above `:keypressed`): "whether the combo tiers (1-2) fire on key-repeat is unruled; isrepeat is threaded to tier 3 only, combos keep current behaviour." → **fire-on-every-repeat at tiers 1-2**; no `isr` gate in the combo dispatch. |
| 4 | `multiline` spec §3 flag — implement or strike | ✅ **CONFIRMED** unimplemented | No `multiline` config key anywhere in the input path; `userInputModel.lua:499` carries `-- TODO multiline`. (The `parser.lua`/metalua `multiline` hits are the unrelated Lua lexer.) Shift+Enter newline is unconditionally on. |
| 5 | Silent config-key drop in `show{}` — accept, or mandate a warn (C2) | ✅ **CONFIRMED**, and sharpened | `apply_config` reads only the known keys with no `else`/`Log.warn`; a field-write-only key (`after_submit`, …) or a typo passed to `show{}` is silently ignored. **Sharpening:** `set_cursor`/`set_text` **do** `Log.warn(... ignored — hidden)` (consoleController.lua:495, :505) — so warn-don't-swallow is already applied *selectively*; the silence here is an inconsistency, not a blanket policy. |
| 6 | Proxy iteration on LuaJIT — accept indexing-only, or add an iteration helper | ✅ **CONFIRMED**, self-admitted | controller.lua:349-352: "under LuaJIT/Lua 5.1 `pairs` ignores `__pairs`, so `pairs(proxy)` yields nothing … `__pairs` is kept for 5.2+ hosts." Read-index + write-raise hold and are tested; iteration is inert on the shipping platform. |
| 7 | Widget-visibility query — sanction a public `is_active()`-shaped read | ✅ **CONFIRMED** | The `compy.input` surface (`get_compy_input`, consoleController.lua:462) exposes `handlers/show/hide/get_cursor/set_cursor/set_text/configure/clear/…` — **no `is_shown`/`is_active`/`is_visible`**. An internal `UserInputController:is_shown()` exists (userInputController.lua:415) but is not on the project surface, so `maze/main.lua:497` reads `love.state.user_input` directly + keeps a per-tick re-arm poll. |
| 8 | Sweep in-code `REVIEW:` annotations + fix `input_api.md` doc bug | ⚠ **doc bug FIXED**; count is **31, not 45** | `grep REVIEW: src/` = **31** occurrences (all in `controller.lua` + `projectInputController.lua`); `>> REVIEW` = 0. The substance holds (owner's own open questions shipped inside landed code, to sweep before release). The `input_api.md` lifecycle bug is fixed in commit `8b9820d` (order + `before_submit` arg, verified against spec §5 + the code). |

## Bottom line for the owner

Nothing Fable claimed turned out to be false. Every architecture-level assertion checks out; the
sole correction is the annotation **count** (31 vs 45). All eight are genuine open questions, none
reverses the architecture. They fall into three buckets:

- **Contract / spec reconciliation** (docs-corpus stability — relevant *before* Task 4b evaluates
  the corpus): items 2 (`eval` deviation), 4 (`multiline` promise), 6 (proxy iteration spec §1).
- **API-surface additions** (small, additive, each needs a yes/no): items 1 (`compy.keys_pressed`),
  7 (`is_active()` predicate), 5 (warn on dropped config keys).
- **Behaviour ruling shipped open**: item 3 (combo-tier key-repeat).

## Related discovered issue — NOT one of Fable's 8

`doc/development/internals/user_input.md` is a **pre-sweep** narrative that survived the sweep
unrevised: it still describes the deleted `oneshot`/`push('userinput')` auto-hide as the *current*
mechanism, and lines 430-432 assert the `compy.input.*` callbacks "do not exist in `src/` yet" —
now false. Marked "human-approved NOT YET". This is a **rewrite**, not a targeted fix, and overlaps
Task 4b's incorporation decision (does this doc get rewritten to the landed system, or superseded by
`input_api.md` + a fresh internals doc). Escalated to the owner as a scope call, not resolved here.
