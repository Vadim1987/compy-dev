# session44 track

## 2026-08-16 — boot

- Fresh start: no prior `track.md`/`report.md` in `session44/` → re-entrance
  guardrail says begin the task and open the track.
- HEAD `8c0c410d` (docs(validation): refresh the boot ritual's fallback suite
  count). Working tree: only the known untracked scratch (`claude.sh`,
  `input-pr-slices.tar.gz`, `repos.txt`, `src/STEPS.md`, `worklog.md`,
  `src/examples/{balloons,keyboard,maze}`) — all sanctioned anomalies per
  `agents/validation.md` §Hard guardrails 3. Nothing of the owner's to protect
  beyond those.
- Suite: **968 / 0 / 0 / 10** — matches the prompt's authoritative number and
  the refreshed fallback in `agents/validation.md`. Ten pending are the
  owner-sanctioned set (3 routing-grid cells + 7 framework reserved combos).
- Read in order: `agents/validation.md`, `agents/sessions.md`,
  `session44/prompt.md`, `agents/rules/revalidation.md`, `session43/report.md`,
  P10/W9/W10 rows of `validation/reviews/S27-triage-and-plan.md`.
- Booted mandate as read: (1) revalidate Decisions 33 & 34 only — not the code,
  which had cold reviews; (2) P10's remainder in four members; (3) P11 only
  when the owner brings planning changes.
- Open question for the owner at report time: **W10 batch 2** (no historical
  contrast) — the P10 row's [S33] text lists batches 1/2/4 as remaining, the
  session44 prompt lists only batch 4. `S36-marker-disposition.md` routes batch-2
  material to P11/marker work, which would explain the drop, but it is not
  stated anywhere as ruled.
- Told the owner the task before proceeding, per their instruction.

## 2026-08-16 — task 1: Decisions 33/34 revalidation

- Owner: revalidate the decisions first, batch disposition after.
- Report: `validation/reviews/S44-decisions-33-34-revalidation.md`. Verdict
  **sound**, 7 findings — F1–F5 ledger corrections (owner-gated), F6–F7 corpus
  items for the docs rows.
- Both decisions genuinely rest on owner rulings — checked against session43's
  track at the ruling entries, not just against the entries' own claims.
- Code facts verified, not taken from the entries: `RESERVED` at
  `controller.lua:850-867`, never-consumes true in the flow (`:876-891`,
  `:899-905`), `f10` misses under any modifier via `combo_string`, scope clause
  holds (console debug hotkeys `:503`,`:520` still tolerant and route-level),
  `f31bd312` touches one file so "no test edited" is mechanical.
- **F1 is the one that misleads today:** Decision 34 amends Decision 30 point 3,
  and point 3 still says the table "is not committed to … may never be done".
  The ledger's in-place-amendment convention (D8←D31, D30p3←D32, D13/20/29
  headings) was followed everywhere else — broken exactly once, here.
- F2's provenance matters: the "third/fourth" miscount was *created* by
  session43's own correct fix (adding Ctrl+Shift+S to a three-item list). A fix
  that grows a list and leaves an ordinal behind.
- F6 was not in scope and is the more interesting one: `f31bd312` deleted
  `only_mods`, and the debt entry rewritten hours earlier still rests on it —
  "the one place that compares normalises with `not not`" now matches nothing
  (`grep` empty). Behaviour change documented; the neighbouring doc that
  depended on the deleted code was not.
- Nothing edited outside the report — the prompt says report, don't touch the
  ledger without the owner.

## 2026-08-25 — F1–F7 resolved

- Owner (after a gap): these are inconsistencies with unambiguous resolutions,
  not decisions to make — resolve and report. Wants the story finished, no
  ceremony, nothing important omitted.
- All seven applied in one commit; resolutions tabulated in §6 of the review.
  Docs only, suite still 968/0/0/10, no marker added (`git diff | grep '^+'`
  → zero INTERIM/REMARK).
- F1's note also disposes of F4's second half — one blockquote states both that
  the table is built and that the cascade the point describes is gone.
- Fixed one item beyond the seven and said so in the review: Decision 33 blamed
  maze's whole "Shift+Escape family" where only its two Ctrl-bearing members
  ever reached the reservation.
- Left Decision 6's "unconditional and unshadowable" alone — true in the sense
  it means, and Decision 6 is a W9(a) prune candidate.
- No wip path remains in the persistent corpus (`grep -rn P15` over doc/ minus
  wip → clean).
