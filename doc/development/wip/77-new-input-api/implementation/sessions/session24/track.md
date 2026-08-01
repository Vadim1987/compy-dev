# session24 — track

## 2026-07-31 — boot

- Booted per `agents/validation.md` boot ritual + `agents/sessions.md`.
  Re-entrance guardrail: `session24/` held only `prompt.md` — no `track.md`,
  no `report.md` → **fresh start**; this entry opens the track.
- HEAD `7cf2f9d` (`docs(session23): wrap pre-TF2 revalidation`). Working tree
  carries only the sanctioned untracked scratch (guardrail 3): `claude.sh`,
  `src/STEPS.md`, `input-pr-slices.tar.gz`, `doc/tall_blocks.md`,
  `src/examples/{balloons,keyboard,maze}`,
  `doc/development/wip/{clarification,personal-notes,pull-26}`. Left alone.
- Read: `agents/validation.md`, `agents/sessions.md`, `session24/prompt.md`,
  `session23/{prompt,report,track}.md`, `validation/plan.md`.
- Baseline `busted tests` → **867 / 0 / 0 / 3**, exactly the expected count.
  Pendings unchanged (console key release, editor pointer, project-run touch —
  all `tests/input/input_routing_spec.lua`).
- Task per prompt: **wait for the human**; live expectation is inbound TF2
  feedback (receive verbatim → triage against decisions/debt ledgers +
  `validation/plan.md` phases → act only on instruction).

## 2026-07-31 — owner arrives ahead of TF2 feedback

- Owner states TF2 feedback is **not yet in place**; wants to ask codebase
  questions during their review instead. Scope granted: **may commit under
  `wip/`, must not write anywhere outside it** until told otherwise.
  → Q&A / inspection mode; no execution, no phase start.

## 2026-07-31 — Q1: the two construction-named input specs

- Owner (mid-TF2) asks about `input_lifecycle_unfork_spec.lua` and
  `input_redesign_ac_spec.lua`: purpose, leftover-or-necessary, rename
  feasibility. Answer materialized:
  `validation/notes/2026-07-31-construction-named-specs.md`.
- Finding: **neither is a leftover** — each holds sole-witness rows
  (redesign_ac: AC2 veto, AC7 console history end-to-end, AC8 hook
  clear-no-resurrection, AC9 hooks/callbacks identity freeze, AC10
  project-facing re-seed; unfork: `allow_modify`/Ctrl+D — the only
  exercise of that flag in the tree — plus the editor-upstream-consume
  rows and the non-shift-Enter breadth). ~7 of redesign_ac's 12 rows and
  unfork's §6 are deliberate duplication of the thematic files.
- What IS construction-era is the **framing**: names, tags (`#r4`,
  `#lifecycle_unfork`), AC-numbered headings, "RED today" prose.
- Rename is cheap: no runner or doc depends on names/tags; only three
  persistent-corpus lines + the files' own headers cite them
  (`technical_debt/input.md:245,:540`, `internals/user_input.md:331`).
  Nothing done — owner asked for feasibility only.
- Owner then instructed BOTH actions, and widened scope beyond `wip/`:
  rename + re-prose the lifecycle spec, **dissolve** the redesign-AC spec
  (redistribute + kill duplicates), reason given — "otherwise I myself
  cannot read and review them". Also asked for a wip note keeping the
  move restorable until the PR.
- Executed in three commits, suite green at each: `eb43d34` dissolve
  (867 → 861), `0586a57` 64-char rewrap of the rehomed rows, `88fa83f`
  rename `input_lifecycle_unfork_spec.lua` →
  `input_lifecycle_uniform_spec.lua` + prose + the two corpus citations.
  Restoration map: `validation/notes/2026-07-31-spec-dissolution-map.md`.
- Judgment kept in-session rather than delegated (charter (b) says
  delegate down): the deliverable IS the prose quality the owner could
  not read, and the drop/keep calls needed per-row coverage proof. Each
  "duplicate" was verified against its claimed home in code BEFORE
  deletion — two rows survived that check (AC4 auto-close, AC6
  consumption-at-the-route-seam) and were moved, not dropped.
- Discovered, reported not fixed: `doc/development/tests.md` carries a
  stale suite count (862) and names two split files by retired names
  (`input_dispatch_chain_spec`, `input_widget_io_spec`) — as do the two
  spec headers pointing at each other. Same class as session23's F1.
- Erratum: `eb43d34`'s message miscounts one moved row as dropped;
  corrected in the map note, history not rewritten.
## 2026-07-31 — TF2 human take 01 received

- Two owner commits arrived by **push** into this checked-out repo:
  `e9a7ccd` (comment policy moved from `conventions/code.md` to
  `agents/validation.md` — "very context-specific") and `786e8e4`
  ("TF2: human take 01 (there could be more)"). The push moved HEAD
  while index/worktree stayed at `26127bf`, so for a while any commit
  of mine would have silently reverted the owner's review. Flagged;
  owner resynced. Nothing lost — the stale worktree was byte-identical
  to `26127bf`. **Standing lesson: after any owner push, verify
  `git diff HEAD` is empty before committing.**
- Suite went **RED, 859 / 2 / 0 / 3** — the owner's two new cursor
  probes. Verified in code: `col` is a caret position (`1..len+1`),
  `backspace` splices `usub(1, cc-2)..usub(cc)`, and the neighbouring
  clamp row (`'hello'` → 6) proves the same convention. The probes are
  right in intent, the expectations off by one. The real finding
  underneath: `doc/input_api.md` never states the convention, which is
  why it bit.
- Triage + plan written to
  `validation/reviews/S24-TF2-take01-triage.md`: 9 example reports
  clustered into A1 no-overlay-on-second-project (suspected real
  regression) · A2 no auto-clear (Decision 6, examples un-migrated —
  turtle verified to lack `after_submit`) · A3 strictness surface
  (Decision 15 in-flight; balloons raise did not reach the error
  window, maze warns per tick) · A4 "freeze" = the error lock with no
  visible error (`has_error` gate at `userInputController.lua:526`,
  `:715`) · plus singles. Class B = TF3 test actualization, C = nine
  REMARK blocks now sitting in tracked docs, D = slice composition +
  wrapper naming.
- Verified for the owner along the way: `compy.before_exit` **does**
  exist (`consoleController.lua:697-720`, fired `:1193`); the word
  `slot` survives only in the paragraph defending its non-use and in
  the implementation's `before_exit_slot`; `tests/editor/editor_spec_fwd.lua`
  is **tracked**, so guardrail 3 in `agents/validation.md` is wrong to
  call it untracked scratch; `input_nfr_forward_spec`'s
  "pending until implemented" group indeed holds a live passing row
  plus an orphan comment block.
- Nothing executed. Four blocking questions at the end of the triage
  doc (who drives live runs · detached examples in scope? · confirm
  the cursor verdict · re-ordering from take 02).

## 2026-07-31 — owner reshapes P1; replanned in five certainty bands

- Owner rulings received: (1) **no xvfb** — the example defects are mine to
  hunt **headlessly**: hypothesis → busted test (mock/intercept as
  troubleshooting needs) → localize → prepare fix; their manual smoke test
  comes after and confirms rather than gates. (2) `keyboard`, `maze`,
  `balloons` are **out of bug-fixing scope** — never smoke-tested properly,
  so their reports are unconfirmed evidence. (3) Cursor verdict confirmed:
  correct the expectations to caret semantics.
- W0 executed on the spot (`5356355`): probes kept but switched to
  insertion (`'lemon'` + col 3 + `X` → `'leXmon'`), which shows the caret's
  side without arithmetic, and `doc/input_api.md` now states the convention
  it never had. Suite green again, **861 / 0 / 0 / 3**.
- Replan appended as §8 of the triage doc, §6 marked superseded. Five bands,
  each less certain than the last: settled prose/composition → additive
  coverage → headless defect hunt → **one** ruling sitting → post-ruling
  execution → Phase G. Bands never depend forward, so take 02 can land at
  any boundary without unwinding work.
- Behavioural note: the owner optimizes for *their own* scarce attention —
  "minimal intervention, no destabilization" — and treats certainty as the
  ordering key rather than importance. Queue rulings, never trickle them.

- Behavioural note: the owner is reading the PR candidate as a cold
  reviewer would — "does this file's *name* explain itself without wip
  context" — which is the C1/J1 vocabulary axis surfacing from TF2 rather
  than a defect hunt.

## 2026-07-31 — band 1 executed: W1 → W4

- **W1** (`1f6129c`) cold-reader prose sweep of the whole input suite, 19 files.
  Comments and describe/it names only — verified mechanically that no
  non-comment line moved and every added line is ≤64 chars. Standardized
  availability on "predates / introduced with / changed by the Compy input API
  (1.0.0-rc20260712)"; killed "this feature", "feature-new", "pre-baseline",
  `#77`, `#m5c`/`#m7`/`#m8`, TF1 split provenance, commit `1a2a9a3`,
  "Decision N *revised*". Renamed `input_nfr_forward_spec`'s mislabelled
  "planned changes (pending until implemented)" group (it holds a LIVE row) to
  "teardown leaves the love.* wiring at defaults" and dropped its orphan
  comment block. 861 / 0 / 0 / 3 throughout.
- **W2** was already done earlier in the session (`9357d76` delete
  `editor_spec_fwd.lua`, `ad393a1` guardrail 3).
- **Owner instruction mid-band:** drop the tracked `ses/SWEEP.tgz`. Extracted
  first — all nine `SWEEP/session01..05/{prompt,track}.md` are byte-identical
  to the copies under `implementation/sessions/`, so nothing was lost
  (`30a2f34`). Guardrail 3 and the WIP index's flag list updated; the index's
  §Flags entry kept and marked RESOLVED so the anomaly stays legible.
- **W3** (`a622cd5`) composition recipes into `pr-assembly-guide.md`, both
  **verified end-to-end in a scratch worktree** rather than asserted: applying
  the ten slices in the §2 order onto `BASE` reproduces HEAD byte for byte
  outside `wip/`.
  - 1a/1b: 1a = `6c766da^..6c766da` narrowed to Set 1 (NOT `$BASE..6c766da`,
    which drags unrelated content from the 60 commits in between); 1b is by
    definition the remainder, computable only after 1a applies. Recorded as a
    standing rule, per the owner's "would be nice to do it always".
  - 3g: the `highlight()` guard + its spec, selected by git's own hunk funcname
    context. The only hunk-level filter in the guide; §1.1 says how to notice
    if a second hunk ever slips into it.
  - Noted that the hand-split `1a` patch in `pr-slices/` holds 14 files vs the
    recipe's 21 — the recipe supersedes it at Phase G.
- **W4**, the factual doc REMARKs, in five commits (`ae17579`, `ea7b211`,
  `6ff2261`, `06bbe91`, `9b7ed6e`). Notable findings while verifying rather
  than transcribing the remarks:
  - **`before_exit` fires on every stop path that runs a project** — Ctrl+Q,
    Ctrl+S, Ctrl+T and the Ctrl+Esc/`love.quit` path all reach
    `stop_project_run` (`controller.lua:751-779`, `:877`, `:899`, `:903`). The
    doc's old claim that force-exit "runs no project code" was wrong and is
    gone. Only quitting with no project running runs none.
  - **"repl echoes → should say evaluates" is NOT a doc bug.** The example
    really echoes: `on_text_entered` pipes lines to `print`, and the overlay is
    provisioned with `InputEvalText` (`main.lua:370`), a plain-text evaluator
    with no parser. Documented as-is + named the real question (should the REPL
    example evaluate?) → **queued for the W9 sitting**, not silently "fixed".
  - "pen-and-paper" was wrong for guess, repl AND valid (the owner named two);
    introduced "terminal only" as a third draw mode with all three defined.
  - `#77` swept from the persistent corpus (17 mentions); both ledgers gained a
    version anchor line, since neither stated the version anywhere.
  - `tests.md`: every concrete fact in the Input Contract Suite section had
    drifted — file list (3 dead names), the A/B/C/D buckets (labels no longer
    in any file), the milestone tag list, the suite count, all three pending
    line numbers.
- Discovered, not fixed: `input_shortcuts_click_spec.lua:36` has a stray double
  paren in `'... (#disputable))'` — leave for W6, which owns the disputable
  marking. `technical_debt/input.md:118` cites master merge `0022004` (survives,
  unlike a branch hash) and "Decision 2 revised" — the "revised" framing in the
  decisions ledger's own headings is W9 territory.
- Band 1 is **closed**. Next is band 2 (W5 additive coverage, W6 judgment prose
  + the `is_widget_visible()` fixture factoring) — the first band that touches
  test bodies.

### band 2 executed: W5 → W6 (2026-07-31)

Six commits, suite green at each; count moved **861 → 865** and the arithmetic
is stated in every message (4 new rows, no row removed or split).

- **W5**, additive coverage, two commits.
  - `52cda7e` — shortcut **selectivity**, one row per channel
    (`input_events_spec`). Each shortcut is registered *consuming*, so a
    spurious match would be visible twice (the flag flips **and** the tiers
    below stop receiving). Replaces this file's standing REMARK.
  - `9281cdb` — the paired **Shift+Return interceptability** row
    (`input_widgets_callbacks_spec`): a project shortcut on `'shift+return'`
    consumes it and the newline never happens. **Green on the first run**,
    which is the point — it proves the neighbouring row's "never intercepted"
    comment was a false claim, not a missing feature.
- **W6**, judgment prose + the fixture, four commits.
  - `4c74acb` — "console receives input while the widget is hidden" now has a
    persistent home: `technical_debt/input.md`, *"On the console route, a
    hidden widget's input falls to the console line"* (Open decisions), and the
    group is tagged `#disputable` pointing at it. The finding that gave the
    entry its shape: the principle *declined input has no effect* is ruled for
    the **project** route only (Decision 11's changed baseline); the console
    route kept the old fallback to its own command line, which is defensible
    on its own terms — two routes, two answers, one written down. No leak path
    through a running project is known today (ruling (a)'s `user_is_interactive`
    keeps the project route for anything with an overlay or pointer handler),
    so this is a **contract** question first, not a bug report.
  - `6b0650f` — the Shift+Return framing (it describes what the WIDGET does
    once the event arrives, not reachability) and the custom-validator row's
    submit/cancel citation (the validator is a step *of* that chain — the
    reference is not a mismatch, and the row pins the argument, not the order).
  - `a355aa7` — the stray `'(#disputable))'` paren from the TF1 split.
  - `32a0710` — `F.is_widget_visible()` in the shared fixture, replacing 20
    inline `love.state.user_input` reads across four spec files. Kept as a
    `love.state` read on purpose: that field IS the overlay contract (the draw
    loop paints while it is set, the console route forwards while it is set),
    so it is an honest observable, unlike the widget's own `is_shown()`.
    Deliberately NOT rewritten: the two rows that read the handle's *identity*
    and `project_open_liveness_spec`'s writes, which stub state, not observe it.
- Band 2 is **closed**. Next is band 3 — W7, the headless defect hunt (A1
  second-project overlay, A4 error lock, A5 tixy, guess reject freeze), the
  first band that can change production code.

### band 3 executed: W7 → W8 (2026-07-31)

Six commits. Suite **865 → 869**; two production defects found, reproduced
headlessly and fixed test-first. Both were invisible to the suite for reasons
worth carrying forward.

- **A1 — "no overlay when a project starts after Ctrl+Q from another project"
  (tixy 3, turtle 8, valid 9): REAL REGRESSION, FIXED** (`d6b3db4`, note
  `validation/notes/S24-W7-A1-second-project-overlay.md`).
  `stop_project_run` cleared `love.state.user_input` directly instead of asking
  the widget to hide, so `UserInputController.shown` stayed **true** after the
  project that raised it was gone. The next project's `show{}` hit the
  already-active guard (Decision 3), warned, and no-opped — leaving the
  previous project's text in a widget nobody could see. Every stop path arms it
  (all route through `stop_project_run`), and the flag starts down at boot,
  which is exactly report (9)'s "first project after boot" wording.
  - Fixed with `hide_overlay()` — take the overlay down THROUGH the widget.
  - **Why the suite was green:** the nearest teardown row starts its first
    project without an overlay; and `F.reset()` forced `widget.shown = false`
    every test under a comment calling it "state production neither creates nor
    observes". The fixture was compensating for the bug. That line is gone and
    the suite is green without it.
- **A4 + most of A5's UX asks — one defect: an input-only project's overlay was
  NEVER PAINTED. PRE-EXISTING (not a feature regression), FIXED** (`e80c644`,
  note `validation/notes/S24-W7-A4-A5-invisible-overlay.md`).
  The overlay had ONE paint site: the wrapper `set_love_update` installs when a
  project REPLACES `love.draw`. A project hooking no draw (guess, valid, repl,
  sapper) keeps the console's draw, which never painted it. Probe over the real
  `run_project`: drawing project 2 paints / 2 frames, non-drawing **0**.
  - Explains as one cause: "I don't see what I typed", "no prompt", "black
    instead of blue input bar", "no signal that I left the console", and
    **"it freezes"** — the error lock is real and correct, the error text IS
    rendered (probe: the rejecting submit re-renders with `Errors:/…` in the
    same keystroke), but into a canvas nobody blitted.
  - Byte-identical draw wiring at `3256aac`, so **not** ours; what changed is
    reachability — ruling (a) made input-only projects live for the first time.
    Fix is three lines in `set_love_draw`, reusing `get_user_input()` so the
    inspect gate (Decision 12) is inherited, not duplicated. **Owner smoke test
    should confirm the composition; reverting is those three lines.**
- **A5-tixy — BY DESIGN in the example.** The top-right text is `legend`,
  cleared by tixy's own `submit_body` (`legend = ""`): submitting your own
  formula retires the caption describing the canned one. No framework
  involvement.
- **guess reject-path — no project-specific defect.** `LineValidators({
  is_natural })` is submit-time and correct; the "freeze after entering a
  symbol" is the invisible error lock above. Noted for W8/W9: guess defines
  `is_natural` **twice**, the second shadowing the first (dead code).
- **W8** (`9ebeb46`): turtle's `after_submit` clear — the one in-scope example
  never migrated to Decision 6's continuity default.
- New for the **W9** queue, from this band: (i) turtle re-calls `show{}` on
  every `i` KEYRELEASE, including while the overlay is up and while typing a
  word containing "i" → warn + no-op each time; it belongs with the A3
  repeat-`show` ruling and with turtle's combo/hook migration. (ii) whether an
  error lock with no on-screen exit hint is acceptable now that it is visible.
  (iii) guess's duplicate `is_natural`.
- Band 3 is **closed**. Bands 1–3 are all closed; next is band 4 — **W9, the
  one owner sitting**, which is the first thing in this plan that needs the
  owner rather than the tree.

### bands 4–5 executed: W9 sitting + W10 (2026-07-31)

The sitting ran in one pass over `validation/reviews/S24-W9-ruling-sheet.md`
(twelve items; the sheet carries every ruling verbatim plus an execution
table). Eleven commits. Suite **871 / 0 / 0 / 3**.

- **Item 12 was escalated mid-sitting and is the substantive one.** Ruling 1
  asked turtle's `i` to check widget state — and it could not: a project's
  `love` is a deep clone, so `love.state.user_input` read inside a project is
  **always nil** (probed). maze's re-arm guard is that exact read, i.e. dead
  code, which is *why* it re-shows every tick. Owner ruled to expose
  `compy.input.is_shown()`; landed as **Decision 18**, closing the standing
  "No public `is_active()`-shaped visibility query" open decision.
- **Three rulings came back conditional and were resolved by checking, not
  assuming.** The error lock and repl's echo are both pre-feature (verified at
  `3256aac`: the lock there is *stricter*, and repl reprints there too), so
  nothing to reproduce and no re-escalation; and pointer handlers really are
  treated differently from keyboard ones (`hook_pointer` installs them as real
  `love.<event>` handlers), so the vocabulary rewrite owes the caveat the owner
  asked for — cited to the two ledger entries that already carry the
  asymmetry rather than duplicated.
- **Repeat-`show` was ruled the other way from the recommendation:** not a
  framework concern at all — the examples are at fault. turtle now hides on
  submit and opens only when closed; maze stays untouched (detached repo).
- The "Decision N revised" drop turned out to be 38 citations, not one
  heading — four controller files and three corpus docs.
- The wrapper rename is **deliberately deferred to just before the PR**, with
  a comment marking the names disputed so they are not silently re-approved a
  third time.
- Front matter with provenance fields is now a convention
  (`doc/development/conventions/docs.md`, indexed from `agents/rules.md`),
  applied to the persistent corpus first.
- **Open after this sitting:** the wrapper rename, the owner's smoke test of
  the overlay paint, and **W11 / Phase G** slice regeneration — which stays
  last precisely because the rename will move code.

### post-sitting corrections (2026-07-31, owner-raised)

Four owner observations after the W9 execution; three were right, one was a
hypothesis the history disproves.

- **PR assembly, front-matter era** (`56941dd`). The owner flagged that the
  1a/1b rule was written for "one HTML line". The rule survives — all 21 files
  in `1a` still carry the comment at TIP — but the check found something
  worse: `SET1` named three `conventions/` files individually, so the new
  `conventions/docs.md` fell outside **every** slice pathspec and would have
  vanished from the PR silently. `SET1` now names the directory; §4 states
  that its completeness check is what catches this class, with this as the
  worked example, and that it belongs after any commit that ADDS a file.
- **Error-lock exits: NOT drift** (`eadcc8c`). Hypothesis was that clearing on
  Left/Right/Space was an unpermitted relaxation, a side effect of the 2D
  limit work. History says otherwise: the frozen design §10 mandates
  "acknowledged **(Enter/Space/arrows)**", the widening landed under that AC
  with the reason in its message (`9bb6d29`), and no other commit touches that
  key list. `internals/user_input.md` described the wider set **at the PR
  base** while the code did Enter/Up/Down — the change aligned code to spec
  *and* doc. Narrowing it now would be an edit to a frozen document. Recorded
  so it is not re-opened as drift, with the quirk that does bite: an arrow
  acknowledges and is then swallowed instead of moving the caret.
- **Stale "no visibility predicate" paragraph** (`43bde2f`) — found by the
  owner's "recheck where that phrasing is used". `internals/user_input.md`
  still said there is no `is_shown()` and recommended the `love.state` read
  that never worked. The other four uses of the show-if-not-shown phrasing
  (project guide, turtle doc, turtle source, the test row) were consistent.
- **The keypressed/textinput race — REAL, and now fixed** (`0207617`,
  Decision 19). LÖVE delivers both events for one physical key with no
  ordering guarantee, so a project opening the overlay from a key races its
  own trigger. Reproduced: open on `keypressed('i')` → the field comes up
  containing `i`. turtle (open on release) is safe **only by luck** — with the
  textinput delivered last it fails identically, which is now a pinned row.
  Fix: an overlay shown from inside a keyboard/text event is **sealed** for
  the rest of that event batch (released at the start of `love.update`, which
  is exactly the batch boundary). Batch-scoped rather than key-matched on
  purpose: order-independent and no key→text mapping (`space` → `" "`,
  `shift+i` → `"I"`, IME output). A sealed overlay is still shown, so
  consumption reporting is unchanged. maze/sapper-style shows from `update` or
  a click are not sealed and stay live at once.

### nested example repos: their own commits, their own PRs (owner, 2026-07-31)

Owner directive: maze, keyboard and balloons are separate repos and each
should carry local commits and its own PR, following the platform PR closely.
This supersedes guardrail 3's "sanctioned, do not clean up" framing — what
looked like anomalies was the work-in-progress of those PRs.

- **maze** (`nagydani/Compy-maze`, `v3.4`, was in sync): the whole migration
  was sitting **uncommitted**. Committed as `790ac19`, with the dead guard
  fixed on the way in — `love.state.user_input` → `compy.input.is_shown()`
  (Decision 18). Deliberately NOT redesigned: since submit no longer closes
  the overlay or clears the field, `need_reopen`/`reopen_text` may be dead
  weight and "prompt only while idle" would need an explicit `hide()` — that
  is a game-design call for that repo, and the commit says so.
- **balloons** (`hleb-rubanau/compy-balloons`, `main`, was 1 ahead): the
  staged `terminal.lua` fix was the answer to smoke report 5 —
  `compy.input.after_submit = …` **raises** (frozen container), lifecycle
  callbacks live under `.callbacks`, and the re-show is gone since submit no
  longer closes. Committed as `94a5f02`; now 2 ahead.
- **keyboard** (`dsent/keyboard`, `dsent/dev`): clean and in sync, nothing of
  ours in it. Also answers smoke report 7 statically — it defines
  `love.keypressed`/`keyreleased`/`textinput` and uses `compy.audio`, never
  shows an overlay, and does **not** bypass the routes: those functions are
  captured and run as hooks inside the project route (Decision 10).
- Nothing pushed anywhere. `pr-assembly-guide.md` §1/§5 rewritten: Set 4 is
  not a slice of this PR but three sibling PRs, with each repo's remote,
  branch and commits listed.

### wrap (2026-08-01)

Owner contested Decision 19 as landed-without-ratification and corrected the
sibling-repo framing (we suggest complete migrations; we do not hand our API
change's consequences back to repo authors). Both recorded in
`validation/reviews/S24-contradictions.md`, with the third, weaker item (the
overlay paint awaiting a smoke test) alongside them. Decision 19 is now marked
contested in the ledger, the project guide and the code that implements it.

Distilled into `report.md`; successor `session25/prompt.md` commissioned as a
**revalidation** (session24 was cognitive-heavy), ordered C1 → C2 → re-evaluate
where the feature stands. Pointer in `agents/validation.md` repointed.

Session totals: 34 commits in `/repo`, 1 in maze, 1 in balloons; suite
861 → 874 / 0 / 0 / 3; nothing pushed anywhere.
