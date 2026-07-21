# D6 — dissolve `slot` contextually — edit-list (apply-spec)

**VERDICT (owner, 2026-07-21): dissolve `slot` entirely across all senses.** Baseline: `git grep
slot updev -- src` = **0** across *every* sense → all feature-era, all in scope. `callback`
baseline also checked (owner-requested): updev = 2 (`setup_callback_handlers` only); current = 77
(already the established word for `input.callbacks.*`) → dissolving C→`callback` creates no new
overload. Grep is the completeness authority (LSP broken on cross-file method refs).

**Taxonomy ratified** in `decisions/input.md` (new "Vocabulary — hook, callback, handler" section,
owner reasoning): hooks (closed LÖVE event namespace) vs callbacks (open Compy namespace) kept
**distinct** — the split records *which authority owns the name*; handler = the callback whose
mount point is never empty; slot dissolved because "install into slot X" ≡ "define X".

Suite must stay **841/0/0/4** after apply.

| sense | what it is | → becomes |
|---|---|---|
| **A. occupancy** | which controller owns the keyboard/text `love.*` handlers | **route** (owner) / **handlers** (positions) |
| **B. assignable hook** | `hooks[event]` (LÖVE-named) | **hook** |
| **C. widget callback** | `on_text_entered`/`validator`/`highlighter`/`on_limit_reached`/output (Compy-named) | **callback** (/ **field** where "output field" already idiomatic) |

Noun for Sense A "keyboard/text slots" = **"keyboard/text handlers"** (approved) — concrete
`love.*` positions; **route** for the *owner*, consistent with `_keyboard_route`.

**`before_exit_slot` (consoleController:644/654/659) — EXCLUDED (owner).** Feature-born (386cfe1,
M5c) but a project *lifecycle* callback, outside the input-slot vocabulary → left exactly as-is.
A `REVIEW/provenance` marker was added at `consoleController.lua:636` (is it a requested+ratified
feature or an interim bridge for a misread spec? → verify vs `design/spec/M6-02-before-exit.md`).

---

## Sense A — occupancy → route / handlers

### src
| loc | old | new |
|---|---|---|
| controller.lua:219 | `occupies the keyboard/text slots for` | `occupies the keyboard/text handlers for` |
| controller.lua:221 | `(never slot occupants themselves).` | `(never route owners themselves).` |
| controller.lua:225 | `take over the keyboard/text slots for the project route's` | `take over the keyboard/text handlers for the project route's` |
| projectInputController.lua:5 | `occupant of the keyboard/text slots while` | `owner of the keyboard/text handlers while` |

### tests
| loc | old | new |
|---|---|---|
| fixture:151 | ~~`-- Native slots: the gate's last-resort route…`~~ | **SUPERSEDED by M1** — whole comment replaced with `REVIEW/fidelity (→TF2)` (done) |
| fixture:233 | ~~`becomes the slot occupant and captures`~~ | **SUPERSEDED by M2** — whole block replaced with `REVIEW/fidelity (→TF2)` (done) |
| fixture:266 | `local function restore_native_slots()` | `local function restore_default_handlers()` *(FLAG-4 from D5 lands here; also folds `native`)* |
| fixture:315 | `restore_native_slots()` | `restore_default_handlers()` |
| input_events:33 | `{jargon: slot occupant} (app_state='running')` | `the active route (app_state='running')` |
| input_widgets_callbacks:25 | `{jargon: slot occupant} (app_state='running')` | `the active route (app_state='running')` |
| input_nfr_forward:188 | `active route/mode, not slot restore;` | `active route/mode, not handler restore;` |
| input_nfr_forward:208 | `remains wired in ANY {jargon: slot}.` | `remains wired in ANY handler.` |
| input_nfr_forward:213 | test name `'slot'` (`...wired in any ' .. 'slot'`) | `...wired in any ' .. 'handler'` |
| input_shortcuts_click:88 | `{jargon: rewires the handler slots}` | `rewires the handlers` |
| input_shortcuts_click:135 | `not on slot identity.` | `not on handler identity.` |
| input_session:7 | `-- slots and drives EditorController directly).` | `-- handlers and drives EditorController directly).` |

### ratified docs (decisions/input.md)
| loc | old | new |
|---|---|---|
| 399 | `occupies the **keyboard/text** slots only while` | `occupies the **keyboard/text** handlers only while` |
| 401 | `the keyboard/text slots are restored` | `the keyboard/text handlers are restored` |
| 402 | `every slot restores to framework defaults` | `every handler restores to framework defaults` |
| 407 | `**keyboard/text slots only**` | `**keyboard/text handlers only**` |
| 427 | `restores all slots to the console` | `restores all handlers to the console` |

### ratified docs (internals/user_input.md) — dense lines, per-phrase
| loc | old phrase | new |
|---|---|---|
| 20 | `(default slot handler):` | `(default route handler):` |
| 46 | `the slot function keeps` | `the route's default handler keeps` |
| 138 | `— the slot occupant (the active route)` | `— the active route` |
| 139 | `(the default slot handler):` | `(the default handler):` |
| 173 | `The slot occupant (the active route's controller) always receives` | `The active route's controller always receives` |
| 173 | `and never a slot occupant.` | `and never the active route.` |
| 173 | `records which controller currently occupies the slot` | `records which controller is the active route` |
| 175 | `the same slot-reassignment` | `the same handler-reassignment` |
| 175 | `scoped to the keyboard/text slots (pointer slots stay hooked` | `scoped to the keyboard/text handlers (pointer handlers stay hooked` |
| 461 | `route's slot occupant;` | `route;` *(verify exact substring at apply)* |
| 657 | `route slot management` | `route management` |

---

## Sense B — assignable hook → hook

### ratified docs (decisions/input.md)
| loc | old | new |
|---|---|---|
| 63 | `one per-event hook slot, absorbing both the old per-event generic` | `one per-event hook, absorbing both the old per-event generic` |
| 64 | `into one slot (Decision 10 revised).` | `into one hook (Decision 10 revised).` |
| 168 | `slot, two ergonomics.` | `one hook, two ergonomics.` *(verify context at apply)* |
| 374 | `resolved the hook slot` | `resolved the hook` |
| 376 | `captured handler seeded the slot; otherwise` | `captured handler seeded the hook; otherwise` |

### tests (input_events)
| loc | old | new |
|---|---|---|
| 473 | `the {jargon: tier-3} callback {jargon: slots} are assignable;` | `the hook fields are assignable;` *(also folds D1/D2 `tier-3`)* |
| 475 | `it('assigning an unknown slot raises',` | `it('assigning an unknown hook raises',` |
| 484 | `it('assigning an allowed callback slot is accepted',` | `it('assigning an allowed hook is accepted',` |

---

## Sense C — widget callback → callback (/ "output field" where idiomatic)

`before_exit_slot` (644/654/659) is **EXCLUDED** — see header. Sense C touches only the widget
callback namespace (`input.callbacks.*`).

### src (consoleController) — sticky-state store positions
| loc | old | new |
|---|---|---|
| 491 | `output-callback fields go through the same sticky `state`\n--- slots show() already reads` | `...same sticky `state`\n--- fields show() already reads` |
| 572 | `(via\n    -- state/pending, same slots show() reads) for` | `...same fields show() reads) for` |

### tests (input_widgets_callbacks)
| loc | old | new |
|---|---|---|
| 43 | `describe('output field slots and sharing',` | `describe('output fields and sharing',` *(keeps idiomatic "output field", drops slot)* |
| 60 | `the same underlying {jargon: slots}.` | `the same underlying callbacks.` |
| 61 | `it('show(config) and fields share one output slot',` | `it('show(config) and fields share one output field',` |
| 75 | `reach the same {jargon: slot} via config key` | `reach the same callback via config key` |
| 79 | `it('show(config) shares on_text_entered slot',` | `it('show(config) shares on_text_entered callback',` |
| 87 | `it('field write shares on_text_entered slot',` | `it('field write shares on_text_entered callback',` |
| 96 | `it('show(config) shares validator slot',` | `it('show(config) shares validator callback',` |
| 104 | `it('field write shares validator slot',` | `it('field write shares validator callback',` |

### tests (input_reconfigure)
| loc | old | new |
|---|---|---|
| 198 | `output-callback {jargon:\n      -- slots},` | `output-callback\n      -- fields,` |

### ratified docs (internals/console.md)
| loc | old | new |
|---|---|---|
| 109 | `callback slots` | `callback fields` |

---

## Owner markers disposed / surviving
| loc | marker | disposition |
|---|---|---|
| projectInputController.lua:4 | `REVIEW/DOC: can we reconsider 'slots' as a primary term?` | **RESOLVED** — dissolved; remove marker |
| fixture:150 | `REVIEW/DOC: 'slots','gate last-resort route' … abstraction leak; tell exactly that` | ⚑ FLAG-M1: slot part resolved by rewriting :151 to plain language; the *leak/"just how framework launches"* clarity ask → SURVIVE to D4? or resolve now with a plain rewrite? |
| fixture:226 | `REVIEW/DOC: 'slot'/'tier-3' should not be there; point to the mocked function + why mocked` | ⚑ FLAG-M2: slot/tier-3 removal done here; the *point-to-mocked-fn + why-mocked* ask is fixture-fidelity → **SURVIVE to D4** (A2 family) |

---

## Flags — status
- **⚑ FLAG-A (noun):** RESOLVED — "keyboard/text handlers" (owner approved).
- **⚑ FLAG-C (identifier):** RESOLVED — `before_exit_slot` kept as-is + provenance marker added.
- **⚑ FLAG-M1:** RESOLVED (owner) — marker+comment replaced with `REVIEW/fidelity (→TF2)` "why not call set_default_handlers()"; applied. Supersedes the fixture:151 vocab edit.
- **⚑ FLAG-M2:** RESOLVED (owner) — whole block collapsed to `REVIEW/fidelity (→TF2)` "does it match real activation path vs mocking"; applied. Supersedes the fixture:233 vocab edit.
- **TF2 handoff:** M1, M2, + the `setup_callback_handlers`-vs-`handlers` naming question recorded under triage-plan §D4 (Test-Fidelity cluster).

## Execution queue (owner-greenlit 2026-07-21; one sub-agent at a time, sequential)
1. **Sweep-src** (Sonnet) — controller.lua, projectInputController.lua (incl. remove :4 marker), consoleController.lua 491/572. `before_exit_slot` EXCLUDED.
2. **Sweep-tests** (Sonnet) — input_events/widgets_callbacks/nfr_forward/reconfigure/shortcuts_click/session + fixture `restore_native_slots` (266/315). (fixture 151/233 already superseded by M1/M2.)
3. **Sweep-docs** (Sonnet) — decisions/input.md, internals/user_input.md, internals/console.md.
4. **Routing-layers doc** (Fable) — new `internals/` doc on `love.handlers[name]`↔`love[name]` (setup_callback_handlers vs set_default_handlers). Not a sweep; documents an untouched layer.
Commit by orchestrator (Opus) after 1–3 green; explicit `git add` (no `-A`).

## Apply order
1. Sense A src → suite. 2. Sense B/C src → suite. 3. Docs (no test impact). 4. Tests (all senses) → suite.
5. Marker dispositions per flags. 6. Update inventory + triage-plan. 7. Commit.
