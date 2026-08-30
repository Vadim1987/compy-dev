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

- Rename blast radius verified: `src/lib/metalua/*` and the **profiler** (`controller/profiler.lua`,
  `controller.lua:842,1080-1082`, `input_global_shortcuts_spec.lua:338`) keep `oneshot`; so do the
  two **historical** comments at `userInputView.lua:290` and `userInputModel.lua:436-439`, which say
  "oneshot is gone" about the *base's* model argument.
