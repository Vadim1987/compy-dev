# session56 — report

**Dates:** 2026-08-28 (first incarnation, died mid-flight) · 2026-08-30 (re-entrance and completion)
**Suite:** **1011 / 0 / 0 / 10** at every commit.
**Mode:** mixed by design — a defect revalidation, then ledger work, then execution. The owner drove
each transition explicitly; none of it drifted.

---

## 1. What this session was

It booted as a wait-for-human placeholder and became two things: **closing out `BUG-01-03`
properly**, and **filing the owner's hand-written debt entries into the plan and the ledgers**.

The first incarnation closed `MERGE-01-04`, `FIX-02-02` and `BUG-01-03`, then commissioned a peer
review of the turtle fix and hit its limit before running it. The second incarnation resumed from
that exact point.

## 2. Outcomes

**`BUG-01-03` is revalidated, not merely fixed.** The commissioned cold review ran: **approve with
comments**. The guard is the framework's own documented idiom — `doc/input_api.md`'s *"Why the
widget sits at tier 3"* puts the onus on the project in words, and the suite pins the shape. Its one
substantive comment (that the guard silently loses suspend-while-typing) was **wrong**, and the
parent's verification says why: `ctrl+pause` is a reservation above tier 1 that no project guard can
reach. What the guard costs is the example's duplicate shortcut, not the capability. The
consequence is now written at the guard itself.

**The owner's three hand-filed entries are filed, ruled and paid or scheduled.** Two new KINDs, both
owner-ruled: **`OP`** (operational, needs no parent decision) and **`FEAT`** (design and
implementation of a proposed surface change).

- **`OP-01` ran and is complete.** It produced **Decision 36** (`oneshot`) and **Decision 37** (the
  submit callbacks are told apart by their payload — which is also the ruled answer to `FIX-02-01`),
  then re-derived the debt entries from them. **`T-NAMESPACE-CLONE` is retired**, paid by a
  *suggested practice* in `conventions/architecture_principles.md` rather than a decision — the
  owner's correction, on the grounds that the rule is generic and that a genuine snapshot may still
  be passed by value.
- **`FEAT-01` is scheduled and leads the remaining sequence** by blast radius: seven rows, of which
  `-01` is an owner-gated design ruling and `-07` is conditional.

**Three new obligations recorded** from the revalidation's residue: `T-GUARD-LIVE` (+ `FIX-02-23`),
`T-MAZE-NEUTRALIZE` (+ `BUG-01-11`, which opens with a weighing and may close `wontfix`), and the
examples' missing coverage — **BACKLOG, with no roadmap row on purpose**, and the entry says so.

**The roadmap's top-level sequence is annotated**, one row per stage: what it is and why it sits
there, with the blast-radius principle stated once. It had been a chain of ids readable only by
someone who already knew the plan.

## 3. Non-obvious points worth carrying

- **A downstream consumer now stands on this branch.** Platform work on the `serial` API took the
  post-merge, pre-debt-entry snapshot as its experimental foundation. It does not delay the release
  — but it makes `FEAT-01`'s payload split **a breaking change with a real consumer**, which is
  `CHG-01`'s audience.
- **Every in-tree consumer of `on_text_entered` simplifies under Decision 37, and none pays.** Four
  call `string.unlines` on the payload as their first statement (`maze`, `tixy`, `balloons`,
  `repl`); three take `lines[1]`. This corrects an earlier claim that `maze` would pay — it does the
  join itself, like the others.
- **`oneshot`'s grounds are precedence and an outside request**, not in-tree demand. Counting
  examples scores it at one call saved and measures the wrong thing; the census survives in
  Decision 36 only as a note on why it does not decide.
- **Half of the payload split already exists** — `after_submit(lines)` is what the submit chain
  passes today, so only `on_text_entered` moves.

## 4. Two errors this session made, and how they were caught

Recorded because the pattern matters more than the instances, and both were caught by the same
instrument — a cold reader given the owner's raw input rather than the session's account of it.

1. **A fabricated migration cost.** Decision 37 claimed `maze` would pay for the payload split.
   `core_editor.lua:46-48` joins the lines as its first statement; the claim was never checked
   against the code.
2. **An overstated documentation gap.** `T-GUARD-LIVE` claimed the guide never says a reservation is
   beyond a project's reach. *"Combos the framework keeps"* documents it, `ctrl+pause` included.
   **A claim that the docs *never* say something is a claim about the whole document, not about the
   section you happen to be standing in.**

Both are fixed. One reviewer finding was **disputed and left standing**: withdrawing Decision 38 is
what `ledgers.md` §2's vacuum clause permits — the entry was never the stakeholder's and nothing
ever cited it.

## 5. Artifacts

- Track: `session56/track.md` (two incarnations, the second appended under a re-entrance heading)
- Reviews: `validation/outcomes/BUG-01-03-turtle-fix-peer-review.md` ·
  `validation/outcomes/session56-input-work-cold-review.md` — both with a parent verification
  addendum, both prompts of record in `validation/prompts/`
- Note: `validation/notes/turtle-pause-duplication.md`
- Persistent corpus: Decisions 36 and 37; the namespace practice in
  `conventions/architecture_principles.md`; four debt entries added, one retired, two restyled
- `ROADMAP.md`: `OP-01` ✅, `FEAT-01`, `FIX-02-23`, `BUG-01-11`, the annotated sequence, the
  downstream record
- Infrastructure (owner's, committed at their direction): `.gitignore`, `compose.yml` bind mount and
  the tmpfs stubs that keep `docker-data` out of tree-wide greps
