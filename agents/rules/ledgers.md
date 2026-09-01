# The three ledgers — where the project's state lives

_Owner-ruled 2026-08-27. Sibling to [`roadmap.md`](roadmap.md), which governs how **planned work** is
represented. This one governs where **state** is recorded, and the two are deliberately different
things._

## Why this exists

A roadmap answers *what is next*, and it changes constantly — steps split, get renumbered, get
absorbed, land, and are struck through. That churn is healthy at step altitude and useless at project
altitude. Anyone asking **"where are we?"** should not have to read a plan that was reorganised twice
this week and infer the answer.

**Three ledgers answer it instead**, and they are all in the persistent corpus — they survive the
deletion of any feature's working tree:

| Ledger | Answers |
|---|---|
| [`CHANGELOG.md`](../../CHANGELOG.md) | **what shipped, and what is about to** |
| [`doc/development/decisions/*`](../../doc/development/decisions/) | **what was ruled, and what still rules** |
| [`doc/development/technical_debt/*`](../../doc/development/technical_debt/) | **what is owed** |

Read those three and you know the project's position without opening a plan.

## 1. The changelog holds `CURRENT_SCOPE`

`CURRENT_SCOPE` is everything not yet released. **On a release it is emptied**, and its content moves
down into a section named for the version that just shipped. Released versions sit below it, newest
first.

Nothing in `CURRENT_SCOPE` is dated or numbered — the release that would date it has not happened.
Write entries at **user-facing altitude**: a project author reading only this file must be able to
answer *"what changed for me?"*. Internal vocabulary and refactor names belong in the decisions
ledger, not here.

## 2. The decisions ledger is split ACTIVE / RETIRED

- **ACTIVE** — decisions in force.
- **RETIRED** — decisions that no longer rule anything: superseded in full by a later one, or kept
  as a correction (an entry that turned out never to have been a decision).

**Retired does not mean deleted — while the ledger is numbered.** Entries keep their number and their
full text, because comments in `src/` and `tests/` cite them by number, and a citation that resolves
to nothing is worse than one that resolves to a tombstone. A retired heading names what stands in
its place.

**That is a condition, not a permanent rule, and the input ledger has discharged it** (2026-09-01):
`decisions/input.md` cites by `D-` slug, so a missed citation dangles visibly instead of resolving
to a different live decision, and its `RETIRED` section is empty by ordinary sweep rather than by
neglect. A numbered ledger still keeps its tombstones. **Convert first, then vacuum** — in that
order, because it is the naming that makes the deletion safe.

**Vacuuming retired entries is nevertheless allowed, and is an obvious operational need** (owner,
2026-08-27). Two conditions, and no formal process is required beyond them:

- **Only entries that were not the stakeholder's.** A ruling we made for ourselves may be swept once
  it rules nothing. A ruling that came from outside is a record of what was asked, and it stays.
- **Citations must still resolve.** Under numbering that means keeping the tombstone; under names a
  removed entry **dangles visibly and greps out**, which is safe. This is the same argument
  [`roadmap.md`](roadmap.md) §2 makes for renaming over renumbering.

**The absence of a written vacuum process does not block the sweep** — rule it in place and record
the ruling. A rule that exists to keep citations resolving must not be read as a rule that the ledger
may only ever grow.

**Disclose supersession in the heading**, not only in the body. An entry whose body says it was
superseded while its heading does not will be read as live by anyone scanning, and it will be
mis-sorted by anyone maintaining.

### What a decision records about its own past (owner, ratified 2026-09-01)

**What was not in a released version is considered never to have existed** — with one exception,
**anything stakeholders explicitly ratified**, which is a record of what was asked and stays.

A ruling reshaped before release therefore leaves **nothing to argue with**. Prose that
re-litigates an interim version of our own decision — *"the original decision said X"*, *"the
rationale was withdrawn because Y"*, a paragraph explaining why a name we used for a week is not
the name we shipped — is archaeology. It describes a system nobody ever ran, inside a ledger read
by people asking how today's system works.

**The test is whether a reader would plausibly propose the alternative again.** A decision saying
*"X, and not Y"* is doing its job when Y is a live option someone reaches for — that is the whole
purpose of recording rationale, and it is why an entry names what it was chosen over. It is doing
the opposite when Y is a draft of X that existed for a fortnight inside the branch. **Argue with
live alternatives; never with your own overwritten past.**

This is narrower than "do not argue with yourself", deliberately: an entry weighing a real
alternative, or amending another live entry, is doing exactly what the ledger is for. The defect
is specifically an **interim, overwritten** past.

Two things survive this cut and must not be swept with it:

- **Facts about the pre-feature baseline.** *"At the base, both channels stayed installed until
  stop"* is provenance — it tells a reviewer the release **restored** behaviour rather than
  changing it, which is a different claim from anything about our own drafts. Keep the fact; drop
  the argument with the withdrawn rationale the fact settled.
- **Whatever a stakeholder ratified explicitly**, per the exception above.

§2's vacuum removes whole retired entries; this removes dead prose from entries that are still in
force. Both are ordinary upkeep, and neither needs a ceremony beyond doing it.

## 3. The debt register is split ACTIVE / BACKLOG / RETIRED

The line between the first two is **release scope** — not severity, and not intent:

- **ACTIVE** — must be resolved before the current release ships.
- **BACKLOG** — real, acknowledged, and deliberately deferred past it.
- **RETIRED** — paid, or turned out not to be debt.

**`ACTIVE` entries carry a `T-` slug; the other two sections do not need one.** Same shape as the
decisions ledger's `D-SLUG` — uppercase mnemonic, `T-` prefix, 16 characters at most, declared first
in the heading with the prose after. **An entry earns its slug when it becomes `ACTIVE`** and keeps
it thereafter.

The asymmetry is deliberate rather than lazy: a decision is cited from `src/` and `tests/`, which is
what makes its numbering dangerous, while a debt entry is cited from **plans**. So the entries that
need a stable handle are exactly the ones a roadmap row points at, and slugging a hundred `BACKLOG`
entries that nobody references is ceremony.

Two consequences worth stating, because both have been got wrong:

- **Partly-paid debt is not retired.** An entry marked resolved-in-part whose own "Revisit" line
  names outstanding work belongs in ACTIVE or BACKLOG. The heading records history; the section
  records status.
- **A settled question is retired, not backlogged.** A proposal that was declined, or a naming
  complaint ruled closed, owes nothing. Filing it under BACKLOG claims it is deferred, which is a
  different and false statement.

## 4. What becomes a debt entry

**Every obligation the project has taken on, whatever its shape:**

- **An unimplemented decision.** A ruling that says the system does X where the code does not yet do
  X is an obligation. The **decision stays in the decisions ledger** — it holds the rationale — and
  the debt entry is the pointer to what is unfulfilled. Never move a decision into the debt register.
- **A defect.** A known misbehaviour is owed work, and the register is where what-is-owed lives.
- **A planned task that outlives its sprint.** Work that was scheduled, then not done and not
  cancelled, is owed. **This holds for work on the ledgers themselves** (owner, 2026-08-27):
  documentation and readability debt is still debt, and a register that exempts its own upkeep is
  keeping two sets of books.

This is what keeps the three ledgers honest against each other: a decision with no matching debt
entry is claiming to be implemented, and a defect with no entry is claiming not to exist.

### An entry normally names a decision

**A debt entry should reference the decision it derives from** (owner, 2026-08-27) — that is what
makes the register readable as obligations rather than as a list of complaints, and it is what lets a
reader follow *what is owed* back to *why it was ruled that way*.

**Two kinds of entry are exempt**, and they are exempt because a citation would add nothing:

- **A self-describing discovered defect.** Something is broken; the entry says what and where. No
  decision produced it and none needs naming.
- **An obvious operational need** — reconciling with upstream before a PR, verifying a claim before
  shipping it, keeping a ledger legible. The need argues for itself.

An entry that is neither, and cites nothing, is usually a sign that the decision behind it was never
written down.

## 5. How the roadmap relates to the debt register

**Roadmap rows point at debt entries, many-to-one.**

> A **debt entry is a goal**. A **roadmap row is a task** that helps fulfil it — and a goal may take
> several tasks.

So the two are never in one-to-one correspondence and should not be forced into it. The roadmap is
free to split, merge and renumber its rows (`roadmap.md` rules 2 and 3) without the register moving
at all, which is the entire point: **the register is stable at exactly the rate the project's
position changes, and the roadmap is stable at the rate the plan changes.**

**A row cites the entry's slug**, which is why `ACTIVE` entries have one — a pointer to a
heading is a pointer to something mutable.

An `ACTIVE` debt entry with no roadmap row pointing at it is a **visible gap** — something is
release-blocking and nothing is scheduled to do it. That cross-check is worth running before any
release, and it earned its place the first time it was run: it found an entry that was not
release-blocking at all, filed `ACTIVE` by a too-broad instruction, and the missing row was the
symptom rather than the cause.

## 6. One timeline, still

`roadmap.md` rule 1 — one roadmap, never a second ledger — applies here too and is easy to violate by
accident. **The three ledgers hold state, not plans.** The moment a register section grows its own
ordering, its own status column, or its own sense of being unfinished, it has become a second
roadmap, and the failure that rule describes has arrived by another door.

**Where** vacuumed entries go — dropped outright, or moved to an archive — remains unruled; §2 rules
only that the sweep may happen and on what condition.
