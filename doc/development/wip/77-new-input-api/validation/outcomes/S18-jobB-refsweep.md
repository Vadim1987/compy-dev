# S18 Job B — wip-reference sweep (resume) — outcome

Docs-and-test-comments-only sweep. No `.lua` under `src/` touched. In `tests/`, only comments
touched — no assertion or other code changed (verified: `busted tests` count unchanged, and
`git diff` on the touched test files shows only `--`-prefixed lines changed).

## Files changed

**`doc/development/technical_debt/input.md`**
- ~:530 heading: "(RESOLVED by option E, 2026-07-21)" → "(RESOLVED — the `app_state` fork was
  removed, 2026-07-21)".
- ~:539 body: `validation/reviews/S18-uic-fork-options.md` → repointed to
  `doc/development/decisions/input.md` Decision 6.
- ~:555 heading: "pinned during option E (rationale note)" → "pinned during the un-fork
  (rationale note)", plus the body's "Option E's preservation tests" → "The un-fork's
  preservation tests".
- ~:563 "delta-spec §3" → repointed to `doc/development/decisions/input.md` Decision 6 (the
  Enter-guard rationale/consistency citation; Decision 14 also documents this de-facto contract
  and is cross-referenced from Decision 6's section).

**`doc/development/internals/project_sandbox_env.md`**
- ~:56-57 Pointers entry citing `doc/development/wip/77-new-input-api/notes/stakeholder-3-input/
  assessment.md (P4)`. The T1/T2/T3 model that entry credits is already fully documented in this
  same file (lines 27-33), so the wip citation was pure provenance, not the model's only home.
  Per the rule ("if purely a process-artifact citation with no persistent equivalent, drop the
  parenthetical path but keep the sentence's factual claim"), dropped the wip path and kept the
  factual claim: "This model was surfaced by input-subsystem analysis during feature #77 (the
  project-exit-cleanup pain point, P4)."

**`doc/input_api.md`**
- ~:11 "input-API redesign (Phase R4)." → "the input-API redesign." (dropped ephemeral "Phase R4"
  process label, kept version/redesign framing).

**`tests/input/input_lifecycle_unfork_spec.lua`** (comments only)
- :1-11 header block: replaced the "Unit 1 of the S18 option-E execution" / wip prompt-path
  framing with timeless framing — this spec pins the `app_state`-fork removal behaviour, citing
  `decisions/input.md` Decision 6 (rationale) and `internals/user_input.md` (mechanism). Dropped
  the stale "Item 1 below is the ONE intended RED assertion pre-unit-3 ... turns GREEN once unit 3
  lands" status paragraph — that described a since-resolved in-flight state (the fork removal has
  landed; the whole suite is green), so it was both ephemeral-process vocab and factually stale.
  Kept the test's own intent/style description (mirrors input_redesign_ac_spec.lua, the
  method-patch-spy technique note).
- ~:217-225 ("modify per-instance flag" section header comment): also referenced "unit 3" /
  "pre-unit-3" (same staleness as the header — not in the prompt's explicit list, but the same
  ephemeral-process-vocab problem, and it described a not-yet-landed state that has since landed).
  Reworded to state the current fact (allow_modify alone decides; app_state no longer gates it —
  decisions/input.md Decision 6) and why the test still pairs allow_modify with app_state values.
- ~:252-260 (now ~255-263) "delta-spec §3's `return and not shift_held`" → repointed to
  `decisions/input.md` Decision 6 / Decision 14 (rationale) + `internals/user_input.md`
  (mechanism).

**`tests/input/input_redesign_ac_spec.lua`** (comments only)
- :1-9 header: replaced "Phase R4 acceptance criteria (validation/reviews/delta-spec-input-api.md
  §7)" framing with plain-English framing — these tests ARE the ACs — plus a pointer to
  `decisions/input.md` (rationale) / `internals/user_input.md` (mechanism). Dropped the stale
  U2/U3 landing-status list (both units have landed; the whole file is green).
- Every "AC N (delta-spec §M ...)" comment (AC8, AC9, AC1-AC7, AC10): dropped the "delta-spec §M"
  fragment. AC8 and AC9 already carried "Decision N revised" — kept as-is. For AC1-AC7 and AC10,
  which had no Decision citation, added the specific Decision number by matching each AC's content
  against `decisions/input.md`:
  - AC1, AC2, AC3, AC4, AC5 → Decision 6 (submit/cancel widget-owned flows; Decision 6 explicitly
    covers Escape-clears, before_cancel veto, submit-stays-open/auto-clear, opt-in auto-close, and
    Enter/Escape shadowability — all five are named in that section).
  - AC6 → Decision 2 (three-component chain, truthy-consume: "shown → widget runs, chain reports
    consumed; hidden → skipped").
  - AC7 → Decision 5 (two directions/two surfaces; console history via `on_limit_reached`).
  - AC10 → Decision 11 ("Consequence — a teardown invariant": no callback/combo/config survives
    the project that installed it).

**`tests/input/input_widgets_callbacks_spec.lua`** (comments only)
- ~:280, 339, 383, 454, 488: dropped the "delta-spec §N" fragment from each "Decision 6 revised
  (delta-spec §N / AC...)" comment, keeping "Decision 6 revised (AC...)" and the plain-English
  description, per the prompt's own instruction for this file.

**`tests/input/input_routing_spec.lua`** (comments only)
- ~:113 (now ~110-114): `see doc/development/wip/77-new-input-api/implementation/reviews/
  M4-0-04.md, "Finding 1"` dropped. The line already carried the persistent-home citations
  (`decisions/input.md` Decision 1/2, `internals/user_input.md` "Dispatch chain") plus a
  `{badspecref: reviews/M4-0-04.md finding 1}` marker (left intact — markers are explicitly
  allowed to stay per the repointing rules). Reworded the trailing clause to "had zero regression
  coverage before this test was added" — the historical claim, without the dangling wip path.
- ~:18 meta-note reworded to present tense, and also rewritten to avoid the literal substring
  `wip/77` (the sweep's own final grep-proof scans this file for that pattern) — now: "all
  comments point to canonical docs, never the feature's ephemeral working tree".

## No persistent home found / needed a judgment call

- The `input_lifecycle_unfork_spec.lua` "unit 3" reference (~:219-225 originally) was not in the
  prompt's explicit reference list and its grep pattern doesn't match "unit N" — but it was the
  same species of ephemeral-process staleness as the header, and factually described a
  no-longer-true "pending" state, so I fixed it too. Flagging it here in case that's out of scope
  for what the orchestrator wanted touched.
- Everything else in the prompt's explicit list had a clean persistent home (`decisions/input.md`
  Decision N or `internals/user_input.md`); nothing required stopping to report a missing home.

## Grep proof (must be empty)

```
grep -rn -E "wip/77|delta-spec|delta-design|validation/(reviews|outcomes|prompts|notes)|option E|option-E|Phase R4" \
  doc/development/decisions/input.md doc/development/internals/user_input.md \
  doc/development/technical_debt/input.md doc/development/internals/project_sandbox_env.md \
  doc/input_api.md tests/input/input_lifecycle_unfork_spec.lua \
  tests/input/input_redesign_ac_spec.lua tests/input/input_widgets_callbacks_spec.lua \
  tests/input/input_routing_spec.lua
```

Output: **(empty — zero matches)**.

## Test suite

`busted tests` → **841 successes / 0 failures / 0 errors / 4 pending** (unchanged from the
required baseline). No assertion or test-body code was touched; only comments in the four `tests/`
files listed above.

Not committed, per instructions.
