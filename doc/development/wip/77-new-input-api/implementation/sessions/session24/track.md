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
