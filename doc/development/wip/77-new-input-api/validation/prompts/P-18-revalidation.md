# Prompt of record — cold revalidation of the landed P-18 work against mandate and intent

**Commissioned:** 2026-08-12, session37, by the owner, before handover. **Model: Opus, explicit.**
**Mode: read-only judgement.** Write one file; change nothing else.

**HARD SAFETY RULE:** do not `checkout`, `switch`, `stash`, `merge`, `reset`, `commit`, or otherwise
touch git state in **any** repository. `/repo` and `/repo/src/examples/keyboard` are both mid-work on
live branches. Read history with `git show` / `git diff` / `git log`, which need no checkout.

## What you are judging

Five commits in the nested repo `/repo/src/examples/keyboard`, newest last:

| commit | claim it makes |
|---|---|
| `ca6d5df` | the merge's correction — `words.lua` judged typing with `inputStale`, deleted on this branch, so the game raised on the first character typed |
| `c60b818` | **the heal** — a glyph claim is released by polling the keyboard once a frame instead of by `keyreleased` plus a frame-stamped grace window; the Alt class claims its chord's trigger |
| `c1ee63c` | **restorations** — three gestures the combo conversion had narrowed are bound back |
| `c3388de` | the `INPUT` proxy is deleted; nine reads call `Key` directly; `isMod` gains `Key.is_mod`'s body |
| `9a20433` | the `isMod` wrapper is deleted; six call sites ask `Key.is_mod` directly |

**Judge them against mandate and intent, not against taste.** The question is whether this work
serves what the feature was asked to do, whether anything a player experiences has changed, and
whether any claim made in a commit message or a comment is false.

## The mandate and the intent, and where each is written

- **The strategic frame** (`agents/validation.md`, "The strategic frame"): stakeholders asked for a
  *simpler and more robust input API*; the PR must be reviewable from `doc/input_api.md` plus the PR
  description alone, and must not carry moving parts beyond that ask without justification. The test
  it names: *does this make the system more predictable, or merely more elaborate?*
- **The governing constraint for this example** —
  `doc/development/wip/77-new-input-api/validation/reviews/P-18-00-keyboard-deepfix-design.md` §1.1,
  an owner ruling: **the game's rules are never changed**; only the implementation is, to fit the
  right mechanism. The test: *would a player notice a difference?* If yes it is out of scope.
- **The step** — `doc/development/wip/77-new-input-api/validation/reviews/S27-triage-and-plan.md`
  §15.4, and the plan and triage in
  `.../validation/reviews/P-18-00-triage-and-plan.md` (§0 holds two further owner calibrations about
  focus loss; §5 holds four rulings; §6 is the execution record).
- **The design reasoning** — the design document above: §1.2 (the delivery order is not a
  guarantee), §2.2 (the inter-channel assumption stated exactly), §7.1 (requirements **R1–R5**), §9
  (the derivation and the settled mechanism).
- **The adoption checklist** — `doc/development/conventions/input_adoption.md`, the operative
  question→action guide, with its rules of restraint.
- **The ledger** — `doc/development/decisions/input.md`, especially Decisions 21, 30, 31 and 32.
- **The API as projects see it** — `doc/input_api.md`.

## A known gap, disclosed so you do not spend effort finding it

**`doc/development/internals/examples/keyboard.md` is STALE and its revision is owed.** It is the
heal's design of record in the persistent corpus, and it still describes the *ratified* design —
`textinput` as the only judge, an `ALT_JUDGE` table with `lastText` and `blocked`, and the subtraction
of `spendGlyph`. **The landed code supersedes that**, because the upstream merge added a second
`textinput` consumer (`words.lua`) and the ratified rule is content-scoped: under it the word `"all"`
cannot be typed. §15.4 requires such a revision to land in that document *before* the code that
assumes it, and it did not. The parent owns this and it is recorded.

**What that means for you:** judge intent from the wip design document, the step and the ledger — not
from that note. **But do check** whether the landed code diverges from the *reasoning* the wip
document sets out, and say plainly if it does. If you find further consequences of the stale note
(citations elsewhere that now mislead, for instance), name them.

## What to check, at minimum

1. **Does the mechanism do what it claims?** Read `input.lua` at `9a20433` and reason about
   `spendGlyph`, `inputTick`, `appKeypressed`, `appKeyreleased`, `appTextinput` and
   `register_reserved` together. Trace the cases the design document says matter: a held key, a
   trailing repeat character after a release, a fast tap, a chord whose modifier is released while
   the trigger stays down, and the help overlay being *held* while the poll runs.
2. **R1–R5 (§7.1): does the landed code satisfy each?** Say so per requirement, with the code path.
3. **Did any player-visible behaviour change?** This is the sharpest question. `c1ee63c` claims to
   *restore* three gestures; check the combos are exactly right (a combo is its modifier set exactly)
   and that `Key.is_alt` restores what the old hand-written chord test swallowed. Check the claim in
   `c60b818` that `alt+p` still pauses once per press.
4. **Is anything the author wrote damaged?** The five scene files touched by `9a20433` are the game
   author's. Compare against `origin/dsent/dev` where useful.
5. **Are the comments true?** Every comment near a changed line is a claim. At least one comment in
   this file's history has already been found re-justifying an inherited exemption with a reason the
   new mechanism does not support — check the `capslock` exemption's comment specifically.
6. **Markers:** `grep -rn "REMARK:\|INTERIM:"` in the game. One marker was retired in `c3388de`
   because the change answered it. Confirm no other was touched, and that the retirement was
   legitimate.
7. **Scope discipline:** does anything in these commits exceed the step? `bubble.lua` in particular
   was ruled *untouched* except for its wrong-key guard line — verify the ruling was honoured.

## Constraints on your judgement

- **Verify in code.** A commit message is the author's claim, not evidence. So is a comment. So is
  this prompt.
- **Do not recommend rule changes.** If you believe a game rule is wrong, put it in a separate
  "raised, not recommended" list.
- **This container cannot inject keystrokes and has no device.** Every smoke run reaches the intro
  and no further. Say what you could not determine rather than implying coverage.
- **Do not fix anything.** Report.

## Deliverable

Write to
`/repo/doc/development/wip/77-new-input-api/validation/reviews/S37-P18-revalidation.md`. Create it
early with headings and update as you go — a prior worker died mid-review holding a full pass of
findings and nothing on disk. Structure: verdict (sound / sound-with-findings / unsound), then
findings ordered by severity, each with file:line and the reasoning that makes it a finding, then
what you could not determine. Finish your chat message with a short digest: the verdict, the counts,
and the three findings you would not want missed.
