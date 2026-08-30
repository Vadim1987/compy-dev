# session57 — track

## Boot — 2026-08-30

- Fresh start: no `track.md`, no `report.md` on disk before this entry (re-entrance guardrail:
  clean boot, nothing to resume).
- HEAD `02cc51f9` — *docs(session56): wrap — report, session57 prompt, repointed pointer,
  refreshed baseline*. Branch `feature/77-newapi-analysis-s20260615`.
- Working tree: no tracked modifications. Untracked only — `broken-busted/`, `claude.sh`,
  `input-pr-slices.tar.gz`, `repos.txt`, `src/STEPS.md`, `src/examples/{balloons,keyboard,maze}/`,
  `worklog.md`. The nested example repos and `src/STEPS.md`/`claude.sh`/`input-pr-slices.tar.gz`
  are named anomalies in `agents/validation.md` §Hard guardrails; `broken-busted/`, `repos.txt`
  and `worklog.md` are **not** on that list — owner scratch, left alone, noted here only so a
  successor does not mistake them for ours.
- Suite: **1011 / 0 / 0 / 10** — matches the prompt's baseline. Go-signal.
- Boot reading done: `agents/sessions.md`, `agents/validation.md`, `session57/prompt.md`,
  `session56/report.md`, `ROADMAP.md` (sequence + `FEAT-01` + `OP-01`), Decisions 36 and 37,
  `T-ONESHOT` and `T-PLAINTEXT-ENTERED`.
- Owner asked, before any execution, for a statement of workflow / project status / the task.
  Delivered in-chat; owner said **go**.

## Scoped revalidation — done

`validation/reviews/FEAT-01-ledger-executability.md`. Two findings, both real:

- **D37 is executable**, and the census is right as corrected — but the consequence paragraph's
  "everyone simplifies" hides an asymmetry: `string.unlines` is **idempotent over a string**
  (`string.join`, `string.lua:284-286`), so the four joiners keep working untouched, while the
  three `lines[1]` sites (`turtle`, `valid`, `guess`) break **silently** (`("s")[1]` → nil, no
  raise). Mandatory-with-`-04`, not cleanup. Both separate-repo consumers are in the safe group.
- **D36 has one hole**: *"closes even if a callback raised"* cannot be built as written — the
  error boundary is at **route entry** (`controller.lua:161/238`), not around the submit chain,
  so a raise in `on_text_entered` already skips `after_submit`. Needs a pcall-then-rehide-then-
  reraise inside `submit_flow`, or a hide-before-callbacks that changes what a callback observes.
  That is a **ruling**, → `FEAT-01-01`. Plus: `oneshot` is the first show-only key that **outlives
  its call** (a remembered per-widget store), a category Decision 35's boundary does not have.
- Everything else in D36 is derivable, and derivable *precisely*, because the decision anchors on
  the boilerplate it replaces (`after_submit = hide`) — that anchor settles what "closes" means,
  when it fires, and that veto/empty/reject suppress it.

## FEAT-01 — complete, all seven rows

- **`-01` RULED** (`b7f0f2a2`). Sheet: `validation/reviews/FEAT-01-01-oneshot-ruling-sheet.md`,
  five questions, dispositions at its foot. Q1 as recommended, no category note (offered,
  declined). Q2 → (a) submit-only **and document the asymmetry** — no debt entry, a documented
  behaviour is not an obligation. Q3 ratified after being put as a formality with a stated
  recommendation; **recorded plainly, because silence is not a ruling** and that one came close.
  Q4 → **(3), reversing Decision 36's own recommendation.**
- **`-02`** (`114cbdb5`), 8 breaking tests first, all seen failing on *unknown config key*. Three
  production lines. `types.lua`'s annotation was missed and landed separately (`1963ce79`).
- **`-03`** (`cc81c6c4`) — the ruling was already the owner's; this row confirmed executability,
  closed **`FIX-02-01`** jointly as required, and corrected D37's consequence paragraph.
- **`-04`** (`d0d7bc37` code + specs + the three mandatory examples, `999d9841` guide + CHANGELOG).
  Nine existing spec cases were payload assertions and moved; none added or deleted.
- **`-05`/`-06`** (`59132142`) written together, per the row. The owner's "not enforced" is
  load-bearing and is in the guide verbatim in substance.
- **`-07`** (`17ed2c09`, plus `d2be028` in maze and `6d6c6e3` in balloons) — all four joiners
  rewired, **none `wontfix`**, reason recorded per example. Two of them carried comments asserting
  the API hands you LINES; the split made those false, so they needed a commit regardless.
- Ledgers closed (`7a16e03f`): both decisions implemented, both debt entries retired, seven rows
  ✅, sequence advanced. Suite **1020 / 0 / 0 / 10** at every commit.

## Findings for the owner — not acted on, not mine to rule

- **`ROADMAP.md`'s status table mis-cites a row.** *"marker gate (src/tests) — clean, but it never
  covered `doc/`, which is FIX-02-01"*. `FIX-02-01` is the two-submit-callbacks question, now
  closed. The `doc/`-markers concern has **no row anywhere** (grep: one hit, that line). Nearest
  home is `FIX-02-07` (execute the 37 remark dispositions) or a row of its own. There is at least
  one live `REMARK:` in `internals/user_input.md` — left untouched.
- **Two in-repo comments cite a debt slug that no longer resolves**: `userInputController.lua:71`
  and `input_widget_callbacks_spec.lua:125` name `T-HL-TWO-HOMES`, whose heading dropped the slug
  when it retired (register convention: the body says *"Was `T-HL-TWO-HOMES`"*). Grep still finds
  it, so it is soft rot rather than a dangler — `FIX-03`'s business, flagged not swept.
