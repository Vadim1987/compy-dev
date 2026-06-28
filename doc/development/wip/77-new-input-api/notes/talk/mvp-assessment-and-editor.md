# MVP assessment + editor UX question

_LLM(Claude Sonnet 4.6) + human(Hleb): 2026-06-24 (session 23)._

---

## 1. Was the design-refinement work necessary or overhead?

**MVP goal stated by human:** unblock key-combo handling (especially maze), unblock keyboard
example, allow fast UX fixups of editor.

### Minimum path to MVP (tracing from goal)

| Need | Depends on |
|---|---|
| maze unblocked | M4 (controller) + M5a (on_text_entered exposed) + M6 (after_submit / Escape) + M8 (legacy removal) |
| keyboard unblocked | M4 + M5a (on_key_pressed) + M6-02 (before_exit, nice-to-have not blocking) |
| editor UX fixups | **Independent of #77** — see §2 |

Note: maze does not need **M5b** (handlers sugar). maze is a textinput-channel REPL: it
submits commands and re-arms. Its "combo handling" (if any) comes through `on_key_pressed`
(M5a) + the user inspecting `keys_pressed`. The handlers dispatch table is never required.
keyboard similarly: once `on_key_pressed` is available (M5a), keyboard can detect combos
manually via `combo_string(k, keys_pressed)`. M5b is syntactic sugar over that pattern.

### What's been done vs. what's overhead

**Necessary, no question:**
- Design convergence sessions (1–11): 10 open decisions (D-1…D-10) had real answers that
  changed things materially (ProjectInputController rename, show-while-active semantics,
  proxy shape, combo-repeat semantics). Skipping this would have produced mid-implementation
  pivots that cost more.
- M4-0 characterization net: M4 is the highest-risk operation (gate removal on the main
  event dispatch path). A net that perturbs→red→restore is the right insurance. Without it,
  "black-box M4" would mean "manually test four app modes and hope." The net paid for itself
  before M4 even runs.
- M2 corrective takes (M2-01, M2-02): discovered bugs, not design gold-plating.
- E9 architect call: settled A6 (combo dispatch shape), repeat semantics, isrepeat threading,
  A1/T3 two-layer resolution. All of these directly constrain M5a/M5b/M6 implementation.

**Could have been faster (honest):**
- Revalidation sessions (02, 04, 19): ~3 sessions of verifying already-converged work. The
  E19 pass on E20's findings was the thinnest investment.
- Operational sessions (E10 estimates extraction, E21 late-input register): lifecycle
  maintenance that a faster-moving project would skip or inline.
- The gap between design convergence (session 10) and first implementation (session 13) was
  ~3 sessions of propagation/architectural prep. Some of that was necessary; some was
  over-sequenced.

**Verdict: unavoidable phase, not overhead.**
Every session produced a shipped artifact (locked spec decisions, M1/M2/M4-0 code) or
resolved a real risk (M4-0 safety net, A6 dispatch semantics). The pace has leaned toward
thoroughness over speed, but the M4-0 characterization net alone justifies the investment —
it is what makes black-box M4 safe, and M4 is where the highest-risk code lives.

**The M5 split (session 23) is the clearest sign the design is self-correcting:** instead
of adding overhead, it removed M5b from the critical path and accelerated everything else.

**Remaining work is lean.** M4 → M5a → M6 → M8 is 4 milestones, each well-specified and
load-bearing. M7 (extended API) and M5b (handlers sugar) are deferrable.

---

## 2. Editor UX — start now or wait for new API?

### Architecture of the question

The key fact: **#77 builds `ProjectInputController`** (the project-run input surface). The
editor lives in `EditorController`, which operates in **console/editor mode** — a completely
separate execution context.

```
Console/editor mode: ConsoleController + EditorController  ← editor UX lives here
Project-run mode:    ProjectInputController                 ← #77 API lives here
```

These two contexts use different `love.keypressed` slot occupants (via `set_handlers()`).
The `compy.input.*` callbacks (#77's output) are only active in project-run mode.

### What the editor UX needs from #77

| Editor UX bug type | Dependency on #77 |
|---|---|
| Buffer/code coordinate navigation | None — lives in EditorController/editor buffer model |
| Hotkeys in editor context (e.g. show/hide hints widget) | **M1 only** (combo_string, already done) — add combo handling directly to EditorController |
| Hints widget that *is* the input singleton | **M2 only** (compy.input.show/hide, already done) |
| Hints widget that is a NEW UI widget | None |

### What "editor will consume new API later" means

The roadmap note (M5a section): "ConsoleController and EditorController will migrate to
`dispatch()` later." This is a **post-MVP unification** — not a precondition for fixing
editor UX bugs. It means: once M5a's shared `dispatch()` function exists, EditorController
*could* reuse it instead of its own key-handling. That refactor is optional and later.

### Recommendation: **start editor UX fixes now, in parallel**

Reasons:
1. The fixes are in `EditorController` / the editor buffer model — different files, different
   execution context. Zero risk of stepping on #77's in-progress controller work.
2. `combo_string` (M1) is already shipped — hotkeys can be added to EditorController today.
3. `compy.input.show/hide` (M2) is already shipped — if the hints widget uses the input
   singleton, that surface is available now.
4. The only #77 deliverable the editor might eventually want is `dispatch()` for unification
   — but that's optional and post-release. Don't let it block UX fixes.
5. Waiting means blocking on M4 → M5a → M6 → (M7?) — several milestones, weeks of work.

**The one caveat:** if a hotkey is intended to trigger something in the input singleton from
WITHIN project-run mode (e.g. a project-run hotkey that shows the hints widget), that
belongs to `ProjectInputController` and depends on M5a. But if the hint-showing hotkey fires
in editor mode (before a project runs), it's fully independent of #77.

### Specific guidance for the editor owner

> **Buffer/code coordinate navigation bugs:** start now. Fully independent. Check
> `EditorController` and the editor buffer model.
>
> **Keyboard hotkeys in editor context** (e.g. toggle hints widget while editing): start now.
> Use `combo_string(k, controller.keys_pressed)` (M1, already available). Add handling
> directly in `EditorController:keypressed`.
>
> **Hints widget** (new UI widget that shows/hides): start now if it's a separate widget.
> If it reuses the input singleton, `compy.input.show/hide` is available (M2 done).
>
> **Do NOT wait** for M5b (combo dispatch table), M7 (set_text/cursor on input widget), or
> the EditorController→`dispatch()` unification. Those are post-MVP or orthogonal.
