# estimates — version 03 (E11 recalc: M5 split + M6-02 before_exit)

_LLM(Claude Sonnet 4.6): 2026-06-24 (E11, session 23); Approved by human?: NOT YET;_

> **Latest version → references up to canonical.** Per
> [`doc-format.md`](/var/lib/brainlab/current/rules/doc-format.md) §6/§6.1, the single
> latest version file points up to the canonical doc (it *is* canonical at this moment);
> only non-latest versions are frozen full snapshots
> ([`version02.md`](version02.md) and [`version01.md`](version01.md) hold the frozen
> prior snapshots).
>
> **What changed vs. version02.** Two changes to the milestone set:
> **(1) M5 split** — M5 (Three-level dispatch) is replaced by **M5a** (callbacks:
> `on_key_pressed` / `on_text_entered` / `framework_handlers` slot; ships next after M4)
> and **M5b** (handlers sugar: `handlers[combo]` + normalisation + `__matcher` seam +
> return-propagate dispatch; **deferred** after M6/M7 or concurrent). Same surface area;
> commissioning overhead is negligible (+0.1 h no-LLM / +0.2 h LLM). Rationale: no
> current project uses combo handlers; `on_key_pressed` gives projects all the raw
> material to implement combos manually; deferring M5b keeps M6/M7/M8 on the critical
> path without waiting for the dispatch table. Spec: `design/spec/M5-01-split.md`.
> **(2) M6-02** — `compy.before_exit` project-stop hook added as a small adjacent slice
> in the M6-family named-hook infrastructure (+2.0 h no-LLM / +1.2 h LLM). keyboard is
> the canonical consumer (T3 device-state restore on exit). Spec: `design/spec/M6-02-before-exit.md`.
>
> **Total at this baseline:** ≈ 76 h (without LLM) / ≈ 45 h (with LLM) —
> **+≈ 2 h / +≈ 1 h** vs. version02 (≈ 74 h / ≈ 44 h).
>
> **Current content:** see [`../estimates.md`](../estimates.md).
>
> When `estimates.md` is next recalculated (E11), **freeze this file's content to the
> then-current canonical snapshot** before minting `version04.md` (demote-by-freezing,
> §6.1), and append the new total as a line to the roadmap's total-estimated log. The
> frozen design-phase total is never touched.
