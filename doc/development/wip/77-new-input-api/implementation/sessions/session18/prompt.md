# session18 — prompt

Read and strictly respect `agents/sessions.md`. You're working inside `agents/validation.md`'s
flow (boot ritual first: read it end-to-end, confirm the suite baseline). Your predecessor
(session17) executed **Phase R4/R5** — the ratified input-API redesign — tests-first, and
committed U1–U4 green. Read `../session17/report.md` for the full account; don't re-derive it.

Baseline to confirm on boot: `busted tests` → **827 / 0 / 0 / 4** (815 + the 12 acceptance-
criteria anchors in `tests/input/input_redesign_ac_spec.lua`; the 4 pending are intentional).

## State of play (one level up)
- The redesign shipped: dumb 3-consumer project route (`shortcuts → hooks → widget`,
  free-function `dispatch`); tier-1 deleted; submit/cancel are the widget's own callback-driven
  business (stays-open default, `before_cancel` veto, Enter/Escape shadowable); `is_shown()` is
  a strictly-internal flag; `compy.input.callbacks` IS the widget's own table; vocabulary and
  persistent docs (`input_api.md`, `internals/user_input.md`, `technical_debt/input.md`) resynced
  to `shortcuts`/`hooks`/`widget`.
- Three owner design rulings drove it (see `../../../validation/reviews/R4-U3-callback-model.md`).
- **Phase R is NOT closed.** The owner is holding it pending analysis of one open architectural
  issue (below).

## Your task (revalidation + open-issue analysis; owner-paced, interactive)
Work `rules/revalidation.md` over session17's R4/R5 outcomes — re-examine the commissioning
intent (delta-design + delta-spec) against what actually shipped, with fresh eyes, and surface
anything that drifted. Then, specifically:

1. **The open issue — UIC reads `app_state` to scope submit/cancel.** Full write-up (concern,
   exact line numbers, why it exists, blast radius, options A/B/C/move-it-out):
   `../../../validation/reviews/R4-open-issue-uic-mode-leak.md`. The owner's read: it's an
   abstraction leak (UIC altering behavior by global context) — "should probably be a feature
   flag toggled by the parent, or the whole code belongs in the wrong place." **Nothing is
   functionally broken** (suite green; all three widgets correct; only a cosmetic console no-op
   `_submit_default` on Enter). Analyze it properly and decide the fix **with the owner** — do
   not pre-commit to A/B/C; the owner explicitly wants this re-opened and re-thought (the parent
   configuring the widget, or moving the mode-fork out of UIC entirely, are live options).
2. **Reanalyze project status + any new findings** the redesign surfaced, and decide with the
   owner whether Phase R can then close, or what remains.
3. **Two non-blocking flags carried forward:** (a) `src/examples/balloons` (untracked nested
   repo) was migrated to the new API in its own working tree — the owner commits that in
   balloons' own repo, not here; (b) the cosmetic console no-op above.

Do NOT start TF2 (owner-paced, explicitly not triggered until R closes and the owner directs).
Gate discipline: iterate until explicitly approved; do not wrap early.

## Note on the plan
`../../../validation/plan.md` Phase R's gate lists suite-green + ten ACs + rename-complete +
no un-dispositioned "resolved" REVIEWs — all MET. The reason R stays open is the owner's
architectural concern above, which is a *judgment* hold, not a gate-criterion miss. Reconcile
the plan's R-gate wording with this reality as part of your revalidation (amend it with the
owner if warranted, following its dated-append convention).

## Standing carryover — do not drop until it fires (owner + Fable, 2026-07-20)
There is an unresolved replan trigger from outside this session's task chain:
`../../../validation/notes/post-R-replan-hypothesis.md` — an unrated note
proposing that Phase B/C/D can collapse to a short pass once R is genuinely closed, written
*before* the UIC `app_state` issue above surfaced. **It is stale as written** — it doesn't
account for that issue, which is itself a new scaffolding-suspect the note's own falsification
condition anticipates.

**Rule: if Phase R closes in this session** (the open issue above gets an owner-approved
disposition), **read that note before taking any step toward TF2.** Reconcile it against
however the issue was resolved — fold it in as a cheap fifth known-item if the fix was small
and mechanical (in the shape of R2/R4/R5), or treat it as a real Phase-B-shaped question if
not — then decide with the owner whether to run the collapsed B→C→D pass the note proposes or
the plan as originally written. This is a decision for the owner to make with fresh eyes on
the actual closed-R state, not something to pre-empt here.

**Rule: if this session wraps without Phase R closing** (the open issue is still unresolved),
copy this entire "Standing carryover" section, verbatim, into the successor session's
`prompt.md`. Do not paraphrase, shorten, or drop it "since nothing happened yet" — repeat this
same block in every successor prompt until the trigger condition above actually fires in some
session. Once it fires (R closes, note gets read and reconciled), retire this section from
that point's successor prompt — it has done its job.
