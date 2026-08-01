# session24 — report

**Commissioned:** wait for the human, then act on inbound TF2 review feedback.
What arrived was the owner's TF2 take-01 (nine smoke reports plus per-file
remarks), which was triaged into a five-band plan
(`validation/reviews/S24-TF2-take01-triage.md` §8) and executed through band 5.

## Outcome

Bands 1–5 executed; suite **861 → 874 / 0 / 0 / 3**, green and stated at every
commit. Two production defects found and fixed, one owner sitting held
(twelve rulings), and three sibling repos put on their own PR footing.

**Two items are unsettled and are the successor's first business** —
`validation/reviews/S24-contradictions.md`:

- **C1** — the event-batch seal (Decision 19) is in the tree **unratified**;
  the owner contests its landing without design review. Marked as such in the
  ledger, the guide and the code; revert surface documented.
- **C2** — maze's migration was committed with two consequences of our own API
  change deferred to that repo's author. Migrations we author are held to the
  platform PR's standard; the questions are ours to finish.
- **C3** — the overlay-paint fix awaits the owner's smoke test (their choice,
  not a contradiction).

## What the defect hunt found

Both defects were invisible to a suite that was green throughout, for reasons
worth carrying forward.

**A1 — a genuine regression** (`d6b3db4`). `stop_project_run` cleared
`love.state.user_input` directly instead of hiding through the widget, so the
widget's own `shown` flag stayed true after the project ended; the next
project's `show{}` hit the already-active guard and no-opped. Every stop path
arms it, and the flag starts down at boot — exactly the reported "first project
after boot works". The suite missed it because `F.reset()` forced
`widget.shown = false` every test, compensating for the bug under a comment
calling it state "production neither creates nor observes".

**A4/A5 — pre-existing, not ours** (`e80c644`). An input-only project's overlay
was never painted: the only paint site was the wrapper installed when a project
*replaces* `love.draw`. Measured: drawing project 2 paints/2 frames,
non-drawing **0**. One cause behind "I don't see what I typed", "no prompt",
"black instead of blue bar", and "it freezes" — the error lock is correct and
its band *is* rendered, into a canvas nobody blitted. Byte-identical wiring at
`3256aac`; ruling (a) made input-only projects live, which is what put the gap
under the examples that demonstrate the API.

Evidence notes: `validation/notes/S24-W7-A1-second-project-overlay.md`,
`.../S24-W7-A4-A5-invisible-overlay.md`.

## The sitting

Twelve items, all recorded with their rulings and an execution table in
`validation/reviews/S24-W9-ruling-sheet.md`. Three things worth knowing at this
level:

- **Item 12 was escalated mid-sitting** and is the substantive one: a project's
  `love` is a deep clone, so `love.state.user_input` read inside a project is
  **always nil**. maze's re-arm guard is that exact read — dead code, and the
  reason it re-shows every tick. Owner ruled to expose
  `compy.input.is_shown()` (Decision 18), closing a standing open decision.
- **Three rulings came back conditional** and were resolved by checking, not
  assuming: the error lock and repl's echo are both pre-feature (verified at
  `3256aac`), and pointer handlers really are treated differently from keyboard
  ones — so the vocabulary rewrite owes the caveat the owner asked for.
- **Repeat-`show` was ruled against the recommendation**: not a framework
  concern, the examples are at fault.

## Post-sitting corrections (owner-raised)

- The PR guide's 1a/1b rule survives the front-matter era, but the check found
  worse: `conventions/docs.md` fell outside every slice pathspec and would have
  vanished from the PR. `SET1` now names the directory; §4 says its
  completeness check belongs after any commit that *adds* a file.
- **The wider error-lock exits are not drift**: the frozen design mandates
  "Enter/Space/arrows", the widening landed under that AC, and the corpus doc
  described the wider set at the PR base while the code did Enter/Up/Down.
  Narrowing now would be an edit to a frozen document.
- The keypressed/textinput race is **real and reproduced** — and its fix is C1.

## Sibling repos

maze (`nagydani/Compy-maze`) had its entire migration **uncommitted**; now
`790ac19`, with the dead guard corrected. balloons had a *staged* fix that
turns out to be the answer to smoke report 5 (`compy.input.after_submit = …`
raises; lifecycle callbacks live under `.callbacks`); now `94a5f02`, two ahead.
keyboard is clean and needs nothing — and does not bypass the routes, which
answers report 7. Nothing pushed. `pr-assembly-guide.md` §5 is rewritten: Set 4
is not a slice of this PR but three sibling PRs.

## Non-obvious points

- **The suite's silence was structural, twice.** A fixture compensating for a
  production bug, and a defect living entirely in the draw path the fixture
  stubs. Both are now pinned by rows that would have failed.
- **`design/` is frozen and it bites both ways** — it ratified the wider error
  lock (so that is not drift), and it is why narrowing it needs the owner.
- **Phase G stays last**, and now has a second reason: the deferred wrapper
  rename will move code, and C1 may move more.
