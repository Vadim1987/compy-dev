# Sonnet worker — Job B ONLY: wip-reference sweep (resume of an interrupted task)

You are a Sonnet worker under the session18 orchestrator, feat #77, LÖVE2D at `/repo` (cwd `/repo`).
**Docs-and-test-comments-only task.** Do NOT touch any `.lua` under `src/`. In `tests/`, touch
**ONLY comments** — never an assertion, never any code. If a count changes you touched code: STOP.

## Context — why this task exists
The whole `doc/development/wip/77-new-input-api/` tree (all `delta-*`, `validation/*`, session dirs)
is **deleted before the PR and not included in it** — so every reference from a *persistent* doc or a
test into `wip/` will dangle. A prior worker already completed **Job A** (folding the ratified redesign
into `doc/development/decisions/input.md` — Decisions 2/5/6/7/8/10 revised, Decision 14 added, vocab
swept). **Job A is DONE and verified — do not touch `decisions/input.md`.** Your job is **Job B only**:
repoint every remaining wip/ephemeral reference in the persistent docs + tests to a persistent home.

## The exact remaining references (grep-confirmed by the orchestrator)
Fix every one of these; then grep-prove none remain.

**`doc/development/technical_debt/input.md`**
- ~:530 heading "...(RESOLVED by option E, 2026-07-21)" — drop the ephemeral "option E" label; keep the
  date + resolution meaning (e.g. "RESOLVED — the `app_state` fork was removed, 2026-07-21").
- ~:539 body pointing to `validation/reviews/S18-uic-fork-options.md` — repoint to
  `doc/development/decisions/input.md` **Decision 6** (the rationale now lives there).
- ~:555 heading "...pinned during option E (rationale note)" — rephrase "option E" → "the un-fork" (or
  "the `app_state`-fork removal").
- ~:563 "delta-spec §3" — repoint to `doc/development/decisions/input.md` Decision 6 (or
  `internals/user_input.md` if the sentence cites the mechanism, not the rationale).

**`doc/development/internals/project_sandbox_env.md`**
- ~:57 points to `doc/development/wip/77-new-input-api/notes/stakeholder-3-input/assessment.md (P4)`.
  That target is a `wip/` note that will be deleted. If the sentence's point has a persistent home,
  repoint there; if it is purely a process-artifact citation with no persistent equivalent, drop the
  parenthetical path but keep the sentence's factual claim. **If unsure whether the claim survives
  without that source, STOP and report it** — do not invent a citation.

**`doc/input_api.md`**
- ~:11 "input-API redesign (Phase R4)." — "Phase R4" is ephemeral process vocab. Drop it; keep the
  version/redesign framing (e.g. "input-API redesign." or "the input-API redesign").

**`tests/input/input_lifecycle_unfork_spec.lua`** (comments only)
- :1-3 header block points to `doc/development/wip/77-new-input-api/validation/prompts/
  S18-optionE-execution.md` and calls the file "Unit 1 of the S18 option-E execution". Rephrase to
  timeless framing: this spec pins the behaviour of the `app_state`-fork removal; cite
  `doc/development/decisions/input.md` Decision 6 (rationale) / `internals/user_input.md` (mechanism).
  Keep the test's own intent description.
- ~:261 "delta-spec §3's `return and not shift_held`" — repoint to a persistent home (the Enter-guard
  breadth is Decision 6 / Decision 14 in decisions/input.md; mechanism in internals/user_input.md).

**`tests/input/input_redesign_ac_spec.lua`** (comments only)
- :1-2 header cites `validation/reviews/delta-spec-input-api.md §7` as the source of the acceptance
  criteria. The tests themselves ARE the ACs now; replace the wip citation with plain-English framing
  + a pointer to `decisions/input.md` / `internals/user_input.md`. Do not delete the intent comment.
- Every "AC N (delta-spec §M ...)" comment (~:18,47,71,82,97,112,122,137,148,165): drop the
  "delta-spec §M" citation, keep the "Decision N revised" pointer where present (those now resolve in
  `decisions/input.md`), and keep the AC's plain-English description.

**`tests/input/input_widgets_callbacks_spec.lua`** (comments only)
- ~:280,339,383,454,488 "delta-spec §N" (some as "Decision 6 revised (delta-spec §N / AC...)"): drop
  the "delta-spec §N" fragment, keep "Decision 6 revised" (resolves in decisions/input.md) + the
  AC/plain-English description.

**`tests/input/input_routing_spec.lua`** (comments only)
- ~:113 points to `doc/development/wip/77-new-input-api/...` — repoint to the persistent home the
  sentence is actually citing (routing rationale → `decisions/input.md` Decision 1/11/12; mechanism →
  `internals/user_input.md`).
- ~:18 is a meta-note "REVIEW/DOC: no comment should point to wip/77 -- only to canonical docs." Once
  :113 is fixed this note is satisfied — you may leave it as a standing guard or reword it to
  present-tense ("all comments point to canonical docs, not wip/77"). Your call; keep it truthful.

## Repointing rules (apply to any ref)
- rationale / "why" citation → `doc/development/decisions/input.md` **Decision N** (folded in).
- mechanism / "how it works" citation → `doc/development/internals/user_input.md`.
- ephemeral process words ("option E", "S18", "unit N", "Phase R4", "the worker") → timeless persistent
  framing ("the un-fork", "the redesign") or drop.
- `{badspecref: …}` markers and `commit <hash>` pointers may stay — they are not wip-tree paths.
- If a reference genuinely has no persistent home, STOP and report it — do not invent one.
- Do NOT touch `wip/` files themselves (frozen records) except your own deliverable.

## Tooling note
`lua-lsp` MCP exists but is not needed here (docs + comments only). No `src/` edits.

## Final — write your deliverable, do NOT commit
1. Write `doc/development/wip/77-new-input-api/validation/outcomes/S18-jobB-refsweep.md`: per-file list
   of what you changed, plus the final grep proof.
2. Run `busted tests` — must stay **841 / 0 / 0 / 4**. Any change means you touched code — STOP, report.
3. Grep-prove ZERO remaining refs. Run exactly this and paste the output (empty = success):
   ```
   grep -rn -E "wip/77|delta-spec|delta-design|validation/(reviews|outcomes|prompts|notes)|option E|option-E|Phase R4" \
     doc/development/decisions/input.md doc/development/internals/user_input.md \
     doc/development/technical_debt/input.md doc/development/internals/project_sandbox_env.md \
     doc/input_api.md tests/input/input_lifecycle_unfork_spec.lua \
     tests/input/input_redesign_ac_spec.lua tests/input/input_widgets_callbacks_spec.lua \
     tests/input/input_routing_spec.lua
   ```
4. Report any ref you were unsure about or that had no persistent home.
