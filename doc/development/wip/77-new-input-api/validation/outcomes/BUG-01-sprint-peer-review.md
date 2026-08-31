# BUG-01 sprint — cold peer review

**Verdict: approve with comments.** All three platform fixes do fix
their rows, are minimal, and are correctly test-pinned; the balloons
change is behaviour-preserving. Three things need action before the PR
description ships: a **false statement in `doc/input_api.md`** (and in
the `BUG-01-04` commit message) about what a shortcut handler can see, a
**byte-column caller the `BUG-01-05` fix left behind and the commit
message denies exists**, and the **`wontfix` on `BUG-01-11` resting on a
justification that a traced path falsifies** (the ruling may stand; the
reason given does not).

Reviewed cold: I did not open session60's track/prompt/report, the
RETIRED section of `technical_debt/input.md`, the maze weighing note, the
`BUG-01-0*-evidence.md` files, or the ROADMAP BUG-01 closure text. I did
read the commit messages, as instructed, and I test them below.

Container is **LuaJIT**; the owner runs **PUC Lua**. Suite here:
`1030 successes / 0 failures / 0 errors / 10 pending` — exactly the
expected numbers, the 10 pending are the known owner ruling, no 11th.
Runtime-divergence notes are called out where they apply (§2.3, §7).

---

## Findings, ranked

| # | severity | defect/taste | where | what |
|---|---|---|---|---|
| F1 | **high** | defect | `src/examples/maze/maze_logic.lua:163-165,185,302-316` + `controls.lua:11` | `BUG-01-11`'s `wontfix` is justified as "no double-handling, **by construction**". It is not by construction: `jump_level` → `start_level` → `cur_controls()` re-arms `ctrl_pressed = handle_key` **without hiding the widget**. Reachable today: sandbox track, from any editor level type `3,` → level 1 (`intro`, `controls = keys`). Every later key then moves the robot *and* is typed into the still-open widget. |
| F2 | **medium** | defect | `doc/input_api.md:429-430` (and commit `4a58b996`) | "A shortcut therefore cannot tell the two cases apart; if your project needs to, read the character in `hooks.textinput`." **False.** `dispatch` calls `sc(...)` with the raw payload (`projectInputController.lua:140`); probed: a `textinput['Shift+I']` handler receives `'I'`. The doc contradicts itself four lines later at `:433`. |
| F3 | **medium** | defect | `src/model/input/userInputModel.lua:868` | The `BUG-01-05` fix missed one of the 18 `move_cursor` callers. `_apply_eval` passes `perr.c`, which is a **byte** column (probed: `LuaSyntaxValidator` returns `c=20` for `x = "привет" +`, a 14-character line), into the now-character bound. Console/editor `evaluate()` path. Commit `e75a48d8`'s "the internal callers pass character values, so nothing that passed before is refused now" is wrong for this one. |
| F4 | **medium** | defect (doc) | `doc/input_api.md:203-206` | "**Every** cursor position the widget reports or accepts is counted this way." The framework's own `LuaSyntaxValidator` emits byte columns, and `userInputView.lua:183-184` compares that byte column `ec` against a **character** index `c` (`:166`, `for c = 1, string.ulen(s)`), so the error underline is misplaced on non-ASCII lines. Pre-existing defect, but the new paragraph promises it away. |
| F5 | **low** | defect (message) | commit `32f8345d` | "`show{text = …}` **and `configure{text = …}`** both land in **`apply_config`** → `set_text`". Two errors: `configure{text=…}` **raises** (`consoleController.lua:599-603,627,646-650`), and `apply_config` no longer exists — the path is `api_show` → `open_widget` → `reset_content` (`userInputController.lua:312-318,330-331`). Going into a PR description as written. |
| F6 | **low** | defect (house rule) | `tests/input/input_widget_control_spec.lua:56` | New line is 69 characters; the limit is 64. The only new over-length line in the sprint. |
| F7 | **low** | defect | `src/model/input/userInputModel.lua:145-151` | The `BUG-01-09` fix routed the **string** branch through `string.lines`; the **table** branch still stores an element verbatim, so `set_text({'a\nb'})` writes a single line containing a newline. Asymmetric with `add_text` (`userInputController.lua:103` normalises via `string.unlines`). Pre-existing, out of the row's letter, in the row's spirit. |
| F8 | **low** | taste | `src/model/input/userInputModel.lua:537,554`, `userInputController.lua:198` | `string.ulen` returns `nil` (not `0`) for invalid UTF-8, so `llen + 1` would raise where `#` could not. Unreachable today (every writer sanitises), but it is a new failure *shape* on three clamps. |
| F9 | **info** | taste | `tests/input/input_combo_serialisation_spec.lua:69-77` | The two serialisation tests pin one half of an agreement (`cs('I') == 'i'`) rather than the agreement itself; they would still pass if registration flipped to preserving case. The end-to-end test at `input_events_spec.lua:281-293` does cover the contract, so this is coverage shape, not a gap. `normalize_combo` is file-local (`key.lua:67`), so a direct cross-check is not currently writable. |
| F10 | **info** | — | `src/examples/tixy/main.lua:39` | Undocumented (good) behaviour change: `compy.input.set_text(body)` in `load_example` was a silent no-op for multi-line example code and now works. Worth a line in the smoke pass, not in the CHANGELOG. |

Nothing here is a blocker on the fixes themselves. F1, F2, F3 and F5 are
what I would want changed before the PR text is written.

---

## 1. Does each fix actually fix its row?

Read against the pre-sprint row text in the spec file, code first.

**`BUG-01-09` — `set_text` drops a multi-line string. Fixed.**
`userInputModel.lua:141` now reads
`self.entered = InputText(string.lines(sanitize_utf8(text)))`. The row's
reproduction (`show{text='previous'}` → `hide()` → `show{text='a\nb'}`)
is closed: `api_show` → `open_widget` → `reset_content`
(`userInputController.lua:312-318`) → `set_text`. The row's `:125-134`
guard is gone entirely rather than extended, which is the right shape —
the table branch already did exactly this.

**`BUG-01-04` — a `textinput` shortcut cannot bind an upper-case
character. Fixed.** `controller.lua:396` is now
`return combo .. k:lower()`. Registration lower-cases the whole combo
(`key.lua:48`, `combo:lower():gmatch`, via `normalize_combo` at `:67` and
`new_handler_table`'s `__newindex` at `:115-118`), so the two sides now
agree. Probed end to end: `shortcuts.textinput['Shift+I']` + `lshift` +
`type('I')` fires.

**`BUG-01-05` — `set_cursor` clamps bytes. Fixed, with one caller left
behind (F3).** Three sites moved from `#` to `string.ulen`:
`userInputController.lua:198`, `userInputModel.lua:537` and `:554`. The
row framed this as an open design call ("which is right is a small design
call"); the fix's claim that the unit was already decided is **correct** —
`userInputModel.lua` lines 112, 131, 314, 339, 501, 615, 643, 677, 693,
735, 751, 784, 822, 955 and `userInputView.lua:58,160,335` all count
characters. There was one outlier and two new copies of it, not a
disagreement.

**`BUG-01-07` — balloons shadow label. Fixed.** `ui.lua:52-53`,
`ui_set_hint` now delegates straight to `ui.terminal.write`. Verified no
reader of `ui_messages.hint` survives anywhere in the repo, and
`ui_draw_hint` had exactly one caller at `6d6c6e3` (inside `ui_set_hint`
itself — the row's "re-pushes it every game cycle" was loose; it was once
per state transition). The dropped `or "         "` fallback is
unreachable: all three `ui_set_hint` call sites pass a non-nil constant
or `fmt(...)` (`main.lua:49`, `ui.lua:67`, `ui.lua:71`). `terminal_write`'s
`flushed` and `ui_set_hint`'s stray second argument are both gone, with
no caller left passing two arguments. `ui_messages.results` (never
assigned; `.result` singular is the real field, still used at `ui.lua:61`
and `:91`) is correctly removed and its branch was provably dead.

**`BUG-01-11` — `wontfix`.** See §5. The outcome is the owner's; the
stated reason is falsifiable and I falsified it.

---

## 2. Correctness and completeness

### 2.1 `BUG-01-09` — sibling paths and edges

Checked, and **sound**:

- **Sibling writers.** `add_text` (`:100-135`) already split multi-line
  input. `_set_text_line` (`:165-182`) is line-scoped by contract. The
  only other `set_text` callers in the model are `history_back`/
  `history_fwd` (`:457`, `:469`), which pass an `InputText` — the
  **table** branch, unchanged. So **the console's history recall is
  untouched by this fix**, which is the thing I most expected to have
  moved.
- **The editor is untouched too.** `editorController.lua:336`
  (`inter:set_text(pretty)`, `Printer` is `fun(...): string[]`,
  `types.lua:168`) and `:602` (`input:set_text(t)` where
  `BufferModel:get_selected_text` returns `string[]`, `bufferModel.lua:286`)
  are both the table branch.
- **Edges, probed.** `set_text('')` → one empty line (`string.split`
  returns `{''}` for empty, `string.lua:229-231`) — identical to the old
  single-line branch, no regression. `set_text('a\n')` → `{'a', ''}`,
  cursor `2,1`. `set_text('\n')` → `{'', ''}`. Multi-byte:
  `set_text('пр\nи')` → `{'пр','и'}`, cursor `2,2`. `show{text='a\nb\nc',
  cursor={3,999}}` → cursor `3,4`. `set_text(multi, true)` clamps rather
  than jumps. All correct.
- `sanitize_utf8` before the split is right: `\n` is valid UTF-8, and the
  sanitiser only deletes invalid bytes (`:85-93`).

Not sound, minor: **F7**, the table branch still does not split embedded
newlines.

### 2.2 `BUG-01-04` — sibling paths and edges

Checked, and **sound**:

- **All four `combo_string` call sites.** `controller.lua:897` and `:921`
  index `RESERVED.keypressed` / `.keyreleased` with a LÖVE key constant
  (already lower), and neither table has a `textinput` channel
  (`:871-888`). `projectInputController.lua:110/113/115` is the project
  dispatch — the one that needed it. `'*'` lower-cases to itself, so the
  class lookup at `:110` and `:115` is unchanged.
- **Console and editor are unaffected**: the console's own keypressed
  hotkeys compare `k` directly (`controller.lua:492-515`), and shortcut
  tables exist only on the project route.
- **Registration/dispatch stay symmetric for non-ASCII**, because both
  now go through the same byte-wise `string.lower`. That matters: if only
  one side had been changed, `'ä'` would have desynchronised under any
  locale that folds high bytes.
- **Deletion still works**: `t['Shift+I'] = nil` fires `__newindex`
  (the raw key is absent) and rawsets `nil` on `'shift+i'`;
  `t['shift+i'] = nil` bypasses `__newindex` and clears directly.

Edge worth naming, very low: `string.lower` is `tolower` per byte and
therefore **locale-dependent**. Under `C`/`POSIX` (the default; neither
Lua nor LuaJIT calls `setlocale`) only ASCII `A-Z` folds and multi-byte
triggers pass through untouched. Under a single-byte non-UTF-8 locale a
high byte could fold and corrupt a sequence — but registration would
corrupt it identically, so the binding still matches. **Same on PUC Lua
and LuaJIT**; not a runtime split.

The behaviour genuinely changed and worth knowing: a bare
`shortcuts.textinput['i']` now **also fires on caps-locked `I`** (probed,
`true`). That is the documented intent, and it is new.

### 2.3 `BUG-01-05` — sibling paths and edges

Checked, and **sound**:

- **Completeness of the sweep.** Grepped every `#`-length in the input
  model/controller/`inputText`: what remains is `#lines`, `#t`, `#ent`,
  `#(self.error)`, `#wt`, `#values` — all table counts, no line lengths.
  No byte-clamp of a column survives.
- **All 18 internal `move_cursor` callers** re-checked. 17 pass
  character values computed with `ulen` or a `Cursor` field. One does
  not — **F3**, `_apply_eval:868`.
- **External entries** into the bound are exactly the two the row named:
  `consoleController.lua:771` (`compy.input.set_cursor`) and
  `open_widget:334` (`show{cursor=...}`), both through
  `set_cursor_pos` — both fixed.
- **A robustness gain nobody claimed**: `string.ulen(nil)` returns `0`
  (`string.lua:102-108`) where `#nil` raised. `move_cursor` accepts
  `l = n + 1` by design (`:548-553`) and then reads `get_text_line(l)`,
  which is `nil` there. That line used to be a latent crash; it isn't now.
  The mirror of that is **F8**.

Not sound: **F3** (byte column into a character bound — a real
console/editor behaviour change: on `x = "привет" +` the caret used to be
seated at byte column 21 of a 14-character line, i.e. past the end; it
now refuses the move and stays put. Both are wrong; the change is
undeclared) and **F4** (the view's error underline, `userInputView.lua:166`
vs `:183-184`).

PUC/LuaJIT note for F8: `string.ulen` resolves to the stdlib `utf8` under
PUC 5.3+ and to `lua-utf8`/LÖVE's `utf8` under LuaJIT
(`string.lua:2`, `utf.lua:3-5`). PUC's `utf8.len` returns `nil, pos` on
invalid input; a polyfill need not. So the three clamps could raise on one
runtime and not the other if invalid UTF-8 ever reached them. It does not
today — every writer sanitises — but the guard is now the sanitiser
rather than the operator.

---

## 3. Are the tests real?

**Yes — all five would fail against the pre-fix code, for the right
reason.** I derived each pre-fix value by hand from the base/pre-sprint
source rather than trusting the commit messages.

| test | pre-fix outcome | right reason? |
|---|---|---|
| `input_widget_control_spec.lua:56-61` | `{'previous'}` vs `{'a','b'}` | yes — the exact row reproduction |
| `input_cursor_text_spec.lua:213-224` | `{'hello'}` vs `{'a','b'}` | yes, and it additionally pins the cursor landing on the **last** line (2,2), which the single-line path could never have produced |
| `input_cursor_text_spec.lua:118-131` | `10` vs `7` (`#'привет'` = 12 → limit 13) | yes. The leading `set_cursor(1, 2)` is deliberate and correct: without it, `move_cursor`'s fallback-to-previous could produce a passing value for the wrong reason |
| `input_cursor_text_spec.lua:134-142` | `10` vs `7` via `_clamp_cursor_pos` | yes — the second, independent entry into the same bound |
| `input_combo_serialisation_spec.lua:70-77` | `'I'`, `'shift+I'` | yes |
| `input_events_spec.lua:281-293` | `fired == false` | yes — this is the contract-level one |

None of them asserts the implementation back to itself. The closest is
F9, noted as shape rather than gap. The comments on the new tests carry
information the code cannot (why a byte clamp would accept 13, why only
`textinput` can deliver a cased trigger) and cite canonical paths with
named sections.

**No test pins F3 or F4**, which is why they survived.

---

## 4. Provenance claims — all three checked against `3256aac`

| row | claim | verdict |
|---|---|---|
| `BUG-01-09` | inherited from the PR base | **CORRECT.** `git show 3256aac:src/model/input/userInputModel.lua` has `set_text` with `local lines = string.lines(text); local n_added = #lines; if n_added == 1 then self.entered = InputText({ text }) end` — the same guard in the same shape. |
| `BUG-01-04` | introduced by this feature | **CORRECT.** At base, `controller.lua` contains no `combo_string` and no `RESERVED` (zero matches for either), and `src/util/key.lua` is **53 lines** with zero matches for combo/normalise machinery. Both halves of the asymmetry are the feature's. |
| `BUG-01-05` | mixed | **CORRECT, and precisely so.** At base `userInputModel:move_cursor` exists with `local llen = #(self:get_text_line(l))` (base line 515) — inherited. `set_cursor_pos` does not exist in `userInputController.lua` at base (only the two-line `set_cursor(cursor)` at base 119-121), and `_clamp_cursor_pos` does not exist in the model — both ours. |

The PR description can carry all three as written. The commit-message
*narrative* around `BUG-01-09` cannot — see **F5**.

Bookkeeping nit: the brief says nine commits; `git log b5022530..HEAD`
shows ten. The tenth (`3c7b7954`, FIX-02-09 vocabulary ruling) is ledger
work outside the BUG-01 sprint and touches nothing in the reviewed
diff scope.

---

## 5. The `wontfix` on `BUG-01-11` — traced, and the justification fails

I read `controls.lua`, `maze_main.lua`, `draw_main.lua`, `core_editor.lua`
and followed the level machinery in `maze_logic.lua`/`levels.lua`.

**What the commits get right.** `ctrl_pressed` is maze's control-mode
slot, not a neutralisation idiom: `controls.lua:11,19` assign it,
`core_editor.lua:147` nils it because the editor mode *has* no key
handler. `core_editor.lua:68`'s `is_shown` is a show-vs-configure branch,
exactly as claimed, not a double-handling guard. The two disputed sites
(`maze_main.lua:124-126`, `draw_main.lua:231-233`) are mode exits that
call `compy.input.hide()` in the same breath. **`draw` is safe outright**:
every entry point (`startFreeDraw:190`, `startPictureLevel:199`,
`resetDrawProgramState:177`) goes through `editor()`, so
`draw_main.lua:366`'s `elseif ctrl_pressed then` is dead code.

**What fails.** "No double-handling, **by construction**" is false. The
invariant holds by *level data*, not by structure, and shipped level data
breaks it on one reachable path:

1. `maze_logic.lua:163-165` — `apply_attrs` only reassigns `cur_controls`
   when the level names one.
2. `maze_logic.lua:185` — `start_level` calls `cur_controls()`
   unconditionally. For a `keys` level that runs `controls.lua:11`,
   `ctrl_pressed = handle_key`.
3. **Nothing on that path hides the widget.** In the whole repo
   `compy.input.hide()` appears only at `maze_main.lua:126` and
   `draw_main.lua:233`, both inside the menu exits.
4. `maze_logic.lua:302-316` — `jump_level` (the editor's `,` / `.`
   commands, `CMD_HANDLERS` at `:344-352`) calls `start_level()` directly.
5. `levels.lua:185-202` — the `sandbox` track (`levels = sandbox`,
   `:802`; TRACKS entry 3, `:797`) runs `intro` (`controls = keys`,
   `:13`) at index 1 and turns editor at index 4 (`two_turns2`, `:48`).

So: pick track 3, reach `two_turns2`, type `3,` into the open widget and
submit. `process_input` queues the command, `execute_next` runs
`step_level` → `jump_level(-3)` → `start_level()` → `keys()`. The widget
was never hidden and `auto_hide` is never set, so it is still up with
`ctrl_pressed = handle_key`. From that frame on, `maze_main.lua:233`'s
hook runs `game_key` → `handle_key` (`macro.lua:77`, executes commands
and records macros) **and** the widget, still shown, takes the same
keystroke at tier 3 (`projectInputController.lua:143-146`). That is the
double-handling the row suspected.

**Recommendation.** The `wontfix` can stand — it is another repo's
working code, the owner ruled, and the failure needs a deliberate
backwards jump to level 1 of one track. But the recorded reason should
not stand: the entry should say the neutralisation is **correct for the
shipped level ordering and not structurally guaranteed**, and that a
level naming `controls = keys` after an editor level (or any future
`jump_level` target that does) reintroduces it. The one-line structural
fix, if it is ever wanted, is `controls.lua`'s `keys()`/`plan()` calling
`compy.input.hide()` — not a `is_shown` guard.

Uncertain only in one respect: I traced this in code and could not run
maze (LÖVE, needs a display, and maze has no busted suite). Playing
track 3 to `two_turns2` and submitting `3,` would settle it in a minute.

---

## 6. Documentation truthfulness

**`CHANGELOG.md:145-154` — accurate.** Every clause checks out: `text` is
documented as "a string or list of line strings" (`doc/input_api.md:104`),
the list form did always write, the string form was guarded on a single
line, `show{text="a\nb"}` and `set_text("a\nb")` are both real entry
points, and "the same guard is in the release this one branches from" is
verified at `3256aac`. Right scope, too — the two feature-introduced rows
correctly get no CHANGELOG entry.

**`doc/input_api.md:196-206` — accurate but over-reaching (F4).**
Dropping `#line + 1` was necessary (`#` is bytes in Lua, so the old text
contradicted its own preceding clause). The `"привет"` example is right:
6 characters, 12 bytes, positions `1..7` not `1..13`. The over-reach is
"**Every** cursor position the widget reports or accepts is counted this
way" — an `Error` column is a position the widget accepts, and the
framework's own `LuaSyntaxValidator` produces it in bytes, which
`userInputView.lua:183-184` then compares against a character index. Either
narrow the sentence to `get_cursor`/`set_cursor`/`show{cursor}`, or fix
the two byte producers.

**`doc/input_api.md:424-430` — one sentence is false (F2).** The
case-insensitivity rule itself is right and well placed ("`'Ctrl+S'`,
`'ctrl+S'` and `'ctrl+s'` are one binding"; probed: caps-locked `I` hits
the `'i'` slot). But "A shortcut therefore cannot tell the two cases
apart; if your project needs to, read the character in `hooks.textinput`"
is wrong twice over: the handler is called with the raw payload
(`projectInputController.lua:138-140`, `TRIGGER.textinput` at `:52` only
*derives* the lookup key), and the same page says so at `:433` for the
class form. Probed: the handler receives `'I'`. Suggested replacement —
*"`I` and `i` share one binding; the handler still receives the character
actually typed as its first argument, so it can tell them apart."* The
same wrong sentence is in commit `4a58b996`'s body and should not be
carried into the PR.

**Neither missing nor over-promised elsewhere**: no CHANGELOG claim for
the two unreleased rows (correct), no doc claim that `configure` accepts
`text` (correct — the commit message alone got that wrong, F5).

---

## 7. House rules

- **Line ≤ 64**: one new violation, **F6** (`input_widget_control_spec.lua:56`,
  69 chars). Every other over-length line in the touched files predates
  the sprint. Note for whoever checks this next: `awk`/`wc` count *bytes*,
  and these files are full of em-dashes and Cyrillic — measure in
  characters or you will chase ~14 phantoms.
- **Function body ≤ 14**: `set_cursor_pos` 5, `_clamp_cursor_pos` 5,
  `set_text` 12 (down from 15), `combo_string` 7. Clean.
- **Params ≤ 4, nesting ≤ 4**: unchanged; `set_text` lost a nesting level.
- **Comment citations**: `controller.lua:382-386` cites
  `doc/development/decisions/input.md, Decision 8` — canonical path, named
  unit. `userInputController.lua:190-192` and `userInputModel.lua:529-533`
  cite `doc/input_api.md, "Live changes"` — verified to exist at
  `input_api.md:158`. Test comments cite `"The input widget — opening it
  and changing it"` (`:93`) and Decision 8. **No `doc/development/wip/…`
  citation anywhere in the new comments.** Clean.
- **Comments carry what the code cannot**: yes. `controller.lua:382-386`
  explains *why* only `textinput` can deliver a cased trigger, which is
  the fact that makes the one-line fix safe; `userInputController.lua:190-192`
  records the unit decision at the site that has to keep it. Both are the
  right kind of comment.
- **Vocabulary**: every new comment and doc sentence in this sprint says
  **widget**. balloons' new comments say "the widget owns its label".
  Surviving "field" occurrences (`userInputController.lua:305`,
  `internals/user_input.md:384`, maze's `core_editor.lua`, balloons'
  `ui.field`) are all pre-existing and belong to FIX-02-09, which
  `3c7b7954` explicitly defers.
- **Fixes and ledger separated**: yes, cleanly — `32f8345d`/`4a4e6687`,
  `4a58b996`/`d5c38d76`, `e75a48d8`/`311dbd18`.

---

## 8. What the sprint should have caught and did not

1. **F3 — `_apply_eval:868`.** The fix's own premise ("characters
   everywhere") makes this caller wrong; the sweep enumerated the callers
   and the commit asserts they all pass character values. One does not,
   and it is provable in ten seconds with the framework's own validator.
   This is the classic shape of a missed sibling: the fix changed a
   *bound*, and the audit looked at everything that *reads* the bound
   rather than everything that *feeds* it.
2. **F4 — the error underline.** Same root cause, in the view. Pre-existing,
   but the sprint wrote the paragraph that now covers it.
3. **F2 — the doc sentence.** The author had `sc(...)` on screen (the fix
   is three lines away from `find_shortcut`) and the page contradicts
   itself at `:433`.
4. **F1 — the maze trace.** The `wontfix` outcome is fine; concluding "by
   construction" from three call sites without following `start_level` is
   not. The row asked for a weighing and the weighing overshot into a
   proof.
5. **F5 — two false statements in a commit message** headed for a PR
   description, in a sprint whose closing commit explicitly says the PR
   description needs the provenance kept straight.

## What is not wrong — coverage statement

So that this review reports coverage and not only complaints, these were
checked and found sound: the multi-line split and all its empty/trailing/
multi-byte/keep-cursor edges; that the console's history recall and the
editor's two `set_text` call sites take the untouched table branch; the
three other `combo_string` call sites and the reservation tables; combo
registration/dispatch symmetry including deletion and the `'*'` class;
the completeness of the byte→character sweep across the model, controller
and view; the two external cursor entry points; balloons' removal being
behaviour-preserving with no surviving reader, no nil-fallback path and
no two-argument caller; every doc section name cited by a new comment;
all three provenance claims against `3256aac`; the suite at exactly
1030/0/0/10 with no eleventh pending; and that `draw_main.lua`'s
`ctrl_pressed` branch is dead, so half of `BUG-01-11` is safe outright.
