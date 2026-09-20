---
description: Behavior and tech spec for the Compy IDE editor rework — modes, line-wise navigation, immediate saves with checkpoints, and normalized hotkeys.
status: approved
audience: developer
---
# Compy Editor Rework — Specification 1.0-1.1

Status: behavior approved by the product owner.
This specification mostly covers 1.0 release version of the product
(target: July 2026). The Undo/Redo feature is postponed to 1.1 and
implemented in the same timeframe if resources allow.

The document has a product part (sections 1–4) and a technical
part (sections 5–9). The technical part follows from the
product part.

---

## 1. General

**1.1. Goal and frame.** The block editor creates a constraint
that nudges children toward structured thinking. The rework's
goal is to make work inside the block frame predictable and
comfortable, with
the shortcuts people are used to (Windows/Linux conventions).
The audience is children: predictable behavior takes priority
over feature density.

**1.2. Non-goals.** We don't aim to make a general-purpose editor,
nor to implement a fully-featured IDE. It's okay not to be able to
edit a file that fails to parse.

**1.3. The block model.** The unit of saving is a block (a
complete top-level construct); auto-formatting on block
acceptance remains.

**1.4. Settled decisions:**

- Block size limit: **14 lines** (the input strip's height). An
  open block is always fully visible; scrolling inside a block
  should not occur in normal circumstances.
- A block over the limit cannot be saved: an explicit, visible
  message along the lines of "Too many lines in a block. Remove
  N lines to save or press Shift+Esc to cancel". Oversized
  blocks from external files still open for viewing and editing;
  saving requires fitting the limit, or splitting on acceptance.
- A file that fails to parse opens **read-only**. Fixing
  such a file happens off the device (attach the SD card to a
  regular computer).
- The device's right mouse button emits Esc — a **temporary
  property**, until it is detached at the system level; the Esc
  requirements (2.3) are designed with it in mind but stand on
  their own.
- Accepted changes are written to the file immediately, so
  **what is on screen is always the content of the actual
  file**. Ctrl+S makes a restore checkpoint; Ctrl+R and the
  REPL's `revert()` restore it (2.6).

---

## 2. Target behavior

### 2.1. Modes

- **Navigation** — moving through the file, operations on
  blocks. Typing a printable character starts editing at the
  active line: the editor opens that line's block and inserts a
  blank line at the active line (pushing it and the rest down)
  to type into. On a blank line (an empty block — the empty file
  is one) the typed text turns that line into a new block. Blank
  lines are structural: the editor keeps at most one between
  blocks and regenerates them on re-chunk, so typing cannot
  place or stack them freely. Final block boundaries follow from
  the re-chunk on acceptance (2.4).
- **Editing** — exactly one block is open; all input goes into
  it.

Block reorder (Ctrl+M) and search (Ctrl+F) are sub-modes of
navigation. The current mode is always visible: an indicator in
the statusline and the active block's frame color.

### 2.2. Navigation: by lines

The active line moves **by lines**: Up/Down arrows move it one
line (crossing a large block does not jump and lose the reader).
The whole block the active line belongs to is slightly
highlighted (less prominently than the active line). Enter opens
that block, with the cursor on the active line.

Block-wise movement is Ctrl+↑/↓ (the paragraph-jump convention):

- Ctrl+↓ — to the first line of the next block;
- Ctrl+↑ — to the first line of the current block if the active
  line is not already the first; otherwise to the first line of
  the previous block.

Scrolling without moving the active line: Alt+↑/↓ — one line,
PageUp/PageDown — one page (screen height). If the active line is
scrolled out of view, any input other than scrolling returns the
view to it.

### 2.3. The Esc key

A bare Esc is safe in every context (see 1.4 on RMB): it never opens
a block and never discards anything. Accepted changes are already
on disk (2.6), so leaving the editor is immediate. The following
table summarizes the Esc/Shift+Esc behavior:

| Context    | Esc               | Shift+Esc                                                     |
| ---------- | ----------------- | ------------------------------------------------------------- |
| Navigation | no action         | leave the editor                                              |
| Editing    | no action         | discard the block's edits, return to navigation at that block |
| Reorder    | cancel the move   | cancel the move                                               |
| Search     | cancel the search | cancel the search                                             |

Shift+Esc has one meaning everywhere: leave / cancel one level up.

### 2.4. Leaving the open block

Inside an open block the arrows move the cursor through the
block's lines. Requirements for any way of leaving the block
(arrow past the edge, Ctrl+↑/↓, jumping from search, closing the
file):

1. Block untouched — leave with no side effects.
2. Changed — validate, auto-format, and re-chunk, then **accept**
   the block and write it to the file (2.6).
3. Invalid — the leave is refused: a short sound (respecting a
   muted device), a red frame, a message stating the reason, the
   cursor moved to the error.
4. Acceptance on an arrow transition opens the neighboring
   block: downward — cursor on its first line, upward — on its
   last. The view scrolls to the block that just opened;
   acceptance in place scrolls back to the current block.

Scrolling from an open block (Alt+↑/↓, PageUp/PageDown) is
context viewing: the edited block does not change, and typing
returns the view to it.

### 2.5. Error messages

Version 1.0 shows the parser's messages as they are, in the
statusline, until the first keystroke that starts fixing.
Translating messages into child-friendly language is a separate
UX effort for the whole team, outside this spec.

### 2.6. Saving

- Accepting a block (Enter, a transition) writes the change to
  the file **immediately**. What is on screen is always the
  content of the actual file.
- **Ctrl+S** makes a **checkpoint**: a copy of the current file at
  `{file.ext}.~save` (e.g. `main.lua.~save`). If a checkpoint
  already exists, Ctrl+S asks for confirmation before overwriting
  it, showing that checkpoint's date/time. In editing, Ctrl+S
  accepts the open block first, so the checkpoint reflects the
  screen.
- **Ctrl+R** restores the file from its checkpoint, if one exists,
  gated on a confirmation showing the checkpoint's and the file's
  date/time. It writes the checkpoint over the file, so the open
  editor shows it too.
- The REPL exposes **`revert(name)`** — restore the checkpoint for
  `name` (default `main.lua`). It returns `false` if there is no
  checkpoint and `true` on success, and does not prompt.
- One checkpoint per file, written only by Ctrl+S.

### 2.7. Hotkeys

Conflicts with the conventions that make the rework mandatory:
Ctrl+Y (currently deletes a block; conventionally — redo),
Ctrl+S (currently closes; conventionally — save), Ctrl+O
(currently follows a require; conventionally — open).

| Combo                 | Navigation                                     | Editing                                         |
| --------------------- | ---------------------------------------------- | ----------------------------------------------- |
| ↑/↓                   | move the active line one line                  | cursor through the block's lines                |
| Ctrl+↑/↓              | block-wise movement (2.2)                       | accept + block-wise move                        |
| Ctrl+←/→              | —                                              | move to the beginning of the previous/next word |
| Ctrl+Home/End         | —                                              | move to the beginning/end of the block          |
| Alt+↑/↓               | scroll one line                                | scroll one line (context)                       |
| Ctrl+Alt+↑/↓          | move the block                                 | move the line up/down                           |
| PageUp/Down           | scroll one page                                | scroll (context)                                |
| Enter                 | open the block (cursor on the active line)     | line break                                      |
| Ctrl+Enter            | new empty block below the current block, open it | accept the block, back to navigation            |
| Ctrl+Shift+Enter      | new empty block above the current block, open it | —                                               |
| Shift+Esc             | leave the editor                               | discard the block's edits                       |
| Ctrl+C / Ctrl+Insert  | copy the block                                 | copy the text selection                         |
| Ctrl+X / Shift+Delete | cut the block                                  | cut the text selection                          |
| Ctrl+V / Shift+Insert | paste as block(s) above the current block        | paste text                                      |
| Ctrl+Backspace / Ctrl+W | —                                              | delete the previous word                        |
| Ctrl+Delete           | delete the block (see note below)              | delete the next word                            |
| Ctrl+A                | —                                              | select the whole block                          |
| Shift+arrows          | —                                              | text selection                                  |
| Home / End            | first / last line of the file                  | start / end of line                             |
| Ctrl+S                | checkpoint (confirm if one exists)             | accept, then checkpoint                         |
| Ctrl+R                | restore from checkpoint (confirm)              | —                                               |
| Ctrl+F                | search                                         | —                                               |
| Ctrl+M                | block reorder mode                             | —                                               |
| F12                   | follow the require                             | —                                               |

Layout notes:

- Ctrl+M (block reorder): terminals send CR for Ctrl+M (an Enter
  equivalent), but the device's input path does not, so the
  binding is safe.
- Undo/Redo (Ctrl+Z / Ctrl+Y) are reserved in the layout and
  land in 1.1 (2.8).
- Raw Delete deletes the block in navigation only once Undo/Redo
  exists (1.1); in 1.0 the binding is Ctrl+Delete.

### 2.8. Undo

A full two-level Undo/Redo (text within a block; block
operations) is agreed in principle and lands as a separate stage
**after version 1.0** (tentatively: 1.1). Until then there is no
in-editor undo; the file-level safety net is the Ctrl+S / Ctrl+R
checkpoint (2.6).

### 2.9. Mouse

Stage 3. Target behavior: click — set the active line; double
click — open the block; clicking another block from editing —
per 2.4; clicking inside the open block — place the cursor.

---

## 3. Work order

1. **Stage 1 — modes and behavior**: mode split, Esc semantics,
   line-wise navigation with Ctrl block jumps, one exit path from
   the open block, immediate writes on accept, Ctrl+S / Ctrl+R
   checkpoints and the REPL `revert()`, the 14-line limit, mode
   indication, refusal feedback.
2. **Stage 2 — hotkeys**: the 2.7 layout on top of the new input
   routing; chord glyph suppression; Alt/page scrolling. A
   device check precedes this stage.
3. **Stage 3 — mouse.**
4. **Stage 4 — Undo/Redo** (Ctrl+Z / Ctrl+Y). Implemented after
   1.0 release (tentatively: 1.1), when the team has resources to spare.

Outside the spec: the child-friendly error dictionary (a
separate team-wide UX effort).

---

## 4. Open items

1. **Checkpoint / restore confirmations** — the Ctrl+S overwrite
   prompt and the Ctrl+R restore prompt: exact wording and answer
   keys (both show the relevant checkpoint's date/time); a
   proposal comes with the stage 1 implementation.

---

## 5. Current implementation (reference)

Code references: dev @ 7728158, plus the completed mode-split
work (branch feat/editor-nav-editing).

The original implementation multiplexed navigation and editing
in a single `edit` mode, disambiguating by implicit state. The
completed work introduced explicit `nav`/`editing` modes, a
single exit path from the open block (dirty-check → validation →
accept/refuse), and the Esc/Shift+Esc semantics. This spec
version additionally changes:

- the block limit: 14;
- the navigation unit (block → line; the active line), with
  block-wise movement on Ctrl+↑/↓;
- checkpoints: Ctrl+S writes a restore checkpoint
  `{file.ext}.~save`, Ctrl+R and the REPL `revert()` restore it
  (persistence itself is unchanged — accept still writes
  immediately);
- Undo moves past 1.0.

The acceptance pipeline (auto-format → re-chunk → size check →
replace with position shifting) and the immediate write on
acceptance are unchanged; the rework adds Ctrl+S / Ctrl+R /
`revert()` checkpoints on top.

## 6. State model and transitions

States `nav`/`editing`, sub-modes `reorder`/`search` from `nav`.
The active line is a file line index; block membership derives
from the existing block positions (every line belongs to a
block; a blank line is an empty block). Blank lines are
normalized by auto-format / re-chunk — at most one between
constructs, positioned by syntax — so they are not freely
placeable. Opening a block places the
cursor on the active line.

The exit path stays as implemented (dirty-check → validation →
refusal with sound/frame/message/cursor → acceptance), with a change:
after acceptance on a transition the view scrolls to the block that
opened, after acceptance in place — back to the current block.

Accepted changes are written immediately, so the on-screen
content always equals the file. The checkpoint is a separate file
`{name}.~save`; the prompts show its and the file's modification
time via `FS.getInfo`. Its presence gates the Ctrl+S overwrite
confirmation and enables Ctrl+R / `revert()`, both of which
restore by writing the checkpoint back over the file.

## 7. Hotkey implementation

Dispatch on top of the #77 input routing (a combo-string
registry with "ctrl+s"-style serialisation, the held-keys table,
the repeat flag); the editor is the scheme's second consumer, no
parallel mechanism is built. Chord glyph suppression is
structural (textinput with Ctrl/Alt held is ignored). Repeats
are allowed for movement (arrows, scrolling) and swallowed for
commands.

## 8. Input-layer coordination and the device check

The boundaries stand: free — everything past input detection; by
agreement — userInputController internals and how its callbacks
are invoked; taken as external — the #77 dispatch mechanism. One
added coordination point: the checkpoint / restore confirmation
dialogs, if built on the input widget.

Device check before stage 2: chord glyphs reaching the platform
input's text; textinput/keypressed ordering on the platform
path; repeat glyphs on key hold; confirming the RMB→Esc binding
level (and recording that it is temporary).

## 9. Acceptance criteria

1. RMB and a bare Esc perform no action in navigation and editing
   states.
2. Navigation arrows move the active line by lines; Ctrl+↑/↓ move
   by blocks per 2.2; Enter opens the block with the cursor on the
   active line.
3. Leaving a changed valid block by arrow: written to the file,
   the neighbor opens with the cursor on the near line, the
   view scrolls to it; an invalid block — sound, frame, message,
   the block stays. Scrolling inside a block can only exist as an
   ephemeral state if an externally-created block is more than 14
   lines; the editor refuses to save it until it is split into
   smaller blocks.
4. If a block was improperly formatted, it is auto-formatted on
   opening. Then the standard pipeline applies: if the block is
   invalid after auto-formatting (e.g. more than 14 lines), the
   user can only leave by fixing it or pressing Shift+Esc to
   discard the changes.
5. Accepting a block writes it to the file immediately. Ctrl+S
   copies the file to `{file.ext}.~save`, asking for confirmation
   (showing the existing checkpoint's date/time) if one already
   exists. Ctrl+R restores the file — and the open editor — from
   that checkpoint after a confirmation showing the checkpoint's
   and the file's date/time. In the REPL, `revert(name)` (default
   `main.lua`) restores the checkpoint, returning `false` if none
   exists and `true` on success.
6. A block of 15+ lines cannot be saved: a visible message
   naming the excess; Shift+Esc cancels.
7. Typing in navigation opens the block at the active line and
   inserts a blank line to type into; on a blank line it starts a
   new block instead. Final block boundaries follow from the
   re-chunk on acceptance.
8. A file that fails to parse opens read-only.
9. The current mode is always visible in the statusline.
10. Shift+Esc from editing restores the block's original text
    and leaves the active line on it.
