# M8-02 — balloons migration (chunk 2 of the M8 carve, terminal milestone)

_Implementor commission (`agents/dev.md`). Milestone id `M8-02`. Second chunk of the M8 carve
(`implementation/M8-chunk-plan.md`), validated against the frozen `design/spec/M8-02-recut.md` (Gate-3
CLOSED, human-approved 2026-07-07). Migrates the **balloons** example (a **nested checkout**) off the
legacy poll-a-reftable idiom onto the `compy.input.*` continuous-session API. **You do NOT remove any
legacy global** (that is M8-03) and you **do NOT touch the in-repo examples** (M8-01, already landed).
Suite baseline entering this chunk: **808 / 0 / 0 / 4**._

## ⚠ DELIVERY DISCIPLINE — read this FIRST (frozen AC-9 + guardrail 7)

`src/examples/balloons/` is a **nested checkout** with its own `.git` (untracked by this repo). Frozen
spec **AC-4** delivers balloons as **uncommitted working-tree changes**; **AC-9** requires its `.git`
**untouched** and **no new commit inside it** (mandate guardrail 7). The human broadened the standing
grant to *permit* commits inside detached sub-repos, but the PM's ruling for **this** chunk is: **honor
AC-9 (frozen authority) — edit the balloons files, leave them uncommitted, NEVER `git add`/`git commit`
inside `src/examples/balloons/`, NEVER touch its `.git`.** List every edited balloons file, path-by-path,
in the outcome ledger so the human carries the patch upstream. The **only** thing you commit to THIS repo
for M8-02 is the outcome ledger (+ any `tests/input/*` row you add). Precedent: maze (M5c-05) — read
`outcomes/M5c-05-example-migration.md` for the exact nested-checkout delivery shape + the honest
headless-verification ceiling.

## Read first (authority chain — higher wins)

1. `design/notes/ratified-model.md` — canonical ratified model (binding glossary; R1 = `on_text_entered`
   is widget output, submit-time, assembled text). Mint no nouns outside its glossary.
2. `design/spec.md` §5 (continuous-session), §8/§9 (migration mapping), §10 (edge cases) — the Gate-2
   authority the M8 spec derives from.
3. **`design/spec/M8-02-recut.md`** — the frozen target. Your ACs this chunk: **AC-4, AC-8, AC-9** (+ AC-6,
   AC-10 for the suite). Read them verbatim (lines 97-111).
4. `doc/development/internals/user_input.md` — the runtime picture: `compy.input`
   (`show`/`hide`/`configure`/`set_text`) + the submit lifecycle.
5. `implementation/M8-chunk-plan.md` — the carve; its "migration recipe" + the balloons note.
6. `implementation/outcomes/M8-01.md` — the just-landed in-repo migrations: the **corrected recipe**
   (see next section) that M8-02 reuses.
7. `implementation/outcomes/M5c-05-example-migration.md` + `outcomes/M7-02.md` (the `configure` semantics).

`design/` is **frozen** — read, never edit. Rules (auto-loaded via `CLAUDE.md`): line ≤64 chars, fn body
≤14 lines, params ≤4, nesting ≤4, no string-tag dispatch, KISS, **tests-first**, **report-don't-fix**,
Conventional Commits, **commit locally NEVER push**. **lua-lsp MCP is UP** — use it for correctness;
`sleep 1` after any `.lua` edit before an MCP call; grep as the completeness backstop.

## The CORRECTED recipe (landed at M8-01 — reuse verbatim)

- `after_submit`/`before_submit`/`before_cancel`/`after_cancel` are **field-writes** on `compy.input`
  (`INPUT_CALLBACKS`, `consoleController.lua:357-369`), **NOT** `show{}` keys — `OUTPUT_KEYS` (the only
  merged/sticky keys) is exactly `on_text_entered`/`on_limit_reached`/`validator`/`highlighter`. So
  `show{ after_submit = fn }` is **silently dropped**. Wire the re-prompt as a standalone
  `compy.input.after_submit = function() compy.input.show{} end`.
- `on_text_entered`/`validator`/`highlighter`/`eval` DO flow through `show{}`; and `prompt`/`eval` stay
  **model-sticky** across a bare re-show (the model singleton persists; `custom_label`/evaluator are
  nilled nowhere — verified at M8-01 review). So a bare `show{}` re-arm keeps the last prompt + evaluator.

## The balloons architecture (map it live before editing — line refs are a guide)

balloons routes input through a small terminal shim; the whole legacy poll-re-arm lives in **three files**:

- **`terminal.lua`** — `terminal_init()` sets `terminal = user_input()` (the legacy reftable) and returns a
  `{ write, read }` shim. `terminal_write(msg)` = `input_text(msg, nil)` (re-arms the widget with `msg` as
  prompt). `terminal_read(callback)` polls: `if not terminal:is_empty() then callback(terminal()) end`.
- **`ui.lua`** — `ui.terminal = terminal_init()` (built at require time). `ui_draw_hint()` calls
  `ui.terminal.write(hint)` (⇒ `input_text`) — this is the **per-hint re-show**. `ui_read_input =
  terminal_read` (aliased). `ui_set_hint(txt)` updates the hint then `ui_draw_hint()`s it.
- **`main.lua`** — `hooks.update` calls `ui_read_input(input_handler)` every frame; `input_handler =
  game_state_router(on_input)` routes the submitted text by `game_state` (`game_command` when
  loaded/finished, `game_validate_input` when active). Note `input_handler` is built in `game_init()`,
  **after** `ui`/`terminal_init` already ran — the handler is passed at read-time, not init-time.

**The two legacy globals to migrate (census): `input_text` (terminal.lua:16), `user_input`
(terminal.lua:20).** No `input_code`/`validated_input`/`write_to_input` in balloons (plain text, default
evaluator — simpler than tixy).

## The migration (continuous-session idiom — AC-4)

Map the poll-re-arm to activate-once + reprompt-from-the-submit-hook (no per-frame poll, no re-show-per-hint):

- **`terminal_init()`** → activate once: `compy.input.show{ on_text_entered = <deliver to the current
  input_handler> }` + `compy.input.after_submit = function() compy.input.show{} end` (bare re-arm; prompt
  stays sticky). Because `input_handler` isn't known at init time, close `on_text_entered` over a module
  slot (e.g. `current_handler`) that `game_init` sets — or expose a small setter. Keep it KISS; the shim's
  `read`/`write` public shape can stay (callers unchanged) even as their bodies change.
- **`terminal_write(msg)`** (the per-hint prompt) → `compy.input.configure{ prompt = msg }`.
  `configure{prompt=…}` updates the label **live while active** and **stashes it as pending for the next
  show while hidden** (`consoleController.lua:517-525`, M7-02 AC-1) — so it is correct both mid-session
  (a hint set from `game_validate_input`, which runs inside `on_text_entered`) and between sessions.
  **No `input_text`, no re-show.**
- **`terminal_read` / `ui_read_input(input_handler)`** → the per-frame poll **disappears**; delivery is
  `on_text_entered`. `hooks.update` no longer needs the read call (drop it, or make `ui_read_input` a
  noop) — keep `state_updater(...)`. `terminal` (the reftable) and `terminal:is_empty()`/`terminal()`
  polling are **deleted**.

**⚠ Verify test-first, and STOP+report if it forces a design choice:** the hint is set *inside*
`on_text_entered` (`game_validate_input → ui_set_hint → configure{prompt}`), i.e. **while the session is
still active** (deliver fires `on_text_entered` **before** hide; F-0). Then `after_submit` (after hide)
re-shows. Confirm the sequence **live-configure-prompt-during-on_text_entered → hide → bare re-show**
lands the intended prompt on the re-armed session (not a stale one). If the configured-while-active prompt
does **not** survive the hide→reshow (e.g. it applies to the dying session and the reshow shows the prior
label), that is a **genuine surface finding** — **STOP and report it surprise-first**; do not paper it
over with a workaround. (Plausible clean outcome: configure-while-active sets `custom_label` on the
persistent model, which the bare reshow keeps — but **prove it**, don't assume.)

## Do in this order (test-first — red before green)

1. **Reproduce the baseline.** `busted tests` → **808 / 0 / 0 / 4** (the four pending are the routing-gap
   cells @101/@153/@161/@222 — leave them).
2. **Contract check (AC-4 idiom + the configure-during-session sequence).** The `#m8` continuous-session
   rows (M8-01) already pin activate-once + `on_text_entered` + field-write-`after_submit` re-arm. If the
   **configure-prompt-set-inside-on_text_entered-then-reshow** sequence balloons depends on is **not**
   already covered by an existing `#input`/`#m7` row (M7-02 AC-1 covers live configure-prompt; check
   whether the "configure inside on_text_entered, then reshow" ordering is pinned), add **one red row** in
   `tests/input/input_contracts_spec.lua` via the `input_fixture` (`F.activate_project` +
   `F.session.type`/`.press`) that stands a synthetic project mirroring balloons' shape and asserts the
   reshown session carries the configured prompt. Only add a row if the ordering isn't already proven —
   don't duplicate coverage. (balloons itself is a nested checkout, **not** in the busted suite; the
   contract is proven at the fixture level, the example at the smoke-load + human-hand-play level.)
3. **Green: migrate balloons** (terminal.lua + ui.lua + main.lua per above). Then **smoke-load headless**:
   `xvfb-run -a love src play src/examples/balloons 2>&1 | head -60` — traceback-free + no warn-spam
   (especially **no `show()`-while-active warn** — the M5c-05 SIGTERM-hang caveat applies: the run staying
   up traceback-free is the pass; you cannot inject keystrokes). Grep balloons for all six legacy globals
   → **zero**.
4. **Full suite + LSP.** `sleep 1`; lua-lsp `diagnostics` on the balloons `.lua` you edited. `busted tests`
   → **808 (+N if you added a row) / 0 / 0 / 4**; the four pending unchanged; **no legacy global removed**
   so no nil-call rows here (those are M8-03).
5. **Record the outcome ledger + commit** (below).

## Scope fence (overreach = STOP + record, do not silently do)

- **Do NOT remove or alter any legacy global** (`user_input`/`input_text`/`input_code`/`validated_input`/
  `write_to_input`/`astv_input`) or the `input()`/`input_ref`/`create_input_handle()` machinery or the
  `compy_namespace.text_input` dead write — **all M8-03**. balloons simply stops calling them.
- **Do NOT touch the in-repo examples** (tixy/repl/guess/valid — M8-01, landed) or maze/turtle/keyboard.
- **Do NOT edit `src/controller/*`, `src/model/*`, or `evaluator.lua`** — you are a **consumer** of the
  landed M5c/M7 surface. If a migration seems to need a surface change, **STOP + record** (likely the
  configure-during-session finding above, or a real gap).
- **NEVER `git add`/`git commit` inside `src/examples/balloons/`; NEVER touch its `.git`.** (AC-9.)
- **Expected edited files:** `src/examples/balloons/{terminal,ui,main}.lua` (uncommitted, ledger-listed)
  + optionally `tests/input/input_contracts_spec.lua` (one contract row, committed to THIS repo) +
  `outcomes/M8-02.md`. Anything beyond = stop + record why.

## Report-don't-fix (log in the ledger, do NOT fix)

- balloons' `main.lua` trailing test-comment cruft (L108-140: `-- test`/`print("ok")` noise) is
  **pre-existing** — do not clean it up (out of scope; it's the human's upstream repo).
- Any leaking example globals / `action_map` fallback quirks you trip over: log, don't fix, unless an AC
  provably needs it.
- Any surface friction that behaves differently from `internals/user_input.md`: **flag it surprise-first**;
  if it forces a **design** choice, **STOP and report** (do not rule in-slice).

## Outcome ledger — write to `outcomes/M8-02.md`

Open with the mandatory **"what will surprise the architect"** (surprise-first): at minimum the
configure-prompt-during-on_text_entered→reshow sequence outcome (did the prompt survive? clean or a
finding?); the terminal-shim restructure (how `on_text_entered` reaches the state-routed `input_handler`);
any conservative-reversible call. Then: per-AC (**AC-4** balloons on `compy.input.*`, no poll/no
re-show-per-hint — how each was proven; **AC-8** edge cases — which the migrated example + the contract
suite cover; AC-6/AC-9/AC-10); before/after of the terminal shim (what the poll-re-arm was, what the
callback+configure wiring is); the **nested-checkout delivery** — every edited `src/examples/balloons/`
file listed path-by-path, with the explicit statement that **`.git` was untouched and nothing was
committed inside it** (AC-9); the contract row if added (red→green); commit hash (THIS repo, ledger +
test only); before/after busted counts; **headless smoke-load result** (traceback-free? no active-show
warn?) **with the honest ceiling** (no keystroke injection → real compose/submit/re-prompt is a **human
hand-play gate** — add balloons to the open list); the scope-fence confirmation (no global removed,
in-repo examples + controllers + evaluator.lua untouched, balloons `.git` untouched). If anything forces a
genuine **design** choice, **STOP and report** — do not rule in-slice.
