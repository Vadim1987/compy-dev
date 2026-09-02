---
description: Commission — cold delivery-level revalidation of session67, including roadmap integrity and the path to release
status: prompt of record
audience: sub-agent (Opus, cold)
authored: llm
session: 67
date: 2026-09-02
---

# Commission — delivery-level revalidation of session67

You are revalidating another session's output **cold**, at the **delivery level**. This is not a code
review and not a second peer review — one already ran and cleared the facts
(`validation/outcomes/S67-cold-peer-review.md`, which you **should** read; do not repeat its work).

Your question is the one it did not ask: **does this session leave the feature closer to a
releasable PR, and is the plan it hands forward still sound?** Work
[`agents/rules/revalidation.md`](../../../../../../agents/rules/revalidation.md)'s six checks — they
are the structure of your report.

## RULE 0 — you are a leaf agent

**Do not use the `Agent` task tool. Do not spawn sub-agents, helpers, or parallel searchers, for any
part of this, including "just to search".** Work the checks yourself, one at a time, sequentially.

This is a hard operational limit. This container has 2 CPUs and 3.8 GB of RAM, no swap, and **no
cgroup ceiling**, so it can consume its host. Two spawns of the *previous* review took the host to
100% CPU with maximum disk read and active swapping within ~20 seconds, each needing a hard power
cycle, and neither wrote a line. Nothing here needs parallelism: the whole commit range diffs to
~3000 lines and the suite runs in 2.3 s. If the job feels too large to do alone, **say so in the
deliverable and stop — do not delegate it.**

Also: **scope every search** — never recurse from `/repo` root (63 MB of `.git`, 28 MB of binary
assets under `src/assets/`, a tarball, five nested repositories); prefer `git grep`. **Query
`lua-lsp` serially** — it is one shared `lua-language-server` process.

## What you must NOT read

- `implementation/sessions/session67/track.md` — the session's running narrative of its own
  reasoning. **Do not open it.** Reading it collapses your independent view into agreement.

`session67/report.md` **is** in scope — it is the handover artifact you are judging, and whether it
tells the truth about the session is part of your job. So is `session68/prompt.md`.

## What you SHOULD read

- `agents/rules/revalidation.md` — your checklist, and the shape of your report.
- `agents/validation.md` — the phase's rules, the **strategic frame**, commit discipline, ledger and
  citation rules, sub-agent hygiene.
- `agents/rules/roadmap.md` and `agents/rules/ledgers.md` — the two rule files this session's work
  is measured against most directly.
- `implementation/sessions/session67/prompt.md` — the mandate it ran under. **Judge against this.**
- `implementation/sessions/session67/report.md` and `sessions/session68/prompt.md` — the handover.
- `doc/development/wip/77-new-input-api/ROADMAP.md` — especially `FIX-02`'s "Execution order" note,
  the eight rows marked complete, and everything downstream that depends on them.
- `validation/plan.md` — the *why* beside the roadmap's *what next*.
- `validation/outcomes/S67-cold-peer-review.md` — what has already been checked, so you do not
  re-check it.
- The commit range **`2986f028..ed4cef41`** — 30 commits.

## The questions, in order of what they are worth

1. **Intent reconstruction.** In one sentence: what was session67 commissioned to achieve? Then say
   whether it did that, or something adjacent to it.
2. **Roadmap integrity — the heaviest check.** Eight rows were marked complete and their cells
   rewritten with disposition text.
   - Does each completed cell describe what actually landed, or has a row been **redefined to match
     what was done**?
   - `FIX-02`'s rows are **deliberately not renumbered** and are cited from live debt goals. Do all
     those citations still resolve to the row they mean?
   - The sequence is `{ FIX-01 · FIX-02 (a) · CHG-01 } → REC-01 → MERGE-01 → ACC-02 → FIX-02 (b) →
     FIX-03 → DEC-02 → LEDGER-02 → DOC-01 → ACC-03 → PR-01`. **Is it still coherent after this
     session?** Specifically: `FIX-02-05` must precede `CHG-01-03`, which names it as feeder; does
     anything session67 did move, block, or quietly discharge a downstream row?
   - Was anything **lost** — a row's original filing, a status fact, an obligation — the way
     session66's revalidation found a *"Gap closed"* fact deleted with a duplicated table?
3. **Ledger integrity.** Three entries moved ACTIVE → RETIRED and `ACTIVE` is now empty. Is that
   *true*, or did something get retired that is not actually resolved? Three BACKLOG entries were
   filed — are they filed at the right altitude, with the right slug decision (a slug is a
   commitment to fix, per `ledgers.md`)? Does `LEDGER-02`, which reads from these documents, still
   have the inputs it expects?
4. **Does this session move the feature toward the PR, or sideways?** The strategic frame in
   `agents/validation.md` is the measure: stakeholders asked for a *simpler and more robust input
   API*, and the PR must be reviewable from `doc/input_api.md` + the PR description **alone**.
   - The guide gained a `hide()` section and an `is_shown` guard paragraph. Do they serve a reader
     with no `wip/77` access, and is anything now **missing** that those additions imply?
   - A design requirement (hide/show content preservation) was **retired rather than implemented**,
     recorded on `D-CFG-BOUNDARY`. Is that recorded where a PR reviewer would find it, and does the
     justification hold up as something to put in front of a stakeholder?
   - Did anything expand scope or vocabulary beyond the ask without justification?
5. **Under-done vs over-done.** Where did this session stop short, and where did it do more than the
   row asked? It declined a rename, declined to amend a frozen tree, and marked seven files
   belonging to another author. Judge the calls — including the ones it *declined*, which are the
   easier place to hide a convenient decision.
6. **Artifact check.** Are the expected outputs present, complete, and non-truncated — the report,
   the successor prompt, the two commissions, the two outcomes, the notes, the new spec? Does
   `session68/prompt.md` hand forward what its session actually needs, or does it recite what
   sounded good? **Name anything it omits that you would have wanted.**
7. **The handover's honesty.** `report.md` claims eight rows closed, `ACTIVE` empty, 1050 tests, and
   a specific set of mistakes made. Spot-check the claims that a successor would build on without
   re-deriving. A handover that overstates is worse than one that is thin.

## How to work

- **Verify in the artifacts, not from the prose about them.** The most valuable thing you can do is
  resolve a plan-level claim against the roadmap, the ledger, or git, and find it wrong.
- The suite is `busted tests` and should be **1050 / 0 / 0 / 10** (LuaJIT 2.1 here). Confirm it.
- `lua-lsp` (MCP) is available for Lua symbol facts. An **empty `references` result is a hint, never
  proof of absence** — this repository has produced two false negatives. A `broken pipe` means the
  language server died while the connection still reports "connected"; **an errored query is not an
  empty result** — report the outage rather than working around it.
- **Resolve every line citation you rely on, or do not cite one.**
- Be willing to return "this holds" — but say *what you checked*, so the verdict is load-bearing.
  A revalidation that manufactures findings is worse than one that clears the work.

## Deliverable

Write **one** file:
`doc/development/wip/77-new-input-api/validation/reviews/S67-delivery-revalidation.md`

(Note the directory: `validation/reviews/`, which is where cross-session **judgment** documents live
— not `outcomes/`.) YAML front matter in this repo's convention: `description`,
`status: revalidation report`, `audience: developer`, `authored: llm`, `session: 67`,
`date: 2026-09-02`.

Structure: a **verdict paragraph** first (does the session leave the feature closer to release; is
the plan it hands forward sound; how many findings and of what severity). Then **numbered findings
F1…Fn**, each with: what was claimed or planned, what you checked, what you found, the correction
you propose, and how sure you are. Rank by **blast radius toward the release**, not by how
interesting they are. Then a short **"what I checked and found correct"** section — the negative
space tells the reader which parts are now load-bearing.

## Rules that apply to you

- **Do not edit any file** except your one deliverable. **Propose** corrections; do not apply them.
- **Do not `git add`, `git commit`, or `git push`**, and do not switch branches or touch the index.
- Dispositions belong to the parent session and the owner — `revalidation.md` §"After the checks"
  requires asking the human before proceeding, and in this arrangement *you* are not the one who
  proceeds. Report and stop.
- If you cannot verify something, say so explicitly rather than softening it into a judgement.
