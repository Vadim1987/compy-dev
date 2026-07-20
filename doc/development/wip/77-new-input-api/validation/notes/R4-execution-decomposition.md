# R4 execution decomposition (owner-confirmed 2026-07-20, session17)

**Why this note exists.** plan.md's R4 lists an 8-step *recommended* order. On inspection
the code steps are more coupled than that order implies, so a literal step-by-step execution
would leave the suite red between coupled units. R4's gate is **outcome-defined** (suite
green, all ten delta-spec ACs pass as tests, rename sweep LSP-verified complete, REVIEW
inventory "resolved" items removed) — not tied to the sub-step sequence — and guardrail-2's
hard ordering constraints (S7-before-green-citing-rulings; slice-regen-last) are unaffected
by regrouping R4's internals. Owner confirmed the regrouping below (AskUserQuestion,
2026-07-20).

## Coupling findings
- Existing tests encode the OLD behavior the ACs invert:
  `input_widgets_callbacks_spec.lua:389` ("framework Enter cannot be shadowed while shown")
  vs **AC5** (Enter/Escape shadowable); `:282`/`:494` (widget hidden after submit/cancel) vs
  **AC1/AC3** (widget stays shown). => removing tier-1 alone reds these; only the submit/
  cancel relocation repairs them. **Tier-1 removal + submit/cancel default-flip are one
  atomic behavioral change.**
- The new free-function `dispatch` reads `shortcuts[event]` / `hooks[event]`; the surface
  reshape (rename `handlers`→`shortcuts`, fold `on_*`→`hooks[event]`) must be **in place
  before** the dispatch flip.

## Units (each commits with suite green)
- **U1 — widget-method factory (obligation 6b, delta-spec §4).** `get_compy_input`'s
  `methods` table extracted to `build_widget_api(get_widget, get_active_flag)` closing over
  passed closures instead of the raw `love.state.*` globals. Project case closes over exactly
  those globals → behavior-identical, **no new test** (pure refactor; existing suite green is
  acceptance). Zero project-facing change.
- **U2 — surface reshape (delta-spec §1 + §5; AC 8, 9, 10).** compy.input restructured into
  three sub-tables `shortcuts` / `hooks` / `callbacks`; `hooks[event]` unification + one-shot
  seeding (no resurrection-on-nil = **AC8**); callbacks grouping; D7 frozen-container guard
  replacing the 11-entry allowlist (**AC9**); teardown re-seeds `DEFAULT_CALLBACKS` not nil
  (**AC10**). Dispatch's tier-2/tier-3 reads updated to the new sub-tables. **Tier-1 and the
  old submit/cancel behavior stay intact** this unit → green.
- **U3 — dispatch + tier-1 removal + submit/cancel (obligations 6a; delta-spec §2, §3, §6;
  AC 1-7).** Extract free-function `dispatch(shortcuts, hooks, widget, event, trigger, ...)`
  with no framework tier; delete `framework_handlers`/`install_tier1`/`framework_submit`/
  `framework_cancel`/`shown_widget`/`run_hook`/`_generic_callback`/`_sink`/`natives`; move
  submit/cancel onto the widget as `_submit_default`/`_cancel_default` with the auto-close
  default flipped OFF (**AC1,3**), `before_cancel` veto (**AC2**), opt-in auto-close
  (**AC4**), Enter/Escape shadowable (**AC5**), consumption-via-shownness (**AC6**); console
  patch onto `on_limit_reached`, dropping the return-value channel (**AC7**). Rewrite the
  existing old-behavior tests to the new ACs + add the AC anchors.
- **U4 — docs + rename-sweep verification.** Update `internals/user_input.md`,
  `doc/input_api.md`, `technical_debt/input.md`; verify the vocabulary rename complete via
  LSP `references` (zero hits on retired terms) + grep backstop; confirm the REVIEW-inventory
  "resolved" items are gone from code. This unit closes R4's gate.

**REVIEW-remark removals (from R4-1 inventory) ride their code units:** uIC 434/480/482 +
main 360 with U3 (dispatch/§2); uIC 669/685/687 with U3 (submit/cancel/§3); controller 325
with U2 (teardown re-seed/AC10).
