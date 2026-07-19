# RS1 — normalize persistent-doc citations to repo-root-relative (Sonnet worker prompt of record)

You are a Sonnet mechanical worker in the compy LÖVE2D project (`/repo`, cwd). Under an Opus
orchestrator. **Do NOT commit** — the orchestrator reviews and commits. Write a deliverable report.

## Task (one mechanical transform)

In `tests/` and `src/` (`.lua` files only; **exclude** `src/examples/**`, `src/vadexamples/**`),
every **bare** citation of a persistent input-corpus doc must become **repo-root-relative**:

- `decisions/input.md`        → `doc/development/decisions/input.md`
- `internals/user_input.md`   → `doc/development/internals/user_input.md`
- `internals/console.md`      → `doc/development/internals/console.md`
- `technical_debt/input.md`   → `doc/development/technical_debt/input.md`
- (any other `internals/*.md`, `decisions/*.md`, `technical_debt/*.md` bare ref) → same rule

Baseline inventory (grep, 2026-07-19): **210 bare refs across 11 files** —
`tests/mock.lua`, `tests/input/keys_pressed_spec.lua`, `tests/helpers/input_fixture.lua`,
`tests/input/input_contracts_spec.lua`, `src/view/input/userInputView.lua`,
`src/model/input/userInputModel.lua`, `src/util/key.lua`, `src/controller/consoleController.lua`,
`src/controller/projectInputController.lua`, `src/controller/userInputController.lua`,
`src/controller/controller.lua`. (10 refs are already `doc/development/...` — leave those.)

## Hard constraints

- **Do NOT double-prefix**: a ref already written `doc/development/decisions/input.md` stays as-is.
- **Comment/prose only.** These refs live in `--` comments and docstrings. Do not touch any string
  literal, require path, or actual code. If a `(decisions|internals|technical_debt)/…md` token ever
  appears in live code (it should not), skip it and report.
- **Only the persistent-corpus doc paths.** Do NOT touch: interim/ephemeral refs (`M2-human-review.md`,
  `reviews/…`, `design/…`, `M#`, `0.1.0-m#`, `E30`, `Scope item …`, `spec §…`), `{badspecref: …}`
  wrappers around non-corpus targets, or `doc A` (already handled). Only bare corpus-doc filepaths.
- **`{badspecref: internals/…}` etc.:** if a bare corpus path sits inside a `{badspecref: …}` wrapper,
  normalize the path but leave the wrapper text otherwise intact.
- Suite must stay **815 / 0 / 0 / 4** (`busted tests`). Comment-only edits — a count change means you
  touched code; STOP and report.

## Method (be precise, not blind)

Prefer a verified pattern over a blind global sed. Suggested: grep each file for the bare forms,
confirm each hit is in a comment, apply the prefix. After editing `.lua`, `sleep 1` then run
`mcp__lua-lsp__diagnostics` (a DEFERRED MCP tool — `ToolSearch` `select:mcp__lua-lsp__diagnostics`
first) on the file to confirm no new diagnostics vs. a pre-edit baseline. Re-grep at the end: **zero**
bare corpus refs should remain in tests/src; the `doc/development/...` count should rise by ~210.

## Deliverable

Write `doc/development/wip/77-new-input-api/validation/outcomes/RS1-normalize.md`: per file, count of
refs normalized; final grep proof (bare=0, root-relative count); `busted` result; any skip/anomaly.
Do NOT commit. Report a concise summary to the orchestrator.
