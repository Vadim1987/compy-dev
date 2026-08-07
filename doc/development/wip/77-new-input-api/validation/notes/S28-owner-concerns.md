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
