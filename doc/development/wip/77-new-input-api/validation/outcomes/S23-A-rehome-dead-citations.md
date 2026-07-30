# S23-A outcome — rehome dead contract citations

Comment-only pass, per
`doc/development/wip/77-new-input-api/validation/prompts/S23-A-rehome-dead-citations.md`.
No commits made (parent session commits).

## Verified headings before starting

`grep -n '^#' doc/input_api.md` and
`grep -n '^#' doc/development/internals/user_input.md` both matched
the prompt's stated headings exactly, including the confirmation that
`internals/user_input.md` line 81 already reads `Cursor manipulation
and "reset" — ...` with **double** quotes.

## Sites changed (file:line → old → new)

Line numbers below are HEAD (pre-edit) on the left where the prompt
gave one, current (post-edit) on the right.

**src/controller/consoleController.lua**
- 440 → 440-443: `"Sticky callbacks"` → `"Callback assignments"`.
- 557 → 558-562 (not in the 22-site list; found on completeness
  sweep): `"Cursor manipulation and 'reset'"` → `"Cursor
  manipulation and \"reset\""`.
- 566 → 567-569 (also not listed): same quote fix.
- 575 → 576-579: `"Live reconfigure: \`configure\`, \`set_text\`,
  \`clear\`, cursor"` → `"Live changes"`.

**src/controller/userInputController.lua** (file not in the 22-site
list at all; both sites found on completeness sweep)
- 149 → 148-150: `"Cursor manipulation and 'reset'"` → `"Cursor
  manipulation and \"reset\""`.
- 267 → 266-268: same quote fix. This one is split `Cursor` /
  `manipulation and 'reset'` across two source lines — the kind of
  split the prompt warned about — and was missed by a same-line
  grep; caught by grepping the `and 'reset'` fragment instead.

**src/model/input/userInputModel.lua**
- 517 → 517: `"Live reconfigure: \`configure\`, \`set_text\`,
  \`clear\`, cursor"` → `"Live changes"`.

**tests/input/input_cursor_text_spec.lua**
- 6 → 6-8: `"API reference"` and `"Cursor manipulation and
  'reset'"` (two citations, one line) → `"Live changes"` and
  `"Cursor manipulation and \"reset\""`.
- 20 → 19-20 (folded with the `"Live reconfigure: ..." ` fragment at
  old line 18-19): both `"Live reconfigure: ..."` and `"API
  reference"` collapsed to one `"Live changes"` citation (they named
  the same section).
- 30 → 29-31 (not listed): `"Cursor manipulation and 'reset'"` quote
  fix.
- 81 → 80-82 (not listed): same quote fix.
- 115 → 114: `"API reference"` → `"Live changes"`.
- 130 → 129: `"Live reconfigure"` → `"Live changes"`.
- 144 → 143: `"Live reconfigure"` → `"Live changes"`.
- 168 → 167-169 (not listed): `"Cursor manipulation and 'reset'"`
  quote fix.
- 188 → 187: `"API reference"` → `"Live changes"`.

**tests/input/input_nfr_forward_spec.lua** (file not in the 22-site
list; found on completeness sweep)
- 148 → 146-150: `"Cursor manipulation and 'reset'"` → `"Cursor
  manipulation and \"reset\""`.

**tests/input/input_reconfigure_spec.lua**
- 257-267 → 257-267: narrative fix — replaced the stale
  `"The continuous-session idiom" (migration recipe)` block with the
  exact text supplied in the prompt (`"Submit lifecycle": the
  overlay stays shown after a submit...`), keeping the `=====` rules
  and the two lifecycle-callback lines.
- 271 → 271: `The recipe:` → `One shape:`.
- 316 → 316: `"Live reconfigure"` → `"Live changes"` (left the
  co-quoted `"A continuous session with a changing prompt"` fragment
  untouched — it isn't in the mapping table).
- 320-321 → 320-321: `"Submit and cancel — the framework submit
  chain"` → `"Submit and cancel — widget-owned callback sequences"`.
- 323 → 323: **judgment call, flagged below** — dropped the dead
  `"The continuous-session idiom"` citation.

**tests/input/input_widget_lifecycle_spec.lua**
- 15-16 → 15-18 (not listed): `"Activating the widget: \`show\`"`
  → `` "`show(config)`"``.
- 26 → 27: same replacement.
- 105 → 106: same replacement.
- 117-118 → 118: same replacement.

**tests/input/input_widgets_callbacks_spec.lua**
- 318-319 → 318-321: `"Submit and cancel — the framework tier-1
  chains"` → `"Submit and cancel — widget-owned callback
  sequences"`.
- 333-334 → 334-336: same replacement.
- 422-423 → 422-425: same replacement, plus the surrounding "no
  framework entry engages" phrase (repeating the retired
  framework-tier framing per Decision 6 revised) reworded to "no
  widget submit/cancel handling engages".
- 526 → 528: `"Sticky callbacks"` → `"Callback assignments"`.

**tests/input/input_route_lifecycle_spec.lua**
- 120 → 120: `"Sticky callbacks"` → `"Callback assignments"`.

**tests/input/user_input_model_spec.lua**
- 151 → 151: `"Live reconfigure: \`configure\`, \`set_text\`,
  \`clear\`, cursor"` → `"Live changes"`.

## Suite numbers

`busted tests` → **862 successes / 0 failures / 0 errors / 3
pending**. Matches the prompt's expected numbers exactly.

## Re-grep result

Re-grepped all 8 dead names (`Sticky callbacks`, `"API reference"`,
`Live reconfigure`, `Activating the widget`, `framework submit`,
`framework tier-1`, and the single-quoted `and 'reset'` form) across
every tracked file outside `doc/`. **Zero remain**, with one
non-citation false-positive noted below.

`git diff --stat` shows exactly the 10 files above (the 8 `src` +
`tests` files named or implied by the prompt's site list, plus
`src/controller/userInputController.lua` and
`tests/input/input_nfr_forward_spec.lua`, both found only via the
completeness sweep). No other files touched; the outcome file itself
is the only thing written under `doc/development/wip/`.

Every replacement heading was confirmed to exist via `grep -n '^#'`
on both target docs before use (see the section above).

## Left alone, and why

- `tests/input/input_reconfigure_spec.lua:28` — `"Live reconfigure +
  clear. Configure changes live callback fields..."` is a section
  banner, not a `doc/input_api.md, "..."` citation. Not touched.
- `tests/input/input_reconfigure_spec.lua:4` — "the continuous-session
  idiom" as plain prose (file-header description), not a citation.
  Not touched.
- `tests/input/input_reconfigure_spec.lua:269` —
  `describe('continuous-session idiom #m8', ...)` is a test
  description string; hard constraint forbids touching those. Not
  touched.
- `tests/input/input_reconfigure_spec.lua:17-18` — **a third dead
  citation of `doc/input_api.md, "The continuous-session idiom"`**
  (split `"The continuous-session` / `idiom")` across two lines,
  inside the file's top-of-file header comment). This name is not a
  row in the decided mapping table, and it's outside both locations
  the "one narrative fix" section named (~257-267 and ~271-273). Left
  untouched rather than improvising a fix outside the decided scope.
  **Flagging for owner attention**: this is a live dead citation that
  the re-grep for the 8 table names won't catch (the table has no row
  for it), so it will not show as zero in a mechanical sweep keyed to
  the 8 names — it needs an explicit decision the same way line
  258/323 did.

## Judgment call: line 323 (flagged, not silently absorbed into the mapping)

Line 323 (`doc/input_api.md, "The continuous-session idiom"'s
apply_config: custom_label is only overwritten...`) is the second
`"The continuous-session idiom"` citation in this file — distinct
from the one covered by the "one narrative fix" instructions
(that fix explicitly targeted only ~257-267 and ~271-273) and not a
row in the decided mapping table either. But it was listed in the
prompt's 22-site list for this file (`258, 316, 320-321, 323`), so
something was expected to change there.

Rather than inventing a new heading citation (which would extend the
table), I dropped the dead heading reference and let the sentence
stand on the citation already established two lines earlier in the
same comment (`doc/input_api.md, "Live changes"` at line 316, which
covers configure()/custom_label persistence — the actual subject of
this sentence). The prose meaning is unchanged; only the redundant,
now-broken second citation is gone.

**This is a deviation from "do not re-derive or extend it"** — I'm
reporting it plainly rather than presenting it as table-driven. If
the owner wants a different resolution (e.g., citing "Live changes"
explicitly a second time, or leaving the sentence uncited), this is
the one edit in the pass worth a second look.

## Surprises

- The 22-site list turned out to systematically omit every
  `"Cursor manipulation and 'reset'"` occurrence (mapping table row
  8) — 9 such sites existed across `src` and `tests`, none in the
  given list, across two files not mentioned in the list at all
  (`src/controller/userInputController.lua`,
  `tests/input/input_nfr_forward_spec.lua`). The prompt's own
  instruction to treat the list as "a starting point, not the
  completeness authority" anticipated exactly this — the completeness
  re-grep was load-bearing, not a formality.
- Two of those row-8 sites (`userInputController.lua:267` and one in
  `input_cursor_text_spec.lua`) had the heading name itself split
  across two comment lines (`Cursor` / `manipulation and 'reset'`),
  which defeated a plain same-line grep; only a grep for the `and
  'reset'` fragment caught them, exactly the failure mode the prompt
  flagged for other citations.
- `input_widget_lifecycle_spec.lua` had a fourth `"Activating the
  widget: \`show\`"` site (lines 15-16) beyond the three listed.

## Verification

- `busted tests`: 862 / 0 / 0 / 3.
- Re-grep of all 8 dead names: zero (see above; one prose
  false-positive at line 28 confirmed not a citation).
- `git diff --stat`: 10 files, all expected (`src/controller/console
  Controller.lua`, `src/controller/userInputController.lua`,
  `src/model/input/userInputModel.lua`, and 7 files under
  `tests/input/`).
- All replacement section names confirmed present via `grep -n '^#'`
  on `doc/input_api.md` and `doc/development/internals/user_input.md`.
- Every added/changed line checked against the ≤64-column limit by
  codepoint count (not byte count, given the em-dashes and arrows in
  these comments) — all in bounds.
- `mcp__lua-lsp__diagnostics` run on every edited file after a 1s
  settle; no new diagnostics — all reported hints/warnings predate
  this change (unused locals, deprecated LuaJIT APIs, etc.).
- Confirmed via `git diff` that every added and every removed line in
  the whole diff starts with `--` or `---`: no executable code,
  assertion, or `it(...)`/`describe(...)` description was touched.
