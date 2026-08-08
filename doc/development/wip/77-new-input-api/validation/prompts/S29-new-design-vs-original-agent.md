# S29 — sub-agent prompt of record: the rewritten design against the original implementation

Spawned: 2026-08-08, session29. Model: **Sonnet** (explicit). **Read-only.**

---

## Context you do not have

`/repo` is a LÖVE2D project (Lua 5.1). Nested inside it at
`src/examples/keyboard` is a **separate git repository** — a typing game with no
test suite. One of its subgames ("Alt-keys") shows a target character and judges
whether the player typed it.

Its judging logic has been rewritten repeatedly. Today the owner discarded the
previous paper design and a new one was written. Your job is to check the new
design against the game's **original** implementation.

- **A — the original.** `c904338` *"Keyboard: Alt-characters fold, press-count
  engine, input hardening"*, before the game moved onto the Compy input API.
  Reach it with `git -C src/examples/keyboard show c904338:<path>`.
- **C — the shipped code.** `3a9d48c`, current HEAD of the nested repo
  (`spendGlyph` / `GLYPH_CLAIMED` / `INPUT.upRecent` / `INPUT_UP_GRACE`). This is
  what is running today and what the new design would replace.
- **E — the new design, on paper.** `doc/development/internals/examples/keyboard.md`
  in the **main** repo. Just rewritten; read it as it stands now, not from
  git history.

E is a *design*, not code. Where its behaviour in a case cannot be determined
from what is written, say **UNDETERMINED** — do not guess, and do not fill the
gap with what you would implement.

## The two questions, in the owner's own framing

**(a) Is E better than A at reducing machinery and complexity, and at
reliability?** Machinery and complexity should be *counted*, not characterised:
pieces of state, tunable constants and their values, distinct code paths a
character can travel, and every place judging consults live input state
(held keys, modifiers) or a frame/clock. Reliability means: how many distinct
ways can a correct player action fail to register, or an incorrect one register?
Enumerate them per version rather than asserting a verdict.

**(b) Is any original design intent from A broken, overlooked or degraded —
and first of all, are there game rules that should NOT change and did?**

This second question is the important one, and it needs a distinction you must
hold throughout: **A's implementation was defective, but A's *intent* may still
be right.** A judged a character by asking whether its key was held, which fails
on desktop LÖVE's event order and rejected essentially every printable target.
That defect is known and is not what you are looking for. What you are looking
for is intent A encoded — in its comments, its constants, its structure, its
scoring — that E drops, contradicts, or quietly changes without saying so.

Read A's judging path and the surrounding game code **in full**, and inventory
what it treats as a win, a miss, or an ignorable event, and under what
conditions. Then check each against E. Anything A deliberately did that E does
not do is a finding unless E states it as an accepted consequence.

## Specific things to check

1. **The game's scoring rules.** `gauge.lua` — `gaugeOnCorrect`, `gaugeOnWrong`,
   `gaugeNext`, `gaugeWeight`, the `fumbled` flag, the mandatory-token logic.
   E's central argument is that the game's own rules make most repeat
   suppression unnecessary. Verify that argument against the scoring code, at
   both A and today. If E's premise about the scoring is wrong, everything built
   on it is wrong.
2. **Non-printing targets** (`backspace`, `tab`, `return`) and `altIsKeyTarget`.
   A, C and E each route these differently. Does E's routing preserve what A
   intended — including what happens when a *printable* key is pressed while a
   non-printing target is displayed, and vice versa?
3. **Shared machinery, other subgames.** E subtracts `spendGlyph`,
   `GLYPH_CLAIMED`, `INPUT.upRecent` and `INPUT_UP_GRACE` — and those live in
   `input.lua`, which **every** scene shares (`find`, `findkey`, `hunt`,
   `press`, `menu`, `pause`, `help`, and others). E's reasoning is scoped to one
   subgame. Check every scene for a dependence on the machinery E removes, and
   on `INPUT.held` / `INPUT.shift` / `INPUT.ctrl` / `INPUT.alt`. A subtraction
   that is safe for Alt-keys and breaks another subgame is exactly the kind of
   thing a scoped design overlooks.
4. **Caps Lock ownership.** `indicators.lua` says the Caps estimate is
   "re-derived from every alphabetic textinput" and is "edge-tracked, not
   isDown". E's rule 1 also reconciles Caps from `textinput`. Are these the same
   mechanism, two mechanisms, or a conflict? Who owns the estimate at A, at C,
   and under E — and does E's account of it match the code that exists?
5. **Reserved chords and the hint.** `shift+escape`, `ctrl+alt+up/down`,
   `alt+*`, `alt+p`, and the `Ctrl+Alt+H` hint. E removes the modifier guard
   from judging. Does anything A relied on for chord handling disappear with it?
6. **Anything A did that neither C nor E does.** Read A's `input.lua` and
   `alt.lua` end to end and list behaviour that simply vanished across the
   rewrites without a decision being recorded anywhere.

## What is already settled — do not re-litigate

These were established earlier today and E was written on them; treat as given:

- A's held-key read broke printable judging outright; the migration to the
  Compy API changed nothing in judging; C is the fix that made judging
  order-independent for `keypressed` vs `textinput`.
- The previous paper design was discarded for being internally contradictory
  and for reintroducing a live held-state read.
- A character whose `textinput` arrives after its own `keyreleased` is dropped
  by A and C alike; E judges it.

## Rules

- **Read-only.** No edits except your deliverable. No `git add`, no `git
  commit`, **no `git push`**, no `git checkout --`, no stash, no branch switch.
  `src/examples/*` are separate git repos — read them and their history freely,
  run no git write command there.
- End with `git status --porcelain` and `git diff --stat`; record both.
- **The `lua-lsp` MCP server is available.** Caveat from this session: its
  `references` query does not disambiguate by receiver type, so cross-check with
  grep.
- **Report what is.** Evidence is the git command and its output, or file:line.
  E being better is a legitimate finding — do not manufacture defects. But
  question (b) asks you to hunt for degradation, so hunt properly before
  concluding there is none.
- **Do not redesign.** If you find a gap, describe it and its consequence; do
  not propose the mechanism that would close it.

## Deliverable

Write to
**`doc/development/wip/77-new-input-api/validation/reviews/S29-new-design-vs-original.md`**:

- **Part 1 — the counts.** A / C / E side by side: state, constants, code paths,
  live-state reads in judging, clock reads in judging.
- **Part 2 — failure modes.** Per version, the enumerated ways a correct action
  fails to register or an incorrect one registers.
- **Part 3 — A's intent inventory.** What A treated as win / miss / ignored, and
  under what condition; each row marked PRESERVED / CHANGED-AND-STATED /
  **CHANGED-SILENTLY** / UNDETERMINED under E.
- **Part 4 — findings**, most serious first, each with file:line or the event
  sequence, and what a player would experience.

Close with three lines:

1. Is E better than A on machinery and reliability, by the counts above?
2. Does E break, overlook or degrade any intent A encoded — and is any *game
   rule* changed that should not have been?
3. What did you check that came back clean?

Your chat reply should be a short digest: the counts, the findings, and the
three closing answers.
