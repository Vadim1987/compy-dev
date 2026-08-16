# P-20-02 — session43's evaluation of the session39 tail revalidation

Worker report: `../outcomes/S43-P-20-02-session39-revalidation.md`. This is the
parent session's judgement: what I re-verified, what I accept, and the finding
the revalidation did not reach.

## Verdict: the tail's work is sound as far as it goes — but it does not close what it believes it closed

The worker's verdict (SOUND) is correct **within the scope it checked**: the
code implements the ruling, the combos are canonical, the teardown path is
shared, the numbers reproduce. I confirmed the load-bearing parts myself. But
the step's purpose was to **restore an upstream gesture family**, and for two of
its four members the platform overrides the restoration. See the finding below.

## Re-verified independently

- **`da9d1c2` registers exactly three combos**, both files, each through the
  same `stop_here(on_escape)` wrapper as the pre-existing `shift+escape`:
  `alt+shift+escape`, `ctrl+shift+escape`, `ctrl+alt+shift+escape`.
- **The combo strings are canonical.** `Key.mod_triples` fixes precedence
  ctrl < alt < shift (`src/util/key.lua:15-19`, Decision 8), so
  `ctrl+alt+shift+escape` is the correct serialisation, not a near-miss that
  would silently never match.
- **The family is exhaustive**, which the worker implied but did not argue:
  `mod_triples` names only ctrl, alt and shift, so a held Super/GUI never enters
  a combo string. Four registrations therefore cover every combo the model can
  produce for Shift+Escape — nothing is left out.
- **The S3 attribution point holds.** `S39-P17-cold-review.md:11-21` names Alt
  and Ctrl only; Ctrl+Alt was the tail's own (correct) generalisation, and
  `session39/report.md:9-11` attributes all three to the review. Documentation
  drift, no consequence.

## The finding the revalidation did not reach — S2

**Two of the four restored variants are overridden by the platform, on release.**

The framework's gateway reserves Ctrl+Escape at the **raw pump entry**, on
`keyreleased`, before any route is forwarded to
(`src/controller/controller.lua:882-890`): `Key.ctrl()` and `k == 'escape'` →
`love.event.quit()` → `love.quit` → with `app_state == 'running'` →
`CC:stop_project_run()` (`:653-684`).

So in maze today, Ctrl+Shift+Escape does this: **on press** the project shortcut
fires and the game returns to its own menu; **on release** the platform stops
the whole project back to the console. Same for Ctrl+Alt+Shift+Escape. Upstream
— plain LÖVE, no gateway — simply went back one level and stayed in the game.

Reproduced: `../notes/S43-ctrl-shift-escape-probe.lua`, driven through the real
`love.handlers` with ctrl+shift held. Note the first run of that probe proved
nothing, because the mock stubs `love.event.quit` to a no-op; the probe now
models what the real loop does (enqueue, then call `love.quit`, truthy return
aborting the exit). Result: shortcut fired 1, quit asked 1, aborted true,
`stop_project_run` 1.

**This is not a regression `da9d1c2` introduced** — before it, the two ctrl
variants were unregistered and the teardown happened anyway, without the menu
step. What the commit does is register a gesture the platform partially owns,
so the restoration is cosmetic for those two: the player sees the game's menu
appear and the project torn down behind it.

**It is also exactly the property P15 pinned** — *a project cannot suppress a
platform combo by naming it*. P15 proved the rule; this is the rule biting a
real project, in the one step that assumed otherwise.

Timing caveat, stated because it bounds the finding: the gate needs Ctrl still
held when Escape is released. A player who lifts Ctrl first escapes it. The
ordinary release — Escape first, or everything together — hits it.

## For the owner

The step's claim "the narrowing is closed" is true for `shift+escape` and
`alt+shift+escape` and false for the two ctrl variants. Three options, none of
them mine to pick: accept and document the divergence (upstream parity is
unreachable here by construction); drop the two ctrl registrations as promises
the platform cannot keep; or raise the gate's reservation as a design question
(P15's own row notes the gate "is not an exempt list of privileged combos" and
that it could carry a real table — currently uncommitted, and out of this PR's
scope).

## Not re-checked

Live keystroke injection, and the maze suite / headless launches the worker
re-ran; the container cannot inject a key, which is the same boundary the cold
review named and handed to human smoke.
