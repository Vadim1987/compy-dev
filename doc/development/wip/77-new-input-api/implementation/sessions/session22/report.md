# session22 — report

**Commissioned:** rule every decision that could reshape the #77 PR candidate
before TF2; execute the resulting work; make the persistent contract corpus
authoritative; then prepare a fresh, navigation-only TF2 slice batch.

## Outcome

All **12/12** pre-TF2 items are dispositioned. The owner chose to resolve the
whole PR-shaping ledger before review, rather than defer decisions that would
force a second reading. The resulting tree is ready for a cold revalidation,
not yet for TF2 itself.

| Area | Result |
| --- | --- |
| Hidden console | Fixed the running-project fallback; inspect remains the visible stopped-project debugger (`93330dc`). |
| Contract | Retired public `eval`/`result`; project callbacks use line arrays with validator → `on_text_entered` → `after_submit`; shipped three small helpers (`2e0d93f`). |
| Compatibility | Rejected the unrequested `multiline` flag; Shift+Enter stays unconditional. |
| Examples/docs | Migrated tracked examples, persistent guide, decisions, debt, and changelog; C1 exposed and fixed Turtle/REPL line-array omissions. |
| Warnings | Unsupported `show` keys now warn and are ignored (`09eb143`). |
| Editor/future scope | Added real-entry Search characterization and a bounded migration path; retained pointer/keyboard asymmetry as explicit future debt. |
| Evidence | D4 now uses real fixture lifecycle where practical; held-key allocation is a narrowly labelled NFR guard. |
| Authority/J1 | Cold C1 sweep reconciled persistent docs; J1 removed construction-era marker vocabulary without changing behavior. |
| Navigation | Fresh, complete/disjoint TF2 review slices in `implementation/pr-slices/` (`4c002e8`); they are **not** final Phase-G assembly and must be regenerated after later changes. |

## Verification and handoff facts

- Latest feature verification: `busted tests` → **862 successes / 0 failures /
  0 errors / 3 intentional pending**. The pending cells remain console key
  release, editor pointer, and touch routing.
- C1’s cold outcome: `validation/outcomes/S22-terra-C1-authority-sweep.md`.
  Its real Turtle finding was fixed in `9f23e8a`; its stale test-guide facts in
  `4c662e9` and `7548541`.
- J1’s audit and cleanup outcomes: `validation/outcomes/S22-terra-J1-*.md`.
  The shipping corpus now has no `{jargon:}`, `{badspecref:}`, or inline
  construction-review markers. The tracked binary swap artifact remains
  deliberately untouched.
- Navigation outcome: `validation/outcomes/S22-terra-TF2-navigation-slices.md`.
  The eight slices cover all 89 WIP-excluded changed files exactly once. Whole
  tree `diff --check` is not meaningful for generated patches because their
  payload faithfully contains baseline whitespace; the guide/artifact check,
  partition verification, and suite are clean.
- The owner committed `16546af` (Dockerfile only) after the gate work. It is
  unrelated to #77 review content and must stay separate.

## Successor task

Session23 must revalidate this session under `agents/rules/revalidation.md`.
It should test the **outcome**, not redo the feature sweep: reconstruct the
pre-TF2 intent, check the persistent docs/code/tests/slices for coherence,
uniformity, integrity, scope, and complete artifacts; report to
`validation/reviews/S23-revalidation-pre-TF2-gates.md`. It must stop for the
human’s acceptance before opening TF2. A clean verdict means the human can
start TF2 using the navigation slices.
