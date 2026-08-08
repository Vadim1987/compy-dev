# S29 — revalidation of session28's two production fixes

Cold review, read-only apart from the deliverable and two immediately-restored
mutation checks. Branch `feature/77-newapi-analysis-s20260615`, HEAD
`d8a15f04`. Baseline: `busted tests` → 954 successes / 0 failures / 0 errors /
3 pending (confirmed before starting).

---

## Fix 1 — net of `8fbcba21` + `811849e2`

### Claim: the defect was real and reproducible

**CONFIRMED**, by mutation (not by trusting the commit).

`8fbcba21`'s own diff shows the pre-fix `dispatch()` in
`projectInputController.lua`:
```lua
if widget and widget:is_shown() then
    widget[event](widget, ...)
    return true
end
```
called unconditionally, and the same commit's diff shows `userInputController.lua`
had no `singleclick`/`doubleclick` methods before it added them. Rather than
trust that reading, I reproduced it directly at HEAD:

- Backed up `src/controller/userInputController.lua` to
  `/tmp/claude-1000/-repo/7df95d55-3cb7-48c8-9fcc-af9f345cc2ac/scratchpad/backups/userInputController.lua.orig`
  (md5 `0305a8d448debd48646dbcd2c3200b07`).
- Deleted the `singleclick`/`doubleclick` no-op methods (lines 833–841,
  including their comment) from `userInputController.lua`.
- `busted tests --filter="a click at a shown widget does not kill the run"`:
  ```
  ERROR: Error: L138:attempt to call a nil value
  ...
  ./src/controller/projectInputController.lua:138: in function <...>
  ...
  0 successes / 1 failure / 0 errors / 0 pending
  Failure -> ... a click at a shown widget does not kill the run
  tests/input/input_events_spec.lua:954: Expected objects to be the same.
  Passed in:    (string) 'snapshot'
  Expected:     (string) 'running'
  ```
  This reproduces exactly what the commit describes: a nil call at
  `projectInputController.lua:138`, swallowed by the route's error boundary,
  `app_state` left at `'snapshot'` instead of `'running'`.
- Full suite with the mutation still in place: `953 successes / 1 failure / 0
  errors / 3 pending` — **only** the named row failed, nothing else.
- Restored from the `/tmp` copy (not `git checkout`), confirmed identical by
  `md5sum` (`0305a8d448debd48646dbcd2c3200b07` both sides), `git status
  --porcelain` and `git diff --stat` empty for the file, and `busted tests`
  back to 954/0/0/3.

### Claim: "Not pre-existing"

**CONFIRMED.**

`git show 3256aac:src/controller/projectInputController.lua` → `fatal: path
... exists on disk, but not in '3256aac'` — the file did not exist at the PR
base at all.

`git grep -n "singleclick" 3256aac -- src/` shows the only production hits at
base were:
```
3256aac:src/controller/controller.lua:150:    singleclick = function() end,
3256aac:src/controller/controller.lua:349:          local handler = CC:get_compy_handler('singleclick')
```
Read in context (`git show 3256aac:src/controller/controller.lua` around line
349), the click timer at base resolved `CC:get_compy_handler('singleclick')`
directly — a straight project-handler lookup, no widget tier, no `dispatch()`
walk, nothing that could call `widget[event]`. The claim holds: there was
no widget participation in clicks at all at `3256aac`, so the branch created
the code path that the defect lives in. (Per the brief's warning that this
exact claim shape has been overturned before, I did not stop at the commit's
assertion — I independently confirmed the file's non-existence and read the
base click-handling code myself.)

### Claim: the surviving test row still discriminates

**CONFIRMED** — this is the same mutation as above, re-stated because
`811849e2`'s message makes the claim explicitly for the row that *survived*
its own deletion of the other row. The result: deleting the two no-ops (not
just blanking their bodies, but removing them entirely) makes **exactly**
`'a click at a shown widget does not kill the run'` fail, with the precise
failure mode (nil call → `'snapshot'`) the commit describes, and no other row
moves. This is a proof, not a pin: the row's assertions
(`assert.same(1, seen)` and `assert.same('running', love.state.app_state)`)
are sensitive to the actual defect being reintroduced, not merely to the
methods' existence.

### Claim: completeness — the widget implements every EVENTS channel

**CONFIRMED**, but the state has changed since the commit's own list, and the
commit's phrasing ("except singleclick/doubleclick") is only true of the
pre-fix tree, not HEAD.

`EVENTS` at `src/controller/projectInputController.lua:34-39`:
```lua
local EVENTS = {
  'keypressed', 'keyreleased', 'textinput',
  'mousepressed', 'mousereleased', 'mousemoved', 'wheelmoved',
  'touchpressed', 'touchreleased', 'touchmoved',
  'singleclick', 'doubleclick',
}
```
12 entries. `grep -n "^function UserInputController:" src/controller/userInputController.lua`
gives (channel-relevant subset): `keypressed`, `textinput`, `keyreleased`,
`mousepressed`, `mousereleased`, `mousemoved`, `wheelmoved`, `singleclick`,
`doubleclick`, `touchpressed`, `touchreleased`, `touchmoved` — all 12,
one-for-one, no gaps and no extras beyond the channel names (the other
`UserInputController:*` methods are non-channel widget API, e.g.
`is_shown`, `show`, `configure`). At HEAD the widget implements every channel
`EVENTS` names; there is no unimplemented channel left for the defect to hide
behind today. This was checked by direct enumeration and comparison, not by
trusting the commit's "except singleclick/doubleclick" list (which describes
the pre-8fbcba21 state, correctly, but is stale for HEAD).

---

## Fix 2 — `493c3cbe`

### Claim: "Call sites audited, all of them"

**CONFIRMED for direct call sites; UNCLEAR/FINDING on one adjacent point**
(see below). Method used: grep across `src/` and `tests/` for
`.keypressed(`/`:keypressed(`/`.keyreleased(`/`:keyreleased(`, cross-checked
with the `lua-lsp` MCP `references` tool.

Grep results for direct calls on a `UserInputController` (widget) instance:

- `src/controller/consoleController.lua:1497: input:keypressed(k)` — single
  arg, `input` = `self.input`, a `UserInputController` (confirmed by reading
  `ConsoleController.new`, `local IC = UserInputController(M.input):always_shown()`).
- `src/controller/editorController.lua:808: input:keypressed(k)` — single
  arg, same reasoning (`input = UserInputController(M.input, true, true):always_shown()`
  at `editorController.lua:12`).
- `src/controller/consoleController.lua:1522: self.input:keyreleased(k)` —
  single arg. (`editorController.lua` has **no** `keyreleased` call on the
  widget at all — confirmed by grepping the file; only `keypressed` is
  forwarded there.)
- The generic dispatch site, `src/controller/projectInputController.lua`'s
  `channel()` installer (line ~184): `widget[event](widget, ...)` forwards
  whatever LÖVE's own arguments were for every `EVENTS` entry, including
  `keypressed`/`keyreleased`.
- `src/controller/searchController.lua:81` has its own `SearchController:keypressed(k)`
  but never calls `self.input:keypressed(...)` — it manipulates
  `self.model.input` directly (`:backspace()`, `:delete()`), so it is not a
  widget call site at all. Checked by reading the full method body
  (lines 79-139).

No other direct `widget:keypressed(...)`/`widget:keyreleased(...)` call
sites exist in `src/` or `tests/` beyond the ones named in the commit plus
the one generic dispatch site. This matches the commit's claim.

**LSP cross-check, and where it was thin (the brief's predicted failure
mode, reproduced in practice):**
`mcp__lua-lsp__references` on `UserInputController.keypressed` and
`UserInputController.keyreleased` resolved to references of the
**constructor** `UserInputController(...)` (class instantiation sites), not
the methods — not useful for this question. Querying the bare method names
`keypressed` / `keyreleased` was worse: the tool returned a blend of
unrelated definitions sharing the same string name across different classes
(`ConsoleController:keypressed`, `love.keypressed`/`love.keyreleased` the
global, `Controller._defaults.keypressed`), with duplicated/repeating blocks
in the output, and never isolated `UserInputController:keypressed` /
`:keyreleased` specifically as a distinct symbol. It also referenced a
transient LSP scratch file
(`tests/input/input_widget_callbacks_spec.lua.tmp.38374.929c607ffcc0`) that
does not exist on disk — an artifact of the language server's own tooling,
not a repository file. This is exactly the "thin on dynamically-dispatched
methods" failure the brief warned about: for a method name shared across
several unrelated tables, the LSP's `references` query does not disambiguate
by receiver type, so grep (which I did first and treated as primary) was the
tool that actually resolved this claim; the LSP corroborated the two named
sites (`controller.lua:545 CC:keypressed(k)`, `controller.lua:913
love.keyreleased(k)`) but added no call site grep had not already found, and
could not be used alone to certify completeness.

### Finding: `keyreleased`'s "`sc` names LÖVE's second argument" is imprecise for the actual production wiring

**FINDING, low severity.** The commit's rationale states "Same for
`keyreleased(k)`, whose second LÖVE argument is also the scancode," implying
`sc` in `UserInputController:keyreleased(k, sc)` is bound to a real scancode
value the same way `keypressed`'s `sc` is. Tracing the actual event-pump
wiring in `src/controller/controller.lua:905-915`:
```lua
handlers.keyreleased = function(k)
  Controller.keys_pressed[k] = nil
  ...
  if love.keyreleased then
    return love.keyreleased(k)
  end
end
```
This is `love.handlers.keyreleased` (`local handlers = love.handlers` at
line 785), the real LÖVE event-pump entry point. It declares only `k` — no
`...`, no second parameter — so whatever scancode LÖVE's own event supplies
is dropped **before** `love.keyreleased` (whichever route currently owns it,
console default or the project route via `occupy_input`'s
`love[k] = ... pic[k](pic, ...)`) is ever called. This holds regardless of
which route is active, because `handlers.keyreleased` is the single
choke point both routes are called through. Independent corroboration:
`tests/helpers/input_session.lua:21`, `release = function(k) h.keyreleased(k) end`
— the test session driver itself only ever exercises `keyreleased` with one
argument, matching this. By contrast `keypressed`'s wrapper at
`controller.lua:787` is `function(k, sc, isr) ... love.keypressed(k, sc, isr) end`
and correctly forwards all three.

Net effect: `sc` in `UserInputController:keyreleased(k, sc)` is not merely
*unread* (as the commit's "tail is unread" claim states, and which is true
and sufficient for "behaviour is unchanged") — via the real production event
path it is **always `nil`**, never a real scancode, because it is stripped
one layer above the widget rather than merely ignored by the widget. This
does not contradict "behaviour is unchanged by construction" (still true,
trivially, since nothing reads `sc` either way) and does not reopen the
original bug (`keyreleased` had no live use of its second argument before or
after). It does mean the doc comment added at
`userInputController.lua:721` ("`sc` string? scancode; LÖVE's second
argument, unread") slightly overstates what actually reaches this parameter
today; it should probably say "never populated in production" rather than
imply it merely goes unread. Reporting as found, not fixing.

### Claim: "Behaviour is unchanged by construction — the tail is unread"

**CONFIRMED**, independent of the finding above.
```
awk 'NR==491,NR==701' src/controller/userInputController.lua | grep -n "\bisr\b\|\bsc\b"
→ 1:function UserInputController:keypressed(k, sc, isr)
awk 'NR==722,NR==745' src/controller/userInputController.lua | grep -n "\bsc\b"
→ 1:function UserInputController:keyreleased(k, sc)
```
In both cases the only occurrence of `sc`/`isr` in the full method body is
the signature line itself — grep over the body finds no other reference.
Confirmed by reading both full method bodies
(`keypressed`: lines 491-701; `keyreleased`: lines 722-745) directly as well,
not just by grep.

### Claim: "No new row" — `the widget receives the uniform keypressed arguments` already pins the triple

**CONFIRMED, with a scope caveat worth recording.**
`tests/input/input_events_spec.lua:869-882`:
```lua
it('the widget receives the uniform keypressed arguments', function()
  local seen
  F.activate_project()
  F.show_widget()
  F.widget.keypressed = function(_, k, sc, isr)
    seen = { k, sc, isr }
  end
  F.session.handlers.keypressed('a', 'scan-a', true)
  F.widget.keypressed = nil
  assert.same({ 'a', 'scan-a', true }, seen)
end)
```
`F.widget` (`tests/helpers/input_fixture.lua:132-138`) is a real
`UserInputController` instance, but this row **overrides**
`F.widget.keypressed` with a capturing stub before firing the event, so it
tests the *chain's* delivery of the full LÖVE triple to whatever object is
plugged in as the widget — it does not exercise
`UserInputController:keypressed`'s own body at all. That is a legitimate
justification for "no new row": since fix 2 changed only the widget's own
parameter *names*, not the chain's delivery contract, a row that already
proves the chain hands the widget `(k, sc, isr)` is exactly the row that
needs no counterpart to cover a naming-only change. It does not, and was
never claimed to, pin that the renamed parameters inside
`UserInputController:keypressed`'s body are unread — that half is covered
by the "tail is unread" grep/read above, not by this row. Read in full and
judged accurate for what it is actually being used to justify.

---

## Closing

1. **Fix 1's defect is fixed at HEAD, and the guarding row is a proof, not a
   pin.** Mutation-checked directly: deleting the `singleclick`/`doubleclick`
   no-ops from `userInputController.lua` at HEAD reproduces the exact
   original failure (`attempt to call a nil value` at
   `projectInputController.lua:138`, `app_state` `'snapshot'` instead of
   `'running'`), and reproduces it in **only** the row
   `'a click at a shown widget does not kill the run'` — the rest of the
   953-row remainder stayed green. Restored from a `/tmp` copy, confirmed
   byte-identical by `md5sum`, `git diff --stat` empty, suite back to
   954/0/0/3.
2. **Fix 2's call-site audit is exhaustive for direct calls on the widget,
   established by grep** (`.keypressed(`/`:keypressed(`/`.keyreleased(`/`:keyreleased(`
   across `src/` and `tests/`, then manually confirming each hit's receiver
   type by reading the constructing code). The `lua-lsp` MCP `references`
   tool was tried first as the brief specifies but was **not usable** for
   this specific question: queried on the qualified method name it resolved
   to constructor-call references instead; queried on the bare method name
   it blended unrelated same-named methods from other classes and the
   `love.*` globals without disambiguating by receiver, exactly the
   "thin on dynamically-dispatched methods" risk the brief flagged. What
   grep-plus-manual-receiver-checking could still miss: a call reached only
   through a metatable/dynamic dispatch table that does not literally spell
   `keypressed(`/`keyreleased(` in source (e.g. built from a string key at
   runtime) — no such pattern was found, but grep cannot prove its absence
   the way an exhaustive dynamic trace could.
3. **What came back clean:** the full suite before and after both mutation
   checks (954/0/0/3 baseline, restored to 954/0/0/3 both times, with only
   the intended row moving under mutation); the "not pre-existing" claim
   against the actual PR-base tree (`git show 3256aac:...`, file absent,
   base click handling read directly); the EVENTS-vs-widget-methods
   completeness enumeration (12/12, no gaps, no extras); the "tail is
   unread" claim for both `keypressed` and `keyreleased`, checked by grep
   over each method body and by reading both bodies in full; and the "no new
   row" row itself, read in full and judged to support what it is cited for.
   The one thing that did **not** come back clean is recorded above as a
   finding (low severity, no behavioural consequence): `keyreleased`'s `sc`
   is not just unread but is never populated with a real scancode by this
   codebase's production event-pump wiring, which makes the commit's
   "second LÖVE argument is also the scancode" phrasing for `keyreleased`
   slightly inaccurate as a description of what actually reaches the
   parameter, though the "behaviour is unchanged" conclusion it supports
   still holds.

**Tree state:** `git status --porcelain` at the end shows only the
pre-existing untracked owner scratch (`claude.sh`, `src/STEPS.md`,
`input-pr-slices.tar.gz`, `doc/tall_blocks.md`,
`doc/development/wip/clarification/`, `doc/development/wip/personal-notes/`,
`doc/development/wip/pull-26/`, the three `src/examples/*` nested repos) plus
this deliverable and the prompt file that was already present at start of
session; `git diff --stat` is empty (no tracked file differs from HEAD). The
mutation to `src/controller/userInputController.lua` was restored from the
`/tmp` backup and verified byte-identical by `md5sum` before and after.
