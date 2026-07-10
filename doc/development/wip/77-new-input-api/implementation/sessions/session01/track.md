# session01 — track (M4)

- [project] Boot 2026-07-02: fresh start (no track/report existed). Mandate + session01/prompt.md
  + implementation/prompts/M4.md read. Task: execute M4 (ProjectInputController + overlay-gate
  removal + isrepeat threading), test-first vs contract suite, 4-mode manual verify, outcome
  ledger, then hold the gate.
- [project] Carried rulings honored: keyreleased tier = descope-with-note (no re-ask);
  kept-OPEN suite rows stand; on_text_entered parked at m5a pending.
- [project] Baseline verified before touching code: `busted tests` = 718/0/0/12 — exact match
  with the M4-0-05 record.
- [project] DESIGN RULING MADE (mine, to be ratified at the gate): spec.md §6/design.md say PIC
  occupies keyboard slots in 'running' AND 'project_open'; doc A §3(A) says non-running states
  route to the console. Literal spec reading kills the REPL after a non-blocking run (sine,
  drawdebug: run script → project_open → typing would no-op → dead console until Ctrl+S).
  Reconciliation adopted: PIC keeps OCCUPANCY for the whole run lifecycle (spec satisfied), but
  when app_state ~= 'running' it forwards to Controller._defaults.* — the console route CONSUMES
  in non-running states (doc A satisfied). Zero example/UX regressions. Post-run handler
  liveness in project_open = genuinely M5 question, deferred to M5a commissioning. Alternative
  if contested: strict no-op outside widget (breaks REPL-after-script).
- [project] Second deliberate change: during 'running' with NO native handler and NO widget,
  keys previously fell to the invisible console line (garbage typed into console during a run,
  visible after stop). Post-M4: PIC sink no-ops when hidden (route exclusivity + the 3a
  no-op-when-hidden acceptance line). No test asserted the old behaviour; recorded for the gate.
- [project] Bucket-D flip planned (deliberate, comment trail): 'a release under a widget is not
  routed' → gate removal means the slot occupant now receives the release (got 0 → 1).
- [project] {M,C,V} disposition: LEFT AS-IS + debt (sink calls via .C, overlay draw via .V
  unchanged); no coordinated sweep needed for M4's goals — sweep risk outweighs gain.
- [project] Executing inline (no Sonnet delegation): every piece of M4 is routing-semantics
  judgment (the mandate flags M4 cognition-heavy); mechanical grind here is only `busted` runs.
- [behavioural] The human's in-suite REVIEW comment on the native-coexistence row ("testing just
  default keys delivery would be fine"; keys anyway delivered to PIC, propagation decided by
  return values) pre-endorses the delegation shape and grants test-simplification latitude —
  used when adapting that pending.
- [project] Implementation + suite conversion DONE: 723/0/0/8 (was 718/0/0/12; 4 m4 pendings
  live, +1 3a sibling row, Bucket-D release row flipped deliberately with comment trail).
  docs: internals/user_input.md rewritten to the slot-occupant model. Outcome ledger drafted
  (outcomes/M4.md), verification section pending the live run.
- [project] Manual 4-mode verification delegated to a Sonnet subagent: temporary in-app driver
  src/tests/autotest.lua via the pre-existing CC:autotest() hook (`love src test --auto`),
  xvfb, love.event.push for real gateway events, direct CC calls for mode transitions
  (synthetic pushes can't satisfy love.keyboard.isDown, so modifier shortcuts undrivable).
- [behavioural] Human interrupted an apt dry-run: container is non-root by policy; offered a
  Dockerfile rebuild path (implementation/docker/src/agent.md) if a tool is truly needed, but
  steered toward "don't overcomplicate — mock helpers may suffice". Prefers minimal-tooling
  solutions; keep infra asks as last resort.
- [behavioural] Human encourages Sonnet delegation for straightforward tasks (repeated at the
  usage-limit resume), including via `claude --model sonnet` or prompts stored on disk for them
  to run separately.
- [project] Session interrupted mid-verification; resumed 2026-07-02 (fresh conversation, booted
  via agents/sweep.md re-entrance rule). Baseline re-confirmed 723/0/0/8; live 4-mode run
  executed inline (`xvfb-run love src test --auto`): 25/25 PASS, 0 FAIL. Ledger verification
  section filled. M4 now complete pending the human gate — nothing committed yet.
