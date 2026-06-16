# Round-2 Evaluation — Coherence & Requirements Check

*Checks that the solution chain remains coherent and still meets
requirements after the round-2 changes tracked in `track00.md`. Scope:
`requirements.md`, `decisions.md`, `design.md`, `spec.md`, `roadmap.md`,
and their `summaries/`.*

---

## 1. Did every change land consistently across the chain?

| Change | decisions | design | spec | roadmap | requirements | summaries |
|---|---|---|---|---|---|---|
| C1 `show()` force flag | D-2 + glance | §3 row ok (no in-place claim) | §2 show/§7/access-note | M2 + tests | — | decisions, spec |
| C2 boundary extension | D-5 + glance | §3 row + §7 ×2 | §4 | M6 + tests | §5 resolved | decisions, design, roadmap |
| C3 rename | all mentions | all + rationale | all | all + file | — | all four |
| C4 proxy read-index | — | §3 | §1 | M1 (noise) | — | spec |
| C5 D-4 gloss | D-4 question | — | — | — | — | — |
| C6 D-3 scope | D-3 | — | — | — | — | — |
| C7 D-7 + touch | D-7 | §1 touch | — | — | §4 touch | — |
| Estimates | — | — | — | tables + delta | — | roadmap glance + README |

Verification sweeps run (see `track00.md`): no `ProjectController`
word-token remains in the chain except the deliberate naming-rationale
note; no `on_limit_reached(direction)` single-arg form remains except
inside D-5's explicitly-superseded "original" text; the only `≈ 63 h` /
`≈ 37 h` strings left are the round-2 delta notes that compare against the
old totals on purpose. **Consistent.**

---

## 2. Requirements still met?

- **FR-1…FR-4 (setup / lifecycle).** Intact. C1 changes only the
  *re-`show()`-while-active* default (now a no-op unless `force`); the
  mid-run prompt/validator/highlighter change that FR-3/FR-4 motivate is
  served by `configure()`, which is unchanged. No requirement regressed;
  the path is just stated explicitly (configure for live change, `force`
  for deliberate re-activation).
- **FR-5 / FR-6 (submit / key events).** Unchanged by round 2. D-4's
  named chains stand; the round-2 edit only glosses the "framework's own
  teardown" wording. D-3/D-6 pass-through-plus-improvement framing
  ratified, no surface change.
- **FR-7 (boundary notification).** Strengthened. Previously satisfied for
  vertical whole-input only; now covers vertical *and* horizontal, at
  whole-input *and* line scope — a strict superset. The §5 open question
  on multiline boundary granularity is now resolved rather than deferred.
- **FR-8 / FR-9 / FR-10 (cursor/text).** Untouched by round 2.
- **FR-11 (REPL expressiveness).** Still met; D-7 reaffirmed
  project-first. The forward note (REPL run path converging on the project
  path) is directional only and pulls no migration into scope.
- **FR-12 (editor expressiveness).** Improved. The editor's caret-edge
  and line-boundary navigation are now directly expressible via
  `on_limit_reached(direction, scope)` with `left`/`right` and `'line'` —
  closer to the editor's real navigation than the vertical-only hook was.
- **NFR-1…NFR-4.** Unaffected. The read-indexable `keys_pressed` proxy
  (C4) keeps the read-only / no-tamper guarantee (NFR consistent), and is
  more ergonomic (`proxy[k]`), which mildly helps NFR-4 (pedagogical
  usability). No allocation, event-model, namespace, or naming convention
  changed.

**No requirement regressed; FR-7 and FR-12 are better served.**

---

## 3. Internal coherence — points checked

1. **`show()` block vs `configure()` live-update.** No contradiction: the
   two paths are now cleanly separated (re-activation = `show` + `force`;
   live field change = `configure`). The spec §2, §7, and the access-
   control note all agree. ✔
2. **Boundary second argument.** Was "reserved, undefined in v1, do not
   use"; is now `scope` with a defined v1 meaning. Every mention
   (decisions D-5, spec §4, design §3/§7, summaries) carries the
   two-argument `(direction, scope)` form. No stale single-arg signature
   in live text. ✔
3. **`is_at_limit` reuse.** The vertical whole-input semantics the editor
   block-navigation depends on (`editorController.lua:511-512`) are
   explicitly preserved; horizontal + line scope are additive. Roadmap M6
   risk note flags keeping the existing semantics intact. ✔
4. **Rename collision.** `ProjectInputController` vs the pre-existing
   `ProjectService` — distinct names, distinct roles; the rename's whole
   point is to remove the create/delete connotation. No collision with
   `ConsoleController` / `EditorController` siblings. ✔
5. **Proxy contract.** Read-indexable + write-blocked still prevents
   tampering with live modifier state (the original rationale), so the
   combo-serialisation and modifier-context guarantees downstream are
   unaffected. ✔
6. **Estimate arithmetic.** Both PERT tables recomputed; row PERTs sum to
   the stated totals (66 h without LLM, 39 h with). README range updated
   to ~39–66 h. ✔

---

## 4. Open / deferred (carried forward, not blocking)

- **`force` semantics vs ownership.** `force` opts past the
  *active-session* block but not past *ownership* (access control remains
  unenforced — spec §2). Recorded as the same known future concern as
  before; round 2 does not change that posture.
- **`'line'` scope precision in wrapped display.** D-5 defines `scope`
  against *source* lines (consistent with the 2D cursor contract D-8);
  behaviour at soft-wrap boundaries is implementation detail for M6, not a
  spec-level open question. Worth a confirmation during M6, noted in the
  roadmap risk line.
- **Refinement during implementation (D-4).** The stakeholder expects the
  submit/cancel chains to be refined while building; the contract is
  stable enough to start, details may settle in M6.
- **Notes / validation folders.** `notes/` still say `ProjectController`
  in places; they are supporting analysis, not the authoritative chain,
  and `validation/` is dated review history left intact on purpose. If a
  fully self-consistent snapshot is wanted, a later mechanical pass over
  `notes/` can align the name — flagged, not done here.

---

## Conclusion

The chain is coherent after round 2. No decision was reversed; the changes
are one default flip (C1), one capability extension (C2), one rename (C3),
one proxy widening (C4), and three clarifications (C5–C7). All twelve FRs
and four NFRs remain satisfied, with FR-7 and FR-12 better served than
before. Estimates rise ≈ 2–3 h (≈ 66 h / ≈ 39 h), concentrated in the M6
boundary work and its tests. Ready to proceed on the same milestone
structure — no reordering, no milestone added or removed.
