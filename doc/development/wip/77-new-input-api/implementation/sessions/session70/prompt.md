# session70 — the delivery review's dispositions, then the owner's call on `REC-01`

Read `agents/sessions.md` and `agents/validation.md` first, then the predecessor
report [`../session69/report.md`](../session69/report.md).

Baseline: **1055 / 0 / 0 / 10** (LuaJIT 2.1 in the container; **the owner runs
PUC Lua** — container-green is not their-machine green, and any suite claim
states its interpreter). A different count is a finding, not a go-signal.

## Carryover — what changed under you

**`FIX-01` is complete, and the brace it lived in is now empty.** With
`FIX-02` (b) scheduled after `ACC-02` by the owner's own ordering, **nothing in
the sequence stands between here and `REC-01`/`MERGE-01`** — the three example
repos, which are separate repositories with their own remotes and their own
PRs. That is owner territory. **Do not open it unprompted; raise it.**

**A new rule landed in the persistent conventions** (`conventions/docs.md`,
*Rules*): **an ephemeral *id* is a citation too.** A bare sprint id resolves
only inside `wip/77`, so it dangles the day that tree is deleted, and unlike a
broken link it greps clean. It applies to everything you write from now on: say
*what was decided and when*, not *which row did it*, in any document under
`doc/` that is not under `doc/development/wip/`. The backlog this created is
registered (`T-EPHEMERAL-IDS`) and swept at **`DOC-01-06`**, not by you.

## Your task

**Open by executing the dispositions on session69's delivery-level review**, in
`validation/reviews/`. Read it in full before acting: the previous two sessions
both found that a review's dispositions are where the real instructions are, and
session68's reviewer was interrupted before writing its own table.

**Then stop and raise `REC-01`/`MERGE-01` with the owner.** Present the
sequencing question; do not start the merges. If the owner hands you something
else instead, that is the session.

## What session69 learned the hard way, stated so you do not repeat it

- **The warning does not work; the command does.** Session68 was told *"a count
  in a document is a snapshot and yours will be too"* and reproduced the error.
  Session69 wrote that sentence into its own note — and then filed a debt entry
  whose count came from a hand-listed directory set instead of the corpus rule,
  quoted after its own sweep had edited four of those files. **Record the exact
  command beside any number you state**, so the next reader re-derives instead of
  trusting. That is now done on `T-EPHEMERAL-IDS`; do it everywhere.
- **Say which grep you mean.** A raw `REMARK` search returns 31 where the marker
  gate returns 29 — two of them are prose *about* markers. Both numbers are
  right and they answer different questions. An unqualified count invites the
  owner to correct you with their own, equally right, figure.
- **Rewriting prose to answer a remark re-reads the code, and that is where the
  yield is.** The one real defect `FIX-01` found was a call path that had drifted
  under a paragraph nobody suspected. A reflow would have preserved it intact.
- **A count is not a scope statement.** `FIX-01-01`'s "eight" was three live
  sites; four had been paid by passes that never ticked the row.
- **Some citations cannot be repointed, and noticing that is the work.** Six wip
  paths stayed because in those entries the wip file **is the defect's location**,
  not a reference. They went to `LEDGER-02` with the reason attached.
- **Do not assert a number in a commit that lands before the change that makes
  it true.** One cell claimed 24 markers at 26 and reached 24 an hour later.

## Standing constraints

- Suite green at every commit, count and interpreter stated in the message;
  commit at the seam, one concern each; **never push** — the platform repo or
  either nested one.
- **Stage explicit paths.** `git add -u` is how an unrelated change rides in;
  `git add -A` in `/repo` commits the nested example repos as gitlinks.
- A behaviour change is **never** documented in the commit message alone.
- **A finding goes to the debt ledger the moment it is found.** Fixed the same
  day, the record is the RETIRED entry; it lands either way.
- **Before filing a surface finding, check whether a decision or a rule already
  draws that line.**
- **A line citation is verified by resolving the exact line, or not at all.**
  Prefer naming a function.
- **Dropping or renaming a heading owes a citation sweep in the same commit**
  (`agents/rules/roadmap.md` §5) — and *keeping* a heading is a legitimate
  outcome of that check, as `FIX-01-01` decided for `configure(config)`.
- Comments cite canonical `doc/…` and a **named section**, never `wip/77`.
- Say **widget**, not "field" or "overlay". *"Prompt"* is a known fifth name and
  is `FIX-02-09`'s to rule; do not pre-empt it.
- The owner also works in this tree. Never sweep their unrelated working-tree
  changes into a commit — the known scratch is `claude.sh`, `src/STEPS.md`,
  `repos.txt`, `worklog.md`, `broken-busted/`, `input-pr-slices.tar.gz` and the
  nested example repos.

## Sub-agents — read before you spawn anything

**The host has no CPU or memory ceiling, and agent fan-out has taken it down
three times** — twice on 2026-09-02 and again on 2026-09-03. Every spawn prompt
carries an explicit **"you are a leaf agent, do not use the Agent tool"** clause
**with its reason stated**, or it reads as fussiness and gets routed around. Run
sub-agents **one at a time**, never in parallel worktrees. Pass the model
explicitly — **Sonnet** for anything mechanical or scoped; the **Fable tier is
retired and unavailable**; hard judgment calls are Opus work and are usually
better done in-session than spawned. When the owner reports the machine under
load, **ask before spawning at all**, including the closing order's own two
reviews.

## Environment facts, stated because they qualify every claim you will make

- **`lua-lsp` is healthy here and still under-reports.** A confident *"No
  references found"* has been wrong three times in this workspace. Cross-check
  every negative with `git grep`.
- **Markdown is not bound by the 64-character limit** — `agents/rules.md` scopes
  it to *coding*. Comment blocks in `.lua` are.

## Open with the owner, deliberately not taken

- **`REC-01`/`MERGE-01` sequencing** — the three example repos, their own PRs.
- **`design/` amendment for `FIX-02-22`** — recommendation on disk (*do not
  amend*), owner-gated either way:
  `validation/notes/FIX-02-22-frozen-design-sites.md`.
- **The container resource ceiling** — `memory.max` and `cpu.max` are both
  `max`. Compose stack under `implementation/docker`.
- **Session66's F6** — `ROADMAP.md`'s section bodies no longer run in sequence
  order. A large diff in a file the owner reads; theirs to call.
- **`OP-02`** — optional, does not delay the release: recover the truncated S68
  delivery review.
