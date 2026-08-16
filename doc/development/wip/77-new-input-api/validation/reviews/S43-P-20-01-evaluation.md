# P-20-01 — session43's evaluation of the session38 outcome review

The worker's report is `../outcomes/S43-P-20-01-session38-outcome-review.md`.
This is the parent session's judgement of it: what I verified myself, what I
accept, and what I add.

## Verdict: session38 stands. It is not the P13 failure mode.

The distinction that matters is **disclosure**. P13's fixture faked a mechanism
(`love.event.push` dispatching synchronously) and the session then claimed an
end-to-end proof it did not have. Session38's harness also short-circuits the
event loop — it calls `ProjectInputController` directly, skipping queue → pump →
`love.keypressed` and the route's error boundary — but it **says so**, in three
separate "Limits" sections across its review chain, and hands the end-to-end
half to the human smoke gate. A stated limit is not a false proof.

## Verified independently (not taken from the worker)

- **Re-ran the harness myself** at `keyboard` HEAD `e568961`: `run_up.lua` vs
  `run_new.lua`, 108 stimuli each, **zero diff**. The claim reproduces.
- **The harness copies the combo builder.** `drive_new.lua:9-27` reimplements
  `combo_string` / `any_mod` verbatim rather than calling production's. Compared
  against `controller.lua:382-424`: identical today, so the result is sound —
  but it is a copy, and a copy is where the next fidelity gap would open. Noted
  in the harness README as the first thing to check if it ever disagrees.
- **F1's timing, on git timestamps rather than file mtimes** (the worker used
  mtimes, which survive nothing): `e568961` committed 20:51:45, the narrow
  review committed 20:52:10, the close-out `84b6e0c5` at 20:52:28. The review's
  *content* predates the fix; the review's *commit* trails it by 25 seconds.
  So the branch's last behavioural commit was indeed never read by an
  independent pass, and calling it "the reviewed head" overstates what happened.
  **F1 upheld at S2.** No defect resulted — I reproduced zero-diff against that
  very commit — so it is a process finding, not a code one.
- **The no-platform-code claim** holds: `git log dd7a7548~22..dd7a7548
  --name-only -- src/ tests/` is empty.

## What I add — the finding the worker did not draw

**S2 — the evidence for the strongest claim in this step lived in `/tmp`.** The
harness was in a session-scoped scratchpad from 2026-08-12, referenced by the
reviews but never materialized into the workspace. Hygiene (c)
(`agents/validation.md`) exists for exactly this: an artifact that is not in the
workspace is gone when the context rolls. Worse than losing a chat log — the
PR's parity claim would have become unreproducible by any reviewer, including
us, and nobody would have noticed until someone tried.

**Resolved in place:** preserved at `../notes/S38-parity-harness/` with the
absolute `dofile` paths made relative, a README stating provenance, how to run
it, and precisely what it does and does not prove.

## Accepted as-is

**F2 (S3) — "provably identical to upstream" oversells.** The report's own body
self-corrects eighty lines later ("nothing in this work has ever run in a game
scene"). Wording, not a false claim. It matters only if that headline reaches
the PR description, where a stakeholder would read it without the limits — one
to watch when the description is assembled, not to fix now.

## Not re-checked

Real event-loop parity and the Android build — the container has no display and
no input device, which is the same boundary session38 named and handed to the
human smoke gate.
