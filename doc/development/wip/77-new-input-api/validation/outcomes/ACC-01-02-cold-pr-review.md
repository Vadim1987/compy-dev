# Review — the new input API (feature #77)

Reviewer: cold reviewer, stakeholder side. Ground truth: `baseline/` + `slices/`. I did not read
`/repo` and did not use the language server. I cannot run the code, the tests, or the device.

---

## Verdict

**Merge with changes.** The core of this is right and I would not want it re-cut. The three faults
the ask named — polling instead of events, the keyboard lockout while a prompt is up, and no
show/hide without teardown — are each fixed at the structural level rather than papered over, and
the fix is genuinely *simpler* than what it replaces: nine near-identical `set_love_*` installers
collapse into one generator, the `get_user_input()`-in-every-gateway-entry pattern is deleted from
eleven places, `oneshot` and the `result` reftable are gone, and the migrated examples are all
shorter. The migrations in `3g`/`4a`–`4c` are real and demonstrate the API works. The test slice is
large, behaviour-shaped, and drives the real production wiring.

What holds it back is not the routing core. It is that **the PR description is materially wrong
about the change it describes** — it advertises a member (`compy.input.keys_pressed`) that the code
does not contain and states a design decision ("No pointer shortcuts") that the code and the guide
both contradict. Going to a stakeholder audience that reads the description first, that alone is a
blocker for the *PR*, if not for the diff. Beneath that there is one real cross-project state leak
(`state.pending`), one contract hole (a highlighter cannot be turned off for the rest of a run), a
docs slice that contradicts its own new convention, and a CHANGELOG that omits the breaking
removals that are the whole point of D-1.

None of those require re-architecting. Fix the description, clear `pending` at teardown, and the
rest is cleanup.

---

## Against the ask

Walking `spec/01` — the requester's own words — request by request.

| Request (quoted from `spec/01`) | Verdict | Where |
|---|---|---|
| "setting up an edit area with an optional non-empty content, syntax highlighter and input validator" | **Delivered** | `3e`, `api_show`/`open_widget`/`apply_config`; every key independently optional, closed config table |
| "receiving callbacks on the user entering something on it" | **Delivered** | `3e`, `UserInputController:submit_flow`; `on_text_entered(lines)` |
| "an API that allows for an easy implementation of interfaces that are similar to either the command console or the editor" | **Delivered** | `3d` `dispatch` is a free function over plain tables; `3e` `build_widget_api` is parameterised by resolver |
| "Ideally, these should also be re-implemented using the same API" | **Partly** — not done, and openly declared not done (`05` open question 4). One piece did move: console history navigation now rides `on_limit_reached` (`3e`, `ConsoleController.new`). Everything else in console/editor still bypasses `compy.input` entirely. The reusable seam exists but has no second adopter, so its adequacy is asserted, not demonstrated | `3e`, `main.lua` comment |
| "callbacks for keys pressed together with the Ctrl key" | **Delivered** | `3d` `combo_string`/`find_shortcut`; `shortcuts.keypressed['ctrl+s']` |
| "or keys that do not insert or remove a symbol in the edit area" | **Delivered** | `3d` `hooks[event]` per channel; a hook sees every key on its channel |
| "function keys ... only work with external keyboard, the internal ones are hijacked by the OS" | **Delivered as documentation** — no code could fix it. The guide states F1–F9 never arrive, F10 is the platform's, F11/F12 untested | `3a` `doc/input_api.md`, "Combos the framework keeps" |
| "a callback ... for cursor movements that 'hit a wall'" | **Delivered, and exceeds the ask** — `on_limit_reached(direction, scope)` covers up/down *and* the left/right case the stakeholder added in round 2, with the `'input'`/`'line'` scope distinction he asked for | `3e` `emit_limit`/`horizontal_limit_scope`; `3f` `UserInputModel:is_at_limit` |
| "and, of course, entering a line" | **Delivered** | `3e` `submit_flow` |
| "Calls ... for setting up an edit area (with an optional initial text, cursor position, highlighter and verifier)" | **Delivered** | `3e` `SHOW_KEYS` |
| "and for removing the edit area" | **Delivered as something else** — there is `hide()`, no `remove()`. The widget is a boot-provisioned singleton (`3e`, `main.lua`) that is never destroyed; FR-2 (remove) and FR-3 (hide) collapse into one call. Defensible under NFR-1 (no per-session object graph), but the ask distinguished them and nothing in the guide says the distinction was deliberately dropped | `3e` `UserInputController:hide` |
| "for querying and changing the cursor's position, and changing the text" | **Delivered** | `3e` `get_cursor`/`set_cursor`/`set_text`/`clear` |
| "handling keyboard events in parallel to editing is a PITA" | **Delivered — this is the best part of the change.** Widget visibility stopped being a routing condition; a project's own handler now runs while a prompt is up | `3d` `handlers.keypressed`, `ProjectInputController.dispatch` |
| "it is not easy to hide or show the input area (see your struggles in sapper)" | **Delivered** | `3e` `show`/`hide` with state preserved |
| D-1: "getting rid of the legacy API, ASAP" + migrate maze/balloons/tixy | **Delivered** — `user_input`/`input_text`/`input_code`/`validated_input`/`write_to_input` and the four evaluator globals are removed and withheld from the project env; every tracked example and all three companion repos are migrated | `3e` `prepare_project_env`; `3g`, `4a`, `4b`, `4c` |
| Round 2: "block [a second `show()`] ... and offer a flag for 'I know what I'm doing'" | **Delivered, incompletely** — `force` exists but only re-applies `text`. `show{force=true, prompt='x'}` silently drops the prompt (see finding 5) | `3e` `re_show` |
| Round 2: "it's straightforward to create a proxy table that allows read indexing but not write indexing" (`keys_pressed`) | **Not delivered — and answered by removal.** Decision 30 dissolved `keys_pressed` entirely; held state is now `Key.any_pressed` / `Key.ctrl()` etc. The stakeholder's *underlying* need is met and the reversal is recorded honestly in `3a`. But he asked a specific question about a specific table and the answer is "that table no longer exists", which the PR description does not say | `3f` `util/key.lua`; `3a` decisions Decision 30 |
| Round 2: "it should not be named `ProjectController` ... call it `ProjectInputController`" | **Delivered** | `3d` `src/controller/projectInputController.lua` |

---

## Findings

### 1. BLOCKER — the PR description describes a different change than the one in the diff

`spec/05-pr-description-DRAFT.md` is the document a stakeholder reads first, and two of its
load-bearing claims are false against the code.

**a. `compy.input.keys_pressed` does not exist.** `05` line 71 gives it a table row and a
justification ("Held keys, readable **outside** an event … a real project needed this and had been
maintaining its own mirror"). Grep the whole delivery: `keys_pressed` appears only in `3a`'s docs,
where Decision 30 records it **dissolved** ("`compy.input.keys_pressed` and `Controller.keys_pressed`
are dissolved from all …"). `3e`'s `build_widget_api` and `build_input_surface` have no such member.
The example that motivated it — `keyboard` — was migrated to `Key.any_pressed` instead
(`4c-keyboard.patch:197`, `:456`, `:499`). A project author who builds a prompt from the description
will write `compy.input.keys_pressed['lshift']`, index `nil`, and crash.

**b. "No pointer shortcuts" is wrong.** `05` line 77: *"**No pointer shortcuts.** A combo names a
key; a pointer event has none. Pointer starts at the hook tier."* The code does the opposite:
`3d-routing-core.patch:1337` defines `TRIGGER.mousepressed`/`mousereleased` serialising the button as
`'mouseN'`, `find_shortcut` (`:1394`) matches modifier classes on the triggerless pointer channels,
and `doc/input_api.md` documents `shortcuts.mousepressed['mouse2']` and
`shortcuts.mousemoved['ctrl+*']` with examples. `3b-tests.patch:3543` has a whole `describe('pointer
shortcuts')` block. `05`'s own "Ratified deviations" table even says "Pointer joined the chain" three
lines later — the document contradicts itself.

**Why it matters:** the brief for this PR states the description should let a reviewer judge the
change from it plus `doc/input_api.md` alone. It cannot. It is dated 2026-08-03 and the delivery has
moved past it. Rewrite it before this goes to stakeholders; the guide in `3a` is accurate and can be
the source.

---

### 2. MAJOR — `state.pending` survives a project stop, so one project's draft text opens in the next project's widget

`3e-widget-surface.patch:585-596`, `get_compy_input`, builds
`state = { shortcuts, hooks, callbacks, pending = {} }`.

`configure()` while the widget is hidden stashes `prompt`/`text`/`cursor` into `state.pending`
(`:443` `stash_hidden_configure`), and the next `show()` consumes them (`:427` `consume_pending`).

Teardown does not clear it. `3d-routing-core.patch:318` `reset_compy_input` wipes `shortcuts` and
nils `hooks`; `:339` `reset_widget_outputs` re-seeds `callbacks` and clears the evaluator
highlighter. Nothing touches `pending`.

And `state` is app-lifetime, not per-run. `ConsoleController.prepare_project_env` — the only caller of
`get_compy_namespace` → `get_compy_input` — is invoked exactly once, from `ConsoleController.new`
(`baseline/platform/src/controller/consoleController.lua:71`); grep confirms no other call site. The
env is then `table.clone`d (shallow) into `base_env` and `project_env`, so every project run for the
life of the app shares one `compy` table and one `state`.

**Failure scenario:** project A runs, calls `compy.input.configure{ text = 'my draft' }` while the
widget is hidden, and stops without showing. Project B runs and calls `compy.input.show{ prompt =
'name?' }`. B's field opens pre-filled with `my draft`. Same for a leaked `prompt` or `cursor`.

This directly violates the PR's own stated invariant (`05` line 57: *"Nothing a project installed
survives it"*) and Decision 11's teardown invariant that the code comments cite six times.

**Fix:** one line in `reset_compy_input` — the `state` table is already reachable from the surface's
closure; expose it or wipe `pending` alongside `hooks`. Add a test; `3b` has none for it.

**Related:** `3a`'s technical-debt ledger has an entry
*"`compy.input` is rebuilt per project environment, not once at namespace setup"* whose premise is
**factually wrong** ("the function that builds `compy.input` is called every time a project
environment is prepared") and whose disposition — *"Accepted, no action expected"* — rests entirely
on that wrong premise. That entry is what would have caught this. It should be corrected or deleted;
leaving it means the next maintainer re-derives a false fact from the ledger.

---

### 3. MAJOR — a highlighter cannot be turned off for the rest of a run

`3e-widget-surface.patch:412` `merge_callback_keys`:

```lua
for _, k in ipairs(CALLBACK_KEYS) do
  if cfg[k] ~= nil then state.callbacks[k] = cfg[k] end
  cfg[k] = state.callbacks[k]          -- absent -> re-inject last known
end
```

In Lua, `configure{ highlighter = nil }` is indistinguishable from `configure{}` — the key is simply
absent. So the sticky value is re-injected and `apply_config` (`3e:969`) re-assigns it:
`if cfg.highlighter ~= nil and ev then ev.highlighter = cfg.highlighter end`.

The obvious workaround does not work either. `compy.input.callbacks.highlighter = nil` clears
`state.callbacks.highlighter` (that table *is* the widget's `callbacks`), but the live highlighter
lives on the **evaluator** — `self.model.evaluator.highlighter` — and `apply_config` only ever
*writes* it, never clears it. The only thing that clears it is `reset_widget_outputs`, at project
stop (`3d:343`).

**Failure scenario:** a project shows a Lua code field with `highlighter = LuaHighlighter`, then
switches to plain-text entry and calls `compy.input.configure{ prompt = 'name?' }`. The name field is
still Lua-coloured for the rest of the run, with no way to stop it short of stopping the project.

`validator` and `on_text_entered` do not have this problem — those are read from `self.callbacks` at
use, so nil-ing the field works. Only `highlighter` is mirrored into a second location that is never
cleared. The guide says these entries "persist until replaced" but never says they cannot be
*un*-set.

---

### 4. MINOR — the docs slice ships a convention and then violates it 22 times

`1b-generic-docs.patch` adds `doc/development/conventions/docs.md`, an owner ruling dated
2026-07-31, which states:

> The block [YAML front matter] is the **only** place provenance is recorded. **Do not re-add the
> HTML comment.**

Slice `1a-generic-docs-rubberstamping.patch` — 21 files, one line each — adds exactly that comment:
`<!-- authored By LLM; human-approved NOT YET -->`. `1b` adds it to a 22nd (the new
`internals/examples/keyboard.md`, `1b:560`). Nothing in any slice removes it or converts those files
to front matter. Apply order is `1a` → `1b`, so the PR adds the marker and then, later in the same
PR, publishes the rule forbidding it.

Either `1a` should be dropped and those 21 files given front matter, or `docs.md` should record that
the migration is pending. As shipped, a contributor reading `docs.md` and then reading any
`internals/` doc gets contradictory instructions from the same commit range.

---

### 5. MINOR — `show{force = true, prompt = ...}` silently drops the prompt

`3e-widget-surface.patch:994` `re_show` handles only `cfg.text`. `SHOW_KEYS` accepts `prompt`,
`cursor`, and every callback key alongside `force`, and `check_keys` raises on anything outside that
set — so the config table is closed *specifically* to prevent silent no-ops. Yet a forced re-show
accepts `prompt` and `cursor` and ignores both without a word.

The guide does scope it correctly (`force` | "while active, replace `text` instead of warning"), and
`UserInputController:configure`'s comment claims "Never a partial/silent apply either way" — which is
untrue on this path. The `maze` migration is visibly working around it: `4b-maze.patch` introduces a
`set_prompt()` helper that branches on `is_shown()` and calls `configure` + `set_text` separately,
with a comment explaining that `show()` "over an already-open field is ignored and cannot change the
prompt". That is the ask's D-2 ruling working as specified, but the ergonomic cost lands on every
caller. Either raise on the ignored keys, or apply them.

---

### 6. MINOR — two docs in slice `3a` disagree about whether the route is released at `running → project_open`

`3a` `internals/user_input.md`: *"The `'running'` → `'project_open'` transition releases nothing."*
That matches the code — `3e-widget-surface.patch:166-178`, the success branch of `run_project`, has
no release call and an explicit comment saying so.

`3a` `technical_debt/input.md`, "Input-only / pointer-only projects stay live in `project_open`":
*"`run_project` now releases the keyboard route only when `not user_is_interactive()`."* That is the
*previous* design. It is false against the diff.

The same ledger entry also cites `hook_pointer` (`controller.lua:238-249`) and `occupy_keyboard`;
the shipped functions are named `mark_pointer_liveness` and `occupy_input`. Several other entries
carry hard line numbers (`controller.lua:1112-1113`, `:778-824`) that were stale the moment the file
was re-cut.

---

### 7. MINOR — CHANGELOG omits the breaking change it exists to record

`3a` adds `CHANGELOG.md` (new file, 22 lines). It has a "Changed" section with three bullets and
**no "Removed" section at all**. Missing: the retirement of `user_input`, `input_text`, `input_code`,
`validated_input`, `write_to_input`, `compy.singleclick`, `compy.doubleclick`, and the withholding of
the four evaluator globals — i.e. every consequence of D-1, the decision the stakeholders spent a
whole round arguing. Also missing: the addition of `compy.input.shortcuts`/`hooks`/`fn` and
`compy.before_exit`.

The file's own first line is an unresolved editorial note — placed *above* the `# Changelog`
heading — reading `> REMARK: too shy for major changes done -- rewired dispatching, unblocked
event-handling, new topology with shortcuts/hooks.... many documentation and technical debt added.
And version is 1.0.0-rc...`. That note is correct and should have been acted on rather than shipped.

---

### 8. MINOR — unresolved `> REMARK:` working notes shipped as documentation

Beyond the CHANGELOG: `1b-generic-docs.patch` adds
`> REMARK: it seems balloons itself is a bit overcomplicated now … now it could e.g.
clear/configure/deliver in a single on_submit callbac.` to `internals/examples/balloons.md`, and
`> REMARK: can we avoid using ambiguous word 'overlay' which is just a synonym for project's input
widget? unifying terminology would be less confusing to reader` to `internals/examples/guess.md`.

Both are reviewer questions addressed to the author, one with a typo, published as project
documentation. The second one is also a live terminology complaint that was never actioned —
"overlay" still appears throughout `3a`'s docs and in `3e`'s inline comments, alongside "input
widget" and "input area", for the same thing.

---

### 9. MINOR — the migrated `turtle` example now double-handles its own keys

`3g-examples-tracked.patch`, `src/examples/turtle/main.lua`. The comment says turtle is *"the example
that demonstrates that path"* — a project keeping its handlers on `love.keypressed`/`keyreleased` and
letting the framework seed them as hooks. It does, and the seeded hook returns nothing, so it falls
through to the widget.

The result: while the `TURTLE` prompt is open, pressing **Space** both toggles `debug` *and* types a
space into the field; **Shift+R** both recentres the turtle *and* types `R`. That is a direct
consequence of the headline lockout fix, so it is not a bug in the framework — but it makes the
example that is advertised as demonstrating the pattern demonstrate the pattern's sharpest edge
without acknowledging it. The guide's own `stop_here` / `is_shown()` machinery exists to solve
exactly this and is used two functions above, for the `i` echo guard.

---

### 10. MINOR — `compy.input.set_cursor` clamps in bytes while the boundary event measures in characters

`3f-model-view-util.patch:122`, `UserInputModel:is_at_limit`, computes
`line_end = string.ulen(line) + 1` — character length, consistent with `cursor_right`.

`3e-widget-surface.patch:922` `UserInputController:set_cursor_pos` and `3f:75`
`UserInputModel:_clamp_cursor_pos` both compute `llen = #(self.model:get_text_line(l))` — **byte**
length, consistent with `move_cursor`.

On a line containing any non-ASCII character the two disagree. `compy.input.set_cursor(1, 999)`
clamps to `#line + 1`, which is past the last valid character position, and `is_at_limit('right')`
at that position is false — so `on_limit_reached` will not fire where the caret visually is at the
end. `doc/input_api.md` documents the range as `1 .. #line + 1`, i.e. it specifies the byte-based
one.

The inconsistency is inherited (`move_cursor` vs `cursor_right` already differ in the baseline), but
this change is what puts it on the public surface, and the project is otherwise carefully
UTF-8-aware (`string.ulen`, `string.usub`, `Char.is_digit` are used throughout).

---

### 11. NIT — the channel list exists twice, which is the exact failure the comments forbid

`3d-routing-core.patch:72-91` builds `_supported` and `_bindable` in `controller.lua`, with a comment:
*"One list, because seeding, teardown and dispatch have to agree about what a channel is, and three
hand-kept subsets did not."*

`3d-routing-core.patch:1323` then declares `EVENTS` in `projectInputController.lua` — a second
hand-written list of the same twelve names, in a different order.

`get_compy_input` (`3e:582`) provisions shortcut tables from `ProjectInputController.EVENTS`;
`reset_compy_input` (`3d:329`) wipes them by iterating `_bindable`. They agree today. If they ever
diverge, `wipe_table(input.shortcuts[ev])` gets `nil` and every project stop raises `bad argument #1
to 'pairs'`. One list should import the other.

---

### 12. NIT — `src/examples/pong/README.md` is a 317-line whole-file rewrite for a two-line change

`3g-examples-tracked.patch` converts the file from CRLF to LF, so git renders every line as
changed. The actual content delta, verified by stripping `\r` and re-diffing, is:

```
-if love.keyboard.isDown("up") then dir = -1
-elseif love.keyboard.isDown("down") then dir = 1 end
+if Key.any_pressed("up") then dir = -1
+elseif Key.any_pressed("down") then dir = 1 end
```

Two observations. The line-ending conversion should be its own commit or not happen. And the change
itself is churn: `pong` has no text input, the guide states plainly that "`love.keyboard.isDown`
still works and is what this calls", and D-1 scoped the migration to examples that use the input
API. The rewrite also introduces a typo in the new prose: `Escape to quit.Input handling`.

---

### 13. NIT — `textinput` shortcuts cannot bind an upper-case character

`Key.normalize_combo` (`3f:351`) lower-cases at registration; `Controller.combo_string` (`3d:379`)
does not lower-case at dispatch. On the `textinput` channel the trigger is the literal character, so
typing `A` dispatches `'shift+A'`, which no registrable key can match. The guide states this
honestly ("`shift+i` on `keypressed` against `shift+I` on `textinput` — and the upper-case form
cannot be registered") and the debt ledger has an entry for it. Recording it here only because the
asymmetry between the two functions is a five-line fix and the workaround it forces on the `turtle`
echo guard ("Use a **bare** key as the trigger") is a real constraint on project authors.

---

## Is it simpler and more robust than what it replaces?

Yes, and by more than the diff size suggests. Concretely removed:

- Nine hand-written `set_love_*` installers, each with its own `@param` block restating LÖVE's
  signature, become one `console_channel(event)` generator (`3d:429`). ~150 lines out.
- Eleven copies of `local user_input = get_user_input(); if user_input then …:C:event(…) else end`
  in the `love.handlers` gateway, several with a literally empty `else` branch, all deleted.
- The `oneshot` flag threaded through model, view and controller; the `result` reftable; the
  `love.event.push('userinput')` round-trip and its `handlers.userinput` receiver — all gone, and
  gone cleanly (grep finds no survivor).
- The `if love.state.app_state == 'editor'` fork inside `UserInputController:keypressed` (`3e:1327`)
  becomes one straight-line sequence gated by a constructor flag.
- A 15-line `if/elseif` chain over `love.PROFILE.fpsc` becomes a 5-entry table (`3d:406`).
- Two `xpcall`-arity bugs fixed en route (`3d:107`: the message handler was receiving the error as
  `CC` and raising inside itself, so *project raises vanished with no error window* — that is a
  serious latent bug found and fixed here, worth calling out as a win).

Concepts added: route, chain, tier, shortcut, hook, combo, combo class, trigger, derived event,
reservation, combinator (`fn.*`), `before_exit`. That is a lot of new vocabulary (see below), but the
concepts are load-bearing and mostly one-to-one with something the ask named.

**Robustness:** the single biggest improvement is that widget visibility is no longer a routing
condition. The old gateway asked "is a widget shown?" at eleven entry points and answered
inconsistently; the new one asks "which route owns this?" once. That is a genuine invariant, not a
refactor.

---

## Vocabulary

Terms a reader must learn that the ask did not require:

- **"tier" / "chain" / "the walk"** — three names for one thing, used interchangeably across `3a`,
  `3d` and `3e`. Pick one.
- **"overlay" vs "input widget" vs "input area" vs "field"** — four names for the widget, all in
  active use. `1b`'s own remark flags this and it was not acted on. `doc/input_api.md` says "input
  widget" consistently; the internals docs and inline comments do not.
- **"combinator"** (`compy.input.fn.*`) — the concept is earned (the description's justification at
  `05:72` is correct: without it every handler ends in `return true` and carries that knowledge
  wherever it is reused), but the *word* is not; "wrapper", which the guide's own table header uses,
  is what a student will understand.
- **"reservation"** — earned. It names a real, otherwise-invisible contract (a platform combo acts
  *and* passes the key through, the inverse of a project shortcut), and the guide devotes a
  well-written section to it.
- **"derived event"** — earned, and better than the `compy.singleclick` special case it replaces.
- **"route" / "occupy"** — earned; the whole fix is expressible in them.

Unearned, and I would cut: the tier/chain/walk triplet and the overlay/widget/area/field quartet.
Neither is a design problem, but the guide's audience is students and their teachers.

---

## Is the public surface coherent? (`doc/input_api.md`)

**Yes — this is the strongest artefact in the delivery.** Judged as its audience would: a project
author can build a prompt from it without reading source. It opens by naming the three surfaces and
then delivers exactly those three in order; the quick-start is five lines and works; the migration
table gives a replacement for every retired global including `eval = InputEvalLua`; the "Held keys"
section ranks three mechanisms and says plainly which one you probably wanted; the "Choosing the
mechanism" section contains the single most useful paragraph in the document (*"Do not use a pair of
shortcuts to hold a state"*, with the concrete reason — release Alt before H and the closing event
serialises as plain `'h'`). The worked echo-guard example is an honest treatment of a genuinely
awkward case.

Gaps I would fix:

- Nothing states that a shown widget **always** consumes, so a hook that does not `return true` runs
  *in addition to* the widget's editing. That is the single most surprising consequence of the
  lockout fix and it is the thing the `turtle` example trips over (finding 9). The guide says it for
  pointer hooks ("consume on a truthy return … return nothing and it carries on to the input widget")
  and never for keyboard.
- No statement that callbacks cannot be un-set (finding 3).
- `hide()` vs "removing the edit area": the guide never says the widget is a persistent singleton
  that `hide()` merely deactivates, so a reader looking for FR-2's teardown will not find an answer.

---

## Tests

Slice `3b` lands before the code and is largely **behaviour-shaped, not implementation-shaped**. Test
names read as stakeholder statements: *"Ctrl+Esc goes back to the console while a widget is up"*,
*"a rejecting validator locks input without delivering"*, *"Enter still submits after the project
code has finished"*, *"the echo does not reach an input widget it opened"*, *"a shortcut fires but
does not consume"*, *"ctrl+shift+t no longer quickswitches; the project binding wins"*. The
reservation matrix is exhaustive in a way I would not have thought to ask for — for each reserved
combo there is a paired case proving the *neighbouring* chord is still the project's.

The fixture (`tests/helpers/input_fixture.lua`) does what `05` claims: it builds a real
`ConsoleController`, calls the real `Controller.set_default_handlers`, and drives the real
`love.handlers` gateway. It mirrors `main.lua`'s widget-before-console ordering and says so. This is
not a simulation.

Two caveats, both self-declared in `3a`'s ledger and both fair:

- `build_widget` installs a stub view (`{ render = …, draw = … }`), so the "a shown widget is
  painted" cases assert against a stub, not the real draw. The bug that motivated slice `3c` crashed
  *inside* the real draw, which this suite cannot reach.
- Three `pending()` markers (`routes the key release to the console`, `routes the pointer to the
  editor`, `touch reaches the active route`). `05` calls these "documented gaps awaiting a consumer";
  the middle one is a routing case, which is the area the brief asked me to read hardest, so I would
  rather it were covered than deferred.

One test-shaped implementation detail: `describe('mechanism / NFR guards — not behaviour')` at
`3b:2621` is honest naming for tests that assert allocation identity (`the widget keeps identity
across cycles`, `no widget model is reallocated`). Those are NFR-1 checks, they are labelled as such,
and I have no objection.

**No test covers the `state.pending` leak (finding 2)** — the `stop teardown` block checks handlers,
hooks, widget visibility and callbacks, but not `pending`.

---

## What I could not check

Being explicit, because several of these bear on findings above:

- **I could not run anything.** No `busted`, no `love`, no device. `05` claims 923 passing / 0
  failing / 3 pending; I verified the 3 pending markers exist and that the fixture wires what it says
  it wires, but the pass count and the "every claim in `doc/input_api.md` is pinned by at least one
  row" claim are unverified.
- **Nothing that reaches a screen.** The overlay paint, the widget's position and appearance, the
  migrated examples in motion, the click and drag paths, the double-click timing window. `05` says a
  smoke plan accompanies the PR; that plan is not in this review kit.
- **The Web (love.js) build.** `3d:111` carries a careful `pcall`-vs-`xpcall` branch with a comment
  about PUC Lua 5.1 argument passing. I believe the reasoning but cannot test it, and `3a` records
  that the Web build has no coverage at all.
- **Whether the reservation table is complete against the baseline.** I hand-checked the six global
  shortcuts in `baseline/.../controller.lua` `handlers.keypressed` against `RESERVED` and found the
  mapping faithful, with one intentional narrowing: the old code fired on `Key.ctrl()` regardless of
  other modifiers, so old `ctrl+shift+s` stopped a run and old `ctrl+alt+shift+r` fired both restart
  and reset. The new exact-match semantics change that. `3b:2313` tests the narrowing deliberately,
  so it is intended, and the guide documents it ("Adding a modifier to a reserved combo is a reliable
  way to get a nearby chord for yourself"). I could not check whether any *untracked* project relies
  on the old loose matching.
- **The three companion repos as PRs.** I read the diffs and they look coherent against their own
  baselines, but I did not review those repos' surrounding code, and `4c` (`keyboard`) in particular
  is a large behavioural rewrite — replacing a hand-maintained `INPUT.held` mirror with device
  queries — whose correctness depends on timing I cannot observe.
- **`harmony/init.lua`.** `3f:221` adds `return false` to a previously-falling-through `isDown` stub.
  It looks right and `3b:217` tests it (*"answers false, not nothing, for an unheld modifier"*), but I
  do not know what harmony is for beyond scripted playback.
- **Whether the `pending` leak is reachable in practice.** It requires `configure` while hidden
  followed by no `show` before the run ends. I confirmed the code path by reading; I did not confirm
  any shipped example does it.
- **The withheld agent-tooling / contributor-workflow set.** Excluded from this kit by design; I did
  not treat its absence as a gap.

---

## Description accuracy

`spec/05-pr-description-DRAFT.md`, dated 2026-08-03, against what is actually in the slices:

| Claim in `05` | Reality |
|---|---|
| The three structural faults (polling / lockout / no show-hide) | **Accurate**, and each is fixed as described |
| `compy.input.show / hide / configure / clear` | **Accurate** |
| `compy.input.is_shown` | **Accurate** (a function, `is_shown()`) |
| `compy.input.set_text / get_cursor / set_cursor` | **Accurate** |
| `compy.input.callbacks` | **Accurate** |
| `compy.input.hooks[event]`, seeded from `love.<event>` | **Accurate** — `3d` `project_handlers` + `seed_hooks` |
| `compy.input.shortcuts[event][combo]` | **Accurate** |
| combo classes `alt+*` | **Accurate** |
| **`compy.input.keys_pressed`** | **FALSE.** Dissolved by Decision 30; no such member exists anywhere in `3e` |
| `compy.input.fn.ignore_repeat / stop_here / side_run` | **Accurate** |
| `compy.before_exit` | **Accurate** — `3e` `framework_before_exit`, upvalue slot with an intercepting `__newindex` |
| **"No pointer shortcuts. … Pointer starts at the hook tier."** | **FALSE.** `TRIGGER` serialises mouse buttons as `mouseN`; triggerless pointer channels take modifier classes; the guide documents both with examples; `3b` tests them. `05` contradicts itself four rows later ("Pointer joined the chain") |
| "No framework tier above shortcuts" | **Accurate** — the chain is three, and `RESERVED` sits *outside* the route, not above the shortcuts tier |
| "No compatibility shim … ordinary nil fields" | **Accurate** — `3e` deletes them and `3b:3738` asserts each is nil |
| "No 'A and B held together' combos" | **Accurate**, and the guide explains why |
| "The four-tier chain became three" | **Accurate** |
| "Hook resolution became a one-time seed" | **Accurate** — `seed_hooks` fills only nil slots, once, at `activate` |
| "The route is no longer released mid-run" | **Accurate** against the code, but `3a`'s own technical-debt ledger still says the opposite (finding 6) |
| "`compy.singleclick` / `.doubleclick` retired … Two examples migrated" | **Accurate** — `paint` and `sapper` in `3g` |
| "Unhandled events are not logged" | **Accurate** |
| "923 passing, 0 failures, 3 pending" | **Unverified.** The 3 pending markers exist |
| "The contract suite drives the real production path" | **Accurate** as far as I can read the fixture, with the stub-view caveat the ledger itself records |
| "Every claim in `doc/input_api.md` is pinned by at least one row" | **Unverified.** Spot-checking found rows for the echo guard, combo classes, reservations, the fn combinators, hidden-configure and keep_cursor — a good sample, but I did not enumerate |
| Open questions 1–5 | **Honest and accurate.** Question 4 (console and editor still share a route) is the correct disclosure of the FR-11/FR-12 gap, and question 3's three predating defects are each present in the debt ledger with a suggested fix, as claimed |

**Summary:** the description is right about the shape of the change and wrong about two of its
members. Both errors point the same way — toward an earlier design that got revised — which is
exactly what a stale draft looks like. It needs a rewrite, not a patch, and `doc/input_api.md` is
already the accurate version of most of it.
