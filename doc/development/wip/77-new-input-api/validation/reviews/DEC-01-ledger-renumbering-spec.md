# DEC-01 — de-noising the decisions ledger: remove tombstones, renumber the rest

**Owner request, 2026-08-26.** Specification only; nothing executed. **Runs before the next slice
cut**, so the ledger a reviewer reads is the clean one.

**Verdict: doable, and the owner's algorithm is the right one.** Its sentinel-wrapping step solves
the problem that makes naive renumbering unsafe — renaming `26 → 13` while a real `13` still exists.
Wrapping puts old and new ids in disjoint namespaces so no rename can collide with a not-yet-renamed
id. What follows adds the survey, the gate that makes it safe, and three hazards the algorithm does
not by itself address.

## The survey

| | count |
|---|---|
| decision headings in the ledger | **33** |
| highest number in use | **34** (so the sequence already has a gap) |
| tombstoned headings (`SUPERSEDED`) | **4** — Decisions **13, 16, 20, 29** |
| `Decision N` mentions inside the ledger | 117 |
| `Decision N` citations in `src/` + `tests/` | **165**, across 18 files |
| `Decision N` citations in the persistent docs | ~10 files |
| `Decision N` citations in `wip/` | 1328 — **out of scope, see below** |

**Result of the operation:** 33 entries minus 4 tombstones = **29**, renumbered to a gapless
**1–29**.

## The hazard that governs the whole job

**A missed citation does not dangle — it silently points at a different, existing decision.** This
is the opposite of the usual rename failure and it is worse: a dangling reference is visibly broken,
whereas a citation that now names Decision 13 when it meant the old Decision 16 reads as
authoritative and is wrong. It is the session45 lesson (*a dangling citation is worse than none*)
with the stakes raised.

**Therefore the gate is at step 1, not at the end.** Once every occurrence is wrapped in a sentinel,
the rest is mechanical and safe. So:

> **After wrapping, `grep -rnE '(^|[^-])\bDecisions?\b' <scope>` must return only sentinel-wrapped
> hits. A single bare occurrence stops the job.**

Verifying completeness *before* renaming is what makes the remaining steps unable to go wrong.

## Three hazards the algorithm does not address by itself

### 1. Line-broken mentions — the owner anticipated this, and it is real

**3 confirmed in the ledger**, where the wrap put the number on the next line:

```
… the chain reports not-consumed (Decision
30) …
```

`decisions/input.md` lines **117**, **230**, **1444**. Exact matching cannot see these, and they are
the ones most likely to survive the whole operation silently.

**Handle first, as its own committed step:** join them so no `Decision` ends a line, verify with
`grep -cE 'Decision$'` returning **0** across scope, and commit *that* before wrapping starts. A
reflow that happens during a rename is a diff nobody can read.

### 2. Case and plural variants

- **Plural:** `SUPERSEDED by Decisions 25 and 27` — one mention, two ids.
- **Lower-case prose:** `decision 5` ×4 and `decision 2` ×3, which an exact `Decision N` match
  misses entirely.

Normalise both before wrapping, or wrap patterns that cover them.

### 3. `wip/` is a different namespace and must NOT be renumbered

Two reasons, and they compound:

- **`wip/` is frozen history.** Renumbering the reasoning trail would make it describe a debate that
  never happened under those numbers.
- **`wip/` also carries `D-1`…`D-10`**, a *separate* design-time id scheme living only in
  `design/spec.md` and its neighbours — **1328 hits, none of them in the persistent corpus or in
  code.** It dies with the tree. Do not conflate the two namespaces; do not sweep either.

**Consequence:** during the transition, `wip/` cites old numbers. That is acceptable and expected —
it is why step 3's inventory matters.

## The inventory is a deliverable, not a worksheet

The owner's step 3 produces the crosswalk, and it must **outlive the operation**: commit messages,
`wip/`, and any stakeholder note written before today all cite old numbers.

**It belongs in the ledger itself, as an appendix** — the persistent corpus is the only place that
survives `wip/77` deletion, and a reader hitting an old number needs the mapping where the decisions
are, not in a scratch tree. One table: old id → new id, or old id → *removed, superseded by <new
id>*.

## The steps

| id | step | gate |
|---|---|---|
| **DEC-01-01** | Join the 3 line-broken mentions; normalise plural and lower-case variants | `grep -cE 'Decision$'` = **0**; no bare `decision N` | 
| **DEC-01-02** | Wrap every live id `Decision N` → `DEC-Decision N-DEC`, every tombstoned id → `TOMB-Decision N-T` | **the governing gate above**: no unwrapped `Decisions?` anywhere in scope |
| **DEC-01-03** | Build the inventory: 33 ids, disposition (keep / remove), new number | reviewed before any deletion |
| **DEC-01-04** | Remove the 4 tombstoned entries | `grep -c 'TOMB-'` = **0** — no surviving mention, including in `src/`, `tests/` and the persistent docs |
| **DEC-01-05** | Rename one at a time, `DEC-Decision <old>-DEC` → `NEW-Decision <new>-NEW` | after each: the old id appears nowhere unwrapped |
| **DEC-01-06** | Strip `NEW-` / `-NEW`; read the diff | 29 headings, gapless 1–29; suite green; **inventory appended to the ledger** |

**Scope for every step:** `doc/development/decisions/input.md`, the persistent docs that cite it
(~10 files), and **`src/` + `tests/` (165 citations)** — code comments cite these ids and are the
easiest scope to forget.

## What DEC-01-04 must check before deleting

The 4 tombstones are **13, 16, 20, 29**, and three of them are superseded *by Decision 30* — which
is itself being renumbered. Before removal, confirm each entry's content is genuinely carried by its
successor and not merely pointed at. **Decision 20's body, for instance, is the last full
description of `compy.input.keys_pressed`**, a member that no longer exists; deleting it removes the
record of why it went. If that history is worth keeping, it belongs in the successor's *Why*, not in
a tombstone — decide per entry, in the inventory, not during the sweep.

## One contested point, stated and not blocking

**Renumbering is optional; removing tombstones is not.** Deleting the 4 and leaving gaps at 13, 16,
20 and 29 costs nothing and carries no risk, because a gap is self-evidently a gap. Renumbering buys
a gapless sequence at the price of touching 165 code citations, where a miss is silent and points at
the wrong decision.

**The owner has asked for the renumbering and the algorithm is sound**, so this specifies it in
full. The judgement is recorded only so the trade is visible: **if the job has to be cut short, cut
the renumbering and keep the removal** — the de-noising the owner wants comes mostly from the four
deletions, and the renumbering is polish on top.
