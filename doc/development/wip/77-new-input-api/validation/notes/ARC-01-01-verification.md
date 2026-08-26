# ARC-01-01 — the nil audit and the pen-and-paper question, both confirmed by experiment

_session48, 2026-08-26. Both questions were **tested, not read** — that was the mandate, because
session47 had read them. Probes are archived verbatim in
[`ARC-01-01-probes/`](ARC-01-01-probes/); neither was left in `tests/` or `src/`._

**Verdict: no can of worms. ARC-01 may proceed to `ARC-01-02` as filed.**

## Q1 — the nil audit: does every dynamic consumer survive a nil widget?

**Yes, all of them.** A probe spec nils `love.state.user_input_controller` after boot and drives each
consumer through the production gateway. 12 cases, all green.

The interesting half is that **every guard was then mutated away and the probe re-run**, because a
passing test proves nothing until you know it would have failed. Each mutation was applied to a
clean tree, run, and reverted.

| # | consumer | guard | mutation verdict |
|---|---|---|---|
| C1 | `hide_input_widget` (`consoleController.lua:183`) | `if widget then` | **load-bearing** — unguarded, every case errors |
| C2 | `reset_widget_outputs` (`controller.lua:349`) | `if not ui then return end` | **load-bearing** — 5 cases error |
| C3 | `dispatch` (`projectInputController.lua:158` → `:143`) | `if widget and widget:is_shown()` | **load-bearing, but see the trap below** |
| C4 | `api_show` / `api_hide` (`consoleController.lua:666,672`) | `if ui then` | **load-bearing** — 1 case errors |
| C5 | `get_active` → the whole `build_widget_api` surface (`:809`) | `return w and w:is_shown()` | **load-bearing** — 4 cases error |
| C6 | `userInputView:draw` (`userInputView.lua:294`) | self-identity compare | **unreachable, by construction** — see below |

**C6 is reasoned, not probed, and the reason is that it cannot be otherwise.** The comparison
`self.controller ~= love.state.user_input_controller` is an identity test made by *every*
`UserInputView`. For the console's and the editor's views the two sides already differ, so nil
changes nothing. For the project widget's own view, the view is a field of the widget — when the
widget does not exist, neither does the view, and nothing draws it. There is no state in which a
nil widget and a live project-widget view coexist.

### The trap in C3, which nearly produced a wrong verdict

The dispatch walk runs inside `with_canvas_and_errors` (`controller.lua:168`), which `xpcall`s it and
routes a raise to `suspend_run`. **A raise on that path does not fail a test, and does not stop the
app** — it prints and moves on. The first mutation run of C3 therefore came back *green*, which
reads as "the guard is not load-bearing" and is the exact opposite of the truth: the guard was
mutated, the error *was* raised on all eight events, and it was swallowed.

Instrumenting `dispatch` with a print settled it — the widget line is reached with `widget=nil` for
all eight events — and the probe was then rewritten to observe **the error channel**
(`love.state.suspend_msg` stays nil, `app_state` stays `running`) instead of the absence of a crash.
Re-mutated, it fails. **Any future nil-safety assertion on the dispatch path must assert on the
error channel; "the suite is green" is not evidence there.**

### One incidental finding, out of ARC-01's scope, base-checked

While establishing the above: **at `project_open` a raise in a project hook is swallowed entirely** —
no error window, no state change. `user_error_handler` calls `CC:suspend_run`, and `suspend_run`
early-returns unless `app_state == 'running'` (`consoleController.lua:1337`). Probed both ways:
raising while `running` sets `suspend_msg`; raising at `project_open` sets nothing.

That resting state is exactly where pen-and-paper projects live, so **sapper's error reporting is
weaker than a normal project's**. **The early return is base code** — verbatim at `3256aac` — so
this is neither ours nor a regression. Recorded as an observation for the debt register's owner to
rule on, per `agents/development.md` (report, do not fix). It has no bearing on ARC-01.

### C7 — the by-reference capture, confirmed as the ordering constraint

The probe also pins `ARC-01-02`'s reason for existing: with the widget nil, constructing a
`ConsoleController` **raises**, because `get_compy_input` indexes `widget.callbacks` and
`widget.pending` at closure-build time (`consoleController.lua:799,804`). This is the empirical form
of the roadmap's "must land BEFORE `ARC-01-03`".

## Q2 — pen-and-paper projects: confirmed with sapper, in the real app

Run: `xvfb-run -a love src harmony`, with the other four scenario files moved aside and restored, a
probe scenario that wraps `run_project` / `stop_project_run` / `close_project` and logs
`app_state` + widget identity at each step. Log and screenshots archived.

```
ARC01| boot                   state=ready         widget=table: 0x…9d8 handle=nil
ARC01| >> run_project sapper  state=ready         widget=table: 0x…9d8 handle=nil
ARC01| << run_project         state=project_open  widget=table: 0x…9d8 handle=nil
ARC01| settled after run      state=project_open  widget=table: 0x…9d8 handle=nil
ARC01| after doubleclick      state=project_open  widget=table: 0x…9d8 handle=nil
ARC01| after 2nd doubleclick  state=project_open  widget=table: 0x…9d8 handle=nil
ARC01| after C-S-q            state=project_open  widget=table: 0x…9d8 handle=nil
ARC01| >> stop_project_run    state=project_open  widget=table: 0x…9d8 handle=nil
ARC01| << stop_project_run    state=project_open  widget=table: 0x…9d8 handle=nil
```

Three facts, each of which the row needed:

1. **Sapper goes through `run_project`.** Construction at that seam reaches pen-and-paper projects.
   The read was right.
2. **It settles at `project_open` and is fully alive there** —
   [`sapper-live-in-project-open.png`](ARC-01-01-probes/sapper-live-in-project-open.png) shows a
   started game, twelve cells opened and the status panel updating, all while `app_state` is
   `project_open`. So the `running → project_open` transition must **not** destroy anything, which
   is the trap the row states.
3. **`stop_project_run` fires exactly once, at the real end**, and it fires *from* `project_open`
   — not from `running`. The destruction seam is reachable for pen-and-paper projects, and reachable
   only once.

**Sapper never shows the input widget at all** (`handle=nil` throughout). It is the strongest case
for the *reachability* of the seams and says nothing about widget content — which is fine, because
the question asked was whether it loses a widget, and the answer is that its widget is created and
destroyed at two boundaries it demonstrably passes through.

### Instrumentation note, worth keeping for the next runtime probe

Harmony's synthetic mouse events are dropped by the derived single/double-click channel unless the
**pointer follows them**: the channel re-samples `love.mouse.getPosition()` when the click window
closes and discards the click as drift (`controller.lua:580`, `no_drift`). The first probe run
produced a board that never changed and looked like "pointer does not reach a project at
`project_open`" — a false finding one line of `love.mouse.getPosition = …` away from the true one.
