# session29 — revalidate session28, then P9b → P10 → P11 → close-out

Read and strictly respect `agents/sessions.md` and `agents/validation.md`.
Boot normally: this prompt, then `../session28/report.md` in full, then the
session28 commissioning prompt and its track. Create `session29/track.md`.
Do not edit any historical session artifact.

Baseline: `busted tests` → **954 / 0 / 0 / 3**. A different count is a finding,
not a go-signal.

## Where things stand

Session27 turned 187 owner remarks into a triaged plan and executed its
architectural half. Session28 revalidated that work, finished P8, and closed
four of five smoke findings. The plan of record is
`../../../validation/reviews/S27-triage-and-plan.md` — §4 is the phase table,
and **§6 logs everything session28 changed in it**, including two constraints
that land on P10.

Full account: `../session28/report.md`. Three things a successor needs and
cannot infer:

1. **A ruling's ideal is not its requirement.** Session28 built a decline
   protocol to satisfy an "ideally…" clause in an owner ruling whose actual
   requirement was one line of no-op. It was rejected and reverted, and the
   directive is now in `agents/rules.md` — *No invented special cases (KISS,
   DRY)*. Implement the requirement; ask about the ideal.
2. **Every verification has a shape, and misses what lies outside it.** The
   suite merge was checked by comparing all 43 row titles and all 76 assertion
   lines against the originals — and still lost a documented busted tag, because
   a tag is neither. Ask of any check what it *cannot* see.
3. **Remarks are questions.** Session28 answered two against the remark with
   evidence (R069's proposed assertion is false; R063's ask was covered three
   rows away). Session27 found two more of the same kind.

## Your task, part 1 — revalidation (do this first)

`agents/rules/revalidation.md` applies. Session28 was cognitive-heavy and
downstream work will trust its outputs without re-reading the source. Scope the
checklist to what is most expensive to have wrong:

- **The suite merge.** Four spec files became two, two rows were deleted, five
  assertions added. It was cold-reviewed before and after and both reviews were
  clean — so **check what those reviews' shape could not see**, not what they
  already checked. Tags were the first such gap; look for the next one.
  Deliverables: `../../../validation/reviews/S28-merge-plan.md`,
  `../../../validation/outcomes/S28-merge-{plan-review,result-review}.md`.
- **The two production fixes.** `8fbcba21` (a click at a shown widget killed the
  run) and `493c3cbe` (the widget's key signatures). The first claims a
  base-check and a reproduced defect; the second claims an exhaustive call-site
  audit and no behaviour change. Verify both claims rather than the summaries.
- **The smoke findings' dispositions.** `../../../validation/notes/S28-smoke-findings.md`
  rules SM1 and SM2 no-change, explains SM3b, pins SM4 with a row that **passes
  before and after** (a pin, not a proof — its mutation check is recorded), and
  fixes SM5 in a repo with no tests. The reasoning is code-only by owner
  instruction; check the code says what the note says.
- **The P9b design**, `doc/development/internals/examples/keyboard.md`. It is now
  in the *persistent* corpus, so a wrong claim there outlives the feature. Its
  rules 3, 4 and 6 make specific claims about what state can and cannot
  distinguish; check them.

**Do not skip to part 2 because part 1 finds nothing.** Report to the owner,
then proceed.

## Your task, part 2 — finish the commission

`../../../validation/prompts/S27-human-commission.md` is the standing commission.
Sequencing is the plan's §4 table; the short form:

- **P9b** — implement the keyboard judgement redesign from
  `doc/development/internals/examples/keyboard.md`. Nested repo, **no test
  suite**, so it is reasoned rather than proven; the doc carries a smoke
  checklist for the owner. **It should subtract code** — `spendGlyph`,
  `GLYPH_CLAIMED`, the `INPUT.held` read in the judging path, and `altPlayKey`'s
  separate judging path all go. An implementation that adds machinery has
  misread the design.
- **SM3a** — maze's nav glyphs after a project→project transition. The owner's
  font hypothesis is neither confirmed nor refuted; there is no explicit
  graphics-state reset between runs. It needs **one runtime check** (print the
  font identity at the start of two consecutive maze runs), not a guess. Session28
  excluded the app by instruction; confirm with the owner whether that still holds.
- **P10** — ledger pruning and the doc/vocabulary batches (retire "overlay";
  remove historical contrast against shapes that never shipped). Two constraints
  from §6: **R081's correction is wider than filed** — Decision 2's paragraph is
  stale about the three-component scope *and* about pointer channels having no
  shortcuts tier — and `doc/input_api.md` states the two-channel ordering fact
  inside its echo-guard section, where a project meeting the other consequence
  will not find it. **Tombstone decisions, never renumber**: 179 comments cite
  them by number.
- **P11** — comment sweep by sub-agent against `agents/rules/commenting.md`
  (`grep -rn 'INTERIM:\|REMARK:' src/ tests/` must return nothing), slice
  regeneration, and **two** cold revalidation rounds over groups 3 and 4 — the
  first autofixes serious concerns, the second is presented to the owner unfixed.
- **Close-out** — PR description refreshed (it predates Decisions 26/27/28), then
  the owner's ruling on deleting `wip/77`.

**Ordering still matters:** code → tests → docs → comments. P9b moves code, so
P10's prose and P11's sweep must not start early.

## Standing constraints

- Suite green and stated at every commit; one concern per commit; a production
  fix is its own commit with its breaking test.
- **Stage explicit paths, never a directory.** The tree permanently carries the
  owner's untracked scratch and three nested example repos.
- **Sequence sub-agents; do not run one concurrently with your own edits.**
  Materialise every prompt and deliverable on disk.
- **Never `git checkout --` a file whose uncommitted work you want to keep** —
  session28 destroyed its own fix that way mid-mutation-check. Restore from a
  copy, or commit first.
- **A row asserting an absence needs a mutation check and a control**, and a row
  that passes before and after is a pin — say so in its message.
- **"Pre-existing" is a claim to check against the PR base** — `git show
  3256aac:<file>`. It has overturned conclusions in four consecutive sessions.
- Commit locally at your discretion. **NEVER push** — not this repo, not the
  three nested ones.
- `design/` is frozen — read, never edit.

## Slices and the PR

Both **stale**, and further from the tree than when session28 booted. Slices last
regenerated at `264e0c6c`; Set 4 needs cutting as `4a-balloons` / `4b-maze` /
`4c-keyboard` per the revised `pr-assembly-guide.md`. The PR description predates
Decisions 26/27/28. Regeneration stays the LAST step.
