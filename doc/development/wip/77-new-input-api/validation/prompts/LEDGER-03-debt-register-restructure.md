# Sub-agent prompt of record — LEDGER-03: restructure the debt register into ACTIVE / RETIRED / BACKLOG

**Spawned session49, 2026-08-27. Model: Sonnet (explicit).** Sequenced **after `LEDGER-01`**, whose
unimplemented-decisions list it consumes. Absorbs the roadmap's `FIX-02-05`. Owner directive: the
debt register becomes one of three ledgers giving project-altitude visibility.

---

You are restructuring the technical-debt register:

- `/repo/doc/development/technical_debt/input.md` (1674 lines, the bulk of the work)
- `/repo/doc/development/technical_debt/general.md` (100 lines, 5 entries)
- `/repo/doc/development/technical_debt/README.md` — describes the register; update it to describe
  the new structure.

## The structure

Each register file gets three sections, in this order:

- **`## ACTIVE`** — debt that **must be resolved before this release ships**.
- **`## BACKLOG`** — debt that is real and acknowledged but **deliberately deferred past this
  release**.
- **`## RETIRED`** — debt that is paid, or that turned out not to be debt.

**The owner ruled the ACTIVE/BACKLOG line is release scope**, not severity and not intent. So:

1. **`RETIRED`** — every entry whose heading already says `(RESOLVED, <date>)` or `— RESOLVED <date>`
   or similar. There are roughly fifteen. Keep the marker in the heading; do not reword it.
2. **`ACTIVE`** — an entry is ACTIVE **if the live roadmap has a task for it**.
   `/repo/doc/development/wip/77-new-input-api/ROADMAP.md` is this release's plan; read it
   **read-only** and match its rows against register entries. The mapping is **many-to-one**: one
   debt entry is a *goal*, and several roadmap rows may be the tasks that fulfil it.
3. **`BACKLOG`** — everything else that is not resolved. The existing section headed
   *"Anticipated — revisit at the named point"* is largely this, but **check each one** rather than
   moving the section wholesale.

Where you cannot tell, **put it in BACKLOG and list it in your report** as needing a human. A wrongly
backlogged entry is visible and cheap; a wrongly ACTIVE one quietly claims release-blocking status.

## Two things to add

**(a) The unimplemented decisions.** The owner's rule: *an unimplemented decision becomes a debt
entry.* `LEDGER-01` produced the verified list, at
`/repo/doc/development/wip/77-new-input-api/validation/outcomes/LEDGER-01-decisions-split.md`. Read
it. Write one **ACTIVE** entry per item, in the register's existing voice, each naming the decision
by number and stating what is unfulfilled.

**The decision itself stays in the decisions ledger — do not move or edit it.** The debt entry is a
pointer to an obligation; the decision keeps the rationale. Do not edit
`doc/development/decisions/input.md` at all.

**(b) The defects with no entry.** The owner's rule: *defects become debt entries too.* The roadmap's
`BUG-01` sprint has ten rows. Some already have a register entry (`close_project bypasses the run's
exit path`, for one); most may not. For each `BUG-01` row, find whether an entry already covers it.
**Report the mapping**, and add an **ACTIVE** entry for each one that has none — short, in the
register's voice, pointing at the roadmap row rather than restating its analysis.

## House rules — read these twice

- **Do not commit, do not push, do not stage anything.** Edit, write your report, stop.
- **Do not edit any file outside `doc/development/technical_debt/`.** `ROADMAP.md` and
  `decisions/input.md` are **read-only** for you.
- **Never delete or reword an existing entry.** Move it between sections, and only that. If an entry
  looks wrong, stale, or duplicated — say so in the report and leave it alone.
- **Preserve every entry's heading text verbatim**, including its `(RESOLVED, …)` marker.
- Count `^### ` (input.md) and `^## ` (general.md) entry headings **before and after**, and state
  both numbers. They must match.
- Match each file's existing line width (~95 columns) and heading depth. `input.md` uses `###` for
  entries under `##` groupings; `general.md` uses `##` for entries. Keep each file's own depth —
  your new sections sit one level above the entries in that file.

### The failure mode that has already bitten twice today

Two workers on this feature drew a conclusion from **one instance and generalised it to its
neighbours** — one checked a single callback field and reported behaviour for four, one sorted on a
heading without reading the body that contradicted it. Both were caught, but only by re-checking.

So: **read each entry's body, not just its heading.** An entry whose heading says nothing may say
"resolved" in its first line, and an entry that looks anticipated may be blocking. And when you state
that N entries behave some way, say how many of the N you actually opened.

## Deliverable

Write
`/repo/doc/development/wip/77-new-input-api/validation/outcomes/LEDGER-03-debt-restructure.md`:

1. The sort: which entries went ACTIVE, which BACKLOG, which RETIRED — by heading, with the roadmap
   row that made each ACTIVE one active.
2. **The `BUG-01` mapping table**: row → existing entry, or row → new entry you wrote.
3. The entries you added for the unimplemented decisions.
4. **Uncertain sorts**, listed for a human, with what you would need to settle each.
5. Anything you noticed that a human should look at — a duplicate, a stale entry, an entry whose
   body contradicts its heading, an entry that reads as resolved but is not marked. Report; do not
   fix.
6. Before/after entry counts for both files.
