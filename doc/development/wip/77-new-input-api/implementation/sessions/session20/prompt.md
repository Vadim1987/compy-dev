# session20 — prompt

Read and strictly respect `agents/sessions.md`. You are inside `agents/validation.md`'s flow — do the
**boot ritual first** (read it end-to-end; confirm the suite baseline; run the re-entrance guardrail).

Baseline to confirm on boot: `busted tests` → **841 / 0 / 0 / 4** (the 4 pending are intentional; do
not "fix" them). A different count is a finding — record it and raise it before proceeding.

## Where the feature stands (one level up)
**Phase R is CLOSED and owner-accepted** (`affc932`). The commissioned phase is **TF2 — the owner's
human review of the split input suite**. At TF2's opening your predecessor (session19) found the ~138
stale `-- REVIEW:` markers too noisy to review cold, so the owner commissioned an **improvised pre-TF2
noise-cleanup**: inventory every marker, then sweep/triage the dissolvable ones in **owner-gated
batches (≤10)**. That cleanup is **in progress, not finished** — this is a mid-task session boundary,
not a completed handover. Read **`../session19/report.md`** for the full account — don't re-derive it.

Key durable artifacts (all under `../../../validation/`):
- `notes/review-marker-inventory.md` — the living per-marker ledger with dispositions.
- `reviews/S19-tests-triage-plan.md` — the carve: 4 governing decisions (all ruled) + the mop-up batch
  map (B-E ✅, **B-I in progress**, B-F, B-COV) with counts and per-marker recommendations.
- `notes/collapsed-gate-ledger.md` — the forward agenda for the collapsed B→C→D sitting; now holds
  **two** OPEN category-(b) finds surfaced by the sweep: **G-1** (console-hidden-sink safety) and
  **G-2** (project-handler API asymmetry: `compy.<event>` callback vs `compy.input.hooks[event]` hook).

**Carry, don't re-derive:**
- **We are at the *beginning of TF2*** — the marker triage is a sub-step inside it, not a separate
  phase. The governing tier (D1/D2/D5/D6) is ruled+applied; D3→ledger G-1, D4→deferred into TF2/TF3.
- **grep is the completeness authority; LSP is a second opinion** (cross-file method-ref misses seen).
- **Locate markers by content (grep), not by cached inventory line numbers** — header edits drift them.

## Your task — continue the noise-cleanup mop-up (owner-paced, interactive, OWNER-GATED)
Resume the batch grind exactly where session19 stopped. **Cadence (do not deviate):** present ONE
batch at a time with concrete before→after drafts + a recommended disposition per marker; get the
owner's rulings; then apply (edit + record each disposition in the inventory + `busted tests` green +
commit). **Never auto-advance to the next batch** — the owner picks it.

**Resume at B-I/2** (RVW-026/080/083/084/085/090/091/094 — cursor + nfr + routing headers). **Fold in
the D1 completeness leftover** recorded in the triage plan's B-I section: `input_routing_spec.lua:4-5`
still carries the old `ROUTE=consumer … SINK=last consumer` block D1 Pass B missed — B-I/2 already
edits that header (RVW-090/091/094), so rewrite it to the ratified route/widget vocab there.

After B-I/2: **B-F** (structural/grouping/relocate — decision-heavy) and **B-COV** (~22 coverage
calls), owner's choice of order. **Parked beyond the mop-up** (do not pursue unprompted): D3/G-1, D4,
and G-2 all ride into the collapsed sitting / TF2-TF3; the `src/` marker sweep (RVW-115..138) is a
deferred expansion the owner confirms *after* tests/ is swept; the deferred vocab phases (TD-actualize;
reference-doc completeness) remain.

**Do NOT** re-run the sweep or "re-verify" the feature; the suite baseline is the only unprompted
re-check. Gate discipline: iterate until explicitly approved; do not wrap early — and a real wrap is
the full ritual (track updated → report → this successor prompt), not a lone bookkeeping commit.

## Side-track anchor (keep the primary thread live)
The last substantive outcome is **B-I/1** (`8bc066f`, suite 841/0/0/4): fixture doc-hygiene, 6 markers,
with **RVW-003 escalated to gate-ledger G-2** (the mouse-vs-keyboard project-handler API coherence
gap). If the mop-up stalls or the owner redirects, that — and the still-open TF2 review of the split
suite — is the context to resume from, not any earlier governing-decision milestone.
