# session19 — report

**Task (per `session19/prompt.md`):** run Phase TF2 — the owner's interactive human review of the
split input suite. **What it actually became:** at TF2's opening the owner judged the ~138 stale
`-- REVIEW:` markers too noisy to review cold, and commissioned an **improvised pre-TF2
noise-cleanup** — inventory every marker, then sweep/triage the dissolvable ones in owner-gated
batches (≤10). This is TF3-shaped work pulled forward and merged into the TF2 opening (plan allows
"ruled in the same sitting").

**Status: NOT complete — wrapped for session length** (owner-directed). TF2 proper and the remaining
mop-up batches (B-I/2, B-F, B-COV) are still pending. Successor continues from B-I/2. Suite green
throughout: **841 / 0 / 0 / 4**.

## What shipped (13 commits, `b9c2bfb`..`8bc066f`)
1. **Marker inventory** (`b9c2bfb`) — all 138 own-code markers (114 tests + 24 src), per-file, with
   Kind. Correcting a bad early count: the true detector is `REVIEW[:/]` (a taxonomy, not just
   `REVIEW:`), owner-caught. `validation/notes/review-marker-inventory.md` is the living ledger.
2. **Governing tier — all four ruled + applied.** Each disposed a whole cluster (~35 markers):
   - **D1 vocab** (`46595d2` symbol rename + `e698309` prose) — the feared production symbols
     (`sink`/`tier-3`) turned out already gone from `src/`; only test-local `F.singleton`→`widget`
     was real code. 12 markers dropped.
   - **D2 API-shape** — `.on_*`→`.hooks[event]` was already shipped/ratified; stale markers dropped.
   - **D5 `native`→`handler`** (`e742471`) + **D6 dissolve `slot`** (`dbeb491`) — both
     baseline-confirmed feature-invented terms (`git grep … updev -- src` = 0), swept across
     src+docs+tests. `95e775f` added `internals/event_dispatch_layers.md` (the `love.handlers.*` vs
     `love.<event>` two-layer doc).
3. **D3 + D4 relocated, not ruled in the marker lane** (`591b941`):
   - **D3 (console-hidden-sink safety) → new collapse-gate ledger, row G-1** (category (b), OPEN) —
     a runtime design-safety ambiguity for the collapsed sitting, not marker vocab.
   - **D4 (testing-philosophy) → deferred as a unit into TF2/TF3** — it *is* the Test-Fidelity
     investigation; ruling it here would rule it twice.
4. **Mop-up B-E** (prose, `c141d2b`+`b3bd3f9`+`aba6dad`) — 15 markers resolved, 3 kept for TF2;
   renamed `highlight_shape_spec`→`highlight_regression_spec`.
5. **Mop-up B-I/1** (fixture, `8bc066f`) — 6 markers; **RVW-003 escalated to gate-ledger G-2**.

## The two architectural finds (the session's real yield)
The noise-cleanup surfaced **two genuine category-(b) items**, both parked on the new
`validation/notes/collapsed-gate-ledger.md`:
- **G-1 — console-as-hidden-sink safety** (from D3): when a project runs and the widget is hidden,
  does the console silently consume/evaluate keystrokes? Doc-first disposition proposed.
- **G-2 — project-handler API asymmetry** (from RVW-003): mouse handlers are bare callbacks on
  `compy.<event>`; keyboard/text handlers are hooks under `compy.input.hooks[event]` seeded from
  `love.<event>`. Same act, two public shapes — a coherence gap. Unifying seam noted; mouse-side API
  was unexamined in #77 so it needs real judgement.

**Signal for the gate:** the collapse hypothesis (B/C/D fold into one sitting) is gated on "low
probability of a new serious finding." The sweep has now produced **two** such finds. Both are
containable with clear charters — not enough to un-collapse — but the collapsed sitting now has real
content to rule on, not rubber-stamps. Weigh at the gate.

## Non-obvious points for a successor
- **We are at the *beginning of TF2*, not past the A/R gate.** The marker triage is a sub-step *inside*
  TF2's opening. See the big-plan reconcile in the track. Owner: "clean code, all comprehensible and
  correct → TF2 closed; TF3 = LLM-side revalidation or discarded."
- **Cadence is strictly owner-gated, one batch at a time** (≤10 markers). Present concrete before→after
  drafts + recommended dispositions; get rulings; then apply (edit + inventory disposition + suite +
  commit). Never auto-advance to the next batch.
- **LSP still treated as second opinion; grep is completeness authority** (D5/D6 renames confirmed a
  cross-file method-ref miss). Carried from session18, still true.
- **Bookkeeping is load-bearing here** — every marker's disposition is recorded in the inventory, and
  the triage plan (`validation/reviews/S19-tests-triage-plan.md`) tracks batch progress. A wrap that
  skips these loses the thread (this session's first wrap attempt `086a66d` did exactly that and was
  corrected).
- **Line-number drift:** header edits shift marker lines; locate markers by content (grep), not by the
  inventory's cached line numbers.

## Where the successor resumes
**B-I/2** (RVW-026/080/083/084/085/090/091/094 — cursor + nfr + routing headers), **plus the folded-in
D1 leftover**: `input_routing_spec.lua:4-5` still carries the old `ROUTE=consumer … SINK=last consumer`
block D1 Pass B missed; B-I/2 already edits that header, so fix it there. Then B-F (structural,
decision-heavy) and B-COV (~22 coverage calls). Still parked beyond mop-up: D3/G-1, D4, G-2 (all for
the collapsed sitting / TF2-TF3); the `src/` marker sweep (RVW-115..138); the deferred vocab phases
(TD-actualize; reference-doc completeness). Batch map + counts in the triage plan; forward agenda in
the collapse-gate ledger.
