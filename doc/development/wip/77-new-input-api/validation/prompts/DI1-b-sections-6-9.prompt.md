# DI1-b — doc-A fidelity audit, evidence dossier for §6–§9

You are a Sonnet evidence worker in the compy LÖVE2D project (repo root `/repo`, your cwd).
You are the **cheap/mechanical tier** — careful, exhaustive, code-grounded evidence gathering.
An Opus orchestrator consolidates your dossier into the final verdict table, so **your job is
evidence + a proposed disposition per row, not the final ruling**. Cite everything.

A sibling worker (DI1-a) has already produced `validation/outcomes/DI1-a-evidence.md` covering
doc A §1–§5. **Read it first** and reuse its established mechanism facts (esp. the
`get_user_input` / `ProjectInputController` reality) — do not recontest them.

## Standing hygiene (stated explicitly — you do NOT inherit repo context)

- **MCP-LSP is available and is your correctness tool.** `lua-lsp` MCP server: defs / refs /
  diagnostics / hover over a real AST of `/repo`. Grep to find candidates, then LSP
  (`mcp__lua-lsp__definition`, `mcp__lua-lsp__references`, `mcp__lua-lsp__hover`) to resolve a
  symbol and prove "who calls this / where defined". You will NOT edit `.lua` (read-only audit).
- **Do the whole task yourself; do not spawn sub-agents.**
- **Materialize your deliverable on disk** at the Output path. The FILE is the deliverable.

## What this is

"Doc A" = `doc/development/wip/77-new-input-api/notes/input-contracts.md` — a pre-implementation
"current behaviour" contract record, written BEFORE the #77 rewrite shipped, never confirmed
against delivered code. ~30 test/fixture comments cite it; slated for deletion with `wip/77`. We
must decide its fate (promote / merge / reword refs), which needs a per-section audit: **does
each claim still describe shipped code, and is its content already covered by the persistent
docs corpus?**

**Your scope: doc A §6 through §9** — §6 Cross-cutting contracts (§6.1–§6.7), §7 Forward
contracts (§7.1–§7.4), §8 Out of #77 blast radius (4 items), §9 Open questions (~6 items).
Lines ~525–859 of the doc.

## The two axes you assign per section/subsection (BOTH — orthogonal)

**Axis 1 — fidelity vs shipped code:**
- `still-true` — holds against current code (judge outcome and mechanism separately if both).
- `stale-mechanism` — the "(current realization)"/mechanism note describes the PRE-rewrite
  world, no longer matches.
- `superseded-by-shipped` — a forward/"0.1.0-mN" contract that has since LANDED (temporal tag now
  wrong), or a contract the shipped design reshaped.

**§7 is special:** every §7 row is tagged `[forward / 0.1.0-mN]` — "does not hold today". Your
job is to check whether it holds NOW (shipped). Many will be `superseded-by-shipped` (the
forward contract landed → the "forward, not present today" framing is inverted). For each §7
row, verify the concrete shipped mechanism: e.g. §7.1 ProjectInputController receiving
keypressed/textinput/keyreleased and occupying slots (anchor fact — already confirmed in
DI1-a); §7.2 named console restoration on stop; §7.3 native-handler coexistence
(auto-provision); §7.4 `isrepeat` threading through the keypressed path + `on_key_pressed`
signature. Also assess the §7.4 "open cross-reference gap" (m4 names a `keyreleased` dispatch
tier m5 never defines) and §9's open questions — several may now be RESOLVED by shipped code or
recorded in the corpus; say so with evidence.

**Axis 2 — corpus home:** `already-covered` (cite exact doc + heading) / `unique-no-home` /
partial. Note that doc A's §8 "out of #77 blast radius" items and several §6 items look likely
to be already homed in `technical_debt/input.md` — verify each precisely.

## Circularity guard (MANDATORY)

Verify doc A **against CODE (LSP + grep), NEVER against the test suite.** Do not cite `tests/**`
as evidence a doc-A claim is true. Corpus DOC coverage (Axis 2) is fine to cite; the Axis-1
fidelity judgment comes from `src/**` only.

## The persistent docs corpus (Axis-2 citation targets) — headings you may cite

- `doc/input_api.md`: Overview; Quick start; Activating the widget: `show`; The submit lifecycle
  (Two callback families); The continuous-session idiom; Validation & highlighting; Live
  reconfigure: `configure`, `set_text`, `clear`, cursor; Combo key handlers; API reference;
  Migration from the legacy globals.
- `doc/development/internals/user_input.md`: Text Input Widget (Data flow / Multiline / Selection
  / Error state / Evaluator and validation / Cursor manipulation and "reset"); Keyboard Handling
  (Dispatch chain / Key state: `Controller.keys_pressed` and `combo_string` / Console-specific
  keys / Editor-specific keys / UserInputController keypressed (shared) / Key release / Search —
  a third widget instance...); Mouse Input (Framework-level click handling / Direct mouse events
  / Input widget mouse / Touch); The `user_input` Overlay (Singleton lifecycle / Dispatch while
  active / Submit and cancel — the framework tier-1 chains / `compy.input` namespace / `show` /
  `configure` / `clear`); Key Files.
- `doc/development/decisions/input.md`: Decisions 1–13 (route-centric routing; four-tier
  dispatch+truthy-consume; boot-provisioned shared widget; callbacks replace polling; two
  directions two surfaces; submit/cancel framework-tier w/ call-order chains; mutable/immutable
  boundary; per-event combo tables + serialisation; uniform signatures + `isrepeat`; legacy
  natives pure-wrapped tier-3; route connects only while running; `inspect` mode-to-route line;
  held-key set read-only callback-only); "Where the shipped system differs from the design
  intent".
- `doc/development/technical_debt/input.md`: Standing (`keys_pressed` stale on focus loss;
  `love.handlers.userinput` dead code; dead `result`/reftable path; input-only/pointer-only
  projects stay live in `project_open` RESOLVED ruling a); Open decisions (`compy.keys_pressed`
  not exposed; `eval`/`result` config keys undocumented deviation; Combo-tier key-repeat
  semantics shipped unsettled; `multiline` unimplemented; Silent config-key drop in `show{}`;
  held-key proxy iteration index-only; no public `is_active()`); Anticipated (Combo-string
  dispatch allocates a table per call; `combo_string` case-normalisation; `gui_k` modifier pair
  no consumer; Overlay-shape test stub; `Esc` clears input in place; Editor input buffer not
  cleared on Escape; Touch delivery not black-box expressible; `F.reset()` exceeds 14-line
  limit; Editor sets input-widget cursor outside project cursor API; `submit()` deliver-then-hide
  ordering; and more — grep the file).
- `doc/development/tests.md`: "Input Contract Suite (feature #77)".

## How to work

1. Read `validation/outcomes/DI1-a-evidence.md` (sibling's dossier — shared mechanism facts).
2. Read doc A §6–§9 in full.
3. For each row, verify the load-bearing claims against `src/**` via grep + LSP. Expected files:
   `src/controller/controller.lua`, `consoleController.lua`, `projectInputController.lua`,
   `userInputController.lua`, `src/model/input/userInputModel.lua`, `src/util/key.lua`. Concrete
   checks to run, among others:
   - §6.1 held-key set: does `Controller.keys_pressed`/`held_keys` have in-`src/` consumers
     beyond its own bookkeeping? (doc claims "zero current src/ consumers" — verify with LSP
     references + grep.) §6.2 `combo_string`: same "no in-src consumer" claim — verify.
   - §6.3 global shortcuts non-consuming; play-mode narrows the set — verify the shortcut layer.
   - §6.4 slot restoration on stop (`set_default_handlers`).
   - §6.5 legacy solicitation path (`user_input()`/`input()`/reftable/`r:is_empty()`); §6.6
     widget activation/reset guarantees; the "four incompatible reset()/cancel impls + cursor
     two-layer split" (doc A §6.6 / §8).
   - §6.7 framework click detection (0.4s / 2.5px, project `compy.singleclick`/`doubleclick`).
   - §7.1–§7.4 as described above (mostly `superseded-by-shipped`); the §7.4 m4↔m5 keyreleased
     cross-reference gap.
   - §8's four items — confirm each is captured in `technical_debt/input.md` (Axis 2) and still
     factually true (Axis 1).
   - §9's open questions — which are now resolved by shipped code / recorded in corpus?
4. Determine Axis 2 for each row.
5. Write the dossier.

## Output

Write to `doc/development/wip/77-new-input-api/validation/outcomes/DI1-b-evidence.md`.

Same format as DI1-a: per (sub)section — **Claim(s)**, **Code check** (`file:line` + concrete
finding, cite LSP where used), **Axis 1 (fidelity)** (+split outcome/mechanism), **Axis 2
(corpus home)** (cite headings), **Notes for consolidation**. End with a "## Uncertainties /
thin spots" list. Be exhaustive and precise; audit whether the DOC matches the CODE — do not
judge whether the feature itself is correct.
