---
description: Cold delivery-level revalidation of session67 — does its work leave the feature closer to a releasable PR, and is the plan it hands forward still sound
status: revalidation report
audience: developer
authored: llm
session: 67
date: 2026-09-02
---

# S67 — delivery-level revalidation

**Commission:** [`validation/prompts/S67-delivery-revalidation-commission.md`](../prompts/S67-delivery-revalidation-commission.md).
Cold reader: `sessions/session67/track.md` not opened. Range read: `2986f028..ed4cef41`, 30 commits.
The cold peer review ([`validation/outcomes/S67-cold-peer-review.md`](../outcomes/S67-cold-peer-review.md))
was read first so its ground was not re-walked; one of its clearances is overturned below (F2).

## Verdict

**The session did what it was commissioned to do, and the feature is closer to release than it was —
but the gating chain is exactly where it was.** Session67 was commissioned to work `FIX-02` half (a)
and `CHG-01` with it; it closed eight of the half's eleven items and did not open `CHG-01` at all,
on an order the owner confirmed on turn one. That is a legitimate call, and it is also the single
most important delivery fact in this report: `CHG-01` gates `ACC-02` **and every slice cut**, it is
the last thing in the brace doing so, and it now sits behind `FIX-02-05` — the largest row in the
half, whose real size is larger than any document currently states (F3). The eight rows that did
land are real work of the kind that only shows up as absence: the prose a device pass reads is now
true, one design requirement was retired rather than mis-implemented, and the sprint's one code row
shipped a test that cannot pass vacuously. The quality of the reasoning is high and the
record-keeping is unusually honest — every completed roadmap cell preserves its original filing
verbatim, every retired ledger entry preserves its filing verbatim, and three cells say plainly that
the row's own premise did not survive contact.

**Nine findings, none blocking, none overturning a disposition.** One reaches the PR's primary
artifact (F1: the guide now instructs a project author to do something the surface does not permit,
and the ledger landed by the same session says so in as many words). One overturns a peer-review
clearance (F2: the completeness claim behind `FIX-02-06` is not met — three present-tense sites
survive in a third persistent document). Three are plan-integrity items that will cost the successor
time rather than correctness (F3, F4, F6). The rest are hygiene. **The plan the session hands
forward is sound in its ordering and its reasoning, and stale in three of its numbers.** Suite
confirmed at **1050 / 0 / 0 / 10**, LuaJIT 2.1.1703358377, 2.32 s.

---

## F1. The guide's new `hide()` section tells a project to do something `compy.input` does not permit

**Claimed / planned.** `FIX-02-13` and `FIX-02-22` landed a `### hide()` section in
`doc/input_api.md` (`:160`–`:181`). It ends: *"If you want the text back, keep it yourself and pass
it to that `show`."* (`doc/input_api.md:181`). The roadmap cell and `D-CFG-BOUNDARY` both rest the
retirement of the ratified preservation requirement on this fallback being available to a project.

**What I checked.** Every path by which a project can observe widget content, in code:
`build_widget_api`'s surface table (`consoleController.lua:879`ff — `show`, `hide`, `is_shown`,
`get_cursor`, `set_cursor`, `set_text`, `clear`, `configure`; no reader), and every delivery of
content to project code — `run_callback(self, 'on_text_entered', …)` and
`run_callback(self, 'after_submit', lines)`, both inside `UserInputController:submit_flow`
(`userInputController.lua:469`–`470`), and `validate(...)` one line above them, also submit-only.
`cancel_flow` (`:487`) delivers nothing. I then read what the same session wrote in the ledger.

**What I found.** A project can read the content **only at submit**. It therefore cannot "keep it
yourself" for text the user typed — only for text it seated itself. The session knows this: the
`D-CFG-BOUNDARY` addition it landed the same day says *"there is no content getter on
`compy.input`… so the text half is not available without the project mirroring keystrokes, **which
is not a thing to ask of one**"* (`decisions/input.md:1513`), and the BACKLOG entry it filed is
titled *"the half of the save-it-yourself fallback that does not exist"*. So the two documents
disagree, and the one that overstates is the one a stakeholder reads. Two smaller things fall out of
the same addition: the guide still nowhere says `get_cursor()` returns `nil` while hidden (it says
only that *mutating* calls warn — `:243`–`:244`), which is precisely the ordering constraint the new
section's advice depends on; and a reader is not told that the save must happen *before* the `hide`.

**Correction I propose.** Two sentences in the guide, not a code change: after `:181`, say what
"keep it yourself" can mean — *the text you passed to `show`, or the text delivered to
`on_text_entered` at the last submit; there is no call that reads the current content* — and add
that `get_cursor()` reports `nil` while the widget is hidden, so a save happens before the `hide`.
This is also the honest place for the deviation: the PR is reviewable from this file plus the
description alone, and today the guide is the one document in that pair that does not disclose the
gap.

**How sure.** Certain on the mechanism (read in code, three call sites resolved). The judgement that
this belongs in the guide rather than only in the ledger follows from the strategic frame in
`agents/validation.md`; the owner may reasonably rule that the guide should stay silent.

---

## F2. `FIX-02-06`'s completeness claim is not met — three stale-name sites survive in the persistent corpus, and the peer review cleared them wrongly

**Claimed / planned.** `ROADMAP.md:767` (`FIX-02-06`, ✅): *"`occupy_keyboard` and `hook_pointer` are
cited by name **across the persistent corpus** and neither exists… Also repaired."* The row's own
third column sets the acceptance test: *"Fix as one; **any survivor re-seeds the others**."* The
cold peer review cleared it: *"their only remaining textual occurrences are inside a `RESOLVED`
ledger entry narrating past naming history, **not a live claim**."*

**What I checked.** `git grep -n "occupy_keyboard\|hook_pointer"` over `doc src tests agents`,
excluding the session/validation/design archives; then read each surviving hit in context and
resolved the names against `src/controller/controller.lua` (`occupy_input` at `:228`,
`mark_pointer_liveness` at `:250`, `user_pointer` declared at `:40` and set at `:253`/`:261`,
`project_handler(userlove, key)` at `:188`, `project_handlers` at `:202`) and via `lua-lsp`
`references` on `mark_pointer_liveness`.

**What I found.** Five hits survive, all in `doc/development/technical_debt/input.md` — persistent
corpus, not `wip/`. **Two of the five are past-tense and correct** (`:2258`–`:2260`, under a
*"What it was:"* heading). **Three are not:**

- `:2237` — a **Resolution** bullet in the present tense: *"both the keyboard participants
  (`project_handlers`) and the pointer installs (`hook_pointer`) use it."* Same bullet also asserts
  *"`chain_project_handler(CC, fn)` wraps, `project_handler(userlove, CC, key)` guards"* —
  `chain_project_handler` exists nowhere in `src/` or `tests/`, and `project_handler` takes
  `(userlove, key)` and returns the raw handler rather than guarding a wrapper. Three stale facts in
  one sentence.
- `:2281` — a **Where:** location claim, *"`user_pointer` / `hook_pointer` (`controller.lua:68`,
  `:238-249`)"*. The name is dead and both line citations have drifted (`user_pointer` is at `:40`;
  `mark_pointer_liveness` starts at `:250`).
- `:2306` — a **Resolution** bullet, present tense: *"the module-local `user_pointer` flag is set in
  `hook_pointer`"*. It is set in `mark_pointer_liveness`.

The *divergence* claim the row was filed for is genuinely gone everywhere — I checked separately and
found no surviving keyboard/pointer routing asymmetry claim in `internals/`, `decisions/`,
`input_api.md` or the registers. What survives is the **dead-name** half, in the one persistent
document the sweep did not open — which is the row's own predicted failure mode, and the same
one-file-over miss session66 and `FIX-02-04` each recorded.

**Correction I propose.** Three edits in `technical_debt/input.md` (`:2237`, `:2281`, `:2306`):
`hook_pointer` → `mark_pointer_liveness`, drop *"the pointer installs"* (it installs nothing now),
correct or drop the two drifted line numbers, and either fix or past-tense the
`chain_project_handler` sentence. Un-tick nothing: the row's substance is done. Note in
`FIX-02-06`'s cell that the sweep's scope was two of three persistent documents, so the lesson lands
where the next sweep will read it. `FIX-02-05` opens this section next, so the cheapest route is to
hand these three line numbers to session68 rather than to schedule a pass.

**How sure.** Certain. Every name and line resolved in `controller.lua` at HEAD.

---

## F3. This session grew the set `FIX-02-05` must walk and updated none of the three places that size it

**Claimed / planned.** `ROADMAP.md:717` — *"It is the largest row in the half — **51 retired
entries**, each base-checked (counted 2026-09-02; the row still says 20)"*. `T-RETIRED-UNVER`
(`technical_debt/general.md:49`, count at `:52`) — *"the section holds **46** today and the whole of
it is this row's scope"*. `T-NEVER-SHIPPED` (`:105`, count at `:107`) — *"**51 entries, 46 + 5**,
counted 2026-09-02"*.
`session68/prompt.md:32` repeats *"there are **51**, counted 2026-09-02"*.

**What I checked.** Counted `### ` headings under `## RETIRED` in both registers at three points:
`7150d15b` (the commit that wrote "51"), `2986f028` (this session's base) and HEAD.

**What I found.** At `7150d15b`: 46 + 5 = **51** — the figure was right when written. At `2986f028`:
46 + 6 = 52. At HEAD: **49 + 6 = 55**. Session67 moved three entries into `input.md`'s `RETIRED`
(`T-KEYSET-SPLIT`, `T-GUARD-LIVE`, `T-MERMAID-MODEL`), which is precisely the set
`T-RETIRED-UNVER`/`FIX-02-05` is defined over and `T-NEVER-SHIPPED`/`LEDGER-02` consumes. The row is
under-sized by four in every document that states it, three of those four caused by this session,
and the successor's prompt repeats the stale number with a date that makes it look freshly counted.
Both goal entries do say *"re-derive"* / *"re-count when the row opens"*, which is the mitigation and
the reason this is not higher.

There is a second, cheaper half of this: **session67 already base-checked some of what `FIX-02-05`
must base-check**, and none of it is handed forward. `T-MERMAID-MODEL`'s retirement records that
`InputModel` and seven sibling classes *"did not exist at the PR base `3256aac`"*; `FIX-02-22`'s work
records that at base the widget was rebuilt per activation. Those are exactly the *"did this exist
at the base?"* answers `LEDGER-02-01` is told **not** to re-derive.

**Correction I propose.** Update the count in three places to 55 (or, better, replace the number
with *"the whole of both `RETIRED` sections — count it when the row opens"*, since the register grows
every time a sprint pays into it), and add one line to `session68/prompt.md` naming the three
entries session67 added and the base facts it already established for two of them.

**How sure.** Certain on the arithmetic (four heading counts, reproducible with `awk`). The
mitigation — that both entries already say "re-derive" — is why I rank this third rather than first.

---

## F4. `validation/plan.md` names `CHG-01`'s feeders by pre-crosswalk ids, and one of them is now a row session67 marked ✅

**Claimed / planned.** `validation/plan.md:515` — *"Three rows feed it — **FIX-02-04**, **FIX-02-15**
and that remark — so write it once."* `session68/prompt.md` sends its reader to `plan.md` for the
*why* beside the roadmap's *what next*, and `CHG-01` is session68's main task.

**What I checked.** Resolved both ids against today's roadmap table: `FIX-02-04` is *"pointer
annotations in `project_sandbox_env.md`"*, marked **✅ COMPLETE (session67)**; `FIX-02-15` is
*"`technical_debt/general.md` carries an entry that is not debt · `T-GFX-GLOBAL`"*. Neither has
anything to do with the CHANGELOG. The roadmap's own `CHG-01` table names the real feeders:
`CHG-01-02` ← `FIX-02-17` (*"CHANGELOG omits the breaking change"*), `CHG-01-03` ← `FIX-02-05`.
`ROADMAP.md:851`–`853` confirms the `FIX-02` renumber happened and *"a crosswalk already shipped"*.

**What I found.** This is `agents/rules/roadmap.md` §2's named hazard in the wild — *a citation that
still resolves, to the wrong thing* — and session67 activated the worst version of it without
touching the file: the id `FIX-02-04` now resolves to a row **struck through and ticked**, so a
successor reading `plan.md` for context can conclude a `CHG-01` feeder is discharged. It is not;
`FIX-02-17` is untouched. The stale ids are not this session's doing; the new failure mode is a
side effect of its ✅.

**Correction I propose.** One edit at `plan.md:515`: *"Three rows feed it — `FIX-02-17`, `FIX-02-05`
and that remark (ids updated after the `FIX-02` renumber; this paragraph was written pre-crosswalk)"*.
Cheap, and it belongs to whoever opens `CHG-01`.

**How sure.** Certain that the ids mis-resolve; certain that the roadmap's feeders are `-17` and
`-05`. I did not locate the original crosswalk document to confirm old-`04` → new-`17` mechanically,
so I state the mismatch rather than the mapping.

---

## F5. `technical_debt/input.md`'s new "ACTIVE is empty" paragraph over-claims one file wider than it can support

**Claimed / planned.** The new section body (`technical_debt/input.md:30`–`32`): *"**Empty as of
2026-09-02** — **every entry that had to be resolved before this release ships is paid**, and each
is in `RETIRED` below with what paid it… nothing there blocks the release."* The report and
`session68/prompt.md` both scope the claim correctly to `input.md`; the ledger's own sentence does
not.

**What I checked.** `technical_debt/general.md`'s `ACTIVE` section, entry by entry, against
`agents/rules/ledgers.md` §3 (*ACTIVE = must be resolved before the current release ships*).

**What I found.** Five `ACTIVE` entries remain in `general.md`, and **four of the five are the input
work's**: `T-VERSION-NUM` (the version number for this feature's four removed globals),
`T-RETIRED-UNVER` (whose *Where* is *"`input.md`'s `RETIRED` section"*), `T-NEVER-SHIPPED` (same
section) and `T-ARGUES-INTERIM` (`decisions/input.md`). So the file states that everything
release-blocking is paid, while three release-blocking obligations **about that very file** sit one
document over. Each of the five is correctly pointed at by a roadmap row, so `ledgers.md` §5's
cross-check passes — the defect is the sentence, not the state.

**Correction I propose.** Add the missing scope clause and the pointer: *"…every entry **in this
file** that had to be resolved before this release ships is paid. The release's remaining
input-related obligations are cross-cutting and live in `general.md`'s `ACTIVE` — `T-VERSION-NUM`,
`T-RETIRED-UNVER`, `T-ARGUES-INTERIM`, `T-NEVER-SHIPPED`."*

**How sure.** Certain on the facts. The reading is a judgement — the sentence sits inside a file
about the input subsystem and could be defended as implicitly scoped; I think a PR-time reader
scanning for *"what is still owed"* would be misled, which is exactly the audience the sentence was
written for.

---

## F6. `session68/prompt.md` is well-shaped but omits three things its session needs

**Claimed / planned.** The prompt hands forward the row order (`-05` → `-17` → `CHG-01` → the `-09`
slice), the mis-sizing lesson, the three BACKLOG filings, the crash guardrails, the LSP caveat and
the three owner-gated open items. It is accurate everywhere I checked it against the artifacts.

**What I checked.** Read it against `report.md`, the roadmap's `CHG-01` and `LEDGER-02` sections, and
the ledger state.

**What I found — three omissions, in descending value:**

1. **The "no CHANGELOG line is owed" ruling is not carried.** The owner ruled that retiring the
   hide/show preservation requirement earns no changelog line, because preservation was never
   shipped (`report.md` §4; landed in `decisions/input.md:1519`ff). `CHG-01-01` is *"validate what is
   there against the actual diff"* — a session doing that against this session's diff meets a
   behaviour-shaped change with no line and no note in its prompt. The ruling is in the ledger, so
   this is recoverable, but the prompt is what session68 reads first and `CHG-01` is its main task.
2. **The base-check facts already derived are not carried** — see F3's second half. `LEDGER-02-01`
   explicitly says *"do not re-derive"*, and session67 derived some of it.
3. **The LSP caveat is now understated.** The prompt says it *"under-reported twice"*. I made it
   three: `references` on `release_keyboard_route` returned *"No references found"* while
   `git grep` finds a definition (`controller.lua:731`), a call site
   (`consoleController.lua:343`) and a doc-comment mention. No `broken pipe`, no error — a clean,
   confident, empty answer. Worth stating as a standing property of this workspace rather than as
   two anecdotes.

**Correction I propose.** Three bullets in `session68/prompt.md`: the changelog ruling under the
`CHG-01` paragraph, the base-check carryover under `FIX-02-05`, and "three times" in the environment
note.

**How sure.** Certain on (1) and (3). (2) is a judgement about what would save the successor time.

---

## F7. `report.md`'s commit arithmetic does not close

**Claimed.** `report.md` header and §11: *"**Twenty-nine commits**, `2986f028`..`9bc2b0cf`"*.

**What I checked.** `git rev-list --count`.

**What I found.** `2986f028..9bc2b0cf` is **28** commits. `2986f028..ed4cef41` — including the wrap
commit that carries the report itself — is **29**. Both numbers are defensible; the pair as printed
is not. All 29 are `Hleb Rubanau <g.rubanau@gmail.com>`, none pushed.

**Correction I propose.** *"Twenty-eight commits, `2986f028`..`9bc2b0cf`, plus this wrap"*.

**How sure.** Certain. Flagged only because this is the same class of error the session's own peer
review caught in its commission's summary, and because a successor reconciling git against the
report will stall on it.

---

## F8. `FIX-02-07`'s count was not decremented, though this session executed five of its dispositions

**Claimed / planned.** `ROADMAP.md:768` — *"`FIX-02-07` | execute the **37** remark dispositions |
triage complete; breadth known, **12 files**"*. The `-03` and `-06` cells each note *"`FIX-02-07`
should not hunt for these"*.

**What I checked.** Counted `REMARK:`/`REVIEW:` markers across the persistent doc corpus at HEAD
(`git grep -c` over `doc`, minus `wip/77`): **34, across 12 files**. The range diff removes five —
three in `internals/user_input.md`, one in `event_dispatch_layers.md`, one in
`project_sandbox_env.md`.

**What I found.** The information is recorded, but in three *other* rows' cells; the row a successor
actually opens still says 37. Dispositions may not map one-to-one to markers, so I do not claim
37 − 5 = 32 exactly — only that the count is now stale in the row that carries it. Removing the five
was correct: each marker's defect was solved in the same pass, which is `DEC-02-04`'s rule.

**Correction I propose.** Amend the cell to *"execute the remaining remark dispositions (was 37;
five were executed at `FIX-02-03`/`-04`/`-06`, 2026-09-02 — **re-count when the row opens**)"*.

**How sure.** Certain the count is stale; deliberately imprecise about the new number.

---

## F9. A persistent internals doc now points its live open questions into a `RETIRED` ledger entry that `LEDGER-02` is scheduled to move

**Claimed / planned.** `internals/event_dispatch_layers.md:125`–`132` (new this session) records two
open pointer questions as *"deliberately open under `../technical_debt/input.md`, 'Pointer delivery
is an unstructured broadcast, not a chain' — an entry whose heading reads RESOLVED because the
broadcast itself was resolved."*

**What I checked.** Resolved the target: `technical_debt/input.md:2577`, inside `## RETIRED`, and it
does carry both questions verbatim (*"Still open, deliberately"*, *"Also still open"*). Then read
`LEDGER-02-02`, which **moves** introduced-and-paid entries out of the register into
`validation/archive/debt-vacuumed.md` — a file that leaves with `wip/77` — and whose four steps
contain no inbound-citation check.

**What I found.** The citation is accurate today and the doc is admirably explicit about the
awkwardness. The hazard is forward-looking: a **persistent** document now depends on an entry in the
set a scheduled pass is authorised to relocate into the ephemeral tree. The broadcast defect looks
pre-existing to me (it shipped), so the entry should survive `LEDGER-02` — but that is exactly the
classification `FIX-02-05` has not yet made, and `roadmap.md` §5 puts the fix on the pass that causes
the orphan. The same shape does **not** apply to `project_sandbox_env.md`'s new pointer at the T3
leak entry: that one is `BACKLOG` (`input.md:308`), which is not vacuumed.

**Correction I propose.** One line in `LEDGER-02`: before moving an entry, grep the persistent corpus
for citations of its heading; a cited entry is rewritten in place or its citation is re-homed, never
silently relocated under `wip/`.

**How sure.** Certain about the citation and about `LEDGER-02`'s steps. The risk is contingent, not
realised.

---

## What I checked and found correct

The negative space matters more than usual here, because several of these are now load-bearing.

1. **Suite.** `busted tests` → **1050 successes / 0 failures / 0 errors / 10 pending**, 2.32 s,
   **LuaJIT 2.1.1703358377**. Matches every claim in the report, the roadmap's suite cell, and
   `agents/validation.md`'s updated baseline. `lua` is not on `PATH` in this container, so **the
   owner's PUC Lua remains unverified** — and the session's one new spec is the range's only code,
   built on `debug.getupvalue`-by-name, which is the one construct here whose behaviour is in
   principle interpreter-dependent. I could not test it on PUC Lua and do not assert it passes there.
2. **Roadmap integrity — the heaviest check, and it holds.** All eight completed cells preserve
   their **original filing verbatim** as an *"Original filing:"* clause plus the untouched
   blast-radius column; I diffed each against `2986f028`. No row was redefined to match what was
   done. Three cells go further and state that the row's own premise failed (`-22`'s *"the code
   clears it"* is true of `show`, not `hide`; `-24`'s *"the model lost that argument in this
   feature"* holds only for `UserInputModel`; `-06`'s *"three places"* was four). `FIX-02-13`'s cell
   declines the row's word *"singleton"* with a stated reason (`D-WIDGET-AT-BOOT`, amended
   2026-08-27) rather than silently. Nothing of the session66-revalidation *"Gap closed"* kind was
   deleted.
3. **The sequence still runs.** `{ FIX-01 · FIX-02 (a) · CHG-01 } → REC-01 → MERGE-01 → ACC-02 →
   FIX-02 (b) → FIX-03 → DEC-02 → LEDGER-02 → DOC-01 → ACC-03 → PR-01` is untouched by this session.
   `FIX-02-05` still precedes `CHG-01-03`, which still names it as feeder. Nothing downstream was
   moved, blocked or quietly discharged: `REC-01`, `MERGE-01`, `ACC-02`, `FIX-03`, `DEC-02`,
   `LEDGER-02`, `DOC-01`, `ACC-03`, `PR-01` carry no edits in the range. The deliberate
   non-renumbering of `FIX-02` holds, and the REMARK that records it was correctly updated to say
   which three slugs stopped being live goals.
4. **Retirement citations.** Every live citation of `T-KEYSET-SPLIT`, `T-GUARD-LIVE` and
   `T-MERMAID-MODEL` outside dated session records now sits either in an *"Original filing"* clause
   or in the REMARK that explains the retirement — i.e. the `roadmap.md` §5 failure mode (a grep
   landing on a tombstone read as a live obligation) is avoided. The one marginal survivor is
   `validation/notes/turtle-pause-duplication.md:41`, a dated note.
5. **The three retired entries preserve their filings.** I diffed each old `ACTIVE` body against its
   new `RETIRED` body mechanically: the text is identical down to the `Resolution` bullet, with only
   the discharged `Revisit:` line dropped in each — and in each case the dropped line's content
   survives in the Resolution. `T-KEYSET-SPLIT`'s entry even explains that its present tense is
   deliberate. Nothing was lost.
6. **The retirements are true, not convenient.** None is partly-paid in `ledgers.md` §3's sense:
   `-23` is prose and the prose is there; `-25` is a test and the test exists and fails correctly;
   `-24` was *verify all three files* and a 32-block field-by-field audit ran. The three BACKLOG
   filings are at the right altitude and correctly unslugged (a slug is a commitment to fix): the
   `release_keyboard_route` naming is deferred pending a design call with a stated trigger, not a
   closed question, so `BACKLOG` beats `RETIRED`; the content-getter is a proposal with a named
   trigger, filed the same way as the existing event-sourced-state proposal beside it.
7. **The one code change.** `tests/input/input_config_key_agreement_spec.lua` reads `SHOW_KEYS` /
   `CONFIGURE_KEYS` out of the surface by upvalue name, asserts non-emptiness before looping, and
   names a missing proof by key. I re-read it rather than re-running the peer review's mutations. Its
   asymmetry is deliberate and correct: it proves *accepted ⊆ applied*, which is the direction that
   fails silently. `agents/validation.md`'s marker gate is clean
   (`grep -rnE 'INTERIM|REMARK|^[[:space:]]*--(->|>)' src/ tests/` → nothing), and no line in the new
   spec exceeds 64 characters.
8. **The load-bearing evidence behind the owner's ruling.** The retirement of a ratified design
   requirement rests on *"the only two `hide()` call sites in the tree both abandon the prompt"*. I
   verified this independently and **including the untracked nested example repos**, which `git grep`
   cannot see: `grep -rn "\.hide(" /repo/src --include='*.lua'` returns exactly
   `src/examples/maze/maze_main.lua:126` and `src/examples/maze/draw_main.lua:233`. Nothing in
   `balloons` or `keyboard` calls it. The claim holds on the widest scope available.
9. **`configure_core`'s persistence, which the new guide section asserts.** `prompt`, `auto_hide` and
   the four callbacks are all set-if-given (`userInputController.lua:280`–`301`), `reset_content`
   clears on a bare `show` (`:311`–`:317`), and `hide()` touches neither (`:375`–`:379`). The
   guide's *"your settings survive a hide; the content does not"* is exactly right, and its worked
   three-line example is consistent with the code.
10. **Cited headings resolve.** `### hide()` sits between `show(config)` (`:97`) and `Live changes`
    (`:183`), as the cell claims; *"Why the widget sits at tier 3"* (`:475`) and *"Combos the
    framework keeps"* (`:569`) both exist and say what the new paragraphs point at. `FIX-02-22`'s
    two `decisions/input.md` citations (`:76`, `:194`) resolve **exactly** at `2986f028` — I checked
    the pre-edit file rather than trusting the prose.
11. **The mermaid pass.** All seven files carry an identical banner; `README.md` is in the persistent
    corpus and cites no `wip/` path; `eval.md` really does carry both *"Planned refactor"* (`:4`) and
    *"Current"* (`:45`), which is the argument the README rests on. The date correction from the peer
    review landed in all three claimed places.
12. **Artifacts.** All present, none truncated, all with conforming YAML front matter: `report.md`
    (206), `session68/prompt.md` (125), two commissions (150, 109), two outcomes (212, 786), two
    notes (86, 133), the new spec (158). `agents/validation.md`'s volatile pointer was repointed to
    `session68` and its baseline paragraph updated in the same wrap commit. `1048` survives in the
    corpus only inside a dated session66 commission.
13. **Scope discipline.** The frozen `design/` tree has no commits in the range; the recommendation
    not to amend it is on disk, argued (amending would break `D-CFG-BOUNDARY`'s deliberate verbatim
    quotation), and correctly left owner-gated. `src/controller/controller.lua` is the only
    production file touched and only in comments. No vocabulary was minted: I found no new term in
    the landed prose that is not already in the ledger or the guide.
14. **`lua-lsp` health.** Responsive throughout, serially queried, no `broken pipe`, no errored
    query. But see F6.3 — it produced a **third** confident false negative in this workspace.

## What I did not verify

- **PUC Lua.** Not installed here. See item 1.
- **The mermaid audit's 32 blocks.** The peer review spot-checked two; I re-checked neither and take
  both on its verification.
- **The old→new `FIX-02` crosswalk mapping** (F4) — I found the renumber recorded but did not locate
  the crosswalk document itself, so I report the mismatch, not the mapping.
- **`FIX-02-07`'s exact remaining count** (F8) — I counted markers, not dispositions.

## Process note

No file in this repository was edited except this one. No `git add`, `commit`, `push`, `checkout` or
any other index- or history-mutating command was run; the only writes were to the scratchpad. Every
correction above is **proposed**, not applied — dispositions belong to the parent session and the
owner, and `agents/rules/revalidation.md` §"After the checks" requires that they be asked before
anything proceeds.
