# session40 — clear the remaining S27 sprint in dependency order

Read and strictly respect `agents/sessions.md` and `agents/validation.md`. Boot normally:
this prompt, then `../session39/report.md` in full, then the session39 commissioning prompt
and track. Create `session40/track.md`; do not edit historical session artifacts.

## Plan locations and relationship — retain this context

The **current sprint plan** is
`doc/development/wip/77-new-input-api/validation/reviews/S27-triage-and-plan.md`.
It is the open descendant of the parent plan’s TF2 human-review phase, not the release plan.
The **parent release plan** is
`doc/development/wip/77-new-input-api/validation/plan.md`.
The plans are linked, never merged: clear the sprint → close TF2 → return to the parent’s
gated B/C/D collapse ruling → F → U → L → G (and E if that ruling leaves execution).

Read both plan locations before choosing work. Amend the operative sprint row in place whenever
a step changes; dated amendments explain why but are not the source of current status.

## Handoff state

P-17 maze/draw is code-complete through P-17-16; its cold review and owner-approved modifier
fix are in `../validation/reviews/S39-P17-cold-review.md` and `../reviews/P-17-04-triage-and-substeps.md`.
Its human smoke checklist is written but deliberately pending. P-18 keyboard is also code and
cold-review complete, pending human smoke. Do not reopen either without a concrete finding.

The recommended remaining-sprint order is:

1. **P16** — ready `paint` hook spelling, then obtain the one turtle Ctrl+Escape owner ruling.
2. **P19** — sapper deepfix: planning/owner review first; it is an author-owned semantic question.
3. **P13** — reduced harmony revalidation: prove a real combo end-to-end, then retire manual
   release handling only if the measurement supports it.
4. **P10** — remaining docs, ledger and vocabulary after code choices are settled.
5. **P11** — last: marker disposition, all example comment compaction, revalidation and slices.

P9’s diagnostic found no reproducing fault; treat formal closure as planning/accounting, not an
invitation to add a fix. Human smoke and P11 compaction are postponed until the end of the sprint.
P11 is owner-gated on its marker-disposition reading and is the largest remaining block.

Baseline: `busted tests` → 946 / 0 / 0 / 10. The 10 pending are sanctioned; an eleventh is a
finding. Never push. Commit locally by concern and state the suite in every commit. The owner’s
known untracked scratch must remain untouched; name every staged path. Nested repos have their own
