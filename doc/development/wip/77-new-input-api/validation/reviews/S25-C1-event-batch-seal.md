---
description: C1 settled — the owner ruled the event-batch seal out of the tree; what was reverted, what was verified in code, and the option set a design pass inherits
status: active
audience: developer
authored: llm
reviewed: none
---

# S25 · C1 — the event-batch seal, reverted

Supersedes C1 of [`S24-contradictions.md`](S24-contradictions.md), which left
the question open for this session. The race it addresses is unaffected: it
was verified independently of the fix and now lives in the persistent corpus
as [`technical_debt/input.md`](../../../../technical_debt/input.md), *"An overlay
opened from a key can receive that key's own echo"*.

## The ruling (owner, 2026-08-01)

> *"I specifically request reverting any relevant codebase/doc changes except
> the tests that surface the problem. if needed, these reversed changes could
> be stored in wip workspace as suggested patch (literally a diff file)."*

Given before any recommendation was presented, i.e. the mechanism is out on
the ratification ground alone — not because a better one was chosen.

## What was executed — `190f0c9`

| Surface | Disposition |
|---|---|
| `src/controller/controller.lua` | `end_event_batch()`, its `update` call, `dispatching_input`, the three gateway assignments — **removed** |
| `src/controller/userInputController.lua` | the seal armed in `open_fresh`, `:unseal()`, the three `if self.sealed then return end` guards — **removed** |
| `doc/development/decisions/input.md` | Decision 19 — **removed** (the ledger now ends at 18) |
| `doc/input_api.md` | the "key that opens the overlay never lands in it" paragraph — **removed** |
| `doc/development/internals/examples/turtle.md` | the clause separating the guard's job from the seal's — **reverted** |
| `tests/input/input_widget_lifecycle_spec.lua` | 2 rows **kept as `pending`**, 1 removed (see below) |
| `doc/development/technical_debt/input.md` | the race **added** as an open-decision entry with four candidate mechanisms |

**Proof of completeness**, not assertion: after the revert the five
non-test files are **byte-identical to `eadcc8cd`**, the commit immediately
before the seal landed (`git diff eadcc8cd -- <the five>` is empty), and a
tree-wide grep for `Decision 19` / `sealed` / `unseal` / `dispatching_input`
over `src/` and the persistent corpus returns nothing. C1's revert table was
accurate and complete.

Suite **874 → 871 / 0 / 0 / 5**.

### Why one test row left with the mechanism

The group held three rows. Two reproduce the **defect** — a
`keypressed`-opened overlay typing its own trigger, and the same batch with
the `textinput` delivered last — and they stay, as `pending`, citing the debt
entry. The third, *"accepts input from the next frame on"*, pinned the
**seal's own lifetime** (release at `love.update`): it asserts a property of
mechanism (a), not the contract, and would presuppose an unmade decision if
left standing. It is preserved verbatim in the patch below.

The two pending rows name a contract the tree does not meet. Flipping either
back to a live `it` is one edit once a mechanism is ruled; leaving them live
and red was not an option, since suite-green-at-every-commit is a standing
constraint of this phase.

## Verified in code while settling this

Four claims from the original commit and from C1 were checked rather than
carried forward. Two survive; two are corrected.

1. **"Release at `love.update` is the batch boundary" — TRUE, and stronger
   than argued.** The commit justified it by stock LÖVE's `love.run`. compy
   does not use stock `love.run`: `src/harmony/init.lua:104` replaces it with
   `harmonius_run`, whose loop is `pump()` → poll **all** queued events →
   `love.update(dt)` → draw (`:47-98`). So the boundary is a property of the
   loop **this project ships and owns**, not an inherited assumption.

2. **"It silently assumes no other pump" — over-cautious.** The only other
   pump in the tree is the crash explorer's loop
   (`src/lib/error_explorer.lua:651-676`). It dispatches its own `keypressed`
   directly and never reaches `love.handlers` or the controller, so it can
   neither arm a seal nor strand one.

3. **"No project can fix this for itself" — TOO STRONG.** A project cannot
   *consume* the echo (it cannot derive the text from the key name: `space` →
   `" "`, `shift+i` → `"I"`, IME output). It can, however, *undo* it — call
   `compy.input.clear()` on the first `update` after opening, or `set_text`
   back to the intended prefill. That is a wart every such project repeats,
   and it flickers for one frame, but it exists. Option (d) below is therefore
   viable-but-ugly, not impossible.

4. **The race itself — unaffected by the revert.** Verified in session24 with
   evidence independent of the fix (open on `keypressed('i')` → the field
   comes up containing `i`; open on `keyreleased` with the `textinput`
   delivered last → identical). Nothing here reopens that.

## The three choices that were mine, not ruled

Restated so the design pass starts from the actual decision surface rather
than from the implementation:

1. **Scope** — seal the whole *event batch* rather than matching the trigger
   key's echo. Order-independent and needs no key→text mapping; also swallows
   an unrelated key typed inside the same frame.
2. **Lifetime** — release at the start of `love.update`. Correct for the
   shipping loop (verified above); it is a promise about the loop, which is a
   thing the framework has to be willing to make.
3. **Exclusions** — only overlays shown *from inside a keyboard/text event*
   seal; `update`-time and pointer-time shows stay live at once.

None of the three is forced by the defect. That is what made the landing a
breach rather than a judgment call.

## Option set for the design pass

The persistent record ([`technical_debt/input.md`](../../../../technical_debt/input.md))
carries (a)–(d). Two more are named here because they came out of this
review, and the ledger entry stays deliberately short.

- **(a) Batch seal** — what was implemented. One rule, no mapping,
  order-independent. Cost: an unrelated key typed under ~17 ms after the
  opening one is swallowed.
- **(a′) At most one `textinput` per batch** — strictly narrower than (a),
  same no-mapping property. New failure mode: when the trigger key emits no
  `textinput` at all (`f1`, a bare modifier), the seal eats the *next* key's
  text instead. Buys a rare edge case for extra state plus a new edge case.
- **(b) Key-matched seal** — narrowest, but needs exactly the key→text
  mapping (a) exists to avoid.
- **(c) Arm only on `keypressed`** — leaves open-on-`keyreleased` projects
  racing, which is what `examples/turtle` does. Does not solve the reported
  case.
- **(d) No framework change, documented idiom** — viable per finding 3
  above: clear or re-set the field on the first `update` after opening. Every
  project that opens an overlay from a key repeats it, and it flickers.
- **(e) Deferred show** — `show()` called from inside a key event takes
  effect *at the batch boundary* instead of showing-and-sealing. One rule and
  one state instead of two, and it removes the "shown but deaf" condition
  that made consumption reporting need a paragraph of explanation. Cost:
  `compy.input.is_shown()` returns `false` immediately after `show()` within
  the same event, and the overlay is not painted for that frame.

**Recommendation, for whenever the design pass happens: (a), ratified
explicitly** — smallest mechanism, and its one cost is a keystroke inside the
same 17 ms frame. If the owner would rather not have a shown-but-deaf widget
at all, **(e)** is the coherent alternative and should be weighed against the
`is_shown()` surprise it introduces. **(c)** is out on the evidence; **(b)**
buys precision with the mapping the whole design avoids; **(d)** is the
do-nothing baseline and should be priced as such, not dismissed.

## The suggested patch

[`../notes/S25-C1-event-batch-seal.patch`](../notes/S25-C1-event-batch-seal.patch)
— the mechanism exactly as it stood at `6842683`, before the "unratified"
markings were added.

```
git apply doc/development/wip/77-new-input-api/validation/notes/S25-C1-event-batch-seal.patch
```

Verified to apply cleanly at `190f0c9`. Six files: the two controllers, the
ledger entry, the guide paragraph, the turtle clause, and the full
three-row test group (which replaces the two pending rows).

It does **not** touch `technical_debt/input.md` — re-applying the mechanism
means that entry becomes resolved rather than open, and how it is worded then
depends on which option is ratified. That is a ruling, not a patch hunk.
