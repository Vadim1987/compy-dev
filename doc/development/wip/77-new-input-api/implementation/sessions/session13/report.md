# session13 — report

**Task:** orchestrate **DI1** — the doc-A fidelity audit (first executable step of the amended,
ratified validation plan). Sonnet for the mechanical evidence; Opus consolidates + rules on
verdicts.

**Outcome: DONE, committed locally** (`0628087`). Owner reviewed and accepted; ruled to proceed
per the ratified recommended session layout (DI2+DI3 → S14), and to wrap S13 here.

## Deliverable

`validation/outcomes/DI1-docA-fidelity.md` — a per-section verdict table over doc A
(`notes/input-contracts.md`, §1–§9) on two axes: **Axis 1 fidelity vs shipped code** (still-true /
stale-mechanism / superseded-by-shipped) and **Axis 2 corpus home** (already-covered / unique-no-
home / partial). Backed by two Sonnet evidence dossiers (`DI1-a-evidence.md` §1–5,
`DI1-b-evidence.md` §6–9); prompts of record in `validation/prompts/`.

## The finding (one level up)

Doc A's **outcome-level contracts are overwhelmingly still-true**, but its **"today's mechanism"
notes and every `[forward / 0.1.0-mN]` tag are pervasively `superseded-by-shipped`** — the #77
rewrite it framed as *forward* has *landed* — and **nearly all its content is already homed in the
persistent corpus**, dominantly `internals/user_input.md`, which in several places is **more
current than doc A itself**. The genuinely `unique-no-home` residue is thin.

## Non-obvious points (what a downstream reader must not miss)

- **Four doc-A claims are now demonstrably FALSE against code** (not merely stale tags — positive
  claims the code contradicts): §6.1/§6.2 "`keys_pressed`/`combo_string` have zero `src/`
  consumers / inert / staged" (PIC `_dispatch` consumes both, `projectInputController.lua:198-207`);
  §5.4 "not documented in `internals/user_input.md`; first record" (it is, ~line 168); §6.6
  "`compy`: nothing yet" for cursor (`compy.input.get_cursor/set_cursor` exist); §6.6 auto-close
  "via a pushed `userinput` event" (now synchronous `hide()`; push path is dead code). Promoting
  any of these as-is would import a falsehood — the reason option (a) is off the table.
- **Circularity guard honoured:** doc A verified against `src/**` only, never the suite (the
  suite's fidelity is Phase TF's question). Corpus-DOC coverage was cited for Axis 2; that is not
  a suite witness.
- **Orchestrator re-verified every verdict-flipping claim in code itself** (spot-check log in the
  deliverable) — the dossiers were accurate, but the four FALSE-claim findings, the legacy-removal
  (`git log b4d96ec`, M8-03), and the 'starting'-state resolution rest on the orchestrator's own
  reads, not the workers' word.
- **§9 movement:** item 2 ('starting' ever observed by an input path) is now resolvable **NO**;
  item 4's provisional leaning was *not* adopted (shipped does the opposite, still unruled);
  item 3 (project overriding `on_key_pressed` silently disables `on_limit_reached`) is the one
  real **`unique-no-home`** fact worth merging → `technical_debt/input.md`.
- **`tests.md` drift recorded, not fixed:** its "Input Contract Suite" section says "808
  successes" + pending rows 101/153/161/222; live is **815/0/0/4**, pendings 118/172/185/246 (same
  four rows by content). The fix is a **DI3** action per the plan, deliberately not applied in DI1.
- **§8's four out-of-radius items are homed in `internals/user_input.md`, not
  `technical_debt/input.md`** (corrects the DI1-b brief's own hint).
- **Validation map** got a DI1 status banner only; suite rows untouched (TF scope). Its three open
  findings (editor keypressed-vs-textinput coverage gap; §5.8 search `pending`; `F.reset()`
  14-line breach) are carried forward to **Phase TF**.

## Evidence bearing on DI2 (owner-gated — NOT ruled here)

Confirms session12's prior: **option (b) merge**. No case for promoting doc A whole (a). Option
(c) largely collapses into (b) since content is already homed — DI3's ref-retarget over the ~30
doc-A citations is the same work either way. Full reasoning: the deliverable's "Evidence bearing
on DI2" section.

## Process notes for the successor

- Both Sonnet workers ran sequentially in the shared `/repo` tree (hygiene-d, no worktree
  isolation). LSP (`lua-lsp` MCP) is a **deferred** tool for sub-agents — they must ToolSearch-load
  it before use; DI1-a discovered this mid-run, DI1-b was told up front. LSP `references` output on
  this repo is noisy (hits inside `pr-slices/*.patch` and stale indexer `*.tmp` files) — cross-check
  with grep.
- session13/ was created root-owned (owner placed `prompt.md` as root); required an owner
  `chown` before the track could be written. Create successor dirs as `agent` to avoid a repeat.
