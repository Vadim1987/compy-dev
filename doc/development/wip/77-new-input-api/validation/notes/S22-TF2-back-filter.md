# S22 — TF2 back-filter

## Purpose

Before TF2 begins, identify parked decisions whose later ruling would
change the files the owner is about to review. This is not a ruling.

| Item | What it is | Cost to rule up-front | Cost if deferred | Recommendation |
|---|---|---|---|---|
| G-1 | Inspect-mode console owns all input; real hidden-widget runs already fall through. | Choose only whether to schedule a future console/editor migration or retain the contested status quo. No defined replacement exists. | No TF2 file changes. At most recheck the hidden-widget assertion if a later migration is commissioned. | Safe to defer. |
| G-2 | Mouse uses `compy.singleclick`/`doubleclick`; keyboard/text use `compy.input.hooks[event]`. | Decide unify vs intentional split; may change the click fixture, docs, and the shortcuts/click review target. | The owner reviews a shape that a later ruling may rework, then revisits the same click/fixture material. | Rule now. |
| R2/R4/R5/C1 | Residual API/spec deviations: `result`, multiline, unknown show keys, and frozen-design archival status. | Four narrow product/documentation dispositions. | No split-test review changes; only later docs/code/test additions where a chosen correction needs them. | Safe to defer. |
| Jargon cluster | Policy for `overlay`, tier-N prose, callback-slot wording, and related vocabulary. | One terminology policy, contrary to the plan's explicit later sitting. | Prose may be edited later, but TF2's behavioural reading remains valid. | Safe to defer. |
| D4 | Whether fixtures/tests should drive real framework entrypoints and public surface rather than partial setup and monkeypatches. Includes the two fixture-fidelity questions. | One test philosophy ruling; either queue a bounded fixture refactor or justify the test doubles. | It governs how many TF2 files deserve trust and may require re-reading their setup and assertions after a refactor. | Rule now. |
| RVW-023 | Local clarity choice: aliases/table for the three highlight evaluator variants. The current file now explains all four matrix rows. | Decide whether that presentation needs a local restructure. | At most revisit this one short test file; no cross-file contract changes. | Safe to defer into TF2. |
| RVW-020 deviation | The former `view_access_ok` helper vanished when B-COV replaced its semantics; `assert_indexable_hl` was the consequential rename. | Ratify or reject the already-executed consequential rename. | A rejection is a local helper rename only; it does not alter what TF2 reviews. | Safe to defer; note it as a deviation. |
| RVW-092 | Owed propagation-table identity assertion; delivery is covered, identity is not. | Decide whether identity itself is a public contract worth a separate end-to-end test. | A later test is additive and local to propagation coverage. | Safe to defer. |
| RVW-100 | Search routing has no #77 design contract, so a test would invent one. | Define a separate Search surface contract before adding a test. | Does not change the input-API test philosophy or existing assertions; it adds a new, separately reviewable contract. | Safe to defer. |

## Inventory correction

RVW-087 is not live: S21 resolved it by adding the three widget-state
rows. It should not be presented as a decision candidate. RVW-020 is
also no longer a live marker; its consequential early resolution is the
only remaining matter.

## Basis

G-1/G-2: `collapsed-gate-ledger.md`; category (a):
`S18-post-R-replan-reconciliation.md`; D4: `S19-tests-triage-plan.md`;
marker state: `review-marker-inventory.md`; contested G-1 status:
`technical_debt/input.md`.
