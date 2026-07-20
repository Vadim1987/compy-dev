# R4 step 1 — REVIEW-remarks reconnaissance (Sonnet worker prompt of record)

**Model:** sonnet (explicit). **Phase:** #77 input-API redesign, Phase R4, step 1.
**Nature:** inventory + tagging only. **NO code edits.** Read-only reconnaissance.

## Standing hygiene (carried in per owner directive — you do NOT inherit repo CLAUDE.md)
- **lua-lsp MCP server is available** (`mcp__lua-lsp__definition`/`references`/`hover`/
  `diagnostics`) over a real AST of the `/repo` workspace. Use grep to find candidates,
  then LSP to resolve a concrete symbol / prove "who calls this". This task is read-only,
  so you likely won't edit; but if you ever do edit a `.lua`, `sleep 1` before querying
  refs/diagnostics (the server re-indexes).
- Materialize your deliverable on disk at the exact path in "Deliverable" below.

## Context you need
Two approved redesign documents drive Phase R (read both in full first):
- `doc/development/wip/77-new-input-api/validation/reviews/delta-design-input-api.md`
  — decision-level: revises D2 (four-tier chain → three-component chain, tier-1 deleted),
  D5 (limit signal moves fully to `on_limit_reached`, return value freed for consume),
  D6 (submit/cancel become widget-default callback sequences; auto-close default flips
  OFF; `before_cancel` may veto; Enter/Escape shadowable), D7 (freeze container +
  sub-table identities, leaves writable; drops the 11-entry allowlist), D10 (one
  `hooks[event]` table seeded once at activation; no resurrection-on-nil). Vocabulary
  table: `handlers`→`shortcuts`, `sink`/`singleton`→`widget`, tier-3 `on_*`→`hooks[event]`,
  the `before_*`/`after_*`/`on_text_entered`/`on_limit_reached`/`validator`/`highlighter`
  cluster → `callbacks[name]`, "framework handlers" retired.
- `doc/development/wip/77-new-input-api/validation/reviews/delta-spec-input-api.md`
  — mechanism-level: §2 dispatch as free function (deletes `_generic_callback`, `_sink`,
  `framework_handlers`, `install_tier1`, `shown_widget`, `run_hook`, `framework_submit`,
  `framework_cancel`, `natives` field); §3 submit/cancel on the widget; §4 widget-method
  factory `build_widget_api`; §5 hook seeding; §6 console patch; §7 ten acceptance criteria.

## Your task
Inventory **every** `REVIEW:` / `REVIEW/` remark in `src/` (42 counted across
`userInputController.lua` (20), `controller.lua` (8), `model/input/userInputModel.lua` (5),
`projectInputController.lua` (5), `util/key.lua` (2), `view/input/userInputView.lua` (1),
`main.lua` (1) — re-verify with your own grep, don't trust this number). For **each** remark,
record: `file:line`, the verbatim remark text (trimmed), and a **tag**:

- **`resolved-by-redesign`** — the delta-design/spec obligation that makes this remark
  moot once R4 executes. Name the specific decision/§ (e.g. "D6 revised — tier-1 deleted,
  so framework_handlers duplication remark is resolved by §2"). These will be **removed**
  as their code changes during R4, so note *which R4 sub-step* (delta-spec §/AC) the removal
  rides with.
- **`still-open`** — a legitimate concern the redesign does NOT touch (carries forward to
  Phase C's disposition table). Say why it survives.
- **`out-of-scope`** — not an input-API-redesign concern at all (e.g. a naming nitpick in
  an unrelated subsystem, or a DOC/nitpick the owner may never action). Say why.

When a remark's disposition hinges on a code fact ("is this legacy reftable read anywhere?"
— userInputController.lua:391), **verify it in code** (LSP `references` / grep) and record
the finding, rather than guessing from the comment text. That verification is the high-value
part of this inventory.

## Deliverable
Write a single markdown file to:
`doc/development/wip/77-new-input-api/validation/outcomes/R4-1-review-inventory.md`

Structure: one table (or one section per file) with columns/fields
`file:line | verbatim remark | tag | rationale + which R4 sub-step removes it (if resolved)`.
End with a short **summary tally** (counts per tag) and a **"resolved list for R4 execution"**
— just the `file:line`s tagged resolved-by-redesign, grouped by the R4 sub-step that removes
them, so the executor can cross them off mechanically.

Do not edit any source file. Return a 3-5 line summary of the tally + anything surprising.
