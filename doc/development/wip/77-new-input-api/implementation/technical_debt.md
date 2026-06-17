# Feature #77 — interim debt & open boundaries

_Feature-scoped ledger. Tracks debt and unresolved boundaries **surfaced during #77 implementation**
that are tied to this feature's own milestones — to be **resolved or consciously accepted before the
feature closes**, not carried into the project at large._

> Distinct from [`/doc/development/technical_debt.md`](../../../technical_debt.md), which holds only
> **persistent** debt that survives beyond #77. Anything here is expected to be swept (or formally
> accepted) by the time the new input API ships. When an entry is settled, strike it and fold the
> decision into the relevant milestone's spec/outcome.

---

## Surfaced by the M2 take-1 review ([`reviews/M2-01.md`](reviews/M2-01.md))

### F-4 — `compy.input` is rebuilt per project-env, not "once at namespace setup" — **ACCEPTED**

- **Where:** `src/controller/consoleController.lua` — `get_compy_input()` is called from
  `get_compy_namespace()`, which `prepare_project_env()` invokes per project setup, so the
  `compy.input` table is reconstructed each time a project env is prepared.
- **Disposition:** **Accept as-is, no action.** The `show`/`hide` closures resolve
  `love.state.user_input_controller` dynamically, so they always reach the live singleton regardless
  of when the table was built. This is a wording deviation from M2's "created once at namespace setup",
  not a defect — the dynamic-lookup design is the better call (resilient to the singleton being
  (re)assigned). The decision is recorded in the M2-02 corrective spec's out-of-scope note; this
  entry exists so the deviation is understood as intentional, not an oversight to "fix" later.
- **Sweep:** nothing to do; closes with the feature as a documented, accepted deviation.

### F-5 — `show({ force = true })` / `configure()` cannot re-target an active session's `result`/`eval` — **OPEN → settle at M7**

- **Where:** `src/controller/userInputController.lua` — the `force` branch of `show()` re-applies only
  `text`; a fresh activation runs `apply_config` (eval, prompt, text, result).
- **State:** A running session's `result` target and evaluator cannot be changed mid-session.
  `M2.md` frames `force` purely in terms of content, so this is correct for M2. **M7's `configure()`
  does not close it either** — its spec live-updates only `prompt`/`highlighter`/`validator` and
  explicitly no-ops other fields while active. So no surface currently re-targets `result`/`eval` on
  an active session.
- **Sweep:** When **M7** (extended singleton API) is designed/implemented, **decide explicitly**
  whether mid-session re-targeting of `result`/`eval` is wanted — if yes, extend `configure()` to
  cover it; if no, record it as a deliberate constraint (a session's evaluator/result are fixed at
  `show()`). Either way the open boundary is closed there, not left implicit.
