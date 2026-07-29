# S22 Sol consultation — ruling order before TF2

Assess whether #77 should rule as much of the currently visible ledger
as possible before the owner performs TF2 human review of the split
input-suite PR candidate.

Current candidates:

- G-1: inspect-mode console ownership, now narrowed to future migration
  scheduling versus leaving a contested status quo.
- G-2: mouse `compy.singleclick`/`doubleclick` callbacks versus
  keyboard/text `compy.input.hooks[event]`.
- Category (a): R2 (`result`), R4 (`multiline`), R5 (unknown `show{}`
  keys), C1 (frozen design archival).
- Postponed jargon policy.
- D4: fixture/test philosophy, including whether fixtures should drive
  real framework/public entrypoints rather than partial hand-built
  setup and mocks.
- Local RVW-023/RVW-020 and owed RVW-092/RVW-100.

Question: What is the best *current* sequencing for reviewability,
quality, and architecture consistency? State serious arguments for
leaving any decisions until after TF2. Distinguish decisions that need
substantive code/test execution before review from those that should be
resolved, explicitly deferred, or merely documented before review.

Do not edit code. Verify any factual claim against the named current
records or source. The Lua LSP is available for concrete Lua symbol
facts; use grep to find candidates, then LSP for definitions/references
and sleep one second after any Lua edit before LSP queries. Write the
complete consultation to
`doc/development/wip/77-new-input-api/validation/outcomes/S22-sol-pre-TF2-ruling-order.md`.
