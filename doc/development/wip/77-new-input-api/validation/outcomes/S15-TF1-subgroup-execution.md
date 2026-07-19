# S15-TF1 — subgroup-execution report (Sonnet worker)

Executed per `validation/prompts/S15-TF1-subgroup-execution.md`. Mirrored the
owner's `input_cursor_text_spec.lua` nesting idiom (concept-named nested
`describe`s, readability-only, no logic change) over the 4 files in the group
map: `input_events_spec.lua`, `input_widgets_callbacks_spec.lua`,
`input_reconfigure_spec.lua`, `input_route_lifecycle_spec.lua`. No hooks added
to any nested describe; every existing `-- ----` section-marker comment was
kept verbatim as a comment (either standing alone above the new `describe`,
for files 1/2 where the marker already delimited the group, or preserved
as-is while new sub-`describe`s were introduced within an unmarked section,
for files 2/3/4's finer subdivisions). Not committed — left for the
orchestrator.

## Per-file it/pending counts (HEAD vs. now) and standalone results

| # | file | HEAD it+pending | now it+pending | `busted tests/input/<f>` |
|---|------|---|---|---|
| 1 | `input_events_spec.lua` | 25 | 25 | 25 successes / 0 failures / 0 errors / 0 pending |
| 2 | `input_widgets_callbacks_spec.lua` | 27 | 27 | 27 successes / 0 failures / 0 errors / 0 pending |
| 3 | `input_reconfigure_spec.lua` | 15 | 15 | 15 successes / 0 failures / 0 errors / 0 pending |
| 4 | `input_route_lifecycle_spec.lua` | 8 | 8 | 8 successes / 0 failures / 0 errors / 0 pending |

Counts taken via `git show HEAD:tests/input/<f> | grep -cE '^\s*(it|pending)\('`
vs. the same grep on the current file. All four unchanged; all four
standalone-green.

## Full-suite result

```
busted tests
815 successes / 0 failures / 0 errors / 4 pending
```

Matches the hard-contract baseline exactly (same 815/0/0/4 as before this
change).

## Groups applied

**1. `input_events_spec.lua`** — inner describe `#input events dispatch
chain`, 7 groups, each wrapping the its already delimited by an existing
`-- ----` seam comment (seam comment kept in place, unchanged, immediately
above the new `describe`): `order, consume, fall-through` (5 its),
`combo tables and normalisation` (4), `signatures and the read-only proxy`
(5), `defaults and the hidden sink` (2), `tier-3: the on_* generic callback`
(2), `tier-3: the native install path` (5), `the mutable/immutable boundary`
(2). No label shortening applied — none of the 7 group names is a literal
leading-word match of any child `it` label (they are topic summaries, not
sentence prefixes), so every label was left verbatim per the idiom's
"no clean shared prefix" branch.

**2. `input_widgets_callbacks_spec.lua`** — inner describe `dispatch chain:
widget outputs and submit/cancel #m5c #input`. The file's two existing
`-- ----` markers (`widget outputs`, `submit and cancel`) stayed as plain
comments, unmoved; 8 new sub-`describe`s were inserted inside/around them:
`output field slots and sharing` (6 its), `highlighter` (1), `navigation
boundary outputs` (7), `submit` (4), `cancel — the Escape chain` (1),
`Enter and Escape as ordinary keys` (3), `suppressed cancel` (2),
`continuity across submit` (3). No label shortening — checked each group
name against its first child label for a literal leading-word match
(including the near-miss `Enter and Escape as ordinary keys` vs. `it('Enter
and Escape are ordinary keys while hidden')`, which shares 3 leading words
but stripping them would leave `'are ordinary keys while hidden'`, not a
sentence — left verbatim per the rule).

**3. `input_reconfigure_spec.lua`** — nested one level deeper, inside the
already-existing `describe('live reconfigure and clear #m7', ...)` (its
sibling `describe('continuous-session idiom #m8', ...)` untouched, 3 its
unchanged). 4 groups: `configure on an active session` (6 its), `hidden
configure` (3), `clear` (2), `immutability` (1, verbatim — no prefix
match).

**4. `input_route_lifecycle_spec.lua`** — nested inside the existing
`describe('route connection lifecycle #m5c', ...)`. 4 groups: `connection at
the running boundary` (2 its, verbatim — no prefix match), `stop teardown`
(3), `inspect` (1), `compy.before_exit` (2).

## Labels shortened (non-trivial, i.e. redundant leading word(s) stripped)

Applied only where a child `it` label's leading word(s) literally duplicated
the group name's leading word(s) *and* the trimmed label still read as a
sentence (per the worked example in the prompt, `configure on an active
session` + `it('configure updates the prompt...')` → `it('updates the
prompt...')`):

- `input_reconfigure_spec.lua`, group `configure on an active session` (all
  6 children had a redundant `configure ` prefix, stripped):
  `configure updates the prompt on an active session` → `updates the prompt
  on an active session`; `configure swaps the live validator` → `swaps the
  live validator`; `configure swaps the live highlighter` → `swaps the live
  highlighter`; `configure swaps the live on_text_entered` → `swaps the live
  on_text_entered`; `configure swaps the live on_limit_reached` → `swaps the
  live on_limit_reached`; `configure leaves text/cursor untouched on an
  active session, even mixed with a live field` → `leaves text/cursor
  untouched on an active session, even mixed with a live field`.
- `input_reconfigure_spec.lua`, group `hidden configure` (2 of 3 children —
  the third, `hidden-configured text does not leak into a later show`, is
  hyphenated differently and was left verbatim, no literal prefix match):
  `hidden configure applies text and cursor on the next show` → `applies
  text and cursor on the next show`; `hidden configure applies prompt and
  validator on the next show` → `applies prompt and validator on the next
  show`.
- `input_reconfigure_spec.lua`, group `clear` (both children had a redundant
  `clear ` prefix): `clear empties an active session with no callback` →
  `empties an active session with no callback`; `clear while hidden warns
  and no-ops` → `while hidden warns and no-ops`.
- `input_route_lifecycle_spec.lua`, group `stop teardown` (all 3 children
  had a redundant `stop ` prefix): `stop clears every project-installed
  handler and hook` → `clears every project-installed handler and hook`;
  `stop silently hides a shown widget without firing the cancel chain` →
  `silently hides a shown widget without firing the cancel chain`; `stop
  resets the widget's own output fields` → `resets the widget's own output
  fields`.
- `input_route_lifecycle_spec.lua`, group `inspect` (single child, redundant
  `inspect ` prefix): `inspect disconnects the project route and its widget
  goes unhonoured` → `disconnects the project route and its widget goes
  unhonoured`.
- `input_route_lifecycle_spec.lua`, group `compy.before_exit` (both
  children had the full group name as a literal prefix): `compy.before_exit
  fires once on stop before cleanup` → `fires once on stop before cleanup`;
  `compy.before_exit resets to noop after stop` → `resets to noop after
  stop`.

No label's *meaning* changed — only a redundant subject already implied by
the enclosing `describe` name was dropped.

## Diff shape verification

For each of the 4 files, diffed HEAD vs. now with both sides
whitespace-stripped per line (`sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//'`)
to isolate content-only changes from the reindentation. Every remaining diff
line is one of exactly two kinds: an inserted `describe('<name>', function()`
/ `end)` line, or a changed `it('<old label>' → `it('<new label>'` line
matching the shortenings listed above. No assertion, setup, or comment body
line changed content anywhere across the 4 files.

## LSP diagnostics (post-edit, `sleep 1` before each query)

- `input_events_spec.lua`: 4 warnings — 2× `duplicate-set-field` on
  `input.on_text_input = ...` (two sequential reassignments in the same
  `it`, pre-existing test logic, lines 363/366), 1× `duplicate-set-field` on
  `Controller.project_input.framework_handlers.keypressed['a'] = ...`
  (line 77), 1× `undefined-field` on `assert.has_no.errors` (line 478,
  `luassert`'s DSL isn't in the LSP's stub type). All four are pre-existing
  patterns in the original file's bodies (untouched by this edit, confirmed
  by the whitespace-stripped diff above showing no body-line changes at
  those lines beyond added indent) — not introduced by the nesting.
- `input_widgets_callbacks_spec.lua`: 3 warnings, all `undefined-field` on
  `assert.has_no.errors` (lines 50, 498, 503) — same pre-existing
  `luassert` stub gap.
- `input_reconfigure_spec.lua`: 2 warnings, `duplicate-set-field` on
  `Log.warn = ...` save/restore idiom (lines 167, 238) — pre-existing
  save-restore pattern, unrelated to the nesting.
- `input_route_lifecycle_spec.lua`: zero diagnostics.

No new errors or warnings attributable to the restructuring in any of the 4
files.

## Confirmation

- Only the 4 named files under `tests/input/` were touched; no other file,
  tag, outer describe name, `setup`/`teardown`/`before_each`, or `local F =
  require(...)` line was changed (confirmed via `git status` and the
  whitespace-stripped diffs above).
- `input_reconfigure_spec.lua`'s sibling `describe('continuous-session idiom
  #m8', ...)` was left untouched, as instructed.
- Not committed.
