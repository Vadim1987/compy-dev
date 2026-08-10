# session35 — track

## 2026-08-10 — boot

- Booted per `agents/validation.md` → `agents/sessions.md`. **Fresh start**: session35 held only
  `prompt.md`; no `track.md` / `report.md` (sessions §2 row 1). Track opened now.
- HEAD `5c405575` "docs(session34): wrap — report, session35 prompt, repointed pointer", branch
  `feature/77-newapi-analysis-s20260615`. Working tree: **no tracked modifications** — only the
  known untracked scratch (`claude.sh`, `src/STEPS.md`, `input-pr-slices.tar.gz`,
  `doc/tall_blocks.md`, `doc/development/wip/{clarification,personal-notes,pull-26}/`) and the
  three nested example repos.
- **Baseline confirmed: `busted tests` → 955 / 0 / 0 / 3.** Matches the prompt.
- Read in full: `agents/validation.md`, `agents/sessions.md`, this prompt, session34's
  `report.md` + `prompt.md` + `track.md`, `agents/rules/revalidation.md`.
- Task restated to the owner before any work, at their request. **Mode: research + analysis
  (revalidation)** — Part 1 only; Part 2 (tests, then platform code) is execution and is gated
  on the owner's go after the findings report.

## 2026-08-10 — Part 1 done: the spec revalidation

Report: `../../../validation/reviews/S35-spec-revalidation.md`. Done inline, no sub-agent —
the briefing would have cost more than the work, and every claim needed verifying in code by
the same reader who has to write the tests. Tree untouched.

- **Spec verdict: sound.** Markers honest in both directions (all 11 name something genuinely
  not true yet), guide accurate today, ledger tombstones hold, the mock's stated defect is real
  in code.
- **Three things gate the tests.** (1) The `gui` row is not only a platform decision — the
  seventh combo test case asserts `'ctrl+alt+shift+gui+s'` and cannot be rewritten without the
  ruling; recommend adding `Key.gui()` since every already-written document stays true.
  (2) Removing the field **crashes** the keyboard example — the frozen view returns nil silently,
  `modHeld` indexes it — and the internals guide already claims that example reads the device,
  inside the marker the platform step clears. (3) Nothing says whether a modifier's own press
  still serialises as `alt+lalt`; today the gateway's first line guarantees it, after the change
  the device does, and the mock does not do it for free.
- **The docs sweep missed a fourth persistent document**: `internals/examples/keyboard.md`, which
  is P9b's design of record and *recommends* reading the dissolved set. P9b now runs after the
  platform code, so it would be read after the surface is gone.
- **Citation rot is broad but pre-existing** (`git log -S` on each): the layers guide is off by
  ~88 lines on the gateway, the internals guide cites two ranges past end-of-file, and the
  in-code `DEFERRED` marker it names exists nowhere in `src/` or `tests/`.
- **Reported and stopped** per the prompt's gate. No code moved.

## 2026-08-10 — owner pivots the session: the spec is wrong in two places, fix it

Corrections written to `../../../validation/reviews/S35-spec-corrections.md`. The session's task
is no longer "tests then platform code" — it is **fix the spec first**. Mode stays
research/evaluation until the corrections are agreed; execution after.

- **(1) `Key`, not `love.keyboard`, is what a project consults.** A ladder, not a binary:
  shortcuts/combos first; `Key.*` inside project code is *permitted but a symptom of possible
  tech debt*; `love.keyboard` is the *method of last resort*, legitimate only where `Key` has no
  answer (keycap visualisation). The guide teaches the last rung as the recommendation — my F2
  inherited the error, and my "clean bill" citing turtle/clock as proof is **withdrawn**: they
  are work items, not evidence.
- Verified: `Key` is a global required at boot and **already the project idiom** (sapper ×4,
  tixy, paint). **Harmony is safe** — its `patch_isDown` is variadic (`init.lua:242-253`),
  unlike the test mock. To update: turtle (**two** sites, not one), clock, and the keyboard
  example's `modHeld`.
- **(2) `gui` goes** — never requested, added for symmetry with the shape now dissolved. Out of
  code, tests and docs; one debt-register line saying it is supportable in principle and
  purposefully unsupported. **This supersedes my F1** (add `Key.gui()`) and dissolves the
  question instead of answering it — the same argument Decision 30 applies to the tracked set.
- Enumerated traces incl. two nobody had listed: **harmony's `Super`/`Hyper`/`H` token map**
  (dead — no scenario uses it) and **Decision 8 names `gui` in its precedence list** (`:392`),
  so the ledger needs an in-place amendment, session34's Decision-21 precedent.
- Two behavioural consequences recorded rather than hidden: registering `'gui+s'` starts failing
  loudly (`gui` reads as a second trigger), and a Super press stops being modifier-shaped, so a
  registered `'ctrl+*'` class would now catch it.

## 2026-08-10 — plan adjusted: the detached examples get a reconciliation step

Owner: `modHeld` re-implements `Key.ctrl()`'s folding over the dissolved table, so it **goes**
rather than being converted — and more generally the sprint owed a step reconciling the
**detached** examples with the removal. **The step existed but was scoped to `keyboard` alone**,
so it is rescoped, not added: amendment in P14e's own step (the plan's rule), reasoning in a new
§14, and the §4 P14a–e row updated for both this and the spec corrections.

- Swept the three repos to scope it rather than assert it: **`maze`'s `is_shift_down()`
  (`main.lua:562-565`) is `Key.shift()` written out by hand** — the same duplication as `modHeld`,
  in a second repo, which nobody had named; **`balloons` is clean** (overlay API only) and is
  recorded as clean so the sweep is not re-derived; **`keyboard` gains `help.lua:11`**, the only
  consumer of the `held` branch and not previously listed.
- Guarded explicitly against reading as a reopened ruling: this is **not** the blanket example
  sweep the owner ruled out — one named platform change is the trigger, and an empty repo is
  closed, not searched.
- `maze:517`'s `isDown('tab')` **stays** — a non-modifier key is the legitimate last rung.
- Left open unchanged: whether the examples step must precede the heal. The rescope widens the
  question (P14e now touches maze, which the heal does not) but does not settle it.
- Suite 955/0/0/3, unchanged — plan-document edit only.

## 2026-08-10 — owner rules both open ends: the examples step precedes the heal, and reaches in-repo

- **Ordering RULED.** §13's open question is closed: **P14a → P14c → P14d → P14e → P9b**. Third
  application of one argument — the heal is designed against the approved design, then landed
  code, now reconciled examples; sharpest here because the two steps edit the same file. Written
  into P9b's step (old text struck, not deleted), P14e's step, the §4 row, and §14.3.
- **Scope RULED wider: in-repo examples too.** Swept before writing, so the step is enumerated,
  not open-ended: **`turtle` (2 sites) and `clock` (1)** are the only conversions; **`tixy`,
  `paint`** already sit at the right rung; **`pong` stays** at the last rung — it polls arbitrary
  keys, and its README teaches the same correctly; **`guess`, `life`, `repl`, `sine`, `valid`**
  read no held state.
- **`sapper` is the one judgement call** — four call sites repeating `not Key.shift() and not
  Key.alt() and not Key.ctrl()`, exactly the cascade the guide says combos replace. **Flagged,
  not converted**: it works, the conversion is a real refactor, and a sprint removing a moving
  part should not add one in the same breath. Debt-register entry if declined.
- Boundary restated in the plan so this does not read as reopening *"no blanket example sweep"*:
  **only held-state reads are swept, triggered by two named changes** (the removal, the ladder);
  an example with none is closed, not searched.
- `keyboard/input.lua:99`'s `setTextInput` named as **out of scope** — an IME toggle, not a
  held-state read, and the kind of thing a later sweep would otherwise catch by pattern.

## 2026-08-10 — owner hint: some of these reads are combos written out by hand

Owner on maze's `tab` poll: *likely a combo equivalent, and there could be more, especially in
maze and keyboard.* Recorded as **§14.4, a hint not a work list**. Scanned to make it useful.

- **Third instance of one pattern.** `modHeld` re-implements `Key.ctrl()`'s folding;
  `is_shift_down()` re-implements `Key.shift()`; now polls re-implement `keypressed`. The
  examples keep rebuilding framework mechanisms over lower-level APIs.
- **Discriminator recorded** so the hint stays falsifiable: *"is it held right now"* is a correct
  poll (Decision 30's own argument); *"did it just happen"* / *"was it modified"* rebuilt from a
  poll is an event or combo by hand.
- **Found:** maze's `poll_tab_progression` (`:514-526`) keeps a `tab_was_down` mirror and derives
  an edge — a discrete question on frame-time machinery, **and the same bug class the sprint is
  removing**: a flag mirroring a key with nothing to reconcile it. maze's `love.keypressed` doing
  `k == 'escape' and not is_shift_down()` is `shift+escape` vs `escape` — **this supersedes my own
  earlier recommendation** to convert it to `Key.shift()`, which is only the middle rung. keyboard's
  `alt.lua:203` hand-matches the combo its own comment calls *"Ctrl+Alt+H"*; `help.lua:11` spans
  frames, so it is the flag-shortcut shape.
- **Excluded on purpose, both directions:** `appTextinput`'s alt/ctrl refusal is **P9b's** to
  redesign and `textinput` carries no key; pong's paddle polls and the keycap renderer are the
  *correct* poll and are named as the counter-examples that keep the hint honest.
- **Scope guard written in:** this could turn a reconciliation into an example rewrite. Small and
  obviously behaviour-preserving conversions only; the rest goes to the debt register like
  sapper's cascade.
- Amended the step's earlier *"isDown('tab') stays"* line — it read as settled and is not.

## 2026-08-10 — the examples step factored out of the table (owner-approved)

Caught by the owner asking where I had written the hint: my two rescopes were inserted **ahead of**
the original cell text, orphaning the sentence that followed (*"They were each updated once…"* had
lost its subject). Repaired first (`006acba1`), then the structural fix.

- The P14e cell had reached **639 words in one table row** — an ordering ruling, two rescopes,
  three repos, seven examples, a flagged call and a hint pointer, run together. Exactly what the
  owner has said twice they cannot reason over.
- **Kept in the plan as §11.4.1, not moved to a separate doc.** The owner left the choice to me;
  a second document is a second place a change could live, which is precisely the failure the
  plan's *"the amendment goes in the step"* rule exists to prevent — and that failure cost two
  sessions. §11.4.1 is inside the operative contents section, so the rule holds trivially.
- Row is now **117 words** and points down. §11.4.1 is headed **OPERATIVE** and says amendments
  belong in it, so it cannot be mistaken for the reasoning sections.
- **§14.4 trimmed to its dated-record role** — provenance, the falsifiable discriminator, and why
  the hint is capped; the leads themselves moved to §11.4.1. Cross-linked both ways, plus the §4
  row.
- Suite 955/0/0/3 throughout.

## 2026-08-10 — modifier's own press: ruled accidental, unsupported; guard-first hint into the step

Owner: *"a corner case we never seriously considered — it became an accidental rule, we do not have
to support it."* **This closes F3** by refusing its premise rather than answering it.

- **Answer to the owner's question:** left Alt still builds **`alt+lalt`** — unchanged string, new
  source (the device instead of the gateway's first line).
- **The finding that makes it safe to ignore:** that string, *and* the bare `'lalt'` the
  same-frame-release corner produces, are **both unregistrable** — `check_combo` folds every token,
  finds no trigger and raises. So the lookup can never hit in either direction, and `is_mod` then
  stops the class fallback.
- **Placement, owner's instruction and my one addition.** They put the guard-first simplification
  in the step spec as a tactical hint — correct, and it went into **P14d**. I added that the
  *ruling* still needs a durable home (**§14.5**), or a later session rediscovers `alt+lalt` and
  "fixes" it; the hint alone would not stop that. **P14c** carries the operative half: **no test
  pins it** — pinning an accident is how it becomes a contract.
- Also written into P14d: dropping `gui` makes `Key.is_mod('lgui')` false, so
  `shortcuts.keypressed['lgui']` becomes a **registrable binding firing on a Super press**. New
  reachable behaviour, named in the debt entry rather than left to be found.
