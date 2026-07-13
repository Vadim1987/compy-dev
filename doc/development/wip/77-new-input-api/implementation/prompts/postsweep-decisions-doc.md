# Post-sweep — generate the input-subsystem architectural-decisions doc

_Commissioned by the opus-sweeper PM (session06), 2026-07-13. You are a **cold analyst/author**
(Opus). Repo root = cwd. You **generate** durable, subsystem-scoped corpus docs — you do not move
wip artifacts verbatim. Read-only over the corpus except the files you create. Commit locally; never
push; never touch `wip/77` sources or nested checkouts' `.git`._

## Why this task exists

The input feature's design corpus currently lives under `doc/development/wip/77-new-input-api/` and
will be **deleted before the PR** (its history survives locally but is NOT pushed — the PR is
reassembled to avoid overwhelming stakeholders). The durable *architectural rationale* — the "why
the input system is shaped this way" that the code and `internals/user_input.md` (how-it-works) do
not capture — must be **regenerated as a permanent, stakeholder-facing corpus doc** before that
deletion. The owner's ruling: a new **`doc/development/decisions/`** directory holding **per-subsystem
architectural-decision docs** (one dir, not one file, so future subsystems each get their own).

## What to create

1. **`doc/development/decisions/README.md`** — a short (½ page) index explaining the directory's
   purpose: per-subsystem architectural decisions & rationale (the durable *why*, distinct from
   `internals/*` how-it-works narratives and `conventions/*` house rules). List the docs in the dir.
2. **`doc/development/decisions/input.md`** — the input subsystem's architecture & key decisions.

## Content of `input.md` — the durable WHY, subsystem-framed

Capture the *decisions and their rationale*, ADR-flavoured — NOT a how-it-works walkthrough
(`internals/user_input.md` is that; cross-reference it, do not duplicate mechanism detail). Cover:

- **The core shape** and why: gateway (`love.handlers.*`) → active keyboard route (slot occupant) →
  the **four-tier dispatch chain** (`handlers[combo]` → `on_*` callbacks → captured native → widget
  sink), truthy-consume at each tier. Why route-centric rather than widget-as-router.
- **The boot-provisioned `compy.input.*` singleton** and why one shared surface (not per-project
  controller construction): show/hide as state changes never routing changes.
- **Callback-over-poll**: the dissolved poll-a-reftable idiom and why the callback API replaced it
  (consistency with LÖVE, no per-frame polling, no parallel-keyboard lockout).
- **The ratified decisions worth recording with rationale**: submit/cancel *semantic chains* vs the
  framework tier-1 entry; widget outputs (`on_text_entered`, `on_limit_reached`, `validator`,
  `highlighter`) vs the semantic chains; `isrepeat` threading; per-event combo tables + canonical
  combo serialisation; the mutable-callback API boundary (write-raise on non-callbacks); route
  restoration at the `'running' ↔ 'project_open'` boundary; auto-close-on-submit as unconditional;
  the held-key proxy as read-only.
- **The dev-facing ergonomics goal**: the before/after that the example migrations demonstrate.

## Sources — synthesize, don't transcribe; the code wins on facts

- `doc/development/wip/77-new-input-api/design/notes/ratified-model.md` — the **RATIFIED canonical
  model + binding glossary** (use its nouns; it is the authority).
- `design/design.md`, `design/requirements.md` (FR/NFR rationale), `design/spec.md` (contract),
  `design/notes/input.md` (the original stakeholder ticket + owner clarification — the ground-truth
  *why now*).
- The landed code for accuracy (`src/controller/{controller,projectInputController,userInputController,
  consoleController}.lua`) — if a design doc states an intention that did not land, describe what
  landed and note the gap (do not assert the aspiration as fact). The verified gap list is
  `reviews/owner-rulings-verified.md` — the tech-debt ledger (a sibling task) owns the *open* items;
  here you only need to avoid stating an un-landed aspiration as a shipped decision.

## HARD framing constraints (the owner was explicit)

- **NO feature/issue/milestone numbers anywhere.** No "#77", "issue 77", "feature 77", "M5c", "M8",
  "Gate 3", "rc20260712", "sweep". Write as timeless subsystem documentation: "the input subsystem
  does X because Y." A reader who never heard of the feature project must understand it.
- **NO links into `wip/77/`** (that dir is being deleted). Cross-reference only permanent-corpus docs
  (`internals/user_input.md`, `../input_api.md`, `conventions/*`) and `src/`.
- **Describe decisions, don't re-litigate or rule.** Open questions belong in the tech-debt ledger,
  not here — at most a one-line "see the input tech-debt ledger for open calls."
- Respect `agents/rules.md` doc-conventions (C1/C2/C3) — tone matches `conventions/` +
  `technical_debt.md` (matter-of-fact, provenance-aware).

## Deliverables & boundaries

- Create the two files above. Commit locally (Conventional Commits, e.g.
  `docs(input): add input-subsystem architecture & decisions doc`). No push.
- Do **not** edit `internals/user_input.md`, `doc/input_api.md`, any `.lua`, any `wip/77` source, or
  the tech-debt ledger (a sibling subagent owns that). Do not delete `wip/77`.
- Final message to the PM (concise): the commit hash, a 3–5 bullet outline of `input.md`'s decision
  list, and any place a design doc's stated intent did **not** land (so I can confirm the tech-debt
  ledger captures it). Do not paste the doc back.
