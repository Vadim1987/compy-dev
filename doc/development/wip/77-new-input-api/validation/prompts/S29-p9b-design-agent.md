# S29 — sub-agent prompt of record: revalidate the P9b keyboard-judgement design

Spawned: 2026-08-08, session29, part 1 step 4. Model: **Sonnet** (explicit).
**Read-only.**

---

## Context you do not have

`/repo` is a LÖVE2D project (Lua 5.1). It is finishing a new input API for a PR;
branch `feature/77-newapi-analysis-s20260615`, HEAD `36853f54`. Suite:
`busted tests` → **955 / 0 / 0 / 3**.

`src/examples/keyboard` is a **separate git repository** nested inside this one,
with no test suite of its own. It is a typing game. One of its subgames judges
whether the character the player typed matched the displayed target.

The document under review is the design of record for how that judgement should
work:

**`doc/development/internals/examples/keyboard.md`**

Read it in full. Two things about its standing:

- It sits in the project's **persistent documentation corpus** — the docs that
  survive deletion of the feature's scratch directory. A wrong claim in it
  outlives the feature that produced it, and nothing downstream will re-derive
  it.
- It is **not yet implemented**. The shipped code carries an earlier interim fix,
  described in the document's last section. Implementation is the next task after
  this review, so a defect found now is cheap and a defect found later is not.

## Why the design exists (the history it is answering)

The example shipped a defect: it judged a `textinput` by reading whether the
producing key was currently **held**. LÖVE gives no ordering guarantee between
`keypressed` and `textinput`; desktop delivers `keypressed` first, so the key is
*always* held when its own character arrives, and every target was rejected.

An interim fix (`spendGlyph` / `GLYPH_CLAIMED` in the nested repo) claimed one
character per press and released the claim at keyup. The design under review
supersedes it, and is expected to **subtract** code.

A separate review this session traced a residual hole in that interim fix, and
you should test the new design against the same trace:

> A `textinput` that arrives **after its own `keyreleased`** finds no claim
> recorded, falls through to the post-keyup grace window, and is dropped as a
> trailing repeat — although it is the press's own legitimate character.

The design's §"Why rule 4 needs a clock" claims to answer exactly this. Does it?

## What to check

Work in this order; the first is the most valuable.

1. **Internal coherence of the rules against the declared state.** §"State"
   declares one table with four named fields, and says the per-event path
   allocates nothing. §"Rules" lists six rules evaluated on `textinput`, plus
   what `keypressed` and `keyreleased` do in §"Channel ownership". **For each
   rule, ask whether it can actually be evaluated from the state the document
   declares, given what the other two channels are said to do to that state.**
   A rule that needs a value the declared state does not hold — or that the
   other channel has already destroyed by the time the rule runs — is a hole in
   the design, not a detail of implementation. Trace the fields, do not skim
   them.
2. **Rules 3, 4 and 6 make specific claims about what state can and cannot
   distinguish.** Check each claim on its own terms:
   - Rule 3 claims `text == seenText` proves "the producing key has not been
     released since it was last seen", with "no timing involved".
   - Rule 4 claims a clock is *necessary* — that at the moment a `textinput`
     arrives after its own `keyreleased`, a repeat tail and a late-delivered
     character are indistinguishable by state alone.
   - Rule 6 claims to be a dedupe and explicitly disclaims repeat detection.
   For each: does the claim hold? Can you construct a realistic sequence of
   LÖVE events where the rule does the wrong thing — accepts what it should
   drop, or drops what it should judge? Walk concrete event sequences
   (`keypressed`/`textinput`/`keyreleased`, with and without OS repeats, with
   and without modifiers), not abstractions.
3. **The SM5 trace above.** Under the new design, is the late-arriving
   character judged or dropped? Show the rule-by-rule walk.
4. **Interaction with the acceptance gate.** `accepting` closes on a hit and
   reopens when the next target is displayed. Consider what happens to a key
   that is still held across that boundary, and to characters arriving while
   `accepting` is false — which rules run, which state gets updated, and what
   the *next* character therefore sees. The document's own smoke checklist
   names "holding the right key scores one hit and does not bleed a miss onto
   the next target"; decide whether the design achieves that, and say why.
5. **Factual claims about the platform and about LÖVE.** The document asserts:
   no guaranteed order between the channels; desktop sends `keypressed` first
   and the web build sends `textinput` first; `textinput` carries no repeat
   flag; LÖVE 11.5 has no API to query the Caps Lock state; `keyreleased`
   for `capslock` is unreliable. Check what is checkable — the platform's own
   documentation in this repo (`doc/development/internals/user_input.md`, and
   its "Data flow" section in particular) and the LÖVE API. Say plainly which
   claims you could verify and which you could not.
6. **Claims about the shipped code.** The last section describes the interim
   fix: judgement depends on a release arriving; non-printing targets are judged
   on a second path (`altPlayKey`); a chord whose modifiers are released while
   its base key is still held can slip one character through. Verify each against
   the nested repo's actual code (`src/examples/keyboard/input.lua`, `alt.lua`,
   `gauge.lua`). Also confirm the named things the design says should disappear
   (`spendGlyph`, `GLYPH_CLAIMED`, the held-set read in judging, `altPlayKey`'s
   separate judging path) exist today and are where the document says.
7. **Citations and vocabulary.** The document cites `../user_input.md`,
   "Data flow" and names `gauge.lua` as where the target is set. Confirm each
   reference resolves — the file exists, and the **named section** exists under
   that name. A citation that no longer resolves reads as authoritative and is
   worse than none.

## Rules

- **Read-only.** No edits to any file except your deliverable. No `git add`, no
  `git commit`, **no `git push`**, no `git checkout --`, no stash, no branch
  switch. `src/examples/*` are separate git repositories — **read inside them
  freely**, run no git write command in them.
- The tree permanently carries the owner's untracked scratch (`claude.sh`,
  `src/STEPS.md`, `input-pr-slices.tar.gz`, `doc/tall_blocks.md`, some
  `doc/development/wip/` subdirs). Expected; leave it alone.
- End with `git status --porcelain` and `git diff --stat`; record both.
- **The `lua-lsp` MCP server is available** (definition / references /
  diagnostics / hover over a real AST of `/repo`). Caveat from this session: its
  `references` query does not disambiguate methods by receiver type, so for a
  name shared across tables it returns a blend — cross-check with grep.
- **You are reviewing a design, not proposing a better one.** Do not redesign
  the mechanism, and do not report a preference as a defect. Report where the
  document is **wrong, incomplete, or internally inconsistent** — the bar is "a
  competent implementer following this document would build something that
  misbehaves, or could not build it at all from what is written".
- **Report what is, including nothing-found.** Give the file:line, the event
  sequence, or the command output — not a conclusion. Confirming the design is
  sound is a good result; do not manufacture findings. If a rule is right but
  its stated *reason* is wrong, say so — that distinction matters here.

## Deliverable

Write to
**`doc/development/wip/77-new-input-api/validation/reviews/S29-p9b-design-revalidation.md`**.

Structure: one section per check above, each with **CONFIRMED / FINDING /
UNCLEAR**, and for findings the concrete event sequence or file:line that shows
it, plus how a reader would be misled. Then three closing lines:

1. Could a competent implementer build this from the document alone, without
   inventing state or behaviour the document does not specify?
2. Do rules 3, 4 and 6 hold as stated — and is rule 4's necessity argument
   (that state alone cannot separate the two cases) correct?
3. What did you check that came back clean, so the next reader knows the shape
   of your pass?

Your chat reply should be a short digest: verdicts, findings, and the three
closing lines.
