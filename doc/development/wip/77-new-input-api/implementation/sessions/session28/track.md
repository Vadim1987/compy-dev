# session28 — track

## 2026-08-07 — boot

- Booted per `agents/validation.md` → `agents/sessions.md`. **Fresh start**:
  session28 held only `prompt.md`, no `track.md`/`report.md` (§2 first row).
- HEAD `a7a2158c` "docs(session27): split the wrap note by audience", branch
  `feature/77-newapi-analysis-s20260615`. Working tree carries only the known
  untracked scratch (`claude.sh`, `src/STEPS.md`, `input-pr-slices.tar.gz`,
  `doc/tall_blocks.md`, `doc/development/wip/{clarification,personal-notes,pull-26}/`)
  and the three nested example repos.
- **Baseline confirmed: `busted tests` → 953 / 0 / 0 / 3.** Matches the prompt.
  The 3 pending are the intentional rows in `tests/input/input_routing_spec.lua`
  (@68, @144, @214).
- Read in full: session28 prompt, session27 `report.md` + `track.md` +
  commissioning `prompt.md` (via report/track references), the standing
  commission `validation/prompts/S27-human-commission.md`, the owner attestations
  note, `agents/rules/revalidation.md`, and §4 (phase table) of
  `validation/reviews/S27-triage-and-plan.md`.
- **`lua-lsp` MCP still unreachable** — `definition` returns `broken pipe`, twice.
  Same condition as all of session27. Will retry later; until it answers, the
  `handlers.userinput` completeness claim stays grep-only.
- **`lua-lsp` restored** by the owner via `/mcp` reconnect. The stale bridge from
  Jul 30 had a dead `lua-language-server` child; the owner's own manual run
  initialised fine, so the fault was the client's connection, not the binary.
  Verified working: `definition framework_before_exit` resolves.
- Owner concern parked before it is due (they said not to dig now):
  `validation/notes/S28-owner-concerns.md` — R081's correction must also drop
  "pointer minus the shortcuts tier", false since Decision 27.

## 2026-08-07 — part 1 findings

- Evidence note: `validation/notes/S28-revalidation-evidence.md`.
- **F1 is a real S0 defect, reproduced**: a shown widget + a derived click →
  `widget[event](widget, ...)` calls nil (`projectInputController.lua:138`);
  the route's error boundary catches it and the run dies to `snapshot`. The
  widget implements every channel in `EVENTS` except `singleclick`/`doubleclick`.
  Base-checked: created by `b1885568` (2026-08-03), widened by `069b93e9`.
  Fix shape is a Decision 5 question → owner's call, not applied.
- F2: widget `keypressed(k, isr)` names scancode `isr` (annotated `boolean?`).
  Unused in the body, so latent, but it is the exact trap Decision 26 warns of.
- F3: Appendix A labels W10 "(92)" while enumerating 85. Label wrong, coverage
  intact.
- Clean: Decisions 26/27/28 all match code as written (LSP-verified single call
  site for `framework_before_exit`); coverage claim confirmed third time by
  script; all four contested severity calls (R135, R110, R088, R081) upheld.
- Sub-agent (Sonnet, explicit) running the five defect-fix mutation checks;
  prompt of record `validation/prompts/S28-mutation-check-agent.md`, deliverable
  `validation/outcomes/S28-mutation-checks.md`. No edits of my own while it runs.
## 2026-08-07 — mutation checks back, part 1 complete

- Agent deliverable `validation/outcomes/S28-mutation-checks.md` (333 lines).
  Verdicts: commits 1 (`276f0075`), 3 (`df3f9119`), 4 (`25b9742e`)
  **DISCRIMINATING** with the failing row named; commit 5 (`953d0e9f`) confirmed
  — old row survives deleting the `after_submit` call, new pair fails; commit 2
  (`41747ac0`) **PIN**, and for an interesting reason: commit 3's later `pcall`
  subsumes commit 2's nil-guard, so nothing can discriminate commit 2 alone
  against today's tree. Not a weak-assertion blind row.
- Spot-verified the agent's load-bearing facts myself: `pcall(nil)` → `false,
  'attempt to call a nil value'` (no raise); `hide()` carries
  `if self.always then return end` (`userInputController.lua:328`) and
  `always_shown` sets `self.always` (`:455-458`). Tree restored, suite 953.
- Agent flagged repeated system-reminders claiming its files were "modified by
  the user or a linter" while `git diff` showed them identical to HEAD. It
  disregarded them and trusted git — correct call. Reads to me like the standard
  harness reminder firing spuriously, not an injection; reported to the owner as
  such, no action taken.
- **Blocked on one owner ruling: F1's fix shape** (widget consumes channels it
  does not implement, or falls through). Decision 5 is at stake, so it is the
  owner's per `agents/validation.md`. P8 held until it lands — the fix adds a
  test row and R057 would otherwise regroup it twice.
## 2026-08-07 — F1 ruling and fix

- **Owner ruling on F1:** the widget gets a no-op that does *not* consume
  (returns false); an event consumed by nobody is ordinary and must raise no
  error. Neither of the two shapes I offered — implemented as a third: no-op
  present AND declining, with `dispatch` honouring an explicit `false`.
- `8fbcba21` — breaking rows first (both failed: nil-call error, then
  `app_state 'snapshot'`), then widget no-ops + `~= false` in the widget tier.
  Decline mutation-checked (bare `return` makes the row fail). 953 → 955.
- **Self-inflicted, worth remembering:** ran the mutation check with
  `git checkout -- <file>` to restore — which discarded my own UNCOMMITTED fix
  in the same file. Caught it because the follow-up grep found no
  `singleclick`. Mutation-check *before* writing the fix, or commit first.
- Nothing in `src/` reads the walk's `consumed` return (LSP + grep), so the
  ruling is a semantics correction, not a behaviour switch for live channels.
- Decision 2's paragraph now carries a third stale claim (widget decline) on top
  of R081's two; appended to `validation/notes/S28-owner-concerns.md` for P10/W9.
- Task as understood, stated to the owner before proceeding: part 1 revalidation
  of session27 (Decisions 26/27/28, five defect fixes + their tests, the 187-id
  coverage claim, the four changed severity calls), report findings, then part 2
  P8-tail → P9 → P10 → P11 → close-out.
