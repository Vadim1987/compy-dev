# Compy Editor Rework — Specification (final)

Status: behavior approved by the product owner.
Effort estimates are tracked in a separate document.

The document has a product part (sections 1–4) and a technical
part (sections 5–9). The technical part follows from the
product part.

---

## 1. General

**1.1. Goal and frame.** The block editor is first of all a
pedagogical idea: a constraint that nudges children toward
structured thinking. The rework's goal is not to bring it closer
to a regular editor (imitating vim or nano would be pointless:
we would lose a unique didactic instrument and gain a poor
ordinary editor), but to make work inside the block frame
predictable and comfortable, with the shortcuts people are used
to (Windows/Linux conventions). The audience is children:
predictable behavior takes priority over feature density.

**1.2. The block model.** The unit of saving is a block (a
complete top-level construct); auto-formatting on block
acceptance remains.

**1.3. Settled decisions:**

- Block size limit: **14 lines** (the input strip's height). An
  open block is always fully visible; scrolling inside a block
  does not exist under any circumstances.
- A block over the limit cannot be saved: an explicit, visible
  message along the lines of "Too many lines in a block. Remove
  N lines to save or press Shift+Esc to cancel". Oversized
  blocks from external files still open for viewing and editing;
  saving requires fitting the limit, or splitting on acceptance.
- A file that fails to parse opens **read-only**, as today. A
  line-editing mode is deliberately not introduced (a decision
  of frame 1.1); fixing such a file happens off the device (the
  card in a regular computer).
- The device's right mouse button emits Esc — a **temporary
  property**, until it is detached at the system level; the Esc
  requirements (2.3) are designed with it in mind but stand on
  their own.
- Changes are applied in memory; the file is written to disk by
  explicit actions (2.6).

---

## 2. Target behavior

### 2.1. Modes

- **Navigation** — moving through the file, operations on
  blocks. Typing does not change the file; typing printable
  characters opens the search bar and searches as you type.
- **Editing** — exactly one block is open; all input goes into
  it.

Block reorder (Ctrl+M) and search (Ctrl+F) are sub-modes of
navigation. The current mode is always visible: an indicator in
the statusline and the active block's frame color.

### 2.2. Navigation: lines, not blocks

The navigation selection moves **by lines**: Up/Down arrows move
one line (crossing a large block does not jump and lose the
reader). Enter opens the block the selected line belongs to,
with the cursor on that line.

Block-wise movement is Ctrl+↑/↓ (the paragraph-jump convention):

- Ctrl+↓ — to the first line of the next block;
- Ctrl+↑ — to the first line of the current block if a different
  line is selected; otherwise to the first line of the previous
  block.

Scrolling without moving the selection: Alt+↑/↓ — one line,
PageUp/PageDown — one page.

### 2.3. The Esc key

A bare Esc is safe in every context (see 1.3 on RMB).

| Context | Esc | Shift+Esc |
|---|---|---|
| Navigation | no action | leave the editor; with unsaved changes, offer to save (save / don't save / stay) |
| Editing | no action | discard the block's edits, return to navigation at that block |
| Reorder | no action | cancel the move |
| Search | no action | cancel the search |

Esc never opens a block. Shift+Esc has one meaning everywhere:
leave / cancel one level up. Shift+Esc is an exit, not an "exit
without saving": losing changes takes an explicit "don't save"
answer.

### 2.4. Leaving the open block

Inside an open block the arrows move the cursor through the
block's lines. Requirements for any way of leaving the block
(arrow past the edge, Ctrl+↑/↓, jumping from search, closing the
file):

1. Block untouched — leave with no side effects.
2. Changed — validate and **accept into memory** (auto-format,
   re-chunk; no disk write).
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

- Accepting a block (Enter, a transition) applies the change to
  the file **in memory**.
- Disk writes: Ctrl+S (explicit save with an indication) and
  Ctrl+W (write and close the file).
- Shift+Esc in navigation leaves the editor; with unsaved
  changes it offers to save (save / don't save / stay).
- The unsaved-changes marker is always visible (statusline).

### 2.7. Hotkeys

Conflicts with the conventions that make the rework mandatory:
Ctrl+Y (currently deletes a block; conventionally — redo),
Ctrl+S (currently closes; conventionally — save), Ctrl+O
(currently follows a require; conventionally — open).

| Combo | Navigation | Editing |
|---|---|---|
| ↑/↓ | selection one line | cursor through the block's lines |
| Ctrl+↑/↓ | block-wise movement (2.2) | accept + block-wise move |
| Alt+↑/↓ | scroll one line | scroll one line (context) |
| Ctrl+Alt+↑/↓ | move the block | move the line up/down |
| PageUp/Down | scroll one page | scroll (context) |
| Enter | open the block (cursor on the selected line) | line break |
| Ctrl+Enter | new empty block below the selection, open it | accept the block, back to navigation |
| Shift+Esc | leave (offer to save) | discard the block's edits |
| Ctrl+C / Ctrl+Insert | copy the block | copy the text selection |
| Ctrl+X / Shift+Delete | cut the block | cut the text selection |
| Ctrl+V / Shift+Insert | paste as block(s) below the selection | paste text |
| Ctrl+Delete | delete the block | — |
| Ctrl+A | — | select the whole block |
| Ctrl+←/→ | — | word-wise movement |
| Shift+arrows | — | text selection |
| Home / End | first / last line of the file | start / end of line |
| Ctrl+S | write to disk (indication) | write to disk |
| Ctrl+W | write and close the file | — |
| Ctrl+F | search (also opens by typing) | — |
| Ctrl+M | block reorder mode | — |
| F12 | follow the require | — |

Layout notes:

- A new block is Ctrl+Enter in navigation (Insert was rejected:
  traditionally it toggles insert/overwrite).
- Ctrl+M in terminals is equivalent to Enter (sends CR); the
  editor on the device does not reproduce the conflict, so the
  binding stays; if the device proves otherwise, it will be
  replaced.
- Undo/Redo (Ctrl+Z / Ctrl+Y) are reserved in the layout and
  disabled in version 1.0 (2.8).

### 2.8. Undo

A full two-level Undo/Redo (text within a block; block
operations) is agreed in principle and lands as a separate stage
**after version 1.0**. In 1.0 the protection is file-level:
changes are not auto-written to disk; leaving without writing
takes a "don't save" answer to the exit offer; Shift+Esc while
editing rolls back the block and returns to it.

### 2.9. Mouse

Stage 3. Target behavior: click — select the line; double click
— open the block; clicking another block from editing — per 2.4;
clicking inside the open block — place the cursor.

---

## 3. Work order

1. **Stage 1 — modes and behavior**: mode split, Esc semantics
   with the save offer, line-wise navigation with Ctrl block
   jumps, one exit path from the open block, in-memory
   acceptance + explicit writes, the 14-line limit, mode and
   unsaved-changes indication, refusal feedback.
2. **Stage 2 — hotkeys**: the 2.7 layout on top of the new input
   routing; chord glyph suppression; Alt/page scrolling. A
   device check precedes this stage.
3. **Stage 3 — mouse.**

Outside 1.0: Undo/Redo; the child-friendly error dictionary (a
separate team-wide UX effort).

---

## 4. Open items

1. **The save-offer dialog** (wording and the answer keys for
   save / don't save / stay) — a proposal comes with the stage 1
   implementation.

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

- the block limit: 14 (settles the input_max = 14 vs.
  16-line-check divergence in favor of 14; a one-point fix at
  `get_max_size`);
- the navigation selection unit (block → line), with block-wise
  movement on Ctrl+↑/↓;
- the persistence model: acceptance writes to memory, disk
  writes are Ctrl+S / Ctrl+W; leaving with unsaved changes
  offers to save;
- typing in navigation: opens search-as-you-type instead of
  composing a new block;
- Undo moves past 1.0.

The acceptance pipeline (auto-format → re-chunk → size check →
replace with position shifting) stays; the write target (memory
instead of disk) and the write points change.

## 6. State model and transitions

States `nav`/`editing`, sub-modes `reorder`/`search` from `nav`.
The navigation selection is a line (model: a file line index;
block membership derives from the existing block positions).
Opening a block places the cursor on the selected line.

The exit path stays as implemented, with two changes: acceptance
does not write to disk; after acceptance on a transition the
view scrolls to the block that opened, after acceptance in place
— back to the current block.

File dirtiness (accepted but unwritten changes) is a buffer
flag, feeding the status indication, the exit save offer, and
the Ctrl+S / Ctrl+W writes.

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
added coordination point: the save-offer dialog, if it is built
on the input widget.

Device check before stage 2: chord glyphs reaching the platform
input's text; textinput/keypressed ordering on the platform
path; repeat glyphs on key hold; confirming the RMB→Esc binding
level (and recording that it is temporary).

## 9. Acceptance criteria

1. RMB and a bare Esc perform no action in any state.
2. Navigation arrows move by lines; Ctrl+↑/↓ move by blocks per
   2.2; Enter opens the block with the cursor on the selected
   line.
3. Leaving a changed valid block by arrow: accepted into memory,
   the neighbor opens with the cursor on the near line, the view
   scrolls to it; an invalid block — sound, frame, message, the
   block stays. Scrolling inside a block does not exist.
4. An untouched block is not reformatted on leave.
5. Acceptance does not write to disk; Ctrl+S writes; Ctrl+W
   writes and closes; Shift+Esc with unsaved changes offers to
   save — losing them takes an explicit "don't save".
6. A block of 15+ lines cannot be saved: a visible message
   naming the excess; Shift+Esc cancels.
7. Typing in navigation opens search-as-you-type; the file does
   not change.
8. A file that fails to parse opens read-only.
9. The current mode and the unsaved-changes marker are always
   visible.
10. Shift+Esc from editing restores the block's original text
    and leaves the selection on it.
