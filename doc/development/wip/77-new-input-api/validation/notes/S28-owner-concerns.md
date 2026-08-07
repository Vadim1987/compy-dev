# S28 — owner concerns raised in session

Concerns the owner raised in chat during session28, parked here so the phase
that acts on them does not have to reconstruct them from the transcript. Each
names the id or artifact it attaches to.

---

## R081 — the correction must not repeat "except shortcuts" (owner, 2026-08-07)

**Where R081 stands.** `doc/development/decisions/input.md:120`, Decision 2's
"one chain of three components" framing. The owner's remark: *"now its more than
three components, we are sending pointer events the same way!"* Cold review
promoted it W10 → W9 and S4 → S3 (a permanent doc stating something false about
routing, not a wording preference).

**The concern.** The triage's own justification for the promotion reads
"pointer runs the *same* `dispatch` **minus the shortcuts tier**". The owner
believes that qualifier is itself now stale: session27 (Decision 27, commits
`5d144f37` + `1a414dbb`) gave pointer channels a shortcuts tier —
`shortcuts.mousepressed['mouse2']` is a right-click. If so, the R081 fix must
correct **two** things, not one:

1. the "three components" scope, which excludes pointer from the chain shape; and
2. any "pointer has no shortcuts" claim — in the doc *and* in the triage's own
   rationale — which after Decision 27 is false in the same way.

**Status:** to verify when P10/W9 reaches R081. Owner explicitly said not to dig
now. The check is cheap: Decision 27's entry in the ledger vs. the combo-table
provisioning in `projectInputController.lua`, then grep the permanent docs for
"shortcut" claims scoped to keyboard.

**No third correction after all.** For one commit (`8fbcba21`) the widget tier
honoured an explicit `false` as a decline, which would have made Decision 2's
"shownness, not the return value" claim conditional. The owner rejected the
mechanism and `811849e2` removed it: shownness decides, one rule, every channel.
That sentence stays true and R081's fix has two corrections, not three.

---

## KISS/DRY — no invented special cases (owner, 2026-08-07)

Standing instruction given while rejecting the decline mechanism above: *"I am
actively against hallucinated special cases (KISS and DRY principles must be
honored)"*. The minimum that satisfies the requirement is the answer; a second
rule that solves nothing the system actually suffers from is a defect, even
when it is small and even when it reads as principled. Written into
`agents/rules.md`.

---

## Are the keyboard fix and the turtle echo guard two answers to one problem? (owner, 2026-08-07)

**No — same root fact, two different questions. Checked before answering.**

The **root fact** both live on: one physical key produces a `keypressed` **and**
a `textinput`, in no guaranteed order (`doc/input_api.md`, "Opening the overlay
from a key"; `internals/user_input.md`, "Data flow").

**The echo guard** (`doc/input_api.md`; used by `examples/turtle`) answers: *a
known key opens a widget — keep that key's glyph out of the field.* It
**pre-arms** a one-shot `shortcuts.textinput['i']` that consumes the glyph and
unregisters itself. Pre-arming is what makes it order-independent: the one-shot
is already in place whichever side of the open the glyph lands on. It works
because the key is known in advance and because the right outcome is to
**discard** the glyph.

**The keyboard's Alt-keys scene** (`3a9d48c`) answers a different question:
*any printable key may be the target, the glyph must be **accepted** — it is
the gameplay input — and only its repeats dropped.* The echo idiom cannot be
borrowed for it on three counts: the key is not known ahead of time, so there is
nothing to pre-arm; the one-shot discards where this must deliver; and arming on
the keypress instead would reintroduce the order dependency the guard avoids by
pre-arming (the keyboard's own header had already reasoned that out, and then
solved it with the held set, which is the part that was wrong). `fn.ignore_repeat`
is no help either — it reads `isrepeat`, which only `keypressed` carries, and
the scene must judge the produced glyph, not the physical key, since Shift
changes what is produced.

So the claim-per-press fix is not a second solution to the echo problem; the two
idioms do not overlap and neither can be expressed as the other.

**Worth doing in P10 (docs), not now:** `doc/input_api.md` states the root fact
inside the echo-guard section, as if it were a fact about opening a widget. It
is a fact about the two channels, and a project hitting the *other* question has
no signpost. State it once in its own right, then show the echo guard as one
consequence — and if a second worked example is ever wanted, "accept the first
glyph, drop the repeats" is the natural companion. **No platform helper for
it:** one example's need is not an API (`agents/rules.md`, "No invented special
cases").
