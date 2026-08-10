---
description: S35 cold revalidation of P14c (tests step) and P14d (platform step), the keys_pressed dissolution
status: complete
audience: developer
authored: llm
reviewed: none
---

# S35 — cold revalidation of the tests step and the platform step

Review scope: `d630d12f~1..0a84e817` (all commits in that range read via `git show`, cross-checked
against the working tree at HEAD `de390ab9`, one commit past the reviewed range — that commit only
adds the review prompt this report answers, no code). `busted tests` run directly by me at HEAD:
**942 successes / 0 failures / 0 errors / 10 pending**, matching every commit's stated count and
the final track entry's claim exactly.

Commits reviewed, chronological: `d630d12f`, `6ea411ab`, `8fd6d589`, `e3d94104`, `2aaf07c1`,
`d2df5872`, `a510f88a`, `3f946640`, `354a1267`, `46952e4c`, `fb42b138` (the tests step, P14c, plus
the adjacent P15 work); `ac33ccb5`, `b0130412`, `91fbf07e`, `9cb5b636`, `c6d05685` (the platform
step, P14d); `9e241aaf`, `0a84e817` (plan/track bookkeeping).

## Verdict

**Sound as it stands.** This is an unusually well-executed pair of steps. I checked every factual
claim that was checkable — line ranges, behavioural-equivalence arguments, production code paths,
debt-register arithmetic, doc citations, the "must not do" lists for both steps, and the final
suite count — against the actual code and docs rather than the commit prose, per the commission's
own rule, and every one of them held up. I found **no omission**, **no excess**, and both
behavioural questions resolve in the author's favour on independent tracing, not just on the
author's say-so. The three declared deviations are all correct calls. The one thing I'd flag is
not a defect in this work: a stale arithmetic detail in the **ephemeral plan document**
(`S27-triage-and-plan.md`, itself outside `wip/77`'s persistent corpus and not part of the reviewed
commits) undercounts a device-call optimisation the platform step's own commit message states
correctly — see "Excess" below, filed there only because it's the closest fitting bucket, not
because anyone committed anything wrong.

## Omissions

**None found.** I walked §11.4.1 and §11.4.2 clause by clause:

- **P14c (§11.4.1):** both kinds of spec dissolution (withdrawn-contract deletion in `6ea411ab`,
  never-contract NFR guards in `8fd6d589`) landed, each in a genuinely separate commit as the plan
  demanded, with the reasons kept apart. The fixture-fidelity change (`2aaf07c1`) landed. The
  file-rename housekeeping and all four named citation moves (`event_dispatch_layers.md`,
  `tests.md` twice, `input_session.lua`) landed, verified against the actual diffs, not assumed.
  The "must NOT do" list (§11.4.1.5) — no `Key.ctrl()`-call assertions, no pinning a modifier's own
  press, no guard-hoist assertion, no new `gui` cases, no device-level guard replacements — is
  clean; I read every test diff in the step and none of these appear.
- **P14d (§11.4.2):** every named site in the role inventory is gone or rewired exactly as the
  role called for. Verified directly in the tree at HEAD:
  - the consumer (`find_shortcut`, `projectInputController.lua:103-110`) — rewired, loses its
    argument, guard hoisted;
  - the builder's parameter (`combo_string`/`any_mod`, `controller.lua`) — rewired to call
    `Key.ctrl()`/`Key.alt()`/`Key.shift()`, no table parameter;
  - the bookkeeping (`controller.lua:788,906` writes) — removed, confirmed by reading the current
    `handlers.keypressed`/`handlers.keyreleased` bodies;
  - the field, the view (`held_keys()`) and its two memoisation upvalues — removed, confirmed
    `git grep -n "keys_pressed\|held_keys" -- src/ tests/` (excluding `src/examples/`) returns
    **nothing**;
  - the sandbox exposure (`consoleController.lua`'s `if k == 'keys_pressed'` branch,
    `build_input_surface`'s `get_keys` parameter, the `held` upvalue plumbing) — removed; the
    function signature itself now takes no `get_keys` parameter at all, matching the "adjacent-code
    rule" the plan called for rather than a parameter kept alive for a replacement;
  - declarations/prose (`types.lua:251`'s `@field keys_pressed`, `userInputController.lua:490`'s
    comment) — both removed;
  - the `gui` row (`gui_k`, the fourth `mod_triples` row, `mod_rank`, `mod_order`) — removed from
    `src/util/key.lua`, confirmed by reading the file in full at HEAD.
  - Doc obligations: **zero `PENDING` markers remain** in the persistent corpus — verified myself
    with `grep -rn PENDING doc/input_api.md doc/development/internals/ doc/development/decisions/
    doc/development/technical_debt/`, empty. **Five debt entries deleted**, and I independently
    re-derived the "four defects in five entries" arithmetic (see "What I checked" below) rather
    than accepting the count — it's right.
- Both steps' "must NOT do" lists (§11.4.2.5) are respected: `src/harmony/` is untouched (empty
  diff for that path across the whole range), the `NOTE` above `combo_string` keeps only its
  allocation half, and the mocks' own `lgui`/`rgui` device slots survive in both
  `tests/mock.lua` and `src/harmony/init.lua` (a device still has those keys) — the "do not sweep
  on the word `held`" instruction is respected exactly.

## Excess

**None found in the reviewed commits.** `git diff --stat d630d12f~1..0a84e817 -- src/ tests/` and
the equivalent for `doc/` (excluding `wip/`) both list **only** files the plan named by role —
`consoleController.lua`, `controller.lua`, `projectInputController.lua`, `userInputController.lua`,
`types.lua`, `util/key.lua`, the named test files, and the five persistent docs (`input_api.md`,
`internals/user_input.md`, `internals/event_dispatch_layers.md`, `technical_debt/input.md`,
`tests.md`). No stray file, no comment-sweep scope creep, no `decisions/input.md` edits (Decisions
30/31 predate this range and are correctly left alone). No in-code `REMARK:` marker anywhere in the
diff was added, edited, or removed — I grepped every `+`/`-` line across the full range for
`REMARK` and the only two hits are prose *about* the convention (a track-entry sentence and a
sub-agent prompt's house rule), not an actual marker being touched; I additionally spot-checked the
one `REMARK` line sitting directly inside a diff's unchanged context
(`tests/helpers/input_session.lua`, in `2aaf07c1`) and the one at `internals/user_input.md:306`
(deliberately left alone per `c6d05685`'s own stated judgement call, next to a stale `DEFERRED`
citation that I confirmed via `grep -rn DEFERRED src/ tests/` — genuinely nowhere in code, so the
"leave it for the comment sweep" call is correct, not a dodge).

**One thing worth naming, filed here only for lack of a better bucket — not a defect in the
commits under review.** The *plan document*'s P14d table cell (`S27-triage-and-plan.md`, dated
`[S33]`, i.e. written before the shape ruling that actually landed) states "an unmodified pointer
motion now costs up to **4** device calls instead of 8." I recomputed this against the shipped
code: `any_mod()` calls `MOD_HELD[m[3]]()` for `ctrl`/`alt`/`shift` in turn (3 rows, since `gui` is
gone), each of which is **one** call to `Key.ctrl`/`Key.alt`/`Key.shift`, itself one variadic call
to `love.keyboard.isDown`. Worst case (no modifier held, so no early return) is **3** device calls,
not 4 — which is exactly what `b0130412`'s own commit message says ("up to 3 device calls instead
of 8"). The commit is right; the ephemeral plan cell is stale by one, evidently unrefreshed after
the final shape ruling. It's in `wip/77` scratch, not the persistent corpus, and none of the
reviewed commits touch that cell, so it isn't a finding against this work — but it's a fact I
verified and would otherwise have had to re-derive later, so it's recorded here for the parent.

## Appropriateness

- **Remove-vs-rewire calls are all correct.** `find_shortcut` and `combo_string`/`any_mod` were
  rewired (own purpose, lost only their argument); the bookkeeping, field, view, sandbox branch and
  declarations were removed outright (existed only because the set existed). This is exactly the
  role-based test the plan itself specified, applied consistently.
- **The test deletions are appropriately scoped, and the one place coverage was actually lost is
  named as such, in its own commit.** `8fd6d589` (the 4 NFR guards) is explicitly called out —
  by the commit message, and independently confirmed by me — as the one place the suite loses the
  ability to catch something, kept apart from the withdrawn-contract deletion (`6ea411ab`) for
  exactly that reason. This is the honest accounting the PR description will need, already staged.
- **Doc passages that lost their `PENDING` marker are true of the tree now**, checked by reading
  the passages myself rather than trusting the marker's removal: `internals/user_input.md`'s "Key
  state" section (lines 241–296) accurately describes `Key.ctrl()`/`alt()`/`shift()` as the single
  source, three modifier rows not four, `combo_string`/`any_mod` taking no table parameter, and the
  `dispatch` citation now points at a named in-code anchor (`"the three-consumer walk"`) that I
  confirmed exists verbatim at `projectInputController.lua:116`, replacing a line-number citation
  that had already drifted ~60 lines out of date — a real, separate pre-existing rot the step
  fixed as a byproduct of having to re-read the section it was certifying.
- **The debt-register deletion arithmetic is right.** I independently re-derived "four defects in
  five entries" rather than trusting the commit: the five deleted entries are (1) "held-key set
  never cleared on focus loss" (Standing), (2) "the gateway asks the device a question about an
  event" (Standing), (3) "the held-key surface is a table that cannot be iterated" (Standing), (4)
  "`keys_pressed` can go stale on focus loss" (a second section, later in the file), (5) "Held-key
  pressed-keys view iteration is index-only" (a third section). (1) and (4) describe the identical
  focus-loss defect under two headings — the commit's own claim, and correct on inspection: same
  root cause, same "no focus handler installed" fact, same fix shape. That leaves (2), (3), (5) as
  three independent defects, for a total of 4 distinct defects recorded across the 5 deleted
  entries. Arithmetic reconciles exactly as claimed. The two entries the plan said would **stay**
  — `gui` and "service keys" — are both still present at HEAD (`technical_debt/input.md:734` and
  `:752`), correctly untouched by the deletion pass because they record decisions, not defects.

## The three deviations

1. **Narrower test-deletion range than planned (`input_events_spec.lua:776-863` used instead of
   the plan's `:781-901`).** **Right, and independently reconfirmed by me from first principles,
   not by re-reading the commit's own math.** I read the pre-commit file
   (`git show d630d12f^:tests/input/input_events_spec.lua`) and counted lines myself: the "held-key
   table" comment starts at line 776, the closing `end)` of the `compy.input.keys_pressed` describe
   sits at line 863 — exactly the claimed span, comments included. The plan's wider range
   (`:781-901`) would have silently deleted `:865-899`, two live and unrelated widget
   uniform-signature test cases (Decision 26's own contract). The narrower cut is correct and
   nothing is now missing that the wider cut would have removed correctly — the wider cut was
   simply wrong.
2. **The `gui` combo-serialisation case rewritten, not deleted.** **Right.** The case ("all
   modifiers: ctrl alt shift gui" → "all modifiers: ctrl alt shift") is the only one in the suite
   that exercises the complete precedence fold with every modifier held at once; its subject was
   always precedence ordering, not `gui`'s presence. Deleting it outright, as the plan's literal
   text said, would have been a real (if small) coverage loss for a clause that was only ever
   trying to remove `gui`-referencing content, not protect `gui` specifically. No case names `gui`
   after the change (confirmed by reading `input_combo_serialisation_spec.lua` at HEAD), which is
   what the actual ruling required.
3. **Three shortcut test cases moved from Ctrl+S to Ctrl+J.** **Right, and I traced the production
   code myself rather than accepting the characterisation.** Read
   `src/controller/controller.lua:766-875` (`setup_callback_handlers`'s `handlers.keypressed`):
   `project_state_change()` — which contains `if k == "s" then if love.state.app_state == 'running'
   then CC:stop_project_run() end ...`, gated on `Key.ctrl()` — runs **before** the gateway's
   forwarding line (`if love.keypressed then return love.keypressed(k, sc, isr) end`). Confirmed
   `F.activate_project()` (`tests/helpers/input_fixture.lua:236-240`) sets
   `love.state.app_state = 'running'` for exactly the tests in question. So once the fixture
   honestly holds Ctrl on the device, a `ctrl+s` keypress **is** intercepted by the gateway's
   power-shortcut gate and the project route is torn down before a project's own
   `shortcuts.keypressed['ctrl+s']` could ever be reached. The three old cases could only have
   passed because the pre-fix mock device was permanently blank (`Key.ctrl()` false), letting the
   event fall through to the project route by fixture accident, not by anything the production code
   actually does. Moving to `ctrl+j` (a trigger the gateway does not claim) is the right fix for
   what these cases are actually testing — combo normalisation — and is not a case of rewriting a
   test to make an inconvenient failure disappear: the failure it would have produced was **true**,
   not spurious, and the cases' own subject was never "who wins a contested combo."

## The two behavioural questions

1. **The guard hoist in `find_shortcut` — behaviour-identical, verified by tracing the combo
   grammar myself.** Read `src/util/key.lua`'s `split_combo`/`check_combo` (invoked on every
   registration via `new_handler_table`'s `__newindex`, confirmed at
   `consoleController.lua:797` — `shortcut_tables[ev] = Key.new_handler_table()`). For any combo
   string built from a modifier's own key name as sole trigger (`'lalt'`, or `'alt+lalt'` as
   `find_shortcut` would have built pre-hoist), `split_combo` folds every token via `fold_mod`; a
   folded token that also appears in `mod_rank` (`ctrl`/`alt`/`shift`) is classified as a
   **modifier**, never a trigger — so the trigger count `n` is `0` for both strings, and
   `check_combo` raises `"names no trigger"`. **Consequence: no combo string with a modifier as its
   own trigger can ever pass registration**, so `tbl[Controller.combo_string(trigger)]` on that
   path was *always* a guaranteed-`nil` lookup before the hoist — the `sc or Key.is_mod(trigger)`
   fallback was reachable but `sc` could never have been anything other than `nil` when it mattered.
   Hoisting `if Key.is_mod(trigger) then return end` to the top of the branch therefore removes a
   build-and-lookup that was structurally incapable of ever succeeding, and changes nothing
   observable. The claim holds.
2. **The fixture holding modifiers on the mock device — does not weaken or void any assertion I
   could find.** Reasoned through the mechanism: `F.session.press`/`repeat_press`/`release` now
   call `mock.hold`/`unhold` in addition to firing the real gateway event, and `F.reset()` (run
   `before_each`) calls `mock.release_keys()`, so there's no cross-test leakage. Before this
   change, `F.session.press('lctrl')` only fed the (now-removed) tracked-set bookkeeping, never the
   device (`love.keyboard.isDown`) — so any code path reading the device directly (the gateway's
   own power-shortcut gate, and per Decision 14 the widget's own submit-guard reading `Key.shift()`
   directly) was **not** actually exercised by a plain `F.session.press`, only by the separate
   `mock.keystroke` driver. That gap is exactly what `2aaf07c1` closes, and it closes it in the
   direction of **more** faithful modelling, not less — it's what *surfaced* the real Ctrl+S
   shadowing (deviation 3), which is the opposite of a test quietly losing power. I specifically
   checked the one place the commit's own comment flags redundancy
   (`input_widget_callbacks_spec.lua:537-540`, Shift+Return): the explicit `F.session.press('lshift')`
   and the following `mock.keystroke('S-return', ...)` now both set the same device flag, which the
   updated comment states plainly rather than hides — the test's assertion is on the widget's
   final text state, unaffected either way. I did not find any test whose *outcome* now depends on
   the redundancy rather than on the code under test, and I did not find a case where a previously
   meaningful "modifier not held" branch became untestable or unconditionally true because of the
   fixture change. The one thing I could not fully rule out without reverting code (which I was not
   permitted to do) is whether some *other*, unrelated existing test relies on a modifier staying
   *unheld* across an assertion inside the same test body without an intervening release — I looked
   for this pattern and found none in the diffed files, and the full suite is green, which is
   evidence against it but not proof for every file outside the diff.

## What I checked and found correct (so the parent does not re-derive it)

- Every line-range and citation-move claim in P14c's commits (`6ea411ab`, `8fd6d589`, `e3d94104`,
  `a510f88a`) — re-derived independently from the pre-commit file contents, not accepted from the
  message.
- The sub-agent citation sweep (`d2df5872`'s deliverable) — read in full; its two findings
  (untracked `.claude/settings.local.json` stale paths) are correctly out of tracked scope and
  correctly left for the owner; its "checked and already correct" list matches what I independently
  see in the tree; the stale-suite-count flag it raised was in fact fixed in the very next commit
  (`a510f88a`).
- Both P15 test cases (`46952e4c`) traced against `controller.lua`/`consoleController.lua`:
  `ctrl+pause` → `suspend_run` (route-preserving, no `set_default_handlers` call) and `ctrl+q` →
  `quit_project` → `stop_project_run` (route-destroying, `set_default_handlers` runs before the
  gateway's forwarding line) both match their test assertions exactly, including the
  `app_state == 'project_open'` detail (`close_project()` inside `quit_project` only advances to
  `'ready'` if `P.current` is set, which the test fixture leaves unset).
  The `f10`-has-no-modifier-gate correction is confirmed against `controller.lua`'s `profile()`
  local: a bare, unconditional `if k == "f10" then`.
- `git grep -n "keys_pressed\|held_keys" -- src/ tests/` (excluding `src/examples/`) returns
  nothing at HEAD — the dissolution is complete in first-party code.
- `src/examples/keyboard` (a separate nested repo, plain `grep` since it's outside the main repo's
  git boundary) **still** references `compy.input.keys_pressed` in three places
  (`help.lua:11`, `input.lua:43,57,109`) — this is **expected and correctly out of scope**: the
  plan explicitly defers examples to P14e ("Do not fix the examples here"), and the commit message
  for `9cb5b636` says so in the same breath it reports the grep. Not a regression, not an omission
  of P14c/P14d — a live pointer to work not yet done, exactly as scheduled.
- `src/harmony/` untouched across the whole range (empty diff); its `lgui`/`rgui` tokens, and
  `tests/mock.lua`'s, both remain — matches the "these are device mocks, a device still has those
  keys" carve-out.
- Zero `PENDING` markers anywhere in the persistent corpus at HEAD; zero `REMARK`/`INTERIM` markers
  touched by any commit in the range; the one `REMARK` the platform step deliberately left alone
  (`internals/user_input.md:306`, next to a `DEFERRED` citation) checks out — `grep -rn DEFERRED
  src/ tests/` finds nothing, confirming the citation really is pre-existing rot outside this
  step's remit, not a dodge.
- `busted tests` run by me at HEAD: **942 / 0 / 0 / 10**, matching every commit's stated count
  through the whole range.

## What I could not determine

- **Historical/transient claims I could not reproduce without reverting code** (which the brief
  prohibits): the "13 cases failed on device leakage" figure in `d2df5872`'s track entry (before
  `mock.release_keys()` was wired into `F.reset()`), and the sub-agent's report of transient,
  stale `mcp__lua-lsp__references` results (phantom `.tmp.*` shadow paths, results for the deleted
  `keys_pressed_spec.lua`) during the citation sweep. Both are plausible and consistent with
  everything else I verified, but I have no way to independently re-run them against the
  now-different tree state without git operations I'm not permitted to use.
- **Whether some test outside the diffed files** relies on a modifier staying unheld within a
  single test body across an assertion boundary in a way the fixture change could silently defeat
  — see behavioural question 2 above. I looked for this pattern in the changed files and found
  none, and the full suite (beyond just `#input`) is green, which is evidence against a live
  problem, but I did not exhaustively read every test file in the repo for this pattern.
- **Whether the `ctrl+j` choice itself** (as opposed to some other unclaimed trigger) has any
  second-order interaction I haven't spotted — I checked it's not one of the ~9 reserved gateway
  combos enumerated in `46952e4c`'s own audit, which is the only reservation list this codebase
  has, so I'm reasonably confident but did not independently re-derive that enumeration from
  scratch (I did independently re-verify two of its entries — `ctrl+pause`/`ctrl+q` — and the
  `f10` correction — against source, not all nine).
