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

## 2026-08-10 — where the two non-supports belong, and an error of mine about the ledger

Owner asked whether *"no gui as modifier"* and *"no mod-only combos"* belong in the persistent
decisions corpus, and noted the two are connected.

- **They are the same rule from two sides:** membership of the modifier set is what makes a token a
  **modifier** rather than a **trigger**. Decision 21's one-trigger rule is why `alt+lalt` and bare
  `lalt` are unregistrable; dropping `gui` moves `lgui` across that same boundary the other way, so
  `shortcuts.keypressed['lgui']` starts working and `'gui+s'` starts raising.
- **Mod-only: already ruled, needs nothing.** Decision 21 says it verbatim — *"two triggers, or
  none, raises at registration"* — **and** rules the class guard. **This corrected §14.5**
  (`4258681c`), which had implied `is_mod` was emergent behaviour I found by reading. The guard is
  designed; only the `alt+lalt` string is debris, and debris stays out of the ledger.
- **`gui`: the ledger is not optional** — Decision 8 *states* the four-name precedence order, so
  removal retracts ratified text. Recommended a new decision (the modifier set is closed and is
  exactly ctrl/alt/shift) carrying the rationale, with Decision 8 amended to point at it. Also
  raised that filing a deliberate choice in the **debt** register misreads it as something someone
  should fix. **Not written — a new decision is ruling-shaped; awaiting the owner.**
- **My error, owner-corrected.** I claimed the ledger is not part of the stakeholder review
  surface. The frame says the PR must be **reviewable from the guide + description alone** — a
  sufficiency claim, so nobody is forced into `wip/77`; I read it as exclusivity. The ledger is in
  the persistent corpus and in the diff, and stakeholders will read it. Recorded in **§11.7**, with
  the consequence: a decision this sprint mints or retracts **owes a justification-table line**.
  Also noted there that session33's *"the guide cites no ledger"* ruling is about the **guide
  standing alone**, not about the ledger being private — which is probably where I picked the idea
  up.

## 2026-08-10 — Decision 31 written (owner: *"if they are made they have to be documented"*)

Owner ruled to add/update the decisions, adding the decisive point I had inverted: **a reviewer
will not see `wip/` docs at all** — they are transient and not in the PR — so a rationale that
lives only in the plan is a rationale the PR does not carry. `83af97db`.

- **Decision 31** — the modifier set is closed and is `ctrl`/`alt`/`shift`. Rationale: never
  requested, added for symmetry with the table-driven builder Decision 30 dissolves, so the row
  that was free becomes upkeep for a capability nobody asked for — Decision 30's own ground.
- **Written as a boundary, not a gap**, because it is observable: `gui+s` is refused at
  registration under Decision 21, and `lgui` becomes an ordinary bindable trigger. Stated there
  as the connection the owner spotted — **membership of the set is what makes a token a modifier
  rather than a trigger**, the same rule running both ways.
- **Decision 8 amended in place** (serialisation rule unchanged, only the list's membership
  moves); tombstone discipline, never renumbered.
- **Debt register: pointer, not defect.** The `gui_k` entry became *"supportable and deliberately
  not supported"*, naming Decision 31 as the authority, what re-adding takes, and *revisit when a
  requirement asks — not for symmetry, which is what put it there the first time.* Marked
  `PENDING` and **explicitly excluded from the five dissolution deletions**, since it records a
  choice rather than a defect.
- Internals precedence list dropped to three rows with the reason, inside the section's existing
  blanket marker. Marker count still 11 (one question marker retired, one entry marker added).
- **No new decision for the mod-only rule** — Decision 21 already states it verbatim. Minting one
  would give a ratified rule two homes to drift between.

## 2026-08-10 — the guide's ladder landed; harmony investigated; the debt reframed

- **Ladder correction applied** (`aa38dafa`): `doc/input_api.md` §"Held keys" now teaches three
  rungs and says outright they are not equal. `Key` introduced as something a project has. Still
  **zero** ledger citations in that guide (session33's naming ruling).
- **No gui tests** (owner): they would test an *instance* of a general rule — `check_combo`'s
  one-trigger check and "an ordinary key binds" — which is the 105-cases-for-105-characters trap.
- **Harmony, investigated at the owner's request.** Two hypotheses tested against base
  `3256aac`:
  - **The decisive find is not about harmony.** Base `key.lua` is 53 lines with **three**
    modifier pairs — **no `gui_k`, no `mod_triples`, no combo machinery**. `gui` entered in
    `c7083dda` (M2a), **this feature's own commit**. So Decision 31 reverts our own addition, in
    scope, and its rationale is now **verified rather than argued**.
  - **Harmony's gui is pre-existing** — byte-identical at base, from `4203de7f`, an ancestor of
    the PR base.
  - **Hypothesis (b), right shape wrong author:** the token map is **Emacs notation** — `C`/`M`/
    `S`/`A`/`H` is exactly Emacs's modifier alphabet. The tell is the collapsing: `Meta` *and*
    `Alt` → `lalt`, `Hyper` *and* `Super` → `lgui`, distinct modifiers upstream. Borrowed
    vocabulary, not an intended compy capability. Extends session30's §10 (*harmony is a statement
    of what the input interface used to be*) rather than contradicting it.
  - **Hypothesis (a), inverted:** the tokens have always been inert, and **Decision 30 alone would
    have activated them** — once the matcher reads the device, `Super-s` would serialise as
    `gui+s` for the first time ever. Decision 31 prevents that. It takes nothing from harmony.
  - **Retracted my own proposal** to remove harmony's tokens in the platform step: pre-existing
    code, swept into our PR, for no correctness gain.
- **Owner reframed the debt, and the reframing is the point.** Not *"harmony has misleading
  tokens"* — that implies harmony is broken and someone owes a fix, when **the feature's only
  obligation to harmony is to stay compatible**. Instead a framework-level observation:
  `capslock`, `tab`, `lgui`/`rgui` get **no special treatment** from shortcuts or `Key.is_mod`.
  Verified stronger than claimed — **no code outside `src/examples/` mentions capslock or tab at
  all**. Written to name the gap (no vocabulary for keys that are neither modifiers nor ordinary
  characters) while **favouring none of the three open directions**, with no scheduled revisit.
  `c53251a1`; the `gui` entry's revisit line softened so it no longer reads as the only route.

## 2026-08-10 — the tests step defined, and what the heal actually is

`6a0a3613`. Both corrections the owner's.

- **The heal is a defect in its own right, NOT part of the retirement.** The `textinput` ordering
  bug predates Decision 30 and would need fixing if the dissolution had never been proposed. What
  it blocks is **this sprint's closure** — a spinoff of the parent's Phase TF2, whose goal is
  clearing known defects before release (§0) — not the dissolution's. The orderings sequence it
  against the dissolution **without making it part of it**. Recorded in P9b's step and in the
  P14a–e row (*the dissolution ends at P14e*), including that this document's own phrase
  *"the reason the sprint exists"* **overstates it**: 187 remarks, of which this is one.
- **P14c defined as §11.4.1**, opening from the owner's framing — a **mechanism change plus one
  contract withdrawal**, so *"update the tests"* does not describe it. Governing principle stated
  first (**observable, contractable behaviour only**), which is why the step adds almost nothing.
- Two things it pins that are easy to get wrong: **the deletions are two kinds** — a withdrawn
  project-facing contract whose tests *are* its spec, and internals guards that die because their
  subject is gone (the one place the suite actually loses reach, which §11.7 owes the PR) — and
  **the mock's `held` table being a tracked set is not a contradiction**: Decision 30 objects to a
  model kept *beside* the device, and a mock **is** the device in tests.
- §5 states **what the step must not do**, including the owner's declined gui cases: they test an
  *instance* of a general rule, which argues for 105 more.
- Sections renumbered to follow step order — **11.4.1 tests, 11.4.2 examples** — refs updated.

## 2026-08-10 — the platform step defined (§11.4.2), and one finding that moves work

`cd4a30f5`. Written from the owner's commission. Sections renumbered again: **11.4.1 tests,
11.4.2 platform, 11.4.3 examples**.

- **Owner caught an overstatement of mine** in §11.4.1: *"deleting them **is** the dissolution"*.
  It dissolves **the spec of that contract**; the mechanism is still standing. Read the other way
  the tests step looks like the feature change. Corrected in place.
- **Inventory written by ROLE, not by file** — role is what answers remove-vs-rewire. Remove when
  the thing exists *because the set exists*; rewire when it has its own purpose and merely used
  it (`find_shortcut` is for matching, `combo_string` for serialisation — both keep their jobs,
  lose their argument).
- **The owner's adjacent-code rule, with its sharpest case:** `held_keys()` goes, its two
  memoisation upvalues go with it, and `build_input_surface` is rewired to **take no `get_keys`
  parameter at all** rather than be handed something else. *A parameter kept alive to receive a
  replacement is the mechanism surviving under a new name.*
- **FINDING — work moves between steps.** The rewritten combo cases **cannot land green in
  P14c**: they drive a patched `isDown` that today's table-reading builder ignores. Two standing
  rules collide — *suite green at every commit* vs *a fix commits with its breaking test* — and
  the second resolves it: **those cases belong in P14d**, as the breaking tests the change
  answers. P14c keeps only what is green alone (deletions, mock fix, fixture change).
- Docs obligations spelled out: `PENDING` → reality (**re-read the passage**, the §"Key state"
  marker over-covers), deprecation → absence (the five entries **deleted**, two of them one
  defect recorded twice; the `gui` and service-keys entries are **not** among them).
- **Must-nots**: no seam left for the set, **no touching `src/harmony/`**, no example fixes here,
  and the `NOTE` above `combo_string` keeps its allocation half only.

## 2026-08-10 — cold site enumeration run, and what it corrected

Sonnet sub-agent, **model passed explicitly**, read-only, given **no plan and no prior site
list** — so agreement is confirmation and disagreement is a finding. Prompt
`../../../validation/prompts/S35-dissolution-site-enumeration.md`, deliverable
`../../../validation/outcomes/S35-dissolution-site-enumeration.md`. `be7827f5`.

Owner's reason for running it **now** rather than at the top of the executing session: *I* hold
the context, so I can spot results that contradict intent — a cold session could not.

- **Agreement where it counts:** its framework inventory matches the plan's **exactly**. Nothing
  missed, nothing spurious. That is the result worth having before code moves.
- **CORRECTION 1 — the mock's `lgui`/`rgui` slots STAY.** My §14.1 gui enumeration had listed
  them for removal and was wrong: `tests/mock.lua` mocks the **device**, and a real keyboard still
  has Super keys. Decision 31 removes `gui` from the *modifier set*, not from the set of keys that
  exist; stripping the slots would leave the mock unable to represent a physically-held Super key,
  which is now an ordinary bindable trigger.
- **CORRECTION 2 — the examples step is smaller than it looked.** 11 read sites in the keyboard
  example, **9 needing no edit**: they read `INPUT.shift`/`.ctrl`/`.alt` and are insulated once
  the three proxy branches call `Key.*`. **The proxy is the seam.** Only `help.lua:11`
  (`INPUT.held.h`) and `modHeld` are edits.
- **CORRECTION 3 — `held` is a three-way homonym** here: the tracked set, the device mocks
  (tests + harmony), and `model/input/selection.lua`'s text-selection drag state. P14d's must-nots
  now say not to sweep on the word.
- Also superseded the corrections review's stale line proposing harmony's gui tokens for removal.
- **The LSP behaved exactly as the standing warning predicts:** every declared-symbol occurrence
  found, and **zero** of the ~30 that route through metatable `__index` dispatch on string keys.
  Grep was the only tool that saw those. Worth carrying forward as evidence, not folklore.

## 2026-08-10 — re-entry after container restart (context cleared, same session)

Re-entrance guardrail (sessions §2, row 2): `track.md` present, no `report.md` → **interrupted
before wrap**. Reconciled against `git log` + tree rather than restarted: HEAD `3213b465`, working
tree clean of tracked modifications (only the known untracked scratch + the three nested repos),
**suite 955 / 0 / 0 / 3** — matches the last entry, so nothing was lost mid-flight.

- **Where it stopped:** the spec corrections and the plan definitions are all landed and committed;
  the cold site enumeration (`be7827f5`) was the last unit. **P14c has not started** — no test or
  platform file has moved in this session.
- **Doc marker state verified:** 11 `PENDING` in the persistent corpus (1 guide, 3 internals, 1
  layers, 6 debt-register), as the last entry claims. `INTERIM:`/`REMARK:` still 27 in `src/`+`tests/`
  (P11's gate, not this step's).
- **Two loose ends confirmed unassigned to any step**, both from Part 1 and both still standing in
  the corrections table: **F6** (`internals/examples/keyboard.md` names the dissolved surface in
  four places, one of them *recommending* reading it — and it is P9b's design of record, read after
  P14d lands) and **F7** (`doc/development/tests.md:73` describes the NFR guards as held-key-table
  checks, unmarked). Raised with the owner before P14c starts.

## 2026-08-10 — the owner rules the three open ends; sapper is the interesting one

- **F6 — fixed in place, now** (`ffc21370`). Five sites, not the four the revalidation listed: the
  shipped-code contrast paragraph names the set too. Four were phrasing (*"the held set"* → the
  question actually being asked, true on both sides of Decision 30); the fifth is the one that
  mattered — the suggested hold requirement *recommended* reading the set, and now names
  `love.keyboard.isDown` with the reason it is the right rung, citing the guide's "Held keys".
  **The Caps Lock bullet was re-reasoned rather than reworded**: its rationale blamed the tracked
  set for something the set never did. What can go stale is the **device's** view — no release
  delivered, so the next press arrives flagged as a repeat — and the `isrepeat` exemption is what
  stops that freezing the estimate. **The example's own comment (`input.lua:162-167`) says the same
  wrong thing**; it is in the file P14e edits and P9b rewrites, so it is left to them, not fixed
  from here.
- **F7 — actualized, not marked** (`959dcc0d`, into P14c's housekeeping). The passage is **true
  today**; marking a true passage `PENDING` is exactly the noise Part 1 was asked to catch. It is
  corrected in the commit that deletes the guards.
- **sapper — RULED IN, and my deferral does not survive the owner's reading** (`2ebeb9ba`). Their
  framing: the machinery *is* combos on the click channels. **The check that settles it:** the class
  key folds **every** held modifier, so `'shift+*'` already means *shift and nothing else* — the
  four-site cascade is spelling out a match the matcher performs. So nothing is added, a
  hand-rolled copy of the matcher is deleted; "a real refactor" was the wrong description.
- **Two deviations found while verifying, written into the step so they are stated not discovered:**
  derived clicks are **button 1, counted on release, resolved after the window, dropped on drift**
  (`controller.lua:936-941`) where `love.mousepressed` acts on any button at press time; and the
  cascade's implicit *"every other combination does nothing"* has **no shortcut expression** — an
  unclaimed modified click (alt alone, ctrl+shift) falls through to the hook and acts as a plain
  click. Recommended accepting the widening; re-growing a guard would keep the cascade.
- **Fourth instance of the sprint's recurring pattern**, now with a framework-level edge: `modHeld`
  copies `Key.ctrl()`, `is_shift_down()` copies `Key.shift()`, the polls copy `keypressed`, and
  sapper copies **class matching itself**.

## 2026-08-10 — EXECUTION: P14c, the tests step, in five commits

Mode transition named and taken on the owner's go. Suite at each commit, in order: 955 (mock fix,
no count change) → 948 → 944 → 940 → 940. Arithmetic reconciled in every message.

- `d630d12f` **mock fix, alone.** `isDown` variadic + `rctrl`/`rshift`/`ralt` tokens. The
  left-hand tokens are Emacs letters and the right-hand keys have none, so a test names the key.
- `6ea411ab` **the withdrawn contract's spec** — 7 cases. **The step's range was WRONG and I did
  not inherit it:** it said `:781-901`; the contract ends at `:863` and `:865-899` are the two
  **widget uniform-signature** cases, Decision 26's own contract, live and unrelated. The planned
  cut would have deleted them silently. Session33 "re-verified" this range — a re-verification
  that checked the start and not the end.
- `8fd6d589` **the dead NFR guards** — 4 cases, deliberately a separate commit: this is the one
  place the suite loses reach, and the PR owes a reader that distinction. F7's `tests.md` line
  actualized in the same commit, plus the same enumeration inside the spec file, which nobody had
  listed.
- `e3d94104` **rename + citations.** `keys_pressed_spec.lua` → `input_combo_serialisation_spec.lua`
  (matches the documented `input_*_spec.lua` convention; the survivor keeps Decision 8). Deleting
  the block also killed the **startup-wiring preamble**, which falsifies `event_dispatch_layers.md`
  **independently of the rename** — the plan predicted exactly this and it held.
- `2aaf07c1` **the fixture holds modifiers on the device.** `mock.hold/unhold`, wired into
  `press`/`repeat_press`/`release` in the order hardware guarantees, and lifted in `F.reset()`.

**Two findings from the fixture change, and the second is the one that matters.**

- **13 cases failed on device leakage** before the reset was added: `chord()` never releases, so a
  modifier stayed down into the next test. The tracked set had `F.reset()`; the device had nothing.
- **A real, pre-existing shadowing became testable for the first time.** Three cases registered a
  project shortcut on **Ctrl+S** and asserted it fires. The gateway's power shortcuts **poll the
  device**, and Ctrl+S stops a running project *before* dispatch reaches the route — so in
  production that binding never fires. They passed only because the fixture's device was blank.
  Moved to `ctrl+j` with the reason in a comment; their subject is normalisation, not who wins.
  **Not this step's business to fix** — P9e is withdrawn and the gates' polling is settled — but it
  is a fixture-fidelity defect of the class S7 was about, found by making the fixture honest.
- `Controller.keys_pressed = { }` **stays** in `F.reset()`: it goes with the field, in P14d.
  Removing the reset while the field still exists would leak set state between tests, and this
  branch owns two order-dependent cases already.
- **Delegated** the rename's blast-radius sweep to a Sonnet worker (model passed explicitly,
  read-only, prompt of record in `validation/prompts/`), rather than trusting my own three known
  citations as complete.

## 2026-08-10 — the sweep reports: the rename is clean, and it found one unrelated lie

Deliverable `../../../validation/outcomes/S35-keys-pressed-spec-citation-sweep.md`.

- **No dangling citation of the renamed spec anywhere in the tracked tree.** The three I fixed in
  `e3d94104` were the whole set; the four deleted case names and `kp_handler`/`kr_handler` occur
  nowhere. Every `setup_callback_handlers` citation still resolves.
- **Two stale entries in `.claude/settings.local.json`** naming the old path. Untracked harness
  config, not repo content, and a stale allow-entry is inert — **reported to the owner, not
  edited.** Their settings are not mine to sweep.
- **`tests.md` quoted a live suite count (861) as fact** — pre-existing drift, wrong long before
  this session and made worse by it. Fixed by removing the number rather than updating it: it is a
  moving quantity in a persistent document, and the sentence's claim is about the **3 pending**
  being named gaps, which needs no success count to stand.
- **The LSP returned phantom references to the deleted file** and stale line content, plus two
  nonexistent `.tmp.*` shadow paths — index lag after a `git mv`. Second session running in which
  grep is the tool that told the truth; the worker cross-checked and did not report the phantoms as
  findings, which is the behaviour the briefing asked for.
