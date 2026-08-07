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
## 2026-08-07 — owner rejects the decline mechanism

- **Ruling:** truthy consumes, non-truthy does not; no false/nil distinction; the
  minimum that stops singleclick/doubleclick blowing up is a plain no-op inside
  the widget. *"I am actively against hallucinated special cases (KISS and DRY
  must be honored)"* — and: write it into the rules.
- I had read "ideally does not consume" as a requirement and built a decline
  protocol for it. The ideal was subordinate to not inventing mechanics; the
  requirement was only "does not blow up". Rule of thumb I take from it: when a
  ruling contains an ideal and a requirement, the requirement is the mandate.
- `811849e2` reverts the mechanism — widget tier back to shown-means-consumed,
  no-ops plain, decline row deleted with the mechanism it pinned. The defect row
  survives and still discriminates (mutation-checked by file copy this time, not
  `git checkout`). 955 → 954.
- `f8ad6940` `agents/rules.md` Design section gains **"No invented special cases
  (KISS, DRY)"**, with the rejected code as the worked example and three signs:
  a sentinel only one caller produces, a branch nothing exercises, an exception
  clause on a previously uniform decision.
- `493c3cbe` F2 signature unification (owner approved, rationale: shrink the
  future-mistake surface). `keypressed(k, sc, isr)`, `keyreleased(k, sc)`. All
  call sites audited — every non-chain caller passes the key alone, so nothing
  relied on the old second position. No new row: an existing one already pins
  that ('a', 'scan-a', true) reaches the widget. 954 unchanged.
- Tooling anomaly handed to a cold Sonnet agent (owner's suggestion: git hook
  inherited from their workspace? linter rewriting atomically without changing
  content? LSP?). Prompt `validation/prompts/S28-tooling-anomaly-agent.md`,
  deliverable `validation/outcomes/S28-tooling-anomaly.md`. Read-only, and told
  to record the message verbatim if it fires during its own run.
## 2026-08-07 — P8 tail begins

- Tooling anomaly closed: harness's own atomic-write detector, content-aware
  (a byte-identical rewrite did NOT trigger it), benign. Hooks/linters/LSP all
  ruled out; I spot-checked the hook and binary claims. `f31b43ca`.
- Three small P8 items, three commits (one concern each):
  - `53abd09e` **R069 answered against the remark.** Asserting "widget not shown
    after suspend" FAILS — suspend leaves both the shown flag and the overlay
    handle standing; only the route is disconnected. Pinned the true pair
    instead. Another remark that would have been wrong to implement literally.
  - `1aa01572` **R063 declined, with the evidence named.** All three combo
    shapes already have firing rows (matrix + 'combo classes'); the row's
    subject is acceptance and canonicalisation. Comment says where, so the
    question does not recur. DRY, per the rule just written.
  - `64ac38d0` **R047 implemented.** Search query now typed character by
    character; the mock wrapper it used was the handler call with extra steps.
    Suite unchanged, which says the search path is cadence-insensitive.
- **Owner rulings on the restructuring:** surfaces are **inbound events /
  widget control / widget callbacks**; merges go ahead (variant 2) but
  **inventory first, written merge plan on disk before anything moves, cold
  agent revalidates the plan BEFORE the move and the results after**.
- Inventory agent (Sonnet) running: every `it` in the four merge-pair files with
  describe path + helper dependencies, duplication candidates, one-liners for
  the rest. Prompt `validation/prompts/S28-merge-inventory-agent.md` →
  `validation/outcomes/S28-merge-inventory.md`.
## 2026-08-07 — the merge, planned then executed

- Inventory back: **93 rows, and only ONE of 11 duplication candidates is a true
  duplicate**; one more is a superset relationship. The rest are designed splits
  (different entry point / route / depth, several documented in the files' own
  comments). So R074+R078 are a regrouping, not a cull — that reframing is the
  whole value of the inventory step the owner insisted on.
- Plan `validation/reviews/S28-merge-plan.md`: two merged files, two deletions
  named with their survivors, one three-way cluster deliberately KEPT (each row
  pins a distinct fact — deleting one to improve a dedup count is the failure
  this guards against). R064 answered by dissolution rather than rename.
- **Cold review earned its cost.** Four corrections, all accepted, two
  re-verified by me in the source:
  - deletion 1 would have **dropped an assertion** — deleted row checks
    `F.is_widget_visible()` (love.state overlay handle, user-observable),
    survivor checks `F.widget:is_shown()` (internal flag, kept free of
    love.state by owner ruling 2026-07-20). Survivor gains the visible check.
  - **arithmetic bug that contradicted itself**: File B's table listed row 33
    inside a group two sections after deleting it; summed 53, not 52. A literal
    execution lands the suite at 953 and nobody notices.
  Revision log is §5b. `5f261188`.
- `90f632cf` **step 1** (Sonnet executor, verbatim move): widget control surface,
  39 rows, suite 954 unchanged. Verified beyond the count, since a green count
  survives a silently rewritten row: **43/43 row titles identical, 76/76
  assertion lines byte-identical**. That check is the one to reuse for step 2.
- Executor flagged, correctly, that the merged header still carries REMARKs
  asking for the merge it had just done. Told it to delete them in step 2 — a
  note whose subject no longer exists is not covered by "do not improve while
  moving".
## 2026-08-07 — merge complete, P8 tail done

- `25f70175` **step 2**: widget callbacks surface, 52 rows, 954 → 952. Two
  deletions, five assertions added to the survivors at the positions §5b names.
  Verified: 54 titles in, 52 out, missing exactly the two named; asserts 84 → 86,
  reconciled. Read both modified rows myself rather than trusting the report.
- `b0c9d032` **the guards' blind spot**: `#lifecycle`, a tag documented in
  `tests.md`, did NOT move with its rows — `--tags=lifecycle` selected zero. Row
  titles unchanged and every assertion accounted for; a tag is neither. Caught by
  chance while chasing dangling filenames. **Lesson for any future move: verify
  tags and cross-file citations, not just rows and assertions.** Written into
  the post-move review prompt as its own check.
- `bc5b97ae` 13 dangling citations repointed. Four of five in tests turned out
  to be intra-file after the merge → now name a describe group, which cannot rot
  like a path. One was already wrong pre-merge (credited the method-patch
  technique to the callbacks suite; the row using it is in the events spec).
  `tests.md`'s ten-file list rewritten around the three surfaces.
- `a246c170` **step 3**: surface names on the six files that stay put. Titles
  only. `input_nfr_mechanism_spec` deliberately keeps its old title — it belongs
  to no surface and a surface name on it would be false.
- Post-move cold review running (owner's second required round):
  `validation/prompts/S28-merge-result-review-agent.md` →
  `outcomes/S28-merge-result-review.md`. Told to reach the originals via
  `git show 90f632cf^:` and to prove every tag still selects its rows.
- Phantom "file was modified" notices fired twice more, on the two files I
  edited via a python heredoc — i.e. writes outside the harness's own edit path,
  exactly as the investigation predicted. Confirms the finding; no action.
- Task as understood, stated to the owner before proceeding: part 1 revalidation
  of session27 (Decisions 26/27/28, five defect fixes + their tests, the 187-id
  coverage claim, the four changed severity calls), report findings, then part 2
  P8-tail → P9 → P10 → P11 → close-out.
