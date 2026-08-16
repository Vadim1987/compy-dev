# P-13-04 — cold review of commit `3befd556`

Reviewer: cold agent (Sonnet), read-only. Commission:
`../prompts/S43-P-13-04-cold-review.md`.

## Verdict

**Sound. The revert is complete, byte-identical to the pre-P13 baseline, and
the rewritten spec pins the restored contract with three cases that are each
independently load-bearing — a defect that returned would break every one of
them.** No leftovers of P13 in the tree. Suite arithmetic reconciles. Hygiene
is clean; the only over-length lines are inherited, not new. No findings at
any severity. The one thing the commission did not anticipate (`patch_isDown`'s
missing return) is confirmed pre-existing and, on inspection of its production
call sites, has no live behavioural consequence today — see Check 6.

## What I checked, and how

### Check 1 — is the restored contract actually the pre-P13 one?

```
git diff 5b580661^ -- src/harmony/          → empty
git log --oneline 5b580661^..3befd556^ -- src/harmony/
  → b31e99a9 refactor(harmony): split chord emission helpers
  → 5b580661 fix(harmony): release simulated modifiers per chord
```

Exactly the two P13 commits touched `src/harmony/` between the baseline and
the revert; nothing else landed there for an unrelated reason that the revert
would have thrown away. The baseline is the right one. **Confirmed clean.**

### Check 2 — does the new fixture model the real loop?

`tests/harmony_input_spec.lua:33-47` (`queue_recorder`) makes
`love.event.push` append to a local `queue` and only calls
`love.handlers[e[1]](e[2])` from a separate `drain()`. That mirrors the real
split: `love.event.push` only enqueues into LÖVE's queue
(`src/harmony/init.lua:156-159`, `love_event`), and `main_loop`
(`src/harmony/init.lua:47-78`) drains and dispatches at the top of the
**next** iteration, i.e. after the frame in which the scenario step (driven
from `love.update` → `Controller` → `love.harmony.timer_update`,
`src/controller/controller.lua:604-605`) ran and pushed the events. The
fixture's `gateway()` (`:63-72`) installs the real production dispatch by
calling `Controller.setup_callback_handlers(cc)`, which sets
`love.handlers.keypressed` directly (`src/controller/controller.lua:759-773`,
the `quickswitch` closure reading `Key.ctrl()`). So `drain()` invoking
`love.handlers.keypressed(key)` runs the actual gateway function, not a
stand-in. **Confirmed the fixture matches the real timing split** — the
load-bearing property the old (P13-era) fixture lacked, since that one
replaced `love.event.push` with a synchronous `love.handlers[name](key)` call
at push time (verified against the pre-revert spec, `git show 3befd556^:
tests/harmony_input_spec.lua:31-34`).

### Check 3 — do the three cases pin the contract, or only restate the code?

For each case, what change would break it:

1. **"queues on push, drains before the app sees it"**
   (`tests/harmony_input_spec.lua:75-84`). If the P13-style change returned
   (modifier `held` cleared synchronously inside `love_key`, in the same call
   that pushes events), then after `drain()` the gateway's `Key.ctrl()` read
   would see `held.lctrl == false` at handler time and `quickswitch` would not
   fire — `calls` would stay `{}` instead of `{edit=true, stop=true}`. **Fails
   if the defect returns.**
2. **"puts only the trigger key on the event stream"** (`:86-97`). If P13's
   modifier-event emission returned, `events` would include
   `'keypressed:lctrl'`/`'keyreleased:lctrl'` alongside the trigger, breaking
   the `assert.same` against the two-element list. **Fails if the defect
   returns.**
3. **"keeps the modifier held until release_keys"** (`:99-110`). If `held` is
   cleared synchronously (P13's behaviour) instead of surviving until an
   explicit `release_keys()`, `Key.ctrl()` right after `drain()` (before the
   scenario's own release call) would already read false, breaking
   `assert.is_true(Key.ctrl())`. **Fails if the defect returns.**

All three are load-bearing under the sharp test — none would survive the
regression coming back. **Confirmed.**

### Check 4 — is anything of P13 left?

```
grep -rn "press_modifier|release_modifier|love_chord" src/ tests/  → no hits
  (only in doc/…/notes/S43-harmony-p13-timing-finding.md, the finding itself)
```

`src/harmony/init.lua` has no `love_chord` or plural `release_modifiers` —
only the singular `release_keys` from the pre-P13 tree
(`src/harmony/init.lua:224-230, 296`). LSP `references` for `release_keys`
confirms every call site is exactly the pre-P13 pattern: `console.lua:29,46`,
`editor.lua` (20 sites), `inspect.lua:14`, plus `hm_done`
(`src/harmony/init.lua:331`) which auto-releases at scenario end.

`scenarios/examples.lua` has three chords (`C-S-q` at `:13,42,65`) with **no**
explicit `release_keys()` — at first glance this looks like a leftover, but
`git diff 5b580661^ -- src/harmony/scenarios/examples.lua` is **empty** (this
file was untouched by either P13 commit) and every one of those chords is
immediately followed by `hm_done()`, which itself calls
`love.harmony.utils.release_keys()` (`src/harmony/init.lua:329-331`). Pattern
is pre-existing and correct, not a gap the revert left behind.

Plan-doc staleness: `../reviews/S27-triage-and-plan.md:612` still reads
`~~P13~~ DONE [S42] (5b580661)` with the retired description (inject modifier
events, retire `release_keys()`). This is not silently stale — row
`P-13-00` (`:613`) explicitly says "Retraction of the S42 result … in §10's
`[S43]` subsections", and `§10` (`:870`, `"[S43] That result is WRONG — P13 is
reverted by P13a"`) carries the correction. Consistent with this document's
own append-only/tombstone convention (§0, W9). **No actionable staleness.**

### Check 5 — arithmetic and hygiene

```
busted tests → 949 successes / 0 failures / 0 errors / 10 pending
```

Matches the claimed 947 → 949: `git show 3befd556^:tests/harmony_input_spec.lua`
has exactly one `it` block; the rewrite has three. **+2 net, reconciles
exactly with "spec grew from 1 case to 3."** The 10 pending are untouched
(`tests/input/input_global_shortcuts_spec.lua`,
`tests/input/input_routing_spec.lua`), unrelated to this change.

Hard limits on `tests/harmony_input_spec.lua`: longest line is well under 64
chars (`awk` sweep found zero violations); every function body is ≤13 lines
(`queue_recorder` 13, `setup_harmony` 11, `gateway` 8, each `it` block ≤10);
all params ≤2; nesting stays at "function → for/if → statement", ≤3 deep.
**Compliant**, and the 23-line `setup_harmony` violation from before is
resolved by the `mock_state`/`queue_recorder`/`setup_harmony` split as
claimed.

`src/harmony/init.lua` over-length lines: `awk` found exactly two, `:39` (78
chars) and `:361` (69 chars). `git show 5b580661^:src/harmony/init.lua | awk
...` finds the same two lines at the same length. **Confirmed inherited, not
new.**

Comment added at `tests/harmony_input_spec.lua:30-32` ("Real LOVE semantics:
push only enqueues…") carries payload 1 (intent/constraint not obvious from
the code) per `agents/rules/commenting.md` — compliant, no narration, no
citation needed.

LSP `diagnostics`: `tests/harmony_input_spec.lua` shows two
`duplicate-set-field` WARNINGs (`love.event.push` reassignment at `:35`,
`package.preload['view.view']` at `:9`) — both are the mock-monkeypatch
pattern and both existed identically in the pre-revert spec
(`git show 3befd556^:tests/harmony_input_spec.lua`, same two constructs), so
not new debt. `src/harmony/init.lua` shows one pre-existing HINT
(`unused-local _cls`, `:123`), inherited from `5b580661^` verbatim, matching
the outcome report's own claim.

### Check 6 — the `patch_isDown` zero-return path

`src/harmony/init.lua:242-253` (`patch_isDown`'s `isDown` closure): when
`lock` is true and no key in `held` matches, the function falls off the end
with **no return statement at all** — zero values, not `nil`. Confirmed
present, byte-identical, at `5b580661^` (part of the empty diff in Check 1) —
**pre-existing, not introduced by this commit.**

Consequence beyond test ergonomics: in Lua, a zero-value return only surfaces
as a problem where the call sits in a *multiret-expansion* position — the
last argument of a call, the last element of a table constructor, or a bare
`return`. Every `if Key.ctrl() then` / `Key.ctrl() and …` site (the large
majority of ~90 call sites across `controller.lua`, `editorController.lua`,
`userInputController.lua`, `consoleController.lua`, `searchController.lua`,
the examples) sits in a single-value boolean-test position, which Lua
truncates to one value regardless of arity — those are unaffected.

I found six production call sites where `Key.ctrl()` **is** the last argument
of a call — `editorController.lua:466,470,772,776` and
`searchController.lua:101,105`, all of the shape `self:_scroll('up',
Key.ctrl())`, where `_scroll(dir, warp, by)`
(`editorController.lua:412-415`, `searchController.lua:73-`) forwards `warp`
straight through to `buf:scroll(dir, by, warp)` with no arity-sensitive
logic. A zero-value `Key.ctrl()` here drops `warp` (and `by`) from the call
entirely rather than passing `false`; since the callee only ever tests
`warp` for truthiness, an omitted argument and an explicit `false` are
indistinguishable. **Traced through: no observable behavioural difference
today.** This matches the P-13-01/02 worker's own characterisation — real,
worth flagging as a trap for a future assertion or a future arity-sensitive
callee, but not a live defect. Confined to harmony's locked-run mode; normal
gameplay always has a real `love.keyboard.isDown` returning exactly one
boolean.

## Verified clean (not repeated in Findings, since there are none)

- Baseline diff, fixture timing, all three test cases' bite, P13-leftover
  sweep, suite arithmetic, hard-limit compliance, comment compliance, LSP
  diagnostics on both changed files, and the `patch_isDown` pre-existence and
  blast radius.

## What I could not check

- Could not run harmony itself end-to-end under `xvfb-run love src` (outside
  this review's read-only/no-display scope) to watch a real frame-by-frame
  Ctrl+T fire; relied on the `busted` fixture plus static tracing of
  `main_loop`/`Controller.setup_callback_handlers`, which is the same
  evidence the P-13-01/02 worker's report cites.
- Did not exhaustively re-verify every one of the ~90 `Key.ctrl()`/`Key.alt()`
  /`Key.shift()` call sites outside `src/harmony`; the six last-argument sites
  found by the grep sweep were checked, and no other call shape (variadic
  wrapper, `select('#', ...)` consumer) turned up in that sweep.
