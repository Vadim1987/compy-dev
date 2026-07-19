# Sonnet worker — nest split input specs into readability sub-describes (TF1 amendment)

## Environment & tools
Working dir `/repo`. LÖVE2D/Lua; tests run with `busted` (uses mock_love, no display).
The `lua-lsp` MCP server (defs/refs/diagnostics over a real AST of `/repo`) is available;
after any `.lua` edit `sleep 1` before calling LSP diagnostics (it re-indexes).

## Context — what and why
In TF1 a 2.3K-LoC spec was split into 9 `tests/input/input_*_spec.lua` files. The owner
then hand-nested ONE of them, `input_cursor_text_spec.lua`, wrapping its flat `it` list in
concept-named `describe` blocks **purely for readability** (no logic change). Your job:
mirror that transform over **4 more files**, following the exact group map below.

**Read `tests/input/input_cursor_text_spec.lua` first** — it is the reference idiom
(method-named nested `describe`s; a further nested `describe("with keep_cursor", …)`
inside `set_text`; child `it` labels shortened where the group name already carries the
prefix).

## HARD CONTRACT — verify at the end (this is the whole safety net)
- Full suite `busted tests` stays **815 successes / 0 failures / 0 errors / 4 pending**.
- **Per file**: `it` count and `pending` count unchanged vs git HEAD (`git show
  HEAD:tests/input/<f>` then `grep -cE '^\s*(it|pending)\('`). Each file stays
  standalone-green (`busted tests/input/<f>`).
- **No `it`/`pending` BODY changes** — assertions, setup lines, everything inside the
  callbacks is byte-identical. Only three things change: (a) new nested `describe(...)`
  wrappers inserted, (b) the enclosed its re-indented under them, (c) child `it` LABEL
  strings optionally shortened per the idiom below.

## The idiom (match cursor_text exactly)
1. Wrap **contiguous** runs of `it`s — **in existing file order, NEVER reorder** — in a
   nested `describe('<group name>', function() … end)`.
2. **Do NOT add any hook** (`setup`/`teardown`/`before_each`) to a nested describe. They
   already live on the outer describe and inherit downward. Nested describe body = just its.
3. **Label shortening**: when the group name lifts a redundant leading prefix off a child
   `it` label AND the shortened label still reads as a sentence, strip that prefix
   (e.g. group `configure on an active session` + `it('configure updates the prompt on an
   active session')` → `it('updates the prompt on an active session')`). When there is no
   clean shared prefix, **leave the label verbatim**. Never change label meaning.
4. **Preserve every comment verbatim** — especially owner `REVIEW`/`REVIEW/…` lines,
   `{jargon:…}`/`{badspecref:…}`/`{clarity:…}` markers, and doc-ref lines. The existing
   `-- ----` section-marker comments become the seams: keep each marker's text (as a
   comment immediately above or inside the new `describe`) so nothing is lost — do not
   silently delete a marker just because it is now also a describe name.
5. Re-indent the moved its by one level (2 spaces), like the owner did for `keep_cursor`.
   Do not re-flow or re-wrap existing multi-line labels/bodies beyond that added indent.

## The group map (per file — locate its by the quoted label text; ranges are first→last)

### 1. tests/input/input_events_spec.lua
Inner describe `#input events dispatch chain`. 7 nested groups on the existing `-- ----`
seams (each seam comment already marks the group start):
- `order, consume, fall-through` : `a framework handler consumes before lower tiers` → `assigning a callback replaces only it; sink still runs`
- `combo tables and normalisation` : `a keypressed combo fires on the normalised combo` → `the combo tables are per-event, not one flat table`
- `signatures and the read-only proxy` : `keypressed carries (k, keys_pressed, isrepeat)` → `a keyreleased participant sees the key already gone`
- `defaults and the hidden sink` : `the default callback neither edits nor consumes` → `no participant + hidden widget mutates nothing`
- `tier-3: the on_* generic callback` : `on_text_input fires per character as text arrives` → `a truthy on_text_input intercepts; falsey reaches sink`
- `tier-3: the native install path` : `a native fires whether or not the widget is shown` → `an explicit on_* takes precedence over the native`
- `the mutable/immutable boundary` : `assigning an unknown slot raises` → `assigning an allowed callback slot is accepted`

### 2. tests/input/input_widgets_callbacks_spec.lua
Inner describe `dispatch chain: widget outputs and submit/cancel #m5c #input`. 8 groups
(the existing two `-- ----` section markers, "widget outputs" and "submit and cancel",
stay as comments; subdivide within them):
- `output field slots and sharing` : `the four widget output fields are assignable` → `field write shares validator slot`
- `highlighter` : `a custom highlighter transforms queried highlight` (single it)
- `navigation boundary outputs` : `up boundary fires direction up with input scope` → `right at last-line end reports input scope`
- `submit` : `Enter runs the full submit call-order chain` → `a rejecting validator locks input without delivering`
- `cancel — the Escape chain` : `Escape runs the full cancel call-order chain` (single it)
- `Enter and Escape as ordinary keys` : `Enter and Escape are ordinary keys while hidden` → `Shift+Return is not intercepted; the sink edits`
- `suppressed cancel` : `hide() fires no cancel chain` → `a force=true reconfigure fires no cancel chain`
- `continuity across submit` : `after_submit can re-activate the widget mid-sequence` → `submit and cancel complete with no hooks set`

### 3. tests/input/input_reconfigure_spec.lua
Inner describe `live reconfigure and clear #m7`. 4 groups; **leave the sibling
`continuous-session idiom #m8` describe untouched** (already its own describe, 3 its):
- `configure on an active session` : `configure updates the prompt on an active session` → `configure leaves text/cursor untouched on an active session`
- `hidden configure` : `hidden configure applies text and cursor on the …` → `hidden-configured text does not leak into a later …`
- `clear` : `clear empties an active session with no callback` → `clear while hidden warns and no-ops`
- `immutability` : `assigning configure/clear raises` (single it)

### 4. tests/input/input_route_lifecycle_spec.lua
Inner describe `route connection lifecycle #m5c`. 4 groups:
- `connection at the running boundary` : `the console regains text entry when a …` → `pointer stays hooked when a non-blocking run …`
- `stop teardown` : `stop clears every project-installed handler …` → `stop resets the widget's own output fields`
- `inspect` : `inspect disconnects the project route and its …` (single it)
- `compy.before_exit` : `compy.before_exit fires once on stop before …` → `compy.before_exit resets to noop after stop`

## Do NOT touch
Any other file. Do not touch tags, the outer describe names, `setup`/`teardown`/
`before_each`, `local F = require(...)` lines, or `tests/helpers/*`. Do not `git add` or
commit — the orchestrator verifies and commits.

## Self-verification protocol (run and report actual numbers)
1. `busted tests` → exactly `815 successes / 0 failures / 0 errors / 4 pending`.
2. For each of the 4 files: `busted tests/input/<f>` standalone → 0 fail / 0 error; and
   `it`+`pending` counts equal to `git show HEAD:tests/input/<f> | grep -cE '^\s*(it|pending)\('`.
3. `git diff HEAD -- tests/input/<f>` and eyeball: confirm the diff is ONLY inserted
   `describe(...)`/`end)` lines, added indentation, and label-prefix trims — no assertion
   or body line changed content (indentation-only changes are fine).
4. `sleep 1`, then LSP diagnostics on each of the 4 files → no new errors.

## Deliverable
Write `doc/development/wip/77-new-input-api/validation/outcomes/S15-TF1-subgroup-execution.md`:
per-file it/pending counts (HEAD vs now), full-suite result, standalone results, and a note
of any label you shortened non-trivially. Then return a short summary.
