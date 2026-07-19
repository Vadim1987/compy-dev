# Sonnet worker — execute the TF1 split of input_contracts_spec.lua

## Environment & tools
Working dir `/repo`. LÖVE2D/Lua project. Tests run with `busted` (uses mock_love, no
display). The `lua-lsp` MCP server (defs/refs/diagnostics over a real AST of `/repo`) is
available — use it to confirm a symbol/require is actually used before dropping it, and to
check no undefined global sneaks in; grep is your completeness backstop. After any `.lua`
edit, `sleep 1` before calling LSP diagnostics (the server re-indexes).

## Task
Split `tests/input/input_contracts_spec.lua` (~2322 LoC, ONE top-level
`describe('input contracts #input', ...)` containing 19 flat `it`-sequence describes) into
**9 new spec files** under `tests/input/`, then delete the original. This is a
**behaviour-preserving** cut — no test logic changes.

**HARD CONTRACT (the whole point — verify at the end):**
- Full suite `busted tests` stays **815 successes / 0 failures / 0 errors / 4 pending**.
- The 9 new files together account for **120 successes + 4 pending** (what the original
  file has today: `busted tests/input/input_contracts_spec.lua` = 120/0/0/4).
- **Every tag preserved** verbatim (`#input` on each new top describe; inner
  `#m5c #m7 #m8 #legacy #disputable #play #editor #order #seen #got #1 #2 #77` on the exact
  describes/its they annotate today).
- The **4 pendings** survive as pendings in their destination files.
- **Every new file passes standalone**: `busted tests/input/<file>` green in isolation.
  This is the decisive gate — a file that passes in-suite but fails alone has an
  unsatisfied cross-`it` dependency; report it, do not paper over it.

## The decomposition (locate describes by NAME; line ranges are guidance only)

| # | new file | describes to move (in order) |
|---|----------|------------------------------|
| 1 | `input_routing_spec.lua` | `routing: console mode`, `routing: editor mode`, `routing: editor search`, `routing: project run` |
| 2 | `input_shortcuts_click_spec.lua` | `global shortcuts do not consume the key`, `framework click detection`, `project stop returns input to the console`, `legacy text solicitation #legacy` |
| 3 | `input_widget_lifecycle_spec.lua` | `widget activation and reset`, `a hidden widget does not consume`, `#editor block navigation at the limit` |
| 4 | `input_nfr_forward_spec.lua` | `provisional — expected to change, no mandate`, `mechanism / NFR guards — not behaviour`, `forward contracts (pending until implemented)` |
| 5 | `input_dispatch_chain_spec.lua` | `the four-tier dispatch chain #m5c` — **MECHANICS HALF ONLY**: from the first `it` through the last `it` BEFORE the `-- ---- widget outputs (...Decision 5)` marker (last mechanics it: `assigning an allowed callback slot is accepted`) |
| 6 | `input_widget_io_spec.lua` | `the four-tier dispatch chain #m5c` — **OUTPUTS HALF**: from the `-- ---- widget outputs` marker (first it: `the four widget output fields are assignable`) through the end of the dispatch-chain describe |
| 7 | `input_route_lifecycle_spec.lua` | `route connection lifecycle #m5c` |
| 8 | `input_cursor_text_spec.lua` | `cursor and text surface #m7` |
| 9 | `input_reconfigure_spec.lua` | `live reconfigure and clear #m7`, `continuous-session idiom #m8` |

**Splitting the #m5c chain (files 5 & 6):** it is a flat `it`-list under one describe.
Cut it into TWO describes in TWO files at the `-- ---- widget outputs` comment marker.
File 5's top describe: `describe('dispatch chain: tier mechanics #m5c', ...)`.
File 6's top describe: `describe('dispatch chain: widget outputs and submit/cancel #m5c', ...)`.
Keep the `#m5c` tag on BOTH. Move each half's `-- ----` sub-section comments with their its.

## Structure of every new file
```lua
-- <condensed shared header — see template below>
-- <one theme-specific line + corpus pointer>

local F  = require('tests.helpers.input_fixture')
-- include ONLY the extra module-level requires/locals the moved code actually uses,
-- e.g.  local TU = require('tests.testutil')  /  local mock = require('tests.mock')
--       require('tests.helpers.codesnippets')  /  require('tests.helpers.editor_session')
-- (verify usage by grep/LSP over the moved block; a missing require surfaces as a
--  standalone-run error, an unused one as an LSP warning — aim for exactly-used.)

describe('input contracts: <theme> #input', function()
  setup(function() F.setup() end)
  teardown(function() F.teardown() end)
  before_each(function() F.reset() end)

  -- <the moved inner describe block(s), VERBATIM, with their bucket/section comments>
end)
```

### Condensed shared header template (put atop every file; keep it short)
```lua
-- <THEME> — split from input_contracts_spec.lua (TF1). Routing invariant
-- (doc/development/decisions/input.md, Decision 1): inter-route dispatch is EXCLUSIVE —
-- each event reaches exactly ONE route, fixed by the active screen mode. Vocabulary
-- (doc/development/internals/user_input.md, "Dispatch chain"): ROUTE = consumer an event
-- is dispatched to; WIDGET = a route-managed input surface; SINK = last consumer. Tests
-- assert observable outcomes at public seams, never method-name spies. keypressed fires
-- for every physical key, textinput only for character-producing keys
-- (doc/development/internals/user_input.md, "Data flow").
```

## Rules & cautions
- **Preserve test logic and inner-describe names byte-for-byte.** Only the containing
  top-level describe changes (its name + it hosts setup/teardown/before_each). Do not
  rename its, do not touch assertions.
- **`make_editor_session`** (helper defined near the top of the original, lines ~64–71,
  uses EditorModel/EditorController/EditorView/EditorSession) is used ONLY by
  `#editor block navigation at the limit` → put it in **file 3 only**, and that file
  requires `tests.helpers.editor_session`.
- **The owner's in-code `REVIEW`/`REVIEW/DOC` comments** travel with the lines/tests they
  annotate. Never drop or reword them. The big file-head comment block (original lines
  ~1–49, buckets A/B/C/D prose + the top-of-file REVIEW list) is condensed into the shared
  header above — but any REVIEW remark it contains that is NOT captured by the template
  must be preserved in the file whose tests it concerns (use judgment; when unsure, keep).
- **Do NOT edit** `tests/helpers/input_fixture.lua`, `tests/input/project_open_liveness_spec.lua`,
  or anything under `src/`. Only create the 9 files and delete the original.
- Delete the original with `git rm tests/input/input_contracts_spec.lua` (or plain delete)
  once all 9 files are in place and verified.

## Self-verification protocol (RUN before returning — report actual numbers)
1. `busted tests` → must be exactly `815 successes / 0 failures / 0 errors / 4 pending`.
2. For each of the 9 files: `busted tests/input/<file>` → record `S/F/E/P`. Sum of
   successes across the 9 MUST = 120; sum of pending MUST = 4; all failures/errors = 0.
3. Tag preservation: compare `grep -ohE '#[a-zA-Z0-9_]+' <9 new files>` (sorted, counted)
   against the same over the original at git HEAD (`git show HEAD:tests/input/input_contracts_spec.lua`).
   Counts must match (the top-level `#input` goes from 1 to 9 — account for that in your report).
4. `sleep 1`, then LSP diagnostics on each new file → no errors (unused-require warnings
   OK but prefer to eliminate).

## Deliverable
Write a report to `doc/development/wip/77-new-input-api/validation/outcomes/S15-TF1-split-execution.md`:
per-file standalone S/F/E/P table, full-suite result, the tag-count diff, any
standalone-only failure you hit and how you resolved it (or flagged it), and confirmation
the original was removed. Then return a short summary. Do NOT commit — the orchestrator
verifies and commits.
