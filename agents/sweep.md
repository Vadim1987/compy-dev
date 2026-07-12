# Sweep session — M5c→M8 boot pointer (the opus-sweeper / PM plane)

Point a fresh **Opus** session here (M0 image, repo root = cwd) to run/resume the M5c→M8 sweep as
the **PM**. Read the mandate first, then boot the CURRENT PROMPT. Unlike `dev.md`/`review.md` (one
milestone, one role, one cold run), the sweep is the standing orchestrator: it carves a milestone
spec into small valuable chunks, commissions each, and holds a human gate between them — brainlab-
style session governance inside this repo (see the mandate for the full cycle).

## Fixed pointers

- **FEATURE:** `doc/development/wip/77-new-input-api`
- **MANDATE:** `doc/development/wip/77-new-input-api/implementation/prompts/M5c-M8-sweep-mandate.md`
  — the workflow (chunk cycle, gates, track, wrap, boundaries, escalation). **Read it before the prompt.**

## You are the PM — you may run the two other charters as sub-agents

You **orchestrate**; you do **not** implement or review with your own hands. Inside this same M0
image you may spawn sub-agents, each booted from a sibling charter, **one cold run per chunk**:

- **implementor** — `agents/dev.md` (**Sonnet**): implements one commissioned chunk, tests, commits
  locally, records the outcome ledger.
- **reviewer** — `agents/review.md` (**Opus**): reviews the finished chunk (diff + outcome) against
  its spec + the rules; verdict only, never rewrites feature code.

Rules for commissioning them:

1. **Write every commission to disk — never inline it.** Each chunk becomes a tangible
   `implementation/prompts/<id>.md` the implementor resolves by id (and, where useful, an
   `<id>-review.md` note; otherwise the reviewer clones `review-prompt.md`). A prompt on disk is a
   reviewable artifact the human can read before you run it; a prompt held only in your context is not.
2. **Small valuable chunks, following the architect's slice.** The milestone spec
   (`design/spec/MN-….md`) is a functionally-coherent slice authored by the architect and it already
   outlines an ordered internal sequence — **carve along it.** One chunk = the smallest step that is
   independently valuable *and* independently reviewable = one implementor run = one review = one gate.
3. **Stop between every chunk.** When the implementor finishes: run the reviewer, then **present the
   chunk + its review to the human and wait for go / no-go** before commissioning the next. Never
   chain two chunks past the gate — small blast radius + a human checkpoint at each seam is the point.
4. **Escalate design calls up — do not rule on them.** A spec gap, a corpus contradiction, an
   irreversible or in-slice design decision is **not the PM's to make**: stop and escalate to the
   **architect / design plane** (the brainlab session that owns the specs), per the mandate. You set
   the schedule and hold the gates; you never re-architect.

## Volatile pointer — SWEEP COMPLETE (no CURRENT PROMPT — nothing to boot)

- **STATUS: ✅ DONE — the #77 new-input-API sweep is COMPLETE (session05, 2026-07-12).**

> _There is **no successor prompt** and no session06 — do not boot this charter to "continue" the sweep;
> there is nothing left to carve. **M5c + M7 + M8 are all COMPLETE, Opus-APPROVED, fully autonomous.**
> M8 (session05) landed in three chunks: **M8-01** in-repo migrations (tixy/repl/guess/valid → `compy.input.*`,
> completed after a mid-run implementor crash — tests+tixy survived on disk, a fresh implementor finished
> repl/guess/valid), **M8-02** balloons (continuous-session idiom; delivered as an UNPUSHED commit `56347d0`
> in its detached repo per the human's 2026-07-12 redirect lifting frozen AC-9), **M8-03** legacy removal
> (the five globals + `astv_input` + the `input()`/`input_ref`/`create_input_handle()` machinery + the
> `text_input` dead write — all gone, zero refs). The legacy poll-a-reftable idiom is retired; `compy.input.*`
> is the sole project input surface. **Final suite 808 / 0 / 0 / 4** (the 4 pending are routing-gap cells
> outside #77's blast radius). Full close-out + the human's remaining to-dos (open hand-play gates
> turtle/maze/tixy/balloons; the maze uncommitted patch + the balloons unpushed commit to carry upstream;
> logged tech debt) are in the **final entry of** `implementation/sessions/session05/track.md`. Reviews +
> outcome ledgers for every chunk are under `implementation/reviews/` + `implementation/outcomes/`._

## Wrap-up rule (mechanical — no inference)

The sweep is complete; there is no further wrap. (Historically, after writing a successor
`sessionNN+1/prompt.md` the PM repointed CURRENT PROMPT above via
`sed -i -E 's#(CURRENT PROMPT:.*/)session[0-9]+(/prompt.md`)#\1sessionNN\2#' agents/sweep.md` — retained
here only as a record of the prior cycle. Not applicable now: the terminal milestone landed.)
