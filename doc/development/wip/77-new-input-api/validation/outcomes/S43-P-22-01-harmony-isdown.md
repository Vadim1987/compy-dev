# P-22-01 — harmony's `isDown` patch returns a boolean (outcome)

Commits: `4e93ff78` (harmony patch + test) and `802ff1a4` (controller
comment). Branch `feature/77-newapi-analysis-s20260615`. Not pushed.

## The patch

`src/harmony/init.lua`, `patch_isDown`, one line added:

```lua
        if not lock then
          return down(...)
        end
        return false
      end
```

Before: the locked/not-held path fell off the function end and
returned no value at all. Now it returns `false` explicitly, matching
`love.keyboard.isDown`'s `boolean` signature on every path (`held`
fast path → `true`, unlocked → the real `down(...)`, locked-and-not-
held → `false`). No second no-value path exists in the function — the
`held` branch always `return`s `true` inside its loop, and the
unlocked branch always `return`s `down(...)`'s result.

`src/harmony` is otherwise untouched: `git diff` for the file is a
single `+return false` line, nothing restructured, no size rules
applied inside it (standing owner exception for this subsystem).

## The test

`tests/harmony_input_spec.lua`, one new case appended after the
three existing ones (all three left byte-identical):

```lua
  it('answers false, not nothing, for an unheld modifier', function()
    local harmony = setup_harmony()

    local isDown = love.keyboard.isDown('lctrl')
    assert.is_boolean(isDown)
    assert.is_false(isDown)
  end)
```

`setup_harmony()` runs `harmony(true)` (locked) and `harmony.load()`,
which installs the patch. `lctrl` is never pushed into `held`, so this
exercises exactly the locked/not-held path. `assert.is_boolean` fails
on `nil` (a no-value return coerces to `nil` when captured into a
local), so the case regresses loudly — not silently falsy — if the
`return false` is ever reverted. `assert.is_false` additionally pins
the value, not just the type.

## The stale comment

`src/controller/controller.lua`, `only_mods`'s comment cited
"Harmony's lock mode returns no value" as the reason for the `not not`
normalisation — no longer true after the patch above. Restated to cite
the debt entry by section name instead of the (now-fixed) harmony
instance:

```lua
-- `not not` normalises: `Key`'s own `@return boolean` is not
-- enforced for every isDown patcher (technical_debt/input.md,
-- "A modifier accessor answers truthy/falsy, not a boolean").
```

The normalisation itself is unchanged — `Key.ctrl()/alt()/shift()`
still pass `love.keyboard.isDown(...)` straight through with no
normalisation of their own (`src/util/key.lua:138,168,178`), so
`not not` in `only_mods` is still doing real work for any other
patcher that might someday return non-boolean truthy/falsy. Two
commits, not one: the harmony fix and its test are one functional
change to another author's subsystem; the controller comment is an
unrelated docs-only edit in a different file, so keeping it separate
keeps each commit's diff legible on its own terms.

## Suite arithmetic

Before: 966/0/0/10. After: **967/0/0/10** — the one new case, pending
count unchanged, no failures, no errors.

## The six call sites — do they now get a real boolean?

Checked `editorController.lua:466,470,772,776` and
`searchController.lua:101,105`; all six are `self:_scroll(dir,
Key.ctrl())` (or the down/up variant), i.e. `Key.ctrl()` spliced as
the trailing argument of a call. `Key.ctrl()` (`src/util/key.lua:166-
168`) is `return love.keyboard.isDown(unpack(ctrl_k))` — a straight,
unnormalised passthrough, unlike `only_mods`.

**Yes — under a locked harmony run, all six now receive a real
`false`, not "no argument at all".** Before this patch, an unheld
Ctrl at any of those six sites meant `love.keyboard.isDown(...)`
returned no value, so `Key.ctrl()` returned no value, so e.g.
`self:_scroll('up', Key.ctrl())` called `_scroll` with **one**
argument instead of two, leaving `_scroll`'s second parameter `nil`
by Lua's own default-arg behaviour rather than by an explicit
`false`. The patch fixes this at the root (`love.keyboard.isDown`
itself), so every unnormalised caller — not just `only_mods` — is
fixed, not only the six named ones. None of the six had a live
behavioural bug today (the debt entry notes the callee only tested
the value for truthiness, and `nil`/`false` are both falsy to that
test), so this is a signature-correctness fix with no observed
behaviour change at any of the six sites.

## Debt entry

Not edited — `doc/development/technical_debt/input.md`, "A modifier
accessor answers truthy/falsy, not a boolean" is the parent session's
to update, per this task's scope.
