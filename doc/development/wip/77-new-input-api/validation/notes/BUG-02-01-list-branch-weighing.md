# `BUG-02-01` — the weighing: does `set_text`'s list branch normalise?

**Session63, 2026-09-01.** Evidence for the owner's ruling. Everything below was verified in code
or by probe against `HEAD` `3dd14192`; the probe ran under `busted` with `mock_love` and is
reproduced in the scratchpad, not committed.

---

## 1. The defect, characterised

`UserInputModel:set_text` (`src/model/input/userInputModel.lua:139-159`) has two branches. The
string branch splits on newlines; the table branch sanitises each element for UTF-8 validity and
stores it verbatim. So one documented input shape — *"a string or list of line strings"*
(`doc/input_api.md`) — has two spellings that produce **different model state**:

| | `set_text('a\nb')` | `set_text({'a\nb'})` |
|---|---|---|
| model lines | **2** | **1** |
| `ulen` of line 1 | 1 | **3** — the `\n` counts as an ordinary character |
| cursor after the call | `2,2` | **`1,4`** — the caret can park past the newline |
| visible (wrapped) line 1 | `"a"` | **`"a\nb"`** — the raw newline reaches the view |
| `string.unlines(items)` | `"a\nb"` | `"a\nb"` — identical |

## 2. What is observable, and it is more than the ledger entry says

The BACKLOG entry says the content *"round-trips through `string.unlines` unchanged, so a submit
delivers what was set; what is uncharacterised is the rendering"*. That is right about
`on_text_entered` and **understates two things**.

**(a) `after_submit`'s payload differs.** `UserInputController:submit_flow`
(`src/controller/userInputController.lua:462-471`) passes `string.unlines(lines)` to
`on_text_entered` and the **line list itself** to `after_submit` — the payload split ratified as
Decision 37. So the two spellings deliver the same string to one callback and **different lists** to
the other: `{'a','b'}` versus `{'a\nb'}`. The disagreement reaches a public callback payload, not
only the display.

**(b) The validator sees one line where the project meant two.** The same function keeps the line
list for the validator, which runs per line and whose `LineValidators` reports *which* line failed.
An unsplit element makes a per-line rule measure the concatenation and name the wrong line.

**(c) The rendering is now characterised, and the two draw paths disagree with each other.** Both
end at `gfx.print`, which honours `\n`:

- **plain path** — `ViewUtils.write_line` (`src/util/view.lua:24-28`) prints the whole display line,
  so `"a\nb"` draws `a` on its row and `b` **one row below at x=0**, over the neighbouring line. The
  model still believes it drew one row, so the cursor, the visible window and the scroll arithmetic
  all disagree with the screen.
- **highlighted path** — `userInputView.lua:158-217` prints character by character at explicit
  `dx`, so the `\n` draws **nothing** and reads as a blank column; `b` lands at column 3.

Neither is what a project asking for two lines gets from the string spelling. Not display-verified —
this is read from the draw code, and it needs a device to see.

**The wrap maps stay internally consistent.** `WrappedText:wrap` (`src/util/wrapped_text.lua:79`)
sizes apparent lines from `string.ulen(l) / w` and `string.wrap_at` splits purely on length, never on
`\n` — so the model's own bookkeeping is coherent. The corruption is entirely at the `gfx.print`
boundary.

## 3. Is there a sane reason to want it? — **no, and the state is unreachable by any other route**

The model has no soft/hard newline distinction and no escaping: a "line" is a row, and a row holding
a row terminator is a contradiction the rest of the system never produces.

- **No user action can create it.** `add_text` splits its string argument
  (`userInputModel.lua:100-135`), and the paste path hands it `string.unlines(t)` first
  (`userInputController.lua:103`), which `add_text` then splits again. Typing Enter makes a real
  line break. There is no key that inserts a raw `\n` into a line.
- **No in-tree caller can create it.** All three (`maze/core_editor.lua`, `tixy/main.lua` twice)
  pass either a raw string or `string.lines(…)`, and `string.lines` never emits an element
  containing a newline.
- **Nothing can usefully read it back.** The `compy.input` surface
  (`consoleController.lua:819-873`) is `show` / `hide` / `is_shown` / `set_cursor` / `set_text` /
  `configure` / `clear` — **there is no content getter**. Text is write-only from a project's side;
  the only read-back is the submit payload. So there is no set/get round-trip for normalisation to
  break.

So the unsplit state can be entered by exactly one call, is invisible to the callback that
concatenates, is wrong on screen, and cannot be observed except as the malformed list handed back to
`after_submit`. It is a state with no use, not a capability.

## 4. Does the fix complicate the code? — **no; it is one call, and the utility already exists**

`string.lines` is already polymorphic over `string | string[]`
(`src/util/string/string.lua:258-266`): given a table it delegates to `string.split_array`, which
splits each element **and explicitly preserves empty ones** (`:240-254` — the `line == ''` branch
exists for exactly that). Verified: `string.lines({'a\nb', '', 'c'})` → `{'a','b','','c'}`;
`string.lines({''})` → one element.

The whole change is to wrap the already-built list in the call the string branch already makes:

```lua
    self.entered = InputText(string.lines(clean))
```

No new helper, no new vocabulary, no line-count or nesting change, and the two branches converge on
one function instead of stating the rule twice. **Applied and measured: `busted tests` →
1032 / 0 / 0 / 10, fully green** — no existing case depends on the non-splitting. Re-probed after the
change, `{'a\nb'}` and `'a\nb'` produce identical state (2 lines, cursor `2,2`). *The candidate was
reverted; the tree is clean and the ruling is the owner's.*

## 5. Does it handcuff a project? — **no**

The only capability removed is *store a line containing a raw newline*, which §3 shows is
unreachable, unrenderable and unobservable. A project wanting one row that displays `a`, a gap and
`b` writes a space. A project wanting two rows writes either spelling and now gets the same thing.

## 6. Provenance, base-checked at `3256aac`

```lua
  elseif type(text) == 'table' then
    self.entered = InputText(text)
```

**The non-splitting is pre-existing** — at base the table branch has no split *and no sanitise*, and
the string branch was itself broken in a different way (`BUG-01-09`). Two refinements the roadmap
row does not carry:

- **The sanitising loop is ours.** This feature added the per-element `sanitize_utf8` pass, so the
  branch that would carry the split is code this feature wrote. Completing a normalisation we
  started is not a size refactor of another author's subsystem.
- **The asymmetry is ours by choice, not by inheritance.** We normalise UTF-8 on both branches and
  newlines on only one. Base normalised neither.

## 7. One thing found in passing, not folded in

The two branches disagree about the cursor as well: the string branch calls `_update_cursor(true)`
when `keep_cursor` is falsy, the table branch does not — and both then fall through to `jump_end()`,
which sets the cursor anyway. Either the call is redundant on the string branch or it is missing on
the table one. **Not investigated and not part of this row** — recorded so it is not lost.
