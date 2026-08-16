# P-23-03 — cold review of the Ctrl+S relocation (outcome)

Worker: Sonnet, read-only. Commits reviewed: `cb6b867e` (move editor's Ctrl+S
meanings out of the gate) and `5e6ad8c2` (extract `_save_keys`).

## Verdict

**Faithful move, exactly one intended behaviour change, in the code.**
Branch-by-branch comparison of the pre-change gate block
(`git show cb6b867e^:src/controller/controller.lua`, lines 813–823) against
`EditorController:_save_keys` + its call site confirms: Alt exclusion,
Shift's meaning (finish_edit vs close_buffer), and reachability across all
of the editor's internal sub-modes (reorder/search/normal — the gate never
saw these either, so nothing changed there) are all preserved exactly. The
one behavioural difference — Ctrl+Shift+S no longer stops a running
project — is confirmed as the *only* one across all four modifier
combinations (`ctrl+s`, `ctrl+shift+s`, `ctrl+alt+s`,
`ctrl+alt+shift+s`) in all five states the gate can see (`running`,
`project_open`, `editor`, `ready`, `inspect`): neither the pre- nor
post-change inner `if/elseif` ever branched on `project_open`, `ready`, or
`inspect` for `k == "s"`, and Alt was excluded identically before and
after. Pen-and-paper projects: `project_open` is untouched by both commits
(diff confirms `ProjectInputController` has zero changes), and the gate's
`k == "s"` block never had a `project_open` case in either version, so a
project's own `ctrl+s` binding is unaffected — confirmed structurally, not
just by commit-message claim.

However: **two now-stale claims exist in files adjacent to, but not
touched by, the diff** — a doc and a test comment, both invalidated as a
side effect of the move even though neither commit edited them. Reported
below as findings; nothing in executable behaviour is wrong.

## Findings

### S2 — `doc/development/internals/user_input.md:199` now misdescribes where Ctrl+S's editor semantics live

> "Global shortcuts intercepted in `love.handlers.keypressed`
> (`controller.lua:797+`) before anything reaches the active route's
> controller: Ctrl+Pause suspends, Ctrl+Q quits project, **Ctrl+S stops run
> or closes buffer**, Ctrl+Shift+R resets application, ..."

This is the exact stale-claim shape the review was commissioned to look
for: post-`cb6b867e`, "closes buffer" (and finish_edit) is no longer
gate/pre-dispatch behaviour — it is `EditorController:keypressed`'s own
business (`src/controller/editorController.lua:814-822`), reached only
after the active route already has the event. `internals/user_input.md` is
exactly the doc this project's own CLAUDE.md tells an agent to trust first
for "how does X reach Y" questions, so this line will actively mislead the
next reader into re-deriving the wrong control-flow picture. Fix is
narrow: drop "or closes buffer" from the gate's list (or add a clause that
editor's own Ctrl+S/Ctrl+Shift+S is route-level, per Decision 33's scope
note two sections earlier in `decisions/input.md:1489-1493`, which already
draws this exact distinction).

### S2 — `tests/input/input_global_shortcuts_spec.lua:182-185` comment's premise no longer holds

```
182   -- Shift stays meaningful in the editor branch (finish
183   -- edit vs close buffer); exactness excludes Alt only.
184   -- Exercised through the simpler running-state branch,
185   -- which shares the same outer condition.
186   it('ctrl+s still stops a running project', function()
```

Written by `77aed369` (13:46, before either reviewed commit) when the
running and editor branches genuinely did share one outer condition
(`Key.ctrl() and not Key.alt() and k == "s"` in the old gate). `cb6b867e`
made the running branch's condition exact (`only_mods(true, false,
false)`) while the editor branch's condition, now in
`EditorController:_save_keys`, stayed permissive (`Key.ctrl() and not
Key.alt()`, Shift still meaningful there). The two conditions have
diverged — they no longer "share" anything — but the comment asserting
that they do was never touched by either commit under review, so it reads
as current and is wrong. The test itself still passes and asserts the
right thing; only the comment's claim is now false. Low-cost fix: drop the
"which shares the same outer condition" sentence, since the payload it
carried (why this test doesn't also press Shift) is already covered by the
adjacent tests at lines 212-263 that exercise Shift directly in both
branches.

### S3 — `doc/development/decisions/input.md` Decision 33's example list is now incomplete, not wrong

Decision 33 ("What this changes", lines 1481-1484) names "Ctrl+Shift+Escape,
Ctrl+Shift+T and Ctrl+Alt+Shift+R" as the combos that stop being the
framework's exclusively once reservations become exact. That list was
written (`098b3cdb`) before the ctrl+s reservation was swept — at the time,
`ctrl+s` was deliberately left permissive (test `2b89bba8` pinned Shift as
meaningful there, comment `802ff1a4` called `only_mods` "now-stale" for
it). `cb6b867e` completes that deferred sweep for `ctrl+s`, so
Ctrl+Shift+S now also "stops being the framework's" in the `running`
state, exactly the pattern the decision describes, but the illustrative
list was never extended to say so. This is not a false claim (the decision
never claimed to be exhaustive, and its separate "Scope" paragraph
correctly excludes editor/console route-level Ctrl+S from Decision 33
entirely) — just a list a reader could take as complete and isn't. Lowest
severity of the three; optional to fix.

## Verified clean

- **Branch parity** (check 1): confirmed via direct diff of
  `cb6b867e^:src/controller/controller.lua` lines 811-823 against
  `editorController.lua:814-822` + call site at `:829-837`. No drift in
  what any branch does or when it is reached (editor sub-mode
  reachability unchanged; Ctrl-block in `EditorController:keypressed` was
  already unconditional on `mode` before this diff, for `ctrl+m`/`ctrl+f`).
- **Reach of the one behaviour change** (check 2): matrix of
  `{ctrl+s, ctrl+shift+s, ctrl+alt+s, ctrl+alt+shift+s}` ×
  `{running, project_open, editor, ready, inspect}` walked directly against
  both `only_mods` conditions; only `running` + `ctrl+shift+s` differs.
  Covered by tests at `input_global_shortcuts_spec.lua:186-263` (still
  stops on plain ctrl+s while running; no longer stops on ctrl+shift+s or
  ctrl+alt+s; editor branch unchanged for both ctrl+s and ctrl+shift+s).
- **Pen-and-paper / `project_open`** (check 3): `ProjectInputController`
  has zero diff across both commits; the gate's `k == "s"` inner
  conditional never had (before or after) a `project_open` case, so a
  live project's own `ctrl+s` shortcut binding is reached exactly as
  before, through the unchanged forwarding path.
- **Who calls what** (check 5): `mcp__lua-lsp__references` on
  `finish_edit` and `close_buffer` shows no orphaned or newly-broken
  caller; `EditorController:_save_keys` reaches them via
  `self.console:finish_edit()` / `self.console:close_buffer()`, the exact
  idiom already used at `editorController.lua:126`
  (`EditorController:close_buffer` → `self.console:finish_edit()`).
  `mcp__lua-lsp__diagnostics` on both changed files: zero new diagnostics
  in `editorController.lua`; `controller.lua`'s 21 diagnostics are all
  pre-existing and none touch the changed lines (811-822).
- **Limits and hygiene** (check 6): both changed files' touched lines are
  ≤64 chars (checked programmatically); `_save_keys` body is 7 lines, 1
  param, nesting depth 2 — comfortably under the 14/4/4 limits.
  `EditorController:keypressed` measured at 29 body lines exactly (31 total
  incl. signature/`end`), matching the "28 pre-existing + 1 call" claim —
  correctly left unrestructured, not reported as debt.
- **Suite**: `busted tests` → `968 successes / 0 failures / 0 errors / 10
  pending`, the same seven `pending(...)` outlines (`input_global_
  shortcuts_spec.lua` ctrl+alt+r/ctrl+t/profiler/f10/ctrl+s/ctrl+shift+r/
  ctrl+escape rows, plus the three `input_routing_spec.lua` rows) —
  untouched.
- **`doc/development/internals/editor.md:162`** ("Ctrl+S (`close_buffer`)
  pops the front buffer...") — still accurate; if anything it now
  describes the code's actual location *better* than before, since the
  behaviour it names is literally in `EditorController` now.
  `console.md:29` and the two `mermaid/fsm*.md` files' `finish_edit()`
  transition labels are state-machine-level and unaffected by which
  controller calls the method.

## Not checked / lower confidence

- No interactive/headless `love src` run was performed to visually confirm
  the buffer-close/finish-edit UI transition; relied on the unit suite
  (which does stub `finish_edit`/`close_buffer` and assert the branch
  taken, per `input_global_shortcuts_spec.lua:234-263`) plus static/LSP
  analysis.
- Did not audit every `doc/development/wip/77-new-input-api/**` session
  log or validation-outcome file for Ctrl+S mentions — those are dated,
  append-only records of past sessions, not living reference docs, so a
  "stale" mention there (e.g. describing the gate as it was *at that
  session's time*) is not a defect. Grep was run broadly (listed ~90
  files); the ones inspected in depth were the non-`wip` reference docs
  plus the `wip/.../design/` and `decisions/` documents most likely to be
  treated as current.
- Did not re-verify the line-number citations in `user_input.md:199`
  (`controller.lua:797+`) and elsewhere (`:910-920` for `keyreleased`) —
  the latter has drifted more than these two commits alone account for
  (cumulative drift from the whole exactness-sweep sequence this session),
  so it is pre-existing and out of this review's scope.
