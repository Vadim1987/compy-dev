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

### T-ARGUES-INTERIM — the decisions ledger argues with an interim past that never shipped

- **Where:** `doc/development/decisions/input.md`, throughout the live entries — not the `RETIRED`
  section, which is already empty.
- **The rule it fails:** `../../../agents/rules/ledgers.md`, *"What a decision records about its
  own past"* — what was not in a released version is considered never to have existed, except what
  stakeholders explicitly ratified. Prose re-litigating an interim version of our own ruling
  describes a system nobody ran.
- **Two measured instances, and they are the two shapes:**
  - **A whole section arguing with a withdrawn rationale.** `D-ROUTE-LIFETIME` carries *"Why the
    original rationale was withdrawn"* — ten lines quoting a justification that never reached a
    release and refuting it point by point. The mid-run release it describes was introduced and
    removed inside this branch.
  - **A name that lived a fortnight.** `oneshot` was ruled and overruled within a day, never
    released, and is mentioned **13 times** in the ledger — amendment narration explaining why the
    key a reader has never seen is not the key they have.
- **Not a mechanical sweep, and this is the whole difficulty.** Two things sit inside the same
  paragraphs and must survive: **pre-feature baseline facts**, which are provenance telling a
  reviewer the release *restored* behaviour rather than changing it, and **anything stakeholders
  ratified**. `D-ROUTE-LIFETIME`'s section is the worked example of both — the base check inside it
  (`set_default_handlers` called from exactly two sites at `3256aac`; the `running → project_open`
  transition released nothing) is exactly what must be kept while the argument around it goes.
- **The qualifier is `interim, overwritten`, not `self-arguing`** (owner correction, 2026-09-01).
  An entry weighing a live alternative, or amending another entry still in force, is the ledger
  doing its job. The test is whether a reader would plausibly propose the alternative again.
- **The `REMARK` that raised it stays until this is paid, deliberately** (owner, 2026-09-01):
  `decisions/input.md`'s *"clean up self-arguing with past decisions that were then reshaped before
  release"*. A marker is removed when the defect it names is solved, not when a sweep reaches it —
  so whichever pass takes the corpus markers must leave this one, and paying this entry is what
  removes it.
- **Revisit:** `DEC-02`.

## BACKLOG

### Line citations across the persistent corpus are unverified, and a fifth of the checkable ones do not resolve

- **Where:** every `doc/` file outside `wip/` that cites source by line —
  `technical_debt/input.md` (24), `internals/user_input.md` (19),
  `internals/event_dispatch_layers.md` (17), `internals/project_sandbox_env.md` (6),
  `internals/editor.md` (4), `tests.md` (3), this file (2), `internals/console.md` (2),
  `internals/examples/repl.md` (1), `drawing_system.md` (1). 77 distinct `file.lua:N` references.
- **State, measured 2026-09-01:** 62 resolve to a basename unique under `src/`; the other 15 name
  files that exist in several repos (`main.lua`, `input.lua`, …) and were not checked at all.
  **Of the 62, fourteen — 23% — land on a blank line or a bare `end`.** That is a floor, not the
  count: a drifted citation can also land on plausible code, which is how
  `userInputModel.lua:487` passed as a history-restore `set_text` while pointing at
  `self:clear_input()`.
- **Why it matters:** this is `T-DEC-NUMBERED`'s sibling. A citation by a coordinate that moves
  **resolves to the wrong thing instead of dangling**, so it reads as authoritative and greps
  clean — the argument `agents/rules/roadmap.md` §2 makes for ids in code, and
  `agents/validation.md`'s *"Comment References"* makes for section names. Line numbers are the
  same hazard with no mitigation at all: nothing in the workspace can tell you one has drifted.
- **How it happens is ordinary, not careless:** the six corrected under
  `input.md`'s *"Six line citations into `userInputModel.lua` were stale on arrival"* were written
  in the very commit that shifted them, by a session that had verified each one before its own
  unrelated edit moved the file. No sweep catches that; only not citing lines does.
- **The fix is the one the corpus keeps re-deriving:** cite the **function or section name**.
  Where a line is genuinely the point, cite the name and quote the line's text so a reader can
  grep it. Sizing is real work — 77 references, and the 15 example-repo ones need the repo
  identified before they can even be checked.
- **Provenance: mixed and mostly ours.** The corpus is `#77`'s own creation (at
  `wip77/20260826/mergebase`, `doc/development/` holds five entries), but the practice of citing
  by line predates the feature and is not confined to it.
- **Not slugged** — no commitment to fix before release; that is an owner call. If taken it is a
  `FIX` row, and it belongs beside `FIX-03`, which runs late for the same reason: a citation
  sweep run while the tree still moves is run twice.

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

### `string.split_array`'s type guard never fires

- **Where:** `src/util/string/string.lua:241` —
  `if not type(str_arr) == 'table' then return {} end`.
- **State:** operator precedence makes this `(not type(str_arr)) == 'table'`,
  which is `false == 'table'`, i.e. **always false**. The guard never returns
  early, so a non-table argument reaches `ipairs(str_arr)` and raises there
  instead of being handled. The intended form is `type(str_arr) ~= 'table'`.
- **Why it matters beyond the typo:** `string.lines` delegates every list to
  this function, and `UserInputModel:set_text` delegates to `string.lines`, so
  the guard sits on the input widget's content path. It is **latent, not live** —
  every current caller passes a table — which is why this is BACKLOG.
- **Provenance: pre-existing**, another author's utility module. Found by the
  cold peer review of `BUG-02-01`, 2026-09-01, while checking how a non-string
  element is handled.
- **Not slugged**, and **no size refactor implied** — the fix is the two
  characters that make the guard mean what it says.

### `table.protect(love.handlers)` is a no-op on the passed table

- **Where:** `src/controller/controller.lua` — end of `setup_callback_handlers`.
- **State:** `table.protect` returns a read-only proxy but does not mutate the original
  table; the call's return value is unused, so `love.handlers` is not actually protected.
- **Why it stands:** No observed breakage, and the proxy-vs-mutate semantics are a broader
  `util/table` question.
- **Revisit:** If/when read-only enforcement on `love.handlers` is actually wanted — either
  consume the returned proxy or change `table.protect`'s semantics.

## RETIRED

### The decisions ledger is cited by number — PAID by the conversion to names (2026-09-01)

- **Was `T-DEC-NUMBERED`.**
- **What was owed:** the conversion from numbers to mnemonic names. Under numbering a missed
  citation after any renumber still resolves — **to the wrong decision** — and reads as
  authoritative; under names it dangles visibly and greps out.
- **Paid by `DEC-01`.** 31 decisions carry a `D-` slug declared first in the heading, and
  `Decisions? [0-9]+` returns zero across `src/`, `tests/`, the persistent corpus and `agents/`.
  The crosswalk from every number the ledger ever issued is an appendix to the ledger itself, so
  it outlives the feature's working tree.
- **Sized at 165 citations across 18 files; it was 554 across 36**, and the gap was not drift.
  Three forms were invisible to the pattern the sizing used: **18 line-broken citations** with the
  number on the next line, 11 plural mentions, and **8 bare back-references** — a decision cited by
  number with no `Decision` word anywhere near it, all of them in a sentence unpacking a plural.
  `DEC-01-01` made every mention one greppable token before anything was rewritten, which is what
  the spec's sentinel gate was for and where the owner moved the burden when the sentinels were
  dropped.
- **It also discharged the tombstone condition.** `ledgers.md` §2 keeps retired entries *while the
  ledger is numbered*; six were vacuumed once that stopped being true, and the rule now says so.

### T-NAMESPACE-CLONE — a live platform table in a namespace travels to the project as a copy — PAID by a written practice

- **Where:** the project environment's construction — a deep clone taken before the run
  (`../internals/project_sandbox_env.md`) — and every namespace that hands a project a
  platform table.
- **What was owed:** the pattern written down. A live table placed in a namespace as a
  plain field is *copied* into the project's clone, so the program assigns its handlers
  into the copy while the dispatcher reads the original, and **neither side raises** —
  nothing is nil, nothing is logged, the handlers simply never run. It cost an hour of
  on-device debugging to find. `compy.input` already dodged it by holding the surface
  up-value behind `__index`, and `serial` was later built the same way per its author,
  assignment to the table itself included (that surface is not in this repository); what was missing was the rule stated once, where the next person
  to add a namespace field would meet it.
- **Paid by:** `../conventions/architecture_principles.md`, *"A Namespace Hands Out Live
  Tables by Reference, Never by Value"*. It is filed as a **suggested practice rather than
  a decision** (owner, 2026-08-30) on two grounds: the rule is generic — it binds any
  subsystem handing a project a live table, not the input surface — and a table that is
  genuinely a snapshot may be passed by value quite correctly, so the right instrument is
  a practice with a question attached (*does anyone write to this after the run starts?*),
  not a ruling. `decisions/input.md` D-FROZEN-SHELL carries the one-line pointer to it, which
  is where `serial`'s author suggested the note belonged; D-ONE-STATE-ASK records the same
  hazard met from the other direction (`love.state.user_input` read inside a project is
  always `nil`).
- **Retired 2026-08-30.** Nothing outstanding: the obligation was documentation, and the
  code already implements the pattern in both places it applies.
