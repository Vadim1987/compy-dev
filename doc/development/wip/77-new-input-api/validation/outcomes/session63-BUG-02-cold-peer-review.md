# Cold peer review — session63's `BUG-02` work

Reviewer: a cold agent spawned 2026-09-01, no part in the work. Base for every comparison:
`3dd14192` (session base). Head at review: `6f264505` (the prompt commit `22276407` landed on top
while I worked; it is not part of what I reviewed).

Environment facts that qualify everything below: **`busted tests` here runs on LuaJIT 2.1
(Lua 5.1)**, not the owner's PUC Lua — `1038 successes / 0 failures / 0 errors / 10 pending`,
matching the expected figure, is a *container* result. **The `lua-lsp` MCP server is still returning
`broken pipe`** (`references` and `diagnostics` both failed); every "who calls this" answer below is
grep plus a manual check for dynamic dispatch (`self[name](...)` appears only in `src/lib/`
vendored code), so caller counts are grep-complete but not AST-confirmed.

---

## 1. Verdict

**Changes needed** — the code change is sound and I could not break it, but three durable documents
carry statements that are false, self-contradicting, or missing, one of them a claim this session
had already corrected twice elsewhere.

---

## 2. Claim check

| # | Claim | Result | Evidence |
|---|---|---|---|
| 1 | `string.lines` polymorphic; delegates a list to `split_array`; empties preserved | **CONFIRMED**, with a caveat | `src/util/string/string.lua:258-266` (`lines`), `:240-254` (`split_array`), `:244-246` is the explicit empty-element branch. Probe: `split_array({'a\nb','','c'},'\n')` → `{'a','b','','c'}`. **Caveat the claim omits:** `split_array` calls `string.split(line, char)`, and `split` returns `{}` for a non-string (`:232-234`), so a **non-string element is silently dropped**, not split. That is the mechanism behind the open item, and it is not "splits each element". |
| 2 | All **seven** callers of `_set_text_line` pass `keep_cursor = true`, so its `_update_cursor` is unreachable | **CONFIRMED** | `src/model/input/userInputModel.lua:111, 250, 251, 262, 335, 343, 372` — seven, every one ending `, true)`. `grep -rn _set_text_line src/ tests/` finds no others and no dynamic dispatch. Count independently verified; the guard is `:193`. |
| 3 | `clear_input` is the only reachable caller, and `(1,1)` is correct by accident | **CONFIRMED** | Only other call site is `:380`. Probe (content `{'one','twotwo','xx'}`, caret at `(3,2)`, then `clear_input`) → `(1,1)`. Two mutations settle "by accident": rewriting `t[cl]` → `t[#t]` (the narrow repair) leaves the suite **fully green**, i.e. nothing distinguishes the two indexings today; emptying the body entirely **breaks 21 tests**, i.e. the seat itself is load-bearing. Both facts are what "correct by accident" means, and both hold. |
| 4 | `_update_cursor(true)` yields out-of-range `(3,7)` on `{'one','twotwo','xx'}`, caret line 2 | **CONFIRMED** | Direct probe of the private method returned exactly `(3, 7)`; `'xx'` admits `1..3`. |
| 5 | The deleted call was inert in **every** revision it existed in | **CONFIRMED** | Walked all 72 revisions of `set_text` from `472c6bba` to `2986fd80`: in every one the call sits inside `if not keep_cursor` and the function ends with an unconditional `self:jump_end()` (`git show 472c6bba:…` lines 107-126 is the first). Empirically at head: restoring the call leaves the suite green, and my base-vs-head behaviour matrix (below) is byte-identical on every string-spelling case. One precision the ROADMAP's short phrasing loses and the ledger keeps correctly: *inert* here means "every effect discarded before return" — it did mutate the cursor ahead of `text_change()`/`_follow_cursor()`, and `init_visible` + `jump_end` then overwrote both. |
| 6 | Pre-multiline form was `utf8.len(t)+1` over a string; `19351528` (2023-07-17) broke it | **CONFIRMED** | `git show 19351528 -- src/model/inputModel.lua`: `- self.cursor.c = utf8.len(t) + 1` → `+ self.cursor.c = utf8.len(t[cl]) + 1` / `+ self.cursor.l = #t`. Date and title match. |
| 7 | Partial unvalidated duplicate of `jump_end`; `jump_end` not a drop-in at `clear_input` | **CONFIRMED as stated** — but a *supporting* claim in the same entry is **REFUTED** | `jump_end` (`:802-815`) takes both coordinates from `ent[last_line]`/`#ent`, routes through `move_cursor` (`:566-591`, which clamps), and additionally calls `end_selection` and `visible:to_end()` + `check_range` — so not a drop-in. **Refutation:** the entry says `_update_cursor` "and `_advance_cursor` are the only two writers" of raw cursor fields. `UserInputModel:insert_text_line` (`:224`) does `self.cursor.l = l + 1`, unvalidated, and it is **live on a hot path** — `line_feed()` (`:263`, every Shift+Enter) and Ctrl+D duplicate-line (`userInputController.lua:702`). See F1. |
| 8 | `after_submit` gets the line list, `on_text_entered` the joined string | **CONFIRMED** | `src/controller/userInputController.lua:470-471`. Precision: `after_submit` receives `self.model:get_text()` — the **live `InputText`**, not a copy of it. |
| 9 | No content getter on `compy.input`, so normalising breaks no set/get round-trip | **CONFIRMED for a getter** | `build_widget_api`, `src/controller/consoleController.lua:817-882`: `show`, `hide`, `is_shown`, `get_cursor`, `set_cursor`, `set_text`, `configure`, `clear`. `UserInputController:get_text` exists (`:104`) but is not on the project surface. See F4 — the *conclusion drawn from it* in Decision 38 is wider than the fact. |
| 10 | Both draw paths reach `gfx.print`, honour `\n`, corrupt it differently | **CONFIRMED by inspection only** | `src/util/view.lua:24-28` prints the whole string at `x = 0`; `src/view/input/userInputView.lua:158-217` walks `c = 1, tl` with `string.usub(s,c,c)` and prints each character at `dx = (c-1)*fw`. Not observed running: tests short-circuit on `gfx.mock` and I have no display. The ledger says "not display-verified" — that is honest and I confirm I could not raise it above inspection either. |

### The unification, checked against the two branches it replaced

I ran a 22-input × `keep_cursor ∈ {false,true}` matrix (string/list, newlines, trailing newline,
empty, whitespace-only, multi-byte, invalid UTF-8, nested table, boolean, number, `nil`, empty
table, `nil` hole, sparse, 300-char line), first at head, then with
`src/model/input/userInputModel.lua` checked out at `3dd14192`, and diffed. **The only deltas are:**

- the intended ones — list elements now split, trailing newline yields a blank last line, blank
  elements survive, and the cursor lands accordingly;
- the number-element cases, which are the open item (§4).

Everything else — `nil`, booleans, nested tables, empty table, `nil` hole, sparse array, long line,
multi-byte, invalid UTF-8, both `keep_cursor` values — is **identical to base**. In particular
`set_text(nil)` / `set_text(42)` / `set_text(true)` still leave content standing and still run
`jump_end` (cursor moves though content did not; unchanged from base, undocumented in both), and
`set_text({'a', true})` / `set_text({'a', {'b'}})` still **raise** from `sanitize_utf8`
(`userInputModel.lua:87`, `bad argument #1 to 'len'`) — identically at base. The raise is **not a
regression of this work**.

### Are the tests any good? — yes, verified by mutation

| mutation | caught by |
|---|---|
| list not split (`return clean`) | 4 tests: `user_input_model_spec` @101, @109, @115 (three of the new ones) + `input_cursor_text_spec` @228 (the new surface one) |
| store the normalised value unconditionally (drop `if lines then`) | `user_input_model_spec` @140 — the new "leaves content standing" test |
| string branch not split | 3 tests incl. `input_widget_control_spec` @56 |
| drop the per-element `sanitize_utf8` | `user_input_model_spec` @85 (errors) |
| drop `_clamp_cursor_pos` under `keep_cursor` | 3 tests |

Every new test earns its place, and each fails for the reason it was written. One exception, F6.

---

## 3. Findings, most severe first

### F1 — **defect (false claim in the new ledger entry)**: `_update_cursor` and `_advance_cursor` are *not* the only raw cursor writers

`doc/development/technical_debt/input.md`, *"`_update_cursor` measures the column on the wrong
line"*, bullet *"The mechanism is that it bypasses the validated path"*:

> `_update_cursor` writes `self.cursor.l` and `self.cursor.c` as raw fields instead — **it and
> `_advance_cursor` are the only two writers that do** — so nothing catches the mismatch.

`src/model/input/userInputModel.lua:222-227`:

```lua
function UserInputModel:insert_text_line(text, li)
  local l = li or self:get_cursor_y()
  self.cursor.l = l + 1
```

That is a third raw, unvalidated writer, and unlike the two named it is **reachable in normal use**:
`line_feed()` calls it on every Shift+Enter (`:263`), and Ctrl+D duplicate-line calls it from
`userInputController.lua:702`. (`set_cursor` at `:546` replaces the whole `Cursor` object with no
check either, though the entry's phrasing is about field writes.)

**Reachable how:** the sentence is load-bearing — it is the entry's argument for *why* the defect is
structural rather than a typo. **Recommendation:** correct the count. The correction *strengthens*
the entry's own disposition ("review the cursor writers, don't repair the body"), because it makes
the population three, one of which is on a hot path.

### F2 — **omission**: the ROADMAP still carries the claim the session corrected twice

`doc/development/wip/77-new-input-api/ROADMAP.md:639`, in the `BUG-02-01` row:

> `_update_cursor` itself stays, **live from `_set_text_line` and `clear_input`**.

This is exactly the claim `cd56778b` corrected in the ledger (`technical_debt/input.md:1426`: *"this
entry first said `_set_text_line` and `clear_input` 'both call it live', which is wrong about the
first"*) and in `internals/user_input.md:93`. Two of the three artefacts were fixed; the ROADMAP —
the one a PR reader is most likely to read — was not. A correction that leaves the claim standing in
the summary document has not been made. **Recommendation:** fix the ROADMAP row in the same wording
as the other two.

### F3 — **defect / unrecorded behaviour change**: `set_text{42}` now silently **empties** the widget

The open item is filed (in the prompt) as "drops the `42`". At the whole-list level it is worse than
a drop: for a list with **no** string elements, `normalized_lines` returns `{}`, `{}` is truthy, so
`self.entered = InputText({})` — which appends `''`. Probed:

| input | base `3dd14192` | head |
|---|---|---|
| `set_text{'a', 42}` | `{'a', 42}` (element is a **number**) | `{'a'}` |
| `set_text{42}` | `{42}` | `{''}` — **content wiped** |

Note the base column: the author's statement that base produced `{"a","42"}` is **wrong about the
type**. `sanitize_utf8` returns its argument unchanged when `utf8.len` succeeds, and `utf8.len(42)`
succeeds by string coercion returning `2`, so base stored the **number** `42` in a list of "line
strings". `assert.same({'a','42'}, …)` would fail at base. This matters for the disposition (§4),
which is why I am flagging the wrong detail rather than the conclusion.

Nothing in the tree records either row. **Recommendation:** record it (see §4), which is also the
house rule about accepted behaviour changes living in the workspace rather than only in a commit
message.

### F4 — **overclaim**: Decision 38 argues "could not be read back at all" while its own ledger entry says it could

Decision 38, *Consequence*:

> …no capability is removed: the state normalisation eliminates … could not be produced by typing or
> by pasting, and **could not be read back at all**, the `compy.input` surface having no content
> getter.

The RETIRED ledger entry, *What was observable*, established the opposite as the *point* of the
weighing:

> `after_submit` receives the line list itself (Decision 37's payload split), so the spellings handed
> a project `{"a","b"}` versus `{"a\nb"}`.

Both are in the tree, dated the same day. The narrow reading ("no *getter*") is true — claim 9 —
but the sentence is doing rhetorical work ("no capability is removed") that the submit payload
contradicts: a project *could* observe the un-normalised state, and after the fix it observes
something different. That is a real, documented-surface behaviour change, which is precisely why the
CHANGELOG entry exists. **Recommendation:** narrow the sentence to "no getter; the change is
observable only at submit, and the CHANGELOG carries it".

### F5 — **overclaim (small, pre-existing)**: "**No line ever contains a line terminator**" is true of `\n` only

`string.lines` splits on `'\n'` and nothing in `src/model/input/`, `src/util/string/string.lua` or
`userInputController.lua` mentions `\r` at all. `set_text("a\r\nb")` yields `{"a\r", "b"}` — the
line retains half a line terminator, which the cursor then counts as an ordinary column, which is
the exact ambiguity the decision says it removes. Reachable by a project that sets content read from
a CRLF file; the clipboard path is probably safe because SDL normalises, but I did not verify that
and it is not stated anywhere. **Recommendation:** scope the sentence to `\n` explicitly, or open an
item. Low severity — pre-existing, and not a regression.

### F6 — **overclaim (small)**: the two "pinned" tests do not guard the deletion

The ledger says of the deleted call: *"Mutation-tested before deletion… Two of them are now pinned
as tests."* I restored the deleted call verbatim at head and ran the full suite: **1102/0/0/10, no
failures.** No test in the tree distinguishes the call's presence from its absence. That is
*inherent* — an inert call cannot be pinned, and the two tests do pin the end-of-content behaviour,
which is worth having — but "pinned as tests" reads as a guard against reintroduction, and there is
none. **Recommendation:** one word — "the *behaviour* is pinned"; and note that reintroduction is
not test-detectable.

### F7 — **style**: the same paragraph is reproduced in five places

The "(line, column) … invalid bytes leave a column's *length* undefined; a newline leaves its
*position* undefined" argument appears, near-verbatim, in `userInputModel.lua:157-162` (the
`set_text` doc comment), `tests/input/user_input_model_spec.lua:92-98`,
`tests/input/input_cursor_text_spec.lua:223-226`, Decision 38, `internals/user_input.md` and the
CHANGELOG. `agents/rules/commenting.md`, payload 2: a comment "carries the pointer **plus the one
thing the reader needs here**; it does not reproduce what it points at." The `set_text` comment
already cites Decision 38 and then restates its full argument. **Recommendation:** trim the
`set_text` comment to the pointer plus the one-clause reason; the tests' copies are the more
defensible of the six, but two of them is one too many. Hard limits are all met — no added line
exceeds 64 characters, `normalized_lines` is a 9-line body, `set_text` an 11-line body, 1-2
parameters, nesting ≤ 2.

### F8 — **omission (minor)**: the "all three in-tree callers" enumeration is incomplete

Both the RETIRED entry and the ROADMAP say "no in-tree caller can reach it. All three
(`maze/core_editor.lua`, `tixy/main.lua` twice)…". Those are the *project-facing* callers. The
model's `set_text` is also called from `editorController.lua:336` (`buf.printer(raw)`),
`editorController.lua:602` (`buf:get_selected_text()`), `userInputModel.lua:475`/`:487`
(history restore) and `userInputController.lua:316` (`show`'s `cfg.text`). **I checked all of
them and the conclusion survives** — `pprint` returns `string.lines(src)`
(`src/model/lang/lua/parser.lua:291`), buffer lines and history entries are already split — but the
enumeration as written would let a later reader think five call sites do not exist.

### F9 / F10 — **adjacent fossils, not this work's** (report only, per the debt-report rule)

- `string.split_array`'s type guard is dead: `if not type(str_arr) == 'table' then` parses as
  `(not type(str_arr)) == 'table'`, i.e. `false == 'table'`, always false
  (`src/util/string/string.lua:241`). Another author's file; no size refactor implied.
- `_set_text_line` (`userInputModel.lua:196-198`) has its own unreachable branch: `elseif
  type(text) == 'table' and ln == 1` nested inside `if type(text) == 'string'`. Same fossil family
  as the one this work retired, left untouched, and it would be a one-line deletion in the pass F1's
  entry already proposes.

---

## 4. The open item — `set_text{'a', 42}`

**My call: do not change the code. Narrow Decision 38's wording, and record the behaviour — with
the `{42}` row, not only the `{'a', 42}` one.**

Reasoning, from what the base actually did rather than from the contract:

1. **Base did not preserve the value in any useful sense.** It stored the raw **number** in a list
   of line strings. Downstream, `string.join` skips non-strings while still emitting the separator
   (`src/util/string/string.lua:277-282`), so at base `on_text_entered` for `{'a', 42}` already
   received `"a\n"` — the `42` was **already silently dropped** at the submit boundary, while
   `after_submit` handed the project a raw number. Base was internally inconsistent about the same
   element; head is consistent.
2. **`{42}` at base was already a phantom.** `is_non_empty_string_array({42})` is false, so
   `InputText:is_empty()` returned true and `submit_flow` refused to submit
   (`userInputController.lua:464`) — while the draw path printed "42" on screen. Head's `{''}` is
   the same "empty" verdict with a screen that agrees with it. **The new behaviour is strictly more
   coherent than the old**, which is the strongest argument for leaving the code alone.
3. **The input is out of contract**, `text` being documented as "a string or list of line strings",
   and total-but-lossy is a defensible response to out-of-contract input in a framework whose
   failure mode otherwise is a raw Lua error in the project's face.
4. **But Decision 38's sentence is now false as written**: *"nothing here rejects, truncates,
   escapes or re-flows what is set"*. Dropping a list element **is** truncation, and wiping the
   widget on `{42}` is the loudest form of it. Fix the sentence, not the code:
   > Normalisation is total over the documented shape. An element that is not a string is not a
   > line: it is dropped, and a list with no string elements normalises to empty content. Behaviour
   > on out-of-contract input is defined but lossy, and no capability of the documented shape is
   > affected.
5. **File it BACKLOG, unslugged.** By the house rule a slug is the commitment to fix and is earned
   at `ACTIVE`; nothing here is committed to a fix.

**On `true` / nested tables raising from inside `sanitize_utf8`:** it is **not a regression** — base
raises identically (verified in the base-vs-head matrix) — so it is not this work's defect. It *is*
its own latent defect, and worth naming in the same record for one reason the drop makes visible:
**the same call now answers two out-of-contract element types two different ways** — a number is
swallowed, a boolean raises a raw Lua error with a `utf8.len` message naming a function the project
author has never heard of. That inconsistency is the thing to record. The natural resolution is not
in `set_text` at all but at the project boundary, where `checked_cursor` already sets the precedent
(clamp/refuse with a message naming the key, Decision 35's strictness); that is a `FIX`-sprint
question, not a `BUG-02` one, and I would not reopen `BUG-02` for it.

---

## 5. What I could not check

- **`lua-lsp` is still dead** — `references` and `diagnostics` both returned
  `failed to write header: write |1: broken pipe`. Every caller count here is grep + a manual scan
  for `self[<expr>](…)` dispatch (none outside `src/lib/`). Grep is complete for a name this
  distinctive, but it is not an AST, and I did not type-check the edit the way the LSP would have.
- **The rendering claim (10) is inspection only.** No display; `UserInputView:render` returns early
  on `gfx.mock`. I confirmed both paths reach `gfx.print` and that they pass it different units
  (whole string vs one character at an explicit `dx`); I did not see either corrupt anything.
- **The suite result is a LuaJIT 2.1 result.** The owner runs PUC Lua. The two facts my findings
  lean on that could in principle differ by interpreter — `utf8.len(42)` coercing rather than
  raising, and `string.split`'s `type(str) == 'string'` gate — are the second one interpreter-proof
  and the first one true of PUC 5.4's `utf8.len` as well (`luaL_checklstring` coerces), but I could
  not run PUC Lua here to prove it.
- **CRLF via the clipboard (F5).** I did not verify whether SDL normalises `\r\n` in
  `love.system.getClipboardText`; the project-sets-a-CRLF-string path needs no such assumption and
  is enough for the finding.
- **Owner quotations and attestations** (the ruling wording quoted in Decision 38 and the track) are
  outside anything I can verify from the repo. I took them as given and reviewed only what the code
  and the documents say.
