# Prompt 13 — Cold review of the contract correction (prompt12 output)

**Target executor: Claude Opus.** Independent review, **reviewer-not-co-author.** A
fresh pass: you did not write the correction, and you must not have been told its
author's reasoning. Paths relative to repo root.

---

## Charter

prompt12 corrected `notes/input-contracts.md` (§2/§3/§4 + pointer rows) and
`design/spec/M4-0-03-contract-suite.md` to remove a **mechanism-as-contract** drift
(keyboard routing keyed on widget presence; pointer routing as inter-route BOTH — both
were today's implementation mistaken for the invariant). **Your single job: verify the
correction is *unbiased* — that it states intent, not implementation, with sound
provenance — and catch any residue.** Confirming it because it reads well would defeat
the review.

---

## Read first

1. `notes/intent-fidelity-audit.md` — intent ground truth.
2. `notes/input-contracts-correction.md` — the provenance ledger prompt12 produced.
3. The corrected `notes/input-contracts.md` (§2/§3/§4) and
   `design/spec/M4-0-03-contract-suite.md` — read the **change** via `git show` / `diff`.
4. `agents/rules.md` — tone.

---

## Tests to apply (report Pass / Fail each, with evidence)

1. **Provenance gate held.** EVERY PRESERVE routing row cites a tier-1/2 mandate or the
   ratified mode-exclusivity principle. Flag any PRESERVE row that asserts **observed**
   behaviour with no mandate (the original disease).
2. **No mechanism-as-contract residue.** No row keyed on widget presence; no inter-route
   keyboard-vs-pointer asymmetry; no current-code behaviour promoted to invariant.
3. **Pointer collapse is principled.** Pointer routing stated as inter-route exclusive
   (active route); intra-route forwarding noted as the route's concern — not as dispatch
   BOTH.
4. **Honesty of the principle's provenance.** The inter-route exclusivity rule is labeled
   a **ratified design rule** (mode-exclusivity + endorsed topology), NOT a stakeholder
   mandate; intent-silence is marked where it exists.
5. **No over-reach.** The correction touched only the drifted rows; rows the audit found
   **Faithful** (Phase 2) are unchanged; `design.md` is not contradicted.
6. **Open rulings preserved.** inspect (§3.4) and combo-repeat (D-C) left provisional /
   `OWNER RULING PENDING`, not invented.

---

## Output

Write `reviews/input-contracts-correction.md`: per-test verdict + evidence; an overall
**Approve / Revise**; any residual drift as a **specific, owner-actionable** item.
Findings only — do **not** edit the chain. Read-only git; **no subagents**; no GitHub.
