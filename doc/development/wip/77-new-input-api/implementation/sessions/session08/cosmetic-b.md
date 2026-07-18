# Session 08 — cosmetic pass B

Files: `src/model/input/userInputModel.lua`,
`src/view/input/userInputView.lua`, `src/util/key.lua`, plus the
sweep-only list. Comments only; no executable code or identifier
touched. Line numbers below are post-edit unless marked (pre).

## 1. Remarks fixed and deleted

- `userInputModel.lua:411` (pre) `REVIEW/DOC "AC-25"` — wrapped
  the `AC-25` ref in the keep_history comment as
  `{badspecref: AC-25}`, rewrapped the block to <=64; deleted
  the REVIEW/DOC line.
- `userInputModel.lua:512` (pre) `REVIEW/DOC "AC-8, M7-01"` —
  wrapped both refs in the `_clamp_cursor_pos` doc block;
  deleted the REVIEW/DOC line.
- `userInputModel.lua:579` (pre) `REVIEW/DOC annotate
  two-dimensional limit logic` — replaced with a written
  explanation of `is_at_limit` (verified against the body):
  up/down/nil compare the line only; left/right at scope
  'line' need only the column edge, at scope 'input' (default,
  forced when single-line) the line must be an edge too, so
  left-at-very-start doubles as 'up' and right-at-very-end as
  'down'.
- `userInputModel.lua:832` (pre) `REVIEW/DOC "AC-25"` — wrapped
  the ref in the `_report_parse_error` doc block; deleted.
- `userInputModel.lua:866` (pre) `REVIEW/DOC "AC-25"` — wrapped
  `AC-25` and `spec §5` in the `handle()` comment; deleted.
- `userInputView.lua:285` (pre) `REVIEW/DOC interim refs /
  commit ref` — wrapped `M6-01`, `AC-25`, `commit 7b4422c` in
  the `draw()` comment; deleted the REVIEW/DOC line.
- `userInputView.lua:294` (pre) `REVIEW/DOCS avoid
  'slot'/'overlay'` — reworded "the published overlay
  singleton" to "the published input widget singleton";
  'slot' did not occur outside the remark itself; deleted.
- `key.lua:51` (pre) `REVIEW/DOC spec ref` — wrapped `spec §1`
  in the `normalize_combo` doc block; deleted.
- `key.lua:68` (pre) `REVIEW/DOC spec ref` — wrapped `spec §1`
  and `R14` (separately) in the `new_handler_table` doc block;
  deleted.

## 2. Inventory of added markers + FIX PLAN (propose only)

No `{jargon:}` wraps were needed: the only jargon hit
('overlay', view draw block) had an explicit REVIEW asking for
removal, so it was reworded plainly instead.

| Marker (file:line) | Meant (per frozen design) | Proposed persistent target |
|---|---|---|
| `{badspecref: AC-25}` — userInputModel.lua:413, 843, 872 | M5c spec: `oneshot` flag removed, `push('userinput')` retired in favour of the submit-callback chain | `doc/development/decisions/input.md` Decision 4 (callbacks replace polling) + Decision 6 (framework-tier submit/cancel); the dead `push('userinput')` remnant is `doc/development/technical_debt/input.md` §"`love.handlers.userinput` is dead code" |
| `{badspecref: spec §5}` — userInputModel.lua:876 | spec.md §5 submit mechanism ("value ready" via on_text_entered) | `doc/input_api.md` §"The submit lifecycle" / §"Two callback families" |
| `{badspecref: AC-8}` — userInputModel.lua:514 | M7 spec: `set_text(t, true)` preserves cursor, clamped to new content | `doc/input_api.md` §"Live reconfigure: `configure`, `set_text`, `clear`, cursor" |
| `{badspecref: M7-01}` — userInputModel.lua:516 | spec/M7-01-retarget.md (cursor-preserve retarget) | same as AC-8; internals detail in `doc/development/internals/user_input.md` §"Cursor manipulation and 'reset'" |
| `{badspecref: M6-01}` — userInputView.lua:286 | roadmap adjacent: view `oneshot` snapshot removal riding M5c | `doc/development/internals/user_input.md` §"The `user_input` Overlay — Input Perspective" (singleton lifecycle / draw wiring); related debt: technical_debt/input.md §"Overlay-shape test exercises a stub" |
| `{badspecref: AC-25}` — userInputView.lua:287 | as above | as AC-25 above |
| `{badspecref: commit 7b4422c}` — userInputView.lua:291 | commit that introduced the redraw-skip workaround | no persistent target possible — propose dropping the commit ref and keeping only the quoted "transitional workaround" wording (pending the conceptual REVIEW just below it) |
| `{badspecref: 0.1.0-m2a}` — key.lua:15 | pre-#77 milestone when mod folding was centralised | no persistent target — propose plain words: "centralised here; previously a duplicate COMBO_MODS literal in controller.lua" |
| `{badspecref: spec §1}` — key.lua:25, 53 | spec.md §1 combo canonical form and modifier precedence | `doc/development/decisions/input.md` Decision 8 (canonical combo serialisation); user-facing form: `doc/input_api.md` §"Combo key handlers" |
| `{badspecref: spec §1}`, `{badspecref: R14}` — key.lua:72 | R14 = per-event handler tables (one table per channel) | `doc/development/decisions/input.md` Decision 8 (per-event combo tables) |
| `{badspecref: M8-01}` — examples guess/main.lua:49, tixy/main.lua:171, valid/main.lua:73, repl/main.lua:1 | spec/M8-01: legacy removal, examples migrated to the continuous-session idiom | `doc/input_api.md` §"The continuous-session idiom" |

Sweep-only files with zero findings: `consoleModel.lua`,
`searchModel.lua`, `examples/turtle/main.lua`.

## 3. Remarks left as conceptual (untouched)

- `userInputModel.lua:411` history lifecycle across
  re-arm/cancel/submit/reconfigure/project churn.
- `userInputModel.lua:599` `'req'` local rename.
- `userInputModel.lua:838` love.harmony.utils interaction gone
  — behaviour question.
- `userInputModel.lua:839` `report_parse_error` →
  `_move_cursor_to_err_pos` rename.
- `userInputModel.lua:893` cross-file comment/annotation
  ordering — covered as plan item in §5 below.
- `userInputView.lua:294` redraw-skip justification /
  singleton-identity check survival.
- `key.lua:70` validator decision-tree proposal.
- `key.lua:123` `mod_triples` rename.

## 4. Skipped as uncertain

None. The one explanation-request (is_at_limit) was verifiable
directly from the function body and was written.

## 5. Comment/annotation ordering observations (for the plan)

Orderings seen in my three files:

1. prose description first, annotations last — key.lua
   `normalize_combo`, `new_handler_table`; model
   `is_at_limit` (incl. the block written this session).
2. annotations first, prose after, directly above the
   function — model `keep_history` (`@return` then `--`
   prose), `handle()` (`@param`/`@return` then the AC-25
   block).
3. interleaved — model `_report_parse_error` (`@private`,
   prose, then `@param`); `_clamp_cursor_pos` (`@private`
   then prose).
4. marker drift: annotations are `---` (LuaCATS); prose is
   sometimes `---` (key.lua, `_clamp_cursor_pos`) and
   sometimes `--` (`keep_history`, `handle`, view `draw`).

Proposed normal form: `---` prose description first, then
`@private`, then `@param`s, `@return`s last; never a plain
`--` line inside a `---` annotation block (lua-language-server
attaches the doc block to the next statement and a non-`---`
line can split it). REVIEW lines currently sit above the
blocks and are unaffected.

## 6. Verification

`busted tests` from /repo:
815 successes / 0 failures / 0 errors / 4 pending
(pendings are pre-existing `pending()` rows in
`tests/input/input_contracts_spec.lua`).
