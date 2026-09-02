# S66 — session65, delivery-level revalidation

**Commissioned by** `implementation/sessions/session66/prompt.md`, scoped to four subjects; the
owner added a fifth in-session on 2026-09-02: *"validating replan sanity and integrity — anything
omitted, lost, done in a way that undermines path to release?"*

**Method.** `agents/rules/revalidation.md` at the **delivery** level — did the outcome match the
need, was anything overlooked, was anything unnecessary delivered. Every claim below was resolved
against the file it names, not against the commit trail. Suite at boot and throughout: **1048 / 0 /
0 / 10**, LuaJIT 2.1 in the container (the owner runs PUC Lua).

**Out of scope by the commission, and not re-checked:** the 554 substitutions, the 68 reflowed
comment blocks, and `DEC-02`/`LEDGER-02` as filed — all three are proven by construction, and
re-deriving them is the recursion `agents/validation.md` guardrail 1 forbids.

---

## Verdict

**Session65's four hand-written judgement calls hold. The replan does not.**

Subjects 1–3 are clean on substance: no live ruling was dropped from `D-AUTO-HIDE`, every
re-pointed citation resolves to a statement that says what the citing comment asserts, and the
vacuum's rehoming neither lost anything nor invented anything. Subject 4 found one contradiction
the addition left standing. Subject 5 — the replan — is where the pass earns its keep: the
acceptance split silently reverses **two dated owner rulings**, and the renumber that came with it
left live citations resolving to the wrong step.

Findings F1, F2, F5, F7 are unambiguous defects with mechanical fixes. F3 is a sweep. **F4 is not a
defect and is not ours to rule** — it is a decision the owner has already made once, in the
opposite direction, and it needs re-making explicitly.

---

## Subject 1 — `D-AUTO-HIDE`'s live-vs-churn split (`d0f4e66c`, 132 → 77 lines)

**Checked against the tests and the guide, not the diff**, exactly as commissioned — a dropped live
ruling under-specifies behaviour the suite pins, and the suite stays green.

**Every behaviour the suite pins has a home in the five statements.** The nine cases in
`tests/input/input_widget_callbacks_spec.lua` (`auto_hide` describe block) and the two in
`input_widget_control_spec.lua` map as: closes on submit → 1; plain `show` does not → 1; not on
cancel → 3; composes, closing last → 4; rejecting validator leaves it open → 1 (*"clean submit"*);
bare `show` inherits → 2; `false` disarms → 2; disarming forced follow-up survives → *"the edge it
does not close"* (read placement at the END of the submit); raised callback leaves it standing → 5;
`configure` arms it → 2; `configure{auto_hide = false}` keeps the draft → 2 + `D-CFG-BOUNDARY`.

**Every claim in the guide is backed.** `doc/input_api.md` *"Asking one question"* (lines 274–326)
— the mode's persistence, both disarm forms, the `before_submit`/empty/validator exclusions, the
Escape asymmetry, and the three follow-up shapes — resolves into statements 1–5 and the edge
paragraph without remainder.

**Three things the rewrite dropped. None is a live ruling; all three are stated here so the call is
visible rather than assumed:**

- **`T-ONESHOT` is retired / built at `FEAT-01-02`** — back-links, not rulings. The debt entries
  carry the forward link themselves (`technical_debt/input.md`, `T-ONESHOT-SCOPE`'s *Where* now
  names `D-AUTO-HIDE`), so nothing dangles.
- **The in-tree `oneshot` token collision** — `Prof.start_oneshot` / `love.PROFILE.oneshot`, still
  present at `src/controller/profiler.lua:18,60` and `controller.lua:850,1091`. It was a real
  supporting argument for the rename and it is gone; dropping it is consistent with the owner's
  *"name the complexity, don't unpack it"*, so **no action** — recorded only so a later reader does
  not rediscover it as a loss.
- **The *"What it fixes"* paragraph** (`configure` refused the key, so disarming cost the user's
  draft). This described a state that was ruled and overruled inside one day and never released —
  `ledgers.md`'s new rule is exactly that this is not kept. Its live half survives as
  `D-CFG-BOUNDARY` statements 3 and 4, which the paragraph itself cited.

**And one thing it did not drop that it might have.** `force` is `show`-only *because it is
meaningless at `configure`*, not because it is protected — the distinction that keeps `auto_hide`
out of the category. It survives in `D-CFG-BOUNDARY` at `decisions/input.md:1415-1420`, together
with *"neither reason is 'it describes this session'"*. Checked because losing it would have made
statement 2 unfounded.

**Verdict: clean.**

## Subject 2 — the eleven re-pointed citations

Thirteen edits across seven files (the commit's *"eleven"* counts named `Amendment` / `ruled edge`
references; the header and two rewordings are the rest). **Each resolved individually** against the
statement it now names:

| site | now cites | resolves |
|---|---|---|
| `input_widget_callbacks_spec.lua:512` | five statements are the edges | ✅ |
| `:534` | statement 3 (cancel is not a close) | ✅ |
| `:545` | statement 4 (composes, closes last) | ✅ |
| `:580` | statement 2 (persistence) | ✅ |
| `:609` | statement 2 (*"silence is not a disarm"* — verbatim in the entry) | ✅ |
| `:615` | the entry records the generation token as declined | ✅ (*"the edge it does not close"*) |
| `:643` | statement 5 (raise leaves it standing) | ✅ statement — ❌ **text, see F5** |
| `input_widget_control_spec.lua:170` | statement 2 (not `show`-only) | ✅ |
| `consoleController.lua:600` | statement 2 (`auto_hide` is NOT in `SHOW_ONLY_KEYS`) | ✅ |
| `userInputController.lua:292` | statement 2 (persistent until replaced) | ✅ |
| `internals/user_input.md:758` | statement 2 (applies until a call passes `false`) | ✅ |
| `technical_debt/input.md:1883` (`T-ONESHOT-SCOPE` *Where*) | `D-AUTO-HIDE` | ✅ |
| `technical_debt/input.md:1897` (`T-ONESHOT` *Where*) | `D-AUTO-HIDE` | ✅ |
| `technical_debt/input.md:1889` (`T-ONESHOT` resolution) | reworded off the entry | ✅ |

No `Amendment` or `ruled edge` citation survives in `src/`, `tests/` or the persistent corpus; the
two remaining hits (`technical_debt/general.md:78`, `ROADMAP.md:1031`) **describe the phrase as
history**, which is correct.

**Verdict: every citation resolves. One botched comment body — F5.**

## Subject 3 — what the vacuum rehomed

**`D-ASK-THE-DEVICE`, *"what it withdraws"*** (`decisions/input.md:1051-1064`) against archived
Decisions 13, 20 and 29: the arc is stated accurately in all three of its stages (read-only view as
argument 2 → globally readable → the framework's event-time truth), and both details flagged as
*"still biting"* are faithful — the `__pairs` index-only limitation (D13's *"Recorded honestly"*,
D20's *"Not a new capability"*) and the `examples/keyboard` consumer (D20's *"The consumer that
settled it"*). **The one claim not in the originals** — that the example *"is served by
`love.keyboard.isDown` directly, which is why removing the surface cost that example nothing"* — is
**true in the tree**: `keyboard_view.lua:286` reads `Key.shift()`, and no `INPUT.held` mirror or
`keys_pressed` reference remains anywhere in `src/examples/keyboard/`. Nothing asserted that the
originals did not support.

D29's material that is *not* carried is all moot under the reversal (the unfolded key names, the
proxy-allocation note, the callback-over-poll ground), and the one live inversion — a device poll
answering an event-time question — is **stated as an accepted cost**, not quietly dropped:
*"Consequence, accepted — the batch-skew error"*.

**`internals/user_input.md`, *"inspect mode"***: `f30c5a72` added **only the heading**; the
paragraph beneath it is pre-existing internals prose. Nothing was invented, and all **seven** code
citations resolve (`src/main.lua:363`, `src/controller/controller.lua:631`,
`input_widget_control_spec.lua:820`, `input_route_lifecycle_spec.lua:20,36,430,447`). The one line
of Decision 12 not carried is its cross-reference to the connection rule (*"the project route is
disconnected exactly as `D-ROUTE-LIFETIME` describes"*); no citation depends on it, and
`input_route_lifecycle_spec.lua:19-20` pairs both documents itself. **No action.**

**Verdict: clean — nothing lost, nothing invented.**

## Subject 4 — the three additions to `agents/rules/ledgers.md`

- **§2 *"Vacuuming is a move, not a deletion"*** — coherent with §2's existing conditions, and it
  carries its own guard against the failure mode it could create (*"not a second ledger … the
  ledger is right"*). Its extension to a superseded **part** of a live entry is what makes
  `DEC-02` a tidy-up rather than a loss. **No overreach.**
- **§2 *"What a decision records about its own past"*** — the narrowing is explicit and correct
  (*"interim, overwritten"*, not "arguing with itself"), and both carve-outs are stated. **No
  overreach.**
- **§3's introduced-vs-pre-existing rule** — sound, and the mixed-provenance clause is the part a
  mechanical sweep would have got wrong. **One scope question for the owner, not a defect: it does
  not restate §2's stakeholder carve-out.** §2 keeps a ruling that came from outside; §3 as written
  would vacuum a defect a **stakeholder reported during the branch** on the sole test of *did it
  ship*. `LEDGER-02` executes on this rule, so the answer is worth having before it runs (F9).

**One contradiction the additions left standing — F2.**

## Subject 5 — the replan (owner-added)

**The split itself is complete and correct.** All eight rows of the old `ACC-02` are accounted for
in the crosswalk; nothing was dropped, and `ACC-02-08` finally sits in execution order.
`smoke_checklists.md` — persistent corpus — was renumbered with it, which `roadmap.md` §5 requires
of the pass that causes the orphan.

**Two dated owner rulings were reversed without being cited, and the reversal is presented as
fixing an oversight (F4).** Both live in `validation/plan.md`, which `agents/validation.md` names
as the *why* document beside the roadmap's *what next* — and both were reversed by a pass that
read the roadmap.

**The renumber shipped a crosswalk but did not sweep the planning documents (F3)**, which is the
other half of `roadmap.md` §2's *"No"* branch.

---

## Findings

### F1 — the crosswalk cites a section that was deleted, and contradicts its own prose

`doc/development/decisions/input.md:1799`. The Decision 16 row says *"What it ruled, and why the
ruling fell, is in `D-ONE-LIFETIME`, **"what it reverses"**"*. **That section does not exist** — it
was added at `e9a3501a` and removed at `cd1264da` when the owner refuted its premise. The crosswalk
(`187b62a3`, 21:09) was written two hours before the removal (23:19), and `cd1264da`'s own message
says *"Nothing is lost"*.

It also contradicts the prose forty lines above it (`:1758-1761`), which says the two
superseded-in-full entries *"left nothing behind"*. A mechanical sweep of `*"section"*` citations
across `src/`, `tests/` and the persistent corpus finds **this and nothing else** unresolved.

**Fix:** drop the second sentence of the row. **Class:** the exact failure `agents/validation.md`
*"Comment References"* warns about, at doc-to-doc range rather than code-to-doc — which is why the
removal pass's `src/`+`tests/` grep did not see it.

### F2 — `ledgers.md` §6 still says the question §2 now answers is unruled

`agents/rules/ledgers.md:234-235`: *"**Where** vacuumed entries go — dropped outright, or moved to
an archive — remains unruled; §2 rules only that the sweep may happen and on what condition."*
`cbd88b00` ruled it, at §2 *"Vacuuming is a move, not a deletion"*, and left this standing.

This is a **live rule document governing all future ledger work**, and the two halves give opposite
instructions to whoever runs `DEC-02` or `LEDGER-02` next. **Fix:** delete the sentence.

### F3 — the ACC renumber left live citations resolving to the wrong step

`roadmap.md` §2: *"renumbering is cheap. Ids live in a handful of planning documents; **sweep
them**, ship the crosswalk, done."* The crosswalk shipped; the sweep did not. §5 names this exact
hazard as the one that bites — *"a citation that still resolves, to a heading that no longer means
what it did."*

| site | says | now resolves to | was |
|---|---|---|---|
| `validation/plan.md:438-452` | the whole `ACC-02` table, old ids | mixed | — |
| `validation/plan.md:519` (heading) | *"`ACC-02-04` carries a coverage gap"* | `sapper` smoke | `maze` + `draw` |
| `validation/plan.md:552` | *"Add rows for Track 2 before running `ACC-02-04`"* | `sapper` smoke | `maze` + `draw` |
| `validation/outcomes/BUG-01-03-turtle-fix-peer-review.md:351` | *"covered by `ACC-02-04`'s smoke"* | `sapper` (in-repo) | `maze` (nested repo) |
| `validation/plan.md:446` | `ACC-02-01` = the second cold review | `balloons` smoke | the cold review |

`plan.md:552` is an **instruction to the future** — prepare the maze Track-2 rows before running
that pass — and it now names a different repo's smoke. This is `wip/`, so it dies with the tree,
but it is live until then and it is the document the owner is pointed at for *why*.

**Fix:** a scoped sweep of `ACC-0[123]-` ids across `validation/` and `implementation/`, applying
the crosswalk; the frozen session dirs and commit messages keep their old ids and are what the
crosswalk is for.

### F4 — the reordering reverses two owner rulings without citing either — **owner call, not a defect**

**(a) *"Why ACC runs before U, not after"* (owner, 2026-08-26; `validation/plan.md:554-558`).**

> *"A smoke pass on the pre-merge tree is not merely reassurance — it is the **control** for the
> post-merge one. Merging an advanced upstream … into a branch whose behaviour no human has
> verified leaves every later device failure with two candidate causes and no way to separate them.
> Re-running a pass costs bounded owner time; bisecting a confounded failure does not."*

Session65 moved `REC-01`/`MERGE-01` **ahead** of `ACC-02` on the ground that the smoke otherwise
runs against a tree that then changes — *"either its result was stale or the passes got run twice,
which is the exact waste that row's own preamble exists to prevent"* — and recorded it as *"an
inversion nobody had noticed"*.

**It was noticed and ruled on.** The 2026-08-26 ruling weighs the same trade and accepts the
re-run: running a pass twice is the price it pays **for** the control. The new order does not
answer that argument, and the roadmap now presents the old order as an oversight.

**The owner's 2026-09-02 instruction was narrower than the change made.** Per session65's own
report: *"move the smoke passes and the remaining recon ahead of slicing and the docs
finalisation"* — that orders `ACC-02` against `FIX-03`/`DEC-02`/`LEDGER-02`/`DOC-01`. Putting the
**merges** ahead of the smoke is an additional move the session made on its own initiative.

**(b) *"before any keyboard time"* (owner, 2026-08-26).** The old `ACC-02-01` was *"a second cold
PR review, over the fixed tree — **before the owner touches a keyboard**"* — the owner's stated
reason for the ACC-01/ACC-02 split in the first place (*"we have enough defects to fix before I put
my hands on keyboard"*, `plan.md:415-417`). The split moves that review to `ACC-03-01`, **after**
the device passes. `ACC-03`'s note argues well for reading the prose that ships; it does not
address why the review was placed ahead of the sitting it was meant to protect.

**Neither is ours to rule.** Both orders are defensible, and the owner may well confirm the new one
— but it should be confirmed rather than inherited. **A reconciliation exists if wanted:** split
the cold read the way the smoke was split — the code/API delta review before the keyboard, the
prose read after `DOC-01` — which is the same *"opposite ordering requirements"* argument that
produced `ACC-02`/`ACC-03`.

### F5 — a citation edit left a sentence fragment asserting the opposite of the entry

`tests/input/input_widget_callbacks_spec.lua:643-644`, after `d0f4e66c`:

```lua
-- D-AUTO-HIDE, statement 5 -- the widget survives a raise;
-- entry's own recommendation. A raised callback leaves the
```

It was *"ruled edge 4 — the one REVERSED from the entry's own recommendation"*. The substitution
took the first half and left *"entry's own recommendation."* standing as a sentence, which now
reads as a claim that statement 5 **is** the entry's recommendation — the opposite of what it was,
and a fact the rewrite deliberately retired as churn. Session65's own method note applies to its
own edit: **prove a mechanical edit, do not eyeball it.**

**Fix:** `-- D-AUTO-HIDE, statement 5 -- the widget survives a raise.`

### F6 — the roadmap's section order no longer matches its sequence (minor)

`ROADMAP.md` bodies now run `DOC-01` (1103) → `ACC-02` (1152) → `ACC-03` (1217) → `REC-01` (1232) →
`MERGE-01` → `PR-01`, against a sequence of `REC-01 → MERGE-01 → ACC-02 → FIX-03 → DEC-02 →
LEDGER-02 → DOC-01 → ACC-03 → PR-01`. `roadmap.md` §2 is about ids, but its reason — *"a roadmap
where 07 runs before 03 costs a lookup on every read"* — applies to a reader scanning the body.
Also a stray double `---` at `:1211`/`:1215`.

### F7 — the crosswalk's closing count is off by one (minor)

`decisions/input.md:1823`: *"The seven that map to nothing **are archived**"* — six are; the
seventh is Decision 19, which *"never existed; the sequence had a gap"*. The next clause says the
archive holds six, so the file contradicts itself in one sentence.

### F8 — no action, recorded so it is not rediscovered

The three `D-AUTO-HIDE` omissions in Subject 1 — judged consistent with the owner's framing.

### F9 — scope question for the owner, ahead of `LEDGER-02`

Does §2's stakeholder carve-out reach §3? See Subject 4.

---

## Disposition — as executed, 2026-09-02

| # | outcome | where |
|---|---|---|
| F1, F7 | **fixed**; RETIRED entry in `technical_debt/general.md` carries the `*"section"*` sweep | `4ebc9dff` |
| F2 | **fixed** — §6 points at §2 and keeps the *record, not a second ledger* half | `aeab2a78` |
| F5 | **fixed**, two ragged neighbours rewrapped with it, wording untouched | `cdf28968` |
| F3 | **swept**; `plan.md`'s duplicate row table deleted rather than renumbered | `b365a42e` |
| F4 | **ruled by the owner — both halves confirm the new order**, and both are now recorded on the roadmap and superseded in place in `plan.md` | `156b8cd4` |
| F6 | stray `---` removed; **the section-order move is not done** — the bodies still run `DOC-01` → `ACC-02` → `ACC-03` → `REC-01` → `MERGE-01` against a sequence that runs the merges first. Left for the owner: it is a large diff in a file they read | — |
| F8 | closed here, no action | — |
| F9 | **ruled for the instance, not generalised** (owner, 2026-09-02) — `T-ONESHOT` and `T-ONESHOT-SCOPE` are swept despite the outside request behind them, because *"why is `oneshot` gone and what replaces it"* is a **decisions** question, and the contradiction they record did not exist at base: there was `oneshot` and nothing replacing it. They stand in `D-AUTO-HIDE` and, as the capability, in `CHANGELOG.md`. §3's test is unchanged. Recorded on `T-NEVER-SHIPPED`, where `LEDGER-02` will read it | — |

**The two rulings, in the owner's terms, because they generalise past these rows.** Merges before
smoke: *"we are accelerating now, so no point in having two separate sessions of smoke testing and
defect fixing just for ceremony. Recon will document what changed in the upstreams before the merge;
this knowledge will assist troubleshooting."* The cold read after keyboard time: *"it was supposed to
de-risk by spotting bugs, but can also become wasted effort or misfire. Smoke becomes more important
in the same way as behavioural versus unit testing — cold review checks internals, smoke validates
the surface. When the planning horizon collapses to one day, postponing smoke for the sake of
additional peace of mind makes no sense."*

**Neither ruling overturns the 2026-08-26 reasoning on its merits; both change what it is priced
against.** The control the old order bought with a second sitting is now bought by `REC-01`'s written
upstream delta — which is why that document is recorded on the row as the condition this order stands
on, and not as a by-product of the recon.
