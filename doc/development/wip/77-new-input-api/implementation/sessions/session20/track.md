# session20 — track

## Boot (2026-07-22)
- Booted via `agents/validation.md` → session20/prompt.md. Read sessions.md, validation.md,
  session19/report.md, S19-tests-triage-plan.md.
- Re-entrance guardrail: neither track.md nor report.md present → **fresh start**.
- Baseline: `busted tests` → **841 / 0 / 0 / 4** ✅ (matches prompt; 4 pending intentional).
- HEAD `6a196a8` (session19 wrap). Working tree: owner scratch untracked (per guardrail §3), plus
  `M agents/validation.md` (pointer already at session20).
- **Task:** resume noise-cleanup mop-up at **B-I/2** (RVW-026/080/083/084/085/090/091/094) +
  fold in D1 leftover `input_routing_spec.lua:4-5` (ROUTE/WIDGET/SINK block). Owner-gated, one
  batch, present before→after drafts + recommended dispositions, get rulings, apply, suite, commit.

## B-I/2 analysis (2026-07-22, pre-presentation)
- Located all 8 markers by content (lines drifted from inventory): cursor:1 (026); nfr:1 (080),
  25 (083), 26 (084), 53 (085); routing:18-19 (090), 20 (091), 23 (094). D1 leftover = routing:3-5
  ROUTE/WIDGET/SINK block (still `ROUTE=consumer … SINK=last consumer`).
- **Facts:** RVW-091 MOOT — no `paragraph X` refs remain in tests/input; headers cite named
  sections already. RVW-094 buckets still LIVE (routing:36, nfr:33/79/98/175). Stale root-owned
  `.input_nfr_forward_spec.lua.swp` (Jul 19) — leave, note only.
- **Shape of batch:** decision-heavy (unlike B-E/B-I/1). Clear-apply: D1-leftover(RENAME),
  026+080(DROP provenance), 091(DROP moot). Genuine rulings: 083, 084, 085, 090, 094.
- **Consistency catch:** routing:1 also opens `split from input_contracts_spec.lua (TF1)` — not
  separately marked, but if 026/080 provenance is dropped, routing head needs same for consistency.
- **Entanglement:** 084/085 = promote "provisional/expected-to-change" → invariant/decisions;
  header itself says OWNER-RULING-PENDING; 085's test (`inspect: console owns surface`) ties to
  G-1 (console-surface-ownership). Flag — may belong in collapsed sitting, not mechanical mop-up.

## B-I/2 clear-apply DONE (2026-07-28)
- Owner ruled: **apply 1-4, revisit other rulings afterwards.**
- Applied: D1 leftover (routing ROUTE/WIDGET/SINK → ratified route/widget); RVW-026 (cursor
  provenance DROP); RVW-080 (nfr provenance DROP, own instruction); RVW-091 (routing DROP, moot);
  + consistency strip of unmarked routing:1 provenance.
- Dispositions recorded in inventory (026/080/091) + triage plan (D1 leftover + B-I/2 status).
- Suite 841/0/0/4. Committing this unit.
- **STILL OPEN (owner to revisit):** RVW-083/084/085/090/094 — presented, awaiting rulings.

## Owner rulings on the version-tag convention (2026-07-28)
- **Fork settled: behaviour-availability.** Feature-new behaviour (absent from updev baseline) →
  `since 1.0.0-rc20260712`. Pre-existing behaviour → documented, NO tag attribution.
- **Decision (a) accepted** — fold 094 in: full cross-file bucket→version-tag migration.
- **Console handling (G-1/RVW-085) — owner ruling:** do NOT change it (no stakeholder request).
  If we judge it wrong → track as tech-debt + optionally a pending test for *proper* behaviour +
  mark existing behaviour contested/disputable. Deprecation would need a stakeholder round; owner
  won't open one on a tangential issue unless it changes architecture dramatically. Owner asked:
  does it?
- **4 pending cases (answer):** all in input_routing_spec — :81 keyrelease→console, :145
  pointer→editor, :158 keys→search widget, :224 touch→active route. All un-observable grid cells
  (release carries no text; editor disables selection; search absent from design corpus; touch has
  no consumer), NOT shipped-but-broken features. (search-widget is the one genuine design gap.)
- **Architecture-blast verdict (verified in code):** inspect-console-ownership lives in the
  suspend()/set_default_handlers/get_user_input/evaluate_input spine — changing it IS
  architecturally significant, not a routing tweak. So keep it; the doc already calls it
  "characterized status quo, not a ratified contract." RVW-111's "silent sink" fear is narrower
  than stated: during a real RUN a hidden widget already falls through (no console consumption);
  the contested behaviour is only inspect-mode debugger ownership (REPL in paused project's env) —
  arguably correct-by-design.
- **NEXT:** write tag-key doc (mapping + RVW-085 carve-out + tech-debt entry) → owner OK → execute
  (a) migration + fold in ruling 8.

## B-I/2 version-tag migration EXECUTED (2026-07-28)
- Owner: docs/comments only, no code, no intermediate approval needed ("if messy I'll tell you").
- Judged this a readability/design-intent pass (contested carve-out, prose quality owner flagged)
  → did it in-session rather than delegating; key doc materialized for the record.
- Wrote key: `validation/reviews/S20-version-tag-migration-key.md`.
- Applied: routing Bucket A dissolved; nfr Bucket B/C/D dissolved + top describe renamed; events
  dangling "retired Bucket-D" ref stripped (RVW-076 marker itself left for B-F). RVW-085 → contested
  status-quo header + `technical_debt/input.md` "Inspect-mode console-owns-surface (CONTESTED)".
  Ruling 8 → `conventions/code.md` "Comment References" + tech-debt wip-citation-cleanup follow-up.
- **grep confirms zero `Bucket` refs remain in tests/input.** Suite 841/0/0/4.
- Dispositions recorded: inventory (083/084/085/090/094) + triage plan (B-I/2 COMPLETE).
- IMPORTANT: kept persistent docs free of wip/ citations (the very rule ruling 8 enforces) —
  tech-debt/conventions entries cite internals/decisions, not the wip ledger.
- **Remaining mop-up (owner picks order):** B-F (structural, decision-heavy), B-COV (~22 coverage).
