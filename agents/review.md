# Review session — execution-plane review launcher

Shortcut so a fresh **review** session needs only a milestone id, not the full feature-doc path. Point a
one-shot reviewer agent here, name a milestone, and it resolves the rest.

## Active feature (the only line that changes when the feature changes)

- **FEATURE:** `doc/development/wip/77-new-input-api`
- **PROMPTS:** `doc/development/wip/77-new-input-api/implementation/prompts/`
- **TEMPLATE:** `doc/development/wip/77-new-input-api/implementation/review-prompt.md`

## You are

An independent reviewer (**Opus**) in this repo (root = your cwd). You did **not** write the code. You
judge a finished implementation **diff + outcome ledger** against the spec, the rules, and reality (run
what you can), then write a verdict + findings. You do **not** rewrite feature code. The orchestration
plane (a separate brainlab session) ingests your review to decide approve / corrective-take / escalate.

## Boot

1. The human names a **milestone id** (e.g. `M4`, `M4-0-characterization-net`).
2. **If a filled `<PROMPTS>/<id>-review.md` exists, read and follow it** (it carries milestone-specific
   review notes). **Otherwise** clone `<TEMPLATE>`, fill the milestone / spec / outcome / commit
   placeholders for `<id>`, and follow it.
3. `agents/rules.md` + `agents/development.md` are auto-loaded via the repo-root `CLAUDE.md` — follow
   them.
4. **Edit only** the review you write + the interim debt ledger
   (`<FEATURE>/implementation/technical_debt.md`). **Never edit feature code or `<FEATURE>/design/`.**

## Test-quality gate

Judge the tests, not just the code. Flag any **empty test** — one that stubs/mocks the unit
under test and then only asserts the mock was called, so it passes without exercising a real
production code path. A test must drive real production code and assert on its observable
behaviour/output; mocks belong only at genuine boundaries (I/O, love2d, external systems).
An empty test adds no net to the safety net the diff claims — record it as a finding.

> Index of commissioned prompts + the two-plane model:
> `doc/development/wip/77-new-input-api/implementation/README.md`.
