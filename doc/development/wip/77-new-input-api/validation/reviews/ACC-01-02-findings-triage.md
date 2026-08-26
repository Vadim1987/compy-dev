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
| **FIX-02** | doc / process defects | five, mechanical once ruled on (`02-02` reduced to three files by owner ruling) |

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

**Severity: major, and the most consequential finding here. Verified: 14 sites** — the 10 first
reported came from a truncated grep. **Triaged in full: [`FIX-02-01-remark-triage.md`](FIX-02-01-remark-triage.md).**

`> REMARK:` blocks are committed in two persistent docs that **ship in slice `3a`**:

| file | count |
|---|---|
| `doc/development/decisions/input.md` | 12 |
| `doc/development/tests.md` | 2 |

**They were inventoried by TF2** (R080–R109, R166) and several were triaged. What failed was the
removal pass, and then the absence of any check over `doc/`. None of the 14 is stale.

These are not editorial nits. Several are substantive challenges in the owner's own voice — one
argues Decision 5 should be discarded outright (*"I see no reason to treat widget separately — and
if we discard decision 5, codebase change would be minimal and won't change any behaviour"*),
others correct terminology that conflates inbound events with widget callbacks.

**Two separate problems, and the second is the reason this recurs:**

1. The remarks are unaddressed. Each needs a ruling, not deletion — one of them may change code.
2. **The marker gate never covered `doc/`.** It greps `src/` and `tests/` only
   (`agents/validation.md`, "Comment gate"). P11 closed that gate and reported it clean, correctly,
   because `doc/` was outside its scope. **Widen the gate**, or this recurs on the next feature.

### FIX-02-02 — provenance: three files, not forty-four (owner ruling, 2026-08-26)

**Severity: nit. Scope settled by the owner; most of what the reviewer reported is not a defect.**

The reviewer reported a contradiction *inside* the PR: slice `1a` adds an HTML comment that slice
`1b`'s new `conventions/docs.md` forbids. The convention **does** say it — *"The block is the only
place provenance is recorded. Do not re-add the HTML comment."*

**But it forbids the form, not the purpose**, and the purpose survives: `authored: llm` plus
`reviewed: none` carries exactly what *"authored By LLM; human-approved NOT YET"* carried. The
`reviewed` field's own description says so.

**Owner ruling — the history is not a violation:**

1. the rubber-stamping was done in HTML;
2. the convention came **after** it;
3. **files added or changed later should respect it; older stamps may remain intact unless they are
   changed;**
4. and a formal violation is not worth displacing more important work.

So slice `1a` is not a defect at all — it faithfully reproduces a commit that predates the rule,
and re-cutting it to satisfy a later convention would misrepresent the history it exists to record.

**Applying rule 3 mechanically** — docs touched since the convention commit `8d665fe4` (2026-07-31)
that still lack front matter — gives **13**, which split by how much they are ours:

| group | count | disposition |
|---|---|---|
| **added after the convention** — unambiguously ours | **3** | the only ones worth doing |
| pre-existing, merely *changed* since | 10 | in scope by the letter of rule 3; **deferred under rule 4** |
| untouched since the convention | 31 | **not in scope** — rule 3 does not reach them |

The three:

- `doc/development/internals/examples/keyboard.md` (added 2026-08-07)
- `doc/development/smoke_checklists.md` (added 2026-08-12)
- `doc/tall_blocks.md` (added 2026-08-16)

All three ship in this PR, all three are ours, and the fix is a six-line block each. **That is the
whole row.** The 44-of-53 figure the survey produced describes the corpus, not a defect in this
work, and is recorded here only so nobody re-derives it and re-opens the question.

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
