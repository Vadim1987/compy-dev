# session46 report — the sprint closed, and acceptance found 26 defects

Booted to plan the smoke pass with the owner. Ended having closed TF2, run the first cold PR review,
registered **26 defects**, dissolved four planned phases, and rebuilt the plan into a navigable
roadmap. **29 commits, suite `968 / 0 / 0 / 10` at every one, nothing pushed in any repo.**

## What changed structurally

**The TF2 spinoff is closed and its remainder promoted.** All 187 remarks were discharged; what kept
it alive was residue at the wrong altitude — acceptance work, which gates PRs and therefore belongs
to the release plan. Closing it was the sprint's *own* §0 promotion rule firing, not an override.

**Phases B, C, D and F are dissolved** (owner ruling). They predicted the shape of pre-release work;
that shape emerged differently. The intent check is what the **cold reviews** do — and by a reviewer
with no stake, which a self-check could never be. The disposition table emerged as the **defect
register**. C1 and D dissolved outright: *principles are enforced at the row, without abstract
encoding first.* This settled the B→C→D collapse gate, which had been scheduled as step zero of
Phase G, months ahead of it.

**The release phases were renamed and one retired.** `recon` → `REC-01`, lifted **out** of the
release path because it is discovery that can spawn defects. Phase U → `MERGE-01`. Phase G →
`PR-01`, shrunk. **Phase L retired** — its three items were absorbed by DEC-01, already a row, or
parked.

**`ROADMAP.md` is new** and is the navigable view; `plan.md` stays the reasoning and the record.
The rules that emerged are now in **`agents/rules/roadmap.md`**, referenced from `AGENTS.md`.

## ACC-01 — the device-free acceptance pass

**ACC-01-01, slice regeneration**, ran the guide's own §4 check and found **5 files outside every
pathspec** — including `src/harmony/init.lua`, production code. The third occurrence of one failure:
*a pathspec naming files cannot see a file that did not exist when it was written.* The owner's
correction turned the fix from patching the list into **deriving the classification each time**,
with a hard stop on anything unclassified (guide §1.0). 100/100 complete and disjoint.

**ACC-01-02, the cold PR review.** A kit outside the repo: stakeholder inputs as the specification,
slices minus the agentic set, clean `git archive` baselines with no `.git`. The reviewer was
**forbidden `/repo` and the LSP** — both expose the landed state, and a review against the answer
key reports what the author did, not whether it was right. Verdict: **merge with changes.**

## The 26 defects

19 from the review, **2 the owner found by reading it**, 5 from the remark triage. Registered in
`validation/reviews/ACC-01-02-findings-triage.md`, ordered in the roadmap **by blast radius**.

Two were fixed in-session because they blocked nothing else: the **PR description**, which described
a member that does not exist and denied a capability the code ships, and the **five unsliced files**.

The largest single row: **37 unresolved `> REMARK:` blocks across 12 shipping files** — not the 10,
then 14, first reported. They were never un-inventoried; TF2 captured them all. What failed was the
removal pass and then the absence of any check, because **the marker gate greps `src/` and `tests/`
only**. P11 reported it clean and was correct — `doc/` was never in scope.

## Three things worth carrying

**The owner's questions outperformed the review.** Two defects came from them: `release_keyboard_route`
whose name, comment and cited decision all describe retired behaviour, and the debt ledger's **547
resolved lines, a third of the file**. Both are the same shape as the decision tombstones — *every
ledger this feature keeps has accumulated entries about its own scaffolding* — which is why FIX-03
was commissioned as a sweep rather than a fourth row.

**Triaging remarks revealed defects, exactly as predicted.** Directed to lead the roadmap, it
produced five new rows including a possibly **unratified behaviour change in `tixy`** and an
API-shape question the cold reviewer missed entirely.

**Four mechanical slips, all one shape.** Two `| head` truncations that undercounted markers twice, a
`grep -h` whose path filter silently did nothing, and a text-range trim that deleted an adjacent
section. All four: **acting on a range or a pipeline without checking what it actually contained.**
Recorded under that name rather than as four incidents, because the counting errors twice hid the
defect being counted.

## Rulings collected

Provenance scoped to 3 files, not 44 · session numbers never in the persistent corpus · rot debt
vacuumed, pre-existing fixes and behavioural changes to the CHANGELOG · decisions get **names, not
numbers** · Decision 12 stays for the owner to dispose · B/C/D dissolve · the release phases renamed.

Four questions are **parked with the moment each gets answered**, not left open.
