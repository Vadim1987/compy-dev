# session21 — prompt

Read and strictly respect `agents/sessions.md`. You are inside `agents/validation.md`'s flow — do
the **boot ritual first** (read it end-to-end; confirm the suite baseline; run the re-entrance
guardrail).

Baseline to confirm on boot: `busted tests` → **841 / 0 / 0 / 4** (the 4 pending are intentional;
do not "fix" them). A different count is a finding — record it and raise it before proceeding.

## Where the feature stands (one level up)
**Phase R closed + owner-accepted** long ago; the commissioned phase is **TF2 — the owner's human
review of the split input suite**, and inside its opening we are running an **owner-gated
noise-cleanup mop-up** of the ~138 stale `-- REVIEW:` markers (inventory → owner-paced batches
≤10). We are **at the beginning of TF2**, not past it. This is a mid-phase boundary.

**Predecessor (session20) — read `../session20/report.md` end-to-end; don't re-derive it.** It
completed **B-I/2** and, mid-batch, the owner expanded scope into a full **version-tag migration**:
the A/B/C/D bucket taxonomy was dissolved into LÖVE-style per-version availability vocabulary
(behaviour-availability fork — feature-new → `since 1.0.0-rc20260712`; pre-existing → untagged;
forward → "planned change"; NFR → guard label). Two commits (`8a6e95b`, `e254ae7`), suite
841/0/0/4 throughout. The judgment record is `validation/reviews/S20-version-tag-migration-key.md`;
the RVW-085 console-handling carve-out landed as a CONTESTED tech-debt entry (ties gate-ledger
G-1).

Key durable artifacts (under `../../../validation/`):
- `reviews/S20-version-tag-migration-key.md` — the migration key (bucket→tag map, carve-out).
- `notes/review-marker-inventory.md` — the living per-marker ledger with dispositions.
- `reviews/S19-tests-triage-plan.md` — the batch map (B-E ✅, B-I ✅, **B-F** + **B-COV** remain).
- `notes/collapsed-gate-ledger.md` — forward agenda; OPEN finds G-1, G-2.

## Your task — PART 1 (do first): revalidate the S20 version-tag migration
Predecessor output was **cognitive-heavy** (multi-step transformation + substantive judgment), so
your first job is to **check it**, per `agents/rules/revalidation.md` (work the full checklist).
Concretely, verify:
1. **Uniformity** — the bucket→tag transformation applied everywhere: grep confirms **zero
   `Bucket` refs** remain in `tests/input/`; each dissolved banner reads coherently.
2. **The RVW-085 carve-out is coherent** — the contested/status-quo test header, the
   `technical_debt/input.md` "Inspect-mode console-owns-surface (CONTESTED)" entry, and the G-1
   ledger row agree; the architecture claim (suspend/inspect spine) still matches code (spot-check
   `controller.lua` get_user_input, `consoleController.lua` suspend).
3. **wip-citation discipline held** — the new **persistent** docs (`conventions/code.md`,
   `technical_debt/input.md`) cite `internals/`/`decisions/`, **never** the `wip/` tree (this is
   the very rule ruling 8 promoted — a self-contradiction would be a real finding).
4. **Bookkeeping matches the tree** — inventory dispositions (RVW-026/080/083/084/085/090/091/094)
   and the triage-plan B-I status reflect what actually shipped.
Frame findings as a structured report (confirm clean / call out corrections with refs). **Make or
explicitly propose corrections; do not proceed to Part 2 without owner approval** (revalidation.md).

## Your task — PART 2 (after approval): resume the mop-up
Continue the **owner-gated** batch grind. **Cadence (do not deviate):** present ONE batch with
concrete before→after drafts + a recommended disposition per marker; get the owner's rulings; then
apply (edit + inventory disposition + `busted tests` green + commit). **Never auto-advance** — the
owner picks the batch. Remaining: **B-F** (structural/grouping/relocate — decision-heavy, incl. the
deferred **RVW-076**) and **B-COV** (~22 coverage calls). Owner's choice of order.

**Parked beyond the mop-up (do not pursue unprompted):** G-1/G-2 + D4 (collapsed sitting / TF2-TF3);
the `src/` marker sweep (RVW-115..138, owner-confirmed only after tests/ is swept); the deferred
vocab phases (TD-actualize; reference-doc completeness). **Do NOT** re-run the sweep or "re-verify"
the feature; the suite baseline is the only unprompted re-check. A real wrap is the full ritual
(track → report → successor prompt → repointed pointer), not a lone bookkeeping commit.

## Side-track anchor (keep the primary thread live)
The last substantive outcome is the **B-I/2 version-tag migration** (`e254ae7`, suite 841/0/0/4):
A/B/C/D buckets dissolved into per-version availability tags; RVW-083/084/085/090/094 resolved;
RVW-085 kept as a contested tech-debt carve-out; ruling 8 (canonical-docs comment rule) promoted to
`conventions/code.md` with a 2-violation src cleanup logged as tech-debt. If the mop-up stalls or
the owner redirects, that migration and the still-open TF2 review of the split suite are the context
to resume from.
