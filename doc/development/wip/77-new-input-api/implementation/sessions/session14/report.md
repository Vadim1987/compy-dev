# session14 — report

**Task:** (1) revalidate DI1 (the doc-A fidelity audit — cognitive-heavy predecessor output);
(2) DI2 owner ruling on doc-A promotion form; (3) DI3 mechanical execution. Mid-session the owner
added a **Phase-A tactical amendment** (reference stabilization) ahead of TF.

**Outcome: DONE, committed locally.** All work green against suite baseline **815/0/0/4** throughout.

## What happened, in order

1. **DI1 revalidation — CLEAN.** Re-verified every load-bearing claim in code myself (not trusting
   the deliverable): all four "demonstrably FALSE doc-A claims" hold, both `unique-no-home` survivor
   facts are real, the circularity guard held (doc A judged vs `src/**`, never the suite), no doc-A
   section was skipped, and the `tests.md` drift target was accurate. No corrections needed. Owner
   accepted before DI2.
2. **DI2 ruling (owner): option (b) — merge survivors, doc A frozen in place.** Recorded with a
   resolution index: `validation/notes/DI2-ruling-and-resolution-index.md` (DI1 Axis-2 homes × A1
   citation inventory → a per-citation retarget map, so DI3 followed mapped paths, not re-discovery).
3. **DI3 (Sonnet, verified + committed):** merged the two survivor facts into the corpus
   (`internals/user_input.md` 'starting'-state line; `technical_debt/input.md` on_limit_reached
   silent-disable coupling); retargeted ~28 doc-A citations to named corpus sections; refreshed
   `tests.md` (808→815, pending lines → 124/186/199/265). Doc A untouched; `design/` frozen.
4. **Reference stabilization (Phase-A tactical amendment — owner-directed):**
   - **RS1:** normalized all 210 bare corpus citations in tests/src → repo-root-relative
     `doc/development/...` (bare form only resolves inside `doc/development/`).
   - **RS2:** annotated ~20 opaque ephemeral `{badspecref:}` refs with a one-line meaning gloss +
     source-quoted decode-map, **keeping every wrapper** (evidence). `{jargon:}` untouched (TF task).

## Non-obvious points (what a successor must not miss)

- **The DI/TF gate is only half-closed.** DI (doc integrity) is fully done; **TF (test fidelity) is
  NOT started** — the owner explicitly deferred it to stabilize comment references first. Phase B
  (convergence) is gated on **DI + TF both accepted** (`validation/plan.md` line 132).
- **Interim refs are KEPT, not resolved.** The ~25 non-doc-A ephemeral refs (milestone marks,
  review-doc pointers, ratified-model/scope items) remain as **Phase-C evidence** — RS2 only made
  them *legible* (additive glosses). This is plan-consistent; do not "finish the job" by resolving
  them without an owner ruling. Marker convention: `{badspecref:}` = owner's bad-ref flag (our
  targets); `{jargon:}` = leave for a TF-phase term-explanation task.
- **RS2 glosses are freshly-authored context TF will lean on.** I spot-checked the load-bearing
  decodes (A5, E30/C23, ratified-model R11/ruling-3, M8-01) against source — accurate — but TF
  should sanity-check glosses as it reads test intent; a wrong gloss would mislead exactly the
  review TF performs. Full decode-map with sources: `validation/outcomes/RS2-annotate.md`.
- **Four FLAGGED refs left as-is (owner-agreed):** the empty `{badspecref:}` (owner's own
  convention meta-comment), `#77`/`this feature`/`#77's blast radius` (feature self-refs — wording
  nits, fold into the TF `{jargon:}` pass), `m7 design session` (no pinnable doc exists).
- **Three DI1 open findings still carried to TF** (from the validation map): editor
  keypressed-vs-textinput coverage gap; the §5.8 search `pending`; the `F.reset()` 14-line breach.

## Artifacts of record

`validation/notes/DI2-ruling-and-resolution-index.md`, `validation/reviews/ref-stabilization-2026-07-19.md`,
`validation/outcomes/{DI3-execution,RS1-normalize,RS2-annotate}.md`, prompts in `validation/prompts/`.
Commits: `62022fe` `a89fbf4` `a54558c` `7b7f2f2` (DI) · `47d92f0` (RS1) · `2fac6f3` (RS2) ·
`bf135ed` (RS bookkeeping) · `e868457` (owner: examples).
