# M8 — chunk carve (PM planning artifact, terminal milestone)

_Written by the opus-sweeper PM (`agents/sweep.md`), session05, 2026-07-11, on entering the
**autonomous, terminal** M8 sweep. Promotes the session05 prompt's proposed carve to a first-class,
reviewable artifact and **validates it against the frozen `design/spec/M8-02-recut.md`** (Gate-3 CLOSED,
human-approved 2026-07-07 — the implementation target; `M8.md` / `M8-01-dead-text-input.md` are frozen
history, folded in). The spec's **REVALIDATE-AT-COMMISSIONING flag is discharged** — the full
revalidation (two open reads + example census + `astv_input` disposition + submit-lifecycle) is recorded
in [`sessions/session05/track.md`](sessions/session05/track.md), verified live in code; this carve builds
on it. This is a **schedule** first, with **one pinned design-shaped ruling** (`astv_input`, below) made
explicitly here — not left to an implementor — per the standing authorization (conservative + reversible
+ surprise-first)._

## Scope of this carve — M8 ONLY (the terminal slice)

M8 deletes the legacy text-input globals + the poll-a-reftable idiom and migrates the remaining
consumers to `compy.input.*`. **When M8-03 lands green with the globals gone, the whole sweep is
COMPLETE.** Authority chain (frozen): `ratified-model.md` → `design.md`+`spec.md` (Gate-2) →
`spec/M8-02-recut.md` (Gate-3). Higher authority wins; no architectural nouns outside the ratified
glossary; `design/` is read-only.

## The migration recipe (established at revalidation — the linchpin of every chunk)

Every legacy consumer uses the **poll-re-arm loop**: `r = user_input()` once, then each frame
`if r:is_empty() then <re-show> else <consume r()> end`. The landed submit lifecycle is:
Enter → `before_submit` → `ui:submit()` = `deliver()` (fires **`on_text_entered(text)` while active**)
then `hide()` → **`after_submit(text)` (after hide)**. So the poll loop maps to the **continuous-session
idiom**:

```lua
compy.input.show{
  prompt          = P,
  validator       = V,           -- or eval = InputEvalLua for Lua highlighting (tixy)
  on_text_entered = function(text) <consume> end,   -- fires while active
  after_submit    = function(text) compy.input.show{ prompt = nextP } end, -- re-prompt AFTER hide
}
```

- Consume in `on_text_entered`; **re-`show{}` in `after_submit`** — a `show()` inside `on_text_entered`
  warns (still active). Widget-output callbacks are sticky, so a bare re-show re-arms with the same
  callbacks/validator (`show{prompt=…}` is enough).
- `write_to_input(c)` → `compy.input.set_text(c)` (active-session live write).
- `input_text(p,i)` → `show{ prompt=p, text=i, on_text_entered=… }` (plain, default eval).
- `input_code(p,i)` → `show{ prompt=p, text=i, eval=InputEvalLua, on_text_entered=… }` (see tixy note).
- `validated_input(filters,p)` → `show{ prompt=p, validator=<filters>, on_text_entered=… }`.
- `user_input()` + poll → the `on_text_entered`/`after_submit` callbacks (nothing to poll).

This recipe is AC-4's sanctioned pattern and applies identically to tixy/repl/guess/valid. F-0
(deliver-then-hide) stays open — M8 does not touch it (no AC forces it).

## PINNED DESIGN-SHAPED RULING — `astv_input` (decided here, not by an implementor)

`consoleController.lua:873` (`if love.debug` → `project_env.astv_input = function() return input(LuaEditorEval) end`)
is a **sixth** input global on the same `input()`/reftable machinery M8 removes — **not** in the spec's
five-global census, and it **breaks mechanically** when the machinery goes. Census confirms **zero
consumers** (grep-clean, no example / no test). **RULING: remove it with the machinery** (M8-03).
Rationale: debug-only dev tooling + dead poll idiom + no release value in re-plumbing onto `compy.input`
→ conservative + reversible + mechanically-forced. **Flag surprise-first in the M8-03 outcome ledger.**
This is the one place M8 goes beyond the spec's literal census; it is called out loudly rather than made
silently. (Fable consult was available; the call leans clearly conservative — declined.)

## The carve — 3 chunks (grouped by delivery discipline)

Order rationale: **migrate consumers first, remove globals last** — a removed-before-migrated global
breaks its example. Chunks are grouped by delivery discipline so each has a homogeneous review + a clean
commit boundary: M8-01 in-repo (commits normally) · M8-02 nested checkout (delivery TBD at its gate, see
note) · M8-03 pure removal.

| Chunk | Slug | Surface | In-scope ACs | Status |
|-------|------|---------|--------------|--------|
| **M8-01** | in-repo-migrations | Migrate **tixy** + **repl** + **guess** + **valid** to `compy.input.*` (in-repo, commit normally). Establishes + applies the full recipe (`input_code`/`input_text`/`validated_input`/`write_to_input`/`user_input`→callbacks; tixy `eval=InputEvalLua` + `set_text`). | **AC-3** (tixy), **AC-5** (repl/guess/valid — convert; exclude only on a recorded genuine blocker), AC-6 (natives unaffected), AC-10 (suite green; globals still present this chunk) | ⬜ in progress |
| **M8-02** | balloons-migration | Migrate **balloons** (`terminal.lua`) to the continuous-session idiom. Nested checkout — **delivery discipline resolved at this chunk's gate** (see note). | **AC-4**, **AC-9** (nested `.git`), AC-8 edge cases (stop-while-active / show-while-active warn / validator-reject lock) on migrated examples | ⬜ blocked by M8-01 |
| **M8-03** | legacy-removal | Delete the five globals + `input_ref`/`input()`/`create_input_handle()` + the `text_input` dead write (M8-01 fold-in) + **`astv_input`** (ruling above). Close-out. | **AC-1** (nil-call), **AC-2** (dead write + poll surface gone), **AC-7** (`love.state.user_input` widget-only), AC-6, AC-8, **AC-10** (full suite green, nil-call asserted, priority examples exercised) | ⬜ blocked by M8-01, M8-02 |

### Why tixy leads M8-01

tixy is the richest in-repo migration (`input_code` Lua highlighting via `eval=InputEvalLua` +
`write_to_input`→`set_text` + the poll→callback re-prompt). Landing it first, test-first, **establishes
and verifies the whole recipe**; repl/guess/valid are then the same recipe applied to plain
text/validator cases. If the chunk proves too large mid-run, tixy lands alone and the three trivial ones
re-commission — not expected.

### `eval = InputEvalLua` note (tixy, AC-3)

tixy's Lua syntax highlighting migrates by passing `eval = InputEvalLua` through `show{}` (`show` passes
its cfg wholesale to `apply_config`, which reads `cfg.eval`). Reconstructing it via `highlighter=` on the
plain default eval is **not** equivalent. The spec's de-bound-helper-names note (§Contract) sanctions
using whatever evaluator mechanism the codebase provides. Implementor **verifies the highlighter actually
renders** (headless smoke + inspection); surprise-first flag that it uses the `eval` mechanism key rather
than the documented `highlighter`/`validator` keys. If `eval` does not flow through, that is a stop.

### Balloons delivery note (resolve at the M8-02 gate — do NOT pre-decide silently)

Frozen spec **AC-9** requires `balloons` to deliver as **uncommitted working-tree changes** with an
**untouched nested `.git`** (mandate guardrail 7 — the human carries the patch upstream). On 2026-07-11
the human **broadened** the standing grant to permit local commits inside detached example sub-repos.
These are not contradictory: the grant lifts a hard *prohibition*; AC-9 states the *intended delivery*.
**Default: honor AC-9 (frozen spec authority) — deliver balloons as an uncommitted patch, list files
in the ledger, leave `.git` untouched.** Surface the tension at the M8-02 gate; only commit-in-checkout if
the human explicitly redirects for balloons specifically (a frozen-AC change = a gate round, not a silent
call). Pinned here so the implementor does not decide it.

## Test strategy (per chunk)

Tier-2 test-first: red acceptance rows transcribed from the ACs precede implementation. Examples are
exercised **headless** in-container (`busted tests` + smoke-load where a harness exists); **human
hand-play is the final gate** for tixy + balloons (composition, submit, re-prompt loop, Escape dismiss) —
report, do not overclaim. M8-03's AC-1 nil-call assertions go green **only in that final chunk** (globals
present until then).

## Human hand-play gates this milestone will add (report-don't-block)

tixy (compose → submit → re-prompt loop → Escape) and balloons (continuous session) join the open
list (turtle input, maze show→Escape→reopen from M5c-05). Flag in the ledgers; do not block on them.
