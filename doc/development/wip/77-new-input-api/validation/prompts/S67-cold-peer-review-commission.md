---
description: Commission — cold peer review of session67's work (FIX-02 half (a), eight rows), by a reader with no access to the session's reasoning
status: prompt of record
audience: sub-agent (Opus, cold)
authored: llm
session: 67
date: 2026-09-02
---

# Commission — cold peer review of session67

You are reviewing another session's work **cold**. You have the repository, the commits, and the
mandate that session ran under. You do **not** have its reasoning, and that is deliberate: the
value you add is forming your own view of the same evidence and finding where the session's
conclusions do not follow from it.

## What you must NOT read

- `doc/development/wip/77-new-input-api/implementation/sessions/session67/track.md` — the running
  narrative. **Do not open it.** It contains the session's own account of every decision, and
  reading it collapses you into agreeing with it.
- Any `report.md` in `sessions/session67/` if one appears.

Everything else is fair game, and the commit messages **are** in scope — they carry the session's
stated justifications and are exactly the claims you are testing.

## What you SHOULD read

- `agents/validation.md` — the phase's rules (commit discipline, citation rules, the ledger rules,
  sub-agent hygiene, the strategic frame).
- `doc/development/wip/77-new-input-api/implementation/sessions/session67/prompt.md` — the mandate
  the session booted under, including its standing constraints. **Judge against this.**
- `doc/development/wip/77-new-input-api/ROADMAP.md` — `FIX-02`'s section, especially the
  "Execution order" note and the rows marked complete.
- The commit range **`4a0b4dd0..HEAD`** — 25 commits. `git log`, `git show`, `git diff` are your
  primary instruments.
- The files the work landed in, as they now stand.
- `agents/rules/ledgers.md`, `agents/rules/roadmap.md`, `agents/rules/commenting.md` where a
  commit claims to be following one.

## What the session claims to have done

Eight roadmap rows in `FIX-02` half (a), plus one sub-agent commission. In its own words, from the
commits: `-22`/`-13` (a false content-preservation claim, and an undocumented `hide()`), `-25`
(a test pinning that the surface's accepted config keys and the widget's applied keys agree),
`-06` (a stale keyboard/pointer divergence claim), `-23` (the guide never named the `is_shown`
guard), `-24` (the mermaid diagrams), `-03` and `-04` (two verification rows). Three debt entries
retired; two filed; one owner ruling recorded as a decision.

## The questions to answer, in order of what they are worth

1. **Is every factual claim in the commit messages and the landed prose actually true?** This is
   the core of the job. The session made many assertions of the form *"X does not exist"*, *"the
   suite pins Y"*, *"this was identical at the PR base `3256aac`"*, *"exactly one line was ours"*.
   **Check them.** `git grep <symbol> 3256aac` is how the base claims are testable. A claim that
   is *nearly* true is a finding.
2. **Where a row was declared complete, is it?** Read each row's original filing (it is preserved
   in the cell under *"Original filing"*) and ask whether what landed actually discharges it, or
   whether the session redefined the row to match what it did.
3. **Did anything get missed the same way the session says other passes missed things?** It
   repeatedly found that a claim survived in one more place than a row named. Look for a survivor
   it did not find — in `doc/`, `src/`, `tests/`, the planning tree, and the nested example repos
   under `src/examples/`. **Search where the citations are, not only where the code is.**
4. **Are the ledger moves right?** Three entries moved ACTIVE → RETIRED. Does each resolution
   actually resolve the entry as filed? Were the slug citations swept — and did the sweep miss
   any? Is `ACTIVE` legitimately empty, or was something retired that should not have been?
5. **The one code change.** `tests/input/input_config_key_agreement_spec.lua` reads the accepted
   key set out of the surface by **upvalue name**, via `debug.getupvalue`. Judge that: is it
   sound, is it too clever, does it actually fail when it should, and is the claim that a
   hand-written list "cannot fail on a key it does not know about" correct? The session says it
   mutation-tested this; **re-run the mutation yourself** and report what you saw. Restore the
   file afterwards (`git checkout -- <file>`) and confirm the tree is clean.
6. **Scope discipline.** Did the session stay inside its mandate? It declined a rename and
   declined to amend a frozen tree; it *did* mark seven files belonging to another author, and
   *did* delete one line from one of them. Were those calls right, and were the ones it declined
   declined for good reasons or convenient ones?
7. **Anything that is a phantom** — a problem that exists in the analysis but not in the code or
   in use — or **unratified vocabulary the session minted for itself**. Check any new term against
   the PR base: absent there means it is this branch's own.

## How to work

- **Verify in code, not from prose.** The single most valuable thing you can do is resolve a
  claim against the source and find it wrong.
- **`lua-lsp` (MCP) is available and is the correctness tool for Lua** — definitions, references,
  hover, diagnostics over a real AST of `/repo`. grep to find candidates, LSP to resolve them,
  and **cross-check both ways**: this session recorded two occasions where LSP `references`
  returned empty for a symbol that grep proved had callers. Treat an empty LSP result as a hint,
  never as proof of absence. A `broken pipe` error means the language server died even though the
  connection reports "connected" — **an errored query is not an empty result**; report the outage
  rather than working around it.
- **Resolve every line citation you rely on, or do not cite one.**
- The suite is `busted tests` and should be **1050 / 0 / 0 / 10** (LuaJIT 2.1 in this container).
  Confirm it. A different number is a finding.
- Be willing to return "this holds". A review that manufactures findings to look thorough is worse
  than one that clears the work — but say *what you checked*, so "holds" is load-bearing.

## Deliverable

Write **one** file:
`doc/development/wip/77-new-input-api/validation/outcomes/S67-cold-peer-review.md`

With YAML front matter in this repo's convention (`description`, `status: review report`,
`audience: developer`, `authored: llm`, `session: 67`, `date: 2026-09-02`).

Structure: a **verdict paragraph** first (does the work hold; how many findings and of what
severity; was the LSP healthy; was the suite green). Then **numbered findings**, each with: what
is claimed, what you checked, what you found, and how sure you are. Then a short section on
**what you checked and found correct** — the negative space matters, because it tells the reader
which claims are now load-bearing. Rank findings by blast radius, not by how interesting they are.

## Rules that apply to you

- **Do not edit any file** except your one deliverable. If you mutate a file to test something,
  restore it and say so.
- **Do not `git add`, `git commit`, or `git push`.**
- Do not fix what you find. Report it. Dispositions belong to the parent session and the owner.
- If you cannot verify something, say so explicitly rather than softening it into a judgement.
