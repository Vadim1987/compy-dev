---
description: Field-by-field audit of doc/mermaid/ (7 files, 32 class blocks) against src/ as it exists today
status: audit report
audience: developer
authored: llm
session: 67
date: 2026-09-02
---

# Audit — `doc/mermaid/` vs `src/` (2026-09-02)

## Verdict

**LSP was healthy throughout** — `mcp__lua-lsp__definition` and `mcp__lua-lsp__references`
answered every query (confirmed with `UserInputModel`, `EvalBase`, `InterpreterModel`,
`InterpreterController`, `InputController`, `EditorController.model`); no `broken pipe` was hit,
no finding below rests on an errored query treated as empty. One `references` call on the bare
name `UserInputModel` overflowed the tool's output-token cap (2,047 lines) — not a broken-pipe
outage — so that specific call was abandoned in favour of reading source files directly and
narrower `references` queries; every finding that needed it is instead backed by a direct
`Read` of the defining file (constructor + `@field`/`@class` annotations) or a scoped LSP call,
cited by file and line below. Every "does not exist" claim (`EvalBase`, `InterpreterModel`,
`InterpreterController`, `InputController`, `InputModel`, `InterpreterView`, `InputView`,
`InputEval`, `HistoryModel`, `EditorInterpreter`, `InterpreterBase`, `Selected`) is cross-checked
two ways: `grep -rn` over `/repo/src` (excluding `examples/` and `lib/`) returning zero hits, and
an LSP `definition` query returning `"<name> not found"` for the four spot-checked above.

Seven files, **32 class blocks**, reviewed member-by-member. Headline: **classes.md and
editor.md are substantially stale** — not just the `oneshot`/`custom_label` row the debt entry
named, but whole classes that no longer exist (`InputModel`, `InterpreterModel`,
`InterpreterController`, `InputController`, `InputView`, `InterpreterView`, `EvalBase`) still
drawn with fields and relationship arrows, plus renamed methods, wrong field types, and at least
two places where the **source annotation itself disagrees with its own constructor** (not a
diagram problem, a code-comment problem the diagram inherited). `eval.md`'s two headed sections
turn out to be inverted in trustworthiness — the section literally labelled "Current" describes a
class hierarchy (`EvalBase` + subclasses) that was never built; the section labelled "Planned
refactor" is the one closer to what actually shipped. `input.md` and the second half of
`scratch.md` are flagged per the commission's instruction rather than graded as live references —
see their sections below. `fsm.md`/`fsm_f.md` carry no class blocks at all.

Rough tally across all class blocks: of the members drawn, roughly a third are OK, roughly a
third are STALE/MISSING-class-context (drawn on a class/type that no longer exists), and the
remainder splits between renamed members, type mismatches, and members present in code but absent
from every diagram. Exact per-block counts are in each table below.

---

## `doc/mermaid/classes.md`

Four sections: **Model**, **View**, **Controller**, **MVC**. 8 class blocks total.

### Model section

Relationship arrows as drawn:
```
BufferModel --* EditorModel
EditorInterpreter --* EditorModel
EditorModel --* ConsoleModel
InputModel --* InterpreterModel
CanvasModel --* ConsoleModel
InterpreterModel --* ConsoleModel
```

`EditorInterpreter`, `InputModel`, `InterpreterModel` do not exist anywhere under `/repo/src`
(grep zero hits outside `examples/`/`lib/`; LSP `definition` confirms `InterpreterModel` "not
found"). Ground truth, from `/repo/src/model/editor/editorModel.lua:7-19` (`@class EditorModel`)
and `/repo/src/model/consoleModel.lua:7-21` (`@class Model`, the runtime name for what the
diagram calls `ConsoleModel`):

- `EditorModel` composes `input: UserInputModel`, `buffers: Dequeue<BufferModel>`,
  `search: Search`, `cfg: Config`. So `BufferModel --* EditorModel` is **OK** (via `buffers`),
  but `EditorInterpreter --* EditorModel` is **STALE** — should be
  `UserInputModel --* EditorModel` (and `Search --* EditorModel` is undrawn, **MISSING**).
- `ConsoleModel` composes `input: UserInputModel`, `editor: EditorModel`, `output: CanvasModel`,
  `projects: ProjectService`, `cfg: Config`. So `EditorModel --* ConsoleModel` and
  `CanvasModel --* ConsoleModel` are **OK**; `InterpreterModel --* ConsoleModel` is **STALE** —
  should be `UserInputModel --* ConsoleModel`; `InputModel --* InterpreterModel` is **STALE**,
  both endpoints are non-existent classes.

#### `class ConsoleModel`

| member as written | exists in code? | where (file, symbol) | verdict |
|---|---|---|---|
| `projects: ProjectService` | yes | `src/model/consoleModel.lua:11,18` `@field projects ProjectService` / `projects = ProjectService()` | OK |

Only one field is drawn. The real class (named `Model` in the `@class` annotation, but assigned
to the global `ConsoleModel`, `src/model/consoleModel.lua:13`) has four more fields never drawn:
`input: UserInputModel`, `editor: EditorModel`, `output: CanvasModel`, `cfg: Config` — all
**MISSING**.

#### `class InputModel`

The class itself does not exist. `grep -rn '\bInputModel\b' src --include=*.lua` (excluding
examples/lib) returns nothing; LSP `definition` on `InputModel` was not separately queried here
because the identical-shaped `editor.md`/`input.md` blocks already establish it (see below) and
`InterpreterModel`/`InterpreterController`/`InputController` were confirmed absent by LSP. Every
member below is therefore **UNVERIFIABLE-as-drawn**: there is no `InputModel` class to check a
field against. Treating the block as "this is actually `UserInputModel` under an old name" (the
debt entry's framing) — see the `UserInputModel` table under `editor.md`, which is the live class
these fields most closely resemble. Distinctive to *this* block: `type: InputType` and
`wrapped:_text WrappedText` do not appear in `UserInputModel` at all — `type` is not a field of
`UserInputModel` anywhere (`grep -n 'self\.type' src/model/input/userInputModel.lua` — no hits),
and `wrapped:_text` is a **MALFORMED** line — the colon is misplaced (`wrapped:_text` parses as
member `wrapped` typed `:_text`, not member `wrapped_text` typed `WrappedText`; compare
`editor.md:52` and `scratch.md`'s use of `wrapped: WrappedText` without the stray colon-underscore).

#### `class InterpreterModel`

Same situation: the class does not exist (LSP `definition`: `"InterpreterModel not found"`).
`input: InputModel` compounds onto a second non-existent class. `get_entered_text()` — grep for
this method name across `/repo/src` (excluding examples/lib) returns zero hits; it is not
implemented anywhere under any class. All members **UNVERIFIABLE-as-drawn** for the same reason
as `InputModel` above.

### View section (relationship arrows only, no class blocks)

```
Statusline --* InputView
InputView --* InterpreterView
InterpreterView --* ConsoleView
EditorView --* ConsoleView
CanvasView --* ConsoleView
BufferView --* EditorView
InputView --* EditorView
```
`InputView` and `InterpreterView` do not exist (grep zero hits; the live input view class is
`UserInputView`, `src/view/input/userInputView.lua:27`). Ground truth from
`src/view/consoleView.lua:14-26` (`@class ConsoleView`) and
`src/view/editor/editorView.lua:9-20,25` (`@class EditorView`):
- `ConsoleView` composes `title`, `canvas: CanvasView`, `input: UserInputView`,
  `editor: EditorView`, `controller: ConsoleController`, `cfg`, `drawable_height`.
- `EditorView` composes `controller: EditorController`, `input: UserInputView`,
  `buffers: {[string]: BufferView}`, `search: SearchView`.

So: `EditorView --* ConsoleView` **OK**, `CanvasView --* ConsoleView` **OK**,
`BufferView --* EditorView` **OK** (via the `buffers` map). `Statusline --* InputView` is
**RENAMED** — current name `UserInputView` (`Statusline --* UserInputView` is otherwise correct:
`src/view/input/userInputView.lua:23` embeds `statusline: Statusline`). `InputView --*
InterpreterView` and `InterpreterView --* ConsoleView` are **STALE** — there is no interpreter
view layer; `UserInputView --* ConsoleView` directly (confirmed above). `InputView --*
EditorView` is **RENAMED** to `UserInputView --* EditorView` (confirmed above). `SearchView --*
EditorView`/`SearchView --* ConsoleView` are real (`search: SearchView` on both) and **MISSING**
from the diagram entirely.

### Controller section

```
class InterpreterController { model: InterpreterModel; input: InputController; set_eval() get_eval()
  get_viewdata() set_text() add_text() textinput() keypressed() clear() get_input() get_text()
  set_custom_status() }
class EditorController { model: EditorModel; interpreter: InterpreterController; view: EditorView | nil
  open() close() get_active_buffer() update_status() textinput() keypressed() }
InputController --* ConsoleController
InputController --* InterpreterController
InterpreterController --* EditorController
EditorController --* ConsoleController
class Controller { <<singleton>> }
```

`InterpreterController` and `InputController` do not exist (LSP `definition`: both "not found").
Ground truth for the real controller topology, `src/controller/editorController.lua:29-37`
(`@class EditorController`) and `src/controller/consoleController.lua:20-36`
(`@class ConsoleController`):

- `EditorController` fields: `model: EditorModel`, `input: UserInputController`,
  `search: SearchController`, `console: ConsoleController`, `view: EditorView?`,
  `state: EditorState?`, `mode: EditorMode`.
- `ConsoleController` fields: `time`, `model: Model`, `main_ctrl`, `main_env`/`pre_env`/
  `base_env`/`project_env`, `loaders`, `input: UserInputController`, `editor: EditorController`,
  `view: ConsoleView?`, `cfg: Config`.

So `InterpreterController --* EditorController` is **STALE**; the real composing relationship is
`UserInputController --* EditorController`, drawn nowhere. `InputController --* ConsoleController`
is **RENAMED** to `UserInputController --* ConsoleController`. `InputController --*
InterpreterController` is **STALE**, both endpoints gone. `EditorController --* ConsoleController`
is real in the sense that `ConsoleController.editor` holds an `EditorController` — **OK**, though
the reverse edge (`EditorController.console: ConsoleController`) is also real and undrawn
(**MISSING**). `SearchController --* EditorController` is real (`search` field) and **MISSING**.

#### `class InterpreterController`

The class does not exist. Every member below is **UNVERIFIABLE-as-drawn**, same reasoning as
`InterpreterModel` above. The method list (`set_eval, get_eval, get_viewdata, set_text, add_text,
textinput, keypressed, clear, get_input, get_text, set_custom_status`) is a near-exact match for
`UserInputController`'s real surface (`src/controller/userInputController.lua`): `set_eval` (line
137), `get_eval` (142), `set_text` (113), `add_text` (102), `get_input` (157), `get_text` (107),
`set_custom_status` (152) all exist verbatim on `UserInputController`. `textinput` and
`keypressed` exist too, but on `UserInputController`'s *keyboard* section
(`keypressed` at line 543, `textinput` at line 763) — not disputed, just noting the real owner.
`clear()` also exists (line 146). `get_viewdata()` — grep for this name across `/repo/src`
(excluding examples/lib) returns **zero hits**; it is not implemented under any current class
name, so even mapped onto `UserInputController` it would be **STALE**, not just renamed.
Net: this block reads as an old name for `UserInputController` with one method
(`get_viewdata`) that never existed under either name.

#### `class EditorController`

| member as written | exists in code? | where (file, symbol) | verdict |
|---|---|---|---|
| `model: EditorModel` | yes | `src/controller/editorController.lua:30` `@field model EditorModel` | OK |
| `interpreter: InterpreterController` | no | — | STALE (class gone; real field is `input: UserInputController`, `editorController.lua:31`) |
| `view: EditorView \| nil` | yes | `src/controller/editorController.lua:34` `@field view EditorView?` | OK |
| `open()` | yes, different signature | `editorController.lua:48` `open(name, content, save)` | OK (name matches; `save` param undrawn) |
| `close()` | yes | `editorController.lua:238` `EditorController:close()` | OK |
| `get_active_buffer()` | yes | `editorController.lua:248` | OK |
| `update_status()` | yes | `editorController.lua:280` | OK |
| `textinput()` | yes | `editorController.lua:287` | OK |
| `keypressed()` | yes | `editorController.lua:825` | OK |
| *(not drawn)* `search: SearchController` | yes | `editorController.lua:32` | MISSING |
| *(not drawn)* `console: ConsoleController` | yes | `editorController.lua:33` | MISSING |
| *(not drawn)* `state: EditorState?` | yes | `editorController.lua:35` | MISSING |
| *(not drawn)* `mode: EditorMode` | yes | `editorController.lua:36` | MISSING |

Plus ~25 more real methods not drawn (`open_view`/`init_view`, `set_mode`, `get_mode`,
`is_normal_mode`, `pop_buffer`, `close_buffer`, `follow_require`, `save`, `save_state`,
`restore_state`, `set_state`, `get_state`, `set_clipboard`, `get_clipboard`, `get_input`, and the
private `_handle_submit`/`_move_sel`/`_scroll`/`_reorg*`/`_normal_mode_keys`/`_search_mode_keys`/
`_save_keys` family) — noted collectively rather than row-by-row; the six drawn methods are all
real, so the drawing is a true subset, just an old one (`interpreter` predates the field rename
to `input`).

### MVC section

```
Config --* ConsoleModel
Config --* ConsoleController
Config --* ConsoleView
ConsoleModel --> ConsoleController
ConsoleController --> ConsoleView
class Controller { <<singleton>> }
class View { <<singleton>> }
```
`Config --* ConsoleModel`: OK (`consoleModel.lua:12` `@field cfg Config`). `Config --*
ConsoleController`: OK (`consoleController.lua:32` `@field cfg Config`). `Config --* ConsoleView`:
OK (`consoleView.lua:33` `@field cfg Config`). The two `-->` arrows and both singleton stubs are
not falsifiable against member lists (no members drawn); `Controller` (`src/controller/
controller.lua`) and a `View` module both exist as files, consistent with the singleton framing.

---

## `doc/mermaid/editor.md`

Four `mermaid classDiagram` fences plus two `sequenceDiagram` fences (sequence diagrams carry no
class blocks, not evaluated against member lists per the commission's scope). 14 class blocks.

### Block 1 — `Empty`, `Chunk`, `Block`, `Content`, `ContentType`, `More`

Ground truth: `src/model/editor/content.lua` and `src/types.lua`.

#### `class Empty`
| member | exists? | where | verdict |
|---|---|---|---|
| `tag: 'empty'` | yes | `content.lua:8,12` `@field tag 'empty'` | OK |
| `pos: Range` | yes | `content.lua:9,13` | OK |

#### `class Chunk`
| member | exists? | where | verdict |
|---|---|---|---|
| `tag: 'chunk'` | yes | `content.lua:31,46` | OK |
| `pos: Range` | yes | `content.lua:34,49` | OK |
| `lines: string[]` | yes, type differs | `content.lua:32` `@field lines Dequeue<string>` | STALE-type (annotation says `Dequeue<string>`, not `string[]`) |
| *(not drawn)* `hl: SyntaxColoring` | yes | `content.lua:33` | MISSING |

#### `class Block` (`<<enumeration>>` stereotype for a type alias)
`Block` is `--- @alias Block Empty|Chunk` (`content.lua:5`), not a `class.create()` type. Modelling
a union alias as an `<<enumeration>>` is a defensible mermaid idiom, not a defect — flagging per
the commission's "does the class itself still exist" check: **the class itself is, correctly,
not a class** — the diagram already treats it as an alias/enum, which matches. OK as drawn.

#### `class Content` (`<<enumeration>>`)
Real alias: `--- @alias Content Dequeue<string>|Dequeue<Block>` (`src/model/editor/
bufferModel.lua:27`). Diagram: `string[] | Block[]`. Same STALE-type pattern as `Chunk.lines` —
the `Dequeue<>` wrapper is dropped both places, consistently.

#### `class ContentType` (`<<enumeration>>`)
Real alias: `'plain' | 'lua' | 'md'` (`src/types.lua:33-36`). Diagram: `'plain' | 'lua'` —
**STALE**, missing the `'md'` variant (markdown buffers, wired in `editorController.lua:71-74`
via `MdEval`/`is_md`).

#### `class More`
| member | exists? | where | verdict |
|---|---|---|---|
| `up: bool` | yes | `types.lua:81` `@alias More {up: boolean, down: boolean}` | OK |
| `down: bool` | yes | `types.lua:81` | OK |

### Block 2 — `VisibleBlock`, `WrappedText`, `VisibleContent`, `VisibleStructuredContent`

Relationship arrows as drawn:
```
WrappedText <|-- VisibleContent
WrappedText *-- VisibleStructuredContent
```
Both `VisibleContent` and `VisibleStructuredContent` use the **identical** prototype pattern —
`setmetatable(X, { __index = WrappedText, __call = ... })` (`src/view/editor/
visibleContent.lua:24-32` and `src/view/editor/visibleStructuredContent.lua:37-45`). There is no
code-level distinction between an "inherits" relationship and a "composes" one here; both are
inheritance-style delegation. So `WrappedText *-- VisibleStructuredContent` is **STALE** — it
should be `<|--` like its sibling, not `*--`; the diagram draws two different relationships for
one identical pattern.

#### `class VisibleBlock`
| member | exists? | where | verdict |
|---|---|---|---|
| `wrapped: WrappedText` | yes | `src/view/editor/visibleBlock.lua:42` | OK |
| `highlight: SyntaxColoring` | yes | `visibleBlock.lua:43` | OK |
| `pos: Range` | yes | `visibleBlock.lua:44` | OK |
| `app_pos: Range` | yes | `visibleBlock.lua:45` | OK |

All four fields match the `@class VisibleBlock` annotation exactly. Fully OK.

#### `class WrappedText`
| member | exists? | where | verdict |
|---|---|---|---|
| `text: string[]` | yes, type differs | `src/util/wrapped_text.lua:31` `@field text Dequeue<string>` | STALE-type |
| `wrap_w: integer` | yes | `wrapped_text.lua:33` | OK |
| `wrap_forward: integer[][]` | yes | `wrapped_text.lua:34` (alias `WrapForward = integer[][]`, line 15) | OK |
| `wrap_reverse: integer[]` | yes | `wrapped_text.lua:35` | OK |
| `n_breaks: integer` | yes | `wrapped_text.lua:37` | OK |
| `wrap()` | yes | `wrapped_text.lua:79` | OK |
| `get_text()` | yes | `wrapped_text.lua:126` | OK |
| `get_line()` | yes | `wrapped_text.lua:131` | OK |
| `get_text_length()` | yes | `wrapped_text.lua:136` | OK |
| *(not drawn)* `orig: Dequeue<string>` | yes | `wrapped_text.lua:32` | MISSING |
| *(not drawn)* `wrap_rank: WrapRank` | yes | `wrapped_text.lua:36` | MISSING |

#### `class VisibleContent`
| member | exists? | where | verdict |
|---|---|---|---|
| `range: Range?` | yes | `src/view/editor/visibleContent.lua:7` | OK |
| `overscroll: integer` | yes | `visibleContent.lua:11` | OK |
| `overscroll_max: integer` | yes | `visibleContent.lua:10` | OK |
| `set_range()` | yes | `visibleContent.lua:117` | OK |
| `get_range()` | yes | `visibleContent.lua:113` | OK |
| `move_range()` | yes | `visibleContent.lua:130` | OK |
| `get_visible()` | yes | `visibleContent.lua:145` | OK |
| `get_content_length()` | yes | `visibleContent.lua:150` | OK |
| *(not drawn)* `offset: integer` | yes | `visibleContent.lua:8` | MISSING |
| *(not drawn)* `size_max: integer` | yes | `visibleContent.lua:9` | MISSING |
| *(not drawn)* `get_default_range()`, `check_range()`, `set_default_range()`, `get_more()`, `to_end()`, `wrap()` | yes, all six | `visibleContent.lua:55,69,124,154,62,108` | MISSING (6 methods) |

#### `class VisibleStructuredContent`
| member | exists? | where | verdict |
|---|---|---|---|
| `text: string[]` | inherited, type differs | inherited from `WrappedText`, actual `Dequeue<string>` | STALE-type (also arguably shouldn't be redrawn as an own field — it's inherited) |
| `v_blocks: VisibleBlock[]` | yes, type differs | `src/view/editor/visibleStructuredContent.lua:21` `@field v_blocks Dequeue<VisibleBlock>` | STALE-type |
| `reverse_map: ReverseMap` | yes | `visibleStructuredContent.lua:22` | OK |
| `range: Range?` | yes | `visibleStructuredContent.lua:20` | OK |
| `overscroll: integer` | yes | `visibleStructuredContent.lua:17` | OK |
| `overscroll_max: integer` | **no** — see note | — | STALE |
| `set_range()` | yes | `visibleStructuredContent.lua:154` | OK |
| `get_range()` | yes | `visibleStructuredContent.lua:149` | OK |
| `move_range()` | yes | `visibleStructuredContent.lua:160` | OK |
| `get_visible()` | yes | `visibleStructuredContent.lua:172` | OK |
| `get_content_length()` | yes | `visibleStructuredContent.lua:185` | OK |

**`overscroll_max` finding, worth being precise about**: it is not a top-level field at all, on
*either* the `@class` annotation or the actual `self.*` assignments. The constructor
(`visibleStructuredContent.lua:51-65`) stores the whole options table as `self.opts = opts`, and
`overscroll_max` lives at `self.opts.overscroll_max` (consumed at line 133,
`self.opts.overscroll_max`). The `@class VisibleStructuredContent` annotation
(lines 15-35) doesn't declare `overscroll_max` either — it declares `size_max` as if it were
top-level (`--- @field size_max integer`, line 19), but the constructor never assigns
`self.size_max`; `size_max` is likewise only reachable via `self.opts.size_max`. **This is an
annotation-vs-assignment disagreement in the source itself**, independent of the diagram: the
`@field size_max` annotation is stale against its own constructor. The diagram's `overscroll_max`
doesn't match either the (also-wrong) annotation or the real code — it should be `opts: VSCOpts`
(one field, `visibleStructuredContent.lua:11` — `@class VSCOpts` with `wrap_w`, `size_max`,
`overscroll_max`, `cfg`), and `highlighter: fun(c: string[]): SyntaxColoring` is also missing
(constructor line 58: `highlighter = highlighter`).

### Block 3 — `UserInputModel`

Ground truth: `src/model/input/userInputModel.lua:14-39` (`@class UserInputModel`) plus the real
constructor (line 45, `UserInputModel.new(cfg, eval, custom_label)` — no `oneshot` parameter).

| member as written | exists? | where (file, symbol) | verdict |
|---|---|---|---|
| `oneshot: boolean` | **no** | — | **STALE** — matches the debt entry exactly. `userInputModel.lua:448-451` even carries a comment explaining the removal: "oneshot is gone, so nothing distinguishes a single-use solicitation... Only the (never-history-reading) project widget set oneshot=true, so suppression here was already inert." |
| `entered: InputText` | yes | `userInputModel.lua:15` | OK |
| `history: History` | yes | `userInputModel.lua:16` | OK |
| `evaluator: EvalBase` | yes, type differs | `userInputModel.lua:17` `@field evaluator Evaluator` | RENAMED-type — `EvalBase` doesn't exist anywhere (LSP-confirmed); real type is `Evaluator` |
| `cursor: Cursor` | yes | `userInputModel.lua:18` | OK |
| `visible: VisibleContent` | yes | `userInputModel.lua:20` | OK |
| `wrapped_error: string[]` | field name mismatch | `userInputModel.lua:19` `@field error string[]?` | RENAMED — the real field is `self.error` (`userInputModel.lua:938,958`); `wrapped_error` is a *method*, `get_wrapped_error()` (line 942), that derives the wrapped display text from `self.error`. Same conflation appears in `scratch.md`. |
| `selection: InputSelection` | yes | `userInputModel.lua:21` | OK |
| `cfg: Config` | yes | `userInputModel.lua:22` | OK |
| `custom_status: CustomStatus?` | yes | `userInputModel.lua:23` | OK |
| `get_label()` | yes | `userInputModel.lua:66` | OK |
| `add_text()` | yes | `userInputModel.lua:100` | OK |
| `set_text()` | yes | `userInputModel.lua:162` | OK |
| `line_feed()` | yes | `userInputModel.lua:255` | OK |
| `get_text()` | yes | `userInputModel.lua:266` | OK |
| `get_text_line()` | yes | `userInputModel.lua:272` | OK |
| `get_n_text_lines()` | yes | `userInputModel.lua:278` | OK |
| `get_wrapped_text() VisibleContent` | yes | `userInputModel.lua:284` | OK |
| `get_wrapped_error()` | yes | `userInputModel.lua:942` | OK |
| `swap_lines()` | yes | `userInputModel.lua:230` | OK |
| *(not drawn)* `custom_label: string?` | yes | `userInputModel.lua:24,53` | **MISSING** — matches the debt entry exactly |
| *(not drawn)* `_memo: table` | yes (private) | `userInputModel.lua:25` | MISSING (private, low-value to draw) |

Plus ~50 more real methods (`delete_line`, `insert_text_line`, `backspace`, `delete`,
`clear_input`, `reset`, `text_change`, `highlight`, `keep_history`, `history_back`,
`history_fwd`, the whole cursor/selection/mouse family) not drawn — noted collectively, not
row-by-row; the annotated `@field` list above is the documented public surface and it's the one
the diagram tracks reasonably closely modulo the four findings above.

### Block 4 — `BufferModel`, `BufferView`, `EditorController`

#### `class BufferModel`
Ground truth: `src/model/editor/bufferModel.lua:106-127` (`@class BufferModel`).

| member | exists? | where | verdict |
|---|---|---|---|
| `name: string` | yes | `bufferModel.lua:107` | OK |
| `content: Content` | yes, type differs | `bufferModel.lua:108` `@field content Dequeue -- Content` | OK-ish (annotation itself hedges with the `-- Content` comment; real runtime type is `Dequeue`) |
| `content_type: ContentType` | yes | `bufferModel.lua:109` | OK |
| `selection: Selected` | type does not exist | `bufferModel.lua:111` `@field selection integer` | **STALE-type** — there is no `Selected` type anywhere in `/repo/src` (grep zero hits); real type is plain `integer` |
| `readonly: bool` | yes | `bufferModel.lua:113` | OK |
| `revmap: table` | yes | `bufferModel.lua:115` | OK |
| `chunker(string[], boolean?): Block[]` | yes, signature simplified | `bufferModel.lua:117`, `Chunker` alias `types.lua:166` (`fun(s: string[], integer, boolean?): boolean, Block[], ParseResult`) | OK (drawing drops the middle `integer` param and two of three returns, but the shape is recognisably the same function) |
| `highlighter(string[]): SyntaxColoring` | yes | `bufferModel.lua:118`, `Highlighter` alias `types.lua:167` | OK |
| `printer(string[]): string[]` | yes | `bufferModel.lua:119`, `Printer` alias `types.lua:168` | OK |
| `move_selection()` | yes | `bufferModel.lua:208` | OK |
| `get_selection()` | yes | `bufferModel.lua:253` | OK |
| `get_selected_text()` | yes | `bufferModel.lua:286` | OK |
| `delete_selected_text()` | yes | `bufferModel.lua:322` | OK |
| `replace_selected_text()` | **method not implemented anywhere** | `bufferModel.lua:125` `@field replace_selected_text function` | **STALE, but with a twist** — the `@field` annotation itself claims this member, but no function named `replace_selected_text` is defined anywhere in `/repo/src` (grep zero hits for `function.*replace_selected_text` and zero for bare `replace_selected_text` outside the annotation line). The real, called method is `replace_content` (`bufferModel.lua:340`, called from `editorController.lua:665`). **The disagreement is in the source annotation, not introduced by the diagram** — the diagram faithfully drew a field that the code's own doc-comment promises but never delivers. |

#### `class BufferView`
Ground truth: `src/view/editor/bufferView.lua:11-26` (constructor) and `:28-41` (`@class BufferView`).

| member | exists? | where | verdict |
|---|---|---|---|
| `cfg: ViewConfig` | yes | `bufferView.lua:33` | OK |
| `content: VisibleContent\|VisibleStructuredContent` | yes | `bufferView.lua:29` | OK |
| `content_type: ContentType` | yes | `bufferView.lua:30` | OK |
| `buffer: BufferModel` | field exists at runtime, annotation disagrees | constructor `bufferView.lua:24` sets `buffer = nil`, used throughout (e.g. `bufferView.lua:52,93,109,133,264`) | **OK against the code, but flag the annotation**: `@class BufferView` (line 31) declares `--- @field buffers Dequeue<BufferModel>` (plural) — a field that is never assigned or read anywhere in this file. The diagram's `buffer: BufferModel` (singular) matches the *real* runtime field, not the (stale) annotation. Second instance of an annotation/code disagreement the diagram inherited correctly by accident. |
| `LINES: integer` | yes | `bufferView.lua:34` | OK |
| `SCROLL_BY: integer` | yes | `bufferView.lua:35` | OK |
| `w: integer` | **no** | `bufferView.lua:36` `@field wrap_w integer` | **STALE** — real field name is `wrap_w` (constructor line 18: `wrap_w = cfg.drawableChars`), not `w` |
| `offset: integer` | **no**, not a `BufferView` field | `BufferView:get_offset()` (line 167) returns `self.content.offset` | **STALE** — `offset` lives on the `content` object (`VisibleContent`/`VisibleStructuredContent`), not on `BufferView` itself; `BufferView` has no `self.offset` |
| `more: More` | yes | `bufferView.lua:37` | OK |
| `open(b: BufferModel)` | yes | `bufferView.lua:50` `BufferView:open(buffer)` | OK |
| `refresh()` | yes | `bufferView.lua:129` `refresh(moved)` | OK (param undrawn, fine) |
| `draw()` | yes | `bufferView.lua:276` `draw(special)` | OK (param undrawn, fine) |
| `follow_selection()` | yes | `bufferView.lua:264` | OK |
| `get_wrapped_selection()` | name mismatch | `bufferView.lua:92` `_get_wrapped_selection()` (leading underscore — private) | **RENAMED** — real name is `_get_wrapped_selection` |
| `_scroll()` | name mismatch | `bufferView.lua:181` `scroll(dir, by, warp)` (no leading underscore — public) | **RENAMED** — real name is `scroll`, and it's public, not private as drawn |
| `_calculate_end_range()` | name mismatch | `bufferView.lua:173` `_get_end_range()` | **RENAMED** — real private method is `_get_end_range`; `calculate_end_range` is a *different*, real, static method on `Scrollable` (`src/util/scrollable.lua:10`) that `_get_end_range` calls internally — the diagram appears to have conflated the two |
| `_update_visible()` | yes | `bufferView.lua:45` `_update_visible(r)` | OK |

Not drawn at all: `get_state()`, `get_max_size()`, `get_offset()`, `scroll_to()`,
`scroll_to_line()`, `is_selection_visible()` — six real public methods, **MISSING**.

#### `class EditorController`
Same class as in `classes.md`'s Controller section — see that table above (identical
`interpreter: InterpreterController` staleness; this block additionally draws `open(name: string,
content: string[])` with an explicit signature, which drops the real third parameter `save`
(`editorController.lua:48`, `open(name, content, save)`) and states `content: string[]` where the
real parameter is `@param content str?` (a single string, not an array) — **STALE-type** on top
of the field-level finding already logged.

---

## `doc/mermaid/eval.md`

Two headed sections, five class blocks total. **Read the heading claims literally before grading
against them** — see the finding below.

### "### Planned refactor" section

```mermaid
class Parser { parse() get_error() chunker() highlighter?: fun(string) SyntaxColoring pprint() ast_to_src() }
class Filters { validators: ValidatorFilter[] astValidators: AstValidatorFilter[] transformers: TransformerFilter[] }
class Evaluator { label: string parser?: Parser filters?: Filters apply: function }
```
plus a `hl`/`apply` table for `LuaEval`/`TextEval`/`InputEval lua`/`InputEval` (not a class
block, not graded here).

#### `class Parser`
Ground truth: `src/types.lua:170-176` (`@class Parser`), plus the actual `luaParser` instance
wired at `src/model/interpreter/eval/evaluator.lua:132-136`.

| member | exists? | where | verdict |
|---|---|---|---|
| `parse()` | yes | `types.lua:171` | OK |
| `get_error()` | no | — | STALE — no `get_error` on the `Parser` annotation or on `luaParser`'s usage sites |
| `chunker()` | yes | `types.lua:172` | OK |
| `highlighter?: fun(string) SyntaxColoring` | yes, at the instance level, not the annotation | `evaluator.lua:135` `luaTools = { parser = luaParser, highlighter = luaParser.highlighter }` | OK against real usage, but note: the `@class Parser` annotation (`types.lua:170-176`) does **not** declare a `highlighter` field — this is an annotation/actual-usage gap in the source, independent of the diagram |
| `pprint()` | yes | `types.lua:173` `@field pprint Printer?` | OK |
| `ast_to_src()` | no | — | STALE — no such member anywhere |
| *(not drawn)* `tokenize`, `syntax_hl` | yes | `types.lua:175-176` | MISSING (2) |

#### `class Filters`
Ground truth: `src/model/interpreter/eval/filter.lua:10-14` (`@class Filters`).

| member | exists? | where | verdict |
|---|---|---|---|
| `validators: ValidatorFilter[]` | name mismatch | `filter.lua:11` `@field line_validators ValidatorFilter[]` | RENAMED — real field is `line_validators` |
| `astValidators: AstValidatorFilter[]` | yes | `filter.lua:12` | OK |
| `transformers: TransformerFilter[]` | yes | `filter.lua:13` | OK |
| *(not drawn)* `validators_only` (static ctor) | yes | `filter.lua:14,26` | MISSING (minor — a static factory, not really an instance field) |

#### `class Evaluator`
Ground truth: `src/model/interpreter/eval/evaluator.lua:6-15` (`@class Evaluator`).

| member | exists? | where | verdict |
|---|---|---|---|
| `label: string` | yes | `evaluator.lua:7` | OK |
| `parser?: Parser` | yes | `evaluator.lua:8` | OK |
| `filters?: Filters` | restructured | — | STALE — `Evaluator` has no single `filters: Filters` field; the `Filters` shape is flattened directly onto it as three separate fields (`line_validators`, `astValidators`, `transformers` — `evaluator.lua:12-14`), not nested |
| `apply: function` | yes | `evaluator.lua:10` | OK |
| *(not drawn)* `highlighter: Highlighter?` | yes | `evaluator.lua:9` | MISSING |
| *(not drawn)* `custom_apply: function?` | yes | `evaluator.lua:11` | MISSING |

**This whole section is real Evaluator's shape, closely** — despite being headed "Planned
refactor." Flagging per the commission's instruction to report rather than decide: this may mean
the refactor described here already landed (it reads far closer to today's `Evaluator` than the
"Current" section below does), or the heading is simply stale. Not deciding which.

### "### Current" section — two class blocks, both named `EvalBase`

```mermaid
class EvalBase { kind: string apply: function is_lua: boolean highlight: boolean inherit: fun(...) EvalBase }
TextEval --|> EvalBase
LuaEval --|> EvalBase
InputEval --|> EvalBase
```
and, further down, a second, smaller `EvalBase` block with just `kind`, `is_lua`, `highlight`,
`apply()`.

**The class `EvalBase` does not exist anywhere in `/repo/src`** — confirmed by `grep -rn
'EvalBase' src --include=*.lua` (zero hits outside this doc) and by LSP `definition`
(`"EvalBase not found"`). Every member of both `EvalBase` blocks is **UNVERIFIABLE-as-drawn**
for the class itself; there is no class to check `kind`, `apply`, `is_lua`, `highlight`, or
`inherit` against.

The three `--|>` inheritance arrows are also not what the code does:
- `TextEval` is not a class or subclass — it's an **instance**: `TextEval = Evaluator.plain('text')`
  (`evaluator.lua:130`).
- `LuaEval` is not a class or subclass — it's a **factory function**:
  `LuaEval = function(label, filters, custom_apply) ... return Evaluator(l, luaTools, filters,
  custom_apply) end` (`evaluator.lua:164-167`), returning `Evaluator` instances.
- `InputEval` (bare) **does not exist at all**. Grep for `\bInputEval\b` returns zero hits; what
  exists is `InputEvalText` and `InputEvalLua` (`evaluator.lua:180,184`), both `Evaluator`
  instances (one plain, one with a custom `apply` that's an identity function).

So none of `TextEval --|> EvalBase`, `LuaEval --|> EvalBase`, `InputEval --|> EvalBase` hold:
there is no base class to inherit from, and two of the three named subtypes aren't classes
either. **Net finding for this section, stated plainly: the section titled "Current" describes an
`EvalBase` inheritance hierarchy that was never built.** All current specialisation (`TextEval`,
`LuaEval`, `MdEval`, `InputEvalText`, `InputEvalLua`, `LuaEditorEval` — `evaluator.lua:130-215`)
goes through composition — constructing an `Evaluator` with different `tools`/`filters` — not
subclassing. Given the "Planned refactor" section directly above it is the one that actually
resembles today's `Evaluator` class, the two headings in this file look swapped relative to
what shipped. Flagging, not deciding — this is exactly the kind of call the commission reserves
for the parent session.

---

## `doc/mermaid/fsm.md`

No class blocks — one `stateDiagram-v2`. Out of the commission's core scope (class-diagram
member audit), but a quick sanity check against `/repo/src/types.lua:121-129`
(`@alias AppState`: `'starting' | 'title' | 'ready' | 'project_open' | 'editor' | 'running' |
'inspect' | 'shutdown'`) and the real `love.state.app_state` assignment sites
(`src/main.lua:286,319`, `src/controller/consoleController.lua:326,354,368,1232,1399,1417,1448,
1490,1532,1565`, `src/controller/controller.lua:669`) turned up a state-name mismatch: the
diagram's `init` composite state names its first sub-state `booting`; the real `AppState` alias
and every assignment site use `starting`, never `booting` — grep for `'booting'` across
`/repo/src` (excluding examples/lib) returns zero hits. Also present in code but absent from the
diagram: `'snapshot'` (`consoleController.lua:1417`) and `'shutdown'` (`controller.lua:669`,
also in the `AppState` alias). Not turned into a formal member table since this file has no class
blocks and state-transition semantics are a different kind of check than the one commissioned;
noted here and also below under "Out of scope."

## `doc/mermaid/fsm_f.md`

No class blocks — one `flowchart TD`, a alternate rendering of the same state machine as
`fsm.md` (same node set: `booting`, `title`, `ready`, `project_open`(`O`), `running`(`R`),
`inspect`(`I`), `editor`(`E`)). Same `booting`/`starting` naming note applies. Not separately
re-derived; see `fsm.md` above.

---

## `doc/mermaid/input.md`

Headed **"### Planned refactor"**, one class block, plus prose: "Interpreter is out, instead
create a History triplet and have one optionally in the input. If present, invoke. Evaluation is
tightly coupled with the input, no sense having it separately. Non-validated inputs still can be
made with an 'all goes' eval." **Per the commission, this is flagged, not graded as a live
reference.** Facts only:

```mermaid
class InputModel {
  oneshot: boolean
  entered: InputText
  evaluator: EvalBase
  type: InputType
  cursor: Cursor
  wrapped_text: WrappedText
  wrapped_error: string[]
  selection: InputSelection
  cfg: Config
  custom_status: CustomStatus?
  history?: HistoryModel
}
```

**What the prose claims, checked against current code:**
- *"Interpreter is out"* — **true today**. `InterpreterModel`, `InterpreterController`,
  `InterpreterView`, `InterpreterBase` all return zero grep hits under `/repo/src` (excluding
  examples/lib), and LSP `definition` confirms `InterpreterModel`/`InterpreterController` "not
  found." There is no interpreter layer anywhere in the current model/controller/view stack.
- *"Evaluation is tightly coupled with the input"* — **true today**. `UserInputModel` holds
  `evaluator: Evaluator` directly (`userInputModel.lua:17,49`), no intermediary.
- *"create a History triplet and have one optionally in the input"* — **partially true, but not
  as drawn**. `UserInputModel` does hold a `history` field (`userInputModel.lua:16,48`), but it
  is a single `History` instance (`src/model/input/history.lua:8`, `@class History:
  Dequeue<string[]>`), constructed unconditionally in `UserInputModel.new` — not optional, and
  not a "triplet" of anything. There is no type named `HistoryModel` anywhere (grep zero hits);
  the diagram's `history?: HistoryModel` field names a class that never existed under that name
  either before or after this refactor.
- `oneshot: boolean` is drawn here too, and per the debt entry this is **also gone** in the
  actual code that shipped (`UserInputModel.new(cfg, eval, custom_label)`, no `oneshot` param) —
  worth noting because it means this "planned" sketch and the "current" diagrams
  (`classes.md`, `editor.md`) share the same stale field, which weakly suggests `input.md`
  predates the removal rather than describes a future state that still has it.
- `evaluator: EvalBase` — same `EvalBase`-doesn't-exist finding as everywhere else; live type is
  `Evaluator`.
- `wrapped_text: WrappedText` — `UserInputModel` has no field by this name; its wrapped-text
  handle is `visible: VisibleContent` (`userInputModel.lua:20`), which *is-a* `WrappedText` via
  inheritance (`visibleContent.lua:27-32`), not stored under a field called `wrapped_text`.
- `custom_label` is **absent** from this block too (same gap as `editor.md`'s `UserInputModel`
  block), despite the block otherwise being fairly detailed.

Disposition (is this a design sketch or a stale class reference) is explicitly the parent
session's call per the commission; the facts above are offered to support that call, not to make
it.

---

## `doc/mermaid/scratch.md`

Mixed content: a Scala pseudocode fence (not mermaid, not graded), a mermaid `sequenceDiagram`
(no class block), one mermaid `classDiagram` under a **"### Scrolling"** heading (4 class blocks),
a `lua` code fence, and two more diagrams under headings **"### Input scrolling"** and **"##### ex"**
— the second of which is a generic `graph TD; A[Start] --> B[Step 1]; ...` with no project-specific
content at all (a textbook mermaid syntax example, not a diagram of anything in this codebase).
**This file reads as scratch/exploratory notes, not a live reference** — the mix of a
non-mermaid Scala sketch, a throwaway "ex" flowchart, and a classDiagram whose relationships
don't match any other diagram in this repo (see below) all point the same way. Flagging per the
commission's second "flag rather than resolve" instruction; not applying a live-reference grading
standard to the file as a whole, but the one classDiagram is checked for the record:

### `class Scrollable` / `WrappedText` / `VisibleContent` / `VisibleStructuredContent` (under "Scrolling")

```mermaid
class Scrollable { range overscroll overscroll_max size size_max content_length
  full_range() follow_focus() calculate_end_range() get_more() }
class VisibleContent { scroll: Scrollable move_range() get_visible() get_content_length() }
class VisibleStructuredContent { scroll: Scrollable blocks: Block[] visible_blocks: Block[] reverse_map: ReverseMap
  get_visible() get_content_length() }
Scrollable *-- VisibleContent
Scrollable *-- VisibleStructuredContent
```

Ground truth: `src/util/scrollable.lua` (whole file, 22 lines). The real `Scrollable`
(`@class Scrollable`, line 4-5) is a **stateless utility** with exactly two static functions,
`calculate_end_range` and `to_end` — **no instance fields at all** (`range`, `overscroll`,
`overscroll_max`, `size`, `size_max`, `content_length` are all absent), and no
`full_range()`/`follow_focus()`/`get_more()` methods (grep for `full_range` and `follow_focus`
across `/repo/src`, excluding examples/lib, returns zero hits). Both `VisibleContent` and
`VisibleStructuredContent` today hold their own scroll-adjacent fields directly (`range`,
`overscroll`, `overscroll_max`/`opts.overscroll_max` — see `editor.md`'s tables above) and call
`Scrollable.to_end(...)`/`Scrollable.calculate_end_range(...)` as **static utility calls**
(`visibleContent.lua:63-64`, `visibleStructuredContent.lua:69-70`), never storing a `Scrollable`
instance on `self`. So `Scrollable *-- VisibleContent` and `Scrollable *-- VisibleStructuredContent`
are both **STALE as composition relationships** — nothing is composed; `Scrollable` is called,
not held. This whole block reads as an aspirational refactor sketch (extract a `Scrollable`
value object that the two content classes hold and delegate to) that was **not** implemented —
consistent with the file being scratch, not a description of current or even fully-planned state
(contrast with `input.md`, which at least carries an explicit "Planned refactor" heading; this
block carries no such heading, it just doesn't match reality).

`blocks: Block[]` / `visible_blocks: Block[]` on `VisibleStructuredContent` also don't match
current field names — the real class has `v_blocks: Dequeue<VisibleBlock>` (one field, not two;
see `editor.md`'s `VisibleStructuredContent` table above for the live shape).

---

## Recommendations (parent applies; not applied here)

Ordered by the ground each edit covers, evidence line included with each.

1. **`doc/mermaid/classes.md`, Model section** — drop the `InputModel` and `InterpreterModel`
   class blocks and their relationship arrows entirely (`EditorInterpreter --* EditorModel`,
   `InputModel --* InterpreterModel`, `InterpreterModel --* ConsoleModel`); redraw `ConsoleModel`
   with all five real fields. Evidence: `src/model/consoleModel.lua:7-21`, zero grep hits for
   `InputModel`/`InterpreterModel`/`EditorInterpreter` under `/repo/src`.
2. **`doc/mermaid/classes.md`, View section** — rename `InputView` → `UserInputView` throughout;
   drop `InterpreterView` and its two arrows, replacing with `UserInputView --* ConsoleView`
   directly; add `SearchView --* EditorView` and `SearchView --* ConsoleView`. Evidence:
   `src/view/consoleView.lua:14-26`, `src/view/editor/editorView.lua:9-20`.
3. **`doc/mermaid/classes.md`, Controller section** — drop `InterpreterController` and
   `InputController` and their four relationship arrows; redraw with `UserInputController`,
   adding `search: SearchController`/`console: ConsoleController`/`state`/`mode` to
   `EditorController`. Evidence: `src/controller/editorController.lua:29-37`,
   `src/controller/consoleController.lua:20-36`.
4. **`doc/mermaid/editor.md` and `classes.md`, both `EditorController` blocks** — rename
   `interpreter: InterpreterController` → `input: UserInputController`. Evidence:
   `editorController.lua:31`.
5. **`doc/mermaid/editor.md`, `UserInputModel` block** — drop `oneshot: boolean`; add
   `custom_label: string?`; rename `evaluator: EvalBase` → `evaluator: Evaluator`; rename
   `wrapped_error: string[]` → `error: string[]?` (and keep `get_wrapped_error()` as the derived
   accessor, already correctly drawn). Evidence: `src/model/input/userInputModel.lua:14-53`
   (matches the technical-debt entry `T-MERMAID-MODEL` for two of the four edits).
6. **`doc/mermaid/input.md`** — same `oneshot`/`EvalBase`/`custom_label` edits as (5) apply *if*
   the parent decides this file should be graded as a live reference; if it's kept as a design
   sketch, consider adding an explicit "not current" caveat instead, since `oneshot` being drawn
   here already suggests it predates the removal rather than anticipates a future state.
   Evidence: prose vs. code comparison in the `input.md` section above.
7. **`doc/mermaid/classes.md`, `ConsoleModel` block** — add the four missing fields (`input`,
   `editor`, `output`, `cfg`). Evidence: `src/model/consoleModel.lua:7-21`.
8. **`doc/mermaid/editor.md`, `WrappedText`/`VisibleContent`/`VisibleStructuredContent` blocks** —
   fix the `WrappedText <|-- ...` / `*-- ...` relationship inconsistency (both should be `<|--`);
   add missing fields (`orig`, `wrap_rank` on `WrappedText`; `offset`, `size_max` on
   `VisibleContent`; replace `overscroll_max` with `opts: VSCOpts` and add `highlighter` on
   `VisibleStructuredContent`). Evidence: the three source files under "Block 2" above.
9. **`doc/mermaid/editor.md`, `BufferModel` block** — rename `selection: Selected` → `selection:
   integer` (`Selected` doesn't exist); note but don't silently "fix" `replace_selected_text` —
   the *source* annotation (`bufferModel.lua:125`) is itself stale against `replace_content`
   (line 340); that's a code-comment fix, not a diagram fix, and worth a debt-ledger entry of its
   own if not already tracked.
10. **`doc/mermaid/editor.md`, `BufferView` block** — rename `w` → `wrap_w`; drop `offset` (it's
    on `content`, not `BufferView`); rename `get_wrapped_selection()` →
    `_get_wrapped_selection()`, `_scroll()` → `scroll()`, `_calculate_end_range()` →
    `_get_end_range()`. Evidence: `src/view/editor/bufferView.lua` line numbers in the table above.
11. **`doc/mermaid/classes.md`, `class InputModel` block** — fix the malformed
    `wrapped:_text WrappedText` line regardless of any other disposition; it's a syntax defect
    independent of staleness.
12. **`doc/mermaid/eval.md`** — the two section headings ("Planned refactor" vs "Current") look
    swapped relative to what shipped; recommend the parent re-examine and either relabel or
    rewrite the "Current" `EvalBase` hierarchy to describe the real composition-based
    `Evaluator`/`TextEval`/`LuaEval`/`InputEvalText`/`InputEvalLua` shape. Evidence: `eval.md`
    section above, cross-referenced against `src/model/interpreter/eval/evaluator.lua`.
13. **`doc/mermaid/eval.md`, `Filters` block** — rename `validators` → `line_validators`.
    Evidence: `src/model/interpreter/eval/filter.lua:11`.
14. **`doc/mermaid/scratch.md`** — recommend the parent decide whether this file should be kept
    at all; the `Scrollable`/`VisibleContent`/`VisibleStructuredContent` composition it draws was
    never built (`Scrollable` is a stateless static-function utility, not a composed value
    object), and the file mixes a non-mermaid Scala sketch and a generic mermaid syntax example
    with project diagrams.
15. **`doc/mermaid/fsm.md` / `fsm_f.md`** — minor: `booting` → `starting` to match the real
    `AppState` alias; consider adding `snapshot` and `shutdown` states, both real and currently
    undrawn. Evidence: `src/types.lua:121-129`.

---

## Out of scope, seen in passing

- `src/model/editor/bufferModel.lua:125` — the `@field replace_selected_text function`
  annotation on `BufferModel` names a method that was never implemented; the real, called method
  is `replace_content` (line 340, called from `editorController.lua:665`). This is a source-code
  documentation defect, not a mermaid-diagram defect — worth a technical-debt entry of its own if
  one doesn't already exist, since a doc-comment claiming a nonexistent method could mislead a
  future reader (or an LLM agent) faster than a stale diagram would.
- `src/view/editor/bufferView.lua:31` — `@class BufferView`'s `@field buffers Dequeue<BufferModel>`
  (plural) is never assigned or read; the real runtime field is `self.buffer` (singular,
  `BufferModel`). Same category of finding as above — an annotation that disagrees with its own
  file's constructor.
- `src/view/editor/visibleStructuredContent.lua:19` — `@field size_max integer` is declared on
  `VisibleStructuredContent` but never assigned as `self.size_max`; it only exists nested at
  `self.opts.size_max`. Third instance of the same annotation-vs-constructor pattern in this
  audit — three independent files, same defect shape, which might indicate a systemic gap in how
  `@field` annotations get updated when a constructor is refactored to take an options table.
- `doc/mermaid/scratch.md`'s Scala fence (not evaluated as mermaid) has its own typo,
  `qoverscroll: Int` in `VisibleStructuredContent`'s constructor params — clearly a typo for
  `overscroll`, irrelevant to the mermaid audit but noted since it sits in the same file.
- `love.state.app_state` also takes the value `'snapshot'` (`consoleController.lua:1417`), which
  is real and current but appears in neither `fsm.md` nor `fsm_f.md` nor the `AppState` alias's
  informal "what the FSM diagrams should show" framing — it *is* in the formal `@alias AppState`
  list though (`types.lua` — actually checked: `'snapshot'` is **not** in the `AppState` alias
  either, `types.lua:121-129` lists `starting/title/ready/project_open/editor/running/inspect/
  shutdown`, no `snapshot`). So `'snapshot'` is a real runtime state absent from both the FSM
  diagrams *and* the type alias — a third, independent place this could be tracked and isn't.
