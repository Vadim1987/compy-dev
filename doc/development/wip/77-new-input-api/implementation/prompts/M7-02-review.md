# M7-02 — review note (traps to check)

_Reviewer boot (`agents/review.md`). Milestone id `M7-02`. Review the finished chunk (diff + ledger)
against `spec/M7-02-recut.md` AC-1..5/9/10/11/12 + the rules. **Verify-don't-trust:** re-run `busted
tests`; use lua-lsp `references` on `apply_config`/`show` to confirm no caller regressions. Edit ONLY
`reviews/M7-02.md` + `technical_debt.md`; NEVER feature code or `design/`. Verdict + busted counts.
**This chunk closes M7** — the milestone close-out (AC-12) is part of what you certify._

## Baseline / expected end state

- Entering: **794 / 0 / 0 / 5**. Expected exit: **794 + N / 0 / 0 / 4** — the m7 anchor pending
  (`configure/set_text/cursor, force-vs-configure`) is **retired** (5→4), while the **four routing-gap
  pendings @101/@153/@161/@222 survive**. If pending ≠ 4, or a routing-gap pending was touched, that is
  a finding.

## Traps — the high-value checks

1. **AC-3/AC-4 the subtle one — configure's two modes.** On an **active** session, `configure{text,
   cursor}` must be **inert** (session unchanged) — verify the test proves the content/cursor did NOT
   change. On a **hidden** session, `configure{...}` (including `text`/`cursor` AND `prompt`) must
   **persist and apply on the next `show()`** — verify the persistence was added to the existing
   `state`/`show` merge (single-sourced), not a forked second mechanism, and that `prompt` (not just the
   four output keys) persists. A common miss: only the 4 output keys persist and `prompt`/`text` silently
   drop on hidden-configure → AC-4/AC-3 fail. Check the test actually shows-after-hidden-configure and
   asserts the field applied.
2. **AC-2 "uses the new fn" — exercised, not just set.** The validator/highlighter/on_text_entered/
   on_limit_reached swap must be proven by **driving the path** (submit/boundary/keystroke) and observing
   the NEW fn ran — a test that only asserts `state.validator == fn` is insufficient. Push back if the
   proof is field-read-only.
3. **AC-11 no partial/silent application.** The Contract says configure applies fully or refuses — no
   half-applied state. Verify there is a test with mixed live+inert fields on an active session showing
   the live ones applied, inert ones untouched, nothing partial. And that the internals doc states this.
4. **AC-5 clear fires no callback.** Verify the test **spies the widget outputs and asserts 0 calls** on
   `clear()` — not just that content emptied. Cursor to start (line 1, col 1). Hidden clear → warn+noop.
5. **AC-10 by placement.** `configure`/`clear` in `methods`, NOT `INPUT_CALLBACKS`; assignment raises,
   asserted. Any `INPUT_CALLBACKS` addition is a corrective-take.
6. **AC-11 F-5 strike.** Confirm BOTH the summary-table row (~L22) and the detailed `### F-5` section
   (~L99-107) of `technical_debt.md` are struck (`~~…~~` + `**closed**` + closure note), matching the
   ledger's convention. A half-strike (one but not the other) is a finding.
7. **AC-11 internals doc.** Confirm the `configure` semantics are documented in
   `doc/development/internals/user_input.md` (compy.input namespace section is the natural home), the
   **force-vs-configure distinction** is stated, and there are **NO milestone ids in prose** ("M7",
   "M7-01", "0.1.0-m7" etc. must not appear as prose — the doc describes the shipped contract). Grep the
   added lines for milestone tokens.
8. **AC-12 no routing/dispatch change observable.** The diff must not touch projectInputController or
   controller.lua route wiring; the four routing-gap pendings unchanged. `apply_config`/`show`
   `references` clean.
9. **Scope fence + rules.** No model edit expected (configure/clear are controller+namespace) — if the
   model was touched, scrutinise why. No legacy global removed. Line ≤64, fn ≤14, params ≤4, nesting ≤4
   on the new methods. Watch that the `configure` live-apply filtering (stripping text/cursor before
   `apply_config`) didn't balloon a function past 14 lines.

## Carried debt to keep an eye on (do not require fixed here)

- `UserInputModel:set_text` 19-line body (M7-01 carry) — model file, out of M7-02 scope. If the
  implementor touched the model at all, note it (unexpected). Otherwise leave the carry as-is.
