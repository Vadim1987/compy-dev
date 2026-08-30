# session58 — track

## Boot — 2026-08-30

- HEAD `77786929` (`docs(FEAT-02): the name is auto_hide; the getter row is withdrawn`).
- Tree: only the known untracked scratch (`broken-busted/`, `claude.sh`, `input-pr-slices.tar.gz`,
  `repos.txt`, `src/STEPS.md`, `src/examples/{balloons,keyboard,maze}`, `worklog.md`) — no owner
  working-tree edits to step around. No tracked modifications.
- Suite: **1021 / 0 / 0 / 10** — matches the prompt's baseline.
- Fresh start: no prior `track.md`/`report.md` in session58.
- Read: `agents/validation.md`, `agents/sessions.md`, `agents/rules/revalidation.md`, session58
  prompt, session57 report, the attestation, `oneshot-at-the-pr-base.md`, `ROADMAP.md` FEAT-02
  block (431–524), Decisions 35 + 36, `T-ONESHOT-SCOPE`.

## Opening move — scoped revalidation (the two questions the prompt names)

**Q1 — does the case for `FEAT-02` hold?** Yes, verified in code, and the load-bearing claim is
**stronger** than filed: the "or an exact hand re-supply of `text` and `cursor`" escape hatch does
not exist. The project surface has no text getter (`build_widget_api`,
`consoleController.lua:811`), and Decision 18's sandbox means a project cannot read the model. So
disarming a live `oneshot` today does not cost typing that can be restored — it destroys a draft
the project **cannot read back**.

**Q2 — is the attestation executable on its own?** Two real ledger defects, both stale citations of
things withdrawn on 2026-08-30:

- `ROADMAP.md:457` (`FEAT-02-04`) still says renaming is off the table and repeats the
  *"not checkable in this repo"* claim the base check overturned.
- `ROADMAP.md:458` (`FEAT-02-05`) says `it is spent by its own show` *"becomes the going-down
  rule"* — the going-down rule is the **withdrawn** row. Executed literally it re-files the
  clearing rule the owner withdrew. This is the "citation that still resolves" hazard verbatim.

Third, softer: the attestation's ruling 1 carries the owner's superseded *"cleared on consumption"*
quote with no marker; 2a/2c supersede it further down.

Note: the same stale "renaming is off the table" sentence is in **this session's own prompt**
(immutable — recorded here, not edited).

Full note: `validation/reviews/FEAT-02-case-and-executability.md`.

## Execution

- `-01` landed as two commits: `8bca3c04` (the three stale citations) then `19f47df0` (Decisions 36
  and 35 amended, `T-ONESHOT-SCOPE`'s State corrected on the no-getter evidence).
- `-02` landed as `fe076244` — token-only rename, suite green at 1021, profiler / metalua / the two
  "oneshot is gone" historical comments deliberately untouched.
- `-03` was **blocked on an owner ruling** and is now `2c6fe978`. The ruled persistence
  retires the *implicit* disarm a bare `show{force}` used to perform, so
  `a forced follow-up show survives the close` fails — the case pins the category as well as the
  placement, and the roadmap + prompt both say it must keep passing. Evidence in
  `validation/notes/auto-hide-persistence-vs-the-forced-follow-up.md`, including a re-run of the
  forbidden capture-before mutation, which fails the same case under the new shape too — the
  placement is untouched and still load-bearing.
- **Owner ruling on the collision (2026-08-30), and it corrected my framing.** I called the delta
  *"a working idiom stops working"*; the owner: *"there is no working idiom"* — `FEAT-01`'s shape
  was a quick implementation of a disposable flag, ruled and overruled within a day and never
  released, so a contradiction with it is the thing being removed, not a cost to weigh. The
  instruction: **implement the pivot** across code, tests, examples and docs. Recorded verbatim in
  the note.
- `-04` `5ad6e518` — guide + internals + the retired `T-ONESHOT` entry marked as history.
- `-05` `6d0aa9af` (CHANGELOG rewritten as a mode; `T-ONESHOT-SCOPE` retired) and `07c8e183`
  (roadmap complete, suite arithmetic, the collision on the record). `ce86010d` fixes a `types.lua`
  annotation the sprint made misleading.
- **Examples: nothing to change.** No example uses the flag (`turtle` closes with its own
  `after_submit`, which Decision 36 already records); checked before claiming it.
- Suite **1023 / 0 / 0 / 10** at every commit from `-03` on. Marker gate clean.

## Findings parked (not ours)

- `doc/mermaid/{input,editor,classes}.md` show `oneshot: boolean` on `InputModel`/`UserInputModel`.
  That field is **gone** from the model (the base's constructor argument), so the diagrams are stale
  — pre-existing drift, unrelated to the rename. Not fixed; reported.

- Rename blast radius verified: `src/lib/metalua/*` and the **profiler** (`controller/profiler.lua`,
  `controller.lua:842,1080-1082`, `input_global_shortcuts_spec.lua:338`) keep `oneshot`; so do the
  two **historical** comments at `userInputView.lua:290` and `userInputModel.lua:436-439`, which say
  "oneshot is gone" about the *base's* model argument.
