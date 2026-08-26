# session46 — the sprint's last open question is the smoke pass

Read `agents/sessions.md` and `agents/validation.md` first, then
`../session45/report.md`. Do **not** re-derive session45's work from its track;
the report is the handover.

## Where the sprint is

**P11 is closed and the marker gate is clean** —
`grep -rnE 'INTERIM|REMARK|^[[:space:]]*--(->|>)' src/ tests/` returns nothing,
which was the row's release condition. **P25 and P26 were opened during
session45 and are both empty**: every item escalated to them came back
answerable once someone checked it. The operative list,
`validation/reviews/S27-triage-and-plan.md`, has nothing outstanding in the
sprint except the human smoke pass.

Baseline: **968 / 0 / 0 / 10**. Maze specs: **42** (`luajit spec/*_spec.lua`
from `src/examples/maze` — the documented `lua5.1` is not installed here).

## Your task — planning with the owner, not execution

This is an **evaluation-and-replanning** session by design. Session45 ran
execution end to end and stopped rather than make these calls inside a long
context. Nothing is mid-flight.

### 1. The smoke pass — scope it with the owner

`doc/development/smoke_checklists.md` has lists for `keyboard` and `maze`+`draw`.
Session45 refreshed both sets of commit anchors and added maze's B8–B10 (the
`Shift+Esc` modifier family, whose two halves — Decision 33 platform-side and
`da9d1c2` maze-side — **have never been exercised together on a device**).

Open, and the document's own header says so:

- **`balloons` needs a list.** It is detached, so its PR's only gate is that pass.
- **`sapper` needs one.** Tracked, but its input mechanism changed materially and
  it carries a live defect (P19's).
- **When the pass runs** relative to slice regeneration, and **how a human result
  is recorded** so a failure is investigable.

The owner runs the pass; you write what they run and where the answer lands.

### 2. Then the release path, which is the parent plan's

`validation/plan.md` resumes when the sprint closes, and **the first thing
waiting there is the B→C→D collapse ruling** — an open gate, not a settled
substitution. Also parent-owned: Phase U (both halves), Phase L (ledger
compaction, which will reach back into the two tombstones session44 created),
the deferred editorial marker list, and Phase G — slice regeneration and PR
assembly, which stay **last**. The parent plan's status block is stale and the
owner has left it so deliberately; the collapse ruling rewrites it anyway.

## Three things session45 learned that generalise

1. **Stale claims cluster in prose that narrates change.** Seven doc defects
   were found in sentences of the form *"X no longer does Y"*. If you need to
   find more, that is where to grep — and one false claim had **three** homes,
   because nothing greps for a claim.
2. **Write the checker.** A word-stream comparison, a citation resolver, a
   reverted line — each caught what reading had missed, twice when the reading
   was the parent's own. Cheap, and they do not get tired.
3. **Verify a handover's claims before acting on them.** Session44's lesson held
   again: three of P11's marker tasks were already answered, and one escalation
   was retired an hour after it was filed.

## Two mechanical cautions

- **Never `git add <directory>`.** Session45 swept three embedded example repos
  in as gitlinks and the owner's untracked scratch with them (repaired in
  `7fa248fa`, without rewriting history). Name files.
- **The example repos are separate repositories** with their own remotes and
  their own PRs. Commit in them as the work demands; **never push** any of them,
  or the platform.
