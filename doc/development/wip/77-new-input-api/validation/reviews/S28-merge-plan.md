# S28 — merge plan for R057 / R064 / R074 / R075 / R078

Written 2026-08-07, session28, P8 tail. **Nothing has moved yet.** The owner's
condition: inventory first, plan on disk, cold review of the plan *before* the
move and of the results *after*. Evidence base:
`../outcomes/S28-merge-inventory.md` (93 rows across four files, busted-verified
per file, 11 duplication candidates).

Owner rulings this plan implements:

- **Surfaces are named `inbound events` / `widget control` / `widget
  callbacks`** (R057, and R172 inherits the same three names in P10).
- **Merge the pairs outright** (R074, R078), deduplicating as we go.

## 1. What the inventory actually found

Of the 11 candidate pairs, **one is a true duplicate** (#6) and **one is a
superset relationship** (#8). The other nine are designed splits — different API
entry point, different route, or an explicit depth split the files' own comments
already document. This matters for the merge: the two files in each pair are
**not** two attempts at the same coverage, they are two halves of one subject
that were filed apart. Merging them is a regrouping, not a cull.

Anything below that deletes or rewrites a row states the fact the row pins and
why it survives elsewhere. **Row count is arithmetic, not a target.**

## 2. Target shape

Two merged files, both `#input`, each with a surface-named root describe.

### A. `tests/input/input_widget_control_spec.lua` — surface (b), 39 rows

Root: `describe('input surface: widget control #input', ...)`

Sources: all 27 rows of `input_widget_lifecycle_spec.lua`, plus rows 1-12 of
`input_reconfigure_spec.lua` (`configure` / hidden configure / `clear` /
immutability). Both files answer one question — *how does a project drive the
widget* — split along the `show()`-vs-`configure()` seam, which is exactly what
candidate #2 identified as the substance of R074.

| new describe | rows from | count |
|---|---|---|
| `show(): activation and reset` | widget_lifecycle 1-13 | 13 |
| `configure(): the live session` | reconfigure 1-6 | 6 |
| `configure(): while hidden` | reconfigure 7-9 | 3 |
| `clear()` | reconfigure 10-11 | 2 |
| `the mutable boundary` | reconfigure 12 | 1 |
| `a hidden widget is skipped` | widget_lifecycle 14-16 | 3 |
| `is_shown()` | widget_lifecycle 17-20 | 4 |
| `the documented echo guard` | widget_lifecycle 21-24 | 4 |
| `a shown overlay is painted` | widget_lifecycle 25-27 | 3 |

**No deletions in this file.** Candidates #1, #3, #4, #5 are all designed splits
(see inventory Part 2); after the merge they sit next to each other, which is
the point — a reader comparing `show({force=true})` against `configure()` no
longer has to open two files to find the seam.

Two rows keep their direct-construction fixtures (widget_lifecycle 19-20 build a
widget by hand rather than through `F.compy_input`); that is deliberate in the
source and moves unchanged.

### B. `tests/input/input_widget_callbacks_spec.lua` — surface (c), 52 rows

Root: `describe('input surface: widget callbacks #input', ...)`

Sources: `input_widgets_callbacks_spec.lua` (36) **minus 2 deletions**, plus
rows 13-16 of `input_reconfigure_spec.lua` (the `continuous-session idiom`
block, 4), plus all 14 rows of `input_lifecycle_uniform_spec.lua`.

**Why the reconfigure block moves here and not into file A.** Its four rows are
about `after_submit` / `on_text_entered` — widget-originated events, surface
(c). They sit in the reconfigure file for historical reasons, and all three
genuine dedup findings (#6, #7, #8) are between those rows and the callbacks
file. Leaving them in file A would split surface (c) across two files and hide
the duplication the owner asked to remove.

| new describe | rows from | count |
|---|---|---|
| `the callback fields` | callbacks 1-6 | 6 |
| `highlighter` | callbacks 7-8 | 2 |
| `navigation boundaries` | callbacks 9-15 | 7 |
| `submit` | callbacks 16-24 | 9 |
| `cancel — the Escape chain` | callbacks 25-26 | 2 |
| `Enter and Escape as ordinary keys` | callbacks 27-30 | 4 |
| `hide() and force fire no cancel` | callbacks 31-32 | 2 |
| `the continuous session` | callbacks 35,36 + reconfigure 13-16 | 6 |
| `the same lifecycle on every route` | lifecycle_uniform 1-14 | 14 |

#### Deletions — two, both stated

1. **`input_widgets_callbacks_spec.lua:629`** ("after_submit may hide,
   reproducing prompt-once") — the true duplicate, candidate #6.
   `input_reconfigure_spec.lua:279` assigns the same `after_submit =
   function() input.hide() end`, submits the same way, **and** additionally
   captures the delivered text through `on_text_entered`. Net −1.
   **[REV] The two rows do not assert the same invisibility, and the survivor
   must gain the difference.** The deleted row reads
   `F.is_widget_visible()` — `love.state.user_input`, the user-observable
   overlay handle; the survivor reads `F.widget:is_shown()` — the widget's own
   internal flag, which an owner ruling (2026-07-20) deliberately keeps free of
   any `love.state` reach. `hide()` currently moves both, which is exactly why
   the suite asserts them separately. `reconfigure:279` therefore gains
   `assert.is_false(F.is_widget_visible())` beside its existing
   `is_shown()` check.
2. **`input_widgets_callbacks_spec.lua:613`** ("stays open after submit; a
   project clears in after_submit") — candidate #8.
   `input_reconfigure_spec.lua:308` drives the same `after_submit =
   clear()` idiom through **two** submits and proves the sticky
   `on_text_entered` observes both. It does not currently assert the widget is
   empty and visible afterwards, which is 613's contribution, so **308 gains
   those two assertions** as part of the move rather than 613 surviving beside
   it. Net −1.
   **[REV] Named precisely, since "those two assertions" was too loose to
   execute:** after **each** of 308's two submits, add
   `assert.is_true(F.is_widget_visible())` and
   `assert.is_true(F.widget:is_empty())` — `is_widget_visible`, not
   `is_shown`, because that is the helper 613 used and the distinction is the
   one corrected in deletion 1 above.

#### Kept despite looking duplicated — the three-way cluster (#7)

`reconfigure:296`, `callbacks:350` and `callbacks:661` all touch "no
`after_submit` ⇒ the widget stays open". They are **not** deleted, because each
pins a fact the others do not:

- `reconfigure:296` is the **control** for `reconfigure:279` — without it, a
  broken `hide()` would let 279 pass for the wrong reason.
- `callbacks:350` reads visibility from **inside** `on_text_entered` and
  `after_submit`, pinning that neither callback runs after a close.
- `callbacks:661` registers **no callbacks at all** and sweeps submit **and**
  cancel — the widest net, and the only row covering cancel's default.

After the merge they land in one describe, and each carries a one-line comment
naming what distinguishes it from its neighbours. Deleting a row that pins a
distinct fact to make a dedup count look better is the failure this plan is
guarding against.

#### The depth split with `lifecycle_uniform` (#9, #10, #11) — kept as is

`lifecycle_uniform`'s rows deliberately assert only "each surface runs the one
lifecycle at all", deferring call-order depth to the callbacks file, and its
Shift+Enter row runs on the **editor** route where the callbacks file's runs on
the project overlay. All 14 rows move unchanged into their own describe. The
file's own framing comment moves with them.

## 3. Renames, and what dissolves

- **R075** — `input_widgets_callbacks_spec.lua` → `input_widget_callbacks_spec.lua`
  (singular, matching every sibling). Satisfied by target file B's name.
- **R064** — `input_lifecycle_uniform_spec.lua` was to be renamed to name
  submit/cancel. It **dissolves** into file B instead, which answers the remark
  more directly than a rename: its content is submit/cancel across routes, and
  that is now a describe inside the surface that owns those callbacks.
- `input_widget_lifecycle_spec.lua` and `input_reconfigure_spec.lua` both
  dissolve into files A and B. Four files become two.

## 4. R057 — surface names on the files that are NOT merging

Root `describe` titles only; no rows move, no files are renamed in this pass.

| file | surface | new root describe |
|---|---|---|
| `input_events_spec.lua` | inbound events | `input surface: inbound events — dispatch #input` |
| `input_shortcuts_click_spec.lua` | inbound events | `input surface: inbound events — shortcuts and clicks #input` |
| `input_routing_spec.lua` | inbound events | `input surface: inbound events — routing #input` |
| `input_route_lifecycle_spec.lua` | inbound events | `input surface: inbound events — route lifetime #input` |
| `keys_pressed_spec.lua` | inbound events | `input surface: inbound events — the held-key set #input` |
| `input_cursor_text_spec.lua` | widget control | `input surface: widget control — cursor and text #input` |
| `input_nfr_mechanism_spec.lua` | — | unchanged (cross-cutting NFR guards, not a surface) |
| `project_open_liveness_spec.lua` | — | unchanged pending R079 (open ruling) |
| `user_input_model_spec.lua`, `user_input_view_spec.lua`, `input_text_spec.lua`, `cursor_spec.lua`, `input_spec.lua`, `history_spec.lua`, `highlight_regression_spec.lua` | — | unchanged: widget internals and pre-feature units, not API surfaces |

Naming the surfaces on files that keep their contents is deliberate: it makes
the vocabulary real in the suite before P10 puts it in `doc/input_api.md`, at
zero risk of losing a row.

## 5. Execution order and the checks at each step

Each step ends green and is committed on its own.

1. **File A** — create `input_widget_control_spec.lua` by moving both sources in
   whole, regrouped per §2A; delete the two source files. Expect **39 rows**,
   suite **954** (nothing added, nothing dropped).
2. **File B** — create `input_widget_callbacks_spec.lua`; apply the two
   deletions and fold 613's assertions into the surviving 308. Expect **52
   rows**, suite **952**.
3. **R057 describes** on the six files in §4. Expect suite **952**, unchanged.

Between steps: `busted tests` green and the per-file row count checked against
the inventory's totals, not against grep — `input_events_spec.lua` alone
generates 17 rows from loops, so grep undercounts.

**Arithmetic:** 93 rows in, 91 out, 2 deleted, both named above. Suite
954 → 952.

## 5b. [REV] Revision log — what the cold review changed

Reviewer worked read-only from the plan and the inventory, and read the four
disputed rows in the source rather than the summaries of them. Deliverable:
`../outcomes/S28-merge-plan-review.md`. Four corrections, all accepted; the two
substantive ones were re-verified in the source before acceptance.

| # | correction | where |
|---|---|---|
| 1 | **Deletion 1 would have dropped an assertion.** The deleted row checks `F.is_widget_visible()` (the overlay handle a user sees), the survivor checks `F.widget:is_shown()` (the widget's internal flag, ruled free of `love.state`). Survivor gains the visible check. **Verified in source** — `input_reconfigure_spec.lua:290` vs `input_widgets_callbacks_spec.lua:636`. | §2B deletion 1 |
| 2 | "308 gains those two assertions" named neither the helper nor the position. Now: `is_widget_visible` + `is_empty`, after **each** of the two submits. | §2B deletion 2 |
| 3 | **Arithmetic bug, self-contradicting.** File B's table listed `callbacks 33` inside `the continuous session` — row 33 is `callbacks:613`, deleted two sections earlier in the same document. The table summed to 53, not 52. A literal execution would have un-deleted the row and landed the suite at 953. Corrected to `callbacks 35,36 + reconfigure 13-16` = 6. | §2B table |
| 4 | File B needs the `TU` require carried over with `lifecycle_uniform`'s rows (`open_doc` uses `TU.get_save_function`); the plan listed the helpers but not the require. | §6 |

Confirmed without change: the three-way cluster stays (each row pins a distinct
fact), no helper name collisions between the merging files, the echo-guard
placement, and identical `setup`/`teardown`/`before_each` across all four files.

## 6. What would make this plan wrong

- If either deletion turns out to pin something its survivor does not, the row
  stays and the count moves. The cold review is asked to check exactly this
  against the source, not against this document's summary of it.
- If `lifecycle_uniform`'s rows depend on file-local helpers (`bare_uic`,
  `driver`, `open_doc`) that collide with names in the callbacks file, the
  helpers move with them and are renamed, not reimplemented. **[REV]** No
  collisions exist (grep-verified by the review), but `open_doc` uses
  `TU.get_save_function`, so file B must carry `lifecycle_uniform`'s `TU`
  require as well as its helpers.
- The echo-guard block (file A) is arguably surface (a) — it is about a shortcut
  eating an echo. It stays in widget control because what it pins is *a widget
  opening cleanly*. Flagged as the one judgment call in the grouping that a
  reasonable reviewer could reverse.
