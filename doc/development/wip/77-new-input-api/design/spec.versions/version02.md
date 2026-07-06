# spec — version 02 (E29 re-derivation)

_LLM(Claude Fable 5): 2026-07-05 (E29 Stage 2, session33); Approved by human?: NOT YET;_

> **Latest version → references up to canonical.** Per doc-format §6/§6.1, the single latest
> version file points up to the canonical doc; only non-latest versions are frozen full
> snapshots ([`version01.md`](version01.md) holds the frozen pre-E29 contract).
>
> **What changed vs. version01.** Contract rebuilt on the Gate-1 ratified chain: §3's
> default-is-the-sink/replace-semantics removed; four tiers with per-event combo tables on
> all three keyboard/text channels; `on_text_input` (per-char chain callback) split from
> `on_text_entered` (widget output, submit-time); widget-outputs surface specified; legacy
> natives = pure wrap; PIC occupancy narrowed to `'running'` (keyboard/text slots only);
> mutable-boundary rule; claims-diff + deviations sections added; per-milestone slice index
> marked superseded pending the Stage-3 re-cut.

Canonical content: [`../spec.md`](../spec.md).
