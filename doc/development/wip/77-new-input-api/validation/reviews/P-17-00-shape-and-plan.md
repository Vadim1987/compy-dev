# P-17-00 — the new shape: fork the edge, adopt by checklist, plan from the analysis

**Session:** 39. **Date:** 2026-08-12. **Status:** shape **ratified by the owner**; the analysis
(`P-17-03`) is the work; the execution substeps (`P-17-05`…) do not exist yet.

**Supersedes** the shape P-17-00 carried until now — *"the same three moves `keyboard` had: assess,
merge, plan"* (`session39/prompt.md`, and `S27-triage-and-plan.md` §15.3). The assessment was
performed and is `S39-maze-upstream-input-assessment.md`; it is what made the old shape untenable and
this one obvious. The old shape is not wrong so much as **inapplicable**: it was built for a repo
whose upstream had left our work intact.

---

## 0. Why the shape changed

Two facts from the assessment, and one from the owner.

- **The merge does not apply, and merging is not the useful part.** `main.lua` is a modify/delete
  conflict; our entire migration lives in the file upstream deleted. Our `main.lua` defines 53
  globals and **48 are redefined** by upstream's split files, `rearm_input` among them with different
  semantics — so the conservative resolution produces a tree that does not raise and does not work.
  Whatever the resolution, **none of our four commits' text survives and all of their intent has to
  be re-applied to different code** (assessment §3, §4.1).
- **The rework is deep enough that "carry our patch across" is the wrong frame.** `main.lua` split
  into five files, a shared `core_editor.lua`, a second program, three `spec/` suites, a build step.
  Reconciling a 67-line patch against that is more expensive, and less honest, than doing the
  adoption again on the code as it now stands.
- **Owner ruling (2026-08-12), and it is the frame for everything below:** *"we fork off brand new
  branch from maze's dsent edge and it becomes our working branch — I especially ratify that move."*

**What that buys, beyond avoiding a bad merge:** the slice question in `pr-assembly-guide.md` §5.1
dissolves. A branch **forked from** `dsent/dsent/dev` has that ref as an ancestor by construction, so
`git diff dsent/dsent/dev..HEAD` is exactly our change, on day one, with no ancestor check to
remember and no reversal-of-26-commits trap to fall into.

**What it costs, stated plainly:** the four commits on `newinput` stop being the deliverable. They
are not deleted and not wasted — `P-17-01` promotes them to *evidence*. `newinput` and
`newinput-backup-copy-20260811` stay where they are; nothing is rewritten.

---

## 1. The shape, as numbered substeps (owner, 2026-08-12; ids assigned 2026-08-12)

### P-17-01 — Inventory the practices, as a catalogue and nothing more  ✅ **DONE**

Two sources, both **guidance, not mandate** — the owner's word is that they *"serve merely as a
catalogue of practices that **may** be used for maze… or not"*:

1. **What we did to maze's old base** — the four commits on `newinput` (`790ac19`, `d2ce7a0`,
   `aeabb73`, `a045fdb`): the editor-prompt migration, the idle gate, `Key.shift()`, and the two
   owner `REMARK:`s. This is the only place anyone has previously reasoned about *this game's* input,
   and its reasoning (recorded at length in those commit messages) is worth more than its diff.
2. **What `keyboard` learned** — and the point is **not to re-derive it**. P-18 produced review
   material that already names the practices and the traps:
   `P-18-00-triage-and-plan.md` (§0's two calibrations, §5's four rulings, §§6-11's execution record),
   `P-18-00-keyboard-deepfix-design.md` (§1.1 the game's rules are not ours, §1.2 the delivery order
   is not a guarantee, §7.1 R1–R5), and the four cold reviews
   `S38-P18-final-revalidation{,-2,-3}.md` + `S38-P18-narrow-review.md`.

Deliverable: **one catalogue document**, `validation/reviews/P-17-01-practice-catalogue.md`, that
states each practice, where it came from, and *whether maze's code presents the shape it applies to*
— with "does not apply here" as a first-class, expected answer.

### P-17-02 — Fork the working branch off the edge  ✅ **ratified — and DONE**

**`newinput-edge`, forked from `dsent/dsent/dev` @ `b8cc436`, 2026-08-12.** It is the working branch;
`newinput` (`a045fdb`) and `newinput-backup-copy-20260811` are untouched as the record of the old
attempt. No merge, no rebase, no history rewrite, nothing pushed.

`git merge-base --is-ancestor dsent/dsent/dev HEAD` → **safe**, and `git diff dsent/dsent/dev..HEAD`
is empty, as a fresh fork should be. `pr-assembly-guide.md` §5.1's maze row is updated to match.

**And the first thing the new branch proves is the smoke question — measured, not predicted:**

```
$ timeout 25 xvfb-run -a stdbuf -oL -eL love src play src/examples/maze
Project play opened
Press Ctrl-Esc to exit
[string "main.lua does not exist"]:1: '=' expected near 'does'
```

`BUILD.md` was right: the source root is not a runnable project, and **this sprint's smoke command
for maze is dead, and §4.3 records the replacement the owner ruled (build, then play the emitted
project) — measured working.** (The platform's error path there is its own
small finding — it feeds the *message* "main.lua does not exist" into the Lua compiler and reports
the syntax error of that sentence. Not this step's business; worth someone's.)

### P-17-03 — The analysis, driven by `input_adoption.md`

The primary instrument is **`doc/development/conventions/input_adoption.md`** — Decision 32's
operational form, Q1–Q10 plus five rules of restraint. The catalogue from `P-17-01` is a **secondary**
source, consulted after the checklist has had its say, so that maze is read on its own terms rather
than through `keyboard`'s.

The analysis answers three questions per site, and the owner's phrasing fixes their order:

1. **Regressions the new platform may introduce.** The platform under this branch is *not* the
   platform upstream was written against, and the difference is not only additive. The known one is
   the removed overlay gate (assessment §2.2): at the PR base a shown widget meant the project's
   handler was **not called at all**; now the project route walks shortcuts → hooks → widget. Every
   place where this game has a handler and a live field at the same instant is a candidate.
2. **Locally-duplicated machinery to replace with the platform's.** `is_shift_down` ×2, the held-key
   sets (`plan_held`, `macro_state.shift_held`), the poll-plus-`_was_down` edge detectors ×2. Q1, Q2,
   Q4.
3. **Focused migrations where the gain is real — and a report where it is not.** The owner's standing
   test (2026-08-12): *"is the replacement justified on its own terms"*, not *"can the project avoid
   the API"*. **Where there is no gain, that is an outcome to write down, not a site to convert.**

Deliverable: `validation/reviews/P-17-00-adoption-analysis.md` — site by site, each carrying its
checklist question, its verdict, and, where it is a behaviour change, the words that say so.

### P-17-04 — The triage: turn the analysis into execution substeps

From the analysis, a triage into **`P-17-05`, `P-17-06`, …** — dependency-ordered, each its own
commit, with any remaining owner rulings named before a child starts. **The last of them is always
the comment-compaction pass** (§5).

---

## 2. Tests — a real asset, and the ruling on growing it

Unlike `keyboard`, this repo **has a suite**: `spec/script_spec.lua`, `spec/draw_levels_spec.lua`,
`spec/draw_mode_spec.lua`, run by plain `lua` from the repo root, plus `verify.sh` (compile check +
the three specs + a self-containment check per emitted project), plus the author's own
`TEST-PLAN.md` for what only a device can show.

**So `agents/development.md`'s "start with a breaking test" is available here**, and the suite is
also a regression fence the reconciliation can lean on.

**Measured on the new branch, 2026-08-12 — it all works in this container:**

| what | result |
|---|---|
| `luajit spec/script_spec.lua` | **29 passed / 0 failed / 0 pending** |
| `luajit spec/draw_levels_spec.lua` | **10 passed / 0 failed / 0 pending** |
| `luajit spec/draw_mode_spec.lua` | **3 passed / 0 failed / 0 pending** |
| `./verify.sh` (emit → `luac -p` every file → the three specs → self-containment per project) | **`== OK: build verified ==`** |

**The baseline for this step is therefore 42 / 0 / 0**, and `verify.sh` is a real fence, not a
promise. Two environment facts a successor must not rediscover:

- **This container has `luajit` only** — no `lua`, no `lua5.1`, no `luac`. `verify.sh` probes
  `command -v lua || command -v lua5.1` and calls `luac -p`, so it needs a shim on `PATH`
  (`lua` → `exec luajit "$@"`; `luac` → `luajit -e "assert(loadfile([[$f]]))"` per argument). Put the
  shim somewhere **executable** — the session scratchpad is mounted `noexec` and fails silently-ish
  with *Permission denied*. This is an environment gap, **not** a defect in their script.
- **`BUILD.md`'s spec counts are stale** — it says `8` for draw-levels and `2` for draw-mode where
  the suites report `10` and `3`. Harmless (`verify.sh` checks exit codes, not counts) and *theirs*,
  not ours; noted because a count in a document is a claim like any other, and the next reader will
  otherwise think something regressed.

**Settled by the owner, 2026-08-12 — the suite does NOT grow (§4.4).** The 42 assertions stay a
regression fence; no input behaviour gets suite coverage, so the human smoke pass is the only gate
this step has.

---

## 3. Boundaries carried forward unchanged

- **The game's rules are not ours.** *"Would a player notice a difference?"* If yes, it is out of
  scope — raise it, do not do it. (`P-18-00-keyboard-deepfix-design.md` §1.1.)
- **A deviation lives in the workspace**, not only in a commit message.
- **No comment in an example repo may cite a platform doc** (owner, 2026-08-12). The repo's only such
  citation today is ours (`main.lua:565`), and it is on the branch we are leaving — it must not be
  re-introduced in the re-application.
- **NEVER push**, this repo or the nested three. Commit locally, one concern per commit, suite stated
  in every message even when untouched.

## 4. The rulings — ANSWERED (owner, 2026-08-12)

The fork settled the merge. The rest were put to the owner and answered:

### 4.1 `<` STAYS. We add the capability; we do not delete the author's command.

**Ruled: agreed.** The author's `TEMPORARY` comment asks for `<` to be removed once Shift+Esc
reaches a program from an active field, and this feature makes that true — but `<` is a **command in
the game's language**, so deleting it is a change a child would notice, and §1.1 forbids it. We
**register `shift+escape`** (pure added capability, breaks nothing) and **leave `<` in place**; the
PR reports to the author that their stated condition is now met. **The deletion is theirs to make in
their own repo.**

### 4.2 `draw` IS in scope

**Ruled: yes.** Cheaper than it looked: the cold inventory established that **`ctrl_pressed` is
structurally always `nil` in DRAW** (`controls.lua` is MAZE-only, and is the only file that assigns
it), so `drawGameKey`'s fallback is dead code and draw's whole in-game keyboard surface is the editor
field, the Escape branch and the Tab poll. Its 8 sites are mostly duplicates of maze's.

### 4.3 The smoke path — build and play the emitted project. MEASURED, works.

```sh
cd src/examples/maze && ./.compy/build /abs/scratch/emit
cd /repo && timeout 25 xvfb-run -a stdbuf -oL -eL love src play /abs/scratch/emit/maze
```

Both programs load and run this way — *"Project play opened" / "Running 'play'"*, no raise
(2026-08-12). **The source root itself stays unplayable, by upstream's design.** The larger
question — *should the platform implement the `.compy/build` convention?* — is **promoted, not
answered here**: the string appears nowhere in `/repo/src` or `/repo/doc`, so today it is upstream's
own convention (or the `dsent` fork's), and adopting it is a packaging decision, not an input one.

### 4.4 The suite does NOT grow (owner)

**Ruled:** *"let's not grow the suite — if the author wanted to test input they would drop in at
least some tests. Adding them just during development and deleting before the PR would likely be an
overkill."*

**What follows, and it must be stated because it is a real consequence:** the existing 42 assertions
stay a **regression fence** (run `./verify.sh` at every commit — it is free and it is theirs), but
**no input behaviour will be covered by any suite**. So **input correctness rests entirely on the
human smoke pass**, exactly as it did for `keyboard`. That makes `doc/development/smoke_checklists.md`
the only gate this step has, and writing maze's section is therefore **`P-17-04`'s to schedule, not a nicety** —
with the launch commands from §4.3, since the old one no longer works.

### 4.5 The two `REMARK:`s — both discharged, neither re-planted

Both lived in `main.lua`, which `newinput-edge` does not contain, so the marker gate is satisfied
with nothing to sweep. Their content:

- *"can we try using shortcuts/hooks and callbacks more actively?"* — **owner: a hint of direction,
  now superseded by the adoption guide.** `input_adoption.md` is the instrument that answers it, and
  step C runs on it. Nothing further owed.
- *"comment `*tooo*` verbose. simplify/compress"* — editorial, and it pointed at **our own** ~21-line
  comment block above `open_editor_input`/`rearm_input` (written by `790ac19`, rewritten by
  `d2ce7a0`). **It survives the fork as a constraint on the comments the new migration writes**, not
  as a marker to re-plant — and it agrees with `agents/rules/commenting.md`'s size rule. Note the
  same block also referenced the platform guide by title, which the 2026-08-12 citation ruling now
  forbids in an example repo: **do not reproduce either fault in `core_editor.lua`.**

---

## 5. Comments: verbose while the work is live, compacted once at the end (owner, 2026-08-12)

**Ruling:** *"the session of P-18 ended in a comment compaction substep. Here we just can do the
same. Reason: mid-development, verbose comments help assistants to get oriented in a fragile and
unstable codebase; it's only before release we need to compact them, drying up history/obituaries
and intermediate rulings."*

**So: do not compact as you go.** While `P-17-05…` are landing, a comment that over-explains is
doing real work — it orients the next reader in code whose reasoning is not settled yet, and this
step in particular is re-deriving a migration on a codebase none of us wrote. **The last execution
substep is a dedicated compaction pass**, taken once over stabilised code, on the `P-18-10` model:
dry up history, obituaries, intermediate rulings and second phrasings; keep the reasons. That pass
took `keyboard`'s `input.lua` from 177 comment lines to 101 without losing an argument.

Carried into `agents/rules/commenting.md` ("Where this is enforced"), so it binds beyond this step.

## 6. The citation rule, refined (owner, 2026-08-12)

The 2026-08-12 ban read as *"never cite a platform doc from inside an example repository"*. The
owner has narrowed it to what it was actually protecting:

> *"what is prohibited are links to files not reachable from detached repos. Merely referencing the
> platform guide by header is tolerable if it happens only in places where it's really needed."*

- **Prohibited:** a pointer to a file the repo does not contain — a `doc/…` path — and
  platform-internal identifiers such as decision numbers, which mean nothing to that reader.
- **Tolerable, where really needed:** naming the guide and its section — *"Compy Input API,
  'Submit lifecycle'"* — when the alternative is restating a contract the platform owns. A name a
  reader can search for is not a broken link; a path they cannot open is.

**This revises §4.5's closing instruction.** Our old `main.lua` block committed **one** fault worth
avoiding (its length), not two: its *"Compy Input API, 'Submit lifecycle'"* reference is exactly the
tolerated form. Carried into `agents/rules/commenting.md`, "Citations".
