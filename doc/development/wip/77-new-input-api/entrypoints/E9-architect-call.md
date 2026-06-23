# E9 — Architect call (decision record)
_Held 2026-06-22 (session 20). Architect: LLM(Claude Opus 4.8) + human design authority._
_Inputs: M2 human review (A1/A5/A6/A8), E20 SR3 hand-off, two-tier test strategy (E14), M4/M5/M6 specs._

The call that unblocks the forward feature path: commission **M4-0**, confirm the **test-first split**,
and resolve the **M2-review open design questions** + the **E20/SR3** hand-off. Outputs feed **E16**
(propagation) and the **E11** estimate recalc.

---

## 1. M4-0 commissioned — spec written

[`design/spec/M4-0-characterization-net.md`](../design/spec/M4-0-characterization-net.md). **Infra-feasibility
answer (the load-bearing unknown): feasible, a modest harness-extension at keypress granularity.** The
base precedent is the **raw-handler pattern** (`keys_pressed_spec` drives the real
`love.handlers.{keypressed,keyreleased}` closures installed by `setup_callback_handlers` — the slot M4
rewrites), **not `EditorSession`** (editor-block-nav-specific, bypasses the love slots — corrected by the
human, session 20). All three production slots already exist (`keypressed`/`textinput`/`keyreleased`), so
the gaps are narrow: a keypress-level driver helper + two `mock` emitters (order-independent textinput,
isrepeat). See the spec for coverage + acceptance. Chief input to the E16 sizing recalc — **smaller than a
session-style build**.

## 2. Test-first split — **confirmed**

Two-tier strategy stands (settled E14): M4-0 = Tier-1 characterization net; **M5/M6/M7 each get a
Tier-2 acceptance-test step preceding implementation** (test prompt may run on a cheaper model; red
suite is the guardrail the implementation step must turn green). Codification into
`process.md`/`sdlc.md` rides **E16**.

## 3. M4 execution — **black-box, guarded by M4-0** *(human)*

M4 runs as a standard lightweight execution prompt (implement→outcome→review), with the M4-0 net +
manual 4-mode verification (REPL / editor / project+overlay / project no-overlay) as the guardrail.
**Escalate to a managed subtopic only if** M4-0's infra work proves the integration can't be
characterized. The net is precisely what makes black-box safe on the highest-risk milestone.

## 4. M7 scheduling — **sequential M5 → M6 → M7** *(human)*

Keep roadmap order; no parallelism. Each milestone's test-first step lands against a settled prior
state; lowest coordination cost in the human-driven execution plane.

## 5. A6 [serialize-vs-match] — **keep serialize, kill the churn; noop-index + return-propagate** *(human)*

Decision (decide-before-M5): **keep `combo_string` → exact-match dispatch** (M5 spec's `__matcher` seam
stays as the future glob/prefix hook), **but eliminate the per-keypress table allocation** — build the
combo into a **module-local scratch buffer**, no fresh table per press (Lua/LÖVE is single-threaded, so
a reused scratch is safe). The registration-time matcher-closure pivot is **not** taken: it loses the
simple normalised string-keyed table for a churn problem a scratch buffer already solves; the `__matcher`
seam remains if profiling ever demands it.

Two human design refinements fold in:

- **noop default via metatable `__index`** — every *missing* combo resolves to a `noop` (returns nil),
  so dispatch needs **no `if`/nil-check** (honours the no-if-arrows ethos the A6 remark flagged).
- **return-not-swallow** — dispatch **returns** the handler result up even though LÖVE won't consume it;
  cleaner design, and it composes with the `or`-chain below for free.

Synthesised dispatch shape (realised in M5; recorded here as the decided direction):

```lua
-- framework_handlers / handlers: metatable-backed, two-level (see §6), __index → noop
function ProjectInputController:keypressed(k, keys_pressed, isrepeat)
  local combo = combo_string(k, keys_pressed)            -- scratch buf, no per-press table
  return framework_handlers[isrepeat][combo](k, keys_pressed)   -- truthy ⇒ chain stops, value returned
      or handlers[isrepeat][combo](k, keys_pressed)
      or on_key_pressed(k, keys_pressed, isrepeat)        -- default value IS the text-editing sink
end
```

The `or` short-circuit gives **chain-stop-on-truthy** (the consume contract), **no `if`**, and
**return-propagation** in one expression. noop returns nil → falls through naturally.

## 6. Combo-tier repeat semantics — **ratified, expressed structurally** *(human, was provisional)*

Decision: **`handlers[combo]` / `framework_handlers` fire once per physical press (fresh-only);
`on_key_pressed` keeps firing on every repeat.** A project gets *both* — one-off actions via handlers,
repeat-aware handling via `on_key_pressed` — with **no per-handler `isrepeat` guard**. Matches the
`keyboard` example's once-per-press "hit"/"knock" need.

**Human structural refinement — `handlers[isrepeat][combo]`:** key the handler tables *first* by the
`isrepeat` boolean, then by combo. **Only the `[false]` (fresh) plane is populated**; the `[true]`
(repeat) plane is all-noop. So a repeat hits noop at the framework/handler tiers and **falls straight
through to `on_key_pressed`** — the fresh-only rule is encoded **structurally**, with no `if not
isrepeat` branch. Clean and straight; composes with §5's `or`-chain.

**Margin note (human, recorded not adopted):** the per-combo `__index` default could be
`on_key_pressed` *itself* rather than `noop`, collapsing the third `or` term. Not taken — keeping
`on_key_pressed` as the explicit tail is clearer and lets the sink default be replaced independently of
the handler tables. Captured here for the M5 designer to weigh. Aligns with the
[no-modifier-privilege](../notes/talk/keys-pressed-no-modifier-privilege.md) stance (full key-state in,
combos are sugar).

**`isrepeat` threading (regression-undo):** thread `isrepeat` (+ `scancode`) through the harvest
wrapper (`controller.lua:554`, today `function(k)`); lands in **M4**, asserted by **M4-0** (the one
red-until-fixed assertion).

## 7. A5 [overlay-flag contract] — **keep documented-as-intentional** (ratified, no refactor)

`love.state.user_input = {M,C,V}` overlay flag stays; session-17 already documented the contract. **No
controller-owned-M/V refactor** — it's durable (persists unchanged to M8, only drivers change), and the
refactor is scope-risk for zero behavioural gain.

## 8. A1 / P4 [project hooks / global-state leak] — two layers, ship the cheap one *(human, refined session 20)*

- **In-#77:** the project-hook question is answered by M4's **D-9 native-coexistence wrapper** (specced
  in `M4.md`). No new work.
- **The P4/T3 leak → two complementary layers, *not* "framework-only".** Background: the sandbox
  deep-clones the `love` *table* but shares leaf C functions, so a project's imperative
  `love.*` calls (`setKeyRepeat`, `setTextInput`, `setRelativeMode`, raw audio) hit real SDL/LÖVE state
  and nothing restores it on stop. Two layers address it:
  - **Layer 1 — project-bindable `before_exit()` hook (enabled, not enforced; near-term).** A hook the
    project can bind, fired on stop (incl. `Ctrl+Esc` — framework-invoked code, so it *does* run).
    Wanted **anyway** for the project's own internal teardown (save/memoize), and it **doubles as a
    cheap, opt-in device-cleanup path**: a self-aware app restores its own T3 state (e.g. `keyboard`
    re-enabling key-repeat on exit). Same hook family as **M6**'s named `before_*`/`after_*` chains →
    natural home is **M6 or a small adjacent slice**. *Not guaranteed* (a careless project skips it),
    but enabled > absent.
  - **Layer 2 — framework-guaranteed T3 snapshot/restore (robust, postponed).** The reliable answer:
    framework snapshots T3 device state and restores on stop — robust to crash/force-exit, sandbox-safe,
    and it *also* dissolves the P2 edge-tracking workaround. **But effectively a separate, non-input
    feature:** it first needs an **architecture extension to reliably grab/serialize device state**
    (otherwise there is nothing to restore *to*), plus **extensive testing** before it earns
    "guaranteed." → **deferred, not dismissed**; remains the eventual robust backstop, parked as an
    **A1 sibling** (project-run-lifecycle / sandbox concern, outside #77's keyboard-widget scope).
- **Design principle (human):** *not-enforceable-but-enabled > no mechanism.* Layer 1 ships the cheap,
  available protection now; Layer 2 is the guaranteed backstop, later. Mechanism doc:
  [`internals/project_sandbox_env.md`](../../../internals/project_sandbox_env.md).

## 9. P1 [event-order] — test hygiene only, no runtime contract

No spec order-guarantee owed (upstream keypressed→textinput is a de-facto SDL artifact, not a
guarantee; the channel split is already order-*independent*, which is strictly better). M4-0 must **not**
bake the order in as an invariant; one optional spec sentence states order-independence is intentional.

---

## Resolution roll-up

| Item | Resolution |
|---|---|
| M4-0 spec | **Commissioned** — harness-extension + characterization; infra feasible (driver + textinput + isrepeat) |
| Test-first split | **Confirmed** — M4-0 Tier-1; M5/M6/M7 Tier-2 test-first |
| M4 model | **Black-box, guarded by M4-0** (escalate only if infra uncharacterizable) |
| M7 | **Sequential** M5→M6→M7 |
| A6 dispatch | **Serialize + scratch-buf**, `__matcher` seam kept; **noop-index** (no `if`) + **return-propagate** (`or`-chain) |
| Combo repeat | **Fresh-only handlers / repeats to `on_key_pressed`**, via **`handlers[isrepeat][combo]`** structural keying; `on_key_pressed`-as-default margin note recorded |
| isrepeat threading | Thread at `controller.lua:554` in **M4**; **M4-0** asserts (red-until-fixed) |
| A5 overlay flag | **Keep documented**, no refactor |
| A1 / P4 / T3 | M4 D-9 wrapper (specced). P4 leak = **two layers**: (1) project `before_exit()` hook — enabled-not-enforced, cheap device cleanup + internal teardown, M6-family, **near-term**; (2) framework T3 snapshot/restore — guaranteed but **postponed** (needs device-state serialize + heavy testing), A1 sibling. Principle: *enabled > absent* |
| P1 order | Test hygiene only; no runtime guarantee |

## Downstream

- **E16 (propagate, atomic-after-E9):** retire M3 tombstone → add M4-0 + the test-first steps; codify the
  `-0` precondition rule + test-first split into `process.md`/`sdlc.md`; **E11 recalc** sized off M4-0
  (harness + characterization). The §5/§6 dispatch decisions feed the M5 spec when M5 is commissioned
  (frozen `M5.md` is not edited — they ride an adjacent M5 slice / its test-first prompt).
- **`before_exit()` hook (§8 Layer 1):** slot when M6 is commissioned — same named-hook family as M6's
  `before_*`/`after_*` chains; either folds into M6 or rides a small adjacent M6 slice. Carry as a near-term
  deliverable, not a parked sibling (that's Layer 2 only).
- **E8 resumes** at M4 once E16 lands.
- **SR3 register** ([`notes/late-input-register.md`](../notes/late-input-register.md)) — items flipped to
  landed-in-E9.
