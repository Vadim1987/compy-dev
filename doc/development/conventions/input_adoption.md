---
description: Question-and-action checklist for adopting the input API — applied to the examples, written to be reused for the console and editor
status: active
audience: developer
authored: llm
reviewed: none
---

# Adopting the input API — a review checklist

Operational form of **Decision 32** (`../decisions/input.md`), which states *why*; this states
*what to do*. Written as **question → action** so it can be applied to code without reading the
reasoning first, and so it survives being handed to someone who has not.

Its first use was the example corpus. It is written to be **reused when the console and the editor
are evaluated**, so each rule is marked:

- **[universal]** — true of any code that reads input, framework included;
- **[project surface]** — depends on `compy.input`, so framework-side code must translate the
  intent rather than copy the instruction.

The project-facing version of the same material is `doc/input_api.md`, "Choosing the mechanism".

---

**Q1 [universal] — Does it keep its own copy of held state?** A boolean mirroring a key, a table
of keys currently down, a `*_was_down` companion.
→ **Delete it; ask at the point of use.** A mirror has no reconciliation path: focus loss, a
missed release or an unexpected event order leaves it lying and nothing corrects it. If a project
has a real reason to keep one, that is a decision it states, not a default (Decision 32.5).

**Q2 [universal] — Does it re-implement the left/right fold?** `isDown('lshift','rshift')`,
`is_shift_down()`, `modHeld(a, b)` — any helper meaning "either of the pair".
→ **Call `Key.shift()` / `Key.ctrl()` / `Key.alt()`.** The fold ships already, and a local copy
also hard-codes *which keys are modifiers* — a set that has changed once (Decision 31).

**Q3 [universal] — Does one expression mix `Key.*` with raw `love.keyboard.isDown`?**
→ **Route both through `Key`**: the folded accessors for a modifier, `Key.any_pressed(k)` for any
other key. Two spellings of one question in one line read as two mechanisms.

**Q4 [universal] — Does it answer *"did this just happen"* by polling plus edge detection?** A
per-frame poll with a previous-value companion, deriving a transition.
→ **That is an event.** Use the channel — a hook, or a shortcut if it names a combo. The poll and
its companion both go. Watch for one behaviour change: a bare-key binding matches only when no
modifier is held, where the poll fired regardless.

**Q5 [universal] — Does it answer *"is this held right now"*?** A key cap to light, a modifier
gating a drag, a paddle key.
→ **Poll, and leave it alone.** This is the correct shape, not a rung to climb (Decision 32.4).

**Q6 [universal] — Does it open a state on one channel and close it on the mirrored one with the
same combo?**
→ **Antipattern; replace it** (Decision 32.2). Poll the condition instead, or restructure so the
ending does not depend on a matching event. Note that a modifier's own release has no bindable
combo, so sometimes the closing half cannot be written at all.

**Q7 [universal] — Is physical keyboard state consulted deep inside logic?**
→ **Lift it.** Read the keyboard early — top of the handler, shortcut or `update` — into names
carrying domain meaning, then run the logic on those. Keeps the non-deterministic input visible in
one place instead of scattered through deterministic code.

**Q8 [project surface] — Does one hook demultiplex several orthogonal combos by hand?**
→ **Split into shortcuts, one per combo.** That is what they are for: decomposition, not
capability (Decision 32.1).

**Q9 [project surface] — Is a binding on the release channel?**
→ **Legitimate if it is a choice** (Decision 32.3) — it sidesteps key repeat with no filtering.
Two cautions: `fn.ignore_repeat` does the same job on the press channel, and a *modified* combo
can be missed on release when a modifier comes up first, so prefer release for bare keys.

**Q10 [project surface] — Does it re-implement *"this modifier and none of the others"*?**
→ **For a binding, use the class key** (`'shift+*'`) — it means exactly that, folded over every
modifier the framework knows. **For a query**, spell the exclusion out and accept that it
hard-codes the modifier set; a query primitive that would delegate it is proposed but not built
(`../technical_debt/input.md`).

---

## Rules of restraint

These are not optional, and each was bought with a mistake.

- **Behaviour-preserving, or recorded and deferred.** If a conversion is not obviously
  behaviour-preserving it is not sweep work: record it with its reasoning and leave it to a step
  that can rule on it.
- **A deviation is stated in the workspace** — in a document or a comment — not only in a commit
  message. A commit message is not part of what a reader has open.
- **Purpose beats shape.** Code whose *shape* matches an antipattern may exist for a reason nobody
  wrote down. Ask the author before converting: one example's press-time modifier path looked
  exactly like a hand-rolled cascade and was a deliberate touch-device fallback.
- **Code that demonstrates a path is not a candidate for converting off it.** One example
  deliberately keeps its handlers on the captured `love.*` path because it is the only place that
  path is visible.
- **A narrowing is a change.** Binding what a poll used to answer generally — a bare key, an
  exclusive class — silently stops firing in cases that used to work, and it is invisible in the
  diff that introduces it. Say it, or do not do it.
