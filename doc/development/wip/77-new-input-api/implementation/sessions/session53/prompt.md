# session53 — revalidate `doc/input_api.md` improvements and `ARC-02`

Read `agents/sessions.md` and `agents/validation.md` first. Then the predecessor reports
[`../session52/report.md`](../session52/report.md) and
[`../session51/prompt.md`](../session51/prompt.md).

Baseline: **990 / 0 / 0 / 10**.

## Your task

Run a thorough **revalidation** via cold-agent inspection / sub-agents covering two targets:

1. **Proofread and revalidate session52's changes to `doc/input_api.md`** (`50380a00`):
   - Verify cognitive friendliness, clarity, formatting, and technical precision of the new `Vocabulary` section and `Dispatch chain` diagram.
   - Confirm no terminology or concept drifts from codebase facts (`src/controller/projectInputController.lua`, `doc/development/internals/user_input.md`).

2. **Re-execute the `ARC-02` revalidation mandate** (re-requesting the task from `session51/prompt.md` which was incomplete):
   - Work the six checks of `agents/rules/revalidation.md` against the ten `ARC-02` commits: `b325826d` `ef20466a` `af1e8ec6` `7b927249` `191e28c3` `cad0bb25` `3bade47a` `e4748e60` `ddfe8be0` `ee59ccdc`.
   - Verify the 3 judgment calls (malformed cursor shapes raise, `cursor = false` as unset, Decision 35 text alignment).
   - Verify cross-references across `doc/input_api.md`, `internals/user_input.md`, `decisions/input.md`, `technical_debt/input.md`, and `CHANGELOG.md`.
   - Verify integrity of deletions (`re_show`, `state.pending`, `consume_pending`, `stash_hidden_configure`, `PER_SHOW_KEYS`, `live` table).
   - Check `BUG-01-09` status.

This is **research + analysis** (revalidation mode). Report findings cleanly and materialize review artifacts on disk.
