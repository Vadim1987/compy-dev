# session36 — report

**Commissioned as:** execute P14e, the examples reconciliation. **Ran as:** that step, then its
correction, then a design conversation the owner opened out of the correction — ending in a
ratified decision, a promoted principle set, a new (small) API function, and a replan.

**Tree at wrap:** `a08afbca`, suite **946 / 0 / 0 / 10** (was 942; `Key.any_pressed` brought four
new cases with it). Nested repos: `keyboard` at `05cedec`, `maze` at `a045fdb`, both clean.

---

## What landed

**P14e — the examples reconciliation, five commits across three repos.** The keyboard example was
broken at HEAD and is not: its `INPUT` proxy asks `Key`, `modHeld` is deleted, `helpHeld` asks the
keyboard for a non-modifier key. `maze` lost its hand-written shift fold. `turtle` and `clock`
moved to `Key`. Everything declined went to the persistent debt register as an enumerated list,
which is what the follow-on steps read.

**The step's sapper conversion was reverted** (`f61ada67`) after the owner supplied the rationale
that existed nowhere in the tree: the modifier-held **press** is a touch fallback, because on touch
devices a single tap is often accidental and a double tap unreliable. Moving it to the derived
click channel put it on the mechanism it exists to bypass. Reverting restored the author's shape;
sapper became its own step.

**Decision 32 — how the input API is meant to be used** — was written, promoted, and is now in the
persistent corpus, with **Decision 30 point 3 amended in place** (`Key.*` at a call site is no
longer called a smell in general). The project guide's flag-shortcut section, which taught the
antipattern the decision forbids, was replaced by "Choosing the mechanism". The operational form
lives in `conventions/input_adoption.md` as a question→action checklist, marked universal vs
project-surface **because the owner intends to reuse it for the console and editor**.

**`Key.any_pressed`** landed (breaking test first; `Key` had no spec at all until now) so a project
has one surface for held state. The richer token-language predicate was **not** ratified for this
release.

**The remainder was replanned** against all of that, and the sprint's steps were separated from the
release plan's phases after the owner caught me conflating them.

---

## The five findings a successor should not have to rediscover

1. **A conversion faithful to a shape can destroy the purpose.** The sapper commit described its
   own mechanics accurately and still broke the feature's reason for existing, because the reason
   was written down nowhere. *Ask the author* is now a rule of restraint in the checklist.
2. **The smoke gate was silently toothless.** LÖVE block-buffers stdout and the container cannot
   end the app cleanly, so `timeout`'s kill discarded the buffer: a project raising at load looked
   exactly like a healthy one. Proven with a deliberately bad registration that printed nothing.
   **Always line-buffer (`stdbuf -oL`) when smoking an example.**
3. **A grep-based gate could not see two of its own markers** (`REMARK` with no colon). Fixed, and
   the plan now says to run the case-insensitive pattern at least once before trusting the count.
4. **"No marker was touched" answers a different question than "no marker went stale".** Two cold
   reviews confirmed the first; the owner asked the second, and four markers were genuinely about
   the changes being made — one of which the same session had made obsolete and left standing.
5. **111 markers are ~6 repeated moves plus ~20 unique fixes.** The disposition pass
   (`validation/outcomes/S36-marker-disposition.md`) bound every one to sprint or parent; the
   editorial bulk is the parent's prose sweep, which is what shrank the endgame.

## Things a successor will otherwise misread

- **The suite is 946, not 942**, and the four new cases are `Key.any_pressed`'s own spec.
- **`sapper` carries a live defect that predates the feature**: shift-click flags a cell at press,
  and if Shift is released inside the 0.4 s click window the derived click arrives unmodified,
  passes the hook's own guard and **un-flags it**. It is P19's, and converting the example neither
  causes nor cures it.
- **Decision 30 was challenged by the owner and survived** — cold-reviewed, with the finding that
  the ledger never made the premise the challenge attributed to it. The condition attached to its
  survival lives on the `compy.input.keys` proposal in the register, not in a review document.
- **Three cold reviews ran this session** (two Sonnet, one Fable) and each corrected something
  real, including the retraction of a claim of mine that was self-contradictory. Their reports are
  in `validation/outcomes/` and `validation/reviews/`.
- **Two owner rulings changed standing process**: deviations must be documented in the workspace
  and not only in commit messages; and tombstone discipline is reversed for the release, with the
  compaction placed in the parent plan as Phase L.
