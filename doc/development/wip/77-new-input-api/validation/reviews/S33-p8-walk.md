# S33 — P8's nine-id walk

**Commissioned by owner ruling, 2026-08-09** (`S27-triage-and-plan.md` §12.2, decision 1):
walk all nine remaining W8 ids rather than re-baselining the step to R079 on the strength of
§6's *"P8 marked done"*. The reasoning was that §6's claim and §4's row **contradict each
other and neither had been checked against the tree**, so trusting either would repeat the
failure the revalidation had just documented. The walk starts from §6's claim as a hypothesis
and confirms or refutes per id.

**Result: all nine are discharged. P8 is done.** §6 was right, §4's row was stale — and so was
one claim of my own, which is the part of this walk worth reading.

---

## Per-id disposition

| id | ask | disposition | evidence, verified in the tree |
|---|---|---|---|
| **R047** | the search-test helper should type character-by-character, not hand a whole string to a `mock.textinput` wrapper | **IMPLEMENTED** | `64ac38d0`. `tests/editor/editor_spec.lua:494-498` — `type_search` now loops `for ch in text:gmatch('.')` calling `controller:textinput(ch)`. The comment above it records why the wrapper was dropped: it was "the handler call with extra steps" |
| **R057** | reorganise the input suite into three explicit groups — inbound events, widget management, reacting to widget events — with `describe` names aligned to the docs | **LANDED** | Every input spec now opens with one of three surface names: `input surface: inbound events — …` (routing, route lifetime, shortcuts and clicks, dispatch, held-key set, combo serialisation, a project stays live), `input surface: widget control — …`, `input surface: widget callbacks`. Verified across all 19 top-level `describe`s in `tests/input/` |
| **R063** | the registration test should also assert the shortcuts actually fire | **DECLINED, with the evidence in the file** | `1aa01572`. `input_events_spec.lua:329-335` carries the reason in place: firing is already covered by the interception matrix above and the 'combo classes' block below, so *"asserting it again here would say it a third time"*. The test itself is deliberately about acceptance and canonicalisation |
| **R064** | rename `input_lifecycle_uniform_spec.lua` — "lifecycle" is ambiguous | **LANDED via the merge** | file is GONE; its content lives in the two merge products |
| **R069** | assert the widget is *not* shown after `suspend()` | **ANSWERED AGAINST THE REMARK** | `53abd09e`. The proposed assertion is **false**: `input_route_lifecycle_spec.lua:315-321` now pins the truth with a comment — *"Unhonoured is not hidden: suspend disconnects the route, so the widget receives nothing, while its own shown flag…"* — and asserts `is_shown()` and `is_widget_visible()` are both **true** |
| **R074** | merge `input_widget_lifecycle_spec.lua` with the reconfiguration suite | **LANDED via the merge** | both `input_widget_lifecycle_spec.lua` and `input_reconfigure_spec.lua` are GONE |
| **R075** | rename — the file says "widgets", others say "widget" | **LANDED** | `input_widgets_callbacks_spec.lua` GONE; `input_widget_callbacks_spec.lua` PRESENT |
| **R078** | another suite duplicates submit/cancel; merge and deduplicate | **LANDED via the merge** | four input specs became two (`input_widget_callbacks_spec.lua`, `input_widget_control_spec.lua`), under the owner's process: inventory → written plan → cold review → execute → cold review |
| **R079** | the file's claims are unreadable: write a companion doc, rewrite the claims, or dissolve it if the logic is phantom | **ANSWERED — rewrite, with a coverage gap filled** | `ae176dd1`, 2026-08-07. All three exits were weighed against evidence: the logic is **live** (`love.quit` consults `user_is_interactive()`, `controller.lua:697-702`), and the companion doc already existed and was already cited. So the fault was the prose. `project_open_liveness_spec.lua:4-27` now opens with a plain-language paragraph, and test names state what a user would see (*"Ctrl+Esc goes back to the console while a widget is up"*). It also filled a gap the rewrite exposed — `user_is_interactive` is `user_input ~= nil OR user_pointer` and only the first half was tested; the new case is mutation-checked |

---

## The one thing this walk overturned, and it was mine

**I reported that R079 was "separately and explicitly held open" and recommended re-baselining
P8 to it.** That was wrong. The claim came from `S28-merge-plan.md:170` — *"`project_open_liveness_spec.lua` | — | unchanged pending R079 (open ruling)"* — which is a
**merge-scoping line**, saying only that the merge would not touch that file. R079 was
discharged separately the same day, in its own commit, and session28's report says so.

**I inherited a planning table's phrase and did not check the commit history behind it** — the
exact failure mode this phase has a standing rule against, committed inside a review whose
subject was that failure mode. Had the owner accepted my recommendation, the plan would now
carry a **phantom open ruling** as P8's sole remaining content.

**The conservative ruling caught an error the confident recommendation would have shipped.**
Worth recording as method, not just as an outcome: *"both documents are unverified, so check
the tree"* beat *"this document looks better-sourced than that one"*.

---

## What the walk was actually for — three interactions with the dissolution

The walk was owed **before** the test-rewrite step because both restructure the same files.
It found three, none of them visible from the id list alone:

**1. Three `keys_pressed` occurrences in `tests/` that the test-rewrite step does not name.**
Its scope names `keys_pressed_spec.lua` (12), `input_events_spec.lua` (15) and
`input_nfr_mechanism_spec.lua` (8) — 35 of 38. The other three:

- **`tests/helpers/input_fixture.lua:272` — `Controller.keys_pressed = { }`.** Live code in the
  **shared fixture reset**, on the path of every input test. The field ceases to exist, so this
  line must go with it. This is the most consequential of the three and it is in no plan cell.
- **`tests/helpers/input_session.lua:6`** — a comment citing *"the `keys_pressed_spec`
  raw-handler pattern"*. That spec is largely emptied by the rewrite, so the citation rots —
  the failure `agents/validation.md` names explicitly.
- **`tests/input/input_widget_callbacks_spec.lua:538`** — see below; this one is interesting.

**2. A comment that shape (b) makes obsolete in a way worth noticing.**
`input_widget_callbacks_spec.lua:537-541` explains that the test drives **both modifier
tracks**: `F.session.press` keeps `Controller.keys_pressed` correct for `combo_string`, while
`mock.keystroke`'s `S` token flips *"the separate `love.keyboard.isDown` mock the widget's own
`Key.shift()` reads"* — *"two distinct"* mocks. **Under the ruled shape those two tracks become
one**: the matcher reads `love.keyboard.isDown` too. So the comment is not merely stale, it
documents a duplication the ruling removes — **evidence that shape (b) simplifies the test
surface here**, which the shape's cost accounting did not credit it with.

**3. R057's surface vocabulary partly lives in a file the rewrite empties.**
`keys_pressed_spec.lua` holds two of the three surfaces' `describe`s: *"inbound events — the
held-key set"* (deleted) and *"inbound events — combo serialisation"* (rewritten). After the
deletion the file name is a misnomer for its only surviving block. The surviving describe
should move or the file be renamed, or R057's outcome degrades quietly.

---

## Disposition

- **P8 is DONE.** Both §4's row and §11.3's row are updated to say so, with this walk cited.
- **Nothing is owed before the test-rewrite step from P8 itself** — but the three items in
  interaction (1) and the naming problem in (3) are **added to that step's scope**, since they
  are what the walk was for.
- No id needs re-opening under Decision 30 or under the matcher-shape ruling.
