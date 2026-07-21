# Sonnet worker prompt — S18 revalidation mechanical evidence sweep

You are a Sonnet worker under the session18 orchestrator (feat #77, LÖVE2D project at `/repo`,
cwd `/repo`). Purely mechanical **evidence-gathering** — no code edits, no judgment calls, no
fixes. Report facts; where a claim fails, say so with the exact file:line. Write your deliverable
to `doc/development/wip/77-new-input-api/validation/outcomes/S18-revalidation-evidence.md`.

## Tooling (important)
- The `lua-lsp` MCP server (defs/refs/diagnostics over a real AST of `/repo`) is available and is
  the **correctness** tool for "who references symbol X" / "does file Y type-check". Use grep to
  find candidates, then LSP `references`/`diagnostics` to confirm. After any `.lua` edit `sleep 1`
  before querying — but you are NOT editing, so just query freely.
- Lua refs can be incomplete (dynamic language) — for the "deleted symbol = zero refs" checks,
  use **both** grep across `src/` + `tests/` **and** LSP, and report if they disagree.

## The task — verify session17's R4/R5 shipped output against the commissioning spec

Commissioning docs (read them for the expected end-state):
- `doc/development/wip/77-new-input-api/validation/reviews/delta-design-input-api.md`
- `doc/development/wip/77-new-input-api/validation/reviews/delta-spec-input-api.md`
Session17 report (what it claims it did): `implementation/sessions/session17/report.md`.

Produce a verdict (CONFIRMED / FAILED / DISCREPANCY + evidence) for each:

### A. Deleted symbols — must be zero refs in src/ and tests/ (grep AND LSP)
`framework_handlers`, `install_tier1`, `_generic_callback`, `_sink`, `shown_widget`,
`run_hook`, `framework_submit`, `framework_cancel`, and the `ProjectInputController.natives`
field (delta-spec §2/§5 say all deleted). Report any surviving reference with file:line.

### B. Vocabulary sweep completeness (delta-design vocabulary table)
Retired terms that must NOT survive in `src/**/*.lua` comments or the persistent docs corpus
(`doc/input_api.md`, `doc/development/internals/user_input.md`,
`doc/development/technical_debt/input.md`, `doc/development/decisions/input.md`):
`sink`, `singleton`, `tier` (as in tier-1/tier-3/framework tier), `framework handler(s)`,
`generic callback`, `proxy`. Also: the combo table must be named `shortcuts` (not `handlers`)
and the tier-3 slot `hooks` (not `on_key_pressed`/`on_text_input`/`on_key_released`). Report
each surviving hit with file:line and a one-line "is this a real miss or a legitimate use"
note (e.g. `love.handlers` is LÖVE's own and legitimate; "singleton" in an unrelated subsystem
is out of scope — only the input domain matters).

### C. Acceptance criteria present as tests
`tests/input/input_redesign_ac_spec.lua` — confirm it contains tests anchoring the 10 acceptance
criteria in delta-spec §7 (AC1–AC10). List which AC each test maps to; flag any AC with no test.
Run `busted tests/input/input_redesign_ac_spec.lua` and report the pass/pending/fail count.

### D. Persistent-docs resync (spot-check, not full read)
`doc/input_api.md`, `doc/development/internals/user_input.md`,
`doc/development/technical_debt/input.md`: confirm each uses the new vocabulary
(`shortcuts`/`hooks`/`callbacks`/`widget`) and does not still describe the deleted tier-1 /
framework-tier / sink model as current. Quote one representative line from each as evidence.

### E. Open-issue code facts (verify precisely — this is the session's crux)
1. `src/controller/userInputController.lua:725` — confirm `if love.state.app_state == 'editor'
   then … else … end` exists; describe exactly what differs between the two branches (key
   handler call order; presence of `modify()`; presence of `_submit_default`/`_cancel_default`).
   Confirm the standing REVIEW at `:724`.
2. Confirm `_submit_default` and `_cancel_default` are defined (report their line numbers) and
   are called ONLY in the `else` (non-editor) branch.
3. The editor fall-through constraint: `src/controller/editorController.lua` — confirm `load()`
   (~:716) handles plain Escape via `load_selection()` and does NOT call `block_input()`, so
   Escape passes through (~:803-804 `if passthrough then input:keypressed(k)`) to the widget.
   Confirm editor has Enter/Escape handling in normal/reorg/search modes (report line numbers).
   This is the constraint that forces SOME scoping today. Quote the relevant lines.
4. Who sets `love.state.app_state`, and to what values? Grep `app_state` across `src/` and list
   every assignment site (file:line = value) and every read site. This tells us how coupled the
   fork is to global state.

### F. Suite baseline
Run `busted tests` and report the exact count line. Expected 827/0/0/4.

## Output format
One markdown file at the path above: a section per A–F, each with verdict + evidence
(file:line, quoted lines, grep/LSP agreement). Keep it terse and factual. End with a
"DISCREPANCIES / SURPRISES" list of anything that did not match the commissioning spec or the
session17 report — that list is the highest-value part for the orchestrator.

Do not fix anything. Do not edit files. Report only.
