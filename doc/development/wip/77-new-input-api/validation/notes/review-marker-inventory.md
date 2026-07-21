# REVIEW-marker inventory (input test/source files)

## Purpose

The owner has injected inline `-- REVIEW[:/kind]:` remarks across the input
test and source files over many prior sessions (feature #77 and its
predecessors). No resolution-and-prune pass has ever run, so they have
accumulated. This document is a **persistent, first-cut inventory** of every
such marker: a stable ID, its verbatim text, what it comments on, and a
provisional bucket. It drives owner-gated cleanup — first sweeping
genuinely-dissolvable markers in small batches, then triaging the rest. This
pass does **not** touch any marker, source, or test; it is inventory only.

## Maintenance protocol (living doc)

This document is updated after each sweep. When a marker is resolved, its
**Disposition** cell is filled in (what happened: dissolved / relocated /
kept / superseded by RVW-xxx) — the row is **struck through**, never
deleted, so the ID stays greppable and the history stays intact. IDs are
never reused. New markers discovered later (if any) are appended with new
IDs, not inserted into the existing sequence.

## Scope

Own-code `-- REVIEW[:/kind]:` inline comments only, in `tests/` and `src/`
(excluding vendored `src/lib/`). The owner's markers use a small taxonomy —
`REVIEW:` (bare/"plain"), `REVIEW/clarity:`, `REVIEW/fidelity:`,
`REVIEW/DOC:`, `REVIEW/cosmetic:`, `REVIEW/nitpick:`, `REVIEW/consistency:`
(and `consistence:`), `REVIEW/coherence:`, `REVIEW/quality:`,
`REVIEW/terminology:`, `REVIEW/RESPONSE:`, `REVIEW/OPEN`, and compounds
(`clarity/consistence`, `fidelity/consistency`, …) — so the detector is
`REVIEW[:/]`, not a bare `REVIEW:` string match. Enumerated with:

```
grep -rn 'REVIEW[:/]' tests/ --include=*.lua
grep -rn 'REVIEW[:/]' src/ --include=*.lua | grep -v 'src/lib/'
```

**Total: 138** (114 in `tests/`, 24 in `src/`), matching the commissioned
expectation exactly — no count deviation. Two look-alike lines were checked
and confirmed NOT markers (prose that merely contains the word "REVIEW" with
no `:`/`/` immediately after, so the detector regex does not — and should
not — match them): `tests/input/input_routing_spec.lua:13` ("SUITE-LEVEL
REVIEW NOTES" section header) and `tests/helpers/input_fixture.lua:128`
("The line-123 REVIEW that used to sit here…", itself a note that an older
REVIEW was already resolved). `doc/`, `wip/`, and vendored `src/lib/` were
surveyed and are excluded as citation-only / not our code — not inventoried.

Two markers span multiple lines (continuation lines carry no token) and are
captured verbatim in full below: `tests/input/input_routing_spec.lua:18-19`
and `src/controller/controller.lua:450-452`. All other 136 markers are
single physical lines (adjacent non-tagged comment lines checked and
confirmed to be separate, independently-complete prose, not continuations).

## Reading the entries

Each entry: **ID**, **Location** (`path:line`), **Kind** (taxonomy suffix,
verbatim — `plain` = bare `REVIEW:`), the full **Verbatim** remark, what it
**Comments-on**, a provisional **Bucket** (`DISSOLVE?` only where current
code/docs were checked and concretely answer or moot the concern; `TRIAGE`
otherwise — default), a one-line evidence-anchored **Rationale**, and an
empty **Disposition** (`—`, filled during sweeps).

---

## `tests/helpers/input_fixture.lua` (16)

**RVW-001** `tests/helpers/input_fixture.lua:150` — Kind: `DOC`
> "REVIEW/DOC: 'slots', 'gate last-resort route' sound exotic and cannot be understood without context -- dependence on 'when no widget is up' looks like abstraction leak; if its just the way framework sets the controllers when launched -- tell exactly that"
- Comments-on: the native-slot wiring block (`Controller.set_love_keypressed(CC)` … `set_love_update(CC)`, F.setup)
- Bucket: **TRIAGE**
- Rationale: mixes a wording ask with a suspected abstraction leak; owner call on both → TRIAGE
- Disposition: —

**RVW-002** `tests/helpers/input_fixture.lua:160` — Kind: `DOC`
> "REVIEW/DOC: explain what the line before does and why its needed"
- Comments-on: line 159, `Controller.set_love_update(CC)` in `F.setup`
- Bucket: **TRIAGE**
- Rationale: asks for content to be written, not a factual question → TRIAGE
- Disposition: —

**RVW-003** `tests/helpers/input_fixture.lua:191` — Kind: `DOC`
> "REVIEW/DOC: we have 'native' handlers, and we have 'compy' handlers, and then we have compy input handlers... there could be a confusion. Can we find a better name explaining this setter unambiguously? Maybe \"project_set_compy\"? (it will also exactly match what it does."
- Comments-on: `F.set_compy_handler(name, fn)` (line 197)
- Bucket: **TRIAGE**
- Rationale: naming suggestion — owner call, same pattern as the `gate`/`deliver` naming markers elsewhere → TRIAGE
- Disposition: —

**RVW-004** `tests/helpers/input_fixture.lua:192` — Kind: `plain`
> "REVIEW: maybe we should instead use common method 'project_compy_namespace' (which encapsulates CC:get_project_env().compy), and let calling code work from there? (explicirly setting and getting .input, or other attributes)"
- Comments-on: `F.set_compy_handler` / the `CC:get_project_env().compy...` access pattern repeated across the fixture
- Bucket: **TRIAGE**
- Rationale: refactor-extraction proposal; design call → TRIAGE
- Disposition: —

**RVW-005** `tests/helpers/input_fixture.lua:205` — Kind: `plain`
> "REVIEW: is it used? Maybe name it 'love_update' for better grepability and transparency?"
- Comments-on: `F.update(dt)`
- Bucket: **TRIAGE**
- Rationale: "is it used?" half is answered — yes, 4 call sites in `tests/input/input_shortcuts_click_spec.lua:100,102,113,125`; the rename ask still stands → TRIAGE
- Disposition: —

**RVW-006** `tests/helpers/input_fixture.lua:211` — Kind: `plain`
> "REVIEW: why not via compy.input.show ?"
- Comments-on: `F.show_widget(opts)`
- Bucket: **TRIAGE**
- Rationale: asks whether the helper should route through the public API instead of `singleton:show` directly — design call → TRIAGE
- Disposition: —

**RVW-007** `tests/helpers/input_fixture.lua:217` — Kind: `plain`
> "REVIEW: is it adequate mocking? When project sets up 'love' its actually sets up project_env.love -- sandboxed table what is passed as 'userlove' in a container. Here' instead it sets up direct love callback?"
- Comments-on: `F.running_project(name, fn)`
- Bucket: **TRIAGE**
- Rationale: the doc at lines 218-220 confirms the described mechanism (direct `love[name]` assignment, not `project_env.love`) is accurate; whether that's adequate fidelity is a judgment call → TRIAGE
- Disposition: —

**RVW-008** `tests/helpers/input_fixture.lua:226` — Kind: `DOC`
> "REVIEW/DOC: 'slot' and 'tier-3' language should rather not be there. instead I'd pferer to see specific pointer to the code/function which is mocked (and why is it mocked, not called?)"
- Comments-on: `F.activate_project(natives)` doc block (lines 230-238)
- Bucket: **TRIAGE**
- Rationale: vocabulary ask plus a "why mock not call" design question → TRIAGE
- Disposition: —

**RVW-009** `tests/helpers/input_fixture.lua:227` — Kind: `plain`
> "REVIEW: I am not sure the level of mocking is correct there. I would rather expect setting 'natives' as project environment (like userlove) and calling the normal framework operation that runs project"
- Comments-on: `F.activate_project(natives)`
- Bucket: **TRIAGE**
- Rationale: test-fidelity design concern re mocking depth; same theme as RVW-006/008/010 → TRIAGE
- Disposition: —

**RVW-010** `tests/helpers/input_fixture.lua:228` — Kind: `DOC`
> "REVIEW/DOC: 'REAL activation path' is claimed, not proved (at least via reference to source code, better by calling real code)"
- Comments-on: `F.activate_project`'s doc claim "the REAL activation path"
- Bucket: **DISSOLVE?**
- Rationale: claim checked and substantiated — `F.activate_project` (line 241) calls `Controller.set_user_handlers(natives or {}, CC)`, the exact function `src/controller/consoleController.lua:123` calls (`cc.main_ctrl.set_user_handlers(env['love'], cc)`) when a real project run starts; the "proof" the marker asks for exists in-code, just add the cross-reference → DISSOLVE?
- Disposition: —

**RVW-011** `tests/helpers/input_fixture.lua:229` — Kind: `DOC`
> "REVIEW/DOC: 'M4 ruling-1' is emphemeral dev-time reference, and I suspect the whole comment may reflect outdated logic/architecture"
- Comments-on: `F.activate_project` doc block, "the four-tier chain (not the M4 ruling-1 forward)" (lines 234-235)
- Bucket: **TRIAGE**
- Rationale: checked — the M4 ruling-1 forwarding WAS removed (per `doc/development/wip/77-new-input-api/implementation/outcomes/M5c-04-route-lifecycle.md`), and the comment correctly describes current dispatch as the four-tier chain, only naming the old mechanism parenthetically to disambiguate; not outdated, but the ephemeral dev-session jargon ("M4 ruling-1") is real and worth a rewrite — clarity call, not accuracy → TRIAGE
- Disposition: —

**RVW-012** `tests/helpers/input_fixture.lua:245` — Kind: `plain`
> "REVIEW: why this low-level machinery and not a call of some existing function? the intent is plausible, the implementation is suspicious"
- Comments-on: `F.show_selectable_widget(lines)`
- Bucket: **TRIAGE**
- Rationale: implementation-approach question, same "call real framework code" theme as RVW-006/009/013/014/016 → TRIAGE
- Disposition: —

**RVW-013** `tests/helpers/input_fixture.lua:260` — Kind: `plain`
> "REVIEW: do not we have framework/consolecontroller method for that? Why not call it? Otherwise its not clear which part of the real lifecycle we're mimicking there (if any)"
- Comments-on: `restore_native_slots()` (local fn, lines 265-271)
- Bucket: **TRIAGE**
- Rationale: same "call real framework code" pattern as RVW-009/012/014/016; owner call whether to consolidate → TRIAGE
- Disposition: —

**RVW-014** `tests/helpers/input_fixture.lua:261` — Kind: `plain`
> "REVIEW: in general, I'd prefer helper/fixture functions to call real framework's code with some test-specific parameters/configuration -- not implement its own 'provision/deprovision' algorithms which will inevitably deviate from what real framework is doing"
- Comments-on: general fixture-design principle, sits directly above `restore_native_slots()`
- Bucket: **TRIAGE**
- Rationale: this is the general form of the same principle repeated at RVW-013/016 for specific functions — architecture/testing-philosophy call, not a single-function fix → TRIAGE
- Disposition: —

**RVW-015** `tests/helpers/input_fixture.lua:283` — Kind: `plain`
> "REVIEW: is not there a framework/controller method doing this? why replicate instead of calling it?"
- Comments-on: `reset_chain()` (local fn, lines 290-299)
- Bucket: **TRIAGE**
- Rationale: same "call real framework code" pattern as RVW-013/016 → TRIAGE
- Disposition: —

**RVW-016** `tests/helpers/input_fixture.lua:303` — Kind: `plain`
> "REVIEW: good intent but why not framework method? I am sure it has methods for exiting the project and doing big cleanup"
- Comments-on: `F.reset()`
- Bucket: **TRIAGE**
- Rationale: same "call real framework code" pattern as RVW-013/015; `F.reset` is the fixture's biggest teardown routine, highest-value candidate in this cluster → TRIAGE
- Disposition: —

---

## `tests/input/highlight_shape_spec.lua` (9)

**RVW-017** `tests/input/highlight_shape_spec.lua:1` — Kind: `clarity`
> "REVIEW/clarity: 'shape contract' is jargonic. The purpose of this test is simply to isolate already-fixed regression (input blowing up in some configurations when highlighter is not set but accessed by index)"
- Comments-on: file title / describe('highlight shape contract #input')
- Bucket: **TRIAGE**
- Rationale: naming/framing call (regression test vs "contract") → TRIAGE
- Disposition: —

**RVW-018** `tests/input/highlight_shape_spec.lua:2` — Kind: `clarity`
> "REVIEW/clarity: test purpose (regression catch) should be clearly communicated both in file name, suite name, opening comments"
- Comments-on: same file header as RVW-017
- Bucket: **TRIAGE**
- Rationale: companion ask to RVW-017 — same rename/rewrite call → TRIAGE
- Disposition: —

**RVW-019** `tests/input/highlight_shape_spec.lua:23` — Kind: `coherence`
> "REVIEW/coherence: does it interfere with other tests?"
- Comments-on: `if not orig_print then _G.orig_print = function() end end` (global stub install)
- Bucket: **TRIAGE**
- Rationale: cross-file/global-state interaction question — needs checking test run order and other specs' use of `orig_print`, not verified here → TRIAGE
- Disposition: —

**RVW-020** `tests/input/highlight_shape_spec.lua:36` — Kind: `clarity`
> "REVIEW/clarity: function name does not communicate the purpose of check unambiguously"
- Comments-on: `local function view_access_ok(model)`
- Bucket: **TRIAGE**
- Rationale: naming call → TRIAGE
- Disposition: —

**RVW-021** `tests/input/highlight_shape_spec.lua:39` — Kind: `fidelity`
> "REVIEW/fidelity: does this guard betray the purpose of test?"
- Comments-on: `if h == nil then return true end` inside `view_access_ok`
- Bucket: **TRIAGE**
- Rationale: test-fidelity question re whether the early-return masks the regression path → TRIAGE
- Disposition: —

**RVW-022** `tests/input/highlight_shape_spec.lua:44` — Kind: `fidelity`
> "REVIEW/fidelity: why check test symptom instead of bug path? (i.e. calling the function which internally could've blow up?)"
- Comments-on: `return pcall(function() ... end)` in `view_access_ok`
- Bucket: **TRIAGE**
- Rationale: same test-fidelity family as RVW-021 → TRIAGE
- Disposition: —

**RVW-023** `tests/input/highlight_shape_spec.lua:51` — Kind: `clarity`
> "REVIEW/clarity: what's the difference between three modes not explained? (especially not clear how LuaEval() is different from InputEvalLua. Maybe wrap them into aliases semantically meaningful in test context? (e.g. `ev = evaluator_without_highlighter()`, `input_with_lua_evaluator', 'input_with_text_evaluator'). Or even table (ev = evaluators['text_no_hl']; m=evaluators['lua_normal']; m=evaluators['lua_with_dummy_hl'])"
- Comments-on: `it('parser present, highlighter returns nil -> hl still indexable', ...)`
- Bucket: **TRIAGE**
- Rationale: naming/structure proposal for the three evaluator variants → TRIAGE
- Disposition: —

**RVW-024** `tests/input/highlight_shape_spec.lua:53` — Kind: `clarity/fidelity`
> "REVIEW/clarity/fidelity:  how LuaEval() with nil-returning highlighter is different from case#2 and case#3? it seems to be a mix of both, but not sure which production scenarios are mapped. And maybe there shold be 4 cases? ( [lua || text] x [ missing hl || returning empty ])"
- Comments-on: `local ev = LuaEval()` inside the same `it` as RVW-023
- Bucket: **TRIAGE**
- Rationale: coverage-matrix proposal (2x2 of lua/text x missing/empty hl) — needs owner call on whether worth the added cases → TRIAGE
- Disposition: —

**RVW-025** `tests/input/highlight_shape_spec.lua:61` — Kind: `fidelity`
> "REVIEW/fidelity: claims 'empty and non-empty' but its not clear what both mean and how *both* are tested"
- Comments-on: `it('standard lua eval -> hl indexable (empty and non-empty)', ...)`
- Bucket: **TRIAGE**
- Rationale: test-description/coverage clarity question → TRIAGE
- Disposition: —

---

## `tests/input/input_cursor_text_spec.lua` (6)

**RVW-026** `tests/input/input_cursor_text_spec.lua:1` — Kind: `plain` (embedded, `{temporal/REVIEW: ...}`)
> "cursor and text surface — {temporal/REVIEW: split from input_contracts_spec.lua (TF1)}."
- Comments-on: file title / provenance note (this file is a TF1 split of the former `input_contracts_spec.lua`)
- Bucket: **TRIAGE**
- Rationale: a "temporal" self-tag flagging the note itself as possibly stale once the split settles; owner call on whether the provenance note is still wanted → TRIAGE
- Disposition: —

**RVW-027** `tests/input/input_cursor_text_spec.lua:2` — Kind: `clarity`
> "REVIEW/clarity: why the prose below describes event dispatching if the suite references active API? (getting,setting text/cursor?)"
- Comments-on: file header prose (routing invariant / dispatch-chain vocabulary block, lines 3-12)
- Bucket: **TRIAGE**
- Rationale: scope-mismatch question between boilerplate header prose and this file's actual (cursor/text API) subject → TRIAGE
- Disposition: —

**RVW-028** `tests/input/input_cursor_text_spec.lua:6` — Kind: `clarity`
> "REVIEW/clarity: route(controller) and sink(chain element in the controller) are both called 'consumer' below"
- Comments-on: the shared vocabulary paragraph (ROUTE/WIDGET/SINK), duplicated across split files
- Bucket: **TRIAGE**
- Rationale: same vocabulary-overload concern raised independently at RVW-... in `input_events_spec.lua:7` and `input_routing_spec.lua` header — terminology call → TRIAGE
- Disposition: —

**RVW-029** `tests/input/input_cursor_text_spec.lua:13` — Kind: `clarity`
> "REVIEW/clarity: phrase below has no verb so reads awkwardly ('\"x on y (...)\" -- does or means what?')"
- Comments-on: "get_cursor/set_cursor/set_text on the public project surface" (line 14)
- Bucket: **TRIAGE**
- Rationale: pure grammar/rewrite ask — but still a rewrite the owner should confirm the intended meaning of before editing → TRIAGE
- Disposition: —

**RVW-030** `tests/input/input_cursor_text_spec.lua:43` — Kind: `fidelity`
> "REVIEW/fidelity: only one case is checked -- 'when active' proven, but whether this line/col really always match cursor? not clear (otoh we're against testing all corner cases). Maybe its not worth separate case -- but running few modifications and rechecking assertions would be practical?"
- Comments-on: test body around `local input = F.compy_input()` (cursor-get case)
- Bucket: **TRIAGE**
- Rationale: coverage-adequacy judgment call → TRIAGE
- Disposition: —

**RVW-031** `tests/input/input_cursor_text_spec.lua:52` — Kind: `fidelity`
> "REVIEW/fidelity: no explicit 'hide()', no text filled -- nil could be returned just by default because input is *empty* not because its hidden"
- Comments-on: test body around `local input = F.compy_input()` (cursor default-nil case)
- Bucket: **TRIAGE**
- Rationale: raises a genuine test-fidelity gap (confound between "empty" and "hidden") — plausible but not verified against the actual assertions here → TRIAGE
- Disposition: —

---

## `tests/input/input_events_spec.lua` (48)

**RVW-032** `tests/input/input_events_spec.lua:1` — Kind: `fidelity`
> "REVIEW/fidelity: any occurence of 'singleton' in any file triggers fidelity check on the appropriate case -- is there alternative 'official' method of configuration/invocation? if access to singleton happens because we need to mock or trigger its internal methods which normally would not be accessible (boundary tests), can we wrap it into clearly test-specific function (i.e. F.mock_widget)."
- Comments-on: file-wide convention: every `F.singleton.*` access in this suite
- Bucket: **TRIAGE**
- Rationale: proposes a blanket `F.mock_widget` wrapper; suite-wide refactor, owner call → TRIAGE
- Disposition: —

**RVW-033** `tests/input/input_events_spec.lua:2` — Kind: `clarity/design/terminology`
> "REVIEW/clarity/design/terminology: I suggest following global renaming: 'singleton'->'widget', 'sink' -> 'widget', 'tier-3/tier3' -> '[project] hook[s]', 'framework handlers' -> 'global/framework handlers' (if they capture combo) or 'framework/global] shortcuts' ( if they always address only two specific keys ESC/Enter and are not configurable for generic combos handling ) , 'handlers'->'[project] handler[s]' (those which bind to key combos), '.on_{eventname}' -> 'hooks[eventname]', 'generic callbacks' -> '[project] hook[s]', How to name the 'love' hooks that project installs (legacy) as love.handlers and which are converted to 'hooks' -- its an open question. Maybe literally \"project's [sandboxed] love.* hook(s)'? suggestions are welcome. PRINCIPLE: I'd reserve word 'handlers' for combo-bound things, 'callbacks' -- for something that is called by trigger, 'hooks' -- to something that is injected in the middle of event processing and can intercept/modify it. 'routing' may remain 'routing' and rely strictly to selection of dispatcher(controller)."
- Comments-on: file-wide vocabulary (whole dispatch-chain terminology)
- Bucket: **TRIAGE**
- Rationale: the single largest, most consequential vocabulary proposal in the corpus — governs many other `clarity`/`terminology` markers below (e.g. RVW-052, 062, 070, 072, 077, 088); owner must rule on it first → TRIAGE
- Disposition: —

**RVW-034** `tests/input/input_events_spec.lua:7` — Kind: `clarity`
> "REVIEW/clarity: prose below calls both ROUTE and SINK 'consumers' which may lead to confusion: afaik 'route' is in fact controller, while 'sink' is the name for the last item in the processing chain the route enforces"
- Comments-on: file header vocabulary paragraph (lines 8-18)
- Bucket: **TRIAGE**
- Rationale: same overload noted at RVW-028; terminology call → TRIAGE
- Disposition: —

**RVW-035** `tests/input/input_events_spec.lua:20` — Kind: `clarity`
> "REVIEW/clarity: language of the prose below is broken -- it tries to say that this test covers only half of the activities but fails to say so (and its alwo not clear why we have 9 input files not just 2 spolier: because its not 'half-this/half-that' split)"
- Comments-on: file header scope note (lines 21-25, "Mechanics half of the four-tier dispatch chain…")
- Bucket: **TRIAGE**
- Rationale: rewrite ask on the file-split rationale — content call → TRIAGE
- Disposition: —

**RVW-036** `tests/input/input_events_spec.lua:29` — Kind: `clarity`
> "REVIEW/clarity: need to cleanup jargon, also the prose below partialy duplicates opening prose"
- Comments-on: "The four-tier dispatch chain" section banner (lines 31-44)
- Bucket: **TRIAGE**
- Rationale: cleanup/de-dup ask, same theme as RVW-035 → TRIAGE
- Disposition: —

**RVW-037** `tests/input/input_events_spec.lua:30` — Kind: `clarity`
> "REVIEW/clarity: prose below speaks of callbacks but we have also output callbacks -- maybe we should instead use term 'hooks' to describe what is installed by project into dispatch chain"
- Comments-on: same section banner as RVW-036
- Bucket: **TRIAGE**
- Rationale: vocabulary call, subordinate to the master proposal RVW-033 → TRIAGE
- Disposition: —

**RVW-038** `tests/input/input_events_spec.lua:54` — Kind: `fidelity`
> "REVIEW/fidelity: comment overexplains mechanics that helper does not control; first line would be enough"
- Comments-on: doc block above `local function chord(mod, k)` (lines 55-58)
- Bucket: **TRIAGE**
- Rationale: trim-the-comment ask — plausible but a content-editing call, not verified as trivial → TRIAGE
- Disposition: —

**RVW-039** `tests/input/input_events_spec.lua:59` — Kind: `quality`
> "REVIEW/quality: better allow random chords -- (...) and iterating over it? cheap and more flexible"
- Comments-on: `local function chord(mod, k)`
- Bucket: **TRIAGE**
- Rationale: test-helper generalization proposal → TRIAGE
- Disposition: —

**RVW-040** `tests/input/input_events_spec.lua:65` — Kind: `clarity`
> "REVIEW/clarity: the prose below is correct but uncomprehensible, looks like noise"
- Comments-on: "---- order, consume, fall-through" section banner (line 66)
- Bucket: **TRIAGE**
- Rationale: rewrite/removal call on the section banner → TRIAGE
- Disposition: —

**RVW-041** `tests/input/input_events_spec.lua:70` — Kind: `fidelity/consistence`
> "REVIEW/fidelity/consistence: group tests only against specific event type -- keypressed. Should rather be generalized (dynamically constructed) to test against all relevant even types (keyreleased, textinput)?"
- Comments-on: `describe('order, consume, fall-through', ...)` group
- Bucket: **TRIAGE**
- Rationale: coverage-generalization proposal (parametrize across event types) — real structural change → TRIAGE
- Disposition: —

**RVW-042** `tests/input/input_events_spec.lua:109` — Kind: `clarity`
> "REVIEW/clarity: I would use same chain with mnemonic flags as in previous case -- and probably matrix test to show interception on every step, and also that lack of step (no combo defined, no hook defined) does not prevent other parts from working"
- Comments-on: `it('a truthy combo handler stops the descent', ...)`
- Bucket: **TRIAGE**
- Rationale: proposes a coverage matrix; structural test-design call → TRIAGE
- Disposition: —

**RVW-043** `tests/input/input_events_spec.lua:110` — Kind: `clarity`
> "REVIEW/clarity: I'd double-check the 'it' description -- 'truthy handler' means handler is truthy when its function (not false or nil value). we're speaking about *return value* instead. also 'decent' describes mechanics maybe and instead we should use 'stops processing', or 'prevents reaching hook' (and testboth)."
- Comments-on: same test as RVW-042
- Bucket: **TRIAGE**
- Rationale: wording-precision call (truthy value vs return value) → TRIAGE
- Disposition: —

**RVW-044** `tests/input/input_events_spec.lua:111` — Kind: `clarity`
> "REVIEW/clarity: do we have the symmetric test 'truthy hook return value prevents reaching widget'? and symmetric tests for '*missing* handler does not prevent reaching hook, missing hook does not prevent reaching widget'?"
- Comments-on: same test as RVW-042/043
- Bucket: **TRIAGE**
- Rationale: coverage-gap question (symmetric cases); needs a coverage audit to answer, not done here → TRIAGE
- Disposition: —

**RVW-045** `tests/input/input_events_spec.lua:129` — Kind: `clarity/sanity`
> "REVIEW/clarity/sanity:"
- Comments-on: `it('is a permanent configuration', ...)`
- Bucket: **DISSOLVE?**
- Rationale: marker body is empty — no concern recorded (confirmed by direct read of the line, nothing follows the colon) — safe to drop, nothing to triage → DISSOLVE?
- Disposition: —

**RVW-046** `tests/input/input_events_spec.lua:144` — Kind: `clarity/consistence`
> "REVIEW/clarity/consistence: this test is redundant -- the whole need raised from reversing misinterpreted requirements -- test can safely go, it repeats one particular configuration tested above"
- Comments-on: `it('assigning a callback replaces only it; sink still runs', ...)`
- Bucket: **TRIAGE**
- Rationale: the marker itself claims the test is safely removable, but confirming "repeats one particular configuration tested above" requires comparing against the two prior `it`s in the same `describe` — not independently re-verified here, and deleting a test is an owner call regardless → TRIAGE
- Disposition: —

**RVW-047** `tests/input/input_events_spec.lua:155` — Kind: `clarity`
> "REVIEW/clarity: cleanup prose below and reformulate 'it' in more human-friendly way"
- Comments-on: "combo tables and normalisation" section banner (lines 157-158)
- Bucket: **TRIAGE**
- Rationale: rewrite ask → TRIAGE
- Disposition: —

**RVW-048** `tests/input/input_events_spec.lua:156` — Kind: `clarity`
> "REVIEW/clarity: maybe wrap three cases below into sub-describe"
- Comments-on: same banner as RVW-047, the three combo-normalisation `it`s below (lines 164-194)
- Bucket: **TRIAGE**
- Rationale: structural grouping suggestion → TRIAGE
- Disposition: —

**RVW-049** `tests/input/input_events_spec.lua:159` — Kind: `clarity`
> "REVIEW/clarity: mention handlers there ('tables and normalization' are characteristics of internals, not observable behaviour)"
- Comments-on: `describe('combo tables and normalisation', ...)`
- Bucket: **TRIAGE**
- Rationale: naming/framing call → TRIAGE
- Disposition: —

**RVW-050** `tests/input/input_events_spec.lua:196` — Kind: `fidelity`
> "REVIEW/fidelity: we'd rather should test that setting combo on one event does not alter propagation of other events, and same with hooks. on the other hand, this test does smoke-check in most economic way. but still testing internals is smelly!"
- Comments-on: `it('the combo tables are per-event, not one flat table', ...)`
- Bucket: **TRIAGE**
- Rationale: test-design tradeoff (internals smoke check vs behavioural test) — self-acknowledged tension in the marker itself, owner call → TRIAGE
- Disposition: —

**RVW-051** `tests/input/input_events_spec.lua:214` — Kind: `clarity`
> "REVIEW/clarity: I'd rather wrap in 'describe'"
- Comments-on: "signatures + read-only proxy" section banner (lines 216-217)
- Bucket: **TRIAGE**
- Rationale: structural grouping suggestion, same family as RVW-048 → TRIAGE
- Disposition: —

**RVW-052** `tests/input/input_events_spec.lua:215` — Kind: `clarity`
> "REVIEW/clarity: cleanup prose below and get rid of jargon ('tier-3' is 'project hook' in newly suggested vocabulary)"
- Comments-on: same banner as RVW-051
- Bucket: **TRIAGE**
- Rationale: subordinate to master vocabulary proposal RVW-033 → TRIAGE
- Disposition: —

**RVW-053** `tests/input/input_events_spec.lua:220` — Kind: `fidelity`
> "REVIEW/fidelity: no test in the group checks the contents of keypressed table (if its checked in another suit, maybe replace this comment with reference)"
- Comments-on: `describe('signatures and the read-only proxy', ...)` group
- Bucket: **TRIAGE**
- Rationale: coverage-location question — needs a cross-suite grep to answer definitively, not done here → TRIAGE
- Disposition: —

**RVW-054** `tests/input/input_events_spec.lua:221` — Kind: `plain`
> "REVIEW: why not test whole chain instead? configure all parts to be passthrough/nonconsuming (registering args and returning false), than check that every step registered the triade?"
- Comments-on: same group as RVW-053, adjacent
- Bucket: **TRIAGE**
- Rationale: alternative test-design proposal → TRIAGE
- Disposition: —

**RVW-055** `tests/input/input_events_spec.lua:234` — Kind: `fidelity`
> "REVIEW/fidelity: only type signature is tested but not what is really delivered -- so its not a test of contract, only of its type-compliance"
- Comments-on: `it('keypressed carries (k, keys_pressed, isrepeat)', ...)` assertions
- Bucket: **TRIAGE**
- Rationale: test-depth gap — plausible, not independently re-verified → TRIAGE
- Disposition: —

**RVW-056** `tests/input/input_events_spec.lua:240` — Kind: `clarity`
> "REVIEW/clarity: fix jargon ('tier-3' -> 'hook'?)"
- Comments-on: `it('isrepeat threads to the tier-3 callback', ...)` doc
- Bucket: **TRIAGE**
- Rationale: subordinate to RVW-033 → TRIAGE
- Disposition: —

**RVW-057** `tests/input/input_events_spec.lua:254` — Kind: `clarity`
> "REVIEW/clarity: this test IS testing both reading from proxy (i.e. proxy contents) and prohibited writing. But its not stated in the 'it' (definition focused only on write-prohibition). Also, word 'proxy' is not well-undertandable without details and describes implementation, not behaviour."
- Comments-on: `it('the keys_pressed proxy is read-only', ...)`
- Bucket: **TRIAGE**
- Rationale: `it`-description accuracy + naming call → TRIAGE
- Disposition: —

**RVW-058** `tests/input/input_events_spec.lua:255` — Kind: `clarity/consistency/fidelity`
> "REVIEW/clarity/consistency/fidelity: Should instead be something like \"describe('pressed keys table') -> it('contains pressed keys') , it('does not contain released keys'), it('can not be modified from hook or handler'))\" and multiply it by evet type?"
- Comments-on: same test as RVW-057
- Bucket: **TRIAGE**
- Rationale: concrete restructure proposal, structural change → TRIAGE
- Disposition: —

**RVW-059** `tests/input/input_events_spec.lua:272` — Kind: `clarity`
> "REVIEW/clarity: jargon ('sink' -> 'widget hook', 'widget'?)"
- Comments-on: `it('the sink receives the uniform keypressed triple', ...)` doc
- Bucket: **TRIAGE**
- Rationale: subordinate to RVW-033 → TRIAGE
- Disposition: —

**RVW-060** `tests/input/input_events_spec.lua:283` — Kind: `fidelity`
> "REVIEW/fidelity: are we testing internals there instead of behavior? in this case its justified if we cannot configure widget from the outside but need to ensure it received keypress -- but then maybe explicitly admit that this is test-specific patching. Maybe expose method like F.mock_widget_with(...) so that purpose will be clear, especially given the fact same mechanics is used in few other places. Right now it looks like legit configuration, which it is not (or is it?)"
- Comments-on: `F.singleton.keypressed = function(...)` monkeypatch, same test as RVW-059
- Bucket: **TRIAGE**
- Rationale: proposes the same `F.mock_widget`/`F.mock_widget_with` wrapper as RVW-032 — recurring pattern across the file, owner call once, applies broadly → TRIAGE
- Disposition: —

**RVW-061** `tests/input/input_events_spec.lua:288` — Kind: `plain`
> "REVIEW: why set to nil here?"
- Comments-on: `F.singleton.keypressed = nil` (immediately after the RVW-060 monkeypatch, before assertions)
- Bucket: **TRIAGE**
- Rationale: unclear from local code alone why the patch is undone before assertions rather than in teardown; plausible reasons (avoid leaking into `F.reset`/other tests) not confirmed → TRIAGE
- Disposition: —

**RVW-062** `tests/input/input_events_spec.lua:295` — Kind: `consistency`
> "REVIEW/consistency: this test checks the delivery of keys_pressed table -- should not it live alongside the test which checks the contents of passed table (symmetry: key present on keypressed (and tetnput ?), released on keyreleased)"
- Comments-on: `it('a keyreleased participant sees the key already gone', ...)`
- Bucket: **TRIAGE**
- Rationale: reorganization/grouping proposal → TRIAGE
- Disposition: —

**RVW-063** `tests/input/input_events_spec.lua:314` — Kind: `clarity/consistency`
> "REVIEW/clarity/consistency: 'avoid *sink*, use *text widget* instead'?"
- Comments-on: "defaults + hidden sink" section banner (lines 316-317)
- Bucket: **TRIAGE**
- Rationale: subordinate to RVW-033 → TRIAGE
- Disposition: —

**RVW-064** `tests/input/input_events_spec.lua:315` — Kind: `cosmetic`
> "REVIEW/cosmetic: extra '---' right below this line and after"
- Comments-on: same banner as RVW-063 (the `---- … -------` decoration on lines 316-317)
- Bucket: **DISSOLVE?**
- Rationale: checked — this dash-bracketed section-divider style is used consistently throughout the file for every subsection banner (compare lines 66, 157-158, 216-217, 351-352, 394-395, 484-486); it is the file's deliberate house style, not a stray/accidental artifact → DISSOLVE?
- Disposition: —

**RVW-065** `tests/input/input_events_spec.lua:320` — Kind: `fidelity/consistency`
> "REVIEW/fidelity/consistency: test against all non-defined participants? (both handler and hook -- disabled altogether or one-by-one -- I think already described somewhere above... symmetry feels off there"
- Comments-on: `describe('defaults and the hidden sink', ...)` group
- Bucket: **TRIAGE**
- Rationale: coverage-matrix question, self-admittedly uncertain ("I think already described somewhere above") → TRIAGE
- Disposition: —

**RVW-066** `tests/input/input_events_spec.lua:322` — Kind: `clarity/terminology`
> "REVIEW/clarity/terminology: current suggested alternative to 'generic callback' is 'hook'/'project hook'"
- Comments-on: `it('the default callback neither edits nor consumes', ...)` doc
- Bucket: **TRIAGE**
- Rationale: subordinate to RVW-033 → TRIAGE
- Disposition: —

**RVW-067** `tests/input/input_events_spec.lua:328` — Kind: `clarity`
> "REVIEW/clarity: 'default callback(hook) does (not) smth' is implementation details, behavioural manifestation is 'when no hook configured...'"
- Comments-on: same test as RVW-066
- Bucket: **TRIAGE**
- Rationale: `it`-description framing call → TRIAGE
- Disposition: —

**RVW-068** `tests/input/input_events_spec.lua:337` — Kind: `cosmetic`
> "REVIEW/cosmetic: prose below is a bit unnatural (content fine, grammar crippled)"
- Comments-on: `it('no participant + hidden widget mutates nothing', ...)` doc (lines 338-340)
- Bucket: **TRIAGE**
- Rationale: grammar fix ask; content is agreed fine per the marker itself, so this is close to trivial, but rewriting prose is still an edit an owner should confirm the phrasing of → TRIAGE
- Disposition: —

**RVW-069** `tests/input/input_events_spec.lua:354` — Kind: `terminology`
> "REVIEW/terminology: now we can simply call it 'hooks' (\"describe: hook\" -> describe(\"on_text_input\") -> it(\"fires per character\"))"
- Comments-on: `describe('tier-3: the on_* generic callback', ...)`
- Bucket: **TRIAGE**
- Rationale: subordinate to RVW-033, with a concrete rename proposal → TRIAGE
- Disposition: —

**RVW-070** `tests/input/input_events_spec.lua:357` — Kind: `fidelity/consistency`
> "REVIEW/fidelity/consistency: only 'on_text_input' hook is tested, what about 'on_key_pressed'?"
- Comments-on: `it('on_text_input fires per character as text arrives', ...)`
- Bucket: **TRIAGE**
- Rationale: coverage-gap question re symmetric `on_key_pressed` case → TRIAGE
- Disposition: —

**RVW-071** `tests/input/input_events_spec.lua:382` — Kind: `clarity/suggestion`
> "REVIEW/clarity/suggestion: what if we redesign API syntax in this part and decide its not 'input.on_*' but input.hooks.{textinput,keypressed,keyreleased,mousewheel} -- with same logic just different configuration syntax/arch"
- Comments-on: `it('a truthy on_text_input intercepts; falsey reaches sink', ...)`
- Bucket: **TRIAGE**
- Rationale: public-API redesign proposal — significant architecture call → TRIAGE
- Disposition: —

**RVW-072** `tests/input/input_events_spec.lua:385` — Kind: `fidelity`
> "REVIEW/fidelity: why would we check sigleton internals instead of compy.input. method ? (official behaviour)"
- Comments-on: `assert.is_true(F.singleton:is_empty())`, same test as RVW-071
- Bucket: **TRIAGE**
- Rationale: same "test the public surface, not internals" family as RVW-060/072 → TRIAGE
- Disposition: —

**RVW-073** `tests/input/input_events_spec.lua:393` — Kind: `clarity/jargon`
> "REVIEW/clarity/jargon: rename? (according to new vocabulary the describe below would be something like \"hooks: installation via sandboxed love.* handlers/slots\" (in this context 'slots' may be tolerable?) suggestions are welcome. Word 'native' is certainly misleading and should be removed from all declarations in the group."
- Comments-on: `describe('tier-3: the native install path', ...)`
- Bucket: **TRIAGE**
- Rationale: subordinate to RVW-033, with a concrete rename ("native" -> ...) → TRIAGE
- Disposition: —

**RVW-074** `tests/input/input_events_spec.lua:402` — Kind: `consistency`
> "REVIEW/consistency: any hook not only promoted 'native' should fire regardless of widget status (and widget absence can have two forms: never was 'shown', or was 'shown than hidden')"
- Comments-on: `it('a native fires whether or not the widget is shown', ...)`
- Bucket: **TRIAGE**
- Rationale: behavioural-symmetry/coverage question across hook kinds and widget states → TRIAGE
- Disposition: —

**RVW-075** `tests/input/input_events_spec.lua:403` — Kind: `clarity`
> "REVIEW/clarity: make it clear that 'native' always behaves like hook -- so the match in behaviour is not occasional. Maybe reuse shared tests suite (if busted supports it)"
- Comments-on: same test as RVW-074
- Bucket: **TRIAGE**
- Rationale: proposes shared-suite reuse across "native" and "hook" tests — structural change → TRIAGE
- Disposition: —

**RVW-076** `tests/input/input_events_spec.lua:443` — Kind: `clarity`
> "REVIEW/clarity: unite with the first test in this group, and remove references from 'downstream bucket D' from the prose. We simply test that hook fires whether widget is shown or hidden or never shown. Its a wortful test which would normally belong to both variants (hook installed via input API, and hook installed from legacy sandboxed love.* equivalent). See remark abouve about reusing tests group. Amd once again -- the test itself is worthful, and belongs to dispatching chain. The reason: it checks that downstream dispatching chain members (or just last one -- widget) do not block upstream consumption"
- Comments-on: `it('a native keyreleased fires while the widget is shown', ...)`
- Bucket: **TRIAGE**
- Rationale: merge/restructure proposal, references RVW-075's shared-suite idea → TRIAGE
- Disposition: —

**RVW-077** `tests/input/input_events_spec.lua:462` — Kind: `clarity`
> "REVIEW/clarity: update prose and declaration and variable names to new vocabulary"
- Comments-on: `it('an explicit on_* takes precedence over the native', ...)` doc (lines 463-468)
- Bucket: **TRIAGE**
- Rationale: subordinate to RVW-033 → TRIAGE
- Disposition: —

**RVW-078** `tests/input/input_events_spec.lua:473` — Kind: `fidelity/consistency`
> "REVIEW/fidelity/consistency: is 'activate_project' installing hooks via legacy path? (as love.*) are other tests (in the beginning of this suite) also testing this path and theerfore NOT testing input.on_ path (explicit hook configuration). What do we do with it?"
- Comments-on: `local input = F.activate_project({ keypressed = bump })`, same test as RVW-077
- Bucket: **TRIAGE**
- Rationale: raises a genuine potential coverage confound (legacy-path vs `on_*`-path tests) that needs an actual suite-wide audit → TRIAGE
- Disposition: —

**RVW-079** `tests/input/input_events_spec.lua:483` — Kind: `consistency/architecture`
> "REVIEW/consistency/architecture: if we decide to pivot from .on_{event} to .hooks[event] the whole test should not be needed at all"
- Comments-on: `describe('the mutable/immutable boundary', ...)`
- Bucket: **TRIAGE**
- Rationale: contingent on the API-redesign proposal at RVW-071 — architecture call → TRIAGE
- Disposition: —

---

## `tests/input/input_nfr_forward_spec.lua` (10)

**RVW-080** `tests/input/input_nfr_forward_spec.lua:1` — Kind: `clarity`
> "REVIEW/clarity: remove historical reference to once-monolithic spec."
- Comments-on: file header ("NFR guards and forward contracts — split from input_contracts_spec.lua (TF1)", lines 3-4)
- Bucket: **TRIAGE**
- Rationale: cosmetic-leaning but a content edit (removing a provenance note) — same family as RVW-026; owner call whether provenance notes stay → TRIAGE
- Disposition: —

**RVW-081** `tests/input/input_nfr_forward_spec.lua:8` — Kind: `clarity/vocabulary`
> "REVIEW/clarity/vocabulary: see alternative suggestion in input_events_spec.lua"
- Comments-on: file header vocabulary paragraph (lines 10-15)
- Bucket: **TRIAGE**
- Rationale: explicitly points at RVW-033 (the master vocabulary proposal) → TRIAGE
- Disposition: —

**RVW-082** `tests/input/input_nfr_forward_spec.lua:17` — Kind: `clarity`
> "REVIEW/clarity: the prose below is a bit mumbling, needs rewrite into more consistent human language"
- Comments-on: "Provisional today-facts expected to change…" paragraph (lines 18-20)
- Bucket: **TRIAGE**
- Rationale: rewrite ask → TRIAGE
- Disposition: —

**RVW-083** `tests/input/input_nfr_forward_spec.lua:24` — Kind: `clarity`
> "REVIEW/clarity: 'forward' means what? lots of prose in this group are outdated (including REVIEW remarks)"
- Comments-on: `describe('input contracts: NFR and forward #input', ...)`
- Bucket: **TRIAGE**
- Rationale: terminology question plus a claim that some REVIEW remarks in-group are themselves outdated — needs a targeted pass to identify which, not done here → TRIAGE
- Disposition: —

**RVW-084** `tests/input/input_nfr_forward_spec.lua:25` — Kind: `consistence`
> "REVIEW/consistence: group 'expected to change' actually describes *behaviour* that precedes the tests (so is taken as de-facto standard to keep -- probably could be referenced from decision docs), and should be renamed accordingly"
- Comments-on: same `describe` as RVW-083
- Bucket: **TRIAGE**
- Rationale: rename + potential promotion of "provisional" facts into `decisions/input.md` — real design call → TRIAGE
- Disposition: —

**RVW-085** `tests/input/input_nfr_forward_spec.lua:52` — Kind: `DOC`
> "REVIEW/DOC: its no more 'expected to change', going to be correct invariant/contract? maybe moved out of 'provisional'?"
- Comments-on: `it('inspect: the console owns the surface', ...)`
- Bucket: **TRIAGE**
- Rationale: same "promote to a stable contract" question as RVW-084, applied to a specific test — needs an owner ruling per the doc's own "OWNER RULING PENDING" note at lines 44-45 → TRIAGE
- Disposition: —

**RVW-086** `tests/input/input_nfr_forward_spec.lua:70` — Kind: `fidelity`
> "REVIEW/fidelity: why check session.handlers? any other space?"
- Comments-on: `it('wheel has no framework gateway entry', ...)`
- Bucket: **TRIAGE**
- Rationale: test-fidelity question re what surface is being asserted on → TRIAGE
- Disposition: —

**RVW-087** `tests/input/input_nfr_forward_spec.lua:103` — Kind: `plain`
> "REVIEW: when we come to testing *propagation* of keypressed into consumers, we will need to ensure its the same table -- OR replace this implementation test with end-to-end test ensuring that what was pressed (all keys held) is what is received at consumer"
- Comments-on: `it('the pressed key is in the held set', ...)`
- Bucket: **TRIAGE**
- Rationale: forward-looking test-design note, explicitly deferred by the marker itself to a future propagation-testing pass → TRIAGE
- Disposition: —

**RVW-088** `tests/input/input_nfr_forward_spec.lua:134` — Kind: `plain`
> "REVIEW: why not set 'ctrl' as pressed too? Much cheaper, no?"
- Comments-on: `it('left/right names stay raw in the held set', ...)`
- Bucket: **TRIAGE**
- Rationale: test-cost/design tradeoff question → TRIAGE
- Disposition: —

**RVW-089** `tests/input/input_nfr_forward_spec.lua:151` — Kind: `plain`
> "REVIEW: do we have pending tests outlined for future consideration?"
- Comments-on: `it('the widget keeps identity across cycles', ...)`
- Bucket: **TRIAGE**
- Rationale: checked — `tests/input/input_routing_spec.lua` has four `pending(...)` rows (lines 81, 145, 158, 224) that plausibly answer "yes"; not cross-confirmed as the specific set the marker means, so left for owner to point to → TRIAGE
- Disposition: —

---

## `tests/input/input_routing_spec.lua` (11)

**RVW-090** `tests/input/input_routing_spec.lua:18-19` — Kind: `DOC` *(multi-line marker)*
> "REVIEW/DOC: all comments point to canonical docs, never the feature's ephemeral working tree"
- Comments-on: "SUITE-LEVEL REVIEW NOTES" preamble (carried from the pre-split `input_contracts_spec.lua`, lines 13-17)
- Bucket: **TRIAGE**
- Rationale: checked — the rule is NOT universally honored: `src/controller/consoleController.lua:511` and `src/controller/userInputController.lua:8` both cite `doc/development/wip/77-new-input-api/validation/...` (ephemeral wip paths) in comments, so the concern is live, not moot → TRIAGE
- Disposition: —

**RVW-091** `tests/input/input_routing_spec.lua:20` — Kind: `DOC`
> "REVIEW/DOC: referencing items as 'paragraph X' is insufficient and unreadable -- should reference specific named sections so they are discoverable/greppable in their doc"
- Comments-on: same suite-level preamble as RVW-090
- Bucket: **TRIAGE**
- Rationale: doc-citation-style rule; owner call → TRIAGE
- Disposition: —

**RVW-092** `tests/input/input_routing_spec.lua:21` — Kind: `DOC`
> "REVIEW/DOC: fix spec references EVERYWHERE IN THE FILE (I will wrap them into {badspecref:} wherever I see them"
- Comments-on: same preamble; explains the `{badspecref: ...}` tags seen elsewhere in the suite (e.g. `input_routing_spec.lua:88,131,151`)
- Bucket: **TRIAGE**
- Rationale: an in-progress self-assigned action, not yet complete across the corpus — owner-tracked, not dissolvable by inspection → TRIAGE
- Disposition: —

**RVW-093** `tests/input/input_routing_spec.lua:22` — Kind: `DOC`
> "REVIEW/DOC: also I will wrap with {jargon:...} the words or phrases which seem invented"
- Comments-on: same preamble; explains the `{jargon: ...}` tags seen elsewhere (e.g. `input_events_spec.lua:36,39,107`)
- Bucket: **TRIAGE**
- Rationale: same self-assigned, in-progress tagging convention as RVW-092 → TRIAGE
- Disposition: —

**RVW-094** `tests/input/input_routing_spec.lua:23` — Kind: `plain`
> "REVIEW: maybe A/B/C/D buckets can be dissolved today as they are less important today when feature is supposedly implemented. Simply marking tests as 'since 1.0.0...' (or 'changed in 1.0.0...') for new/altered behaviour would be enough."
- Comments-on: same preamble; the A/B/C/D bucket convention used across `input_routing_spec.lua`, `input_nfr_forward_spec.lua`, `input_events_spec.lua`
- Bucket: **TRIAGE**
- Rationale: suite-wide organizational-scheme change — significant, cross-file → TRIAGE
- Disposition: —

**RVW-095** `tests/input/input_routing_spec.lua:24` — Kind: `plain`
> "REVIEW: using tags in groups would also be great but I will inject some myself"
- Comments-on: same preamble
- Bucket: **TRIAGE**
- Rationale: self-assigned, in-progress (busted `#tags`) — owner-tracked → TRIAGE
- Disposition: —

**RVW-096** `tests/input/input_routing_spec.lua:25` — Kind: `plain`
> "REVIEW: would it be worth splitting the 2K+ LoC into several test suites, for easier inspection?"
- Comments-on: same preamble
- Bucket: **TRIAGE**
- Rationale: checked — this already happened for `input_events_spec.lua`/`input_cursor_text_spec.lua`/`input_routing_spec.lua`/`input_widget_lifecycle_spec.lua` (all four carry "split from input_contracts_spec.lua (TF1)" notes), so the split IS underway; whether it's complete/sufficient is still an owner call → TRIAGE
- Disposition: —

**RVW-097** `tests/input/input_routing_spec.lua:60` — Kind: `nitpick`
> "REVIEW/nitpick: we can have function kind of F.console_with('ab') to distinguish between test context setup (tests-specific method, explicitly aliased in fixture) and actions under test (called as in real code)"
- Comments-on: `F.console:add_text('ab')` in `it('routes keys to the console', ...)`
- Bucket: **TRIAGE**
- Rationale: fixture-helper proposal (`F.console_with`), same family as the "call real framework code" cluster in `input_fixture.lua` (RVW-006/009/012-016) → TRIAGE
- Disposition: —

**RVW-098** `tests/input/input_routing_spec.lua:137` — Kind: `plain`
> "REVIEW: why not add the test then?"
- Comments-on: the "keyreleased under editor" gap note (lines 130-136, "no suite row is owed under {badspecref: this feature}")
- Bucket: **TRIAGE**
- Rationale: coverage-gap question, contests the adjacent "no row owed" rationale → TRIAGE
- Disposition: —

**RVW-099** `tests/input/input_routing_spec.lua:144` — Kind: `plain`
> "REVIEW: why not implement?"
- Comments-on: `pending('routes the pointer to the editor')` (line 145)
- Bucket: **TRIAGE**
- Rationale: same "why pending, not implemented" question as RVW-098, applied to a `pending()` row — coverage-gap call → TRIAGE
- Disposition: —

**RVW-100** `tests/input/input_routing_spec.lua:148` — Kind: `plain`
> "REVIEW: and why not test it, is it complex? Spec is not called 'feature_77_spec.lua' so not being included in blast radius is a weak excuse for incompleteness (if test could be filled easily)"
- Comments-on: the Search-widget gap note (lines 149-159, "absent from the design corpus")
- Bucket: **TRIAGE**
- Rationale: coverage-gap question, same family as RVW-098/099 → TRIAGE
- Disposition: —

---

## `tests/input/input_shortcuts_click_spec.lua` (4)

**RVW-101** `tests/input/input_shortcuts_click_spec.lua:31` — Kind: `plain`
> "REVIEW: both cases need reconsideration/refinement later, they look plausible in spirit but they do not demonstrate which exact production scenario is tested, and mastering framework state via low-level configuration flags is suspicious (if we mock the real production path like project run, it should be explicit, not imitated)"
- Comments-on: `describe('global shortcuts do not consume the key (#disputable))', ...)` group
- Bucket: **TRIAGE**
- Rationale: test-fidelity concern, group already self-tagged `#disputable` — owner already flagged this as open → TRIAGE
- Disposition: —

**RVW-102** `tests/input/input_shortcuts_click_spec.lua:39` — Kind: `plain`
> "REVIEW: is it how in real scenarios handlers are altered?"
- Comments-on: `love.keypressed = function(k) n = n + 1; orig(k) end` (manual monkeypatch)
- Bucket: **TRIAGE**
- Rationale: same "call real framework code, not a hand-rolled patch" family as the `input_fixture.lua` cluster → TRIAGE
- Disposition: —

**RVW-103** `tests/input/input_shortcuts_click_spec.lua:59` — Kind: `plain`
> "REVIEW: suspiciously big amount of lower-level 'magic' manipulations -- should not test execute a few real framework methods instead and check their results?"
- Comments-on: `it('#play mode narrows the active shortcut set', ...)`
- Bucket: **TRIAGE**
- Rationale: same family as RVW-102 → TRIAGE
- Disposition: —

**RVW-104** `tests/input/input_shortcuts_click_spec.lua:96` — Kind: `plain`
> "REVIEW: why not setup via 'running_project'? unification is good. or it does not work with mouse events?"
- Comments-on: `it('a single click confirms after the window', ...)`
- Bucket: **TRIAGE**
- Rationale: asks whether `F.running_project` (itself the subject of RVW-007) could unify this setup — needs checking whether `running_project` supports mouse events, not verified here → TRIAGE
- Disposition: —

---

## `tests/input/input_widget_lifecycle_spec.lua` (10)

**RVW-105** `tests/input/input_widget_lifecycle_spec.lua:27` — Kind: `plain`
> "REVIEW: this helper serves one case which must be displaced"
- Comments-on: `local function make_editor_session()`
- Bucket: **TRIAGE**
- Rationale: checked — `make_editor_session` is indeed called from exactly one place (line 180, the block-nav test) confirming the "one case" claim; but *where* to relocate it is a structural call the owner listed explicitly as pending at lines 160-170 ("relocate to tests/editor/... is the human's call") → TRIAGE
- Disposition: —

**RVW-106** `tests/input/input_widget_lifecycle_spec.lua:50` — Kind: `plain`
> "REVIEW: TODO: need to test prompt-labelling and relabelling"
- Comments-on: `describe('widget activation and reset', ...)` group
- Bucket: **TRIAGE**
- Rationale: explicit coverage-gap TODO → TRIAGE
- Disposition: —

**RVW-107** `tests/input/input_widget_lifecycle_spec.lua:106` — Kind: `DOC`
> "REVIEW/DOC: I believe that design rule is that after hide widget stops consuming whatever comes to it -- concern-under-test is valid, prose description is misorienting. MAYBE (check towards design) deactivated widget simply means if events fall through they are ignored. I am not sure that console consuming typed characters while not being shown is the valid or desired scenario!"
- Comments-on: `it('hide deactivates the widget', ...)`
- Bucket: **TRIAGE**
- Rationale: raises the same "should console silently consume input while widget hidden" design question later developed in depth at RVW-111/112 — needs `decisions/input.md`/`internals/user_input.md` cross-check, not conclusively resolved by either doc per the marker's own uncertainty → TRIAGE
- Disposition: —

**RVW-108** `tests/input/input_widget_lifecycle_spec.lua:128` — Kind: `plain`
> "REVIEW: whenever we migrate console to new API, we may stop silent consuming of input (to be confirmed yet) -- therefore assertions checking the console as hidden sink will break and will have to be updated (see also one of previous remarks not so far before)"
- Comments-on: `describe('a hidden widget does not consume', ...)` group
- Bucket: **TRIAGE**
- Rationale: forward-looking migration note, explicitly "to be confirmed yet" by the marker itself → TRIAGE
- Disposition: —

**RVW-109** `tests/input/input_widget_lifecycle_spec.lua:129` — Kind: `plain`
> "REVIEW: this test case is literally a sibling of previous one, the only difference is that two modes are preserved ('keep' vs no-keep). So the two should be better named/grouped. Not sure if we can just test the widget state (e.g. typing+enter do *not* delivering on_text_entered while widget is hidden; and the re-delegation to console is a separate *disputable* concern that should be asserted separately (if not discarded)"
- Comments-on: same `describe` as RVW-108
- Bucket: **TRIAGE**
- Rationale: restructure/rename proposal for the two sibling tests → TRIAGE
- Disposition: —

**RVW-110** `tests/input/input_widget_lifecycle_spec.lua:142` — Kind: `plain`
> "REVIEW: remark below is historical (from previous passes, it addresses same problem as substantial remarks on two previous cases)"
- Comments-on: self-referential meta-note pointing at RVW-111 (line 143)
- Bucket: **TRIAGE**
- Rationale: the marker itself flags RVW-111 as possibly redundant with RVW-108/109, but RVW-111's actual content (console-eval-danger question) goes further than either — a straight "duplicate, drop" call isn't safe without the owner confirming the overlap → TRIAGE
- Disposition: —

**RVW-111** `tests/input/input_widget_lifecycle_spec.lua:143` — Kind: `plain`
> "REVIEW: now I am concerned about the very concept. Was it in place before? (that console absorbs any interaction when project is active but widget is hidden) How it correlates with common logic? Will it mean somewhere in the console random keystrokes are accumulating? What for? User even does not see the console if project is running -- will it see a garbage on 'inspect'? what is user occasionally types some destructive or ambiguous command while project is running -- will console evaluate/execute it? if so, its dangerous and strange; if not, there's no point in routing input to console. MY UNDERSTANDING IS: if \"project/editor\" is active -- its an active route -- events travel down through it. Whether they end up in user_widget (shown) or in noop (if widget is hidden), or intercepted by project combos/handlers and interpreted other way -- is totally the responsibility of the route (e.g. project input controller or editor controlle or console controller). Is this logic reasonable?"
- Comments-on: `it('a key while hidden does not mutate it', ...)`
- Bucket: **TRIAGE**
- Rationale: a genuine, substantial design/safety question (does hidden console silently evaluate keystrokes?) — needs a real answer from `decisions/input.md`/`internals/user_input.md` and/or the owner, not resolvable by grep → TRIAGE. Flagged as the most significant single marker in this file.
- Disposition: —

**RVW-112** `tests/input/input_widget_lifecycle_spec.lua:144` — Kind: `plain`
> "REVIEW: once again -- the very concept of console secretly and meaningfully processing user input while not being on the screen looks weird to me."
- Comments-on: same test as RVW-111
- Bucket: **TRIAGE**
- Rationale: restates/reinforces RVW-111 — same open question, not a separate concern → TRIAGE
- Disposition: —

**RVW-113** `tests/input/input_widget_lifecycle_spec.lua:160` — Kind: `plain`
> "REVIEW: this test in this form should be relocated under tests/editor. Input contract should test delivery *and only if editor really relies on it* (situation where editor *may* not rely on it: just counting keystrokes itself and translating them into files' coordinates with every move -- therefore block-nav is triggered not by event emitted by input widget, but by the mere fact that internal navigation map says the cursor in 'project space' is no more inside current selection lines)"
- Comments-on: `describe('#editor block navigation at the limit', ...)` group
- Bucket: **TRIAGE**
- Rationale: relocate suggestion — the file's own adjacent "OPEN" note (lines 161-170) explicitly says disposition "is the human's call" → TRIAGE (textbook relocate-suggestion example)
- Disposition: —

**RVW-114** `tests/input/input_widget_lifecycle_spec.lua:171` — Kind: `RESPONSE`
> "REVIEW/RESPONSE: (check preceding REVIEW/OPEN lines) editor behaviour test clearly does not belong here. here we should just check that the relevant behavior is triggered by native keys events (and for key-level tests we have separate editor helper -- half of editor suite uses it and we should too. Here we can just reference new test disposition in the COMMENT. Or test at boundary (keystroke/invokation)"
- Comments-on: same OPEN note / group as RVW-113 — this is the owner's own follow-up answer to it
- Bucket: **TRIAGE**
- Rationale: reads as the owner's provisional resolution of RVW-113, but is itself phrased as still-open ("we should just check…", "Or test at boundary…" — two options offered, no final pick) → not dissolvable without the owner picking one; TRIAGE
- Disposition: —

---

## `src/controller/controller.lua` (7)

**RVW-115** `src/controller/controller.lua:27` — Kind: `plain`
> "REVIEW: why separate function for every forwarder, not generic one, with event name as payload?"
- Comments-on: `forward_keypressed` / `forward_textinput` / `forward_keyreleased` (lines 41-64)
- Bucket: **TRIAGE**
- Rationale: architecture proposal (generic forwarder) → TRIAGE
- Disposition: —

**RVW-116** `src/controller/controller.lua:28` — Kind: `plain`
> "REVIEW: why explicit work with ui.c instead of something like get_user_input().handle(event_name,k,held_keys,is_r) ?"
- Comments-on: same forwarders as RVW-115
- Bucket: **TRIAGE**
- Rationale: companion architecture proposal (uniform `.handle(...)` API on the widget) → TRIAGE
- Disposition: —

**RVW-117** `src/controller/controller.lua:29` — Kind: `plain`
> "REVIEW: why returning strict 'true' instead of returning whatever handler returns?"
- Comments-on: same forwarders as RVW-115/116 (`return true` in each)
- Bucket: **TRIAGE**
- Rationale: return-value semantics question — changing this affects the dispatch chain's "truthy consumes" contract (`doc/development/decisions/input.md`, Decision 2), needs owner sign-off → TRIAGE
- Disposition: —

**RVW-118** `src/controller/controller.lua:145` — Kind: `plain`
> "REVIEW: `key` is ambiguous -- use 'handlername' or whatever semantically meaningful?"
- Comments-on: `local function wrapped_native(userlove, CC, key)` param
- Bucket: **TRIAGE**
- Rationale: naming call, same family as the `gate`/`deliver`/`req` naming markers in the controller layer → TRIAGE
- Disposition: —

**RVW-119** `src/controller/controller.lua:372` — Kind: `plain`
> "REVIEW: from engineering perspective it would be more interesting to unwrap 'serialized' combo definitions (defined by project) into a chain of functions built-in-place, that would be applied to every keypress. building functions once per project load -- looks clear than building tables on every keypress (NOT TO IMPLEMENT NOW: put into tech debt ledger as suggestion)"
- Comments-on: `local function combo_string(k, keys_pressed)`
- Bucket: **TRIAGE**
- Rationale: checked `doc/development/technical_debt/input.md` — it has a "Combo-string dispatch allocates a table per call" entry covering the per-keystroke allocation cost, but NOT this marker's specific chain-of-functions-built-once alternative; the marker's own self-assigned action ("put into tech debt ledger") is not yet done → TRIAGE
- Disposition: —

**RVW-120** `src/controller/controller.lua:450-452` — Kind: `plain` *(multi-line marker)*
> "REVIEW: consider alternative combo-table mechanism (table on initialization used to build a chain of checkers)"
- Comments-on: `keypressed(k, _, isr)` inside `Controller.set_love_keypressed`, the debug-hotkey if-blocks below it
- Bucket: **TRIAGE**
- Rationale: same combo-table-mechanism family as RVW-119, applied to the debug-hotkey path; the adjacent `TODO(debt)` comment (line 453) already tracks migrating these hotkeys onto the combo-table mechanism (`technical_debt/input.md`, "Console debug hotkeys are ad-hoc") but not this specific alternative-mechanism idea → TRIAGE
- Disposition: —

**RVW-121** `src/controller/controller.lua:875` — Kind: `plain`
> "REVIEW: what is 'sc' ? meaningless name"
- Comments-on: `handlers.keypressed = function(k, sc, isr)` inside `setup_callback_handlers`
- Bucket: **DISSOLVE?**
- Rationale: `sc` is LÖVE's standard `scancode` parameter from `love.keypressed(key, scancode, isrepeat)`; confirmed by reading the full function body (lines 875-935+) that `sc` is never referenced after the parameter list — dispatch matches on `k` (the key name), not scancode. Fully answers "what is it" and "why unused" without owner judgment → DISSOLVE? (a rename to `_sc`/`scancode` is a trivial cosmetic follow-up, not a design question)
- Disposition: —

---

## `src/controller/projectInputController.lua` (3)

**RVW-122** `src/controller/projectInputController.lua:4` — Kind: `DOC`
> "REVIEW/DOC: can we reconsider 'slots' as a primary term? Could it be 'event slot' or 'event handler slot' or something similar? Ideally I want a concise and unambiguous term. \"Slot\" is a bit vague as it requires understanding the context"
- Comments-on: file-header doc block (lines 5-24) describing `ProjectInputController` as "occupant of the keyboard/text slots"
- Bucket: **TRIAGE**
- Rationale: subordinate to the master vocabulary proposal RVW-033 ("slot" appears throughout the dispatch-chain vocabulary) → TRIAGE
- Disposition: —

**RVW-123** `src/controller/projectInputController.lua:139` — Kind: `plain`
> "REVIEW: what is 'sc' and why its not used?"
- Comments-on: `function ProjectInputController:keypressed(k, sc, isr)`
- Bucket: **DISSOLVE?**
- Rationale: same as RVW-121 — `sc` is LÖVE's `scancode` param; confirmed unused in the body (`return self:_dispatch('keypressed', k, k, Controller.held_keys(), isr)` passes only `k`/`isr`) → DISSOLVE?
- Disposition: —

**RVW-124** `src/controller/projectInputController.lua:140` — Kind: `plain`
> "REVIEW: duplicaion of 'k,k' and 't,t' looks smelly -- why is it needed. in additon, _dispatch grabs keys_pressed itself(should not) and how other arguments are consumed its not very easy to understand."
- Comments-on: same method as RVW-123, and `textinput(t)` below it
- Bucket: **TRIAGE**
- Rationale: real API-shape/readability concern about `_dispatch`'s argument duplication and implicit `Controller.held_keys()` grab — architecture call → TRIAGE
- Disposition: —

---

## `src/controller/userInputController.lua` (6)

**RVW-125** `src/controller/userInputController.lua:399` — Kind: `plain`
> "REVIEW: why function name is 'gate'(noun) and not 'validate'(action)?"
- Comments-on: `local function gate(model, validator, text)`
- Bucket: **TRIAGE**
- Rationale: code at `userInputController.lua:399` still names `gate`; naming question stands → TRIAGE
- Disposition: —

**RVW-126** `src/controller/userInputController.lua:408` — Kind: `nitpick`
> "REVIEW/nitpick: noop_debug would be better semantically (primary action first, side-effect second). Also using it as factory would be even more elegant (therefore 'noop_debug()' would produce earmarked 'noop' that could be invoked transparently)"
- Comments-on: `local function debug_noop(label)`
- Bucket: **TRIAGE**
- Rationale: naming + a factory-pattern refactor proposal, referenced again by RVW-128 → TRIAGE
- Disposition: —

**RVW-127** `src/controller/userInputController.lua:421` — Kind: `plain`
> "REVIEW: is this legacy reftable even read anywhere now?"
- Comments-on: `local res = self.result` inside `deliver(self, text)`
- Bucket: **DISSOLVE?**
- Rationale: checked all 7 `UserInputController(...)` construction sites (`src/main.lua:375`, `src/controller/editorController.lua:12,16`, `src/controller/consoleController.lua:44`, `tests/input/input_lifecycle_unfork_spec.lua:27`, `tests/input/user_input_view_spec.lua:25`, `tests/helpers/input_fixture.lua:117,253`) — every one passes `nil`/omits the `result` positional param, so `self.result` is always `nil` in current code; the inline doc at lines 251-254 confirms it as "Legacy poll idiom; superseded by the callback API — Decision 4." The reftable is dead → DISSOLVE?
- Disposition: —

**RVW-128** `src/controller/userInputController.lua:422` — Kind: `plain`
> "REVIEW: if 'noop_debug' would be a factory, we could just install its result (with label enclosed) as default value for self.on_text_entered (unless overwritten) therefore collapsing all this wrapper, wiring on_text_entered directly without 'deliver' wrapper"
- Comments-on: `deliver(self, text)` wrapper, building on RVW-126's factory proposal
- Bucket: **TRIAGE**
- Rationale: concrete refactor proposal collapsing `deliver`/`debug_noop` — architecture call → TRIAGE
- Disposition: —

**RVW-129** `src/controller/userInputController.lua:423` — Kind: `plain`
> "REVIEW: `deliver` is vague name -- must be deliver_text_entered or something like that ? (one more symptom of it being redundant wrapper)"
- Comments-on: same `deliver(self, text)` function
- Bucket: **TRIAGE**
- Rationale: naming call, tied to the RVW-127/128 "is this wrapper even needed" cluster → TRIAGE
- Disposition: —

**RVW-130** `src/controller/userInputController.lua:791` — Kind: `plain`
> "REVIEW: why this wrap with immediate call? Cannot we just call the function body with same effect without wrapping? ah... its just following the convention for combos handling"
- Comments-on: `local function selection() ... end; selection()` inside the keypressed handler
- Bucket: **TRIAGE**
- Rationale: the marker self-answers ("ah... its just following the convention") but leaves open whether that convention should still apply here — plausible near-DISSOLVE, but the marker itself doesn't commit to an answer, so left for owner confirmation → TRIAGE
- Disposition: —

---

## `src/model/input/userInputModel.lua` (5)

**RVW-131** `src/model/input/userInputModel.lua:411` — Kind: `plain`
> "REVIEW: when widget is re-armed, or cancelled or closed-on-submit, history is dropped? what about when its reconfigured? when one project launches input, than is torn down and new project launches input"
- Comments-on: `function UserInputModel:keep_history()`
- Bucket: **TRIAGE**
- Rationale: genuine lifecycle-coverage question across re-arm/cancel/reconfigure/project-switch; the adjacent doc (lines 413-419) explains oneshot's removal but doesn't address history-drop timing directly → TRIAGE
- Disposition: —

**RVW-132** `src/model/input/userInputModel.lua:601` — Kind: `plain`
> "REVIEW: 'req' name does not reflect semantics -- what is it at all?"
- Comments-on: `local req = (n == 1) and 'input' or (scope or 'input')` inside `is_at_limit`
- Bucket: **TRIAGE**
- Rationale: naming call, same family as `gate`/`sc`/`deliver` → TRIAGE
- Disposition: —

**RVW-133** `src/model/input/userInputModel.lua:840` — Kind: `plain`
> "REVIEW: previous one-shot logic also involved love.harmony.utils interaction -- what is it for and is it ok that its gone?"
- Comments-on: `function UserInputModel:_report_parse_error(result)`
- Bucket: **TRIAGE**
- Rationale: asks about a removed dependency (`love.harmony.utils`) with no reference found in current `src/` (not independently re-confirmed absent everywhere) — needs a targeted check plus historical/git context → TRIAGE
- Disposition: —

**RVW-134** `src/model/input/userInputModel.lua:841` — Kind: `plain`
> "REVIEW: report_parse_error is misleading name, should not be _move_cursor_to_err_pos ?"
- Comments-on: same method as RVW-133
- Bucket: **TRIAGE**
- Rationale: naming call → TRIAGE
- Disposition: —

**RVW-135** `src/model/input/userInputModel.lua:896` — Kind: `plain`
> "REVIEW: regarding all files(!) -> should comments vs annotations order be the same everywhere? I see comments between annotations, before, after... need normalization for readablitity as also because at least some type parsers may break?(not sure which ones we are using though)"
- Comments-on: file-wide LDoc-annotation-vs-comment ordering convention (sits between `handle()` and the error-handling section)
- Bucket: **TRIAGE**
- Rationale: cross-file style-normalization question with a possible tooling risk ("some type parsers may break") — needs a real audit of `--- @...` vs `--` ordering across the corpus, not done here → TRIAGE
- Disposition: —

---

## `src/util/key.lua` (2)

**RVW-136** `src/util/key.lua:70` — Kind: `plain`
> "REVIEW: can we think of building set of validators instead? it may be interesting because we'd only have to check for combos that are defined, not convert every typed combo into string on every keystroke. So that our table would *speak* the language of serialized combos but *act* as fast 'decision-tree' (and could return noop if nothing found, as a bonus -- saving the nil check upstream and allowing unconditional execution of returned handler)"
- Comments-on: `local function new_handler_table()`
- Bucket: **TRIAGE**
- Rationale: architecture proposal for combo dispatch, same family as RVW-119/120 (controller.lua combo-table alternatives) — worth linking together for a single owner ruling → TRIAGE
- Disposition: —

**RVW-137** `src/util/key.lua:122` — Kind: `plain`
> "REVIEW: would 'mod_folds' or 'mod_aliases' be better name than `mod_triples` ?"
- Comments-on: `Key = { mod_triples = mod_triples, ... }` table export
- Bucket: **TRIAGE**
- Rationale: naming call — `mod_triples` is also referenced from `src/controller/controller.lua:369` (`COMBO_MODS = Key.mod_triples`), so a rename touches two files → TRIAGE
- Disposition: —

---

## `src/view/input/userInputView.lua` (1)

**RVW-138** `src/view/input/userInputView.lua:297` — Kind: `plain`
> "REVIEW: need better explanation of the logic and justification for the decision -- why exactly redraw is skipped when controller is active? why widget identity is used as a check? will this check survive when/if we replug Console/Editor to the same widget?"
- Comments-on: `function UserInputView:draw()`, specifically `if self.controller ~= love.state.user_input_controller then self.controller:update_view() end`
- Bucket: **TRIAGE**
- Rationale: genuine design-durability question (does the identity check survive a future Console/Editor replug onto the same widget) — forward-looking architecture concern → TRIAGE
- Disposition: —

---

## Summary

### By bucket

| Bucket | Count |
|---|---|
| DISSOLVE? | 6 |
| TRIAGE | 132 |
| **Total** | **138** |

DISSOLVE? markers: RVW-010, RVW-045, RVW-064, RVW-121, RVW-123, RVW-127.

### By file

| File | Count | RVW range |
|---|---|---|
| `tests/helpers/input_fixture.lua` | 16 | RVW-001 – RVW-016 |
| `tests/input/highlight_shape_spec.lua` | 9 | RVW-017 – RVW-025 |
| `tests/input/input_cursor_text_spec.lua` | 6 | RVW-026 – RVW-031 |
| `tests/input/input_events_spec.lua` | 48 | RVW-032 – RVW-079 |
| `tests/input/input_nfr_forward_spec.lua` | 10 | RVW-080 – RVW-089 |
| `tests/input/input_routing_spec.lua` | 11 | RVW-090 – RVW-100 |
| `tests/input/input_shortcuts_click_spec.lua` | 4 | RVW-101 – RVW-104 |
| `tests/input/input_widget_lifecycle_spec.lua` | 10 | RVW-105 – RVW-114 |
| **tests/ subtotal** | **114** | |
| `src/controller/controller.lua` | 7 | RVW-115 – RVW-121 |
| `src/controller/projectInputController.lua` | 3 | RVW-122 – RVW-124 |
| `src/controller/userInputController.lua` | 6 | RVW-125 – RVW-130 |
| `src/model/input/userInputModel.lua` | 5 | RVW-131 – RVW-135 |
| `src/util/key.lua` | 2 | RVW-136 – RVW-137 |
| `src/view/input/userInputView.lua` | 1 | RVW-138 |
| **src/ subtotal** | **24** | |
| **Grand total** | **138** | |

### By kind (taxonomy suffix)

Tallied by exact taxonomy string on the marker (compounds counted once as
their full compound, not split per component); verified by
`grep -oP '(?<=— Kind: \`)[^\`]+' review-marker-inventory.md | sort | uniq -c`
against the file as written.

| Kind | Count |
|---|---|
| `plain` (bare `REVIEW:`) | 56 |
| `clarity` | 30 |
| `fidelity` | 13 |
| `DOC` | 13 |
| `fidelity/consistency` | 3 |
| `nitpick` | 2 |
| `cosmetic` | 2 |
| `consistency` (standalone) | 2 |
| `terminology` (standalone) | 1 |
| `quality` | 1 |
| `fidelity/consistence` | 1 |
| `consistency/architecture` | 1 |
| `consistence` (standalone) | 1 |
| `coherence` | 1 |
| `clarity/vocabulary` | 1 |
| `clarity/terminology` | 1 |
| `clarity/suggestion` | 1 |
| `clarity/sanity` | 1 |
| `clarity/jargon` | 1 |
| `clarity/fidelity` | 1 |
| `clarity/design/terminology` | 1 |
| `clarity/consistency/fidelity` | 1 |
| `clarity/consistency` | 1 |
| `clarity/consistence` | 1 |
| `RESPONSE` | 1 |
| **Total** | **138** |
