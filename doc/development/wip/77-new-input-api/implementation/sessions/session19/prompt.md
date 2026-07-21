# session19 — prompt

Read and strictly respect `agents/sessions.md`. You are inside `agents/validation.md`'s flow — do the
**boot ritual first** (read it end-to-end; confirm the suite baseline; run the re-entrance guardrail).

Baseline to confirm on boot: `busted tests` → **841 / 0 / 0 / 4** (the 4 pending are intentional; do
not "fix" them). A different count is a finding — record it and raise it before proceeding.

## Where the feature stands (one level up)
**Phase R is CLOSED and owner-accepted (2026-07-21), committed `affc932`.** Your predecessor
(session18) analyzed the one open architectural issue — the input widget reading `love.state.app_state`
to scope submit/cancel — and, with the owner, resolved it via **option E** (the editor consumes
Enter/Escape upstream; `allow_modify` becomes a constructor flag; `UserInputController:keypressed` runs
one uniform path with no global-mode read). That landed alongside the **R3 fold-in** (the ratified
redesign folded into `decisions/input.md`; all `wip/`-tree references swept out of the persistent
corpus + tests so the docs are self-contained ahead of `wip/` deletion). Read
**`../session18/report.md`** for the full account — don't re-derive it. Key durable artifacts:
`../../../validation/reviews/S18-post-R-replan-reconciliation.md` (the post-R state analysis) and
`../../../validation/reviews/S18-uic-fork-options.md` (why option E).

**Two things to carry, not re-derive:**
- **LSP (`lua-lsp`) was unreliable all of session18** — phantom / out-of-range refs. Use **grep as the
  ground-truth completeness backstop** until you confirm the tool is healthy again. Re-verify LSP
  before trusting its refs.
- **The standing "post-R replan" carryover has FIRED and been discharged** (R closed; the sealed
  `../../../validation/notes/post-R-replan-hypothesis.md` was read and reconciled). It is **retired** —
  do not copy it forward. Its conclusion: the hypothesis (B/C/D can collapse) survives *amended*, but
  its confirmation is gated on TF2/TF3 (below), which are the last unknowns. See the reconciliation doc.

## Your task — Phase TF2 (owner-paced, interactive, OWNER-GATED)
Per plan.md (`../../../validation/plan.md`, Phase TF, lines 135-160) the next phase is **TF2 — the
owner's human review of the split test suite**, which was deliberately deferred to resume *after* Phase
R (the reshape changed the very files TF2 would review; reviewing earlier meant reviewing
soon-to-be-renamed code twice). TF1 (the mechanical split of `input_contracts_spec.lua` into
human-reviewable files) is DONE.

- **TF2 is interactive and owner-gated — never start it unprompted.** Confirm the owner wants to begin,
  then walk the split input-suite *against the validated persistent docs* (`decisions/input.md`,
  `internals/user_input.md`, `input_api.md`) with the owner. **Record every hint the owner raises to
  `../../../validation/notes/`** (materialization — hints are the input to TF3). Do not "fix" as you go:
  mechanical fixes and judgment items are triaged in TF3, not mid-review.
- **TF3 follows** (hint-scoped fidelity re-check — NOT a re-audit; guardrail 1 stands): mechanical
  fixes land per hint; judgment items pool with A2's two standing fixture-architecture questions
  (wrap-native helper; play-mode fixture) into one triage list, ruled in the same sitting as TF2 where
  possible. The absorbed-by-redesign bucket is expected **near-empty** (R executed ahead of TF2/TF3).
- **After TF2/TF3:** the owner has already signalled the intended path — adopt the reconciliation's
  **collapsed B→C→D** over the known short list (category-(a) rows R2/R4/R5/C1 — each with a drafted
  disposition in the sealed note; R2 partially advanced, `eval` now documented — plus the postponed
  jargon cluster + any small TF3 leftover), rather than the full multi-phase sitting. This stays the
  owner's call to confirm with fresh eyes once TF2/TF3 are in.

**Do NOT** re-run the sweep or "re-verify" the feature (guardrail 1); the suite baseline is the only
unprompted re-check. Gate discipline: iterate until explicitly approved; do not wrap early.

## Side-track anchor (keep the primary thread live)
The last substantive outcome is **R-close via option E + the R3 fold-in** (commit `affc932`, suite
841/0/0/4) and the **post-R reconciliation** (owner ruled: accept R, TF2 next). If TF2 stalls or the
owner redirects, that closed-R state — not any earlier milestone — is the context to resume from.
