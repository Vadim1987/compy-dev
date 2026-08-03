# session26 — wait for the human, then move in coordination

Read and strictly respect `agents/sessions.md` and `agents/validation.md`.
Boot normally: read this prompt, the complete `../session25/report.md`, the
session25 commissioning prompt and its track, then create `session26/track.md`.
Do not edit any historical session artifact.

Baseline: `busted tests` → **904 / 0 / 0 / 3**. A different count is a finding,
not a go-signal.

## Where things stand

Session25 was commissioned as a revalidation of session24 and settled both
contradictions it left. It then ran a long owner-led design arc: five public
members were added to `compy.input` (Decisions 20–24), four debt entries
closed, and `examples/keyboard` was migrated onto the API after the owner
overturned the "nothing to migrate" verdict — it is now the feature's
acceptance case, and the only sibling repo whose review changed the platform.

Full account, including two of my own green-but-blind tests and one staging
error: `../session25/report.md`.

## Your task

**Wait for the human.** This prompt specifies no work of your own, by the
owner's instruction at the session25 wrap: *"tell your successor to move on in
coordination with me"*.

The feature is close to PR assembly but **not** ready for it, and the
remaining items are mostly the owner's to release rather than yours to start.
When they arrive:

1. Record what they say in `track.md` — verbatim where it is a ruling.
2. Say which of the items below it lands in, **before** changing files.
3. Act only on their instruction. Do not start Phase G, the wrapper rename, or
   a fix sweep off your own reading.

If they arrive with something else entirely, ask for instructions and act on
those.

## The open items, roughly in the order they gate the PR

- **The owner's smoke test.** Nothing this session that touches the screen or
  a game can be verified headlessly: C3 (the overlay paint fix), keyboard's
  whole migration, turtle's echo guard, maze's idle gating, balloons' submit
  fix. This is the one item nobody else can do.
- **RULED, and yours to execute: a bare `*` shortcut must raise** (owner,
  2026-08-03). Today `shortcuts.keypressed['*']` registers without raising
  and catches every *unmodified* key — `q` yes, `ctrl+s` no, since that
  belongs to the `ctrl+*` class. This is the one ruled-but-unimplemented item
  in the tree, and it is deliberately recorded in
  `technical_debt/input.md` rather than in the decisions ledger, because a
  ratified entry describing behaviour the code lacks is the exact error this
  phase spent a session undoing. Work it test-first: `check_combo`
  (`src/util/key.lua`) gains a case for "trigger is `*` with no modifiers",
  then Decision 21 gains the sentence, then the guide, then the row moves the
  entry to RESOLVED.
- **Already settled, do not re-open.** The scancode question is recorded in
  `technical_debt/input.md` as the open decision *"Combo triggers are
  key-name-only"* — not now, never as a swap, additive if ever. And the
  sibling repos are **not** to be squashed: every repo is sliced for its PR
  the same way the platform is (owner, 2026-08-03), so their commit churn
  never reaches the PR. `pr-assembly-guide.md` §1 and §5 carry both.
- **The deferred wrapper rename** — `forward_*`, `userlove`, the `*_native`
  trio — ruled to happen *just before* the PR, because it moves code.
- **Phase G, slice regeneration.** Still last, and now with a third reason:
  session25 added five public members after the current batch was cut, so
  those slices are further out of date than the guide's "STALE" note implies.
- **The PR description.** Intent → design → ratified deviations →
  justification table → open questions. The table now owes a line per new
  public member, and the strategic frame (`agents/validation.md`) says each
  needs a one-line justification against the stakeholders' "simpler and more
  robust" ask.
- **Three questions the session24 sitting referred to stakeholders** rather
  than settling, still carried in `technical_debt/input.md`.
- **Deleting `wip/77`** — owner-gated, and the phase's formal close-out.

## Standing constraints

- Suite green and stated at every commit; one concern per commit; a production
  fix is always its own commit with its breaking test.
- **Stage explicit paths, never a directory.** This tree permanently carries
  the owner's untracked scratch (`src/STEPS.md`, `claude.sh`, …) and three
  nested example repos; session25 swept them into a commit with `git add -A
  src` and had to squash it out.
- `design/` is frozen — read, never edit. It ratified the combo *format* and
  named the matcher an extension seam; check it before assuming a constraint
  is inherited rather than chosen.
- Commit locally at your discretion. **NEVER push** — not this repo, not the
  three nested ones, each of which carries unpushed local commits of its own.
- A test row asserting an *absence* needs a mutation check and a control.
  Two of session25's rows were green and blind.
