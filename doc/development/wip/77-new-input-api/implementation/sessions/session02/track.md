# session02 — track (M5c: the dispatch chain)

- [project] Boot (opus-sweeper PM). Read the mandate (`prompts/M5c-M8-sweep-mandate.md`), the
  authority chain, and the frozen `spec/M5c-dispatch-chain.md` end-to-end. Task: carve M5c into
  human-gated chunks along Scope 1–10, commission one chunk at a time, hold the gate between each.
- [project] Re-entrance guardrail: this session's own track was **missing** — the prior session02
  conversation (which commissioned + landed chunk 1) was interrupted by laptop battery discharge and
  never wrote `session02/track.md`. Recreated here on resume. `session01/track.md` is pure-M4 and left
  untouched (human ruling 2026-07-09: milestone tracks stay separate; don't append M5c to it).
- [project] Chunk 1 (`M5c-01-dispatch-chain`) — the four-tier dispatch chain — **landed and gated**
  before the interruption: commissioned to `prompts/M5c-01-dispatch-chain.md`, Sonnet implementor,
  Opus reviewer **APPROVE** (`reviews/M5c-01.md`, one non-blocking deferral flagged: the
  `active_keyboard_route()` accessor / `stop names the console` deviation → pointed at chunk 4) plus
  human review, committed (`b9bcc16 M5c reviews landed`). Suite green **744/0/0/6** (M4 baseline
  723/0/0/8; +21 live rows). Covers Scope 1, 2, 6[native-mechanism], 7[incremental AC-33], and the
  Scope-10 generic-callback rows (AC-36/AC-38).
- [project] The chunk carve had never been persisted as a first-class artifact — it survived only in
  the interrupted context + implicitly in the chunk-1 prompt's `## Boundaries` section. Promoted it to
  `implementation/M5c-chunk-plan.md` and **validated it against Scope 1–10**: 5 chunks, all inside
  M5c, nothing in Scope 1–10 unassigned. Order: 1 chain (done) → 2 widget-outputs (Scope 4) →
  3 submit-cancel (Scope 3) → 4 route-lifecycle (Scope 5) → 5 example-migration (Scope 6 turtle+maze).
  Scope 8/9/10 are cross-cutting (per-remark disposition by the owning chunk, not a chunk each).
- [project] Ordering rationale recorded in the plan: 2 before 3 (submit fires `on_text_entered` /
  reads `validator`, which chunk 2 establishes as settable slots); 5 last (migration needs the full
  surface). **Flagged seam:** chunks 3 and 4 both touch deactivate (submit-time vs route-level) —
  chunk-3/4 commissions must not silently re-scope each other.
- [project] Scoping clarified for the human: **turtle+maze migrate in M5c** (chunk 5), not M8 — design
  §5 sequencing constraint (their behaviour visibly changes with the new chain; deferring ships a
  window with misbehaving examples). **tixy+balloons** migrate in M8 (terminal milestone, legacy-globals
  removal). M7 = additive widget surface (`configure`/`clear`/cursor/`set_text`), no routing change.
  **`keyboard` example is never migrated** — pure-native, nothing to do (mandate guardrail 7 +
  M8-02-recut §81): it uses only native LÖVE callbacks, which survive as ordinary tier-3 participants;
  it never touched the legacy text-input globals.
- [project] Commissioned **chunk 2 (widget-outputs)** to disk (human asked; subagents NOT run):
  `prompts/M5c-02-widget-outputs.md` + `-review.md`. Scope = Scope 4 **non-submit half** + Scope 7
  allowlist widening; ACs **14, 15, 16, 42(a)**. Key seam pinned: `validator` + `on_text_entered` are
  **settable here** (AC-16, allowlist +4) but their **behaviour** (gate / submit delivery) is **chunk
  3** — a settability-forces-firing collision is an escalation, not a quiet pull-in. Meatiest impl
  piece = `is_at_limit` extension to two scopes (D-5, `userInputModel.lua:558`) with caller-regression
  guard (`editorController.lua:511-512`, view L308). Chunk 1 left a breadcrumb for exactly this at
  `consoleController.lua:349-352`.
- [behavioural] Human corrected my "chunks 2-4 are lighter than chunk 1" framing risk pre-emptively:
  honest per-chunk read given back — **chunk 2 lighter** (additive output layer, contained to the
  widget), **chunk 4 moderate** (route lifecycle, removes M4 ruling-1 forwarding), **chunk 3 is the
  heaviest remaining** (deletes `oneshot`, dissolves `push('userinput')` producer, submit/cancel
  semantics) — NOT lighter than chunk 1, just more localised.
- [behavioural] Human added REVIEW/TODO markers to **`src/controller/projectInputController.lua`**
  (chunk-1 code); read all 9. Disposition: **none affect chunk 2** (nothing touches the widget-output
  surface), **no real bug**. Buckets: (1) cosmetic/codestyle → final-pass, safe: L70, L77, L78, L97.
  (2) **L76 already satisfied** — `_dispatch` only reaches `_sink` on fall-through, non-issue. (3)
  **L66 + L117 (install natives as callbacks at activate): design-adjacent, NOT free** — activate()
  docstring L113-114 pins "No handler is copied onto compy.input"; materializing natives into callback
  slots must target an internal slot or it deviates from R7 → escalation. Leave pinned with that caveat.
  (4) **L141 + L142 (the `app_state ~= 'running'` → `Controller._defaults` forwarding) = chunk 4** —
  that branch IS the M4 ruling-1 forwarding Scope 5 removes; cite them in the chunk-4 commission, not a
  final pass.
- [behavioural] Human added several `-- REVIEW:` markers to `tests/input/input_contracts_spec.lua`
  (L230/401/495/508-510/536/578/629/659/671/714), flagged **non-blocking**. Read them: most are homed
  in later chunks — L401 prompt-labelling = **M7**; L495/508-510 console-as-hidden-sink musings =
  **chunk 4 route-lifecycle / console-migration follow-on**; L536 block-nav relocation = editor,
  kept-OPEN. Chunk-2 prompt instructs reconcile-only-widget-output-homed, leave the rest for their
  owning chunk (guardrail 4).
- [project] Chunk 2 implemented (`6a3215e` feat + `f280096` test expansion) and reviewed by
  **Antigravity** (independent experiment, not the standing Opus reviewer): `reviews/M5c-02.md`,
  verdict **CORRECTIVE-TAKE NEEDED** (3 findings). Human contested review quality; PM re-verified
  each finding against live code. **All findings substantively real**, verdict sound, but citations
  imprecise: (F2) `is_at_limit` body is 21 lines not "23" — still > 14 hard limit; (F3a)
  `userInputController.lua:322` REVIEW comment 173 chars not "175" — still > 64; (F3b) real 65-char
  line is `input_contracts_spec.lua:1229` not the cited 1245 (1245 is 63, compliant); (F1) slot-share
  proven for only 2 of 4 outputs — valid per review-trap-1 "all four". PM also caught what the review
  **missed**: trap 5 (`is_at_limit` caller-regression) never explicitly cleared — PM cleared it (up/down
  callers pass only `dir`, vertical path unchanged, no regression). Verdict on reviewer: competent on
  conclusions, weak on rigor — usable only with a cross-check pass.
- [project] **Human lifted the per-chunk gate for this session (2026-07-10):** PM authorised to
  orchestrate M5c-02c → M5c-05 → M7 → M8 **autonomously**, committing after each chunk/corrective take,
  human reviews post-factum in git. Fable-5 advisor reserved for genuinely hard design calls only. PM
  still escalates-by-documentation (surprise-first ledgers) rather than making silent in-slice rulings.
