# Outcome — M5c-05: example migration (turtle + maze,

chunk 5 of the M5c carve — final)

_Executed against
[`../prompts/M5c-05-example-migration.md`](../prompts/M5c-05-example-migration.md),
2026-07-11. Delivers **AC-32**. Native-wrap / AC-31/33/36 dispatch semantics
were already landed and green — not re-touched here._

## What will surprise the architect (read first)

1. **turtle's behaviour change is exactly the sanctioned one, no more.**
   `eval` used to run every `love.update` tick while the polled reftable
   was non-empty (in practice: once, since nothing cleared it, but
   structurally a per-frame poll); it now runs exactly once, synchronously,
   from `on_text_entered = eval` (`src/examples/turtle/main.lua:47-53`).
   `eval`'s signature (`function eval(input)`) already matches
   `on_text_entered(text)` exactly, so the callback is `eval` itself — no
   wrapper closure needed (simpler than the prompt's illustrative
   `function(text) eval(text) end`).
2. **maze's `rearm_input` is not a straight callback swap — it required a
   real design decision the prompt didn't spell out.** `UserInputController
   :submit()` calls `deliver()` (which fires `on_text_entered`) **before**
   `self:hide()` (`userInputController.lua:341-343`). That means inside the
   `on_text_entered` callback the overlay is still reported active
   (`love.state.user_input` still set), so a synchronous
   `compy.input.show{...}` call to immediately reshow-with-invalid-text
   would hit `show()`'s re-entry guard (`Log.warn` + no-op,
   `userInputController.lua:246-249`) and then get unconditionally wiped by
   the `hide()` that runs right after the callback returns. **Fix:** the
   reshow-on-invalid-input is deferred one frame — `handle_editor_submit`
   sets `need_reopen`/`reopen_text` instead of calling `show()` directly;
   the next `love.update` tick's `rearm_input()` (still wired as
   `ctrl_update`) picks it up once the overlay has actually finished
   hiding. This also replaces the old per-frame reftable poll with an
   `input_open` guard so `rearm_input` no-ops while the widget is up,
   instead of re-issuing `show()` every frame (verified: no warning spam
   during a multi-second headless run — see Verification).
   Net visible effect: the "reshow with the bad text after Enter" flash is
   one frame (~16 ms) later than before — imperceptible, and squarely the
   kind of "old feel differs" change SR1 sanctions, not a capability gap.
3. **Verification ceiling is honest, not "verified playable."** No
   `xdotool` (or equivalent) is available in this container to synthesize
   keystrokes into the Xvfb-backed LÖVE window, so the actual submit/Enter
   path was **not** exercised end-to-end. What was verified: full contract
   suite unchanged, headless load-without-traceback for both examples via
   `love src play <example>`, and — for maze specifically — several
   seconds of the live `editor()`/`rearm_input` loop running under Xvfb
   with zero warnings/errors (which does exercise the `input_open`/
   `need_reopen` state machine's steady-state branch, just not the
   submit-triggered branches). **True hand-play (typing a command, hitting
   Enter, watching the turtle move / maze respond, including the
   invalid-input reshow) is the human's final AC-32 gate.**

## Commit refs

- turtle + this ledger: committed to `/repo` (see `git log` after this
  ledger lands — Conventional Commits, not pushed).
- maze: **uncommitted working-tree changes**, guardrail 7 — see file list
  below; never `git add`/`git commit` inside `src/examples/maze/`.

## Files changed

**turtle (tracked in /repo, commits normally):**
- `src/examples/turtle/main.lua` — removed `local r = user_input()`;
  `love.keyreleased`'s `i` branch now calls `compy.input.show{ prompt =
  "TURTLE", on_text_entered = eval }`; `love.update` no longer polls `r`.

**maze (nested checkout — `src/examples/maze/`, own `.git`, NOT tracked by
/repo; delivered uncommitted per Gate-3 guardrail 7):**
- `src/examples/maze/controls.lua` — `editor()`: removed `GS.input =
  user_input()` + `input_text(...)`; now `ctrl_update = rearm_input` +
  `open_editor_input()`.
- `src/examples/maze/main.lua` — removed `process_user_input` and the old
  reftable-based `rearm_input`; added `input_open`/`need_reopen`/
  `reopen_text` state, `open_editor_input(text)`, `handle_editor_submit
  (text)`, and a new `rearm_input()` built on the callback + deferred-
  reopen design above. `record_echo` unchanged.

(Confirmed via `git -C src/examples/maze status --short`: exactly these
two files modified, nothing staged/committed there.)

## Verification

- **Full suite (`busted tests`):**
  - Before: **779 successes / 0 failures / 0 errors / 5 pending.**
  - After: **779 successes / 0 failures / 0 errors / 5 pending.** (Unmoved
    — expected, examples are not suite-covered.)
- **LSP (`mcp__lua-lsp__diagnostics` + `references`)** on all three touched
  files: no new diagnostics — only the pre-existing systemic
  `lowercase-global` INFO noise (this codebase's globals-as-module-state
  style, present throughout both files before this change) and pre-
  existing, unrelated warnings elsewhere in `maze/main.lua` (duplicate
  `resize` field, a `need-check-nil`, a `param-type-mismatch` — none on
  touched lines). `references` on `eval`, `rearm_input`, and
  `open_editor_input` confirm every call site resolves to the intended
  definition and no stray caller of the removed `process_user_input`/
  `GS.input` remains (cross-checked with `grep -rn` as backstop — zero
  hits for `input_text|user_input()|GS\.input|process_user_input` in
  either example).
- **Headless load-without-traceback** (`xvfb-run -a love src play
  <example>`, backgrounded + log-file capture since `timeout | tail`
  hangs — `xvfb-run` doesn't forward SIGTERM to the LÖVE child):
  - turtle: loaded and ran ~9s with only ALSA "Could not open device"
    noise (expected, no audio device in the container) — no Lua
    traceback.
  - maze: loaded and ran ~12s in `editor()` mode (so `rearm_input` fired
    every frame via `ctrl_update`) with the same ALSA-only noise, no
    traceback, and **no `Log.warn` spam** from `UserInputController:show`
    — i.e. the `input_open` guard is doing its job (not re-issuing `show()`
    every idle frame).
  - Both processes killed cleanly after observation (`pkill -9`), no
    orphaned `love` processes left running.
- **Not verified (the honest gap):** actual keystroke-driven submit/cancel
  — no `xdotool`/equivalent in this container. See surprise #3 above.

## AC-32 checklist

| Item | Status | Note |
|---|---|---|
| turtle migrated off `input_text`/`user_input` poll | met | `main.lua:47-53`; `love.update` poll removed |
| turtle `on_text_entered` fires once/submit (R1) | met by construction | `eval` is the direct callback; `deliver()` calls it exactly once per `submit()` |
| maze migrated off `input_text`/`user_input` poll (all 3 call sites: `controls.lua:21`, `main.lua:458`, `main.lua:474`) | met | replaced by `open_editor_input`/`handle_editor_submit` |
| maze command flow reaches `process_input` via the callback | met | `handle_editor_submit` → `string.lines(text)` → `process_input(lines, offset)`, same as before |
| maze's queue-drain gate (`not player.anim and #(player.queue)==0`) preserved | met | now the else-branch of `rearm_input` |
| maze's mousepressed / natives left alone (AC-28/AC-31) | met | `love.mousepressed = SYSTEM_KEYS.menu`, `love.keypressed`/`keyreleased` untouched |
| hand-playable | **unverified — human gate** | see Verification's honest gap |

## Per-remark disposition (AC-34)

No `-- REVIEW:` / `>> REVIEW` / SCOPE markers exist in
`src/examples/turtle/main.lua`, `src/examples/maze/main.lua`, or
`src/examples/maze/controls.lua` (checked via `grep -n "REVIEW\|SCOPE"` on
all three — zero hits). Nothing to dispose.

## Surfaced gaps / judgement calls

- **Judgement call (small, reversible, flagged loud):** the deferred-reopen
  design (`need_reopen`/`reopen_text`) is not spelled out in the prompt's
  "landed surface" section — it follows from reading `submit()`'s
  deliver-then-hide ordering in `userInputController.lua`. This is a
  mechanical consequence of the already-landed, already-frozen submit
  sequencing (not a new design ruling, not a missing M5c capability) — the
  most-conservative fix (defer one frame, reuse the existing per-frame
  `ctrl_update` hook already in place) was applied rather than escalating.
- No true M7 dependency and no route-model change was needed — the
  callback surface as landed (`prompt`/`text`/`on_text_entered`) was
  sufficient for both examples.
