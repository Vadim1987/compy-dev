---
description: E20 assessment — do the stakeholder-3 input pain statements + the maze/keyboard examples alter the #77 design direction? Verdict + the items they hand to the architect call (E9).
status: active
audience: design
---
# E20 — Pain-statement & example assessment

**Verdict: the design direction holds — no reversal, no new scope forced.** The four pains and the two
examples *validate* the suggested direction far more than they challenge it: the feature's
`keys_pressed` set + combo dispatch + channel callbacks absorb most of the boilerplate the examples
hand-roll today.

**Framing correction (human, 2026-06-22) — symptoms, not requirements.** The quirks doc is largely a
**catalogue of symptoms of the feature's *absence***, not a spec the feature must satisfy. The
keyboard example is "what game code looks like *without* #77": a developer hand-rolling key-state
management and combo detection — exactly what `keys_pressed` + `handlers[combo]` exist to remove. So
the design posture is to **dissolve** these pains by making the hand-rolling unnecessary, **not** to
reproduce or "fix" the platform behaviours the workarounds fight. Two consequences:
- **Event-order (P1) is NOT an obligation.** Upstream LÖVE's `keypressed`-before-`textinput` is a
  *de-facto* SDL artifact, **not a documented guarantee** — code relying on it is already fragile. The
  framework owes no order guarantee; the design is already order-*independent* (channels fire
  independently; text judged directly in `on_text_entered`), which is strictly better than
  order-*correct*. The only survivor is **test hygiene** (below), not a runtime contract.
- **`isrepeat` (P2)** is kept as the honest primitive (it lets `if isrepeat then return` replace
  edge-tracking) — restoring a standard LÖVE arg the Controller drops, i.e. removing a regression, not
  adding scope.

Net: after stripping the symptoms, the pains leave the architect call (E9) **one genuinely-open design
question** — *how does our design account for key-repeats at the combo tier?* — plus a test-design
constraint (P1), a regression to undo (`isrepeat` threading), and one broader concern to rule
out-of-scope (P4-general). None reshapes M4–M9; all sharpen it.

Source: HEAD of `topics/git` (commit 410e020) — `compy-input-quirks.md` (the 4 pains) + its supporting
`compy-lua-game-patterns.md` → **Text & Key Input** recipe (the codified workaround, not itself a pain).
Examples: `src/examples/keyboard/` (`input.lua`, `alt.lua`) and `src/examples/maze/`.

---

## The four pains vs. the design

| Pain | Design status | What E9 must do |
|---|---|---|
| **P1 — `textinput` arrives BEFORE `keypressed`** (reverse of upstream LÖVE) | **A symptom, not a gap — and not an obligation.** Upstream order is a *de-facto* SDL artifact, not a guarantee, so the framework owes none. The design's channel split (`on_key_pressed` for commands / `on_text_entered` for text, "independent, no suppression") is *already* the recipe's load-bearing rule and is order-*independent* — the correct posture. The pain ("press twice after a chord") only exists for code that gates a glyph on a keypress flag; the new API removes the reason to. **Surviving residual: test hygiene only.** The pain warns *"invisible to synchronous test harnesses … unit tests pass while the device fails"* — so M4-0 must **not bake the canonical order in as an invariant**; it must tolerate either order. | **Test-design constraint, not a feature/runtime contract.** Tell E9: M4-0 (A8) must not assume keypressed→textinput ordering (else false-green); no spec order-guarantee is owed. *Optional:* one spec sentence stating order-independence is intentional, to forestall a future reader re-adding a gate. |
| **P2 — key-repeat on, `isrepeat` stripped** | **Same "ill" as P1 (a symptom of hand-managing state) + one genuine signal.** The `INPUT.held` repeat-tracking is the developer reimplementing fresh-vs-repeat by hand — dissolved once the API exposes repeat cleanly. **Source-confirmed split:** key-repeat being *on* is **deliberate** (`main.lua:297 love.keyboard.setKeyRepeat(true)`); `isrepeat` being dropped is **incidental** — the harvest wrapper is literally `handlers.keypressed = function(k)` (`controller.lua:554`), no comment, no rationale, re-dispatched as `love.keypressed(k)` (`:656`). The arg was never threaded, not deliberately stripped. **The real, still-open signal:** *how does **our** design account for repeats at the combo tier?* `isrepeat` is forwarded only to `on_key_pressed`; the spec is **silent on whether `handlers[combo]` / `framework_handlers` fire on key-repeats or only fresh presses** — a held `ctrl+s` would re-fire its handler every repeat unless suppressed. | **(the one genuinely-open design question)** E9: define **repeat semantics at the combo/handler tier** (fire-on-repeat vs fresh-only; likely fresh-only with `on_key_pressed` seeing repeats) — sits next to **A6**. Plus: thread `isrepeat` (+ `scancode`) in the harvest rewrite — undo the incidental drop; **M4-0 assert** it arrives. |
| **P3 — modifier chords emit no `textinput`** | **Solved by the feature — and not even a "fix" (`compy-input-quirks.md` itself says "Platform fix: none needed — correct behavior").** Combo dispatch (`compy.input.handlers[combo]` in the keypressed channel) is precisely the recipe's "consume chords in keypressed, no trailing glyph to clean up." The keyboard example's `appChord`/`reservedChord` boilerplate collapses into combo registrations. | Validation only — **reinforces A6 priority**: the chord path is the sanctioned answer to a real, recurring pain, so A6 is load-bearing, not cosmetic. No separate E9 item. |
| **P4 — no project-exit cleanup hook** (`Ctrl+Esc` → `love.event.quit()`, `controller.lua:672`; today runs no game code) | **Code-grounded — three tiers, not "owned vs not."** Projects run setfenv'd in a **deep-cloned** env (`consoleController.lua:40,297` + recursive `table.lua:48`): the `love` table is a fresh identity but **leaf functions are shared references**. So: **(T1) callbacks** (`love.draw/keypressed/update`) are set on the clone, harvested by `save_user_handlers` (`:824`) + reset by `set_default_handlers` on stop ⇒ framework-managed, **no leak**. **(T2) `compy.*`** (audio/terminal/input) = framework wrappers ⇒ managed. **(T3) raw `love.*` imperative calls** (`love.keyboard.setTextInput`/`setKeyRepeat`, `love.mouse.setRelativeMode`, raw `love.audio`) hit the **shared C functions ⇒ real global SDL/LÖVE state**, and nothing snapshots/restores it across run boundaries ⇒ **genuine leak.** **This is the actual P4.** The stakeholder is half-right: the *table* is sandboxed; the *side effects* are global. **Earlier "hook can't fire on force-exit" was WRONG** — `Ctrl+Esc` is the framework's own code; a framework-invoked hook *would* fire there; only OS-kill/crash escapes it. **What they're actually doing** (keyboard ex.): `input.lua:41` calls real `setTextInput`; the comment shows they *wanted* to disable key-repeat but **didn't, because they can't restore it** — hand-rolling edge-tracking instead (so P4 feeds back into P2). | **Framework snapshot/restore of T3 state across run boundaries — not a project hook.** Robust to crash/force-exit, sandbox-safe (doesn't trust the project), and it **dissolves the P2 workaround too** (they could disable key-repeat and drop the edge-tracking). This is a **project-run-lifecycle / sandbox concern, outside #77's keyboard-widget scope** → sibling, parked under **A1**. A `before_exit` hook (which *can* run on `Ctrl+Esc` if framework-invoked) is only needed for **project-internal** teardown (save/memoize), not for global-state restoration. Interrogation now narrower: confirm it's T3 global-mode restoration (→ framework job) vs internal save (→ hook). |

---

## The two examples — what they exercise

**`keyboard/` — a live, hand-rolled workaround for all four pains at once** (`input.lua` header is a
near-verbatim restatement of the quirks doc). It demonstrates: edge-tracked repeat filtering
(`INPUT.held`, `inputStale`, the `upRecent`/`INPUT_UP_GRACE` release-boundary glyph leak), direct
textinput judging (no gate), chord swallowing in keypress + glyph dropping in textinput, and the
explicit note that it *cannot* restore key-repeat on exit (P4). It is **new-style** today (native
`love.keypressed`/`textinput`, no legacy globals). → **Best M4-0 characterization showcase**: most of
its bookkeeping (`INPUT.shift/ctrl/alt`, `modHeld`, `inputUpdateMods`) collapses into `keys_pressed` +
combos; what *survives* migration (repeat filtering, release-boundary staleness) is exactly the
P1/P2 surface E9 must pin down.

**What the developer actually wanted (precise, from the scene code) — NOT combo-tracking.** It's a
typing tutor: each scene judges a key/glyph as a discrete **"hit"** (target) or **"knock"** (wrong),
and must fire **once per physical press**. With key-repeat on, a *held* correct key would re-fire the
target every tick and a held wrong key would knock every frame (`alt.lua:156`, `:167–176` →
`if inputStale(altBaseKey(ch)) then return end`). So the desire is plain **auto-repeat debounce for
discrete actions**. They had two clean fixes and the framework denied **both**: (1) *disable* key-repeat
for the game → not done, because it can't be restored on exit (**P4**/T3); (2) *read `isrepeat` and
bail* → blocked, framework strips it (**P2**). Hence the manual edge-tracking, made fiddlier by the
reversed order (**P1**). **Design upshot:** **forwarding `isrepeat` is the targeted, cheap fix** —
`if isrepeat then return` deletes the whole block, with no global-state lifecycle. Disabling key-repeat
(the P4 route) was only the *fallback they reached for because `isrepeat` was gone*. This also confirms
the combo-tier default: games want once-per-press at the action level, so `isrepeat` must be visible at
`on_key_pressed` while `handlers[combo]` fires once.

**`maze/` — a legacy + native hybrid, three migration surfaces in one**: (1) legacy text-input globals
`user_input()` / `input_text()` + the `GS.input:is_empty()` **polling reftable** idiom → the exact M8
removal/`after_submit` migration target; (2) native `love.keypressed` via `ctrl_pressed` indirection →
**D-9 coexistence** path; (3) `love.keyboard.isDown` + manual edge-tracking (`tab_was_down`,
`is_shift_down`) + Shift-held modal recording + Shift+Enter multiline → the `keys_pressed` replacement
case. → **Best D-9 + M8 coexistence/migration anchor** for M4-0 coverage scope.

Neither example reveals a behavior the design *misses* — they reveal behavior the design **must keep
working through the routing change** (D-9 native coexistence) and **must let migrate cleanly** (M8).

---

## Hand-off to E9 (what changes there, nothing here)

1. **THE open design question — combo-tier repeat semantics (next to A6):** with key-repeat deliberately
   on, do `handlers[combo]` / `framework_handlers` fire on every repeat or only on fresh presses? Spec
   forwards `isrepeat` only to `on_key_pressed` and is silent here. **Human leaning (2026-06-22, provisional —
   may reconsider at E9):** the **handler/framework tier fires once per physical press** (fresh-only);
   **`on_key_pressed` continues to fire on every repeat**. Net: a project gets *both* — one-off actions via
   `handlers[combo]`, repeat-aware handling via `on_key_pressed` — with no per-handler `isrepeat` guard.
   This is the single substantive thing the pains add; carry it to E9 as a near-settled default, not an open void.
2. **`isrepeat` threading (regression undo):** the harvest rewrite must thread `isrepeat` (+ `scancode`)
   through `handlers.keypressed` (today `function(k)`, `controller.lua:554`). **M4-0 assert** it arrives.
3. **P1 test hygiene (A8/M4-0):** no spec order-guarantee is owed; just ensure M4-0 does **not** encode
   keypressed→textinput as an invariant (a synchronous harness would go false-green on a sequencing the
   device doesn't honor). Optional one-line spec note that order-independence is intentional.
4. **P3 → A6:** validation only — combo path is the sanctioned chord answer → A6 stays *decide-before-M5*.
5. **P4 → A1 (concrete, code-grounded driver):** the real P4 is **T3 raw-`love.*` global state leaking
   across run boundaries** (the sandbox deep-clones the `love` *table* but shares leaf C functions, so
   imperative calls hit real SDL/LÖVE state — `consoleController.lua:40,297`, `table.lua:48`). **Fix:
   framework snapshot/restore of T3 state on project stop — not a project hook** (robust to crash/force-exit,
   sandbox-safe, and it *also* dissolves the P2 edge-tracking workaround by letting projects disable
   key-repeat). A project-run-lifecycle / sandbox concern, **outside #77's keyboard-widget scope** → A1.
   A `before_exit` hook (which **can** fire on `Ctrl+Esc` if framework-invoked — my earlier "can't" was
   wrong) is needed only for project-*internal* save/memoize, not for global-state restoration. Narrowed
   interrogation: confirm T3-global-restore (→ framework) vs internal-save (→ hook).
6. **Coverage scope:** adopt `keyboard` (new-style characterization) + `maze` (D-9 + M8 migration) as
   named M4-0 / migration targets.

*Estimate impact (E11/E16): none new — these refine M4-0's acceptance scope, already an E9 deliverable;
they do not add or pivot a milestone.*

## See also (produced alongside this assessment)
- **Sandbox env mechanism** (the T1/T2/T3 model behind the P4 analysis):
  [`doc/development/internals/project_sandbox_env.md`](../../../../internals/project_sandbox_env.md).
- **Design stance — full key-state, no modifier privilege** (bears on the combo tier / A6):
  [`notes/talk/keys-pressed-no-modifier-privilege.md`](../talk/keys-pressed-no-modifier-privilege.md).

*— assessment by AI, 2026-06-22*
