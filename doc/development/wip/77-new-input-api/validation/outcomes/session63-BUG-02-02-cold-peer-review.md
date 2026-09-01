# Cold peer review — `BUG-02-02`, the content boundary check

Reviewer: cold, no stake. Commits under review: `9d5cbd41` (production + tests), `18250e3e`
(docs and ledgers). Prompt of record:
[`validation/prompts/session63-bug-02-02-cold-peer-review.md`](../prompts/session63-bug-02-02-cold-peer-review.md).

**Environment.** `busted tests` at HEAD → **1043 / 0 / 0 / 10**, matching the claim. Container
interpreter is **LuaJIT 2.1.1703358377** (`lua` is not on PATH); the owner's PUC Lua is not
exercised here. One finding below (F9) is interpreter-sensitive and is flagged as such; the
principal finding (F1) is not — it holds on 5.1, 5.2, 5.3, 5.4 and LuaJIT alike.

**`lua-lsp` MCP.** `diagnostics` worked (`src/controller/consoleController.lua` → clean).
`references` still fails with `failed to fetch symbol: ... broken pipe`, on two separate attempts
(`build_widget_api`, `checked_text`). The "who calls this" questions in items 2 and 3 were therefore
answered with `grep` over `src/` plus a manual read of the one construction site
(`consoleController.lua:958`) rather than with AST references. That is a weaker instrument on a
dynamically-typed codebase and I say so rather than implying I had the LSP's coverage.

---

## Verdict

**Changes needed.** The check is real and its five tests are honest, but it does not close the
defect class it is written against: a list with a **hole** or with **hash keys** slips past
`checked_text` and reproduces *both* silent symptoms — the drop and the wipe — from inside the
project surface. `doc/input_api.md` and the RETIRED ledger entry state a guarantee the code does not
give. Separately, the lift silently changed what `show{text = false}` does, undocumented and
untested; and the CHANGELOG's "previously" sentence is not true of the release it says it is written
against.

---

## Point by point

### 1. Is `checked_text` correct and complete? — **No. This is the finding.**

`checked_text` (`src/controller/consoleController.lua:720-732`) walks the candidate list with
`ipairs` (`:725`). `normalized_lines` (`src/model/input/userInputModel.lua:145-155`) walks it with
`ipairs` too (`:151`). The two agree, which is why nothing raises — and they agree on *stopping at
the first hole* and on *ignoring every non-integer key*. Everything past a hole is neither validated
nor rendered.

Probed through the real surface (`F.compy_input()`, throwaway spec, since deleted). Widget seeded
with `show{text = 'kept'}` first in every case:

| input | raises? | resulting content | verdict |
|---|---|---|---|
| `{'a', nil, 'b'}` (literal) | no | `{'a'}` | **`'b'` silently lost** |
| `t[1]='a'; t[3]='b'` | no | `{'a'}` | **`'b'` silently lost** |
| `t[1]='a'; t[3]=42` | no | `{'a'}` | **the drop symptom, verbatim** |
| `show{text = t}` with `t[1]='a'; t[3]=42` | no | `{'a'}` | same, through the other entry point |
| `{foo = 'bar'}` | no | `{''}`, `is_empty()` **true** | **the wipe symptom, verbatim** |
| `{foo = 42}` | no | `{''}` | same |
| `{'a', foo = 42}` | no | `{'a'}` | non-string value dropped silently |

The hole is not an exotic construction. This produces one:

```lua
local src = { [1] = 'one', [3] = 'three' }
local lines = {}
for i, v in pairs(src) do lines[i] = v end
compy.input.set_text(lines)      -- widget shows 'one'. No message.
```

That is exactly the failure the debt entry calls *"silent and it looks right: the widget comes up
with content, just not the content the project set"*. Answering `{42}` with a refusal while
answering `{foo = 42}` with a silent wipe is the same "three unrelated answers" shape the row exists
to remove, one spelling further out.

Also probed and **correct**: `nil` and `false` → no-op (see item 5); `''` → empty; `{}` and `{''}`
→ empty content (defensible — an empty list is an empty document); a bare `42`, `true`, or a
function → refused with the right message; a 20 000-element list → accepted, nothing truncated; an
embedded `\0` → stored (representation, correctly not refused); the widget's own `InputText`
round-tripped back through `set_text` → accepted, content preserved.

**Recommendation.** Validate against `#text` rather than `ipairs`, or reject a table whose `#`
count and `ipairs` count disagree, or reject any table carrying a non-integer key. The narrow fix
inside the existing shape:

```lua
for i = 1, #text do
  if type(text[i]) ~= 'string' then ok = false end
end
```

That closes the `t[3]=42` drop (`#t` is 3 under both interpreters for that table) but **not** the
`{foo = 42}` wipe, and `#` on a table with a hole is undefined by the language — so a check that
refuses "a table that is not a dense array of strings" is the one that actually matches the
documented contract. Whichever is chosen, `normalized_lines` must be brought to the same rule or the
two will disagree again.

### 2. Is the boundary complete for the project surface? — **Yes, for `text`.**

`build_widget_api` has exactly one construction site (`consoleController.lua:958`, grep over `src/`
returns that plus a prose mention in `main.lua:358`), so the project surface is the only consumer.
Its content-setting members are `show` and `set_text`; both now pass `checked_text` (`:778-779`,
`:813-814`). `clear` sets no content. `configure` refuses `text` — verified live, not read:

```
pcall(input.configure, { text = {'a', 42} })
→ compy.input.configure: 'text' belongs to show(), or set_text on a live widget, do not pass it here
```

and the same for a *well-formed* `text`, so it is `check_keys`/`SHOW_ONLY_KEYS` doing it, as
claimed. No other project-visible route reaches content: `get_compy_namespace` exposes
`terminal / audio / graphics / fonts / input / before_exit`, and the legacy globals
(`write_to_input` et al., present at the PR base `0022004e:consoleController.lua:567`) are gone.

Framework-internal callers do bypass, exactly where the split is claimed:
`editorController.lua:336, :602`, `userInputModel.lua:472, :484` (history) all call
`UserInputController:set_text` / `UserInputModel:set_text` directly. Confirmed by grep, not by LSP
references (broken pipe); for a dynamically-dispatched call I could have missed one, so treat this
as strong rather than exhaustive.

### 3. Did lifting `set_text` into `api_set_text` change anything? — **Yes, one thing, unclaimed.**

Mechanically the lift is faithful: same warn string, same early `return`, `keep_cursor` forwarded,
and neither the old closure nor the new one returns a value (`UserInputController:set_text` returns
nothing either way).

But `api_show` now writes `next_cfg.text = checked_text(...)` (`:778-779`), and `checked_text`
normalises **falsy to `nil`** — while `reset_content` (`userInputController.lua:312-318`) branches on
`cfg.text == nil`. Probed both revisions by swapping in `9d5cbd41^`'s `consoleController.lua` and
re-running the same spec:

| | `show{text='kept'}` → `hide()` → `show{text=false}` |
|---|---|
| at `9d5cbd41^` | content `{'kept'}` survives, `is_empty()` **false** |
| at `9d5cbd41` | content cleared, `is_empty()` **true** |

See item 5. Nothing else in the diff moves.

### 4. Is the error attribution right? — **Yes, from both entry points, and end to end.**

Called from a chunk named `@/proj/main.lua`:

```
/proj/main.lua:1: compy.input.set_text: text must be a string or a list of line strings
/proj/main.lua:1: compy.input.show: text must be a string or a list of line strings
/proj/main.lua:1: compy.input.set_cursor: cursor must be a {line, col} pair of numbers   (existing)
/proj/main.lua:1: compy.input.show: unknown config key 'bogus'                           (existing)
```

Identical shape to the two existing raises. Through a **real project run** (`F.run_project`, the
production `run_user_code` boundary) what a project author sees on the console is:

```
Error:  L10:compy.input.show: text must be a string or a list of line strings
```

`L10` is the project's own `compy.input.show` line, not a framework line. The error boundary does
not swallow or re-wrap it. This item is fine.

### 5. Does `false` still work as the unset? — **It behaves correctly now, but the change is undocumented and untested.**

The new behaviour is the *right* one: Decision 35 statement 1 says *"`text` given is the content,
`text` absent is an empty field"* and statement 3 makes `false` the uniform unset
(`decisions/input.md:1406-1416`), so `show{text = false}` ought to give an empty field. Before this
commit it left the previous session's content standing, contradicting both statements. So the lift
quietly fixed a second bug.

`cursor` is treated identically (`show{cursor = false}` → `cfg.cursor` normalised to `nil`), so the
two keys are consistent. `set_text(false)` and `set_text()` remain no-ops leaving content standing,
unchanged from the parent — correct, since `set_text` is not the content baseline.

What is wrong is that **nothing says so**:

- `doc/input_api.md:133` enumerates the keys `false` unsets — `prompt`, `highlighter`, `validator`,
  `on_text_entered`, `on_limit_reached`, `auto_hide` — and `:136` handles `cursor` separately.
  `text` appears in neither. A project author has no way to learn what `show{text = false}` does.
- No CHANGELOG line, no ledger line, no commit-message line. The `BUG-02-02` ROADMAP row's own
  standard (*"a public-surface behaviour change ... earns a CHANGELOG line and a justification line
  of its own"*, inherited from the deleted BACKLOG entry) is not met by its own change.
- No test pins it. The suite is green in both directions.

### 6. Are the five new tests good? — **Yes. They are the strongest part of the change.**

All five run — `-o TAP` shows tests 16-20, four from the `pairs` table (`a number`,
`only a number`, `a boolean`, `a nested table`) plus the `show` case. Nothing is silently skipped.

Mutation-tested, one at a time, restoring between each:

| mutation | new tests failing | reads as |
|---|---|---|
| `checked_text` always returns `text` | **5** | ✓ |
| never set `ok = false` in the scan | **5** | ✓ |
| drop the `api_show` call only | **1** (the `show` case) | ✓ correctly isolated |
| drop the `api_set_text` call only | **4** | ✓ correctly isolated |
| reword the message to `': bad text'` | **4** | the `show` case does **not** pin the message body |
| `error(…, 4)` → `error(…, 3)` | **0** | **the depth rule is not tested at all** |
| wipe content *before* raising | **4** | ✓ the "content untouched" assert is load-bearing |

Two gaps fall out. The `show` case asserts only `assert.matches('compy%.input%.show', err)`, so the
guide's promise that *"`show` raises the same message under its own name"* is unpinned — one extra
`assert.matches('list of line strings', err)` fixes it. More seriously, **changing the error level
breaks nothing**: the entire stated reason `api_set_text` exists is the level-4 depth rule, and no
test anywhere in `tests/` asserts on a `file:line` prefix (grepped). A future edit that inlines
`api_set_text` back into the closure, or interposes a frame, silently points every one of these
messages at `consoleController.lua` and the suite stays at 1043. That gap pre-dates this change (it
applies to `check_keys` and `checked_cursor` too) but this change adds a third function whose only
justification rests on it.

### 7. Are the documents honest? — **Three problems.**

**a. The guide and the RETIRED entry state a guarantee the code does not give.**
`doc/input_api.md:217` — *"**Every element must be a string, and a list containing anything else is
refused**"*. `technical_debt/input.md:1381` — *"refuses **any** `text` that is not a string or a list
of strings"*. Both are refuted by item 1's table: `{foo = 42}` is not a list of strings and is not
refused, it wipes the widget. This is worse than the pre-change state of the *documentation*, which
at least described the behaviour accurately in the BACKLOG entry now deleted.

**b. The CHANGELOG's "previously" is not true of the release it claims to be written against.**
`CHANGELOG.md:159-161`: *"Previously such a value died inside the framework with `bad argument #1 to
'len'`."* The commit message defends writing this against the last release rather than against this
morning. But `sanitize_utf8` — the function that raises it — **does not exist at the PR base**:
`git show 0022004e:src/model/input/userInputModel.lua | grep sanitize_utf8` returns nothing, and
`git log -S sanitize_utf8` puts its arrival at `945a5d1d`, which
`git merge-base --is-ancestor 945a5d1d 0022004e` reports is **not** an ancestor of the base. At the
base, `UserInputModel:set_text` (`:128-146`) handed the list straight to `InputText`, which stored
it as-is. Whether *some other* `len` call produced the same message at the base is unverified — the
string utility was a submodule at that revision (`160000 commit ff9be4b9` at `src/util/string`), so I
could not run it. Either way the entry asserts a specific pre-state it has not established.

Two further inaccuracies in the same paragraph: *"anything else — a number, a boolean, a table —
now raises"* is false for `false` (a boolean, which is the unset and correctly does not raise) and
misleading for *"a table"*, which is the **valid** spelling of the shape. And the neighbouring entry
at `:145-152` sets the file's own convention by saying explicitly *"This is longstanding, not new —
the same guard is in the release this one branches from"*; this entry says nothing about provenance
while making a provenance claim.

**c. Decision 38's new section overclaims the scope of what was settled.**
`decisions/input.md` (the paragraph closing the new section at `:1701` ff): *"a malformed value on
the public surface earns **one** message naming the call and the expected shape, never a raw Lua
error from inside the framework and never a silent repair."* Only `text` and `cursor` are checked.
Probed:

```
show{prompt = 42}              → accepted silently
show{prompt = {'x'}}           → accepted silently
show{on_text_entered = 42}     → accepted silently; at submit:
    Error: L437: attempt to call local 'cb' (a number value)   [userInputController.lua:437]
show{validator = 42}           → accepted silently; at submit:
    Error: L417: attempt to call local 'validator' (a number value)
```

That is precisely *"a raw Lua error from inside the framework"*, still reachable from the public
surface, from a config table that `check_keys` accepted. The claim needs narrowing to `text` and
`cursor`, or the remaining keys need the same treatment. *"Never a silent repair"* is likewise
refuted by item 1.

**d. `pong/main.lua:104` is the wrong citation, and it is load-bearing.** It appears in the commit
message, in Decision 38 (*"as `pong` already does"*) and in the RETIRED entry (*"as
`pong/main.lua:104` does"*), each time as the evidence that projects already convert numbers
themselves. `src/examples/pong/main.lua:95` defines pong's **own** local
`set_text(name, str)` — a `gfx.newText` wrapper for on-screen labels. It has no connection to
`compy.input.set_text`; the two share a name and nothing else. A reader who follows the citation
finds a different function. Under `conventions/docs.md` citation hygiene this should be dropped or
replaced with a real `compy.input` call site — and none exists, which is itself the honest finding
(no in-tree project passes a number to `compy.input.set_text` in either direction).

**e. ROADMAP presentation.** `ROADMAP.md:641`: the `BUG-02-02` row is separated from the table above
by a blank line, so it renders as its own one-row table rather than joining `BUG-02-01`'s. It is
also the only ✅ row in the section not struck through (`~~**BUG-02-02**~~`), unlike `BUG-02-01`,
`BUG-01-08` and `BUG-01-09` immediately around it. Cosmetic, both.

### 8. Rules compliance — **clean on the hard limits; three small annotation/style points.**

Every added line, in both files, is **≤ 64 characters** (measured as characters, not bytes — the
`awk`-length hits in this file are all pre-existing em-dash lines). Function bodies:
`checked_text` 11 lines, `api_set_text` 6, `api_show` 9 — all under 14. `api_set_text` takes
**exactly 4 parameters** — at the limit, not over it, confirmed. `lua-lsp diagnostics` on the file:
clean.

- Nesting in `checked_text` reaches `function → if → for → if`. Whether that is 4 or 5 depends on
  whether the function body counts as a level; either way it is the deepest helper in this
  neighbourhood (`check_keys` is 3, `checked_cursor` is 2) and the rule says to redesign when a
  limit is *approached*. An early-return formulation is flatter and also drops the pointless full
  scan — the loop has no `break`, so it keeps walking a 20 000-element list after the first bad
  element.
- `--- @param get_active fun(): table?` (`:805`) is **wrong**: the resolver is
  `function() return w and w:is_shown() end` (`:954-957`) and `UserInputController:is_shown`
  (`userInputController.lua:507`) is `--- @return boolean`. This is copied from `api_set_cursor`,
  which has the same error — but it is a *new* wrong annotation added by this commit, not merely an
  inherited one.
- `--- @return str? text` (`:719`): `str` is `string|string[]`
  (`src/util/string/string.lua:4`), but the function returns whatever table it was given, including
  the map- and hole-shaped tables of item 1. Imprecise rather than wrong.

The comments themselves pass `rules/commenting.md`: `checked_text`'s block carries intent plus a
Decision-38 pointer (payload 2) and does not reproduce what it points at; `api_set_text`'s carries a
prohibition on future edits (payload 1), which is exactly the right shape — and is the only thing
protecting the depth rule, given item 6 shows no test does.

### 9. Is refusing right at all? — **The conclusion is right. The stated argument is not.**

I tried to break the coercion case and could not: no in-tree example passes a non-string
(`maze/core_editor.lua:70` and `tixy/main.lua:188` pass `string.lines(...)`, which only ever emits
strings; `tixy/main.lua:39` passes a string body; everything else passes a literal), so **refusing
breaks no shipped example**. And `set_text{1, 2, 3}` has no realistic constituency I can construct:
`text` is documented as line strings, the widget is an *editor* the user then types into, and a
project that renders a score already has `tostring` one character away. Refusing is the right call.

But the argument written into Decision 38 and the ledger does not support it. It rests on
`{'a', 42}` matching `UserInputModel:insert_text_line(text, li)`, *"so the likeliest way a project
builds one is by confusing two functions"*. `insert_text_line` is a **`UserInputModel` method**
(`userInputModel.lua:219`). It is not on `compy.input` — the surface is
`show / hide / is_shown / get_cursor / set_cursor / set_text / configure / clear` — it appears
nowhere in `doc/input_api.md`, and a project's sandboxed `love` cannot reach the model. A project
author cannot confuse `set_text` with a function they have never seen and cannot call. The one
category of caller that *could* make that confusion — framework-internal code — bypasses
`checked_text` entirely (item 2). So the justification names a mistake that is impossible at the
boundary where the check sits.

The honest argument is simpler and survives scrutiny: **the contract is documented and closed, and
a value outside it can only be a mistake — so say so instead of guessing.** That is the same
sentence `BUG-01-08` used for `cursor`, and it needs no `insert_text_line` story. I recommend
replacing the rationale in Decision 38, since a design document outlives the row and this reasoning
will be cited later.

One consistency point on the shape of the refusal, not the decision: the hidden guard runs
**before** the check (`:809-812`), so `set_text({'a', 42})` on a hidden widget warns
*"compy.input.set_text ignored — hidden"* and does not raise. Whether an authoring error is
reported depends on widget state. `api_set_cursor` has the identical ordering, so the change is at
least consistent with the house — but *"a malformed value on the public surface earns one message"*
is not what the code does when the widget is down.

---

## Findings, most severe first

**F1 — DEFECT. A list with a hole or with hash keys slips through, and both silent symptoms
survive.** `checked_text:725` and `normalized_lines:151` both use `ipairs`. `t[1]='a'; t[3]=42`
→ accepted, `42` **dropped**, content silently becomes `{'a'}`, through `set_text` *and* through
`show`. `{foo = 42}` → accepted, content **wiped** to `{''}`, `is_empty()` true. These are the drop
and the wipe the row exists to eliminate. Reachable in one line of ordinary project code (a `pairs`
loop building a line list). *Recommend:* refuse any table that is not a dense array of strings, and
bring `normalized_lines` to the same rule; add the hole and the map to the test table.

**F2 — OVERCLAIM (documentation, reader-facing).** `doc/input_api.md:217` *"Every element must be a
string, and a list containing anything else is refused"* and `technical_debt/input.md:1381`
*"refuses any `text` that is not a string or a list of strings"* are both false given F1. A project
author is told a guarantee they do not have. *Recommend:* fix F1 and keep the wording, or weaken the
wording now.

**F3 — OMISSION. `show{text = false}` changed meaning, silently.** From "leave the previous content
standing" (`9d5cbd41^`) to "clear the field" (`9d5cbd41`), via `checked_text`'s falsy→`nil` and
`reset_content`'s `cfg.text == nil` test. The new behaviour is correct per Decision 35 statements 1
and 3 — but it is a public behaviour change with no CHANGELOG line, no ledger line, no guide line
(`input_api.md:133` still omits `text` from the `false`-unsets list), and no test. *Recommend:*
one guide sentence, one CHANGELOG bullet, one test. Per the standing rule, an accepted behaviour
change belongs in the workspace, not only in a diff.

**F4 — OVERCLAIM (CHANGELOG, factual).** *"Previously such a value died inside the framework with
`bad argument #1 to 'len'`"* is written against the last release, but `sanitize_utf8` — the raise
site — is unreleased (`945a5d1d`, not an ancestor of base `0022004e`; absent from
`0022004e:src/model/input/userInputModel.lua`). Same paragraph: *"a boolean ... now raises"* is
false for `false`. *Recommend:* state what the base actually did, or drop the "previously" clause
and describe the new contract only — the surface is itself new in `CURRENT_SCOPE`, so a stakeholder
of the last release has no prior behaviour to be told about.

**F5 — OVERCLAIM (Decision 38, a permanent design document).** *"a malformed value on the public
surface earns one message ... never a raw Lua error from inside the framework and never a silent
repair."* Only `text` and `cursor` are checked; `show{on_text_entered = 42}` and
`show{validator = 42}` are accepted and produce raw framework errors at
`userInputController.lua:437` and `:417`. *Recommend:* scope the sentence to `text` and `cursor`, or
open a row for the remaining keys.

**F6 — WRONG CITATION, repeated in three places.** `pong/main.lua:104` calls pong's own
`gfx.newText` helper defined at `pong/main.lua:95`, not `compy.input.set_text`. Cited in the commit
message, Decision 38 and the RETIRED entry as evidence for the coercion argument. *Recommend:*
delete it; there is no in-tree instance, and saying so is stronger than a name collision.

**F7 — WEAK RATIONALE.** The `insert_text_line` confusion story is unreachable from the project
boundary (item 9). The conclusion (refuse) is right; the reasoning in Decision 38 should be replaced
before it is cited downstream.

**F8 — OMISSION (test coverage).** `error(…, 4)` → `error(…, 3)` leaves the suite green: the depth
rule that is the *sole* justification for `api_set_text`, `api_set_cursor` and `api_configure` is
untested anywhere in `tests/`. The `show` case also does not pin the message body. *Recommend:* one
test that loads a named chunk and asserts the `file:line` prefix — it would cover all four raises at
once.

**F9 — ENVIRONMENT NOTE, not a defect.** `ipairs` is raw in Lua 5.1 and LuaJIT but honours
`__index` from 5.2 on, so a proxy table (`setmetatable({}, {__index = list})`) is accepted-and-wiped
here and would be read through on PUC 5.3/5.4. `checked_text` and `normalized_lines` use the same
iterator, so they never disagree on either interpreter and no unsound state results. The project's
stated floor is PUC Lua 5.1, where behaviour matches this container. F1 is unaffected — `ipairs`
stops at a `nil` in every version.

**F10 — STYLE.** (a) `@param get_active fun(): table?` at `:805` should be `boolean?`
(`is_shown` is `@return boolean`) — a new wrong annotation, copied from an old one. (b) `@return
str?` at `:719` does not describe what the function can return. (c) The scan has no `break`.
(d) `checked_text` nests to the limit where a flat early-return reads better. (e)
`ROADMAP.md:641` — the new row is detached from its table by a blank line and is the only ✅ row in
the section without strikethrough.

---

## What I could not check

- **`lua-lsp` `references`** — broken pipe on every attempt (`diagnostics` worked). Items 2 and 3's
  caller enumeration is grep plus a manual read, not AST references. On dynamically-dispatched Lua
  that is a real gap: a caller reached through a table field or a computed name would not appear.
- **PUC Lua** — not installed in this container (`lua: command not found`); everything above is
  LuaJIT 2.1. F9 states where that could matter. No suite claim here is a claim about the owner's
  interpreter.
- **Behaviour at the PR base for `{'a', 42}`** — `src/util/string` is a submodule at `0022004e`
  (`160000 commit ff9be4b9`) and is not checked out at that revision, so I could not run base
  `string.split_array` to establish what a last-release caller actually saw. What I *can* establish
  is negative and is enough for F4: `sanitize_utf8` did not exist there.
- **On-screen rendering** — no display; content was read through `F.widget:get_text()` and
  `is_empty()`, not from the draw path.
- **The 10 pending tests** — taken as the stated owner ruling, not re-litigated.

Probe specs written under `tests/input/` for this review have been deleted; `git status` shows the
tree unchanged apart from this file, and `busted tests` is back to **1043 / 0 / 0 / 10**.
