# session27 — receive the smoke-test verdict, then revalidate or plan the rebase

Read and strictly respect `agents/sessions.md` and `agents/validation.md`.
Boot normally: read this prompt, the complete `../session26/report.md`, the
session26 commissioning prompt and its track, then create `session27/track.md`.
Do not edit any historical session artifact.

Baseline: `busted tests` → **923 / 0 / 0 / 3**. A different count is a finding,
not a go-signal.

## Where things stand

Session26 was commissioned to wait for the owner. It became the session that
removed the feature's largest piece of self-inflicted complexity: the
keyboard/pointer split turned out to be **this feature's own invention**, not
inherited platform behaviour as Decision 11 claimed, and everything built to
work around it went with it. Six defects were found and fixed along the way,
four of them ours, including one where raises inside `love.update` and pointer
handlers vanished silently.

The tree is **PR-ready**. Slices, commit messages, PR description and a
smoke-test plan are all on disk and current as of `264e0c6c`.

Full account: `../session26/report.md`. Read it before anything else — this
prompt summarises it one level up and does not repeat its evidence.

## Your task

**Wait for the owner's smoke-test verdict.** They are running
`validation/reviews/S26-smoke-test-plan.md` and reviewing the PR in the same
pass, by their choice. Their feedback is your opening input; do not start
anything off your own reading of the tree.

When it arrives, it goes one of two ways.

### If the feedback reports failures

Treat each as a finding, not a task list. For each: reproduce it, find whether
it is a defect this session introduced or one it exposed, and say which before
proposing a fix. The plan's items each state *why* they are on the list —
that reasoning is what tells you whether a surprise is interesting.

Standing discipline applies: breaking test first, production fix in its own
commit with its evidence, suite green and stated at every commit.

### If the feedback is positive

The owner has named the next step: **plan rebasing onto — or merging from —
upstream**, which has moved forward since `updev`. Nothing has been
investigated; you start from zero. Establish at least:

- what upstream is now, and how far it has diverged from `BASE=3256aac`;
- whether the divergence touches files this feature changed (the slice
  pathspecs in `pr-assembly-guide.md` §1 are the ready-made list);
- rebase versus merge, with the argument for each, **and what it does to the
  slices** — they are `git diff BASE..TIP` narrowed by pathspec, so moving BASE
  invalidates every one of them and Phase G runs again;
- whether the PR should target the moved upstream or land against `updev` first.

Present the options with a recommendation. **The choice is the owner's.**

## Then, and only after the owner is satisfied

Session26 was cognitive-heavy: judgment was exercised throughout and the
outputs — Decision 25, the amended Decision 11, the PR description, the
regenerated slices — are artifacts downstream work will trust without
re-reading the source. That is the trigger in `agents/rules/revalidation.md`.
A revalidation pass over session26 is therefore owed, and specifically over:

- **Decision 25 and the Decision 11 amendment.** Both are ratified-ledger
  changes made in-flight. Check the evidence cited actually says what the entry
  claims it says.
- **The PR description** against `doc/input_api.md` — the frame requires a
  reviewer with only those two to be able to judge the PR. Test that claim by
  reading them together and nothing else.
- **The slice verification.** It was checked by applying to a temporary index
  and comparing trees; re-run it rather than trusting the recorded result.

Do not run this before the owner's feedback — a revalidation of work the owner
is about to change wastes both passes.

## Standing constraints

- Suite green and stated at every commit; one concern per commit; a production
  fix is always its own commit with its breaking test.
- **Stage explicit paths, never a directory.** This tree permanently carries
  the owner's untracked scratch and three nested example repos.
- Commit locally at your discretion. **NEVER push** — not this repo, not the
  three nested ones (3 / 2 / 8 commits ahead of their remotes).
- `design/` is frozen — read, never edit.
- **A row asserting an absence needs a mutation check and a control.** Three
  rows this session were green and blind or nearly so; each was caught by
  asking what the assertion could distinguish, not by re-reading it.
- **When a document claims behaviour is pre-existing, check it against the PR
  base before building on it.** `git show 3256aac:<file>`. That defence
  overturned a ratified rationale twice this session, and the failure mode it
  guards against is recorded in
  `validation/notes/S26-owner-on-the-failure-mode.md`.
