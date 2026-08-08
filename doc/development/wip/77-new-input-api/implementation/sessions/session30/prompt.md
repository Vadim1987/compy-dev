# session30 — the held-key set: a design session, then back to the plan

Read and strictly respect `agents/sessions.md` and `agents/validation.md`.
Boot normally: this prompt, then `../session29/report.md` in full, then the
session29 commissioning prompt and its track. Create `session30/track.md`.
Do not edit any historical session artifact.

Baseline: `busted tests` → **955 / 0 / 0 / 3**. A different count is a finding,
not a go-signal.

## Why this session exists

Session29 ratified **Decision 29** — the framework answers event-time questions
from the event-tracked `keys_pressed`; projects express chords through combos;
the direct reads stay as secondary channels for wherever combo logic does not
fit. Writing it surfaced four questions the owner judged too substantial to
answer inside a long, heterogeneous context. They called for a cold session.

**This is that session, and it is a design session with the owner, not an
execution one.** The agenda is on disk, with the owner's framing preserved:
`../../../validation/notes/S29-held-state-design-agenda.md`.

## Your task, part 1 — the held-state design, with the owner

Four questions, and **they are one agenda**. The note says why: Q1 asks how the
set recovers, Q5 asks what it records, Q4 asks what shape it is exposed in, Q3
asks how it reaches a consumer. Choose a recovery path before deciding whether
entries are booleans or counts and the next answer invalidates it. (Q2 is
answered in the note; do not re-open it.)

- **Q1 — recovery from staleness.** P9d closes the *known* wedge (focus loss). It
  is not a recovery path. **This one undercuts Decision 29's own claim**: the set
  is asserted to be the framework's truth for event-time questions, and that
  assertion is only as strong as its pairing guarantee, which nothing currently
  provides. Decision 29 may need amending, and that is the owner's call.
- **Q3 — the trailing argument.** Passing the held set after LÖVE's own arguments
  is *exactly* the "no argument is added" that **Decision 26 forbids**. So it is
  an amend-or-supersede question against a ratified decision, not only a design
  one. W1 removed this argument for stated reasons; re-adding it is either those
  reasons overturned or a different thing with the same name.
- **Q4 — a serialised form.** Correct the premise first: the table *is*
  indexable; it is *un-iterable*, because the read-only proxy carries `__pairs`
  and the shipping runtime ignores it. The interesting argument for a string is
  not the iteration gap — it is that a serialised held set is the same shape as a
  combo string, so the vocabulary would be one.
- **Q5 — repeated press/release.** Today it is a boolean per key: `true` on
  press, `nil` on release, no counting, `isrepeat` not consulted there.

**Rulings are the owner's.** Gather evidence, present, wait — and check every
factual claim in code before building on it. Two verdicts this phase were
overturned exactly that way, and session29 corrected three of its own claims
mid-thread.

## Your task, part 2 — resume the plan

Plan of record: `../../../validation/reviews/S27-triage-and-plan.md`, §4 table,
amended by **§6** (session28) and **§7** (session29, six amendments), with **§8**
carrying P12's rationale. In order:

- **P9b** — implement the keyboard judgement redesign. The design was **discarded
  and rewritten** in session29 and is in the persistent corpus:
  `doc/development/internals/examples/keyboard.md`. It should **subtract**
  `spendGlyph`, `GLYPH_CLAIMED`, `INPUT.upRecent`, `INPUT_UP_GRACE` and
  `altPlayKey`'s judging path. Nested repo, **no suite** — reasoned, not proven;
  the smoke checklist is in the design. The owner has not yet read the rewrite as
  text, and that omission is what produced the discarded version.
- **P9c** — the two order-dependent rows this branch owns. The suite-wide
  condition is pre-existing debt and explicitly **not** in scope.
- **P9d / P9e** — clear the held set on focus loss; the gateway's own gates read
  the event set rather than the device. Both code, both before P10, one concern
  per commit. **Part 1 may change both** — do not start them before it settles.
- **P10** — ledger and vocabulary. Decision 29 and the `input_api.md` "Held keys"
  rewrite landed early by owner instruction; **do not redo them**. R081's
  correction is wider than filed.
- **P11** — comment sweep (`grep -rn 'INTERIM:\|REMARK:' src/ tests/` must return
  nothing), slice regeneration, two cold revalidation rounds.
- **Close-out** — PR description refreshed, then the owner's ruling on deleting
  `wip/77`.
- **P12** — upstream reconciliation. **Blocks the real PR** and needs its own
  coordinated plan; deliberately last, after the snapshots stabilise. §8.

## How session29 was run, and it should continue

The owner's directive, and it earned its cost every time: **each revalidation
step through a cold sub-agent you brief, its review on disk under
`validation/reviews/`, then pause and report before the next step.** Sonnet,
explicit model, prompt of record on disk. Brief them at what the *previous*
check's shape could not see — that is what found the tag loss, the three-row
mutation, and the design's contradictions.

## Standing constraints

- Suite green and stated at every commit; one concern per commit; a production
  fix is its own commit with its breaking test.
- **Stage explicit paths, never a directory.**
- **Never `git checkout --` a file whose uncommitted work you want** — restore
  from a `/tmp` copy.
- **"Pre-existing" is a claim to check against the PR base** — `git show
  3256aac:<file>`. It has now overturned conclusions in five consecutive
  sessions, including this one.
- **The LSP cannot disambiguate a method name shared across tables** — it
  resolves to constructors or blends receivers. Grep with receiver types read
  manually; cross-check, trust neither alone.
- **`--shuffle` failures are pre-existing** (29–48 at the PR base) — not a
  regression, and not yours except for P9c's two rows.
- Commit locally at your discretion. **NEVER push** — not this repo, not the
  three nested ones.
- `design/` is frozen — read, never edit.

## Slices and the PR

Both **stale**, and further from the tree again. Slices last regenerated at
`264e0c6c`; Set 4 needs cutting as `4a-balloons` / `4b-maze` / `4c-keyboard`.
The PR description predates Decisions 26/27/28 **and 29**. Regeneration stays the
LAST step before the PR.
