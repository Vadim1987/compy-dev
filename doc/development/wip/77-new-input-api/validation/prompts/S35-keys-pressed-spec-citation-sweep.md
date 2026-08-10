# S35 — citation sweep after `keys_pressed_spec.lua` is renamed and emptied

**Model: Sonnet (passed explicitly). Read-only investigation — write NOTHING except your
deliverable file.** You are a sub-agent of the compy `/repo` session executing step P14c of the
`keys_pressed` dissolution. You do not inherit the parent's context; everything you need is here.

## What just happened in the tree

1. `tests/input/keys_pressed_spec.lua` was **renamed** to
   `tests/input/input_combo_serialisation_spec.lua` (`git mv`, already done).
2. That file previously held **two** `describe` blocks. The first — the held-key set's lifecycle
   (`adds key on keypressed`, `removes key on keyreleased`, `tracks multiple held keys`, `keeps lr
   variants distinct`) — was **deleted**. Only the **combo serialisation** block survives.
3. The file's whole startup-wiring preamble was deleted with it: it no longer calls
   `Controller.setup_callback_handlers`, no longer installs `love.handlers`, and no longer holds
   `kp_handler` / `kr_handler`. The survivors call `Controller.combo_string` directly.
4. Earlier in the same step, `compy.input.keys_pressed`'s own spec was deleted from
   `tests/input/input_events_spec.lua`, and four held-key NFR guards were deleted from
   `tests/input/input_nfr_mechanism_spec.lua`.

## Your task — find every reference that these four facts falsify

Sweep **the whole repo** (`src/`, `tests/`, `doc/`, `agents/`, and any other tracked directory —
but **skip** `doc/development/wip/`, which is this feature's own scratch and is handled by the
parent, and **skip** the three nested example repos `src/examples/{balloons,maze,keyboard}`).

Report anything that:

- **names the file** `keys_pressed_spec` (any form: with or without `.lua`, with or without the
  `tests/input/` prefix, inside prose, inside a code comment, inside a table cell);
- **names one of the deleted test cases** by its description, or describes the file/suite as
  covering the held-key set's lifecycle;
- **cites the file as an example of the production startup wiring** (`setup_callback_handlers`),
  which is the claim fact 3 above falsifies even without the rename;
- **names `compy.input.keys_pressed` or `Controller.keys_pressed` as something the SUITE
  asserts** — the field still exists in `src/` at this moment (it is removed in the next step,
  P14d), so a reference to the *field* in production code is NOT a finding; a reference to the
  *tests* that covered it is.

For each finding report: `path:line`, the exact text, which of the four facts falsifies it, and a
**suggested minimal correction** (one line — do not rewrite the passage).

Also report explicitly, as a separate section, **anything you checked and found already correct**,
so the parent does not re-derive the sweep.

## How to search — both tools, cross-checked

- **grep is the completeness backstop and your primary tool here**, because most of these
  references are in **prose and comments**, which no language server sees.
- The **`lua-lsp` MCP server** is available (defs / refs / diagnostics / hover over a real AST of
  the `/repo` workspace). Use it to confirm that nothing in Lua *code* still references the removed
  symbols — but do **not** trust it alone: this repo has a standing finding that LSP references
  miss occurrences routed through metatable `__index` dispatch on string keys, and it missed 4 of
  22 occurrences in an earlier session. After any `.lua` edit, `sleep 1` before querying it (it
  re-indexes). You are read-only, so you will mostly be querying, not editing.
- Search for the **stem** (`keys_pressed`), not only whole identifiers, and search
  case-insensitively for prose forms ("pressed-keys table", "held-key set", "held key set").

## Deliverable

Write your report to
`/repo/doc/development/wip/77-new-input-api/validation/outcomes/S35-keys-pressed-spec-citation-sweep.md`

Markdown, structured as: **Findings** (a table, most consequential first), **Checked and already
correct**, **What I could not determine**. Be concrete and quote the text. Do not edit any file
other than your deliverable, and do not run `git` write commands.

## One standing rule that applies to you

A dangling citation is **worse than none**, because it reads as authoritative — especially in
`doc/`, which is the persistent corpus and outlives this feature's working tree. Judge each
reference by whether a reader following it would find what it promises.
