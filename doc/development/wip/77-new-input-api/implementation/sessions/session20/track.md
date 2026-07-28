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
