# S19 — tests/ REVIEW-marker triage plan (the carve)

Judgment carve of the **111 `tests/` TRIAGE markers** (all of RVW-001..114 except the
3 Batch-1 dissolvables RVW-010/045/064). Companion to the inventory
(`../notes/review-marker-inventory.md`) — the inventory has each marker's verbatim text,
Comments-on, and rationale; this doc adds the **judgment layer**: theme grouping, a
recommended disposition per marker, and the **dependency order** (rule the governing
decisions first — they collapse ~1/3 of the markers).

`src/` markers (RVW-115..138) are out of scope here — parked until the owner confirms the
`src/` expansion after `tests/` is swept.

## How to use this
1. **Rule the governing decisions first (§Governing).** Each disposes a whole cluster,
   so the walkthrough then only mops up what a governing ruling didn't settle. **Status
   (2026-07-21): the governing tier is CLEARED from this lane** — D1/D2/D5/D6 ruled+applied;
   **D4 deferred into TF2/TF3**; **D3 relocated to the collapse-gate ledger**
   (`../notes/collapsed-gate-ledger.md`). Next in-lane work is the mop-up batches (§Batches).
2. **Then walk the mop-up batches (§Batches), ≤10 markers each.** Each row carries a
   recommended disposition; the owner confirms/overrides; the runner applies (edit + inventory
   disposition + suite + commit) per batch.
3. **Parked set (§Owner-tracked)** is left alone — owner's own in-progress conventions.

Disposition vocabulary: **DROP** (remove marker; moot/answered/won't-do) · **REWORD** (edit the
comment/prose; owner gives phrasing or "your discretion") · **RENAME** (apply a vocab/symbol
rename; gated on a governing decision) · **RESTRUCT** (wrap-in-describe / merge / split) ·
**RELOC** (move test to another file) · **COV** (coverage call: add test / accept gap / mark
`pending`) · **PROMOTE** (lift a de-facto contract into `decisions/input.md`) · **DEFER**
(record as tech-debt / design-question, then drop marker) · **DECIDE** (genuine owner ruling,
no mechanical default) · **PARK** (owner-owned in-progress; leave).

---

## Governing decisions — rule these FIRST

### D1 — Test vocabulary (master **RVW-033**)
RVW-033 proposes a whole rename table: `singleton→widget`, `sink→widget/text-widget`,
`tier-3→[project] hook`, `generic callback→hook`, `framework handlers→…`, `.on_*→hooks[event]`,
`handlers` reserved for combo-bound, `callbacks` for trigger-called, `hooks` for
mid-chain-injected. **Governs:** RVW-028, 034 (route/sink both called "consumer"), 037, 052,
056, 059, 063, 066, 069, 073, 077, 081.
- **RULED 2026-07-21 (owner) — accept, implement now.** Ground-truth check reframed the split:
  the feared "production symbols" **do not exist in `src/` anymore** — `sink` and `tier-3` are
  gone entirely from production; `singleton` in `src/` is only the unrelated `Range.singleton`
  data API; production already calls the input widget `widget`. So there is **no `src/`-coupled
  rename to defer** for this vocab.
  - **D1a — apply now (prose + test-local symbol).** `singleton→widget`, `sink→widget`,
    `tier-3→[per-event] hook`, stale `on_*` narration → `hooks`, across test prose /
    describe-strings / comments. Rewrite the ROUTE/WIDGET/SINK definition block (RVW-034 overload).
  - **D1b — the ONE real code item is test-local:** the fixture symbol `F.singleton` /
    `build_singleton` / local `singleton` → `widget`. Coupled to **nothing** in `src/`
    (production is already `widget`; `F.singleton` mirrors main.lua's widget under a legacy name).
    Mechanical rename, tests-only — **not** gated on the `src/` sweep.
  - **`native` / `handlers` vocab is D4** — deliberately NOT touched in this sweep.
- **Implementation:** Pass A = `singleton→widget` code-symbol rename (delegated, mechanical).
  Pass B = vocab prose + DROP the 15 D1/D2 markers (RVW-033/028/034/037/052/056/059/063/066/069/
  073/077/081 + D2's 071/079). Both suite-green.

### D2 — Public-API shape `.on_*` → `.hooks[event]` (master **RVW-071**)
Whether the project-hook API is `input.on_textinput` or `input.hooks.textinput`.
**Governs:** RVW-079 (whole test unneeded if pivoted), RVW-069 (shares the rename).
- **RULED 2026-07-21 (owner) — ALREADY DONE; wipe + reword.** Evidence: the redesign RVW-071
  proposes is *already ratified, implemented, tested, documented*:
  - `decisions/input.md` ratifies the three-participant chain: `shortcuts[event][combo]` ·
    `hooks[event]` ("one per-event hook slot, absorbing the old per-event generic callback") ·
    the widget.
  - `src/` implements it: `HOOK_EVENTS = {keypressed,keyreleased,textinput}`, `input.hooks[ev]`,
    `compy.input.hooks[event]`. **No `input.on_*` public surface** anywhere.
  - The specs already drive it: `input.hooks.keypressed = …`, `input.hooks.textinput = …`.
  - The lingering `.callbacks.on_text_entered`/`on_limit_reached` are the widget's *trigger
    callbacks* — a different layer, already matching the ratified principle (`callbacks` =
    trigger-called). Not part of this rename.
- So RVW-071 is a **stale marker on already-shipped work** (+ its `it`-string still narrates the
  old name). Disposition: **DROP RVW-071/079/069** and REWORD the stale `on_text_input`/`sink`/
  `tier-3` describe/it strings to the ratified vocab. No design work, no deferral.

### D3 — Console-as-hidden-sink safety (master **RVW-111**) — RELOCATED to the collapse-gate ledger
> **RELOCATED (owner, 2026-07-21).** D3 is not marker vocabulary — it's a genuine runtime
> **design-safety** ambiguity, surfaced *during* this pre-TF2 noise-cleanup. Thrown forward to
> the pre-B/C/D collapse-gate ledger (`../notes/collapsed-gate-ledger.md`, row **G-1**, category
> (b), OPEN) to be ruled in the collapsed sitting after TF2/TF3 — **not** ruled in the marker
> lane. Markers RVW-107..112 stay in-tree, un-dropped, pointing there. Section kept below for the
> charter text.

The substantive question: when a project runs and the input widget is hidden, does the console
**silently consume / evaluate** keystrokes? RVW-111 argues that's dangerous-or-pointless and
that an active *route* should own the fall-through, not a hidden console. **Governs:** RVW-107,
108, 109, 110, 112.
- **Recommendation — DECIDE, doc-first (I pre-research):** I cross-check `decisions/input.md` +
  `internals/user_input.md` for whether hidden-console consumption is intended. If the docs
  settle it → REWORD the markers to a doc-reference + DROP. If they don't → this is a **real
  design gap** the owner rules (and may feed a decision/tech-debt entry). Highest-value cluster;
  do not delegate the ruling.

### D4 — Testing philosophy: drive real framework code / public surface vs. internal mocks — DEFERRED into TF2/TF3
> **DEFERRED (owner, 2026-07-21).** D4 *is* the Test-Fidelity investigation; ruling it in the
> marker lane would rule it twice and risk divergence. Deferred **as a unit into TF2/TF3** — the
> ~13 non-fidelity markers ride along with the three fidelity items already stamped `→TF2`
> (below). Item 3 (the `setup_callback_handlers`/`set_default_handlers` naming collision) is
> **not heavy** (owner): the collision is documented in
> `../../../internals/event_dispatch_layers.md`; its in-tree remark is left in place for the
> owner's own eyes during the TF2 manual recheck — **not** promoted to the collapse-gate ledger.

Recurring across the fixture and several specs: should fixtures/tests call **real framework
entrypoints + the public `compy.input` surface** instead of hand-rolled provision/deprovision
algorithms and `F.singleton.*` monkeypatches? **Governs:** RVW-006, 007, 009, 012, 013, 014
(general principle), 015, 016 (`F.reset`), 032 + 060 (`F.mock_widget[_with]` wrapper), 072,
097 (`F.console_with`), 101, 102, 103, 104. **Pools with A2's two standing fixture-architecture
questions** (wrap-native helper; play-mode fixture) per the TF3 plan.
- **Recommendation — DECIDE the principle once:** if "prefer real code / public surface" →
  it spawns a **fixture-refactor work item** (bigger than marker-drop; record as a decision +
  tech-debt/refactor task, annotate markers as tracked). If "mocks acceptable here" → REWORD the
  markers to a one-line justification + DROP. Either way one ruling disposes the cluster.
- **Handed off from D6 (owner, 2026-07-21) — three concrete fidelity items for the TF review:**
  1. **`fixture:150` `REVIEW/fidelity (→TF2)`** — the `F.new` `set_love_*` block hand-rolls a
     **partial** equivalent of `Controller.set_default_handlers()` (skips its View ops +
     `project_input:deactivate()`, installs a hand-picked event subset). *Why not just call
     `set_default_handlers()`?*
  2. **`fixture:226` `REVIEW/fidelity (→TF2)`** — does `F.activate_project` match the **actual**
     activation path (`consoleController.run_user_code` → `Controller.set_user_handlers`) instead
     of mocking it? (Same question `:245` raises for the next helper.)
  3. **Architecture-naming question (owner spotted):** `Controller.setup_callback_handlers`
     installs `love.handlers.*` (the master dispatch table, w/ shortcut logic), while
     `set_default_handlers`/`set_love_*` install the individual `love.<event>` callbacks — **two
     layers both named "handlers", plus a "callback" in the name.** After D6 settled hook /
     callback / handler for the *input-API* vocabulary, the *Controller/framework* layer still
     carries its own "callbacks" alongside "handlers"; clarify what each means there (or escalate).
     Not a D6 rename — a conceptual/architecture item TF should resolve or escalate.

### D5 — `native`/`natives` vocabulary rename (owner, 2026-07-21)
**Baseline-confirmed feature-invented term.** `git grep native updev -- src` = **0** in the input
sense (all baseline hits are the vendored `nativefs` filesystem lib). So `native`/`natives` was
born inside feat/77 and self-ratified by its own design docs — NOT pre-existing project vocabulary.
Not a public contract: the public surface is `compy.input.hooks[event]`; `natives` leaked only into
**private** identifiers (`project_natives`, `wrapped_native`, `chain_native`, `keyboard_native`,
`seed_hooks(hooks, natives)` param) + comments + ratified prose. The code already sources these from
a param named `userlove`.
- **RULED (owner): variant B — `handler`.** Prose → "the project's own love.\* handler(s)" (zero
  jargon); identifiers → `project_natives`→`project_handlers`, `*_native`→`*_handler`,
  `natives` param→`handlers`; tests `it('a native …')`→`it('a project handler …')`. Keep `userlove`
  as-is (it's accurate provenance).
- **Blast radius (grep census, real, minus `alter`***`native`*** false positives + vendored):**
  src ≈ 21 (controller ~12 + projectInputController 9), tests ≈ 37 (input_events 24, fixture 7,
  redesign_ac 4, shortcuts_click 1, widget_lifecycle 1), ratified docs ≈ 16 (decisions 13 +
  internals 3; input_api hits are `alternative` FPs). **~74 lines.**
- **Re-homes the parked markers:** RVW-073/077 (native-install-path describe/vars, was "→D4") are
  **D5 work**. Also folds the fixture native-naming markers (input_fixture:191/227) + the
  input_events native-group markers (378/387/388).
- **Run SOON — before D4/D3** (owner: high cognitive noise fogs the remaining review). Reorders the
  earlier D1,D2,D4,D3 → …D5,D6,D4,D3.

### D6 — dissolve `slot` contextually (owner, 2026-07-21)
**Baseline-confirmed feature-invented + vague-because-overloaded.** `git grep slot updev -- src`
= **0**. `slot` is doing **two jobs**, which is exactly why it needs context: (a) **gateway
occupancy** ("keyboard/text slots", "slot occupant", "route slot management") = *which controller
owns `love.handlers.keypressed`* — the code already names this `_keyboard_route`; (b) **assignable
position** ("hook slot", "on_text_entered slot", "validator slot", "output slot") = *a function
field* — the real name is **hook** (`hooks[event]`) or **callback field** (widget).
- **RULED (owner): dissolve `slot`, contextually.** Occupancy sense → **route** vocabulary;
  assignable sense → **hook** / **callback field**. Retire the umbrella word. Existing src marker
  `projectInputController.lua:4` (RVW range) is resolved by this. `before_exit_slot` private local
  may stay or →`before_exit_field` (discretion).
- **Blast radius (grep census):** src 10 (consoleController 5, controller 3, projectInputController
  2 incl. the marker line), tests 28 (widgets_callbacks 9, fixture 6, input_events 6, nfr 3,
  shortcuts 2, session 1, reconfigure 1), ratified docs 19 (decisions 10, internals 8, input_api 1).
  **~57 lines.**
- **Run alongside/after D5**, before D4/D3.

**D5/D6 note:** these touch **src + ratified docs + tests together** (unlike tests-only D1/D2) — a
tests-only reword would re-drift tests from docs/src. Sweep all three areas per cluster. LSP
re-verified 2026-07-21: OK for `definition`/`diagnostics`/local-fn refs, **BROKEN on cross-file
method refs** (missed `pic:activate` call site) — **grep is the completeness authority** for these
renames; LSP is a second opinion only.

**Governing decisions dispose ≈ 37 markers.** The ~74 below are the mop-up.

---

## Deferred phases (owner, 2026-07-21) — completeness residue from D5/D6

The D5/D6 census scoped only `decisions/` + `internals/`; it under-scoped three reference docs.
Owner ruling: don't hold the D6 commit for these; handle in upcoming commits.

- **Phase TD-actualize — `doc/development/technical_debt/input.md`.** This doc is actualized
  regularly, so its vocabulary refresh gets **its own phase**, not a D6 sub-sweep. Deferred D5/D6
  residue to fold in there: `:360`/`:365` `native-slot restores` → `default-handler restores`;
  `:519-520` `slot occupant (the project's native handler)` → `active route (the project's
  handler)`. **Prose left intact for now** (owner) — incl. the `:501/:503` "Old state" historical
  description (`compy_input[chan] or natives[event]`, "captured native"): leave as historical.
  **Keep (not residue):** the carve-out item `:19-39` deliberately names the *current* code
  (`wrapped_native`/`keyboard_native`/`chain_native`/`natives`) its future refactor renames;
  `:121` "slots into" (English verb); `:154` "before_exit slot" (excluded lifecycle sense).
- **Reference-doc vocab completeness (small, upcoming commit)** — ratified/guide docs the census
  missed: `tests.md:17` `F.activate_project(natives)`→`(handlers)` + `raw-slot`→`raw handler`;
  `tests.md:19` `bypasses the \`love\` slots`→`\`love\` handlers`; `input_api.md:317` `a single
  function slot per event`→`a single function per event`. (`input_api.md:72/217` = "alternative"
  false positives.)

---

## Mop-up batches (≤10 each; order after governing)

### B-E — Prose / clarity rewrites (owner confirms intent → Sonnet applies)
Split E1/E2 (≤10). Recommend REWORD unless noted; several are "your discretion" grammar fixes.

| RVW | loc | rec | note |
|---|---|---|---|
| 017 | highlight:1 | REWORD | reframe "shape contract"→ regression-isolation purpose (with 018) |
| 018 | highlight:2 | REWORD | say "regression catch" in file+suite+opening (with 017) |
| 020 | highlight:36 | RENAME | `view_access_ok` → clearer name (naming) |
| 023 | highlight:51 | RESTRUCT | alias the 3 evaluator variants meaningfully |
| 027 | cursor:2 | REWORD | header prose describes dispatch but file is cursor/text API |
| 029 | cursor:13 | REWORD | verbless phrase; confirm intended meaning |
| 035 | events:20 | REWORD | fix broken file-split-rationale prose |
| 036 | events:29 | REWORD | de-jargon + de-dup opening prose |
| 038 | events:54 | REWORD | trim over-explaining comment to first line |
| 040 | events:65 | REWORD/DROP | "order, consume, fall-through" banner reads as noise |
| 043 | events:110 | REWORD | it-desc: "truthy return value", not "truthy handler" |
| 047 | events:155 | REWORD | cleanup banner + it wording |
| 057 | events:254 | REWORD | it-desc covers read+write; "proxy" is impl jargon |
| 067 | events:328 | REWORD | frame behaviourally ("when no hook configured…") |
| 068 | events:337 | REWORD | grammar only (content agreed fine) |
| 075 | events:403 | REWORD | make "native always behaves like hook" explicit |
| 082 | nfr:17 | REWORD | rewrite mumbling "provisional facts" prose |
| 049 | events:159 | REWORD | "tables and normalization" are internals; name behaviourally |

### B-F — Structural / grouping / relocate

> **B-F COMPLETE (S21, 2026-07-29).** All 14 markers dispositioned and dropped; suite
> **847/0/0/4** (841 − 1 redundant test + 7 matrix rows + 1 read/write split − 1 merge, editor
> +1 / input −1 from the relocation). Owner rulings: **relocate** the editor block-nav cluster
> (105/113/114 → `tests/editor/editor_spec.lua`); **drop** the redundant test (046) once the new
> matrix covered it; **accept** 042 (interception matrix) and 054 (whole-chain delivered triple),
> **decline** 039 (random chords); **confirm** the TF1 split sufficient (096); apply the
> mechanical bundle (048/051/058/062/076/109). Two findings against this plan: **048 and 051 were
> already satisfied in-tree** — the `describe` wraps they ask for exist, so their RESTRUCT
> recommendation here was stale, and they were dropped as moot rather than acted on. Both new
> tests were negative-checked (deliberately flipped assertions fail) rather than trusted green.
> Per-marker detail in `../notes/review-marker-inventory.md`.

| RVW | loc | rec | note |
|---|---|---|---|
| 105 | lifecycle:27 | RELOC | `make_editor_session` (1 caller) — editor-reloc cluster |
| 113 | lifecycle:160 | RELOC | block-nav test → tests/editor (file's own OPEN note defers to owner) |
| 114 | lifecycle:171 | DECIDE | owner's own RESPONSE offers 2 options; pick one |
| 046 | events:144 | DROP? | marker claims test redundant; owner confirms then drop test |
| 048 | events:156 | RESTRUCT | wrap 3 combo cases in sub-describe |
| 051 | events:214 | RESTRUCT | wrap signatures group in describe |
| 058 | events:255 | RESTRUCT | restructure pressed-keys-table tests (× event type) |
| 062 | events:295 | RESTRUCT | move keyreleased-delivery test beside contents test |
| 076 | events:443 | RESTRUCT | merge with first test in group; drop "bucket D" prose |
| 109 | lifecycle:129 | RESTRUCT | rename/group the two sibling hidden-widget tests |
| 039 | events:59 | DECIDE | generalize `chord` helper to random chords? |
| 042 | events:109 | DECIDE | add interception matrix test? |
| 054 | events:221 | DECIDE | whole-chain passthrough test instead? |
| 096 | routing:25 | DROP | split already done (TF1); confirm sufficient → drop |

### B-COV — Coverage gaps / matrix / symmetry (owner: add / accept-gap / mark pending)
| RVW | loc | rec | note |
|---|---|---|---|
| 021 | highlight:39 | COV | does early-return guard mask the regression path? |
| 022 | highlight:44 | COV | test symptom vs bug path |
| 024 | highlight:53 | COV | 2×2 lua/text × missing/empty-hl matrix? |
| 025 | highlight:61 | COV | "empty and non-empty" unclear/untested |
| 030 | cursor:43 | COV | only one cursor case proven |
| 031 | cursor:52 | COV | empty-vs-hidden confound |
| 041 | events:70 | COV | parametrize group across event types |
| 044 | events:111 | COV | symmetric truthy-hook / missing-participant cases |
| 050 | events:196 | COV | per-event vs flat — internals smoke-check tension |
| 053 | events:220 | COV | keypressed-table-contents coverage location |
| 055 | events:234 | COV | type-signature only, not delivered contents |
| 065 | events:320 | COV | non-defined-participant matrix |
| 070 | events:357 | COV | symmetric `on_key_pressed` case |
| 074 | events:402 | COV | hook fires regardless of widget-state (2 forms) |
| 078 | events:473 | COV | legacy-path vs `on_*`-path coverage confound (audit) |
| 086 | nfr:70 | COV | why assert on `session.handlers` surface |
| 087 | nfr:103 | DEFER | self-deferred to a future propagation-test pass |
| 088 | nfr:134 | COV | set `ctrl` pressed too — cheaper? |
| 098 | routing:137 | COV | keyreleased-under-editor gap: add test? |
| 099 | routing:145 | COV | why `pending`, not implemented (pointer→editor) |
| 100 | routing:148 | COV | Search-widget gap: fill or justify |
| 106 | lifecycle:50 | COV | TODO: prompt-labelling/relabelling test |

### B-I — Doc-citation hygiene & conventions
**B-I/1 (fixture: RVW-001/002/003/004/005/011) DONE — commit `8bc066f`** (2 moot, 1 reworded,
1 rename `F.update`→`F.love_update`, 1 dropped; **RVW-003 escalated → collapse-gate ledger
G-2**, the compy/hooks API-coherence gap). **B-I/2 IN PROGRESS (S20):** clear-apply half DONE —
RVW-026/080 (DROP provenance), RVW-091 (DROP moot: no `paragraph X` refs remain), **+ the D1
leftover below (RENAME, done)**; consistency-stripped the unmarked routing:1 provenance too.
Suite 841/0/0/4. **B-I/2 COMPLETE (S20)** — RVW-083/084/085/090/094 all ruled+applied via the
**version-tag migration** (owner decision (a), 2026-07-28): dissolved the A/B/C/D bucket taxonomy
across routing+nfr(+events dangling ref) in favour of LÖVE-style per-version availability tags
(`since 1.0.0-rc20260712` = feature-new; pre-existing = untagged; forward→"planned change";
NFR→guard label). 083 (drop 'forward' jargon), 084 (rename provisional group), 094 (dissolve
buckets) done; 090 (ruling 8) → conventions doc + tech-debt follow-up; **085 → contested carve-out**
(inspect-console-owns-surface kept as-is, tech-debt entry, ties G-1). Migration key:
`S20-version-tag-migration-key.md`. Suite 841/0/0/4.

> **D1 completeness leftover — `input_routing_spec.lua:4-5` — DONE (S20, B-I/2).** Rewrote the
> ROUTE/WIDGET/SINK block to the ratified `route / widget` vocab (dropped `SINK = last consumer`
> and the `consumer` gloss on ROUTE), matching the `nfr_forward_spec` head. Was the block D1 Pass
> B missed (RVW-034 overload).

| RVW | loc | rec | note |
|---|---|---|---|
| 001 | fixture:150 | REWORD | de-jargon "slots/gate last-resort route" + leak concern |
| 002 | fixture:160 | REWORD | explain `set_love_update(CC)` line |
| 003 | fixture:191 | RENAME | `set_compy_handler` → clearer (naming) |
| 004 | fixture:192 | DECIDE | extract `project_compy_namespace` helper? |
| 005 | fixture:205 | RENAME | `F.update` → `love_update`? (used: 4 sites) |
| 011 | fixture:229 | REWORD | drop ephemeral "M4 ruling-1" ref (accuracy ok) |
| 026 | cursor:1 | DECIDE | keep/drop TF1 provenance note (with 080) |
| 080 | nfr:1 | DECIDE | drop once-monolithic-spec provenance (with 026) |
| 083 | nfr:24 | REWORD | "forward" meaning + some in-group prose outdated |
| 084 | nfr:25 | PROMOTE | rename "expected to change" + reference decisions |
| 085 | nfr:52 | PROMOTE | promote provisional fact → invariant (doc has OWNER-RULING-PENDING) |
| 090 | routing:18-19 | DECIDE | comments→canonical-docs rule (live: 2 src violations found) |
| 091 | routing:20 | DECIDE | cite named sections, not "paragraph X" |
| 094 | routing:23 | DECIDE | dissolve A/B/C/D buckets → "since 1.0.0" tags |

### B-H / naming leftovers fold into B-I/B-E RENAME rows above (003, 005, 020).

---

## Owner-tracked / parked (NOT for dissolve)
Owner's own in-progress, self-assigned tagging actions — leave until the owner finishes them:
- **RVW-092** (`{badspecref:}` sweep — "everywhere in the file"), **RVW-093** (`{jargon:}`
  tags), **RVW-095** (busted `#tags` in groups). These are owner-owned conventions in progress.

---

## Batch summary
**111 open `tests/` markers** (RVW-001..114 minus the 3 Batch-1 done). Groups below **cross-list**
a few markers (e.g. 069 in D1+D2, 049 in D1+B-E, 072 in D4), so the counts are approximate, not a
clean partition — each marker's final single home is fixed when its batch runs.
- **Governing (all disposed as of 2026-07-21):** D1 (vocab, ~13) ✅ · D2 (API-shape, ~2) ✅ ·
  D5 (native rename) ✅ · D6 (slot) ✅ — all ruled+applied. **D3 (hidden-sink safety, ~6) →
  relocated to collapse-gate ledger** (markers stay in-tree, un-dropped). **D4 (testing-philosophy
  + A2, ~16) → deferred into TF2/TF3.** ≈ 35 distinct markers, none now ruled in this lane.
- **Mop-up:** B-E prose (~18, split E1/E2) · B-F structural (~14, split F1/F2) · B-COV coverage
  (~22, split COV1/COV2/COV3) · B-I doc-hygiene (~14). ≈ 68 markers.
- **Parked:** RVW-092/093/095 (owner-tracked).
- Every open marker lands in exactly one governing decision OR one mop-up batch OR parked; the
  cross-listings above are pointers, resolved at batch time.
