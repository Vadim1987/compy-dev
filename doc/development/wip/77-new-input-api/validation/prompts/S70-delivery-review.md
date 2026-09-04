---
description: commissioning prompt for the session70 delivery-level review — roadmap integrity, omissions, drift from purpose (step 3 of the closing order)
status: active
audience: developer
authored: llm
session: 70
date: 2026-09-04
---

# Prompt of record — S70 delivery review (step 3 of the closing order)

Model: **Opus**. One spawn, leaf-agent clause. Deliverable:
`validation/reviews/S70-delivery-revalidation.md`.

---

You are reviewing a completed session at the **delivery** level in a Lua/LÖVE2D
repository at `/repo`. Step 1 of the closing order was a Sonnet peer review of the
diff (`validation/outcomes/S70-cold-peer-review.md`) — **it is done, its three
findings are applied, and you are not repeating it.** Your question is the higher
one: **roadmap integrity, whether anything was omitted, and whether the work drifted
from its purpose.** You read the plan and the range, and you are the reviewer who can
say *the session did what it was for* or *it did not*.

**You are a leaf agent. Do NOT use the Agent tool to spawn sub-agents.** Strict, and
it protects the host rather than a preference: agent fan-out has taken this
container's machine down three times, there is no CPU or memory ceiling, and a
runaway takes the machine rather than the box.

## The range and the mandate

Range `1299ed2b..HEAD` — 36 commits, **all documentation**, no `.lua` under `src/` or
`tests/`. The session booted under
`implementation/sessions/session70/prompt.md`, whose task was: *execute the S69
delivery review's dispositions, then stop and raise `REC-01`/`MERGE-01` with the
owner.* The owner then redirected it repeatedly, in this order:

1. plan the proposal block committed into `doc/input_api.md` as a roadmap step;
2. recon and merge against the platform **again**, drift evaluated towards the edge,
   measured and analysed at the recon stage, with **https remotes**;
3. `agents/` is not the persistent corpus — and, the same day, it **splits**;
4. `PROP-01` is an analysis sprint, not seven tickets;
5. inventory every drift as debt with blast radius and cost; produce a
   stakeholder-showable evaluation; write a merge plan and evaluate its risks;
6. build on PR #45 and ship together; the edge remainder afterwards;
7. import #45 as one squashed commit, deliver the PR as content-derived patches;
8. the drift document is working-tree, not corpus — move it;
9. record every git anchor; wrap; commission the successor to run the import.

The session's own account is `implementation/sessions/session70/report.md`.

## What to test

**A. Did it discharge the mandate it booted with, and did each redirection land?**
The S69 dispositions F2, F3, F4, F7, F8 — are they *worked* or merely *declared*?
F5 and F6 went to the owner: check that what came back is recorded where a successor
will meet it, not only in a commit message.

**B. Roadmap integrity.** `PROP-01`, `MERGE-01-05`, `MERGE-01-06`, `DOC-01-07` are
new; `MERGE-01-01`/`-02`/`-03`, `PR-01-01` and the `REC-01` section were rewritten.
Does the one-line sequence agree with the section headers and the summary table?
Does anything contradict itself the way `DOC-01`'s placement did before F4? Is any
row now unreachable, or owned by nobody?

**C. Omission.** The session produced eight new documents. Ask what is *not* in
them. Specifically: the successor prompt commissions an import — does it carry
everything the successor needs, or does it assume context that dies with this
session? Are the three carve-outs of `PROP-01` owned by rows, or only by prose?

**D. Drift from purpose.** The session was told to execute dispositions and stop. It
ended up rehearsing a merge in throwaway clones and rewriting the assembly plan.
**Each transition was owner-directed** — verify that, commit by commit, and say
plainly whether any of it was self-initiated scope growth. `agents/validation.md`'s
*operational modes* section is the standard: mixing modes at small scale is normal,
at large scale it is what that rule exists to catch.

**E. The two self-corrections, judged rather than counted.** The session reported a
revert risk as *"340 removed lines"* and later corrected it to **49 of #45's added
lines**; and advised `merge --squash` *"not `diff | apply`"*, later corrected to
*three-way versus two-way, either spelling*. Both corrections came after the **owner**
questioned the number. **Is the underlying method sound, or does it produce more of
these?** That is the most useful thing you can judge.

**F. The claims that will be trusted later.** `ANCHORS.md` and the merge plan will be
read by someone executing, not reviewing. Are they usable? Is anything in them stated
with more confidence than its evidence carries — the peer review found exactly that
in the `maze` branch claim (eleven named, six measured).

## What is out of scope

- Re-deriving shas and counts — step 1 did that and its findings are applied.
- Re-litigating owner rulings. Record them; do not weigh them.
- Anything in `src/` or `tests/`: nothing there changed.

## Deliverable

`doc/development/wip/77-new-input-api/validation/reviews/S70-delivery-revalidation.md`,
with front matter (`description`, `status: active`, `audience: developer`,
`authored: llm`, `session: 70`, `date: 2026-09-04`). Structure: **a verdict first**,
then numbered findings each with what/evidence/why-it-matters-at-delivery-level, then
a **dispositions table** naming for each finding whether it is the successor's, the
owner's, or no action. The successor opens by executing that table, so it is the part
that must be unambiguous.

An empty finding list is acceptable if it is true. A confident wrong claim is not.
