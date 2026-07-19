# session14 — prompt

Boot per `agents/validation.md` ritual (read it end-to-end first: baseline `busted tests` →
815/0/0/4, foundation reads, create `session14/track.md`). Then read your predecessor's report
**and** its commissioning prompt:

- Predecessor task (S13): orchestrated **DI1** — the doc-A fidelity audit. Commissioning prompt:
  `sessions/session13/prompt.md`. Outcome report: `sessions/session13/report.md` (read in full).
- DI1 deliverable of record: `validation/outcomes/DI1-docA-fidelity.md` (per-section verdict
  table; the two Sonnet evidence dossiers are `validation/outcomes/DI1-{a,b}-evidence.md`).

## Taskflow (per the ratified plan's recommended layout: S14 = DI2 sitting + DI3 execution)

DI1 produced **cognitive-heavy** output that DI2 will rule on and DI3 will execute against — so it
must be **revalidated before it is built upon**. Your session runs three things, in order:

1. **Revalidate DI1** (`agents/rules/revalidation.md` — work its checklist). One level up: DI1
   judged doc A (`notes/input-contracts.md`) against shipped code (never the suite — circularity
   guard) and concluded its outcomes are still-true but its mechanism/forward tags are pervasively
   *superseded-by-shipped*, its content almost entirely already-homed in the corpus (dominantly
   `internals/user_input.md`), with **four positive doc-A claims now demonstrably FALSE** and a
   thin `unique-no-home` residue. Your job is to **check** that: spot-check the verdict table
   against code (especially the four FALSE-claim findings and any `unique-no-home` row DI3 would
   act on — LSP for symbols, grep as the backstop), confirm the circularity guard truly held, and
   confirm no doc-A section was silently skipped. Report findings clearly (confirm clean / call out
   corrections with refs). **Do not proceed to DI2 without owner approval of the revalidation.**

2. **DI2 — owner ruling on promotion form (OWNER-GATED, interactive).** Present the three options
   with DI1 evidence attached: (a) promote a re-baselined doc A as a new corpus doc; (b) merge
   surviving unique content into existing corpus homes, doc A stays a frozen wip record; (c) no
   promotion — reword the ~30 clause refs to cite behaviour/corpus. DI1's evidence supports **(b)**
   and rules out (a) (promoting whole would import inverted tags + four false claims); (c) largely
   collapses into (b) since content is already homed. **Do not rule this yourself — gather,
   present, wait.** Record the ruling on disk immediately (anti-rubber-stamp discipline).

3. **DI3 — execute the ruling (Sonnet mechanical under your orchestration).** Per the ruling:
   content moves/merges (the thin `unique-no-home` residue — chiefly §9-item-3, the sink-as-default
   silent-disable of `on_limit_reached` → `technical_debt/input.md`, plus a one-liner for §9-item-2
   → `internals/user_input.md` "Dispatch chain"); re-run the A1 retarget over the doc-A citation
   family (~30 refs incl. `input_fixture.lua`'s "doc A" definition and the `design.md §4` sibling —
   see `validation/outcomes/A1-spec-ref-sweep.md` inventory); **refresh `tests.md` facts** (the
   recorded drift: "808"→815, pending line numbers 101/153/161/222 → 118/172/185/246). Doc A itself
   stays **unedited in place** regardless of outcome; `design/` stays frozen. The ~25 non-doc-A
   inventory refs are **NOT absorbed** — they stay Phase C evidence. Suite green (815/0/0/4) after
   every unit; commit unit-sized.

Model economy: revalidation + DI2 presentation are your (judgment-tier) work; DI3 is Sonnet
(spawn explicitly with `model: sonnet`, hygiene a/b/c/d each spawn). Fable is **not** required
before the Phase D sitting. Standing gates unchanged (jargon, Phase D, `wip/77` deletion).

## Carryover (primary thread, so it stays live context)

The validation phase's mandate and boundaries are in `validation/plan.md` (amended + ratified
2026-07-19: DI/TF gate inserted between A and B; Phase B is gated on DI+TF and *consumes* DI1's
verdict table). Phase order after DI/TF: B (convergence check) → C (principle sheet + disposition
table) → D (owner sitting) → E (execution) → F (final revalidation) → G (PR assembly). The
strategic frame (owner): the PR must be reviewable from `doc/input_api.md` + the PR description
alone; no moving parts beyond "simpler, more robust input API" without a one-line justification.
