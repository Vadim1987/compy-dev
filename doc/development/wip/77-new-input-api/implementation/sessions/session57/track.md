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
