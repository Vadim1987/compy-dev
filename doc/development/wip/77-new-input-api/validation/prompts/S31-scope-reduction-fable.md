# S31 — Fable consultation #2: is the surface justified by the bug it fixes?

**Prompt of record** (hygiene c). Spawned 2026-08-09, session31, model **Fable**,
explicitly passed. This is the pre-registered escalation: the evidence census
showed thin net adoption impact, and the owner has asked whether the right move is
to **reduce feature scope** rather than fix every release blocker. Deliverable:
`doc/development/wip/77-new-input-api/validation/reviews/S31-scope-reduction-fable.md`.

---

You are consulting on a LÖVE2D/Lua project at `/repo` (branch
`feature/77-newapi-analysis-s20260615`, PR base `3256aac`). **Read-only.** You are
not implementing. Your predecessor consultation (`validation/reviews/S31-boundary-challenge-fable.md`
— read it) established that the shipped surface is forward-compatible. That is
settled. **This is the different and harder question: is it *justified*?**

## The motivating bug (owner's attestation, corroborated in the corpus)

Read `validation/notes/S31-owner-attestation-where-we-are.md` in full first.

Before the feature, a project-activated **user input widget was modal**: once
shown it **consumed keyboard events wholesale**, so **no modifier combo could
reach the project**; the project could only **poll** the text; and lifecycle
control was limited to self-closing on one-shot input.

`doc/development/decisions/input.md:73` records the same defect, and **Decision 1**
(routing is route-centric, not widget-centric) is stated at `:95` as **"the single
structural change the subsystem exists for."**

The owner considers the fix a genuine **platform win**. Their open question is
whether the *result* is **adoptable and appropriate**, and whether the right move
now is to **reduce scope** rather than clear every blocker.

Their blocker accounting: **only one keyboard subgame was actually broken**
(the "alt" subgame in `src/examples/keyboard`, relying on `keypressed`/`textinput`
delivery order). The other blockers were **readability of the change** and
**catching up with advancing upstreams** — not functional defects.

## The hypothesis you must test

> **The motivating bug is fixable with far less surface than was built.** Making
> the widget a chain *terminal* instead of a gateway *diverter* (Decision 1) is
> sufficient on its own: once the widget stops swallowing, a project's existing
> `love.keypressed` fires, and it can read modifiers with the pre-existing
> `Key.ctrl/alt/shift()` exactly as it always did. On that reading,
> `compy.input.hooks`, `compy.input.shortcuts` + combo strings, and
> `compy.input.keys_pressed` are **ergonomics layered on top of the fix**, not
> the fix — motivated by a separate structural goal ("stop `if Key.shift()`
> cascades sprawling"), which the owner has already ruled does **not** decide the
> event-vs-poll source question.

**Test it, do not assume it.** Establish in code what the minimum change set for
the modal-widget bug actually is, and what each additional layer buys. Specifically:

1. Is Decision 1 alone sufficient for combos to reach a project while the widget
   is shown? Trace it. If not, what is the true minimum?
2. What does `compy.input.shortcuts` + combo strings buy **that the minimum does
   not**? Is it necessary for any *shipped* behaviour, or is it ergonomics?
3. What does `compy.input.keys_pressed` buy? Note `src/examples/keyboard/input.lua:47`
   reads it **from draw**, and that the example previously maintained its own
   mirror — so this is a simplification, but is it a *necessity*?
4. The lifecycle controls/callbacks on input solicitation are part of the owner's
   stated win. Which parts of the surface are those, and are they separable from
   the rest?

## The evidence you must weigh

Read `validation/outcomes/S31-example-adoption-impact.md` (the per-example census).
Its scorecard, on the owner's own metric — *net adoption impact across examples
characterises the feature's quality*:

- **Positive:** keyboard (−19 lines; adoption was **not forced**), guess (−14),
  repl, tixy, maze *if finished*.
- **Overhead (~0 net):** paint, sapper, valid, balloons.
- **Negative:** turtle — **+13 lines on a 58-line beginner example**.
- **Correctly do-not-adopt:** pong. `life` and `paint` have **no API equivalent**
  for what they need (`keys_pressed` is keyboard-only).

Three further verified facts:

- **`turtle` and `maze` change behaviour on this branch** (turtle: Space typed
  into its prompt toggles a debug overlay; maze: Shift+Escape while typing quits
  the app). The session's current reading is that these are **not accidental
  regressions but the intended effect of Decision 1** — both examples were written
  *against* the modal bug. **Judge that reading.** If it is right, it changes how
  they are counted; if it is rationalisation, say so.
- **`compy.singleclick`/`doubleclick` were a project API at base and are retired.**
  In-tree examples were migrated; **out-of-tree student projects fail silently** —
  the assignment lands on the namespace and nothing reads it. No diagnostic.
- **`textinput` carries no `isrepeat`** (`projectInputController.lua:51`;
  LÖVE's `love.textinput(t)` has none to pass through). So the keyboard example
  must **keep** `spendGlyph`/`GLYPH_CLAIMED`/`upRecent`/`INPUT_UP_GRACE` (~20
  lines) even after full adoption — the claim that adoption subtracts that
  machinery is false.

## What to deliver

A **recommendation with a spine**, not a survey. Specifically:

1. **Is the built surface justified by the bug it fixes?** Yes / no / partly —
   and if partly, *which parts*.
2. **If scope should be reduced, what exactly is cut, and what does cutting cost?**
   Unpicking is not free: the branch has ~30 sessions of work, the examples are
   already migrated, and reverting has its own risk. Quantify roughly. A
   scope reduction that costs more than shipping is not a reduction.
3. **What is the minimum shippable feature** that (a) fixes the modal-widget bug,
   (b) fixes the one broken keyboard subgame, and (c) leaves the examples no worse
   than base?
4. **Name the strongest argument against your own recommendation.**

Consider seriously that **shipping the built surface may be correct** — thin
adoption impact is not the same as negative impact, and an API can be justified by
the bug it fixes plus one strong adopter. Do not reach for the dramatic answer.
Equally, do not flinch from recommending a cut if the evidence supports it.

## Tools and discipline

- The **`lua-lsp` MCP server**: defs / refs / diagnostics over a real AST of
  `/repo`. Grep for candidates, LSP to resolve a concrete symbol and to answer
  "who calls this". Lua is dynamic — LSP refs can be **incomplete**; cross-check
  with grep, trust neither alone.
- `git show 3256aac:<file>` reads the PR base. Every "pre-existing" claim is
  checked that way. It has overturned conclusions in six consecutive sessions.
- `busted tests` → 955 / 0 / 0 / 3. The nested example repos (`keyboard`, `maze`,
  `balloons`) have **no suite**; reasoning about them is unproven by construction
  and must be marked as such.
- `doc/development/wip/77-new-input-api/design/` is **frozen** — read, never edit.
- Verify before asserting; mark inference as inference.

Write the deliverable to
`doc/development/wip/77-new-input-api/validation/reviews/S31-scope-reduction-fable.md`.
The file **is** the deliverable — your final chat message is discarded.
