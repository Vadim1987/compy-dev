# Input suite validation map

<!-- authored by LLM (Sonnet 5); human-approved: NOT YET. -->

Bridges doc (A)
([`input-contracts.md`](input-contracts.md)) to
[`tests/input/input_contracts_spec.lua`](../../../../../tests/input/input_contracts_spec.lua),
so the suite cleanup that follows this pass is mechanical. One row
per doc-(A) contract. This note does not edit the suite — mapping
only.

Status:
- **present** — the suite already asserts this; cited by line.
- **add** — no coverage yet; a test (or a `pending` naming the
  gap) should be added.
- **pending** — a forward contract, correctly parked as
  `pending(...)` in the suite already.
- **mechanism-guard** — kept, but must be labelled honestly as
  mechanism/NFR, not a behavioural contract.
- **out-of-scope** — foundation work outside #77's blast radius
  (doc A §8); no suite row is expected for it.

---

## Bucket A — PRESERVE (stable-now contracts)

| Contract (doc A ref) | Suite assertion | Status | Note |
|---|---|---|---|
| §5.1 keypressed EXCLUSIVE — console | `input_contracts_spec.lua:89-96` "console mode routes keys to the console" | present | |
| §5.1 keypressed EXCLUSIVE — editor | `input_contracts_spec.lua:98-107` "editor mode routes keys to the editor" | **add** | **Open Opus finding.** The test fires `F.session.type('q')` — `textinput`, not `keypressed` (`tests/helpers/input_session.lua:16` vs `:14`). Editor has **zero** keypressed-EXCLUSIVE regression coverage despite the title/comment claiming sibling coverage across all three routes. Recommended fix (test-only, from `reviews/M4-0-04.md` Finding 1): add a `F.session.press`-driven test (e.g. type then backspace, assert editor shrank / console stayed empty) and retitle the existing test to "editor mode routes text to the editor". |
| §5.1 keypressed EXCLUSIVE — project | `input_contracts_spec.lua:109-119` "project run routes keys to the project" | present | |
| §5.2 textinput EXCLUSIVE — console | `input_contracts_spec.lua:121-125` "console mode routes text to the console" | present | |
| §5.2 textinput EXCLUSIVE — editor | `input_contracts_spec.lua:98-107` (same test as above) | present | Coverage exists but under a mislabeled title; the retitle recommended above (to "...routes text to...") is what makes this row's own status honest. |
| §5.2 textinput EXCLUSIVE — project | `input_contracts_spec.lua:127-135` "project run routes text to the project" | present | |
| §5.3.1 keyreleased EXCLUSIVE — project | `input_contracts_spec.lua:143-150` "the active route receives the key release" | present | |
| §5.3.1 keyreleased EXCLUSIVE — console | none | **add** | No direct assertion that a release reaches console's own route specifically (only project is exercised). Low priority — the held-key-set tests (§6.1 below) touch keyreleased indirectly but don't assert route delivery. |
| §5.3.2 keyreleased — CC-internal editor/search fork gap | none | **out-of-scope** | Doc A §5.3.2 / §8: out of #77 blast radius, carried as foundation for the console/editor migration. No suite row expected under this milestone's scope. |
| §5.4 inspect: console owns the surface | `input_contracts_spec.lua:539-546` | present | Correctly placed in Bucket D (characterize-provisional), not Bucket A — inspect is out-of-radius per doc A §8, not a preserve-forever contract. |
| §3C hidden widget does not consume [owner-minted] | `input_contracts_spec.lua:478-485` "input while hidden does not mutate it" | present | |
| §5.5 mouse EXCLUSIVE — console | `input_contracts_spec.lua:260-265` "a pointer reaches the active route" | present | |
| §5.5 mouse EXCLUSIVE — project | `input_contracts_spec.lua:268-277` "project run routes the pointer" | present | |
| §5.5 mouse EXCLUSIVE — editor | none | **add** | No sibling test for editor; low priority since the production editor widget disables selection (`disable_selection`), making delivery hard to observe without `F.show_selectable_widget`-style scaffolding. |
| §5.6 touch EXCLUSIVE | `input_contracts_spec.lua:285` `pending('touch reaches the active route')` | pending | Correctly parked — no gateway entry for touch today (doc A §5.6); greens when a touch consumer lands. |
| §5.7 wheel — no framework gateway entry | `input_contracts_spec.lua:555-557` | present | Bucket D, correctly characterize-only. |
| §5.8 search sub-widget (keypressed/textinput/keyreleased) | none | **add** | **Explicit gap this map is asked to surface.** Recommended: one `pending('search mode routes keys/text to the search widget')`-style row naming the gap, per `m4-0-04-safety-net-review.md`'s own recommendation — costs one line, closes the loop the original M4-0-04 prompt's "sibling coverage" instruction opened but never finished. |
| §6.3 global shortcuts non-consuming | `input_contracts_spec.lua:205-214` "a shortcut fires but does not consume" | present | |
| §6.3 play mode narrows the shortcut set | `input_contracts_spec.lua:223-242` | present | |
| §6.4 slot restoration on project stop | `input_contracts_spec.lua:345-353` "no project handler remains after stop" | present | |
| §6.5 legacy: submit fills handle and closes | `input_contracts_spec.lua:364-378` | present | |
| §6.5 legacy: guarded refusal warns | `input_contracts_spec.lua:382-392` | present | |
| §6.6 re-activation without force warns + no-op | `input_contracts_spec.lua:403-413` | present | |
| §6.6 re-activation with force reapplies text | `input_contracts_spec.lua:416-421` | present | |
| §6.6 force without text leaves content intact | `input_contracts_spec.lua:424-429` | present | |
| §6.6 fresh activation with no text is empty | `input_contracts_spec.lua:432-439` | present | |
| §6.6 hide deactivates the widget | `input_contracts_spec.lua:444-450` | present | |
| §6.6 oneshot submit deactivates the widget | `input_contracts_spec.lua:455-464` | present | |
| §6.6 four `reset()`/cancel impls + cursor two-layer split | none | **out-of-scope** | Doc A §6.6 / §8: out of #77 blast radius, foundation for the future `configure()`/`clear()`/cursor surface (0.1.0-m7). No suite row expected under this milestone's scope. |
| §6.7 single click confirms after the window | `input_contracts_spec.lua:297-307` | present | |
| §6.7 pointer drift suppresses the single click | `input_contracts_spec.lua:309-317` | present | |
| §6.7 double click calls the project handler | `input_contracts_spec.lua:320-329` | present | |

## Bucket B — IMPLEMENT (forward contracts, carried `pending`)

| Contract (doc A ref) | Suite assertion | Status | Note |
|---|---|---|---|
| §7.1 (I1) project keys reach the project sink | `input_contracts_spec.lua:624-633` `pending('project keys reach the project sink')` | pending | Correctly parked at 0.1.0-m4. |
| §7.2 (I2) stop names the console as restored route | `input_contracts_spec.lua:641-645` `pending('stop names the console as restored route')` | pending | |
| §7.3 (I3) native handler coexists with the sink | `input_contracts_spec.lua:656-667` `pending('a native handler coexists with the sink')` | pending | |
| §7.4 (I4) keypressed path carries the triple | `input_contracts_spec.lua:676-686` `pending('the keypressed path carries the triple')` | pending | |
| §7.4/§9 (I5) `on_key_pressed`/`on_text_entered` exist | `input_contracts_spec.lua:693-703` `pending('on_key_pressed and on_text_entered exist')` | pending | |
| §7.4 (I6) `on_key_pressed` receives `isrepeat` | `input_contracts_spec.lua:711-719` `pending('on_key_pressed receives isrepeat')` | pending | |
| §7.4 (I7) combo handlers dispatch on the combo | `input_contracts_spec.lua:729-736` `pending('combo handlers dispatch on the combo')` | pending | Fresh-vs-repeat keying is a provisional leaning only (doc A §9); not asserted as settled. |
| M6/M7 forward anchor (submit/cancel, `on_limit_reached`, `configure`/`set_text`/cursor, force-vs-configure) | `input_contracts_spec.lua:747-750` `pending(...)` | pending | Deliberately not fleshed out — scope-fenced to m4/m5 (doc A §7 scope note). |

## Bucket C — MECHANISM-GUARD (labelled, not behaviour)

| Contract (doc A ref) | Suite assertion | Status | Note |
|---|---|---|---|
| §6.1 held-key set lifecycle | `input_contracts_spec.lua:163-173,175-186,188-195` | **mechanism-guard** | Correctly asserted, but currently sits in the suite's Bucket-A position (`describe('held-key set lifecycle', ...)`, right after Bucket A's keyboard-exclusive block, with no mechanism label) rather than alongside the labelled `describe('mechanism / NFR guards — not behaviour', ...)` block. Per doc A §6.1 and `m4-0-04-safety-net-review.md`'s bucket-mislabeling finding: relabel/relocate at suite cleanup time — not a coverage gap, a placement/labelling one. |
| singleton identity across show/hide cycles | `input_contracts_spec.lua:590-596` | mechanism-guard | Correctly labelled already (`describe('mechanism / NFR guards — not behaviour', ...)`). |
| no widget model reallocated across cycles | `input_contracts_spec.lua:600-606` | mechanism-guard | Correctly labelled already. |
| §6.2 combo serialisation | none in this file | **out-of-scope** | Covered instead by `tests/input/keys_pressed_spec.lua` (`combo_string` describe block) — a different file, correctly out of this suite's scope. Not a gap; noted so a reader of this map isn't surprised by the absence. |

## Bucket D — CHARACTERIZE-PROVISIONAL (factual today, expected to change)

| Contract (doc A ref) | Suite assertion | Status | Note |
|---|---|---|---|
| §5.4 inspect: the console owns the surface | `input_contracts_spec.lua:539-546` | present | See Bucket A row above — listed once, cross-referenced. |
| §5.7 wheel has no framework gateway entry | `input_contracts_spec.lua:555-557` | present | See Bucket A row above. |
| §5.3.1 note: a release under a widget is not routed | `input_contracts_spec.lua:565-572` | present | Overlay-diversion half of §5.3's "today's mechanism"; correctly separate from the CC-internal-fork half (§5.3.2), which has no suite row (out-of-scope, above). |

## Suite mechanics / rules compliance (not a contract-coverage row)

| Item | Location | Status | Note |
|---|---|---|---|
| `F.reset()` exceeds the 14-line function-body hard limit | `tests/helpers/input_fixture.lua:198-217` (16 code-statement lines) | **add** | **Second open Opus finding** (`reviews/M4-0-04.md` Finding 2), still unfixed. Recommended fix (mechanical, test-only): extract the five `love.keypressed/textinput/keyreleased/mousepressed/mousereleased = Controller._defaults.*` lines into a `restore_native_slots()` helper called from `reset()`. Not a doc-A contract gap — a `agents/rules.md` hard-limit breach in helper code the suite depends on. |

## Not mapped to a doc-A contract (flagged, not resolved here)

| Item | Location | Note |
|---|---|---|
| "editor block navigation at the limit" | `input_contracts_spec.lua:499-521` | Tests editor-internal block-nav behaviour at the buffer limit (FR-7-adjacent), not a doc-A routing contract — the suite's own comment already flags this as indirect/unclear (`REVIEW: THIS TEST IS A MESS`). `m4-0-04-safety-net-review.md` triaged the surrounding `-- REVIEW:` comments but did not conclusively resolve this one. Left open for the human; not a contract this map can dispose of. |
