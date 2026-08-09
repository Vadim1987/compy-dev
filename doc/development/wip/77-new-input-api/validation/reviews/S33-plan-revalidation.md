# S33 — revalidation of session32's plan actualisation

**Material under review:** `S27-triage-and-plan.md` **§11** (the item-by-item walk, the P14
rows, the design-fork evidence, the debt-register enumeration) and the cross-links session32
added to `../plan.md`.
**Governing rules:** `agents/rules/revalidation.md`, all six checks, plus the red-flag
checklist in `agents/validation.md` § *Replanning always starts with evaluation of the
findings* (session32 was analysis-heavy, so that checklist opens this one).
**Cold check commissioned:** `../prompts/S33-p14-citation-verification.md` (Sonnet,
read-only) → `../outcomes/S33-p14-citation-verification.md`. Every load-bearing claim it
returned was re-verified here in code before being carried into this document; two of its
findings were extended by that re-verification and one of my own earlier claims was
**refuted** by it (noted at the end).

**Verdict: the plan is sound in substance and defective in navigation.** No disposition in
§11 is wrong on the merits. What is wrong is that §11 was written against a table that had
gone stale, re-lettered mid-session without a sweep, and never propagated back into the
document a executor actually reads. Eleven findings, four of them worth acting on before any
execution starts.

---

## Check 1 — intent reconstruction

Session32 was commissioned to **recheck Decision 30 before anything was built on it, then
replan the surviving plan against it, item by item**, with "likely dissolved" treated as a
per-item hypothesis rather than a licence to discard. Both halves were performed; the ruling
survived; four owner rulings shaped the result.

## Check 2 — intent vs outcome (the weighted check)

The owner named the form: **the plan's intents against session32's report.** The report says
what the session believed it was doing; the plan is what executes. Four divergences, in
severity order.

---

### F1 — the obligation session32 created rests on a row that session28 had already retired

**This is the finding that changes work, and it inverts the concern the commission carried.**

§11.3's P8 row says its **nine** remaining ids (R057, R074, R078, R079, R047, R063, R064,
R069, R075) need a per-id check against Decision 30 — *"not performed this session, and
explicitly not assumed"*. That was the right instinct applied to the wrong input.

**§6 amendment 1 of this same document** (session28, 2026-08-07, `:688`) reads:

> **P8 marked done.** R047, R063, R069 answered; R057 landed as three named surfaces;
> R064/R074/R075/R078 landed as the merge (four input specs → two)

That discharges **eight of the nine**. The ninth, **R079**, is separately and explicitly
held open — `S28-merge-plan.md:170`: *"`project_open_liveness_spec.lua` | — | unchanged
pending R079 (open ruling)"*. Both cold reviews of that work are on disk
(`../reviews/S28-merge-plan.md`, `../outcomes/S28-merge-result-review.md`).

**But §4's P8 row was never edited.** §6 opens by asserting *"the phase table above is the
running plan and is amended **in place**"* — and the amendment was announced without being
applied. The row still reads "**Left:** R057, R074/R078/R079, R047, R063, R064, R069, R075"
and carries **no `[S28]` marker**, while the four rows session32 touched later all carry
`[S32]`.

**Consequence.** Session32 walked §4 item by item, read the unamended row, and reproduced all
nine — into §11.3, and into `../notes/S32-plan-map.md:74`, **the map the owner read before
ratifying the plan**. The obligation as ratified is therefore calibrated to nine ids when the
evidence on disk says the answer is **at most one**.

**Fair statement of what is and is not verified here.** Verified: the §6-vs-§4 contradiction,
the R079 carve-out, the existence of the executed merge and its two reviews. **Not** verified:
that each of the eight asks is discharged in the current tree — that is the per-id check
itself, which survives as a real task but is now a small one: *confirm the eight, then rule on
R079.* The check is not a phantom; its **size** was.

**Correction proposed.** Amend §4's P8 row in place with an `[S28]` marker recording what
amendment 1 discharged and that R079 alone remains pending a ruling; amend §11.3's P8 row to
point at R079 rather than at nine ids. **Owner-gated** — it revises a disposition the owner
ratified.

---

### F2 — §11.3 still speaks the pre-ruling lettering, and it now contradicts §11.4

Mechanism established in git, not inferred. In `24170aec` the new rows were lettered
**P14a** docs / **P14b tests** / P14c code / P14d examples / P14e debt register. `d348b505`
re-lettered them, and says so in its own message:

> Rows re-lettered accordingly: P14a docs+debt, P14b design ruling, P14c tests, P14d platform
> code, P14e examples.

The re-lettering was applied to **§11.4 and §11.5** and **§11.3 was left untouched**. Four
references survive at the old lettering, every one of them meaning *the tests step*:

| line | text | means | reads as |
|---|---|---|---|
| `:942` | "test-restructuring territory that **P14b** now also touches" | P14c | the design ruling |
| `:942` | "owed before **P14b** starts" | P14c | the design ruling |
| `:945` | "**P14b** moves and deletes test cases" | P14c | the design ruling |
| `:945` | "re-check … after **P14b**, not before" | P14c | the design ruling |

**Not cosmetic.** P14b is **deferred by owner ruling** ("raise it when it actually blocks").
As written, §11.3 gates P8's owed check on a step that may not start for a long time — while
§11.4's unblocked list (`:966-969`) names that same check as proceeding **now**. The two
subsections contradict each other under the current lettering and agree under the intended
one. P9c fares worse: "re-check after the design ruling" would have it run against a tree
where no test case has moved, which is precisely when the check finds nothing.

Session32's own successor prompt says **P14c** in both places. Report and plan diverged, and
the plan is what executes.

**Correction proposed.** Four token replacements in §11.3, `P14b` → `P14c`. Mechanical
restoration of `d348b505`'s stated intent; I can apply it on a word.

---

### F3 — §4's table was annotated selectively, and P14 is not in it at all

§4's table is described as the operative plan and has been since session27. Session32's
`[S32]` markers landed on exactly the four rows that **lost** work — P9d, P9e (withdrawn),
P12 (promoted), P13 (reduced). The four rows that **gained** work carry no marker:

- **P8** — a per-id check now owed (and see F1);
- **P9c** — its timing moved (re-check only after the tests step);
- **P10** — grows, and its Decision-30 slice is pulled out into P14a;
- **P11** — the comment gate is currently failing (22 platform + 5 examples).

And **P14a–e do not appear in §4's table**, nor does the probe deletion, which §11.4 places
"outside P14" in prose with no id and no row.

The commission asked whether P8's owed check is "visible enough to survive a handover."
**Answered: no** — and the same answer covers P9c, P10, P11 and P14. A cold executor reading
the operative table sees none of it; all of it lives 350 lines further down.

**Correction proposed.** Annotate the four rows with `[S32]` pointers to §11.3, and add P14a–e
plus the probe deletion to §4's table (or, at minimum, a pointer line beneath it). Keeping two
tables in sync is what produced F1 and F2; one table with pointers is the cheaper discipline.

---

### F4 — `plan.md`'s Phase U still asks a question the same session answered

`../plan.md:344-347` reads: *"**Still to be dispositioned (session32):** … Whether P13 follows
P12 up to this phase, survives in the spinoff, or dissolves is an **open item for the
session32 replan**."*

`d348b505` closed it: **P13 is reduced to revalidation and stays in the sprint.** Session32
edited the parent plan, then ruled on the parent plan's own open item, and did not go back.
(Revalidation check 2d, exactly.)

**Correction proposed.** Replace the bullet with the ruling. Mechanical; I can apply it on a
word.

---

## Check 3 — consistency

**Applied uniformly? No — and both failures are the same failure.** F1 (session28 announced an
amendment it did not apply) and F2 (session32 re-lettered without sweeping its own §11.3) are
one pattern: *the document is amended in one place and read from another.* F3 is the standing
condition that makes it costly. This is worth naming as a working rule rather than three
separate fixes — **when a row is amended, the amendment goes in the row.**

Cleanly consistent: the P14 lettering within §11.4/§11.5; the withdrawal marks on P9d/P9e; the
tombstone discipline (Decision 30's rule 3 softened in place by `36de0eaa`, never renumbered);
the three-way id agreement between §11.3, §4 and Appendix A (9 + 7 = 16, verified — the lists
agree with each other perfectly, which is *why* F1 went undetected: they are all consistent
copies of the same stale row).

## Check 4 — integrity

Nothing dispositioned in §11 was dropped or distorted; every §4 row is walked; all ten `../`
links in §11 resolve. Two integrity gaps:

**F5 — a report-level insight that reached no plan row.** Session32's report closes with *"the
comment-bloat subset (~50 ids) inside W10's block of 92 is **never separately enumerated** and
must be re-derived before P11."* The plan says "~50 remarks" (`:464`); P11's row says nothing.
The report is a session artifact; the plan is what the P11 executor reads.

**F6 — nothing schedules the internals backfill.** P14a defers the shape-dependent internals
passage by writing "to the level of *the matcher reads the device*"; P14b resolves the shape;
no row commits to writing the concrete shape back into `internals/user_input.md`. P10's
remainder (W9 ledger + W10 batches 1/2/4) does not cover it.

## Check 5 — calibration (under-done vs over-done)

**Over-done: F1** — a nine-id obligation where one id is owed.

**Under-done: the citations were inherited, not verified.** The cold check found **eight wrong
citations**, six of them execution hazards because they name ranges a future session will
delete:

| citation | claimed | actual |
|---|---|---|
| `input_nfr_mechanism_spec.lua` delete | `:66-105` | `:66-112` — `:105` is the **opening line of the 4th test**; deleting to `:105` orphans a 7-line body |
| `input_events_spec.lua` delete | `:781-905` | `:781-901`; `:902-905` leads in to the next describe |
| `keys_pressed_spec.lua` first describe | `:52-96` | `:52-90`; `:91-96` is an unrelated comment |
| `consoleController.lua` held plumbing | `:829-834` | `:829-830`; `:833-834` is a different function's comment |
| `input_api.md` §"Held keys" | `:365-395` | `:365-396`, off by two |
| `input_api.md` the contradicting clause | `:390` | the negation is on `:389` |

**F7 — two debt-register pairs are misattributed, and a third entry is missing.** Verified
myself line by line:
- `:738`+`:731` — **`:731` belongs to the `:719` entry**, not `:738`'s. `:738`'s own
  `keys_pressed` line is `:773`.
- `:775`+`:773` — **`:775`'s entry contains no `keys_pressed` mention at all**; `:773` is
  `:738`'s line (above).
- **`:719` — "A multi-trigger combo is silently truncated at registration (RESOLVED)" names
  `compy.input.keys_pressed` as the recommended answer at `:731`, in exactly the pattern
  §11.6 reworks for `:664` and `:738`, and it is absent from §11.6's list entirely.**

**F8 — five `keys_pressed` sites no P14d/P14e bullet accounts for.** The overall count is
right (22 across 7 files, confirmed exact); the *attribution* is not:

- **`src/types.lua:251`** — `--- @field keys_pressed table` on the `CompyInput` type. A
  production type declaration: left in place, the type lies about the API.
- **`src/controller/userInputController.lua:490`** — a comment naming the set.
- **`src/examples/keyboard/input.lua:109`** — `modHeld(a, b)` reads
  `compy.input.keys_pressed`. **A distinct code site** from the `INPUT.__index` "held" branch
  (`:57`) that P14e names — `modHeld` is a separate top-level function the metamethod calls.
- **`src/examples/keyboard/input.lua:43`** — header prose.
- (`src/probe/input_probe.lua:81,124` are covered by §11.4's separate delete bullet.)

Note the tooling lesson, which held exactly as the standing rule predicts: **LSP references
missed four of the 22** — a type annotation, a comment, a computed-string-key indirection
(`if k == 'keys_pressed'`), and the `compy.input.*` proxy path in the example. Grep as
backstop was load-bearing, not ceremonial.

## Check 6 — artifacts

All present and complete: §11 (seven subsections), the plan cross-links, both session32
sub-agent prompts and both deliverables, `notes/S32-plan-map.md`, the report, the track, the
successor prompt, the repointed pointer, and `36de0eaa`'s in-place softening of Decision 30
rule 3 (read and confirmed — it now says *"It could build its own table … That is not
committed to (owner, 2026-08-09)"*). `doc/development/internals/examples/keyboard.md`, P9b's
design of record, exists. No placeholders, nothing truncated.

---

## The two arguments the commission asked to be tested

### The ordering reversal (§11.2) — coherent, correctly scoped, under-argued

**The reversal holds.** §4's premise is that moving code invalidates prose written before it;
Decision 30 settles the shape by ruling, so P14a's docs are a **specification**, and tests
against a spec before implementation is `agents/development.md`'s own mandate. Sound.

Three things the argument misses, none of them fatal:

1. **§4 already contains both orders.** Its own text: *"This inverts the **commit** order
   (docs → tests → code) deliberately — that is the reviewer's reading order, not the working
   order."* P14's ordering **is** §4's stated commit order, adopted as the working order.
   §11.2 never engages the distinction §4 would defend itself with.
2. **The precedent is already in the plan.** **P9b ran docs-first by owner design** — its
   design of record was written into the persistent corpus in session29 and its code is still
   unwritten. So this is not a new regime; it is a second instance of one the plan already uses.
3. **The general rule is cleaner than the special case.** Not "the shape is settled so docs may
   go first", but: **docs-first when the doc is a specification of work not yet built;
   docs-last when it describes work already built.** That reconciles P14a with P10's remainder
   without an exception clause, and it makes the scoping self-evident rather than asserted.

**The scoping claim ("§4's rule still governs P8, P10, P11") holds — conditionally.** P14c and
P8 both restructure test files under opposite regimes, so the guarantee is that P8's per-id
check lands **before** P14c. F2 breaks exactly that link, and F1 changes its size.

### The P14b trigger — concrete, and it fires earlier than the plan implies

The trigger works. `internals/user_input.md` §"Key state" (`:241-296`) is the passage P14a
must rewrite; it documents **`Controller.combo_string(k, keys_pressed)` by signature**, plus a
*"Why the event-tracked set and not `love.keyboard.isDown`"* subsection built on the two-clocks
argument and cited to Decision 29 — which Decision 30 supersedes. Under fork **(a)**
`combo_string` keeps its second parameter and receives a proxy; under fork **(b)** it calls
`Key.*` itself and the parameter goes. **The signature is fork-dependent**, so the passage
cannot be written at the "matcher reads the device" altitude without either omitting a
signature — in the one document whose job is signatures — or picking a fork.

So the trigger fires, and it fires on P14a's **first** internals paragraph. §11.4's phrasing
that the fork blocks *"**only** the one internals passage"* understates it: that passage is the
section's centre of gravity.

**The useful refinement — P14a splits in two.** Its **project-facing half** (`doc/input_api.md`
§"Held keys", the flag-shortcut teaching, the false `:268` claim, the debt register, the
Decision 21 tombstone, the rule-3 softening) is **genuinely shape-independent** — projects
never see the matcher — and is unblocked exactly as the plan says. Its **internals half** is
fork-blocked from the first paragraph. Recommend §11.4 say that instead of "except one passage".

## Red-flag checklist (opening checklist for an analysis-heavy predecessor)

- **Self-inflicted constraints** — session32 *removed* one (the "mock fix must land FIRST"
  sequencing) and introduced none. **F1 is the closest thing to one**, and its origin is
  inherited rather than invented.
- **Phantom problems** — one, partially: F1's nine-id check.
- **Unratified terminology — one, small and PR-facing.** *"Rule 4"* is **our shorthand**: the
  string appears **nowhere** in the persistent corpus; Decision 30 has an unnamed numbered list
  1–4. And **`doc/input_api.md` contains zero occurrences of "Decision"** — the project-facing
  document has never cited the ledger. P14a's *"teach rule 4 for the first time in the corpus"*
  is right about the **pattern** and must not carry the **label**, or a stakeholder reading
  only `input_api.md` + the PR description meets a numbered rule with no visible list. Same
  applies to §11.7's PR-description obligation.
- **Scope expansion** — none; the movement is subtractive, and the owner cut the one addition
  (rule 3's gate table).
- **Deviation from intent / the mandate** — none; §11.7 addresses the frame directly.
- **Deviation from pre-feature functionality — CLEARS, and this is the load-bearing one.**
  Verified independently: `keys_pressed` appears **nowhere in the entire tree at PR base
  `3256aac`** (whole-tree `git grep`; machinery sanity-checked against `love.keyboard`;
  `3256aac` confirmed an ancestor of HEAD). The tracked set is entirely feature-introduced, so
  dissolving it cannot regress anything that worked before the feature. Every "pre-existing"
  check this phase has run has overturned something; **this one confirms.**

## Corrections proposed

Mechanical restorations, ready to apply immediately:

1. **F2** — four `P14b` → `P14c` in §11.3 (`:942` ×2, `:945` ×2).
2. **F4** — replace `plan.md:344-347`'s open item with the ruling.
3. **F7** — repair the two debt pairs (`:738`→`:773`, drop `:775`'s phantom line) and add the
   `:719` entry to §11.6's rework list.
4. **F5(citations)** — correct the six ranges in §11.4 to the verified boundaries.
5. **F8** — add `types.lua:251` and `userInputController.lua:490` to P14d, and
   `keyboard/input.lua:109` (`modHeld`) + `:43` to P14e.

Judgement, owner-gated:

6. **F1** — re-baseline P8 to R079 in both §4 and §11.3, with an `[S28]` marker on the row.
   Revises a disposition the owner ratified from a stale map.
7. **F3** — annotate §4's P8/P9c/P10/P11 rows and put P14a–e + the probe deletion in the table.
8. **F6 / F5(report)** — schedule the internals backfill; record the ~50-id re-derivation on P11.
9. **§11.4 wording** — P14a splits into an unblocked project-facing half and a fork-blocked
   internals half.
10. **F9** — a line in P14a: teach the flag-shortcut pattern **without** the "rule 4" label.

## One correction against this session

My own earlier note recorded that the controllers "live at `src/controller/` at base,
`src/model/` now". **Wrong** — they are at `src/controller/` in both; `src/model/` holds
unrelated model files. The error reached the sub-agent's prompt, which caught it and said so.
Corrected here and in the track.

---

## Disposition (added at the end of session33 — this review is CLOSED)

All five mechanical corrections applied; all five owner-gated items ruled on 2026-08-09 and
applied. Nothing in this document is outstanding.

| Proposed | Outcome |
|---|---|
| 1–5, mechanical | **Applied** — `2eaa0163` (parent plan's Phase U) and `c54dc0e7` (lettering, six ranges, debt pairs, three unnamed sites) |
| 6 — re-baseline P8 to R079 | **DECLINED.** Owner ruled: **walk all nine.** §6's "P8 marked done" and §4's row are both unverified against the tree, so the walk settles it rather than one document being trusted over the other. It starts from §6's claim as a hypothesis; R079 is a ruling, not a check |
| 7 — annotate §4's rows | **Superseded by a stronger ruling:** §4 becomes the **single operative list** — four steps rewritten, P14a–e and the probe deletion added as rows, `c65c2269` |
| 8 — schedule the internals backfill / the ~50-id re-derivation | **Backfill no longer owed** (see next row); the ~50-id re-derivation is now recorded in P11's own step |
| 9 — split P14a into blocked and unblocked halves | **Superseded:** the owner **took the design ruling up front** instead, so the docs step is unblocked in full and neither the split nor the backfill is needed |
| 10 — keep the "rule 4" label out of the project-facing guide | **Ruled as proposed** — plain descriptive name, no ledger reference, in the guide and the PR description alike |

**One finding of this review was overtaken by its own ruling.** The document argues that
`keys_pressed_spec.lua:98-138` needing zero edits is "the cheapest available evidence the
ruling is cleanly implementable" — inherited from session32 and true when written. The owner
chose **matcher shape (b)**, which removes the matcher's source-blindness, so those seven test
cases are rewritten and the property is gone. **The claim is withdrawn as evidence** (see
§11.4 P14c and §11.5's [S33] note). It was a real property of the rejected shape, not an error.

**Carried into execution:** the mock's variadic fix lands first, as its own commit, ahead of
the test rewrite — reinstated as a genuine prerequisite by shape (b), with the precise scope
recorded in `decisions/input.md` (Decision 30's amended "prerequisite" note).
