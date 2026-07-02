# Sweep session — M4→M8 boot pointer

Point a fresh **Fable** session here (M0 image, repo root = cwd) to run/resume the M4→M8 sweep.
Read the mandate first, then boot the CURRENT PROMPT. Unlike `dev.md`/`review.md` (one milestone,
one role, no session management), the sweep runs brainlab-style session governance inside this repo
— see the mandate for the full cycle.

## Fixed pointers

- **FEATURE:** `doc/development/wip/77-new-input-api`
- **MANDATE:** `doc/development/wip/77-new-input-api/implementation/prompts/M4-M8-sweep-mandate.md`
  — the workflow (session cycle, gates, track, wrap, boundaries). **Read it before the prompt.**

## Volatile pointer — the only line that changes between sessions

- **CURRENT PROMPT:** `doc/development/wip/77-new-input-api/implementation/sessions/session01/prompt.md`

## Wrap-up rule (mechanical — no inference)

After writing the successor `sessionNN+1/prompt.md`, repoint CURRENT PROMPT above. Only the session
number changes:

```sh
# replace 02 with the new session number
sed -i -E 's#(CURRENT PROMPT:.*/)session[0-9]+(/prompt.md`)#\1session02\2#' agents/sweep.md
```
