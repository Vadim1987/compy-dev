---
description: Per-entry mechanical evidence for every RETIRED debt entry — resolution-at-HEAD and presence-at-base-3256aac, with a proposed (not ruled) classification
status: sub-agent outcome
audience: developer
authored: llm
session: 68
date: 2026-09-03
---

# `FIX-02-05` base evidence — session68

**Entry count, today (2026-09-03):** `input.md` `## RETIRED` = **50** entries (`### ` headings from
line 1331 to 2715, counted with `awk 'NR>=1329' input.md | grep -c '^### '`). `general.md`
`## RETIRED` = **6** entries (line 337 to 442, same method). **Total 56.** This supersedes every
earlier count cited elsewhere (20/46/47/51/55) per the commission — this is the one to use.

**Not classifying with authority.** Each row below is evidence plus a *proposed* classification;
the parent session rules.

---

## Summary of proposed classifications (56 entries)

- **INTRODUCED-IN-BRANCH: 39**
- **PRE-EXISTING: 9**
- **MIXED: 5**
- **CANNOT TELL: 3**

By file: `general.md` — 5 INTRODUCED-IN-BRANCH, 1 MIXED. `input.md` — 34 INTRODUCED-IN-BRANCH,
9 PRE-EXISTING, 4 MIXED, 3 CANNOT TELL.

**The single largest surprise, and worth the parent's attention:** the overwhelming majority of the
`RETIRED` section is `INTRODUCED-IN-BRANCH`, not because the register is padded, but because the
subject of nearly every entry — `compy.input`/`build_widget_api`, `doc/input_api.md`, the combo/
shortcut grammar in `key.lua`'s `check_combo`/`split_combo`/`normalize_combo`, the decisions ledger,
the whole `doc/development/wip` tree — is **itself absent at base**, confirmed directly (`git
ls-tree`/`git grep` against `3256aac`) rather than assumed. A defect in a surface that didn't exist
outside this branch cannot be pre-existing by construction; this register is largely the branch's own
paid-down construction debt, not inherited defects it happened to also fix. The 9 `PRE-EXISTING`
entries are the genuine exceptions and are the more interesting rows for `CHG-01-03`
(changelog-worthy fixes to something a user could have met before this release) — see the list below.

## The 9 entries proposed `PRE-EXISTING` — likely `CHG-01-03` candidates

1. `set_text`'s list branch does not split embedded newlines — `input.md:1759` (table branch was
   `InputText(text)`, no split, at base — measured byte-for-byte)
2. `set_text`'s two branches disagreed about the cursor, and the call was dead — `input.md:1834`
   (the string/table asymmetry itself measured present at base)
3. T-MULTILINE-STR — `set_text` silently ignores a multi-line string — `input.md:2012` (the
   `n_added == 1` guard measured present at base)
4. `wrap` guards the `xpcall` arity hazard on the platform, not the capability — `input.md:2102`
   (base `wrap` has the `_G.web` branch, measured)
5. `love.handlers.userinput` is dead code — `input.md:2304` (the dead push site measured present at
   base)
6. `wrap`'s error handler is called with the wrong arity, so project raises vanish — `input.md:2184`
   (base `wrap`'s single-argument `xpcall(f, user_error_handler, ...)` measured present)
7. `UserInputController:keypressed` forked on `app_state == 'editor'` — `input.md:2637` (the fork
   measured present at base, at a different line)
8. `userlove` does not convey its semantics — `input.md:2691` (the identifier itself measured
   present at base; the entry is a ruling not to rename it)
9. The console's prompt is drawn under a project that never takes over `love.draw` — `input.md:2715`
   (the drawing mechanism measured unchanged in shape at base)

## Entries whose resolution claim (a) could not be fully confirmed, or was confirmed only partially

None of the below overturn a `HOLDS` into a failure — every one still reads as resolved on the
evidence gathered — but each rests on something I did not independently re-derive, usually because
doing so would mean running the test suite (forbidden) or re-tracing a call graph deeper than a grep
sweep reaches. Listed by name so the parent can decide whether any is worth a dedicated re-check:

- **The class diagrams show a model field that no longer exists** (`input.md:1394`) — did not
  re-walk all seven mermaid files' 32 class blocks myself; relied on the entry's own cited
  `S67-mermaid-audit.md` evidence for everything except the one `editor.md` line I measured directly.
- **The set of accepted config keys has no single home** (`input.md:1480`) — spec file's existence
  confirmed; its "mutation-tested in both directions" claim was read, not re-run (suite is out of
  scope for this commission).
- **The callable config keys are unchecked** (`input.md:1595`) — confirmed the call sites would
  raise on a non-callable; did not execute to see the literal error string.
- **T-CURSOR-BYTES** (`input.md:1954`) — confirmed the branch-new functions are absent at base and
  `string.ulen` is used at HEAD; did not re-run the `'привет'` mutation example or independently
  re-verify `move_cursor`'s pre-existing byte-bound claim (taken from the sibling BACKLOG entry's own
  evidence).
- **Project-handler wrapping: dedup the guard** (`input.md:2269`) — the named function
  (`chain_project_handler`) no longer exists under that name at HEAD; the outcome (no
  `wrapped_native`/`keyboard_native`/`chain_native`) holds, but I could not fully re-confirm "the
  guard exists exactly once" given intervening refactors not described by this entry. Flagged
  `PARTIAL` in its own row.
- **Input-only / pointer-only projects stay live in `project_open`** (`input.md:2312`) — did not
  re-verify the "byte-identical on `master` pre-`0022004`" claim (outside this commission's base ref
  and read-only-grep scope).
- **A combo table cannot express a modifier-class rule** (`input.md:2513`) — did not re-verify the
  "never matches the modifier's own press" edge case.
- **Combo-string dispatch allocates a table per call** (`input.md:2551`) — did not re-verify the
  `find_shortcut` double-call detail.
- **`F.reset()` test helper exceeds the 14-line function-body limit** (`input.md:2569`) — HEAD count
  is 11 executable lines, not the "nine" the entry states; still well under the 14-line limit, so the
  substantive claim holds, but the specific figure has drifted.
- **`submit()`'s deliver-then-hide ordering** (`input.md:2581`) — did not exhaustively confirm base
  had no other hide-on-submit path beyond what I read.
- **Pointer delivery is an unstructured broadcast, not a chain** (`input.md:2613`) — the weakest-
  evidence row in this pass: did not trace the dispatch call graph to confirm pointer and keyboard
  share one function, and did not re-derive the "measured across `life`, `sapper`, `tixy`, `paint`
  and `pong`" claim.
- **Comment wip-citation cleanup** (`input.md:2662`) — confirmed for `src/controller/`; did not
  re-check the four shipped-example files or re-derive the "thirteen across seven files" count.

## Structurally CANNOT TELL — separate repos with no pin to the platform base

Three entries have their subject in `src/examples/maze` or `src/examples/balloons` — **untracked,
independently-versioned sibling repos** (confirmed via `git status --porcelain`, each has its own
`.git` and remote), not part of `/repo`'s tree at `3256aac` in any revision. Their (a) resolution
claims all `HOLD` (confirmed against each repo's own current state); their (b) base-provenance
question has no well-formed answer through this commission's method, because there is no comparable
platform-base commit inside a sibling repo's own history:

- T-MAZE-NEUTRALIZE (`input.md:1885`)
- T-BALLOON-LABEL (`input.md:1920`)
- An `update_prompt` endpoint was asked for and declined (`input.md:2675`)

---

## `general.md` — `## RETIRED` (6 entries)

**Scope note before the batch:** `git ls-tree -d 3256aac -- doc/development/wip` returns nothing —
the whole `doc/development/wip` tree is **absent at base**; it is this feature's own working
directory, created inside the branch. That single fact answers (b) for every entry below whose
subject lives under `doc/development/wip/77-new-input-api/` without opening any file there (a tree
listing is a path check, not content) — and the commission forbids opening files under that path
anyway, so entries 1–2 below are marked NOT CHECKABLE for (a) on that ground and PRESUMED ABSENT for
(b) on the tree-listing ground alone.

**Slip during this batch, reported per the commission's honesty requirement:** while sizing entry 5
below I ran `git grep -nE "Decisions? [0-9]+" -- ... doc` (a `doc`-wide pathspec) once before
narrowing it, which printed matching lines from several files under `doc/development/wip/` into my
own output before I caught it and re-ran with the path excluded. I did not read or act on that
content beyond noticing it was there (informal "Decision N" phrasing in session tracks, not a
citation the entry's claim governs) and no finding below rests on it. Flagged rather than hidden,
per the commission.

### 1. A renumber shipped its crosswalk without the sweep, and five citations resolved to the wrong pass (RESOLVED, 2026-09-02) — `general.md:337`

- **Claim:** a scope error in an earlier sweep left five citations (two in `ROADMAP.md`, three in
  the feature's `validation/` tree) pointing at the wrong pass after an `ACC` renumber; all were
  repointed and `validation/plan.md`'s duplicate row table was deleted rather than renumbered.
- **(a) Resolution at HEAD:** `NOT CHECKABLE` — every named artifact (`wip/77-new-input-api/ROADMAP.md`,
  `validation/plan.md`, two `validation/outcomes/reviews` files) is under
  `doc/development/wip/77-new-input-api/`, which the commission forbids opening. No command run.
- **(b) At base `3256aac`:** `ABSENT` — `git ls-tree -d 3256aac -- doc/development/wip` (empty
  output); the whole working-tree directory these citations live in did not exist at base.
- **Self-declared provenance:** the entry is explicitly about the feature's own planning documents
  and a renumber this branch performed; nothing claims pre-existing.
- **Proposed classification:** `INTRODUCED-IN-BRANCH` — the defect (a stale citation inside a
  branch-created planning tree) could not have existed before the tree did. High confidence on (b)
  despite (a) being unchecked: a doc that didn't exist at base cannot have a pre-existing citation
  bug, whatever HEAD's fix turns out to look like.

### 2. The `FIX-02` renumber's own citations were never swept (RESOLVED, 2026-09-02) — `general.md:366`

- **Claim:** an earlier `FIX-02` renumber left five `ROADMAP.md` citations naming `FIX-02-01` to mean
  a row that is now `FIX-02-07`; four were repointed and two parked questions marked ANSWERED.
- **(a) Resolution at HEAD:** `NOT CHECKABLE` — subject is `wip/77-new-input-api/ROADMAP.md`, out of
  scope to open. No command run.
- **(b) At base `3256aac`:** `ABSENT`, same ground as entry 1 — the roadmap file lives under
  `doc/development/wip`, which is entirely absent at base.
- **Self-declared provenance:** entry calls the underlying citation drift "pre-existing" relative to
  the 2026-09-02 `ACC` splits (i.e., older than that specific renumber) but it is still entirely
  inside the branch's own working tree — "pre-existing" here means *before the most recent sweep*,
  not *before the branch*.
- **Proposed classification:** `INTRODUCED-IN-BRANCH` — same reasoning as entry 1: the subject tree
  postdates the base wholesale.

### 3. `ledgers.md` still called unruled the question it had just ruled (RESOLVED, 2026-09-02) — `general.md:387`

- **Claim:** `agents/rules/ledgers.md` §6 used to say "where vacuumed entries go... remains unruled"
  after §2 had just ruled it ("Vacuuming is a move, not a deletion"); the closing paragraph now
  points at §2 instead of contradicting it.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "Vacuuming is a move\|remains unruled\|record and not
  a second ledger" /repo/agents/rules/ledgers.md` → line 66 has the §2 heading "Vacuuming is a move,
  not a deletion"; line 234 (read directly) reads *"**Where** vacuumed entries go is ruled at §2,
  ... an archive under the feature's working tree, which is a **record**, not a second ledger"* — the
  "remains unruled" wording is gone and the paragraph now cross-references §2 as claimed.
- **(b) At base `3256aac`:** `ABSENT`. `git ls-tree 3256aac -- agents/rules/ledgers.md` and
  `git ls-tree -d 3256aac -- agents` both return empty — the whole `agents/` rule tree does not exist
  at base.
- **Self-declared provenance:** not stated explicitly, but the subject is a rule file governing this
  branch's own ledger conventions.
- **Proposed classification:** `INTRODUCED-IN-BRANCH` — a rule file that is entirely absent at base
  cannot carry a pre-existing internal contradiction.

### 4. The crosswalk pointed at a section deleted two hours after it was written (RESOLVED, 2026-09-02) — `general.md:401`

- **Claim:** `decisions/input.md`'s Decision-16 crosswalk row cited a section (`D-ONE-LIFETIME`,
  "what it reverses") removed hours after the citation was written; also miscounted vacuumed
  decisions as seven where six is right. Both now fixed.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "Decision 16"` → line 1846: `| Decision 16 | — |
  **removed**; superseded by \`D-ONE-LIFETIME\` and \`D-BUTTON-TRIGGER\`, and it left nothing behind
  in the corpus |` — states supersession only, no dangling section citation. Read lines 1860–1874:
  *"**The six that were vacuumed are archived**... (Seven rows map to nothing: Decision 19 is the
  seventh, and it never existed to archive.)"* — matches the claimed fix exactly (six counted, the
  seventh named and distinguished).
- **(b) At base `3256aac`:** `ABSENT`. `git ls-tree 3256aac -- doc/development/decisions/input.md`
  returns empty — the decisions ledger does not exist at base at all.
- **Self-declared provenance:** none claimed as pre-existing; explicitly an artifact of this branch's
  own decisions-ledger conversion work.
- **Proposed classification:** `INTRODUCED-IN-BRANCH` — subject file absent at base.

### 5. The decisions ledger is cited by number — PAID by the conversion to names (2026-09-01) — `general.md:422`

- **Claim:** (was `T-DEC-NUMBERED`) decisions converted from numbers to `D-` mnemonic names; 31
  decisions carry a slug; `Decisions? [0-9]+` returns zero across `src/`, `tests/`, the persistent
  corpus and `agents/` (excluding the crosswalk appendix itself, which is kept deliberately).
- **(a) Resolution at HEAD:** `HOLDS`, with one caveat. `grep -c "^## D-"
  /repo/doc/development/decisions/input.md` → **31**, matching the claim exactly. Numbered-citation
  sweep: `git grep -clE "Decisions? [0-9]+" -- src tests agents 'doc/development/decisions'
  'doc/development/internals' 'doc/development/conventions' 'doc/development/technical_debt'
  'doc/development/*.md'` → hits only in `doc/development/decisions/input.md` (the crosswalk table
  itself, explicitly kept as an appendix — lines like `| Decision 1 | \`D-ROUTE-OWNS\` | |` — and one
  explanatory line about the old convention) and `doc/development/technical_debt/general.md` (this
  entry's own prose, quoting itself). No hits in `src/`, `tests/`, or `agents/`. The claim "returns
  zero" is true of citations outside the crosswalk appendix the entry itself says survives; read
  literally against the raw pattern it is not exactly zero, but every non-zero hit is the kept
  appendix or a self-quotation, which the entry's own text anticipates ("appendix... outlives the
  feature's working tree").
- **(b) At base `3256aac`:** `ABSENT`. `doc/development/decisions/input.md` does not exist at base
  (empty `git ls-tree`); `agents/` does not exist at base either. The numbered-decision convention
  this entry retires is entirely a branch invention.
- **Self-declared provenance:** none claimed pre-existing.
- **Proposed classification:** `INTRODUCED-IN-BRANCH` — subject and its predecessor both postdate
  base.

### 6. T-NAMESPACE-CLONE — a live platform table in a namespace travels to the project as a copy — PAID by a written practice (RESOLVED, 2026-08-30) — `general.md:442`

- **Claim:** the hazard (a namespace field holding a live table gets deep-cloned into the project
  env, so writes to the copy are invisible to the original) is now written down as a practice in
  `conventions/architecture_principles.md`, "A Namespace Hands Out Live Tables by Reference, Never by
  Value"; the code already implements the pattern in both places (`compy.input`, `serial`) that
  matter.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "Namespace Hands Out Live Tables"
  /repo/doc/development/conventions/architecture_principles.md` → line 80, heading present as named.
- **(b) At base `3256aac`:** `CHANGED SHAPE`. The **file** exists at base (`git show
  3256aac:doc/development/conventions/architecture_principles.md | wc -l` → 82 lines) but the
  **section** does not: `git grep -n "Namespace Hands Out Live Tables" 3256aac --
  doc/development/conventions` → no hit. So the file is pre-existing (another author's), the
  practice section is branch-added.
- **Self-declared provenance:** entry says `compy.input` "already dodged it" (implying the mechanism
  itself, `__index`-backed field, predates the writeup) and that `serial`'s author later built the
  same way — i.e., the underlying hazard is treated as a general, not input-specific, risk that this
  branch's own `compy.input` surface (introduced in this branch per `input.md`'s header) happened to
  avoid by construction; the entry does not claim the hazard itself is pre-existing framework debt,
  only that the file it landed in is another author's.
- **Proposed classification:** `MIXED` — the host file (`architecture_principles.md`) is
  pre-existing; the specific practice/rule text this entry retires is introduced-in-branch, since the
  hazard it documents was found and closed entirely inside this branch's own new surface
  (`compy.input`). Not `CANNOT TELL`: the file-vs-section split is directly measured, not guessed.


---

## `input.md` — `## RETIRED` (50 entries)

**Scope note for this whole section:** `compy.input` (the free-function `build_widget_api` surface in
`consoleController.lua`) and `doc/input_api.md` are both **entirely absent at base** — confirmed
below per-entry, but true across the section as a background fact: `git grep -n
"build_widget_api" 3256aac -- src` and `git ls-tree 3256aac -- doc/input_api.md` both return
nothing. Any entry whose subject is that surface or that guide is `ABSENT`/`INTRODUCED-IN-BRANCH` on
that ground alone; I still ran the specific identifier check per entry per the commission's Trap 2,
rather than assuming it from this note.

### Batch 1 (entries 1-8)

#### 1. A project cannot read the widget's content except at submit (RESOLVED, 2026-09-03) -- `input.md:1331`

- **Claim:** `compy.input.get_text()` shipped -- read-only, `nil` while hidden, `''` while shown and
  empty, one string with `\n` between lines, round-trips with `set_text`.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "get_text" src/controller/consoleController.lua` ->
  line 906: `get_text = function() ... return string.unlines(get_widget():get_text()) end`, inside the
  `compy.input` table build (comment at :866 lists it alongside `configure/set_text/.../get_cursor`).
- **(b) At base `3256aac`:** `CHANGED SHAPE` / effectively `ABSENT` for the claimed surface. The
  **model-level** `UserInputController:get_text()` already existed at base (`git grep -n "get_text"
  3256aac -- src` -> `userInputController.lua:50-51`), but `build_widget_api` -- the function that
  builds the project-facing `compy.input` table -- does not exist at base at all (`git grep -n
  "build_widget_api" 3256aac -- src/controller/consoleController.lua` -> no hit). So a caller-facing
  read of widget content did not exist at base; only an internal, controller-level one did.
- **Self-declared provenance:** entry frames this as a gap in "the `compy.input` surface," which the
  file's own header says was "introduced in 1.0.0-rc20260712" -- this branch.
- **Proposed classification:** `INTRODUCED-IN-BRANCH` -- the defect (missing project-facing getter) is
  a gap in a surface that itself postdates base; nothing here for an outside user to have met before
  this branch existed.

#### 2. The class diagrams show a model field that no longer exists (RESOLVED, 2026-09-02 -- and the premise was half wrong) -- `input.md:1394`

- **Claim:** `doc/mermaid/{input,editor,classes}.md` show `oneshot: boolean` on a model class; it was
  removed as a constructor arg by this feature. Resolution marks the diagrams historical rather than
  correcting them, except `editor.md`'s `oneshot` line (the one live-class instance), which is
  deleted outright.
- **(a) Resolution at HEAD:** `HOLDS`. `doc/mermaid/README.md:9` -> `"# The diagrams in this directory
  are historical"`. `grep -n "oneshot" doc/mermaid/editor.md` -> no hit (deleted, as claimed).
- **(b) At base `3256aac`:** `CHANGED SHAPE`, entry's own correction is right. `doc/mermaid/` as a
  directory exists at base (`git ls-tree -d 3256aac -- doc/mermaid`), but per-file: `git grep -n
  "oneshot" 3256aac -- doc/mermaid/editor.md` -> hit at line 101 -- `editor.md`'s field **was present
  at base**, confirming the one line this entry says is "ours" to fix really was live and
  pre-existing. (I did not re-check `input.md`/`classes.md`'s `InputModel` class non-existence at base
  myself -- the entry's own S67-mermaid-audit evidence for that is not re-derived here, per the
  commission's scope; flagged under "not verified" below.)
- **Self-declared provenance:** explicit and unusually granular -- "exactly one line of 32 class blocks
  was ours," the rest inherited drift from `aldum`'s pre-feature diagrams.
- **Proposed classification:** `MIXED`, matching the entry's own finding: the diagrams as a whole are
  pre-existing drift (not ours to fix, correctly left historical); the one `editor.md` line is a
  branch-caused omission (this branch's own removal of a live field from the model, not reflected in
  its diagram) and was fixed.

#### 3. The guide never says a project's own keys stay live while the widget is shown (RESOLVED, 2026-09-02) -- `input.md:1435`

- **Claim:** `doc/input_api.md`'s `is_shown` paragraph now states that hooks/shortcuts sit above the
  widget so unguarded handlers still fire, and names the whole-handler `is_shown()` early-return
  remedy, distinct from the narrower trigger-key guard.
- **(a) Resolution at HEAD:** `HOLDS`. Read `doc/input_api.md:233-244`: *"**While the widget is shown,
  your own handlers keep running.** Hooks and shortcuts sit *above* it -- see \"Why the widget sits at
  tier 3\"... An unguarded handler acts on that typing... The remedy is one line, and it covers the
  **whole** handler:"* followed by the `is_shown()` early-return example. Matches the claim verbatim.
- **(b) At base `3256aac`:** `ABSENT`. `git ls-tree 3256aac -- doc/input_api.md` -> no hit; the guide
  itself postdates base.
- **Self-declared provenance:** none claimed pre-existing; explicitly about this branch's own guide.
- **Proposed classification:** `INTRODUCED-IN-BRANCH` -- subject document absent at base.

#### 4. The set of accepted config keys has no single home (RESOLVED, 2026-09-02) -- `input.md:1480`

- **Claim:** `tests/input/input_config_key_agreement_spec.lua` now reads the real accepted key set out
  of the surface (`SHOW_KEYS`, `CONFIGURE_KEYS` by upvalue) and asserts every key reaches the widget;
  no production defect existed, the two sides already agreed.
- **(a) Resolution at HEAD:** `HOLDS`, existence-checked. `git -C /repo ls-files -- \
  'tests/input/input_config_key_agreement_spec.lua'` -> file present. (I did not execute the suite --
  the commission forbids running tests -- so "mutation-tested in both directions" is read, not rerun;
  flagged under "not verified.")
- **(b) At base `3256aac`:** `ABSENT`. Spec file: `git ls-tree 3256aac -- \
  tests/input/input_config_key_agreement_spec.lua` -> no hit. The keys it guards
  (`CALLBACK_KEYS`/`WIDGET_KEYS` in `consoleController.lua`) are also absent at base: `git grep -n
  "CALLBACK_KEYS\|WIDGET_KEYS" 3256aac -- src/controller/consoleController.lua` -> no hit.
- **Self-declared provenance:** none claimed pre-existing; the whole `show`/`configure` key-set split
  is this branch's own `compy.input` design.
- **Proposed classification:** `INTRODUCED-IN-BRANCH` -- both the guarded mechanism and its guard are
  branch-new.

#### 5. A citation edit left half a sentence asserting the opposite of the statement it cites (RESOLVED, 2026-09-02) -- `input.md:1540`

Two sub-defects under one heading.

- **Claim (a -- test comment):** `tests/input/input_widget_callbacks_spec.lua`'s `auto_hide` raise
  case had a dangling fragment reading as if statement 5 *were* the entry's own recommendation, when
  the recommendation was the opposite; fragment removed.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "ruled edge 4\|entry's own recommendation\|widget
  survives a" tests/input/input_widget_callbacks_spec.lua` -> only line 643: `-- D-AUTO-HIDE, statement
  5 -- the widget survives a raise.` -- no trailing fragment, matches the claimed rewrite.
- **Claim (b -- guide ordering):** `doc/input_api.md`'s close-after-submit paragraph led with the
  superseded `after_submit = hide` idiom ahead of the now-recommended `auto_hide`; reordered to lead
  with `auto_hide`, keeping the hand-written form as what the key *does*.
- **(a) Resolution at HEAD:** `HOLDS`. `doc/input_api.md:334-335`: *"The input widget remains shown by
  default. To close it after a submit, pass \`auto_hide = true\` -- that is the form to reach for..."*
  -- `auto_hide` leads, as claimed.
- **(b) At base `3256aac`, both sub-defects:** `ABSENT`. `git grep -n "auto_hide" 3256aac -- src tests
  doc` -> no hit anywhere in the tree; `auto_hide` is entirely a branch invention (matches
  `T-ONESHOT-SCOPE`/`D-AUTO-HIDE` elsewhere in this register), so neither the test file's comment nor
  the guide paragraph it describes could have existed at base.
- **Self-declared provenance:** none claimed pre-existing.
- **Proposed classification:** `INTRODUCED-IN-BRANCH` for both sub-defects.

#### 6. The deviation justifications live only in the PR description -- NOT DEBT, the premise was false (2026-09-01) -- `input.md:1571`

- **Claim:** filed and refuted same day -- the PR table's six justifications are already carried, in
  more depth, inside their respective decisions (`D-ROUTE-LIFETIME`, `D-NO-LOG-NOISE`,
  `D-HOOKS-SEEDED`, `D-NO-FW-TIER`, `D-ONE-LIFETIME`); not a defect.
- **(a) "Resolution" at HEAD (i.e., is the refutation's evidence still true):** `HOLDS`. `grep -n
  "SUPERSEDED IN PART\|What this settles\|Why the log is declined" doc/development/decisions/input.md`
  -> all three phrases present (`:476`, `:834`, `:840`), matching the entry's claim that these
  decisions already carry the named arguments.
- **(b) At base `3256aac`:** `ABSENT`. `doc/development/decisions/input.md` does not exist at base
  (established for the whole decisions ledger above). The entire question -- table vs. ledger,
  PR-description-only justifications -- is about a branch-internal document that has no base analogue.
- **Self-declared provenance:** none claimed pre-existing; explicitly a same-branch, same-day
  filed-and-refuted row.
- **Proposed classification:** `INTRODUCED-IN-BRANCH` -- both the alleged defect and its refutation are
  contained entirely within branch-only artifacts.

#### 7. The callable config keys are unchecked (WONTFIX by owner ruling, 2026-09-01 -- the premise was wrong) -- `input.md:1595`

- **Claim:** `show{validator = 42}` raises `attempt to call local 'validator' (a number value)` at
  `userInputController.lua:417`, same for `cb` at `:437`; ruled WONTFIX, not a defect -- self-diagnosing
  by design (D-CFG-BOUNDARY).
- **(a) Resolution at HEAD:** `HOLDS` structurally. `awk 'NR==417 || NR==437'
  src/controller/userInputController.lua` -> `417: local ok, errors = validator(lines)` and `437: if cb
  then return cb(...) end` -- both call the value directly without a `type(...) == 'function'` guard, so
  a non-callable would raise exactly as claimed. (Did not execute to observe the literal error
  message -- reading the call site is sufficient for "would raise," not for the exact string; flagged
  under "not verified.")
- **(b) At base `3256aac`:** the specific `compy.input`/`show{}` surface this entry is about is
  `ABSENT` at base (established above: `build_widget_api` doesn't exist at base). The underlying
  pattern -- calling a project-supplied callback unguarded -- is older than the branch in spirit
  (`UserInputController` itself predates the branch, base has `get_text` etc.) but the specific
  `show{validator=...}` config-key entry point this entry is about is branch-new.
- **Self-declared provenance:** entry states outright -- *"Provenance: `#77`'s own surface."*
- **Proposed classification:** `INTRODUCED-IN-BRANCH`, matching the entry's own declared provenance.

#### 8. Six line citations into `userInputModel.lua` were stale on arrival (RESOLVED, 2026-09-01) -- `input.md:1631`

- **Claim:** six citations, stale after commit `e3484987` trimmed a doc comment by 3 lines, replaced
  with function names (`insert_text_line`, `line_feed`, `set_cursor`, `_set_text_line`,
  `history_back`, `history_fwd`) instead of line numbers.
- **(a) Resolution at HEAD:** `HOLDS`, two-part check. First, the corrected raw line numbers the entry
  gives (`221`, `260`, `543`, `193-195`, `472`, `484`) do land on the right content: `awk` over those
  lines in `src/model/input/userInputModel.lua` shows `221: self.cursor.l = l + 1` (inside
  `insert_text_line`), `260: self:insert_text_line(...)` (inside `line_feed`), `543: self.cursor = c`
  (inside `set_cursor`), `193-195` the `elseif type(text) == 'table'...end` block (inside
  `_set_text_line`), and `472`/`484` both `self:set_text(hist)` (the two history-restore sites).
  Second, the stale numeric forms are gone from the register: `grep -n
  "userInputModel.lua:224\|:263\|:546\|:196-198\|:475\|:487" doc/development/technical_debt/input.md`
  -> no match.
- **(b) At base `3256aac`:** `PRESENT` (the file), but the citing commit is branch-internal. `git log
  --oneline 3256aac -- src/model/input/userInputModel.lua` and `git log --oneline -1 e3484987` both
  resolve -- `userInputModel.lua` predates the branch, but `e3484987` ("docs: act on the cold peer
  review...") is a documentation commit made inside the branch, and the citations it broke were
  themselves written inside the branch (they cite the multiline-input machinery this feature added).
- **Self-declared provenance:** *"Provenance: ours, 2026-09-01, all six traceable to one commit."*
- **Proposed classification:** `INTRODUCED-IN-BRANCH`, matching self-declared provenance -- the citing
  prose and the commit that broke it are both branch-internal, even though the cited file predates
  the branch.

### Batch 2 (entries 9-16)

#### 9. The programmatic-cursor census omitted the one writer on a hot path (RESOLVED, 2026-09-01) -- `input.md:1666`

- **Claim:** `internals/user_input.md`'s cursor-access census now lists field-writers
  (`_update_cursor`, `_advance_cursor`, `insert_text_line`) as a separate population from cursor-API
  callers, notes `insert_text_line` fires on every Shift+Enter/Ctrl+D, and widens a parenthesis from
  "an arrow/Home/End keypress" to "a cursor-movement keypress".
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "Cursor access exists at three layers\|cursor-movement
  keypress" doc/development/internals/user_input.md` -> both phrases present (`:152`, `:171`).
- **(b) At base `3256aac`:** `CHANGED SHAPE`. The **file** exists at base (`git ls-tree 3256aac --
  doc/development/internals/user_input.md` -> blob present) but the **census paragraph** does not:
  `git grep -n "Cursor access exists at three layers\|cursor-movement keypress" 3256aac --
  doc/development/internals/user_input.md` -> no hit.
- **Self-declared provenance:** *"Provenance: ours. The census paragraph is `#77`'s writing."*
- **Proposed classification:** `INTRODUCED-IN-BRANCH`, matching self-declared provenance -- the doc
  file predates the branch, the specific paragraph this entry fixes does not.

#### 10. `set_text` answered a malformed content element three different ways (RESOLVED, 2026-09-01) -- `input.md:1692`

- **Claim:** `checked_text`/`api_set_text`/`is_line_list` (`consoleController.lua`) now refuse a
  non-string/non-line-list `text` with one message at the project boundary, replacing three silent
  behaviours (drop, wipe, raw internal raise). "The raw raise is pre-existing; the drop and the wipe
  were this feature's own", introduced hours earlier the same day by `BUG-02-01`.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "function checked_text\|function api_set_text\|function
  is_line_list" src/controller/consoleController.lua` -> all three present (`:723`, `:742`, `:826`).
- **(b) At base `3256aac`:** `ABSENT`. `git grep -n "api_set_text\|checked_text" 3256aac -- src` -> no
  hit; neither function exists at base. Additionally `git grep -n "sanitize_utf8" 3256aac -- src` -> no
  hit either, so the "raw raise is pre-existing" qualifier in the entry's own text is **not** relative
  to the PR base -- `sanitize_utf8` itself is branch-new, so that raise path could not have existed at
  base. Read in context, the entry's "pre-existing" means *older within the branch, relative to that
  same day's `BUG-02-01` fix* -- a second instance of Trap 1 (subject named in prose whose "pre-
  existing" is relative to an in-branch event, not to base). Flagged so the parent does not read it as
  a base claim.
- **Self-declared provenance:** internally mixed, see above -- the entry's own text partitions this
  into "pre-existing" (the raw-raise class) and "this feature's own" (the drop/wipe class), but
  neither half of that split resolves to *before base*: the whole `checked_text`/`sanitize_utf8`
  apparatus is absent at base.
- **Proposed classification:** `INTRODUCED-IN-BRANCH` — corrects the entry's internal "pre-existing"
  framing on the base question specifically: relative to `3256aac`, no part of this defect existed
  outside the branch. The entry's own PRE-EXISTING/OURS split is real and useful but answers a
  different question (chronology within the branch), not this commission's (b).

#### 11. `set_text`'s list branch does not split embedded newlines (RESOLVED, 2026-09-01) -- `input.md:1759`

- **Claim:** the `table` branch of `UserInputModel:set_text` now runs through `string.lines` (via
  `normalized_lines`), splitting embedded newlines and matching the string branch; fixed at
  `BUG-02-01`. Entry states outright: *"Provenance: pre-existing. At the PR base `3256aac` the table
  branch is `InputText(text)` — no split, no sanitise."*
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "function UserInputModel:set_text\|normalized_lines"
  src/model/input/userInputModel.lua` -> `set_text` at `:162` calls `normalized_lines(text)` at `:163`
  (one unified path for both spellings), confirmed by reading `:162-174`.
- **(b) At base `3256aac`:** `PRESENT`, and the claim is exactly right. `git show
  3256aac:src/model/input/userInputModel.lua | grep -n "function UserInputModel:set_text" -A 15` ->
  `elseif type(text) == 'table' then self.entered = InputText(text) end` — verbatim what the entry
  says, no split, no sanitise.
- **Self-declared provenance:** *"Provenance: pre-existing"* — confirmed by direct measurement, not
  taken on the entry's word.
- **Proposed classification:** `PRE-EXISTING` — measured, not inferred: the defective shape is
  byte-identical at base to what the entry describes.

#### 12. `set_text`'s two branches disagreed about the cursor, and the call was dead (RESOLVED, 2026-09-01) -- `input.md:1834`

- **Claim:** at base, the string branch of `set_text` called `_update_cursor(true)` and the table
  branch never did — an inert asymmetry (both branches end in `jump_end()`, which overwrites the
  effect). Fixed at `BUG-02-01`: the call is deleted outright, both branches unified.
- **(a) Resolution at HEAD:** `HOLDS`. Reading `userInputModel.lua:162-174` (see entry 11), `set_text`
  contains no `_update_cursor` call at all — deleted, as claimed. (The two `_update_cursor(true)` hits
  elsewhere in the file, `:191` and `:377`, are inside `_set_text_line` and a different function, not
  `set_text` — confirmed by reading `:180-192`.)
- **(b) At base `3256aac`:** `PRESENT`, and the claimed asymmetry is exactly right. The same base
  `set_text` dump (entry 11's command) shows the **string** branch: `if not keep_cursor then
  self:_update_cursor(true) end`; the **table** branch (`elseif type(text) == 'table' then
  self.entered = InputText(text) end`) has no such call. This is precisely the pre-existing asymmetry
  the entry describes.
- **Self-declared provenance:** *"Provenance: pre-existing, inherited from the transitional triplet
  and present at the PR base in the same shape."*
- **Proposed classification:** `PRE-EXISTING` — measured directly, matches self-declared provenance
  exactly.

#### 13. T-MAZE-NEUTRALIZE — `maze` neutralises two hook sites by clearing a flag, not by the widget guard (NOT DEBT, 2026-08-31) -- `input.md:1885`

- **Claim:** wontfix by owner ruling; the weighing found nothing to weigh, no code changed in `maze`.
  A real but separate defect (the `jump_level` re-arm leaving `ctrl_pressed` live) was reported in
  maze's own `ISSUES.md`, not fixed, because it is that repo's defect.
- **(a) Resolution at HEAD:** `HOLDS` — "no code changed" is itself the claim, and it checks out.
  `grep -n "ctrl_pressed" src/examples/maze/controls.lua` -> present exactly as a mode-selection slot
  (`ctrl_pressed = handle_key` / `= plan_key`), consistent with the entry's description, not a
  neutralisation idiom. `grep -n "jump_level" src/examples/maze/ISSUES.md` -> the `jump_level` defect
  is documented there as claimed, not fixed in code.
- **(b) At base `3256aac`:** `NOT CHECKABLE`, structurally. `src/examples/maze` is an **untracked,
  separately-versioned repo** with its own `.git` and remote (`git status --porcelain -- \
  src/examples/maze` -> `??`, i.e. not part of `/repo`'s tree at all, in any revision) — it "opens its
  own PR alongside the platform one," per the entry. The platform's `3256aac` has no bearing on this
  repo's history; there is no base commit to diff against inside `/repo`'s git. `maze`'s own log
  (`git -C src/examples/maze log --oneline -3`) shows recent commits including `"docs: record two
  defects found reading, neither fixed"`, consistent with the claim, but "did this exist at platform
  base" has no answer for a sibling repo with independent history.
- **Self-declared provenance:** not framed as pre-existing/ours in the base sense; framed as "not a
  defect" outright.
- **Proposed classification:** `CANNOT TELL` for the base-provenance question specifically — not
  because the claim is doubtful (it checks out), but because "PRE-EXISTING vs. INTRODUCED-IN-BRANCH
  relative to `3256aac`" is not a well-formed question for a companion repo with its own independent
  history and no pin to the platform's base commit. The resolution claim itself is `HOLDS`.

#### 14. T-BALLOON-LABEL — balloons keeps a shadow copy of the widget's label, re-pushed every cycle (RESOLVED, 2026-08-31) -- `input.md:1920`

- **Claim:** fixed in the balloons repo — `ui_messages.hint`/`ui_draw_hint` removed, `ui_set_hint`
  writes straight through to the widget; a second, unrelated defect (`ui_messages.results`, a field
  that was never set) found and deleted on the owner's ruling.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -rn "ui_messages.hint\|ui_draw_hint\|ui_set_hint\|
  ui_messages.results" src/examples/balloons --include=*.lua` -> `ui_set_hint` present and calling
  through directly (`ui.lua:52`, called from `main.lua:49`); no hits at all for `ui_messages.hint`,
  `ui_draw_hint` or `ui_messages.results` — all three removed, as claimed. Balloons' own log (`git -C
  src/examples/balloons log --oneline -3`) shows `"refactor(ui): drop the shadow label; the widget
  owns it"` and `"fix(ui): drop ui_messages.results, a field that never existed"`, matching both
  halves of the claim by commit message.
- **(b) At base `3256aac`:** `NOT CHECKABLE`, same structural reason as entry 13 — `src/examples/
  balloons` is a separate, untracked, independently-versioned repo (`?? src/examples/balloons/` in
  `/repo`'s status); the platform's `3256aac` is not a commit in its history.
- **Self-declared provenance:** not framed relative to the platform base.
- **Proposed classification:** `CANNOT TELL` for the base-provenance question, same reasoning as
  entry 13. Resolution claim itself is `HOLDS`.

#### 15. T-CURSOR-BYTES — `set_cursor` clamps by byte offset; the boundary event measures characters (RESOLVED, 2026-08-31) -- `input.md:1954`

- **Claim:** three byte-bounded cursor clamps now count characters via `string.ulen`; fixed at
  `BUG-01-05`. Provenance explicitly mixed: `UserInputModel:move_cursor`'s bound is pre-existing and
  unchanged at base (18 internal callers all pass character values, so inert); `set_cursor_pos` and
  `_clamp_cursor_pos` are branch-new and made the gap externally reachable.
- **(a) Resolution at HEAD:** `HOLDS`, existence-checked. `grep -n "string.ulen" \
  src/model/input/userInputModel.lua` -> widely used, including at the cited call sites (`:519` for
  the cursor-column clamp among others). Did not re-derive the full "all three now agree" mutation
  test from the six-character/twelve-byte `'привет'` example myself; treated the entry's own worked
  example as read, not re-executed (test suite is out of scope per the commission) — flagged under
  "not verified."
- **(b) At base `3256aac`:** `MIXED`, exactly as self-declared. `git grep -n "set_cursor_pos\|
  _clamp_cursor_pos" 3256aac -- src` -> no hit — both are absent at base, confirming "OURS — absent at
  base." (Did not separately re-verify `move_cursor`'s bound is byte-based and unchanged at base —
  that specific claim is carried over from the BACKLOG entry `_update_cursor measures the column on
  the wrong line`'s own evidence and not re-derived here; flagged under "not verified.")
- **Self-declared provenance:** *"Provenance, and it is mixed"* — stated outright.
- **Proposed classification:** `MIXED`, matching self-declared provenance and partially confirmed by
  direct measurement (the branch-new half).

#### 16. T-COMBO-CASE — `combo_string` does not normalise the case of a textinput token (RESOLVED, 2026-08-31) -- `input.md:1984`

- **Claim:** `combo_string` (`controller.lua`) now lower-cases the trigger so dispatch matches
  registration's already-lower-cased combo strings; fixed at `BUG-01-04`.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "function combo_string\|:lower()"
  src/controller/controller.lua` -> `combo_string` at `:390`, returning `combo .. k:lower()` at `:397`.
- **(b) At base `3256aac`:** `ABSENT`. `git ls-tree 3256aac -- src/controller/controller.lua` -> file
  exists at base, but `git grep -n "combo_string\|split_combo" 3256aac -- src` -> no hit for either —
  the whole combo/shortcut dispatch mechanism this defect lives in is branch-new (consistent with
  `D-COMBO-TABLES` being a ratified decision of this branch, cited by the entry itself).
- **Self-declared provenance:** not stated explicitly as pre-existing/ours, but the mechanism it
  patches (`D-COMBO-TABLES`) is this branch's own design.
- **Proposed classification:** `INTRODUCED-IN-BRANCH` — the file predates base, the specific
  mechanism and its defect do not.

### Batch 3 (entries 17-24)

#### 17. T-MULTILINE-STR — `set_text` silently ignores a multi-line *string* (RESOLVED, 2026-08-31) -- `input.md:2012`

- **Claim:** the string branch of `set_text` used to write `self.entered` only when the string held
  one line (`#string.lines(text) == 1`), so a multi-line string silently kept the old content; fixed
  at `BUG-01-09` by unifying through `string.lines`. Entry states: *"It was PRE-EXISTING, not ours.
  The `#string.lines(text) == 1` guard is at the PR base `3256aac` in the same shape."*
- **(a) Resolution at HEAD:** `HOLDS`. `userInputModel.lua:162-174` (already read for entries 11/12)
  shows one unified path (`normalized_lines`), no `n_added == 1` guard anywhere.
- **(b) At base `3256aac`:** `PRESENT`, exactly as claimed. `git show
  3256aac:src/model/input/userInputModel.lua | grep -n "string.lines(text)\|n_added == 1"` -> both the
  guard and the `n_added == 1` condition appear (`:96-98` and `:130-132` — the string branch of
  `set_text` and a sibling function share the shape).
- **Self-declared provenance:** *"pre-existing, not ours"* — confirmed by direct measurement.
- **Proposed classification:** `PRE-EXISTING`, measured directly.

#### 18. T-ONESHOT-SCOPE — the `show`-only `oneshot` becomes `auto_hide`, a widget property (RESOLVED, 2026-08-30) -- `input.md:2042`

- **Claim:** the key is now `auto_hide`, moved out of `SHOW_ONLY_KEYS` into `configure_core`, settable
  by both `show` and `configure`, persists until explicitly unset with `false`.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "SHOW_ONLY_KEYS\s*=" -A 10
  src/controller/consoleController.lua` -> the table (`:603-607`) holds only `text`, `cursor`, `force`
  — `auto_hide` is **not** in it, confirming it left the show-only set. `grep -n "auto_hide"
  src/controller/userInputController.lua` -> `cfg.auto_hide` read at config time (`:294-295`) and
  `if self.auto_hide then self:hide() end` at submit (`:479`) — a persistent widget property, not a
  spent flag.
- **(b) At base `3256aac`:** `ABSENT`. `git grep -n "auto_hide" 3256aac -- src tests doc` -> no hit
  anywhere (established earlier for the whole `auto_hide` family).
- **Self-declared provenance:** none claimed pre-existing; explicit branch history (built at `FEAT-02`,
  same-day amendment of `T-ONESHOT`).
- **Proposed classification:** `INTRODUCED-IN-BRANCH`.

#### 19. T-ONESHOT — `oneshot` is ruled in and nothing implements it (RESOLVED, 2026-08-30) -- `input.md:2065`

- **Claim:** `show{oneshot = true}` was ratified but unimplemented; built at `FEAT-01-02`, then
  superseded same-day by `T-ONESHOT-SCOPE`/`auto_hide` — read as history, not current behaviour.
- **(a) Resolution at HEAD:** `HOLDS` in the historical sense the entry itself asks for: the
  project-facing `oneshot` key is gone (`git grep -n "\boneshot\b" -- src` finds only unrelated hits —
  `controller.lua:1093`'s `oneshot = function()` is a `love.handlers`-shaped dispatch entry, not the
  input key; `profiler.lua`'s `oneshot` is a profiler setting; `userInputModel.lua`/`userInputView.lua`
  carry only comments noting *"oneshot is gone"*) — consistent with the entry's own note that
  `auto_hide` replaced it.
- **(b) At base `3256aac`:** `CHANGED SHAPE`, with a naming trap worth flagging explicitly (Trap 1).
  A **different, internal** `oneshot` already existed at base: `git grep -n "UserInputModel.new\|
  oneshot" 3256aac -- src/model/input/userInputModel.lua` -> `@field oneshot boolean`, a constructor
  parameter (`UserInputModel.new(cfg, eval, oneshot, custom_label)`), and two live reads
  (`return not self.oneshot`, `if self.oneshot then`) — but per entry 2 above, this base-era
  `oneshot` distinguishes the console's **permanent** widget instance from a **transient** prompt
  instance; it is not the project-facing `show{oneshot = true}` capability this entry is about. The
  capability this entry retires — a project asking for a self-closing prompt — has no base analogue:
  `build_widget_api`/`compy.input` (the only place `show{}` could be called from) is absent at base.
  So on the actual subject, `ABSENT`; a naive grep for the bare identifier `oneshot` would have
  wrongly suggested `PRESENT` by matching the unrelated internal field.
- **Self-declared provenance:** not stated in base terms in this entry; `general.md`'s `T-NEVER-
  SHIPPED` entry (not in this section's scope, but cross-referenced) rules the same fact from the
  decisions side: *"at `3256aac` there was `oneshot` and nothing replacing it"* — which is about the
  **decision text**, and is consistent with what I found for the **code**: an unrelated internal flag
  existed, the ratified-but-unbuilt capability did not.
- **Proposed classification:** `INTRODUCED-IN-BRANCH` for the actual subject (the project-facing
  capability); flagged as a naming collision so the parent doesn't read the internal-field hit as
  contradicting this.

#### 20. T-PLAINTEXT-ENTERED — the two submit callbacks receive identical payloads (RESOLVED, 2026-08-30) -- `input.md:2082`

- **Claim:** `on_text_entered` now gets the joined string, `after_submit` the line list
  (D-PAYLOAD-SPLIT); built at `FEAT-01-04`.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "on_text_entered\|after_submit"
  src/controller/userInputController.lua` -> `:469-470`: `run_callback(self, 'on_text_entered',
  string.unlines(lines))` immediately followed by `run_callback(self, 'after_submit', lines)` — joined
  string vs. line list, exactly as claimed.
- **(b) At base `3256aac`:** `ABSENT`. `git grep -n "on_text_entered\|after_submit" 3256aac -- src` ->
  no hit anywhere. Reading the base `submit()` directly (`git show
  3256aac:src/controller/userInputController.lua`, `:344-361`) shows exactly **one** result path —
  `self.result` — called once with `string.unlines(text)` (the joined string) and nothing else; there
  was no second callback to disagree with the first. The defect this entry describes (two callbacks,
  same payload) cannot have existed at base because only one callback existed.
- **Self-declared provenance:** none claimed pre-existing.
- **Proposed classification:** `INTRODUCED-IN-BRANCH` — both the second callback and the defect in
  its payload are branch-new; base had no second callback to be identical with the first.

#### 21. T-TURTLE-DUP — `turtle` double-handles its own keys (RESOLVED, 2026-08-28) -- `input.md:2097`

- **Claim:** `if compy.input.is_shown() then return end` added to `love.keypressed` in
  `src/examples/turtle/main.lua`, matching the existing `love.keyreleased` guard.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "is_shown" src/examples/turtle/main.lua` -> two hits,
  `:40` (inside `love.keypressed`) and `:92`, both guarding on `compy.input.is_shown()`.
- **(b) At base `3256aac`:** unlike `maze`/`balloons`, **`turtle` is tracked inside `/repo`'s own git**
  (`git status --porcelain -- src/examples/turtle` -> empty/clean, i.e. not an untracked sibling repo;
  `git ls-tree 3256aac -- src/examples/turtle` -> resolves, with `main.lua` etc. present), so the base
  check is meaningful here. `git show 3256aac:src/examples/turtle/main.lua | grep -n "is_shown\|
  keypressed\|keyreleased"` -> `love.keypressed`/`love.keyreleased` both exist at base, **neither**
  guarded by `is_shown` (naturally — `compy.input.is_shown()` doesn't exist at base at all, since the
  whole surface is branch-new). So the specific double-handling shape this entry describes (tier-2
  hooks racing a tier-3 widget under the new dispatch chain) has no base analogue: base's turtle used
  a different, pre-feature widget mechanism entirely. `ABSENT`.
- **Self-declared provenance:** not stated explicitly as pre-existing/ours.
- **Proposed classification:** `INTRODUCED-IN-BRANCH` — the defect is specific to this branch's own
  dispatch-order architecture (D-CHAIN-OF-3) and the `compy.input` surface it introduced; turtle's
  base-era code used a different mechanism this defect shape doesn't apply to.

#### 22. `wrap` guards the `xpcall` arity hazard on the platform, not the capability (RESOLVED, 2026-08-28) -- `input.md:2102`

- **Claim:** the `_G.web` branch in `controller.lua`'s `wrap` is gone; `wrap` now closes arguments over
  a nullary function and calls `xpcall(fn, on_error)` unconditionally. Entry states: *"Not introduced
  by this feature. `master` carries the same guarded `xpcall`"* — pre-existing.
- **(a) Resolution at HEAD:** `HOLDS`. Read `controller.lua:138-146`: `wrap` closes `args`/`n` over an
  inner nullary function and calls `xpcall(function() return f(unpack(args, 1, n)) end, on_error)` —
  no `_G.web` branch anywhere in the function body.
- **(b) At base `3256aac`:** `PRESENT`, confirming pre-existing. `git grep -n "function wrap\|
  _G.web" 3256aac -- src/controller/controller.lua` -> `wrap` exists at `:59` with `if _G.web then` at
  `:60` — the two-branch, platform-guarded shape this entry describes is exactly what's at base.
- **Self-declared provenance:** *"Not introduced by this feature."* — confirmed by direct measurement.
- **Proposed classification:** `PRE-EXISTING`, measured directly. Note for the parent: this is a
  **different** `wrap`/`xpcall` defect from the one in `general.md`'s BACKLOG entry "The Web build has
  no coverage" (commit `56c4284f`'s bare, unguarded second `xpcall`, which **was** introduced by this
  feature and later removed by `f1dc6aee`) — same file, same function name, two distinct defects; do
  not conflate the two provenances.

#### 23. The `show`/`configure` content-ownership boundary was not built (RESOLVED, 2026-08-27) -- `input.md:2125`

- **Claim:** `configure` now refuses `text`/`cursor` as `show`-only keys; the hidden-`configure` stash
  (`stash_hidden_configure`, `state.pending`) is gone; a forced `show` with no `text` clears. Was
  `T-CFG-BOUNDARY`, built as `ARC-02`.
- **(a) Resolution at HEAD:** `HOLDS`, via the renamed mechanism. `grep -n "PER_SHOW_KEYS\|
  stash_hidden_configure\|state.pending" src/controller/consoleController.lua
  src/controller/userInputController.lua` -> **no hits** for the old names (consistent with "Where it
  was" phrasing — they're gone). The live equivalent: `grep -n "SHOW_ONLY_KEYS\s*=\|function
  check_keys\|function api_configure" src/controller/consoleController.lua` -> `SHOW_ONLY_KEYS`
  (`:603`), `check_keys` (`:680`) still enforcing `belongs_to = SHOW_ONLY_KEYS[name]` (`:651`) — the
  boundary is built, just under the name this register's own entry 18 already showed replaced
  `PER_SHOW_KEYS`.
- **(b) At base `3256aac`:** `ABSENT`. `git grep -n "PER_SHOW_KEYS\|stash_hidden_configure" 3256aac --
  src` -> no hit; the whole `show`/`configure` split is branch-new (consistent with `compy.input`
  being absent at base throughout this section).
- **Self-declared provenance:** none claimed pre-existing.
- **Proposed classification:** `INTRODUCED-IN-BRANCH`.

#### 24. A highlighter could not be turned off — `false` already did it, unratified (RESOLVED, 2026-08-27) -- `input.md:2137`

- **Claim:** no code changed — `false` already worked as the uniform unset because every consumer
  tested truthiness; the entry's resolution is ratification (D-CFG-BOUNDARY statement 3) and
  documentation (`doc/input_api.md`'s `computed or false` idiom), not a code fix. Was `T-HL-UNSET`.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "or false" doc/input_api.md` -> `:134`: *"`false` is
  how you unset any project-owned key... making expressions like `custom_validator or false` safe..."*
  — documented as claimed. `grep -n "D-CFG-BOUNDARY" doc/development/decisions/input.md` -> present
  (`:1410` heading, `:200`/`:549`/`:559` citing it), consistent with ratification having happened.
- **(b) At base `3256aac`:** `ABSENT` for the surface this is about (`show`/`configure`'s `highlighter`
  key doesn't exist at base — established throughout this section for the whole `compy.input` surface),
  so the ratification and the documentation are both necessarily branch-internal. Did not separately
  verify whether some *earlier*, differently-named highlighter-assignment path at base already
  behaved this way by accident (the entry's own claim is only about the current surface) — flagged
  under "not verified."
- **Self-declared provenance:** none claimed pre-existing.
- **Proposed classification:** `INTRODUCED-IN-BRANCH` — the surface (and therefore both the "defect"
  and its non-fix) is branch-new; this is a documentation/ratification retirement, not a code change,
  and the entry says so itself.

### Batch 4 (entries 25-32)

#### 25. Future input unification (RESOLVED, 2026-08-03) -- `input.md:2251`

- **Claim:** every channel (keyboard, text, pointer, derived singleclick/doubleclick) now routes
  through one chain with one error boundary and lifetime (D-ONE-LIFETIME); `compy.singleclick` is
  gone, `compy.input.hooks.singleclick` replaces it. Entry explicitly self-corrects: *"it recorded the
  asymmetry as predating the input API. It did not... the split was introduced by this feature."*
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "singleclick\|doubleclick"
  src/controller/controller.lua` -> `'singleclick'`/`'doubleclick'` listed among the derived hook
  events (`:75-76`) and assigned as `derived = 'singleclick'`/`'doubleclick'` in the dispatch code
  (`:549`, `:551`) — folded into the ordinary hooks mechanism, matching the claim.
- **(b) At base `3256aac`:** `PRESENT`, confirming the entry's own correction. `git grep -n
  "singleclick" 3256aac -- src` -> `controller.lua:150` (`singleclick = function() end` — a no-op
  default), `:349` (`CC:get_compy_handler('singleclick')`), plus **three project-facing consumers**:
  `examples/paint/main.lua:356`, `examples/sapper/main.lua:671` (both `function
  compy.singleclick(x, y)`), and `types.lua:193` (`@field singleclick function?`). So at base,
  `compy.singleclick` was already a real, single-callback project surface — a shared, chain-agnostic
  contract, exactly what the entry's correction says was "in fact the pre-existing state."
- **Self-declared provenance:** the entry corrects itself mid-text; net effect is that the underlying
  singleclick/doubleclick *capability* is pre-existing, the *unification into one hooks chain* is this
  branch's own architecture.
- **Proposed classification:** `MIXED` — the capability predates the branch (`PRESENT` at base, three
  real consumers), the mechanism unifying it with keyboard/text dispatch is `INTRODUCED-IN-BRANCH`.

#### 26. Project-handler wrapping: dedup the guard, drop the misleading `keyboard_` name (RESOLVED, 2026-08-03) -- `input.md:2269`

- **Claim:** `wrapped_native`/`keyboard_native`/`chain_native` collapsed into `chain_project_handler`
  (wraps) + `project_handler` (guards), both keyboard and pointer paths sharing one guard.
- **(a) Resolution at HEAD:** `PARTIAL`, and worth flagging rather than waving through. The **outcome**
  holds: `grep -n "wrapped_native\|keyboard_native\|chain_native"
  src/controller/controller.lua` -> no hits, all three old names are gone, as claimed. But the
  **named mechanism has moved on since 2026-08-03**: `chain_project_handler` does not exist under that
  name at HEAD (`grep -n "chain_project_handler"` -> no hit); `project_handler` exists (`:188`) but
  with a different signature (`userlove, key`, not `userlove, CC, key`) and a rewritten guard (`if not
  new or new == Controller._defaults[key] then return end`, not the `orig and new and orig ~= new`
  form the entry describes). A structurally similar condition (`if orig and new and orig ~= new
  then`) does exist elsewhere (`:1062`), but inside `save_user_handlers`/`save_if_differs` — a
  **different function serving a different purpose** (deciding whether to persist a project's override
  for later restoration, not whether to wrap a handler for dispatch). I did not trace the full history
  of intermediate refactors between this entry's 2026-08-03 resolution and HEAD to confirm the "one
  guard, used once" property still holds under its current names — flagged under "not verified."
- **(b) At base `3256aac`:** `ABSENT` for the resolution's own subject. `git grep -n
  "wrapped_native\|keyboard_native\|chain_native"` was not separately re-run against base (the entry's
  own "Where it was" section implies these existed pre-resolution, i.e. before 2026-08-03, but that is
  a mid-branch state, not necessarily the PR base). Given `controller.lua`'s `wrap`/dispatch machinery
  is extensively branch-rewritten throughout this whole section, I treat this as `INTRODUCED-IN-
  BRANCH` by the same background pattern rather than a directly re-verified base grep — flagged as
  weaker evidence than the entries above.
- **Self-declared provenance:** none claimed pre-existing.
- **Proposed classification:** `INTRODUCED-IN-BRANCH`, with the caveat that (a)'s specific claimed
  shape ("the guard exists once, under these names") could not be fully re-confirmed at HEAD given
  intervening refactors; the observable outcome (no duplicate/misnamed old builders) does hold.

#### 27. `love.handlers.userinput` is dead code (RESOLVED, 2026-08-07) -- `input.md:2304`

- **Claim:** `love.event.push('userinput')` and the `clear_user_input` local that fed it are deleted;
  both push sites were present at base and removed by this feature.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "love.handlers.userinput\|clear_user_input\|
  love.event.push('userinput')" src/controller/controller.lua src/model/input/userInputModel.lua` ->
  no hits in either file.
- **(b) At base `3256aac`:** `PRESENT`, exactly as the entry states. `git grep -n
  "love.event.push('userinput')\|love.handlers.userinput" 3256aac -- src` -> one hit,
  `userInputModel.lua:819`.
- **Self-declared provenance:** implicit pre-existing (states the push sites were "present at the PR
  base... and were removed by this feature") — confirmed by direct measurement.
- **Proposed classification:** `PRE-EXISTING` — the dead code itself predates the branch; this branch
  is what removed it.

#### 28. Input-only / pointer-only projects stay live in `project_open` (RESOLVED, ruling a) -- `input.md:2312`

- **Claim:** `Controller.user_is_interactive()` (`love.state.user_input ~= nil or user_pointer`) now
  keeps the project route for a non-blocking-but-interactive project; entry states *"Confirmed pre-
  existing: this was verified byte-identical on `master` (pre-`0022004`)... The `release_keyboard_
  route` call site is new in 1.0.0-rc20260712... but the lifecycle split it slots into predates the
  feature."*
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "function.*user_is_interactive\|user_pointer"
  src/controller/controller.lua` -> `user_is_interactive = function() return (love.state.user_input ~=
  nil) or user_pointer end` (`:1051-1054`), with the doc comment above it reading *"A non-blocking
  project is still 'live' while it has an active input widget or a pointer/click handler"* — matches
  the claim verbatim, including the exact predicate.
- **(b) At base `3256aac`:** `ABSENT` for the fix's own machinery. `git grep -n
  "release_keyboard_route\|user_is_interactive" 3256aac -- src` -> no hit for either. This is
  consistent with, not contradictory to, the entry's own claim: the entry says the **bug's root cause**
  (lifecycle split dropping to `project_open` unconditionally) predates the feature, while the **call
  site and the fix** (`release_keyboard_route`, `user_is_interactive`) are branch-new — I did not
  independently re-derive the "byte-identical on `master` pre-`0022004`" claim myself (that would
  require checking out a different ref outside `3256aac`, which is both outside this commission's base
  and outside its read-only-grep-only constraint in spirit); flagged under "not verified."
- **Self-declared provenance:** *"Confirmed pre-existing"* for the underlying defect; the specific
  fix machinery is branch-new by construction (it has to be — `release_keyboard_route` itself is
  dated 1.0.0-rc20260712 by the entry's own text).
- **Proposed classification:** `MIXED` — the entry's own framing: pre-existing defect (unverified by
  me against `master`/`0022004`, taken on the entry's word), branch-new fix and branch-new call site
  that exposed it as reachable (`release_keyboard_route`, confirmed absent at `3256aac`).

#### 29. `compy.keys_pressed` is not exposed to projects (RESOLVED, 2026-08-03) -- `input.md:2359`

- **Claim:** resolution superseded — ruled to expose `compy.input.keys_pressed`, then that whole
  held-key view was dissolved by D-ASK-THE-DEVICE; the *need* is still met by reading the device
  directly (`love.keyboard.isDown`) rather than by any framework-held view.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "keys_pressed"
  src/controller/consoleController.lua doc/development/decisions/input.md` -> no hit in
  `consoleController.lua` (nothing on the live `compy.input` surface); all hits are in
  `decisions/input.md`, describing the dissolution (`D-ASK-THE-DEVICE — modifier state is read from
  the device; \`keys_pressed\` is dissolved`, `:1058`, and *"\`compy.input.keys_pressed\` and
  \`Controller.keys_pressed\` are dissolved from all..."*, `:1083`) — matches the claim that the
  surface was built and then withdrawn, leaving no trace on the live API.
- **(b) At base `3256aac`:** `ABSENT`. `git grep -n "keys_pressed" 3256aac -- src` -> no hit anywhere.
- **Self-declared provenance:** none claimed pre-existing; the entry frames the underlying need
  (a project reading held state during `draw`) as real but answers it a different way than either the
  entry or its first resolution proposed.
- **Proposed classification:** `INTRODUCED-IN-BRANCH` — both the withdrawn capability and the
  eventual non-capability answer are entirely branch-internal.

#### 30. Shortcuts key-repeat semantics are shipped unsettled (RESOLVED, 2026-08-03) -- `input.md:2390`

- **Claim:** dispatch keeps firing on every OS repeat; a binding opts out with
  `compy.input.fn.ignore_repeat(fn)` (D-IGNORE-REPEAT), composable with `fn.stop_here`
  (D-STOP-AND-SIDE).
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "ignore_repeat\|stop_here"
  src/controller/consoleController.lua` -> `ignore_repeat = function(fn)` (`:519`) and `stop_here =
  function(fn)` (`:527`), under a doc comment (`:508-513`) reading *"\`ignore_repeat\` decides whether
  the handler RUNS, \`stop_here\`/\`side_run\` decide whether the event PROPAGATES"* — matches the
  claim's composability description.
- **(b) At base `3256aac`:** `ABSENT`. `git grep -n "ignore_repeat\|stop_here" 3256aac -- src` -> no
  hit for either.
- **Self-declared provenance:** none claimed pre-existing; `projectInputController.lua`'s `isrepeat`
  threading (the entry's own "Where") is named as the pre-fix state, itself part of this branch's own
  tier machinery per the rest of this section.
- **Proposed classification:** `INTRODUCED-IN-BRANCH`.

#### 31. No public `is_active()`-shaped visibility query (RESOLVED, 2026-07-31) -- `input.md:2413`

- **Claim:** `compy.input.is_shown()` now exposed (D-ONE-STATE-ASK), returning the widget's own flag;
  used by `examples/turtle`'s open-only-if-closed guard. Entry also corrects itself: reading
  `love.state.user_input` directly from inside a project is *always nil* (sandboxed clone), so the
  workaround the original entry assumed was dead code, not a working fallback.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "is_shown = function"
  src/controller/consoleController.lua` -> present (`:888`), and `is_shown()` is used repeatedly by
  `turtle` (already confirmed under entry 21, `main.lua:40,92`).
- **(b) At base `3256aac`:** `ABSENT`. `git grep -n "is_shown" 3256aac -- src` -> no hit anywhere on
  the project-facing surface. (The entry itself notes an **internal** `UserInputController:is_shown()`
  already existed pre-feature — consistent with the general pattern in this section of an internal
  controller method predating its public `compy.input` exposure; I did not separately re-verify that
  specific internal method's base presence, since the entry's claim is about the *public* surface,
  which is unambiguously absent.)
- **Self-declared provenance:** none claimed pre-existing for the public surface.
- **Proposed classification:** `INTRODUCED-IN-BRANCH`.

#### 32. On the console route, a hidden widget's input falls to the console line (RESOLVED, 2026-08-03) -- `input.md:2431`

- **Claim:** `forward_keypressed`/`forward_textinput`/`forward_keyreleased` deleted outright — the
  console route no longer has a separate widget-forwarding step at all; every keypress on that route
  goes straight to `CC:keypressed`/`CC:textinput`.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "forward_keypressed\|forward_textinput\|
  forward_keyreleased" src/controller/controller.lua` -> no hits; all three are gone, as claimed.
- **(b) At base `3256aac`:** `ABSENT`. `git grep -n "forward_keypressed\|forward_textinput\|
  forward_keyreleased" 3256aac -- src` -> no hit either — these functions were themselves introduced
  and later removed entirely inside the branch (the entry's "Where it was" describes their role in an
  earlier, now-superseded mid-branch shape, not a base-era mechanism).
- **Self-declared provenance:** none claimed pre-existing.
- **Proposed classification:** `INTRODUCED-IN-BRANCH` — both the mechanism this entry removes and the
  defect it exhibited are entirely internal to the branch's own evolution; base had neither.

### Batch 5 (entries 33-40)

#### 33. A bare `*` shortcut is legal, and ruled that it should not be (RESOLVED, 2026-08-03) -- `input.md:2473`

- **Claim:** `check_combo` (`src/util/key.lua`) now raises on a bare `*` trigger with no modifiers,
  naming `compy.input.hooks` as the alternative; `shift+*` (a real class) is still accepted.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "function check_combo" -A 15 src/util/key.lua` ->
  `:90-103`: `if n == 1 then if trigger ~= '*' or next(mods) then return end error("bad combo '*': a
  class needs modifiers to be a class of (e.g. alt+*); for every key, use compy.input.hooks", 4) end`
  — matches the claim's exact message content and the "modifiers required" logic.
- **(b) At base `3256aac`:** `ABSENT`. `git ls-tree 3256aac -- src/util/key.lua` -> file exists at
  base, but `git grep -n "check_combo\|split_combo\|normalize_combo" 3256aac -- src` -> no hit for
  any of the three — the whole combo-grammar/validation apparatus is branch-new; the file predates
  the branch, this function does not.
- **Self-declared provenance:** none claimed pre-existing; the entry explicitly measures the old
  (pre-fix, mid-branch) behaviour, not a base-era one.
- **Proposed classification:** `INTRODUCED-IN-BRANCH`.

#### 34. A multi-trigger combo is silently truncated at registration (RESOLVED, 2026-08-03) -- `input.md:2492`

- **Claim:** registration now raises on a combo naming more than one trigger or none (D-COMBO-SHAPE),
  replacing silent truncation (`ctrl+a+b` -> `ctrl+b`, `a+b+*` -> `*`).
- **(a) Resolution at HEAD:** `HOLDS`. Same `check_combo` body (entry 33's read) continues at
  `:98-102`: `local why = (n == 0) and 'names no trigger' or 'names more than one trigger' error("bad
  combo '" .. tostring(combo) .. "': " .. why ...)`. `split_combo` (`:46-57`) and `normalize_combo`
  (`:67-75`) are the canonicalisation functions the doc comment (`:77-83`, quoted in the source) says
  used to silently keep the last trigger — now feeding `check_combo`'s raise instead.
- **(b) At base `3256aac`:** `ABSENT`, same evidence as entry 33 (`split_combo`/`normalize_combo`
  absent at base).
- **Self-declared provenance:** none claimed pre-existing.
- **Proposed classification:** `INTRODUCED-IN-BRANCH`.

#### 35. A combo table cannot express a modifier-class rule (RESOLVED, 2026-08-03) -- `input.md:2513`

- **Claim:** a trailing `*` now binds a whole modifier class (`alt+*` = every Alt chord, D-COMBO-SHAPE);
  exact bindings win, class is consulted only on a miss, and it never matches the modifier's own press.
- **(a) Resolution at HEAD:** `HOLDS`, structurally. `grep -n "'\*'"
  src/controller/projectInputController.lua` -> `:107`, `:112`: `return tbl[Controller.combo_string
  ('*')]` — a fallback class-lookup keyed by the modifier-plus-`*` combo string, consistent with
  "exact bindings win, class consulted only on a miss." Did not separately re-verify the "never matches
  the modifier's own press" edge case at HEAD (would need tracing `combo_string`'s exclusion of a held
  modifier from matching its own class) — flagged under "not verified."
- **(b) At base `3256aac`:** `ABSENT`. `projectInputController.lua` and the `'*'`-class lookup pattern
  both postdate base — consistent with the whole shortcut/combo-tables mechanism being branch-new
  throughout this section (`D-COMBO-TABLES` is a ratified decision of this branch).
- **Self-declared provenance:** none claimed pre-existing.
- **Proposed classification:** `INTRODUCED-IN-BRANCH`.

#### 36. Combo-string dispatch allocates a table per call — RESOLVED 2026-08-16 -- `input.md:2551`

- **Claim:** `combo_string` (`controller.lua`) used to build a `parts` table and `table.concat` it per
  call; fixed at `737d8316` to accumulate the string directly, no table allocated. `find_shortcut`
  still calls `combo_string` twice on a miss (exact + `'*'` class), left as a smaller, accepted cost.
- **(a) Resolution at HEAD:** `HOLDS`. `sed -n '390,398p' controller.lua`:
  `local function combo_string(k) local combo = '' for _, m in ipairs(COMBO_MODS) do if
  MOD_HELD[m[3]]() then combo = combo .. m[3] .. '+' end end return combo .. k:lower() end` — string
  concatenation only, no table construction. Did not independently re-verify the `find_shortcut`
  double-call claim (a secondary, explicitly-not-fixed detail) — flagged under "not verified."
- **(b) At base `3256aac`:** `ABSENT`. `combo_string` doesn't exist at base (established under entry
  16); the whole function, table-allocating or not, is branch-new.
- **Self-declared provenance:** none claimed pre-existing — this is a performance fix to branch-new
  code, not a defect inherited from base.
- **Proposed classification:** `INTRODUCED-IN-BRANCH`.

#### 37. `F.reset()` test helper exceeds the 14-line function-body limit (RESOLVED, 2026-07-31) -- `input.md:2569`

- **Claim:** the ~18-code-line helper now delegates to production teardown (`CC:stop_project_run()`)
  and is down to nine code lines "as of the widget-shown fix."
- **(a) Resolution at HEAD:** `HOLDS` on the substantive claim (under the 14-line hard limit), `PARTIAL`
  on the specific figure. Read `tests/helpers/input_fixture.lua:325-357` in full: the function calls
  `CC:stop_project_run()` (delegating to production teardown, as claimed) and I count **11** executable
  (non-comment) lines — `:329`, `:330`, `:336`, `:340`, `:341`, `:342`, `:347`, `:348`, `:349`, `:350`,
  `:356` — not nine. Both are comfortably under the 14-line limit this entry is about, so the actual
  defect (exceeding the limit) is resolved either way; the entry's "nine" may have drifted as later,
  unrelated lines were added (one comment block explicitly references a *later* discovery, "the
  route-lifecycle inspect case," suggesting the function grew after this entry closed). Not a
  resolution failure, but the entry's own count no longer matches what's on disk.
- **(b) At base `3256aac`:** `NOT CHECKABLE` in the usual sense — `tests/helpers/input_fixture.lua` is
  a test-suite fixture for the `compy.input` surface, which is branch-new throughout; a fixture for a
  surface absent at base cannot itself have existed at base in any comparable form. Did not run
  `git ls-tree` to confirm the file's absence explicitly, since the surface-absence argument already
  establishes it; flagged as inferred rather than directly measured for this one entry.
- **Self-declared provenance:** none claimed pre-existing.
- **Proposed classification:** `INTRODUCED-IN-BRANCH`.

#### 38. `submit()`'s deliver-then-hide ordering forced example-side deferral of any reshow (RESOLVED by the input-API redesign) -- `input.md:2581`

- **Claim:** auto-close-on-submit is gone (D-NO-FW-TIER); `after_submit` defaults to a no-op and the
  widget stays open, removing the need for the one-frame-deferral workaround the entry describes.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "function.*submit_flow\|after_submit = noop"
  src/controller/userInputController.lua` -> `after_submit = noop` in the defaults table (`:21`),
  `UserInputController:submit_flow` present (`:461`) — matches "now `submit_flow`," no-op default.
- **(b) At base `3256aac`:** `ABSENT` for the described mid-branch shape. `git grep -n
  "function.*:submit\b\|deliver(self" 3256aac -- src/controller/userInputController.lua` -> no hit.
  Reading the actual base `submit()` (already done for entry 20): it calls a single `self.result(t)`
  callback with no unconditional `hide()` afterward in what I read — the specific "`deliver` then
  unconditional `hide()`" shape this entry names as "old state" appears to be a **mid-branch**
  intermediate design, not the base-era one; base's design was different again (single callback, no
  auto-hide apparent). I did not exhaustively trace whether base's `submit()` had *some* hide-on-submit
  behaviour elsewhere in the surrounding code — flagged under "not verified," but the `deliver`/
  `after_submit` vocabulary itself is unambiguously absent at base.
- **Self-declared provenance:** none claimed pre-existing; the entry's own "Old state" is a mid-branch
  snapshot ("now `submit_flow`" implies a prior branch-internal name, not a base one).
- **Proposed classification:** `INTRODUCED-IN-BRANCH`.

#### 39. `_generic_callback` re-resolves the callback precedence on every event (RESOLVED by the input-API redesign) -- `input.md:2598`

- **Claim:** `_generic_callback` is gone; D-HOOKS-SEEDED replaced per-event precedence resolution with
  one `hooks[event]` table seeded once at `activate` (`seed_hooks`).
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "_generic_callback\|function seed_hooks"
  src/controller/projectInputController.lua` -> no hit for `_generic_callback`; `seed_hooks` present
  (`:64`), called at `:169` with a doc comment citing D-HOOKS-SEEDED.
- **(b) At base `3256aac`:** `ABSENT`. `git grep -n "_generic_callback" 3256aac -- src` -> no hit —
  `projectInputController.lua` and its whole precedence mechanism (old or new) is branch-new
  (consistent with `D-HOOKS-SEEDED` being a ratified decision of this branch).
- **Self-declared provenance:** none claimed pre-existing.
- **Proposed classification:** `INTRODUCED-IN-BRANCH`.

#### 40. Pointer delivery is an unstructured broadcast, not a chain (RESOLVED, 2026-08-03) -- `input.md:2613`

- **Claim:** pointer now joins the existing keyboard/text chain (D-ONE-LIFETIME) rather than being a
  separate mirrored broadcast; a pointer hook can starve the widget of a click by consuming truthily.
- **(a) Resolution at HEAD:** `PARTIAL` evidence, light check only. `grep -n "function.*keypressed\|
  function.*mousepressed\|function.*pointer" src/controller/controller.lua` -> found
  `mark_pointer_liveness` (`:250`) and the keyboard gateway (`:487`), consistent with pointer and
  keyboard sharing infrastructure, but I did not trace the actual dispatch call graph to directly
  confirm pointer events now enter the *same* `dispatch`/chain function keyboard/text use, nor did I
  re-derive the "measured across `life`, `sapper`, `tixy`, `paint` and `pong`, no project pointer
  handler returns a value" claim (that would mean opening those example projects, several of which —
  per entries 13/14 — are separate untracked repos outside straightforward base-comparison anyway).
  Flagged under "not verified" — I am relying more heavily here on the entry's own internal coherence
  and its consistency with `D-ONE-LIFETIME`'s established branch-wide role elsewhere in this section.
- **(b) At base `3256aac`:** not separately measured for this entry; by the section-wide pattern
  (pointer/keyboard unification is `D-ONE-LIFETIME`'s work, and that decision itself is absent at
  base per the decisions-ledger check earlier), I infer `ABSENT`/`INTRODUCED-IN-BRANCH`, but this is
  inference from pattern, not a direct grep for this entry — flagged explicitly as the weakest-evidence
  entry in this batch.
- **Self-declared provenance:** none claimed pre-existing; frames the old "unstructured broadcast" as
  a design gap in the input API's own predecessor state, which is itself branch-internal (the input
  API predates nothing at base).
- **Proposed classification:** `INTRODUCED-IN-BRANCH`, lower confidence than most of this batch — the
  parent should treat this one as needing its own direct check if it matters for the roadmap decision.

### Batch 6 — gap-fill (5 entries skipped between batches 3-4) + final 5 entries

**Correction, reported per the commission's honesty requirement:** while re-numbering entries
sequentially across batches I skipped five headings (`input.md:2148`, `:2156`, `:2167`, `:2184`,
`:2237`) between what I labelled "batch 3" and "batch 4" — they were read (in the same file read
that covered batch 3's range) but not written up. Caught while reconciling the running total against
the 50-entry count. Filled in below, in their correct heading order, alongside the five entries that
close the file. Every entry in this whole section carries its exact `input.md:LINE` citation, which
is unaffected by the numbering slip — only the running `#### N.` labels were off; this batch's
labels resume a plain running count and are not meant to imply original position.

#### 41. `show{force = true}` applied some keys, dropped one, deferred another (RESOLVED, 2026-08-27) -- `input.md:2148`

- **Claim:** dissolved rather than patched — a forced `show` now takes the ordinary activation path,
  so there's no separate `force` path left to misbehave. `re_show` (`userInputController.lua`) is
  deleted outright.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "function.*re_show\|local function re_show"
  src/controller/userInputController.lua` -> no hit; the function is gone, matching "Where it was...
  deleted."
- **(b) At base `3256aac`:** `ABSENT`. `git grep -n "re_show" 3256aac -- src` -> no hit — `re_show`
  (and the whole `show{force=...}` mechanism) is branch-new; there is no force-path defect to have
  pre-dated the branch.
- **Self-declared provenance:** none claimed pre-existing.
- **Proposed classification:** `INTRODUCED-IN-BRANCH`.

#### 42. `show{cursor = {}}` raised a raw Lua error from inside the framework (RESOLVED, 2026-08-27) -- `input.md:2156`

- **Claim:** `checked_cursor` at the project boundary now refuses a malformed cursor pair with a
  named-shape message, on both `show{cursor=...}` and `compy.input.set_cursor`; out-of-range numbers
  still clamp; `cursor = false` is the uniform unset.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "function checked_cursor"
  src/controller/consoleController.lua` -> present at `:705`.
- **(b) At base `3256aac`:** `ABSENT`. `git grep -n "checked_cursor" 3256aac -- src` -> no hit; the
  project-facing `set_cursor_pos`/`checked_cursor` boundary (see also entry 15/T-CURSOR-BYTES, which
  independently established `set_cursor_pos` as branch-new) doesn't exist at base.
- **Self-declared provenance:** none claimed pre-existing.
- **Proposed classification:** `INTRODUCED-IN-BRANCH`.

#### 43. The highlighter had two homes, and one of them lagged (RESOLVED, 2026-08-27) -- `input.md:2167`

- **Claim:** one home now — the widget's `callbacks` slot is the source of truth, and the evaluator
  **resolves** it (`UserInputController:bind_highlighter`) rather than holding its own copy.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "function.*bind_highlighter"
  src/controller/userInputController.lua` -> `UserInputController:bind_highlighter` present at `:82`.
- **(b) At base `3256aac`:** `ABSENT`. `git grep -n "bind_highlighter" 3256aac -- src` -> no hit; the
  whole `show`/`configure` highlighter-callback surface (and therefore its two-homes defect) is
  branch-new.
- **Self-declared provenance:** none claimed pre-existing.
- **Proposed classification:** `INTRODUCED-IN-BRANCH`.

#### 44. `wrap`'s error handler is called with the wrong arity, so project raises vanish (RESOLVED, 2026-08-03) -- `input.md:2184`

- **Claim:** `wrap` (`controller.lua`) used to call `xpcall(f, user_error_handler, ...)` directly —
  `xpcall` invokes its message handler with exactly one argument, but `user_error_handler(CC, msg)`
  takes two, so `CC` bound to the error string and `msg` was nil, swallowing the raise inside the
  handler itself. Fixed (`2554d2e3`) by binding `CC` in a closure used by both branches. Entry states:
  *"Pre-feature, verified: `wrap` and `user_error_handler` are byte-identical at the PR base
  `3256aac`."*
- **(a) Resolution at HEAD:** `HOLDS`. `git log --oneline -1 2554d2e3` -> resolves to *"fix(input):
  bind CC in wrap's error handler so raises reach the user"*. `controller.lua:138-146` (already read
  for entry 22): `wrap` closes an inner `on_error(msg)` that calls `user_error_handler(CC, msg)` — `CC`
  is a true closure-bound upvalue, not an `xpcall`-supplied argument, so the arity mismatch cannot
  recur.
- **(b) At base `3256aac`:** `PRESENT`, confirming the entry's claim exactly. `git show
  3256aac:src/controller/controller.lua` (`:59-69`) shows the pre-fix `wrap`: the non-web branch is
  `return xpcall(f, user_error_handler, ...)` verbatim — precisely the buggy shape described (single-
  argument message-handler invocation against a two-parameter function).
- **Self-declared provenance:** *"Pre-feature, verified"* — confirmed here by direct measurement, not
  taken on the entry's word.
- **Proposed classification:** `PRE-EXISTING`, measured directly. (Distinct from the `_G.web`-branch
  defect in entry 22 and from the *different*, branch-introduced bare-`xpcall` regression described in
  `general.md`'s BACKLOG entry "The Web build has no coverage" — three separate `wrap`/`xpcall` defects
  live in this section's evidence; do not conflate them.)

#### 45. `compy.before_exit` is absent from the persistent API docs (RESOLVED, 2026-08-03) -- `input.md:2237`

- **Claim:** documented in `doc/input_api.md`, "Stop hook — `compy.before_exit`" — signature, ignored
  return, timing, which stop paths fire it (not a raise), the reset.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "Stop hook\|compy.before_exit" doc/input_api.md` ->
  heading at `:865` (`## Stop hook — \`compy.before_exit\``), worked example at `:877`.
- **(b) At base `3256aac`:** `ABSENT`. `git grep -n "before_exit" 3256aac -- src` -> no hit anywhere;
  the hook and its documentation are both branch-new (`doc/input_api.md` itself absent at base,
  established at the top of this section).
- **Self-declared provenance:** none claimed pre-existing.
- **Proposed classification:** `INTRODUCED-IN-BRANCH`.

#### 46. `UserInputController:keypressed` forked on `love.state.app_state == 'editor'` (RESOLVED, 2026-07-21) -- `input.md:2637`

- **Claim:** the `if love.state.app_state == 'editor' then … else … end` fork inside the widget's
  `keypressed` is deleted; the editing keymap difference becomes a per-instance `allow_duplicate_line`
  constructor flag, and the editor now consumes Enter/Escape upstream instead of the widget branching
  on global mode.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "app_state == 'editor'\|allow_duplicate_line"
  src/controller/userInputController.lua` -> **no** hit for the `app_state == 'editor'` fork; instead,
  `allow_duplicate_line` appears as a constructor parameter (`:28-34`) and a guard at the Ctrl+D site
  (`:740`, `if self.allow_duplicate_line then modify() end`) — exactly the described replacement.
- **(b) At base `3256aac`:** `PRESENT`, and this is a genuinely pre-existing abstraction leak. `git
  grep -n "app_state == 'editor'" 3256aac -- src/controller/userInputController.lua` -> hit at
  `:362` — the fork already existed at base, in the file's pre-multiline-era shape.
- **Self-declared provenance:** not framed explicitly as pre-existing/ours by the entry, but flagged
  by the owner "2026-07-20" (a date **before** this file's earliest branch-dated entries elsewhere in
  this register, consistent with an early-branch fix of inherited code) as "an abstraction leak" — the
  measurement above confirms the leak itself predates the branch.
- **Proposed classification:** `PRE-EXISTING`, measured directly.

#### 47. Comment wip-citation cleanup (RESOLVED, 2026-07-30) -- `input.md:2662`

- **Claim:** comments citing the feature's ephemeral wip tree (instead of a canonical doc) were
  rehomed — controller comments to the `decisions/input.md` decisions they already cited, four
  shipped-example comments to `doc/input_api.md`, "Submit lifecycle." Originally filed as two
  comments, a pre-PR revalidation found thirteen across seven files; entry kept specifically to record
  the undercount as the lesson.
- **(a) Resolution at HEAD:** `HOLDS`, partially re-verified. `grep -rn "wip/77-new-input-api"
  src/controller/*.lua` -> no hits — the controller-side citations are gone, consistent with the
  claim. Did not re-run the same check across the four `src/examples/` files the entry names (three
  of which — per entries 13/14/21's findings — may live in separately-versioned example repos with
  their own citation conventions), nor re-derive the "thirteen across seven files" count myself —
  flagged under "not verified."
- **(b) At base `3256aac`:** `NOT APPLICABLE` / effectively `ABSENT` — a citation into
  `doc/development/wip/77-new-input-api/` cannot exist in any file at base, because that whole
  directory is absent at base (established at the top of this section). Any such citation, wherever
  it appeared, is by construction branch-internal.
- **Self-declared provenance:** none claimed pre-existing; explicitly a hygiene defect in this
  branch's own commenting practice.
- **Proposed classification:** `INTRODUCED-IN-BRANCH`.

#### 48. An `update_prompt` endpoint was asked for and declined; `configure` already is one -- `input.md:2675`

- **Claim:** a code remark in `src/examples/balloons/terminal.lua` asked for an `update-prompt`
  endpoint; declined by the owner (2026-08-11) as sugar over `compy.input.configure{prompt=...}`,
  which the file's own `terminal_write`/`write` already demonstrates.
- **(a) Resolution at HEAD:** `HOLDS`. `grep -n "prompt" src/examples/balloons/terminal.lua` -> `:23`:
  `compy.input.configure({ prompt = msg })` — the recommended pattern, live in the file. The remark
  itself that asked for the endpoint is gone; balloons' own log (`git -C src/examples/balloons log
  --oneline -- terminal.lua`) shows `"docs: retire the review remark, both halves already ruled"`
  (`99ad70f`), consistent with the decline being acted on.
- **(b) At base `3256aac`:** `NOT CHECKABLE`, same structural reason as entries 13/14/48 —
  `src/examples/balloons` is a separate, untracked, independently-versioned repo; `3256aac` has no
  bearing on its history, and `compy.input.configure` (the very capability being discussed) is itself
  entirely absent at the platform's base.
- **Self-declared provenance:** not framed relative to platform base; the request and its decline are
  both dated well within this branch's timeline.
- **Proposed classification:** `CANNOT TELL` for the base-provenance question (structural reason as
  entries 13/14), though given `compy.input.configure` itself is `INTRODUCED-IN-BRANCH` throughout
  this whole section, the practical answer is very likely `INTRODUCED-IN-BRANCH` too — flagged as
  inference rather than direct measurement.

#### 49. `userlove` does not convey its semantics (CLOSED — ruled to keep, 2026-08-03) -- `input.md:2691`

- **Claim:** owner ruled to keep the name; no code changed. The entry's earlier scope covering
  `forward_keypressed`/`forward_keyreleased`/`forward_textinput` was corrected out (those were
  deleted, not renamed — see entry 32/`input.md:2431`).
- **(a) Resolution at HEAD:** `HOLDS` — "no rename happened" is the claim, and it checks out. `grep -n
  "userlove" src/controller/controller.lua` -> the parameter name is used throughout (`project_handler
  (userlove, key)`, `project_handlers(userlove, CC)`, etc.) — unchanged, as a kept-not-renamed
  identifier should be.
- **(b) At base `3256aac`:** `PRESENT`. `git grep -n "userlove" 3256aac -- src` -> hits in
  `controller.lua` from base (`set_handlers = function(userlove, CC)`, `:73`, and further reads at
  `:77/:89/:96`) — the name predates the branch; this entry is about a branch-time proposal to rename
  **inherited** code, declined.
- **Self-declared provenance:** not stated as pre-existing/ours explicitly, but the ruling is about
  whether to rename an existing identifier, which presupposes it already existed.
- **Proposed classification:** `PRE-EXISTING` for the identifier itself (measured); the retirement
  (a ruling not to touch it) is of course a branch-time event, but the *subject* debt (an unclear
  inherited name) predates the branch.

#### 50. The console's prompt is drawn under a project that never takes over `love.draw` (DISPUTABLE, ruled to keep 2026-08-07) -- `input.md:2715`

- **Claim:** `ConsoleView:draw`/`drawConsole` paints the console's input strip whenever screen mode
  isn't `editor`, regardless of whether the active project (like `sapper`) draws through the console
  terminal without defining its own `love.draw` — so the strip sits inert under the game for the whole
  session. Ruled to keep as-is (owner, 2026-08-07): the view should not carry project-lifecycle
  knowledge for one example's cosmetics. No code changed.
- **(a) Resolution at HEAD:** `HOLDS` — again a "nothing changed" claim. `grep -n
  "function.*drawConsole\|function ConsoleView:draw" src/view/consoleView.lua` -> `ConsoleView:draw`
  at `:43`, inner `drawConsole` at `:48` — present and, per the claim, unconditioned on project draw
  ownership.
- **(b) At base `3256aac`:** `PRESENT`, and essentially unchanged in shape. `git grep -n
  "drawConsole\|function ConsoleView:draw" 3256aac -- src/view/consoleView.lua` -> the same two
  symbols at the same lines (`:43`, `:48`, plus the `:67` call site) — the drawing mechanism this
  entry is about already existed at base in this shape.
- **Self-declared provenance:** not stated explicitly; `sapper` (the triggering example) is described
  elsewhere in this register as a pre-existing pen-and-paper example, and the view code measured above
  predates the branch.
- **Proposed classification:** `PRE-EXISTING` for the underlying drawing mechanism (measured); the
  entry itself is a ruling not to change pre-existing behaviour for a cosmetic concern surfaced during
  this branch's own smoke testing, not a claim that the branch introduced the condition.

---

## What I did not verify

Stated plainly, per the commission — an unchecked claim named is worth more than a checked claim
overstated:

- **No test suite was run**, per the hard constraint. Every "mutation-tested"/"suite green"/"111
  failures" style claim inside a RESOLVED entry's own text was read as historical record, not
  re-executed. Where an entry's resolution claim rests entirely on such a run (e.g. the config-key
  agreement spec's bidirectional mutation test), I checked the artifact exists and its logic reads as
  described, not that it currently passes.
- **`lua-lsp` (the MCP language server) was not used at all in this pass.** Every check in this
  deliverable was `git grep`/`git show`/`git ls-tree` plus direct file reads, because every question
  this commission asks — "does X exist at HEAD," "does X exist at base `3256aac`" — is answered more
  directly and more verifiably by grepping two trees than by asking a language server about live-
  workspace references, which only ever answers the HEAD half and (per the commission's own warning)
  has produced false-negative "no references" results in this workspace before. Flagging the omission
  explicitly since the commission calls out the tool as available: I judged it added no value over
  `git grep` for this specific task shape, not that I hit a `broken pipe` or empty-result trap.
- **Three entries' base-provenance question is structurally unanswerable** through this method
  (`T-MAZE-NEUTRALIZE`, `T-BALLOON-LABEL`, the `update_prompt` entry) — they concern
  `src/examples/maze` and `src/examples/balloons`, untracked sibling repos with their own git history,
  not pinned to the platform's `3256aac` in any way. I did not attempt to reconstruct an equivalent
  "base" for either sibling repo (e.g. by date-correlating their own early commits against
  `3256aac`'s date) — that would be inference, not measurement, and the commission asks for the
  latter.
- **The full `S67-mermaid-audit.md`'s 32-class-block field-by-field walk was not re-performed** — I
  measured the one line this section's entry says is "ours" (`editor.md`'s `oneshot`) directly against
  base, and took the rest of that audit's findings (about `InputModel`, `InterpreterModel`, etc. all
  postdating base too) on the entry's own citation, since re-deriving a 32-block audit is a
  differently-scoped task from this commission's per-entry pass.
- **Two entries' "did master have this defect, pre-`0022004`" and "was this byte-identical on a ref
  other than `3256aac`" claims were not independently re-derived** (`input.md:2312`'s "Input-only /
  pointer-only projects," and implicitly anything else in the register citing a ref other than the PR
  base) — this commission's scope and tooling is specifically the `3256aac` base check; a different
  historical ref is a different question with a different answer, and I did not chase it.
- **I did not open, and therefore could not verify, anything the commission scoped out**: no file
  under `doc/development/wip/77-new-input-api/` other than this deliverable was read, including the
  two `general.md` entries whose subject lives entirely there (renumber crosswalk, `FIX-02` citation
  sweep) — their (a) resolution claims are marked `NOT CHECKABLE` rather than guessed at.
- **No `broken pipe` or empty-`references` trap was hit**, because the MCP tool was not invoked — see
  above. Recorded so the parent does not read the absence of a trap report as evidence the tool was
  used and behaved.
