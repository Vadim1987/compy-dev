# session69 — the delivery review's dispositions, then `FIX-01`

Read `agents/sessions.md` and `agents/validation.md` first — **the closing order changed on
2026-09-03 and you are the first session to boot under it** (see below) — then the predecessor
report [`../session68/report.md`](../session68/report.md).

Baseline: **1055 / 0 / 0 / 10** (LuaJIT 2.1 in the container). A different count is a finding, not a
go-signal.

## Carryover — what changed under you

**`CHG-01` is complete, so the gate is gone.** It held `ACC-02` **and every slice cut**; it does not
any more. `FIX-02` half (a) is finished, and `FEAT-03` — a surface sprint that did not exist
yesterday — shipped `compy.input.get_text()`. What remains in the brace is **`FIX-01`** (three rows)
and `FIX-02`'s (b) half, and (b) runs after `ACC-02` by the owner's ordering. **So the sequence's
next real item is `REC-01`/`MERGE-01` on the three example repos**, which are nested repositories
with their own PRs — owner territory, not something to start unprompted.

**Five owner rulings landed mid-session** and all five are materialized (`report.md` §2). The two
that will bear on your work: **a terminology drift goes to the step that unifies terminology if that
step has not run** (so `FIX-02-09` now carries *"prompt"* as a fifth name with its own ruling), and
**shipped-but-false documentation is an active defect** (so `T-EXAMPLE-README` / `FIX-02-27` exists).

## The closing order is now three steps — you are the first to run it end to end

`agents/validation.md`, *"Closing a session — the three-step review order"*. Commit → **Sonnet peer
review of your changes** (integrity and sanity; it reads the diff, not the plan) → **wrap** →
**Opus delivery review** (roadmap integrity, omissions, drift from purpose). **Neither sub-agent may
spawn sub-agents — strict, host protection, and the clause goes in the prompt *with its reason*** or
it gets read as fussiness and routed around.

## Your task

**Open by executing the dispositions on session68's delivery-level review**, which is in
`validation/reviews/` with its dispositions in a table at the end. Then work **`FIX-01`** — three
rows of citation hygiene, `ROADMAP.md`'s `FIX-01` table:

- **`FIX-01-01`** leads because its size is unknown: P11's deferred editorial list was *named as a
  count and never enumerated*. **Re-derive before sizing.**
- **`FIX-01-02`** — ephemeral citations in the persistent corpus (`wip/` paths, step ids, the
  `FR-1`/`FR-6` namespace). The stated *~12 sites* is stale by construction: the count drifts every
  time a row cites its own evidence note, and **this session added several `validation/` citations**
  to the register and the roadmap.
- **`FIX-01-03`** — session numbers in the persistent corpus, 4 sites when last counted.

**Then stop and raise `REC-01`/`MERGE-01` with the owner** rather than opening them.

## What session68 learned the hard way, stated so you do not repeat it

- **A count in a document is a snapshot, and yours will be too.** I claimed *"56 retired entries
  walked"* when the section held 59 — and it grew *because of me*, three retirements landing while
  the walk ran. **A verification pass whose subject grows while it runs must claim the snapshot it
  walked, not the section.** `FIX-01-02` is exactly this shape: its subject is citations, and you
  will be adding citations.
- **Check your greps for case.** `project_env\.[a-z_]+` silently dropped a third of its input and
  hid the three keys that would have led to the finding I later reached by another route. **A
  character class is a filter you did not declare.**
- **Grepping for a retired word finds retired mechanisms.** Checking whether *"one-shot"* was live
  vocabulary turned up an internals doc whose **Lua code sample** taught the pre-`auto_hide` shape.
  Prose gets read around; a sample gets copied.
- **A finding parked against another row's opening leaves with that row.** A disposition said *"take
  it when `FIX-02-05` opens that file anyway"*; `FIX-02-05` closed and it had not been taken.
- **The claims that fail are the ones that read well.** Both `CHG-01` defects were fluent, plausible
  sentences that did not survive being resolved against the tree.

## Standing constraints

- Suite green at every commit, count stated in the message; commit at the seam, one concern each;
  **never push** — the platform repo or either nested one.
- **`git add -u` is how a change rides in on an unrelated commit.** Stage explicit paths. (Also:
  `git add -A` in `/repo` commits the nested example repos as gitlinks.)
- A behaviour change is **never** documented in the commit message alone.
- **A finding goes to the debt ledger the moment it is found.** Fixed the same day, the record is
  the RETIRED entry; it lands either way.
- **Before filing a surface finding, check whether a decision or a rule already draws that line.**
- **A line citation is verified by resolving the exact line, or not at all.** Prefer naming a
  function to citing its line — session68 replaced two drifted citations that way, and the class is
  already registered in `technical_debt/general.md`.
- **Dropping a slug from a heading owes a citation sweep in the same commit** (`roadmap.md` §5).
- **Run the example, do not reason about it.** Two of this session's better answers came from a
  scratch spec that printed what the code actually does; one of them corrected me twice.
- Say **widget**, not "field" or "overlay" — and *the widget is shown*, not *the field is open*.
  **"Prompt" is now known to be a fifth name** and is `FIX-02-09`'s to rule; do not pre-empt it.
- Comments cite canonical `doc/…` and a **named section**, never `wip/77`. Check the heading exists.
- The owner also works in this tree. Never sweep their unrelated working-tree changes into a commit.

## Environment facts, stated because they qualify every claim you will make

- **The container runs LuaJIT 2.1; the owner runs PUC Lua.** Container-green is not their-machine
  green. State the interpreter behind any suite claim.
- **`lua-lsp` is healthy here and still under-reports.** A clean, confident *"No references found"*
  has been wrong **three times** in this workspace. Treat an empty `references` as a standing
  property, not an anecdote: cross-check every negative with `git grep`.
- **Markdown is not bound by the 64-character limit** — `agents/rules.md` scopes it to *coding*.
  Comment blocks in `.lua` are.

## Open with the owner, deliberately not taken

- **`REC-01`/`MERGE-01` sequencing** — the three example repos, their own PRs. Theirs to start.
- **`design/` amendment for `FIX-02-22`** — recommendation on disk (*do not amend*), owner-gated
  either way: `validation/notes/FIX-02-22-frozen-design-sites.md`.
- **The container resource ceiling** — `memory.max` and `cpu.max` are both `max`, so a runaway
  sub-agent takes the host. Compose stack under `implementation/docker`.
- **Session66's F6** — `ROADMAP.md`'s section bodies no longer run in sequence order. A large diff
  in a file the owner reads; theirs to call. **Do not take it unprompted.**
