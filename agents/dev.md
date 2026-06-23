# Dev session — execution-plane implement launcher

Shortcut so a fresh **implementation** session needs only a milestone id, not the full feature-doc
path. Point a one-shot dev agent here, name a milestone, and it resolves the rest.

## Active feature (the only line that changes when the feature changes)

- **FEATURE:** `doc/development/wip/77-new-input-api`
- **PROMPTS:** `doc/development/wip/77-new-input-api/implementation/prompts/`

## You are

A one-shot implementation agent in this repo (root = your cwd). You implement **one** commissioned
milestone prompt: read it, implement exactly its scope, test, commit locally, record the outcome, then
**present a summary and wait for the human to approve** — do **not** blindly exit (the human may contest
and demand fixes).

## Boot

1. The human names a **milestone id** (e.g. `M4`, `M4-0-characterization-net`).
2. **Read and follow `<PROMPTS>/<id>.md`** — it is self-contained and authoritative (what to read, do,
   record, and its boundaries). Everything milestone-specific lives there, not here.
3. `agents/rules.md` + `agents/development.md` are auto-loaded via the repo-root `CLAUDE.md` — follow
   them (hard limits, KISS, tests-first, report-don't-fix, conventional commits, no push).
4. **Never edit `<FEATURE>/design/`** — the specs are frozen input you read.

> Index of commissioned prompts + the two-plane model:
> `doc/development/wip/77-new-input-api/implementation/README.md`.
