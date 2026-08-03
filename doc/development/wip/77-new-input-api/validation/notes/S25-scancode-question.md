---
description: Owner's question — should combo registration and dispatch key on scancode rather than the literal character? Answer, with what it would cost and what it would not fix
status: active
audience: developer
authored: llm
reviewed: none
---

# S25 · scancodes for combo registration and dispatch?

Owner, 2026-08-03, raised while ruling the C1 echo guard. Two questions are
tangled in it; they have different answers.

## As a fix for the C1 echo — no

`textinput` carries **no scancode**. LÖVE's signature is
`love.textinput(text)` — one string, the character actually produced after
layout, modifiers and IME. `keypressed`/`keyreleased` carry
`(key, scancode)`; the text channel has nothing to key on but the character
itself.

So scancodes cannot unify the two channels. They would widen the gap: the
`keypressed` side would be keyed by physical position while the `textinput`
side stays keyed by a produced character, and the paired-shortcut idiom would
have to bridge *two* vocabularies instead of one. The case mismatch that
limits the idiom today (`shift+i` vs `shift+I`) is a normalisation bug on the
character side, and no scancode change touches it.

## As a question about the shortcuts surface — real, but separate

"Should a combo mean a physical key position or a labelled key?" is a genuine
design question, and the honest answer is that **compy has both audiences**:

- **Positional** bindings — a game's WASD — want scancode. On AZERTY, `w`
  bound by key name lands under the player's little finger.
- **Mnemonic** bindings — `ctrl+s` for save, turtle's `i` for input — want the
  key *name*. The user's keycap says S; following the letter is the point.

LÖVE's own guidance splits exactly this way, which is why it exposes both.
A swap would therefore fix one audience by breaking the other. If this is ever
worth doing it is **additive** — a second registration vocabulary
(`shortcuts.scancode.*`, or a `sc:` prefix inside the combo string) — not a
change to what an existing combo means.

## What it would cost

Not free, and more than it looks:

- **The scancode is discarded at the gateway today.** `controller.lua`,
  `set_love_keypressed`: `local function keypressed(k, _, isr)`. It reaches
  neither `forward_keypressed`, nor the routes, nor
  `ProjectInputController:_dispatch`. Every seam between the gateway and the
  chain would need it threaded through.
- **`Controller.keys_pressed` is keyed by key name**, and `combo_string`
  builds its modifier prefixes from that set (`keys_pressed['lctrl']` …). A
  scancode combo needs a scancode-keyed held set, or the combo becomes a
  hybrid — modifiers by name, trigger by position.
- **Decision 8's combo vocabulary is ratified and documented**, and is the
  exact surface this PR asks stakeholders to review. Changing what a combo
  string means is a breaking, user-visible change to the thing under review.

## Recommendation

**Not now, and never as a swap.** No layout complaint exists in the record —
this is a hypothesis about non-QWERTY users, not a report from one — and the
strategic frame for this PR asks whether a change makes the system more
predictable or merely more elaborate. A second vocabulary is more elaborate;
it earns its place when a positional-binding consumer actually appears.

If the owner wants it carried, the persistent home is
`technical_debt/input.md` → *Open decisions*, phrased as "combo triggers are
key-name-only; positional bindings have no vocabulary", with the revisit
condition "a project needs layout-independent positional keys". Say the word
and it goes in; it is not there yet, because nothing has been ruled.
