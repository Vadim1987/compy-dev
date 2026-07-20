# session17 — track

## Boot (2026-07-20)
- Fresh start: no prior track.md/report.md in session17/ → clean boot.
- HEAD: `2069e45 compose commited`. Tree: only sanctioned untracked scratch (per validation.md §Hard guardrails 3).
- Suite baseline confirmed: **815 successes / 0 failures / 0 errors / 4 pending**. Matches expected.
- Read: agents/validation.md, agents/sessions.md, session17/prompt.md, session16/report.md,
  delta-design-input-api.md, delta-spec-input-api.md, plan.md Phase R section.
- Task: **Phase R execution (R4/R5)**. Opus orchestrates; Sonnet workers for mechanical; Fable oracle only for genuinely hard judgment.
- Standing hygiene carried into every spawn: (a) tell agent lua-lsp MCP exists + sleep 1 after .lua edit;
  (b) delegate down to Sonnet; (c) materialize prompt+result on disk; (d) serial in shared tree, no worktree parallelism.

## R4 order (from delta-spec obligations / plan.md):
1. REVIEW-remarks reconnaissance (Sonnet) — inventory src/ REVIEW: remarks, tag against delta-design obligations
2. Tier-1 removal + gateway-pretap-unaffected proof (§2; AC 5,6,9-mid)
3. Submit/cancel default-flip + veto (§3; AC 1-4)
4. hooks[event] unification + seeding (§5; AC 8)
5. callbacks membership + D7 guard simplification (§1; AC 9,10) — guard LAST
6. Console patch (§6; AC 7)
7. Vocabulary/rename sweep (handlers→shortcuts etc.) — LSP rename + grep backstop, all-or-nothing
8. Docs update (internals/user_input.md, input_api.md, technical_debt/input.md)
R5: dispatch (6a) + widget-method factory (6b) extraction — can ride units 2-3 or standalone.

Gate: suite green, 10 ACs pass as tests, rename sweep LSP-verified zero hits, REVIEW inventory no un-dispositioned "resolved".

## R4 step 1 DONE (Sonnet worker, model:sonnet)
- Inventory: validation/outcomes/R4-1-review-inventory.md. Tally: 8 resolved / 30 open / 4 out-of-scope (42 total).
- Worker judgment good: flagged 2 "host-deleted-but-concern-survives" (pIC:47 run_hook→run_callback; pIC:197 the OR-chain remark the delta-spec itself defers — NOT resolved). Verified pIC:197 & main.lua:360 dispositions match delta docs.
- Resolved list (to remove as code changes): uIC 434,480,482,669,685,687; controller 325; main 360.

## COUPLING FINDING (2026-07-20) — plan.md R4 literal step order won't stay green unit-by-unit
- Existing tests encode OLD behavior that ACs invert: input_widgets_callbacks_spec.lua:389 "framework Enter cannot be shadowed" (AC5 inverts→shadowable), :282/:494 widget hidden after submit/cancel (AC1/3 flip→stays shown).
- => tier-1 removal (plan step 2) alone reds those tests; only submit/cancel relocation (step 3) repairs. Steps 2+3 are ONE atomic behavioral change.
- Also: new dispatch reads shortcuts[event]/hooks[event] → surface reshape (rename handlers→shortcuts, on_*→hooks) must PRECEDE or accompany dispatch flip.
- plan.md calls it "recommended order"; R4 gate is OUTCOME-defined (green, 10 ACs, rename complete). Guardrail-2 hard constraints (S7-before-green-citing, slices-last) NOT violated by regrouping R4 internals.
- Proposed green-to-green regrouping (pending owner confirm): U1 widget-method factory (6b, pure refactor); U2 surface reshape (shortcuts/hooks/callbacks sub-tables + hooks unification §5 + callbacks grouping + D7 guard + teardown reseed §1, tier-1 KEPT) AC8/9/10; U3 dispatch free-fn + tier-1 removal + widget submit/cancel defaults + flip + veto + shadowability + consumption-via-shownness + console patch (6a/§2/§3/§6) AC1-7; U4 docs + rename-sweep LSP verify.

## OWNER RULING (2026-07-20, AskUserQuestion): APPROVED green-to-green 4-unit regrouping (U1-U4 above).
- Materialized: validation/notes/R4-execution-decomposition.md.
- Delegation call: U1 (tiny ~15-line pure refactor) done in-session by Opus to build file familiarity for writing tight U2/U3 worker prompts; U2/U3 (large, tightly-spec'd) → Sonnet workers. Rationale: spawn overhead > saving for U1; token-economy directive targets LARGE Opus sweeps, not a 15-line change.
- U1 has NO new test (pure refactor, §4 "zero observable difference"); existing suite-green is acceptance.

## U1 DONE — commit e856760. build_widget_api(get_widget, get_active_flag, state) factory. Suite 815/0/0/4. LSP clean.
- Spec wrinkle noted: §4's sketch omits that show/configure need sticky `state` → threaded as 3rd param (≤4, faithful to intent).

## U2 design (Opus, in-progress). Refined AC slicing: **U2 = AC8 (hooks seed) + AC9 (guard)**. AC10 (teardown reseed to stay-open default) → U3 (needs U3's auto-close flip; U2 still auto-closes via ui:submit/cancel).
- New state shape: state.{shortcuts={kp,kr,ti Key.new_handler_table}, hooks={kp,kr,ti}, callbacks={8 slots}, pending}.
- Guard (build_input_surface): compy.input __newindex ALWAYS errors; shortcuts proxy __index→per-event table, __newindex errors (frozen identity); hooks/callbacks proxies allow leaf writes. AC9 covers all 6 cases.
- hooks unification: CHANNELS map DELETED; seed_hooks(hooks,natives) at activate (if hooks[ev]==nil then hooks[ev]=native); _generic_callback reads compy_input.hooks[event]; self.natives field DELETED. AC8 = no resurrection on nil.
- callbacks: merge_output_keys/stash read state.callbacks[k]; run_hook reads ci.callbacks[name]; _dispatch tier-2 → shortcuts[event][combo]. tier-1 + old submit/cancel auto-close KEPT.
- reset_compy_input rewrite: can't write through frozen surface top-level → wipe via sub-tables (input.shortcuts.<ev> wipe_table; input.hooks[ev]=nil; input.callbacks[k]=nil). Split INPUT_CALLBACK_SLOTS→ 3 hooks-events + 8 callback-names.
- Delegation: Opus does core src + central fixtures + AC8/9; delegate leaf spec/example rename sweep (~13 files) to Sonnet; verify green; commit U2.

## U2 DONE — commit 41cbe87. Suite 819/0/0/4 (815 baseline + 4 AC).
- Opus: consoleController surface (frozen 3-subtable guard), controller reset, projectInputController (seed_hooks, hooks[event] dispatch, natives/CHANNELS deleted), fixture reset_chain, AC8/AC9 spec.
- Sonnet worker (rename sweep, 4 test files, 67 renames): validation/prompts+outcomes/R4-U2-rename-sweep. Verified independently: suite green, diff = surface field-paths only, no assertions/config-keys/singleton-fields/false-friends touched, no old surface tokens on code lines. LSP clean.
- Deferred to U4: example migrations (guess/tixy/valid/repl) + prose-comment vocab (sink/singleton/handlers in comments) — don't affect green; U4 verifies completeness. balloons/maze = sanctioned scratch, leave.

## U3 (in progress) — dispatch free-fn + tier-1 removal + widget submit/cancel + console patch. AC1-7 + AC10. tests-first STRICT.

### OWNER RULING (2026-07-20): compy.input.callbacks ARE the widget's self.callbacks — literally same table. Project sets callbacks, widget calls them, no widget modification.
- Owner REJECTED my broad Fable spawn, answered Q1 directly. Said "recheck vs spec / consult Fable IF needed" but "should resolve concern generally." → proceed myself; consult Fable only on a real contradiction.
- Resolved model materialized: validation/reviews/R4-U3-callback-model.md.
- KEY TIMING FACT (verified): get_compy_input runs EAGERLY in build_console, BEFORE overlay singleton exists → callbacks proxy must resolve love.state.user_input_controller.callbacks LIVE (lazy), not capture. Rules out eager-capture variant.
- Q2 (overlay scoping) MY decision: widget:keypressed handles return/escape→_submit_default/_cancel_default gated on _is_overlay (self==love.state.user_input_controller, reuses existing predicate; console/editor never the overlay → provably untouched).
- Sticky-output machinery (merge_output_keys/OUTPUT_KEYS) becomes redundant (widget's callbacks table persists inherently) → remove; apply_config writes self.callbacks; highlighter keeps ev bridge.
- Gave owner the plan; proceeding tests-first.

### OWNER PUSHBACK (2026-07-20) on Q2: `self == love.state.user_input_controller` gate is the abstraction leak the REVIEWs/Fable flagged. Widget should use its own shown/hidden flag; propagation is the callback's business.
- MY REVISED Q2 = **(iii) route-invoked**: submit/cancel-default lives in the free `dispatch` fn's widget-branch (only the PROJECT ROUTE calls dispatch). Console/editor call IC:keypressed DIRECTLY → never reach submit/cancel → untouched by CALL PATH, no global check, no capability flag. Widget PROVIDES _submit_default/_cancel_default; dispatch triggers them for plain return/escape (shift+return / ctrl+escape fall through to keypressed editing). Aligned w/ D6 "widget owns behavior, context owns trigger" + future console/editor reuse.
- OPEN QUESTION to owner (A/B): also convert is_shown() itself (still-leaky `self==singleton`) to an internal self.shown flag NOW (A, scope-expands into console/editor construction) vs leave as-is for U3 and log for Phase C (B, my lean). Awaiting answer.
### FINAL U3 MODEL (owner-clarified 2026-07-20): route is DUMB (shortcuts→hooks→widget, first-truthy-wins, zero submit/cancel awareness). Submit/cancel = widget's OWN business via its callbacks. is_shown = strictly internal self.shown flag (no love.state reach). Free-function dispatch.
- No route/global scoping of submit/cancel: widget:keypressed handles Enter/Escape in the NON-EDITOR branch (editor branch keeps its own); console/editor ICs marked always_shown() → they process, and submit-on-Enter is a harmless no-op for console (no on_text_entered; evaluate_input does the work), escape=clear matches. Editor untouched (editor branch).
- compy.input.callbacks IS widget.callbacks (captured once in get_compy_input; boot reordered so singleton exists first — main.lua + fixture). NEVER reassign the table (reset_callbacks mutates in place).
- love.state.user_input KEPT as the {M,C,V} draw handle + paint gate (deeply used for pointer/draw); self.shown is the authoritative shown flag. view:draw() redraw-skip check left as-is (overlay-IDENTITY, not shown-ness — is_shown can't distinguish overlay from always_shown console/editor; flagged to owner, deferred).

## U3 DONE — suite 827/0/0/4 (815 + 12 AC anchors AC1-10). LSP clean. Ready to commit.
- projectInputController: free dispatch() + thin _dispatch; DELETED framework_handlers/install_tier1/framework_submit/framework_cancel/shown_widget/run_hook/_generic_callback/_sink/log_branch (grep-verified zero). (R5/6a done.)
- userInputController: self.shown + default_callbacks + always_shown()/reset_callbacks(); is_shown()=self.shown (removed _is_hidden_overlay + resolved REVIEWs 430-434,480,482); _submit_default/_cancel_default/run_callback replace submit(); deliver/gate/emit_limit read self.callbacks; apply_config→self.callbacks; keypressed Enter/Escape in non-editor branch; ret/limit-return retired.
- consoleController: get_compy_input captures widget.callbacks + is_shown-based get_active; console IC always_shown()+on_limit_reached (§6); dropped `local limit=input:keypressed` (AC7 grep-verified).
- controller.lua: reset_compy_input (shortcuts+hooks only); reset_widget_outputs→ui:reset_callbacks() (AC10 re-seed).
- main.lua + fixture: singleton before console. editor ICs always_shown().
- Tests: input_redesign_ac_spec += AC1-7,AC10; rewrote old-behavior tests in input_events_spec (framework→3-consumer), input_widgets_callbacks_spec (auto-close→stays-open, shadowable), input_reconfigure_spec (stays-open + clear-in-after_submit idiom), input_route_lifecycle_spec (callbacks.* fields).
- OPEN for U4/owner: view:draw() overlay-identity check (is_shown mismatch — flagged); vocab/prose sweep (sink/singleton/handlers in comments); example migration (guess/tixy/valid/repl); docs (user_input.md, input_api.md, technical_debt/input.md); final R gate.

## U4 DONE — commit 6157222 (Sonnet worker, model:sonnet). Suite 827/0/0/4.
- Vocab sweep complete (retired sink/singleton/tier/framework-handler/generic-callback/proxy → 0 in input files; native disambiguated; in-code citations updated). Examples migrated (guess/valid/repl clear-in-after_submit; tixy set_text-on-cancel). main.lua REVIEW dispositioned. Docs: user_input.md, input_api.md, technical_debt/input.md resynced.
- Independently VERIFIED (charter): suite green; grep zero-hits on 9 deleted symbols; retired prose zero in input files; NON-comment src code lines changed = ZERO (comments/citations only); examples correct + parse; LSP diagnostics clean on all touched files (worker's LSP-refs flakiness was transient index lag).
- Fixed my stale R4-U3-callback-model.md: shipped code has NO _is_overlay gate (owner's dumb-route steer superseded it); submit/cancel scoped by the existing non-editor branch; console widget also runs _submit/_cancel_default (harmless, no callbacks) — documented code-wins-on-facts.

## ===== PHASE R GATE: MET (pending owner approval) =====
- suite green 827/0/0/4 ✓ | ten ACs pass as tests (input_redesign_ac_spec, AC1-10 / 12 cases) ✓ | rename sweep complete (grep zero-hits deleted-symbols + retired-prose; LSP now clean) ✓ | REVIEW inventory no un-dispositioned "resolved" left ✓
- R4/R5 (obligations 6a dispatch + 6b factory) DONE. Commits: e856760(U1) 41cbe87(U2) f1050d8(U3) 3c7d6ef(docs) 6157222(U4).
- TWO FLAGS surfaced to owner (non-blocking): (1) balloons (untracked nested-repo example) will now throw at runtime (top-level field-write vs frozen container) — sanctioned scratch, needs migration if revived; (2) console widget runs _submit/_cancel_default on its own Enter/Escape (non-editor branch, no identity gate) — harmless (no callbacks; evaluate_input does the work; escape-clear matches prior), consistent with owner's "widget owns it" model, but confirm acceptable.
- NEXT (not this session unless redirected): TF2 resumes (owner-paced). Gate discipline: await explicit owner approval of R-closed before wrap.

## OWNER FEEDBACK ROUND (2026-07-20, post-U4):
1. Docs vocab: "Combo key handlers" etc. → shortcuts everywhere (owner: pre-vocab-upgrade remarks not authoritative; love2d has own handlers → for THIS feature say shortcuts/hooks/widget). DONE input_api.md (commit 55135b4).
2. balloons: fix to new API. DONE in balloons' nested working tree (terminal.lua after_submit→callbacks.after_submit+clear; after_cancel removed). Owner commits in balloons' own repo.
3. "non-editor branch" = unratified imparity / abstraction leak. Owner: UIC reading app_state to alter behavior is a mode-concern leak (feature-flag-by-parent, or code belongs elsewhere). Owner will inspect + reevaluate in a NEW session. Gave exact line map. Logged as OPEN ISSUE: validation/reviews/R4-open-issue-uic-mode-leak.md.
   - Blast radius (owner asked): NOTHING functionally broken — suite green 827/0/0/4; overlay/console/editor all correct; only cosmetic console no-op _submit_default on Enter. Latent architectural debt (global app_state read + unratified scoping rule I added in U3), not a live bug.

## ===== WRAP (2026-07-20) — Phase R NOT closed (owner hold on #3) =====
- Owner directive: commit current state, document #3 as separate note, wrap; new session reevaluates R4 outcomes + #3 + status, decides next.
- Wrapped: report.md (session17), session18/prompt.md (revalidation + #3 analysis; R not closed), pointer repointed to session18, this track distilled.
- R4/R5 CODE done + green (U1 e856760, U2 41cbe87, U3 f1050d8, U4 6157222, vocab 55135b4). R gate CRITERIA met but R held OPEN on the #3 architectural judgment.

## OLD U3 notes (superseded):
- U3 impl started (tree RED mid-unit, expected): widget new() → self.callbacks = default_callbacks() {on_limit_reached, after_submit, after_cancel = noop}; removed flat on_limit_reached default (emit_limit rewire pending). Next: rewire deliver/gate/emit_limit → self.callbacks; apply_config → self.callbacks (highlighter→ev kept); add _submit_default/_cancel_default/run_callback; keep UIC:cancel (console terminal_test uses it) + UIC:submit removal (only framework_submit called it); dispatch free-fn + tier-1 deletion; get_compy_input callbacks=widget.callbacks + boot reorder; console §6 patch; reset re-seed default_callbacks; rewrite old-behavior tests + add AC1-7,10.
