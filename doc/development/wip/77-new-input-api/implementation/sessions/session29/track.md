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

## 2026-08-08 — step 3: the smoke-finding dispositions

- Cold Sonnet agent, prompt `validation/prompts/S29-smoke-dispositions-agent.md`,
  deliverable `validation/reviews/S29-smoke-dispositions-revalidation.md`.
  Briefed for a verdict **per premise**, not per finding, and told that a wrong
  premise under a no-change ruling is the most expensive thing available.
- **The three no-change rulings hold on every premise** (SM1, SM2, SM3b), and so
  does SM3a's negative claim (no graphics-state reset on the
  `stop_project_run` → next-run path; the only `setFont` outside project code
  fires on quit). The two premises I most expected to be asserted rather than
  checked — `ConsoleView:draw` exercised by no row, and nothing in the platform
  dimming anything — both verified.
- **SM4 correction, reproduced by me:** the `mod_order` mutation fails **three**
  rows (`:336`, `:411`, `:425`), not one. `:425` is the class-marker row the note
  names as *not* catching this, and it is pre-existing — `edb6321b`, 2026-08-03,
  four days before the SM4 commit. Verdict unaffected; the coverage-gap framing
  overstated by one row.
- **SM5 correction:** "reads the same in both orders" names two orders. A
  `textinput` after its own `keyreleased` finds an empty claim table and is
  dropped by the carried-over `INPUT_UP_GRACE` window — same failure shape,
  other gate, inherited not introduced. **This is the exact case P9b exists to
  answer** (owner's overturn of the state-only proposal), so it is not new work
  — but P9b's implementation must be checked against this trace, not only
  against the design's own examples.
- Both corrections appended to `validation/notes/S28-smoke-findings.md` under an
  `[S29]` heading; session28's text left as written, per the amend-don't-rewrite
  pattern used for the plan's §6/§7.

## 2026-08-08 — step 4: the P9b design

- Cold Sonnet agent, prompt `validation/prompts/S29-p9b-design-agent.md`,
  deliverable `validation/reviews/S29-p9b-design-revalidation.md`. Briefed to
  test whether each rule can be *evaluated from the declared state* given what
  the other channels do to it — framed neutrally, not handed the answer.
- **Finding 1 (root): the doc contradicts itself about `seenText`.** `:45` calls
  it "text of the most recent textinput, judged or not" (never cleared); `:33`
  gives `keyreleased` the job of clearing it. Either reading breaks a rule —
  never-clear reproduces the original defect through rule 3; clear-on-release
  leaves rule 4 comparing against "`seenText`'s value at release", which **no
  declared field holds** once `keyreleased` has run. I had spotted the missing
  field myself before spawning; the agent found the contradiction that explains
  how it got there.
- **Finding 2 (consequence): the acceptance gate never closes observably.**
  Verified in the nested repo: `alt.lua:148` → `gaugeOnCorrect` →
  `gaugeNext(st,cfg)` **synchronously**, so `accepting` goes false and true
  again, and `judgedText` resets, inside the same judging call. Rule 5 is dead
  in practice and rule 6's dedupe is wiped immediately. Chain: release clears
  `seenText` (rule 3 passes), rule 4 unimplementable (passes), rule 5 reopened
  (passes), rule 6 reset (passes) → a trailing OS repeat is judged against the
  **new** target. That is the bleed the design's own smoke checklist forbids.
- **Rule 4's necessity argument — the agent is half right, and I disagree with
  its framing.** Its pair (repeat tail vs late first character) *is* separable
  by state, using exactly the value `keyreleased` discards: a tail was seen
  during the hold, a late first character was not. But a clock is still needed
  for a pair the doc never names — **repeat tail vs a deliberate fast re-press
  of the same character**, which are identical in state. So the owner's
  session28 conclusion (a clock is needed) **stands**; the reason written into
  the doc does not. Worked this through myself rather than relay it.
- Everything else clean: rule 6 holds as stated, all shipped-code claims land at
  the cited locations, all citations resolve (incl. `user_input.md` "Data flow"
  and `gauge.lua`), platform claims confirmed where checkable (no ordering
  guarantee; no Caps query API in LÖVE 11.5) and honestly marked unverifiable
  where not (desktop-first/web-first, `capslock` release reliability).
- Design doc NOT edited — owner's design, persistent corpus, header still says
  "human-approved NOT YET". Presented for ruling before P9b implementation.

## 2026-08-08 — owner asks: is the design better than the original?

- Owner's suspicion, stated: the design was written by an agent after a spoken
  discussion they have not reviewed as text, and grew across rounds of challenge
  — they suspect drift/accretion. Four-way comparison commissioned (A original
  `c904338`, B migration `4814407`, C shipped interim `3a9d48c`, D the paper
  design). Prompt `validation/prompts/S29-p9b-design-vs-original-agent.md`,
  deliverable `validation/reviews/S29-p9b-vs-original.md`.
- **The premise is refuted, and I verified it myself.** A was not
  simple-and-correct: `input.lua@c904338:112` `inputStale(k)` returns true when
  `INPUT.held[k]`, and judging ran through it — so under desktop order
  (keypressed first) **every fresh printable press was dropped**. The original's
  printable judging never worked outside the event order it was written against.
- **B changed nothing in judging** — `git diff c904338 4814407 -- alt.lua` is
  empty. Pure plumbing migration. So the defect was inherited, not introduced by
  the input-API work.
- **C is the real fix** and is small: 55 insertions / 32 deletions over two
  files. Claim one glyph per press, release at keyup, 1-frame post-keyup grace.
  Verified `spendGlyph` (`input.lua:154`) and `altTextinput` (`alt.lua:173`).
  Its claim survives target changes, so it is **structurally immune to the
  bleed** — `alt.lua`'s own comment names that case.
- **D as written is worse than C.** Its regression on the bleed is not an
  independent flaw — it is finding 1 again: rule 4 is C's grace window's
  analogue, and rule 4 is inert, so nothing catches the post-release trailing
  glyph. Plus a fourth self-contradiction I confirmed in the doc text: the
  closing section lists the chord-modifier slip as a defect of the shipped code
  that D supersedes, while §Concerns admits D keeps it ("the one live-state read
  left in the path").
- **D's one earned gain is real:** one judging path instead of two
  (`altPlayKey` + `altTextinput`), which subtracts a path and matches the
  no-special-cases rule. That is liftable into C on its own.
- Case 4 (a fast tap whose glyph trails its own `keyreleased`) is dropped by
  **A, B and C alike today** — a genuine unfixed hole in the shipped game, and
  D does not reliably fix it either. That is the real open defect, and it is not
  what D's machinery is aimed at.
- My recommendation to the owner: keep C, lift the path unification into it,
  do not implement D as written. Presented with the alternative (repair D) —
  owner's call, P9b's disposition is theirs.

## 2026-08-08 — the owner's paradigm, recovered; D discarded and rewritten

- **The owner supplied the missing half:** their session28 proposal was
  `textinput`-only judgement with *"on win, stop updating last judged input
  (block writing) and stop judging, update the target, release the block"*.
  Their statement, 2026-08-08: **the paradigm and the table-as-state-model were
  their only original inputs to D** — everything else answered corner-cases the
  assistant raised, which they took for existing game constraints and which were
  self-inflicted.
- **The drift is on disk and now annotated.** `S28-owner-concerns.md:131`
  captured *"blocking table writes is more reliable than freezing isolated
  scalar value"* — but filed it under *"a predeclared state table with scalar
  fields"*, i.e. as an argument for the table **shape**, with the paradigm it
  belonged to absent. The seam is the next line: *"two fields: one for the
  tail/grace mechanics, one for judgement dedupe"* — the mechanism meant to
  **replace** the tail/grace was recorded as its peer.
- **I corrected myself twice today, both times in the owner's favour.** (i) I
  had said a clock is still needed for repeat-tail vs fast re-press; under the
  paradigm both match last-judged, both are ignored, and the only casualty is
  two identical consecutive targets — a `gaugePick` constraint, not a timing
  problem. So **no clock at all**. (ii) I objected that a hold-rule must
  re-couple to `keypressed`; the owner's `love.update` variant sidesteps it —
  asking the held set *"is the key still down"* is a direct question, unlike
  asking it to *infer* whether a character is a repeat. Recorded that
  distinction in the doc.
- **Verified before writing:** `gaugeOnWrong` is idempotent per presentation
  (`gauge.lua:205`), so repeated wrong characters are already harmless by the
  game's own rule; `gaugeOnCorrect` → `gaugeNext` is synchronous, so a repeat of
  the *winning* character lands on the next target — the one repeat that changes
  an outcome. `upRecent`/`GLYPH_CLAIMED`/`INPUT_UP_GRACE` are read **only** by
  `spendGlyph` and `appKeyreleased`, so all three leave with the mechanism;
  `altIsKeyTarget` stays, it selects the feeding channel.
- `doc/development/internals/examples/keyboard.md` **rewritten wholesale**: one
  judge (`textinput`), two fields (`lastText`, `blocked`), writes blocked across
  the win transition, no clock, no grace, no held-set read in judging, no
  modifier guard (Shift is how capitals are typed — a guard would need an
  exemption list). The hold suggestion is recorded as a game-design question
  with both mechanisms costed, explicitly not adopted.
- Plan §7 amendment 3 + the P9b row rewritten. Grepped the corpus for citations
  of the discarded design's terms (`TEXT_TAIL_FRAMES`, `seenText`, `judgedText`,
  `lastGlyph`) — none outside the wip working tree, so nothing dangles.

## 2026-08-08 — validation of the rewrite, and three gaps that were mine

- Cold Sonnet agent, A vs C vs E, prompt
  `validation/prompts/S29-new-design-vs-original-agent.md` → review
  `validation/reviews/S29-new-design-vs-original.md`. Owner extended scope
  mid-run to include **B**, once they learned the minigames share input
  infrastructure; sent via message to the running agent rather than a respawn.
- **Both questions answered.** Better on the counts (judging state 5 → 2 → 2;
  constants 1 → 1 → **0**; live-state reads in judging 4 → 2 → **0**; clock
  reads 1 → 1 → **0**). And the subtraction has **no other-scene blast radius**
  — `GLYPH_CLAIMED`/`spendGlyph`/`upRecent`/`INPUT_UP_GRACE` are read nowhere
  outside `input.lua` and `alt.lua` across 23 files; no other scene carries an
  `inputStale`-shaped defect; `help.lua`'s `INPUT.held` read is a continuous
  poll, not event-time inference.
- **B behaved better than feared:** its first commit *split* `inputStale` —
  keypressed-channel repeat filtering moved to the platform's `isrepeat`, which
  benefits every scene identically, while the textinput defect was left verbatim
  until `3a9d48c`. Every scene file byte-identical to A across the migration.
- **Three gaps, all mine, all at the boundary I did not look at.** Verified each
  in code before fixing: (i) `capsReconcile` runs in the **shared**
  `appTextinput` for every scene, not in Alt's judging — my "rule 1" would have
  silently stopped Caps re-estimation in `press`/`find`/`intro`; (ii) the shared
  handler **already** drops Alt/Ctrl chords, so my "there is no modifier guard"
  was false as a description; (iii) I dropped `alt.lua`'s exemption that a
  modifier or `capslock` must not knock a non-printing target. `4a49c4ea`.
- Opened rather than answered: the **symmetric** chord case — releasing Ctrl+Alt
  while `H` stays down sends stray `h` into judgement. Recorded what A and C do
  from the code, not their comments: **C's own comment claims to cover it and
  the path does not obviously bear that out**. Needs the device; owner's ruling.

## 2026-08-08 — P12 added: upstream reconciliation blocks the PR

- **Owner corrected me.** I had written the upstream-integration question up as
  a later nice-to-have, "explicitly not a PR blocker". It blocks: a platform
  upgrade that breaks a downstream project cannot ship without a compatibility
  PR to that project, and two of the three example repos are **not ours**
  (`dsent/keyboard`, `nagydani/Compy-maze`). Platform PR + example PRs are one
  release, not four.
- Wider than the examples: the **platform** repo has advanced too, possibly
  along a fork, so the real PR reconciles on three fronts at once.
- Written into the plan as **P12** with §8 carrying the rationale, the snapshot
  table (keyboard `3a9d48c` on `newinput`, **no tracking ref**; maze ahead 3;
  balloons ahead 4 — all against last-known refs, nothing fetched), and the part
  that is not a merge: upstream's newer minigames were written against the
  pre-migration path, so re-integration repeats this session's audit over scenes
  that do not exist here yet. §7 amendment 4 records the correction.
- Sequenced deliberately last — stabilise the snapshots first; re-planning
  against a moving upstream mid-design is how work gets done twice, which this
  session watched happen. P12 owes its own coordinated plan, an owner-authorised
  fetch of third-party remotes, and a merge-order decision.
- Also to carry into the PR description's open questions, per the strategic
  frame: a reviewer who cannot see this is tracked will assume it was missed.
</content>
</invoke>

## 2026-08-08 — WRAPPED

Suite **955 / 0 / 0 / 3**, green and stated at every commit. 13 commits, one a
production fix (`5a83fe8c`). Nothing pushed.

Wrapped at the owner's call, not on context pressure alone: the five held-key
questions are a coherent design agenda, and answering them inside a long,
heterogeneous thread is how the discarded P9b design got made. Q2 answered in
the agenda note; the other four handed over intact.

Distilled into `report.md`; agenda into
`../../../validation/notes/S29-held-state-design-agenda.md`; successor
commissioned as session30 and the pointer repointed. Track kept raw per
`agents/sessions.md` §3.

## Sub-agents

All Sonnet, explicit model, prompts and deliverables on disk under
`validation/{prompts,reviews}/` — the owner directed reviews to `reviews/` for
this phase rather than `outcomes/`:

- **S29-merge-revalidation** — the suite merge, from outside the S28 checks' shape.
- **S29-production-fixes** — the two fixes, mutation re-run rather than trusted.
- **S29-smoke-dispositions** — SM1–SM5, per premise rather than per finding.
- **S29-p9b-design** — the design against its own declared state.
- **S29-p9b-vs-original** / **S29-new-design-vs-original** — the four-way
  comparisons, the second extended mid-run to include the migration once the
  owner flagged shared input infrastructure.

The two design comparisons were the highest-value spawns: the first found the
design was a regression against shipped code, the second found three gaps in the
rewrite that replaced it.
