# S29 — sub-agent prompt of record: the P9b design against the mini-game's own history

Spawned: 2026-08-08, session29, owner question after step 4. Model: **Sonnet**
(explicit). **Read-only.**

---

## Context you do not have

`/repo` is a LÖVE2D project (Lua 5.1). Nested inside it at
`src/examples/keyboard` is a **separate git repository** — a typing game, no test
suite of its own. One of its subgames ("Alt-keys") shows a target character and
judges whether what the player typed matched it.

That judging logic has been rewritten several times, and a **fifth** version now
exists on paper but is not implemented:
`doc/development/internals/examples/keyboard.md` (in the *main* repo).

The owner's question, in their words: **is the new recorded design better or
worse conceptually than the original implementation of the mini-game — does it
solve problems, or create them?** Their concern is specific and you should take
it seriously: the design was produced by an agent after a spoken discussion, and
grew across several rounds of challenge (one field → two fields → state-only →
state plus a timing window). They have not reviewed it as text, and they suspect
it may have **drifted or accreted** — that it may be more elaborate than the
problem requires.

## The versions to compare

All in the nested repo `src/examples/keyboard` unless stated. Reach them with
`git -C src/examples/keyboard show <sha>:<path>`.

- **A — the original.** `c904338` *"Keyboard: Alt-characters fold, press-count
  engine, input hardening"*, before the game moved onto the Compy input API.
  This is the "original implementation" the owner's question names.
- **B — the migration.** `4814407` *"run on the Compy input API instead of
  hand-rolling it"* and the refactors after it up to `6eb7919`. This is where
  `inputStale` (the held-key read) is in play.
- **C — the shipped interim fix.** `3a9d48c`, current `HEAD` of the nested repo:
  `spendGlyph` / `GLYPH_CLAIMED`, claim one character per press, release at
  keyup, `INPUT.upRecent` + `INPUT_UP_GRACE` for the tail.
- **D — the design on paper.** `doc/development/internals/examples/keyboard.md`,
  main repo. `ALT_JUDGE` table, six ordered rules on `textinput`, injection of
  non-printing targets, `TEXT_TAIL_FRAMES`.

## The question that matters most — ask it first

**How did A actually judge a character, and was it correct?**

If the original was simple and correct, then the defect this whole chain of
fixes has been chasing was *introduced* somewhere in B/C, and D may be
re-inventing — with more machinery — something that already worked. If the
original was broken too, in what way, and does D fix that same thing?

Do not assume the later version is the better one because it is later. Read A's
judging path in full and describe what it does in plain terms.

## What to produce

1. **A plain-language account of each version's judging rule** — A, B, C, D —
   two or three sentences each. What decides "this character counts"? What state
   does each keep, and where does it live?
2. **A moving-parts count per version**, so elaboration is visible rather than
   argued: how many pieces of state, how many tunable constants (and their
   values), how many separate code paths a character can travel, how many places
   read *live* input state (held keys, modifiers) at judging time.
3. **A behaviour matrix.** Rows = concrete cases; columns = A, B, C, D; each
   cell = judged / dropped / (state change only), with the reason. Cases must
   include at least:
   - a plain single press of the target character;
   - a key held down producing OS repeats;
   - `textinput` arriving *before* its own `keypressed` (the web-build order);
   - `textinput` arriving *after* its own `keyreleased`;
   - a chord (Alt or Ctrl held) whose character is not a target;
   - a chord whose modifiers are released before its character arrives;
   - a non-printing target (`backspace`, `tab`, `return`);
   - a deliberate fast re-press of the same character;
   - a key still held when the next target appears.
   Where a version's behaviour cannot be determined from what is written (this
   applies especially to D), say **UNDETERMINED** and why — do not guess.
4. **Solved / created, per version transition.** A→B, B→C, C→D: what did the
   change fix, and what did it break or newly complicate? Name the concrete case
   from the matrix each time.
5. **The accretion question, answered with evidence.** For **each** moving part
   in D, state which case in your matrix would misbehave if that part were
   removed. A part with no case behind it is accretion — that is the owner's
   suspicion and this is the test of it. Be specific about `TEXT_TAIL_FRAMES`,
   the four-field table, and the six-rule ordering.

## Findings you should already know about, so you do not re-derive them

A review earlier today (`../reviews/S29-p9b-design-revalidation.md`, read it)
established, and these are settled — build on them, do not re-litigate:

- D contradicts itself about `seenText`: its State section says never cleared,
  its Channel-ownership section has `keyreleased` clear it. Rule 4 then compares
  against a value no declared field holds.
- D's acceptance gate never closes observably, because `gaugeOnCorrect` calls
  `gaugeNext` synchronously.
- D's stated reason for needing a clock names a pair of cases that *is*
  separable by state. A clock is still needed, but for a different pair — a
  repeat tail versus a deliberate fast re-press of the same character.

Your job is the **conceptual comparison against the game's own history**, which
that review did not attempt.

## Rules

- **Read-only.** No edits except your deliverable. No `git add`, no `git
  commit`, **no `git push`**, no `git checkout --`, no stash, no branch switch.
  `src/examples/*` are separate git repos — read inside them freely (including
  their history), run no git write command there.
- End with `git status --porcelain` and `git diff --stat`; record both.
- **The `lua-lsp` MCP server is available.** Caveat from this session: its
  `references` query does not disambiguate by receiver type, so cross-check with
  grep.
- **Judge the designs, not the people.** No praise, no blame; the owner wants to
  know whether the artifact is sound.
- **"Better" needs a stated criterion.** Whenever you call something better or
  worse, say better *at what* — fewer failure modes, fewer moving parts, easier
  to reason about, closer to the platform's actual guarantees. A preference
  asserted without a criterion is worth nothing here.
- **Report what is.** Evidence is the git command and its output, or file:line.
  If a version's behaviour in a case is genuinely unclear, say so.

## Deliverable

Write to
**`doc/development/wip/77-new-input-api/validation/reviews/S29-p9b-vs-original.md`**,
in the five numbered parts above. Then close with:

1. Is D conceptually better or worse than A, and by which criterion?
2. Which of D's moving parts are earned by a real case, and which are accretion?
3. If you had to state, in one paragraph, the *simplest* rule that handles every
   case in your matrix — not a redesign, just the shape of one — what would it
   be, and which case defeats it?

Your chat reply should be a short digest: the matrix's surprises, the accretion
verdict, and the three closing answers.
