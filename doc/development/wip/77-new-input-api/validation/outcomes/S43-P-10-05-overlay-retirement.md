# S43-P-10-05 — overlay retirement (outcome)

Worker: Sonnet. Prompt: `../prompts/S43-P-10-05-overlay-retirement.md`.

## Result

- **Occurrences in scope at start:** 130 (case-insensitive `overlay`, across
  `doc/input_api.md`, `doc/development/internals/`, `doc/development/decisions/`,
  `doc/development/technical_debt/`, `doc/development/tests.md`,
  `doc/development/conventions/` — the last had zero hits).
- **Changed:** 96 word-instances, across 11 files (9 doc files in scope, plus
  two mandated citation fixes outside scope — see "Heading renames" below).
- **Left as-is, deliberately:** 34. Full reasons below.
- **Suite:** `busted tests` → `968 successes / 0 failures / 0 errors / 10 pending`
  — identical to baseline. No test or `src/` *behaviour* was touched; the two
  `src/`/`tests/` edits are comment-text-only (heading citations, see below).
- **Commit:** `9254b524` — `docs(input): retire 'overlay' from the persistent
  docs in favour of 'input widget'`.

## Rule applied

Per file, per sentence: is this passage about the project-facing **input
widget**, or about the console's own drawing/compositing layer?

- Project-facing widget → the word "overlay" is replaced by "widget" (or
  "input widget" on first/ambiguous mention), matching the vocabulary
  `doc/input_api.md` already uses for the same concept.
- Console's own drawing layer (the widget's on-screen paint/composite,
  specifically) → replaced with the implementation's own name,
  `` `input_widget_overlay` ``, per the prompt's carve-out.
- Identifiers, file names, quoted source strings that are still accurate, and
  code samples (including comments inside fenced code blocks) → untouched.
- A second, distinct sense of "overlay" appears in a few places — a
  **project's own on-screen UI panel** (e.g. the keyboard example's help
  screen) that has nothing to do with `compy.input`'s widget. Left alone: same
  English word, different referent, out of this retirement's mandate.

## Heading renames

Two headings were renamed as their own REMARK markers explicitly asked for,
after confirming (via repo-wide grep) that no citation outside
`doc/development/wip/` (out of scope, scratch, deleted at feature end) quoted
the full heading text — so no cascade:

1. `doc/input_api.md`: `## Opening the overlay from a key` →
   `## Opening the input widget from a key`. Citations fixed in the same
   commit:
   - `doc/input_api.md:172` (self-citation, "see ... below")
   - `doc/development/internals/examples/turtle.md:48`
   - `doc/development/technical_debt/input.md:543` and `:749`
   - `src/examples/turtle/main.lua:48` — a comment; the heading-trap rule in
     the prompt explicitly requires fixing citations in `src/`/`tests/` too,
     even though those directories are otherwise out of this task's scope.
     Comment-text-only, no behaviour change.
   - `tests/input/input_widget_control_spec.lua:547` — same: comment-only.

2. `doc/development/technical_debt/input.md`: `### An overlay opened from a
   key can receive that key's own echo` → `### A widget opened from a key can
   receive that key's own echo`. Citation fixed at `technical_debt/input.md:749`
   (same file, cross-referencing itself).

Two further headings were renamed with **no citations to fix** (grep found
none outside `wip/`):

3. `doc/development/internals/console.md`: `` ## The `user_input` Overlay ``
   → `` ## The `user_input` Widget ``.
4. `doc/development/internals/user_input.md`: `` ## The `user_input` Overlay
   — Input Perspective `` → `` ## The `user_input` Widget — Input
   Perspective ``. (This section's REMARK explicitly asked to retire
   "overlay" "except contextually, for how the widget is drawn" — but the
   section itself covers lifecycle/dispatch/submit-cancel, not drawing, so
   the plain "Widget" rename was correct; the one genuinely-drawing-layer
   sentence inside it, about the per-frame-render workaround, got
   `` `input_widget_overlay` `` instead — see below.)
5. `doc/development/technical_debt/input.md`: `### Overlay-shape test
   exercises a stub, not the real draw wiring` → `` ### The
   `input_widget_overlay` shape test exercises a stub, not the real draw
   wiring `` — this section is specifically about the draw-wrapper test gap,
   so it got the identifier form rather than plain "widget".
6. `doc/development/decisions/input.md`: `## Decision 18 — the overlay
   answers one state question: `is_shown()`` → `## Decision 18 — the widget
   answers one state question: `is_shown()``. Not a cascade risk: every other
   citation in the corpus refers to it only as "(Decision 18)", never by the
   full heading text.

No heading rename was skipped for cascading beyond "a handful" — every
citation found was fixable in-commit.

## One factual correction made along the way

`doc/development/internals/user_input.md:631` quoted
`Log.warn('UserInputController:show ignored — overlay already active...')`
as the literal source text. The actual source
(`src/controller/userInputController.lua:271-272`) already says `'...widget
already active...'` — the doc's quote had drifted stale before this pass.
Fixed to match the real string, which also happens to retire the word.

## Left alone — the list that matters

**REMARK/INTERIM markers (9 word-instances, untouched per the prompt's own
rule):** `doc/input_api.md:258,322`; `doc/development/internals/user_input.md:12,24,95,135,606`;
`doc/development/decisions/input.md:775`; `doc/development/internals/examples/guess.md:5`.
Several of these are the *source* of the retirement instruction itself —
editing them would delete the paper trail for why the change was made.

**Code samples — fenced blocks, including comments inside them (5):**
`doc/input_api.md:160,245` (Lua comments inside ` ```lua ` examples);
`doc/development/internals/user_input.md:37,168` (an ASCII dispatch-chain
diagram inside a plain fenced block); `doc/development/internals/examples/turtle.md:28`
(a Lua comment inside a code sample). The prompt's own rule groups "code
samples" as non-prose alongside identifiers — comments inside a fenced block
are part of the sample, not free text, so they stay verbatim even where the
prose immediately outside the fence was changed. Flagging this explicitly
since it is a judgment call, not a mechanical one: these comments *do* leak
the word to a reader, same as the prose did, but the fence makes them code.

**Deliberate `input_widget_overlay` identifier — console's own drawing layer
(11):** `doc/development/internals/console.md:113` (the widget model drawn
on top of the console); `doc/development/decisions/input.md:593` and
`doc/development/technical_debt/input.md:1400` (the same per-frame-render
`update_view()` workaround, described in two places — kept the identifier
consistent across both); `doc/development/technical_debt/input.md:477,483,526,801,803,811,814`
(the "overlay-paint fix" / "unpainted overlay" / the draw-wrapper test gap
section — all specifically about the widget's on-screen paint path, the
carve-out this task's own rule anticipated).

**A file name, not prose (1):** `doc/development/technical_debt/input.md:806`
— `` `overlay_spec.lua` `` is the actual (now-deleted) test file's name,
quoted as history. Identifiers/file names stay exactly as written per the
prompt.

**A different referent entirely — a project's own on-screen UI panel, not
the framework's input widget (7):** `doc/development/decisions/input.md:1305`
("rendered into a help overlay" — an illustrative example of a keybinding
help screen); `doc/development/technical_debt/input.md:1107,1211` (the
`examples/keyboard` project's own Alt+H help screen); `doc/development/internals/examples/keyboard.md:60`
(same help screen, 2 instances on one line); `doc/development/internals/examples/turtle.md:9,59`
("debug overlay" — the turtle example's own `drawDebuginfo()` panel, toggled
by `space`). None of these are `compy.input`'s widget; they are each
project's own drawn UI, described in ordinary English. Renaming them would
conflate two unrelated concepts that happen to share a word — explicitly out
of this retirement's mandate ("the project-facing thing is an input
widget" — these panels are not it).

**A literal historical quote (1):** `doc/development/tests.md:77` — the
sentence quotes, verbatim, the title of a row that used to exist in an
*earlier version of this same doc* ("Not covered: `user_input` overlay API").
It is presented in quotes specifically as a historical artifact ("...no
longer applies"), not as current terminology — rewriting the quote would
misrepresent what that earlier row actually said.

## Files changed

- `doc/input_api.md`
- `doc/development/internals/console.md`
- `doc/development/internals/user_input.md`
- `doc/development/decisions/input.md`
- `doc/development/technical_debt/input.md`
- `doc/development/tests.md`
- `doc/development/internals/examples/guess.md`
- `doc/development/internals/examples/repl.md`
- `doc/development/internals/examples/turtle.md`
- `src/examples/turtle/main.lua` (comment only, heading-citation fix)
- `tests/input/input_widget_control_spec.lua` (comment only, heading-citation fix)

## Note on the commit

Committed as `9254b524`, staging exactly the 11 files above by explicit path
(never `git add .`), not pushed. This report itself is intentionally left
uncommitted, per the prompt.
