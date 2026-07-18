# Fact-check: fable-claims (session09)

Part A verifies five code claims read-only, with file:line evidence. Part B
(below) carries out the `tier3` → `generic_callback` rename once Part A is
recorded.

## Claim 1 — `UserInputController:_is_hidden_overlay()`

**Verdict: CONFIRMED** (with one LSP-reliability caveat noted below).

- Defined at `src/controller/userInputController.lua:437`:
  ```lua
  function UserInputController:_is_hidden_overlay()
    return self == love.state.user_input_controller
        and not love.state.user_input
  end
  ```
  Predicate matches the claim exactly (`self ==
  love.state.user_input_controller and not love.state.user_input`).

- Call sites — grep backstop (`grep -n "_is_hidden_overlay"
  -r /repo --include="*.lua"`) found exactly 4 call expressions, all inside
  `src/controller/userInputController.lua`, all inside UIC's own methods:
  - `userInputController.lua:448` — inside `UserInputController:is_shown()`
  - `userInputController.lua:472` — inside `UserInputController:keypressed()`
  - `userInputController.lua:722` — inside `UserInputController:textinput()`
  - `userInputController.lua:738` — inside `UserInputController:keyreleased()`

  (Line 437 is the definition; line 443 is a doc-comment mention on
  `is_shown`, not a call.) No call sites exist outside
  `userInputController.lua` — the claim "called only from inside UIC's own
  handler methods" is CONFIRMED.

  **LSP note:** `mcp__lua-lsp__references` on `_is_hidden_overlay` returned
  a *different* set of line numbers for the same file (`L436, L459, L706,
  L721` — missing the `is_shown` call entirely) and also surfaced a phantom
  path (`userInputController.lua.tmp.494.614413c670c1`) that does not exist
  on disk, alongside a `.patch` file's matches. This indicates a stale LSP
  index for this file at the time of query (no edits had yet been made in
  this session). Grep against the live file is ground truth here and is
  internally consistent (line numbers match a direct `Read` of the
  surrounding code); the LSP result is flagged, not trusted, for this claim.

- Internal shown/hidden flag: **only proposed, not implemented.** The
  doc-comment block directly above the definition
  (`userInputController.lua:421-436`) is REVIEW commentary, including:
  > `--- REVIEW: why should not it simply be *internal* flag, reset on
  > show/hide so that relevant code can check the state (shown/hidden)`
  (line 423)

  This is a critique proposing a flag as an alternative design — it
  confirms no such flag currently exists; the check is computed each call
  from `love.state.user_input_controller` / `love.state.user_input`, not
  read from a stored flag on `self`.

## Claim 2 — `doc/input_api.md`: `framework_handlers` absent; jargon leak at ~20-21

**Verdict: CONFIRMED.**

- `grep -n "framework_handlers" /repo/doc/input_api.md` → no matches
  (exit code 1). The term does not appear anywhere in the file.
- Lines 20-21 (exact current text):
  ```
  `compy.input` is a table on your project's `compy` namespace. It holds **methods** (call them —
  assigning over a method name raises loudly) and **callback slots** (assign to them — that is how
  you wire the tier-3 callbacks such as `after_submit`). The input widget itself is a single shared
  ```
  Line 20 ends with "**callback slots** (assign to them — that is how", line 21 is "you wire the
  tier-3 callbacks such as `after_submit`). ..." — both jargon terms
  ("callback slots", "tier-3 callbacks") are present exactly as claimed, on
  the expected lines.

## Claim 3 — hidden-widget tests run under `app_state = 'ready'`

**Verdict: CONFIRMED.**

- `tests/input/input_contracts_spec.lua:472` — `describe('a hidden widget
  does not consume', function()`; its two `it(...)` blocks are at lines 474
  and 491 (inside the claimed ~472-499 span; the described block ends at
  line ~500). Neither test, nor any enclosing `describe`/`before_each` in
  that range, sets `love.state.app_state`. The nearest prior/following
  explicit `app_state` writes in the spec file are at lines 290
  (`'running'`, inside an earlier, unrelated block) and 517 (`'editor'`,
  after this block) — this block is untouched by either.
- Fixture: `tests/helpers/input_fixture.lua:291` — inside `function
  F.reset()`:
  ```lua
  love.state.app_state          = 'ready'
  ```
  `F.reset()` runs between tests (the suite's teardown/reset hook), so the
  hidden-widget block runs under `app_state = 'ready'`, exactly as the
  claim states. (Note: the fixture path is `tests/helpers/input_fixture.lua`,
  not `tests/input/.../input_fixture.lua` as the claim's phrasing suggested
  — the file lives one directory up, at `tests/helpers/`, not nested under
  `tests/input/`. Content and line number match; only the claim's directory
  guess was off.)

## Claim 4 — fixture fidelity in `tests/helpers/input_fixture.lua`

**Verdict: CONFIRMED** (all four sub-claims, plus the three real
framework paths it says are bypassed).

- (i) `activate_project` calls production `Controller.set_user_handlers`:
  `input_fixture.lua:211-214`:
  ```lua
  function F.activate_project(natives)
    love.state.app_state = 'running'
    Controller.set_user_handlers(natives or { }, CC)
    return F.compy_input()
  end
  ```
  Confirmed — line 213 calls `Controller.set_user_handlers` directly.

- (ii) `running_project` installs bare `love[name]` rather than a
  sandboxed `project_env.love`: `input_fixture.lua:193-194`:
  ```lua
  function F.running_project(name, fn)
    love.state.app_state = 'running'
    love[name] = fn
  end
  ```
  Confirmed at line 194 (`love[name] = fn`, the real top-level `love`
  table, not a sandboxed `project_env.love`). A REVIEW comment directly
  above (line ~189) flags the same gap: "when project sets up 'love' its
  actually sets up project_env.love ... Here instead it sets up direct
  love callback?"

- (iii) `show_widget` bypasses `compy.input.show`: `input_fixture.lua:184-187`:
  ```lua
  function F.show_widget(opts)
    singleton:show(opts)
    return singleton
  end
  ```
  Confirmed — calls `singleton:show(opts)` (the UIC instance) directly,
  not `compy.input.show`. A REVIEW comment immediately above (line 183)
  asks exactly this: "why not via compy.input.show ?"

- (iv) `reset`/`reset_chain` re-implement teardown: `input_fixture.lua:263`
  (`local function reset_chain()`) manually calls
  `Controller.project_input:deactivate()` then hand-wipes
  `framework_handlers`/combo tables/`compy.input.*` callback fields
  field-by-field (lines 264-286); `F.reset()` (line 288) manually resets
  `love.state.*`, calls `restore_native_slots()` (line 236, which
  hand-restores `love.keypressed`/`textinput`/etc. from
  `Controller._defaults`) and `reset_chain()`, rather than calling a single
  framework teardown entry point. Confirmed — both functions duplicate
  teardown logic rather than delegating to it.

  The real framework paths this bypasses do exist as claimed:
  - `ConsoleController:suspend_run` — `src/controller/consoleController.lua:971`
  - `ConsoleController:stop_project_run` — `src/controller/consoleController.lua:1060`
  - `ConsoleController:quit_project` — `src/controller/consoleController.lua:1075`
    (which itself calls `stop_project_run` at line 1076)

  All three line numbers match exactly.

## Claim 5 — `tier3` census

**Verdict: REFUTED** — the count and "all in one file" claim are both
wrong; the true picture is larger and more scattered. Full census below
(this claim gates Part B scope, so precision matters).

**Literal identifier form `tier3`** (no separator — the actual naming
violation per `pre-review-drift-assessment.md`, which calls out `tier3`
**as a code identifier**, distinct from the prose term "tier 3"/"tier-3"
which legitimately uses the ratified §10 glossary word "tier"):

- Repo-wide total: **35** occurrences across **15** files (not 21, not
  confined to one file):
  - `src/controller/projectInputController.lua` — **6** (lines 155, 156,
    196 ×2, 204, 214)
  - `doc/development/technical_debt/input.md` — **2** (lines 454, 456)
  - 13 other files under `doc/development/wip/77-new-input-api/` (session
    notes, reviews, outcome ledgers, prompts — process/historical
    records, not live code or user docs) — **27** occurrences combined:
    `implementation/sessions/session09/fable-sequencing-consultation.md` (4),
    `implementation/sessions/session09/track.md` (4),
    `implementation/sessions/session09/prompt.md` (2),
    `implementation/sessions/session08/prompt.md` (2),
    `implementation/sessions/session08/cosmetic-a.md` (1),
    `implementation/sessions/session07/prompt.md` (1),
    `implementation/reviews/pre-review-drift-assessment.md` (4),
    `implementation/reviews/postsweep-internals-rewrite-review.md` (1),
    `implementation/reviews/M5c-01.md` (4),
    `implementation/outcomes/M5c-01-dispatch-chain.md` (1),
    `implementation/outcomes/M5c-03-submit-cancel.md` (2),
    `reviews/review-annotations-triage.md` (4),
    `reviews/intent-alignment-verdict.md` (1).

- `doc/input_api.md`: **0** occurrences of literal `tier3` — the leak
  there is the hyphenated prose form `tier-3` (1 occurrence, line 21,
  already quoted under Claim 2).

**All separator variants combined** (`tier3` / `tier-3` / `tier 3` /
`tier_3`, case-insensitive — i.e. including legitimate glossary prose,
not just the identifier violation): **257** occurrences repo-wide. Inside
`src/controller/projectInputController.lua` specifically this combined
count is **13** (not 21 either), across 12 lines (33, 51, 143, 152, 155,
156, 196, 204, 210, 214, 219, 250).

**Correction to the claim:**
1. Count in `projectInputController.lua` is **6** (literal `tier3`) or
   **13** (all variants) — not **21** under either reading.
2. Occurrences are **not** "all in" that one file. Literal `tier3` also
   appears in `technical_debt/input.md` (2, not the claimed "one") and in
   13 further historical/process markdown files (27 occurrences) the
   claim did not mention at all.
3. The `doc/input_api.md` leak is real and correctly located (line 21),
   but it is the prose form `tier-3`, not the literal identifier `tier3`.

**Flag for Part B:** the 27 occurrences in session notes / reviews /
outcome ledgers / prompts under
`doc/development/wip/77-new-input-api/{implementation,reviews}/**` are
historical, dated records — several of them (e.g.
`fable-sequencing-consultation.md`, `session09/track.md`,
`pre-review-drift-assessment.md`) are literally *about* the fact that this
rename was agreed but not yet applied. Rewriting `tier3` inside those would
corrupt the historical record rather than fix live terminology. Part B
therefore renames the identifier where it is a real, live Lua symbol
(`projectInputController.lua`) and updates the two living docs the prompt
named (`doc/input_api.md`, `doc/development/technical_debt/input.md`); it
does **not** touch the 13 historical/process files, per this flag.

---

# Part B — rename `tier3` → `generic_callback`

## Changes

### `src/controller/projectInputController.lua`

Attempted `mcp__lua-lsp__rename_symbol` on the method `_tier3` (tried both
the definition site, line 156 col 33, and a call site, line 204 col 11,
1 second after no prior edits — so staleness doesn't explain it). Both
attempts returned `Failed to rename symbol. 0 occurrences found.` — the
LSP does not resolve this colon-method-sugar symbol for rename (consistent
with the reliability caveat already flagged under Claim 1). Fell back to
careful manual text edits per the prompt's fallback instruction, verified
by grep before/after: renamed the definition (line 156), its two internal
call sites (lines 156 self-reference removed — see table — and 204), and
its two doc-comment mentions (lines 155, 213 post-edit). The one
prose-form `tier3` REVIEW comment (old line 196) was deleted rather than
renamed — see note below.

| Line | Before | After |
|---|---|---|
| 33 | `-- Event type -> its tier-3 generic-callback field on compy.input.` | unchanged (prose "tier-3", not literal `tier3` — out of scope) |
| 51 | `--- same noop+log default shape as tier 3 (log_branch above).` | unchanged (prose "tier 3" — out of scope) |
| 143 | `--- Tier 3 — the per-event generic callback, resolved by` | unchanged (prose "Tier 3" — out of scope) |
| 152 | `--- TODO(debt): tier-3 precedence is fixed at activate but` | unchanged (prose "tier-3" — out of scope) |
| 155 | ``--- "`_tier3` re-resolves the callback precedence on every event".`` | ``--- "`_generic_callback` re-resolves the callback precedence on every event".`` |
| 156 | `function ProjectInputController:_tier3(event, ...)` | `function ProjectInputController:_generic_callback(event, ...)` |
| 196 | `--- REVIEW: 'tier3' is weird name -- we agreed on 'generic_callback' but it was ignored. ... (tier3 or sink) ...` | REVIEW comment removed (rename now applied, so the comment recording that it *wasn't* applied is stale); see note below |
| 204 | `  if self:_tier3(event, ...) then return true end` | `  if self:_generic_callback(event, ...) then return true end` |
| 210 | `--- (from the caller); they seed tier 3 as default participants` | unchanged (prose "tier 3" — out of scope) |
| 214 | `--- _tier3). No handler is copied onto compy.input.` | `--- _generic_callback). No handler is copied onto compy.input.` |
| 219 | `--- pure-wrapped as tier-3".)` | unchanged (prose "tier-3" — out of scope) |
| 250 | `--- key-repeat is unruled; isrepeat is threaded to tier 3 only,` | unchanged (prose "tier 3" — out of scope) |

Note on line 196: this REVIEW comment's entire content is "the rename to
`generic_callback` was agreed but ignored — mark for refactoring." Since
this session performs exactly that rename, the comment is now satisfied;
it was deleted rather than left dangling (it referred to a `tier3`
identifier that no longer exists in the code below it).

### `doc/input_api.md`

Line 21 jargon leak fixed — replaced "tier-3 callbacks" with role-named
wording, keeping "callback slots" (already role-named, per the doc's own
established vocabulary of "methods" vs "callback slots"):

- Before (lines 20-21):
  > `compy.input` is a table on your project's `compy` namespace. It holds
  > **methods** (call them — assigning over a method name raises loudly)
  > and **callback slots** (assign to them — that is how you wire the
  > tier-3 callbacks such as `after_submit`). The input widget itself is a
  > single shared overlay: ...

- After:
  > `compy.input` is a table on your project's `compy` namespace. It holds
  > **methods** (call them — assigning over a method name raises loudly)
  > and **callback slots** (assign to them — that is how you wire
  > callbacks such as `after_submit`). The input widget itself is a
  > single shared overlay: ...

(Dropped "the tier-3" entirely rather than substituting a new term — the
sentence already names the mechanism precisely as "callback slots"; "tier-3"
was purely redundant internal-chain-position jargon leaking into a
project-facing doc, per Claim 2/Decision the prompt describes.)

### `doc/development/technical_debt/input.md`

Both literal-`tier3` occurrences updated (the debt entry documents the
now-renamed method):

- Line 454: `### \`_tier3\` re-resolves the callback precedence on every event`
  → `### \`_generic_callback\` re-resolves the callback precedence on every event`
- Line 456: `- **Where:** \`src/controller/projectInputController.lua\`, \`_tier3\` — computes`
  → `- **Where:** \`src/controller/projectInputController.lua\`, \`_generic_callback\` — computes`

Lines 134-135 and 465 use the prose form "tier-3"/"tier 3" (glossary term,
not the identifier) — left unchanged, in scope boundary with Claim 5's
finding.

## Verification

- **Final grep for literal `tier3`** (`grep -rn "tier3" /repo/src
  /repo/doc/input_api.md /repo/doc/development/technical_debt/input.md`):
  zero matches in `src/`, `doc/input_api.md`, and
  `doc/development/technical_debt/input.md`.
- Deliberately-retained mentions (per the Claim-5 flag, historical/process
  docs not touched): 27 occurrences of literal `tier3` remain across the 13
  files listed under Claim 5 — all under
  `doc/development/wip/77-new-input-api/{implementation,reviews}/**`,
  dated session/review/outcome records.
- `mcp__lua-lsp__diagnostics` on
  `src/controller/projectInputController.lua` after the edits (1s pause
  first): **21 diagnostics, all pre-existing and unrelated to the rename**
  — duplicate-doc-field / duplicate-set-field warnings on unrelated
  fields (`natives`, `compy_input`, `framework_handlers`, `_sink`,
  `_dispatch`, `activate`, `deactivate`, `keypressed`, `textinput`,
  `keyreleased`), redundant-return-value and param-type-mismatch warnings
  on `framework_submit`/`framework_cancel`, and one unused-local hint on
  `sc` (line 242). None reference `_tier3` or `_generic_callback`, and a
  repo-wide `grep -rn "_tier3\b" /repo --include="*.lua"` after the edits
  returns zero matches — no dangling old symbol, no new diagnostic
  introduced by the rename.
- `busted tests`: **815 successes / 0 failures / 0 errors / 4 pending** —
  unchanged from baseline (same 4 pending tests as before, at the same
  spec locations).

## Surprises / flags

- The LSP reliability issue noted under Claim 1 (stale references,
  phantom temp-file path) recurred as a caution during Part B — `sleep 1`
  was honored before every post-edit LSP call, and `rename_symbol` /
  `diagnostics` results were cross-checked against a direct grep of the
  file afterward to confirm no residual `_tier3` symbol references.
- No `tier3` occurrences were found that Part A's census did not already
  predict (the 35-occurrence literal census was exhaustive; nothing new
  surfaced during editing).
