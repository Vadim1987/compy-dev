# Post-sweep — rewrite `internals/user_input.md` to the landed system

_Commissioned by the opus-sweeper PM (session06), 2026-07-13. You are a **cold implementor**
(Sonnet, `agents/dev.md` charter). Repo root = cwd. This is a **main-corpus documentation rewrite**,
not a code chunk — there is no red-test step; instead **every factual claim you write is verified
against the landed code** (grep + lua-lsp; the mandate's "code wins on facts"). Commit locally in
this repo; never push; never touch `wip/77` source docs or the nested example checkouts' `.git`._

## Why this task exists

`doc/development/internals/user_input.md` is the permanent-corpus "how input works today" narrative,
and the shipped user guide `doc/input_api.md` (§See also, line 356) points project authors straight
at it. It is **pre-sweep stale**: it describes the DELETED `oneshot` / `love.event.push('userinput')`
auto-hide as the *current* mechanism and asserts (lines ~429–432) that the `compy.input.*` callbacks
"do not exist in `src/` yet … not current implementation" — false post-sweep. It also **links into
`wip/77/` in 8 places** (4 distinct notes), and `wip/77` is about to be **deleted** — so those links,
and the detail they defer to, must be absorbed inline or dropped, or the doc ships broken.

Your job: **rewrite it to describe the landed system accurately, self-containedly, and with no
pre-sweep residue** — so it survives the `wip/77` deletion as the correct internals reference.

## Scope — what to change, what to leave

**Rewrite (stale, must change):**
- The **Keyboard Handling** dispatch narrative (§Dispatch chain, §UserInputController keypressed,
  §Key release, the `oneshot` material): replace the pre-sweep mechanism with the **landed** model —
  gateway (`controller.lua` `love.handlers.*`) → active route (slot occupant) → the **four-tier
  chain** (`handlers[combo]` → `on_*` tier → captured native → widget sink) on the project route, the
  boot-provisioned `compy.input.*` singleton, submit/cancel chains, and route restoration at the
  `'running' ↔ 'project_open'` boundary. `oneshot` and `push('userinput')` are **GONE** — describe
  the current auto-close-on-submit as it actually works now (`userInputController.lua:submit()` +
  `projectInputController.lua` framework tier-1 entries), not the queued-event mechanism.
- The **isrepeat / scancode** claim (§Data flow `>` block, lines ~35–45): `isrepeat` is now **threaded
  through** the chain (gateway `function(k, sc, isr)` → tier-3 `on_key_pressed(k, keys_pressed, isr)`);
  it is no longer "stripped at the first hop." Correct it to landed reality.
- Any statement that the new callbacks/surface "do not exist yet."

**Sweep doc-wide (hygiene, regardless of section):**
- **All 65 inline `> …` author-questions must be gone.** For each: if it is marked **Resolved:** and
  carries real content, **fold that content into the prose** as plain narrative; if it is an open
  question or now moot, **drop it**. No `>`-prefixed author asides survive in the final doc.
- **All 8 links into `wip/77/` must be gone.** Where the doc currently *defers detail* to a wip note,
  **pull the essential content inline** (see source list below); where the link is a mere pointer,
  drop it. After deletion the doc must have zero dangling references.

**Leave intact (out of #77 scope, likely accurate):** the **Mouse Input** sections (§322+) and any
text/keyboard prose that is already factually correct about the landed code — *except* you must still
remove any `>` question or wip link inside them. Do not gratuitously reword correct prose.

## Source material — read, then VERIFY against code (do not transcribe blindly)

The richest source is the wip contract record, but it contains **forward contracts** ("the rewrite
will…") and **some of them did not land as written** — so you transcribe nothing without confirming
it against `src/`:

- `doc/development/wip/77-new-input-api/notes/input-contracts.md` (+ its already-applied
  `input-contracts-correction.md`, `input-contracts-revalidation.md`) — the routing-internals record.
  Load-bearing sections to absorb: **§2** channel convention, **§3** route/sink/widget vocabulary,
  **§5.3.2** the `ConsoleController:keyreleased` console-only fork, **§5.4** `inspect`-mode override,
  **§5.8** the `search` MVC triad, **§6 / §6.6** cross-cutting contracts + the four-incompatible
  `reset()` split, **§8** the "out of #77 blast radius" foundation map. These are exactly the
  "how it works today" internals the corpus otherwise has no record of — this is the *reason* the doc
  is worth saving.
- `doc/development/wip/77-new-input-api/design/spec.md` and `design/notes/ratified-model.md` — the
  ratified shape (glossary is binding; use its nouns).
- The **landed code** — authoritative on facts. Key files: `src/controller/controller.lua`
  (gateway, `keys_pressed`/`held_keys` proxy), `src/controller/projectInputController.lua`
  (four-tier chain, framework submit/cancel), `src/controller/userInputController.lua` (widget sink,
  `submit()`/`cancel()`, `is_shown()`), `src/controller/consoleController.lua`
  (`get_compy_namespace` / `get_compy_input` — the project surface).

## The didn't-land gaps — note these INLINE, do not paper over them

These are landed-vs-spec deviations already fact-checked by the PM in
`doc/development/wip/77-new-input-api/reviews/owner-rulings-verified.md` (read it — it has the exact
line cites). Where the internals narrative would otherwise imply the spec'd behaviour, state the
**actual landed behaviour** and flag the gap in one clause (no rulings — you describe, you don't
decide):
- `compy.keys_pressed` is **not** exposed to the project namespace (held keys readable only inside a
  callback, not pollable in `update()`).
- The `eval` / `result` config keys exist in `apply_config` (spec'd surface is `validator` /
  `highlighter`).
- Combo-tier key-repeat fires on **every** repeat at tiers 1–2 (isrepeat threaded to tier 3 only) —
  a DEFERRED/unsettled point.
- `multiline` is not a config key (Shift+Enter newline is unconditionally on).
- No public `is_active()`/visibility predicate on `compy.input` (an internal `is_shown()` exists).
- The held-key proxy is index-only on LuaJIT (`__pairs` is 5.2+).
- `show{}` silently drops unknown/field-write-only config keys (while `set_cursor`/`set_text` warn
  when hidden — an inconsistency worth one line).

## Deliverables

1. The rewritten `doc/development/internals/user_input.md` — accurate to landed code, self-contained
   (zero `wip/77` links, zero `>` author-questions), the internals knowledge from input-contracts.md
   §5/§6/§8 absorbed inline, the didn't-land gaps noted. Keep the doc's dual structure
   (text/keyboard **and** mouse). Update the stale header note "human-approved NOT YET" only if
   `agents/rules.md` doc-conventions (C1/C2/C3) direct otherwise — otherwise leave the approval
   marker for the human.
2. A brief **outcome ledger** at
   `doc/development/wip/77-new-input-api/implementation/outcomes/postsweep-internals-rewrite.md`,
   guardrail-shaped: open with a **"what will surprise the reviewer"** section (every place you
   departed from input-contracts.md because the code said otherwise — cite file:line), then the
   change summary, then a confirmation that no `>` questions or `wip/77` links remain
   (`grep -c` both, expect 0).
3. Commit locally (Conventional Commits, e.g. `docs(input): rewrite internals/user_input.md to the
   landed system`), doc + ledger together or as two commits. **No push.**

## Boundaries (hard)

- **Code is the source of truth.** Every mechanism sentence must match `src/`. If input-contracts.md
  and the code disagree, the code wins and you note it in the surprise section. Use lua-lsp
  (definition/references) when unsure who calls what — after any `.lua` touch pause ~1s before MCP
  calls (you won't be editing `.lua`, but the LSP is your fact-check tool).
- **You edit exactly one doc** (`internals/user_input.md`) + write one ledger. Do **not** edit any
  `wip/77` source, any `.lua`, `doc/input_api.md`, or anything else. Do **not** delete `wip/77`. Do
  **not** touch nested checkouts' `.git`.
- **Describe, don't rule.** The 8 open owner rulings are the owner's; you note landed behaviour and
  gaps, you never resolve a design question or recommend one in the doc.
- Respect `agents/rules.md` doc-conventions (C1/C2/C3) and `agents/development.md` (report-don't-fix:
  if you find a *code* bug while fact-checking, note it in the ledger, do not fix it).
