# FIX-03 — the closed-arc sweep: retiring narration of history that ended inside this branch

**Owner proposal, 2026-08-26.** Specification only; nothing executed.

**Recommended: yes, commission it — and the argument is not tidiness, it is that we have already
found three by accident.**

## Why a sweep rather than more rows

This session found the same defect three times, by three unrelated routes:

| found | how |
|---|---|
| decision tombstones (13, 16, 20, 29) | a planned de-noising step |
| `release_keyboard_route`'s comment and citation | the owner asking a design question |
| the debt ledger's 547 resolved lines | the owner asking a second question by analogy |

**None was found by looking for it.** Three independent discoveries of one shape is the signature
of a class defect, and the owner has now found two of them by reading — which says more about what
is left than another discrete row would.

## What the sweep targets, stated mechanically

**A closed arc: something this branch introduced and then removed, so it is net-absent from the
base *and* from the shipped tree — yet the corpus still narrates it.**

The test is the one Phase L used and DEC-01 and FIX-02-15 reuse, and it is cheap:

```
subject absent at PR base 3256aac   AND   absent in the tree today
    → the arc opened and closed inside this branch
    → any prose still arguing about it is narrating a debate that never reached anyone
```

That is a **grep, twice**, per subject — not a judgement call. Judgement is needed only for the
exclusions below.

## Two exclusions — and the second was discovered the hard way

**1. Lessons already materialized elsewhere (owner's exclusion).** Where a closed arc taught
something, the lesson normally lives in a decision, a convention, or an ordinary doc. **Verify the
lesson is actually there before deleting the instance** — an unmaterialized lesson deleted with its
narration is gone. Today's example: the keyboard/pointer asymmetry taught that *"a shape that has
been in the code for twenty minutes reads exactly like one that has been there for a year"*, and
that lesson **is** materialized, in `conventions/docs.md`'s *"de-facto behaviour has a boundary"*.
So the instance can go. That check is the work; the deletion is trivial.

**2. Prose that is the only record of a deviation from PRE-FEATURE behaviour.** Not the owner's
stated exclusion, and it nearly cost something today. In `decisions/input.md`, Decision 11's
*"Why the original rationale was withdrawn"* (rot) sits **immediately above** *"Changed baseline
behaviour"*, which records that a running project without its own keyboard handler used to leave
the console callback installed — so unhandled input accumulated in the hidden console and Enter
could evaluate it. **That is a real pre-feature deviation and must survive.** A sweep that matches
on "reads like history" takes both.

**So the sweep must operate on subjects, not on tone.** Rot is identified by its *subject* failing
the two greps, never by its prose sounding retrospective.

## Scope

The persistent corpus — the docs that survive `wip/77` deletion:

`doc/input_api.md` · `doc/development/internals/user_input.md` · `doc/development/decisions/input.md` ·
`doc/development/technical_debt/{input,general}.md` · `doc/development/tests.md` ·
`doc/development/smoke_checklists.md` — **plus `src/` and `tests/` comments**, which is where
`release_keyboard_route` hid and which no doc sweep would have reached.

**`wip/` is out of scope**, as always: frozen history, deleted whole.

## Shape: inventory first, disposal second

Following DEC-01 and this session's standing discipline — **triage before edit**.

| id | step |
|---|---|
| **FIX-03-01** | enumerate candidate subjects: names appearing in the corpus that fail the two greps |
| **FIX-03-02** | for each, classify — closed arc / lesson-bearing / pre-feature-deviation record |
| **FIX-03-03** | for lesson-bearing ones, **locate the materialized lesson** and cite it, or promote the lesson before deleting |
| **FIX-03-04** | dispose: closed arcs vacuumed, per the owner's ruling on FIX-02-15 |

**Overlaps to honour, not duplicate.** DEC-01 already removes four decision tombstones; FIX-02-15
already vacuums the rot debt entries; FIX-02-01's `:429`/`:749` rows already carry the
*"self-arguing with past decisions"* principle for `decisions/input.md`. **FIX-03 is the sweep that
catches what those three miss** — it should run **after** them and treat their output as already
done, or three brooms will pass over the same floor and disagree at the edges.

## One expected objection, answered

*Does this erase how the design was reached?* No — `git` has it, and `wip/77` has it until the
owner deletes it. What goes is **the retelling of it in documents a stakeholder reads to learn what
the system does now**. That distinction is the owner's own rule, already ratified for the decisions
ledger: *what was not in the released version is considered as never existing.* FIX-03 applies it
everywhere else.
