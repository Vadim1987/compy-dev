---
description: Standing design stance for #77 input handlers — pass the full key-state to every handler and give modifiers NO privileged semantics in the primitive; combo strings are a convenience layer, not the foundation
status: active
audience: design
---
# Handlers carry full key-state; modifiers get no special meaning

**Stance (stakeholder/human, held from the outset of #77).** The foundational dispatch contract is:
**every handler receives the complete set of currently-pressed keys, and modifiers (`ctrl`/`shift`/
`alt`/`gui`) are ordinary members of that set — not a privileged, pre-interpreted layer.** The handler
decides what a key combination *means*; the framework does not pre-chew modifiers into semantics before
the handler sees them.

## Why it's the right primitive

- **No information loss.** `keys_pressed` retains precise LÖVE key names (incl. `lctrl`/`rctrl` etc.);
  the handler can distinguish left/right, see every held key, and judge any combination it wants. A
  modifier-privileged primitive throws away exactly the cases the privileging didn't anticipate.
- **Combo strings are sugar, not source-of-truth.** The `"ctrl+s"` serialisation (modifier-first,
  l/r-folded) and `compy.input.handlers[combo]` are a **convenience layer on top of** the full state —
  a registration shortcut for the common case. They must not become the *only* way to read input, and
  they must not replace the full-state argument flowing to every handler. (Design already reflects this:
  `keys_pressed` keeps precise names; only combo *serialisation* folds — see `design/design.md §3`,
  `design/spec.md §"on_key_pressed"`.)
- **Extensibility.** Glob/prefix matchers, chord grammars, per-project schemes are all expressible *above*
  a full-fidelity primitive; none are expressible if the primitive has already collapsed modifiers.

## The recurring drift to resist (note to future design sessions, incl. LLM agents)

Across #77's design, the LLM counterpart **repeatedly leaned toward giving modifiers special
interpretation** — treating `ctrl`/`shift`/`alt` as a distinct, pre-resolved concept rather than as
plain keys in the pressed-set. The human repeatedly pulled it back to: *pass the full state; let the
handler interpret.* If a proposal starts by special-casing modifiers in the dispatch primitive (vs. in
an optional convenience layer), that is the drift — check it against this stance before adopting.

## Bearing on open questions

- Reinforces the combo-tier repeat-semantics default (E20/E9): the primitive stays full-fidelity
  (`keys_pressed` + `isrepeat` visible at `on_key_pressed`); the convenience tier (`handlers[combo]`)
  fires once. Convenience layers add ergonomics without amputating the primitive.
- Relevant to **A6** (combo serialize-vs-match, decide before M5): A6 is a *convenience-layer* decision,
  and must not be allowed to redefine the underlying full-state contract.
