# session15 — track

## Boot (2026-07-19)
- HEAD `8106c48` (frontload agents/sessions.md). Tree: guardrail-3 anomalies only.
- Baseline suite confirmed: **815 / 0 / 0 / 4** (`busted tests`).
- Re-entrance: fresh start (only prompt.md in session15/). Track opened now.
- Task per prompt.md: **TF1** — split `tests/input/input_contracts_spec.lua`
  (2317 LoC, 19 inner describes) into human-reviewable files.
  Behaviour-preservation contract: 815/0/0/4, same tags, same 4 pendings.

## Owner direction (in-session, 2026-07-19, boot)
- Split boundaries may be **cognitive**, not just describe/tag seams — read what
  tests *target*; tags don't reflect full topology and describe scopes "could be
  better."
- **PRECURSOR REFACTOR (do first):** the fixture (`tests/helpers/input_fixture.lua`)
  executes all its build code at **module-load time** (lines 125–143) — a state-
  collision risk when the suite is split. Directive: wrap that top-level executable
  code into an explicit `setup()` method, add a **symmetric `teardown()`**, and
  call setup/teardown from test hooks (before_suite / before_each or analogs) so
  module loading no longer triggers context/state collisions. This is the fixture's
  own open REVIEW at input_fixture.lua:123.
- "If unsure, ask Fable for advice." + later: "don't hesitate to spawn subagents
  for mechanical work (Sonnet) or expensive advanced wisdom (Fable)."

## Fable consult — fixture lifecycle (verdict verified in code)
Prompt: `validation/prompts/S15-TF1-fable-fixture-lifecycle.md`
Verdict: `validation/outcomes/S15-TF1-fable-fixture-lifecycle.md`
- **HEADLINE (verified):** busted 2.3.0 **insulates every spec file** —
  `busted/init.lua:63` registers files `envmode='insulate'`; `context.lua` save/restore
  snapshots+reverts BOTH `_G` and `package.loaded` per file boundary. So the cross-file
  `_G.love`-clobber threat the owner's directive names **does not exist under this runner**
  (it's a busted-1-era concern). Proof: `busted tests/input/project_open_liveness_spec.lua`
  = 4/0/0/0 standalone (fixture rebuilds fresh in that file's bubble).
- **Refactor still recommended**, for different valid reasons: explicitness,
  runner-independence, and — decisive — **per-file standalone-runnability**, which is the
  GATE that proves the split introduced no hidden cross-describe coupling.
- **Design (Fable):** move build (lines 125–143) into `F.setup()` guarded against
  double-call; keep `package.preload['view.view']` at module scope (must precede any view
  require); shallow symmetric `F.teardown()` = `project_input:deactivate()` +
  `_G.love/_G.TESTING=nil` + nil the module-locals; wire `setup(F.setup)`/`teardown(F.teardown)`
  + keep `before_each(F.reset)` per split file. Preserve build line-order (session.new LAST;
  TESTING before require_modules). Optionally add `set_love_quit` to setup's installs.
- **Non-additive consequence (verified):** `project_open_liveness_spec.lua:16` reads
  `F.cc` at describe-body scope → nil-crashes after the move; must relocate into a hook.
- All 5 Fable factual claims verified in code (insulation, standalone-green,
  describe-body-read, stale keys_pressed comment). Refactor MUST keep suite 815/0/0/4;
  any behaviour change = regression, not expected.

## Precursor refactor DONE + committed `8f35589`
- input_fixture.lua build → guarded F.setup / shallow F.teardown; hooks wired into
  input_contracts_spec + project_open_liveness (latter's describe-body F.cc read → before_each).
- Verified: suite 815/0/0/4 (× --repeat 2), both consumers standalone-green, no diagnostics.

## Split design (proposed, owner-gated)
- File is 19 flat-`it` describes (no nested describes); #m5c "four-tier dispatch chain"
  is 883 LoC with internal `-- ----` seams. Proposed 9-file cognitive decomposition:
  `validation/reviews/TF1-split-decomposition.md`. Open calls: split the #m5c elephant
  into 2 (5+6) vs keep whole (8 files); naming; #m8 placement. Awaiting owner ruling
  before Sonnet executes the cut.

## Owner ruling (in-session): split #m5c into 2 → 9 files; proceed as proposed.

## Split EXECUTED (Sonnet worker) + independently verified
- Prompt: `validation/prompts/S15-TF1-split-execution.md`; deliverable:
  `validation/outcomes/S15-TF1-split-execution.md`.
- 9 files created (172–493 LoC each), original `git rm`'d. Independently verified by me:
  suite 815/0/0/4; per-file standalone sum = 120 succ / 4 pend (all 4 pendings in
  input_routing_spec); tags identical except mandated #input 1→9 and #m5c 2→3;
  it-count 120=120; pendings 4=4.
- **Caught a fidelity regression Sonnet missed:** 7 file-head meta-REVIEW remarks
  (owner's jargon/spec-ref/bucket/split notes) were dropped when the header was
  condensed. Carried all 7 verbatim into a "SUITE-LEVEL REVIEW NOTES" block atop
  input_routing_spec.lua (kept greppable in-tree for jargon/spec-ref/Phase-C). No
  test-attached REVIEW was lost. (Sonnet also self-caught+fixed a stray `#77` its
  header had introduced in nfr_forward.)
- tests.md updated (split reality; "comment header, not a file split" sentence
  superseded; 4 pending file:line → input_routing_spec 80/145/158/224; coverage-table
  + tag-locality refs). technical_debt/input.md 2 stale file refs retargeted. New spec
  headers keep "split from input_contracts_spec.lua" provenance lines (lineage, fine).
- Note for successor: `keys_pressed_spec.lua:48-50` stale "other spec files replace
  _G.love during collection" comment (invalidated by the busted-2 insulation finding)
  is a {badspecref: A8} item — NOT touched (Phase-C evidence, out of TF1 scope).

## TF1 AMENDMENT — readability sub-describes (owner request, post-split)
- Owner hand-nested `input_cursor_text_spec.lua` into method-named describes
  (get_cursor/set_cursor/set_text, keep_cursor nested) + reworked headers, renamed
  dispatch_chain→events / widget_io→widgets_callbacks, dropped/moved some tags
  (their own commit `265a5ba` "human review of tests: wip"). Asked me to mirror the
  nesting over the remaining flat files: map its → subgroups myself, Sonnet carves.
- Confirmed to owner: nested describes are idiomatic busted (zero runtime effect;
  outer setup/teardown/before_each inherit) — cannot change 815/0/0/4.
- Mapping (mine): `validation/reviews/TF1-subgrouping-map.md`. Owner rulings: leave
  the 2 light files (widget_lifecycle, nfr_forward) FLAT; keep lone single-it groups
  as-is (no folding); routing + shortcuts_click already-nested, untouched. Net: 4 files.
- Executed by Sonnet (prompt `validation/prompts/S15-TF1-subgroup-execution.md`,
  outcome `.../outcomes/S15-TF1-subgroup-execution.md`): 23 nested groups
  (events 7 on existing -- ---- seams, widgets_callbacks 8, reconfigure 4,
  route_lifecycle 4). Idiom: wrap CONTIGUOUS runs only (no reorder), no hooks on
  nested describes, prefix-trim it-labels only where clean, all REVIEW/{jargon} +
  section comments preserved.
- Independently verified: suite 815/0/0/4; per-file it+pending identical to HEAD
  (25/27/15/8); `git diff -w` shows ONLY describe wrappers + indent + label trims,
  zero assertion/body lines changed; all 4 standalone-green; 23 group names present
  as mapped. Committed `6dabe62` (code + 3 validation docs); compose.yml (owner WT) left alone.

## TF2 started + REDESIGN side-product (owner process pivot, 2026-07-20)
- Owner sprawled inline TF2 review notes across cursor_text/events/nfr_forward specs
  (terminology/clarity/fidelity + an API-shape pivot idea). Committed as TF2-wip `34cf318`
  (notes only; suite 815/0/0/4; nfr_forward still open in owner's vim `.swp` at commit).
- Owner sketched a redesign: **3-component chain** (handlers[event][combo] -> hooks[event]
  -> widget), widget **callbacks** table (on_text_entered + before/after submit/cancel) at
  UIC level, a handler/hook/callback/routing **vocabulary**, no framework tier (Enter/Esc
  project-overridable-then-widget-default; non-consume-when-hidden bubbles to parent
  dispatch), loosened D7 (freeze container, keys writable). D6 trap resolved by
  separation-of-concerns (UIC detects+propagates; context owns lifecycle).
- I asked the design questions, read decisions/input.md (13 decisions) + projectInputController
  (live 4-tier chain) to ground it. Distilled to two notes (committed `b35eb9c`):
  `validation/notes/input-api-redesign-proposal.md` (vocab table + decision-by-decision
  keep/supersede map: 9 keep / 1 re-home / 3 supersede) and
  `.../input-api-redesign-evaluation.md` (my assessment: vocab now unconditionally, structure
  as a scoped tests-first pass; 7 resurfacing tensions harvested; risk = D6 controller-vs-model
  layering seam). Explicitly a Phase-B (scaffolding-suspect) input, NOT smuggled into TF2.

## WRAP (2026-07-20) — process pivot
- Status: **TF1 complete**; **TF2 in progress** (finish against CURRENT impl; post-TF2 plan
  may change if redesign adopted); **redesign = side-product feeding Phase B**.
- S16 handover overridden by owner: NOT the default revalidation task — instead **Fable-led
  preliminary analysis + plan review** (pressure-test the proposal, esp. D6 seam; re-shape
  post-TF2 plan). Report + session16/prompt written; CURRENT PROMPT repointed to session16.
