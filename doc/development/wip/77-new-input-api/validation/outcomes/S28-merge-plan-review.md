# S28 — cold review of the merge plan (pre-move)

Reviewed 2026-08-07, session28. Read-only: no spec/source/config file was
touched; `busted tests` was run once to confirm the baseline (`954
successes / 0 failures / 0 errors / 3 pending`, matching the plan). Plan
reviewed: `../reviews/S28-merge-plan.md`. Evidence base reviewed alongside
it: `S28-merge-inventory.md` in this directory.

For check 1, all four rows were opened and read directly in
`tests/input/input_widgets_callbacks_spec.lua` and
`tests/input/input_reconfigure_spec.lua`, plus the helpers they call in
`tests/helpers/input_fixture.lua` and `src/controller/userInputController.lua`
— not taken from the plan's or the inventory's description.

---

## 1. The two deletions — CORRECTION

### Deletion 1: `input_widgets_callbacks_spec.lua:629` vs `input_reconfigure_spec.lua:279`

Both rows read as the plan describes on their surface: same
`after_submit = function() input.hide() end`, both submit, both assert
the widget is no longer visible, and 279 additionally captures delivered
text via `on_text_entered`. But the two rows assert "invisible" through
**two different mechanisms**, and the suite treats those mechanisms as
deliberately non-interchangeable:

- `input_widgets_callbacks_spec.lua:636` (inside the `:629` row):
  `assert.is_false(F.is_widget_visible())`
- `input_reconfigure_spec.lua:290` (inside the `:279` row):
  `assert.is_false(F.widget:is_shown())`

`F.is_widget_visible()` (`tests/helpers/input_fixture.lua:209-211`) reads
`love.state.user_input ~= nil` — the fixture's own comment (lines
200-208) calls this **the observable "the user sees an input field"**,
explicitly contrasted with "the widget's own self-report," and says it
"stays honest if the two ever disagree." `F.widget:is_shown()` resolves
to `UserInputController:is_shown()` (`src/controller/userInputController.lua:440-442`),
documented at lines 433-438 as **"a strictly INTERNAL flag... no
love.state reach"** per an explicit owner ruling (2026-07-20) — i.e. the
suite's own convention deliberately keeps these two predicates apart
rather than treating one as a stand-in for the other.

I checked whether they can currently diverge: `hide()`
(`userInputController.lua:327-330`) sets `self.shown = false` and
`love.state.user_input = nil` unconditionally together, in the same
function body, so for the code path under test today the two assertions
are behaviourally coupled — the deletion would not currently hide a real
bug. But that coupling is exactly what the fixture comment is guarding
against future drift on ("it stays honest if the two ever disagree"), and
after the merge-plus-deletion, no row anywhere in the surviving file
checks `F.is_widget_visible()` at the `after_submit → hide()` call site
— I grepped every `is_widget_visible`/`is_shown` call in both source
files (11 sites) and confirmed line 636 is the only one exercising that
exact fact. The plan's claim "asserts the same invisibility" is not
accurate as a description of the code; it is the same *outcome*, checked
through a different, deliberately-distinguished mechanism.

**Correction:** when 629 is deleted, 279 should gain
`assert.is_false(F.is_widget_visible())` alongside its existing
`F.widget:is_shown()` check, so the framework-observable fact 629 pinned
is not silently traded for the internal one. This is a small, mechanical
fix, not a reason to keep 629.

### Deletion 2: `input_widgets_callbacks_spec.lua:613` vs `input_reconfigure_spec.lua:308`

Read directly: `:613` presets text via `show({text='first'})`, submits
once, and asserts `F.is_widget_visible()` true and `F.widget:is_empty()`
true. `:308` types and submits **twice**, asserting only that
`on_text_entered` observed both deliveries (`assert.same({{'a'},{'b'}},
seen)`) — it currently has no visibility or emptiness assertion at all.
The plan is candid about this ("it does not currently assert... which is
613's contribution... 308 gains those two assertions as part of the
move") — this is not a silent drop, it is a declared edit, which is the
right way to handle it.

Two things the plan should make explicit rather than leaving to whoever
executes it:

- **Which helper.** `:613`'s visibility check uses `F.is_widget_visible()`
  (line 621), not `F.widget:is_shown()`. Given the finding above, the
  folded-in assertion should keep `F.is_widget_visible()` specifically —
  not be silently written as `is_shown()` because that's the file
  convention `reconfigure` otherwise leans on (it uses `is_shown()` at
  lines 290/301 but `is_widget_visible()` at lines 71/351 — it is not a
  clean per-file convention, so this has to be a deliberate choice, not a
  default).
- **Where.** 308 proves repeatability across two submits; 613 only
  checked state after one. The plan doesn't say whether the folded
  assertions land after the first submit, the second, or both. Checking
  only after the second is a weaker claim than 613 made (613 pins that
  the very first cycle already leaves the widget open+empty); the
  faithful fold is to assert visibility+emptiness after **each** submit,
  or at minimum after the first (matching 613 exactly) in addition to the
  final `assert.same`.

**Verdict: CORRECTION.** Both deletions are directionally right — nothing
argues either survivor should stay unmerged — but the plan's description
of deletion 1 overstates equivalence between two mechanisms the suite
treats as distinct, and deletion 2's "gains those two assertions" is
under-specified enough that a literal execution could produce a weaker
row than the one deleted. Both are cheap to fix by naming the exact
assertion and helper to add.

---

## 2. The three-way cluster kept (`reconfigure:296`, `callbacks:350`, `callbacks:661`) — CONFIRMED

Read all three directly:

- `input_reconfigure_spec.lua:296-302` — bare control: show, submit, no
  callbacks set, `assert.is_true(F.widget:is_shown())` after everything
  completes. Sits beside `:279` as the pair the plan says it is (without
  it, a broken `hide()` would let `:279` pass for the wrong reason).
- `input_widgets_callbacks_spec.lua:350-366` — reads visibility **from
  inside** the `on_text_entered` and `after_submit` callbacks themselves
  (`seen.entered = F.is_widget_visible()` at line 357, `seen.after =
  F.is_widget_visible()` at line 361), asserting both afterward. This is
  a genuinely different fact: not "is it open when everything is done"
  but "is it still open *while the callbacks run*" — i.e. that submit
  doesn't hide before running them.
- `input_widgets_callbacks_spec.lua:661-675` — registers **no callbacks
  at all**, and is the only one of the three that also drives Escape
  (`F.session.press('escape')` at line 671) and asserts both post-submit
  and post-cancel state.

None of the three is a restatement of another; each exercises a distinct
mechanism (final-state control / mid-callback observation / zero-callback
sweep including cancel). The plan's claim holds and I did not find a
fourth row anywhere in either file duplicating any of these three.

---

## 3. Row arithmetic — CORRECTION

Grand totals check out: 27+16+36+14 = 93 in; 93 − 2 = 91 out; File A's
table (13+6+3+2+1+3+4+4+3) sums to 39, matching its stated count and
matching 27 (all of widget_lifecycle) + 12 (reconfigure rows 1-12).

File B's table does **not** sum to its own stated total. As literally
written:

```
the callback fields                6
highlighter                        2
navigation boundaries              7
submit                             9
cancel — the Escape chain          2
Enter and Escape as ordinary keys  4
hide() and force fire no cancel    2
the continuous session             7   <- "callbacks 33,35,36 + reconfigure 13-16"
the same lifecycle on every route  14
                                   ---
                                    53
```

That's 53, not the stated 52. The bug is in the "the continuous session"
row: it lists **callbacks 33, 35, 36** as sources. Cross-checked against
the inventory, inventory row 33 is `input_widgets_callbacks_spec.lua:613`
— "stays open after submit; a project clears in after_submit" — which is
**exactly deletion 2**, named two sections earlier in the same document
as cut. Row 33 cannot be both deleted and moved into the destination
table. With row 33 correctly excluded, the entry is "callbacks 35,36 +
reconfigure 13-16 | **6**", the table sums to 52, and the file-B header
and §5's "Expect 52 rows" are both right — but only because the table
disagrees with itself and with the deletions section, not because the
table is internally consistent.

This is more than cosmetic: if the merge is executed by literally moving
the rows a table cell names, "callbacks 33,35,36" tells the executor to
carry line 613 into the new describe rather than deleting it, which would
silently undo deletion 2 and land the suite at 953, not 952.

**Correction:** change the "the continuous session" row to `callbacks
35,36 + reconfigure 13-16 | 6`. No other table row disagrees with the
inventory — I checked every remaining File A and File B row range against
the inventory's row numbers and titles and they all line up.

**Verdict: CORRECTION** — one destination-table row contradicts the
plan's own deletions list; everything else in the arithmetic (totals,
other table rows, 954→952) is correct once that row is fixed.

---

## 4. Helper dependencies — CONFIRMED

Grepped `bare_uic`, `driver`, `open_doc`, `arm`, `open_on` across all four
source files:

- `arm` / `open_on` appear only in `input_widget_lifecycle_spec.lua`
  (inside the `the documented echo guard` describe, lines 335-395) — the
  file merging into File A. `input_reconfigure_spec.lua` (also merging
  into A) defines no local helpers at all (confirmed: only its `local F =
  require(...)` at file scope). No collision.
- `bare_uic` / `driver` / `open_doc` appear only in
  `input_lifecycle_uniform_spec.lua` — merging into File B.
  `input_widgets_callbacks_spec.lua` (also merging into B) defines no
  local helpers beyond its module requires. No collision.

Also checked: all four files declare an identical top-level
`setup`/`teardown`/`before_each` (`F.setup()` / `F.teardown()` /
`F.reset()`) and none has a nested per-`describe` `before_each` — so no
row depends on scope-local state that the merge would strand.

One completeness note, not a defect: File B's merged file will need the
union of requires from all three sources — `F` and `mock` (already both
present in `input_widgets_callbacks_spec.lua`) plus `TU =
require('tests.testutil')`, which only `input_lifecycle_uniform_spec.lua`
currently requires (used by its `open_doc` helper). The plan doesn't
mention carrying this require forward; it should, since `open_doc` won't
resolve without it.

**Verdict: CONFIRMED**, with the `TU` require noted for §5's execution
checklist.

---

## 5. The grouping calls — CONFIRMED

Read the full echo-guard block (`input_widget_lifecycle_spec.lua:333-412`).
It is triggered from a `keypressed` shortcut and is mechanically about
event dispatch (a one-shot `textinput` guard consuming an echo), which
does lean toward "inbound events." But every assertion in the block is
about the **widget's** resulting state (`F.is_widget_visible()`,
`F.widget:is_empty()`, `F.widget:get_text()`) — none assert anything
about routing or dispatch order for its own sake. The plan's framing
("what it pins is a widget opening cleanly") matches what the rows
actually check, so I agree it belongs in widget control, while agreeing
it's a legitimate judgment call rather than a clear-cut placement.

I did not find another row whose assigned surface looks wrong. The two
direct-construction rows (`widget_lifecycle:302`, `:313`, "is_shown"
group) stay in widget control appropriately — they assert
`is_shown()`/`hide()` behaviour, not dispatch. The reconfigure rows 1-12
(configure/clear/immutability) are unambiguously widget-control (they
never touch events). The reconfigure rows 13-16 and all of
`lifecycle_uniform` are unambiguously widget-callbacks (submit/cancel
outcomes). No further disagreement.

**Verdict: CONFIRMED.**

---

## 6. Anything unmentioned — minor notes only

- **setup/before_each:** identical across all four files (see check 4) —
  no divergence to reconcile.
- **describe-scope dependence:** none of the four files has a nested
  `before_each`; no row's behaviour depends on which file's top-level
  `describe` it sits directly under.
- **module requires:** covered under check 4 — `TU` needs to move with
  `lifecycle_uniform`'s content into File B; not currently called out in
  the plan.
- One thing worth flagging that isn't a defect: `input_reconfigure_spec.lua`
  mixes `F.is_widget_visible()` (lines 71, 351) and `F.widget:is_shown()`
  (lines 290, 301) itself, i.e. it is not a clean per-file convention
  that File A vs File B each "own" one helper — so future rows added to
  either merged file should pick the helper deliberately (framework-
  observable vs internal flag) rather than copying whichever neighbour
  happens to be nearby.

**Verdict: CONFIRMED** — no undocumented breakage found beyond the two
corrections already named above.

---

## Overall

Safe to execute **with the corrections named above**, not as written
verbatim:

1. Fold `F.is_widget_visible()` into the surviving `:279` row when `:629`
   is deleted (check 1).
2. Fold `F.is_widget_visible()` (not `is_shown()`) plus emptiness into
   `:308`, placed after each submit or at least after the first, when
   `:613` is deleted (check 1).
3. Fix the File B "the continuous session" table row to `callbacks 35,36
   + reconfigure 13-16 | 6` — as written it contradicts the plan's own
   deletions list and would misdirect a literal execution (check 3).
4. Carry the `TU` require into File B alongside `lifecycle_uniform`'s
   content (check 4/6).

Everything else — the three-way cluster's distinctness (check 2), helper
non-collision (check 4), the echo-guard placement and the rest of the
grouping (check 5), and shared setup/scope hygiene (check 6) — is
CONFIRMED as the plan states it, verified against the source rather than
the plan's summary.
