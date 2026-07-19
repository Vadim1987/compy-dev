# DI1 — Doc-A fidelity audit (consolidated verdict table)

_Session13 (Opus orchestrator), 2026-07-19. Per `validation/plan.md` Phase DI, step DI1._

**Doc A** = `doc/development/wip/77-new-input-api/notes/input-contracts.md` — a pre-implementation
"current behaviour" contract record, written **before** the #77 rewrite shipped and never
re-confirmed against the delivered code. ~30 test/fixture comments still cite it; it is slated
for deletion with the `wip/77` tree. DI1 audits **whether each section still describes shipped
code, and whether its content is already homed in the persistent corpus** — the evidence base for
the DI2 owner ruling (promote / merge / reword refs).

**Method.** Two sequential Sonnet evidence workers produced per-section dossiers
(`validation/outcomes/DI1-a-evidence.md` §1–§5, `DI1-b-evidence.md` §6–§9) against `src/**` via
grep + the `lua-lsp` MCP server. The orchestrator consolidated the verdicts and **independently
re-verified every load-bearing correction in code** (see "Orchestrator spot-checks" below).

**Circularity guard (honoured).** Doc A was verified against **CODE (`src/**`), never the test
suite** — the suite's own fidelity is Phase TF's question; using it as doc A's witness would be
circular. Corpus-DOC coverage (Axis 2) is cited from the persistent docs, not from tests.

## Two axes

- **Axis 1 — fidelity vs shipped code:** `still-true` / `stale-mechanism` (a "(current
  realization)" note describing the pre-rewrite world) / `superseded-by-shipped` (a
  forward/"0.1.0-mN" contract that has since **landed**, so the temporal tag is now wrong, or a
  contract the shipped design reshaped). Where a row separates an OUTCOME contract from a
  MECHANISM note, the two are judged separately.
- **Axis 2 — corpus home:** `already-covered` (cite the corpus doc + section) / `unique-no-home`
  (no persistent mirror — a merge/promote candidate) / `partial`.

## The dominant pattern (one sentence)

Doc A's **outcome-level contracts are overwhelmingly still-true**, but its **"today's mechanism"
notes and every `[forward / 0.1.0-mN]` tag are pervasively `superseded-by-shipped`** — the #77
rewrite it anticipated as *forward* has *landed* — and **nearly all of its content is already
homed in the persistent corpus** (dominantly `internals/user_input.md`, which is in several
places **more current than doc A**). The genuinely `unique-no-home` residue is thin.

---

## Verdict table

| Doc-A section | Axis 1 — fidelity | Axis 2 — corpus home | Note |
|---|---|---|---|
| §1 Premise / read-discipline | still-true (methodology); its factual aside on what #77 changed has **landed** | partial — tag/provenance *methodology* is unique-no-home (doc scaffolding, should not be promoted); the "what changed" aside already-covered: `decisions/input.md` Decision 1 + "Where the shipped system differs from the design intent" | Meta-preamble, not a testable contract row. |
| §2 Keypressed vs textinput channels | still-true | already-covered: `internals/user_input.md` "Data flow" (near-verbatim, incl. the two keypressed-triggered exceptions) | LÖVE/compy-convention fact, orthogonal to the rewrite. |
| §3 exclusivity invariant | still-true | already-covered: `decisions/input.md` Decision 1 | The ratified, currently-enforced invariant. |
| §3 glossary — **route** | "today" half **superseded-by-shipped** (shipped set already = the doc's "rewrite" target `{Console, Editor, ProjectInputController}`; no `overlay` object occupies a slot) | already-covered: Decision 1; `internals/user_input.md` "Dispatch chain" | |
| §3 glossary — **sink** | still-true (Console/Editor still lack PIC's tiered sink; #77 scoped the chain to the project route) | already-covered: Decision 1 consequence paragraph | |
| §3 glossary — **widget** | still-true (controller occupies the slot, widget never does — grep of `love.keypressed/textinput/keyreleased =` returns only controller-level assignments) | already-covered: `internals/user_input.md` "Keyboard Handling" / "Dispatch chain"; Decision 1 | |
| §3(C) hidden widget does not consume | still-true (`_is_hidden_overlay` guards open all three UIC keyboard/text handlers, `userInputController.lua:440-443,477,728,744`) | already-covered: Decision 2; `internals/user_input.md` | The forward "internal hidden-check" design, now landed. |
| §3 slot-occupant / `app_state` selects route | still-true (`set_default_handlers` vs `occupy_keyboard`; all seven states assigned) | already-covered: Decisions 1 & 11; `internals/user_input.md` "Dispatch chain" | |
| §3 two-step / "free `show_widget()` is incoherent" | still-true (no free-floating `show_widget()` symbol in `src/**`) | **unique-no-home** (the negative-scenario framing); underlying two-step model covered by Decision 1 | |
| §3 reset semantics (re-activation) | still-true (exact match `show`/`open_fresh`, `userInputController.lua:288-310`) | already-covered: `internals/user_input.md` "Singleton lifecycle" (near-verbatim) | |
| §4 completeness table | shape still-true (no silent cells); individual cells resolve as their §5 rows | **unique-no-home as a table** (no corpus doc holds the mode×channel matrix); cells covered piecemeal | If promoted, needs re-deriving — its "forward §7.1" annotations are now stale. |
| §5.1 keypressed EXCLUSIVE | OUTCOME still-true; **MECHANISM superseded-by-shipped** (overlay gate gone; PIC occupies slot, runs 4-tier `_dispatch`; `get_user_input` survives only as CC's intra-route forward) | already-covered: Decisions 1 & 2; `internals/user_input.md` "Dispatch chain" (states the gate removal explicitly) | The canonical inverted-temporal-frame case. |
| §5.2 textinput EXCLUSIVE | OUTCOME still-true; MECHANISM superseded-by-shipped (identical to §5.1) | already-covered: same as §5.1 + "Data flow" | |
| §5.3.1 keyreleased — overlay diversion | **superseded-by-shipped** (release now runs the same 4-tier chain; the "does any consumer consume keyreleased" open Q is answered: the sink does) | already-covered: `internals/user_input.md` "Key release" | |
| §5.3.2 keyreleased — CC-internal editor-fork gap | still-true (`ConsoleController:keyreleased`, `consoleController.lua:1241-1244`, no `app_state=='editor'` branch; editor/search define no `:keyreleased`) | already-covered **near-verbatim**: `internals/user_input.md` "Key release" | doc-A's own line cite (`:1090-1093`) is drifted; content solid. |
| §5.4 inspect — console owns surface | still-true (outcome + mechanism exact) — **but its provenance claim "not documented in internals/user_input.md; first record" is now FALSE** (see Findings) | already-covered: `internals/user_input.md` "Dispatch chain" ("`inspect` overrides all of the above", near-verbatim); Decision 12 | Out-of-radius, owner-ruling-deferred. |
| §5.5 mouse EXCLUSIVE | still-true | already-covered: `internals/user_input.md` "Framework-level click handling" / "Direct mouse events" / "Input widget mouse" | Pointer gateway is a thinner broadcast than keyboard (own tech-debt item). |
| §5.6 touch EXCLUSIVE | still-true (widget touch handlers are `-- TODO` stubs) | already-covered: `internals/user_input.md` "Touch" | |
| §5.7 wheelmoved | still-true (route-axis + CHARACTERIZE mechanism both hold; widget `wheelmoved` is a stub) | already-covered: `internals/user_input.md` "Direct mouse events" | |
| §5.8 search — third MVC triad | still-true across every sub-claim (`SearchController`/`SearchModel`, no `:keyreleased`, `nil` evaluator, `clear()` bypasses its own controller) | already-covered **near-verbatim** (largest overlap found): `internals/user_input.md` "Search — a third widget instance" | Content fully preserved already if doc A is deleted. |
| §5.9 the one rule (summary) | still-true (rollup; global-shortcuts-non-consuming independently confirmed) | already-covered distributed; as a *digest* it's a convenient unique restatement, but every constituent fact is homed | |
| §6.1 held-key set lifecycle | bookkeeping still-true; **"zero src/ consumers … inert, staged for §7.4" is superseded-by-shipped / FALSE** — PIC `_dispatch` consumes `Controller.keys_pressed`/`held_keys()` (see Findings) | already-covered, **corpus more current**: `internals/user_input.md` "Key state: `Controller.keys_pressed` and `combo_string`" | Highest-value correction. |
| §6.2 combo serialisation | format still-true; **"no in-src consumer … staged" superseded-by-shipped / FALSE** — `combo_string` is the live tier-1/2 dispatch lookup in `_dispatch` (`projectInputController.lua:199-200`) | already-covered, corpus more current: "Key state"; Decision 8 | Same underlying correction as §6.1. |
| §6.3 global shortcuts non-consuming | still-true (incl. play-mode narrowing to restart/profile) | already-covered: `internals/user_input.md` "Dispatch chain"; Decision 1 | Sits above the route rewrite. |
| §6.4 slot restoration on stop | still-true (`set_default_handlers` wholesale) | already-covered: `internals/user_input.md` "Dispatch chain"; Decision 11 | **Now two restoration paths** exist — wholesale + named `release_keyboard_route` (§7.2 landed). |
| §6.5 legacy solicitation path | **superseded-by-shipped, decisively** — the whole API was **deleted** (`b4d96ec` M8-03; zero defs in tracked `src/`) | already-covered: `input_api.md` "Migration from the legacy globals"; `technical_debt/input.md` dead-path items | **Strongest delete-don't-promote case** — describes removed code in present tense. |
| §6.6 widget activation/reset | **split:** first three bullets + reset-impls paragraph still-true; `hide()`-no-cancel-chain still-true; **"auto-close via pushed `userinput` event" stale-mechanism** (now direct synchronous `hide()`); forward-notes (a) m6 cancel-chains & (b) m7 `configure()` **superseded-by-shipped, landed**; cursor-split **partially stale** ("compy: nothing yet" now false — `compy.input.get_cursor/set_cursor` exist) | already-covered: `internals/user_input.md` "Cursor manipulation and 'reset'" (near-verbatim reset-impls) + "Submit and cancel" + "`configure(config)`"; Decision 6; `input_api.md` "Live reconfigure" | |
| §6.7 framework click detection | still-true (0.4s / 2.5px; `compy.singleclick`/`doubleclick`) | already-covered near-verbatim: `internals/user_input.md` "Framework-level click handling" | |
| §7.1 project key/text reach project sink | **superseded-by-shipped** (landed: `occupy_keyboard`, PIC 4-tier `_dispatch`) | already-covered: Decisions 1 & 2; "Dispatch chain" | |
| §7.2 restoration named to console | **superseded-by-shipped** (landed as a real 2nd path, `release_keyboard_route`, `controller.lua:798-803`) | already-covered: Decision 11; "Dispatch chain" | |
| §7.3 native-handler coexistence | **superseded-by-shipped** (landed: `project_natives` → tier-3 `_generic_callback` precedence `on_* or native`) | already-covered: Decision 10; "Dispatch chain" | |
| §7.4 `isrepeat` reaches keypressed path | **superseded-by-shipped** (both m4/m5 landed; uniform triple incl. sink); the m4↔m5 keyreleased cross-ref gap has **no code-level consequence** (the tier exists, symmetric) | already-covered: "Key state"; `technical_debt/input.md` "Combo-tier key-repeat semantics" | The spec-doc wording gap itself is a `design/spec/` question, no corpus home. |
| §8 out-of-radius (4 items) | all still-true (item 4 cursor-half partially stale, as §6.6) | already-covered — **home is `internals/user_input.md`** (three named sections: "Key release", "Dispatch chain", "Search…", "Cursor manipulation and 'reset'"), **not** `technical_debt/input.md` | Corrects the earlier expectation that these were tech-debt-homed. |
| §9 open questions (6) | see "Open-questions status" below | mixed (mostly already-covered; two `unique-no-home`) | Items 2 now-resolvable; 3 & 5 still open; 1/4/6 resolved/superseded. |

---

## Fidelity findings — doc-A claims that are demonstrably FALSE against shipped code

These are the rows where doc A does not merely carry a stale *tag* but makes a positive claim
that the code contradicts. They matter for DI2 because **promoting/merging them as-is would import
a falsehood.**

1. **§6.1 / §6.2 "`keys_pressed` and `combo_string` have zero current `src/` consumers … inert
   infrastructure staged for §7.4."** FALSE. `ProjectInputController:_dispatch`
   (`projectInputController.lua:198-207`) computes `Controller.combo_string(trigger,
   Controller.keys_pressed)` as the **live tier-1/2 combo lookup on every project keyboard/text
   event**, and each PIC channel threads `Controller.held_keys()` into `_dispatch`. The forward
   consumer doc A said was "staged" has **shipped**. The corpus (`internals/user_input.md` "Key
   state") already states the current reality correctly.
2. **§5.4 "This is not currently documented in either `internals/console.md` or
   `internals/user_input.md`; this pass is its first record in a durable doc."** FALSE.
   `internals/user_input.md` documents the inspect mechanism near-verbatim (`get_user_input()`
   returns nil under inspect; `ConsoleController:suspend()` physically swaps slots; REPL over
   `project_env` — "a live debugger console"). The *content* is still-true; only the novelty claim
   is stale. Consequence: this section is **not** `unique-no-home` despite doc A asserting so.
3. **§6.6 cursor-split "`compy`: nothing yet."** Stale — `compy.input.get_cursor()` /
   `set_cursor(line, col)` / `set_text` now exist on the project surface
   (`consoleController.lua:520-545`; 0.1.0-m7 landed). The Model/Controller-layer halves of the
   same paragraph ("Controller narrower passthrough missing `jump_end`/`cursor_left`/`right`/
   `move_cursor`"; "`Model:set_cursor` raw unvalidated assignment") are **still accurate**.
4. **§6.6 "auto-close on submit … today via a pushed `userinput` event."** Stale-mechanism —
   `submit()` now calls `deliver()` then `self:hide()` synchronously; nothing pushes `'userinput'`
   anywhere in `src/**` (`handlers.userinput` is unreachable dead code, already a tech-debt item).
   Outcome (auto-close) unchanged; the implementation detail is wrong.

## Open-questions status (§9)

1. Sink receives `keys_pressed`/`isrepeat` — **already resolved (yes)**, re-confirmed: `_dispatch`
   forwards the uniform triple to `_sink`. Homed: "Key state".
2. `app_state == 'starting'` ever observed by an input path — **now answerable: NO.** `main.lua`
   sets `'starting'` (`:286`) then `'ready'` (`:319`) inside the same synchronous `love.load()`,
   before the event pump starts. `unique-no-home` (a one-liner in "Dispatch chain" would close it).
3. Sink-as-default coupling (project overriding `on_key_pressed` with a truthy return silently
   disables `on_limit_reached`) — **still-true, still-unruled** (conditional on the project's
   return-value convention). **`unique-no-home`** — a genuine promote candidate for
   `technical_debt/input.md`.
4. Combo-tier key-repeat semantics — **still an open (unruled) question**, but the specific
   *provisional leaning* doc A recorded (fresh-only at tiers 1-2) was **not adopted**; shipped
   behaviour is the opposite (tiers 1-2 fire on every repeat), still `DEFERRED` in code.
   Already-covered: `technical_debt/input.md` "Combo-tier key-repeat semantics are shipped
   unsettled" (cleanest verbatim match in the audit).
5. m4↔m5 keyreleased dispatch cross-reference gap — **no code-level gap** (the keyreleased
   dispatch tier exists, symmetric with the other two channels). The spec-document wording
   mismatch is a `design/spec/` question, out of `src/**` scope, no corpus home.
6. `combo_string`/`keys_pressed` zero-callers caveat — same fact as §6.1/§6.2,
   **superseded-by-shipped**.

## Corpus drift fold-in (`doc/development/tests.md`)

`tests.md` "Input Contract Suite" section (line 69) states **"808 successes / 0 failures / 0
errors / 4 pending (confirmed by a live run)"** and cites the four pending rows at lines
**101 / 153 / 161 / 222**. The live suite is **815 / 0 / 0 / 4** with pendings at **118 / 172 /
185 / 246** (the same four rows by content — pure count/line drift). **Recorded here as a DI1
finding; the fix is a DI3 execution action** (the plan assigns "refresh `tests.md` facts" to DI3),
not applied in this audit.

## Orchestrator spot-checks (independent code re-verification of the load-bearing corrections)

Per the standing "verify every sub-agent claim in code" discipline, the four verdict-flipping
corrections were re-checked directly, not taken from the dossiers:

- §6.1/§6.2 consumers: `sed` of `projectInputController.lua:195-275` — confirmed `_dispatch` calls
  `Controller.combo_string(trigger, Controller.keys_pressed)` and all three channels pass
  `Controller.held_keys()`. ✓
- §6.5 removal: grep of `src/**` for legacy-global definitions — **zero** in tracked source (hits
  only in untracked `src/vadexamples/**` scratch + READMEs, and a local variable named
  `user_input` at `controller.lua:1024`); `git log b4d96ec` confirms "remove legacy text-input
  globals + poll machinery (M8-03)". ✓
- §9-item-2 'starting': `main.lua:272` (`love.load`), `:286` (`='starting'`), `:319`
  (`='ready'`) — same synchronous call. ✓
- §5.4 novelty claim false: read of `internals/user_input.md` around line 168 — the inspect
  mechanism is documented near-verbatim. ✓

---

## Evidence bearing on DI2 (owner decides — NOT ruled here)

DI2 is the owner-gated ruling on promotion form: (a) promote a re-baselined doc A as a new corpus
doc; (b) merge surviving unique content into existing corpus homes, doc A stays a frozen wip
record; (c) no promotion — reword the ~30 clause refs to cite behaviour/corpus. Session12's prior
(to be tested by this audit) was **(b)**. The DI1 evidence bears on it as follows — presented as
evidence, not as a ruling:

- **Against a new standalone doc (option a):** doc A is `already-covered` almost everywhere,
  dominantly by a **single** existing home (`internals/user_input.md`), and in several places
  (§6.1/§6.2) the corpus is **already more current than doc A**. Promoting a re-baselined doc A
  would (i) require re-baselining a large document whose forward tags are all inverted and whose
  positive claims include four now-false statements, and (ii) create a sixth overlapping input doc
  — against the strategic frame's "no moving parts beyond the ask."
- **The merge residue is small (option b's actual workload).** After removing everything
  already-covered and everything describing removed/reshaped code, the genuinely `unique-no-home`
  content that a reader would lose on doc-A deletion is thin:
  - §9-item-3 (sink-as-default silent-disable of `on_limit_reached`) → `technical_debt/input.md`
    (a real, unrecorded coupling — the clearest merge target).
  - §9-item-2 ('starting' never observed) → one line in `internals/user_input.md` "Dispatch chain".
  - Doc-scaffolding that should **not** be promoted at all: §1 tag/provenance methodology, the §4
    completeness-table device, the §5.9 rule-of-five digest, the §3 "incoherent free `show_widget()`"
    framing — these are this-doc editorial apparatus, not system facts.
- **For the ~30 citing comments (bears on option c):** because the cited content is overwhelmingly
  already-homed, "reword to cite behaviour/corpus" (c) largely collapses into (b) — most refs would
  simply be re-pointed at the `internals/user_input.md` / `decisions/input.md` section that already
  says the thing. This is a **DI3 execution** detail (re-run the A1 retarget over the doc-A family)
  regardless of whether the owner picks (b) or (c).

**Orchestrator reading (a recommendation-as-proposal, for the owner to accept or overturn):** the
evidence supports **(b) merge** — specifically, merge the two small `unique-no-home` facts into
their natural homes (`technical_debt` + one line in `internals`), leave doc A a frozen wip record,
and let DI3 re-point the ~30 clause refs at the corpus. There is **no case for promoting doc A
whole** (option a): it would import inverted tags and four false claims into the canonical corpus.

## Validation-map refresh

`notes/input-suite-validation-map.md` (the doc-A-clause → suite-row bridge) was **leveraged** as
Axis-2 evidence and is **refreshed** with a DI1 status banner: it records that DI1 has audited doc
A against code (not the suite), that most clauses are now `already-covered`/`superseded-by-shipped`
per this table, and it carries its three open findings forward to **Phase TF** (the
editor-keypressed-vs-textinput coverage gap; the §5.8 search `pending`; the `F.reset()` 14-line
breach). No suite rows were re-derived here — that is TF's scope, and re-deriving them would breach
the circularity guard.
