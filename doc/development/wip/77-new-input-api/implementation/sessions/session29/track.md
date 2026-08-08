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
- Owner ruled: order-dependence → persistent debt (`technical_debt/general.md`),
  the two rows → new plan phase **P9c** before the PR, scoped to rows this branch
  adds. `d8a15f04`, suite 954.

## 2026-08-08 — step 2: the two production fixes

- Cold Sonnet agent, prompt `validation/prompts/S29-production-fixes-agent.md`,
  deliverable `validation/reviews/S29-production-fixes-revalidation.md`. Briefed
  that `8fbcba21`'s message describes the reverted decline mechanism, so the tree
  must be checked against the *net* of `8fbcba21` + `811849e2`.
- Fix 1 clean and better than claimed: mutation re-run at HEAD reproduces the
  exact defect (nil call at `projectInputController.lua:138`, `app_state`
  `'snapshot'`), only the named row fails → **proof, not a pin**. "Not
  pre-existing" holds — `projectInputController.lua` does not exist at `3256aac`.
  EVENTS is 12 channels and the widget now implements all 12.
- Fix 2's call-site audit holds, by grep with receiver types read manually. The
  **LSP was unusable for this question** — `references` on the qualified method
  resolved to constructor sites; on the bare name it blended `love.keypressed`,
  `ConsoleController:keypressed` and `Controller._defaults.keypressed` without
  disambiguating by receiver. Worth remembering: the hygiene rule says LSP for
  facts, but for a method name shared across unrelated tables it is grep that
  answers, and the LSP that corroborates.
- **Agent's "low severity" finding is bigger than it filed it.** Traced it
  myself: `controller.lua:905` `handlers.keyreleased = function(k)` drops LÖVE's
  scancode at the gateway — the single choke point both routes pass through.
  Enumerated all ten gateway wrappers: every other channel forwards LÖVE's list
  in full (keypressed 3/3 since Decision 26, mouse* 5/5, touch* 6/6, wheelmoved
  2/2, textinput 1/1). **`keyreleased` is the only exception left**, and
  Decision 26's rule is "no argument is added, removed or reordered on the way
  through the chain". `doc/input_api.md` states it in bold as the PR's contract.
  Base-checked: at `3256aac` both keypressed and keyreleased narrowed to `(k)`;
  Decision 26 widened keypressed and **missed keyreleased**.
- So `493c3cbe`'s `keyreleased(k, sc)` names a parameter production can never
  populate, and a project writing the documented signature gets nil. Presented
  to the owner: widen the gateway (one line + a breaking row) vs record the
  exception in Decision 26 and drop `sc`. Not fixed unilaterally — production
  change plus a decision-scope question.
- **Owner ruled: widen.** `5a83fe8c` — breaking row first (`{'a'}` against
  `{'a','scan-a'}`), then `handlers.keyreleased = function(k, sc)` forwarding
  both. Verified both route forwarders pass `...`, so the scancode reaches
  hooks, shortcuts and the widget; the console route's internal narrowing to
  `CC:keyreleased(k, sc)` is the one Decision 26 already accepts. Also widened
  `input_session`'s `release` emitter — a driver modelling a shape the gateway
  rejects cannot see this class of defect. 954 → 955.
- No doc change owed: `input_api.md`'s bold claim and Decision 26 were already
  right; the code was the thing out of line. The widget's `sc` annotation
  ("unread") stays true and is now also accurate about the source.
</content>
</invoke>
