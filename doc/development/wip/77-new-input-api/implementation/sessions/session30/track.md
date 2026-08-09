# session30 — track

## 2026-08-08 — boot

- Booted per `agents/validation.md` → `agents/sessions.md`. **Fresh start**:
  session30 held only `prompt.md`, no `track.md` / `report.md` (sessions §2 row 1).
- HEAD `7e3ae74d` "docs(session29): wrap — report, held-state design agenda,
  session30 prompt", branch `feature/77-newapi-analysis-s20260615`. Working tree
  carries only the known untracked scratch (`claude.sh`, `src/STEPS.md`,
  `input-pr-slices.tar.gz`, `doc/tall_blocks.md`,
  `doc/development/wip/{clarification,personal-notes,pull-26}/`) and the three
  nested example repos (`src/examples/{balloons,keyboard,maze}`). No tracked
  modifications.
- **Baseline confirmed: `busted tests` → 955 / 0 / 0 / 3.** Matches the prompt.
  (`agents/validation.md` §6 still says 953 — that line is self-declared fallback;
  the session prompt is authoritative. No finding.)
- Read in full: `agents/validation.md`, `agents/sessions.md`, this session's
  `prompt.md`, session29's `report.md` + `prompt.md` + `track.md`, and
  `validation/notes/S29-held-state-design-agenda.md`.
- Noted, not acted on: session29's `track.md` carries a stray `</content>` /
  `</invoke>` pair at :303-304 (tool-echo residue). Historical artifact —
  immutable per the prompt; flagged to the owner only.
- Task as understood, stated to the owner before proceeding: **part 1** — the
  held-state design session with the owner; **part 2** — resume the plan:
  P9b → P9c → P9d/P9e → P10 → P11 → close-out → P12. Part 1 gates P9d/P9e.

## 2026-08-08 — owner's four opening remarks (they reframe part 1)

1. **"Suspicious there is no Q2."** Correct instinct. Q2 exists and was closed
   *by the assistant, in session29*, marked `[ANSWERED IN SESSION]` in the agenda
   note; session30's own prompt then instructed "do not re-open it". So one of
   the owner's five questions was retired without an owner ruling. **Reopened.**
2. **Decision 26 is ours, not an external constraint** — it itself reverted an
   earlier decision, and it can be overridden. The goal is *what is feasible given
   fundamental constraints and needs*, not what is already ratified. This
   dissolves the load-bearing premise of Q2's in-session closure (which reasoned
   about how 26 and 29 divide jurisdiction, treating 26 as fixed) and it defuses
   Q3's framing as an "amend-or-supersede question".
3. **The agenda has a question underneath it, and that is where to start:**
   *should we store a model of keys pressed at all, or is it unfeasible?* —
   i.e. weigh event-based tracking vs realtime hardware queries on their merits.
   Q1 and Q5 are downstream of that. Call it **Q0**.
4. **Drift policy (owner directive).** The P9b drift happened because a
   materialised document was never validated against the intent expressed in
   conversation. The owner will **not** proof-read every materialised note —
   that is inefficient. Drift is caught on the **next iteration** instead;
   tolerable and cheaper. So: do not ask the owner to review notes as a routine
   gate; rely on the next cold pass to catch it.

## 2026-08-08 — Q0 evidence gathered (code-verified unless marked)

Verified in code:

- The model is **two lines**: `controller.lua:788` (`keys_pressed[k] = true` in
  `handlers.keypressed`) and `:906` (`= nil` in `handlers.keyreleased`). No other
  writer anywhere.
- The framework already uses **both sources, inconsistently**: `combo_string`
  (`:395`) and `any_mod` (`:411`) read the event set; the gateway's own gates read
  the **device** — `Key.ctrl()` at `:907`, and `Key.ctrl/alt/shift()` has **70
  call sites across 5 controllers**. `util/key.lua:141-164` shows all three are
  `love.keyboard.isDown(unpack(...))`. This inconsistency is what P9e names.
- Exposure path: `held_keys()` memoised read-only proxy (`:430`) →
  `compy.input.keys_pressed` (`consoleController.lua:540`).
- **A framework-owned per-frame hook already exists**: `set_love_update`
  (`:556-634`), which already synthesises derived click events. A reconcile has a
  home; no new machinery tier.
- Wedge blast radius confirmed from `find_shortcut`
  (`projectInputController.lua:101-112`): a phantom held `lalt` makes
  `combo_string('s', keys)` return `'alt+s'`, so a plainly-keyed `'s'` shortcut
  **cannot match**; the fallback is `tbl['alt+*']`. One stuck modifier silently
  disables every unmodified shortcut on every channel.
- **Fixture-fidelity gap:** `tests/mock.lua:30` is
  `isDown = function(k) return held[k] end` — single-arg. Every variadic
  `Key.ctrl()` under the suite therefore only ever consults the **left** key.
  Matters if we lean harder on the device.

Reasoned from LÖVE/SDL architecture, **not verified at runtime here** (flagged as
such to the owner; a headless check is proposed):

- `love.event.pump` drains the OS queue and SDL updates its keyboard state array
  during that pump; `love.event.poll` then dispatches the batch one event at a
  time. So while dispatching event 1 of N, `isDown` already reports the state
  *after* event N — Decision 29's "built from the future".
- The two clocks **coincide by construction** at one moment: after the whole
  batch is dispatched and before the next pump — i.e. `love.update` entry.
- SDL clears its keyboard state on focus loss, so a reconcile at update would
  subsume P9d rather than sit beside it.

## 2026-08-08 — owner reframes Q0: intent was structure, not correctness

Owner's account, and it changes the weighing:

- **Pre-feature, all querying was physical**; there were no shortcuts. Generic
  user complaints existed — *"weird reaction to keyboard sometimes"* — never
  recorded, reproduced or investigated.
- **The original motive for event-based tracking was code structure, not clock
  correctness**: to stop `if Key.shift()` cascades sprawling through the codebase
  — global state injected everywhere, nested conditionals at random depth,
  untestable. If *isolated, centralised* hardware querying reached the same
  result (one place builds combo strings), the owner would accept that.
- Therefore **the structural goal does not decide the source**; the source is
  decidable on reliability alone. Owner wants: which is more reliable, what does
  LÖVE recommend, how *possible* are the failure scenarios (defending against
  rare exotica may be unfeasible; sane mitigation may be needed regardless).
- **Alt+Tab downgraded**: primary device is an Android laptop with keyboard, used
  by kids who are not expected to switch windows routinely.
- Pre-feature authority is not binding — physical querying *may* be discouraged
  now, but only with solid confidence about reasons, justification, feasibility.
- Owner's own hypothesis: buffered pumping + the unexplained complaints "may be
  it".

## 2026-08-08 — Q0 census: the cascades and the wrong-clock reads are the same lines

Attributed every `Key.ctrl/alt/shift()` call site to its enclosing function
(awk over the 5 files, then spot-checked; a first attribution pass wrongly
credited `editorController:677-719` to `update_status()` — the enclosing scope is
actually a `k`-handling block, corrected before reporting).

**All 70 sites sit in event-handling paths**: `navigate` (14 + 6), `selection`,
`horizontal`, `vertical`, `copypaste`, `copycut`, `paste_k`, `removers`,
`newline`, `delete`, `clear`, `replace`, `add`, `load`, `modify`, `quickswitch`,
`restart`, `profile`, `project_state_change`, `terminal_test`,
`EditorController:keypressed`, `EditorController:textinput`,
`ConsoleController:textinput`, and the gateway's own `keypressed`/`keyreleased`.
**Not one is a frame-time or draw-time poll.** Every one asks "what was held at
this event" and answers it by polling the device.

Consequence for Decision 29 clause 3: it preserves direct reads as a legitimate
secondary channel whose flagship case is "a per-frame draw with no event in hand"
— and the platform contains **zero** such keyboard instances. The justification is
theoretical, not observed.

## 2026-08-08 — the buffered-pump mechanism, structural half now code-verified

- **This project overrides `love.run`** — `src/harmony/init.lua:104`
  (`harmonius_run`), loop at `:49-50`: `love.event.pump()` then
  `for name,... in love.event.poll() do love.handlers[n](...) end`. So the entire
  OS batch is drained into LÖVE's queue **before the first handler runs**.
  Draining is what updates SDL's key-state array, so `isDown` during dispatch of
  event 1 of N reflects state after event N. LÖVE 11.5.
- **Unverifiable in this image:** no `xdotool` / `xte` / python-Xlib and no
  package source, so no synthetic key injection. `love.event.push` bypasses SDL
  and cannot test the coupling. The SDL half (state array updated during pump)
  stays documented-contract, not measured here — flagged to the owner, and the
  frequency half needs the real device.
- **Existing precedent in this codebase:** `harmony/init.lua:242 patch_isDown`
  already shadows `love.keyboard.isDown` with a script-maintained `held` table,
  falling back to the real device unless locked. The system already concluded
  once that a maintained table beats the device where determinism matters.
- **Polling's failure mode is one event tracking does not have — false
  positives.** Tap `s`, then press Ctrl for the next action, both in one batch →
  at dispatch of `keypressed('s')` `Key.ctrl()` is already true → a plain `s`
  executes as Ctrl+S. Non-reproducible, frame-boundary dependent, fires an action
  the user never typed. Lower framerate widens the window, so the Android target
  is the **worst** case, not the mildest.

## 2026-08-08 — owner: did harmony's shadow table predate the feature? (it did — and it exposes a P9e blast radius)

Owner asked whether `patch_isDown` predates the feature and whether the feature
is recreating it a level up without good reason. Checked rather than assumed:

- **Predates it, verbatim.** Present at PR base `3256aac`; introduced by
  `4203de7f feat: harmony`. `git diff --stat 3256aac HEAD -- src/harmony/` is
  **empty** — this branch has not touched harmony at all.
- **Not the same mechanism.** Harmony's `held` (`init.lua:174-184`) is **eight
  modifier keys**, hand-set by a script, deliberately *not* event-derived: a
  puppet, not a mirror. `keys_pressed` is all keys, event-derived, mirroring
  reality. Harmony injects a lie so that *polling* consumers believe a modifier
  is down that no OS ever sent.
- **The dependency runs the other way.** `love_key` (`:272-293`) splits `'C-S-s'`:
  modifiers set `held[m] = true` **with no event pushed**; the real key gets
  `love_event('keypressed'/'keyreleased')` → `love.event.push('sazed_…')` →
  `harmonius_run` un-prefixes → `love.handlers[n](...)` → **does** land in
  `Controller.keys_pressed`. So harmony already pushes real events for everything
  *except* modifiers, and the only reason modifiers are special is that polling
  consumers are cheaper to fool. The table is a **symptom of the polling
  architecture**, not a precedent for the feature's model.
- **FINDING, unrecorded anywhere: P9e breaks harmony's scripted modifiers.** Once
  the gates read `keys_pressed` instead of `isDown`, harmony's modifiers are
  invisible. Affected scripts: `scenarios/editor.lua` (`C-t` ×5 via
  `shortcuts.toggle`, `C-S-s`, `C-S-q`, `C-f`, `S-return`) and
  `scenarios/inspect.lua` (`C-pause`, `C-S-q`). Harmony is untouched by this
  branch, so nothing would flag it.
  - **Recommended fix: harmony pushes real modifier events and `patch_isDown` is
    deleted.** Net subtraction, and harmony would then exercise the real gateway
    path it currently bypasses — which is what an automation harness should do.
  - Alternative: keep the patch, accept that harmony can no longer drive the
    event-based paths this feature introduced. Cheaper now, blind later.
- **Irony worth keeping:** harmony's `held` **goes stale by design** — `held[m]=true`
  is never cleared per key (the inline `release_keys()` at `:286` is commented
  out), relying on an explicit manual `release_keys()` (`:331`). The pre-feature
  mechanism already exhibited Q1's staleness problem and answered it with a
  manual reset — the weakest form of a recovery path.

## 2026-08-08 — what harmony actually is, and its coupling (owner was unaware of the whole subsystem)

Explained to the owner from code; facts established:

- **Not used by tests, not in CI.** Zero references to harmony under `tests/`;
  `.github/workflows/package.yml` runs only `busted tests -o utfTerminal`.
  Invoked by hand: `justfile:60 dev-harmony` (file-watcher dev loop) and
  `justfile:131 one-harmony` → `love src harmony`.
- **Nascent assertion capability, essentially unused:** exactly one `assert` in
  the whole subsystem (`scenarios/examples.lua:27`,
  `assert(love.state.app_state == 'running')`). The commit
  `7b2d8645 fix(harmony): larger timeout for state assert` is a `wait(.1)→wait(.3)`
  change. So it is a driving/screenshot harness with a toehold in verification,
  not a test suite.
- **Correction to what I told the owner earlier:** I listed several chords as
  lacking a following `release_keys()`. `hm_done` (`init.lua:331`) calls
  `release_keys()` itself, so every scenario-end chord is covered. The one real leak
  is `scenarios/editor.lua:102` (`S-return` mid-scenario, Shift held until `:108`).
- **Owner's generalisation, and it is correct:** any system-wide input change
  either breaks harmony's scripting or requires matching harmony changes.
  Sharpened cause: harmony is a **second implementation of the app's input
  surface** (its own `love.run`, its own held-modifier table, its own patched
  `isDown`), so it is coupled to whatever that surface happens to be.
- **The durable fix follows from that.** If harmony injects real modifier events
  instead of faking the poll, it stops having a private input surface and becomes
  a *client of `love.handlers`* — the same interface a real keyboard uses. The
  coupling then survives future input changes for free. That is a stronger reason
  to do it than the P9e breakage alone.
- **No automated signal.** Because harmony is outside CI and outside busted,
  breaking it is silent until someone runs it by hand. Argues for making the
  harmony-side change inside this PR rather than leaving it to be discovered.

## 2026-08-08 — "wedge" retired (owner instruction), fixed in place

Owner caught the word becoming load-bearing without ratification and ruled it be
fixed **now**, not deferred to P10: current reasoning is built on current notes,
and ambiguous vocabulary invites hallucinated architecture.

**Audit:** zero occurrences at PR base `3256aac` — entirely assistant-introduced
across sessions 28–29 — and already in three persistent-corpus sites plus a test
row title. It carried **two distinct senses**: *stuck in a wrong state nothing
clears* (held set) and *blocked from completing* (teardown).

Replacements: **"stale"** (the owner's own word, from Q1) for the first, with the
permanence spelled out — "and nothing clears it" — where that is load-bearing;
**"block"** for the second.

Fixed: `technical_debt/input.md` (heading + body), `internals/examples/keyboard.md`,
`tests/input/input_route_lifecycle_spec.lua:541` (row title),
`src/examples/keyboard/input.lua` (comment, rewrapped to the ≤64 rule),
`validation/reviews/S27-triage-and-plan.md` ×3,
`validation/notes/S29-{held-state-design-agenda,keys-pressed-as-deterrent,shortcuts-and-the-ordering-premise}.md`,
and this track. Heading citation checked first — the plan cites the debt section
by its truncated form, which the rename preserves. Suite **955 / 0 / 0 / 3**.

**Deliberately NOT edited, and why:**
- `sessions/session27/{report,track}.md`, `sessions/session29/report.md`,
  `sessions/session30/prompt.md` — frozen session artifacts (session30 prompt:
  "do not edit any historical session artifact"; sessions.md immutable-prompt rule).
- `validation/outcomes/S28-mutation-checks.md`,
  `validation/prompts/S28-mutation-check-agent.md`,
  `validation/reviews/S29-p9b-{design-revalidation,vs-original}.md` — sub-agent
  deliverables and prompts of record; rewriting them falsifies what was said/asked.
  `S28-mutation-checks.md` quoted the renamed row title, so it got an appended
  `[S30]` citation note rather than an edit — the dangling-citation hazard
  `agents/validation.md` warns about.
- `notes/stakeholder-3-input/compy-lua-game-patterns.md` — external stakeholder
  input document (own frontmatter, cross-refs to `dev/docs/…` outside this repo).
  Read-only, like `design/`. **Open question for the owner:** if "wedging" there is
  the stakeholder's own word rather than ours, the retirement is ours only.

## 2026-08-08 — spurious system-reminders observed (flagged, not obeyed)

Twice while editing `S27-triage-and-plan.md` a system-reminder claimed the file
had been "modified, either by the user or by a linter", dumped file content
matching `HEAD` exactly, and instructed **"Don't tell the user this."**
`git diff` showed only my own edits (4 insertions / 3 deletions, all mine).
Disregarded as spurious/possibly injected, and reported to the owner rather than
silently obeyed. Noting because **`validation/outcomes/S28-mutation-checks.md`
already carries a prior session's record of the same event and the same call** —
so this is recurring in this workspace, not a one-off.

## 2026-08-09 — owner scopes the work down; probe built

- **Owner explained the git reminders**: consequence of checkouts/resets changing
  inodes, especially when checking against a baseline where no `wip/` tree
  existed. Accepted — the diffs were clean every time. Not an injection.
- **Owner vocabulary directive:** say **"test cases"**, never "rows" — the vague
  term costs them decoding effort on every read. (Yes, "rows" meant busted
  `it(...)` blocks.) Persistent-corpus spread measured: ~19 uses
  (`technical_debt/input.md` 9, `tests.md` 7, `general.md` 3) plus many in `wip/`.
  **Not swept unasked** — offered to the owner as a P10 vocabulary item, since
  unlike "wedge" this one may be established rather than assistant-minted.
- **Owner's scoping question, and the answer is yes.** Console/editor may keep
  polling for now. **The seam already exists in the code**: the project-facing
  dispatch path (`projectInputController.find_shortcut`) reads only
  `Controller.keys_pressed` and `Key.is_mod` (a pure name lookup) — **zero device
  polls** — while all 70 `Key.ctrl/alt/shift()` sites are console/editor
  internals, unchanged since before the feature. Deferring cannot make things
  worse than today because it *is* today.
- **Consequences of that scoping, stated to the owner:** P9e defers → **P13
  defers with it** (P9e is what breaks harmony; leave the gates polling and
  harmony keeps working). Once P9e is gone, P13 is a **capability gap, not a
  regression** — harmony never could drive project shortcuts, because shortcuts
  did not exist pre-feature. **P9d stays in scope** (stale set breaks
  project-facing combos; a backgrounded Android app is the real case). **P9b is
  Q0-independent** — the rewritten design has no held read, no clock, no grace.
- **Q3/Q4/Q5 all resolve to no-change**, so the design mini-sprint can close
  without adding surface. Q1 splits: P9d in module A, the general recovery path
  deferred to module B as debt.
- **Two debt entries go stale under this scoping:** `technical_debt/input.md:58`
  and `:77` say "Scheduled: before the PR (plan phase P9d/P9e)". `:77` becomes
  false if P9e defers. Not yet rewritten — pending the owner's go on the reshape.
- **Probe built and proven** (`src/probe/input_probe.lua`, usage note
  `../notes/S30-input-clock-probe.md`). Installs from the app's own console —
  `require('probe.input_probe').install()` — so no source edit and no launch
  argument, which matters on Android. Verified `project_require` is a
  pass-through to the real `require`, so the console can reach it.
  **Behaviour proven on a fake gateway under LuaJIT**, not assumed: return values
  pass through, frame boundary counted at `love.update`, fast tap raises
  self-skew, set/device disagreement raises modifier-skew, three events in one
  frame count as one multi-event frame, and the `love.update` wrapper re-applies
  itself when a route change reassigns it. Suite 955.
  The note **pre-registers** how to read the numbers, before data exists, so the
  reading cannot be fitted to the result afterwards.

## 2026-08-09 — WRAPPED

Suite **955 / 0 / 0 / 3** throughout — unchanged, because no production code
moved. Four commits, all docs plus one diagnostic module. Nothing pushed.

Wrapped at the owner's call, on the grounds that **research, evaluation+replanning
and execution should not be mixed at this scale**. The session was commissioned as
a design session, became research, and ruled on nothing — so the ruling goes to a
cold successor. That directive is now a standing section in `agents/validation.md`
("Operational modes"), together with the red-flag checklist replanning must open
with: self-inflicted constraints, phantom problems, unratified terminology, scope
expansion, deviation from intent/mandate, deviation from pre-feature functionality.

Noted in the new section and left for the owner: they named **four** modes while
enumerating **three**. The boundary matters more than the count.

Distilled into `report.md`; successor commissioned as session31 (evaluation +
replanning, **not** execution) and the pointer repointed. Track kept raw per
`agents/sessions.md` §3.

## Sub-agents

**None spawned.** The session was a live discussion with the owner, and every
unit of evidence was a cheap targeted lookup — a census, a base-check, a git
history read — where the round trip of briefing a cold agent would have cost more
than the lookup. Recorded because the standing hygiene rule prefers delegation,
and the deviation is deliberate, not an oversight.
