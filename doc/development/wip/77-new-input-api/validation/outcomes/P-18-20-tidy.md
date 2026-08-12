# P-18-20 execution record — four small corrections

Mechanical, Sonnet. Nothing committed — working tree left with the edits
uncommitted, as instructed.

## 1. Stale comment — `src/examples/keyboard/words.lua`, `wordsBaseKey`

`wordsBaseKey` forwards to `glyphBaseKey` (`input.lua:133-138`), confirmed via
the `lua-lsp` MCP server (`hover` on the definition, `references` showing
`words.lua:148`, `alt.lua:63`, and one prompt/review doc as the only callers).
`glyphBaseKey`'s actual branches: space → `"space"`; a shifted symbol →
its unshifted key via `GLYPH_BASE` (the inverted `SHIFT_MAP`); a letter →
its lowercase key; else the glyph itself. The old comment said "the
glyph itself (an unshifted punctuation key)" for the last case, omitting
the `SHIFT_MAP`-inversion branch entirely — the one that stops the game
crashing on `~`/`|` (`love.keyboard.isDown` raises on those strings).

Changed `words.lua:144-146` from:
```
-- The physical key a target glyph is produced on: space for a
-- space, the lowercase key for a letter (incl. a capital), else
-- the glyph itself (an unshifted punctuation key).
```
to:
```
-- The physical key a target glyph is produced on: space for a
-- space, a letter's lowercase key, a shifted symbol's unshifted
-- key, else the glyph itself.
```

## 2. Wrong count — `doc/development/technical_debt/input.md`

Counted `sc[...] = ...` assignments in `register_reserved`
(`src/examples/keyboard/input.lua:67-87`): `shift+escape`,
`alt+shift+escape`, `ctrl+alt+up`, `ctrl+alt+shift+up`, `ctrl+alt+down`,
`ctrl+alt+shift+down`, `alt+*`, `alt+shift+*`, `alt+p`, `alt+shift+p`,
`ctrl+alt+h`, `ctrl+alt+shift+h` — **twelve**, matching the task brief,
not the eleven the doc said. Corrected both occurrences:
- line 1506, "eleven" → "twelve" registrations
- line 1516, "eleven lines" → "twelve lines"

Nothing else in that entry touched.

## 3. Missing smoke row — `doc/development/smoke_checklists.md`, `keyboard` §D

Added `D10` after `D9`:
```
| D10 | in game 1 or 6 (no `onHint`), press `Ctrl+Alt+H` | **[new]** nothing happens: no knock, no miss, no sound |
```
and added `D10` to the `[new]`-row enumeration under "What a failure here
means" (was `..., D8b, G1`, now `..., D8b, D10, G1`).

## 4. Comment economy — game repo, three sites

**`bubble.lua`**, above `bubbleKeyreleased` (was 8 lines). Kept the fact
statement and the caution/timeout payload; reduced the five-line argument
(poll-could-measure-it, channel-is-author's-choice) to one clause:
```
-- The one judge in the game that keys on the release EVENT --
-- a chosen channel, not a platform limit.
-- The caution: a release lost to a focus change leaves BUB.key
-- set with no release coming. bubbleGrow's timeout pops the
-- bubble a moment later: the cost is a pop the child retries.
```

**`main.lua`**, trailing comment at EOF. Compared against the file header
(`main.lua:1-5`, "...the keyboard/text callbacks are compy.input hooks
and shortcuts, registered in input.lua."): the header already states
where/how the callbacks are registered. The trailing comment's only
non-duplicate content was that `love.*` globals would *also* work
(the framework captures them into the same hooks) — kept that one
clause and dropped the rest, including "only drops three wrappers that
existed to satisfy LOVE's naming convention," which is history-narration
(a comment rule violation independent of the length concern):
```
-- love.* globals would work too -- the framework captures them
-- into the same hooks.
```

**`input.lua`** header, the `setTextInput(true)` sentence. Rewrote to
remove the "for the device... so here it is redundant" contradiction and
the ragged short line, into one statement: the IDE makes the same call
at its own boot, so the line matters for the device build and is
harmless here (kept the "undoing it on exit is a no-op" clause — it was
already correct and not part of the contradiction):
```
-- OS key repeat is filtered by the isrepeat flag the hooks get
-- as their third argument. setTextInput(true) below is for the
-- device build: the IDE makes the same call at its own boot, so
-- this line matters there and is harmless here (undoing it on
-- exit would be a no-op). Global key repeat is left ON -- the
-- repeats are filtered rather than suppressed, and stopping
-- them would change what scenes see.
```

## Where the instruction did not quite match the code

Nothing found that contradicted the brief. The one judgment call: the
task asked for the `main.lua` trailing comment to be "reduced to
whatever it says that the header does not," but part of what it said
beyond the header (the "three wrappers" detail) was itself a comment-rules
violation (narrates history) rather than merely non-duplicate content, so
it was dropped rather than kept as the "extra" residue. Flagging this
rather than assuming — if the parent wants that detail preserved some
other way (e.g., a durable note elsewhere), it is not currently anywhere
in the tree.

## Left untouched

- The author's own `docs/...` references elsewhere in the game repo —
  out of scope per the task.
- `alt.lua:61-63` (`altBaseKey`), which also calls `glyphBaseKey` and has
  its own comment — not named in the task, not touched.
- Everything else in `technical_debt/input.md` and `smoke_checklists.md`
  beyond the named entry/row.

## Verification

**Parse check** (`luajit -e "assert(loadfile(...))"` per file, all OK):
```
src/examples/keyboard/words.lua   OK
src/examples/keyboard/main.lua    OK
src/examples/keyboard/bubble.lua  OK
src/examples/keyboard/input.lua   OK
```

**Column width** — `awk 'length>64 {print FILENAME":"FNR}'` over all four
edited files: no output, zero violations.

**Doc citations** — `grep -n "doc/"` over all four edited files: no
output. No comment written cites a platform `doc/...` path or a decision
number.

**App load smoke test**, from `/repo`:
```
timeout 25 xvfb-run -a stdbuf -oL -eL love src play src/examples/keyboard
```
Ran to the 25s timeout (`Terminated`, exit 143). Output included
"Project play opened", "Press Ctrl-Esc to exit", the play-mode INFO line,
then the timeout kill — no `Error:` line. (ALSA "Could not open device"
warnings are pre-existing headless-audio noise from the sandbox, unrelated
to these changes.)

## Files touched

- `/repo/src/examples/keyboard/words.lua`
- `/repo/src/examples/keyboard/main.lua`
- `/repo/src/examples/keyboard/bubble.lua`
- `/repo/src/examples/keyboard/input.lua`
- `/repo/doc/development/technical_debt/input.md`
- `/repo/doc/development/smoke_checklists.md`

All left uncommitted in both repos, per instruction.

---

## Parent's note (2026-08-12) — one edit was moved, so this report quotes a comment that no longer exists

The worker reduced `main.lua`'s trailing comment to one line. **The parent deleted it instead** and
folded its one real claim — that `love.*` globals would work, since the framework captures them into
the same hooks (`projectInputController.lua`, `seed_hooks`) — into `input.lua`'s header, where the
registration choice is described. An orphan comment at end of file is not where a reader looks for
it. Everything the worker wrote about `main.lua` above therefore describes an intermediate state, not
the tree: see `f09f1e7`. The other three corrections landed as written.

Recorded here because a narrow review found this report quoting text that is not in the repository,
and a result file that describes a state nobody can reach is worse than one that says it was
superseded.
