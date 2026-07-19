# RS2 — annotate opaque interim refs for TF legibility (Sonnet worker prompt of record)

You are a Sonnet worker in the compy LÖVE2D project (`/repo`, cwd). Under an Opus orchestrator.
**Do NOT commit.** Accuracy matters more than speed here: a wrong gloss misleads the later TF
reviewer — the opposite of the goal. Quote your source for every gloss so it can be verified.

## Goal (Phase-A tactical amendment — see `validation/reviews/ref-stabilization-2026-07-19.md`)

Interim/ephemeral `{badspecref: X}` refs in `tests/`+`src/` stay as **evidence** (the plan keeps
them; they will dangle harmlessly once `wip/77` is deleted). Your job is **additive legibility**:
beside each opaque one, inline a **short meaning gloss** so a TF reviewer knows *what the test is
about* without opening the ephemeral doc. **Never remove the ref or its `{badspecref:}` wrapper.**

`{badspecref: X}` = a bad/ephemeral ref the owner flagged (our target). `{jargon: Y}` = **DO NOT
TOUCH** (a separate Phase-TF task). New corpus pointers you add use **repo-root-relative** form
(`doc/development/...`).

## Two phases, one run

### Phase 1 — build a decode-map FIRST (research only, no edits yet)
For each target ref below, grep/read the ephemeral source doc under `wip/77`, find the item's
definition, and record in your deliverable: `ref | file:line(s) it appears | decoded meaning (≤1 line)
| SOURCE doc:line + short verbatim quote | persistent home if any`. If a ref cannot be located in any
source, mark it `UNRESOLVED — flag` (do not invent meaning).

### Phase 2 — apply the glosses
Edit each target site: keep the `{badspecref: X}` intact, add a concise parenthetical gloss beside it
(e.g. `{badspecref: A5} (the singleton-lifecycle / overlay-draw-flag contract — M2 review agenda
item)`). Where a persistent home exists, append a root-relative pointer
(`; see doc/development/decisions/input.md, Decision N`). Respect the file's ≤64-char line rule
(wrap comments). After editing a `.lua`, `sleep 1` then run `mcp__lua-lsp__diagnostics` (DEFERRED MCP
tool — `ToolSearch` `select:mcp__lua-lsp__diagnostics` first) to confirm no new diagnostics.

## Targets (inventory from grep 2026-07-19) and their source docs

**ENRICH (decode + gloss):**
- `A5` (`src/main.lua`, `src/controller/userInputController.lua`), `A8` (`tests/input/keys_pressed_spec.lua`),
  `A2`/`m4/m5 A2` (`userInputController.lua`) → `implementation/reviews/M2-human-review.md` (§A1–A8 agenda).
- `M2-human-review.md` bare refs (`keys_pressed_spec.lua`, `userInputController.lua`) → gloss = which
  agenda item the adjacent code concerns (tie to the A# on the same comment).
- `E30` (`tests/input/input_contracts_spec.lua`) → `design/spec.md` / `design/spec/M5c-dispatch-chain.md`.
- `Scope item 10(a)` (`input_contracts_spec.lua`) → `design/spec.md` / `design/requirements.md`.
- `AC-17..26` (`userInputController.lua`) → `design/requirements.md` (acceptance criteria).
- `ratified-model R11`, `ratified-model ruling 3` (`input_contracts_spec.lua`) →
  `design/notes/ratified-model.md`; **persistent home: `doc/development/decisions/input.md` Decision 11**
  (add pointer).
- `M6-02`/`M6-02-before-exit.md` (`input_contracts_spec.lua`) → `design/spec/M6-02-before-exit.md`.
- `M4-0-04.md finding 1` (`input_contracts_spec.lua`) → `implementation/reviews/M4-0-04.md`.
- `M7-01`, `M7-02-recut` (`input_contracts_spec.lua`) → `design/spec/M7-01-retarget.md`, `.../M7-02-recut.md`.
- `M8-01` (`input_contracts_spec.lua`) → `implementation/reviews/M8-01.md` / `design/spec/`.

**MILESTONE MARKS — light touch:** `0.1.0-m2a/m4/m5c/m7/mN`, `M4`, `chunk 4` (across
`key.lua`, `keys_pressed_spec.lua`, `input_contracts_spec.lua`, `consoleController.lua`,
`userInputController.lua`). These are schedule/version provenance. **Add a gloss ONLY where the mark
stands alone with no adjacent explanation** in its comment; if the surrounding comment already says
what the milestone delivered, leave it untouched. Never remove the mark.

**FLAG, do NOT edit (report for owner):** the empty `{badspecref:}` (`input_contracts_spec.lua`);
`{badspecref: this feature}`, `{badspecref: #77}`, `{badspecref: #77's blast radius}` (feature
self-refs / vague wording, not ephemeral-doc refs); `{badspecref: commit 7b4422c}`
(`userInputView.lua` — git SHA; gloss from `git show --stat 7b4422c` only if unambiguous, else flag);
`{badspecref: m7 design session}` (`consoleController.lua` — gloss if locatable in `design/`, else flag).

**DO NOT TOUCH:** every `{jargon: ...}` tag; `doc A` (done); already-root-relative corpus refs (done).

## Constraints
- Suite stays **815/0/0/4** (`busted tests`) — comment-only edits; a count change means you hit code, STOP.
- Line ≤64 chars (`agents/rules.md`); wrap glosses across comment lines as needed.
- Do not touch the owner's `REVIEW:`/`REVIEW/DOC:` inline remarks.

## Deliverable
Write `doc/development/wip/77-new-input-api/validation/outcomes/RS2-annotate.md`: the full Phase-1
decode-map (with source quotes), the Phase-2 edit list (file:line, added gloss), the FLAGGED set, and
the `busted` result. Do NOT commit. Report a concise summary to the orchestrator.
