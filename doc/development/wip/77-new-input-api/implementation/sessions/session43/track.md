# session43 — track

## 2026-08-16 — boot

- Booted per `agents/validation.md` + `agents/sessions.md`. Fresh start:
  session43 held only `prompt.md`; no track or report existed.
- HEAD `b54c0778` `docs(session42): wrap P9c and P13 work`. No tracked
  modifications; only the known untracked scratch (`claude.sh`,
  `input-pr-slices.tar.gz`, `src/STEPS.md`, `worklog.md`, `doc/tall_blocks.md`,
  `repos.txt`) and the nested example repos.
- Baseline confirmed: `busted tests` → **947 / 0 / 0 / 10**, matching the
  session43 prompt's authoritative number (validation.md's fallback 946 is
  stale by one — session42's P13 added a case). Ten pending are sanctioned.
- Read session42 `prompt.md`, `track.md`, `report.md`, and the follow-up cold
  review. One open item: S2 — `setup_harmony` in
  `tests/harmony_input_spec.lua:18-42` is a 23-line body, over the 14-line
  hard limit.
- Prompt mandate: **wait for owner direction**; do not select a sprint task.
  Reported the state to the owner and am holding.

## 2026-08-16 — owner contests their own P13 ruling

- Owner asked what P9c/P13 were (verified independently of session42's report)
  and challenged the retirement of harmony's `release_keys()` discipline as a
  possible behaviour change, not a mechanism swap.
- **The challenge lands, and harder than framed.** `love_key` pushes and clears
  `held` synchronously; `love.event.push` only enqueues; the queue drains one
  frame later, after `love.update` advanced the scenario. So `held` is already
  false when the app handles the key, and `patch_isDown`/`Key.ctrl()` answer
  false. Every scripted chord now arrives as a bare key.
- A/B probes under realistic queue semantics: pre-P13 Ctrl+T fires quickswitch
  (`Key.ctrl()` true), HEAD does not (`nil`). Session42's spec passes only
  because its fixture dispatches on push.
- The owner's 2026-08-09 ruling was conditional ("retire ... **if** that
  confirms"); the confirmation used the synchronous fixture, so the condition
  was never met.
- Materialized: `validation/notes/S43-harmony-p13-timing-finding.md` +
  `validation/notes/S43-harmony-probes/`. No code changed; awaiting ruling.
- Owner directed a correction step: revert harmony, re-add only the
  non-disruptive part — and asked whether emission is needed at all given
  device polling. Added **P13a** to the operative table + two `[S43]`
  subsections in §10.
- Answer to the owner's question, from code: emission is **not needed**
  (Decision 30 = device-only; `projectInputController.lua:110` drops modifier
  triggers) and **not free** (`consoleController.lua:1449-1462` reacts to any
  key while testing is `waiting`). Recommendation recorded: revert and stop.
  Pre-P13 harmony was already correct under the device-read matcher.
- Execution not started — the correction is a plan entry awaiting the go.
- Owner: use **numeric** substeps as for P17/P18. Re-cut as `P-13-00`
  (finding+plan, done) / `-01` (revert) / `-02` (spec, ruling pending) /
  `-03` (emission, conditional, default skip). `P13a` retired.
- **Self-correction, same turn:** my "not free" bullet was a phantom. The
  `terminal_test` path is unreachable — its guard is `~= 'ready' or ~=
  'project_open'`, true for every value (`99941d1f`, Nov 2025, pre-branch).
  Real consequence found instead: `find_shortcut` drops a modifier trigger but
  `dispatch` still runs the project's **hook**, so emission does change what
  projects see — toward real hardware, which emits modifier events too.
- Incidental, not ours: the dead terminal test is recorded in §10 for the owner
  to route to the debt register or to aldum. Not fixed.

## 2026-08-16 — owner rulings on the correction

- **Terminal self-test → debt ledger, no-blame framing.** Landed in
  `technical_debt/general.md` ("The console's terminal self-test is
  unreachable"): mechanism, dormancy, present at PR base `3256aac`, no author
  named, revisit tied to the next console/terminal pass.
- **Spec: keep and rewrite, not delete.** Owner frames it as a late instance of
  **canonicalizing de-facto behaviour** — the move the feature opened with.
  Harmony's press/hold/release contract was real but unwritten, and that gap is
  what let P13's synchronous-push fixture pass as proof. P-13-02 recut as RULED.
- Still open: P-13-03 (emission — default skip). **Execution not started by
  explicit instruction**; P-13-01 and P-13-02 land together (suite green).

## 2026-08-16 — authorship audit (owner request)

- Owner: session42 was Codex and showed ignorance of project constraints; asked
  which recent consecutive sessions were not Claude-run, stopping at the first
  Claude report.
- Signal: `Co-Authored-By: Claude` trailer (git author is the owner throughout,
  so `%an` says nothing). Boundary `a1842a2f`; corroborated by literal `\n`
  escapes in several untrailered commit bodies.
- Run: 42, 41, 40 not Claude; **39 mixed** (Claude to `a1842a2f`, tail not); 38
  not Claude; **37 Claude → stop**.
- Recorded `validation/notes/S43-agent-authorship-audit.md` with a re-review
  ranking. session38 ranks first — largest footprint, and its upstream-parity
  claim rests on its own harness, the same class of thing that made P13's proof
  false.

## 2026-08-16 — P-20 opened and running

- Owner: open a revalidation step, most attention on session39 (Claude-run then
  handed over mid-flight); session38 at least an outcome review — owner recalls
  it as Claude-run and pedantic. Subagents review, I evaluate.
- **Attribution correction owed to the owner:** my flat "session38 = not Claude"
  overstated it. Trailer absence is the *only* evidence there; the positive
  foreign fingerprint (literal `\n` in commit bodies, 8 commits) appears in the
  39-tail/40/41/42 block and **not once** in session38's 22 commits. Owner's
  recollection is consistent with the evidence.
- Plan: `P-20-00` audit+plan (done), `-01` session38 outcome review, `-02`
  session39 tail full revalidation (priority), `-03` sessions 40+41 sweep.
- Two Sonnet workers commissioned, models passed explicitly, read-only, prompts
  of record on disk, each writing its own deliverable path. **Run concurrently,
  not sequenced** — the charter's rule (d) prohibits *worktree isolation*; these
  are read-only, in the shared tree, on different repos (keyboard vs maze), with
  disjoint outputs, so none of the costs that rule exists to prevent apply.
- `P-20-03` done in-session rather than delegated (three small diffs): clean.
  The one real question — whether paint's move to directly-assigned hooks lost
  the error wrapping a seeded `love.*` handler gets — is answered no by
  `controller.lua:155-171`: the boundary is applied at route entry and names
  that exact case.

## 2026-08-16 — P-20-01 evaluated

- Worker returned: parity claim SOUND, not the P13 mode — the harness
  short-circuits the loop but **discloses it** in three Limits sections. Two
  findings: `e568961` landed after the last independent review yet `84b6e0c5`
  calls it "the reviewed head" (S2); the report headline oversells (S3).
- Checked myself rather than relaying: re-ran the harness at `e568961` — 108
  stimuli, **zero diff**. Re-derived F1 on git timestamps (20:51:45 code,
  20:52:10 review, 20:52:28 close-out) since the worker used file mtimes.
- **My own finding, S2, that the worker did not draw:** the harness existed only
  in a 2026-08-12 `/tmp` scratchpad. The step's strongest claim rested on an
  instrument one cleanup from gone — hygiene (c) squarely. Preserved to
  `validation/notes/S38-parity-harness/`, paths made relative, README stating
  what it proves and what it does not.
- Also caught: `drive_new.lua` **copies** `combo_string`/`any_mod` instead of
  calling production. Verified identical to `controller.lua:382-424` today, so
  sound — but it is where the next fidelity gap opens. Recorded in the README.
- P-20-02 still running.

## 2026-08-16 — P-20-02 evaluated

- Worker verdict SOUND, and correct within what it checked: `da9d1c2`
  implements the ruling exactly, combos canonical, teardown shared, numbers
  reproduce. Confirmed the load-bearing parts myself, and added the
  exhaustiveness argument it only implied (`mod_triples` names ctrl/alt/shift
  only, so four registrations cover the whole expressible family).
- **Finding the revalidation did not reach (S2):** the gateway reserves
  Ctrl+Escape on **keyreleased** at the raw pump entry, so `ctrl+shift+escape`
  and `ctrl+alt+shift+escape` fire the game's menu on press and then have the
  project stopped on release. Two of the four restored variants are cosmetic.
  Upstream had no such gate. **This is P15's ruled property — a project cannot
  suppress a platform combo by naming it — biting a real project.**
- Probe preserved: `validation/notes/S43-ctrl-shift-escape-probe.lua`. First
  run proved nothing (the mock stubs `love.event.quit`); re-run modelling the
  real loop's quit handling: shortcut 1, quit asked 1, aborted true,
  `stop_project_run` 1.
- Not a regression `da9d1c2` introduced — the teardown pre-dated it. Owner
  ruling needed: accept and document, drop the two ctrl registrations, or open
  the gate's reservation as a design question (out of PR scope).

## 2026-08-16 — P-20-04 opened (the gate's tolerance)

- Owner pressed on the maze case: fragile, needs a solution if true. It is
  true, with two corrections: (a) not the framework *exit* — in dev the project
  is stopped back to the console; it is an exit only in `play` mode; (b) not
  order-fragile but order-*conditional* — release Escape first and it fires,
  lift Ctrl first and it does not, so one gesture behaves two ways.
- **Pre-existing:** the release gate has this shape at PR base `3256aac`. Maze
  always ran under the gateway; the migration changed visibility, not
  behaviour.
- Systemic, all verified: `quickswitch` ignores Shift; `f10` names no modifier;
  **Ctrl+Alt+Shift+R fires `restart` AND `reset`** (probe, both true).
- Documented in `technical_debt/input.md` ("The gate reserves tolerantly;
  projects must register exactly"). Options doc:
  `validation/reviews/S43-reserved-combo-tolerance.md` — A tighten the gate
  (recommended), B privileged table (recommend against; Decision 30 declines
  it), C document + drop maze's two ctrl registrations (fallback).
- Nothing in `controller.lua` touched. Awaiting the ruling.

## 2026-08-16 — owner rules option A; P-21 opened

- Ruling: tighten, **all framework cases**, with the reasoning ratified as a
  decision. Written as **Decision 33** — a framework reservation matches its
  modifier set exactly. Both owner reasons recorded: a project's richer combo
  must not dissolve into a framework one, and (stronger) framework shortcuts
  are non-overridable, so unlimited power gets the narrowest condition —
  least privilege.
- Maze/draw: risk note added at the registrations, self-contained (nested repo
  standalone has no access to compy docs), with the removal condition stated.
  Committed in the maze repo `7947ac3`, not pushed. Maze specs 42/0/0.
- **Correction to the P-20-02 worker's evidence:** it reported the maze suite
  via `verify.sh`; that script cannot run in this container (`lua`/`luac`
  absent, only `luajit`) and exits 1 silently. The 42/0/0 number is right —
  10+3+29 running the three specs directly — but the instrument named was not.
- P-21-00 done as analysis: nine reservations tabulated, row 7 (profiler)
  already exact and must not be touched, rows 5+6 are the Ctrl+Alt+Shift+R
  double-fire, no existing test depends on tolerant matching, only maze/draw
  are affected downstream and in their favour. Substeps P-21-01..04 proposed.
- Open question put to the owner: whether "all framework cases" includes the
  console debug hotkeys (`controller.lua:493,510`), which are route-level and
  outside Decision 33's scope clause as written.
- **No `controller.lua` edit yet** — P-21-01 awaits the go.

## 2026-08-16 — P-13 executed

- Owner: pre-dispatch only for Decision 33 (recorded); execute P-13; cold
  review after every execution step; orchestrate rather than hand-code.
- Judged a cold session unnecessary and said why: the analysis is already on
  disk, so a cold session would rebuild it; the self-review risk lives in the
  review, which P-13-04 covers.
- Sonnet worker executed P-13-01/-02 → `3befd556`. Verified myself: revert is
  exact (`git diff 5b580661^ -- src/harmony/` empty), commit staged only the
  two paths, trailer present, tree otherwise untouched, suite **949/0/0/10**
  (947 + 2 as the spec grew 1 case to 3).
- Read the spec rather than trusting the digest: the fixture genuinely queues
  and drains separately, and case 1 asserts the gateway saw **nothing** before
  the drain — which is the property the old fixture destroyed.
- Worker's incidental find, pre-existing at the baseline: harmony's
  `patch_isDown` has no explicit return on its default path, so `Key.ctrl()`
  yields **zero values**, not `nil`, under a locked run — splices badly into a
  call argument. Test ergonomics today; noted, not fixed.
- P-13-04 cold review commissioned (Sonnet, read-only, prompt of record on
  disk). P-13-03 (emission) remains the owner's open call; default skip.

## 2026-08-16 — the split question, and P-13-04

- Owner: prefer not splitting a long function in another author's zone. Asked
  which one; answer was harmony's `love_key` (production), and the test helper
  may stay split since the spec is ours (`5b580661` created it, not aldum).
- Rechecked as asked — **did we bloat it?** No. `git diff 3256aac --
  src/harmony/` is now **empty**: the subsystem is byte-identical to the PR
  base. `love_key` is 23 lines at the PR base and 25 at harmony's first commit,
  so it arrived long. `b31e99a9`'s split is gone with the revert and must not
  return. Nothing to change.
- Standing preference recorded on the P-13-01 plan row and in agent memory: no
  size refactors inside another author's subsystem unless our own work bloated
  the function; measure against the PR base before deciding.
- **P-13-04 cold review: sound, no findings at any severity.** It did the sharp
  check properly — traced each of the three cases and confirmed each fails if
  the defect returns — and went past its brief on the `Key.ctrl()` zero-value
  return, finding six production call sites where it lands as a last argument
  (`editorController.lua:466,470,772,776`, `searchController.lua:101,105`) and
  proving none is affected, since `_scroll` only tests `warp` for truthiness.
- Also confirmed against the tree: `scenarios/examples.lua` has no explicit
  `release_keys()` and does not need one — `hm_done` releases (`init.lua:331`).

## 2026-08-16 — P-13-03 ruled: no emission, one comment

- Owner: combo checking depends on device polling and harmony plumbs it, so
  nothing to do. Leave a comment warning that code counting events to mirror
  held keys would break silently under harmony. No debt entry — no such code
  exists, and a record would have to warn about a parity limitation rather
  than blame harmony.
- Comment placed at the `held` table (`src/harmony/init.lua:174-180`), citing
  Decision 30 by name in the canonical doc, not a wip path. Seven lines.
- **Consequence worth naming:** `git diff 3256aac -- src/harmony/` is no longer
  empty — +7 lines. The subsystem was byte-identical to the PR base as of the
  revert; this is a deliberate, minimal exception, and it is the only thing
  this feature leaves in aldum's code.

## 2026-08-16 — P-21-01/-02 executed

- Judged the session fit to continue and said why: Decision 33 and the nine-row
  table are already on disk, so what remains is execution against a written
  spec, delegated and cold-reviewed. Boundary set in the commission: a design
  question inside the step goes to the owner, not the worker.
- **Corrected my own plan before commissioning:** the blast radius had proposed
  converting the `ctrl+escape` pending into a live case. Wrong — the seven
  pendings name each combo's own *effect* (P15, the framework's contract, not
  this PR's), and 10 is an owner ruling the boot ritual checks. Decision 33
  makes the **boundary** ours, not the effect. New cases are additive; pendings
  stayed at 10.
- Worker landed `b20a4c35` + `77aed369`. Verified myself: predicate correct,
  row 4 excludes Alt only with the reason in a comment, row 7 untouched, no
  added line over 64 chars, pendings intact, suite **964 / 0 / 0 / 10**.
- **The thing the table did not anticipate**, and it is a good catch: the
  worker's first `only_mods` used `==` and broke the harmony spec, because a
  patched `isDown` returns *no value* rather than `false`. Fixed with `not not`
  normalisation, reason stated in the predicate's comment. This is the same
  zero-value quirk P-13-04 found from the other side — it has now bitten real
  production code, which raises whether it deserves a debt entry.
- P-21-05 cold review commissioned; P-21-03 (maze note) and -04 (docs) wait on
  its verdict.

## 2026-08-16 — P-21-05 verdict: sound, two real findings

- Cold review: sweep complete, exact, defended. Nine rows match the table, row 7
  byte-identical, `not not` confirmed a genuine fix (it traced `patch_isDown`
  and proved bare `nil` under lock), blast radius clean by grep of examples.
- **Both findings verified by me before acting.** No test in the tree presses
  `ctrl+shift+s` — confirmed. And `project_state_change` did change size
  (27 → 29 lines by my count, header to `end`), so the report's "unchanged"
  was wrong; nesting improved rather than held.
- The S2 is the good kind of finding: every *other* row drops Shift, so row 4 is
  where a well-meaning edit would break something, and nothing guarded it.
- P-21-06 commissioned to close both, with the case proved by temporarily
  breaking row 4. Production code explicitly off limits.
- Debt entry written: "A modifier accessor answers truthy/falsy, not a boolean"
  — the zero-value quirk, now seen from both sides (P-13-04 found six call
  sites; P-21 had it break a comparison). Framed as our annotation being
  unenforced rather than as harmony's fault, with the one-line fix in `Key`
  named as the shape if it is ever answered.

## 2026-08-16 — P-21 closed out (bar P10's section)

- P-21-06 landed `2b89bba8`: two cases pin Shift as meaningful on `ctrl+s`,
  and the worker proved them by temporarily adding `not Key.shift()` and
  showing only the shift case failed. Suite **966 / 0 / 0 / 10**, pendings
  untouched, `controller.lua` left exactly as reviewed.
- Checked the new cases for the P9c failure mode myself — `session.press`
  holds without releasing — and the file's `before_each(F.reset)` calls
  `mock.release_keys()`, so nothing leaks between cases.
- P-21-03: maze note removed (`c23cb59`), specs 42/0/0, and **the original
  defect probe now passes** — shortcut fires, platform never asks to quit,
  project not stopped. That is the end-to-end confirmation, not a claim.
- P-21-04 part done: the tolerance debt entry is marked RESOLVED against
  Decision 33 rather than deleted (it records why the asymmetry existed), with
  the route-level half named as deliberately still open. PR paragraphs drafted
  in `validation/notes/S43-pr-lines-owed.md` for the regeneration step rather
  than written into the stale `pr-description.md`.
- **Scope call:** did not write the guide's reserved-combo section. That is
  P10's row, unstarted and large; writing it inside P-21 would preempt it.
  Flagged on P10 instead that the section must now state what a reservation
  *claims*, not just which combos are reserved.

## 2026-08-16 — two owner rulings: harmony signature parity, Ctrl+S relocation

- **P-22-01** commissioned (Sonnet): harmony's patched `isDown` returns a real
  boolean. Owner's rationale is signature parity with the thing it mocks, which
  makes it a justified exception to the standing rule against touching aldum's
  subsystem — so the prompt insists on the smallest edit and forbids any
  restructuring. It also has to restate `only_mods`'s comment, whose stated
  reason the patch makes false.
- **P-23-00** done by me (design analysis, parent tier). Verdict: the move is
  feasible and small. The load-bearing fact is that `occupy_input` installs the
  project route **unconditionally** on every successful run, so `running` always
  means PIC owns the keyboard — the relocation has a guaranteed owner. The
  failure path releases the route but also leaves `running`, and the window
  before `occupy_input` is not observable because top-level code completes
  inside one `love.update`.
- Named the risks rather than waving at them: teardown would now run **inside**
  `with_canvas_and_errors` rather than outside it; `project_open` must not be
  widened into; and P-21's row-4 cases must be re-pointed rather than deleted.
- Scoping call: `ctrl+s` stays scoped to `running` exactly as today, and the
  shortcut-syntax migration the owner floated is recorded as a later option,
  not folded in.

## 2026-08-16 — P-22-01 landed

- Patch is one line (`return false` on the locked, not-held path), test
  type-asserts so a regression to `nil` fails loudly rather than passing as
  falsy, and `only_mods`'s comment now cites the debt entry instead of the
  harmony instance it no longer describes. Verified all three myself; suite
  **967 / 0 / 0 / 10**.
- Worker split it into two commits on its own judgement — code+test, then the
  unrelated comment in another file. That is the granularity rule applied
  correctly without being told.
- Debt entry narrowed rather than closed: the known offender is fixed, the
  general exposure (`Key`'s `@return boolean` is unenforced for any patcher)
  stands, with the fix shape still recorded.
- Harmony is now `+8` lines against the PR base — the seven-line comment and
  this one-line return, both deliberate and both owner-ruled.

## 2026-08-16 — P-23-00b: two findings, one changes the step's shape

- Owner asked for the pen-and-paper and canvas/error analysis before -01.
  Relettered the feasibility pass to P-23-00a (committed as P-23-00) rather
  than renumbering committed references.
- **Finding 1.** A non-blocking project keeps the route in `project_open`, and
  in that state `ctrl+s` today falls through to the project's own binding. The
  obvious implementation — check at the top of PIC's walk — would apply in
  `project_open` too and stop pen-and-paper projects on a key that is theirs.
  The `running` scope is load-bearing; it gets a live test.
- **Finding 2, and it changes the shape.** The route boundary's error handler
  is `user_error_handler` → **`CC:suspend_run`**. A raise inside
  `stop_project_run` running inside the boundary would suspend the run
  mid-teardown and label it a project error — in the one path whose whole
  purpose is recovery. Recommendation: PIC decides and consumes; the gateway
  performs the action after the route returns, where it runs today.
- Also found: `use_canvas` binds and unbinds unconditionally with no
  save/restore, so it does not nest. Latent today (teardown calls it nowhere),
  a trap once teardown lives inside a bound canvas.
- Not a problem, checked: the project's own `before_exit` is already pcalled
  inside `framework_before_exit`, so its error handling is unaffected.

## 2026-08-16 — owner leans A; P-23-02 commissioned

- Owner picked **A** after I withdrew the overengineered recommendation. So:
  the editor's two meanings move to `EditorController`, the gate keeps an
  **exact** run-stop `ctrl+s`, and `ProjectInputController` is not touched at
  all. P-23-01 withdrawn.
- One intended behaviour change: **Ctrl+Shift+S no longer stops a running
  project** — the wrinkle P-21 had to leave loose, now closed by exactness.
  Commissioned tests-first so it fails against the current tree.
- Prediction written into the commission rather than assumed: the P-21-06
  editor cases assert behaviour, not layering, so they should survive the move
  untouched. If they break, the worker reports why instead of weakening them.
- Told the worker to stop rather than restructure if the addition would breach
  a limit in `EditorController:keypressed`, which is already long — the
  standing rule against reshaping code we are only passing through.

## 2026-08-16 — P-23-02 landed, and the seven lines came back out

- `cb6b867e`: gate keeps one exact run-stop `ctrl+s`; editor's two meanings move
  to `EditorController`. Verified the diff myself — semantics preserved branch
  for branch, `ProjectInputController` untouched, failing-first evidence real.
- **The prediction held:** both P-21-06 editor cases passed byte-identical
  across the move. They assert behaviour through `CC` stubs, so they were
  written at the right level and the move proved it.
- Sent back one thing the worker had correctly refused to fix on its own: our
  7-line addition sat in a function already 28 lines against a 14-line limit.
  A function that *arrives* long stays long; one **we** bloat is ours. Hence
  `5e6ad8c2` — `_save_keys`, following the file's own `_reorg_mode_keys` /
  `_search_mode_keys` idiom, leaving `keypressed` at 29 (28 + our one call).
  The worker left `Key.ctrl()` at the call site so the new call reads parallel
  to `ctrl+m` and `ctrl+f`; that is the right call.
- P-23-03 cold review commissioned, pointed at the one question that matters:
  is there a *second* behaviour change nobody intended, including in **when** a
  branch is reached rather than what it does.

## 2026-08-16 — P-23-03: faithful move, three drift findings

- Verdict: exactly one intended behaviour change, verified across the full
  four-chord × five-state matrix. `ProjectInputController` has zero diff and
  `project_open` is untouched, so the pen-and-paper property that justified
  option A actually holds rather than being assumed.
- All three findings were documentation/comment drift **adjacent to the diff** —
  the class the workflow warns about, where a stale claim reads as
  authoritative. Verified each, then fixed all three myself (docs are parent
  work): `internals/user_input.md` said the gate closes buffers; a spec comment
  said the running and editor branches share an outer condition, which stopped
  being true when the running branch became exact; Decision 33's example list
  omitted Ctrl+Shift+S.
- While fixing, swept for other Ctrl+S claims. `internals/editor.md` is still
  correct (Ctrl+S closes a buffer — it just lives elsewhere now).
  `internals/project_sandbox_env.md:81` is correct in substance but cites
  `controller.lua` line numbers that were **already stale before this session**
  — reported, not fixed; line-number citations are what the conventions
  discourage, and a sweep belongs with the docs rows, not here.

## 2026-08-16 — P-24-00: the only_mods API question

- Owner flagged the positional-boolean API as non-intuitive. Reach measured:
  **seven call sites, all file-local, introduced today** — nothing outside
  `controller.lua` names it, so the change is cheap now and gets dearer.
- Weighed the owner's two forms and a third: **drop the predicate entirely and
  compare `combo_string(k)`**, the serialiser the project already ratified.
  Probed it against live code first — `f10`, `ctrl+s`, `ctrl+shift+s`,
  `ctrl+alt+shift+r` all come out exactly as the gate would need.
- The argument that decided it for me: exactness stops being a rule someone
  must remember and becomes a property of string equality — the P-21 bug class
  cannot recur. Plus one vocabulary with project bindings, and 21 device reads
  per keypress drop to 3.
- Stated the cost rather than burying it: one table allocation per keypress,
  the same one the register already names for dispatch.
- Owner chooses; P-24-01 is written either way, with the standing rule that no
  existing test may need editing — a changed test would mean the rewrite is not
  equivalent.

## 2026-08-16 — P-24-00b: three follow-ups answered

- **Shortcuts table for the gate:** agreed on merits, and Decision 33 is what
  made it possible — while reservations tolerated unnamed modifiers,
  `ctrl+alt+shift+r` matched two of them and a combo→fn table had no
  well-defined entry. But it is **exactly what Decision 30 point 3 declined**,
  so it is a ruling to amend, not a refactor to slip in. Scoped as P-24-03,
  owner-gated, with the non-consumption contract named as part of the
  deliverable — same table shape as a project's, opposite consumption rule, and
  that is the most misleading thing about the design.
- **The allocation** is `parts = {}` in `combo_string`; the concat result is an
  interned string, so the table is the garbage and the string mostly is not.
  Already up to **two** per event in dispatch, not one. Recommended no table at
  all over a reused buffer — same win without the shared-mutable-state footgun.
- **Sharing the combo: recommended against, on the feature's own ground.** A
  per-event cache of device state with no path back to the truth is the
  `keys_pressed` shape Decision 30 dissolved, and `_dispatch` is reachable
  without the gate (tests drive PIC directly; the walk is deliberately reusable
  by other adopters). Passing it down as a parameter is separately ruled out by
  Decision 27's payload clause.

## 2026-08-16 — Decision 34, and P-24 commissioned

- **Owner corrected my reading, and they are right:** Decision 30 point 3
  declines to *commit* to the gate's table and guards against **confusing** it
  with a project's — it does not prohibit one. Recorded as **Decision 34**,
  which amends only the "not committed to" and keeps the separateness
  requirement as a build instruction.
- The owner's chain is the decision's own reasoning: exclusivity at the gate →
  combo strings as its natural expression → the table as the natural form of a
  set of string keys. Each step made the next available; Decision 33 is the
  prerequisite, because while `ctrl+alt+shift+r` matched two gates there was no
  well-defined single entry for it.
- **Device reads, their question:** roughly right. Today the cascade asks once
  per predicate, up to ~20 per keypress (fewer in practice — `and` chains
  short-circuit). After: 3 at the gate. In the route it is 3 **or 6** —
  `find_shortcut` builds the exact combo and then the `'*'` class on a miss, so
  the honest answer is 3 unless that second build can reuse the first read. Put
  that in the commission as a question, not an assumption.
- Folded the string-comparison step into the table step: landing a cascade of
  string comparisons we would replace immediately is churn, not increments.
- Commissioned as two commits — the allocation first, then the table — with the
  Decision 33 live cases as the equivalence proof and the standing rule that a
  test needing an edit is a finding.

## 2026-08-16 — P-24 landed; the table is in

- `737d8316` (no allocation) and `f31bd312` (the table). Verified myself:
  handlers are now a lookup plus a forward, every reservation is a named
  function, the never-consumes contract is stated at the table, no test was
  edited, suite 968 / 0 / 0 / 10.
- **Device reads counted, not estimated: 23 → 3 at the gate** per event. Route
  unchanged: 3, or 6 when the exact combo misses and the `'*'` class is built.
  So the owner's "3 and 3" is the hit case; 6 is the miss case, and closing it
  needs a parameter, cached state, or a second copy of Decision 8's precedence —
  all worse than the cost, so it stays and is written into the debt entry.
- **The thing both my analyses missed**, found by the worker and worth
  recording: `cfg.mode == 'play'` was a **fourth** state condition. The old
  gate ran restart and profile in both branches and quickswitch /
  project_state_change in dev only; that split had to move into per-reservation
  guards. Neither P-24-00 nor -00b mentioned playback at all. It was caught by
  `input_shortcuts_click_spec.lua`'s play-mode case — the one test in the suite
  that exercises it — which is exactly why the proof rule was "no test may need
  editing" rather than "the tests pass".
- Second trap the worker avoided: the f10 chain has no `else`, so an
  unrecognised `fpsc` is left alone; a lookup with an `or 'off'` fallback would
  have silently changed that.
- Debt entry "Combo-string dispatch allocates a table per call" closed, with the
  `find_shortcut` remainder named.

## 2026-08-16 — P-24-03: representation-only, clean

- No findings at any severity. It did the playback partition properly —
  guarded set {quickswitch, suspend, quit, stop_run, reset} against unguarded
  {restart, profile_start, profile_stop, overlay}, matching the old branch
  split exactly — and confirmed the `f10` no-`else` property survived.
- Verified two of its claims myself rather than relaying: `setup_callback_handlers`
  is called once, at `main.lua:385`, and the old closures really were declared
  inside `handlers.keypressed`, so they were rebuilt on **every keypress**. The
  table therefore allocates strictly less than the cascade it replaced — the
  opposite of the cost I warned about in P-24-00.
- Also re-measured `reserved_quickswitch`: 14 body lines, at the limit, not over.
- Added the third PR paragraph to `validation/notes/S43-pr-lines-owed.md`,
  including the two rejected alternatives — a stakeholder asking "why not just
  share the combo" deserves the answer in the description, not in a review file.

## 2026-08-16 — P9 closed, P10 started

- Owner: the nested repo commits exist; close P9 and take P10 now. P11 will run
  cold with their own planning changes.
- Verified rather than assumed: all three repos carry local, unpushed history —
  `maze` 10 ahead of `dsent/dsent/dev`, `keyboard` on `newinput` with no
  upstream at all, `balloons` 4 ahead of `origin/main`.
- Closed P9 with two things named rather than absorbed: the **human smoke gate
  is not discharged** by the closure (it is the same pass P17/P18 wait on, with
  `examples/keyboard` as P9's named minimum), and **SM3a is unreproduced, not
  disproved** — the note says what stabilises the font is a consequence of the
  return path rather than a guarantee, so it must not authorise a state-reset
  fix.
- P10 decomposed from its row: the reserved-combo section, the flag-shortcut
  teaching defect, W9(a) ledger prune, W9(b) accuracy items, W10 batches 1 and
  4. W10 batch 3 (comment bloat) and the §16.2 marker question stay with P11,
  which the owner runs cold.
- P-10-05 (W10 batch 1, "overlay" → "input widget") commissioned to Sonnet,
  scoped to the **persistent corpus only** — `src/`+`tests/` comments are P11's,
  and touching them here would collide with it.
