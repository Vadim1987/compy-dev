# M4-0-01 — M4 front-tests (corrective) — outcome ledger

_Filled by the implementation agent (Claude Opus 4.8): 2026-06-28._

**Status:** ✅ implemented — awaiting human approval
**Spec implemented:**
[`../../design/spec/M4-0-01-front-tests.md`](../../design/spec/M4-0-01-front-tests.md)
(supersedes
[`../../design/spec/M4-0-characterization-net.md`](../../design/spec/M4-0-characterization-net.md))

---

## What changed

The feature-global characterization net was replaced by a small,
routing-level front-test suite. `tests/input/characterization_spec.lua`
was deleted and rewritten as `tests/input/input_routing_spec.lua`:

- **Removed** (pinned non-obligations / re-tested ground / tautologies):
  the example-BC rows (tixy/balloons/turtle/maze submit + `is_empty`),
  the alias trio (`session.press` → self-installed lambda), and the
  reimplemented keyboard once-per-press debounce (tested a test-local
  `held_keys`, not production).
- **Kept + reframed**: the editor vertical block-nav at-limit row (drives
  `EditorController` via `editor_session.lua`, unchanged); its comment now
  states it exercises block-nav **indirectly** through the at-limit
  condition.
- **Added Group 1 (must-not-degrade, green now):** each drives a real
  production `love.handlers.*` slot and asserts the **real** consumer
  received — a real `ConsoleController` (and its `EditorController`) is
  built the way `main.lua` wires it, and the input singleton is a real
  `UserInputController`. No hand-rolled lambdas as consumers.
- **Added Group 2 (to-be-implemented):** four `pending(...)` carrying
  greppable `DEFERRED (0.1.0-m4)` markers — project events reach the
  project sink, slot ownership/restoration, legacy native coexistence,
  and `isrepeat` threading.

## Files changed

- `tests/input/characterization_spec.lua` — **deleted**.
- `tests/input/input_routing_spec.lua` — **new** (the rewritten suite).
- No production code (`src/`) changed.

## Verification

- **Full suite:** `busted tests` →
  **708 successes / 0 failures / 0 errors / 4 pending**
  (the 4 pending are the Group-2 forward tests).
- **New file:** `busted tests/input/input_routing_spec.lua` →
  7 successes / 4 pending.
- **lua-language-server diagnostics** on the new file: none.
- All lines ≤ 64 chars; no test description contains a milestone/sprint id
  (`M4`, `D-9`, "characterization net" are absent from all descriptions —
  the `DEFERRED (0.1.0-m4)` release marker lives only in comments, as the
  spec mandates).

### Teeth (perturb → red → restore), demonstrated on production code

Both perturbations were applied to `src/controller/controller.lua`, the
test observed to go red, then the source restored (src is clean — verified
via `git status`):

| Test | Perturbation | Result |
|---|---|---|
| `active overlay does not also fire native` | overlay branch also calls the native `love.keypressed` slot | red (`native` = 1, expected 0) |
| `console text reaches the console input` | drop the no-overlay textinput fall-through | red (input stayed empty, expected `Z`) |

## Acceptance check

- [x] `characterization_spec.lua` reduced to front-tests; example-BC rows,
  alias trio, reimplemented debounce removed; file renamed to a behaviour
  name (`input_routing_spec.lua`).
- [x] Group 1 (+ editor block-nav) green against current code; each driven
  through `love.handlers.*` and asserting a real controller received.
- [x] Group 1 has teeth — perturb→red→restore shown for no-double-delivery
  and one consumer-receive test.
- [x] Group 2 carried `pending` with `DEFERRED (0.1.0-m4)` markers; suite
  green; pre-commit hook (`just ut_all`) passes.
- [x] `input_session.lua` consumed (no inlined copy — the `-0` dead-code
  finding is closed); `mock.textinput` exercised (console-text proof) and
  `keystroke` exercised (block-nav row).
- [x] No `src/` change; no milestone/sprint id in any test description.

## Notes / judgement calls

- **Real `ConsoleController` under mock_love.** Group 1's "real consumer
  received" requirement meant building a real Console MVC without a
  display. This needed a modest mock surface added **in the spec file
  only** (no helper, to stay within the spec's file list): `love.audio`,
  `love.paths`, an enriched `love.graphics` (canvas/font/setCanvas…), a
  stub monospace font, and the real `conf.colors`. The console REPL is
  suppressed in `'running'` state by design, so the console proofs run in
  `'ready'` (the REPL mode).
- **Receipt assertion style.** Console-text uses an **observable effect**
  (the console input model gains the char). The other smokes spy-record on
  the real controller instance's method (record-only, auto-restored after
  each test): this proves the gate delivered to *that* real instance
  without depending on downstream view/buffer state, and still has teeth
  (perturbing the gate makes them red). This is deliberately distinct from
  the deep editor behaviour, which `editor_spec_fwd` + the block-nav row
  already cover.
- **`input_session.lua` kept intact (not trimmed to 2 methods).** It is
  now consumed (the dead-copy finding is closed). Its `release` /
  `repeat_press` methods are unused by the live Group-1 tests but are the
  cohesive driver surface the Group-2 conversion (gate rewrite) will use
  (`repeat_press` is named by the `isrepeat` pending). Trimming then
  re-adding would be churn; left as the complete driver.
- **`mock.textinput` / `keystroke` opts.** `mock.textinput` is exercised
  by the console-text proof; base `keystroke` by the block-nav row. The
  `isrepeat` / `scancode` opts remain retained but are **not** exercised
  live yet — the path drops `isrepeat` today (Group-2 `pending`); the gate
  rewrite that threads it converts that pending to a live test which
  exercises the opt. Asserting it now would be a no-op.

## Surfaced gaps

- None blocking. As the spec's own Notes record: the **M4 implementor
  prompt** (`implementation/prompts/M4.md`) and `process.md §9.2` describe
  M4 as black-box; with Group-2 carried as red/pending front-tests, M4 is
  now test-first. Those reconciliations are explicitly out of this slice's
  scope (follow-ups), not introduced here.
