# D5 — `native`/`natives` → `handler` — edit-list (apply-spec)

Ruling: **variant B** (owner, 2026-07-21). Prose → "the project's own love.\* handler(s)";
identifiers → `*_native`→`*_handler`, `project_natives`→`project_handlers`, `natives` param
→`handlers`; keep `userlove`. `pure-native`→`handler-only`. Grep is the completeness authority
(LSP broken on cross-file method refs). Excludes vendored `nativefs` + `alter`***`native`*** FPs.

Suite must stay **841/0/0/4** after apply.

---

## Bucket 1 — SRC identifiers (mechanical, internal only; no public contract)

**FLAG-1 RESOLVED (owner, option B): CARVE OUT the wrapper family.** `wrapped_native`,
`chain_native`, `keyboard_native` + the "Native = …" defining comment (`controller.lua:146-199`)
are **entangled with a design smell** (duplicated guard; `keyboard_native` misnamed) → deferred to
a dedicated behaviour-preserving refactor (`technical_debt/input.md` §"Project-handler wrapping").
**D5 does NOT touch them.** D5 renames only the unambiguous vocabulary.

### `src/controller/controller.lua` — D5 touches only:
| line | old | new |
|---|---|---|
| 207 | `--- @return table natives` | `--- @return table handlers` |
| 208 | `local function project_natives(userlove, CC)` | `local function project_handlers(userlove, CC)` |
| 237 | `pic:activate(project_natives(userlove, CC), compy.input)` | `pic:activate(project_handlers(userlove, CC), compy.input)` |

> **CARVED — leave for the refactor item:** L146-153 defining comment, L158 `wrapped_native`,
> L177 `chain_native`, L193/197 `keyboard_native`/`chain_native`, L211/213/215 `keyboard_native`
> calls (inside `project_handlers` body — interim mixed state, tracked), L255 `wrapped_native` call.

### `src/controller/projectInputController.lua`
| line | old | new |
|---|---|---|
| 36 | `its captured native love.* handler, once,` | `the project's own love.* handler, seeded once,` |
| 42 | `--- @param natives table  { event -> fn? }` | `--- @param handlers table  { event -> fn? }` |
| 43 | `local function seed_hooks(hooks, natives)` | `local function seed_hooks(hooks, handlers)` |
| 46 | `hooks[event] = natives[event]` | `hooks[event] = handlers[event]` |
| 99 | `` `natives` holds the`` | `` `handlers` holds the`` |
| 104 | `there is no separate natives store.` | `there is no separate handlers store.` |
| 105 | `--- @param natives table?` | `--- @param handlers table?` |
| 107 | `function ProjectInputController:activate(natives, compy_input)` | `function ProjectInputController:activate(handlers, compy_input)` |
| 109 | `seed_hooks(compy_input.hooks, natives or {})` | `seed_hooks(compy_input.hooks, handlers or {})` |

> `filesystem.lua:119` (`nativefs`) = vendored, **excluded**.
> ⚑ FLAG-1: `keyboard_handler`/`chain_handler`/`project_handlers` are generic next to existing
> `set_user_handlers`/`default_handlers`/`love.handlers`. Load-bearing? No (all file-local). Owner
> may prefer `*_userlove` for the builders. Default: proceed with B as ruled.

---

## Bucket 2 — Ratified-doc prose (variant-B phrasing)

### `doc/development/decisions/input.md`
| line | change |
|---|---|
| 64 | `the legacy native-`love.*` seeding path` → `the legacy project `love.*` handler seeding path` |
| 151 | `native keyboard handling keeps working` → `the project's keyboard handling keeps working` |
| 370 | `its captured native handler (if any)` → `its captured project handler (if any)` |
| 376 | `captured native seeded the slot` → `captured handler seeded the slot` *(slot→D6)* |
| 377 | `the native. … Read the native once` → `the handler. … Read the handler once` |
| 382 | `Treating natives as ordinary chain participants` → `Treating project handlers as ordinary chain participants` |
| 384 | `a native handler now sees events` → `a project handler now sees events` |
| 389 | `whether a native was silently active` → `whether a handler was silently active` |
| 392 | `Because natives fire while the widget is shown` → `Because project handlers fire while the widget is shown` |
| 393 | `combined a native handler with widget solicitation` → `combined a project handler with widget solicitation` |
| 395 | `pure-native projects (no widget)` → `handler-only projects (no widget)` |
| 407 | `pointer natives stay hooked` → `pointer handlers stay hooked` |

### `doc/development/internals/user_input.md`
| line | change |
|---|---|
| 158 | `captured native love.* handler where unset` → `the project's love.* handler where unset` — ⚑ FLAG-2: inside an ASCII diagram; width shifts (`native `=7→``). Re-pad the diagram row. |
| 173 | `the project's captured native `love.*` handler` → `the project's captured `love.*` handler` (drop redundant `native`) |
| 265 | `the project's native handler — seeded as a` → `the project's handler — seeded as a` |

---

## Bucket 3 — Tests

### 3a. Clean renames (no marker judgment)
- `input_redesign_ac_spec.lua`: L17 `native love.*`→`the project's love.*`; L19 `explicit or native`→`explicit or handler`; L21 `it('a captured native …')`→`it('a captured handler …')`; L30 `does not resurrect the native`→`… the handler`.
- `input_events_spec.lua` L21: `native install, the mutable/immutable boundary` → `handler install, …`.
- `input_shortcuts_click_spec.lua` L132: `{jargon: native handler} {jargon: is installed}` → `the project handler is installed`.

### 3b. `input_events` native-install group (L378–466) — vocab sweep + fold-in residual D1/D2
This group was **left untouched by D1/D2** (deferred), so it still has `sink`/`tier-3`/`on_*`.
Finish all three here:
- L379 banner `-- ---- {jargon: tier-3}: the {jargon: native} install path` → `-- ---- the project-handler install path`
- L382 `describe('tier-3: the native install path', …)` → `describe('the project-handler install path', …)`
- L384 `-- {jargon: native} is a plain {jargon: tier-3}` → `-- a project handler is a plain hook`
- L389 `it('a native fires whether or not the widget is shown')` → `it('a project handler fires …')`
- L401–402 `Decision 10, {jargon: native} / a truthy {jargon: native} intercepts the sink.` → `Decision 10, project-handler path: a truthy handler intercepts the widget.`
- L403 `it('a native returning truthy intercepts the sink')` → `it('a handler returning truthy intercepts the widget')`
- L413–417 `{jargon: native}` ×2 + `the sink` → `project-handler` + `the widget`
- L418 `it('a falsey native textinput falls through to the sink')` → `it('a falsey handler textinput falls through to the widget')`
- L429 `{jargon: native}` → `project-handler`
- L436 `it('a native keyreleased fires while the widget is shown')` → `it('a handler keyreleased fires while the widget is shown')`
- L450–453 `the captured {jargon: native} — the {jargon: native} never seeds the {jargon: slot}` → `the captured handler — the handler never seeds the hook` *(slot→hook folds D6 for this line; OK to do now)*
- L454 `it('an explicit on_* takes precedence over the native')` → `it('an explicit hook takes precedence over the handler')` *(on_*→hook folds D1/D2 residual)*
- L456–457 `local native_hits … function bump() native_hits = native_hits + 1` → `handler_hits`
- L464 `assert.equal(0, native_hits)` → `assert.equal(0, handler_hits)`

### 3c. Markers in that group — DROP vs SURVIVE  ⚑ FLAG-3 (owner ruling needed)
| line | marker | proposed |
|---|---|---|
| 378 | `REVIEW/clarity/jargon: rename? … Word 'native' … removed from all declarations` | **DROP** — this IS the rename D5 performs |
| 447 | `REVIEW/clarity: update prose and declaration and variable names to new vocabulary` | **DROP** — done by 3b |
| 387 | `REVIEW/consistency: any hook not only promoted 'native' should fire regardless of widget status …` | **SURVIVE**, dejargon `'native'`→`a project handler` — substantive coverage point (→D4) |
| 388 | `REVIEW/clarity: make it clear that 'native' always behaves like hook … reuse shared tests suite` | **SURVIVE**, dejargon — substantive (shared-suite idea, →D4) |
| 428 | `REVIEW/clarity: unite with the first test … remove 'downstream bucket D' … worthful test …` | **SURVIVE** — substantive restructure/coverage (→D4) |
| 458 | `REVIEW/fidelity/consistency: is 'activate_project' installing hooks via legacy path? …` | **SURVIVE** — substantive fixture-fidelity Q (→D4/A2) |
| 468 | `REVIEW/consistency/architecture: if we decide to pivot from .on_{event} to .hooks[event] the whole test should not be needed` | **KEEP (owner)** — actualize prose to "after we pivoted to `.hooks[event]` …"; the *is-this-test-needed* resolution scheduled to **D4** |

### 3d. `input_fixture.lua` — mixed
| line | old | proposed |
|---|---|---|
| 234 | `-- the project's `natives` (its love.* handlers) as tier-3 seeds.` | `-- the project's `handlers` (its love.* handlers) as hook seeds.` |
| 240 | `function F.activate_project(natives)` | `function F.activate_project(handlers)` |
| 242 | `Controller.set_user_handlers(natives or { }, CC)` | `Controller.set_user_handlers(handlers or { }, CC)` |
| 266/315 | `restore_native_slots` | **FLAG-4 RESOLVED (owner) → D6, not D5.** Body restores `love.*` to `Controller._defaults` (framework defaults, NOT project handlers) → "native" is wrong here; "slots" is D6's occupancy sense. Leave in D5; D6 renames (e.g. `restore_default_handlers`). L262 marker SURVIVES→D4. |
| 191 | `REVIEW/DOC: … 'native' handlers … 'compy' handlers … confusion … "project_set_compy"?` | **SURVIVE** — substantive setter-naming Q (not our vocab) |
| 227 | `REVIEW: … level of mocking … setting 'natives' as project environment (like userlove) …` | **SURVIVE** — D4 mock-level Q |

### 3e. `input_widget_lifecycle_spec.lua` L171
`REVIEW/RESPONSE: … triggered by native keys events …` — here `native` means "actual/hardware key
events", **not** the project-handler sense. **Leave as-is** (out of D5 scope) or reword to "real key
events" for clarity. ⚑ FLAG-5.

---

## Apply order
1. Bucket 1 (src ids) → run suite. 2. Bucket 2 (docs, no test impact). 3. Bucket 3a/3b (test prose
+ residual D1/D2) → run suite. 4. Bucket 3c/3d/3e per owner rulings on the flags. 5. Update inventory
dispositions (RVW-073/077 + the dropped markers) + triage-plan. 6. Commit.
