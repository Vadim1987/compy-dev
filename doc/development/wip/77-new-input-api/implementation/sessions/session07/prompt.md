# session07 — prompt (POST-SWEEP: REVIEW triage done; PR-prep continues)

_Handover from session06 (opus-PM), 2026-07-15. Boot as **opus-PM**, same setup: repo root = cwd;
you orchestrate, spawn Sonnet implementors + Fable/Opus analysts selectively, commit after each unit
locally, **never push**; MCP-LSP is UP; Fable-5 available as an expensive advisor (use sparingly —
it earned its cost this session, see below). Read `agents/sweep.md` for the standing rules, then this._

## Where things stand — the #77 CODE is COMPLETE + green; this is PR-PREP

The M5c→M8 sweep landed long ago (suite **808 / 0 / 0 / 4**; the 4 pending are intentional). `compy.input.*`
is the sole project input surface; legacy poll globals are gone. **Do not re-run the sweep.** The
post-sweep documentation-finalization phase is essentially complete. Session06 delivered: the Fable
intent-alignment verdict (validated + committed), the 8 owner-rulings verified against code, Task 4b
incorporation recommendations, the rewritten `internals/user_input.md` (Opus-APPROVED), the permanent
`decisions/input.md` + per-subsystem `technical_debt/` ledger, and the re-runnable `pr-assembly-guide.md`.

**This session (session07) cleared owner-ruling item 8 — the in-code `REVIEW:` annotation triage.**

### DONE this session — REVIEW-annotation triage (commit `6b70907`)

- **31 `REVIEW:` markers → 0.** All in `controller.lua` (24) + `projectInputController.lua` (7),
  each resolved into an in-comment rationale (with named decision pointers) or a `TODO(debt)` marker
  + a `technical_debt/input.md` entry. **No behavioural change** — every actual fix (renames, dead-field
  removal, table-driven installers) is logged as debt, not applied. `grep REVIEW: src/` = 0; suite
  still 808/0/0/4; LSP diagnostics clean on both files.
- **Sign-off table:** `reviews/review-annotations-triage.md`. **Fable verdict:** `reviews/review-triage-fable-verdict.md`.
- **A tight Fable pass** on the 3 core design "WHY"s (66/898/927) **paid for itself** — it overturned
  one disposition and corrected the other two's citations. Both its factual claims were verified in code
  before acting:
  - `Controller._keyboard_route` is **write-only** (2 writes, 0 reads) — a first-draft comment claiming
    it was "used by restore + inspect handoff" was FALSE; corrected + logged as debt.
  - The **pointer path is an unstructured broadcast**, not a mirror chain (both widget + native fire; no
    bounds/consume check). My "pointer bubble-up" rationale was wrong on the facts; closed honestly + logged.
- **7 new tech-debt entries** added to `technical_debt/input.md` (all cosmetic/hygiene except the last):
  console debug-hotkey if-nav, `forward_*`/`userlove` naming, per-event installers, `_tier3` resolution,
  sink `love.state` injection, `_keyboard_route` write-only, **pointer-broadcast (carries an owner ruling)**.

### The one NEW owner ruling this session produced — item 9

The triage surfaced a genuinely-unresolved design question, added to `reviews/owner-rulings-verified.md`
as **item 9**: **should pointer routing get a keyboard-style mirrored consume-chain, and should a shown
widget consume clicks within its bounds?** Today pointer is a broadcast — a shown widget cannot swallow a
click aimed at it. It's an architectural follow-on (kin to Decision 1's deferred console/editor
convergence) and to ruling 7 (the widget-visibility/`is_active()` boundary). **Owner's call; do not resolve.**

## What remains before the PR (all owner-gated)

1. **Owner rulings — now 9** (`reviews/owner-rulings-verified.md`): the original 8 (all confirmed real)
   + item 9 (pointer). None reverses the architecture. These want the owner's decisions; the recommended
   home is the PR description (per Task 4b's incorporation rec).
2. **Incorporation controversies C1/C2** (`reviews/incorporation-recommendations.md`): is `design/spec.md`
   promoted as *history* or a *live contract* (code drifts on ≥3 axes)? and how to handle the stakeholder
   quirks/game-pattern docs. Owner's call.
3. **Delete `wip/77-new-input-api/`** — Task 4b has cleared, so this is unblocked, but it is **explicitly
   the owner's go**. Do not auto-delete.
4. **Execute the PR assembly** per `implementation/pr-assembly-guide.md` (re-runnable, git-only; BASE=3256aac).
   Re-verify the complete+disjoint slice check against the current tip before slicing.

## Loose ends / anomalies (unactioned, for the owner)

- `implementation/ses/SWEEP.tgz` — **root-owned** binary tarball anomalously in the doc tree; untracked. Ask.
- `tests/editor/editor_spec_fwd.lua` — untracked stray scratch (partial dup of `editor_spec.lua`).
- `docker/compose.yml` — pre-existing uncommitted diff, **not ours** (comments out two brainlab bind mounts). Leave.
- Untracked scratch: `src/STEPS.md`, `input-pr-slices.tar.gz`, `claude.sh`, several `src/examples/*` + `src/vadexamples/` checkouts.

## Standing facts

- **Suite:** 808 / 0 / 0 / 4 — Opus-approved; do NOT re-run to "verify" the feature.
- **Synthetic-diff / reassembly baseline:** `3256aac`.
- **Nested example repos:** balloons (`56347d0` unpushed migration), maze (uncommitted working-tree patch),
  keyboard (pure-native, untouched). Human authorized unpushed commits in detached repos (2026-07-12).

## Wrap rule for you

Commit unit-by-unit; never push. When the owner rules on the 9 items + the C1/C2 incorporation calls and
gives the go, help execute (a) deleting `wip/77` and (b) the PR assembly, then mark the post-sweep phase
DONE. Do not delete `wip/77` without explicit human go.
