# session33 — report

**Commissioned:** revalidate session32's plan actualisation, then begin executing it.
Both halves done. **The plan was sound in substance and defective in navigation**; five owner
rulings resolved it; two execution units landed.

Suite **955 / 0 / 0 / 3** throughout. Eleven commits — ten docs, one deletion. Nothing pushed.
One sub-agent (Sonnet, read-only, prompt and deliverable on disk).

## Part 1 — the revalidation

`S33-plan-revalidation.md`, all six checks plus the red-flag checklist. Eleven findings. The
weighted check — the plan's intents against session32's report — produced the three that
mattered, and they share one cause:

**A document amended in one place and read from another.** Session28 declared an amendment to
P8 in §6 and never wrote it into the row. Session32 re-lettered the P14 steps and swept §11.4
and §11.5 only, leaving four references in §11.3 that meant *the tests step* but read as the
*deferred design ruling* — so §11.3 gated P8's check on a step that might not start for a long
time while §11.4 listed the same check as unblocked. Both times a later session read the stale
row and built on it. §4's table, meanwhile, had `[S32]` markers on exactly the four steps that
**lost** work and none on the four that **gained** it.

A cold check (`../../../validation/outcomes/S33-p14-citation-verification.md`) confirmed the
counts the plan rests on — 22 occurrences across 7 files, 10 in the internals doc, the marker
gate at 22 + 5 disjoint — and found **eight wrong citations**, six of them ranges a future
session would have deleted. The worst stops at the **opening line** of a test, orphaning its
body. **LSP missed 4 of the 22 occurrences**; grep as backstop was load-bearing, exactly as the
standing rule says.

**Cleared, and worth not re-litigating:** `keys_pressed` appears **nowhere in the tree at PR
base `3256aac`**. The tracked set is entirely feature-introduced, so dissolving it cannot
regress pre-feature behaviour.

## The five rulings, and the two that went against my recommendation

1. **P8: walk all nine ids, do not re-baseline to R079.** I recommended re-baselining on the
   strength of §6's *"P8 marked done"*. The owner declined: §6's claim and §4's row are **both**
   unverified, so the walk settles it rather than one document being trusted over the other.
2. **The step list becomes the single operative list** — steps rewritten to carry their own
   amendments, P14 and the probe deletion added as rows. Working rule: *when a step is amended,
   the amendment goes in the step.*
3. **Take the design ruling now, do not defer it.** The deferral assumed the fork blocked "only
   one internals passage"; it blocks the internals section's centre of gravity, because that
   section documents the builder **by its signature** and the two shapes disagree about exactly
   that parameter. I proposed splitting the docs step; the owner went to the root instead.
4. **Matcher shape (b): the builder calls `Key.ctrl()/alt()/shift()` directly.** Against my
   recommendation of the per-key stand-in. Costs accepted knowingly and written into the plan.
5. **The flag-shortcut pattern is taught under a plain descriptive name** — no ledger
   references in the project-facing guide, which has never carried one.

## Part 2 — execution

- **Probe deleted** (`ba5c94e4`), on its own declared terms. Verified before removing: no
  references anywhere in code or the persistent corpus, no loader enumerates `src/`, postdates
  the base. Suite green **and a headless boot** — a deletion the suite cannot fail on needs the
  smoke check.
- **P8's nine-id walk** (`../../../validation/reviews/S33-p8-walk.md`): **all nine discharged,
  P8 is DONE.**

## Two places I was wrong, both caught by the process rather than by me

**R079.** I reported it "separately and explicitly held open" and built a recommendation on it.
`S28-merge-plan.md:170`'s *"unchanged pending R079"* is a **merge-scoping** line — it says that
merge would not touch the file. R079 was discharged the same day in its own commit
(`ae176dd1`), by rewrite, with a coverage gap filled and mutation-checked. **I inherited a
planning table's phrase without checking the commits, inside a review whose subject was that
exact failure.** Had the owner accepted my recommendation, P8's sole remaining content would
now be a phantom open ruling.

**`src/model/`.** I recorded that the controllers had moved there. They are at
`src/controller/` in both base and HEAD. The error reached a sub-agent's prompt, which caught
it.

## Non-obvious points worth carrying

- **Shape (b) has an unpriced benefit.** `input_widget_callbacks_spec.lua:537-541` documents a
  test driving **two distinct modifier tracks** — `keys_pressed` for the matcher, a separate
  `isDown` mock for the widget's own `Key.shift()`. The ruled shape **collapses them into
  one**. The cost accounting counted only what shape (b) costs.
- **P8's walk earned its keep after P8 was already done.** Its product was three
  `keys_pressed` sites in `tests/` that P14c's scope did not name — including
  **`input_fixture.lua:272`, live code in the shared fixture reset on every input test's
  path** — plus a citation that rots and a file left misnamed once its first `describe` goes.
- **P14a splits by audience, not by difficulty.** The project-facing guide is
  shape-independent; the internals doc is not. That is why the fork blocked more than it
  looked like it did.
- **The owner cannot reason over ref-ids.** *"i do not understand this taxonomy, cannot reason
  over bare paragraphs and ref-ids… reference their essence not only identifiers."* Every
  decision re-framed as *what step, what document, what changes* was answered immediately.
  P-ids are a filing system, not a language.
