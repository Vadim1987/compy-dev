# session20 — report

**Task (per `session20/prompt.md`):** resume the owner-gated noise-cleanup mop-up at **B-I/2**
(RVW-026/080/083/084/085/090/091/094 + the D1 routing-header leftover). **What it became:** the
clear-apply half ran as planned; the decision-heavy half (083/084/085/090/094) pulled the owner
into designing a **version-tag convention** that dissolves the whole A/B/C/D bucket taxonomy —
scope the owner explicitly expanded in-session (decision (a)).

**Status: B-I/2 COMPLETE.** Suite green throughout: **841 / 0 / 0 / 4**. Two commits
(`8a6e95b`, `e254ae7`). The broader mop-up (B-F, B-COV) and TF2 proper remain — this is again a
mid-phase boundary, not a finished handover.

## What shipped

1. **B-I/2 clear-apply** (`8a6e95b`) — RVW-026/080 (drop stale split-provenance), RVW-091 (drop
   moot: verified no `paragraph X` citations survive in `tests/input/`), the **D1 leftover**
   (`input_routing_spec` ROUTE/WIDGET/SINK block → ratified route/widget vocab), + a consistency
   strip of the unmarked `routing:1` provenance.
2. **Version-tag migration** (`e254ae7`) — dissolved the A/B/C/D bucket banners into LÖVE-style
   per-version availability vocabulary. Resolves RVW-083/084/085/090/094. Zero `Bucket` refs left
   in `tests/input/` (grep-confirmed).

## The session's real yield — two judgment artifacts

- **The version-tag convention (owner-ruled 2026-07-28), fork = _behaviour-availability_.**
  Feature-new behaviour (absent from the `updev` baseline) → `since 1.0.0-rc20260712`; pre-existing
  behaviour → documented **untagged**; forward contracts → **"planned change"** (pending); NFR →
  **mechanism/guard** label. Anchored on `doc/input_api.md`'s existing `(supported since
  1.0.0-rc20260712)` style. Bucket→tag map, per-file work, and the RVW-085 carve-out are the
  durable record: **`validation/reviews/S20-version-tag-migration-key.md`**. Net: almost nothing
  here earns a fresh `since` tag — the bucketed groups characterize preserved / de-facto / NFR /
  not-yet-shipped behaviour, none feature-new.
- **RVW-085 / G-1 architecture assessment (verified in code).** Inspect-mode console-owns-surface
  is **architecturally load-bearing** — wired into `get_user_input()` (nil under inspect),
  `ConsoleController:suspend()` (physical `set_default_handlers` swap), and `evaluate_input()`
  (REPL in the paused project's env). So changing it reworks the suspend/inspect spine; **kept
  as-is** (not a stakeholder ask), recorded as **CONTESTED status-quo** in
  `technical_debt/input.md`. Reframe that narrows RVW-111: during a real *run* a hidden widget
  already falls through with no silent console consumption — the contested behaviour is only the
  inspect-mode debugger. No stakeholder deprecation round.

## Non-obvious points for a successor

- **The migration was smaller than the plan feared.** Bucket banners lived in only **routing**
  (Bucket A) and **nfr** (B/C/D); `input_events_spec` was already behaviour-named (no banners) — a
  single dangling "retired Bucket-D" prose ref was the only events touch (its RVW-076 marker left
  in place for B-F).
- **Persistent docs must stay free of `wip/` citations** — that is the very rule ruling 8 promoted
  into `conventions/code.md`. The new tech-debt + conventions entries cite
  `internals/user_input.md` / `decisions/input.md`, never the wip ledger. A revalidator should
  double-check this held.
- **The 4 `pending` cases are un-observable grid cells, not missing features** (keyrelease carries
  no text; editor disables selection; search-widget absent from the design corpus; touch has no
  consumer). Only editor-search is a genuine un-designed cell.
- **grep is the completeness authority** (carried standing rule) — used to confirm zero residual
  `Bucket` refs after the sweep.
- **Ruling 8 spawned a real follow-up:** 2 live `src/controller/` comments still cite wip paths
  (`consoleController.lua:~511`, `userInputController.lua:~8`) — logged as a comment-cleanup
  tech-debt item, NOT fixed in this comments-only pass.

## Where the successor resumes

Cognitive-heavy output → **revalidate the version-tag migration first** (`rules/revalidation.md`):
check the bucket→tag transformation applied uniformly, the RVW-085 carve-out is coherent, the
persistent-doc/wip-citation discipline held, and the inventory/triage-plan dispositions match the
tree. **Then**, on owner approval, resume the owner-gated mop-up at **B-F** (structural,
decision-heavy — incl. the deferred RVW-076) or **B-COV** (~22 coverage calls) — owner's pick.
Still parked beyond the mop-up: G-1/G-2 + D4 (collapsed sitting / TF2-TF3), the `src/` marker sweep
(RVW-115..138), the deferred vocab phases (TD-actualize; reference-doc completeness). Batch map in
`validation/reviews/S19-tests-triage-plan.md`; forward agenda in
`validation/notes/collapsed-gate-ledger.md`.
