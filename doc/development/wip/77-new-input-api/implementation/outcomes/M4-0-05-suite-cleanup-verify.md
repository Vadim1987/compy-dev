# Outcome — M4-0-05: contract-suite cleanup (run + mend)

_Executed by LLM (Claude Sonnet 5). Verification-only slice; no `src/`
change. Awaiting human approval._

## Result

`busted tests`: **718 successes / 0 failures / 0 errors / 12 pending**
— matches the prompt's expected result exactly (baseline 717/9 +1 test
+3 pending). Hard limits hold on the two changed files (see below).

**No mechanical breakage found. No fixes, no fallbacks needed.**

## What was verified

The rewrite in question is commit `bc32d89` ("fable5 rewrote prompts
and strengthened spec"), which restructured
`tests/input/input_contracts_spec.lua` and extracted
`restore_native_slots()` from `F.reset()` in
`tests/helpers/input_fixture.lua` per `reviews/M4-0-04.md` finding 2.

- **Hard limits, content added by `bc32d89` only**
  (`git diff bc32d89^..bc32d89`, added lines, codepoint length): **0**
  lines over 64 codepoints. (Pre-existing boilerplate in
  `input_fixture.lua` still carries its known ~14 over-length lines,
  untouched by this diff — same as noted in `reviews/M4-0-04.md`.)
- `F.reset()`: 12 code-statement lines (was 16, breaching the review's
  finding 2); `restore_native_slots()`: 5 lines. Both within the
  14-line function-body limit.
- The four **deliberate changes** the prompt calls out were each
  read directly and confirmed present exactly as described — no
  fallback needed for any of them:
  1. `it('routes keys to the editor', ...)` (line 130): types `q`,
     presses `backspace`, asserts editor **and** console both empty.
     Sibling `it('routes text to the editor', ...)` (line 138) covers
     the textinput half.
  2. `it('a submit fills the handle and closes', ...)` (line 358):
     text arrives via `F.session.type('4')` / `type('2')` through the
     real gate, submit via `F.session.press('return')`.
  3. `it('the console receives after stop', ...)` (line 332): installs
     a real project handler via `F.running_project('keypressed', ...)`,
     calls `F.cc:stop_project_run()`, asserts `got == 0` (nothing
     delivered to the stopped project's handler afterward).
  4. `it('routes the pointer to the console', ...)` (line 108):
     `assert.is_false(F.console.model:has_selection())` sits before
     the `mousepressed`/`mousereleased` pair, pinning causality.
- `git diff --stat HEAD -- src/`: empty. No production code touched.

## Surfaced (out of scope for this slice, flagging for the

## orchestration plane)

`tests/input/input_contracts_spec.lua` currently carries **two new
`-- REVIEW:` comments** (lines 496, 698), added by the human directly
in commit `d708259` — *after* the `bc32d89` rewrite this prompt asked
me to verify, and not part of the "Files changed" scope this prompt
describes as already resolved. Both are open questions for a human/
design call (relocating an editor block-nav test out of the input
suite; whether a native-handler-coexistence test is meaningful as
written) — not mechanical breakage, so left untouched per the triage
rule ("anything semantic: stop, do not weaken/delete, record it").
Also incidentally: both comment lines are far over the 64-char limit,
but they are human-authored review prose, not suite content, so out of
this slice's mend authority.

## Commit

No commit made — nothing needed mending, so there is no diff to
commit for this slice. (The prompt's "commit only if green" implicitly
assumes there was something to fix; a clean verify run has no working
tree change to commit.)
