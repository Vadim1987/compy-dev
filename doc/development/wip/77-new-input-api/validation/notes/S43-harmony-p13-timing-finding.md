# S43 — P13 regression: the retired release discipline breaks harmony

Raised by the owner as a challenge to their own P13 ruling: *was retiring the
`release_keys()` discipline an overreach — would a scenario author expect to act
while the chord is still held?* Investigated in analysis mode; **no code changed.**

## Verdict — the concern is correct, and the defect is worse than the framing

Not only is the "hold" interval gone: under the real harmony loop the simulated
modifier is **never observable to the app at all**. Every chord in every scenario
now reaches the app as a **bare key**.

## Why — push and pump are one frame apart

`love_key` is fully synchronous and never yields (`src/harmony/init.lua:302-310`,
`love_chord` `:246-261`, `release_modifiers` `:234-238`):

1. `press_modifier` sets `held.lctrl = true` and **pushes** `keypressed lctrl`;
2. pushes `keypressed t`, `keyreleased t`;
3. `release_modifier` pushes `keyreleased lctrl` and sets `held.lctrl = false`.

`love.event.push` only **enqueues** (`:156-159`). The queue is drained at the top
of the next `main_loop` iteration (`:48-78`), while scenario steps advance in
`love.update` → `Controller` → `love.harmony.timer_update`
(`src/controller/controller.lua:604-605`), i.e. **after** that frame's poll. So by
the time `handlers.keypressed('t')` runs, `held.lctrl` is already `false`.

`patch_isDown` (`:272-284`) answers locked runs **only** from `held`, and the
gateway's gate is a device read — `Key.ctrl()` → `love.keyboard.isDown`
(`src/util/key.lua:166-168`), used at `controller.lua:769` (quickswitch) and
throughout `editorController.lua` (`:294,464-476,522,556,566,574,677`).

Pre-P13 the modifier stayed `true` across frames until an explicit
`release_keys()`, which is exactly why the poll answered correctly. The discipline
was not ceremony — it was the mechanism.

## Why the P13 test did not catch it

`tests/harmony_input_spec.lua:31-34` replaces `love.event.push` with a
**synchronous dispatcher** (`love.handlers[name](key)` at push time). That models
an event bus harmony does not have; it is the one arrangement in which the
released modifier still reads as held.

## Reproduction (A/B, identical fixture, realistic queue)

Probes: `S43-harmony-probes/harmony_pump_spec.lua` (HEAD) and
`harmony_pump_pre_spec.lua` (pre-P13). Both queue on push and drain after the
scenario step. The pre-P13 probe needs the old module on `package.path`:

```
mkdir -p /tmp/pre/harmony
git show 5b580661^:src/harmony/init.lua > /tmp/pre/harmony/init.lua
busted doc/development/wip/77-new-input-api/validation/notes/S43-harmony-probes/harmony_pump_spec.lua
```

| Tree | `Key.ctrl()` at pump time | Ctrl+T quickswitch |
|---|---|---|
| pre-P13 (`5b580661^`) | `true` | **fires** |
| HEAD (`b54c0778`) | `nil` | **does not fire** |

## Scope of the breakage

Every chord in the scenarios — `C-S-s`, `C-S-q`, `C-f`, `C-l`, `C-home`, `C-w`,
`C-y`, `C-m`, `C-pagedown`, `S-pageup`, `S-return`, `C-pause`, `C-t` — is
delivered as its bare key. `C-S-q` types `q` into the buffer instead of quitting;
`C-home` is `home`. Harmony is outside `busted` and outside CI, so **nothing
signals this** — precisely the loss the plan's §10 exists to prevent.

## Against the ruling as written

The owner's 2026-08-09 ruling was **conditional**: confirm harmony drives a real
combo end-to-end under the device-read matcher, *and retire the manual
`release_keys()` discipline **if that confirms***. The confirmation was obtained
only through the synchronous-push fixture, so the condition was never met. The
retirement is therefore unratified, not merely risky.

Two further points for the owner:

- **Capability, not just timing.** Post-P13 no exported primitive can hold a
  modifier across frames (`press_modifier`/`release_modifier` are local). The
  author's two-phase press/hold/release API is gone, and with it the ability to
  script "hold Ctrl while N things happen" — which is also what P13's own
  deliverable 3, the batch-skew reproduction rig, would need.
- **What P13 legitimately added** — modifier `keypressed`/`keyreleased` in the
  event stream — is independent of the retirement and should survive whatever
  correction is chosen.
