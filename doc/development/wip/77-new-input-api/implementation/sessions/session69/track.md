# session69 track

## Boot (2026-09-03)

- HEAD `1a864137` (`docs(session68): commission the delivery-level review — step 3 of the closing order`).
- Working tree: two untracked S68 closing artifacts (`validation/outcomes/S68-cold-peer-review.md`, `validation/reviews/S68-delivery-revalidation.md`); known scratch left alone (`claude.sh`, `src/STEPS.md`, nested examples, etc.).
- No prior `session69/track.md` — fresh start.
- Predecessor track ends at `FIX-02-05` / `CHG-01` complete / F2 nearly missed; **no entries for the peer review, wrap, or delivery commission** (S68 delivery review F1).
- CURRENT PROMPT pointer matches `session69/prompt.md`.
- Owner instruction this turn: housekeeping first — commit the two untracked S68-review files file-by-file, then apply the delivery review's corrective actions. Ask if unsure.

## S68 delivery review as received (2026-09-03)

Read `validation/reviews/S68-delivery-revalidation.md`. Verdict: seven findings, none blocking; dispositions table promised by `session69/prompt.md` is **not in the file**. File ends at F5. Findings present:

- **F1** — peer review of record untracked; wrap carried no track. Propose: commit the file, late-record the track, one line on `session69/prompt.md`.
- **F2** — `get_text()` has no smoke/example coverage while `FEAT-03` claims `ACC-02` exercises it. Propose: checklist row + soften the claim; **question for owner**.
- **F3** — `LEDGER-02` still sized on superseded 56/47 counts.
- **F4** — five unwalked entries dispositioned in a retired entry; carry into `LEDGER-02-01` (folded into F3c).
- **F5** — `FEAT-02` and `FEAT-03` both claim "last surface change".

Conflict: F1 wants a line in the booted prompt; `agents/sessions.md` says never edit a booted prompt. Will ask.

## Owner rulings on the S68 delivery review (2026-09-03)

1. Reviewer was interrupted. Add an **optional** operational roadmap step to re-review S68 and recover the missing findings; it does **not** block the release.
2. F1 note is **track-only** — do not edit the booted prompt.
3. `get_text()` shipped when the ask was to file it as debt. Update `doc/input_api.md` so it does not go unnoticed: delivered prematurely, **experimental**, may be withdrawn unless needed. **No smoke-testing.**
4. F5 wording: *"until `FEAT-03`"*.
5. Apply F3–F5 now, one by one, small incremental commits.

Housekeeping already landed: `d8468910` peer review of record, `3be6da02` delivery review.

## Dispositions executed (2026-09-03)

F1 remainder: late-record on `session68/track.md` (`e298d60c`); note stays in this track, prompt untouched.
F5: `f8dac501` — "until `FEAT-03`".
F3a: `a3d7c876` — `T-NEVER-SHIPPED` Where is 61.
F3b: `1d268e9d` — 47/14/7 replaced with the 39/9/5/3 classification.
F4: `6e636f7a` — `LEDGER-02-01` carries the five unwalked.
F2 as ruled: no smoke. `38a40b4b` marks `get_text()` experimental in `doc/input_api.md` and CHANGELOG; `bacc0f24` records it on `T-CONTENT-READ`; `45bec9df` drops the `ACC-02` claim.
OP-02: `0a5c44c1` — optional, not in the release sequence.

Next: `FIX-01` as the prompt says, after the owner is happy with this pass.

## Re-entrance — second incarnation (2026-09-03, Claude/Opus after the Cursor-led run died)

Track was stale by one commit and one working-tree edit. Reconciled against `git log` + tree:

- `9eb91de2` (not in track) — `FIX-01-01` re-derived. The "eight" is **three live sites**:
  R091+R092 (`decisions/input.md`, `D-TWO-SURFACES` Why), R150 (`internals/user_input.md`, the
  Search paragraph), R164 (same file, the restated API). Four were already paid by later passes
  that never ticked the row; R100's residue is `DEC-02`'s. Enumeration:
  `validation/notes/FIX-01-01-enumeration.md`.
- Uncommitted `decisions/input.md` — the R091/R092 rewrite, mid-flight, unwrapped. Verified
  against the two REMARKs it answers, re-wrapped to the file's column, committed as `ddcdd936`.
- Suite confirmed at boot: **1055 / 0 / 0 / 10** (LuaJIT 2.1, container).
- Untracked `broken-busted/`, `repos.txt`, `worklog.md` are owner scratch — left alone.

Remaining in `FIX-01-01`: R150, R164. Then `FIX-01-02` (re-derive, do not trust ~12) and
`FIX-01-03` (4 sites).

## `FIX-01-01` — complete (2026-09-03)

Three commits, one per site: `ddcdd936` (R091+R092), `cd420088` (R150), `5dd9e455` (R164).
Roadmap ticked and note updated at `733b56b5`.

- R150's rewrite **found a false claim** the reflow would have kept: the paragraph said
  `SearchController` calls its instance's `textinput`; it calls `add_text`. Answering a remark
  re-reads the code, and that is where the yield was.
- R164 **kept both headings** (`show(config)`, `configure(config)`) though the merged treatment
  read better — ten live citations name `configure(config)` as a section (2 in `src/`, 7 in
  `tests/`, 1 in the debt register), and an editorial row should not buy a heading with a comment
  sweep across `src/` and `tests/`.

## `FIX-01-02` / `-03` re-derived — and a fourth class (2026-09-03)

Note: `validation/notes/FIX-01-02-03-rederivation.md`, commit `461b4489`. Four classes:

- **A** ephemeral paths — **20** sites, not ~12. The old count was a `wip/` grep and eight are
  written **relative**. Five of the twenty are debt entries whose *subject* is a wip file →
  `LEDGER-02`'s, not repointing work.
- **B** session numbers — **12**, not 4. This session added one of them.
- **C** `FR-n` — 7 sites; two are the owner's own REMARKs, so answering them clears the markers.
- **D** citations of **live roadmap ids** — **119 occurrences**. No row owns it, no convention
  bans it, it is not `FIX-03-05` (which wipes *retired* ids), and `LEDGER-02`/`DEC-02` are about
  to delete some of the prose carrying it. **Left for the owner with a recommendation, not taken.**

A/B/C are uncontested and are `FIX-01-02`/`-03`'s work. **Raised with the owner before executing**:
whether D is in scope at all.

## Owner ruling on class D, and `FIX-01` closes (2026-09-03)

**Ruling: rule now, sweep after the ledger vacuuming.** Landed as three commits — the convention
(`c9f765e7`), the debt entry `T-EPHEMERAL-IDS` (`61c66ba3`), the roadmap step `DOC-01-06`
(`e3b8b1af`). **`DOC-01`, not `FIX-03-05`:** that row is the retired-id sweep and runs *before*
`DEC-02`/`LEDGER-02`, which vacuum the two registers holding 94 of the 119.

Then executed: `5d8ae109` (B, 12 sites), `ab8c2415` (A, 14 of 20), `6c96c96f` (C, 7 sites,
**spelled out rather than dropped** — the remark asked for the essence, not the deletion).
`b4968192` ticks `FIX-01` complete in all three places and empties the brace.

- **Six path sites stayed and were handed to `LEDGER-02`** — `general.md`'s two renumber entries,
  where the wip file **is the defect's location**, not a reference. No canonical target exists and
  repointing would destroy the entry. Recurring shape; named in `LEDGER-02`'s section.
- `smoke_checklists.md` got *better*, not merely correct: every section already carried a
  *"the N commits a result should be reported against"* table — durable and specific — so the wip
  pointers were a second, worse answer to a question the document had already answered.

## Owner question — the 31 REMARK mentions (2026-09-03)

Counted at boot and at HEAD, so the delta is attributable: **29 markers across 10 files at
session69's boot, 24 now**, all five retired by `FIX-01-01`. `src/` and `tests/` return **nothing**
for the gate pattern. **The five under `src/examples` are not markers** — they are Alice prose in
`keyboard/words_corpus.lua` (*"she remarked"*), which is exactly why `agents/rules/commenting.md`
makes the pattern case-sensitive. The row is **`FIX-02-07`**, in `FIX-02`'s **(b)** half → after
`ACC-02`. Cell recounted at `7c7cf6d2`, with the shape stated: **the count only ever falls by side
effect**, since a marker retires with the pass that fixes what it points at.
