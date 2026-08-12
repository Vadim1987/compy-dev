# Prompt of record — P-18-00 part 1: the cold adoption inventory

**Commissioned:** 2026-08-12, session37, by the owner. **Model: Opus, passed explicitly.**
**Mode: read-only research.** The agent writes exactly one file and changes nothing else.

**HARD SAFETY RULE:** do not `checkout`, `switch`, `stash`, `merge`, `reset` or otherwise touch the
working tree of **any** repository, here or in the nested example repos. Both this repo and
`src/examples/keyboard` are mid-work on live branches, and moving either would destroy work. Read
history with `git show` / `git grep` against a ref, which needs no checkout.

**Why cold:** this branch has already migrated the example once. That work must not anchor the
answer. The question is *"what would we do if none of it had happened"*, so the agent works from
**upstream** and from the platform's current API, and is told nothing about what landed.

---

## Your task

`src/examples/keyboard` is a LÖVE2D game (a separate repository, nested inside this one) that runs
as a project on the Compy platform. Its **upstream** state is the git ref
**`origin/dsent/dev`** inside `/repo/src/examples/keyboard`.

**Produce an inventory of everything in that upstream code that should change to adopt the Compy
input API as it now stands** — a fresh list, as if no adoption work had ever been done.

**Read the upstream ref, not the working tree.** The working tree contains later changes that would
anchor you, and reading them would defeat the purpose of this commission. Use
`git -C /repo/src/examples/keyboard show origin/dsent/dev:<file>` and
`git -C /repo/src/examples/keyboard grep <pattern> origin/dsent/dev -- <paths>`. **Do not** read
`input.lua`, `alt.lua`, `help.lua` or `main.lua` from the working tree, and do not read this repo's
`git log`, `doc/development/wip/77-new-input-api/**` (except what this prompt names), or any session
track.

### What to read first

- **`doc/input_api.md`** — the project-author guide to `compy.input`: hooks, shortcuts, combos and
  classes, the `fn.*` combinators, the overlay, and the "Held keys" ladder.
- **`doc/development/conventions/input_adoption.md`** — the question→action checklist for adopting
  this API, marked universal vs project-surface, plus its rules of restraint. **This is the
  operative guide for your judgement; follow it.**
- **`doc/development/decisions/input.md`** — the decision ledger, for *why* the API is shaped as it
  is. Decisions 21 (one trigger per combo), 30/31 (the framework tracks no held keys; the modifier
  set is ctrl/alt/shift) and 32 (how the API is meant to be used) matter most.
- **`doc/development/internals/user_input.md`** — cross-component behaviour, including the "Data
  flow" section on channel ordering.

Then read the upstream game: `input.lua` and `main.lua` first (its whole event model lives there),
then every file that touches input — `git grep -nE "love\.(keyboard|mouse|textinput|keypressed|keyreleased)|INPUT\.|keypressed|keyreleased|textinput|isDown" origin/dsent/dev -- '*.lua'`.

### Hard constraints on your recommendations

1. **Never change the game's rules.** What a player experiences is the author's and is out of
   scope: the test is *"would a player notice a difference?"* If yes, it is a rule change — do not
   recommend it, however well-motivated. You are changing **how** behaviour is produced, never
   **what** it is. If you believe a rule is itself wrong, say so in a separate "not recommended,
   raised for the owner" list.
2. **Minimise the change.** Prefer the smallest edit that adopts the mechanism. Do not restructure,
   rename, or tidy. Keep the project's own names and vocabulary; do not introduce yours.
3. **Soft preference, not a requirement:** where two adoptions are otherwise equal, the one that
   leaves the game working as a plain LÖVE program is mildly preferable. **Nobody has asked for
   standalone-ness** — it was invented in-session as a tie-breaker for one call and is recorded here
   at that weight. Never trade a clearer adoption for it, and do not let it shape the inventory.
4. **Verify in code.** Every claim names a file and a line at the upstream ref. Do not infer
   behaviour from comments — the comments are the author's claims, and at least one of them
   describes a platform that has since changed.
5. **State what you could not determine.** This container cannot inject keystrokes and has no
   device; anything needing a human is listed as owed, not guessed.

### The one design decision already taken, which you must build on rather than re-derive

Upstream judges typed characters with `inputStale()`, which reads `INPUT.held[k]` — state owned by
the **`love.keypressed`** channel — from inside a **`love.textinput`** handler. That is only correct
if `textinput` is delivered before its own `keypressed`, which LÖVE does not guarantee; under the
other order the first character of every press is discarded and the game is deaf.

**The chosen fix, which is settled — do not redesign it:** keep the project's existing claim
machinery (`GLYPH_CLAIMED`, `spendGlyph`) and change only **how a claim is released**. A character
claims its key when it is delivered to a scene; the claim is released **by polling the device** —
once per frame, any claimed key that `love.keyboard.isDown` reports up is unclaimed. `INPUT.upRecent`,
`INPUT_UP_GRACE` and the release-handler's claim bookkeeping all go. Nothing consults the other
channel, and nothing consults a clock.

Two consequences you should apply, not question:

- **Whoever consumes a chord claims its trigger key**, without judging it — otherwise a chord's
  trigger, still held after its modifier is released, produces characters that reach the scene as a
  typed answer.
- **`love.keyboard.isDown` is kept in the game rather than `Key.any_pressed`**, so the mechanism
  stays portable to the standalone program; a comment points at the platform's form.

**Where your judgement IS wanted on this:** every *other* place in the upstream game where the same
class of assumption appears — one channel's state consulted from another, an event mirrored into a
table, a clock standing in for a device read — and what the API now offers instead.

### What the deliverable must contain

Write to **`/repo/doc/development/wip/77-new-input-api/validation/outcomes/P-18-00-adoption-inventory.md`**.
**Create it in your first minutes with the headings filled in and update it as you go** — a prior
worker died mid-review holding a full pass of findings and nothing on disk.

1. **A per-site inventory**, ordered by file. Each entry: the upstream `file:line`, what the code
   does, which API mechanism replaces it (hook / shortcut / combo class / `fn.*` combinator / `Key`
   query / poll / nothing), the smallest edit that achieves it, and a one-line rationale citing the
   checklist or the guide.
2. **A separate list of platform gaps the example worked around** — places where the code
   compensates for something the platform did not offer. For each: is the gap now closed by the
   API, and if so by what. (The file's own header names several; treat them as claims to verify.)
3. **A "leave alone" list with reasons** — everything you considered and rejected, including
   anything that looks convertible but is load-bearing as written. This list matters as much as the
   first: a previous conversion of another example was mechanically faithful and destroyed the
   feature's purpose, and was reverted.
4. **A "raised, not recommended" list** — rule changes, restructurings, and anything needing the
   author's word.
5. **An ordering proposal**: which edits are independent, which must follow others, and which are
   risky enough to want a human smoke pass.
6. **Confidence and limits**, per §5 above.

### Reporting

Your final chat message is lost when context rolls; **the file is the deliverable**. Finish with a
short digest naming the counts per list and the three findings you would not want missed.

## Tooling notes

- **MCP-LSP is available** (`lua-lsp`): definitions, references, diagnostics over a real AST of the
  `/repo` workspace. Use grep to find candidates and the LSP to resolve a symbol or prove who calls
  it. Note it indexes the **working tree**, not the upstream ref — so use it for *platform* symbols
  (`Key`, `compy.input`), and plain `git show`/`git grep` for the game. After any `.lua` edit
  (you should make none), `sleep 1` before querying it.
- Grep is the completeness backstop: this game dispatches through a metatable `__index` on string
  keys, which the LSP does not see.
