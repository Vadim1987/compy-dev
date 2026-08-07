# S27 — remark inventory (mechanical extraction)

Extracted 2026-08-07 from the owner's code-review commits on feature #77
("new input API"): main repo `9cc0ef50`, plus `77fa43b1`/`5f3078f3`/`c6a0778f`
(checked — no in-scope annotations; `77fa43b1`/`5f3078f3` touch only
`doc/development/wip/`, `c6a0778f` is a test bugfix with no annotations), and
the three nested example repos' review commits (`cb1dd26` balloons, `aeabb73`
maze, `6eb7919` keyboard). HEAD at extraction time: `c6a0778f`. Line numbers
are `file:line` as of that HEAD; no file in scope was touched again after its
review commit, so diff line numbers and working-tree line numbers coincide.

This is a mechanical, read-only extraction. No severity, priority, or
correctness judgement is made here — see Part 3 for facts-only observations.

---

## Part 1 — Summary

**Total remarks found: 187.**

### By marker form

| Form | Count | Notes |
|---|---|---|
| `REMARK:` (and `REMARK` with no colon) | 178 | dominant form, `--> REMARK:` / `---> REMARK:` in Lua, `> REMARK:` in Markdown |
| `REMARKS:` (plural typo) | 1 | `src/controller/userInputController.lua:15` |
| `REMARK/nitpick` | 1 | `doc/development/internals/event_dispatch_layers.md:106` |
| `REMARK/SUMMARY` | 1 | `doc/development/decisions/input.md:426` |
| `REMARL:` (typo, missing K) | 1 | `src/model/input/userInputModel.lua:840` |
| `REVIEW:` | 2 | both in `doc/development/technical_debt/input.md` |
| unmarked (bare comment, no marker word) | 6 | see below |

178+1+1+1 = 181 lines matched a literal `REMARK` substring; add the 1 `REMARL`
typo (misses the substring) and the 2 `REVIEW:` lines = 184 marker-bearing
lines. The remaining **3 entries / 6 lines** are unmarked bare comments added
by the same review commits, identified by diffing added lines with no marker
keyword at all — the task instructions explicitly warned these might exist,
and they do:

- `src/controller/controller.lua:528` — `---> comment describing what code does NOT do is absolutely of no use; delete if it has no positive info`
- `tests/editor/editor_spec.lua:488-489` — two-line remark, no marker word
- `tests/input/input_events_spec.lua:241` — `-->  these things are called 'test cases', not vague 'rows'`

No other marker forms (`TODO`, `FIXME`, `QUESTION`, `NOTE:`, `XXX`, `???`,
`!!`) were added by any of the review commits — confirmed by diffing added
lines against each pattern; all hits for those patterns elsewhere in the tree
predate this review and are unrelated (mostly the vendored `src/lib/metalua`
library).

Two remarks span two comment/blockquote lines each (reproduced as one entry,
full text): `src/examples/balloons/terminal.lua:4-5` and
`doc/development/internals/user_input.md:24-25` (the second line of the pair
has no marker of its own — it is a direct continuation, a suggested
replacement sentence, immediately following with no blank line).

### By area

| Area | Files | Remarks |
|---|---|---|
| `src/` (excl. nested examples) | 5 | 46 |
| `tests/` | 15 | 33 |
| `doc/` (permanent, excl. `wip/`) | 15 | 102 |
| `agents/` | 0 | 0 (see Part 3 — a new file was added here, but it carries no remark) |
| `CHANGELOG.md` | 1 | 1 |
| `src/examples/balloons` (nested repo) | 1 | 1 |
| `src/examples/maze` (nested repo) | 1 | 2 |
| `src/examples/keyboard` (nested repo) | 1 | 2 |
| **Total** | | **187** |

### Dense clusters (5+ remarks in one file)

- `doc/development/internals/user_input.md` — **37** remarks (by far the densest file)
- `doc/development/decisions/input.md` — **36** remarks
- `src/controller/consoleController.lua` — **20** remarks
- `src/controller/controller.lua` — **14** remarks
- `doc/input_api.md` — **11** remarks
- `src/controller/userInputController.lua` — **7** remarks
- `tests/input/input_events_spec.lua` — **6** remarks

### Skipped (out of scope)

`doc/development/wip/` was excluded per instructions. It contains **17**
`REMARK` hits (5 files: session24/session27 `track.md`, this very prompt
file, and two `S24-*` review docs) and **274** `REVIEW:` hits (used
throughout the wip corpus as a template/section-header term, not as an
owner-inline-annotation marker) — none extracted, none further inspected
beyond confirming they are historical/template, not this review's remarks.

---

## Part 2 — The Inventory

### src/

#### R001 — `src/controller/consoleController.lua:134`

> ---> REMARK: comment does not match code and is too verbose

**Context:**
```lua
---> REMARK: comment does not match code and is too verbose
-- Project lifecycle callback. It is intentionally separate from
-- compy.input's keyboard/text dispatch surface. Declared up
-- here with hide_overlay because both ends of a run reset it:
local function default_before_exit()
```

**Asks for:** fix the doc-comment above `default_before_exit` — it does not
match what the code does, and is too verbose.

**Provisional kind:** prose

---

#### R002 — `src/controller/consoleController.lua:143`

> ---> REMARK: word 'overlay' is strongly opposed. if its needed in console context (the only context where its meaningful), let use something like 'input_widget_overlay'

**Context:** attached to the doc-comment above the function that hides the
overlay through the widget when a project run ends (`hide_overlay`-adjacent
code, lines 145-154).

**Asks for:** stop using the word "overlay"; if it is still needed in console
context, use a more specific name such as `input_widget_overlay`.

**Provisional kind:** prose

---

#### R003 — `src/controller/consoleController.lua:144`

> ---> REMARK: too verbose comment. just briefly tell in which contexts function is supposed to be invoked instead of reexplaining how it works (prose length is x5 longer than code length!)

**Context:** same location as R002 — the doc-comment for the "take the
overlay down through the widget" function.

**Asks for:** shorten the same comment: state only the invocation context,
not a re-explanation of the mechanism; the comment is ~5x the length of the
code it documents.

**Provisional kind:** prose

---

#### R004 — `src/controller/consoleController.lua:402`

> ---> REMARK: need more explicit name e.g. 'unassignable_error', 

**Context:**
```lua
---> REMARK: need more explicit name e.g. 'unassignable_error', 
--- @param k any
local function frozen_error(k)
```

**Asks for:** rename `frozen_error` to something more explicit, e.g.
`unassignable_error`.

**Provisional kind:** mechanical

---

#### R005 — `src/controller/consoleController.lua:415`

> ---> REMARK: setting __index is redundant, because its trivial?

**Context:** inside `build_shortcuts_surface`'s `setmetatable` call — the
`__index` entry simply returns `shortcuts[event]`.

**Asks for:** questions whether the `__index` metamethod in
`build_shortcuts_surface` is needed at all, since it looks trivial.

**Provisional kind:** question

---

#### R006 — `src/controller/consoleController.lua:427`

> ---> REMARK: whole function is redundant because its trivial? (literally setting __index and __newindex to their default behaviour!)

**Context:** immediately above `build_leaf_surface`, which sets `__index`/
`__newindex` to pass-through read/write on `store`.

**Asks for:** questions whether `build_leaf_surface` is needed at all, since
it just reproduces default table read/write behaviour.

**Provisional kind:** question

---

#### R007 — `src/controller/consoleController.lua:435`

> ---> REMARK: fix prose -- not "where the event GOES" but "whether event PROPAGATES by returning hardcoded true/false"

**Context:** attached to the doc-comment above `INPUT_FN` describing
`ignore_repeat`/`stop_here`/`side_run` ("...decide where the event GOES...").

**Asks for:** correct the doc-comment's wording: the combinators decide
whether the event propagates (by returning a hardcoded true/false), not
"where it goes."

**Provisional kind:** prose

---

#### R008 — `src/controller/consoleController.lua:436`

> ---> REMARK: why not shorter form? e.g. 'fn and fn(...);return false;' ? its one-off, very straight wrappers

**Context:** same `INPUT_FN` doc-comment block, referring to the
`ignore_repeat`/`stop_here`/`side_run` combinator implementations below.

**Asks for:** questions whether the combinators could be written as a
shorter one-line form instead of the current multi-line closures.

**Provisional kind:** question

---

#### R009 — `src/controller/consoleController.lua:437`

> ---> REMARK: if we drop the 'keys' parameter (therefore unifying shorcuts/hooks signature with love.*), ignore_repeat should be updated

**Context:** same `INPUT_FN` doc-comment block, above the `ignore_repeat`
implementation which reads `(k, keys, isr)`.

**Asks for:** flags a downstream consequence — if the `keys_pressed`
parameter is dropped from shortcut/hook signatures elsewhere (per other
remarks), `ignore_repeat`'s own signature needs updating too.

**Provisional kind:** architectural

---

#### R010 — `src/controller/consoleController.lua:444`

> ---> REMARK: what you mean by 'reserved binding'? Its maybe 'recommended' or 'often used'?

**Context:**
```lua
---> REMARK: what you mean by 'reserved binding'? Its maybe 'recommended' or 'often used'?
--- A reserved binding is `stop_here(ignore_repeat(fn))`.
local INPUT_FN = {
```

**Asks for:** questions the meaning/wording of "reserved binding" in the
comment above `INPUT_FN`; suggests "recommended" or "often used" instead.

**Provisional kind:** question

---

#### R011 — `src/controller/consoleController.lua:475`

> ---> REMARK: why set '__index' if its trivial

**Context:** above `input_fn_surface`'s `setmetatable` call, whose `__index`
just returns `INPUT_FN[k]`.

**Asks for:** questions whether the `__index` metamethod on
`input_fn_surface` is needed, since it looks trivial.

**Provisional kind:** question

---

#### R012 — `src/controller/consoleController.lua:476`

> ---> REMARK: we have characteristical 'frozen write' metatable, why not use class instead of repeating same setmetatable three times?

**Context:** same location as R011 — `input_fn_surface`'s construction,
following the pattern already used for `build_shortcuts_surface` and
`build_leaf_surface`.

**Asks for:** proposes factoring the repeated "frozen write" metatable
pattern into a class/helper instead of writing `setmetatable` three times.

**Provisional kind:** architectural

---

#### R013 — `src/controller/consoleController.lua:513`

> ---> REMARK: lets respect the vocabulary. these things are called *callbacks*.

**Context:**
```lua
---> REMARK: lets respect the vocabulary. these things are called *callbacks*.
-- The four widget-output entries (doc/development/decisions/input.md,
-- Decision 5):
local OUTPUT_KEYS = {
```

**Asks for:** rename/relabel `OUTPUT_KEYS` (or its surrounding comment
vocabulary) to say "callbacks" rather than "widget-output entries."

**Provisional kind:** prose

---

#### R014 — `src/controller/consoleController.lua:529`

> ---> REMARK: why "pending"? need better name. like 'configure-only'? not sure about 'cursor' -- aren't we using set_cursor/get_cursor? not sure what 'cursor' ever means and how its used -- is it?

**Context:** above `PENDING_KEYS = { 'prompt', 'text', 'cursor' }`.

**Asks for:** questions the name `PENDING_KEYS` (proposes e.g.
`configure-only`) and separately questions what the `cursor` pending key
means/does relative to `set_cursor`/`get_cursor`.

**Provisional kind:** question

---

#### R015 — `src/controller/consoleController.lua:535`

> ---> REMARK: why dupicate key names instead of assembling from two tables above?

**Context:** above `SHOW_KEYS`, whose entries (`prompt`, `text`, `cursor`,
`force`, `highlighter`, `validator`, `on_text_entered`, `on_limit_reached`)
duplicate names already present in `OUTPUT_KEYS`/`PENDING_KEYS`.

**Asks for:** proposes assembling `SHOW_KEYS` from `OUTPUT_KEYS` and
`PENDING_KEYS` instead of re-listing the key names.

**Provisional kind:** mechanical

---

#### R016 — `src/controller/consoleController.lua:549`

> ---> REMARK: why two distinct tables 'SHOW_KEYS' and 'CONFIGURE_KEYS' if they are identical by shape and content?

**Context:** above `CONFIGURE_KEYS`, built by copying `SHOW_KEYS` and
deleting `force`.

**Asks for:** questions why `SHOW_KEYS` and `CONFIGURE_KEYS` exist as two
separate tables when one is derived from the other.

**Provisional kind:** question

---

#### R017 — `src/controller/consoleController.lua:640`

> ---> REMARK: major flaw in recent changes across this file is: a) there's too much boilerplate and copypaste for functions that merely do one simple sing (validation and rejection of config keys in various contexts) b) real load-bearing functions are simply lambdas inside moster block (build_widget_api) -- I'd rather extract show and hide here into first-class functions, and reference them from api dictionary -- its much more readable (also why not define them in separate file at all?)

**Context:** above the "Builds the compy.input surface" comment block, just
before the main dispatch-surface construction functions.

**Asks for:** a structural rewrite: extract `show`/`hide` out of the
`build_widget_api` lambda block into first-class functions (possibly in a
separate file), reducing config-key-validation boilerplate/copy-paste.

**Provisional kind:** architectural

---

#### R018 — `src/controller/consoleController.lua:795`

> ---> REMARK: why so special treatment for 'before_exit_slot' if default_before_exit is simply a noop? that's exactly case where simple check of nil-ness followed by execution of non-nil function would be justified than complex meta-table jugglng (feel free to contest)

**Context:**
```lua
local get_compy_namespace = function(terminal)
  require("util.namespace.fonts")
  ---> REMARK: why so special treatment...
  local before_exit_slot = default_before_exit
```

**Asks for:** questions why `before_exit_slot` needs metatable machinery
rather than a simple nil-check-then-call, given `default_before_exit` is a
no-op; invites pushback ("feel free to contest").

**Provisional kind:** question

---

#### R019 — `src/controller/consoleController.lua:1047`

> ---> REMARK: why those four below are nils, and what's the point of exporting them into project_env if they are not real functions?

**Context:**
```lua
---> REMARK: why those four below are nils...
project_env.InputEvalText  = nil
project_env.InputEvalLua   = nil
project_env.ValidatedTextEval = nil
project_env.LuaEditorEval  = nil
```

**Asks for:** questions why four `project_env` fields are explicitly
assigned `nil` and what purpose exporting them (as nils) serves.

**Provisional kind:** question

---

#### R020 — `src/controller/consoleController.lua:1285`

> ---> REMARK: that's exactly where we can check hook existance before execution instead of relying on 20 lines of useless boilerplate and metatables

**Context:**
```lua
function ConsoleController:stop_project_run()
  self:evacuate_required()
  local compy = self:get_project_env().compy
  ---> REMARK: that's exactly where...
  compy.before_exit()
```

**Asks for:** proposes replacing the `before_exit` metatable-slot machinery
with a simple existence check right at the `compy.before_exit()` call site.

**Provisional kind:** architectural

---

#### R021 — `src/controller/controller.lua:9`

> ---> REMARK: I think this file still has two big problems: it plugs and unplugs many supported events literally one by one while it could just set up proxying by event name in a cycle (with couple exceptions that are needed to calculate derived events). So it needs big huge pass, collapsing duplicating functions and drying up comments which are extremely verbose (more than needed)

**Context:** top-of-file, right after the `require` block, before
`local messages = {`.

**Asks for:** a broad structural rewrite of `controller.lua`: replace the
one-by-one event plug/unplug pattern with a loop over event names (with
exceptions for derived events), and shorten the file's generally verbose
comments.

**Provisional kind:** architectural

---

#### R022 — `src/controller/controller.lua:42`

> ---> REMARK: if there's no moer distinction, why keep separate lists? also if we anyway hook singleclick/doubleclick (therefore handling the situation when project sets them via love.singleclick) -- why not just get back to a consolidated supported list? separation seemingly has no more sense there (again, like it was pre-feature)

**Context:** above the "Two lists, one lifetime" comment, which explains
`_supported`/`_derived` still exist as separate lists despite installing/
releasing identically now.

**Asks for:** questions whether `_supported` and `_derived` still need to be
separate lists, proposing consolidation back to one list.

**Provisional kind:** architectural

---

#### R023 — `src/controller/controller.lua:146`

> ---> REMARK: extremely verbose prose shorten to minimum, and consider renaming function to something meaningful (naive but semantically correct variant: "with_canvas_and_error_handling")

**Context:** above the long "NAMING — settled. `userlove` KEEPS its name..."
comment block preceding the `guarded(CC, fn)` function.

**Asks for:** shorten the verbose prose comment, and rename `guarded` to
something more descriptive, e.g. `with_canvas_and_error_handling`.

**Provisional kind:** prose (naming ask is mechanical; noting both)

---

#### R024 — `src/controller/controller.lua:228`

> ---> REMARK: eliminate artificial split between keyboard and non-keyboard events, wire them all at once (note there's also hook_pointer function -- clearly a leftover -- sort out this mess)

**Context:** above the doc-comment for `project_handlers`'s companion
"occupy" section (keyboard/text handler installation).

**Asks for:** eliminate the split between keyboard and non-keyboard event
wiring; flags `hook_pointer` as a likely leftover to clean up.

**Provisional kind:** architectural

---

#### R025 — `src/controller/controller.lua:229`

> ---> REMARK: also, it would be more readable in the form where we just cycle around event names and do for i,event in ipirs(supported) do love[event]=guarded(CC, function(...) cc:dispatch(event,...) end end ? and to prevent GC abuse this set of proxy dispatchers could be built *once*? 

**Context:** immediately follows R024, same location.

**Asks for:** proposes a concrete loop-based rewrite (`for i, event in
ipairs(supported) do love[event] = guarded(...) end`), built once to avoid
per-call GC churn.

**Provisional kind:** architectural

---

#### R026 — `src/controller/controller.lua:334`

> ---> REMARK: as part of de-duplication and elimination of interim text/pointer split there should be just hook_input(userlove,CC) which will do all the machinery inside, uniformly across all supported events -- passing all function arguments downstream. and maybe with a single guarded call around 'dispatch' if possible?

**Context:**
```lua
local set_handlers = function(userlove, CC)
  ---> REMARK: as part of de-duplication...
  occupy_keyboard(userlove, CC)
  hook_pointer(userlove, CC)
```

**Asks for:** proposes replacing `occupy_keyboard`/`hook_pointer` with one
unified `hook_input(userlove, CC)` function covering all supported events,
with a single `guarded` wrap around dispatch if feasible.

**Provisional kind:** architectural

---

#### R027 — `src/controller/controller.lua:368`

> ---> REMARK: wipe should happen across all supported types, and shortcut tables should be provisioned for all supported types (or we can use index, setindex machinery there if we do not want to list them all)

**Context:**
```lua
local function reset_compy_input(CC)
  local input = CC:get_project_env().compy.input
  ---> REMARK: wipe should happen...
  wipe_table(input.shortcuts.keypressed)
  wipe_table(input.shortcuts.keyreleased)
  wipe_table(input.shortcuts.textinput)
```

**Asks for:** `reset_compy_input`'s shortcut-table wipe currently
enumerates three event types by name; should cover all supported types
generically (or use `__index`/`__newindex` machinery to avoid listing them).

**Provisional kind:** mechanical

---

#### R028 — `src/controller/controller.lua:372`

> ---> REMARK why not wipe_table(input.hooks) ?

**Context:** immediately below R027, above the `for _, ev in
ipairs(HOOK_EVENTS) do input.hooks[ev] = nil end` loop.

**Asks for:** questions why hooks are cleared with a manual loop instead of
reusing `wipe_table` on `input.hooks` directly.

**Provisional kind:** question

---

#### R029 — `src/controller/controller.lua:484`

> ---> REMARK: did not we agree that they are *fired* as love.* events  and handled by project via hooks? (by hardwiring proxy from love.* to CC:dispatch(event,..) for all events, native and derived?

**Context:**
```lua
Controller = {
  --- @private
  -- Empty: the click stubs that used to sit here were a fossil
  -- of the era when single/doubleclick were love.* events...
  ---> REMARK: did not we agree that they are *fired*...
  _defaults = { },
```

**Asks for:** questions/recalls a prior agreement that singleclick/
doubleclick should be fired as `love.*` events and handled via hooks, via a
hardwired proxy to `CC:dispatch(event, ...)` for all native and derived
events — seems to contest the adjacent comment's framing.

**Provisional kind:** question / architectural (both apply — reads as a
recollection check that, if confirmed, implies an architecture change)

---

#### R030 — `src/controller/controller.lua:713`

> ---> REMARK: is it a new logic or relocated? if there was drift (so no_drift is falsey), are at least two singleclicks fired? looks like they are swallowed

**Context:**
```lua
local derived
if click_count == 1 then
  derived = 'singleclick'
elseif click_count >= 2 then
  derived = 'doubleclick'
end
---> REMARK: is it a new logic or relocated?...
if derived then
  local x, y = love.mouse.getPosition()
  if no_drift(click_pos, { x = x, y = y }) then
```

**Asks for:** a question about the click/drift logic — asks whether it is
new or relocated, and whether clicks are silently swallowed (not re-fired as
singleclicks) when drift invalidates a double-click.

**Provisional kind:** question

---

#### R031 — `src/controller/controller.lua:851`

> ---> REMARK: should not be iteration over all supported type? and why separate function for every type of event instead of unified function with an event name as param (or list of event names)

**Context:**
```lua
release_keyboard_route = function(CC)
  Controller.project_input:deactivate()
  ---> REMARK: should not be iteration over all supported type?...
  Controller.set_love_keypressed(CC)
  Controller.set_love_keyreleased(CC)
  Controller.set_love_textinput(CC)
```

**Asks for:** proposes replacing the three separate `set_love_*` calls with
a loop over supported types, or a single function parameterised by event
name.

**Provisional kind:** architectural

---

#### R032 — `src/controller/controller.lua:1070`

> ----> REMARK: comment simply out of date and explains what is *not* being done -- actualize or (better) eliminate. 

**Context:** above the "Pointer has NO three-consumer chain: this is an
unstructured broadcast..." comment, on the mousepressed-family handler.

**Asks for:** the comment is stale and describes what the code does *not*
do; update it to reflect current behaviour, or delete it.

**Provisional kind:** prose

---

#### R033 — `src/controller/controller.lua:1142`

> ---> REMARK: is it no more touched/invoked ever?

**Context:**
```lua
---> REMARK: is it no more touched/invoked ever?
handlers.userinput = function()
  local user_input = get_user_input()
```

**Asks for:** questions whether `handlers.userinput` is ever still invoked
(the corresponding doc entry, R171, calls this a dead vestige — same
subject).

**Provisional kind:** question

---

#### R034 — `src/controller/controller.lua:528` *(unmarked)*

> ---> comment describing what code does NOT do is absolutely of no use; delete if it has no positive info

**Context:**
```lua
---> comment describing what code does NOT do is absolutely of no use; delete if it has no positive info
-- Straight to the console, with no widget test in front of
-- it: widget visibility is state on the widget, never a
-- routing condition (doc/development/decisions/input.md,
-- Decision 1). A project overlay is reached inside the
CC:keypressed(k)
```

**Asks for:** delete or rewrite the "Straight to the console, with no widget
test in front of it" comment, since it's phrased as what the code does
*not* do.

**Provisional kind:** prose

---

#### R035 — `src/controller/projectInputController.lua:40`

> ---> REMARK: where are singleclick/doubleclick? they should better be supported as any other

**Context:**
```lua
---> REMARK: where are singleclick/doubleclick? they should better be supported as any other
local EVENTS = {
  'keypressed', 'keyreleased', 'textinput',
  'mousepressed', 'mousereleased', 'mousemoved', 'wheelmoved',
  'touchpressed', 'touchreleased', 'touchmoved',
}
```

**Asks for:** `singleclick`/`doubleclick` are missing from `EVENTS`; they
should be supported like any other event type.

**Provisional kind:** mechanical

---

#### R036 — `src/controller/projectInputController.lua:158`

> ---> REMARK: as said in other remark (on documentation), let's drop 'held_keys()' and instead build combo inside dispatch. This way dispatch would become universal function across all events -- we do not need separate self:textnput, self:keypressed etc. -- and signatures would be aligned with love's?

**Context:** immediately above the doc-comment for `keypressed`
(`ProjectInputController:keypressed`), which calls `Controller.held_keys()`.

**Asks for:** proposes dropping `held_keys()` from per-event method
signatures and building the combo inside a single universal `dispatch`,
removing the need for separate `keypressed`/`textinput`/etc. methods, and
aligning signatures with LÖVE's own.

**Provisional kind:** architectural

---

#### R037 — `src/controller/projectInputController.lua:194`

> ---> REMARK: as discussed, lets *support* combo triggers, fully unifying all dispatching of input events. just that combo triggers for pointer won't have the 'triggering' key they would be modifier-only . btw what about right button? and maybe 'button' for those which support button number. easy change, would unify a lot

**Context:** immediately above the "Pointer channels. Each is the keyboard
shape minus the combo trigger..." comment, before the pointer-channel
methods.

**Asks for:** proposes adding combo-trigger support for pointer channels
(modifier-only combos, no trigger key), and raises open questions about
right-button and button-number handling as part of that unification.

**Provisional kind:** architectural

---

#### R038 — `src/controller/userInputController.lua:15`

> --> REMARK: where are before_submit and before_cancel?

**Context:**
```lua
local function default_callbacks()
  return {
    on_limit_reached = noop,
    --> REMARK: where are before_submit and before_cancel?
    after_submit = noop,
    after_cancel = noop,
  }
end
```

**Asks for:** a question — why aren't `before_submit`/`before_cancel`
included as default no-op callbacks alongside `on_limit_reached`,
`after_submit`, `after_cancel`.

**Provisional kind:** question

---

#### R039 — `src/controller/userInputController.lua:21` *(marker: `REMARKS`)*

> ---> REMARKS: comments inlined are quire useless, code is already self-evident? max 1 line with short purpsoe would be enough -- and its already in the announce. btw, name 'allow_modify' is misleading -- its more about supporting line duplication?

**Context:** above the `new(model, disable_selection, allow_modify)`
constructor and its per-parameter doc-comments.

**Asks for:** trim the inline parameter doc-comments to at most one line
each; separately, questions whether `allow_modify` is a misleading name
(it's really about enabling line duplication).

**Provisional kind:** prose, with a naming question (both)

---

#### R040 — `src/controller/userInputController.lua:204`

> ---> REMARK: why console cannot run same callback flow with hide-after-cancel (if it needs it)? then we'd have just a single function instead of two (and this one function would be named 'cancel')

**Context:**
```lua
---> REMARK: why console cannot run same callback flow with hide-after-cancel...
function UserInputController:cancel()
  self.model:cancel()
  self:hide()
end
```

**Asks for:** proposes merging `cancel()` into the standard callback-driven
cancel flow (with a hide-after-cancel callback) instead of keeping it as a
separate method, reducing two functions to one named `cancel`.

**Provisional kind:** architectural

---

#### R041 — `src/controller/userInputController.lua:250`

> ---> REMARK: can just iterate over callback keys instead of bloated copy-paste with similar if-checks? 

**Context:** inside `apply_config`, above the block of `if cfg.validator ~=
nil then ... end` / `if cfg.on_text_entered ...` / `if cfg.on_limit_reached
...` repeated checks.

**Asks for:** replace the repeated per-field `if cfg.X ~= nil then ... end`
checks in `apply_config` with a loop over callback keys.

**Provisional kind:** mechanical

---

#### R042 — `src/controller/userInputController.lua:262`

> ---> REMARK: 'open_fresh' is misleading -- I'd rather make it a part of normal 'show' and rename 'already shown' branch into function 're_show' or something like that, because reshowing is secondary scenario (less operations, conditional)

**Context:** immediately above the doc-comment for the "Fresh activation of
the overlay widget" function (`open_fresh`).

**Asks for:** rename/restructure — fold `open_fresh` into `show`'s primary
path, and rename the "already shown" branch to something like `re_show`,
since re-showing is the secondary (conditional) case.

**Provisional kind:** architectural

---

#### R043 — `src/controller/userInputController.lua:379`

> ---> REMARK: gate is ambiguous name, and could in fact be folded into a single call-site

**Context:**
```lua
---> REMARK: gate is ambiguous name, and could in fact be folded into a single call-site
local function gate(model, validator, lines)
  if not validator then return true end
```

**Asks for:** rename `gate` (ambiguous name) and/or inline it at its single
call site.

**Provisional kind:** mechanical

---

#### R044 — `src/controller/userInputController.lua:453`

> ---> REMARK: why would we need this function and how can it guarantee that controller is "always" shown and nothing else resets the flag? Why we would need it first of all, if it was not used pre-feature? 

**Context:** immediately above the doc-comment for `always_shown()`, which
sets `self.shown = true` and returns `self`.

**Asks for:** questions the purpose and correctness guarantee of
`always_shown()` — nothing prevents the `shown` flag from being reset
elsewhere, and it wasn't used pre-feature; asks why it's needed at all.

**Provisional kind:** question

---

#### R045 — `src/model/input/userInputModel.lua:839`

> ----> REMARK: if we won't inject boilerplate comments, _apply_eval would have normal size even with this code folded-in, so do it (if there's small overhead like 16 lines -- I ratify it; new rule -- 16 lines are tolerablea

**Context:** above the doc-comment for the "Cursor-to-error-position on an
evaluator reject" helper, which was split out of `_apply_eval` /`handle` to
respect the function-body line limit.

**Asks for:** proposes folding this helper back into `_apply_eval` if
comment boilerplate is trimmed, ratifying a "16 lines is tolerable" rule for
the function-body-length limit in this case.

**Provisional kind:** architectural

---

#### R046 — `src/model/input/userInputModel.lua:840` *(marker: `REMARL`, typo for `REMARK`)*

> ----> REMARL: verbose comment, compress and make simpler)

**Context:** immediately follows R045, same location, closing the
parenthetical from R045's sentence.

**Asks for:** compress/simplify the same doc-comment referenced in R045.

**Provisional kind:** prose

---

### tests/

#### R047 — `tests/editor/editor_spec.lua:488-489` *(unmarked, 2 lines)*

> --> real textinput delivers symbols one-by-one, also in this situation could just call 'controller:textinput()' to the same effect?
> --> I would rather expect 'textinputs' served character-by-character and followed by 'enter'

**Context:**
```lua
describe('search mode', function()
  before_each(function()
    love.system = {
      getClipboardText = function() return '' end,
    }
  end)

  --> real textinput delivers symbols one-by-one...
  --> I would rather expect 'textinputs' served character-by-character...
  local function type_search(text)
    mock.textinput(text, function(t) controller:textinput(t) end)
  end
```

**Asks for:** a question/preference about `type_search`'s test helper —
whether it should call `controller:textinput()` per character directly, and
an expectation that `textinput` mocks be delivered character-by-character
followed by an Enter, rather than as one bulk string.

**Provisional kind:** question

---

#### R048 — `tests/editor/editor_spec.lua:709`

> --> REMARK: rewrite and simplify prose: "later" is no more relevant when feature is delivered. Just "guards compatibility of block navigation with widget's internal limits processing"

**Context:** above the "Block navigation at the buffer limit..." comment,
which currently reads "Guards the later is_at_limit line-scope rewrite from
regressing whole-input block navigation."

**Asks for:** rewrite the comment to drop the "later" framing (stale now
that the feature shipped) and replace it with the suggested simpler
sentence.

**Provisional kind:** prose

---

#### R049 — `tests/helpers/input_fixture.lua:200`

> ---> REMARK: "console route forwards..." is not true any more. only rendering part is true

**Context:**
```lua
---> REMARK: "console route forwards..." is not true any more...
-- Is an overlay visible to the framework? Reads love.state.user_input
-- rather than the widget's own is_shown(): that field IS the overlay
-- contract (userInputController.lua, open_fresh/hide) — the draw loop
```

**Asks for:** the "console route forwards..." claim in the comment is
stale/incorrect; only the rendering part of that claim still holds.

**Provisional kind:** prose

---

#### R050 — `tests/helpers/input_session.lua:1`

> ---> REMARK: simplify comment, do not tell what it is noe

**Context:** top-of-file, above the "Keypress-level driver over the
installed love.handlers.* gate" file-header comment.

**Asks for:** simplify the file-header comment; do not explain "what it is
not" (contrastive framing).

**Provisional kind:** prose

---

#### R051 — `tests/helpers/input_session.lua:12`

> ---> REMARK: simplify comment. just tell it exposes API to invoke 'love' events via handlers. (providing a controllable imitation of love2d events emitting, which in production would be done in response to actions over physical hardware)

**Context:** above `emitters()`'s "Expose one emitter per gateway entry..."
comment.

**Asks for:** simplify the `emitters()` comment to the suggested one-liner
about exposing an API to invoke LÖVE events via handlers.

**Provisional kind:** prose

---

#### R052 — `tests/helpers/input_session.lua:32`

> ---> REMARK: simplify comment. just tell it invokes production function connectinng controller to love2d

**Context:** above the "Install the real gate into a fresh love.handlers..."
comment on the `new(CC)` function.

**Asks for:** simplify this comment to the suggested one-liner about
invoking the production function that connects the controller to LÖVE2D.

**Provisional kind:** prose

---

#### R053 — `tests/input/highlight_regression_spec.lua:1`

> ---> REMARK: remove references to input API release cycle, completely. its just a regression test accompanying bugfix

**Context:** top-of-file, above the "Availability: the highlighter predates
the Compy input API..." comment.

**Asks for:** remove input-API-release-cycle references from this file
entirely; it's a regression test tied to a bugfix, not to the API's
versioning.

**Provisional kind:** prose

---

#### R054 — `tests/input/highlight_regression_spec.lua:2`

> ---> REMARK: simplify prose and desctibe *behavioural* test which raises exception (so, the real bug path -- i.e. project that supplies <some configuration> gets exception on <someinput>). Current checks read as testing seomthing purely internal.

**Context:** same location as R053.

**Asks for:** rewrite the test description to state the behavioural bug path
(a project configuration that raises an exception on some input) rather than
reading as an internal-only check.

**Provisional kind:** prose

---

#### R055 — `tests/input/highlight_regression_spec.lua:3`

> ---> REMARK: acceptance criteria: code does not break the way it used to . 'highlight must stay indexable' is implementation details, not acceptance criteria

**Context:** same location as R053/R054.

**Asks for:** reframe the stated acceptance criteria — "code does not break
the way it used to," not "highlight must stay indexable" (called out as an
implementation detail, not a criterion).

**Provisional kind:** prose

---

#### R056 — `tests/input/history_spec.lua:72`

> ---> REMARK: is comment even needed here? code is quite self-explanatory 

**Context:** above the "Recall the way a user reaches it, through the real
console..." comment preceding a history-navigation test.

**Asks for:** questions whether the comment is needed at all, given the code
below reads as self-explanatory.

**Provisional kind:** question

---

#### R057 — `tests/input/input_cursor_text_spec.lua:1`

> --> REMARK: what if we organize tests by three groups named explicitly: a) interception of inbound key/mouse events b) management of input widget c) reacting to input widget events (limits, submission, cancellation) -- but we'll need good names for describe, aligned with documentation

**Context:** top-of-file, before the "Availability: introduced with the
Compy input API..." comment.

**Asks for:** proposes reorganizing the input test suite (this file and,
implicitly, others) into three explicit groups — inbound event
interception, widget management, and reacting to widget-originated events —
naming `describe` blocks to match documentation vocabulary.

**Provisional kind:** architectural

---

#### R058 — `tests/input/input_events_spec.lua:48`

> ---> REMARK: can we rewrite it as more readable matrix (maybe yes, maybe no). just using unified 'registration', and varying consumption returns to observe different depth of chain propagation

**Context:** above `describe('order, consume, fall-through', ...)`.

**Asks for:** questions whether this `describe` block could be rewritten as
a more readable matrix-style test using unified registration and varying
consumption returns.

**Provisional kind:** question

---

#### R059 — `tests/input/input_events_spec.lua:49`

> ---> REMARK: I really think we could have 'describe-level' "order" table, standardized mock shortcuts/handlers factories that always include updating 'order' when invoked and than return whatever they are told to return. And initial setup of widget with "abc", than combining test cases and inspecting results will be much more obvious. I would even say its MUST HAVE: this way we need to understand paradigm *once*, and tests become more concise. Now each test case establishes its own rules, slightly different -- it looks like too much copy-n-paste, which also *slightly* differs inside, so reader has to decode the universe of each case

**Context:** immediately follows R058, same location.

**Asks for:** proposes a standardized describe-level "order" tracking table
and mock-factory pattern for shortcuts/hooks in this suite, calling it a
"MUST HAVE" to reduce copy-paste and per-test bespoke setup.

**Provisional kind:** architectural

---

#### R060 — `tests/input/input_events_spec.lua:50`

> ---> REMARK: BY THE WAY, AREN'T OUR SHORCUTS mod-only ? WHY TESTS SETTING SHORTCUT AGAINST SIMPLE SYMBOL ARE WORKING THEN?

**Context:** immediately follows R059, same location.

**Asks for:** a question — asks whether shortcuts are supposed to be
modifier-only, and why tests registering shortcuts on a bare symbol (no
modifier) pass if so.

**Provisional kind:** question

---

#### R061 — `tests/input/input_events_spec.lua:194`

> --> REMARK: this is kind of a matrix test I've thought of -- does it supersede dispatching tests above?

**Context:** above `describe('the interception matrix', ...)`.

**Asks for:** questions whether "the interception matrix" `describe` block
supersedes the earlier "order, consume, fall-through" tests (i.e., the
matrix idea from R058/R059 may already exist here).

**Provisional kind:** question

---

#### R062 — `tests/input/input_events_spec.lua:241` *(unmarked)*

> -->  these things are called 'test cases', not vague 'rows'

**Context:**
```lua
-->  these things are called 'test cases', not vague 'rows'
for _, row in ipairs(rows) do
  it(row.name, function()
```

**Asks for:** rename the loop/table variable `rows` (and related
vocabulary) to "test cases."

**Provisional kind:** mechanical

---

#### R063 — `tests/input/input_events_spec.lua:342`

> ---> REMARK: should also check (right here) that they actually work, not only are registered?

**Context:** above `it('accepts a trigger, a combo, and a class', ...)`,
which only asserts the shortcuts are registered (`is_function(sc['a'])`
etc.), not that they fire.

**Asks for:** proposes strengthening this test to also assert the
registered shortcuts actually fire/work, not merely that registration
succeeded.

**Provisional kind:** mechanical

---

#### R064 — `tests/input/input_lifecycle_uniform_spec.lua:1`

> ---> REMARK: rename the file to say something about submit-cancel (better than ambigous 'lifecycle')

**Context:** top-of-file, before the "Availability: introduced with the
Compy input API..." comment.

**Asks for:** rename `input_lifecycle_uniform_spec.lua` to something naming
submit/cancel specifically, since "lifecycle" is ambiguous.

**Provisional kind:** mechanical

---

#### R065 — `tests/input/input_lifecycle_uniform_spec.lua:2`

> ---> REMARK: dry up the prose and consider making test cases more readable and self-evident

**Context:** same location as R064.

**Asks for:** shorten the file's prose and make its test cases more
self-evidently readable.

**Provisional kind:** prose

---

#### R066 — `tests/input/input_lifecycle_uniform_spec.lua:3`

> ---> REMARK: I'd avoid word 'overlay' fully -- can be 'project input widget'

**Context:** same location as R064/R065.

**Asks for:** stop using "overlay" in this file; use "project input widget"
instead.

**Provisional kind:** prose

---

#### R067 — `tests/input/input_nfr_mechanism_spec.lua:1`

> ---> REMARK: what remained here is very unlikely collection, I'd dissolve it across other files. E.g. held_keys is literally a part of documented contract now -- worth its own test suite. "wheel" test should be universalized across all supported event types, and live somewhere around dispatching, as literally a list of supported event types and cyle over it testing that every event is reaching, The *only* NFR I could think of is the usage of widget singleton across project invocations (therefore avoiding GC abuse) -- but its no here (if it was moved elsewhere, that's fine) . If we move these two said tests as said, there's a chance file could be dissolved

**Context:** top-of-file, before "Availability: predates the Compy input
API..." comment.

**Asks for:** proposes dissolving this file: move `held_keys` coverage to
its own suite (it's now a documented contract), generalize the "wheel" test
across all event types near dispatching tests, and questions whether
anything genuinely NFR-shaped remains besides the widget-singleton-reuse
guard.

**Provisional kind:** architectural

---

#### R068 — `tests/input/input_reconfigure_spec.lua:271`

> ---> REMARK: did not we swap default widget behaviour to always show, and recommended to make closing explicit from 'after_submit'? Then this test actually tests nothing and needs to be replaced with closure-on-submit

**Context:** above `describe('continuous-session idiom', ...)` and its "One
shape: consume in on_text_entered, re-show (bare, no config) in
after_submit" test.

**Asks for:** questions whether this test is now vacuous given the
stay-open-by-default behaviour change, and proposes replacing it with a
closure-on-submit-style test.

**Provisional kind:** question (with an implied mechanical fix)

---

#### R069 — `tests/input/input_route_lifecycle_spec.lua:312`

> ---> REMARK: worth also checking that widget is not shown after suspend?

**Context:** inside the "disconnects the project route and its widget goes
unhonoured" test, after `F.cc:suspend()`.

**Asks for:** proposes adding an assertion that the widget is not shown
after `suspend()`, in addition to the existing checks.

**Provisional kind:** mechanical

---

#### R070 — `tests/input/input_route_lifecycle_spec.lua:420`

> ---> REMARK: test that neither raising from before_exit, nor attempt to return true do not block the exit (inability to disable exit from before_exit is dictated by common logic so it becomes final form of the contract for this specific hook)

**Context:** above `describe('compy.before_exit', ...)`.

**Asks for:** proposes adding tests confirming that neither a raise inside
`before_exit` nor a truthy return from it can block the project's exit,
treating "cannot disable exit" as the settled contract for this hook.

**Provisional kind:** mechanical

---

#### R071 — `tests/input/input_shortcuts_click_spec.lua:6`

> ---> REMARK: is the prose below copied from elsewhere? it seems it recites the routing rules while suite tests something else? also its very excessive...

**Context:** top-of-file, above the "shortcuts and click detection. Routing
invariant..." comment block.

**Asks for:** questions whether the file-header prose was copy-pasted from
elsewhere (it restates general routing invariants unrelated to what this
suite actually tests) and calls it excessive.

**Provisional kind:** question

---

#### R072 — `tests/input/input_widget_lifecycle_spec.lua:4`

> ---> REMARK: prose below seems to be copied from elsewhere without much relevance to test suite content

**Context:** top-of-file, above the "widget lifecycle. Routing invariant..."
comment block.

**Asks for:** same concern as R071, applied to this file's header prose.

**Provisional kind:** question

---

#### R073 — `tests/input/input_widget_lifecycle_spec.lua:20`

> ---> REMARK: avoid word 'overlay', better 'project input widget'

**Context:** same top-of-file block, just before `local F =
require('tests.helpers.input_fixture')`.

**Asks for:** stop using "overlay" in this file; use "project input widget."

**Provisional kind:** prose

---

#### R074 — `tests/input/input_widget_lifecycle_spec.lua:21`

> ---> REMARK: There was another test suite on reconfiguration -- worth merging here and possibly de-duplicating?

**Context:** immediately follows R073, same location.

**Asks for:** proposes merging/de-duplicating this file with the separate
reconfiguration test suite (`input_reconfigure_spec.lua`).

**Provisional kind:** architectural

---

#### R075 — `tests/input/input_widgets_callbacks_spec.lua:6`

> ---> REMARK: rename file (there are others mentioning 'widgets' this one mentions 'widget')

**Context:** top-of-file, after the "Availability: introduced with the
Compy input API..." comment.

**Asks for:** rename the file — its name says "widgets" (plural) while
other files use "widget" (singular), an inconsistency.

**Provisional kind:** mechanical

---

#### R076 — `tests/input/input_widgets_callbacks_spec.lua:8`

> ---> REMARK: remove copypasted irrelevant prose below

**Context:** immediately above the "dispatch chain: widget outputs and
submit/cancel. Routing invariant..." comment block.

**Asks for:** delete the copy-pasted, irrelevant prose that follows.

**Provisional kind:** prose

---

#### R077 — `tests/input/input_widgets_callbacks_spec.lua:29`

> ---> REMARK: artifact prose from elsewhere? distill to only relevant 

**Context:** above the "The dispatch chain (doc/development/decisions/
input.md, Decision 2). All rows drive the REAL project route..." comment
block.

**Asks for:** questions whether this prose is another copy-pasted artifact;
distill it to only what's relevant.

**Provisional kind:** question

---

#### R078 — `tests/input/input_widgets_callbacks_spec.lua:45`

> ---> REMARK: don't we have another test suit which also tests submit and cancel? consider merging, unification and deduplication of cases

**Context:** immediately above `describe('widget outputs, submit and cancel
#input', ...)`.

**Asks for:** questions whether another suite (likely
`input_lifecycle_uniform_spec.lua`) duplicates submit/cancel coverage;
proposes merging/deduplicating.

**Provisional kind:** architectural

---

#### R079 — `tests/input/project_open_liveness_spec.lua:1`

> ---> REMARK: all cases here are expressed in terminology that is hard to udnerstand and follow. either we need a separate document describing it and referenced from here, or tests claims need to be rewritten to be more undertandable, or tests are checking some phantom logic and are possibly dissolvable

**Context:** top-of-file, before "Availability: changed by the Compy input
API..." comment.

**Asks for:** the whole file's test claims are hard to follow; proposes
either a companion doc explaining the terminology, rewriting the test
descriptions to be clearer, or — if the logic being tested is "phantom" —
dissolving the file.

**Provisional kind:** unclear (three different possible actions offered,
owner has not chosen between them)

---

### doc/

#### R080 — `doc/development/decisions/input.md:109`

> REMARK: any real reason to treat widget specially? why not interpret it as any other chain element? I feel special treatment is an artifact of design hallucinations that were self-inflicted and dissolved. I see no reason to treat widget separately -- and if we discard decision 5, codebase change would be minimal and won't change any behaviour

**Context:** attached to Decision 2's three-component-chain list, right
before item 1 (`shortcuts[event][combo]`).

**Asks for:** contests treating the widget as a special, distinguished third
chain component; proposes it be just another chain element, contingent on
discarding Decision 5, with claimed minimal codebase impact.

**Provisional kind:** architectural

---

#### R081 — `doc/development/decisions/input.md:120`

> REMARK: now its more than three components, we are sending pointer events the same way!

**Context:** attached to "A **truthy return at any component consumes** the
event..." — the paragraph describing the three-component shape.

**Asks for:** points out the doc's "three components" framing is stale now
that pointer events run the same chain too — more than three components/
channels are involved.

**Provisional kind:** prose

---

#### R082 — `doc/development/decisions/input.md:126`

> REMARK: "there was once" is irrelevant -- a history of hallucination, self-inflicted and dissolved during implementation. Does not have to be mentioned

**Context:** attached to "**No framework tier.** There was once a fourth,
leading component — `framework handlers`..."

**Asks for:** remove the "there was once a fourth component" historical
framing; calls it an irrelevant, self-inflicted-then-dissolved history that
doesn't need documenting.

**Provisional kind:** prose

---

#### R083 — `doc/development/decisions/input.md:136`

> REMARK: 'old four-component shape' was pure hallucination, remove its mentions from here

**Context:** attached to the "**Why.** One uniform shape on every channel is
the predictability meta-rule made concrete..." paragraph, which itself
mentions "the old four-component shape."

**Asks for:** remove all mentions of the "old four-component shape" from
this section.

**Provisional kind:** prose

---

#### R084 — `doc/development/decisions/input.md:146`

> REMARK: "de-facto SDL articat" is vague and its not clear how its relevant here

**Context:** attached to the "**Recognized external constraint — no
cross-channel ordering guarantee...**" paragraph.

**Asks for:** questions the relevance/clarity of the "de-facto SDL artifact"
phrasing in this paragraph.

**Provisional kind:** question

---

#### R085 — `doc/development/decisions/input.md:159`

> REMARK: 'consuming-is-not-removing' is an artifact of self-reasoning across hallucinations. nothing nowhere required 'consuming' to be 'removing', so defending against it makes no sense. I'd remove whole paragraph -- it speaks about what is *not* supported, while this not-supported was also never-requested or never-assumed

**Context:** attached to "**A load-bearing distinction: consuming is not
removing.**" paragraph.

**Asks for:** proposes removing the entire "consuming is not removing"
paragraph — argues it defends against a misconception nobody held.

**Provisional kind:** prose

---

#### R086 — `doc/development/decisions/input.md:167`

> REMARK: this is proper approach and it contradicts with  formula few paragraphs before (supposedly stale) that says widget state is "checked at the end of chain, and bypassed if not shown" -- which was fully unnecessary complication hopefully dissolved since then

**Context:** attached to "**A load-bearing decision about the widget: its
hidden-check is internal.**" paragraph.

**Asks for:** flags a contradiction between this paragraph (widget's
hidden-check is internal, correct/current) and an earlier, allegedly stale
formula elsewhere in the doc saying widget state is "checked at the end of
chain, and bypassed if not shown."

**Provisional kind:** unclear — reads as pointing at an internal
inconsistency for the doc to resolve, not asking for a specific edit here

---

#### R087 — `doc/development/decisions/input.md:173`

> REMARK: its really not exactly this way -- we still use 'ifs' because we decided not to plumb tables with 'no-ops' default. so this paragraph could be recalibrated to reality or removed

**Context:** attached to "**Consequence.** Dispatch is the uniform
short-circuit shape this design always aimed at: `shortcuts(...) or
hooks(...) or widget(...)`..."

**Asks for:** contests the "uniform short-circuit shape" claim — actual code
still uses `if` guards (no-op-table plumbing was rejected); proposes either
correcting the paragraph to match reality or removing it.

**Provisional kind:** prose

---

#### R088 — `doc/development/decisions/input.md:192` *(no space after `>`)*

> REMARK: "same code" (which is kinda true? check) does not mean "same instance" -- and there are reason to limit 'singleton' to project widgets only. prose below was a pre-implementation vision -- but implementation at least currently ended with the different instances (console needs to maintain its own). So the prose below should be recalibrated to reality

**Context:** attached to "**Consequence.** The same widget code backs the
console REPL, the editor input strip, and project overlays..."

**Asks for:** the "same code"/singleton framing needs verification and
recalibration — implementation reportedly ended up with separate instances
(console maintains its own); asks that the paragraph be updated to match.

**Provisional kind:** prose

---

#### R089 — `doc/development/decisions/input.md:200`

> REMARK: replace "input events" with "events originated at input widget" -- to not confuse inbound events and outbound ones. Or if we speak both classes, let's make the paragraph more clear about it . right now it reads like other input events are the same as 'submission' which is not true and confuses reader. rewrite the opening to be unambiguous about context -- message itself (the prose which follows the opening) is correct -- we discard polling idiom.

**Context:** attached to Decision 4's title/opening, "**Decision.**
Submission and all other input events are delivered through **callbacks and
handler tables**..."

**Asks for:** rewrite Decision 4's opening sentence to disambiguate inbound
vs. outbound events, since "input events" currently reads as conflating
submission with other input events; the rest of the paragraph is fine.

**Provisional kind:** prose

---

#### R090 — `doc/development/decisions/input.md:220`

> REMARK: its the good moment to say "chain routes events into the route where they are consumed by shortcuts/hooks. The widgets reports results out through *callbacks*". Which is exactly the difference in terminology -- callbacks originate during input processing, shortcuts/hooks consume inbound OS events. Important part here is using term "callbacks" instead of "widget outputs" which are not defined anywhere.

**Context:** attached to Decision 5's title/opening, "**Decision.** The
chain routes events *into* the active route. The widget reports results
*out* through its own configured **widget outputs**..."

**Asks for:** rewrite this passage to introduce the vocabulary distinction
explicitly — "callbacks" vs. "shortcuts/hooks" — and to use the term
"callbacks" instead of the undefined "widget outputs."

**Provisional kind:** prose

---

#### R091 — `doc/development/decisions/input.md:234`

> REMARK: conflating them is not generally a trap -- so no need for this false rationalization. Just say we distinguish

**Context:** attached to "**Why.** Routing has two genuinely different
directions and conflating them is the trap this subsystem was explicitly
designed around..."

**Asks for:** remove the "conflating them is a trap" rationalization; simply
state that the two directions are distinguished.

**Provisional kind:** prose

---

#### R092 — `doc/development/decisions/input.md:235`

> REMARK: overall this block has too much self-invented explanation, including 'student' passage. No need to overprotect the normal engineering decision.

**Context:** immediately follows R091, same "Why" paragraph block (which
elsewhere in the doc includes a "student" passage).

**Asks for:** trim this block's over-explanation and remove the "student"
passage; treat it as a normal engineering decision that doesn't need
defending at length.

**Provisional kind:** prose

---

#### R093 — `doc/development/decisions/input.md:269`

> REMARK: if it does not differ from pre-feature behaviour, there's no decision to record at all.  Why this decision arrived -- attempt to combat design hallucination which assigned special roles. If as a result we just got back to normal platform behaviour, there was no decision worth standing in this register. IF we did de-facto change the behaviour -- the whole 'decision' block should be compressed 2-3 times and explain only change and why it was necessary/useful. Right now block of decision 6 is overbloated and its not clear which exact decision it describes and what was its rationale/consequences.

**Context:** attached to Decision 6's title, "submit and cancel are
widget-owned callback-driven flows, not a framework tier."

**Asks for:** questions whether Decision 6 should exist at all if it just
restores pre-feature behaviour; if it does record a real change, compress
the block 2-3x and state only the change and its rationale — calls the
current block overbloated and unclear about what it actually decided.

**Provisional kind:** architectural

---

#### R094 — `doc/development/decisions/input.md:350`

> REMARK: the decision is very trivial, I do not think its worth documenting, or should be literally few lines

**Context:** attached to Decision 7's title, "freeze the container and its
sub-table identities; leaves are writable."

**Asks for:** questions whether Decision 7 is worth documenting at all,
given its triviality; if kept, it should be a few lines.

**Provisional kind:** question

---

#### R095 — `doc/development/decisions/input.md:383`

> REMARK: rewrite -- now 'combo-tables' are reproduced without explanation. Instead the solution was to support combo-tables at all (to avoid stuffing all event-handling logic in a single hook and enable modularity). The way combo tables are assembled and checked is downstream tactical decision -- we took the simplest form. So the full block has to be rewritten 

**Context:** attached to Decision 8's title, "per-event combo tables and
canonical combo serialisation."

**Asks for:** rewrite Decision 8 to lead with the actual decision (support
combo tables at all, to avoid one giant hook and enable modularity) rather
than reproducing the combo-table shape without motivating it; the assembly
mechanics are a downstream tactical choice.

**Provisional kind:** prose

---

#### R096 — `doc/development/decisions/input.md:423`

> REMARK: this one needs to be updated. First, the form of signature is ours to decide -- one-line saying that we extend love's signature by keys_pressed would be enough

**Context:** attached to Decision 9's title, "uniform signatures and
`isrepeat` threading."

**Asks for:** update Decision 9; the signature shape is the project's own
choice — a one-liner stating "extends LÖVE's signature with keys_pressed"
would suffice.

**Provisional kind:** prose

---

#### R097 — `doc/development/decisions/input.md:424`

> REMARK: in fact, decision could be even revisited -- now when we just decided to make keys_pressed available globally we have no reason to pass it to hooks. therefore, signatures fall back to standard love2d ones

**Context:** immediately follows R096, same location.

**Asks for:** proposes revisiting Decision 9 itself — since `keys_pressed`
is now globally available, there's no reason to keep passing it as a hook
argument; signatures could fall back to plain LÖVE2D signatures.

**Provisional kind:** architectural

---

#### R098 — `doc/development/decisions/input.md:425`

> REMARK: we invented helpers/wrappers to simplify gating on is-repeat and blocking propagation -- worth mentioning here instead of saying that shortcuts could not be gated?

**Context:** immediately follows R097, same location.

**Asks for:** proposes mentioning the `ignore_repeat`/`stop_here` helper
wrappers in Decision 9's text, instead of the current framing that shortcuts
can't be gated on repeat.

**Provisional kind:** prose

---

#### R099 — `doc/development/decisions/input.md:426` *(marker: `REMARK/SUMMARY`)*

> REMARK/SUMMARY: importance of this decision could be now neglectable (its original purpose was to carry-through the keys pressed proxy, but later we figured out that keys-pressed need to be globally available anyway -- so we can drop both decision and its codebase counterparts without regression in system behaviour (at cost of maybe minimal rewrites) -- worth doing pre-PR to reduce complexity?

**Context:** immediately follows R098, same location, summarizing R096-R098.

**Asks for:** a summary proposal — Decision 9 may be droppable entirely
(along with its codebase counterparts) without behavioural regression, at
the cost of minor rewrites; suggests doing this before the PR to reduce
complexity.

**Provisional kind:** architectural

---

#### R100 — `doc/development/decisions/input.md:444`

> REMARK: these 'no' sound like protecting against alternatives not-requested-and-not-considered 

**Context:** attached to Decision 10's title, "one `hooks[event]` table,
seeded once at activation," whose body lists "no widget-aware gating, no
lifecycle split, no custom logic."

**Asks for:** the list of "no X, no Y, no Z" phrasing reads as defending
against alternatives nobody proposed; implies it should be reworded.

**Provisional kind:** prose

---

#### R101 — `doc/development/decisions/input.md:445`

> REMARK:  now 'all' events are shaped this way

**Context:** immediately follows R100, same location.

**Asks for:** notes that "all" events (not just keyboard/text) are now
shaped this way — implies the decision text should reflect the broader
scope.

**Provisional kind:** prose

---

#### R102 — `doc/development/decisions/input.md:446`

> REMARK: lets reframe the decision as "new api has more appropriate place for hooks -- so we silently re-wire old 'project-installed callbacks' there -- encouraging new usage but not disabling old one, if it's ever needed for pedagogical purposes 

**Context:** immediately follows R101, same location.

**Asks for:** proposes reframing Decision 10's own statement around the new
API providing "a more appropriate place for hooks," silently re-wiring old
project-installed callbacks there without disabling the old path.

**Provisional kind:** prose

---

#### R103 — `doc/development/decisions/input.md:456`

> REMARK: nobody cares which exactly original intermittent shape decision had once if it was rewritten since and dissolved form never materialized in release/contract/doc

**Context:** attached to "**Substance changed from the original pure-wrap.**
The original decision resolved the hook by precedence on **every event**..."

**Asks for:** proposes removing/trimming the "substance changed from the
original pure-wrap" historical comparison, since the earlier shape never
shipped.

**Provisional kind:** prose

---

#### R104 — `doc/development/decisions/input.md:481`

> REMARK: clean up self-arguing with past decisions that were than reshaped before release. WHat was not in released version is considered as never existing (except few bits explicitly ratified by stakeholders) 

**Context:** attached to Decision 11's title, "the route is held by an open
project, released at its stop."

**Asks for:** clean up passages that argue against earlier, pre-release
shapes of a decision; states a general principle that unreleased shapes
should be treated as never having existed (except where explicitly
stakeholder-ratified).

**Provisional kind:** prose

---

#### R105 — `doc/development/decisions/input.md:522`

> REMARK: if its the behaviour system had and keeps having, its not a decision -- its documented de-facto standard

**Context:** attached to Decision 12's title, "`inspect` is a mode-to-route
line, nothing more."

**Asks for:** questions whether Decision 12 should be framed as a
"decision" at all versus a documented de-facto standard, if the behaviour
was and remains unchanged.

**Provisional kind:** question

---

#### R106 — `doc/development/decisions/input.md:562`

> REMARK: only historical correction -- we proactively reverse-engineered system behaviour and codified existing de-facto standards in a tests, and documented some -- therefore canonicalizing them *before* implementation; the fact that some of those came unnoticed until post-implementation controversies resolution is secondary . its mostly about historic accuracy of the first phrase, decision itself stands

**Context:** attached to Decision 14's title, "de-facto contracts:
reverse-engineered behaviour is preserved and formalised, not silently
changed."

**Asks for:** a narrow historical-accuracy correction to Decision 14's
opening — clarifies that behaviour was proactively reverse-engineered and
canonicalized before implementation, not just discovered post-hoc; the
decision itself is not contested.

**Provisional kind:** prose

---

#### R107 — `doc/development/decisions/input.md:591`

> REMARK: its quite trivial and obvious tactical decision, is it even worth documenting?

**Context:** attached to Decision 15's title, "unrecognised show/configure
configuration raises."

**Asks for:** questions whether Decision 15 is worth documenting given its
triviality.

**Provisional kind:** question

---

#### R108 — `doc/development/decisions/input.md:628`

> REMARK: no need to describe interim forms, invented and dissolved in-flight

**Context:** attached to "### Superseded — the original warn-and-ignore
form" (the earlier shape of Decision 15).

**Asks for:** proposes removing the "Superseded — the original
warn-and-ignore form" section describing an interim, never-released shape.

**Provisional kind:** prose

---

#### R109 — `doc/development/decisions/input.md:648`

> REMARK: this decision was fully overwritten and de-facto input was unified across events axis (to not be confused with postponed unification of routing mechanisms across cosnole/editor/project which is still deferred). So this block should be removed

**Context:** attached to Decision 16's title, "defer future input
unification."

**Asks for:** proposes removing Decision 16 entirely, on the grounds that
event-axis unification has already de-facto happened (distinct from the
still-deferred console/editor/project routing unification).

**Provisional kind:** architectural

---

#### R110 — `doc/development/decisions/input.md:697`

> REMARK: is it an artifact block describing history which passed? (afaik now 'dispatch'  *is* reusable function) -- review and recheck if it belongs here

**Context:** attached to "## Implementation note — making the mechanism
reusable (non-normative, no project-facing contract change)."

**Asks for:** questions whether this "Implementation note" section is now
stale history (given `dispatch` is reportedly already a reusable function)
and should be reviewed for relevance.

**Provisional kind:** question

---

#### R111 — `doc/development/decisions/input.md:765`

> REMARK: let's fully retire ambiguous 'overlay' from everywhere. Its input widget.

**Context:** attached to Decision 18's title, "the overlay answers one state
question: `is_shown()`."

**Asks for:** stop using "overlay" throughout this document (and, by
extension elsewhere — this remark recurs across several files); use "input
widget."

**Provisional kind:** prose

---

#### R112 — `doc/development/decisions/input.md:795`

> REMARK: as said, we even can get rid of held-keys passed as arguments to hooks, which aligns hooks signature with love2d native signatures and would be a big win

**Context:** attached to Decision 20's title, "a project can read the
held-key set outside an event."

**Asks for:** reiterates R097's proposal (drop `keys_pressed` from hook
argument lists, aligning with native LÖVE2D signatures), calling it a
worthwhile win.

**Provisional kind:** architectural

---

#### R113 — `doc/development/decisions/input.md:831`

> REMARK: historical references (when exactly was something decided) bear no value, strip them

**Context:** attached to Decision 21's title, "a combo names modifiers plus
one trigger, or a class."

**Asks for:** strip "Status: implemented (owner ruling, <date>)"-style
historical-timestamp references throughout; says they carry no value.

**Provisional kind:** prose

---

#### R114 — `doc/development/decisions/input.md:888`

> REMARK: ignore_repeat appears to be keypressed-specific wrapper, because its not passed anywhere else? worth mentioning.

**Context:** attached to Decision 22's title, "`compy.input.fn.ignore_repeat`."

**Asks for:** notes `ignore_repeat` appears to only be usable/used on
`keypressed` (not passed on other channels) and suggests documenting that
constraint explicitly.

**Provisional kind:** question

---

#### R115 — `doc/development/decisions/input.md:1063`

> REMARK: I thought we agreed on combos for pointers (love2d signature kept, combo is constructed from modifier keys pressed, no trigger key) -- better once do it and enable than document and argue across many iterations

**Context:** attached to "**Not decided here.** Whether pointer should gain
a combo vocabulary of its own..." (the doc's final open item).

**Asks for:** recalls an apparent prior agreement on pointer combos
(LÖVE2D signature kept, combo built from held modifiers, no trigger key);
proposes just implementing it rather than continuing to leave it as an open
question across iterations.

**Provisional kind:** architectural

---

#### R116 — `doc/development/internals/event_dispatch_layers.md:106` *(marker: `REMARK/nitpick`)*

> REMARK/nitpick -- project vocabulary introduces *three* terms (also a 'shortcut') -- maybe its worth mentioning here too

**Context:**
```md
literally sets up `love.handlers`, which is what LÖVE calls that table. There is no second,
Compy-specific sense of *handler* to collide with it — the input API's vocabulary
([`../decisions/input.md`](../decisions/input.md#vocabulary--hook-callback-handler)) names two
> REMARK/nitpick -- project vocabulary introduces *three* terms...
*other* things, **hook** and **callback**, and leaves "handler" to LÖVE.
```

**Asks for:** the sentence says the input API's vocabulary "names two other
things" (hook, callback), but the vocabulary actually has three terms
(including "shortcut"); suggests mentioning that here too.

**Provisional kind:** prose

---

#### R117 — `doc/development/internals/event_dispatch_layers.md:112`

> REMARK: this needs actualization, because the routing was recently unified and there's no more artificial divergence between keyboard/pointer?

**Context:** attached to "What does need saying is what happens to a
project's own `love.*` functions..." — the section below it that
distinguishes keyboard/text handling from pointer handling.

**Asks for:** update this section — the keyboard-vs-pointer divergence it
describes is stale now that routing was unified.

**Provisional kind:** prose

---

#### R118 — `doc/development/internals/examples/balloons.md:3`

> REMARK: it seems balloons itself is a bit overcomplicated now (it built its own abstraction layer around input, to combat previous complexity -- now it could e.g. clear/configure/deliver in a single on_submit callbac. We won't rework it -- just admit the fact (API now makes possible to eliminate internal complexity, but we only do focused updates)

**Context:** top-of-file, right after the `# balloons` heading.

**Asks for:** flags that the balloons example's own input-abstraction layer
is now more complex than needed given the new API, but explicitly says not
to rework it — just to note the fact in the doc.

**Provisional kind:** prose

---

#### R119 — `doc/development/internals/examples/guess.md:5`

> REMARK: can we avoid using ambiguous word 'overlay' which is just a synonym for project's input widget? unifying terminology would be less confusing to reader

**Context:** top-of-file, before "**Number guessing game** with
per-character input validation."

**Asks for:** stop using "overlay" in this file; use "project input widget"
terminology instead.

**Provisional kind:** prose

---

#### R120 — `doc/development/internals/examples/paint.md:3`

> REMARK: worth installing love.{mousemoved,keypressed} as hooks? (as they will anyway be reassigned there). It would be cleaner. we can even introduce paradigm of aliasing compy.input.hooks as 'hooks' for comprehension

**Context:** top-of-file, right after `# paint`, before the
`<!-- authored By LLM -->` marker.

**Asks for:** questions whether the paint example should install
`love.mousemoved`/`love.keypressed` directly as `compy.input.hooks` entries
(since they get reassigned there anyway), and proposes aliasing
`compy.input.hooks` locally as `hooks` for readability.

**Provisional kind:** architectural (about example code) — also reads as a
question

---

#### R121 — `doc/development/internals/examples/repl.md:15`

> REMARK: why two different paths if both actions can be called in a single 'on_text_entered'? if we want to show the different ways, we may explain its for demo purposes (actually on_text_entered and after_submit are obviously duplicates which may be a small architectural smell; consider removing 'after_submit' from callbacks? or allow installing all callbacks via show? or even avoiding setting callbacks via show and only use callbacks table?). ON THE OTHER HAND (and its good argument to keep both, same pardigm in `valid`) -- one callback could be used for mechanical widget cleanup, another one to meaningfullly process the input. Developer is not obliged to use both -- but in some circumstances it may be convenient to be able to do so

**Context:** above "## Code," following the repl example's description of
`on_text_entered`/`after_submit`.

**Asks for:** questions why the repl example uses two separate callback
paths (`on_text_entered` and `after_submit`) when one could suffice; raises
it as a possible architectural smell (maybe `after_submit` should be
removed, or callback installation unified), while also arguing the opposite
— that keeping both is defensible (mechanical cleanup vs. meaningful
processing) — without settling which.

**Provisional kind:** architectural, explicitly torn between two positions
(as the remark itself argues both sides)

---

#### R122 — `doc/development/internals/examples/repl.md:39`

> REMARK: its literally called *with* config in the example above -- and config installs callback, which raises a question of API shape (why not have separate callbacks interface as the only way to set callbacks)

**Context:** under "## Notes," above "`compy.input.show{}` is called with no
config..."

**Asks for:** points out an inconsistency between the doc's claim (`show{}`
called with no config) and the example above it (which does pass config
including a callback), and questions the API shape choice of allowing
callbacks via `show`/`configure` config at all versus only via the
`callbacks` table.

**Provisional kind:** question, with an architectural angle

---

#### R123 — `doc/development/internals/examples/sapper.md:37`

> REMARK: why not align the hooks assignment and set mousepressed via hooks or shortcuts? it makes sense to discourage using love.<event> path, while keeping it supported as backwards-compatibility layer

**Context:** above "## Click handling," before the description of
`compy.input.hooks.singleclick`/`doubleclick` and `love.mousepressed`.

**Asks for:** proposes rewriting the sapper example to set `mousepressed`
via `compy.input.hooks`/`shortcuts` rather than `love.mousepressed`, to
model discouraging the `love.<event>` path while it stays supported for
backwards compatibility.

**Provisional kind:** architectural (about example code)

---

#### R124 — `doc/development/internals/examples/tixy.md:35`

> REMARK: did we decided to change preexisting behaviour by dropping legend on submit? maybe do not do it?

**Context:** above the `submit_body(lines)` code block.

**Asks for:** questions whether dropping the on-submit legend was an
intentional behaviour change; suggests possibly reverting it.

**Provisional kind:** question

---

#### R125 — `doc/development/internals/examples/turtle.md:17`

> REMARK: remove 'owner ruling' provisional reference, just say its done on purpsoe

**Context:** above the "Turtle also keeps its keyboard on
`love.keypressed`/`love.keyreleased` **on purpose** (owner ruling,
2026-07-31)." sentence.

**Asks for:** drop the "(owner ruling, <date>)" provisional-sounding
citation; just state it's done on purpose.

**Provisional kind:** prose

---

#### R126 — `doc/development/internals/project_sandbox_env.md:71`

> REMARK: Update 'exists, not a proposal' with concrete avaiability reference -- "since version..."

**Context:** attached to "### `compy.before_exit` — the project teardown
hook."

**Asks for:** add a concrete version reference ("since version...") to the
"It exists and is wired; it is **not** a proposal" claim about
`compy.before_exit`.

**Provisional kind:** prose

---

#### R127 — `doc/development/internals/project_sandbox_env.md:72`

> REMARK: during session 24 we discussed a conceptual problem that before_exit() cannot guarantee a teardown if project raises before being ablt to clean up. the prose below should be updated to refkect this concern and also reference the appropriate decisions and tech debt record (which in turn could reference back here) -- and the 'proposed robust fix' in the previous paragraph is precisely a counter-measure for this failure mode -- indentified, registered, not implemented (contrary to 'before_exit' hook)

**Context:** immediately follows R126, same location.

**Asks for:** update this section to document that `before_exit()` cannot
guarantee teardown if the project raises before cleanup, cross-reference the
relevant decision/tech-debt records, and note that the "proposed robust
fix" mentioned earlier in the doc is precisely the counter-measure for this
gap (identified/registered, not implemented).

**Provisional kind:** architectural / prose (documenting a known gap, not
proposing new behaviour)

---

#### R128 — `doc/development/internals/project_sandbox_env.md:92`

> REMARK: make pointer annotations more useful for reader, and also check their completeness/consistency and whther they are actual

**Context:** immediately above "## Pointers" (the doc's cross-reference
list).

**Asks for:** improve the "Pointers" section's cross-reference annotations
for usefulness, and audit them for completeness, consistency, and currency.

**Provisional kind:** prose

---

#### R129 — `doc/development/internals/user_input.md:12`

> REMARK: input widget is actualy not shared (as instance), so let's say "input widget instances used across". Word 'overlay' I'd prefer to not see anywhere -- just across "console, editor and projects"

**Context:** top-of-file, right after the "# User Input — Implementation
Overview" heading.

**Asks for:** correct the doc's opening framing — the input widget is not
literally a single shared instance (contradicts R088's related note); say
"input widget instances used across" console/editor/projects, and drop
"overlay" throughout.

**Provisional kind:** prose

---

#### R130 — `doc/development/internals/user_input.md:13`

> REMARK: "both now run" is related to project only -- refactoring console/editor management same way is suggested for the future, when project input controller will be battle-tested

**Context:** same top-of-file block, referring ahead to "Both now run
through the same project-route dispatch chain..." in the opening paragraph.

**Asks for:** clarify that "both now run through the same dispatch chain"
applies only to the project route; console/editor being refactored the same
way is a suggested future step, contingent on the project input controller
being battle-tested first.

**Provisional kind:** prose

---

#### R131 — `doc/development/internals/user_input.md:14`

> REMARK: in recent implementation pointer 'no shortcuts for pointer' should not be true -- the table must exist and be checked; combo of mods just constructed without 'trigger key'

**Context:** same top-of-file block, referring ahead to "...pointer channels
differ only in having no shortcuts tier and no combo trigger..." in the
opening paragraph.

**Asks for:** contests the "no shortcuts tier for pointer" claim (recurs
throughout the doc, see R161, R509-area) — asserts the shortcuts table
should exist and be checked for pointer too, just built from held modifiers
without a trigger key.

**Provisional kind:** architectural

---

#### R132 — `doc/development/internals/user_input.md:24-25` *(2-line remark, second line unmarked continuation)*

> REMARK: 'and project text solicitation'. "overlay" is a vague word, I want to avoid it. if we need to keep it let's say "project text solicitation (widget drawn as overlay)"
> "What differs is the configuration: decoration (prompt), initial text and callbacks responsible for evaluation, highlighting, and actions on submit/cancel"

**Context:** attached to "## Text Input Widget" heading, before "
`UserInputModel` / `UserInputController` / `UserInputView` form a shared
widget reused in three contexts: the console REPL, the editor input strip,
and project-created overlays..."

**Asks for:** replace "project-created overlays" with "project text
solicitation (widget drawn as overlay)" if "overlay" must be kept at all;
the second (unmarked) line proposes replacement wording for the following
sentence about what differs between the three widget hosts.

**Provisional kind:** prose

---

#### R133 — `doc/development/internals/user_input.md:48`

> REMARK: say that "defining its own" is compatibility layer, these functions are reinstalled as hooks 

**Context:** attached to "A project hooks `textinput` either via
`compy.input.shortcuts.textinput[combo]` / `compy.input.hooks.textinput`
... or by defining its own `love.textinput`, which auto-provisions as the
seeded hook..."

**Asks for:** clarify that "defining its own `love.textinput`" is the
backwards-compatibility path — such functions get reinstalled as hooks.

**Provisional kind:** prose

---

#### R134 — `doc/development/internals/user_input.md:77`

> REMARK: does this translation stay true for project's input widget (or was it ever true for project?)

**Context:** attached to "Mouse click on the input widget (translated from
screen coordinates to input grid via `_translate_to_input_grid`) sets the
cursor position..."

**Asks for:** questions whether the described mouse-click-to-cursor
coordinate translation actually applies to the project's input widget (or
ever did).

**Provisional kind:** question

---

#### R135 — `doc/development/internals/user_input.md:86`

> REMARK: "projects cannot install evaluator objects" is not correct now? we allow them to configure evalator function

**Context:** attached to the "### Evaluator and validation" section, above
the bullet list of evaluators, whose "Project overlays" bullet says
"Projects cannot install evaluator objects."

**Asks for:** questions whether "projects cannot install evaluator objects"
is still accurate, since projects can now configure a validator function.

**Provisional kind:** question

---

#### R136 — `doc/development/internals/user_input.md:95`

> REMARK: again, "overlay" -> "widget"

**Context:** attached to "Host evaluators can validate during editing. The
project overlay's public validator runs at submit..."

**Asks for:** another instance of the recurring "overlay" → "widget"
terminology request.

**Provisional kind:** prose

---

#### R137 — `doc/development/internals/user_input.md:126`

> REMARK: FR-1 is deelopment-time requirement id,(refid needs to be translated/deleted and essence needs to be explained to cold reader?)

**Context:** attached to "**FR-1's "initial cursor position" is implemented
at the controller layer, not the model's.**"

**Asks for:** the "FR-1" requirement-id reference is a development-time
artifact unexplained to a reader unfamiliar with it; needs either
translation/explanation or deletion.

**Provisional kind:** prose

---

#### R138 — `doc/development/internals/user_input.md:135`

> REMARK: "project overlay" -> "project input widget". This paragraph has to be rewritten into more readable form and actualized (i.e. project now can set prompt)

**Context:** attached to "'Reset the prompt' is four bespoke, mutually
inconsistent mechanisms, not one shared primitive: console's own Ctrl+L..."

**Asks for:** replace "project overlay" with "project input widget," and
rewrite this paragraph for readability and to reflect that a project can now
set its own prompt.

**Provisional kind:** prose

---

#### R139 — `doc/development/internals/user_input.md:150`

> REMARK: "No framework tier any more" -- there never was pre-feature; remove this reference, it describes self-inflicted-than-dissolved mechanism, which never was made public or stable

**Context:** attached to "## Keyboard Handling" section opening, "The
project route runs a per-event chain... There is no framework tier any
more..."

**Asks for:** remove the "no framework tier any more" framing — the
framework tier never existed pre-feature (it was self-inflicted during this
feature's own development and then dissolved), so "any more" is misleading.

**Provisional kind:** prose

---

#### R140 — `doc/development/internals/user_input.md:201`

> REMARK: "no longer routes on widget presence" is historical reference nobody is interested in -- it does not bear any information about current system for a cold reader ; in the past nobody relied on this occasional behaviour, its removal was one of the goals of new input API. So -- just strip this referencing-to-the-ancient-past part.

**Context:** attached to "The gateway (`love.handlers.*`) no longer routes
on widget presence — the overlay gate is removed..."

**Asks for:** strip the "no longer routes on widget presence" historical
framing; it conveys nothing useful to a cold reader about current behaviour.

**Provisional kind:** prose

---

#### R141 — `doc/development/internals/user_input.md:202`

> REMARK: console routing also was updated and no more consults widget shownness() -- could be stated as a matter of fact no refefences to the past 

**Context:** immediately follows R140, same location.

**Asks for:** state console routing's current behaviour (no longer consults
widget shownness) as a plain fact, without past-vs-present framing.

**Provisional kind:** prose

---

#### R142 — `doc/development/internals/user_input.md:206`

> REMARK: "no longer" relates to self-inflicted-then-dissolved behaviour, which never was characteristical of any stable release; remove referece and 'now-vs-then' vibe

**Context:** attached to "**The `'running'` → `'project_open'` boundary no
longer disconnects the project route at all**..."

**Asks for:** remove the "no longer" framing here too — same
self-inflicted-then-dissolved-behaviour argument as R139/R140.

**Provisional kind:** prose

---

#### R143 — `doc/development/internals/user_input.md:207`

> REMARK: paragraph below is overall too big and unreadable -- simplify/compress or even dissolve?

**Context:** immediately follows R142, same location, referring to the long
paragraph beginning "The `'running'` → `'project_open'` boundary no longer
disconnects..."

**Asks for:** compress or possibly remove the long paragraph following;
calls it too big and unreadable as-is.

**Provisional kind:** prose

---

#### R144 — `doc/development/internals/user_input.md:236`

> REMARK: there's no more forward_-calls (self-inflicted-then-dissolved), actualize towards actual behaviour and pre-feature behaviour (if changed)

**Context:** attached to "**`inspect` mode overrides all of the above.**
... every `forward_*` call in this section reports "no widget"..."

**Asks for:** the "`forward_*` call" mechanism described no longer exists
(another self-inflicted-then-dissolved artifact); update the paragraph to
describe actual current (and, if different, pre-feature) behaviour.

**Provisional kind:** prose

---

#### R145 — `doc/development/internals/user_input.md:250`

> REMARK: for pointer we will assemble combo strings without triggering keys

**Context:** attached to "`Controller.combo_string(k, keys_pressed)`
serialises a key event into a canonical combo string..."

**Asks for:** notes/confirms that pointer combo strings will be assembled
without a triggering key (modifiers only) — related to R131/R161's pointer-
shortcuts thread.

**Provisional kind:** architectural

---

#### R146 — `doc/development/internals/user_input.md:287`

> REMARK: check suggestion in other files -- remove keys_pressed from the argument, as its now available globally, and this would unify method signatures with ones used in love2d

**Context:** attached to "The whole keypressed path hands the widget the
uniform `(k, keys_pressed, isrepeat)` triple..."

**Asks for:** cross-references R097/R112's proposal — drop `keys_pressed`
from dispatch signatures now that it's globally readable, unifying
signatures with LÖVE2D's own.

**Provisional kind:** architectural

---

#### R147 — `doc/development/internals/user_input.md:288`

> REMARK: there's no more 'DEFERRED' I think -- we do not guard shortcuts but provide guarding wrapper for convenience

**Context:** immediately follows R146, same location (referring to
`isrepeat` gating on shortcuts, described elsewhere as a "deferred marker").

**Asks for:** contests the "deferred" framing for `isrepeat` gating on
shortcuts — argues the actual mechanism is that a guarding wrapper
(`ignore_repeat`) is offered for convenience, not that gating is an
unresolved/deferred question.

**Provisional kind:** prose

---

#### R148 — `doc/development/internals/user_input.md:328`

> REMARK: FR-6 is ref-id unknown to reader (implementation-time encoding of requiements)

**Context:** attached to "**FR-6 (project notification of key events): the
keyboard exclusion is resolved as of 1.0.0-rc20260712.**"

**Asks for:** same concern as R137 — the "FR-6" requirement-id reference is
meaningless to a reader unfamiliar with the implementation-time id scheme.

**Provisional kind:** prose

---

#### R149 — `doc/development/internals/user_input.md:393`

> REMARK: while 'oneshot' flag was really removed, the "separate framework-owned submit path" did not exist as a concept pre-feature so there's no need to mention it (correct me if I am wrong)

**Context:** attached to "There is no `oneshot` flag any more, and no
separate framework-owned submit path — there is no framework tier at all
(Decision 2)."

**Asks for:** questions/proposes removing the "no separate framework-owned
submit path" clause — argues that concept never existed pre-feature, so
there's nothing to say "no longer" about; explicitly invites correction if
wrong.

**Provisional kind:** question

---

#### R150 — `doc/development/internals/user_input.md:440`

> REMARK: heavy, unreadable paragraph below, rewrite

**Context:** attached to "### Search — a third widget instance, live only in
editor/search mode," above the dense paragraph describing
`EditorController.search`.

**Asks for:** rewrite the following paragraph; calls it heavy and
unreadable.

**Provisional kind:** prose

---

#### R151 — `doc/development/internals/user_input.md:468`

> REMARK: reference specific version not just 'input API' but 'input API (1.0.0-rc...)

**Context:** attached to "### Future editor migration path (analysis, not
scheduled)," above "The input API makes a later editor migration
possible..."

**Asks for:** cite the specific input API version (`1.0.0-rc...`) rather
than the bare phrase "input API."

**Provisional kind:** prose

---

#### R152 — `doc/development/internals/user_input.md:509`

> REMARK: there should be shortcuts tier for pointer, I think we agreed on this -- if we deferred it, it should be said so. And project SHOULD be able to register shortcuts.

**Context:** attached to "## Mouse Input" → "### Unified dispatch," above
"Pointer channels enter the walk one tier in, at the hook: there is no
shortcuts tier and no combo trigger for pointer..."

**Asks for:** another instance of the pointer-shortcuts thread (R131,
R145) — asserts there should be a shortcuts tier for pointer per a prior
agreement; if deferred, that should be stated explicitly, and projects
should be able to register pointer shortcuts.

**Provisional kind:** architectural

---

#### R153 — `doc/development/internals/user_input.md:536`

> REMARK: do not just say they are removed -- say they are repositioned -- firing happens on the `love.handlers.*` surface, mimicing the native love2d events. Project consumption lives in compy.input.hooks/compy.input.shortcuts. (at least its how I expect things to be)

**Context:** attached to "`compy.singleclick` and `compy.doubleclick` —
fields on the project's `compy` table that the old framework code looked up
and called directly — are **REMOVED**."

**Asks for:** reframe the singleclick/doubleclick documentation — they are
not simply "removed," they are repositioned: firing now happens on
`love.handlers.*`, mimicking native LÖVE2D events, with project consumption
through `compy.input.hooks`/`shortcuts`. Notes this is the owner's
expectation, inviting confirmation.

**Provisional kind:** prose

---

#### R154 — `doc/development/internals/user_input.md:537`

> REMARK: we can support seeding them from projects userlove -- as well as other events. We just do not encourage doing it in new and old projects, to avoid confusion

**Context:** immediately follows R153, same location.

**Asks for:** proposes documenting that singleclick/doubleclick (and other
events) can still be seeded from a project's own `love.*` table, while
discouraging that path in new and existing projects to avoid confusion.

**Provisional kind:** architectural

---

#### R155 — `doc/development/internals/user_input.md:584`

> REMARK: retire 'overlay' completely as terminology . it can be used only contextually (when we want to emphasize the fact how project input widget is drawn)

**Context:** attached to "## The `user_input` Overlay — Input Perspective"
heading.

**Asks for:** another "overlay" terminology remark — retire the term except
when contextually emphasizing that the project input widget is drawn as an
overlay.

**Provisional kind:** prose

---

#### R156 — `doc/development/internals/user_input.md:617`

> REMARK: even if there was 'instead of the main controller' path I doubt somebody relied on it or called it that way; therefore reference could be dropped.

**Context:** attached to "### Dispatch while active," above "While a project
runs, `compy.input.show(config)`/etc. drive the *same* widget instance...
there is no separate "instead of the main controller" special case any
more."

**Asks for:** drop the "no separate 'instead of the main controller'
special case any more" reference; doubts anyone relied on or referred to
such a path.

**Provisional kind:** prose

---

#### R157 — `doc/development/internals/user_input.md:634`

> REMARK: 'no framework tier any more' -- and there was not before feature,so let's not reference self-inflicted-than-dissolved mechanisms nobody ever saw

**Context:** attached to "### Submit and cancel — widget-owned callback
sequences," above "Enter and Escape are **ordinary keys handled by the
widget itself** (Decision 6) — there is no framework tier any more..."

**Asks for:** same recurring request as R139/R142/R157 — drop the "no
framework tier any more" framing for this section too.

**Provisional kind:** prose

---

#### R158 — `doc/development/internals/user_input.md:649`

> REMARK: what do you mean 'reserved, unbuilt' and what is R9? If we declare that callback should be veto-ing, than it should be

**Context:** immediately above the `run_callback(self, 'before_submit',
keys_pressed)   -- veto reserved, unbuilt (R9)` code block.

**Asks for:** questions the meaning of "reserved, unbuilt" and the "R9"
reference; if `before_submit` is meant to be able to veto, it should
actually be built, not left reserved.

**Provisional kind:** question

---

#### R159 — `doc/development/internals/user_input.md:660`

> REMARK: and there was no implicit hide so 'anymore' is improper and whole reference can be removed. or just say -- "there's no implicit hide". asme abot 'no longer auto-closes' -- it never was unless configured with 'one-shot' flag (now replaced by callbacks).

**Context:** immediately above "`on_text_entered` fires **while the widget
is still active** — there is no implicit hide any more."

**Asks for:** drop "any more" — there never was an implicit hide by
default; suggests "there's no implicit hide" instead, and applies the same
correction to "no longer auto-closes" (only true when the retired
`oneshot` flag was set).

**Provisional kind:** prose

---

#### R160 — `doc/development/internals/user_input.md:661`

> REMARK "unbuild, R9" should not be . it should be built at that moment. absolutely cheap change. 

**Context:** immediately follows R159, same location, referring back to the
`before_submit` veto code snippet (same subject as R158).

**Asks for:** reiterates R158 — the `before_submit` veto should actually be
implemented ("built"), not left as a reserved/unbuilt marker; calls it a
cheap change.

**Provisional kind:** mechanical (proposes an actual code change, not just
a documentation fix)

---

#### R161 — `doc/development/internals/user_input.md:677`

> REMARK: "unlike_submit" should be wrong because submit should also be honored 

**Context:** immediately above "Unlike submit, `before_cancel`'s return
value **is honoured**: a truthy return vetoes the clear step entirely..."

**Asks for:** contests the "unlike submit" framing — argues `before_submit`
should also have its return value honoured (ties back to R158/R160's veto
request), so the asymmetry described here shouldn't exist.

**Provisional kind:** architectural

---

#### R162 — `doc/development/internals/user_input.md:701`

> REMARK: this archeology should've been removed, it serves no purpose except confusion (not to be confused though with love.state.user_input that is a flag telling view to draw)

**Context:** immediately above "One vestige of the old mechanism remains in
the gateway: `love.handlers.userinput`..."

**Asks for:** remove the "one vestige... `love.handlers.userinput`"
paragraph describing dead code; calls it confusing archeology (while
clarifying it should not be conflated with the still-live
`love.state.user_input` flag).

**Provisional kind:** prose

---

#### R163 — `doc/development/internals/user_input.md:710`

> REMARK: hook names are actual I hope. Formula still sounds weird. And I am not sure what paragraph tries to communicate -- remove it?

**Context:** immediately above "This whole `before_*`/`after_*` +
widget-output surface (`on_text_entered`, `on_limit_reached`, `validator`,
`highlighter`)... is now live in `src/`..."

**Asks for:** questions whether the listed hook/callback names are still
accurate, finds the sentence's phrasing awkward, and questions the
paragraph's purpose — proposes possibly removing it.

**Provisional kind:** unclear (mixes a factual-accuracy question, a prose
complaint, and an open removal proposal)

---

#### R164 — `doc/development/internals/user_input.md:720`

> REMARK: why restate the shape of API there? Just tell what the table is and where its constructed and where its described

**Context:** attached to "### `compy.input` namespace," above "`compy.input`
is a table created once per project environment..."

**Asks for:** trim this section to just state what `compy.input` is and
where it's constructed/described, rather than restating the API's shape
(already covered elsewhere).

**Provisional kind:** prose

---

#### R165 — `doc/development/internals/user_input.md:765`

> REMARK: it belongs to API documentation, do not duplicate here if not needed. Or describe one-level-of-abstraction-up -- tell what this api is capable of doing, not invocation details and signatures

**Context:** immediately above "#### `show(config)` — activate."

**Asks for:** either remove the `show(config)` field-by-field documentation
here (it duplicates `doc/input_api.md`) or raise it one level of
abstraction — describe capability, not invocation details/signatures.

**Provisional kind:** architectural (documentation structure)

---

#### R166 — `doc/development/tests.md:59`

> REMARK: we do not care where it originally lived as it was mid-implementation. such an ephemeral archeology is irrelevant for persistent doc -- describe current state of things 

**Context:** attached to "## Input Contract Suite (Compy input API)," above
"The `#input` contract suite originally lived in one large file
(`input_contracts_spec.lua`)..."

**Asks for:** remove the "originally lived in one large file" history — a
mid-implementation detail irrelevant to a persistent doc; describe only the
current state.

**Provisional kind:** prose

---

#### R167 — `doc/development/tests.md:60`

> REMARK: also actualize if file/tag/line references are still valid, but first ask yourself, are they really needed for bird-eye overview of testing subsystem?

**Context:** immediately follows R166, same location.

**Asks for:** verify the section's file/tag/line references are still
accurate, but first question whether they're needed at all for a high-level
testing-subsystem overview.

**Provisional kind:** question

---

#### R168 — `doc/development/technical_debt/general.md:16`

> REMARK: its not a defect, but convention -- gfx is alias for love.graphics, sfx is alias for compy.audio 

**Context:** immediately above "## `gfx` implicit global in
`controller.lua`," a technical-debt entry describing `gfx` as an undeclared
free variable.

**Asks for:** contests classifying `gfx` as a defect — argues it's a
convention (an alias for `love.graphics`, alongside `sfx` for
`compy.audio`), implying the tech-debt entry should be reclassified or
removed.

**Provisional kind:** architectural (contests a tech-debt classification)

---

#### R169 — `doc/development/technical_debt/input.md:9` *(marker: `REVIEW:`)*

> REVIEW: drop everything resolved, actualize the list, and maybe make it a bit more comprehensive (less prose, more facts). ToC (list) at the beginning would also help

**Context:** top-of-file, right after the frontmatter, before "# Input
subsystem."

**Asks for:** a general cleanup pass on this tech-debt register: drop
resolved items, update the list, favor facts over prose, and add a
table-of-contents at the top.

**Provisional kind:** architectural (documentation structure)

---

#### R170 — `doc/development/technical_debt/input.md:10` *(marker: `REVIEW:`)*

> REVIEW: absolutely no mentioning of particular commits is allowed, they will be reassembled for the PR

**Context:** immediately follows R169, same location.

**Asks for:** a hard constraint — remove all references to particular
commit hashes/names from this document, since commits will be reassembled
for the PR.

**Provisional kind:** mechanical

---

#### R171 — `doc/input_api.md:11`

> REMARK: rewrite intro completely, be dev-friendly. Vague statements do not help. Just tell its an API for configuring and interacting with text solicitation subsystem, and for reacting to user input events (all of them). Tell that even when widget is not shown or used, still it can be used to manage hotkeys, combos etc.

**Context:** top-of-file, right after "# Compy Input API," before "This
guide is for projects running inside Compy..."

**Asks for:** rewrite the guide's introduction to be concrete/dev-friendly:
state plainly it's an API for configuring/interacting with the text
solicitation subsystem and reacting to all input events, and note it's
usable for hotkeys/combos even without the widget shown.

**Provisional kind:** prose

---

#### R172 — `doc/input_api.md:17`

> REMARK: would it help readability if we conceptually split API into three surfaces (and say so): a) dispatching/intercepting inbound events via shortcuts and hooks b) altering the soliciting widget state (hide/show/cursor/reconfigure) c) handling events generated inside widget via callbacks (submit, cancel, limit...)

**Context:** above "## Quick start."

**Asks for:** proposes restructuring the guide around three named API
surfaces — inbound event interception (shortcuts/hooks), widget state
control (show/hide/cursor/reconfigure), and widget-originated event
handling (callbacks).

**Provisional kind:** architectural (documentation structure)

---

#### R173 — `doc/input_api.md:164`

> REMARK: why developer would even think of reading love.state?

**Context:** immediately above "Do not read `love.state` for this: a
project runs in a sandboxed copy of `love`..."

**Asks for:** questions why the guide needs to warn against reading
`love.state` at all — implies the warning may be unnecessary or should
explain why a developer would be tempted to.

**Provisional kind:** question

---

#### R174 — `doc/input_api.md:246`

> REMARK: retire word 'overlay' -- "stop reaching the input widget too" is a proper formula 

**Context:** immediately above "All three wrap a hook the same way, but
think before you do: a whole-channel hook wrapped in
`stop_here(ignore_repeat(...))` swallows every repeat on that channel, so
held backspace and held arrows stop repeating in the overlay too."

**Asks for:** another "overlay" terminology remark; suggests the phrase
"stop reaching the input widget too" as the replacement formula.

**Provisional kind:** prose

---

#### R175 — `doc/input_api.md:252`

> REMARK: "not expressible as shortcuts and should be processed inside hook, if needed"

**Context:** immediately above "Combos of ordinary keys — "A and B held
together" — are deliberately not expressible..."

**Asks for:** proposes adding/adjusting wording along the lines of "not
expressible as shortcuts and should be processed inside hook, if needed."

**Provisional kind:** prose

---

#### R176 — `doc/input_api.md:253`

> REMARK: we may decide not to deliver keys_pressed as an argument, expecting project to access it via compy.input.keys_pressed instead (already available) -- lets popularize that way

**Context:** immediately follows R175, same location.

**Asks for:** another instance of the keys_pressed-argument-removal thread
(R097/R112/R146) — proposes popularizing `compy.input.keys_pressed` as the
access path instead of the per-call argument.

**Provisional kind:** architectural

---

#### R177 — `doc/input_api.md:292`

> REMARK: there should be pointer shortcuts!

**Context:** immediately above "There are no pointer *shortcuts* — a combo
needs a key to name, so `shortcuts` covers the keyboard and text channels
only."

**Asks for:** another instance of the pointer-shortcuts thread (R131, R145,
R152) — asserts pointer shortcuts should exist, contesting the doc's current
"there are no pointer shortcuts" statement.

**Provisional kind:** architectural

---

#### R178 — `doc/input_api.md:298`

> REMARK: not 'overlay', but 'input widget'

**Context:** above "## Opening the overlay from a key."

**Asks for:** another "overlay" → "input widget" terminology remark, this
time targeting the section heading itself.

**Provisional kind:** prose

---

#### R179 — `doc/input_api.md:299`

> REMARK: frame this whole paragraph as example of solving non-conventional challenge (preventing modifier-based hotkey from echoing into the input widget), not say "if you open with 'i'" as if it was some common or recommended convention

**Context:** immediately follows R178, same location, referring to the
"Opening the overlay from a key" section that follows.

**Asks for:** reframe the section: present it as an example of solving a
specific non-conventional problem (preventing a modifier-based hotkey's
character from echoing into the widget), not as documenting `'i'` as a
common/recommended convention.

**Provisional kind:** prose

---

#### R180 — `doc/input_api.md:329`

> REMARK: term 're-arm' is invented -- if you use it, make sure its explained or defined in the same doc, upfront.

**Context:** immediately above "Re-arm wherever you close the overlay: one
that is closed without re-arming takes the echo on its next open."

**Asks for:** either stop using the invented term "re-arm," or define it
explicitly and upfront in this document if it's kept.

**Provisional kind:** prose

---

#### R181 — `doc/input_api.md:392`

> REMARK: it should be able to suprress/defer the stop?  or if its not allowed purposefully -- that it should not be announced as 'deferred' functionality in other part of documentation

**Context:** immediately above "- **Return value:** ignored. It cannot
suppress or defer the stop." (in the `compy.before_exit` reference section).

**Asks for:** questions whether `before_exit` should be able to
suppress/defer the project stop; if that's deliberately disallowed, other
documentation should not describe it as merely "deferred"/pending
functionality.

**Provisional kind:** question, with an architectural angle

---

### agents/

*(No remarks — see Part 3: a new file, `agents/rules/commenting.md`, was
added by this review commit, but it is authored content, not an annotation
on existing text, so it is not inventoried as a remark.)*

---

### CHANGELOG.md

#### R182 — `CHANGELOG.md:1`

> REMARK: too shy for major changes done -- rewired dispatching, unblocked event-handling, new topology with shortcuts/hooks.... many documentation and technical debt added. And version is 1.0.0-rc...

**Context:** the very first line of the file, before "# Changelog."

**Asks for:** the changelog undersells the scope of what shipped —
dispatching was rewired, event-handling unblocked, a new
shortcuts/hooks topology added, plus substantial documentation and
technical-debt additions — and the version is a release-candidate
(`1.0.0-rc...`); implies the changelog entry should be expanded/rewritten
to reflect this.

**Provisional kind:** prose

---

### Nested repos

#### R183 — `src/examples/balloons/terminal.lua:4-5` (nested repo `balloons`, 2-line remark)

> ---> REMARK: can we somehow simplify setup of the deliver handler? now its literally 3 functions juggling each other. Can be one?a
> ---> In fact, after submit we should deliver, clear *and* update prompt; and expose 'update-prompt' endpoint so that game can write its own welcome messages when mode is iswitched

**Context:**
```lua
require("helpers")
require("debugfunc")

---> REMARK: can we somehow simplify setup of the deliver handler?...
---> In fact, after submit we should deliver, clear *and* update prompt...

-- Deferred until game_init() builds the real router (ui.lua
-- requires this file, and therefore activates the session,
local current_handler = noop
```

**Asks for:** simplify the "deliver handler" setup (currently three
functions coordinating each other) into one; separately proposes that
after-submit should deliver, clear, and update the prompt together, and
that an "update-prompt" endpoint be exposed so the game can write its own
welcome messages on mode switches.

**Provisional kind:** architectural

---

#### R184 — `src/examples/maze/main.lua:456` (nested repo `maze`)

> ---> REMARK: comment *tooo* verbose. simplify/compress 

**Context:** above the "The prompt is up exactly while the player is
idle, and rearm_input (ctrl_update, every tick) keeps those two in sync..."
comment block (lines 457-477), preceding `open_editor_input`.

**Asks for:** shorten/compress the long comment block that follows.

**Provisional kind:** prose

---

#### R185 — `src/examples/maze/main.lua:496` (nested repo `maze`)

> ---> REMARK: can we try using shortcuts/hooks and callbacks more actively?

**Context:** between `handle_editor_submit` and `player_is_idle`, no
attached code block — a standalone suggestion.

**Asks for:** proposes making more active use of `compy.input`
shortcuts/hooks/callbacks in this example, rather than the current input
handling shape.

**Provisional kind:** architectural

---

#### R186 — `src/examples/keyboard/input.lua:49` (nested repo `keyboard`)

> ---> REMARK: WHY WOULD WE DO IT AND WHY USE custom 'INPUT' at all?

**Context:**
```lua
INPUT = setmetatable({ upRecent = { } }, {
  __index = function(_, k)
    ---> REMARK: WHY WOULD WE DO IT AND WHY USE custom 'INPUT' at all?
    if k == "held" then return compy.input.keys_pressed end
    if k == "shift" then return modHeld("lshift", "rshift") end
```

**Asks for:** questions the entire premise of the custom `INPUT` global
wrapper table in this example — why it's needed at all, given
`compy.input.keys_pressed` is directly available.

**Provisional kind:** question (with an architectural undertone — may be
asking to remove the wrapper)

---

#### R187 — `src/examples/keyboard/input.lua:91` (nested repo `keyboard`)

> --> REMARK: what is it for? (setTextInput)

**Context:**
```lua
function inputInit()
  --> REMARK: what is it for? (setTextInput)
  love.keyboard.setTextInput(true)
  INPUT.upRecent = { }
```

**Asks for:** questions the purpose of the `love.keyboard.setTextInput(true)`
call in `inputInit`.

**Provisional kind:** question

---

## Part 3 — Observations for the parent

- **Recurring theme, "overlay" terminology.** At least **17** separate
  remarks across `doc/development/decisions/input.md`,
  `doc/development/internals/user_input.md`, `doc/input_api.md`, and the
  `examples/*.md` docs (R088, R111, R119, R129, R132, R136, R138, R141,
  R155, R174, R178 plus related asides in R130/R134) independently ask to
  retire the word "overlay" in favour of "(project) input widget." This
  reads as one global find-and-replace-with-judgment task, not N
  independent decisions — cheap to batch.

- **Recurring theme, drop `keys_pressed` from callback signatures.** R097,
  R112, R146, R176 (four remarks, three files) all propose the same change:
  since `compy.input.keys_pressed` is globally readable, stop threading it
  as a positional argument to shortcuts/hooks/widget calls, aligning
  signatures with LÖVE2D's own. R009 (consoleController.lua:437) flags that
  `ignore_repeat` would need updating as a consequence if this lands.

- **Recurring theme, pointer shortcuts.** R131, R145, R152, R177 (four
  remarks, two files) all assert that a shortcuts tier for pointer
  events should exist (modifier-only combos, no trigger key), contradicting
  the current doc/code statement that "there are no pointer shortcuts."
  R037 (`projectInputController.lua:194`) is the corresponding code-side
  remark asking for the same capability, including open questions about
  right-button and button-count support.

- **Recurring theme, "no X any more" / historical-contrast phrasing.**
  R082, R083, R139, R140, R142, R144, R149, R156, R157, R162 (ten remarks,
  concentrated in `decisions/input.md` and `user_input.md`) all object to
  the same stylistic pattern: describing current behaviour by contrasting it
  with an intermediate, never-released shape from mid-implementation
  ("no longer," "any more," "used to"). The owner's stated position (R104,
  R169-adjacent) is that anything not in a released version should be
  written as if it never existed. This is a single editorial policy, not
  ten separate ones — likely the single highest-leverage batch in the whole
  inventory.

- **Recurring theme, `Decision 9`/keys_pressed threading may be droppable
  wholesale.** R096-R099 (four consecutive remarks on
  `decisions/input.md`, all on Decision 9) escalate from "reword" to "maybe
  delete the whole decision and its codebase counterparts" — R099
  explicitly asks whether this should happen "pre-PR." This cluster reads
  as a single architectural question the owner is still working out loud,
  not four independent asks.

- **Possible internal contradiction the parent should verify:** R086
  (`decisions/input.md:167`) says a nearby *other* paragraph in the same
  document (not itself carrying a REMARK) claims widget state is "checked
  at the end of chain, and bypassed if not shown" and calls that other
  paragraph stale/contradictory. I did not locate and diff that specific
  other paragraph against R086's claim — worth the parent confirming which
  paragraph it refers to and whether the contradiction is real.

- **Two remarks argue opposite sides of the same question without
  resolving it:** R121 (`examples/repl.md:15`) argues both "maybe
  `on_text_entered`/`after_submit` are a redundant architectural smell" and
  "actually keeping both is a good, deliberate pattern" in the same
  breath. Flagging since it cannot be classified as a single clear ask.

- **A veto/hook-completeness thread:** R158, R160, R161 (three remarks, one
  file, `user_input.md:649-677`) together argue that `before_submit`'s veto
  return should be *built* now (not "reserved, unbuilt (R9)"), and that
  `before_cancel`/`before_submit` asymmetry (only cancel's return is
  honoured) should be resolved by honouring submit's too. This is a
  concrete, small, code-affecting request bundled inside what otherwise
  reads as documentation remarks — worth flagging to the parent as
  possibly `mechanical`/code-level despite living in a doc file.

- **`agents/rules/commenting.md` is new content, not a remark.** The review
  commit `9cc0ef50` added this file wholesale (15 lines, a house style
  guide for comments, ending in "META-RULE: comment should not exist if it
  does not bear any valuable information"). It is not extracted as an
  inventory entry since it doesn't annotate existing text, but the parent
  should know it exists and is now in scope as project policy — several
  remarks in this very inventory (e.g. R017, R039, R050-R055) are direct
  applications of that new rule.

- **A remark referencing a `REMARK` id that doesn't exist elsewhere:** R036
  (`projectInputController.lua:158`) says "as said in other remark (on
  documentation)" — this is very likely referring to R131/R145/R152/R177
  (the pointer-shortcuts thread) but names no specific remark id, since ids
  didn't exist until this inventory. No mismatch, just noting the
  cross-reference for the parent's convenience when triaging.

- **`R9` is a requirement-id the remarks themselves flag as opaque.** R158
  and R137/R148 (FR-1, FR-6) all independently object to bare requirement-id
  citations (`R9`, `FR-1`, `FR-6`) appearing in permanent docs without
  explanation — this is itself a small recurring-theme cluster distinct
  from the veto-thread above.

- **Everything under `doc/development/wip/` was left untouched** per scope
  boundaries — 17 `REMARK` + 274 `REVIEW:` hits across 93 files, confirmed
  historical/template rather than owner-authored review of the current
  state, not further inspected.
