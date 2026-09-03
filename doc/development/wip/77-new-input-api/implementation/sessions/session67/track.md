# session67 — track

## 2026-09-02 — boot

- Fresh start: no `track.md`, no `report.md` in `session67/`. Guardrail → begin.
- Read `agents/sessions.md`, `agents/validation.md`, `session67/prompt.md`,
  `session66/report.md`.
- HEAD `4a0b4dd0` *(docs(session66): re-wrap — the cold read of this session…)*.
- **Suite: 1048 / 0 / 0 / 10** — matches the stated baseline. **LuaJIT 2.1.1703358377** in the
  container; no `lua` binary present, so the PUC-Lua result is unverified here, as always.
- Working tree: the known untracked scratch (`claude.sh`, `src/STEPS.md`, `input-pr-slices.tar.gz`,
  `src/examples/{balloons,keyboard,maze}`, `worklog.md`, `repos.txt`, `broken-busted/`).

### Boot finding — session66's cold-read artifacts are on disk but never committed

`validation/outcomes/S66-cold-revalidation.md` and
`validation/prompts/S66-cold-revalidation-commission.md` are **untracked**. Both are cited from
`session66/report.md` §8 and §9, which *is* committed (`4a0b4dd0`), and from `session67/prompt.md`.
So the committed record points at two files that a fresh clone would not have. Sibling
`validation/reviews/S66-session65-delivery-revalidation.md` **is** tracked — this is a miss, not a
policy. Hygiene (c) is satisfied on disk and not in git. Raised with the owner; not swept
unilaterally, since committing another session's deliverable is theirs to confirm.

### Citations resolved before proposing (prompt: "resolve the exact line, or not at all")

`FIX-02-22`'s three sites, all live:

- `design/spec.md:155` — *"Content preserved for the next `show()` without `text`."* **FROZEN.**
- `design/spec.versions/version01.md:191-194` — *"Input content is preserved (subsequent `show()`
  will display it unless `text` is provided)."* **FROZEN.**
- `decisions/input.md:194` — *"…keeps 'hide and bring back with state intact' free…"*, inside
  `D-WIDGET-AT-BOOT`'s **Why**. Ours to fix. Note the row's cell says "Decision 3"; the ledger has
  been on names since `DEC-01`, and `:1786` is the crosswalk row `Decision 3 → D-WIDGET-AT-BOOT`.

## 2026-09-02 — owner confirms the first pick

- Order for half (a) proposed and accepted: **`-22`+`-13`** → `-25` → `-06`,`-23` →
  `-03`,`-04`,`-24` → `-05`→`-17`→`CHG-01` → the `-09` smoke slice.
  Rationale that carried it: `-22` is the only row in the half with an **owner-gated** part, so
  raising the proposal on turn one unblocks it early. Second: the `-09` slice goes **last in the
  half** because it is a vocabulary sweep and rows 1–5 are still writing prose onto that floor.
- Owner also confirmed committing session66's two untracked artifacts → `2986f028`.

## 2026-09-02 — `FIX-02-22` + `-13` executed. The row was wrong three ways.

Commits: `f3a41997` (decisions), `86f73731` (guide), `c49ac041` (roadmap + proposal note).
Suite 1048 held at every one; docs only, no `.lua` touched.

**The three corrections, and none came from reading the row:**

1. **Persistent corpus: two sites, not one.** `decisions/input.md:76` is the *source* of the
   phrase `:194` quotes. The row named only `:194`. Fixed as one — `FIX-02-06`'s rule.
2. **Frozen tree: five sites, two claims, not two sites and one.** `design/spec/M2.md:33` unnamed;
   and the *forced*-`show` variant (`spec.md:149`, `version01.md:179-180`, `:534-535`) is the same
   sentence one clause over, already reversed by `D-CFG-BOUNDARY` statement 4.
3. **"The code clears it" names the wrong call.** `hide()` **preserves** — pinned by *"a typed
   character while hidden does not mutate it"*. The next bare `show()` clears — pinned by *"a fresh
   activation with no text is empty"*. **A fix written from the row's wording would have been wrong
   in the opposite direction**, and this is the sitting's one real lesson.

**Method note worth keeping:** the guide example (`show{prompt,text}` → `hide` → bare `show`) was
**run** in a scratch spec before being documented, not reasoned about. It passed. An earlier draft
of that example had three calls and would have been wrong — the third `show` lands on an *active*
widget and warns instead of re-opening. Reasoning produced the bug; running caught it.

**Deliberate omission:** no new "draft" vocabulary in the guide paragraph. `FIX-02-20`'s ruling on
the word is still owed and `FEAT-02` already widened its spread once while it waited.

**Recommendation to the owner, not applied:** do **not** amend `design/`.
[`validation/notes/FIX-02-22-frozen-design-sites.md`](../../../validation/notes/FIX-02-22-frozen-design-sites.md).
Ground: `D-CFG-BOUNDARY` establishes the deviation by quoting the round-2 sentence **verbatim**, so
rewriting the spec breaks that citation on purpose. Fallback offered: one precedence line at the
top of `design/spec.md` instead of five edits.

**Open question for the owner:** does §1's extra-sites finding belong in the debt ledger? Kept on
the roadmap row instead — the row is live and cited, `design/` dies with `wip/77`, and an entry
retired in the same breath is noise. Flagging rather than deciding, since three sessions running
have mis-called exactly this boundary.

## 2026-09-02 — owner rules, and reframes the question I asked

- **Behavioural note, the one worth keeping from this session.** I asked *"where does this finding
  get recorded"*. The owner ignored the filing question and asked **whether the rule was ever any
  good**: *"neither of existing known scenarios relies on hiding and restoring widget with exactly
  same text/cursor… the requirement as originally written is likely useless and batch-approved."*
  Same disposition, better ground — and it is the third time this phase has gone this way. The
  memory is *"defects get answered at design level"*; this is that, applied to a **documentation**
  defect, which I had not seen it reach before. A wrong sentence about a rule is a reason to
  re-examine the rule.
- The owner also pre-authorised the honest outcome: *"if rationale is weak and decision is not
  justified, tell it was by mistake but not fixed in release because cost of urgent repair outweighs
  cost of failure."* Judged **not** weak — evidence below — so it is recorded as a retirement.
- **Second correction to my framing:** I asked about a "line in decisions/changelog"; **no CHANGELOG
  line is owed.** Preservation was never shipped — at the PR base the widget was rebuilt per
  activation — so this is a design requirement not built, not a behaviour anyone could notice
  changing. Stated in the decision so the next reader does not re-ask.
- `design/spec/M2.md` out of scope by owner ruling: historical spec subslice, the period's analogue
  of a roadmap row.

**The premise was checked in code and holds, with one gap.** The only two `hide()` call sites in
the tree — `maze_main.lua:126`, `draw_main.lua:233` — both abandon the prompt for a menu and
**want** the clearing. Zero want restoration. But the owner's fallback (*"could be done in calling
project (i hope we have accessors to get cursor position)"*) is **half available**: `get_cursor()`
exists; **there is no content getter**. Surface is `show, hide, is_shown, get_cursor, set_cursor,
set_text, configure, clear`.

- Landed as `D-CFG-BOUNDARY`'s third *"what this changes for a project"* item (`b6394761`), which
  quotes both frozen spec sentences **verbatim** so the record survives `wip/77`'s deletion.
- The gap is **registered** (`2acd6a9e`) — *"PROPOSAL: a read-only content getter"*, BACKLOG,
  unslugged. It had been cited as background in **three** unrelated entries and filed as none; the
  three-unrelated-routes signature is what earned it the entry, not the third instance.
- **So the ledger question answered itself, one level over.** The design-tree finding stays on the
  row (subject and record die together); the thing that *did* belong in the permanent ledger was the
  consequence for the **shipped surface**, which I had not separated from it when I asked.

`FIX-02-22` closes. Next: `-25`.


- Owner then added the getter proposal's **real consumer** (`b28dbe26`): reading content **outside
  submit and cancel** — on a timeout, or from a project-launched process off a hotkey. Today those
  two moments are the entire read surface. Reframes the entry: *"restore a draft across a hide"* is
  exotic, *"read the field without forcing a submit"* is not, and sizing it from the hide/show
  framing alone would under-price it.

## 2026-09-02 — `FIX-02-25`. The test reads the real set; no defect behind it.

Commits `a3097082` (spec), `16e2c100` (ledger retirement + citation sweep). **Suite 1048 → 1050.**

- **The design call that mattered.** A hand-written list of the accepted keys would have been a
  **third** copy — and it cannot fail on a key it does not know about, which is the entire defect.
  So the spec **reads the real set out of the surface**: `show` → `api_show` → `SHOW_KEYS`, two
  upvalue hops **by name**, and the `configure` equivalent. Probed first (scratch spec) to confirm
  reachability before committing to the design.
- **Mutation-tested both ways, and the second one is the important one.** `'ghost'` into
  `WIDGET_KEYS` → both cases fail naming the key. Renaming `SHOW_KEYS` → *"upvalue SHOW_KEYS is
  gone; fix this reader"* rather than **silently checking an empty set**. A reader that returns nil
  on a rename would have degraded to a test that passes while checking nothing; hence the asserts
  and the non-empty guard.
- **No production defect.** `CALLBACK_KEYS` and `CONFIG_CALLBACKS` hold the same four strings;
  `prompt`/`auto_hide` → `configure_core`, `text`/`cursor` → `open_widget`, `force` gates in the
  widget's own `show`. The prompt reserved a separate commit for a defect here; not needed, and the
  row's placement argument (*"the sitting would run against an unknown"*) is now discharged.
- **`lua-lsp` is HEALTHY** — its health was unverified since session65. `diagnostics` clean on the
  new spec, and `references` on `configure_core` returned the two real call sites. Reported because
  the prompt asked for it either way.
- **Ledger: retired, and the slug sweep done in the same commit.** `roadmap.md` §5 makes the pass
  that causes an orphan owe the fix, and dropping a slug from a heading *is* that pass —
  `T-HL-TWO-HOMES` is the standing example. Swept: the roadmap's renumber REMARK, the row, **and my
  own spec header written an hour earlier**. The filing text is kept and labelled rather than
  rewritten (*"No such test exists"* was true when written).

## 2026-09-02 — `FIX-02-06`. Four sites, and the third was hiding in a doc already named.

Commits `d832979c` (the fix), `05730ff8` (ledger). Suite 1050 throughout.

- **The row said three places and left the third as *"whichever second doc `FIX-02-05` found"*.**
  Nobody had ever identified it. Sweeping the corpus by sense: the survivor is **inside
  `event_dispatch_layers.md` itself**, ~40 lines below the bullets — a closing paragraph asserting
  the asymmetry again and sourcing it to a debt entry **RESOLVED 2026-08-03**. Fixing the bullets
  alone would have left the claim standing *and* cited. That is the row's own *"any survivor
  re-seeds the others"*, and the survivor was in the file being edited.
- **`internals/user_input.md` was already correct** and is the doc the other two contradicted. Only
  its two stale function names moved. Worth noting: the corpus was not uniformly wrong; one
  document had it right the whole time.
- **Two function names cited across the corpus do not exist** — `occupy_keyboard` (now
  `occupy_input`) and `hook_pointer` (now `mark_pointer_liveness`, and it installs nothing).
- **The rename the triage proposed was NOT done, deliberately.** `release_keyboard_route`'s caller
  pairs it with `clear_user_handlers`; naming it accurately means first deciding whether the two
  should be one function. That is design, not a docs sweep, and a name chosen without that decision
  is just a second wrong name. Filed BACKLOG. **This is the second time this session that a
  documentation row turned out to sit on a design question** — the first was `-22`, where the owner
  made the same move. Worth watching as the pattern of this sprint rather than a coincidence.
- **A finding I did NOT file:** `event_dispatch_layers.md`'s line citations are wrong by ~110 lines
  and land on unrelated code. `technical_debt/general.md` **already holds that class**, sized at 77
  references, naming *"lands on plausible code"* as the worse mode. Added a worked instance to it
  instead of a duplicate entry. The standing constraint earned its keep here.
- **Caught in my own edit:** a `python` substitution turned *"keeps its literal meaning for
  neither"* into *"for either"* — the exact F5 failure from session66 (read to the end of the
  sentence, not the end of the token). Caught by re-reading the rendered paragraph, not by the
  diff.

Half (a) remaining: `-23`, then `-03`/`-04`/`-24`, then `-05` → `-17` → `CHG-01`, then the
`smoke_checklists.md` slice of `-09`.

## 2026-09-02 — `FIX-02-23`. The row was right; my first draft of the fix was not.

Commits `07812c41` (guide), `3923a4ce` (ledger). Suite 1050.

- The gap was real and exactly as filed: the guide had the **mechanism** and one **case**, never
  the consequence — hooks sit above the widget, so while it is shown an unguarded handler acts on
  the user's typing and the key still reaches the widget. Nothing looks wrong from either side.
- **The error I nearly shipped.** First draft said a blanket guard is safe because the platform's
  reserved combos never reach your handler. **Backwards.** *"Combos the framework keeps"* says a
  reservation **acts and passes the key on** and never consumes — so a blanket guard silences the
  *project's* binding and leaves the *platform's* action standing. Same conclusion (the user is not
  stranded), opposite mechanism. Caught by reading the section I was citing instead of citing it
  from memory. Kept in the retired entry because it is the kind that gets re-made.
- Also switched the example to `ctrl+escape`: `ctrl+pause`, which the entry names, is marked
  **development only** and is inert in a packaged build, so it is the wrong reassurance to offer.
- **My own vocabulary slipped twice** — "lands in the field", "while the prompt is up". Both are
  the idiom `FIX-02-09` exists to delete, written by the session that is carrying the rule. Zero
  new instances after the fix, but the tell is worth recording: it happens while writing *about*
  the widget, not while sweeping for it.
- **`ACTIVE` in `technical_debt/input.md` is down to one entry** — `T-MERMAID-MODEL`, i.e.
  `FIX-02-24`, still in this half.

Half (a) remaining: `-03`/`-04`/`-24`, then `-05` → `-17` → `CHG-01`, then the
`smoke_checklists.md` slice of `-09`.

## 2026-09-02 — `FIX-02-24`. Delegated the evidence; the owner supplied the disposition.

Commits `2e43af48` (audit artifacts), `d547f144` (marking), `54f31e99` (ledger). Suite 1050.

- **Owner suggested a sub-agent and was right about the shape.** Sonnet worker, explicit model,
  commission and report both on disk (`validation/prompts/S67-mermaid-diagram-audit.md`,
  `validation/outcomes/S67-mermaid-audit.md`). Scope widened in the commission from the row's three
  files to all seven, on the *"a count in a row is a lower bound"* rule. 32 class blocks audited
  member-by-member. It reported LSP healthy and **distinguished an output-cap overflow from a
  broken pipe unprompted** — the exact distinction hygiene (a) exists to get.
- **Owner's disposition, mid-task:** *"old mermaid version is a good artifact to check feature
  implementation vs intent… if it's not the live doc and never was, maybe we should not update it,
  just mark (historical)?"* **Third time this session a row was answered at design level rather
  than at the level it was filed at.** The pattern is now unmistakable and belongs in the report.
- **The base check settled it in two commands.** All seven files are `aldum`'s (2024-07-29 →
  2025-01-13, three committed as *"unfinished docs"*), and **none of the eight classes they draw
  existed at the PR base either**. So: another author's, stale a year before this feature, never
  live. Marked, not corrected. `doc/mermaid/README.md` carries the reasoning once; seven banners
  point at it.
- **Of 32 class blocks, exactly ONE line was ours** — `editor.md`'s `oneshot` on `UserInputModel`,
  base-present and gone today. Deleted, on the principle that *a historical marker excuses
  inherited drift, not drift you caused*. `custom_label`, `evaluator: EvalBase` and the
  `wrapped_error`/`error` conflation were each base-checked and are identical there, so they stay.
- **The row's premise was wrong** and the retirement says so: *"the model lost that constructor
  argument in this feature"* is true of `UserInputModel` only.
- **The strongest argument for marking rather than correcting came out of the audit, not the
  ruling:** `eval.md`'s section headed *"Current"* describes a hierarchy **never built**, while
  its *"Planned refactor"* section is closer to what shipped. A correction pass would have deleted
  the evidence that plan and build diverged — which is precisely the owner's *"good artifact to
  check implementation vs intent"*.
- Filed from the audit's margins: three `@field` annotations disagreeing with their own
  constructors, all byte-identical at base → `technical_debt/general.md`, one entry, unslugged,
  recorded not claimed.
- **`ACTIVE` in `technical_debt/input.md` is now EMPTY**, and the section says so in words.

Half (a) remaining: `-03`, `-04`, then `-05` → `-17` → `CHG-01`, then the `smoke_checklists.md`
slice of `-09`.

## 2026-09-02 — `FIX-02-03` and `FIX-02-04`, the two cheap verification rows

Commits `e6bc45ce`, `ae0b191c`, plus the roadmap. Suite 1050.

**`-03` — three alleged factual errors in the A-doc. One real, two already fixed, code right.**

- All three cited line numbers had **drifted**; claims recovered from the filing, not the citation.
- **Claim 1 refuted with a mechanism**: projects genuinely cannot install evaluator objects — no
  `evaluator` key on a closed config table, `set_eval` not on the surface, and `consoleController`
  **withholds** `InputEvalText`/`InputEvalLua`/`ValidatedTextEval`/`LuaEditorEval` from
  `project_env`, which starts as a clone carrying them. But the remark was a **fair reading**: the
  bullet said projects supply "callbacks for validation and display" and then that they cannot
  install evaluators, without ever drawing the function/object line. Drawn now.
- **Claims 2 and 3 object to text that no longer exists** — only the remarks quoting it survived.
- **A false finding caught before filing.** LSP: zero references for `UserInputController:set_eval`
  → reads as dead code. grep: `editorController` holds a `UserInputController` and calls it three
  times. **Empty LSP references are a hint, not ground truth** — the rule earned again, and this
  is the second time this session the LSP under-reported.

**`-04` — the sandbox doc's pointers. Unknown yield, and it paid.**

- One pointer carried **the stale route-lifetime claim `-06` removed this morning** — *"the route
  connects only while the project is actively running"* — a **fourth site**, found by a row filed
  for something else, after a sweep that believed it was complete. **The claim spreads by being
  restated in passing**, which is why annotation text is as dangerous as prose.
- Same line cited the **wrong decision**: `D-ROUTE-LIFETIME` for the `before_exit` contract, which
  is `D-STOP-IS-FW` — correctly cited two paragraphs above in the same document.
- Completeness: three pointers where the doc earns six. Every target resolved before writing.
- Body line citations into `consoleController.lua` have drifted (3 of 4 spot-checked). **Known
  class, already in `general.md`** — recorded, not re-filed, not this row.

**Running theme, now four for four:** every row in this half that was filed as narrow turned out to
be either larger (more sites) or smaller (already fixed) than its cell said, and in both directions
the cell was written by someone who could only grep the obvious form.

Half (a) remaining: `-05` (the big ledger audit) → `-17` → `CHG-01`, then the `smoke_checklists.md`
slice of `-09`.

## 2026-09-02 — the cold peer review took the host down, twice

Spawned the peer reviewer at 20:09 and again at 22:24 (after the crash forced a `/compact`). **Both
took the host to 100% CPU, max disk read and swapping within ~20 seconds**, needing a hard reboot.
Neither wrote a line; the second cost this session its context. Owner asked for a diagnosis before
any further spawn.

- **The review's workload is innocent.** Measured every operation the commission prescribes: range
  diff 3074 lines, `git log -p` 4269, `git grep` at base 0.36 s, suite 2.3 s.
- **The control settles it.** Three spawns this session, identical but for the model: the `sonnet`
  mermaid audit ran 9 minutes and returned; both `opus` peer reviews died at ~16 s and ~22 s.
- **No ceiling anywhere.** `memory.max`/`cpu.max` = `max`; 2 CPUs, 3819 MB, no swap, Node heap limit
  2006 MB. A process climbing toward a 2 GB ceiling on a 3.8 GB box gives precisely the reported
  triad — GC thrash, RSS past RAM, swap-in reads.
- **Leading hypothesis, explicitly unproven** (no sidechain records survived, `dmesg` blocked):
  recursive agent fan-out. `general-purpose` has `Tools: *` **including `Agent`**, and my spawn
  message said *"a spawned agent inherits none of the repo's CLAUDE.md"* and then restated only the
  LSP, git and suite rules — **omitting sub-agent hygiene**, i.e. the very rule against
  parallelising. Seven independently-scoped questions is a fan-out shape.

**The self-inflicted part is the lesson.** Declaring the repo's rules inapplicable and restating a
subset is a licence to do anything unrestated. I restated the constraints on the reviewer's
*conclusions* and none on its *behaviour*.

Hardened the commission: leaf-agent rule (no `Agent` tool, questions worked sequentially, reason
stated), serial `lua-lsp` use, scoped searches (never recurse from `/repo` root — 63 MB `.git`,
28 MB `src/assets`, five nested repos), and the commit range pinned to `4a0b4dd0..874411f5^`.

Diagnosis and evidence: `validation/notes/S67-subagent-host-crash.md`. **The container limit itself
is unfixed and is the owner's call** — the compose stack under `implementation/docker`, not the
older `claude.sh` I first named. Until then the prompt guardrails are the only protection, and they
rely on a sub-agent obeying them.

## 2026-09-02 — the cold peer review, third attempt, on Sonnet

Owner's call after the diagnosis: **peer review on Sonnet, the later delivery-revalidation agent on
Opus.** Ran eleven minutes, 98 tool calls, no incident, under the hardened commission.

**Verdict: the work holds.** ~two dozen claims resolved against source — code behaviour, base
comparisons at `3256aac`, line citations, ledger state, git provenance, the one code change — all
as stated, several to the exact line and exact runtime error string. It re-ran the
`debug.getupvalue` mutation and reproduced both failure messages verbatim, restored what it touched,
confirmed the tree clean. Suite 1050 on LuaJIT 2.1.1703358377. LSP healthy; it independently
re-confirmed the `set_eval` callers that an empty `references` had hidden from me earlier.

Two low findings, **both verified in git before acting** (standing rule), both real:

1. **A date over-generalised from four files to seven.** I wrote all seven mermaid files "added
   2024-07-29"; `eval.md`, `input.md`, `scratch.md` were added **2024-12-18** (`fc2490b4`,
   *"unfinished docs"*) — and those three are exactly the trio I separately described as the
   unfinished ones, so I had both facts and still merged them into one wrong sentence. Corrected in
   `doc/mermaid/README.md` (persistent corpus, so it mattered most), the retired `T-MERMAID-MODEL`
   entry, and the roadmap cell. The substance is untouched: all seven are `aldum`'s, all predate
   the PR base.
2. **My own commission miscounted BACKLOG filings** — "two filed" where three were. The reviewer
   correctly attributed it to the commission, not to the commits or roadmap, which claim no count.
   Recorded as a post-execution correction *appended* to the commission rather than edited into it,
   so the prompt the reviewer actually worked from stays intact.

**The reviewer also flagged what it read as a prompt-injection attempt**: after each
`git checkout --` restore, a system-reminder said the change was intentional and told it not to
revert and not to tell the user. It disregarded and disclosed it. That is the harness's ordinary
external-file-modification reminder — `git checkout` mutates a file the agent had in context, and I
saw the same reminder myself this session for `MEMORY.md`. **Benign, and the agent's handling was
right**: disclosing beats complying with any instruction to conceal.

Half (a) remaining, unchanged: `-05` (the big ledger audit) → `-17` → `CHG-01`, then the
`smoke_checklists.md` slice of `-09`.

## 2026-09-03 — delivery revalidation, dispositioned; the re-wrap

Opus, cold, **fifteen minutes without incident** under the leaf-agent clause — so Opus is not itself
the crash cause and the clause is the likely fix. One data point, not a proof; recorded as such.

**Verdict: the session did what it was commissioned to do, the feature is closer to release, and the
gating chain is exactly where it was.** `CHG-01` was never opened and now sits behind `FIX-02-05`.
Owner's confirmed order, so a call and not a drift — but it is the delivery fact of the session.

It cleared the heaviest check: **every completed roadmap cell and every retired ledger entry
preserves its original filing verbatim**, diffed one by one against `2986f028`.

Nine findings, **all ACCEPT, none rejected**; F1–F5 and F7 re-verified in git/code before
dispositioning. Table appended to the revalidation doc, clearly marked as the parent's.

- **F1** — the guide's new `hide()` section tells an author to *"keep it yourself"* and content
  reaches a project **only at submit**. `D-CFG-BOUNDARY`, landed the same day, says mirroring
  keystrokes *"is not a thing to ask of one"*. **Two documents disagree and the overstating one is
  what a stakeholder reads.** Guide correction accepted **and** the getter marked **ESCALATE** —
  owner directive: *marking as escalatable is disposition, escalating is acting*, so session68 puts
  it. The retirement itself is undamaged: the reviewer re-verified both `hide()` call sites,
  including in the untracked nested repos `git grep` cannot see.
- **F2** — three present-tense stale-name sites survive in `technical_debt/input.md`. **Overturns a
  cold peer-review clearance** — two cold readers disagreed and the second was right.
- **F3** — I staled my own successor's sizing: 52 at session start, **55** now, four documents say
  51. The three entries I retired land in exactly the set `FIX-02-05` walks.
- **F4** — `plan.md` names `CHG-01`'s feeders by pre-crosswalk ids and my ✅ turned one into a row
  that reads as discharged. `roadmap.md` §2's named hazard, activated without touching the file.

**The uncomfortable part, and it is the report's lead:** three of the four significant findings are
this session's own lesson turned on itself. I wrote *a claim spreads by being restated in passing*
and then left a dead name in a third document, a stale count in four, and an id resolving to a ticked
row in a fifth. Session66 recorded the same shape about itself — **twice makes it a property of the
workflow, not a coincidence.**

Applied here (my own handover artifacts): F7's commit arithmetic, F6's three prompt omissions — the
no-CHANGELOG ruling, the base-check carryover, the LSP caveat now at **three** false negatives.
Session68 opens by acting on F1–F5, F8, F9.
