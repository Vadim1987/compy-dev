# Session 08 — cosmetic pass A

Files: `src/controller/controller.lua`, `projectInputController.lua`,
`consoleController.lua`, `userInputController.lua`, `src/main.lua`.
Comments only; no executable code or identifier touched.

**Caveat on method**: `HEAD` (4d8c240) contains zero `REVIEW`/`REVIEW/DOC`
lines in any of these five files — the annotations were injected
uncommitted before this pass started, so a line the predecessor deleted
leaves no `-` trace in `git diff HEAD`; only additions/rewraps are
visible that way. Counts below for *my own* edits are exact (verified
by re-reading current files against the task's rule set); counts
attributed to the predecessor's deletions are inferred from the
`{badspecref:}` wrap count as a proxy, not a literal diff count.

## 1. Remarks resolved/deleted

- **My edits this session**: 0 source lines changed. `userInputController.lua`'s
  remaining `REVIEW` lines (20, listed in §3) all match the task's
  explicit conceptual list verbatim — none needed action. `main.lua`'s
  one remaining `REVIEW` line (the singleton-rewire question near
  line 360) is the one explicitly named conceptual — also untouched.
  All `{badspecref:}` wraps and prose reflow in both files were
  already present when I started (see caveat above).
- **Predecessor (inferred, not directly countable via diff)**: current
  `{badspecref:}` occurrence counts — `controller.lua` 13,
  `projectInputController.lua` 21, `consoleController.lua` 24,
  `userInputController.lua` 34, `main.lua` 3. `consoleController.lua`
  now has **zero** `REVIEW`/`REVIEW/DOC` lines left, i.e. every remark
  there was resolved and deleted. `controller.lua` and
  `projectInputController.lua` each still carry several `REVIEW` lines,
  but all of those are architecture/naming questions (conceptual, see
  §3) — so "fully processed" for those two means "all cosmetic remarks
  resolved, all conceptual ones correctly left in place."

## 2. Inventory of `{badspecref:}` wraps + FIX PLAN (propose only)

Grouped by ref family across all five files; a proposed persistent-corpus
target per family, not applied.

| Family | Seen in | Proposed target |
|---|---|---|
| `ruling a` | controller.lua, consoleController.lua | `doc/development/technical_debt/input.md` §"Input-only / pointer-only projects stay live in `project_open` (RESOLVED, ruling a)" — exact existing heading |
| `Decision 8`, `Decision 11` (bare, no path) | controller.lua | `doc/development/decisions/input.md` Decision 8 (combo tables/serialisation) and Decision 11 (route connects only while running) respectively — direct numeric match, just missing the file-path prefix |
| `spec §1` / `§1` | controller.lua, projectInputController.lua, consoleController.lua, userInputController.lua | `decisions/input.md` Decision 8 (canonical combo form); user-facing: `doc/input_api.md` §"Combo key handlers" |
| `spec §2` / `AC-8` (uniform signature) | controller.lua, projectInputController.lua, consoleController.lua, userInputController.lua | `decisions/input.md` Decision 2 (four-tier dispatch) + Decision 13 (read-only held-key proxy); `internals/user_input.md` §"Dispatch chain" |
| `AC-27`, `AC-28`, `AC-27/29` | controller.lua, projectInputController.lua | `decisions/input.md` Decision 11 (route connects only while running) |
| `R7`, `spec §8 R7` | controller.lua, projectInputController.lua | `decisions/input.md` Decision 10 (legacy natives pure-wrapped as tier-3) |
| `C3/C14` | controller.lua | `decisions/input.md` Decision 2 (truthy-consume chain, return propagation) |
| `R12`, `R13` | projectInputController.lua | `decisions/input.md` Decision 2 (truthy-consume; consuming never removes a tier; sink return carries no meaning) |
| `R14` | projectInputController.lua, consoleController.lua | `decisions/input.md` Decision 8 (per-event combo sub-tables) |
| `0.1.0-m5` (combo dispatch) | controller.lua, projectInputController.lua | no persistent target — propose plain "an open design question, deferred" wording, drop the milestone id |
| `spec §5`, `spec §5 scope note`, `Spec §5 (AC-17/18/42(b))`, `spec §5 AC-19` | projectInputController.lua, userInputController.lua | `decisions/input.md` Decision 6 (submit/cancel are framework-tier); user-facing: `doc/input_api.md` §"The submit lifecycle" |
| `AC-10` | projectInputController.lua | `decisions/input.md` Decision 10 (noop+log default) |
| `AC-11/13`, `AC-11/AC-13` | projectInputController.lua, userInputController.lua | `doc/input_api.md` §"Activating the widget: `show`" (hidden-overlay no-op behaviour) |
| `AC-20`, `AC-20/21` | projectInputController.lua, userInputController.lua | `doc/input_api.md` §"The submit lifecycle" (engagement gated on shown) |
| `AC-26`, `spec §5, AC-26` | projectInputController.lua | `decisions/input.md` Decision 6 (before_/after_ hooks) |
| `AC-17`, `AC-17/18/42(b)`, `AC-17..26`, `AC-18`, `AC-18/AC-42(b)`, `AC-19`, `AC-25` | userInputController.lua | `doc/input_api.md` §"The submit lifecycle"; the dead-poll remnant is `technical_debt/input.md` §"Controller-side dead `result`/reftable delivery path" |
| `AC-1/2/11`, `AC-33`, `C2` | consoleController.lua, userInputController.lua | `doc/input_api.md` §"Live reconfigure: `configure`, `set_text`, `clear`, cursor"; the mutable/immutable boundary is `decisions/input.md` Decision 7 |
| `AC-7`, `AC-7/AC-9`, `AC-8/AC-9`, `AC-6/D-8`, `D-8` | consoleController.lua, userInputController.lua | `doc/input_api.md` §"Live reconfigure…cursor" subsection |
| `AC-5/AC-9`, `AC-3/AC-4`, `AC-4` | consoleController.lua | `doc/input_api.md` §"Live reconfigure: `configure`, `set_text`, `clear`, cursor" |
| `D-b` | consoleController.lua | `doc/input_api.md` §"Sticky callbacks" |
| `spec §7 / R3`, `R3` | consoleController.lua | `decisions/input.md` Decision 7 (mutable/immutable API boundary) |
| `chunk 2`, `chunk 3, AC-26/33` | consoleController.lua | no persistent target — these are PR-slice plan artifacts (`M5c-chunk-plan.md` etc., not in the persistent corpus); propose referencing `doc/input_api.md` sections directly instead |
| `0.1.0-m7`, `m7 design session`, `M7` | consoleController.lua | `doc/input_api.md` §"Live reconfigure…" (the M7 feature, already landed) — drop the milestone id itself |
| `M5c` | consoleController.lua | no persistent target — historical milestone label; propose plain wording |
| `spec.md §6` | consoleController.lua | `doc/input_api.md` §"Live reconfigure…cursor" (get_cursor no-warn phrasing) |
| `0.1.0-m4`, `A5`, `M2-human-review.md` | userInputController.lua, main.lua | **gap**: no current persistent-corpus entry covers the open "should the controller self-provision its model/view" / `open_fresh` naming question. Natural home is a new `technical_debt/input.md` "Open decisions" entry; none exists yet — flag for the doc owner rather than guess a heading |
| `0.1.0-m5/m6` | userInputController.lua | `technical_debt/input.md` §"Controller-side dead `result`/reftable delivery path" (legacy poll superseded by callbacks) |
| `0.1.0-m8`, `M8` | userInputController.lua | `doc/input_api.md` §"The continuous-session idiom" / §"Migration from the legacy globals" |
| `M7-01` | userInputController.lua | `doc/input_api.md` §"Live reconfigure…" (the boundary decision is described there in prose already, no id needed) |
| `m4/m5 A2` | userInputController.lua | `decisions/input.md` Decision 9 (uniform signatures / `isrepeat` threading) |
| `#77` | userInputController.lua | no persistent target — this feature itself; propose dropping the issue number, plain "not part of this change" wording |

## 3. Remarks left in place as conceptual

- **controller.lua**: forwarder-per-slot vs. generic dispatch; `ui.c`
  vs. a `get_user_input().handle(...)` shape; strict `true` vs.
  propagating the handler's return (lines ~27-29); `key` param naming
  in `wrapped_native` (~143); "use noop more universally" for widget
  outputs (~323); serialized-combo-to-closures refactor idea, marked
  "NOT TO IMPLEMENT NOW" (~368); combo-table mechanism for debug
  hotkeys (~447); `sc` param naming in `handlers.keypressed` (~870).
- **projectInputController.lua**: `'slots'` as primary term (~4);
  if-dispatch vs. noop-default hook table (~47); tier-agnostic
  `or`-chain dispatch idea (~195); `'tier3'` naming / role-based naming
  for chain participants (~196); `sc` param naming + `k,k`/`t,t`
  duplication in `_dispatch` (~252-253).
- **userInputController.lua** (all 20 lines, matching the task's list
  exactly): `gate` vs. `validate` naming (362); `noop_debug`-as-factory
  (371); legacy reftable still read anywhere (384-386, `deliver`
  wrapper); UIC's awareness of global placement / two mount points /
  internal hidden flag, 5-line block (421-425); replace handlers with
  noop when hidden, 4-line block (468-471); duplicated
  submit/cancel-out-of-UIC block 1 (657); block 2, 4 lines (673-676);
  wrap-with-immediate-call question (752).
- **main.lua**: singleton-rewire question — why Console/Editor aren't
  rewired onto the same UIC instance (~360).

## 4. Skipped as uncertain / found but out of scope

- `controller.lua:224` — bare `Decision 11` reference ("run (Decision
  11 uses this verb)") is unwrapped, inconsistent with the wrapped
  `Decision 8` at line ~452 in the same file. This is a genuine miss
  from the earlier "fully processed" pass on `controller.lua`, but
  that file is outside this session's edit scope (only
  `userInputController.lua` and `main.lua` were assigned) — flagging
  rather than fixing.
- No other unwrapped bad refs found in `userInputController.lua` or
  `main.lua` after a full sweep (`§`, `AC-n`, `spec`, `Decision n`,
  `0.1.0-mN`, `M2-human-review.md`, `#77`, `A5/A6`, `ruling`, `Cn`,
  `D-n`, `chunk n`, `Rn`, commit hashes — all either absent or already
  wrapped).

## 5. Verification

`busted tests` from `/repo`: 815 successes / 0 failures / 0 errors /
4 pending (pre-existing `pending()` rows in
`tests/input/input_contracts_spec.lua`, unrelated to this pass).
