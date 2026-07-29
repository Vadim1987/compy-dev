# S22 Sol consultation — ruling order before TF2

## Bottom line

Yes: with the ledger now visible and bounded, the effective order is
to settle substantially more than G-2 and D4 before the owner reviews
the PR candidate.

The earlier filter asked a narrower question: whether a later ruling
would invalidate TF2's behavioural reading of the split tests. The
owner is asking the more useful question now: whether the eventual PR
candidate will retain the shape being reviewed. On that criterion,
several supposedly safe deferrals are not safe. Production changes,
test rewrites, comment cleanup, persistent-doc changes, and PR
packaging all create a second diff and a cognitive discontinuity even
when the previously reviewed assertions remain semantically valid.

The best current sequence is:

1. Make a short, explicit scope ruling on every visible item.
2. Execute every ruling that changes production code, tests, fixtures,
   persistent docs, or PR packaging.
3. Re-run the suite and produce a fresh navigation batch.
4. Perform one full TF2 review against that settled candidate.
5. Let TF2 add genuinely new findings; do not preserve known decisions
   merely because the old plan expected to discover them later.

This is not "decide everything imaginable before review." It is
"dispose every known item before review": implement it, reject it, or
explicitly put it outside this PR with a durable reason. That keeps
scope control without leaving ambiguity inside the candidate.

## Why the old ordering is no longer the strongest ordering

The plan's original TF2 -> TF3 -> B/C/D order protected against two
real risks: ruling from an unreliable suite, and abstracting many
unknown findings too early. Those conditions have changed. The suite
has been split and swept, Phase R is closed, the baseline is
854/0/0/4, and the open set is concrete enough to inspect one item at
a time. The plan itself already changed order once for exactly this
reason: Phase R was executed before TF2 resumed so the owner would not
review files whose shape was about to change.

That precedent applies again. A process ordering is useful only while
it protects quality. Once its deferred set becomes observable, keeping
known PR-shaping work behind the review gate makes the review less
efficient without adding architectural safety.

There is one important refinement: some decisions require a small
targeted read to make responsibly. That read should happen now as
decision preparation. It is not the broad TF2 pass. After the decision
and execution, TF2 can still be the one complete review of the settled
candidate.

## Current-record corrections

Two facts materially change the first back-filter.

First, the jargon cluster is not merely later prose work. Current
split-suite files still contain literal `{jargon: ...}` annotations,
including `input_routing_spec.lua`,
`input_widgets_callbacks_spec.lua`,
`input_events_spec.lua`, and `input_nfr_forward_spec.lua`. The routing
file also retains its suite-level jargon and spec-reference review
instructions. Cleaning or retaining these changes what the owner
reads.

Second, the held-key propagation/identity obligation is **RVW-087**,
not RVW-092. Commit `2b75f3a` rewrote RVW-087's marker into the live
`OWED` note in `input_nfr_forward_spec.lua`; its commit message also
names RVW-087. The current inventory's RVW-087 disposition text is
cross-wired with a different widget-state item. RVW-092 is the
suite-level "fix spec references everywhere" instruction in
`input_routing_spec.lua`, and it remains in the file while many
`{badspecref: ...}` annotations remain across `tests/input`.

The initial shortlist also omits other live owner-review prompts such
as RVW-019, RVW-095, RVW-097, and the D4 family. They need not each
become an architecture ruling, but they must be included in the
pre-review disposition sweep. "Every marker dispositioned" currently
means several were deliberately sent to TF2; it does not mean the
candidate has no unresolved prompts.

## Item-by-item recommendation

| Item | Current effect on the PR candidate | Best disposition before TF2 |
|---|---|---|
| **G-1** | A full inspect-mode redesign would alter the console/route spine and tests, but no replacement contract exists. The current persistent docs already label the behaviour contested and limit it to inspect mode. | **Rule now, clarification only:** either explicitly exclude the migration from #77 and retain the contested debt entry, or commission a separate design effort and postpone TF2. Do not leave a vague "schedule later?" question inside the PR. The strong recommendation is exclusion from #77. |
| **G-2** | Unification could change `controller.lua`, project API shape, click tests, fixture setup, liveness detection, docs, and examples. | **Rule now.** First perform a bounded architecture read. Mouse single/double-click is a derived Compy event looked up at delivery time; keyboard/text hooks are raw route-chain consumers, seeded at activation and able to consume before the widget. They are not automatically the same abstraction. A defensible ruling may be "intentional split, document why," which is cheaper and more scope-coherent than forced unification. Ambiguity is the part that cannot remain. |
| **R2: `eval` / `result`** | The old combined proposal is stale. `eval` is already documented public API and used by examples. `result` has no producer in current source/tests, while `apply_config`, `deliver`, reset code, comments, and docs still carry it. | **Rule now, split the row.** Ratify `eval`. Separately decide whether to remove the dead legacy `result` path; removal is a production/test/doc unit and belongs before review. Blessing both together would preserve dead mechanism under cover of the live `eval` API. |
| **R4: `multiline`** | Current code has an unimplemented TODO; persistent docs correctly say Shift+Enter is unconditional and record the deviation. Implementing the flag would add code/tests/API. Striking the old promise is mainly packaging and debt wording because frozen design is not edited. | **Rule now.** Recommend "not part of #77's public API; keep as explicit future work or drop the promise." This should be a clarification/documentation execution, not a late feature implementation, unless the owner deliberately expands scope. |
| **R5: unknown `show{}` keys** | The proposed warn path changes production behaviour and needs tests; it is not merely a doc decision. | **Rule now and execute before TF2** if warn-on-unknown is desired. If silent ignore is retained, say so explicitly in the public contract/known deviations. This is a clear second-review risk. |
| **C1: frozen design archival** | It controls which document is authoritative, how deviations are explained, what enters the PR description, and ultimately whether the large wip tree is retained or deleted. | **Rule now at the policy level:** `doc/input_api.md` is live; frozen `design/` is history, not contract. Keep the separate owner gate for actual wip deletion. Review packaging should not proceed with document authority unresolved. |
| **Jargon and bad references** | Literal review tags and construction vocabulary remain in the split tests. Any later cleanup edits exactly the prose the owner has read. | **Rule and execute now.** This need not become a grand terminology constitution. Apply a local PR criterion: surviving comments use plain project vocabulary and persistent named references; unresolved historical tags do not ship. If a term such as "overlay" is already useful public vocabulary, retain it; remove the annotation rather than inventing a substitute. |
| **D4 test philosophy** | It governs the credibility and shape of the fixture and several suites. `input_fixture.lua` still hand-rolls partial setup/reset, although `doc/development/tests.md` describes a full real standup and real activation path. | **Rule now after a targeted fixture read, then execute.** Prefer real public/framework entrypoints for contract tests; allow direct seams and mocks when the test is explicitly a unit/mechanism guard and the reason is stated. Do not adopt an absolute "no mocks" rule. Resolve the concrete D4 markers under that principle before the broad review. |
| **RVW-023** | The marker remains although the file now has a substantial explanatory matrix and more cases than the original three-mode wording describes. A table/alias rewrite would still alter the reviewed test. | **Resolve now as local presentation.** Either accept the current explanation and remove the stale prompt, or apply the small alias/table rewrite. No architecture sitting is needed. |
| **RVW-020** | The old helper disappeared when its semantics were corrected; `assert_indexable_hl` is already the consequential rename. | **Ratify now administratively.** There is nothing useful to defer to TF2 unless the new helper name itself reads poorly during the targeted check. |
| **RVW-087 held-key identity** | The public hook already receives `Controller.held_keys()` on keypress. The live test note incorrectly says the delivered triple is a planned change, while the delivery-half test has landed. A later identity assertion would change the NFR/propagation tests. | **Rule now and execute or reject.** If same-view identity is intentional, add the end-to-end assertion and correct the stale comment. If only contents matter, remove the implementation-identity promise and keep a contents test. Do not leave an `OWED` note in the reviewed candidate. |
| **RVW-092 spec references** | The suite-level instruction and many `{badspecref: ...}` tags remain in test files. | **Execute before TF2.** This is mechanical reference cleanup under the already-ratified persistent-reference rule, not a new owner design ruling. Any reference with no persistent home should become a plain rationale or an explicit out-of-PR note, not an annotation awaiting another pass. |
| **RVW-100 Search routing** | The PR currently carries an intentional pending test and prose calling Search un-designed, while persistent `internals/user_input.md` already characterizes the real Search route. Adding a contract would alter tests; leaving the pending shapes the PR narrative and pending count. | **Rule scope now.** Either add a current-behaviour characterization test (without pretending Search was designed by #77), or remove Search from this feature's contract grid and record it as out of scope. A full Search API redesign is a serious and valid post-TF2 deferral; the inclusion/exclusion decision is not. |
| **Other live TF2 prompts** | RVW-019, RVW-095, RVW-097 and the remaining D4/G-1-marked comments are still visible in the reviewed files. | **Disposition sweep now.** Most are local clarity, isolation, tags, or fixture questions. Resolve, rewrite as a durable justified limitation, or explicitly exclude. Do not promote each to a principle-level ruling. |

## Serious arguments for leaving work until after TF2

There are four serious arguments, but they justify narrow deferrals,
not the present broad postponement.

1. **TF2 can reveal evidence needed for a ruling.** Readability,
   fidelity, and duplicated setup are best judged while reading the
   tests. The answer is to do a bounded preflight on the affected
   fixture/suites, rule and execute, then start the full pass. Calling
   that targeted evidence-gathering "TF2" would recreate the double
   review; keeping it explicitly scoped avoids that.

2. **TF2 may surface a genuinely new coupled finding.** No ordering can
   guarantee a zero-delta review. The aim is to remove known deltas,
   not pretend the review cannot find bugs. A new finding deserves a
   follow-up diff; a known deferred item does not.

3. **Some designs are outside the stakeholder ask.** Inspect-mode
   migration and a new Search contract can grow into separate
   features. That is a strong reason not to implement them now. It is
   not a reason to leave their status undecided: rule them out of #77,
   state why, and review the candidate on that basis.

4. **Decision fatigue can lower ruling quality.** A large omnibus
   sitting invites rubber-stamping. The mitigation is the owner's
   proposed one-by-one treatment, ordered by dependency, with
   execution between clusters. It is not deferral until after the
   reviewer has absorbed an unstable candidate.

No equally strong argument supports postponing R5, D4, G-2, the live
jargon/reference cleanup, or the held-key obligation after the full
candidate review. Each has an observable route to changing files in
the candidate.

## Recommended concrete order

The dependencies suggest five small clusters:

1. **Scope and document authority:** G-1, C1, R4, RVW-100.
   These establish what #77 is and is not promising.
2. **Public API shape:** G-2, then split R2 (`eval` versus
   `result`), then R5. Execute production changes tests-first.
3. **Test trustworthiness:** D4, including fixture setup/reset and
   the shortcuts/click cases. This comes after G-2 because the click
   fixture's proper public path depends on the mouse ruling.
4. **Test-candidate closure:** RVW-087 identity, RVW-023,
   RVW-020 ratification, RVW-092/reference cleanup, jargon, and all
   remaining local markers. Execute or explicitly close each.
5. **Fresh candidate:** green suite, clean marker/reference check,
   fresh navigation slices clearly labelled non-final, then TF2.

After TF2, TF3 should contain only findings produced by that review.
The collapsed B/C/D sitting can then be reduced to ratifying the
dispositions already made plus any genuinely new TF2 result, rather
than serving as a warehouse for decisions known before the review.

## Recommendation to the owner

Revise the Part-1 gate from "rule G-2 and D4, defer the rest" to:

> Before TF2, walk every visible ledger item once. For each, choose
> include-and-execute, retain-and-explain, or exclude-from-#77.
> Execute all candidate-changing rulings. Then review the regenerated
> candidate once.

That change follows the architectural principle already used for
Phase R, improves review continuity, and does not require accepting
scope expansion. The only things that should remain after the
preflight are explicitly separate future designs and findings that
TF2 has not yet discovered.
