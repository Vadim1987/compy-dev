# S32 — was Decision 30 conceptually right? (cold check 2, judgement)

**Model:** Fable (explicit — expensive oracle). **Mode:** adversarial conceptual review,
then conditional implementation recommendations. **Commissioned by:** session32 parent,
owner's instruction 2026-08-09.

## What you are being asked

An owner ruling — **Decision 30** — has reversed the central implementation decision of a
large, nearly-finished feature. The owner wants it challenged **conceptually**, not merely
checked against codebase statistics (that has been done; results below, and they already
refute one of the decision's own paragraphs).

**Two questions, in order:**

1. **Was Decision 30 right?** Attack it. If it survives your attack, say so and say what it
   rests on. If it does not, say what breaks and how badly.
2. **Conditional on (1) coming out in support:** give **implementation recommendations** —
   how to carry the dissolution out, in what order, what to watch, what the traps are.
   If (1) comes out against, skip (2) and instead state what you would do instead.

**Rulings are the owner's, not yours and not mine.** You are producing an argument, not a
decision.

## Ground rules

- **Verify factual claims in code before you rely on them.** You have been right on judgement
  in this project and **wrong on facts**. Everything below is either code-verified by me this
  session or explicitly flagged as unverified — where I flag it, treat it as unverified.
- **The `lua-lsp` MCP server is available** (`definition`, `references`, `hover`,
  `diagnostics` over a real AST of `/repo`). Use it when you have a concrete symbol: grep to
  find candidates, LSP to resolve and to prove "who calls this". Grep is the completeness
  backstop — Lua is dynamic and LSP refs can be incomplete. Cross-check, trust neither alone.
  The LSP **cannot** disambiguate a method name shared across tables; read receivers manually.
- **"Pre-existing" means present at the PR base commit `3256aac`** — `git show 3256aac:<path>`.
  This distinction has overturned conclusions in seven consecutive sessions. Never infer it.
- **Read-only on code.** Do not edit anything except your deliverable. `busted tests`
  baseline is **955 / 0 / 0 / 3**; observe only.
- `doc/development/wip/77-new-input-api/design/` is **frozen** — read, never edit.

## The system, in one paragraph

`compy` is a LÖVE2D platform for student projects. Feature #77 replaces an input API. The
motivating defect: a **modal input widget** that, once shown, consumed keyboard events
wholesale — no modifier combo could reach the running project, text was poll-only. The
delivered feature adds a project-facing surface `compy.input` with **hooks** (per-event
callbacks), **shortcuts** (declarative combo→function tables, e.g.
`shortcuts.keypressed['ctrl+s']`), a **widget** with callbacks, and — until this ruling —
**`compy.input.keys_pressed`**, a read-only view of a framework-maintained set of currently
held keys, written by the gateway's `keypressed`/`keyreleased` handlers.

## The ruling to attack

`doc/development/decisions/input.md`, **Decision 30** (read it in full, `:1220` onward).
It supersedes Decisions 13, 20 and 29 (the three held-key-set decisions) and leaves
Decisions 8, 21, 26, 27 (combo vocabulary and argument contract) standing. Its four rules:

1. **Modifier state is read from the device.** `Key.ctrl()/alt()/shift()` — i.e.
   `love.keyboard.isDown` — is the single source of held-modifier truth.
   **`keys_pressed` is dissolved from all occurrences**, production and test. Justified as
   reverting an *implementation-time* decision that was never a stakeholder requirement.
2. **`Key.*` is legitimate inside the shortcut matcher** — `combo_string`/`any_mod` read the
   device to name the modifiers they serialise.
3. **`Key.*` at a call site remains a smell**, to be replaced by the shortcuts mechanism.
   One exception: **the gate** — a block in `controller.lua` running before dispatch that
   tests its own universal combos by direct polling (shutdown, exit, quickswitch). It is
   characterised as *a layer lacking a mechanism, not an exempt list*, and the ruling says it
   **can and should build its own shortcuts table**.
4. **When a shortcut does not fit, the shortcut sets a flag and does not grow** — a tiny
   shortcut sets a feature flag without consuming its event; the hook runs heavy logic
   against flags, not hardware.

**Its core rationale:** the tracked set is a *stateful abstraction model over an entity we do
not control*; nothing prevents drift and nothing reconciles it; **the only way to detect drift
is to compare against the device poll — which makes the device the authority and the tracked
set a cache of it, and a cache that needs the authority to validate it is strictly more
machinery than asking the authority.** Polling is stateless and self-healing; its errors are
ephemeral, bounded by one frame's batch.

## What is code-verified as of this session (cold check 1, and re-verified by me)

Deliverable: `../outcomes/S32-decision30-evidence-bundle.md`. Load-bearing results:

- **The gate is real and as characterised.** `src/controller/controller.lua:787-915`,
  **12 combinations** (11 in `handlers.keypressed`, plus Ctrl+Escape in `handlers.keyreleased`
  `:907-910`), **11 `Key.*` call instances**, zero raw `isDown`, and **no shortcuts table at
  that position**. Nearest shortcuts table: `projectInputController.lua:132`, reachable only
  via `love.keypressed(...)` called at `controller.lua:894-896`.
- **The gate's polls are byte-for-byte pre-existing at `3256aac`.** All ten base sites
  confirmed by diff. So the "polling problem" is **not** introduced by this feature.
- **`keys_pressed` does not exist at base at all** — nor does the whole `compy.input`
  namespace. It is new in this feature.
- **`src/util/key.lua`'s three accessors are pre-existing**, and all platform modifier checks
  went through them at base too.
- **`src/lib/error_explorer.lua:418`** (`love.keyboard.isDown('lctrl','rctrl')`) is the one
  platform-side bypass of that seam — and it is **also pre-existing at base**.
- **Two poll-shaped fakes predate the feature and survive it**: `src/harmony/init.lua`
  `patch_isDown` (a monkey-patch, and already variadic-correct) and `tests/mock.lua`
  `keystroke`, which sets `held[m]` per modifier and **emits no modifier event**.
- **Dissolution surface:** `keys_pressed` appears 22× in `src/` (7 files, incl.
  `src/examples/keyboard/input.lua`), 38× in `tests/` (6 files), 17× in `decisions/input.md`,
  **10×** in `internals/user_input.md`, 15× in `technical_debt/`, 8× in `doc/input_api.md`.

### One of Decision 30's own paragraphs is now REFUTED — you must factor this in

Decision 30 contains a paragraph headed *"Consequence — a prerequisite, not an option"*
claiming `tests/mock.lua`'s single-argument `isDown` **must** become variadic *"before the
suite can be trusted about modifiers at all."*

**The premise is true; the consequence is false.** Verified this session, four ways:
`mock.lua`'s `mods` table maps only `C→lctrl`, `S→lshift`, `M→lalt`; `keystroke` writes
`held[m]` **only** for `mods` tokens (any other token is dispatched as a keypress and never
written to `held`); `held` is a module-local and is not exported; no test installs its own
keyboard `isDown`. **No test can construct a state where the left and right variants differ**,
so the variadic form is extensionally equal to the current one over every reachable state —
**making it variadic would change zero test results.** Further, the single-arg `isDown` is
**pre-existing and untouched by this branch**.

Treat that paragraph as **overstated in the decision as written**. Whether that damages the
ruling is part of your question 1.

## The sharpest conceptual objection I can construct — test it, don't accept it

**Decision 30 may have removed the only non-smell way to answer a held-state question inside
a project hook.**

The history matters. Earlier this thread, the assistant proposed a *cut*: keep the tracked set
internally for combo strings, stop exposing it publicly. **The owner killed that proposal with
one question — "without exposing `keys_pressed`, how does a project branch inside a hook?"**
The documented answer was `keys_pressed` itself (`doc/input_api.md:372`: *"The held set below
is for what a combo cannot express"*; `:390`: *"a handler that wants held state reads
`compy.input.keys_pressed` the same way a `love.draw` does"*). The proposal was withdrawn on
that basis.

Decision 30 then dissolves `keys_pressed` **entirely** — which appears to answer the owner's
own question with *"the project polls `Key.ctrl()`"*, while **rule 3 of the same decision
declares exactly that a smell at a call site**. Rule 4 (flag-setting shortcut) is offered as
the escape. So:

- Is rule 4 an adequate answer to the question rule 3 creates, or does it push branching
  complexity into the project under a different name?
- Is there an **asymmetry** worth naming: the framework's own gate is *permitted* to poll and
  is even told to build a table, while projects are told polling is a smell and now have
  nothing else?
- Does the decision leave the **documented** contract (`input_api.md:372/390`) with no
  successor, or is the successor simply "`Key.*`, and that is fine for projects"?

The owner has separately ruled that **polling for decoration or drawing is legitimate** — a
key-cap renderer asking "what is physically held now" is correct use; a *judgement* asking it
is the smell. Factor that in; it may dissolve part of this objection.

## Honest counterweights — do not let me stack the deck

Arguments and facts pointing **for** the ruling, stated at their strength:

- The reconcile-requires-polling argument is genuinely strong and was called by the previous
  session *"the strongest single argument against the tracked set made in this thread."*
- The tracked set has a **non-self-healing failure mode**: a phantom held modifier (key
  released while unfocused) silently disables every unmodified shortcut on every channel, and
  no natural user action clears it. Polling's errors self-heal.
- **The combo/dispatch value is separable from the state-source question** — `combo_string`
  takes held state as a parameter, so declarative binding, introspectability and explicit
  precedence all survive intact. The decision says this and it appears correct.
- The tracked set is the only source of truth in the system that **neither** pre-existing fake
  could drive.

Arguments and facts pointing **against**, also at strength:

- **Two unmeasured frequency claims point in opposite directions** — batch skew (polling's
  error) and staleness (tracking's error). Neither was measured; the owner declined
  measurement, on the defensible ground that it can only inform *how* to fix a deferred
  pre-existing problem, never *whether* to defer it. A diagnostic probe was built and **never
  run** (`src/probe/input_probe.lua`).
- **The suite gets quieter.** Staleness was expressible in a test; batch skew is not, because
  a poll fixture is always self-consistent. The decision accepts this explicitly.
- **The surface is source-agnostic**, which cuts both ways: `keys_pressed` is handed out as a
  memoised read-only proxy (`controller.lua:428-441`) whose `__index` could be swapped to a
  polling function in ~3 lines. If shipping either way commits little, does a full dissolution
  of 22+38+50 occurrences buy enough to justify itself *now*?
- **Cost**: ~30 sessions of built work, examples already migrated, a green 955-test suite.
- The `keyboard` example reads held state **from draw** (`src/examples/keyboard/input.lua:57`,
  `keyboard_view.lua:171,178`); it reverts to polling, which by the owner's decoration rule is
  legitimate — but its adoption saving shrinks, and the PR narrative must say so.

## The stakeholder mandate — the frame you must judge against

`design/requirements.md` (frozen; read it). Established earlier and **owner-confirmed**:

- The problem statement is the **modal widget** defect.
- FR-5/6/7 are scoped to **the edit area** — widget callbacks, not a general prohibition.
- **NFR-2**'s "event-driven rather than requiring the project to poll **a reference for
  results**" is the **narrow** sense — it is *not* a blanket ban on `love.keyboard.isDown`.
- **FR-6 does mandate** notification of non-text key events including **Ctrl combos** while
  the edit area is active — so the combo/shortcut surface is stakeholder-requested.
- FR-11/12 make console/editor re-implementation an **expressiveness target, not a commitment
  to rewrite** — deferring them is what was asked for.
- The strategic frame: stakeholders asked for a **simpler and more robust input API**; the PR
  must be reviewable from `doc/input_api.md` + the PR description alone; the standing test is
  *"does this make the system more predictable, or merely more elaborate?"*

**Judge Decision 30 against that**, not against an idealised architecture.

## Checklist to run explicitly (each needs a stated judgement, none is automatically a defect)

- **self-inflicted constraints** — requirements the assistant introduced answering its own
  corner-cases, later mistaken for givens;
- **phantom problems** — problems that exist in the analysis but not in the code or in use;
- **unratified terminology** — vocabulary this work minted and began reasoning on (check
  against `3256aac`: absent there means it is ours);
- **solutions that expand commitment scope** — the fix larger than the thing it fixes;
- **deviation from intent / the stakeholder mandate**;
- **deviation from pre-feature functionality** — something that worked before and would not
  after, whether or not anyone noticed it working.

## Question 2 — implementation recommendations (only if question 1 supports the ruling)

Then, concretely:

- **Ordering.** What lands first, and why. Note that the "mock variadic first" constraint the
  decision states has been refuted as a *blocker* — but the fix may still be worth doing, and
  its value looks **prospective** (after dissolution, combo tests must migrate from asserting
  on `keys_pressed` to driving the poll fixture, and only then does the left-only limitation
  start to matter). Rule on that.
- **The test migration.** 38 `tests/` references; combo tests currently drive
  `Controller.keys_pressed` directly, and `mock.keystroke` sets modifiers **only** in the poll
  table while emitting no modifier event. These are two disjoint ways to say "ctrl is held"
  that do not agree. What is the right end state?
- **Rule 3's gate table.** The decision says the gate *should* build its own shortcuts table.
  Is that in this PR or a follow-up? What does it cost, and what does it risk (the gate holds
  shutdown/exit/quickswitch — non-overridable by design)?
- **`src/probe/input_probe.lua`** says of itself: *"DIAGNOSTIC, TEMPORARY. Delete when the
  polling-vs-tracking question is ruled on."* The question is now ruled. Recommend.
- **`error_explorer.lua:418`** — pre-existing bypass. In scope or not?
- What must the **PR description** say so a reviewer with only `doc/input_api.md` + the
  description is not misled about any of this?

## Deliverable

Write to
**`doc/development/wip/77-new-input-api/validation/reviews/S32-decision30-challenge-fable.md`**.
That file is the durable artifact; your final chat message is lost when context rolls.

Structure: **verdict first, in one paragraph** — does Decision 30 survive, and on what does it
actually rest. Then the attack, item by item, each with its strength honestly labelled
(code-verified / structural argument / unmeasured). Then the checklist judgements. Then, if
applicable, the implementation recommendations. End with **the strongest argument against your
own conclusion** — that section has been the most valuable part of your previous two
consultations in this project, and both times it changed what the owner did.
