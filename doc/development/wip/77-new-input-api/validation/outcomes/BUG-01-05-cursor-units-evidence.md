# BUG-01-05 — evidence: cursor units, `set_cursor` (bytes) vs. the rest of the model (characters)

Investigates `T-CURSOR-BYTES` (`doc/development/technical_debt/input.md:136-144`).
Read-only pass; no files changed except this one and a throwaway probe spec
under the scratchpad (not in the repo).

## Summary up front

The defect is real and **observable through the public `compy.input`
surface**, confirmed by a running probe (§3). Three functions clamp/bound a
cursor column using **byte length** (`#`); the rest of the model — the
large majority, both the primitive movement API and the view's pixel math —
counts in **characters** (`string.ulen`/`utf8.offset`). The byte convention
is not new: `UserInputModel:move_cursor`'s bound already used `#` at the PR
base. What this feature (#77) did was add **two new project-facing entry
points** — `UserInputController:set_cursor_pos` (`compy.input.set_cursor`,
`show{cursor=...}`) and `UserInputModel:_clamp_cursor_pos`
(`compy.input.set_text(t, true)`) — that both deliberately imitate
`move_cursor`'s pre-existing byte bound (the `_clamp_cursor_pos` doc
comment says so explicitly). Because these are the *only* paths that accept
an arbitrary, non-internally-computed column, the feature turned a
previously inert inconsistency (no internal caller ever exercised the gap
between the byte bound and the char bound) into a live, reachable one. See
§7 for the full base comparison.

No existing test pins a byte count in a way a char-based fix would break
(§5) — the clamp tests all use ASCII text, where bytes and characters
coincide.

## 1. Name the two functions

Three sites clamp/bound a cursor column by **bytes** (`#` / `string.len`),
all doing conceptually the same job — compute "how far right can the caret
go":

| Site | Unit | Code |
|---|---|---|
| `UserInputModel:move_cursor` (`src/model/input/userInputModel.lua:545-561`) | **bytes** | `local llen = #(self:get_text_line(l))` (:554); `char_limit = llen + 1` (:555) |
| `UserInputModel:_clamp_cursor_pos` (`:534-540`) | **bytes** | `local llen = #(self:get_text_line(l))` (:537); comment at :530 explicitly says *"byte length, matching move_cursor's own bound below"* |
| `UserInputController:set_cursor_pos` (`src/controller/userInputController.lua:193-199`) | **bytes** | `local llen = #(self.model:get_text_line(l))` (:196) |

Against this, the rest of the model's cursor-boundary logic counts in
**characters** (`string.ulen`, backed by `utf8.len`, `src/util/string/string.lua:102-108`):

| Site | Unit | Code |
|---|---|---|
| `UserInputModel:_update_cursor` (`:497-506`) | chars | `self.cursor.c = string.ulen(t[cl]) + 1` (:501) |
| `UserInputModel:is_at_limit` (`:606-624`) | chars | `local line_end = string.ulen(line) + 1` (:615) |
| `UserInputModel:cursor_vertical_move` (`:639-724`) | chars | `local llen = string.ulen(self:get_text_line(cl))` (:643), and throughout |
| `UserInputModel:cursor_left` (`:726-746`) | chars | `local cpc = 1 + string.ulen(pl)` (:735) |
| `UserInputModel:cursor_right` (`:748-767`) | chars | `local len = string.ulen(line)` (:751) |
| `UserInputModel:jump_end` (`:781-794`) | chars | `local last_char = string.ulen(ent[last_line]) + 1` (:784) |
| `UserInputModel:jump_line_end` (`:819-830`) | chars | `local char = string.ulen(ent[line]) + 1` (:822) |
| `UserInputModel:add_text` (`:100-135`) | chars | `self:_advance_cursor(string.ulen(text))` (:112); `self:move_cursor(last_line_i, string.ulen(ll) + 1)` (:131) |
| `UserInputModel:backspace` / `delete` (`:301-356`) | chars | `string.ulen`, `string.usub` throughout |
| `UserInputModel:translate_grid_to_cursor` (`:951-959`, mouse) | chars | `local llen = string.ulen(line)` (:955) |

`move_cursor` itself is internally split: its **bound** is bytes (:554-555)
but every caller that reaches it (18 internal call sites, confirmed by both
grep and `mcp__lua-lsp__references` — no discrepancy) passes an
already-char-computed `x` (`string.ulen(...)`-derived, or a mouse/grid
coordinate that is itself char-based). The byte/char gap in `move_cursor`'s
own bound is therefore normally never *exercised* internally — see §7.

**The two functions the debt entry means**, most precisely: `move_cursor`'s
byte-based `char_limit` bound (`userInputModel.lua:554-555`, pre-existing)
versus the char-based boundary computations used everywhere else to decide
"where does this line/text end" — `jump_end`/`jump_line_end`/`is_at_limit`/
`_update_cursor` (all `string.ulen`). `_clamp_cursor_pos` and
`set_cursor_pos` are new code that consciously copied the byte side of that
split out to the two new project-facing entry points.

## 2. Which is the "boundary event"?

The project-facing `compy.input` surface. Two relevant reads/writes, both
thin passthroughs with **no unit reconciliation**:

- `compy.input.get_cursor()` → `src/controller/consoleController.lua:834-836`:
  `get_cursor = function() ... return get_widget():get_cursor_pos() end` →
  `UserInputController:get_cursor_pos` → `UserInputModel:get_cursor_pos`
  (`userInputModel.lua:574-576`) → `return self.cursor.l, self.cursor.c` —
  a raw read of whatever unit last wrote `self.cursor.c`, no re-clamping,
  no unit tag.
- `compy.input.set_cursor(line, col)` →
  `src/controller/consoleController.lua:764-772` (`api_set_cursor`) →
  `get_widget():set_cursor_pos(pair[1], pair[2])` — the **byte**-clamped
  controller function.

`doc/development/internals/user_input.md:93-124`, "Cursor manipulation and
'reset'", names this same surface as the outward-facing layer: *"`compy`
(project-facing) now has its own surface on the input widget:
`compy.input.get_cursor()` / `set_cursor(line, col)` ...`get_cursor` returns
`nil` while hidden ... `set_cursor`/`set_text` no-op and warn while
hidden."* This is the boundary meant: whatever unit a project-supplied
`set_cursor` call is clamped in (bytes) is exactly the unit
`get_cursor()` echoes back out, unreconciled against the char-based value
every other internal path (typing, arrow keys, mouse) would have produced
for the same intended caret position.

## 3. Is the disagreement observable? (probe run)

Yes, run and confirmed. Probe file (throwaway, not in the repo):
`/tmp/claude-1000/-repo/0300de11-b9f4-4385-85b4-566f47ee68cc/scratchpad/probe_cursor_units_spec.lua`,
run with `busted -o gtest <path>` from `/repo`.

**Interpreter used for this run: LuaJIT** (`busted`'s shebang execs
`/usr/bin/luajit`; there is no PUC `lua5.1` binary in this container). Per
the standing note that container-green is not machine-green, this claim is
LuaJIT-only; not re-verified under PUC Lua.

Repro: text `'привет'` — 6 Cyrillic characters, 2 bytes each, so
`string.ulen('привет') == 6` and `#'привет' == 12`. Char-legal caret range
is `1..7`; byte-legal caret range is `1..13`. Column `10` is illegal in
characters, legal in bytes.

**Actual output:**

```
ulen=	6	#bytes=	12
after set_cursor(1,10): l=	1	c=	10
char-clamp would assert c==7; actual c=	10
```

`input.set_cursor(1, 10)` through the real `compy.input` route
(`F.compy_input()`, driven through `ConsoleController`) does **not** clamp
to 7 (the character end); it accepts 10 outright, because
`set_cursor_pos`'s bound is `#'привет' + 1 = 13`, and `10 <= 13`.
`input.get_cursor()` then reports `(1, 10)` — a caret position with no
corresponding character boundary in a 6-character string.

Second case — what typing does at that invalid caret:

```
text after typing X at (1,10):	приветX
cursor after typing:	1	11
```

Typing lands the `X` at the real end of the string (`add_text`'s
`string.split_at` internally falls back to "whole string" / "empty tail"
when asked to split at an out-of-range **character** index — see
`src/util/string/string.lua:156-168` and `:115-143`), silently
re-anchoring the edit to a sane position. But the **reported** cursor
value is not re-anchored: it becomes `11` (`10 + 1`, from
`_advance_cursor`'s plain arithmetic), which is now *further* from the
true valid range (`1..8`, since the string is now 7 characters) than
before. The divergence between reported cursor and actual valid range
grows with each keystroke rather than self-correcting.

Model- and controller-level confirmation of the byte/char split itself:

```
model move_cursor(1,10) -> l,c =	1	10
model jump_end -> l,c =	1	7	(ulen+1 would be	7	)
controller set_cursor_pos(1,10) -> l,c =	1	10
```

`move_cursor` (byte bound) accepts 10; `jump_end` (char bound, the
"boundary" of the text in every other sense) computes 7 for the same
string. `UserInputController:set_cursor_pos` reproduces the same 10.

**Rendering consequence (not run, inferred from code):** the view draws
the caret from raw `cursor.c` treated as a **character** column —
`src/view/input/userInputView.lua:52-53,88-89,110-120`: `acc = cc - 1`,
`x_offset = math.fmod(acc, w)`, `x = (x_offset - .5) * fw` — one glyph
cell per unit of `cc`. With `cc = 10` on a 6-character line, the caret
would be drawn 4 columns past the end of the actually-rendered text
(`calc_overflow`'s own `clen = string.ulen(curline)`, :58, confirms the
view's own idea of line length is chars, not bytes) — visibly detached
from the text rather than sitting inside or at the end of it. This part
was reasoned from the code, not screenshotted; the display would need
`xvfb-run love src` to confirm visually, which was out of scope for a
read-only evidence pass on a headless probe.

## 4. What does the public contract promise?

`doc/input_api.md:192-201`:

> `get_cursor()` returns `line, col`; `set_cursor(line, col)` moves it.
> Mutating calls warn and do nothing while the input widget is hidden.
>
> `col` is a **caret position between characters**, not a character index:
> it ranges over `1 .. #line + 1`, where `1` is before the first character
> and `#line + 1` is at the end of the line. So on `"lemon"`,
> `set_cursor(1, 3)` puts the caret between `e` and `m` — typing inserts
> there (`"leXmon"`) and Backspace deletes the character before it
> (`"lmon"`). Out-of-range values clamp to that range rather than failing.

This is genuinely ambiguous, and arguably self-contradictory. The prose
says "a caret position **between characters**" (a character-counting
notion), but the range formula is written literally as `#line + 1` — `#`
is Lua's byte-length operator, and the doc uses it nowhere else as loose
shorthand for "length" in this section. The worked example (`"lemon"`) is
pure ASCII, where `#line == string.ulen(line)`, so the example cannot
disambiguate which the author meant. Taken at face value, the doc's literal
formula matches the *implementation's* current byte-based clamp
(`set_cursor_pos`), not the character-based convention the prose and the
rest of the model use. **The document does not clearly commit to one or
the other; it currently reads as documenting the buggy (byte) behaviour
verbatim, by accident or by literal transcription of the code.**

`doc/development/internals/user_input.md:93-124`, "Cursor manipulation and
'reset'", describes the three API layers and their call graph in detail
(quoted in §2) but says nothing about byte vs. character units anywhere in
that section or elsewhere in the file (checked with a full-file grep for
`ulen`/`utf8`/byte — no hits). It documents the *shape* and *reachability*
of the cursor-setting paths, not their unit.

**Verdict: silent on the byte/char distinction as a design question; the
one place a unit is written down (`doc/input_api.md`'s `#line + 1`) reads
as accidentally committing to bytes, contradicting its own "between
characters" prose and the majority convention (§6).**

## 5. What do the existing tests pin?

`tests/input/cursor_spec.lua`: tests the standalone `Cursor` class (compare,
equality) only — no text, no units, not relevant here.

`tests/input/input_cursor_text_spec.lua` (the `compy.input` `get_cursor`/
`set_cursor`/`set_text` contract suite): every `it(...)` that exercises
clamping does so on **pure-ASCII** text:

- `'clamps an over-range column'` (:109-116): text `'hello'`,
  `set_cursor(1, 999)` → asserts `c == 6` (`'hello'` end, len 5 + 1).
- `'clamps an over-range line'` (:118-124): text `'hello'`, line clamp only.
- `'clamps when text shrinks'` (:218-226): `set_text('xy', true)` after
  cursor at 5 → asserts `c == 3` (`'xy'` end, len 2 + 1).
- `'replaces content and jumps to the end'` (:171-180), `'moves the
  cursor'` (:92-103), `'preserves the cursor'` (:202-216): all ASCII
  (`'hello'`, `'lemon'`, `'world'`, `'worldly'`).

For every one of these, `#line == string.ulen(line)`, so a byte-clamp and a
char-clamp compute the **identical** number. **None of them would break if
the clamp were changed from `#` to `string.ulen`** — this specific test
file supplies zero discriminating pressure between the two units.

`tests/input/user_input_model_spec.lua` does exercise multi-byte text
(Cyrillic `'когда'`/`'брожу'`, `'кога'`, `'коа'`, `'оа'`) extensively, and
several assertions are explicitly `string.ulen`-based (e.g. :488
`local pos = string.ulen('оа') + 1`, :527 `assert.same(1 +
string.ulen(test1_l2), cc)`), i.e. these tests are *already* written
expecting the character convention. But none of them drive
`move_cursor`/`set_cursor_pos`/`_clamp_cursor_pos` with an **out-of-range**
value on multi-byte text (the only condition where the byte/char bound
actually differs — see §3); they exercise `jump_end`, `backspace`,
`delete`, `add_text` etc. with in-range, internally-computed positions,
which agree regardless of which bound `move_cursor` uses (§7's "inert"
point). So: **no existing test asserts a byte count that a character-based
fix to the clamp would break**, and a subset of tests already assumes and
would keep pinning the character convention.

## 6. How does the rest of the model count?

**Characters, overwhelmingly**, both in the model and in the view:

- Typing (`add_text`): `string.ulen(text)` (:112), `string.ulen(ll) + 1`
  (:131).
- Deleting (`backspace`, `delete`): `string.ulen`, `string.usub`
  throughout (:314, :322-323, :339, :350-351).
- Arrow-key movement (`cursor_left`, `cursor_right`,
  `cursor_vertical_move`): `string.ulen` throughout (:735, :751, :643,
  :677, :693).
- Line/text boundaries (`jump_end`, `jump_line_end`, `is_at_limit`):
  `string.ulen` (:784, :822, :615).
- Mouse→cursor translation (`translate_grid_to_cursor`): `string.ulen`
  (:955).
- The **view**: `src/view/input/userInputView.lua`'s `calc_overflow`
  (:51-68) and `render_input` (:72+) treat `cursor.c` as a raw character
  column for pixel math (`clen = string.ulen(curline)` at :58; `acc = cc -
  1` then divided/modulo'd by the wrap width `w` to place the glyph, :89,
  :111,:119) — one screen column per character, not per byte.

Against this majority: `move_cursor`'s own bound, `_clamp_cursor_pos`, and
`UserInputController:set_cursor_pos` — three sites, all clamps/bounds, none
of them movement or rendering logic. **The rest of the system — every
consumer that actually walks or draws the text — already commits to
characters; the byte convention exists only in the three
bound-computation sites named in §1, and only manifests when a caller
supplies a value those internal char-based callers would never produce.**

## 7. Base check (`3256aac`)

```
git show 3256aac:src/model/input/userInputModel.lua
git show 3256aac:src/controller/userInputController.lua
```

- **`UserInputModel:move_cursor`** — exists at base (base line 506-522),
  **byte-bound already**: `local llen = #(self:get_text_line(l))` (base
  line 515), unchanged in shape from current (:545-561). **Inherited, not
  introduced.**
- **`UserInputModel:_clamp_cursor_pos`** — **does not exist at base.**
  Grep for `_clamp_cursor_pos`/`set_cursor_pos` in the base file returns
  nothing. New in this feature — the `set_text(text, keep_cursor)` clamp
  path.
- **`UserInputController:set_cursor_pos`** — **does not exist at base**
  either (base controller has no `cursor` reference beyond
  `get_cursor_info`/`get_cursor_pos`/`set_cursor(Cursor)`, none of which
  clamp). New in this feature — this is FR-9's `compy.input.set_cursor`
  implementation (matches the already-filed `BUG-01-08` row's
  "`set_cursor_pos` does not exist at `3256aac`" finding for the same
  function).
- All the **char-based** boundary functions — `_update_cursor`,
  `cursor_vertical_move`, `cursor_left`, `cursor_right`, `jump_end`,
  `jump_line_end` — already existed at base with the identical
  `string.ulen` shape (base lines 471-475, 585-589, 672-681, 694-699,
  727-730, 765-768). **Inherited, not introduced.**

**Verdict: this feature inherited the byte/char split unchanged (it was
already present, confined to `move_cursor`'s internal bound, at base) but
widened its exposure.** At base, every caller of `move_cursor` was
internal and char-computed (see §1/§6), so the byte bound was strictly
looser than any value a caller would ever pass — the gap between the two
units was never actually exercised; the inconsistency was latent and
inert. Feature #77 added the *first two* call paths that hand `move_cursor`
(via `set_cursor_pos`) an **arbitrary, externally-supplied** column —
`compy.input.set_cursor(line, col)` and `show{cursor={line,col}}` — and
both new wrapper functions were written to copy `move_cursor`'s pre-existing
byte convention rather than the char convention used everywhere else
(`_clamp_cursor_pos`'s own doc comment at userInputModel.lua:530 says this
was deliberate: *"byte length, matching move_cursor's own bound below"*).
So: **the unit mismatch itself predates the feature; the feature is what
made it reachable from outside the model for the first time.** This is the
same shape of finding as two earlier rows in this workspace (a base check
overturning or refining a "this feature caused it" assumption) — here it
neither fully confirms nor fully denies that framing: the disagreement is
old, but only this feature's new entry points make it observable.

## 8. Blast radius

Concrete callers, cross-checked by grep and `mcp__lua-lsp__references`
(identical results, no discrepancy):

- **`UserInputController:set_cursor_pos`** (the byte-bound controller
  function) has exactly **two** callers, both project-facing:
  - `src/controller/userInputController.lua:332`, inside `open_widget` —
    reached from `compy.input.show{cursor = {line, col}}` and a forced
    `show`.
  - `src/controller/consoleController.lua:771`, inside `api_set_cursor` —
    reached from `compy.input.set_cursor(line, col)` directly.
  If this bound switched from `#` to `string.ulen`, both of these — the
  *entire* set of ways a project can seat an explicit cursor — would
  change behaviour only for out-of-range, multi-byte-line values; in-range
  values and ASCII text are unaffected (§5/§6 already establish no test
  depends on the byte reading).
- **`UserInputModel:_clamp_cursor_pos`** has exactly **one** caller:
  `userInputModel.lua:154`, inside `set_text(text, true)` — reached from
  `compy.input.set_text(text, true)`. Same story: only affects
  out-of-range multi-byte cases.
- **`UserInputModel:move_cursor`** has **18** internal callers (listed in
  full in §1/confirmed by LSP references above) plus the one from
  `set_cursor_pos`. All 18 internal callers pass a value already computed
  via `string.ulen`/char-based grid translation, so they never hit the gap
  between the byte and char bounds — changing `move_cursor`'s own bound
  from `#` to `string.ulen` would be a no-op for every one of them (the
  value they pass is always `<= char_limit <= byte_limit`, so tightening
  the bound to char_limit cannot reject anything they were going to pass
  anyway). The only caller that *could* regress from a byte→char bound
  change is the one from `set_cursor_pos`, already covered above.
- **`src/controller/editorController.lua:631`** (`reject_oversized`) calls
  `input.model:move_cursor(block.pos.start, 1)` directly, bypassing the
  controller — column argument is hardcoded `1`, so it is unaffected by
  either bound.
- **Downstream consumers of `self.cursor.c`** that would be affected by
  whichever value ends up stored, regardless of which function set it:
  `get_cursor_pos`/`get_cursor_x`/`get_cursor_info` (all raw reads),
  `compy.input.get_cursor()` (§2), and the view's pixel math
  (`userInputView.lua`, §3/§6). None of these compute a bound themselves;
  they inherit whatever `self.cursor.c` was left at.

No blast radius was found beyond these four functions and their direct
call graph — the two new project-facing entry points, `move_cursor`'s
pre-existing bound, and the read-only surfaces that echo `cursor.c` back
out.

## Corrections to the debt entry

- The entry names neither function; they are, most precisely,
  `UserInputModel:move_cursor`'s byte-based bound (`userInputModel.lua:554-555`,
  pre-existing) and the char-based boundary computations used by
  `jump_end`/`jump_line_end`/`is_at_limit`/`_update_cursor` and effectively
  everything else in the model and the view. The two *new* functions this
  feature added — `UserInputController:set_cursor_pos` and
  `UserInputModel:_clamp_cursor_pos` — do not disagree with `move_cursor`;
  they were deliberately written to **agree** with it (bytes), which is
  what makes the disagreement with the char-based rest of the system
  reachable from the project-facing API.
- "**Which is right has not been decided**" understates how lopsided the
  existing convention is: every movement primitive (typing, deleting,
  arrows, mouse) and the view's rendering math already count in
  characters. The byte convention exists only in three bound checks, none
  of which anyone would need to touch for movement or rendering to work —
  it is confined to the "clamp an externally supplied number" role.
- **Base check materially changes the framing.** `move_cursor`'s byte
  bound is not new — it existed at `3256aac`, unchanged. The feature did
  not invent the unit mismatch; it inherited it, and specifically
  *because* the new `compy.input.set_cursor`/`show{cursor=...}`/
  `set_text(t, true)` paths were built to reuse `move_cursor`'s existing
  bound rather than the model's dominant char convention, the (previously
  inert) mismatch became reachable from outside for the first time. A
  fix framed purely as "decide bytes vs. chars for `set_cursor`" would
  miss that `move_cursor`'s bound is shared, pre-existing code also used
  internally — any unit change there needs the §8 call-graph check, even
  though none of the 18 internal callers currently depend on the byte
  reading.
- The defect **is observable through the public surface**, confirmed by a
  live probe run (§3), not just by static reading: `compy.input.set_cursor`
  on multi-byte text accepts and echoes back a caret column with no
  corresponding character boundary, and the divergence between the
  reported cursor and the true valid range grows on subsequent edits
  rather than self-correcting.
- `doc/input_api.md`'s public contract is not silent the way the debt
  entry's "not yet decided" framing implies for the *written-down* half of
  the contract — its literal formula (`#line + 1`) already commits to
  bytes, in apparent tension with its own "caret position between
  characters" prose one sentence earlier. `doc/development/internals/user_input.md`
  is genuinely silent on units.
- No existing test asserts a byte-specific value that a character-based
  fix to the clamp would break (§5); the multi-byte-text tests that do
  exist are all char-based already and do not exercise the clamp's
  out-of-range path. Sizing a fix as "small" on the grounds that nothing
  pins the old behaviour appears correct, restricted to this narrow
  observation — it says nothing about how much design discussion the
  "which unit is authoritative" call itself deserves, which is a separate
  question this pass was not asked to answer.
