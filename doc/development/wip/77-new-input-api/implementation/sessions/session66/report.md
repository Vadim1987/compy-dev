# session66 — report

**Date:** 2026-09-02 · **Suite:** 1048 / 0 / 0 / 10 throughout, LuaJIT 2.1 in the container (the
owner runs PUC Lua) · **Mode:** revalidation, then execution of its findings, then a replan the
owner ruled in-session, then a **cold revalidation of this session's own work** whose corrections
are applied. Fifteen commits, none pushed. **No test was added or removed.**

---

## 1. What this session was

The scoped delivery-level revalidation session65 owed (`agents/rules/revalidation.md`), over four
named subjects **plus a fifth the owner added on boot**: *"validating replan sanity and integrity —
anything omitted, lost, done in a way that undermines path to release?"* Then the findings executed,
five owner rulings collected, and `FIX-02` reordered.

Deliverable of record:
[`validation/reviews/S66-session65-delivery-revalidation.md`](../../../validation/reviews/S66-session65-delivery-revalidation.md)
— nine findings, F1–F9, each with its disposition as executed.

## 2. The verdict, in one line

**Session65's four hand-written judgement calls hold; its replan did not.** Subjects 1–3 were clean
on substance — no live ruling dropped from `D-AUTO-HIDE` (checked against the eleven suite cases and
the guide, not the diff), every re-pointed citation resolving to a statement that says what the
citing site asserts, and the vacuum's rehoming neither losing nor inventing anything. The defects
were in subject 4's leftovers and in the replan.

## 3. What was wrong, and the pattern under it

- **F1** — the crosswalk cited `D-ONE-LIFETIME`, *"what it reverses"*, a section deleted **two hours
  after the citation was written**, and contradicted the prose forty lines above it.
- **F2** — `ledgers.md` §6 still called unruled the question §2 had just ruled.
- **F5** — a citation edit left *"entry's own recommendation."* standing as a sentence, asserting the
  opposite of the statement it now cites.
- **F3** — the acceptance renumber shipped its crosswalk without the sweep `roadmap.md` §2 requires;
  five citations resolved to a **different smoke pass**, one of them a standing instruction about
  `maze`'s unexercised Track 2.
- **F7** — the crosswalk's closing count was off by one. **F6** — the roadmap's section bodies no
  longer run in sequence order (not fixed; left for the owner). **F8** — three `D-AUTO-HIDE`
  omissions, judged consistent with the owner's framing, no action.

**The pattern: every one of these was measured against `src/` and `tests/`, and every one lives
outside it.** A doc citing a doc, a plan citing a plan, a rule file citing itself. `agents/
validation.md`'s heading-citation rule names *code*, and that is where the sweeps stopped.

## 4. F4 — the finding that was never ours to fix

Session65 replanned from `ROADMAP.md`. **The two rulings its replan reversed live in
`validation/plan.md`** — the *why* document `agents/validation.md` names beside the roadmap's *what
next* — and neither was cited: the pre-merge smoke as the **control** for the post-merge one
(2026-08-26), and the second cold review *"before any keyboard time"* (same day). The roadmap
described the old order as *"an inversion nobody had noticed"*. It had been noticed and ruled on.

**The owner ruled both, and both confirm the new order.** Merges before smoke, on acceleration:
*"no point in having two separate sessions of smoke testing and defect fixing just for ceremony.
Recon will document what changed in the upstreams before the merge; this knowledge will assist
troubleshooting."* And the cold read after keyboard time: *"cold review checks internals, smoke
validates the surface. When the planning horizon collapses to one day, postponing smoke for the sake
of additional peace of mind makes no sense."*

**Neither reverses the 2026-08-26 reasoning on its merits; both change what it is priced against** —
which is why `REC-01`'s delta document is now recorded **as the condition the order stands on**,
not as a by-product of the recon.

## 5. F9 — and the shape of an answer

`ledgers.md` §2 keeps a ruling that came from outside; §3's debt sweep has no such clause, and
`T-ONESHOT` records a capability an outside developer asked for. I proposed a one-line general
clause. **The owner declined to generalise and ruled the instance** — the entries go, because the
contradiction *never existed at base* (there was `oneshot` and nothing replacing it), and the
question a reader has is a **decisions** question. Recorded on `T-NEVER-SHIPPED`, where `LEDGER-02`
reads its input; §3 is unchanged.

## 6. The replan the session ended on

The owner asked whether `REC-01`/`MERGE-01`/`ACC-02` should precede the editorial bundle, and leaned
against it: *"incorrect prose could confuse"* troubleshooting. **Ruled as a split rather than a
move**, the same shape as the acceptance reorder and for the same reason — moving it whole would
have sweeped `keyboard` and `maze` immediately before merging upstream into them.

`FIX-02` **(a)** — the rows a pass reads plus the rows with unknown yield, including `-25`, whose
test can surface a behavioural defect — runs before `REC-01`. **(b)** — vocabulary and process —
runs after `ACC-02`. **The renumbering is deliberately skipped** so the roadmap's stated order
prevails over the ids; the rows are cited from four live debt goals, and §5's failure mode is a
citation that still resolves to the wrong row.

## 7. Non-obvious points worth carrying

- **A `*"section"*` citation sweep is cheap and decisive** — anchors are headings **plus bold
  lead-ins**, because this corpus names sections both ways; headings alone give ~40 false positives.
  Over the whole corpus it returned exactly one real orphan, which three passes of reading had
  walked past.
- **A duplicated schedule renumbers itself into a lie.** `plan.md`'s copy of the `ACC-02` table was
  deleted rather than renumbered: it was `roadmap.md` §1's second-timeline failure arriving by the
  side door, and it is why seven ids drifted in a single edit.
- **Dated records keep their text.** A finding rewritten to match today is no longer the record it
  is; the two touched here carry a bracketed note instead.
- **Generalising has a price.** A rule earns its place by the passes it saves, and one written to
  close a single instance is one the next reader must interpret. Record where it is consumed.

## 8. The session's own work, cold-reviewed — and what it caught

At the owner's instruction the session commissioned a **cold revalidation of itself** (Opus,
no access to this session's reasoning):
[`validation/outcomes/S66-cold-revalidation.md`](../../../validation/outcomes/S66-cold-revalidation.md),
commission in `validation/prompts/`.

**It cleared the judgement and caught the execution.** All nine findings hold, none is a phantom,
F4's premise is verified on both halves — so the owner's two rulings were **not** collected on a
false report — and all four applied corrections state something true. But:

- **Two of twenty rows were in the wrong half of the split I wrote for session67.** `FIX-02-05` sat
  in (b) while `CHG-01-03` names it as its **feeder** and `CHG-01` runs in (a) and gates `ACC-02` —
  the producer scheduled after its consumer. `FIX-02-13` was separated from `-22` against its own
  cell's *"write with `FIX-02-22`, same paragraph of the same doc"*.
- **The deletion lost a status fact and promoted the instruction that fact refuted.** *"Gap closed
  (B11, D8, D9)"* went with the duplicated table, and the same commit wrote *"Track 2 rows first"*
  into the live roadmap row — an obligation discharged on 2026-08-26 at 17:47, standing in front of
  a device pass.
- **My own citation sweep skipped `ROADMAP.md`** — the document the renumber was performed in, and
  the one file guaranteed to cite every id. Two `ACC-02-01` citations survived there while the
  RETIRED entry reported the class resolved.
- **The counts I measured were not written back** into `T-NEVER-SHIPPED` and `T-RETIRED-UNVER`,
  which are exactly the documents `FIX-02-05` and `LEDGER-02` execute from.

**The lesson is the one to carry, and it is uncomfortable in the right way: the pass that names a
defect class is not thereby immune to it.** F3's own finding was *"the blast radius was measured in
the wrong place"*, and the sweep it produced was measured in the wrong place, one file over.
Five correction commits followed (`7150d15b`, `cce77919`, `1e052c7d`, `2a486215`, `cb159e39`),
and a sixth pre-existing class the cold read found on the way: five `FIX-02-01` citations meaning a
row that has been `FIX-02-07` since an earlier renumber, two of them parked questions whose triggers
had fired on the wrong row.

## 9. Artifacts

- Track: `session66/track.md` — boot, the pass, each ruling as it arrived, the cold read
- **Fifteen commits**, `d5362b06`..`cb159e39`, suite green and stated at each; **none pushed**
- New: `validation/reviews/S66-session65-delivery-revalidation.md`,
  `validation/outcomes/S66-cold-revalidation.md`, `validation/prompts/S66-cold-revalidation-commission.md`
- Ledger: six RETIRED entries (five in `technical_debt/general.md`, one in `input.md`), the
  `T-NEVER-SHIPPED` provenance ruling, and re-dated sizings on it and `T-RETIRED-UNVER`
- Amended: `agents/rules/ledgers.md` §6, `decisions/input.md`'s crosswalk, `ROADMAP.md`
  (both reorders, the split's corrections, five stale ids), `validation/plan.md` (superseded in
  place, and the Track-2 discharge restored)
