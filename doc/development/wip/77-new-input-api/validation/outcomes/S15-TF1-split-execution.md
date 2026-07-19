# S15-TF1 — split-execution report (Sonnet worker)

Executed per `validation/prompts/S15-TF1-split-execution.md`. Split
`tests/input/input_contracts_spec.lua` (2322 LoC, one top-level describe with
19 flat `it`-sequence describes) into 9 new files under `tests/input/`, then
removed the original with `git rm`. `tests/helpers/input_fixture.lua`,
`tests/input/project_open_liveness_spec.lua`, and `src/` were not touched.
Not committed — left for the orchestrator.

## Per-file standalone results (`busted tests/input/<file>`)

| # | file | S | F | E | P |
|---|------|---|---|---|---|
| 1 | `input_routing_spec.lua` | 9 | 0 | 0 | 4 |
| 2 | `input_shortcuts_click_spec.lua` | 7 | 0 | 0 | 0 |
| 3 | `input_widget_lifecycle_spec.lua` | 9 | 0 | 0 | 0 |
| 4 | `input_nfr_forward_spec.lua` | 8 | 0 | 0 | 0 |
| 5 | `input_dispatch_chain_spec.lua` | 25 | 0 | 0 | 0 |
| 6 | `input_widget_io_spec.lua` | 27 | 0 | 0 | 0 |
| 7 | `input_route_lifecycle_spec.lua` | 8 | 0 | 0 | 0 |
| 8 | `input_cursor_text_spec.lua` | 12 | 0 | 0 | 0 |
| 9 | `input_reconfigure_spec.lua` | 15 | 0 | 0 | 0 |
| — | **sum** | **120** | **0** | **0** | **4** |

Every file was green **standalone** on the first run after assembly (after one
self-inflicted issue fixed pre-commit, see "Issue found" below) — no
cross-`it` state leaked from a sibling file or a deleted describe; each
file's `setup(F.setup)` / `teardown(F.teardown)` / `before_each(F.reset)`
triple is sufficient in isolation.

Matches the original's standalone baseline exactly
(`busted tests/input/input_contracts_spec.lua` = 120/0/0/4, captured before
the split as a control).

## Full-suite result

```
busted tests
815 successes / 0 failures / 0 errors / 4 pending
```

Identical to the pre-split baseline (also 815/0/0/4, same 4 pending items —
now all four physically live in `input_routing_spec.lua`, same test names,
same `describe`/`it` text):

- `routing: console mode routes the key release to the console`
- `routing: editor mode routes the pointer to the editor`
- `routing: editor search routes keys and text to the search widget`
- `routing: project run touch reaches the active route`

## Tag-count diff

`grep -ohE '#[a-zA-Z0-9_]+' <files> | sort | uniq -c`, original (git HEAD)
vs. the 9 new files:

| tag | before | after | delta | why |
|---|---|---|---|---|
| `#input` | 1 | 9 | **+8** | expected — one top-level describe per new file, each tagged `#input` (contract requirement) |
| `#m5c` | 2 | 3 | **+1** | expected — the prompt's explicit instruction for the dispatch-chain split: "Keep the `#m5c` tag on BOTH" files 5 and 6 (mechanics + outputs halves of the same original describe) |
| `#77` | 8 | 8 | 0 | unchanged |
| `#1` | 1 | 1 | 0 | unchanged |
| `#2` | 1 | 1 | 0 | unchanged |
| `#disputable` | 1 | 1 | 0 | unchanged |
| `#editor` | 1 | 1 | 0 | unchanged |
| `#got` | 3 | 3 | 0 | unchanged |
| `#legacy` | 1 | 1 | 0 | unchanged |
| `#m7` | 2 | 2 | 0 | unchanged |
| `#m8` | 1 | 1 | 0 | unchanged |
| `#order` | 8 | 8 | 0 | unchanged |
| `#play` | 1 | 1 | 0 | unchanged |
| `#seen` | 12 | 12 | 0 | unchanged |

All 19 inner describes/its kept their exact original tags (`#m5c #m7 #m8
#legacy #disputable #play #editor #order #seen #got #1 #2 #77`, and the
literal `(#disputable))` inline form on the "global shortcuts" describe name)
byte-for-byte. Only the two accounted-for deltas above are non-zero.

## Issue found and resolved (standalone-only, self-inflicted, not a leak)

While drafting `input_nfr_forward_spec.lua`'s theme-specific header line I
wrote a corpus pointer that happened to contain the literal string
`(feature #77)`, inflating the `#77` tag count from 8 to 9 on first pass. This
was **not** a cross-`it` dependency or test-logic issue — it was an artifact
of my own added prose in the condensed header (the template asks for "one
theme-specific line + corpus pointer" per file, which is new text, not moved
text). Caught by the tag-count diff step of the self-verification protocol
(step 3), before the tag mismatch could be mistaken for a preservation bug.
Fixed by rewording the line to "(this feature)" — no functional content lost,
`#77` count restored to 8. Re-ran the file standalone (8/0/0/0, unchanged)
and the full suite (815/0/0/4, unchanged) after the fix.

## Decomposition notes (for the record)

- Files 5 & 6 split the flat 883-LoC `the four-tier dispatch chain #m5c`
  describe at the `-- ---- widget outputs` marker, exactly as specified.
  Each half's own top describe carries **both** the literal name given in the
  prompt and `#input` (the general per-file contract), e.g.
  `describe('dispatch chain: tier mechanics #m5c #input', ...)` — satisfying
  the prompt's literal naming instruction and the "`#input` on each new top
  describe" hard-contract line simultaneously. The mechanics/outputs bodies
  were dedented by one level (4→2 spaces) since they now hang directly off
  the file's single top-level describe instead of two nested describes as in
  the original — a whitespace-only change, no logic/assertion/name edits.
- `make_editor_session` (with its `TU`, `mock`, `codesnippets`,
  `editor_session` requires) landed in file 3
  (`input_widget_lifecycle_spec.lua`) only, per the prompt's explicit
  instruction — it is used solely by `#editor block navigation at the limit`.
- Per-file requires beyond `local F = require('tests.helpers.input_fixture')`
  were added only where the moved code actually calls them, verified by grep
  before and LSP diagnostics after: `mock` (`tests.mock`) in files 2, 3, and 6
  (`mock.keystroke` calls); `TU` (`tests.testutil`) plus
  `tests.helpers.codesnippets` / `tests.helpers.editor_session` in file 3
  only. `Controller`, `Log`, `Cursor`, `noop`, `love`, etc. are globals
  established by `F.setup()` (which requires the real `src/` controller/model
  modules); no split file needs to require them directly, matching the
  original file's own behaviour.
- Bucket-header comments (`-- ====` blocks marking Bucket A/B/C/D and the
  dispatch-chain intro) travelled with the describes they introduce: Bucket A
  → file 1 (its content is specifically about the mode×channel routing grid);
  Bucket D → file 4 (before `provisional...`); Bucket C → file 4 (before
  `mechanism / NFR guards...`); Bucket B → file 4 (before `forward
  contracts...`); the dispatch-chain intro → duplicated into both file 5 and
  file 6, since it explains the whole `#m5c` chain both halves are part of.
  All `REVIEW`/`REVIEW/DOC`/`OPEN` inline comments stayed attached to the
  exact lines/tests they annotate — none were dropped or reworded.

## LSP diagnostics (post-split, `sleep 1` before each query)

All 9 files: zero `ERROR`-severity diagnostics, zero unused-require warnings
(confirming each file's requires are exactly used, no more, no less). The
warnings/hints present are pre-existing patterns carried over verbatim from
the original file, not introduced by the split:

- `missing-parameter` on `pending('...')` calls (files 1) — the LSP doesn't
  know busted's 1-arg `pending` overload; same false positive the original
  file already had.
- `duplicate-set-field` / `need-check-nil` on repeated `Log.warn = ...` /
  `love.keypressed = ...` save-restore idioms (files 2, 3, 4, 5, 8, 9) and on
  `Controller.project_input.framework_handlers.keypressed['a'] = ...` (file
  5) — the LSP flattens per-`it` reassignments of the same table field across
  the file into one static view; pre-existing pattern, not new.
- `undefined-field` on `assert.has_no.errors` (files 5, 6) — `luassert`'s
  `has_no.errors` chain isn't in the LSP's stub type, same as in the original
  file.
- One `trailing-space` hint each in files 1 and 3 (blank-but-for-whitespace
  lines carried over from the original verbatim).
- `input_route_lifecycle_spec.lua`: **zero** diagnostics of any kind.

None of these indicate a missing require, an undefined global, or dropped
logic.

## Confirmation

- Original removed: `git rm tests/input/input_contracts_spec.lua` (`git
  status` shows `D  tests/input/input_contracts_spec.lua`).
- 9 new files present under `tests/input/`, none tracked yet (orchestrator
  commits).
- `tests/helpers/input_fixture.lua`, `tests/input/project_open_liveness_spec.lua`,
  and everything under `src/` are unmodified (`git status` confirms no other
  changes beyond the 9 additions + 1 deletion in `tests/input/`).
- Not committed.
