# W7 / A4 + A5 — "it freezes", "no visible error", "I don't see what I typed"

**Date:** 2026-07-31 · **Session:** 24 · **Verdict:** one defect behind most of
the cluster — **pre-existing, not a feature regression**, reproduced headlessly
and **fixed** (`e80c644` — `fix(input): paint the overlay on the console draw
path too`). tixy's vanishing legend (A5) is **by design in the example**.

## The one defect: an input-only project's overlay was never painted

The overlay widget had a single paint site: the wrapper `set_love_update`
installs around `love.draw` — and it installs **only when a project has
replaced `love.draw`** (`controller.lua`, `local ddr = View.prev_draw ... if
ldr ~= ddr`). A project that hooks no draw at all keeps the console's own draw
function, which painted the console frame and never the overlay.

Measured, not inferred (scratch probe over the real `run_project`, counting
calls to the overlay view's `draw` across two frames):

| project | `love.state.user_input` | overlay painted |
|---|---|---|
| hooks `love.draw` | set | 2 / 2 frames |
| hooks nothing (guess, valid, repl, sapper) | set | **0** |

So the widget consumed every keystroke — the project route owns keyboard and
text while the project is live — and the screen kept showing the **console's**
input line underneath it. That single fact produces the whole complaint set:

- **"I don't see what I typed" / "no prompt"** — the surface showing the draft
  and the prompt was the one not being painted.
- **"black instead of blue input bar"** — the black bar is the console's own
  always-shown input line; the blue overlay was simply never drawn over it.
- **"no signal that I left the console"** — same cause: nothing on screen
  changed when the overlay came up.
- **"it freezes" (guess 1, valid 9)** — the documented error lock is real and
  correct: a rejecting validator sets the error, `textinput` is dropped and
  `keypressed` is swallowed except Enter/Space/arrows, which clear it. The
  error text IS produced and rendered — `submit_flow` → `set_error` →
  `wrapped_error` → `UserInputView:render_error`, confirmed by a probe that
  spied the render calls: the rejecting submit re-renders with
  `Errors:/…` in the same keystroke. It is rendered **into the widget's own
  canvas**, which was never blitted. So the lock was invisible and its exit
  undiscoverable — indistinguishable from a freeze, exactly as the triage
  predicted.

### Why it is not a regression

The draw wiring is byte-identical at the PR base (`3256aac`) — both the
`set_love_update` wrapper and `ConsoleView:draw`. Pre-feature the legacy
`user_input()` published the same `{ M, C, V }` handle into
`love.state.user_input`, so an unpainted overlay was equally possible. What
changed is **reachability**: ruling (a) (`technical_debt/input.md`,
"Input-only / pointer-only projects stay live in `project_open`") made
input-only projects live for the first time, which put the gap directly under
the examples that demonstrate the new API.

### Fix

Three lines in `Controller.set_love_draw`: after `View.draw(CC, CV)`, paint the
overlay through `get_user_input()` — the same call the update-loop wrapper
uses, so the `inspect` gate (Decision 12) is inherited rather than duplicated.
No double paint, since the wrapper installs only when `love.draw` has been
replaced and the console path never replaces it (verified: the drawing project
still paints exactly once per frame).

Pinned by three rows in `input_widget_lifecycle_spec.lua` ("a shown overlay is
painted"): the console path paints a shown overlay, a hidden one is not
painted, `inspect` keeps it unhonoured. They assert the **wiring** — the frame
reaches the overlay's view — against the fixture's view stub, never pixels.

## A5 · tixy: the top-right text disappearing on Enter is the example's own code

`src/examples/tixy/main.lua`: `legend` is the top-right caption
(`drawText`, `gfx.printf(legend, midx + hof, sof, …)`), set from `ex.legend`
when a canned example is advanced, and cleared by the example's own
`submit_body` (`legend = ""`). Submitting your own formula retires the caption
that described the canned one. No framework involvement; nothing to fix unless
the owner wants the example to behave differently.

## Left open

- Whether the error band should ALSO be surfaced outside the widget (the A3
  ruling on "how a contract violation reaches the author" is adjacent, and the
  now-visible error band changes what that ruling is choosing between).
- Whether an error lock with no on-screen exit hint is acceptable now that it
  is visible at all — the exit keys (Enter/Space/arrows) are documented but not
  shown to the user.
