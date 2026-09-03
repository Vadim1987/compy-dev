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
| 1 | `keyboard` takes its one upstream commit | `MERGE-01-02` | its own suite green; the build script still finds a flat source tree — **verified 2026-09-03**: our file set there is identical to upstream's, so its `*.lua` glob emits our tree |
| 2 | `maze`, `balloons` — **nothing to do**, recorded as measured | `MERGE-01-01`/`-03` | — |
| 3 | **merge PR #45's head into our branch** as one merge commit | `MERGE-01-05` | **both suites present, 0 failures** |
| 4 | the re-pins and the two decisions, each its own commit | `MERGE-01-05` | same, plus the Ctrl+S ruling recorded in the decisions ledger |
| 5 | **`ACC-02`, the device passes** | `ACC-02` | as today |
| 6 | the prose rows, the cold read, assembly | `FIX-02` (b) … `PR-01` | as today |
| 7 | the edge remainder | `MERGE-01-06` | after the release — **and it is verified to stack**: the branch, then the rework, then the whole edge runs 1108/22, the same 22 the rework already owed |

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

**Revised 2026-09-03 by three landscape clarifications from the owner**, which change
the mechanics without changing the order:

1. **#45 is the target base *by content*, and it may be force-pushed at any moment**
   (its author rewrites for commit hygiene). We stay on this branch for continuity.
2. **The PR is delivered as a set of patches against #45**, not as a branch whose
   history must be a descendant of it. *"Slices" have always been patches; the word
   is the only new thing.*
3. **The release order is #45, then ours, then the edge remainder**, and the goal is
   that the three **stack**.

### What follows from a force-pushable base

**A merge commit's second parent can become unreachable.** If #45 is rewritten after
we merge it, our merge parent points at an object nobody upstream has any more: the
lineage claim becomes a fiction, and the patches we generate against *"#45"* would
be generated against a version that no longer exists.

So the mechanics are:

- **Merge locally for reconciliation and smoke, and treat the merge as disposable.**
  It exists to produce a runnable tree and to prove the stack — which it has already
  done — not to be the shipping artifact.
- **The shipping artifact is the patch set**, generated against **`aldum/dev` + #45
  at generation time** — *not against #45 alone* — and regenerated when either head
  moves. Generation is last in the sequence for exactly this reason.

  **Why `dev + #45` and not #45**: #45 forked from `dev` on 2026-07-09 and is **seven
  commits behind** it; we have all seven. Generated against bare #45, our patch set
  would carry those seven as apparent changes. `dev + #45` is also the tree that
  exists the moment #45 lands, and it merges cleanly today, so it can be constructed
  locally at any time. Ancestry note:
  [`../notes/S70-platform-ancestry.md`](../notes/S70-platform-ancestry.md).
- **Pin every base we generate against** as a local tag, in the round-3 namespace, so
  *"which #45 was this cut against"* is answerable after a rewrite. `base-pr45`
  (`16eb33d7`) is the first such pin.
- **Keep our own work in commits that carry one concern each** — which the phase
  already requires — because a patch set is only reviewable if its members are.
  A rewritten base costs a re-generation; it must not cost a re-authoring.
- **Do not depend on ancestry anywhere.** No "since the merge base" reasoning in the
  PR description, no diff ranges quoted against #45's sha in prose that ships.

### The conflict resolutions, unchanged by the above

The four conflicts and their intended resolutions (the trial's probes are marked;
they are *not* the plan):

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

**R2 — #45 changes, or is force-pushed, before it lands.** `medium impact, high likelihood`

**The owner states this as a given, not a risk to be hoped away**: its author
rewrites it for commit hygiene. Its head has also not moved since 2026-07-24 — six
weeks — and it is a large, review-heavy change, so content feedback is likely too.

**And there is a structural reason it must move at least once**: #45 is **seven
commits behind `aldum/dev`**. **Treat "#45 changes" as scheduled, not as a hazard** —
and the catch-up itself is **not** the hazardous part, which was checked rather than
assumed:

- **#45 rebases onto current `dev` with zero conflicts**, dropping two commits that
  reached `dev` by another route, leaving 50 — and the result is **green, 760/0**.
- **Merging instead of rebasing gives a byte-identical tree.** So the integrated
  content is determined; only its commit shape is not.
- **Our branch meets the rebased form with exactly the same four conflicts** as it
  meets today's head.

*So the residual in this risk is narrower than it looks: not the catch-up, but any*
***new content*** *the author adds for review feedback. That is the only thing that
can move our numbers, and re-running the stack costs minutes.*

*Mitigation:* the head is pinned as a local tag, so *"what changed"* stays
answerable across a rewrite. Nothing we ship depends on ancestry (§2), so a rewrite
costs a **re-generated patch set and a re-run merge**, not a redo of authored work.
The measured cost of the first reconciliation is the best available estimate of the
second — and it is small.

*The trap to avoid is subtler than the rewrite:* if #45 is rewritten **and its
content changes at the same time**, a re-generated patch set can apply cleanly while
resolving against different behaviour. **Re-run the stack, do not just re-apply the
patches** — the suite numbers in §5 of the essence note are the comparison.

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

**R11 — a change that merges cleanly and stops working.** `high impact, observed once`

**Not hypothetical: it is in the edge remainder now.** The Android exit path
reroutes every full exit through a request the quit handler consumes; one of the
call sites it rewrites is the Ctrl+Escape handler, which **this branch moved** into
the reservation table. The rewrite lands on the old location, our relocated
reservation does not conflict with it, and it keeps calling `love.event.quit()`
directly — so the device stops returning to its launcher. Full analysis and the
one-line fix: [`../notes/S70-edge-essence-and-stack.md`](../notes/S70-edge-essence-and-stack.md) §2.

*Mitigation, and it generalises beyond this instance:* **for every upstream commit
that rewrites a call site, ask where that call site is in our tree.** The class is
*"they changed a line we moved"*, it is invisible to both the merge and the suite,
and this feature moved a great deal of the input path. The reservation table, the
hook seeding and the routing grid are the three places to check first.

---

**R12 — two upstream changes are drawing changes, and this container has no display.**
`medium impact, certain`

The per-character render-cost fix deletes lines from the very view function this
branch also edited, and the terminal's repaint gate makes drawing conditional on a
dirty flag. Neither can fail a headless suite; both can produce a stale or mis-drawn
frame.

*Mitigation:* they go on the device pass explicitly, as named steps rather than as
general "does it look right" — the typing path for the first, and console output
after a project writes for the second.

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
