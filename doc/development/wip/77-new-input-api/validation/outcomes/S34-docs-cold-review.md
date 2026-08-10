# S34 — cold review of the documentation changes (outcome)

Reviewed `115841cd..HEAD`, the five documentation commits: `fb81ecc0`, `90935e2c`, `8a879534`,
`8cae175f`, `70eb4842`. Read-only; every factual claim below was checked against `src/` or
`tests/` at the current tree state, not accepted from the prose. Findings are ranked
most-severe first.

## Findings

### 1. Two false present-tense claims in the debt register, no `PENDING` marker (CONFIRMED)

Both were introduced or rewritten by `8cae175f` and both assert, as current fact, that
`combo_string` already reads the device — which it does not. `combo_string` is still
`local function combo_string(k, keys_pressed)` (`src/controller/controller.lua:395`), and it
still folds modifiers by indexing the `keys_pressed` table (`:397-401`) — confirmed by reading
the function body. No `Key.ctrl()`/`Key.alt()`/`Key.shift()` call appears in it. Compare with
`src/controller/projectInputController.lua:103-110` (`find_shortcut`), which still fetches
`Controller.keys_pressed` and passes it into `Controller.combo_string(trigger, keys)` — the
table-taking call is still live on the dispatch path today.

- **`doc/development/technical_debt/input.md:863-868`**, the `gui_k` entry:
  > "the combo-string builder used to fold `gui` out of a table that carried every held key, and
  > **now asks the device** one modifier at a time through `Key.ctrl()`/`Key.alt()`/`Key.shift()`
  > — for which `gui` has no counterpart."

  "Now asks the device" is false for the tree as it stands. This entry carries **no** `PENDING`
  marker at all — every sibling entry in the same file that describes dissolved-set behaviour
  (lines 31, 69, 95, 298, 468) does. This is the highest-value finding the prompt asked for: an
  unmarked false claim about current behaviour.

- **`doc/development/technical_debt/input.md:714-718`**, "Combo triggers are key-name-only…",
  the "Cost, if it is ever taken" bullet — this exact clause was *rewritten* by `8cae175f` (diff
  confirmed: `git show 8cae175f` replaces "`Controller.keys_pressed` is key-name-keyed, and
  `combo_string` builds its modifier prefixes from it" with "`combo_string` builds its modifier
  prefixes from key names **it asks the device about**"). Same defect, and the commit *touched*
  this line while introducing it — it isn't inherited drift.

Both read naturally as "the ruled shape," which is exactly what a `PENDING` marker exists to
flag, and both entries are missing one. A reader of the debt register with no other context
would take these as descriptions of the code today.

### 2. The same fact is marked in one document and unmarked in another (CONFIRMED, cross-document)

Item 3 asked whether any pair of the five files (+`tests.md`) now disagree. They do, in marker
discipline rather than in the underlying claim: `doc/development/internals/user_input.md:245-249`
puts a section-level `PENDING` over the identical claim ("this section describes the ruled
shape… the platform step… removes this marker") before describing `combo_string`/`any_mod` as
device-reading. `doc/development/technical_debt/input.md`'s two entries above assert the same
fact with no marker. Same fact, same commit range, two different disclosure treatments — a
reader who trusts the debt register (edited by the very commit that discharges five other
entries under a marker) has no signal that this is intended-future, not current.

### 3. `internals/user_input.md`'s Key Files table silently drops the still-live mechanism, unmarked (CONFIRMED)

`doc/development/internals/user_input.md:858`, the `Key Files` table row for
`src/controller/controller.lua`, was edited by `90935e2c` from:
`"Gateway (love.handlers.*), global shortcuts, keys_pressed/combo_string/pressed-keys view, route
management"` to `"Gateway (love.handlers.*), global shortcuts, combo_string/any_mod, route
management"`. `keys_pressed` and the pressed-keys view are gone from the description. But both
are still there: `Controller.keys_pressed = { }` (`controller.lua:498`) and `held_keys()`
(`controller.lua:430-437`, exported at `:501`) are both live exports of the module today. The
`## Key Files` section (line 847 onward) carries no `PENDING` marker anywhere near this row —
unlike the diagram a few hundred lines earlier, which got one specifically for this same
omission. A reader consulting only the table (its purpose — a fast per-file summary) gets an
inaccurate, unmarked picture of what `controller.lua` currently contains.

### 4. Marker-scope ambiguity in `internals/user_input.md`'s "Key state" section (PLAUSIBLE, stylistic)

The section (`:245-322`) opens with one blanket marker ("this section describes the ruled
shape…") intended — per the `90935e2c` commit message — to cover the whole section through the
next heading. A second, narrower marker sits mid-section (`:274-276`, the missing-`gui()` gap).
After that second marker, the text continues for several more paragraphs (`:278-311`: `any_mod`,
"the matcher is **not** source-blind … a test that proves it patches `love.keyboard.isDown`",
the batch-skew clock argument) with no marker of its own. Structurally this is one blanket marker
interrupted by an unrelated, narrower one, and a linear reader who takes the second marker as
"we're back to describing today" would read "Neither function takes a held-key table any more"
(`:284`) as an unmarked, false, current-tense claim — it currently does (confirmed above). I
believe this is intentional (the commit message frames the top marker as section-wide, and it is
internally consistent with itself), but the layout invites exactly the misreading that caused
finding #1 in the sibling document. Lower confidence than #1-#3 because the author's stated intent
resolves it; flagging because a reader without that context would trip here too.

### 5. `gui_k` debt entry's urgency outgrew its section (minor, structural)

`doc/development/technical_debt/input.md:853-871` is filed under `## Anticipated — revisit at the
named point, close only if warranted` (heading at line 742, "may never need action"). The entry
itself, as rewritten by `8cae175f`, now says the platform step "cannot avoid the question" —
language that reads as scheduled/blocking, not "anticipated, maybe never." Not a factual error,
but the entry's own urgency and its section placement now disagree.

## Clean on these questions

- **Heading-rename citation coverage (item 4).** The only heading text changed by these commits
  is `internals/user_input.md`'s `### Key state: ...` (old: `` `Controller.keys_pressed` and
  `combo_string` ``; new: `modifier reads and `combo_string``). Grepped `src/` and `tests/` for
  every citation of the corpus's headings (`Held keys`, `Key state`, `Key release`, `Dispatch
  chain`, `Data flow`, `configure(config)`, etc.) — the **only** citation of the old "Key state"
  wording was `tests/input/input_nfr_mechanism_spec.lua`, and `90935e2c` fixed it in the same
  commit (verified: the comment now cites Decision 30, not the old heading text). No other
  dangling citation of a changed heading found in `src/` or `tests/`. `doc/input_api.md`'s "Held
  keys" heading was deliberately *kept* unchanged specifically so the two citations in
  `tests/input/input_events_spec.lua:723,820` keep resolving — confirmed the heading is still
  literally `## Held keys` (`doc/input_api.md:363`).
- **Relative `../`-style doc links.** Checked every `[...](../...)` / `[...](../../...)` link
  across the five files plus the `#vocabulary--hook-callback-handler` anchor
  (`event_dispatch_layers.md:22,111`) against actual directory structure. All resolve: e.g.
  `../../input_api.md` from `doc/development/decisions/input.md` and from
  `doc/development/internals/user_input.md` both correctly land on `doc/input_api.md`;
  `../decisions/input.md` from `internals/` lands on `doc/development/decisions/input.md`; the
  vocabulary anchor matches the live heading `## Vocabulary — hook, callback, handler`
  (`decisions/input.md:27`). None of these were touched by the reviewed commits, but all are
  correct as read.
- **New code example API surface and Lua 5.1 compliance (item 5).** `doc/input_api.md:394-424`,
  "Shortcuts that set a flag": `compy.input.fn` is introduced earlier in the same doc
  (`:225-247`) and `fn.side_run` is real — `src/controller/consoleController.lua:503-508`,
  signature `side_run(fn)` returning a function that runs `fn` and always returns `false` (does
  not consume), which matches the doc's "does not consume its event" claim exactly.
  `compy.input.shortcuts.keypressed`/`.keyreleased` and `compy.input.hooks.mousemoved` are real,
  writable surfaces (`mousemoved` is in the dispatched `EVENTS` list,
  `projectInputController.lua:34-39`). The `love.draw`/`love.keyboard.isDown('lshift','rshift')`
  example in "Held keys" (`:376-383`) is a real, standard LÖVE call. No syntax in either example
  needs Lua 5.2+ (no `goto`, no bitwise operators, no integer division).
- **Ledger tombstone discipline (item 6).** Decisions 13, 20 and 29 (the three Decision 30
  supersedes) were not touched by `8a879534` — their bodies read exactly as they did before,
  historical text intact, only pre-existing "SUPERSEDED by Decision 30" headers (not part of this
  diff). Decisions 21, 25 and 26 are **live**, not superseded, so editing their text in place
  (rather than tombstoning) is the correct move; Decision 21 additionally got an explicit
  "Amended in place, 2026-08-10" note documenting what changed and why, which the other two
  didn't need since they're pure corrections of a stale citation, not new argumentation. No
  amendment edited something that should have stayed historical, and nothing superseded was left
  un-tombstoned.
- **REMARK discharge claims.** Grepped all `REMARK` occurrences across the five files: the corpus
  carries many pre-existing owner REMARKs unrelated to this work (out of scope, untouched). The
  three REMARKs the commit messages specifically claim to discharge (two in `fb81ecc0`: the
  "not expressible as shortcuts" one and the "keys_pressed as argument" one; one in `90935e2c`:
  the pointer-combo-strings one) are in fact gone from the current text — verified by grep, they
  do not appear in the post-commit REMARK list.

## Outside the six questions, but worth knowing

- **`event_dispatch_layers.md`'s code line-number citations are stale, independent of this
  review.** `70eb4842` only adds a `PENDING` block; it doesn't touch the surrounding citations
  (`controller.lua:864`, `:873`, `:876`, `:877`, `:879-900`, `:928-932`, `:933-955`, `:983-985`,
  `:995`, `:997-998`). None of them point at the code they claim today: `handlers.keypressed` is
  actually at `controller.lua:787` (not `:876`), the `keys_pressed[k]=true` bookkeeping the new
  `PENDING` note is about is at `:788` (not `:877`), and `handlers.keyreleased`/its bookkeeping
  are at `:905-906` (not `:995-998`). `controller.lua` was last touched by `5a83fe8c`, well before
  `115841cd` — this predates the reviewed range entirely, so it's not something these five
  commits broke, but a reader following the new `PENDING` note straight to `:877` will land on the
  wrong line.
- **Same pre-existing staleness in `internals/user_input.md`.** `` `projectInputController.lua:74-86` ``
  (`:290`, for the free-function `dispatch`) and `` `projectInputController.lua:30-39` `` (`:547`,
  for pointer payloads) both point at the wrong span in the current file — `dispatch` is actually
  at `:132-142`; `:30-39` is the `EVENTS` list, not the pointer-argument code. Neither line was
  touched by `90935e2c` (both are unchanged context in the diff), so again pre-existing, not
  introduced here — but it's in a paragraph these commits did edit around, and a reader jumping to
  the cited lines gets nothing relevant.
- **`examples/keyboard`, cited repeatedly as an existing example (Decision 20, the `compy.keys_pressed`
  debt entry, and `90935e2c`'s new sentence at `internals/user_input.md:299`), is not in this
  branch's git history.** `git log -- src/examples/keyboard` is empty and `git cat-file -e
  HEAD:src/examples/keyboard/input.lua` fails — it exists only as an untracked directory in the
  working tree (`git status` shows `?? src/examples/keyboard/`). `doc/development/wip/.../implementation/pr-assembly-guide.md:143`
  suggests it's meant to be pulled in from `origin/dsent/dev` as part of a separate PR-slice
  assembly step, which would explain the gap without it being a doc defect — but as of this
  commit range, a reader who clones/checks out `feature/77-newapi-analysis-s20260615` clean will
  not find the file these docs point them to.
- **The test double for `love.keyboard.isDown` isn't variadic yet.** `tests/mock.lua:30`:
  `isDown = function(k) return held[k] end` — single-argument. `Key.ctrl()` (`util/key.lua:151-153`)
  calls `love.keyboard.isDown(unpack(ctrl_k))`, i.e. two arguments; under the mock the second is
  silently dropped, so today `Key.ctrl()` in tests only ever sees the left key. Decision 30 itself
  already names this ("the mock's variadic fix becomes a prerequisite") so it isn't a new gap these
  five commits introduced, but the new `doc/input_api.md` example (`love.keyboard.isDown('lshift',
  'rshift')`, `:381`) is exactly the shape that would misbehave under the current mock — worth
  remembering when the platform step lands and this becomes testable prose instead of aspirational
  prose.
