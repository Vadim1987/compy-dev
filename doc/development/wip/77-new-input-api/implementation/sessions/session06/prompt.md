# session06 — prompt (POST-SWEEP: doc finalization + intent review + PR prep)

_Handover from session05 (opus-sweeper PM), 2026-07-12, written after a **session-limit cut-off** mid-work.
Boot as **opus-PM**, same setup as session05 (repo root = cwd; you orchestrate, spawn Sonnet implementors +
Fable/Opus analysts, commit after each unit locally, never push; MCP-LSP is UP; Fable-5 available as
advisor/analyst). Read `agents/sweep.md` → the mandate for the standing rules, then this prompt._

## Where things stand — the #77 CODE sweep is COMPLETE; this is the POST-SWEEP phase

The M5c→M8 implementation sweep **landed and is COMPLETE** (suite **808 / 0 / 0 / 4**; the 4 pending are
intentional routing-grid placeholders). `compy.input.*` is the sole project input surface; the legacy poll
globals are gone. See `sessions/session05/track.md` for the full sweep close-out. **Do not re-run the
sweep.** This phase is **documentation finalization + intent review + preparation to delete `wip/77` and
open a PR.**

The human commissioned **four post-sweep "extra sweep commitments"** this session (2026-07-12). Status:

- **Task 1 — tests doc: ✅ DONE + committed `6297b44`.** `doc/development/tests.md` now documents the #77
  input contract suite (`tests/input/input_contracts_spec.lua`, `#input`/`#m5c`/`#m7`/`#m8` tags), the
  fixtures (`input_fixture.lua`/`input_session.lua`), and the 4 intentional `pending()` gaps. (Sonnet
  flagged `tests/editor/editor_spec_fwd.lua` as **untracked stray scratch** — a partial dup of
  `editor_spec.lua`; the human may want it cleaned up. Not actioned.)
- **Task 2 — cleaned synthetic system diff: ✅ DONE + committed `9a3e84e`.**
  `reviews/synthetic-system-diff.patch` + `reviews/synthetic-diff-manifest.md`. Baseline **`3256aac`** (the
  doc-corpus commit right after the `updev` branch tip `01ac142`) → HEAD. **This confirmed the human's
  intuition dramatically: 258 wip/77 files + 14 LLM-header-only files (~41k lines of interim noise)
  stripped → the real system delta is only 43 files / 5421+/331−**, plus the nested example-repo patches
  (balloons `56347d0`, maze working-tree). keyboard verified unchanged/excluded.
- **Task 4a — wip corpus index: ✅ DONE + committed** (the commit right before this handover; message
  "add WIP-DOC-INDEX"). `WIP-DOC-INDEX.md` indexes all 253 wip/77 docs (115 canonical individually; the
  rest as snapshot/process-bulk dir summaries) with an **incorporation shortlist**. **This is the input to
  Task 4b.**
- **Task 3 — Fable intent-alignment review: ⚠ Fable DIED at the session limit, BUT its verdict landed
  COMPLETE on disk, UNCOMMITTED.** `reviews/intent-alignment-verdict.md` (21 KB, full "For the owner"
  list). Its process was cut off at the very end, but the file is whole. **PM-unvalidated.** See below.
- **Task 4b — incorporation check (what wip/77 content to preserve before deleting the dir): ❌ NOT
  STARTED.** Needs Task 4a's index (now committed). See below.

## YOUR TASKS (in priority order)

### 1. Inspect + validate the Fable Task-3 verdict, then commit it (or correct it)

`reviews/intent-alignment-verdict.md` is on disk uncommitted (the "remains" of the dead Fable agent —
agent id `abbc1e89732c1b768`; the file is already complete, so a `SendMessage`-resume is almost certainly
unnecessary — validate the file, don't rebuild it). **Top-line verdict: "Holds together — with caveats."**
It confirms the poll idiom is gone, the overlay gate (the prior audit's central drift finding) is genuinely
removed in code, `isrepeat` restored, the four-tier chain / singleton / submit-cancel chains / cursor-text
/ mutable-API boundary all land as ratified. **The example migrations demonstrate the intended ergonomics.**

**Before committing it, spot-verify its concrete factual claims against the code** (it is Fable's
independent opinion, but a few claims are checkable and one impugns a doc YOU shipped this session):
- **⚠ It flags a BUG in `doc/input_api.md` (committed this session, `ced38bd`, header says "human-approved
  NOT YET"):** it claims the submit lifecycle is mis-documented — the guide orders *validation → then
  `before_submit(text)`*, but Fable says spec §5 + the code run **`before_submit(keys_pressed)` FIRST, then
  the validator gate**, and that `before_submit` fires even on an empty-input Enter. **VERIFY this against
  `userInputController.lua` (the submit path) + `design/spec.md` §5.** If Fable is right, fix `input_api.md`
  (and possibly the lifecycle prose in `internals/user_input.md`) — this is a real correctness fix to a
  shipped doc. If Fable is wrong, note it. Use lua-lsp to trace the submit path.
- The verdict's **"For the owner" list has 8 items needing human rulings** (none reverses the architecture)
  — see below; these are for the HUMAN, surface them, do not rule on them yourself.

Once validated (and any doc-bug fixed), commit the verdict (+ any doc fix) and **surface the "For the
owner" list to the human**.

### 2. Task 4b — the incorporation check (Fable OR Opus)

The human wants to **delete `wip/77-new-input-api/` before the PR** and needs assurance nothing durable is
lost. Commission an analyst (the human said "Fable or Opus" — Opus is a good fit for careful curation over
the corpus) to: read **`WIP-DOC-INDEX.md`** (so it need not read all 253 docs) + the index's incorporation
shortlist, then decide **what — if anything — should be promoted into the main docs corpus**
(`doc/development/internals/`, `doc/`, etc.) before the wip dir is deleted. Output a recommendations doc
(e.g. `reviews/incorporation-recommendations.md`): for each keep-candidate, what it is, where it should go,
and whether it's a straight move, a merge, or a distillation. The index's tier-1 shortlist to weigh:
`design/notes/ratified-model.md` (strongest keep), `design/spec.md`, `design/design.md`,
`design/requirements.md`, `design/notes/input.md` (verbatim stakeholder ticket), `notes/input-contracts.md`
(self-nominated `internals/` promotion), `notes/stakeholder-3-input/{compy-input-quirks,compy-lua-game-patterns}.md`.
**Surface any controversy/gap to the human; don't auto-delete wip/77** — deletion is the human's call after
reviewing the recommendations.

### 3. Report all controversies/gaps to the human (do not resolve design questions yourself)

The human asked twice to be told of controversies/gaps. The Fable verdict's **"For the owner" list**
(verify each is real before relaying; paraphrased):
1. **`compy.keys_pressed`** — promised as a read-only held-key proxy to projects; verify whether it's
   actually exposed, else amend the contract to callback-arg-only.
2. **The `eval` config key** — the examples wire validation/highlighting via `eval = InputEvalLua` /
   `ValidatedTextEval(filters)` (legacy evaluator objects), but the spec'd public surface is
   `validator`/`highlighter`. Bless `eval` as public API + record the deviation, or realign examples +
   `doc/input_api.md`. (This is the same `eval`-mechanism-key surprise flagged surprise-first back at M8-01.)
3. **Combo-tier key-repeat semantics** — shipped unsettled (fires on every repeat at tiers 1–2, contra the
   recorded provisional leaning); a reserved owner ruling still owed.
4. **`multiline` spec flag** — implement spec §3, or strike it (today: always-on Shift+Enter newlines).
5. **Silent config-key drops in `show{}`** (the documented `after_submit` footgun) — accept, or mandate a
   warn per the C2 warn-don't-swallow convention.
6. **Proxy iteration on LuaJIT** — accept indexing-only, or require an iteration/snapshot helper.
7. **Widget-visibility query** — sanction a public `is_active()`-shaped read (maze currently reads
   `love.state.user_input` internals + keeps a per-tick re-arm poll).
8. **The 45 committed in-code `REVIEW:` annotations** (the owner's own open questions shipped inside the
   landed code — naming, structure, pointer-routing "why") — sweep to answers/removal before release; plus
   fix `doc/input_api.md` (item 1 above).

**These need a validation pass before you relay them as fact** — several are checkable in code (LSP/grep).
Present the human a clean, verified list separating "confirmed real" from "Fable-claimed, unverified."

## The remains / anomalies to be aware of (surfaced by the sub-agents)

- `reviews/intent-alignment-verdict.md` — the uncommitted Fable verdict (Task 1 above).
- `implementation/ses/SWEEP.tgz` — a **root-owned binary tarball anomalously sitting in the doc tree**
  (flagged by the indexer); untracked. Ask the human what it is; do not commit it.
- `doc/development/wip/77-new-input-api/implementation/docker/compose.yml` — a **pre-existing uncommitted
  diff** (present since before session05; NOT ours — comments out two brainlab bind mounts). Never been
  committed; leave for the human.
- Many wip headers say "Approved NOT YET" despite the body/Gate markers showing the work landed — the
  **body/Gate markers are authoritative** (per the indexer), the stale headers are not.
- `tests/editor/editor_spec_fwd.lua` — untracked stray scratch (Task 1 note).

## Standing facts for quick reference

- **Version identifier:** `1.0.0-rc20260712` (doc convention; markers `(deprecated, removed in …)` /
  `(supported since …)`). No code version field exists.
- **Suite:** 808 / 0 / 0 / 4 — do NOT re-run to "verify" the feature; it's green + Opus-approved.
- **Synthetic-diff baseline:** `3256aac` (reproduction commands in `synthetic-diff-manifest.md`).
- **Nested example repos:** balloons (`56347d0`, unpushed migration commit in its detached `.git`), maze
  (uncommitted working-tree M5c-05 patch), keyboard (pure-native, untouched). Human authorized unpushed
  commits in detached repos (2026-07-12); balloons already carries one.
- **Open human hand-play gates** (no keystroke injection in-container): turtle, maze, tixy, balloons.

## Wrap rule for you

Keep this session's work committed unit-by-unit. When Tasks 3-validation + 4b land and the human has the
controversy/gap list, either (a) wrap to `session07/prompt.md` + repoint `agents/sweep.md` if more remains,
or (b) if the human proceeds to delete wip/77 + open the PR, help execute that and mark the post-sweep
phase DONE. Do not delete wip/77 without explicit human go — Task 4b must clear first.
