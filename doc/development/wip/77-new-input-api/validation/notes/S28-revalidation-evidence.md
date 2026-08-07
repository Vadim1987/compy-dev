# S28 — revalidation evidence (session27 outputs)

Part-1 evidence, gathered in session28 against `agents/rules/revalidation.md`.
Every claim below was checked in code or by running something, not read off the
session27 record. Findings are numbered F1…; clean checks are stated as clean.

---

## F1 — DEFECT (new, this feature): a shown widget + a derived click kills the run

**Severity: S0.** Reproduced, not inferred.

`ProjectInputController.EVENTS` includes `singleclick` and `doubleclick`
(`projectInputController.lua:38`), and `dispatch`'s widget tier calls
`widget[event](widget, ...)` unconditionally once the widget reports shown
(`projectInputController.lua:137-140`). `UserInputController` implements every
other channel in that list and **implements neither derived click** — the only
pointer methods are `mousepressed`/`mousereleased`/`mousemoved`/`wheelmoved`
and the three touch events.

Probe (temporary spec, run then deleted): a selectable widget shown, project
route active, `love.singleclick(5, 5)`:

```
./src/controller/projectInputController.lua:138: attempt to call a nil value
    ...consoleController.lua:1657: in function 'singleclick'
PROBE B app_state: snapshot
```

The route's error boundary (`with_canvas_and_errors` → `user_error_handler`)
catches it, so the app does not die — **the project run does**: `app_state`
goes to `snapshot`, i.e. the error screen. Any project that shows an input
widget and then receives a click loses its run.

**Not pre-existing.** At the PR base `3256aac` there was no widget tier for
clicks at all — the timer resolved `CC:get_compy_handler('singleclick')`
(`3256aac:src/controller/controller.lua:349`). The reachable path was created by
`b1885568` (2026-08-03, "emit single/doubleclick as events"), which routed the
derived clicks through the same chain as native events, and widened by session27's
`069b93e9` (one `_bindable` list).

**Why the suite is silent.** 953 rows and none drives a derived click into a
*shown* widget. `input_shortcuts_click_spec.lua` and `input_events_spec.lua`
cover clicks at the shortcut and hook tiers only.

**Open design question for the owner** (fix not applied — this is a Decision 5
question, not a typo): when the terminal consumer has no method for a channel,
does the widget still *consume* the event? Two shapes:
(a) give the widget `singleclick`/`doubleclick` no-ops — widget consumes, chain
    reports consumed, consistent with "shown → the widget runs";
(b) guard the tier (`local m = widget[event]; if m then …`) — a channel the
    widget does not implement falls through as not-consumed.
They differ observably for a project that shows a widget and also binds a click
hook. **(b) contradicts Decision 5 as written** ("its *shownness*, not its return
value, decides whether it consumed"), so (a) is the shape that keeps the ledger
true — but the choice is the owner's.

## F2 — the widget's `keypressed` parameter names lie (Decision 26)

**Severity: S2/S3.** `UserInputController:keypressed(k, isr)` with
`--- @param isr boolean?` (`userInputController.lua:478-485`). Since Decision 26
the route passes LÖVE's list verbatim, so the second argument is **`scancode`, a
string**, and `isrepeat` arrives third and unnamed. Probe output:

```
PROBE A widget got: 3  a  scancode-a  false
```

Harmless today — the body never reads `isr` (checked: the only occurrence of the
identifier in the whole method is the parameter list). It is a trap of exactly
the kind Decision 26's own *Why* paragraph describes for projects ("would have
bound scancode to isrepeat"), and the LSP annotation types a string as
`boolean?`. Fix is the signature: `(k, _sc, isr)` or `(k)` if the tail is unused.

## F3 — Appendix A's W10 count label is wrong (arithmetic only, coverage intact)

`S27-triage-and-plan.md:624` labels W10 "every id not listed above (**92**)" and
the revision log repeats "W10 92". The enumeration under it holds **85** ids.
85 + the other workstreams' 102 = 187, so the *assignment* is complete and the
label is the error. See the coverage check below.

---

## Clean checks

**Coverage claim (187 ids, each in exactly one workstream) — CONFIRMED, third
verification, by script.** Inventory `#### RNNN` headings: 187, all unique.
Appendix A workstream lines: 187 ids, all unique, zero missing against the
inventory, zero extra, zero duplicates. (A naive grep over the whole appendix
reports five duplicates — R044, R081, R088, R110, R135 — which are the five ids
named a second time in the "[REV] Moves in this revision" footer, not double
assignments.) Only the W10 label is wrong (F3).

**Decision 28 — CONFIRMED against code.** `framework_before_exit`
(`consoleController.lua:168-178`) calls the project hook inside `pcall`, reads no
return, returns nothing itself, and resets the slot **after** the call,
unconditionally and outside the `if`. LSP `references` on it: exactly one call
site, `stop_project_run` (`:1352`). Nothing else invokes `compy.before_exit`;
the only other mention is the failed-run path (`:322`), which *uninstalls without
firing* — deliberate, commented, and consistent with the decision text ("the only
place it is ever invoked" is about invocation, not assignment).

**Decision 26 — CONFIRMED against code, with F2 as the exception.** The route
forwards `...` untouched to all three tiers (`dispatch`, `:132-142`); the gateway
passes `(k, sc, isr)` (`controller.lua:787, 894`); `ignore_repeat` was re-cut to
`(k, sc, isr)` (`consoleController.lua:486-491`). The decision's own accepted
consequence — the console route still narrows to `CC:keypressed(k)` — is true
(`controller.lua:509, 545`). Probe A confirms three arguments reach the terminal
consumer.

**Decision 27 — CONFIRMED against code.** One combo table per channel,
provisioned from `ProjectInputController.EVENTS` rather than a literal
(`consoleController.lua:800-803`). `TRIGGER` is a table of accessors, not a
branch, and serialises buttons as `'mouse' .. b`
(`projectInputController.lua:48-54`). The fast path is real: `find_shortcut`
tests `Controller.any_mod(keys)` **before** building any string for a triggerless
channel (`:104-106`). The bare-`'*'` refusal is enforced at registration for
every channel, because it lives in `new_handler_table`'s `__newindex`
(`key.lua:89-102, 111-117`) and every channel's table is one of those.

**Severity call R135 (dropped) — reviewers were RIGHT.** `internals/user_input.md`
lines 91-92 read "the internal plain evaluator plus project callbacks for
validation and display. Projects cannot install evaluator objects." The bullet
already distinguishes a project-supplied *validator callback* from an `Evaluator`
object (`LuaEval`, `LuaEditorEval`). The sentence is precise; no action is
correct.

**Severity call R110 (re-kinded, W9 → W10) — reviewers were RIGHT.** The section
at `decisions/input.md:703-712` says in the past tense that "the dispatch that
**had shipped** was a `ProjectInputController` method … not actually reusable",
and describes the extraction that fixed it. It states nothing false; its ask is
"cut stale intra-feature history", which is W10's batch. `dispatch` is a free
function today — `projectInputController.lua:132` (the triage cites `:109`, a
line drift, not an error of fact).

**Severity call R088 (S4 → S3) — reviewers were RIGHT.** Decision 3's *Why*
(`decisions/input.md:188-192`) argues the shared-instance case ("the state was
never destroyed", "nothing to reconnect"), while `:720-721` states "Multiple
`UserInputController` instances remain required … and would be clobbered by a
single shared instance". A reader of Decision 3 alone concludes a singleton. Four
instances exist in code. Internal contradiction inside one permanent doc → S3.

**Severity call R081 (S4 → S3) — reviewers were RIGHT, and the fix is wider than
filed.** `decisions/input.md:120-123`: "The same three-component shape runs on all
three channels (`keypressed`, `textinput`, `keyreleased`)" — false since the
pointer channels run the same chain. See `S28-owner-concerns.md`: the owner adds
that the correction must also not restate "pointer minus the shortcuts tier",
which Decision 27 has made false as well.
