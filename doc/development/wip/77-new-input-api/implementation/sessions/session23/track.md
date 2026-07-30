# session23 — track

## 2026-07-30 — boot

- Booted per `agents/validation.md` (boot ritual), `agents/sessions.md`,
  `agents/rules/revalidation.md`. Re-entrance guardrail: no `track.md`
  and no `report.md` in `session23/` → **fresh start**; this entry opens
  the track.
- HEAD `2942147` (`docs(session22): wrap pre-TF2 gates`). Working tree
  carries only the sanctioned untracked scratch (`claude.sh`,
  `src/STEPS.md`, `input-pr-slices.tar.gz`, `src/examples/*`,
  `doc/development/wip/{clarification,personal-notes,pull-26}`,
  `doc/tall_blocks.md`) — guardrail 3 anomalies, left alone.
- Read: `agents/validation.md`, `agents/sessions.md`,
  `agents/rules/revalidation.md`, `session23/prompt.md`,
  `session22/{prompt,report,track}.md`.
- Task: delta revalidation of session22's pre-TF2 gate work
  (C1 authority integration, J1 plain-vocabulary cleanup, persistent
  contract corpus, code/test alignment, TF2 navigation slices), written
  to `validation/reviews/S23-revalidation-pre-TF2-gates.md`. Expected
  suite: 862 / 0 / 0 / 3. Stop for human acceptance before TF2.

## 2026-07-30 — baseline confirmed; two Sonnet audit legs opened

- `busted tests` → **862 / 0 / 0 / 3**, matching the prompt exactly. The
  three pendings are the documented ones (console key release, editor
  pointer, project-run touch), all in `tests/input/input_routing_spec.lua`.
- Delegated the two mechanical legs to Sonnet workers (token-economy
  charter; prompts of record under `validation/prompts/`): the J1
  marker/corpus sweep and the TF2 slice-partition verification. Both are
  read-only, each writes one named outcome under `validation/outcomes/`.
- Kept the judgment core in-session: persistent-corpus authority vs. the
  code, i.e. whether C1's "the persistent docs are the #77 contract" ruling
  actually propagated into the tree.

## 2026-07-30 — finding: the code→doc reference layer was never reconciled

- Verified `show`/submit/helpers against code: `SHOW_KEYS` matches the
  guide's table exactly; `reject_unknown_show_keys` warns + drops;
  submit order is before_submit → empty guard → validator → on_text_entered
  → after_submit; `LuaHighlighter`/`LuaSyntaxValidator`/`LineValidators`
  exist and are seeded into the project env. **Contract text is accurate.**
- But the *citations* into that contract are not. Wrote a resolver
  (`scratchpad/refcheck2.lua`) over every quoted `doc/…md, "Section"`
  citation in tracked `src`+`tests`: **8 section names cited that do not
  exist**, across **22 sites in 8 files**. Worst two are semantic, not
  cosmetic: `"Submit and cancel — the framework submit chain"` /
  `"— the framework tier-1 chains"` reassert the **superseded** framework-tier
  model that Decision 6 revised replaced with widget-owned flows.
- Separately: 13 comment blocks in 7 tracked files (incl. **4 shipped
  examples**) still cite the deletion-gated `wip/77` tree. Both
  `conventions/code.md` (L87) and `technical_debt/input.md` ("Comment
  wip-citation cleanup") record this as **"two `src/controller/` comments"**
  — the persistent corpus understates its own known debt by ~6×.
- `src/main.lua:355` still carries a `RESOLVED-BY-REDESIGN` marker with
  "R4-1 inventory" phrasing, although `e28f58d` (J1 source pass, which
  claimed "no source marker remains") touched that very file.
- `tests/input/.input_nfr_forward_spec.lua.swp` — a tracked **vim swap
  binary**, ADDED inside the #77 diff by `64e5af4`. Session22 declared it
  out of J1 scope; as PR content a reviewer sees a binary blob.
- All four are findings for the owner, not unilateral fixes.

## 2026-07-30 — both audit legs landed; claims verified in tree

- Slice audit: partition is genuinely CLEAN (8 slices, 89 files, complete +
  disjoint, arithmetic confirmed; reviewable set identical at `4c002e8` and
  HEAD; `16546af` lands *inside* the excluded wip tree, so doubly out of
  scope). Its one finding is strong and I re-verified it myself:
  `3d-tests.patch:909-912` carries the `.swp` as a payload-less
  "Binary files … differ" hunk → **`git apply` refuses the whole slice**.
  Session22 only diffed name lists, never ran `apply --check`.
- Marker sweep: J1's two commits are comment-only within their diff scope
  (verified). Residue it found and I confirmed in tree:
  `tests/editor/editor_spec.lua:712` (`S21/B-F`) — a *scope* miss, that file
  was outside both J1 commits; `technical_debt/input.md:243` cites
  `tests/input/overlay_spec.lua` which **does not exist**;
  `decisions/input.md:257` rests a withdrawn-guarantee justification on
  `design/requirements.md`, which resolves **only inside wip/77**.
- **Overruled the sub-agent on one framing:** it flagged 23 bare `#77`
  citations in persistent docs as residue. `#77` is a GitHub issue number —
  permanent, public, resolvable after wip deletion. Correct thing to cite;
  not a finding. Same for the literal wip path at `technical_debt/input.md:570`
  (that entry's whole subject *is* wip citations). Kept `TF1` / `M8-03` /
  `0.1.0-m8` as minor, since those are internal batch labels.
- Review written to
  `validation/reviews/S23-revalidation-pre-TF2-gates.md`: verdict NOT CLEAN
  (accept with corrections), 5 findings, 4 ordered dispositions, none
  executed. Awaiting owner acceptance — TF2 not opened.
