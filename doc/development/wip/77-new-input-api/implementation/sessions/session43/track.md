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
