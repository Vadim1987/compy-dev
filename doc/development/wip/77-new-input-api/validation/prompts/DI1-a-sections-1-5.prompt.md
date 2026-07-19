# DI1-a — doc-A fidelity audit, evidence dossier for §1–§5

You are a Sonnet evidence worker in the compy LÖVE2D project (repo root `/repo`, your cwd).
You are the **cheap/mechanical tier** — this is exactly your kind of task: careful, exhaustive,
code-grounded evidence gathering. An Opus orchestrator will consolidate your dossier into the
final verdict table, so **your job is evidence + a proposed disposition per row, not the final
ruling**. Do the legwork thoroughly and cite everything.

## Standing hygiene (stated explicitly per owner directive — you do NOT inherit repo context)

- **MCP-LSP is available and is your correctness tool.** The `lua-lsp` MCP server gives
  defs / refs / diagnostics / hover over a real AST of the `/repo` workspace. Workflow: grep to
  find candidates, then LSP (`mcp__lua-lsp__definition`, `mcp__lua-lsp__references`,
  `mcp__lua-lsp__hover`) to resolve a symbol precisely and prove "who calls this / where is this
  defined". Use it whenever you are unsure where something lives or whether a symbol still
  exists. You will NOT edit any `.lua` file (read-only audit), so no re-index waits apply.
- **You are the delegated worker; do the whole task yourself, do not spawn sub-agents.**
- **Materialize your deliverable on disk** at the exact path in "Output" below. Your final chat
  message is secondary and will be lost when context rolls — the FILE is the deliverable.

## What this is

"Doc A" = `doc/development/wip/77-new-input-api/notes/input-contracts.md` — a pre-implementation
"current behaviour" contract record, written BEFORE the #77 rewrite shipped, never confirmed
against the delivered code. ~30 test/fixture comments still cite it, and it is slated for
deletion with the `wip/77` tree. We must decide its fate (promote / merge / reword refs). That
decision needs a per-section audit: **does each claim still describe the shipped code, and is
its content already covered by the persistent docs corpus?** Your dossier is the evidence for
that decision.

**Your scope: doc A §1 through §5** (Premise/§1, Channels/§2, Routing vocabulary/§3,
Completeness table/§4, per-event contract table §5.1–§5.9). A sibling worker (DI1-b) covers
§6–§9 — do not touch those.

## The two axes you assign per section/subsection (BOTH, they are orthogonal)

**Axis 1 — fidelity vs shipped code:**
- `still-true` — the claim (at the level it is stated) holds against current code.
- `stale-mechanism` — the claim's "(current realization)" / mechanism note describes the
  PRE-rewrite world and no longer matches shipped code.
- `superseded-by-shipped` — a forward/contract-level statement whose shape the shipped code
  changed (e.g. a "forward / 0.1.0-mN" contract that has since LANDED, so the temporal tag is
  now wrong; or a contract the shipped design reshaped).

Many doc-A rows carefully separate an OUTCOME contract (durable) from a MECHANISM note
(non-binding). Judge the **outcome** and the **mechanism** separately when a row has both —
frequently the outcome is `still-true` while the mechanism note is `stale-mechanism`.

**Axis 2 — corpus home:**
- `already-covered` — the content already lives in a persistent corpus doc; **cite the exact
  doc + section heading**.
- `unique-no-home` — no persistent mirror exists; this content would be lost if doc A is
  deleted (a merge/promote candidate).
- (partial is fine: "outcome covered in decisions/input.md Decision 6; the inspect
  mechanism-trace is unique-no-home".)

## Circularity guard (MANDATORY)

Verify doc A **against CODE (LSP + grep), NEVER against the test suite.** The suite's own
fidelity is a separate later phase; using it as doc A's witness would be circular. Do not cite
`tests/**` as evidence that a doc-A claim is true. (You may note where a corpus DOC covers a
claim — that is Axis 2 — but the *fidelity* judgment on Axis 1 comes from `src/**` only.)

## Anchor facts already verified in code by the orchestrator (reuse; do not recontest)

- `get_user_input` **survives** at `src/controller/controller.lua:21-24`
  (`if love.state.app_state=='inspect' then return end; return love.state.user_input`). It is
  now the **console route's** intra-route widget forward — `forward_keypressed/textinput/
  keyreleased` (`controller.lua:40-60`) and the mouse/touch handlers (`controller.lua:1022-1117`)
  all gate on it. Comment at :30-37 cites decisions/input.md Decision 9 & 13.
- `ProjectInputController` is real: `Controller.project_input = ProjectInputController()`
  (`controller.lua:1192`). On a running project, `occupy_keyboard` (`controller.lua:234-259`)
  installs `love.keypressed/textinput/keyreleased = pic:...` — **PIC occupies the keyboard/text
  slots**, and the overlay gate is REMOVED for the project route. `pic:deactivate()` on stop
  (:799, :815).
- **Therefore** doc A's recurring "today = overlay gate on project keys / forward =
  ProjectInputController (§7.1)" framing is INVERTED by shipped reality: the forward world
  landed. Expect §5.1/§5.2's "today's mechanism [CHARACTERIZE-PROVISIONAL]" overlay-gate-on-
  project notes to be `stale-mechanism`; the gate survives only on the console route's own
  widget forward. Confirm the specifics per section — but you need not re-establish these three
  bullets.

## The persistent docs corpus (Axis-2 citation targets) — headings you may cite

- `doc/input_api.md`: Overview; Quick start; Activating the widget: `show`; The submit
  lifecycle (+ Two callback families); The continuous-session idiom; Validation & highlighting;
  Live reconfigure: `configure`, `set_text`, `clear`, cursor; Combo key handlers; API reference
  (Methods / config keys / Sticky callbacks / Field-write-only callbacks); Migration from the
  legacy globals.
- `doc/development/internals/user_input.md`: Text Input Widget (Data flow / Multiline input /
  Selection / Error state / Evaluator and validation / Cursor manipulation and "reset");
  Keyboard Handling (Dispatch chain / Key state: `Controller.keys_pressed` and `combo_string` /
  Console-specific keys / Editor-specific keys / UserInputController keypressed (shared) / Key
  release / Search — a third widget instance...); Mouse Input (Framework-level click handling /
  Direct mouse events / Input widget mouse / Touch); The `user_input` Overlay (Singleton
  lifecycle / Dispatch while active / Submit and cancel — the framework tier-1 chains /
  `compy.input` namespace / `show(config)` / `configure(config)` / `clear()`); Key Files.
- `doc/development/decisions/input.md`: Decision 1 route-centric-not-widget-centric; 2 four-tier
  dispatch chain w/ truthy-consume; 3 one boot-provisioned shared widget; 4 callbacks replace
  polling; 5 two directions two surfaces; 6 submit/cancel framework-tier w/ call-order chains; 7
  strict mutable/immutable boundary; 8 per-event combo tables + canonical serialisation; 9
  uniform signatures + `isrepeat` threading; 10 legacy native handlers pure-wrapped as tier-3;
  11 route connects only while running; 12 `inspect` is a mode-to-route line; 13 held-key set
  exposed read-only, callback-only; "Where the shipped system differs from the design intent".
- `doc/development/technical_debt/input.md`: many entries — the ones likely relevant to §1–§5:
  "`keys_pressed` can go stale on focus loss"; "`love.handlers.userinput` is dead code";
  "Controller-side dead `result`/reftable delivery path"; "Input-only / pointer-only projects
  stay live in `project_open` (RESOLVED, ruling a)"; "Pointer delivery is an unstructured
  broadcast, not a chain"; "Widget sink reaches the singleton via `love.state` global +
  nil-guard". (Grep the file for others as needed.)
- `doc/development/tests.md`: "Input Contract Suite (feature #77)" — corpus home for suite facts.

## How to work

1. Read doc A §1–§5 in full (lines 1–524 of the file).
2. For each numbered section AND subsection (§1, §2, §3 [treat its glossary entries route/sink/
   widget + the exclusivity invariant + "controller occupies slot, not widget" + reset
   semantics as distinct rows], §4, §5.1 … §5.9), verify the load-bearing claims against
   `src/**` via grep + LSP. Key files to expect: `src/controller/controller.lua`,
   `src/controller/consoleController.lua`, `src/controller/projectInputController.lua`,
   `src/controller/userInputController.lua`, `src/util/key.lua`. For §5.3.2 (the keyreleased
   CC-internal editor-fork gap) and §5.8 (the `search` MVC triad) verify the specific structural
   claims (does `ConsoleController:keyreleased` fork on `app_state=='editor'`? does
   `SearchController` define a `:keyreleased`? where is `EditorController.search` built?).
3. For each row also determine Axis 2 (corpus home) by checking the corpus headings above.
4. Write the dossier.

## Output

Write to `doc/development/wip/77-new-input-api/validation/outcomes/DI1-a-evidence.md`.

Format: one section "## §N.N — <title>" per doc-A (sub)section, each containing:
- **Claim(s):** 1–3 line summary of what the section asserts (separate outcome vs mechanism if
  both present).
- **Code check:** what you inspected — `file:line` refs and the concrete finding (e.g. "confirmed
  `ConsoleController:keyreleased` at consoleController.lua:NNNN calls `self:keyreleased()` with no
  `app_state=='editor'` branch — grep for editor fork returned nothing"). Cite LSP where you used
  it.
- **Axis 1 (fidelity):** still-true / stale-mechanism / superseded-by-shipped (+ split
  outcome/mechanism when they differ), one-line rationale.
- **Axis 2 (corpus home):** already-covered `<doc + heading>` / unique-no-home / partial (say
  which parts), one-line rationale.
- **Notes for consolidation:** anything ambiguous, any place your evidence is thin, any conflict
  you could not resolve — flag it rather than paper over it.

End with a short "## Uncertainties / thin spots" list so the orchestrator knows what to
spot-check. Be exhaustive and precise; do not editorialize about whether the feature is correct
(that is out of scope — you audit whether the DOC matches the CODE, nothing more).
