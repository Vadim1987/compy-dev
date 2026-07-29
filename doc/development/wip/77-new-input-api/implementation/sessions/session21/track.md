# session21 — track

## 2026-07-29 — boot

- Booted per `agents/validation.md` (boot ritual) + `agents/sessions.md`. Re-entrance guardrail:
  no `track.md`/`report.md` in `session21/` → **fresh start**; this entry opens the track.
- HEAD `611a1d4` ("docker tweaks", owner's — not ours). Last ours: `6b369fa` (session20 wrap),
  `e254ae7` / `8a6e95b` (B-I/2 + version-tag migration).
- Tree: only the sanctioned untracked scratch (claude.sh, `implementation/ses/`, wip/clarification,
  wip/personal-notes, wip/pull-26, doc/tall_blocks.md, input-pr-slices.tar.gz, src/STEPS.md,
  src/examples/*, tests/editor/editor_spec_fwd.lua, a stray `.input_nfr_forward_spec.lua.swp`).
  No unstaged modifications.
- Suite: `busted tests` → **841 / 0 / 0 / 4** — matches session21/prompt.md's baseline. (Note:
  `agents/validation.md` boot step 6 still says 815 — stale line in the workflow doc, not a
  finding about the tree; flag to owner.)
- Read: validation.md, sessions.md, session21/prompt.md, session20/report.md,
  rules/revalidation.md, `validation/reviews/S20-version-tag-migration-key.md`,
  `validation/notes/collapsed-gate-ledger.md`.
- Owner asked for a boot brief before work starts → Part 1 (revalidation of the S20 version-tag
  migration) not yet begun; awaiting go.

## 2026-07-29 — owner input (post-brief)

- **REVALIDATION HINT (owner, carry into Part 1):** owner is *surprised* that "almost nothing
  earned a `since` tag" (S20 report / migration-key net claim). Part 1 must not just check the
  transformation's internal consistency — it must **check the tag calibration outward**: is
  genuinely feature-new coverage actually marked as such? i.e. verify against the `updev`
  pre-feature baseline (+ `doc/input_api.md`'s existing `since 1.0.0-rc20260712` surface) that the
  untagged-because-pre-baseline verdict holds per group, and that no feature-new behaviour was
  silently left untagged. Treat "almost nothing is new" as a *claim under test*, not a premise —
  it is exactly the kind of verdict that, if wrong, propagates (revalidation.md §5 under-done).
- Owner flags **taxonomy sprawl**: ad-hoc validation milestones (phases + batches + sub-batches)
  feel like an unbounded spiral. Asked for a flat remaining-steps-to-PR list. Answered in-session
  from `validation/plan.md` (phases TF2→TF3→gate→B/C/D→E→F→G) + the collapse hypothesis; the
  self-generated part is the marker mop-up (B-F, B-COV) inside TF2's opening — the only work not
  in plan.md, and the natural place to cut scope if the owner wants to shorten the path.

## 2026-07-29 — Part 1 (revalidation) DONE, report on disk

- Report: `validation/reviews/S21-revalidation-version-tag-migration.md`. Verdict: migration
  substantively sound + correctly executed *within the scope it took*; scope itself never ruled.
- Verified in code (not trusted): `controller.lua:21` get_user_input → nil under inspect;
  `consoleController.lua:1017` suspend → app_state='inspect' + save_user_handlers +
  set_default_handlers; env selection 865/873/934. S20's "reworks the suspend/inspect spine"
  claim is TRUE → carve-out is the right call.
- Clean: zero `Bucket` refs; RVW-085 carve-out coherent (test ↔ tech-debt ↔ inventory);
  wip-citation discipline HELD (the 2 hits are the rule's own anti-pattern + the debt item, not
  citations); inventory + triage-plan bookkeeping matches the tree.
- Findings: **F1** lowercase "this bucket's" (nfr:217); **F2** nfr file head (L1, 16-19) still in
  retired vocabulary ("forward contracts"/"provisional"/"expected to change") — contradicts its own
  describe; **F3** G-1 ledger row stale (last touched 8bc066f) — S20's code-verified evidence +
  RVW-111 scope narrowing + tech-debt entry unrecorded on the living agenda; **F4** (owner's hint,
  substantive) the `since` branch never exercised — 0 hits in tests/, while input_api.md tags the
  whole compy.input surface feature-new and 13/20 tests/input files are new vs devupstream → the
  S20 claim is true-within-scope but "untagged" now means two different things; **F5** `SINK = last
  consumer` retired in routing only, 5 sibling files stale (half-migrated, from 8a6e95b);
  **F6** 2 dangling spec cross-refs (pre-existing → B-F).
- Awaiting owner: F4 ruling ((i) record the scope limit vs (ii) one availability line per input
  spec head — recommended (ii)); go-ahead to apply F1/F2/F3 (+F5).
- **Owner ruled: apply F1/F2/F3/F5.** Done + committed `96d1c78`, suite 841/0/0/4, grep confirms
  zero `bucket` (bar the RVW-076 marker text) and zero `SINK` in tests/. F2 kept the "named
  milestone" phrasing deliberately so its REVIEW/recheck marker stays live for B-F.
- **F4 still open** — owner asked for it re-explained in plain language before ruling. Behavioural
  note: owner consistently pushes back on jargon-shaped explanations and on unbounded process
  nesting; wants the *decision*, plainly, not the taxonomy around it.
- **Owner RULED F4 = (ii)** after the plain-language re-explanation. Executed: one
  `-- Availability:` line at the head of all **20** files in `tests/input/`. Classified by
  BEHAVIOUR, not file age — verified against `devupstream` (`compy.input`/`keys_pressed`/
  `combo_string`/legacy `solicit*` = 0 hits pre-feature; `singleclick`/`project_open` present
  pre-feature; `highlight.hl` fix landed in-feature at `1a2a9a3`). Non-obvious calls: new-to-repo
  files asserting pre-baseline behaviour (`input_routing`) stay untagged; the pre-existing
  `user_input_model_spec` gained one feature-new group; `input_shortcuts_click` is genuinely mixed
  (incl. legacy globals **removed in** the anchor version). Rule + full table recorded as the S21
  amendment in `S20-version-tag-migration-key.md`; per-group/per-test tags stay prohibited.
  Suite 841/0/0/4. Commit below.
