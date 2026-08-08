# session29 — report

**Commissioned:** revalidate session28, then continue the standing commission
(P9b → P10 → P11 → close-out). Part 1 ran in full, under an owner directive that
changed how: **every step through a cold sub-agent, its review on disk, a pause
and a briefing before the next.** Part 2 did not start as planned — the P9b
design failed its own revalidation and was rewritten instead, and the session
turned into a design thread with the owner.

Suite **955 / 0 / 0 / 3**, green and stated at every commit. 13 commits, one of
them a production fix. Nothing pushed.

## Part 1 — four cold reviews, four verdicts

All four deliverables are in `validation/reviews/`, prompts of record in
`validation/prompts/`.

1. **The suite merge** (`S29-merge-revalidation.md`) — clean but for one latent
   finding: four `Log.warn` monkeypatch rows from two source files now share one
   busted-insulated scope. All restore before their own assertions, so nothing
   can fail today. **Mechanism verified empirically**, not inferred — a throwaway
   two-file busted run showed a patched module global leaks within a file and is
   healed across files. No fix: `finally` is used nowhere else in this suite.
2. **The two production fixes** (`S29-production-fixes-revalidation.md`) — both
   hold. `8fbcba21`'s row is a **proof, not a pin** (mutation re-run). Underneath
   them the review found the last channel in the system not passing LÖVE's
   arguments verbatim, and it became this session's production fix.
3. **The smoke dispositions** (`S29-smoke-dispositions-revalidation.md`) — the
   three no-change rulings all hold on every premise. Two corrections, appended
   to the S28 note under `[S29]`: SM4's coverage-gap claim overstates by one row
   (the mutation fails **three**, one of them pre-existing — reproduced myself),
   and SM5's "same in both orders" names two orders when there is a third.
4. **The P9b design** (`S29-p9b-design-revalidation.md`) — **failed**. See below.

## The production fix

`5a83fe8c` — `handlers.keyreleased` declared `function(k)`, so LÖVE's scancode
died at the gateway. Enumerated all ten gateway wrappers first: every other
channel forwards LÖVE's list in full. **`keyreleased` was the only exception
left**, against Decision 26's own rule and `doc/input_api.md`'s bold statement of
it. Base-checked: Decision 26 widened `keypressed` and missed its pair, so the
gap was the branch's. Breaking row first.

## The P9b design was discarded and rewritten

The revalidation found it internally contradictory (`seenText` never-cleared in
one section, cleared in another; rule 4 comparing against a value no declared
field holds; rule 5 inert because the target advance is synchronous). A four-way
comparison against the game's own history then found the deeper problem: measured
against the **shipped** interim fix it was a **regression** — it reintroduced a
live held-state read that the shipped code had already eliminated.

**The owner's account of how that happened is the most valuable thing in this
session:** the paradigm (`textinput` as the only judge) and the table-as-state-
model were their *only* original inputs; everything else answered corner-cases
the assistant raised, which they took for existing game constraints and which
were self-inflicted. The drift is visible on disk — `S28-owner-concerns.md`
recorded the blocking rationale as an argument for a table *shape* and lost the
paradigm it belonged to.

`doc/development/internals/examples/keyboard.md` is now rewritten on that
paradigm: one judge, two fields, writes blocked across the win transition, **no
clock, no grace window, no held read**. It fixes a case A, B and C all drop. Three
gaps found in my own rewrite and corrected (Caps reconciliation is the *shared*
handler's, the shared Alt/Ctrl guard exists, the non-printing modifier exemption).

## Non-obvious points

- **A four-way comparison beat a two-way one.** The question "is the design
  better than the original?" had a premise — that the original was
  simple-and-correct — and the premise was false: the original's printable
  judging never worked outside the event order it was written against.
- **Adoption is not evidence about a design** when the adopters were assistants
  under instruction (owner correction). It measures the migration.
- **The LSP could not answer "who calls this"** for a method name shared across
  tables — it resolved to constructors, or blended receivers. Grep with receiver
  types read manually is what settled it. The inverse of the standing hygiene
  rule, and the case that rule warns about.
- **The suite is order-dependent and always has been** — `--shuffle` fails 29–48
  rows at the PR base, before this branch existed. Filed as persistent debt.
- **Two clocks.** A device poll answers "held now"; the event-tracked set answers
  "held at this event". LÖVE pumps the whole queue then dispatches, so they
  differ whenever two events share a frame. This became Decision 29.

## What landed in the persistent corpus

Decision 29; the two-clocks explanation in `internals/user_input.md`; the
rewritten keyboard design; `input_api.md`'s "Held keys" section, which lost two
false statements (`lshift` meaning either shift; the table arriving as a second
argument, retired by Decision 26); four debt entries — suite order-dependence,
the wedging held set, the gateway polling the device, and the un-iterable view.

## Plan, as amended (§7, six amendments; §8 for P12)

**P9b** rewritten and ready to implement · **P9c** the two order-dependent rows
this branch owns · **P9d** clear the held set on focus loss · **P9e** the gateway
gates read the event set · then P10, P11, close-out · **P12 upstream
reconciliation blocks the real PR** — a platform upgrade that breaks a downstream
project cannot ship without a compatibility PR, and two of the three example
repos are not ours.

## Open, and the successor's business

**Five owner questions on the held-key set**, recorded verbatim in
`validation/notes/S29-held-state-design-agenda.md`. Q2 is answered there. The
other four — recovery from staleness, the trailing-argument question, a
serialised form, and how repeated press/release are tracked — are one agenda and
must be answered together. **Q1 undercuts Decision 29's own "the framework's
truth" claim**: a set maintained by paired events is only as reliable as the
pairing, and there is no recovery path today.

The owner called for a cold session for exactly this, judging the context long
and heterogeneous. That is session30's task.
