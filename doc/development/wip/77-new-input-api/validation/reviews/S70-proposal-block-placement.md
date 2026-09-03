---
description: assessment of the proposal block the owner committed into doc/input_api.md — what each item is, and where it belongs relative to the PR
status: active
audience: developer
authored: llm
session: 70
date: 2026-09-03
---

# The proposal block — classification and placement

The owner committed a `## Proposed updates/changes` section into
`doc/input_api.md` (`1299ed2b`, 53 lines) and asked for it to be **planned as a
roadmap step** — *"ideally before the PR, but not blocking current stabilization
and cleanup work. maybe it should be after PR"* — with one consequence named
already: one proposal **promotes the status of an already-shipped feature**, so a
documentation fix is owed as a **separate non-design step in the documentation
block**.

This document is the evaluation that precedes the replanning. It rules nothing.

## 1. What is actually in the block

Two proposal sets and a resolution paragraph. They are **not one kind of work**,
which is the first thing the plan has to reflect.

| # | item | kind | blast radius |
|---|---|---|---|
| 1 | `get_text()` exported | **already shipped** (`FEAT-03`, session68) — the proposal retires the *"experimental until somebody needs it"* condition | documentation only |
| 2 | one payload shape: every content-bearing callback receives the string | **breaking**, public surface | largest — and it **overturns a ratified decision**, see §2 |
| 3 | submit clears the field by default; `auto_clear = false` keeps it | **breaking** default, plus a new persistent key | medium — joins `auto_hide`'s family |
| 4 | Escape hides and does not clear | **breaking** default; reverses a documented contract | medium, with a severity argument of its own (§3) |
| 5 | `show{...}` is a new question, bare `show()` restores | semantics of an existing call | medium; **arrived with dissent attached** (§4) |
| 6 | `@nagydani`'s minimal surface — `compy.ask(...)` plus two callbacks — **exposed alongside** the current one under `compy.input` (the live-discussion resolution) | **additive second surface**, *"details to be figured out"* | the largest *shape* question in the block |
| 7 | — | the block itself sits inside the guide the PR is reviewed from, and cites `sync-input-proposal.md`, which **is not in the repository** | housekeeping, pre-PR either way |

## 2. Item 2 is not an amendment, it is a reversal — and it has a live consumer

`FIX-02-01` asked whether `on_text_entered` and `after_submit` are two ways to
set one callback. It was **ANSWERED 2026-08-30 by Decision 37**, ruled jointly
with `FEAT-01-03`: *they are not — they are told apart by their payload*, and the
split was then implemented (`FEAT-01-03`/`-04`) and documented (`FEAT-01-06`).

Item 2 says the payload distinction is the defect: *"today two callbacks are told
apart by payload shape, and `lines[1]` on a string fails silently."* Both
statements are about the same design and they disagree.

That is legitimate — a post-implementation stakeholder read is exactly the kind of
evidence a ratified decision may be reopened on, and the strategic frame invites
it (*"ratified-but-unexamined design is not exempt"*). But it means item 2 is a
**decisions-ledger reopening**, not a small surface tweak, and it lands on a
surface that already has a **downstream consumer**: the platform's `serial` API
took this build as its experimental foundation, and `CHG-01`'s migration note was
written for that audience. Reversing the split pre-PR migrates that consumer
twice.

## 3. Item 4 is the one with a severity argument for going early

Escape currently **clears the content without closing the widget**. That is not
an accident: it is a stated contract (`CHANGELOG.md`; `doc/input_api.md`,
*"Asking one question"*), and the register already names the asymmetry it leaves
(`technical_debt/input.md`, the trigger-echo entry's *"the re-arm has no single
home — Escape clears without hiding, and there is no close callback"*).

The proposal calls it *"the P1 data-loss hazard, reachable from the right mouse
button"*. If that reading is accepted, the shipping release contains a
user-reachable data-loss path that the guide documents as intended behaviour —
and *that* is a question worth answering before the PR even if the **fix** waits,
because the two answers are cheap and opposite: either it is the contract (and
the guide says why), or it is a defect (and it is a `BUG` row, not a proposal).

**Ruling on it pre-PR is cheap. Implementing it pre-PR is not.**

## 4. Item 5 already carries its own dissent, and item 1 is what makes the third option work

The block records soft objections to `show()` vs `show{}` — *"semantically
inobvious"*, *"not clear whether case frequency justifies optimizing API for
it"* — plus two alternatives: bind auto-clear to hide and see whether
`auto_clear × auto_hide` covers the scenarios, or the one **the guide already
advises**: read the content before hiding and restore it from a project variable.

That third option is only writable because `get_text()` shipped. It is the
worked save-and-restore example the register cites as `T-CONTENT-READ`'s
resolution. So item 5's *"do nothing"* branch is already documented and already
works, which lowers its urgency without settling it.

## 5. Where this belongs — recommendation

**Recommended: a `PROP-01` sprint that runs *after* `PR-01`, with three
carve-outs taken before it.**

Grounds for after:

- **Items 2–6 reopen the public surface**, and the phase's whole remaining
  sequence is sized against the current one: `ACC-02` smokes it on hardware,
  `CHG-01` has already written its changelog, `DEC-02`/`LEDGER-02` vacuum the
  ledgers that record it, and `PR-01` cuts slices from it. Anything that moves
  the surface between here and `PR-01` re-runs all of that — the roadmap's own
  ordering principle, *sizing a small row against an unsettled surface is sizing
  it twice*, applied to the surface itself.
- **The strategic frame argues the same way from the other end.** The PR must be
  reviewable from `doc/input_api.md` plus the description alone, carrying no
  moving parts beyond the stakeholder ask. A surface under revision is a moving
  part; a surface that ships with its successor's questions **named in the
  description** is not.
- **Item 6 is not sized at all.** *"Details to be figured out"* is the honest
  state of a second public surface. That is a design cycle, and it is the one
  item nobody has claimed is small.
- **The proposals do not expire.** They are additive to a released API in every
  case except 3 and 4, whose defaults are the only genuinely breaking part — and
  a follow-up release that changes two defaults with a migration note is
  ordinary, where a pre-PR change to them is a re-stabilization.

Grounds for before, stated fairly: the proposals come from **the stakeholders the
PR is for**, so shipping a surface its own reviewers have already asked to change
guarantees a second breaking release soon after the first. That is a real cost.
It is the cost of *one more release*, not of a wrong release, which is why the
recommendation still lands on after.

### The three carve-outs, all pre-PR, none of them design

1. **`DOC-01-07` — retract `get_text()`'s experimental marking.** The owner's
   named consequence. Four sites (`doc/input_api.md` ×3, `CHANGELOG.md` ×1) plus
   past-tensing the debt entry that records the ruling. Non-design: the status
   change is the owner's, already stated; the row executes it.
2. **The block does not ship inside the guide as it stands.** It carries author
   handles, a `remark:` line, unresolved alternatives and a pointer to a document
   that is not in the repository. The PR description already has an **open
   questions** section by construction (`agents/validation.md`, the phase's
   definition of done), which is where a reviewer expects to meet exactly this.
   Owner call on the destination; cheap either way, and it is `PR-01` work.
3. **A ruling on item 4's severity** (§3) — contract or defect. No
   implementation either way.

### What `PROP-01` would hold, if the recommendation stands

Ordered by blast radius, not by the block's own numbering:

| id | row |
|---|---|
| `PROP-01-01` | triage and provenance — which items survive contact with the shipped surface, and what each would break. The classification the rest is sized against |
| `PROP-01-02` | **the two-surface shape** — the live-discussion resolution: `compy.ask`-style simple surface exposed beside the current one, same namespace. First because it decides how much items 3–5 matter: defaults on a low-level surface a wrapper hides are a different question |
| `PROP-01-03` | **one payload shape** — reopens Decision 37 (§2), with the `serial` consumer in the room |
| `PROP-01-04` | `auto_clear`, and whether it joins `auto_hide` as a persistent key or replaces the pair with something better-named (the block's own alternative) |
| `PROP-01-05` | Escape hides and does not clear — implementation of whatever §3's ruling decided |
| `PROP-01-06` | `show()` vs `show{...}`, against the two recorded alternatives and the shipped save-and-restore idiom |
| `PROP-01-07` | the guide and the changelog absorb whatever landed |

## 6. Two loose ends found while reading

- **`sync-input-proposal.md` does not exist** anywhere in the tree
  (`git grep -l sync-input-proposal` returns `doc/input_api.md` only). The guide
  cites it as the home of the synchronous-input proposal. Either it is
  unpublished, or it lives outside this repository, or the reference is
  aspirational — it dangles today, in the persistent corpus, in the one document
  the PR is reviewed from.
- **Synchronous input is named as a separate product proposal** in the block's
  own rationale, which means the block is a *subset* of what the stakeholders
  have on the table. Worth knowing before sizing `PROP-01`.
