# P-13-01 + P-13-02 — execution (prompt of record)

Commissioned by session43, 2026-08-16. Worker: Sonnet, model passed explicitly.
**This step writes code.** Deliverable report:
`doc/development/wip/77-new-input-api/validation/outcomes/S43-P-13-01-02-execution.md`.

## Background — read this first, it is the whole reason for the task

`doc/development/wip/77-new-input-api/validation/notes/S43-harmony-p13-timing-finding.md`.

In short: `src/harmony` is a scripted UI-automation harness with its own
`love.run`. Session42 (commit `5b580661`, refined by `b31e99a9`) made
`love_key` emit modifier press/release events and clear its `held` table inside
the same call, retiring the manual `release_keys()` discipline. That broke the
harness. `love.event.push` only **enqueues**; the queue is drained at the top of
the next `main_loop` iteration, while scenario steps advance later in
`love.update`. So `held` is already false when the app handles the key, the
patched `love.keyboard.isDown` answers false, and **every scripted chord now
reaches the app as a bare key**.

The test that "proved" P13 works passes only because its fixture replaces
`love.event.push` with a synchronous dispatcher — an event bus harmony does not
have.

## P-13-01 — revert

Restore `src/harmony/` to its state at `5b580661^`:

```
git checkout 5b580661^ -- src/harmony/
```

That is the whole change: `init.lua` (undoing both `5b580661` and the
`b31e99a9` helper split) and the `release_keys()` calls in
`scenarios/{console,editor,inspect}.lua`. Confirm with `git diff 5b580661^ --
src/harmony/` that it is empty afterwards. **Do not re-implement anything** and
do not add modifier-event emission — that is a separate, conditional step the
owner has not approved.

## P-13-02 — rewrite `tests/harmony_input_spec.lua`

The owner ruled the spec is **kept and rewritten**, framed as a late instance of
*canonicalizing de-facto behaviour*: harmony's press/hold/release contract is
real but was never written down, and that gap is what let the synchronous-push
fixture pass as proof. Pin the contract the revert restores:

1. **The fixture queues; it does not dispatch on push.** `love.event.push`
   appends to a queue; a separate drain step calls `love.handlers[name](...)`.
   This is the load-bearing part of the whole spec — if a future fixture
   dispatches on push again, it will bless the same regression.
2. **The modifier is still held when the app handles the key.** Drive
   `love_key('C-t')`, then drain, and assert the real gateway
   (`Controller.setup_callback_handlers`) ran the Ctrl+T quickswitch — i.e. the
   device-read matcher saw Ctrl down at handler time.
3. **Only the real key produces events.** Pre-P13 `love_key` pushes
   `keypressed`/`keyreleased` for the trigger only; modifiers are set in `held`
   and never enter the event stream. Assert the recorded event list is exactly
   that.
4. **The release is the scenario's job.** After the chord, `Key.ctrl()` is still
   true; after `harmony.utils.release_keys()` it is false. That is the
   discipline P13 removed, and pinning it is the point of the rewrite.

The starting shape is the probe pair in
`../notes/S43-harmony-probes/harmony_pump_spec.lua` (queue + drain, HEAD
behaviour) and `harmony_pump_pre_spec.lua` (the same against pre-P13). Adapt;
do not copy the scratch prints or the deliberately-inverted assertions.

**Fix the size violation while you are there:** the current `setup_harmony`
helper is 23 lines against a 14-line hard limit (`agents/rules.md`). Split it
into meaningful helpers — the mocked LÖVE state and the event recorder are the
natural seams. All other hard limits apply too: line ≤ 64 chars, params ≤ 4,
nesting ≤ 4.

## Order of work — tests first, and the evidence matters

1. Write the new spec **against the current (broken) tree** and run it. It must
   **fail**, and the failure is the proof the defect is real. Record the exact
   failure output in your report.
2. Then apply the revert and run it again. It must pass.
3. Then run the full suite: `busted tests` from `/repo`.

## Landing it

**One commit**, containing the revert and the rewritten spec together. They
cannot be split: the old spec asserts the P13 behaviour, so a revert-only commit
leaves the suite red, and green-at-every-commit outranks one-concern-per-commit
here. Say so in the message, and carry the evidence: what was broken, how it is
reachable, and that the new spec failed before the revert and passes after.

Conventional-commits style per `agents/rules.md`. State the suite count and
reconcile any change to it (947 today; the spec's case count may change — say
why). **Commit locally. NEVER push.** Do not touch the owner's untracked scratch
(`claude.sh`, `worklog.md`, `src/STEPS.md`, `doc/tall_blocks.md`, `repos.txt`,
`input-pr-slices.tar.gz`) and do not stage anything outside `src/harmony/` and
`tests/harmony_input_spec.lua` — commit those paths explicitly, never `git add .`
or `git add doc/`. Append this trailer:

```
Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
```

## How to work

- **The `lua-lsp` MCP server is available** — defs / refs / diagnostics over a
  real AST of `/repo`. Use grep to find candidates, then the LSP to resolve a
  symbol or prove who calls it. After editing a `.lua` file, `sleep 1` before
  querying refs/diagnostics so the server re-indexes.
- Verify claims in code, not in prose. If anything here contradicts what the
  code says, **stop and report it** rather than working around it.

## Deliverable

Write the report to the path at the top: what you changed, the failing output
before the revert and the passing output after, the suite count, the commit
hash, and anything you found that the prompt did not anticipate. Do not commit
the report — the parent session commits it.
