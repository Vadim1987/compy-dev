# Prompt of record — P-18-20, the tidy batch (delegated worker)

**Commissioned:** 2026-08-12, session38. **Model:** Sonnet, passed explicitly. **Scope:** four small
corrections the third cold revalidation named (`../reviews/S38-P18-final-revalidation-3.md`, D1, O2,
O3(b), O4-O6). **The worker never touches git state**; the parent reviews the diff site by site and
commits.

The prompt as given follows verbatim.

---

You are making four small, precise corrections in a LÖVE2D project. **Do not run any git command
that changes state** — no `add`, no `commit`, no `checkout`, no `stash`, in any repository. Leave
every edit uncommitted in the working tree. `git diff`, `git log`, `git show` for reading are fine.

Two repositories are involved and they are separate:

- **`/repo`** — the platform (a LÖVE2D IDE).
- **`/repo/src/examples/keyboard`** — a nested, separate git repository: a children's typing game
  written by a third party, which the platform ships as an example. Edits here land in someone
  else's tree and will be offered to them as a patch.

A rule that applies to every comment you touch in the game repo: **a comment there may never cite a
platform doc** (`doc/...`) or a platform-internal identifier (a decision number). That path cannot be
followed from a repository that does not contain it. Say the thing in place, briefly, or leave it
out. The author's own `docs/...` references are theirs — do not touch them. Full comment rules:
`/repo/agents/rules/commenting.md` — read it before editing any comment. Its size rule matters here:
minimal viable, no second phrasing of a point already made, no narrating history (git holds that).
The game's own convention is **64 columns**, which upstream keeps at zero violations; do not exceed it.

## The four tasks

### 1. A stale comment — `src/examples/keyboard/words.lua`, at `wordsBaseKey`

The comment says the function maps a target glyph to *"space for a space, the lowercase key for a
letter (incl. a capital), else the glyph itself (an unshifted punctuation key)"*. The body now
forwards to `glyphBaseKey` (in `input.lua`), which **also** inverts `SHIFT_MAP` — so a shifted symbol
maps to its base key, not to itself. That branch is exactly what stops the game crashing when a
player types `~` or `|` in Words (`love.keyboard.isDown` raises on a string that is not a key
constant). Read `glyphBaseKey` and make the comment describe what it does. Keep it short — this is a
one-line delegating function.

### 2. A wrong count — `/repo/doc/development/technical_debt/input.md`

The entry *"A gesture that tolerates a modifier costs one registration per variant"* says
`examples/keyboard` *"pays **eleven** registrations"* and later *"one file's **eleven** lines"*. The
code registers **twelve** (`src/examples/keyboard/input.lua`, in `register_reserved` — count the
`sc[...] = ...` assignments and verify). Correct both occurrences. Change nothing else in that entry;
its argument does not depend on the number.

### 3. A missing smoke row — `/repo/doc/development/smoke_checklists.md`, `keyboard` section

`Ctrl+Alt+H` re-arms a teaching hint, and only the "Alt characters" game defines that hint. Because it
is a registered shortcut, it is **swallowed in every other game too** — where before the migration a
bare `h` reached the scene and could knock as a wrong key. That is an accepted deviation and no row
covers it. Add one row to section **D** (the reserved chords), in the style of its neighbours:
pressing `Ctrl+Alt+H` in a game that has no hint — e.g. **1** Press the key, or **6** Blow the bubble
— does nothing at all: no knock, no miss, no sound. Mark it `[new]` as the other never-run rows are,
and add its id to the list under "What a failure here means" that enumerates the `[new]` rows.

### 4. Comment economy — three sites, all in the game repo

Each of these ships more prose than payload into a third party's file.

- **`bubble.lua`**, the block above `bubbleKeyreleased`. Eight lines, of which the last three (the
  focus-loss caution and the timeout that absorbs it) are the payload a maintainer needs. The rest
  argues with a position nobody in that repository holds — that a poll could have measured the hold,
  and that the channel is the author's choice. Keep the caution. Reduce the argument to at most one
  clause, or drop it.
- **`main.lua`**, the trailing comment at the very end of the file, about handlers being registered
  in `inputInit` rather than as `love.*` globals. The file's **own header** already says this. Delete
  the trailing one, or reduce it to whatever it says that the header does not — check both before
  deciding.
- **`input.lua`**, the header sentence about `setTextInput(true)`. It says the call is for the device
  and then that it is redundant, which reads as a contradiction, and one of its lines is wrapped
  ragged (much shorter than the rest). Make it one clear statement in whole lines: the IDE makes the
  same call at its own boot, so the line matters for the device build and is harmless here.

## What to hand back

Write your report to
**`/repo/doc/development/wip/77-new-input-api/validation/outcomes/P-18-20-tidy.md`** — what you
changed, file and line, and any place where you found the instruction did not match the code (say so
rather than guessing; the parent will rule). List anything you deliberately did not touch.

Then verify, and put the results in the report:

- every `.lua` file you edited still parses: `luajit -e "assert(loadfile('<file>'))"`;
- no line you wrote exceeds 64 columns: `awk 'length>64 {print FILENAME":"FNR}' <files>`;
- no comment you wrote cites a `doc/...` path;
- the app still loads, run from `/repo`:
  `timeout 25 xvfb-run -a stdbuf -oL -eL love src play src/examples/keyboard` — expect it to be
  killed by the timeout with no `Error:` line. **The line buffering matters**: without `stdbuf` the
  kill discards the output and a raising project looks healthy.

**A tool you should use for anything about a symbol:** the `lua-lsp` MCP server gives definitions,
references and diagnostics over a real AST of the `/repo` workspace — use it to resolve `glyphBaseKey`
and to check who calls what, rather than inferring from a grep. After editing a `.lua` file, `sleep 1`
before querying it: the language server re-indexes.

**Leave everything uncommitted.** The parent reviews and commits.
