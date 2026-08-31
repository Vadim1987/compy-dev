# session61 — track

## 2026-08-31 — boot

- Fresh start: no prior `track.md`/`report.md` in session61/ → §2 fresh-start branch.
- HEAD `74a5e8fb` (docs(session60): wrap). Working tree: only the known untracked scratch
  (`broken-busted/`, `claude.sh`, `input-pr-slices.tar.gz`, `repos.txt`, `src/STEPS.md`,
  `src/examples/{balloons,keyboard,maze}/`, `worklog.md`) — matches the guardrail list;
  `repos.txt` and `broken-busted/` are new since the list was written, noted, not touched.
- Suite: **1032 / 0 / 0 / 10** — matches the prompt's baseline. Go-signal.
- Read in order: `agents/validation.md`, `agents/sessions.md`, session61 prompt,
  `agents/rules/revalidation.md`, session60 report.
- Mode: **research + analysis** (revalidation). Task 1 = revalidate the `BUG-01` sprint one level
  up — delivery, re-framings, blast radius, ledger, arithmetic, scope. NOT a code review; the cold
  Opus review already ran (`validation/outcomes/BUG-01-sprint-peer-review.md`).

## 2026-08-31 — revalidation findings (reported, awaiting owner ruling)

**Clean, verified:**
- **Suite arithmetic reconciles exactly.** 1023 →25→28→30→31→32; the added `it(` per commit match
  (+2,+3,+2,+1,+1 = 9). `16726f81`'s widget-control edit is a **retitle**, not a case (1+/1-), so
  its "+1" is right. No docs commit touches `tests/`.
- **Ledger sections survived the `## BACKLOG` scar intact.** Diffed section membership
  `b5022530` vs HEAD: exactly the five ACTIVE→RETIRED moves + one new BACKLOG entry, nothing else
  crossed. ACTIVE = 3, all slugged, each naming a `FIX-02-*` revisit. BACKLOG = 42, **zero**
  slugged. Consistent with the slug convention.
- **The "by construction" retraction is complete in all three places** and says the same thing —
  roadmap `-11`, RETIRED `T-MAZE-NEUTRALIZE`, the weighing note's `## Correction`. (The debt entry
  says "not by *structure*" where the other two say "not by *construction*"; same claim.)
- **Both re-framings hold**, and the cold review reached each independently from code.
- maze `ISSUES.md` covers both defects; `FIX-02-09`'s widening is well recorded.

**Findings — corrections needed:**
- **A1 (worst).** `ui_messages.results` is recorded as *"deliberately NOT fixed … raised for the
  owner"* in **two** places — RETIRED `T-BALLOON-LABEL` last bullet, and the roadmap `-07` row.
  The owner reviewed it 18 min after the row closed and ruled *delete*; `c2bd9b9` did it. The
  debt register is what the PR description is written from, and balloons' PR carries a commit no
  ledger accounts for. The **report** ( §5) has it right; only the persistent corpus is stale.
- **A2.** `agents/validation.md`'s PERSISTENT DOCS CORPUS list omits `internals/text_encoding.md`.
  Indexed in `agents/rules.md`, absent from the list that governs "all spec refs resolve here".
- **A3.** ROADMAP suite row stale at **1030** (`:38` "where things stand", and `:609`). Actual 1032
  — the two peer-review commits added tests and the roadmap was not updated.

**Findings — owner ruling, not just a correction:**
- **B1.** **Case-insensitivity has no home in the decisions ledger.** `decisions/input.md` has
  **zero** mentions of case anywhere; Decision 8 defines canonical serialisation as fold-l/r +
  precedence + `+`-joined, never case. The guide now states the rule and a test pins it. The `-04`
  row's *"Decision 8 already ratified the rule"* overstates the text. Natural home: `DEC-01`.
- **B2.** **Six of the cold review's ten findings have no recorded disposition** — session60's
  track and report both say "four findings". F6 was fixed incidentally (verified: no >64-char line
  in the touched files is session60's; blame confirms). **F7 is real and I reproduced it**:
  `show{text={'a\nb'}}` → one line holding a raw `\n`, string form → two lines. Pre-existing at
  `3256aac` (base's table branch is `InputText(text)` verbatim), but the sprint's own fix put the
  asymmetry on a **documented** surface. Unfiled anywhere. F8 is covered in substance by
  `text_encoding.md`; F9/F10 are info, F10 an undocumented behaviour change in `tixy`.
- **B3.** `internals/user_input.md:107` says **three** call sites manipulate the cursor
  programmatically. There are **four** — `_apply_eval` (`userInputModel.lua:889`), the very site
  F3 is about. Pre-existing, but this sprint proved it and left the census standing.
- **B4.** F4's **doc half** was never dispositioned. `doc/input_api.md:205` still promises "Every
  cursor position …". I judge the sentence **stands**: the caret producer was fixed, and the
  remaining byte producer is the error *underline*, which nothing project-facing reports
  (`userInputView.lua:155-185` — `ec`/`el` only pick a colour). But the reasoning is on no disk.

## 2026-08-31 — owner rulings, and execution

**Two of my findings were wrong, corrected by the owner:**
- **The CHANGELOG, not the debt register, is what the PR description is written from.** A1's
  staleness was real; my reason for its weight was not.
- **A2 was invalid.** `agents/validation.md` is *never* supposed to name the persistent docs. The
  rule is **everything under `doc/` that is not under `wip/`**. So the fix was to replace the
  enumeration with the rule, not to add `text_encoding.md` to it. Enumerations in a governing
  file are the defect; the stale entry was only the symptom.

**Rulings taken:**
- **B1** — case-insensitivity was **always assumed**, obvious and practically universal for key
  bindings. It becomes a note on Decision 8 (which ratifies the whole combo mechanism), not a new
  decision. So the `-04` row's "Decision 8 already ratified the rule" is backed, not overstated.
- **F7** (owner wrote F6; F6 was a 69-char line, already fixed — everything else in the
  instruction fits F7, and I proceeded on F7 saying so) — **BACKLOG + dev-facing docs + open
  `BUG-02` referencing it**, the step opening with a fix-vs-postpone weighing, minimal outcome =
  the defect documented. Release-scope call deferred.
- **B4** — into the backlog entry.
- Everything else mechanical → applied.

**F10 answered and it is inert.** `tixy/examples.lua` defines 35 examples; every `code` is
`"r = " .. c`, single-line — all the `\n`s in that file are legends. Sweeping every
`compy.input.set_text` caller in the examples: three sites, and two already pass `string.lines(…)`
(the table branch, pre-split). Only `tixy/main.lua:39` passes a raw string, always single-line. **The
fix changed nothing observable on shipped data.** That sweep also bounds F7: `string.lines` never
emits an element containing a newline, so F7 needs a hand-built list. Worth one line in ACC-02's
smoke scope; not a persistent-corpus entry.

**F9 recommended skipped** — the two serialisation tests pin one half of an agreement and would
still pass if registration flipped; the end-to-end test covers the contract. Coverage shape, not a
gap, and `tests.md` documents pending rows and philosophy, not per-test shape.

**Eight commits**, `13d9dd33`..`34b9c40d`, suite 1032 green at each. One thing caught in flight:
I first cited `text_encoding.md`'s byte-offset section by a name it does not have, and checked the
headings before committing — the exact failure the citation rule exists for.

**Minor:** `FIX-02-09`'s note says `input_api.md` carries "eight" *field*s — it carries **13**, all
the widget sense · claimed reach "four production files, six spec files" is **3 and 5** ·
`user_input.md:100` cites `userInputController.lua:124-139` for `set_cursor_pos`, now `:195`
(already stale at `b5022530` — FIX-01 territory, not the sprint's) · the new wip citation in the
debt register (`71ef4632`) increments `FIX-01-02`'s "~12 sites" sizing.
