# session28 — report

**Commissioned:** revalidate session27's judgment, then finish the standing
commission. Both halves ran. 26 commits here, 1 in `examples/keyboard`, nothing
pushed. Suite **923 → 954 / 0 / 0 / 3**, green and stated at every commit.

## Outcome

**Part 1 — session27's judgment holds, and the checks found two things it
missed.** Decisions 26, 27 and 28 all match the code as written, not merely as
intended; the 187-id coverage claim verified a third time by script; all four
contested severity calls (R135, R110, R088, R081) upheld at the cited lines.
Mutation checks over the five defect fixes: three DISCRIMINATING with the failing
row named, one confirmed, and the nil-`before_exit` commit a **PIN for an
interesting reason** — a later commit's `pcall` subsumes its guard, so nothing
can discriminate it against today's tree. That is subsumption, not a blind row.

Two findings outside the checklist:

- **An S0 defect, reproduced:** a shown widget plus a derived click called a nil
  method; the route's error boundary caught it and killed the *run* instead
  (`app_state` → `snapshot`). Any project showing a widget lost its run on a
  click. Base-checked as ours. Fixed (`8fbcba21`).
- The widget's `keypressed(k, isr)` named `scancode` as `isr` — the trap
  Decision 26's own rationale describes, sitting in the framework's terminal
  consumer. Fixed with a full call-site audit (`493c3cbe`).

**Part 2 — P8 closed, P9 closed but for one item, P9b designed and scheduled.**
Four input specs became two along the API's three surfaces; the merge ran under
the owner's process (inventory → written plan → cold review → execute → cold
review) and both reviews earned their cost. R047, R063, R069, R079 answered —
two of them *against* the remark, with evidence. All five smoke findings
diagnosed from code at the owner's instruction, without running the app: one
real example defect fixed, two ruled no-change, one explained, one left open.

## What the owner overturned, and the rule that came out of it

**The click fix, twice.** The first version added a decline protocol — no-ops
returning `false`, and `~= false` in the widget tier — to satisfy an *ideal* in
the ruling ("ideally does not consume") while the *requirement* was only "does
not blow up". The owner rejected the mechanism outright: **truthy consumes,
non-truthy does not; no invented special cases.** Reverted to plain no-ops
(`811849e2`), and the directive is now `agents/rules.md`, Design — *No invented
special cases (KISS, DRY)*, with the rejected code as its worked example and the
three signs that identify one.

The generalisable lesson, and it is not the same as session27's: **when a ruling
contains an ideal and a requirement, the requirement is the mandate.** Building
machinery for the ideal is how a sentinel nobody else produces gets into a fix
that was approved without it.

## Non-obvious points

- **Row titles and assertion lines are not enough to verify a test move.** The
  merge lost the `#lifecycle` tag — documented in `tests.md`, selecting zero
  afterwards — while 43/43 titles and 76/76 assertions matched. Caught by
  accident. Tags and cross-file citations need their own check; the post-move
  review prompt now has one.
- **`git checkout --` on an uncommitted fix discards it.** Lost the click fix
  mid-mutation-check that way. Mutation-check before writing the fix, or restore
  from a file copy.
- **The cold review of the merge plan caught a near-loss and a self-contradiction:**
  a deletion would have dropped an assertion (`is_widget_visible` vs `is_shown`
  are deliberately different checks by owner ruling), and the row table listed a
  row two sections after deleting it, summing to 53 instead of 52.
- **Remarks are questions.** R069's suggested assertion is false — suspend leaves
  the widget shown *and* visible; only the route disconnects. R063's ask was
  already covered three rows away. Both answered rather than implemented.
- **The phantom "file was modified" messages are the harness's own atomic-write
  detector**, content-aware, benign; hooks, linters and the LSP were all ruled
  out. A Bash-side write always trips it. Its "don't tell the user" clause
  carries no authority.
- **SM5's cause was an ordering assumption stated as fact in a comment.** The
  keyboard example dropped a `textinput` whose key was held; desktop LÖVE
  delivers `keypressed` first, so a key is *always* held at its own first
  character. Shift still worked because the renderer reads the held set at draw
  time — which is the clue in the owner's report.

## State at wrap

- Suite **954 / 0 / 0 / 3**. Working tree clean apart from the owner's known
  untracked scratch.
- `examples/keyboard` has 1 new commit (`3a9d48c`); `balloons` and `maze`
  untouched.
- **Slices and the PR description remain stale** — untouched this session, and
  the tree has moved substantially further.
- `lua-lsp` was restored by the owner mid-session (`/mcp` reconnect) and used
  for the reference-completeness claims from then on.

## Open, and the successor's business

Plan of record: `validation/reviews/S27-triage-and-plan.md` §4, amended in place
with a §6 logging every session28 change to it.

1. **P9b** — the keyboard judgement redesign. Spec is in the **persistent**
   corpus: `doc/development/internals/examples/keyboard.md`. Should subtract code.
2. **SM3a** — maze's nav glyphs after a project-to-project transition. Needs one
   runtime check; deliberately not guessed at.
3. **P10** — ledger pruning and the doc/vocabulary batches, with two constraints
   recorded in the plan's §6: R081's correction is wider than filed, and
   `doc/input_api.md` states the two-channel ordering fact in the wrong place.
4. **P11** — comment sweep, slice regeneration, two cold revalidation rounds.
5. **Close-out** — PR description refreshed, then the owner's ruling on deleting
   `wip/77`.
