# DI3 — mechanical execution report (Sonnet worker)

Executed per `validation/prompts/DI3-prompt.md` against the map in
`validation/notes/DI2-ruling-and-resolution-index.md`. Doc A
(`notes/input-contracts.md`) was not touched; `design/` was not touched.
Not committed — left for the orchestrator to review and commit.

## Unit 1 — merge the two survivor facts

### 1a. `doc/development/technical_debt/input.md`

Added a new item under `## Standing` (settled fact, not an open decision),
matching the file's existing `### heading` / `- **Where:**` / `- **State:**`
/ `- **Why it stands:**` / `- **Revisit:**` bullet shape. Inserted before
the "Input-only / pointer-only projects..." entry.

New heading: `### A truthy tier-3 return silently disables
'on_limit_reached'`.

Coupling verified in code before writing:
- `src/controller/projectInputController.lua:198-207` (`_dispatch`): tier 3
  (`_generic_callback`, line 205) returns/short-circuits with `return true`
  before the tier-4 sink call at line 206.
- `src/controller/userInputController.lua:495`: `self.on_limit_reached(dir,
  scope)` fires only inside that sink (`deliver`-adjacent code path), so a
  truthy tier-3 return means it never runs for that keystroke.

### 1b. `doc/development/internals/user_input.md`

Added one clarifying line immediately after the "Dispatch chain" fenced
code block (after line 160, before the "Global shortcuts intercepted..."
paragraph at what was line 162):

> `` `app_state == 'starting'` is never observed by any input path:
> `main.lua`'s `love.load()` sets it, then flips it to `'ready'` a few
> lines later — both synchronously, before LÖVE's event pump runs, so no
> `love.handlers.*` entry point can ever see the `'starting'` value. ``

Verified in `src/main.lua`: `love.state.app_state = 'starting'` at line
286, `love.state.app_state = 'ready'` at line 319, both inside the single
synchronous `love.load()` call, before LÖVE begins the event pump.

`busted tests` after Unit 1: **815 successes / 0 failures / 0 errors / 4
pending** (docs-only edits; this run also served as the pre-Unit-2
baseline, confirming the suite was 815/0/0/4 going in).

## Unit 2 — retarget the ~30 doc-A citations

### `tests/helpers/input_fixture.lua` (4 edits)

| file:line (pre-edit) | old text | new text |
|---|---|---|
| `:9-11` | `"doc A" = the contract record: {badspecref: doc/development/wip/77-new-input-api/notes/input-contracts.md}` | dropped entirely (per prompt's "retarget... or drop"; no live citation names "doc A" anywhere else in the file after the sibling retargets below, so the definition became dead weight) |
| `:137` | `({badspecref: doc A §5.5}).` | `(internals/user_input.md, "Direct mouse events").` |
| `:168` | `({badspecref: doc A §6.7}).` | `(internals/user_input.md, "Framework-level click handling").` |
| `:221` | `doc A §5.5). Witnesses pointer delivery to the widget half.` | `internals/user_input.md, "Input widget mouse"). Witnesses pointer delivery to the widget half.` |

### `tests/input/input_contracts_spec.lua` (24 edits, all comment-only)

Header block (`:6-33`, pre-edit numbering):
- Dropped the "Doc A (the contract record...)" definition paragraph
  (`:6-11`), replacing the lead sentence with "Every test below traces to
  a named section of the input corpus (decisions/input.md,
  internals/user_input.md)..." — same methodology statement, no wip-file
  pointer.
- `doc A §5.9` (routing invariant) → `decisions/input.md, Decision 1`.
- `doc A §3` (vocabulary) → `decisions/input.md, Decision 1;
  internals/user_input.md, "Dispatch chain"`.
- `doc A §2` (key vs text events) → `internals/user_input.md, "Data
  flow"`.

Per-test citations, in file order (old ref → new ref; behaviour context
in the "why" column matches A1's style — cite behaviour + named section,
never invent corpus clause numbers):

| old ref | new ref |
|---|---|
| `doc A §5.1-5.5` (bucket-A intro) | `decisions/input.md, Decision 1 and Decision 2; internals/user_input.md, "Dispatch chain"` |
| `doc A §4` (completeness table) | reworded to cite the routing invariant itself, `decisions/input.md Decision 1`, applied per mode × channel (no single corpus home for the table device, per the map) |
| `doc A §5.1` (console keys) | `decisions/input.md, Decision 1 and Decision 2; internals/user_input.md, "Dispatch chain"` |
| `doc A §5.2` (console text) | `decisions/input.md, Decision 1 and Decision 2; internals/user_input.md, "Data flow"` |
| `doc A §5.3` (console release, SURFACED GAP) | `internals/user_input.md, "Key release"` |
| `doc A §5.5` (console pointer) | `internals/user_input.md, "Input widget mouse"` |
| `doc A §5.1; reviews/M4-0-04.md finding 1` (editor keys) | `decisions/input.md, Decision 1 and Decision 2; internals/user_input.md, "Dispatch chain"` — the `reviews/M4-0-04.md` review-doc citation left untouched (Phase-C evidence, out of scope), re-wrapped in its own `{badspecref:}` tag since it's no longer sharing a tag with a doc-A clause |
| `doc A §5.2` (editor text) | `decisions/input.md, Decision 1 and Decision 2; internals/user_input.md, "Data flow"` |
| `doc A §5.3, §8` (editor keyreleased comment) | `internals/user_input.md, "Key release"` for the release-channel gap; `"Dispatch chain"` for the future console/editor migration note (that section's `inspect`-mode paragraph explicitly discusses "a future console/editor migration") — `{badspecref: #77's blast radius}` and `{badspecref: this feature}` on the same lines left untouched (non-doc-A) |
| `doc A §5.5` (editor pointer, SURFACED GAP) | `internals/user_input.md, "Input widget mouse"` |
| `doc A §5.1` (project keys) | `decisions/input.md, Decision 1 and Decision 2; internals/user_input.md, "Dispatch chain"` |
| `doc A §5.2` (project text) | `decisions/input.md, Decision 1 and Decision 2; internals/user_input.md, "Data flow"` |
| `doc A §5.3` (project release) | `internals/user_input.md, "Key release"` |
| `doc A §5.5` (project pointer, via `love.mousepressed` direct forward) | `internals/user_input.md, "Direct mouse events"` |
| `doc A §5.6` (touch, SURFACED GAP) | `internals/user_input.md, "Touch"` |
| `doc A §6.3` (play-mode shortcut narrowing) | `decisions/input.md, Decision 1; internals/user_input.md, "Dispatch chain"` |
| "not a doc A routing contract" (editor block-nav note, no `{badspecref:}` wrapper) | "not a routing contract of the kind decisions/input.md, Decision 1, asserts" |
| `doc A §5.7` (wheel) | `internals/user_input.md, "Direct mouse events"` |
| `doc A §8` (singleton identity, future consideration) | reworded to "a future consideration, out of #77 blast radius" citing `internals/user_input.md`: "Key release", "Dispatch chain", "Search — a third widget instance, live only in editor/search mode", "Cursor manipulation and 'reset'" (the four sections DI1 names as §8's home) — behaviour note, not an assertion, per the map |
| `design.md §4` sibling (`:1657-1658`, pointer-excluded-from-disconnect) | dropped — read the line in context: `decisions/input.md, Decision 11` (already cited on the same comment) states the pointer-exclusion scope explicitly ("pointer natives stay hooked until the project actually stops"), making the `design.md §4` parenthetical fully redundant; removed rather than retargeted to avoid a duplicate citation |

`{badspecref: M4}` (`:313`, click-detection section) and all milestone
marks / `M6-02*`/`M7-01`/`M8-01`/`ratified-model` / `Scope item` /
`E30` / `0.1.0-m*` citations were left untouched — none of them are
doc-A family.

`busted tests` after Unit 2: **815 successes / 0 failures / 0 errors / 4
pending**. Pending rows shifted (comment lines got longer in several
spots): `:118→124`, `:172→186`, `:185→199`, `:246→265` (content
unchanged — same four rows, confirmed by test description in the run
output).

## Unit 3 — refresh `tests.md` facts

`doc/development/tests.md:69` (pre-edit): `808 successes` → `815
successes`.

Pending-row line numbers, derived from the **final** `busted tests` run
(after Units 1-2 landed), not copied blindly:

| row | old line | new line |
|---|---|---|
| routes the key release to the console | `:101` | `:124` |
| routes the pointer to the editor | `:153` | `:186` |
| routes keys and text to the search widget | `:161` | `:199` |
| touch reaches the active route | `:222` | `:265` |

Final confirmation run: **815 successes / 0 failures / 0 errors / 4
pending**, with `Pending -> tests/input/input_contracts_spec.lua @ 124 /
186 / 199 / 265` matching the four rows above by content.

## Anomalies / judgment calls

- The prompt's own §4 section quotes "pending row line numbers
  101/153/161/222 → 118/172/185/246" as an example; those numbers were
  from a stale pre-Unit-2 measurement (or a different edit shape) and did
  **not** match this session's actual post-Unit-2 run (124/186/199/265).
  Per the prompt's explicit instruction ("do not copy 118/172/185/246
  blindly, read them from the run"), the live run's numbers were used.
- `input_fixture.lua:9-11`'s "doc A" definition was **dropped** rather
  than retargeted to a corpus name, since after retargeting its three
  sibling citations no comment in the file names "doc A" anymore — a
  retarget would have left a dangling definition for a term never used
  again.
- The `design.md §4` citation at `input_contracts_spec.lua:1657-1658` was
  **dropped**, not retargeted, because the sibling `decisions/input.md,
  Decision 11` citation on the same comment already states the exact
  behaviour (pointer excluded from the keyboard/text disconnect) —
  retargeting it to a section would have produced a redundant double
  citation for one fact.
- No suite-count anomaly at any checkpoint; count stayed 815/0/0/4
  throughout all three units.
- `mcp__lua-lsp__diagnostics` was run on both edited `.lua` files after a
  `sleep 1`; all reported diagnostics (missing-parameter, duplicate-set-
  field, need-check-nil, trailing-space, etc.) are pre-existing and
  unrelated to the comment-only edits — none anchor to a line this task
  touched in a way that changed code semantics.
