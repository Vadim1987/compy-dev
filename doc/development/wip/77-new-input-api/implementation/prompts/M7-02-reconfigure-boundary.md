# M7-02 — live reconfigure + M7-01 boundary close (chunk 2 of the M7 carve)

_Implementor commission (`agents/dev.md`). Milestone id `M7-02`. Second and **final** chunk of the M7
carve (`implementation/M7-chunk-plan.md`), validated against the frozen `design/spec/M7-02-recut.md`.
Delivers the two live-reconfigure callables — **`configure` / `clear`** — on `compy.input`, plus the
**M7-01 boundary close** (AC-11: document the decided semantics + strike F-5) and the **milestone
close-out** (AC-12). Purely additive; no routing/dispatch change. **This chunk closes M7.** Suite
baseline entering this chunk: **794 / 0 / 0 / 5** (M7-01 landed at `91e6e99`, Opus-APPROVED)._

## Read first (authority chain — higher wins)

1. `design/notes/ratified-model.md` — the canonical ratified model (R1–R14, binding glossary). Mint no
   architectural nouns outside its glossary.
2. `design/spec.md` §3/§6/§7 — Gate-2 contract; §7 = the mutable boundary (callable API raises on assign).
3. **`design/spec/M7-02-recut.md`** — the frozen implementation target. Read the **Contract** section's
   `configure(config)` + `clear()` bullets, the **Riding decision — M7-01** section (the pre-ratified
   Option B), and the **Delta** items 1/2/3 word-for-word. Your ACs are **AC-1, AC-2, AC-3, AC-4, AC-5,
   AC-9, AC-10, AC-11, AC-12** (verbatim in that file).
4. `doc/development/internals/user_input.md` — esp. `### compy.input namespace` (the AC-11 doc target)
   and `### Singleton lifecycle`. M7-01 already landed `get_cursor`/`set_cursor`/`set_text` here — read
   its `outcomes/M7-01.md` + the surrounding code to match style.

`design/` is **frozen** — read, never edit. Repo-root `CLAUDE.md` auto-loads `rules.md` +
`development.md`: hard limits (line ≤64, fn body ≤14, params ≤4, nesting ≤4), no string-tag dispatch,
KISS, **tests-first** (red before green), **report-don't-fix**, Conventional Commits, **commit locally,
NEVER push**. **lua-lsp MCP is RESTORED — use it** (`definition`/`references`/`hover`/`diagnostics`);
`sleep 1` after any `.lua` edit before an MCP call; grep as the completeness backstop.

## Your ACs (verbatim from `spec/M7-02-recut.md`)

- **AC-1** `configure{prompt='new'}` updates the displayed prompt on an active session without teardown
  — content, cursor, and callbacks untouched.
- **AC-2** `configure{validator=fn}` / `{highlighter=fn}` / `{on_text_entered=fn}` / `{on_limit_reached=fn}`
  take effect immediately on an active session; the next submit/boundary/keystroke uses the new function.
- **AC-3** `configure{text=…, cursor=…}` on an active session changes nothing in the session (accepted,
  inert) — **and is applied on the next `show()` when given while hidden.**
- **AC-4** `configure` while hidden is safe and applies on the next `show()`.
- **AC-5** `clear()` on an active session empties the content and puts the cursor at the start; no
  callback fires. `clear()` while hidden is a no-op + warning.
- **AC-9** Every refused call above produces a visible warning (log), never a silent return.
- **AC-10** Assigning to `compy.input.configure` / `compy.input.clear` raises a loud error — the mutable
  boundary is unchanged.
- **AC-11** The M7-01 boundary is closed: the re-target behaviour of `configure()` toward an active
  session is **exactly the Contract**, documented in `doc/development/internals/`, with **F-5 struck**
  from the tech-debt ledger; no path applies a `configure` change partially or silently.
- **AC-12** The contract suite's m7-family `pending` rows convert to live green; the full suite is green;
  no routing/dispatch behaviour change is observable in any app mode.

## The landed surface you build ON (confirmed live in code)

- **`compy.input` `methods` table** — `src/controller/consoleController.lua` `get_compy_input()`. It now
  holds `show` / `hide` / `get_cursor` / `set_cursor` / `set_text` (M7-01). **Add `configure` and
  `clear` here** — non-assignable for free (they are not in `INPUT_CALLBACKS`; that is AC-10, do NOT add
  them to `INPUT_CALLBACKS`). Resolve the singleton via `love.state.user_input_controller` (`ui`);
  "shown" ⟺ `love.state.user_input` truthy.
- **`show`'s config-persistence seam (READ THIS — it is the AC-3/AC-4 subtlety):** `show(cfg)` currently
  persists only the **four output keys** (`on_text_entered`, `on_limit_reached`, `validator`,
  `highlighter`) into `state` across shows, then passes them through on the next `show`. **`prompt`,
  `text`, `cursor` are NOT persisted** — they are per-show only. For **`configure` while hidden** (AC-4/
  AC-3), the provided fields must **persist so the next `show()` applies them** — including `prompt`,
  and (AC-3) `text`/`cursor`. So you must extend the hidden-configure path to stash provided fields into
  `state` (or an adjacent pending-config table) and have `show()` merge them. Keep it single-sourced —
  do not fork a second persistence mechanism; extend the existing `state` merge.
- **Controller internal API** — `src/controller/userInputController.lua`:
  - `apply_config(self, cfg)` (L~191-220) already applies `prompt` / `text` / `highlighter` / `validator`
    / `on_text_entered` / `on_limit_reached` (also legacy `eval`/`result`). This is the **live-apply**
    engine for `configure` on an **active** session — **but `configure` must NOT apply `text` or
    `cursor` on an active session (AC-3 inert)**, and must not touch `eval`/`result`. So the live path
    feeds `apply_config` a **filtered cfg** (only the live-updatable keys: prompt, highlighter, validator,
    on_text_entered, on_limit_reached), or a dedicated method that applies exactly those. Do not let
    text/cursor reach the active-session apply.
  - Add thin controller methods for `configure` and `clear` mirroring M7-01's shape (`get_cursor` etc.).
    `clear` on active: empty content + cursor to start + `update_view()`, **no callback fires** — reuse
    `model:clear_input()` (L~342) and confirm it leaves the cursor at the start (line 1, col 1); add the
    cursor-reset if `clear_input` alone doesn't. `update_view()` reflects it without a re-show.
- **`force` stays as-is.** The `show(force=true)` text-only-subset path (`userInputController.lua:~265-275`)
  is NOT reworked. `configure` is the *documented* live path; part of AC-11 is documenting the
  **force-vs-configure distinction** (force = re-applies only the text subset on an active overlay;
  configure = the full live-reconfigure of the allowed fields). That distinction is the name of the m7
  anchor pending row you retire.

## Do in this order (test-first — red before green)

1. **Reproduce the baseline.** `busted tests` → confirm **794 / 0 / 0 / 5**. Read the frozen spec ACs +
   the M7-01 `#m7` test block in `tests/input/input_contracts_spec.lua` (match its structure/fixture —
   it drives the real `F.compy_input()` / `compy.input` surface, not mocks).
2. **Red: AC-1..AC-5 + AC-9 contract rows** against the real `compy.input` surface. Cover:
   - AC-1: active `configure{prompt='new'}` → displayed prompt changes; content/cursor/callbacks intact.
   - AC-2: active `configure{validator=fn}` (and highlighter / on_text_entered / on_limit_reached) →
     the **next** submit/boundary/keystroke uses the NEW fn (prove by exercising the path, not just
     reading a field).
   - AC-3: active `configure{text=…, cursor=…}` → session **unchanged** (inert); AND hidden
     `configure{text=…}` then `show{}` → the text **is applied** on that show.
   - AC-4: hidden `configure{prompt=…, validator=…}` then `show{}` → applied on show (no warn/error).
   - AC-5: active `clear()` → content empty, cursor at start, **no callback fires** (spy the widget
     outputs, assert 0 calls); hidden `clear()` → **no-op + warn** (`Log.warn` asserted).
   - AC-9: the two refused paths (hidden `clear`; any other refused call) log a real warning.
   - **Watch the modes:** AC-2's "no partial/silent application" (AC-11) means `configure` either applies
     a field fully or refuses — no half-applied state. Add a row that a `configure` with a mix of live
     and inert fields on an active session applies the live ones and leaves the inert ones untouched,
     with nothing partially applied.
3. **Red: AC-10** — `compy.input.configure = fn` and `compy.input.clear = fn` **raise** (assert error,
   like the M7-01 assignment rows).
4. **Green: implement** `configure` + `clear` (methods table + controller methods + the hidden-persist
   extension to `show`/`state`). Keep bodies ≤14 lines, ≤4 params, nesting ≤4. `sleep 1`, then lua-lsp
   `diagnostics` on edited files + `references` on `apply_config` / `show` / any method you touch to
   confirm no caller regressions. Re-run `busted tests` → new rows green.
5. **AC-12: retire the m7 anchor pending.** The row `pending('configure/set_text/cursor,
   force-vs-configure')` (currently `tests/input/input_contracts_spec.lua` **@~1828**, in the
   `describe('later forward contracts — not yet authored')` block) is now fully authored — **replace it
   with the live green rows** (or remove the now-empty anchor block if its whole content is realised).
   Confirm the **four routing-gap pendings** (@101/@153/@161/@222 — console key-release, editor pointer,
   editor-search, touch) **remain pending** (they are outside #77's blast radius — do NOT touch them).
   Target end state: **794 + N / 0 / 0 / 4** (the m7 anchor retired → pending 5 → 4; the four routing
   pendings survive). Full suite green.
6. **AC-11: close the boundary.**
   - **Document** the decided `configure()` semantics (the live-updatable set; text/cursor inert on
     active but applied-on-next-show when hidden; the force-vs-configure distinction; "no partial/silent
     application") in `doc/development/internals/user_input.md` — the **`### compy.input namespace`**
     section is the natural home. **No milestone ids in prose** (say "the live-reconfigure surface", not
     "M7"). Prose describes the shipped contract, not the project history.
   - **Strike F-5** from `implementation/technical_debt.md`: both the summary-table row (~L22) and the
     detailed `### F-5 …` section (~L99-107). Use the ledger's existing strike convention — `~~strike~~`
     + `**closed**` + a one-line closure note citing that M7's `configure()` landed the live-reconfigure
     surface and the boundary is documented (no partial/silent path). Match how e.g. the `~~M5c-02 …~~`
     rows were closed.
7. **Record `outcomes/M7-02.md`** (ledger spec below) and **commit locally**.

## Scope fence (overreach = STOP + record)

- **Do NOT** re-touch `get_cursor`/`set_cursor`/`set_text` (M7-01, landed + approved) beyond wiring
  `configure`/`clear` alongside them.
- **Do NOT** add `configure`/`clear` to `INPUT_CALLBACKS` (AC-10 = placement in `methods`).
- **Do NOT** rework `force`, `show`'s existing behaviour beyond the additive hidden-persist extension,
  or any routing/dispatch (projectInputController, controller.lua route wiring) — AC-12 requires **no
  observable routing/dispatch change**.
- **Do NOT** remove or alter any legacy global (`input_text`/`user_input`/`validated_input`/
  `write_to_input`) or the poll idiom — those die in **M8**.
- **Do NOT** touch the four routing-gap pendings.
- **Expected files** (beyond = stop + record): `src/controller/userInputController.lua`,
  `src/controller/consoleController.lua`, `tests/input/*`, `doc/development/internals/user_input.md`,
  `implementation/technical_debt.md` (the F-5 strike). **No model edit is expected** — `configure`/
  `clear` are controller+namespace; if you believe you need a model change, STOP and record why.

## Report-don't-fix (log, do NOT fix here)

- **Carried from M7-01 review:** `UserInputModel:set_text` body is 19 lines (>14 hard limit; was 17
  pre-M7-01, +2 from the mandated keep_cursor gate). It lives in the **model**, which M7-02 does **not**
  touch — leave it; it is captured in `reviews/M7-01.md`. If (and only if) you end up in the model for a
  legitimate reason, note it; do not open the model just to fix it.
- Tech-debt F-0 (`submit()` deliver-then-hide ordering) — if `configure` makes a reject-keeps-open flow
  naturally expressible, **note it** in the ledger; do NOT scope-creep to fix the ordering.

## Outcome ledger — write to `outcomes/M7-02.md`

Include: per-AC proof (AC-1..5/9/10/11/12 — which test row proves each, esp. AC-2's "uses the new fn"
exercised-not-just-set, AC-3's dual active-inert / hidden-applied behaviour, AC-5's no-callback assert,
AC-11's no-partial-application proof); the **configure semantics** you implemented for each of the two
modes (active vs hidden) and exactly which fields persist in which mode (the AC-3/AC-4 subtlety); the
**hidden-persist mechanism** you added to `show`/`state` and why it is single-sourced; the F-5 strike
(what you changed in `technical_debt.md`); the internals-doc addition (which section, quote the added
contract line — confirm no milestone ids in prose); commit hashes; before/after busted counts
(expect `794 → 794+N / 0 / 0 / **4**`); scope-fence confirmation; tech debt discovered; and a
**"what will surprise the architect"** (surprise-first) section for any conservative-reversible call.
**If anything forces a genuine design choice** — a spec gap, a corpus contradiction, or a concrete need
to **diverge from the Option-B / Contract semantics** (mandate guardrail 1) — **STOP and report**; do
not rule in-slice.
