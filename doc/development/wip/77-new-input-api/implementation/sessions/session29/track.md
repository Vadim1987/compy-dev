# session29 — track

## 2026-08-08 — boot

- Booted per `agents/validation.md` → `agents/sessions.md`. **Fresh start**:
  session29 held only `prompt.md`, no `track.md`/`report.md` (sessions §2 row 1).
- HEAD `8ed4093b` "docs(session28): wrap — report, observations, attestations,
  session29 prompt", branch `feature/77-newapi-analysis-s20260615`. Working tree
  carries only the known untracked scratch (`claude.sh`, `src/STEPS.md`,
  `input-pr-slices.tar.gz`, `doc/tall_blocks.md`,
  `doc/development/wip/{clarification,personal-notes,pull-26}/`) and the three
  nested example repos (`src/examples/{balloons,keyboard,maze}`).
- **Baseline confirmed: `busted tests` → 954 / 0 / 0 / 3.** Matches the prompt.
  Pending rows are in `tests/input/input_routing_spec.lua` (@75, @145, @215).
- Read in full: `agents/validation.md`, `agents/sessions.md`,
  `agents/rules/revalidation.md`, this session's `prompt.md`, and session28's
  `prompt.md` + `report.md` + `track.md`.
- Task as understood, to state to the owner before proceeding: **part 1** —
  revalidate session28 (suite merge, the two production fixes `8fbcba21` /
  `493c3cbe`, the smoke-finding dispositions, the P9b design in the persistent
  corpus), report findings; **part 2** — P9b → SM3a → P10 → P11 → close-out.
- **Owner directive (2026-08-08):** run *each* part-1 step through a cold
  sub-agent I brief; the agent's review lands under `validation/reviews/`
  (not `outcomes/` — owner overrides the `agents/validation.md` split for this
  phase); I read it, pause, and report findings before the next step. Steps run
  sequentially so focus is not distorted.

## 2026-08-08 — step 1: the suite merge

- Cold Sonnet agent, read-only. Prompt of record
  `validation/prompts/S29-merge-revalidation-agent.md`; deliverable
  `validation/reviews/S29-merge-revalidation.md`. Briefed to *skip* what the two
  S28 reviews already compared (titles, assertion lines, deletions, helper
  names, filename citations) and hunt what that shape cannot see.
- **One finding, latent:** four `Log.warn` monkeypatch-with-manual-restore rows
  (two from each source file) now share one busted-insulated file scope in
  `input_widget_control_spec.lua`. All four restore before their own assertions,
  so nothing can fail today; an unexpected raise from `show`/`configure`/`clear`
  between patch and restore would now reach rows that were in the other file.
- **Mechanism verified myself, empirically** — throwaway two-file busted run in
  scratchpad: a patched field of a module-created global leaks to later rows in
  the *same* file and is healed for the *next* file. So insulation is per-file,
  and the merge really did widen the blast radius. Restore-before-assert
  spot-checked at `input_widget_control_spec.lua:64-75` and `:392-400`.
- Other verified-by-me claims: no nested `before_each`/`setup` at any depth in
  either merged file; `--tags=lifecycle` → 14; `25f70175` does touch
  `input_widget_control_spec.lua` (3 lines, header REMARKs, as its message says).
- **Whole-suite `--shuffle` fails 39-52 rows at HEAD.** Agent said symmetric
  pre-merge; I took it further per the base rule — `git archive 3256aac` into
  scratch: base suite is 674/0 ordered and **29-48 failures shuffled**. Order
  dependence predates the entire feature. Not ours, not merge-caused.
- **But two of the shuffle failures are feature-owned rows** (inbound events:
  `Ctrl+Esc quits the app when nothing is left to go back to`; shortcuts:
  `a shortcut fires but does not consume`, `#disputable`). Separate observation
  for the owner, not a merge finding.
</content>
</invoke>
