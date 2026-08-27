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

**Retired never means deleted.** Entries keep their number and their full text, because comments in
`src/` and `tests/` cite them by number and a citation that resolves to nothing is worse than one
that resolves to a tombstone. A retired heading names what stands in its place.

**Disclose supersession in the heading**, not only in the body. An entry whose body says it was
superseded while its heading does not will be read as live by anyone scanning, and it will be
mis-sorted by anyone maintaining.

## 3. The debt register is split ACTIVE / BACKLOG / RETIRED

The line between the first two is **release scope** — not severity, and not intent:

- **ACTIVE** — must be resolved before the current release ships.
- **BACKLOG** — real, acknowledged, and deliberately deferred past it.
- **RETIRED** — paid, or turned out not to be debt.

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

This is what keeps the three ledgers honest against each other: a decision with no matching debt
entry is claiming to be implemented, and a defect with no entry is claiming not to exist.

## 5. How the roadmap relates to the debt register

**Roadmap rows point at debt entries, many-to-one.**

> A **debt entry is a goal**. A **roadmap row is a task** that helps fulfil it — and a goal may take
> several tasks.

So the two are never in one-to-one correspondence and should not be forced into it. The roadmap is
free to split, merge and renumber its rows (`roadmap.md` rules 2 and 3) without the register moving
at all, which is the entire point: **the register is stable at exactly the rate the project's
position changes, and the roadmap is stable at the rate the plan changes.**

An `ACTIVE` debt entry with no roadmap row pointing at it is a **visible gap** — something is
release-blocking and nothing is scheduled to do it. That cross-check is worth running before any
release.

## 6. One timeline, still

`roadmap.md` rule 1 — one roadmap, never a second ledger — applies here too and is easy to violate by
accident. **The three ledgers hold state, not plans.** The moment a register section grows its own
ordering, its own status column, or its own sense of being unfinished, it has become a second
roadmap, and the failure that rule describes has arrived by another door.

Vacuuming the retired sections — when, and to where — is deliberately unruled as of 2026-08-27.
