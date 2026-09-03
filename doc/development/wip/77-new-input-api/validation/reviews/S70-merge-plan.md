---
description: the merge plan — order, gates and rollback for landing on PR #45, the example repos and the edge remainder, with the risks evaluated
status: active
audience: developer
authored: llm
session: 70
date: 2026-09-03
---

# The merge plan, and what can go wrong with it

**Commissioned by the owner, 2026-09-03:** *"i need all these findings written down
and inventorized, than merge plan written and evaluated for risks/conflicts."*

Inputs, all measured this session: the live drift
([`../notes/S70-REC-01-drift-measurement.md`](../notes/S70-REC-01-drift-measurement.md)),
the trial merge onto PR #45
([`../notes/S70-PR45-as-base.md`](../notes/S70-PR45-as-base.md)), and the three
register entries that carry the cost (`T-DRIFT-PR45`, `T-DRIFT-KEYBOARD`, and the
edge's BACKLOG entry). The stakeholder-facing version is
`doc/development/upstream_drift.md`.

## 1. The order, and why it is this order

| # | step | roadmap row | gate before moving on |
|---|---|---|---|
| 1 | `keyboard` takes its one upstream commit | `MERGE-01-02` | its own suite green; the build script still finds a flat source tree |
| 2 | `maze`, `balloons` — **nothing to do**, recorded as measured | `MERGE-01-01`/`-03` | — |
| 3 | **merge PR #45's head into our branch** as one merge commit | `MERGE-01-05` | **both suites present, 0 failures** |
| 4 | the re-pins and the two decisions, each its own commit | `MERGE-01-05` | same, plus the Ctrl+S ruling recorded in the decisions ledger |
| 5 | **`ACC-02`, the device passes** | `ACC-02` | as today |
| 6 | the prose rows, the cold read, assembly | `FIX-02` (b) … `PR-01` | as today |
| 7 | the edge remainder | `MERGE-01-06` | after the release |

**Three ordering claims, each with its reason.**

- **The example repos go first because they are free.** One clean commit and two
  measurements. Doing them first removes them from every later conversation.
- **The platform merge goes before `ACC-02`.** This is the 2026-09-02 ruling that
  moved reconciliation ahead of the device passes, and it now has a much stronger
  case than when it was made: the rework **changes what keys do while typing in the
  editor**, so a device pass run before it smokes a tree that then changes. This is
  the single most expensive thing to get wrong in this plan, because the device
  pass is the one step that cannot be repeated cheaply.
- **The edge remainder goes last, after the release.** Owner decision. Nothing in
  it is needed by anything before it, and one item in it — the tone-bearing prompt
  label — is a *surface* question that would otherwise reopen the guide during
  assembly.

## 2. What step 3 actually does, mechanically

**Merge, do not rebase.** One merge commit whose second parent is PR #45's pinned
head, so the reconciliation is a single reviewable object and can be reverted as
one. The re-pins and decisions of step 4 land **after** it, in their own commits,
so that a later change in #45 costs a re-merge and not an archaeology exercise.

The four conflicts and their intended resolutions (the trial's probes are marked;
they are *not* the plan):

| file | resolution |
|---|---|
| `tests/mock.lua` | union of both sides' exports — trivial |
| `userInputModel.lua`, `set_text` | **ours**, plus their one-line edit-history reset. Settled by measurement, both ways run |
| `userInputModel.lua`, `new()` | ours plus their `editing` flag; **update their two positional call sites in the same commit** |
| `editorController.lua` | theirs as the base, then re-apply our edits to that file deliberately — *the trial took theirs wholesale, which is a probe* |
| `controller.lua` | **neither side wholesale.** Express #45's editor reservations as entries in our `RESERVED` table — *the trial took ours, which is a probe and is what causes its 16 upstream-side failures* |

## 3. Risks, evaluated

Ordered by expected cost, not by likelihood.

---

**R1 — our pull request's diff would contain someone else's 52 commits.** `high impact`

If we merge #45 while #45 is still open, and then open our PR against the
platform's development line, the diff a reviewer sees **includes the entire editor
rework**. That defeats the release's own stated gate — reviewable from the input
API guide plus the description alone.

*Mitigation, and it is a coordination act rather than a technical one:* **#45 lands
first, then ours.** The local merge can happen now — it is what makes our tree
smokable — but the PR is opened, or re-targeted, after #45 is in the platform's
development line. If that ordering cannot be had, the fallback is to open ours as a
**draft that names the dependency**, which is what a draft is for.

*This is the risk that most deserves the owner's attention, because the mitigation
is not ours to execute.*

---

**R2 — #45 changes before it lands.** `medium impact, medium likelihood`

Its head has not moved since 2026-07-24 — **six weeks** — and it is a large,
review-heavy change. Review feedback on it is likely, not unlikely.

*Mitigation:* the head is pinned as a local tag, so *"what changed since we merged"*
is one command. Because the merge is a single commit and the re-pins are separate,
absorbing a revised #45 is a second merge, not a redo. The measured cost of the
first merge is the best available estimate of the second.

---

**R3 — #45 does not land at all.** `high impact, low likelihood`

Then our branch carries a merge of work that never shipped, and our release would
document editor behaviour nobody has.

*Mitigation:* the single merge commit is revertible, and the re-pins that follow it
are separable. **Do not interleave the re-pins with unrelated work**, which is the
one habit that would make the revert expensive. Reassess if #45 goes quiet for
another six weeks.

---

**R4 — the device pass gets run twice, or against the wrong tree.** `high impact`

The rework moves keys that the checklists exercise by hand.

*Mitigation:* the ordering above, plus a re-read of the typing sections of
`doc/development/smoke_checklists.md` **after** the merge and before the pass. Any
step that names a key the rework reassigned is rewritten in the same commit as the
merge's documentation.

---

**R5 — the guide documents keys the rework changed.** `medium impact, certain`

`doc/input_api.md` describes what reaches a project and what the framework keeps.
The rework changes editor-side meanings, and the framework's reserved combos are
where the two lines meet — our own reservation work chose the **`ctrl+s` /
`ctrl+shift+s` pair** as its worked example of *a reservation claims its combo
exactly*, and #45 uses that same pair with different meanings.

*Mitigation:* the Ctrl+S ruling is recorded in the decisions ledger **before** the
guide is edited, and the guide follows the ledger rather than the merge.

---

**R6 — a positional signature merged wrong, silently.** `medium impact, low likelihood`

Observed for real in the trial: with the constructor's parameters reordered, one of
their call sites passed a boolean into the label slot and the label into the
`editing` slot. Nothing raised; a test failed two layers away.

*Mitigation:* update every call site in the same commit as the signature, and let
the language server enumerate them rather than a grep alone. The suite catches it,
but only via a distant failure, so do not rely on the suite as the first line.

---

**R7 — the two test harnesses are not interchangeable.** `low impact, certain`

Adopting #45's `tests/mock.lua` wholesale adds 145 errors in our specs and fixes
none of its own failures. Measured.

*Mitigation:* keep ours, port their additions individually. This is already in the
resolution table.

---

**R8 — the suite baseline moves, and this phase reasons from that number.** `low impact, certain`

Every session boots by confirming 1055/0/0/10, and after the merge that number is
wrong by construction — the merged tree carries both suites (the trial ran 1122
cases).

*Mitigation:* the merge commit **states the new baseline and its arithmetic**, and
the boot pointer's baseline line is updated in the same commit. A phase that treats
its baseline as a go-signal must not be left with a stale one.

---

**R9 — the edge's tone-bearing prompt label reaches our documented surface.**
`low impact now, deferred`

Not a conflict and not this release's problem, but it is the reason the edge
remainder is not merely packaging. Recorded on its register entry so that whoever
takes `MERGE-01-06` meets it as a decision rather than as a surprise.

---

**R10 — the keyboard repository's upstream was renamed.** `negligible`

The old address resolves by redirect. Correct it when that repository's pull
request is opened; nothing depends on it before then.

---

## 4. What this plan does not decide

- **Bare Ctrl+S in the editor** — ours closes the buffer, #45 reserves it for the
  checkpoint. A product question, and the rework's author is a party to it.
- **Landing order with the platform** (R1) — coordination, not code.
- **Whether the five editor-route specs are re-pinned by us or by the rework's
  author.** Re-pinning someone else's redesign from the outside is how a merge
  acquires opinions nobody agreed to; the cheaper path is to state what we
  asserted and let the author say what the new expectation is.

## 5. What is deliberately excluded

**PR #22 is ignored.** Owner, 2026-09-03: it will be superseded by the pull request
this phase prepares. It is not re-targeted, not updated, and not closed as part of
this plan; the assembly row opens the real one.
