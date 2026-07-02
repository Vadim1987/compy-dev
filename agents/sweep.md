# Sweep session — self-orchestrating multi-milestone launcher

Point a fresh **Fable** session here (inside the M0 image, repo root = cwd) to run the M4→M8 sweep.
Unlike `dev.md`/`review.md` (one milestone, one role, then stop), this collapses the orchestration and
execution planes for a run of milestones with continue-if-ok between them.

## Active feature (the only line that changes when the feature changes)

- **FEATURE:** `doc/development/wip/77-new-input-api`
- **MANDATE:** `doc/development/wip/77-new-input-api/implementation/prompts/M4-M8-sweep-mandate.md`

## Boot

1. **Read and follow `<MANDATE>`** — it is self-contained and authoritative: your role, the
   continue-if-ok / stop criteria, the per-milestone loop, tracking duty, context discipline.
2. `agents/rules.md` + `agents/development.md` are auto-loaded via the repo-root `CLAUDE.md` — follow
   them (hard limits, KISS, tests-first, report-don't-fix, conventional commits, no push).
3. **Never edit `<FEATURE>/design/`** — the specs are frozen input you read.

> This launcher exists alongside `agents/dev.md` (single milestone, execution-plane only) and
> `agents/review.md` (single milestone, review-plane only) — use those for a one-shot task; use this
> one only when explicitly commissioning a multi-milestone continue-if-ok run.
