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

## 2026-08-27 — owner rulings at the gate

- **Incidental finding → debt ledger now** (owner). Filed in `technical_debt/input.md` beside "A
  raise from project top-level and from a handler surface differently" — same class, different
  cause. Revisit after the PR, with its sibling. `2474df20`.
- **Ruling re-made: granted, "trivial"** — `compy.input.callbacks` *resolves to* the current
  widget's table. Consequence is work, not risk: three code comments quote the old wording as **IS**
  (`main.lua:367`, `consoleController.lua:776-777`) and are corrected in ARC-01-02.
- **Owner asked whether Decision 3 was amended. It was not, and it was not a step** — it lived as
  prose in the row's "two obligations", which is how things get lost (roadmap rule 5). Now
  **`ARC-01-03`**, an owner-gated ledger step before any lifetime code.
- **Found while filing it: Decision 7 needs the same amendment, and nobody had noticed.** It freezes
  the *identity* of `callbacks`; a per-run widget changes that identity between runs. Unobservable
  to a project (within a run both hold), but "amend, don't reinterpret" applies to it too. Folded
  into the same step.
- Second renumber today: 03→04, 04→05, 05→06, and the old churn step is now 07. Two-insert crosswalk
  table shipped in the row, including a line mapping session48's own prompt (immutable) onto the new
  numbers.

## 2026-08-27 — ARC-01-02 landed (`e684458b`)

- Three breaking tests first (all red before the change): callbacks assignment must land on the
  CURRENT widget; a hidden `configure()` must stash on that widget; with no widget there is no store
  and no raise. Then the shape change: `state.callbacks` / `state.pending` resolve through a
  metatable (`widget_store`) instead of being captured at closure build.
- Readers updated: `merge_callback_keys`, `consume_pending`, `stash_hidden_configure` all treat "no
  store" as "nothing to remember". `build_input_surface` resolves `callbacks` per access; `hooks`
  and `shortcuts` stay the surface's own.
- **The ordering constraint is gone, and the ARC-01-01 probe proved it by failing:** re-running the
  archived nil-audit probe, only C7 fails now — constructing a ConsoleController with no widget no
  longer raises. That was the blocker on ARC-01-04.
- Comment/doc sweep for the re-made ruling: `main.lua` (claimed the boot order was load-bearing —
  it is not), `userInputController.lua` ×2, the fixture's copy of the same claim, and the internals
  guide's "**is this exact same table**" → "**resolves to**".
- Suite **970 → 973**, three added, none changed or removed. LSP diagnostics clean on all three
  touched src files.
- Scope boundary checked and recorded in the roadmap rather than acted on: `compy.input`'s own
  `shortcuts`/`hooks` stay application-lifetime, but their teardown walks `_bindable` — *the
  dispatcher's own channel list* — so it cannot drift the way the widget's field-by-field wipe did.
  Suspected sibling defect, checked, **phantom**. Worth the five minutes; a reviewer will ask.
- Runtime smoke: sapper under harmony behaves exactly as before the change, no errors.
- **A harmony smoke error, attributed rather than assumed.** The full scenario suite surfaced
  `editorView.lua:70: attempt to index local 'bm' (a nil value)` (`get_current_buffer` ←
  `editorController.submit`). Re-ran the whole suite against the PRE-change `src/`: **same error,
  same line, once, in a 45-line log identical in length to the post-change one.** Pre-existing,
  unrelated to ARC-01-02 — an editor-scenario failure nobody has filed. NOT filed by me either:
  it is outside this feature and outside the input subsystem; raising it with the owner instead.

## 2026-08-27 — ARC-01-03 drafted, NOT applied

- Wrote `validation/reviews/ARC-01-03-ledger-amendments-draft.md`: exact replacement text for both
  decisions, so the ruling is a yes/no on words rather than on a summary of them. The ratified
  ledger is untouched.
- **The two amendments are not the same kind of thing, and the ledger already has a convention for
  each.** Decision 3 substantively changes (creation boundary for one of four instances) → Decision
  11's style: an `AMENDED IN PART` header note plus a `Decision (as amended)` paragraph. Decision 7
  does NOT change — only the scope of "frozen" needs saying — → the `Amended in place` blockquote
  style. Saying Decision 7 changes would overstate it.
- **Verified the base claim myself before writing it into a ledger amendment** rather than
  inheriting it from the roadmap: at `3256aac`, `input()` builds `UserInputModel`,
  `UserInputController` AND `UserInputView` on every `input_text`/`input_code` call
  (`consoleController.lua:563-580` at base). Per-activation confirmed; "per-run allocates less than
  the base did" is safe to state to a stakeholder.
- Dropped a premature claim from the draft: it named where construction would live (a file), which
  is ARC-01-04's decision, not this step's. Now says "at the run seam".
- One question left open for the owner deliberately: does the PR description carry the amendments or
  only the behaviour? Recommended one line in the justification table.

## 2026-08-27 — two owner rulings

- **PR carries only the behaviour** (owner). The amendments stay in the ledger; the description does
  not recount them. My justification-table recommendation is settled in the narrower direction and
  the draft records it. Note carried forward: the deviation rule still applies to the internals
  guide and the code — only the PR description is exempt.
- **The `bm` raise goes into a persistent ledger** (owner) — `technical_debt/general.md`, not
  `input.md`: it is an editor defect, and general.md is the persistent home for debt outside the
  input subsystem.
- Characterised before filing: `get_active_buffer` is `buffers:first()`, nil when the list is empty,
  and **three** call sites index it unguarded (`get_current_buffer`, `get_active_buffer_id`,
  `_generate_status`). Deterministic repro named (`editor.open-close`, Ctrl+Shift+S after `edit()`).
  **Root cause deliberately NOT claimed** — why the buffer list is empty right after `edit()` on a
  fresh project is undiagnosed, and the entry says so rather than guessing.
- **The amendments themselves are still unratified.** The owner answered the open question, not the
  ruling — ARC-01-03 stays gated, ARC-01-04 does not start.

## 2026-08-27 — ARC-01-03 applied (ratified verbatim)

- Owner ratified the drafted text ("ok let it be go ahead"); both amendments applied to
  `doc/development/decisions/input.md` **exactly as shown**, nothing added.
- Decision 3: `AMENDED IN PART` note + `Decision (as amended)` + rewritten `Why` (now carrying the
  base-allocation fact and what per-run buys) + Consequence's first sentence. Decision 7: the
  single `Amended in place` blockquote, decision text untouched.
- Citations safe: all 13 `Decision 3` references in `src/`+`tests/` cite the NUMBER, not the
  heading, so nothing dangles. Suite still 973.
- **Raised, not acted on:** Decision 3's HEADING still reads "a boot-provisioned widget per surface,
  not per-session construction", which is now wrong for one of the four instances. The `AMENDED IN
  PART` note directly beneath corrects it, and Decision 11 shows the ledger does update headings —
  but the owner ratified body text, not a heading change, so it waits for a word.

## 2026-08-27 — ARC-01-05, -06, and the wrap

- ARC-01-05 landed in two commits, one concern each: the dead machinery deleted (`55f9edd4`), then
  `close_project` destroying its widget (`e13ef346`). Debt entry filed FIRST at the owner's
  direction (`b658b959`) — it is true regardless of the fix.
- **My first close_project fix was wrong and the new test caught it**: destroy sat inside
  `if open then`, and `F.run_project` restores `P.current`, so the branch never ran. Moved ahead of
  the check. Also discarded my own uncommitted fix with a `git checkout -- src/` while setting up
  the mutation check — second careless git command today, after `git add -A src/`.
- Cold review came back **approve** with one real finding (the dead teardown function — which was
  ARC-01-05's target, reached independently from the code) and a correction to my citation count
  (12, not 13: my grep matched `Decision 30`/`32`/`33`). It **missed close_project**.
- Owner swapped ARC-01-06/-07 so ids match execution order — their words: the original order was
  their mistake. Crosswalk now shows both hops.
- ARC-01-06 (fixture seam) was mostly already done inside -04; the sweep found one real bug
  (`F.show_widget` drove the fixture's stale local) and three comments still asserting the old
  lifetime, one of which named teardown as "the only clearer".
- Wrapped: report, session49 prompt commissioning ARC-01-07 for a COLD session, pointer repointed,
  roadmap status updated to 979.
