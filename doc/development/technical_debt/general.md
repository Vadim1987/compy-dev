---
description: Cross-cutting technical debt outside the input subsystem
status: active
audience: developer
authored: llm
reviewed: none
---

# General

Debt not tied to one subsystem — load-order/aliasing assumptions and shared-utility
semantics.

Three sections below, in release-scope order — not severity, not intent:
**ACTIVE** must be resolved before this release ships. **BACKLOG** is real and
acknowledged, but deliberately deferred past this release. **RETIRED** is
paid, or turned out not to be debt.

---

## ACTIVE

> REMARK: its not a defect, but convention -- gfx is alias for love.graphics, sfx is alias for compy.audio

### T-NAMESPACE-CLONE

Проектное окружение клонируется глубоко (table.clone перед запуском), поэтому любая живая платформенная таблица, положенная в неймспейс полем, едет в проект копией: программа присваивает обработчики в копию, диспетчер читает оригинал, обе стороны молчат без всякой ошибки. Потратил на это час отладки на устройстве. Ты это обошёл для input — держишь поверхность апвэлью за __index; я сделал serial тем же способом, включая запрет на присваивание самой таблицы. Паттерн неочевиден — следующий, кто добавит живую таблицу полем, наступит точно так же. Может, стоит строки в доке рядом с Decision 7.

### T-GFX-GLOBAL — `gfx` implicit global in `controller.lua`

- **Where:** `src/controller/controller.lua` — `set_love_update` / `set_love_draw` (and
  other drawing call sites in the same file) use `gfx`, a free variable not set in the file
  or any of its requires; it must exist at call time (set by the app's load sequence).
- **State:** Works because of load order, not because the file declares its dependency.
- **Why it stands:** Long-standing wiring assumption; changing it risks the load sequence
  for no behavioural gain.
- **Revisit:** When the controller's load/aliasing is next reworked — prefer a module-top
  `local gfx = love.graphics` per the standard-aliases convention.

### T-VERSION-NUM — The changelog's version number has never been settled against the scale of the change

- **Where:** `CHANGELOG.md`, and three independent askers — the file's own `REMARK:`,
  `doc/development/internals/user_input.md:470`, and
  `doc/development/conventions/../internals/project_sandbox_env.md:71`.
- **What is owed:** the tree calls itself `1.0.0-rc`, and the input work removed four public
  globals with no shim. Whether an rc number is honest against a break of that size was never
  ruled. Three places ask; none answers.
- **Why it is an entry:** an **obvious operational need** — a version number is the first thing
  an upgrader reads, and it is not settleable after the release it labels.
- **Roadmap:** `CHG-01-04` is the task. The rest of `CHG-01` was done by the ledger
  restructuring (2026-08-27); this part was not.

### T-RETIRED-UNVER — The register's resolved entries claim resolution that was never verified

- **Where:** `input.md`'s `RETIRED` section — 21 entries carrying a `RESOLVED` marker.
- **What is owed:** the 2026-08-27 restructuring sorted them on their **headings**. Not one was
  tested against the PR base to confirm the claim. A register whose retired section is unaudited
  is a register that quietly forgets things it never finished.
- **Why it is an entry:** an **obvious operational need**, and the register's own upkeep is debt
  like any other (`agents/rules/ledgers.md` §4). Expected yield is unknown, which is the reason
  to run it rather than to skip it.
- **Roadmap:** `FIX-02-05`.

### T-DEC-NUMBERED — The decisions ledger is cited by number, and numbers resolve to the wrong entry when they move

- **Where:** `doc/development/decisions/input.md`; roughly 165 citations across `src/` and
  `tests/`.
- **What is owed:** the conversion from numbers to mnemonic names. Under numbering, a missed
  citation after any renumber still resolves — **to the wrong decision** — and reads as
  authoritative; under names it dangles visibly and greps out. The same argument
  `agents/rules/roadmap.md` §2 makes for ids in code.
- **Why it is an entry:** an **obvious operational need** — readability debt in a ledger is debt
  (`agents/rules/ledgers.md` §4), and this one degrades silently.
- **Also unblocks the vacuum:** the retired entries that were never the stakeholder's may be
  swept once names make a dangling citation safe (`ledgers.md` §2).
- **Roadmap:** `DEC-01`, six steps. Not absorbed by the 2026-08-27 restructuring, which did the
  sectioning only.

## BACKLOG

### The conventions the examples demonstrate carry no test coverage

- **Where:** `src/examples/` and the nested example repos. No example anywhere
  in this codebase has spec coverage; the suite exercises the framework and
  never an example.
- **State:** the gap has teeth because the examples are not only samples — the
  guide points at them and projects copy them, so a convention that rots in an
  example rots in every project derived from it. `T-TURTLE-DUP` is the worked
  case: `turtle` double-handled its own keys for months while the suite stayed
  green, and its fix is likewise pinned by nothing. **End-to-end testing of
  examples is overkill and is not what is owed here** (owner, 2026-08-30).
  What may be worth pinning is the narrow set of conventions the examples
  *share* and the documentation *relies on* — the `is_shown` guard on a native
  handler, the one-shot echo guard on a trigger key, `after_submit` closing a
  prompt-per-command — each of which is a documented promise today with no
  test behind it at the point a project author would copy it.
- **Why it stands:** deliberately deferred past this release (owner,
  2026-08-30). Building it means a test genre this codebase does not have —
  driving an example's own `love.*` handlers through the framework's dispatch
  — and inventing that genre inside a defect row is how a defect row becomes a
  project. The framework side of each convention *is* already covered; what is
  missing is the example side.
- **Revisit:** when an example convention next breaks silently, or when the
  examples are next reworked as a set. **No roadmap row points here on
  purpose** — it is out of release scope, and a row would claim otherwise.

### The test suite passes only in declaration order

- **Where:** the whole suite, not one file. `busted tests` is green; `busted tests --shuffle`
  fails 29–55 rows per run, varying with the shuffle. Concentrated in `input model spec`
  (~23 rows), `Editor #editor` (~10) and a few `Dequeue` rows, but the set is not stable
  between runs.
- **State:** pre-dates any current feature work. Checked against the PR base `3256aac`,
  before the input-API branch existed: **674/0/0/0 ordered, 29–48 failures shuffled** — the
  same condition at a third the suite size. So rows leak state into their successors
  somewhere below the per-file boundary busted insulates (`insulate` restores `_G` and
  `package.loaded` per spec file, not mutations to a required module's own tables).
- **Why it stands:** every run anyone makes — local, CI, `busted tests` — is in declaration
  order, so it costs nothing today. Finding the leaks is a suite-wide investigation across
  subsystems that no single feature owns, and it would be started for a property nothing
  currently depends on.
- **Revisit:** before enabling `--shuffle`, test sharding, or any parallel runner in CI —
  each of those turns this from dormant into a source of false failures. Also worth a pass
  whenever a subsystem's fixtures are next reworked, since the leaks are fixture-shaped.

### Editor submit raises when no buffer is open

- **Where:** `src/view/editor/editorView.lua` `get_current_buffer` — `local bm =
  ctrl:get_active_buffer()` is indexed unguarded on the next line.
  `EditorController:get_active_buffer` is `self.model.buffers:first()`, which answers
  **nil** when the buffer list is empty. Two more call sites index the same nil the same
  way: `get_active_buffer_id` and `_generate_status`.
- **State:** reproduced deterministically, not observed once. The harmony scenario
  `editor.open-close` — `project("create")`, `edit()`, then **Ctrl+Shift+S** — raises
  `editorView.lua:70: attempt to index local 'bm' (a nil value)` through
  `editorController.submit` ← `_normal_mode_keys` ← `keypressed`. The buffer list is empty
  at the moment the key is handled; **why** it is empty right after `edit()` on a freshly
  created project is *not* diagnosed here.
- **Not a feature regression:** the full scenario suite was run against two trees — with and
  without the input feature's in-flight widget-lifetime change — and produced the same error,
  at the same line, once each, in logs of identical length. It predates that work.
- **Why it is filed and not fixed:** it is outside the input subsystem and outside the
  feature that found it; fixing it means deciding what submit *should* do with no buffer
  (no-op, or refuse earlier), which is an editor design call.
- **No test covers it.** `busted tests` is green, so the suite never submits without a
  buffer — the gap is what let a deterministic raise sit unnoticed in a scenario that runs
  every time the harmony suite does.
- **Revisit:** when the editor's buffer lifecycle is next touched. A guard in
  `get_current_buffer` alone would only move the nil one frame later; the three call sites
  and the "what does submit mean here" question go together.

### The console's terminal self-test is unreachable

- **Where:** `src/controller/consoleController.lua` — `terminal_test`'s opening guard,
  `love.state.app_state ~= 'ready' or love.state.app_state ~= 'project_open'`. A state
  cannot be both, so the disjunction holds for every value and the function always returns
  before its body.
- **State:** the whole feature is dormant. `Ctrl+Alt+T` in DEBUG does nothing;
  `util/test_terminal.lua` is never called, so `love.state.testing` is never set and its
  readers — the `'running'` / `'waiting'` branches in `ConsoleController:keypressed` and
  `src/view/input/statusline.lua` — cannot fire. Present at the PR base `3256aac`, so it
  pre-dates the input-API branch and no current work touches it. The intent reads as `and`.
- **Why it stands:** a developer-facing self-test with no caller in normal use; nothing
  observable regressed when it stopped running, which is why it went unnoticed. Fixing the
  operator re-animates a display path nobody has exercised in months — worth doing
  deliberately, with a look at the output it paints, rather than as a drive-by.
- **Revisit:** when the console's debug affordances or the terminal widget are next worked
  on. Fix is one operator; the work is confirming the revived path still renders sensibly.

### `table.protect(love.handlers)` is a no-op on the passed table

- **Where:** `src/controller/controller.lua` — end of `setup_callback_handlers`.
- **State:** `table.protect` returns a read-only proxy but does not mutate the original
  table; the call's return value is unused, so `love.handlers` is not actually protected.
- **Why it stands:** No observed breakage, and the proxy-vs-mutate semantics are a broader
  `util/table` question.
- **Revisit:** If/when read-only enforcement on `love.handlers` is actually wanted — either
  consume the returned proxy or change `table.protect`'s semantics.

## RETIRED

*(none in this file yet.)*
