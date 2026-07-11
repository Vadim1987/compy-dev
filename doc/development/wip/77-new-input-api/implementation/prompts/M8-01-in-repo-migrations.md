# M8-01 — in-repo example migrations (chunk 1 of the M8 carve, terminal milestone)

_Implementor commission (`agents/dev.md`). Milestone id `M8-01`. First chunk of the M8 carve
(`implementation/M8-chunk-plan.md`), validated against the frozen `design/spec/M8-02-recut.md` (Gate-3
CLOSED, human-approved 2026-07-07 — the implementation target; `M8.md` / `M8-01-dead-text-input.md` are
frozen history). Migrates the **four in-repo** legacy-input consumers — **tixy, repl, guess, valid** —
onto the `compy.input.*` callback API, using the continuous-session idiom. **You do NOT remove any legacy
global** (that is M8-03) and you **do NOT touch balloons** (nested checkout, M8-02). Suite baseline
entering this chunk: **806 / 0 / 0 / 4**._

## Read first (authority chain — higher wins)

1. `design/notes/ratified-model.md` — canonical ratified model (R1–R14, binding glossary; R1 =
   `on_text_entered` is widget output, submit-time, assembled text). Mint no nouns outside its glossary.
2. `design/spec.md` §8/§9 (+ §5 continuous-session, §10 edge cases) — the Gate-2 **authority** the M8 spec
   derives from; §9 is the migration mapping.
3. **`design/spec/M8-02-recut.md`** — the frozen implementation target. Read the **Contract**
   (Replacements mapping + the de-bound-helper-names note), **Migration scope**, and the **Acceptance
   criteria** verbatim. Your ACs this chunk: **AC-3, AC-5** (+ AC-6, AC-10 for the suite — see below).
4. `doc/development/internals/user_input.md` — the runtime picture: the `compy.input` namespace
   (`show`/`hide`/`configure`/`set_text`/…) and the submit lifecycle.
5. `implementation/M8-chunk-plan.md` — the carve. Its **"migration recipe"** section is your build
   sheet; its **`eval = InputEvalLua` note** is binding for tixy.
6. `implementation/outcomes/M5c-05-example-migration.md` — the **precedent** (turtle/maze migrations):
   the continuous-session idiom in practice + the honest **headless-verification ceiling** (no keystroke
   injection in-container → human hand-play is the final gate; report, don't overclaim).

`design/` is **frozen** — read, never edit. Repo-root `CLAUDE.md` auto-loads `rules.md` +
`development.md`: hard limits (line ≤64 chars, fn body ≤14 lines, params ≤4, nesting ≤4), no string-tag
dispatch, KISS, **tests-first** (red before green), **report-don't-fix**, Conventional Commits, **commit
locally, NEVER push**. **lua-lsp MCP is UP — use it** for correctness (`definition`/`references`/`hover`/
`diagnostics`); `sleep 1` after any `.lua` edit before an MCP call; grep as the completeness backstop.

## Your ACs (verbatim from `spec/M8-02-recut.md`)

- **AC-3** `tixy` runs fully on `compy.input.*`: code entry with highlighter/validator, live writes via
  `set_text`, submit observed via callbacks — **no polling loop remains in it**.
- **AC-5** `repl`, `guess`, `valid` are each either **migrated** (running on `compy.input.*`) or
  **explicitly marked excluded** in the outcome ledger — the owner's release call, recorded, **no third
  state**. _(PM direction: these three are trivial — **convert all three**; record an exclusion only on a
  genuine recorded blocker, never as the easy path.)_
- **AC-6** Pure-native examples still work unchanged — do not perturb them (verify by not touching them +
  suite green).
- **AC-10** Full suite green; the recipe primitives you rely on stay contract-covered. _(The nil-call
  assertions AC-1/AC-2 land in **M8-03**, not here — the globals still exist this chunk.)_

## The migration recipe (from `M8-chunk-plan.md` — the linchpin)

Every one of these examples uses the **poll-re-arm loop**: `r = user_input()` once, then each frame
`if r:is_empty() then <re-show> else <consume r()> end`. The landed submit lifecycle is:
Enter → `before_submit` → `ui:submit()` = **`deliver()` fires `on_text_entered(text)` while active** then
`hide()` → **`after_submit(text)` fires after hide** (`src/controller/projectInputController.lua:66-81`,
`userInputController.lua:364-389`). So migrate the loop to the **continuous-session idiom**:

```lua
compy.input.show{
  prompt          = P,
  validator       = V,       -- or eval = InputEvalLua for tixy (Lua highlighting)
  on_text_entered = function(text) <consume — what the old `else r()` branch did> end,
  after_submit    = function()     compy.input.show{ prompt = nextP } end, -- re-prompt AFTER hide
}
```

- **Consume in `on_text_entered`; re-`show{}` in `after_submit`.** A `show()` inside `on_text_entered`
  warns (still active). Widget-output callbacks + validator are **sticky** across show/hide, so a bare
  re-show (`show{}` or `show{prompt=…}`) re-arms with the same callbacks — do NOT re-pass them each time.
- `write_to_input(c)` → `compy.input.set_text(c)` (active-session live write; no-op+warn if hidden).
- `user_input()` + `r:is_empty()`/`r()` polling → **deleted**; delivery is the callbacks.

## Per-example migration (line refs — confirm live before editing)

**tixy** (`src/examples/tixy/main.lua`) — the richest; **do this first**, verify the recipe, then the
other three follow the same shape:
- L39 `write_to_input(body)` (inside `load_example`) → `compy.input.set_text(body)`.
- L171 `r = user_input()` → delete; L173-183 `love.update` poll loop → the initial `compy.input.show{…}`
  (moved to the same place tixy first needs the prompt — likely near the end where `advance()` runs, or
  a one-time init) with `on_text_entered(text)` doing what the old `else` branch did
  (`body = string.unlines(text); setupTixy(); legend = ""`), and `after_submit` re-prompting.
- L176 `input_code("function tixy(t, i, x, y)", string.lines(body))` supplied the **prompt + Lua
  highlighting**. Migrate via **`eval = InputEvalLua`** in `show{}` (see the `eval` note below). The
  prompt string moves into `show{ prompt = "function tixy(t, i, x, y)", text = string.lines(body) }`.
- Net: the per-frame `if r:is_empty() then input_code(...) else … end` in `love.update` **disappears**;
  `love.update` keeps only `time = time + dt`. **No polling loop remains** (AC-3).

**repl** (`src/examples/repl/main.lua`, 9 lines) — `user_input()` (L1) + `input_text()` (L5), loop
`print(r())`. → `compy.input.show{ on_text_entered = function(t) print(t) end, after_submit = function()
compy.input.show{} end }`; delete `love.update`'s poll body (it becomes empty → drop the callback).

**guess** (`src/examples/guess/main.lua`) — `user_input()` (L2) + `validated_input({is_natural}, "Guess a
number:")` (L52), loop `check(tonumber(r()))`. → `compy.input.show{ prompt = "Guess a number:",
validator = <the {is_natural} filter — wire via ValidatedTextEval or the validator key, whichever the
codebase provides>, on_text_entered = function(t) check(tonumber(t)) end, after_submit = re-prompt }`.
`is_natural` is defined twice in-file (L12 + L26) — that shadowing is **pre-existing**; don't fix it
(report-don't-fix), just wire the effective one.

**valid** (`src/examples/valid/main.lua`) — `user_input()` (L1) + `validated_input({min_length(2),
is_lower})` (L77), loop `print(r())`. → same shape: `validator = <the two-filter list>`,
`on_text_entered = function(t) print(t) end`, re-prompt in `after_submit`.

### The `validated_input(filters, prompt)` → validator mapping (guess/valid)

Legacy `validated_input(filters)` = `input(ValidatedTextEval(filters), …)` where `ValidatedTextEval` is a
`_G` global (`evaluator.lua:163`) building a plain evaluator whose validators are the filter list.
`compy.input.show{}`'s `validator` slot feeds `apply_config`'s validator **gate**
(`userInputController.lua:230-231, 343-348`) — a **function** `(text) -> ok, err`. Decide, and verify
test-first, the faithful wiring: either pass `eval = ValidatedTextEval({is_natural})` (reuses the exact
legacy filter→evaluator path), or pass a `validator` function that runs the filters. **Prefer the path
that reproduces the legacy validation behaviour with the least new logic**; record which you chose and
why. `ValidatedTextEval`/`InputEvalLua`/`InputEvalText`/`LuaEditorEval` are `_G` globals and **stay** —
you are not removing them (M8 leaves `evaluator.lua` untouched).

### `eval = InputEvalLua` note (tixy — binding)

tixy's Lua highlighting migrates by passing **`eval = InputEvalLua`** through `show{}` — `show` passes
its cfg wholesale to `ui:show` → `apply_config`, which reads `cfg.eval` and calls `model:set_eval`
(`consoleController.lua:472-478`, `userInputController.lua:211-213`). Reconstructing Lua highlighting via
`highlighter=` on the plain **default** eval is **not** equivalent (that only sets `ev.highlighter` on
the existing plain evaluator). The spec's de-bound-helper-names note sanctions using whatever evaluator
mechanism the codebase provides. **Verify the highlighter actually renders** (headless smoke +
inspection). **Flag surprise-first** that tixy uses the `eval` mechanism key (not the documented
`highlighter`/`validator` keys). **If `eval` does not flow through `show{}` to the model, STOP and
report** — do not invent a workaround.

## Do in this order (test-first — red before green)

1. **Reproduce the baseline.** `busted tests` → confirm **806 / 0 / 0 / 4** (the four pending are the
   routing-gap cells @101/@153/@161/@222 — **leave them**; not this chunk's).
2. **Red: a contract test for the continuous-session idiom** (the recipe you rely on for all four). Using
   the `tests/helpers/input_fixture.lua` fixture (`F.activate_project`/`F.running_project` +
   `F.get_compy_input()` + `F.session.type`/`.press`), stand a project that calls
   `show{ on_text_entered=…, after_submit=function() show{} end }`, type text, press return, and assert:
   (a) `on_text_entered` received the assembled text; (b) after submit the widget is **re-shown** (the
   `after_submit` re-show fired — `love.state.user_input` truthy again / `ui:is_shown()`). See the
   existing `describe('routing: project run')` block for how delivery is witnessed at the public seam.
   This fails only if the idiom is mis-wired — it pins the pattern before you touch examples.
3. **Green: migrate tixy** (per above). Then **smoke-load headless**:
   `xvfb-run -a love src play src/examples/tixy 2>&1 | head -40` (see M5c-05 ledger for the
   SIGTERM-hang caveat — the run staying up traceback-free is the pass; you cannot inject keystrokes).
   Inspect for tracebacks / warn-spam. Confirm the highlighter renders (log/inspection).
4. **Green: migrate repl, guess, valid** (same recipe). Smoke-load each headless the same way.
5. **Full suite + LSP.** `sleep 1`; lua-lsp `diagnostics` on any `.lua` you edited (the examples + none
   of `src/` should need changing — if you find yourself editing `src/controller/*`, **STOP + record**,
   that is likely M8-03 scope). `busted tests` → **806 + N / 0 / 0 / 4** (N = your new contract row(s);
   the four pending unchanged; **no legacy global removed** so no nil-call rows here).
6. **Record the outcome ledger** (below) and **commit locally** (Conventional Commits, no push, this repo
   only — all four examples are **in-repo**, commit normally; **none is a nested checkout**).

## Scope fence (overreach = STOP + record, do not silently do)

- **Do NOT remove or alter any legacy global** (`user_input`/`input_text`/`input_code`/`validated_input`/
  `write_to_input`/`astv_input`) or the `input()`/`input_ref`/`create_input_handle()` machinery or the
  `compy_namespace.text_input` dead write — **all of that is M8-03**. They coexist with your migrations
  this chunk (migrated examples simply stop calling them).
- **Do NOT touch `src/examples/balloons/`** (nested checkout — M8-02) or `maze`/`turtle`/`keyboard`
  (already migrated / pure-native).
- **Do NOT edit `evaluator.lua`** — the evaluators stay; you consume `InputEvalLua`/`ValidatedTextEval`
  as `_G` globals.
- **Do NOT change routing/dispatch** (`projectInputController.lua`, `controller.lua`) or the
  `consoleController.lua` `compy.input` surface — you are a **consumer** of the landed M5c/M7 surface, not
  a modifier of it. If a migration seems to need a surface change, **STOP + record** (likely a real gap).
- **Expected files** (anything beyond = stop + record why): `src/examples/tixy/main.lua`,
  `src/examples/repl/main.lua`, `src/examples/guess/main.lua`, `src/examples/valid/main.lua`,
  `tests/input/*` (the continuous-session contract row).

## Report-don't-fix (log in the ledger, do NOT fix)

- **guess's duplicate `is_natural`** (L12 + L26) — pre-existing shadowing; wire the effective one, don't
  refactor.
- Any latent wrinkle in the example code you trip over (globals leaking, `setfenv(f, _G)` in tixy's
  `setupTixy`, etc.): log it, don't fix, unless an AC provably needs it.
- Any surface friction (a recipe primitive that doesn't behave as the internals doc says): **that is a
  finding — flag it surprise-first**; if it forces a **design** choice, **STOP and report** (do not rule
  in-slice).

## Outcome ledger — write to `outcomes/M8-01.md`

Open with the mandatory **"what will surprise the architect"** (surprise-first) section — at minimum: the
tixy `eval = InputEvalLua` mechanism-key choice; the guess/valid validator-vs-eval wiring choice; any
conservative-reversible call. Then: per-AC summary (**AC-3** tixy: how each of code-entry/`set_text`/
callback-submit was proven + that no poll loop remains; **AC-5** repl/guess/valid: migrated vs excluded,
each explicitly, with the recipe used; AC-6/AC-10); per-example before/after (what the poll loop was, what
the callback config is); the **continuous-session contract test** (what it asserts, red→green); commit
hash(es); before/after busted counts (`806 → 806+N / 0 / 0 / 4`); **headless smoke-load results** per
example (traceback-free? highlighter rendered for tixy?) **with the honest ceiling** (no keystroke
injection → real submit/re-prompt is a **human hand-play gate** — list tixy + repl/guess/valid on it);
the scope-fence confirmation (what you did NOT touch — especially: no global removed, balloons untouched,
`evaluator.lua` untouched); tech debt discovered. If anything forces a genuine **design** choice, **STOP
and report** — do not rule in-slice.
