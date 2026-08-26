# session47 track

## 2026-08-26 — boot

- Fresh start: session47/ held only `prompt.md`; no track, no report. Guardrail → begin.
- HEAD `6867236b` (docs(session46): wrap). Working tree: only the known untracked scratch
  (`claude.sh`, `input-pr-slices.tar.gz`, `repos.txt`, `src/STEPS.md`, `worklog.md`,
  `src/examples/{balloons,keyboard,maze}/`) — all named as non-anomalies in `agents/validation.md` §3.
- Suite: **968 / 0 / 0 / 10** — matches the mandated baseline exactly.
- Read: `agents/sessions.md`, `agents/validation.md`, session47 `prompt.md`, session46 `report.md`,
  `ROADMAP.md`, `agents/rules/roadmap.md`.
- **Predecessor track deliberately NOT read**: session47's prompt directs "do not re-derive session46
  from its track — the report is the handover, and the track is long." Prompt overrides the boot
  ritual's step 4 here.
- Mode: **execution**. Mandate = work the roadmap top-down starting at `BUG-01-01`, verifying each row
  before fixing it.
- Reported the task to the owner and paused for a go-signal before touching BUG-01-01. Owner: "go".

## 2026-08-26 — BUG-01-01 CLOSED, fixed

- **Confirmed in code before fixing**, per the prompt's opening rule. `prepare_project_env` is called
  ONCE (`ConsoleController.new:80`) → `state.pending` has application lifetime. Deep `table.clone`
  does not separate instances: the surface is metatable-only and the metatable closes over one
  `state`.
- **Q1 (siblings share the hole?) → NO.** `reset_compy_input` wipes shortcuts/hooks by name off
  `_bindable`; `reset_callbacks` re-seeds callbacks in place. `pending` was the sole survivor — which
  is why the fix stayed small. Blast radius resolved from UNKNOWN to narrow.
- **Q2 (reachable from a shipped example?) → not demonstrably.** balloons configures while shown;
  maze guards with `is_shown()`. Fixed on the merits anyway: hidden-configure stashing is public,
  documented API.
- Not a deviation: Decision 11's teardown invariant already forbade it ("no ... widget configuration
  survives the project that installed it"); an unapplied draft IS widget configuration. So the fix
  **restores** a stated contract. Invariant now names the draft; internals doc says run-scoped.
- Fix shape: draft moved to the widget beside `callbacks`, which lives there for the same lifetime
  reason. Teardown wipes it in `reset_widget_outputs`. **No public surface added** — the alternative
  (a teardown handle threaded out of the closure) would have cost one.
- Breaking test first, in `stop teardown` — failed on the leaked draft, passes after. Suite
  **969 / 0 / 0 / 10**.
- Commits: `bd2a5d49` (fix + test + behaviour docs), `abadf244` (false-premise debt entry). Two
  concerns, two commits.
- Evidence note: `validation/notes/BUG-01-01-pending-lifetime.md`. Roadmap row struck through, suite
  count in the header updated.
- **TOOLING:** `lua-lsp` MCP is DOWN — `broken pipe` on every call including a bare `references`.
  Fell back to grep read at each site. Retry before assuming it is gone; it is the correctness tool
  for the rows still ahead (BUG-01-04 touches combo serialisation, DEC-01 has 165 code citations).
