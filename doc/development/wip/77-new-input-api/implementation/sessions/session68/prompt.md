# session68 — finish `FIX-02` half (a), and `CHG-01` with it

Read `agents/sessions.md` and `agents/validation.md` first, then the predecessor report
[`../session67/report.md`](../session67/report.md).

Baseline: **1050 / 0 / 0 / 10** (LuaJIT 2.1 in the container). A different count is a finding, not a
go-signal.

## Carryover — what changed under you

Session67 closed **eight of the eleven rows** in `FIX-02` half (a): `-22`+`-13`, `-25`, `-06`, `-23`,
`-03`, `-04`, `-24`. **`ACTIVE` in `technical_debt/input.md` is now empty**, and the section says so
in words. One spec was added (`tests/input/input_config_key_agreement_spec.lua`, +2 tests); no other
production or test code moved, and `controller.lua` was touched for comments only.

- **Every one of those eight rows was mis-sized** — larger (more sites than the cell named) or
  smaller (already fixed). The prompt's *"a count in a row is a lower bound"* is the operating
  condition of this sprint, not a caution. **Re-derive every sizing before working the row.**
- **Three rows turned out to sit on design questions**, and twice the owner reframed before I did:
  `-22` (retire the rule rather than amend the spec to match it), `-06` (a rename that needs a design
  decision first — filed BACKLOG, not done), `-24` (mark historical rather than correct). **A wrong
  sentence about a rule is a reason to re-examine the rule.** Expect this and surface the category
  question with the fix.
- **Three BACKLOG entries were filed** — the read-only content getter, the `release_keyboard_route`
  naming, and `@field` annotations disagreeing with their own constructors (`general.md`).

## Your task

**Open by executing the dispositions session67 recorded on its delivery revalidation**, then finish
half (a).

### First — the nine dispositioned findings

They are in the table at the end of
[`validation/reviews/S67-delivery-revalidation.md`](../../../validation/reviews/S67-delivery-revalidation.md).
**All nine are ACCEPT; none needs re-litigating** — the parent verified F1–F5 and F7 in git and in
code before dispositioning. F6 and F7 are already applied (they were this prompt and that report).
Yours are **F1–F5, F8, F9**, and they are cheap: most are one to three edits.

**Take them where they fall, not as a batch** — F2's three edits are in the file `FIX-02-05` opens
anyway, F4 belongs to whoever opens `CHG-01`, F8 is a roadmap cell. Fold each into the row it
touches; only F1 and F9 stand alone.

**F1 carries an escalation, and escalating is the action** — do not re-open the question first. Put
this to the owner, in this shape:

> Retiring the hide/show preservation requirement rested on a project being able to save and restore
> the content itself. It can save what it seated and what a submit delivered; **it cannot read what
> the user typed**. Does the release ship the read-only content getter (BACKLOG, unslugged), or does
> `doc/input_api.md` disclose the gap and the getter stay post-release?

**Apply F1's guide correction either way** — it is true under both answers and the guide is wrong
today. `doc/input_api.md:181` tells an author to *"keep it yourself and pass it to that `show`"*, and
content reaches a project **only at submit**. Say what "keep it yourself" can mean, and that
`get_cursor()` is `nil` while hidden, so the save happens before the `hide`.

### Then — finish half (a), in this order

`FIX-02-05` → `FIX-02-17` → `CHG-01`, then the `smoke_checklists.md` slice of `FIX-02-09`. This is a
working session; execute.

**`FIX-02-05` is the largest row in the half and gates the rest.** Its cell says *"20 resolved
entries"*; four documents say **51**; the true figure at HEAD is **55** (49 in `input.md` + 6 in
`general.md`, counted 2026-09-03). **Session67 is what staled it** — the three entries it retired
land in exactly the set this row walks. **Re-count when you open the row and write the number with
its date**; the register grows every time a sprint pays into it, which is why F3's disposition
prefers *"count it when the row opens"* over any fixed number.

**Two base-check answers are already derived — do not re-derive them** (`LEDGER-02-01` says so in
as many words). `T-MERMAID-MODEL`'s retirement records that `InputModel` and seven sibling classes
**did not exist at the PR base `3256aac`**; `FIX-02-22`'s work records that at base the widget was
**rebuilt per activation**.

**`CHG-01` gates `ACC-02` and every slice cut**, and is the last thing in the brace doing so. It is
four steps and includes the `1.0.0-rc` version question, which is an **owner call** — raise it, do
not settle it. `FIX-02-17` feeds it, so they are one sitting.

**Carry this ruling into `CHG-01-01`:** the owner ruled that retiring the hide/show preservation
requirement earns **no CHANGELOG line**, because preservation was **never shipped** — at the PR base
the widget was rebuilt per activation, so it is a design requirement not built, not a behaviour
anyone could notice changing (`decisions/input.md`, `D-CFG-BOUNDARY`). `CHG-01-01` validates the
CHANGELOG against the actual diff, and this session's diff contains a behaviour-shaped change with
no line by ruling. Do not "fix" it.

**The `-09` slice goes last in the half** because it is a vocabulary sweep and the rows before it are
still writing prose onto that floor. Do not pre-empt its (b)-half scope.

## Standing constraints

- Suite green at every commit, count stated in the message; commit at the seam, one concern each;
  **never push** — the platform repo or either nested one.
- A behaviour change is **never** documented in the commit message alone.
- **A finding goes to the debt ledger the moment it is found.** Fixed the same day, the record is the
  RETIRED entry; it lands in the ledger either way.
- **Before filing a surface finding, check whether a decision or a rule already draws that line.**
  Session67 found `technical_debt/general.md` already held a class it was about to re-file, and added
  a worked instance instead. **Read the ledger, not the commit trail.**
- **A line citation is verified by resolving the exact line, or not at all.** An errored or
  unsupported query is not an empty result. Expect drift: every citation `FIX-02-03` and `-04`
  touched had moved.
- **A citation sweep's scope is where the citations are, not where the code is.** `FIX-02-06` swept
  three sites and `FIX-02-04` — a row filed for something else — found a fourth, in pointer
  annotation text. **A claim spreads by being restated in passing.**
- **Dropping a slug from a heading owes a citation sweep in the same commit** (`roadmap.md` §5).
- **Prove a mechanical edit, do not eyeball it** — and read a substitution to the end of the
  *sentence*, not the end of the token it replaced. Session66 recorded this as F5; session67 made the
  same error anyway and caught it by re-reading the rendered paragraph, not the diff.
- **Run the example, do not reason about it.** A guide example that was reasoned about was wrong; the
  same example, executed in a scratch spec first, was right.
- Stage explicit paths. `git add -A` in `/repo` commits the nested example repos as gitlinks.
- Say **widget**, not "field" or "overlay" — and *the widget is shown*, not *the field is open*.
  Session67 broke this twice while writing **about** the widget; that is where it happens.
- Comments cite canonical `doc/…` and a **named section**, never `wip/77`. Check the heading exists
  before citing it.
- The owner also works in this tree. Never sweep their unrelated working-tree changes into a commit.

## Sub-agents — read this before you spawn anything

**Two Opus sub-agent spawns took the container's host down** on 2026-09-02 (100% CPU, maximum disk
read, active swapping, hard reboot within ~20 seconds, nothing written). Diagnosis:
[`validation/notes/S67-subagent-host-crash.md`](../../../validation/notes/S67-subagent-host-crash.md).

- **Every spawn prompt gets an explicit leaf-agent clause** — *"do not use the `Agent` tool, work
  sequentially"* — stated **with its reason**, or the agent routes around it as fussiness.
- **Scope the agent's searches.** Never recurse from `/repo` root: 63 MB of `.git`, 28 MB of binary
  assets under `src/assets/`, a tarball and five nested repositories. Prefer `git grep`.
- **`lua-lsp` is one shared server** — instruct serial queries.
- **Three spawns have since survived** — two Sonnet (nine and eleven minutes) and, once the
  leaf-agent clause was added, **one Opus (fifteen minutes)**. So Opus is not itself the problem and
  the clause appears to be the fix. **Treat that as one data point, not a proof**: the two failures
  were also Opus, and nothing in the container prevents a repeat.
- **The container still has no memory or CPU ceiling** (`memory.max` = `cpu.max` = `max`), so a
  runaway takes the host, not the box. **Owner's call, open** — compose stack under
  `implementation/docker`.
- The general hygiene rule that failed: saying *"you inherit none of the repo's CLAUDE.md"* and then
  restating a subset is a **licence to do anything unrestated**. Restate the constraints on the
  agent's **behaviour**, not only on its conclusions.

## Environment facts, stated because they qualify every claim you will make

- **The container runs LuaJIT 2.1; the owner runs PUC Lua.** Container-green is not their-machine
  green. State the interpreter behind any suite claim.
- **`lua-lsp` is healthy here and still under-reports.** `diagnostics` is clean and `references` is
  correct on most symbols, but it returned a confident, error-free *"No references found"* **three
  times** for symbols that demonstrably have callers — `UserInputController:set_eval` (three callers)
  and `release_keyboard_route` (a definition at `controller.lua:731` and a call site at
  `consoleController.lua:343`), the latter found by the delivery reviewer after two sessions had
  already recorded the caution. **Treat an empty `references` as a standing property of this
  workspace, not an anecdote: it is a hint, never proof of absence.** Cross-check every negative with
  `git grep` before writing "nothing uses this".
- **Markdown is not bound by the 64-character limit** — `agents/rules.md` scopes it to *coding*.
  Comment blocks in `.lua` are.

## Open with the owner, deliberately not taken

- **`design/` amendment for `FIX-02-22`** — recommendation on disk
  ([`validation/notes/FIX-02-22-frozen-design-sites.md`](../../../validation/notes/FIX-02-22-frozen-design-sites.md)):
  **do not amend.** `D-CFG-BOUNDARY` establishes the deviation by quoting the round-2 sentence
  **verbatim**, so rewriting the spec breaks that citation on purpose. Fallback offered: one
  precedence line at the top of `design/spec.md` instead of five edits. **Owner-gated either way.**
- **The container resource ceiling** — see above.
- **Session66's F6** (not to be confused with the revalidation's F-numbers above) — `ROADMAP.md`'s
  section bodies no longer run in sequence order
  (`DOC-01` → `ACC-02` → `ACC-03` → `REC-01` → `MERGE-01`). The sequence line is correct; the move is
  a large diff in a file the owner reads, so it is theirs to call. **Do not take it unprompted.**

## Your predecessor's work was cold-reviewed before you got it

[`validation/outcomes/S67-cold-peer-review.md`](../../../validation/outcomes/S67-cold-peer-review.md),
commission in `validation/prompts/`. **Verdict: the work holds** — ~two dozen claims resolved against
source, all as stated. Two low findings, both applied: a date over-generalised from four mermaid
files to seven (it had reached the persistent corpus), and a miscount in the commission's own
summary. Neither changed a disposition.

**The one thing it says that this prompt cannot:** the session had both halves of the date fact in
hand — *"four added 2024-07-29"* and *"three committed as unfinished docs"* — and merged them into
one wrong sentence anyway. **A claim assembled from two true facts is not thereby true.**

## And then revalidated at the delivery level

[`validation/reviews/S67-delivery-revalidation.md`](../../../validation/reviews/S67-delivery-revalidation.md),
commission in `validation/prompts/`, dispositions in the table at its end. **Verdict: the session did
what it was commissioned to do and the feature is closer to release — but the gating chain is exactly
where it was.** It cleared the heaviest check: every completed roadmap cell and every retired ledger
entry preserves its original filing verbatim, diffed one by one against `2986f028`.

**Two things it says that this prompt cannot.**

**A cold reader overturned another cold reader, and the second was right.** The peer review cleared
the surviving `occupy_keyboard`/`hook_pointer` occurrences as *"not a live claim"*; three of the five
are present-tense assertions about today's code (F2). A clearance is evidence, not a verdict —
including a clearance in a document this prompt sends you to.

**Three of the four significant findings are session67's own lesson turned on itself.** It recorded
that *a claim spreads by being restated in passing* — and then left a dead name in a third document,
a stale count in four, and an id resolving to a ticked row in a fifth. **Writing the rule is not
applying it**, and the pass most at risk of a defect class is the one that just named it. Session66
recorded the same thing about itself; that is twice, which makes it a property of this workflow
rather than a coincidence.
