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

## Volatile pointer — the only line that changes between sessions

- **CURRENT PROMPT:** `doc/development/wip/77-new-input-api/implementation/sessions/session04/prompt.md`

> _Note (session04 wrap, 2026-07-11): the pointer now names `session04` — the **autonomous** M7→M8
> sweep. **M5c is COMPLETE**: session03 landed chunks 3/4/5 (submit-cancel, route-lifecycle,
> example-migration) with two Opus corrective-takes (AC-29 highlighter leak; maze escape-cancel latch),
> all fully autonomous; suite 779/0/0/5. What remains is M7 (additive widget surface — carve it) then M8
> (legacy removal + tixy/balloons migration — **revalidate the frozen spec against the M5c+M7 ledgers
> before carving**). lua-lsp MCP is now **restored** (was down mid-session03). See the successor prompt
> for the standing authorization, the proposed M7 carve, the sub-agent run mechanism, and the Fable-5
> advisory rule._

## Wrap-up rule (mechanical — no inference)

After writing the successor `sessionNN+1/prompt.md`, repoint CURRENT PROMPT above. Only the session
number changes:

```sh
# replace NN with the new session number (e.g. session04)
sed -i -E 's#(CURRENT PROMPT:.*/)session[0-9]+(/prompt.md`)#\1sessionNN\2#' agents/sweep.md
```
