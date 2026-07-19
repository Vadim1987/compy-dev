# TF1 — proposed cognitive decomposition of input_contracts_spec.lua

_Session15, 2026-07-19. Design proposal (owner-gated before execution). Source:
`tests/input/input_contracts_spec.lua` (2317 LoC, 19 top-level describes, all flat
`it`-sequences — no nested describes). Contract: full suite stays 815/0/0/4, tags and
the 4 pendings preserved, every split file runs standalone-green._

## Principle
Split along **cognitive seams** (what a group of tests *targets*), not merely tag or
describe boundaries. Keep each top-level describe atomic **except** the 883-LoC `#m5c`
"four-tier dispatch chain", which is two distinct concepts and is split at its own
`-- ----` seam (`widget outputs`, spec line ~1208). One decisive safety gate per file:
`busted tests/input/<file>` green in isolation (proves no cross-`it` state coupling that
`F.reset` doesn't clear).

## Proposed files (9)

| # | file | source describes (spec lines) | ~LoC | cognitive theme |
|---|------|-------------------------------|------|-----------------|
| 1 | `input_routing_spec.lua` | console / editor / editor-search / project routing (99–284) | 185 | the exclusivity invariant: each event reaches exactly one mode-fixed route |
| 2 | `input_shortcuts_click_spec.lua` | global shortcuts; framework click; project-stop return; legacy text (285–434) | 150 | cross-cutting delivery paths distinct from mode routing |
| 3 | `input_widget_lifecycle_spec.lua` | widget activation/reset; hidden widget; editor block-nav (435–579) | 145 | show/hide/reset lifecycle of the widget (carries `make_editor_session`) |
| 4 | `input_nfr_forward_spec.lua` | provisional; mechanism/NFR guards; forward contracts (580–798) | 218 | the non-PRESERVE buckets D/C/B: characterization, NFR guards, pending forward contracts |
| 5 | `input_dispatch_chain_spec.lua` | four-tier dispatch chain — mechanics half (799–1207) | 408 | tier order/consume/fall-through, combo tables, signatures/proxy, defaults+sink, tier-3 callbacks, native install, slot assignment `#m5c` |
| 6 | `input_widget_io_spec.lua` | dispatch chain — outputs half (1208–1663) | 455 | widget output slots (Decision 5), highlighter, submit/cancel call-order, validator, Enter/Escape semantics `#m5c` |
| 7 | `input_route_lifecycle_spec.lua` | route connection lifecycle (1664–1841) | 178 | route connect/disconnect on run/stop/inspect; before_exit `#m5c` |
| 8 | `input_cursor_text_spec.lua` | cursor and text surface (1842–2006) | 165 | get/set_cursor, set_text control surface `#m7` |
| 9 | `input_reconfigure_spec.lua` | live reconfigure/clear + continuous-session (2007–2317) | 310 | live `configure`/`clear` on active/hidden session `#m7`; re-arm idiom `#m8` |

## Mechanical rules for the cut (for the Sonnet executor)
- Each file: shared require block (`F`, `TU`, `mock`, `codesnippets`, `editor_session`
  as needed — replicate to keep files standalone), then
  `describe('<theme> #input', function() setup(F.setup); teardown(F.teardown);
  before_each(function() F.reset() end) ... end)`. **Top describe keeps `#input`**;
  inner tags (`#m5c`/`#m7`/`#m8`/`#legacy`/`#disputable`/`#play`/`#editor`) preserved
  verbatim on the same describes/its they annotate today.
- The file-head vocabulary/invariant preamble (spec lines 1–49) is condensed into a
  short shared header per file (routing invariant + ROUTE/WIDGET/SINK + key-vs-text
  note), each pointing at the corpus — NOT copied whole. The owner's in-code `REVIEW`
  remarks travel with the tests/lines they annotate (never dropped, never swept).
- `make_editor_session` (spec lines 64–71) → file 3 only (sole consumer: block-nav).
- The 4 pendings all live in today's file: search (206), and three inside routing/NFR —
  they must remain pending in their destination files.

## Open call for the owner
1. **File count / the `#m5c` split (files 5+6).** Recommended: split the 883-LoC chain
   into mechanics (5) + outputs/submit-cancel (6) — 883 LoC is not human-reviewable as
   one unit and the halves are distinct concepts. Alternative: keep it whole (8 files
   total) if you'd rather not create a describe boundary mid-milestone.
2. **Naming scheme.** Proposed `input_<theme>_spec.lua`. Adjust freely.
3. **#m8 placement.** Folded into file 9 (with #m7 reconfigure); could stand alone.
