# session48 track — execute ARC-01 (project widget gets a run lifetime)

## 2026-08-26 — boot

- Boot ritual per `agents/validation.md`: read sessions.md, validation.md, session48/prompt.md,
  session47/report.md, ROADMAP.md §ARC-01 (lines 35–169).
- Re-entrance: no `track.md`, no `report.md` on disk → **fresh start**. This is the first
  incarnation of session48.
- HEAD `f9c26456` (docs(session47): wrap). Working tree: only the known untracked scratch
  (`claude.sh`, `input-pr-slices.tar.gz`, `repos.txt`, `src/STEPS.md`, `src/examples/{balloons,
  keyboard,maze}`, `worklog.md`) — matches guardrail 3, nothing of ours pending.
- Baseline suite: **970 / 0 / 0 / 10** — matches the prompt's authoritative number. Go-signal.
- **lua-lsp MCP is back up** — the owner ran `/mcp` and reported "Reconnected to lua-lsp" at boot.
  The prompt's caution about it being DOWN is resolved; ARC-01's "who caches this object" question
  can be asked of the AST.
- Mandate understood: execution session, start at `ARC-01-01` (verification only, no code) —
  (1) nil audit of the four `love.state.user_input_controller` consumers, tested not read;
  (2) pen-and-paper (sapper) confirmation with a real project. Pivot before code if it opens up.
- Reported the task to the owner before proceeding, as asked.

## 2026-08-26 — owner adds a step before work starts

- Owner: file "why two reconfiguration policies coexist in the widget instead of uniform logic, and
  is prompt using the wrong policy?" as a step — explicitly **do not dive into it**, just record it.
- Filed as **ARC-01-05** (ahead of the churn step, since it lands in `apply_config`, the function
  ARC-01 already reshapes, and may escalate into a design call — roadmap rule 3). Old ARC-01-05
  (fixture seam + spec fallout) → **ARC-01-06**, crosswalk shipped in the row. `c1c0db55`.
- Behavioural: the owner files a question the moment it occurs to them rather than pursuing it —
  second time this phase the ledger is used as a memory rather than a plan.

## 2026-08-26 — ARC-01-01 executed: both questions answered by experiment

- **Nil audit: all consumers safe.** Probe spec (nil the widget after boot, drive each consumer
  through the real gateway), 12 cases green. Then **mutated every guard away and re-ran** — C1/C2/
  C4/C5 all fail unguarded, so the probe is load-bearing.
- **The near-miss worth remembering:** mutating the *dispatch* guard produced a GREEN run. Not
  because the guard is idle — because `with_canvas_and_errors` xpcalls the walk, so the raise is
  swallowed and printed. Instrumented `dispatch` with a print to prove the line is reached with
  `widget=nil` on all 8 events, then rewrote the probe to assert on the **error channel**
  (`suspend_msg`, `app_state`). Re-mutated: fails. Had I trusted the first green, ARC-01 would have
  carried a "verified" claim that was exactly backwards.
- **C7:** constructing a ConsoleController with the widget nil RAISES — ARC-01-02's ordering
  constraint, now empirical rather than argued.
- **Pen-and-paper CONFIRMED in the real app.** Harmony scenario + sapper under xvfb: through
  `run_project`, alive and playable at `project_open` (screenshot: 12 cells opened), and
  `stop_project_run` fires once, entered *from* `project_open`. Both seams reachable; the transition
  between them is not one.
- Instrumentation gotcha recorded: harmony's synthetic mouse events are discarded as drift unless
  `love.mouse.getPosition` follows them. First run looked like "pointer never reaches a project at
  project_open" — a false finding one line away from the true one.
- Incidental, base-checked, out of scope: at `project_open` a raise in a project hook is swallowed
  whole (`suspend_run` early-returns unless `running`) — so pen-and-paper projects report errors
  worse than normal ones. Verbatim at base `3256aac`, so not ours. Reported, not fixed.
- Probes archived under `validation/notes/ARC-01-01-probes/`; nothing left in `src/` or `tests/`;
  suite back at **970 / 0 / 0 / 10**.
- **Verdict: no can of worms. ARC-01-02 is next.** Holding at the gate for the owner.
