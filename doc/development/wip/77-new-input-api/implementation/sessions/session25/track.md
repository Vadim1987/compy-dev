# session25 — track

## 2026-08-01 — boot

- Booted per `agents/validation.md` boot ritual + `agents/sessions.md`.
  Re-entrance guardrail: `session25/` held only `prompt.md` — no `track.md`,
  no `report.md` → **fresh start**; this entry opens the track.
- HEAD `a77ab9a7` (`docs(session24): wrap — report, session25 prompt,
  pointer`), branch `feature/77-newapi-analysis-s20260615`, `git status`
  clean apart from the sanctioned untracked scratch + the three nested
  example repos (no longer anomalies — owner 2026-07-31).
- Read: `agents/validation.md`, `agents/sessions.md`,
  `agents/rules/revalidation.md`, `session25/prompt.md`,
  `session24/{prompt,report,track}.md`,
  `validation/reviews/S24-contradictions.md`.
- Baseline `busted tests` → **874 / 0 / 0 / 3**, exactly the count the
  session25 prompt and the session24 report state. (`agents/validation.md`'s
  fallback line still says 854/0/0/4 — the prompt is authoritative per that
  same section; noting, not "fixing".)
- Task per prompt: **revalidation of session24** per
  `agents/rules/revalidation.md`, ordered C1 (Decision 19 seal — intent vs
  outcome, recommendation + revert surface, ruling is the owner's) → C2
  (finish maze/balloons/keyboard migrations to the platform standard, correct
  `pr-assembly-guide.md` §5) → re-evaluate what remains between here and a
  stakeholder-readable PR. No next substantive task without owner approval.
- Reported the orientation to the owner; awaiting their go before working the
  checklist.

## 2026-08-01 — C1 ruled and executed

- Owner: *"yes, C1. and to avoid confusion I specifically request reverting any
  relevant codebase/doc changes except the tests that surface the problem. if
  needed, these reversed changes could be stored in wip workspace as suggested
  patch (literally a diff file)."* — the ruling arrived **before** the
  recommendation, so the seal is out on ratification grounds alone.
- `190f0c9` reverts the mechanism everywhere. Completeness proved, not
  asserted: the five non-test files are byte-identical to `eadcc8cd` (the
  commit before the seal landed) and a tree-wide grep for the four symbols is
  empty. C1's revert table was accurate.
- Test disposition: 2 rows kept as `pending` (they reproduce the defect,
  citing the new debt entry); the third pinned the *seal's* lifetime, not the
  contract, so it left with the mechanism into the patch. Suite
  **874 → 871 / 0 / 0 / 5**. Live-and-red was not available —
  suite-green-at-every-commit is standing.
- The race is now persistent-corpus debt: `technical_debt/input.md`, *"An
  overlay opened from a key can receive that key's own echo"*, options (a)–(d),
  revisit = a design pass.
- Four claims re-verified in code rather than carried forward; **two of them
  were wrong**, both mine from session24:
  - "release at update silently assumes no other pump" — over-cautious. compy
    *owns* its loop (`harmony/init.lua:104` replaces `love.run`; poll-all →
    update → draw), and the only other pump is the crash explorer, which never
    reaches `love.handlers`.
  - "no project can fix this for itself" — too strong. A project cannot
    *consume* the echo but can *undo* it (`clear()`/`set_text` on the next
    update). Option (d) is ugly, not impossible — which changes how the
    do-nothing baseline should be priced.
- Assessment + option set (adds (a′) one-textinput and (e) deferred-show to the
  recorded four) + patch pointer:
  `validation/reviews/S25-C1-event-batch-seal.md`. Patch:
  `validation/notes/S25-C1-event-batch-seal.patch`, verified to apply cleanly
  at `190f0c9`.
- `lua-lsp` MCP was down all session (broken pipe on every call); symbol facts
  were established by grep plus byte-identity against `eadcc8cd` instead.

## 2026-08-03 — owner proposes the paired-shortcut idiom; spiked

- Owner: address C1 with *"a specific order-agnostic setup"* — the trigger
  registered on BOTH channels, `shortcuts.keypressed[combo]` opening and
  `shortcuts.textinput[combo]` swallowing the echo and unregistering itself,
  re-armed by whatever closes the widget.
- **It works.** Spiked against the real chain, 6/6 including a deliberate
  negative row. Both delivery orders come up with an empty field; order B (the
  echo arriving BEFORE the keypress) is eaten while the overlay is still
  closed, which is why nothing depends on LÖVE's ordering. Evidence + source:
  `validation/notes/S25-C1-paired-shortcut-spike.md`.
- Why the chain permits it (`projectInputController.lua:71-83`): shortcuts run
  before the widget **on every channel**, the lookup is a direct index (so a
  handler may delete its own slot mid-flight), and leaf writes are allowed
  though sub-table identities are frozen.
- **Two limits, one of them somebody else's bug.** (i) No `after_hide`
  callback and Escape clears without hiding, so the re-arm has no single home
  and rots when a close path is added later. (ii) Only bare combos work:
  measured — dispatch looks up `shift+I`, registration stores `shift+i`, so
  the slot is unreachable. That is the ledger's own "combo_string does not
  normalise the case of a textinput token", whose revisit condition was "if a
  real textinput-combo consumer appears" — this proposal IS that consumer, so
  the entry is updated with the measurement and the trigger noted as fired.
- **Recommendation revised** (was: ratify (a) as implemented). Now split:
  ship-without-framework-change → (d′) documented; if the framework does
  change → (a′), the framework arming the one-shot itself, which as a
  *wildcard* needs no combo lookup and so dodges limit (ii) entirely. The
  owner's idea is what makes (a′) expressible in the existing shortcuts
  vocabulary instead of as new widget state.
- Behavioural note: the owner reaches for composition of existing primitives
  before new mechanism — and it paid, twice: a better (d), and a better (a).

## 2026-08-03 — (d′) adopted; docs + turtle migrated

- Owner: *"now, lets update the docs and turtle example"* → (d′) is the ruled
  answer. Executed in two commits.
- `66e8719f` — `doc/input_api.md` gains "Opening the overlay from a key" (the
  idiom, why it is order-agnostic, where the re-arm goes, and the bare-trigger
  limitation stated plainly). The two parked pendings become **four live
  rows** pinning the guide's shape: a documented idiom rots unless pinned.
  Debt entry restatused from "no mechanism ruled" to "answered by a documented
  idiom"; what stays open is whether the framework should ever take it over.
  Suite **871 → 875 / 0 / 0 / 3** — pending is back to the intentional 3.
- `a0df94aa` — turtle carries `arm_echo_guard()`, re-armed in `after_submit`
  beside the `hide()`. Verified rather than assumed: top-level registration
  survives activation, because `activate()` seeds hooks only and runs *after*
  the project's top-level code (`projectInputController.lua`, `seed_hooks`
  doc comment), so the table the project wrote to is the one dispatch reads.
- Discovered, not fixed (report-don't-fix): `src/examples/turtle/main.lua`
  carries pre-existing comment lines at 68–71 chars, over the 64 hard limit —
  including ones added during this feature. My added lines are ≤64, so the
  file is now mixed-width. Same class as other example-era debt.
- **Scancode question** (owner, same turn): *should combo registration and
  dispatch key on scancode?* Answered, not executed —
  `validation/notes/S25-scancode-question.md`. Short version: **no as a C1
  fix** (`love.textinput(text)` carries no scancode at all, so it cannot
  unify the channels — it widens the gap), and **a real but separate question**
  for the shortcuts surface, where compy has both audiences (positional WASD
  wants scancode; mnemonic ctrl+s and turtle's `i` want the key name). Cost is
  understated at first glance: the gateway *discards* the scancode today
  (`keypressed(k, _, isr)`), and `keys_pressed` is key-name-keyed, so
  `combo_string`'s modifier prefixes would need the same treatment. Recommend
  not now and never as a swap; additively if a positional consumer appears.

## 2026-08-03 — C2 executed

- **maze** (`d2ce7a0`). Both open questions answered by checking, not
  assuming. `submit_flow` runs the callbacks and returns — it touches neither
  the model nor `shown` — so a rejected command's text stays in the field with
  the player still idle, and the prompt stays up on its own: `need_reopen` /
  `reopen_text` were carrying text across a close that no longer happens, and
  are gone. "Prompt only while idle" was silently LOST, not merely implicit —
  with nothing closing the overlay, `rearm_input` hit its `is_shown()` early
  return forever and the prompt stayed up mid-move. Now explicit: sync to
  `player_is_idle()` each tick, hide when a move plays out, reopen when it
  lands. Reopening is also the clear — `open_fresh` calls `clear_input()` when
  `cfg.text == nil`, so `show{}` with no text empties the field. (Note: it is
  **show** that clears, not `hide()`, which only drops `shown` and the state
  flag — turtle's comment says otherwise and is imprecise.)
- No echo guard needed in maze: the prompt opens from `update` (ctrl_update →
  rearm_input) and from `editor()` at level init, never from a key event.
- **balloons** (`cc0dbd7`) — a REAL defect found by reviewing the two commits
  end-to-end, not a tidy-up. `on_text_entered` delivers an array of line
  strings (suite pins `assert.same({'hi'}, got)`); the retired `terminal()`
  returned one string; the migration passed the array straight to handlers
  that index `game_commands[txt]`. Silent, because `action_map.__index`
  returns the fallback on a miss — every typed command re-prompted instead of
  running, and in the active state `fmt(GAME_PROMPT, txt)` would render a
  table address. Fixed with `string.unlines` in `deliver`. The earlier
  after_submit raise masked it: balloons never got past load.
- **keyboard** — confirmed needs nothing, and the route-retention claim
  verified rather than carried: it uses no `compy.input` at all, and keeps the
  project route because it defines `love.update`/`love.draw`, so
  `user_is_blocking()` holds it. Recommending `compy.input.shortcuts` would be
  wrong — it wants every key, not combos.
- Discovered, reported not fixed: `user_is_interactive()` counts an overlay or
  a pointer handler, never seeded keyboard hooks, so a hooks-only project (no
  draw/update/overlay/pointer) would lose the route and its captured hooks
  would never fire. Hypothetical — no such project exists — filed under
  Anticipated in `technical_debt/input.md`.
## 2026-08-03 — owner overturns the keyboard verdict

- Owner: *"I am surprised how keyboard (project most tied to keyboard input)
  is not supposedly benefitting from new API. what's the point and value of
  API then? if all that keyboard does is reacting to keypresses, why would we
  even encourage doing that outside of new API?"*
- **They are right and I was wrong — twice.** Session24 answered smoke report
  7 (*does keyboard bypass the routes?*) and I carried that answer into a
  second, unasked verdict (*nothing to migrate*), which I then re-confirmed
  today after checking only route retention. Checking what keyboard *does*
  with keys takes ten minutes and inverts it.
- Four re-implementations, all verified: hand-rolled combo dispatch with its
  own l/r modifier fold (`reservedChord`/`appChord`/`modHeld` vs Decision 8 +
  `Key.mod_triples`); a key-repeat filter; a held-key mirror; and leaked
  global key-repeat state.
- **Two of keyboard's own comments document limitations this feature
  removed.** (i) *"the IDE strips the isrepeat flag"* — true at `3256aac`
  (`local function keypressed(k)`, one parameter), false now
  (`_dispatch('keypressed', k, k, held_keys(), isr)`). (ii) *"the runner
  exposes no project-exit cleanup hook"* — `compy.before_exit` exists
  (`consoleController.lua:705-728`). Nobody told keyboard either was fixed.
- **The finding that can still move the platform:** `keyboard_view.lua:171,178`
  read held-modifier state **during draw**. The callback-arg shape cannot
  serve a per-frame renderer, so the standing open decision
  "`compy.keys_pressed` is not exposed to projects" now has its real consumer,
  and the evidence rules out the "callback-arg is the sanctioned shape"
  answer. Ledger entry updated; the ruling is the owner's.
- Also corroborating: keyboard independently documented the
  textinput-before-keypress ordering hazard — C1's problem, found by an
  unrelated project before we did.
- Write-up `validation/reviews/S25-keyboard-verdict-overturned.md`; §5
  corrected in the same commit. Migration scoped there but NOT executed —
  750 lines of another repo's game logic is the owner's call, and unlike
  maze/balloons it is not a consequence of our API change.
- Behavioural note: the owner tests a verdict by asking what it implies about
  the *product* ("what's the point of the API then"), not by re-checking the
  evidence. Both overturned verdicts this session came from that move.

### both ruled and executed (2026-08-03)

Owner: *"sure we want it. the reason why game invented its own equivalents was
our API not being ready. so its the best demo case and acceptance. and yes
lets expose the table"*.

- **Decision 20 / `compy.input.keys_pressed`** (`a3e3d39`, platform).
  Tests-first: 4 rows red, then the surface. Resolved through
  `build_input_surface`'s `__index` on **every access**, never captured — the
  view is rebuilt when its backing identity changes, so a build-time reference
  would go stale. Placement (`compy.input`, not top-level `compy`) is mine and
  says so in the ledger entry; the ruling was to expose the table.
  Suite **875 → 879 / 0 / 0 / 3**.
- **keyboard** (`4814407`). Hooks instead of `love.*` wrappers; three reserved
  chords as shortcuts; `isrepeat` instead of edge tracking; `INPUT` reduced
  from a maintained mirror to a proxy over the framework's held set, leaving
  all five consumer files (`help`, `alt`, `findkey`, `hunt`, `keyboard_view`)
  untouched.
- **The trap worth remembering:** the mirror could NOT simply be swapped in
  for the repeat filter. `inputStale(k)` tested `INPUT.held[k]` *before*
  appKeypressed added the key, so "already held" meant "this is a repeat".
  The framework's set has the key in it **at dispatch time** for a fresh press
  too, so a naive swap would have filtered every keystroke. The keypressed
  path had to move to `isr`; the textinput path keeps the held test, where the
  framework's set is the more correct answer (textinput has no repeat flag).
- **Two open decisions got their first real consumer** — which is what an
  acceptance case is for. Shortcuts' `isrepeat` semantics: keyboard's chords
  hand-write `if not isr`, or a held `ctrl+alt+up` ramps the notch every
  frame; entry updated, with the caveat that once-per-press cannot just become
  the default (a movement key wants the opposite, so it may need to be
  per-registration). And the held-key exposure, now ruled.
- **New debt found by the migration:** a combo table cannot express a
  modifier-class rule ("every `alt+x` is a chord"), so `appChord` stays a
  hook. Recorded under Anticipated, with the note that the API guide should
  probably say so, since a reader may assume `shortcuts` covers it.
- **Unverified and flagged in the commit:** none of keyboard's behaviour is
  exercised by the platform suite and it cannot be driven headlessly. It joins
  C3 on the owner's smoke-test list.

### the isrepeat question, put properly (2026-08-03)

- Owner pushed on the `chord()` decorator: *"manual check of isrepeat flag in
  every shortcut handler is a serious code smell that points to suboptimal API
  design"*, and floated two shapes — auto-consume-without-invoking on repeat
  (leaning against it themselves), and splitting the shortcut table by the
  flag. Written up in `validation/reviews/S25-shortcuts-isrepeat.md`; nothing
  implemented, ruling theirs.
- Precision worth keeping: keyboard wrote **one decorator applied three
  times**, not a check per handler. The smell is real but its size is "one
  helper per project".
- The argument that decided my recommendation is not about repeats at all:
  **`shortcuts` and `hooks` differ today only in their lookup key**, not their
  semantics. Making shortcuts once-per-press gives the tier a meaning
  (cooked commands vs the raw channel), which is what "suboptimal design" is
  actually pointing at.
- Second-order: the capability auto-filtering would remove — hold-to-repeat
  driven by OS key repeat — is badly served by that primitive anyway (~500 ms
  initial delay, user-configured rate), and **Decision 20 has just made the
  better shape possible** (poll `keys_pressed` in `update`). The same proposal
  was weaker a week ago.
- Blast radius measured, not estimated: **one** test row (the
  "same delivered triple" row drives a repeat through a shortcut), zero
  examples other than keyboard, and zero consumers in the tree want
  repeat-firing shortcuts.
- Recommended A; C (ship `compy.input.once`) as the PR-safe fallback that does
  not foreclose A; B (split table) dropped — it breaks the
  `shortcuts.<event>` ↔ `love.<event>` mapping and moves a per-handler line
  into a per-registration decision.

### owner rules C; A dropped, and they were right (2026-08-03)

- *"i like the decorator option. lets implement and document and test this
  decorator. not using it blindly on hooks should be decision of developer."*
  **Recorded for implementation, deliberately NOT started** — plan in
  `validation/reviews/S25-shortcuts-isrepeat.md`.
- **Why my recommendation was wrong**, kept because the error is instructive:
  (i) I priced irrecoverable suppression as bounded, and it is not — the
  framework cannot tell a command binding from a hold-to-act one; (ii) I
  missed that a dispatch rule fixes only commands bound as *shortcuts* and
  leaves the same hand-written check in `hooks.keypressed`. **A decorator
  composes across all three tiers; a rule on one tier cannot.** That second
  point also dissolves the tier-semantics argument I had leaned on hardest.
- One correction back to the owner: their fall-through scenario describes a
  *third* variant (skip the tier on repeat), not A (consume without
  invoking). The skip variant is the genuinely broken one — repeats reach a
  shown widget. A was merely opinionated, not broken. The ruling stands either
  way.
- Owner nuance carried into the plan: the whole-channel-hook trap is a
  **caveat for the developer to weigh**, not a prohibition.

### owner: the noop default was asked for repeatedly and ignored — CONFIRMED

- Checked the record rather than taking a side. The owner is right, and it is
  **drift against a frozen document**, not a preference that lost an argument:
  `design/design.md:39` ratifies tier 3 as *"DEFAULT: noop (+debug log)"*, and
  `design/notes/decisions.md:297` has the table itself answering with a
  default, `:793` stating the intent — *"silent failure is replaced by a
  visible hint in debug mode"*.
- What shipped: nil guards (`if sc and sc(...)`, `if hk and hk(...)`) and
  **no logging at all** in `projectInputController.lua` — `Log` is not even
  required in that file.
- The reframe that matters: behaviourally a nil guard and a nil-returning noop
  are identical, which is presumably why it passed review — but the design's
  *reason* for the default was the debug log, and **you cannot log from a
  nil**. The lost thing is the ratified AC, not the `and`.
- Cost found: `seed_hooks` (`:44`) reads `hooks[event] == nil` as "unset", so
  a noop-returning `__index` would silently stop Decision 10's capture path;
  needs `rawget`. And a stored-table default would make
  `compy.input.hooks.textinput` answer with a function the project never
  installed — so the default belongs in the **dispatch view**, with the
  project-facing leaf surface still answering nil.
- Written up with both proposals: `validation/reviews/S25-noop-default-and-wildcards.md`.

### combo classes (`ctrl+alt+*`) — better than I had it

- Owner proposed the sanctioned form. It is cheaper than my debt entry
  implied: `normalize_combo` handles `*` **unchanged** (just a non-modifier
  token), the handler already gets the real trigger as argument 1, and
  precedence is one extra lookup on a miss only.
- The evidence that convinced me: keyboard's `appChord` needs an explicit
  `if INPUT.ctrl then return false end` to keep `ctrl+alt+h` out of the
  Alt class. With combo classes that exclusion is **free** — different
  modifier set, no match — so the wildcard is not just equivalent to the
  hand-rolled test, it is more correct. `appChord` collapses to two
  declarative entries.
- Recommended taking it; ruling needed on two corners (the `alt+lalt`
  self-match, and whether bare `*` is allowed when a hook already means that).
- The two proposals **compose**: the combo table's `__index` tries the class
  key, then falls back to the logging noop. The wildcard IS an `__index`
  behaviour — the mechanism the owner asked for originally.

### owner presses on the details; three of my claims corrected (2026-08-03)

- **"Dispatch view" was fiction.** `occupy_keyboard` passes `compy.input`
  itself to `pic:activate`, and `_dispatch` reads
  `self.compy_input.shortcuts`/`.hooks` — dispatch goes through the SAME
  proxies the project uses. There is no second view to hide a default in;
  making one is machinery, not scoping.
- **My objection to a stored default was already moot.** `seed_hooks` writes
  captured `love.*` into the hooks table, so a project that defined
  `love.keypressed` already finds `compy.input.hooks.keypressed` non-nil
  without assigning it. "Did I set this?" is not answerable today either.
  → the noop belongs on the store's `__index`, which is what the owner asked
  for originally.
- **And `rawget` does not rescue `seed_hooks`.** It receives the leaf *proxy*,
  an empty table over the store, so `rawget(proxy, k)` is always nil. Seeding
  needs an explicit is-set query or has to move to where the store is in
  scope. That is the one genuine cost, and I had named the wrong one.
- **Class lookup should be an explicit two-step read in `dispatch`, not
  `__index`** — the owner was right to question it. `__index` would hand a
  class handler back to a project inspecting an unregistered combo (a lie),
  and it buries precedence + the modifier-trigger exclusion inside a data
  structure. The class key needs no parsing:
  `combo_string('*', keys_pressed)` builds it from the same held set
  (measured → `ctrl+alt+*`). The noop default IS a default, so `__index` is
  right for *it*; the two are different concerns and my "they compose via
  `__index`" line was sloppy.
- **`a+b+*` opened a real defect.** The grammar is modifiers + exactly ONE
  trigger — a held non-modifier never enters the combo string (measured: `a`
  and `b` held, `b` pressed → `ctrl+alt+b`). And `normalize_combo` takes the
  LAST non-modifier token silently: `ctrl+a+b` → `ctrl+b`, and **`a+b+*` →
  `*`**, i.e. the widest binding from a string meant as the narrowest. New
  debt entry; the fix is to raise at registration, which also disposes of the
  bare-`*` question.

### owner partially reverts on noop; and the design backs them on grammar

- **Noop: RULED against the defaulting `__index`.** Owner's reason is better
  than either of mine: a hook's nil-ness is *information*, and code that
  installs/removes a handler conditionally on what another part installed
  needs it. A defaulting `__index` deletes an introspection capability rather
  than merely hiding a check. Explicit branches in `dispatch`, nil checks
  kept. Side effect: the `seed_hooks` problem evaporates — nothing changes
  there if nil keeps meaning unset.
- Raised back: taken literally at the combo tier, the log is a **flood** — a
  line per keystroke that is not a bound combo, 60/s under `love.DEBUG`.
  `design.md:39` puts the default at tier 3 (the generic callback), not the
  combo tier, and the useful signal is "the walk fell through entirely".
  Recommended one log where `dispatch` returns false. Also noted `dispatch`'s
  body is 11 lines against the 14 limit, so full if/elseif branches (+6) force
  a split; one `if not sc then …` per tier fits.
- **Grammar: the owner is right and the frozen design says so.**
  `design.md:348`, salvage register: *"Combo format: modifier-first fixed
  precedence …; registration normalised on assignment; **matcher = marked
  extension seam**"*. What is ratified is the SERIALISATION. "Exactly one
  trigger" is nowhere in it — it is a consequence of `combo_string` prepending
  only modifiers. I had been describing an implementation choice as if the
  design imposed it.
  - Consequence: combo classes land **inside** the seam the design marked.
  - The narrowing is still worth keeping, but on its merits: exact-lookup
    dispatch is sound only because a combo names every modifier that matters
    (`ctrl+s` deliberately does not fire with Alt held). Extend that to
    ordinary keys and every binding becomes conditional on nothing else being
    held — hold `a`, press `space`, and the `space` binding silently dies.
    The alternative ("named keys held, others ignored") is a subset test, not
    a lookup — `O(bindings)` per event. That IS the seam.
- **Disclosure I owed on the earlier ruling:** `design.md:367` records a
  provisional leaning of **fresh-only at combo tiers** — i.e. option A — as
  **not ruled**, to "settle near implementation". So A was the design's own
  leaning and I recommended it without knowing that, then dropped it without
  knowing that either. Recorded in the isrepeat note: the decorator ruling
  settles an open item rather than overturning a ratified one, the owner's
  objections stand independently of the leaning, and its attached constraint
  ("existing combos keep current behaviour unless explicitly altered") is
  satisfied by an opt-in decorator.

### owner approves the plan; three features implemented (2026-08-03)

Owner ruled exact matching plus an optional trailing asterisk, with a
devx rationale worth recording verbatim in intent: **90% of bindings want
exact matching and rely on modifiers, which is what modifiers are for**; the
remaining 10% have hooks, which reach the held set, so *no capability is
stripped* — shortcuts are simply focused on being easy, straightforward and
predictable, and the developer is protected from designing against corner
cases. Also ruled: **no logging** of unconsumed events.

- Verified their aside first: hooks receive `Controller.held_keys()` as
  argument 2 on **all three** keyboard/text channels (keypressed, keyreleased,
  textinput) — yes. Pointer events bypass the chain entirely (`hook_pointer`
  installs real `love.*` handlers), and Decision 20 covers that gap.
- **`edb6321b` — Decision 21, combo classes + one trigger per combo.** Tests
  first (3 red for the contract, 3 for the matcher). `find_shortcut` tries the
  exact combo, then `combo_string('*', keys)` — the class key needs no
  parsing, being the same serialisation with `*` as the trigger. `Key.is_mod`
  added so a class cannot match its own modifier (`alt+lalt`). Registration
  raises on two triggers or none, which kills the silent truncation
  (`a+b+*` → bare `*`). 879 → 889.
- **`d93065f1` — Decision 22, `compy.input.suppress_repeat`.** Opt-in
  once-per-press wrapper that consumes either way. The consuming half is
  pinned by a row that holds backspace against a live widget — an unconsumed
  repeat would fall past the shortcut into the hook and the widget. 889 → 894.
- **`ced8f40` in keyboard** — `appChord` deleted for `sc["alt+*"]` +
  `sc["alt+p"]`, private `chord()` deleted for the public wrapper. The
  hand-written "and not Ctrl" test goes too: `ctrl+alt+h` is a different
  modifier set, so it is not in the Alt class and still reaches the scene.
- **Decision 23 — the log and the noop default are both declined**, recorded
  as a decision rather than left as an unexplained gap, since `design.md:39`
  ratifies "DEFAULT: noop (+debug log)" and a reviewer will find it. The nil
  guards in `dispatch` now carry a comment saying they are deliberate.

### owner catches two defects in what I just shipped (2026-08-03)

Both in `suppress_repeat`, one in its test and one in the thing itself.

- **The test was hollow.** The row claiming to pin "consumes the repeat it
  swallows" deleted both characters with an *unbound* backspace first, then
  asserted the text was still empty — an assertion an empty buffer satisfies
  no matter what the wrapper returns. Proved by **mutation, not by reading**:
  with the wrapper changed to `if isr then return end`, the whole suite still
  passed 894/0/0/3. Rewritten to start from `'abcd'`, establish the control
  that an unbound repeat *does* edit, then assert across a bound press and
  repeat. Fails against the mutation, passes against the real code
  (`cdfea35b`).
- **The implementation was wrong** (`34399a33`). Owner: *"suppress_repeat has
  just one job — return true on repeat or return fn(...) result otherwise. it
  has no business in upper-level dispatching."* It returned `true`
  unconditionally, discarding the handler's result, so it was a repeat filter
  AND a consume-always policy. A handler that wanted to act once per press and
  still fall through could not say so. My own prose gave it away — I kept
  calling it "two halves", which is exactly the smell.
- Fixed to `if isr then return true end; return fn(...)`. The swallowed
  repeat is still consumed, and that is *not* a second policy: suppressing the
  action without suppressing propagation would move the problem, letting a
  held key fall past the shortcut into the widget.
- Fallout in keyboard (`e00430b`): its bindings were consumed only as a side
  effect of being wrapped. Left alone, Shift+Escape would have reached the
  game as an Escape and `alt+*` would have stopped swallowing the class, which
  is its whole purpose. Local `chord()` is back with a *different* job —
  adding the `return true` that is the handler's call — and the repeat
  filtering stays with the platform wrapper.
- **Pattern worth carrying:** three times this phase a green test has been
  blind to what it named (the fixture compensating for the `shown` regression,
  the draw-path defect the fixture stubbed, this row). Mutation is cheap and
  settles it in one run; I should reach for it whenever a row asserts an
  *absence*.

### owner completes the helper set (2026-08-03)

Three asks, all taken: a `bypass_repeat` sibling, `chord()` renamed, and
`always_true` extended to wrap an optional fn.

- **`bypass_repeat`** (`4d9f698d`) completes the pair. Both skip the handler
  on a repeat; suppressed is consumed, bypassed carries on down the chain. It
  is the shape the previous commit could only describe in prose — act once on
  a held key while what is below keeps receiving it. Two names rather than one
  wrapper with a flag: which one a binding wants is fixed at registration, not
  per event.
- **`always_true([fn])`** — the argument is the good one and worth keeping:
  ending every handler with `return true` is the **dark side of the DOM
  idiom**, forcing a function that merely toggles a pause to know its
  propagation context, and to carry that knowledge wherever it is reused. The
  declaration belongs in the dispatch map. Decision 24 records that this is
  **not** a reversal of Decision 22 — that refused a wrapper deciding
  consumption behind the developer's back; this is the developer deciding
  explicitly at the site where the binding is declared. Who chooses, not where
  the `true` comes from.
- **keyboard `28d84cd`:** `chord()` → `reserved()`, body now
  `suppress_repeat(always_true(fn))`. `alt+*` becomes `reserved()` with no
  function at all, swallowing the class being its whole job, and goBack /
  notchAdjust / pauseToggle go back to being about their own subject.
- One new row caught a mistake **in itself** rather than in the code: it
  asserted a class binding consumed everything, but a modifier's own press is
  deliberately not in its class (Decision 21), so `lalt` reaches the hook and
  only the chord does not. Rewritten to assert that, which is the sharper
  claim.
- Suite **896 → 903 / 0 / 0 / 3**.

### owner settles the combinator set: compy.input.fn (2026-08-03)

- Ruled: `fn.stop_here` (always_true), `fn.side_run` (always_false),
  `fn.ignore_repeat`; `suppress_repeat` dropped, since
  `stop_here + ignore_repeat` covers it. Named **in dispatch terms** — what
  happens to the EVENT — because that is what a reader of a registration
  table needs. `a9545fae`.
- `side_run` is the owner's, and I had missed it. It completes the pair and
  covers the "act on the side, claim nothing" shape, letting the event through
  **even when the wrapped function returns truthy** — the declaration outranks
  the handler, which is the point of declaring it at the site.
- `suppress_repeat` was deleted rather than renamed. The measurement is why:
  with a non-consuming handler the FRESH press fell through to the hook while
  every repeat was consumed, so press 1 behaved differently from presses 2+.
  Nothing should offer that.
- Decisions 22 and 24 rewritten along the orthogonality seam — 22 is
  invocation (does the handler run), 24 is propagation (where the event
  goes). keyboard `032265d`, its local aliases gone.

### PROCESS ERROR, mine, and its cleanup (2026-08-03)

- I staged `git add -A src` instead of explicit paths. That committed
  `src/STEPS.md` — the owner's untracked scratch — and turned the three
  nested example repos into gitlinks. Both are exactly what the standing
  rules forbid ("stage explicit paths, never a directory"; "never sweep the
  owner's unrelated working-tree changes in").
- First correction was a `git rm --cached` follow-up, leaving the bad commit
  in the log because history is not mine to rewrite unasked. **Owner ruled to
  squash it** — *"its literally your history in terms that you created it"* —
  with an explicit precaution: back the detached repos up first.
- Executed: the three nested repos copied to the session scratchpad and their
  HEADs recorded before touching anything (`cc0dbd7` balloons, `eb90389`
  keyboard, `d2ce7a0` maze), then `git reset --soft` over the three commits
  and a re-commit from an index that already held the corrected tree. Proved
  by tree hash rather than inspection: the rebuilt history's tree is
  byte-identical to the pre-squash one, so the squash lost nothing.
- Lesson for the rest of this phase: the guardrail exists because this tree
  permanently carries owner scratch and three nested repos, so `add -A` is
  never safe here, not even scoped to a subdirectory. Explicit paths, always.
- Behavioural note: the owner's instinct on being told about a mistake was to
  ask what could still be damaged by the *fix* (the detached repos), not to
  dwell on the mistake.

### re-explaining the combo wildcard finding

- Probed rather than asserted. The metatable of a combo table is **reachable**
  (`Key.new_handler_table` sets no `__metatable`), and an added `__index` gives
  a working `alt+*` wildcard — dispatch's plain lookup consults it on a miss.
  So "cannot express" was too strong: there is no *sanctioned* way, and the
  mechanism exists.
- The probe also turned up a corner any wildcard design must answer: holding
  Alt alone dispatches the combo **`alt+lalt`** — `combo_string` prepends the
  held modifier to a trigger that is that same modifier key. A naive `^alt%+`
  pattern matches it. Ledger entry now carries all three points.

- `pr-assembly-guide.md` §5 reframed: the owner's standard stated at the top
  (our migrations are our work product, no homework for repo authors), the
  "left for that repo to rule on" framing removed, both new commits listed,
  and each repo's note rewritten to what was actually verified.
