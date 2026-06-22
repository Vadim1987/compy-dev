# M2 — Human review triage

_Status tracker for the human's inline review remarks on the M2 outcome._
_Source: three review commits on `topics/git` —_
_`32ca4fa` (doc remarks · `user_input.md`), `28dc7ba` (code round 2 · `consoleController.lua`, `controller.lua`),_
_`60951da` (feedback #3/3 · `userInputController.lua`, `main.lua`, `key.lua`, `tests/input/*`)._
_Feeds **E12** (human code-review → LLM reevaluation of M2)._

## Classification

Two primary classes, as requested:

- **`open`** — needs **architectural discussion / possible pivot** before any code moves. Grouped into
  themes **A1–A8** below; that list **is the discussion agenda**.
- **`fix`** — **straight-fixable**: a comment/annotation, rename, added assertion, or doc edit with no
  design question attached. Tabled in §Straight-fixable.

Two lightweight cross-cuts that don't fit either box cleanly:

- **`policy`** (**C1–C2**) — a one-time convention decision that, once made, turns a pile of `fix`
  items mechanical. Small discussion, large fan-out.
- **`verify`** — a remark that **asserts a possible bug or asks a factual question** I must check in
  code/history before it can be classed `fix` or `open`. Listed in §Verify-first. **All six checked —
  see results there; M2 is sign-off-clean.**

Legend: `open` ▲ · `policy` ◆ · `verify` ◔ · `fix` ✔

### Durability tag (orthogonal to class)

Every item also carries a **durability** tag, because M4–M8 rewrite much of what M2 introduced. This
is the cut that decides *whether to act now*:

- **`durable`** — the code/doc survives the rewrite (or is permanent foundation). **Polish now** —
  otherwise it sprawls tech debt.
- **`ephemeral`** — a later milestone deletes or replaces it. **Mark `transitional — superseded by
  Mx` and defer** — deep work here is micromanaging changes that get wiped.

See §Durability lens for the per-theme mapping and the milestone that wipes each ephemeral one.

---

## A. Architectural themes (`open` — the discussion agenda)

### A1 — Project-side event hooking (project hooks) ▲ · `ephemeral` (overlay gate gone M4)
Can project code hook `textinput`/`keypressed` directly, or is draining down into
`UserInputController` the only (default/last-resort) path? The doc *mentions* the overlay but never
shows how `UserInputController:textinput` gets triggered, nor a project hook mechanism.
**Remarks:** doc "does not show handling events via project"; "mechanism to hook project code to
textinput?"; "what 'regardless of context' means — can projects redefine their own hooks?";
"console-specific" — interpreted in the console controller (where it belongs) or the generic
controller (which would be wrong)?; "editor-specific — technically how different, which hooks
redefined?".
**Ties to:** M4/M5 `ProjectInputController` dispatch (`compy.input.handlers[combo]`). This is the
substantive forward design — overlaps **E9**.

### A2 — Passing `keys_pressed` to text handlers (modifier proxy) ▲ DEFERRED (0.1.0-m4/m5) · `ephemeral`
**Not an M2 *bug* — but the design is not closed.** `spec.md:107–108` + `design.md §4` place the
`keys_pressed`-as-2nd-arg contract on **`ProjectInputController`** (`:keypressed(k, keys_pressed,
isrepeat)`, `:textinput(t, keys_pressed)`), which **M4 (controller intro)** creates and **M5
(three-level dispatch)** wires. So M2's bottom *sink* omitting it matches the **current** design and
doesn't block sign-off. **Open question (human):** it may yet be decided that the bottom sink *should*
receive `keys_pressed` too — e.g. to handle Shift+Enter or similar uniformly at the sink. **To be
resolved in the m4/m5 design session**, not settled now.
**Remarks:** doc "pass keys pressed to text_entered() as 2nd arg?"; `:keypressed`/`:textinput` "keys
not passed — it was in the design".
**In code:** `userInputController` `:keypressed`/`:textinput` carry `DEFERRED (0.1.0-m4/m5, A2)` notes.

### A3 — The `oneshot` submit mechanism (auto-eval flag) ▲ · `ephemeral` (deleted M6)
What `oneshot` actually is, whether auto-running the evaluator on Enter is the right model, and
whether a better approach is planned.
**Remarks:** doc "what exactly is 'oneshot'? auto-triggering eval on Enter? reasonable? better way?".

### A4 — Legacy vs. new input-API boundary & deprecation (old/new seam) ▲ · `ephemeral` (legacy removed M8)
The seam between the **legacy** surface (`write_to_input`, `input()`, `r:is_empty()` polling,
`love.state.user_input`) and the **new** `compy.input` namespace — what's kept, what's deprecated,
and the **`force`-flag semantics** across the seam.
**Remarks:** legacy `input()` "where's the force-flag passthrough? or is it a tolerant legacy
wrapper?"; `write_to_input` "why not use `compy.input`? (legacy, to be ditched?)";
`show` "only a subset of config applied (text yes, clear no) — documented? why?"; doc "project polls
`r:is_empty()` from wherever? deprecate this polling?"; doc "we'll disable the path instead of main
controller — worth mentioning".
**Decide:** the deprecation map + whether legacy wrappers honor `force`.

### A5 — Singleton lifecycle & the `love.state.user_input` draw contract (overlay flag contract) ▲ · `durable` (flag persists to M8; only drivers change)
The biggest cluster. `M`/`C`/`V` are constructed separately in `main.lua`; the controller is parked
in global state; `love.state.user_input = { M, C, V }` is a flag that **silently alters draw
behaviour**. Is the flag a sane architectural contract, and is it documented?
**Remarks:** main "cannot the controller provision its own M and V? why managed separately?";
"`user_input_controller` exists only for API wrappers — why in global state?"; `open_fresh`
"why a separate method, what on second call, why not `init`?"; "factor the `love.state.user_input`
triade into `setup_legacy_user_input` + annotate legacy status"; `hide()` "how does it *physically*
hide? a redraw checks the flag — why the flag's presence vs. querying the controller state?";
test "which code calls `V.draw()`? isn't drawing the controller's duty?".
**Decide:** document the contract as intentional, or refactor (controller-owned M/V, explicit
legacy-setup function, hide() semantics).

### A6 — `combo_string` design / dispatch model (serialize-vs-match) ▲ · `durable` (decide before M5) · potential pivot
`combo_string` builds a **fresh table on every keypress** purely to serialize a combo for handler
lookup. Proposal: register handlers as **boolean matchers / in-place dispatcher closures** built at
registration time `(k, keys_pressed) → fire-if-condition`, so no string is computed per keypress
(most are misses).
**Remarks:** controller "GC churn? more accurate way? register by boolean matcher instead of
serialization?"; "imagine a closure built at registration that fires if its condition is met — no
need to compute combo-string each keypress"; test "deserialize combo strings on hook setup; current
impl creates an empty table per keypress just to serialize (may tension with the no-if-arrows rule —
look for a better resolution)".
**This reshapes M4/M5 dispatch — overlaps A1 and E9.**

### A7 — Project lifecycle hooks (quit/suspend) ▲ · `ephemeral` (future milestone, not in M2)
Plan to fire `before_quit` / `before_suspend` on the project from the global shortcut handler?
**Remarks:** doc "our plan includes firing before_quit / before_suspend on the project?".
Small but a genuine design question; may belong to a later milestone.

### A8 — Test strategy: behaviour vs. internals (test the contract) ▲ · `durable` (the M4-0 safety-net question)
Pervasive: many M2 tests assert **implementation internals** (`love.state.user_input` set, `.C` is
the controller) rather than **observable behaviour**, and exercise the controller directly rather
than through the real `compy.input` API / a real event flow. Plus isolation concerns, boilerplate
duplication, and coverage gaps.
**Remarks:** repeated "internals, not behaviour" on `show sets user_input`, `user_input.C is the
controller`, `hide clears user_input`, `second show leaves user_input unchanged`, `force leaves
user_input active`; "why not test via `compy.input` / real flow?"; "test isolation problem — needs
fundamental resolution? do other tests repeat this setup?"; "is `setup_callback_handlers` wiring
reproducing a real workflow?"; coverage gaps — "previous impl destroyed user input on submission, do
we test it?"; keys_pressed "why not test as a single flow (press→assert→release→assert)? one concern
≠ one assertion; test the *feature*".
**Ties to:** `notes/talk/two-tier-test-strategy.md` (this is exactly the per-milestone test-first /
characterization question — overlaps **E9** and the test split for M5/M6/M7).

---

## B. Durability lens — what M4–M8 wipes

The cut that decides *act-now vs. defer*. Each M2 area, with the milestone that rewrites it:

| Area | Fate downstream | Tag |
|---|---|---|
| `oneshot` (auto-eval flag · A3) | **deleted M6** — submit → `framework_handlers['return']` (enter handler) | `ephemeral` |
| `write_to_input` (legacy write · A4) | **removed M8**, replaced by `compy.input.set_text` (M7) | `ephemeral` |
| `keys_pressed` passing (modifier proxy · A2) | arrives via ProjectInputController (M4/M5) | `ephemeral` |
| overlay `if user_input` gate (A1) | **removed M4** — symmetric routing | `ephemeral` |
| sink `:keypressed`/`:textinput` signature | wrapped by dispatch (M4/M5) | mostly `ephemeral` |
| `combo_string` (serialize-vs-match · A6) | **stays** — M5 `handlers[combo]` registration format | `durable` (perf is M5's call) |
| singleton + `love.state.user_input` flag (overlay contract · A5) | **stays to M8** — only drivers change | `durable` |
| `keys_pressed` table (M1), `key.lua` triples | permanent foundation | `durable` |
| docs (versioning · C1), durable-code naming | persistent artifacts | `durable` |

**Rule:** polish `durable` rows now; mark `ephemeral` rows `transitional — superseded by Mx` and defer.

---

## C. Cross-cutting policy decisions (`policy` — small call, large fan-out)

### C1 — Doc versioning policy (semver-not-milestones) ✅ SETTLED · `durable`
**Decision (human, session 17):** persistent docs use **semantic versioning**, not milestone ids.
Scheme: milestones are a **pre-release suffix `-mN` on a single target version `0.1.0`** (current
release line is `0.0.x`; #77 = one minor bump for a substantial feature + breaking legacy removal).
Markers read *"since 0.1.0-m2"* / *"planned for 0.1.0-m7"*. At release the human **squashes
`0.1.0-m*` → `0.1.0`** (one upstream bump). Not a per-milestone Y/Z increment — all milestones ship
together.
**Landed:** `user_input.md` swept (`M4/M5`→`0.1.0-m4/m5`, `M2+`→`since 0.1.0-m2`, `M7`→`0.1.0-m7`).
**Open:** codify as a doc-rule (process.md/sdlc.md) — fold into E16.

### C2 — "No silent suppression" convention (warn-don't-swallow) ✅ SETTLED · `durable`
**Decision (human, session 17):** *log a warning whenever an action is silently dropped*, **and tests
assert the warning** (it's a contract, not a side effect). Uses the existing global `Log.warn`
(`util/debug.lua`; loaded in tests via `tests/mock.lua`).
**Landed (durable site):** `UserInputController:show()` no-op now `Log.warn`s; **two contract tests**
in `singleton_spec` — suppressed non-force show warns once; `force=true` override does **not** warn.
**Deferred (ephemeral sites):** the `input()` / `write_to_input` guards are legacy (die M8) — they get
the warn during their milestone, not now.

---

## Straight-fixable (`fix` ✔)

Grouped by file. All are comments/annotations, renames, added assertions, or doc edits with **no
design question** attached.

### `doc/development/internals/user_input.md`
- ✔ Document Shift+Enter / multiline assembly (LÖVE vs. custom in `UserInputController`).
- ✔ Document `textinput`/`keypressed` ordering guarantee and the `isrepeat` modifier (where defined,
  where/why suppressed). *(answer from LÖVE docs + code.)*
- ✔ Explain the pre-singleton overlay model (did each project define its own C/V, or just read `r()`?
  was MVC recreation a brute-force reset?) — historical rationale.
- ✔ "Key files" table: add what *uses* each file.
- ◆→✔ Apply C1 version markers throughout (after C1 decided).

### `src/controller/consoleController.lua`
- ✔ Comment `get_compy_input`: its purpose, that it **constructs the new input API**, and that it
  **wraps `UserInputController` by contract** (not incidentally). Consider stubbing the other planned
  methods as explicit no-ops now. *(the "stub now?" sub-question is a tiny `open`.)*
- ✔ Comment `get_compy_namespace`: what calls it and when.
- ✔ Comment `input()`: purpose, caller, and annotate its return value.
- ✔ `input()` one-line `return` — confirm against the style guide; reformat if needed.
- ✔ Naming: `ui` is a poor abbreviation (reads as *user_interface*) — rename to e.g. `uic`.
- ✔ `write_to_input` — name doesn't convey *prompt vs. text*; `set_text` annotate; clarify `ui.C`
  self-reference. *(legacy-ditch + stale-view parts → A4 / verify.)*

### `src/controller/controller.lua`
- ✔ Comment/annotate `COMBO_MODS = Key.mod_triples` — what "triples" are and why (names aren't
  self-explanatory). *(deeper combo-string design → A6.)*
- ✔ `combo_string` — add signature type annotations.

### `src/controller/userInputController.lua`
- ✔ Note the `--- singleton API ---` block is **internal** (consumer access only via wrappers);
  reconcile the inconsistent free-function vs. class-method style. *(style call is tiny `open`.)*
- ✔ `apply_config`: comment what `cfg.result` is.
- ✔ `open_fresh`: comment lifecycle (when called, idempotency); consider a more conventional name;
  mark the legacy placeholder. *(naming/factoring overlaps A5.)*
- ✔ Comment when `update_view` fires (and why first).  *(ordering question → verify U-l.)*
- ✔ Comment `_G.web` / the `space` special case.

### `src/main.lua`
- ✔ Comment `init_view` — what it does (and that it isn't an unconditional show).
  *(M/V separation + global parking → A5.)*

### `src/util/key.lua`
- ✔ `gui_k` unused — mark explicitly; confirm we're intentionally limited to a minimal ANSI-ish set
  (ties to `implementation/technical_debt.md` `gui_k` item).
- ✔ Comment `mod_triples` purpose (dup of the `controller.lua` triples note). *(design → A6.)*

### `tests/input/*`
- ✔ `keys_pressed_spec`: reference the mimicked interface for the `view.view` preload; `gfx` reads as
  `love.graphics`/`compy.graphics` — clarify; note the keyboard isn't actually mocked despite the
  comment; clarify `event.quit` no-op intent.
- ✔ `keys_pressed_spec` "tracks multiple held keys" — assert no *other* key reads truthy.
- ✔ `overlay_spec` / `singleton_spec`: rename `mv` → `mock_view`; rename `push_called` →
  `userinput_emitted`; redefine only `love.event.push`, not the whole `love.event` table; comment
  `make_ctrl`'s purpose.
- ✔ `singleton_spec` "no-op does not reset content" — add a second `show` step with different config
  and re-assert. *(NB: `show` takes a config table, not a bare string.)*
- ✔ `singleton_spec` singleton-identity — also exercise the `force` path. *(the test itself is the
  one internals-test worth keeping — validates the no-waste NFR.)*

---

## Verify-first — CHECKED (all six; M2 sign-off-clean)

No verify item surfaced an **M2-introduced bug**. Two yield durable doc/test fixes; the rest benign or
out-of-scope.

- ◑ **`input_max` 14 vs. 16** → **not an M2 bug, but unsettled.** They are two *separate* limits —
  `input_max = 14` (input-strip height) and `LINES = 16` (buffer viewport). But **which value is the
  correct monster-block threshold is NOT settled** — the human (author of the monster-block feature)
  is unsure, so we do **not** claim the gap is intentional/canonical. `editor.md` already flags a
  related inconsistency (rejection threshold uses `LINES`/16). → `user_input.md` now marks this as an
  **open review item** (no "intentional" claim); the reconciliation is a pending design decision, out
  of M2 scope.
- ✅ **`local input_ref` localization** → **not a regression.** History (`git log -L`): it was *always*
  `local`. M2 (`2245aa5`) only dropped the now-unused `ui_model, ui_con` companions from the joint
  declaration (the singleton is now built in `main.lua`, not per-call). Nothing breaks. → benign;
  optional clarifying comment (`ephemeral` — legacy `input()` dies M8).
- ✅ **Removed `init_view`/`update_view`** in legacy `input()` → **safe.** `init_view(v)` just sets
  `self.view`; it's now called **once at startup** (`main.lua`), and `show()`→`open_fresh`→
  `update_view()` re-renders. The singleton owns its view; no missing init. → benign.
- ◑ **`update_view` ordering** in `:keypressed` (line 264, *before* processing) → **not a correctness
  bug.** The leading render is **defensive/redundant**; mutating branches each re-render at their end
  (lines 465/472/480/486/502). Odd but safe. → `fix`/`durable`: a clarifying comment; the "is this the
  right pattern" part folds into **A5**.
- ✅ **Overlay stale-view** → **draw path sound.** `ui.V:draw()` runs **every frame** the overlay flag
  is set (`controller.lua:406`), and `update_view()` syncs content; the leading `:keypressed` render
  actually **guards against** a branch that forgot to re-render. The balloons/game-end recollection is
  a different layer, not this overlay render path. → document under **A5**, no M2 bug.
- ✅ **`does not fold lr variants` test** → **human is right.** `keys_pressed['ctrl']` is **never
  written** (the table stores raw LÖVE names `lctrl`/`rctrl`; folding happens *only* in `combo_string`
  serialisation). So the trailing `is_nil('ctrl')` assertion is a **tautology** testing nothing — the
  `lctrl`/`rctrl` truthy asserts *are* meaningful. → `fix`/`durable`: drop/replace the tautological
  assertion (the M1 `keys_pressed` table is permanent).

**Conclusion:** M2 code is **sign-off-clean**. A2 (the only thing that looked like it could reopen
sign-off) does not block — M2 matches current design — though whether the sink should receive
`keys_pressed` is **deferred to the m4/m5 design session**, not closed. One durable fix drops out
(fold-test tautology) plus one durable comment (`update_view` ordering); `input_max` is now flagged
as an **open review item** rather than fixed.

---

## Status roll-up

| Class | Count | Durability | Gate / disposition |
|---|---|---|---|
| `open` (A1–A8) | 8 themes (A2 deferred to m4/m5) | A5/A6/A8 `durable`; A1/A2/A3/A4/A7 `ephemeral` | A1/A6/A8 → **E9** (architect call); rest defer or mark |
| `policy` (C1–C2) | 2 decisions | both `durable` | decide → unblocks the `fix` bulk |
| `verify` | 6 — **all checked** | — | **M2 sign-off-clean**; 2 durable fixes + 1 durable comment drop out |
| `fix` | ~25 items | split — see Durability lens | `durable` ones now; `ephemeral` ones get `superseded by Mx` + defer |

**M2 sign-off:** **clean** — proceed (this closes the code half of **E12**, human-review→LLM-reeval).

**Suggested order (durability-driven):**
1. Decide **C1 (semver-not-milestones)** + **C2 (warn-don't-swallow)** — both `durable` standing
   conventions.
2. Land the **`durable` `fix` subset** — `combo_string`/triples comments, **A5 (overlay flag
   contract)** documentation, durable-code naming, the two verify-fixes (`input_max` doc cross-ref,
   fold-test tautology), C1 doc sweep.
3. **Mark-and-defer the `ephemeral` subset** — `oneshot` (A3), `write_to_input` (A4), the M2
   internals-tests (A8), keys_pressed-passing (A2) — each gets `transitional — superseded by Mx`.
4. Carry **A1 (project hooks)**, **A5 (decision part)**, **A6 (serialize-vs-match)**, **A8 (test the
   contract)** into **E9** — same forward-design questions E9 owns; **A6 must be decided before M5**.

---

## Landed — session 17 (full durable subset; suite **701** green, human-run)

Code/doc changes applied to `topics/git` (review cleanups, not feature code — human-directed):

- **`util/key.lua`** — `gui_k` + `mod_triples` explained (precedence, l/r fold, single source of truth).
- **`controller.lua`** — `COMBO_MODS` + `combo_string` doc'd & type-annotated; A6 deferred-to-m5 note.
- **`userInputController.lua`** — internal-API note; `cfg.result` explained; `open_fresh` lifecycle +
  the **A5 `love.state.user_input` overlay-flag contract** documented; `hide()` contract; `:keypressed`
  render-on-entry rationale + **A2** note; `:textinput` A2 note. **C2:** `show()` no-op now `Log.warn`s.
- **`keys_pressed_spec.lua`** — fold-test tautology replaced with positive proof (`combo_string`
  folds, table doesn't); "no other keys truthy" assertion added; A8/A6 design questions → deferred
  pointers.
- **`singleton_spec.lua`** — **C2 contract tests**: suppressed non-force `show()` warns once;
  `force=true` does not warn.
- **`user_input.md`** — `input_max` 14-vs-`LINES` 16 clarified (intentional, cross-ref `editor.md`);
  **C1** semver sweep.

**Batch 2 — remaining durable hygiene (this turn):**
- **`main.lua`** — 3 **A5** call-site comments (M/V-separation, `init_view` binds-not-shows,
  controller-in-`love.state` service-locator).
- **`keys_pressed_spec.lua`** — boilerplate-stub / mock-surface / real-wiring REVIEWs answered;
  dedup + isolation questions → crisp **A8** pointers.
- **`overlay_spec.lua`** — `mv`→`mock_view`, `push_called`→`userinput_emitted`, `love.event.push`
  scoped (was whole-table); `make_ctrl`/`before_each`/`V:draw` comments; coverage gap → A8 pointer.
- **`singleton_spec.lua`** — `mv`→`mock_view`; ~8 repetitive "internals-not-behaviour" REVIEWs
  collapsed into **one A8 pointer**; singleton-identity NFR documented.

**Batch 3 — `consoleController` triage + two corrections (this turn):**
- **Convention:** every remaining review marker is now either an applied fix or an explicit
  **`DEFERRED (0.1.0-mN): … — to be resolved in design session`** comment. No raw `REVIEW` left
  anywhere in `src/` or `tests/input/`; intermediary decisions stay *visibly* intermediary (not
  silently removed). 5 `DEFERRED` markers placed (grep `DEFERRED`).
- **`consoleController.lua`** — `get_compy_input`/`get_compy_namespace` documented (new input API,
  architectural-contract wrapper); `input_ref` localization explained; legacy `input()` got return
  annotation + **C2 warns** on its 3 guards + a force-flag `DEFERRED (m4/m5)`; `write_to_input` got a
  **C2 warn**, `ui`→`overlay` rename, "sets text not prompt" doc + a stale-view `DEFERRED (m7)`.
- **Correction — `input_max` overclaim softened.** Removed the "intentional, not a typo" claim in
  `user_input.md` (and this doc's verify item). Per the human (monster-block author): which of 14/16
  is correct is **not settled** — now marked an open review item, no canonicality asserted.
- **Correction — A2 re-opened as deferred.** The bottom sink may yet need `keys_pressed` (e.g.
  uniform Shift+Enter handling); reclassified from "resolved" to **DEFERRED (m4/m5)** in the doc,
  code (`userInputController` notes), and §A2.

Fully cleaned (0 raw review markers): all of `userInputController.lua`, `controller.lua`, `key.lua`,
`main.lua`, `consoleController.lua`, `keys_pressed_spec.lua`, `overlay_spec.lua`, `singleton_spec.lua`.

**Test note:** the durable C2 warn (`show()`) is covered by two contract tests. The legacy C2 warns
(`input()`/`write_to_input`) are **not** unit-tested — those are `prepare_project_env` closures, not
unit-reachable without harness work, and are removed in **M8**; flagged here rather than silently
skipped.

**Deferred (now carried as in-code `DEFERRED` markers, not raw REVIEWs):** A2 sink-`keys_pressed` and
the legacy `input()` force-flag → **m4/m5**; `get_compy_input` method-stubs and `write_to_input`
stale-view → **m7**; A3 `oneshot` + the legacy wrappers' removal → **m8**; **A8** test
behaviour-vs-internals restructure and **A6** dispatch pivot → **E9**. None blocking M2 sign-off.
