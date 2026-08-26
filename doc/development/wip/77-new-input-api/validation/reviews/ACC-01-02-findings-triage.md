# ACC-01-02 — triage of the cold review's findings

**Input:** `../outcomes/ACC-01-02-cold-pr-review.md` (the cold reviewer's report) and
`../prompts/ACC-01-02-cold-review-commission.md` (its commission).
**Author:** session46 (parent). **Triage only — nothing here is fixed** (owner, 2026-08-26).

Every finding below was **re-verified in code by the parent** before being triaged. Two came back
materially different from how the reviewer framed them, which is why the rule exists: a sub-agent's
finding is a strong hint, not a fact.

**Proposed disposition: two sprints**, following the owner's own boundary — a defect that is
understood and mechanical is a `FIX` row; one that needs investigation or a design call earns a
focused sprint.

| | sprint | contents |
|---|---|---|
| **BUG-01** | runtime defects | two, both needing investigation before a fix can be sized |
| **FIX-02** | doc / process defects | five, mechanical once ruled on |

*(`FIX-01` stays as it is — citations, session numbers, the editorial list. These are a separate
batch from a separate source and mixing them would lose that.)*

---

## BUG-01 — runtime defects

### BUG-01-01 — `state.pending` outlives the project that set it

**Severity: major. Verified structurally; reachability NOT traced.**

`compy.input`'s private `state` — including `pending` — is built inside the `get_compy_input()`
closure (`src/controller/consoleController.lua:775`), which runs from `prepare_project_env`, which
is called **once**, from `ConsoleController.new` (line 80). So `pending` has **application
lifetime**, not project lifetime. A hidden `configure{ text = … }` stashes into it
(line 651) and is consumed by the next `show()` (line 665). I found no code clearing it.

**The consequence if reachable:** project A's stashed prompt or text opens inside project B's
widget — which contradicts this PR's own stated contract, *"Nothing a project installed survives
it."*

**Why it deserves investigation rather than a patch.** The obvious fix (clear `pending` at
teardown) is one line, but two things must be established first: whether the path is actually
reachable given how teardown re-seeds the surfaces, and whether `shortcuts` / `hooks` / `callbacks`
have the same hole — the reviewer asserted they are wiped and I did not confirm it.

**Compounding, and worth its own attention:** the debt-ledger entry covering this area justifies
accepting the debt on the premise that *"`compy.input` is rebuilt per project environment"* —
which the call graph above contradicts. **A ledger entry resting on a false premise is worse than
no entry**, because it closes the question. Re-check the premise, then the entry.

### BUG-01-02 — a highlighter cannot be un-set for the rest of a run

**Severity: major. Owner's read, 2026-08-26: "looks like a bug too." Not yet re-verified by the
parent — the one row here still resting on the reviewer's word.**

`merge_callback_keys` re-injects the sticky value because **nil is indistinguishable from absent**,
and the live highlighter is additionally mirrored onto the evaluator, which only `apply_config`
writes and only project stop clears. Net: having set a highlighter, a project cannot remove it.

**The design call this needs.** "Absent means keep, nil means clear" requires a sentinel, and a
sentinel is new vocabulary in an API whose whole mandate is *fewer* moving parts. The alternative —
an explicit `clear_highlighter` — is a new member. Neither is obviously right, which is precisely
why this is not a FIX row.

---

## FIX-02 — documentation and process defects

### FIX-02-01 — the owner's own review remarks would ship to stakeholders

**Severity: major, and the most consequential finding here. Verified: 10 sites.**

`> REMARK:` blocks are committed in two persistent docs that **ship in slice `3a`**:

| file | count |
|---|---|
| `doc/development/decisions/input.md` | 8 |
| `doc/development/tests.md` | 2 |

These are not editorial nits. Several are substantive challenges in the owner's own voice — one
argues Decision 5 should be discarded outright (*"I see no reason to treat widget separately — and
if we discard decision 5, codebase change would be minimal and won't change any behaviour"*),
others correct terminology that conflates inbound events with widget callbacks.

**Two separate problems, and the second is the reason this recurs:**

1. The remarks are unaddressed. Each needs a ruling, not deletion — one of them may change code.
2. **The marker gate never covered `doc/`.** It greps `src/` and `tests/` only
   (`agents/validation.md`, "Comment gate"). P11 closed that gate and reported it clean, correctly,
   because `doc/` was outside its scope. **Widen the gate**, or this recurs on the next feature.

### FIX-02-02 — the provenance convention is 83% unapplied

**Severity: minor as a defect, but the reviewer's framing was wrong and the real shape is bigger.**

The reviewer reported this as a contradiction *inside* the PR: slice `1a` adds an HTML comment that
slice `1b`'s new `conventions/docs.md` forbids. The convention **does** say it —
*"The block is the only place provenance is recorded. Do not re-add the HTML comment."*

**But that forbids the form, not the purpose**, and the purpose is preserved: `authored: llm` plus
`reviewed: none` carries exactly what *"authored By LLM; human-approved NOT YET"* carried. The
`reviewed` field's own description says so.

**What is actually wrong is that the migration was never finished.** Across `doc/` (wip excluded),
**53 documents**:

| form | count |
|---|---|
| front matter — the convention | **9** |
| HTML comment only — the retired form | **22** |
| both | 1 |
| neither | **21** |

All 21 files in slice `1a` are in the "HTML only" group; none has front matter, so this is an
**incomplete migration, not a duplicate**. The convention says *"Every document under `doc/` opens
with YAML front matter"* — 44 of 53 do not. Note `doc/development/smoke_checklists.md`, which this
feature added, is itself in the "neither" group.

**Scope ruling wanted:** migrate only what this PR ships, or the corpus. The second is larger than
this feature and arguably not ours.

### FIX-02-03 — `pong/README.md` is a 316-line diff hiding a 2-line change

**Severity: minor. Verified.** `git diff --numstat` reports **316/316**; with `--ignore-all-space`
it reports **2/2**. A line-ending rewrite (CRLF→LF) swallowed the real change. A reviewer sees a
whole-file rewrite in an example nobody touched and must either read 316 lines or trust it.

**Fix:** re-commit as the 2-line change, or keep the normalisation and split it into its own commit
so the letter of the rule that governs `1a` — *a mechanical pass ships separately from meaning* —
applies here too.

### FIX-02-04 — the CHANGELOG has no `Removed` section

**Severity: minor. Verified:** `## Unreleased` carries only `### Changed`.

Removal of the four polling globals is the single most breaking thing in this release and the
argument the PR leads with. A stakeholder scanning the CHANGELOG for what breaks finds nothing
under the heading they would look under.

### FIX-02-05 — byte-vs-character clamping split across two functions

**Severity: minor. NOT re-verified by the parent** — carried from the reviewer's report at its
word, and flagged so nobody treats it as established.

`set_cursor` and `is_at_limit` reportedly disagree about whether they clamp in bytes or characters.
If true it is a defect for any non-ASCII prompt. **Verify first, then size.**

---

## Already closed, recorded so the count reconciles

**The PR description drift** — the reviewer's blocker — was fixed in `e123ca9e` before this triage,
because it was the one finding that blocked nothing else and cost only prose. Both of its claims
were verified in code first: `compy.input.keys_pressed` does not exist in `src/`, and *"No pointer
shortcuts"* is contradicted by `projectInputController.lua:53` and by the comment at line 45 of the
same file (*"'ctrl+s' and 'ctrl+mouse2' are one vocabulary, not two"*).

## What the reviewer got right that is worth keeping

Not everything here is a defect, and the report's positive findings are evidence about the work:
the `xpcall` arity fix in `3d` means project raises previously vanished **with no error window at
all**; `on_limit_reached(direction, scope)` delivers more than the ask; the test slice drives the
real gateway rather than a simulation; and **`doc/input_api.md` is accurate exactly where the PR
description was not** — which is the artefact the strategic frame cares most about.
