# P-22-01 — harmony's `isDown` patch returns a boolean (prompt of record)

Commissioned by session43, 2026-08-16, on the owner's ruling. Worker: Sonnet,
model passed explicitly. **This step writes code in another author's subsystem —
keep it surgical.** Deliverable:
`doc/development/wip/77-new-input-api/validation/outcomes/S43-P-22-01-harmony-isdown.md`.

## The ruling and its rationale

A mock must match the signature of the thing it mocks. `love.keyboard.isDown`
returns a **boolean**; harmony's patched replacement does not, on one path.

`src/harmony/init.lua`, `patch_isDown`: the returned `isDown` answers `true` when
the key is in harmony's own `held` table, falls through to the real `down(...)`
when **not** locked — and when locked and not held, **falls off the end and
returns no value at all**. Lua then adjusts that to `nil` at a call site, or to
*no argument* when it is the last argument of a call.

Fix that one path so the function always answers a boolean. Nothing else.

## Why this matters, so you can judge the edit

The debt entry `doc/development/technical_debt/input.md`, "A modifier accessor
answers truthy/falsy, not a boolean", records the consequences: `Key.ctrl() ==
false` is false under a locked harmony run, and `f(x, Key.ctrl())` passes **one**
argument rather than two. Neither has a live effect today, but one of them broke
`only_mods` while it was being written (Decision 33 sweep).

## Scope — surgical, and why

`src/harmony` is **aldum's subsystem**, and this feature's standing rule is not
to reshape it (no size refactors, no restructuring). After the P-13 revert it is
byte-identical to the PR base apart from one comment. This patch is a deliberate,
owner-ruled exception justified by *mock/real signature parity* — so it must be
the smallest edit that achieves that, and nothing else in the file changes.

## What to do

1. **The patch.** Make the locked, not-held path return `false` explicitly. Keep
   the `held` fast path and the unlocked `down(...)` passthrough as they are. If
   you find a second path that can return no value, fix it the same way and say
   so.
2. **A test.** `tests/harmony_input_spec.lua` exists and uses a queue-and-drain
   fixture; add a case there asserting the patched `isDown` answers `false` — not
   `nil`, not "nothing" — for an unheld modifier under a locked run. Assert the
   *type* or compare with `==`, so the case fails if the value goes back to
   nothing. **Do not touch the three existing cases.**
3. **The stale comment.** `src/controller/controller.lua`'s `only_mods` explains
   its `not not` normalisation by citing *"Harmony's lock mode returns no value"*.
   Once you land this, that reason is **no longer true**, and a comment stating a
   false reason is worse than none. **Keep the normalisation** — `Key`'s own
   `@return boolean` is still unenforced for any other patcher — but restate why,
   citing the debt entry above by its section name rather than harmony.
4. Do **not** edit the debt entry itself; the parent session does documentation.

## Constraints

- `agents/rules.md` hard limits (body ≤ 14 lines, line ≤ 64 chars, params ≤ 4,
  nesting ≤ 4). **Do not split or restructure any harmony function** — the size
  rules are not applied inside this subsystem by standing owner preference.
- Suite is **966 / 0 / 0 / 10** before your change; state the arithmetic after.
  Pending count must stay 10.
- Commit the code as **one commit**, staging only the paths you actually change
  (`src/harmony/init.lua`, `tests/harmony_input_spec.lua`, and
  `src/controller/controller.lua` for the comment — keep that as a separate
  commit if it reads better; your call, say which you did and why). Never
  `git add .`, never `git add doc/`. **NEVER push.** Leave the owner's untracked
  scratch alone (`claude.sh`, `worklog.md`, `src/STEPS.md`, `doc/tall_blocks.md`,
  `repos.txt`, `input-pr-slices.tar.gz`).
- Trailer: `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`
- **The `lua-lsp` MCP server is available**; `sleep 1` after a `.lua` edit before
  querying it.

## Deliverable

What changed and where, the new case and what it would catch, the suite
arithmetic, the commit hash(es), and — importantly — whether the six call sites
named in the debt entry (`editorController.lua:466,470,772,776`,
`searchController.lua:101,105`) now receive a real boolean under a locked harmony
run. Do not commit the report; the parent session commits it.
