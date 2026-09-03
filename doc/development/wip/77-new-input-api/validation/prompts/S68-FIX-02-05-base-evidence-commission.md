---
description: Commission — per-entry base evidence for every RETIRED debt entry, the mechanical half of FIX-02-05
status: sub-agent commission
audience: developer
authored: llm
session: 68
date: 2026-09-03
---

# Commission — `FIX-02-05`'s evidence pass (Sonnet worker, session68)

**Model: Sonnet, explicitly.** Prompt of record (hygiene c). The worker's deliverable is
`validation/outcomes/S68-FIX-02-05-base-evidence.md`; classification and the roadmap row are the
parent session's.

---

## What you are doing

You are gathering **evidence**, not making rulings. For every entry in the `RETIRED` section of the
two debt registers, answer two mechanical questions and show the command that answered each:

- **(a) Is the resolution real?** The entry claims something was fixed, ratified or found not to be
  debt. Does the artifact it names exist at **HEAD** — the function, the test, the doc section, the
  removed code?
- **(b) Did the subject exist at the PR base `3256aac`?** i.e. was this defect something the outside
  world could have met, or did this branch introduce it and pay it before release?

The two questions are one pass over each entry on purpose. **Do not classify with authority** —
propose a classification and say what would change it.

## The two files, and the exact scope

- `doc/development/technical_debt/input.md`, everything under `## RETIRED`
- `doc/development/technical_debt/general.md`, everything under `## RETIRED`

Nothing above `## RETIRED` in either file is in scope. Do not open anything under
`doc/development/wip/77-new-input-api/` except to write your deliverable — the session tracks,
prompts and reviews there are not your input and will cost you context for nothing.

**Count the entries first** (`### ` headings under `## RETIRED` in each file) and put the number
with today's date at the top of your deliverable. Earlier documents say 20, 46, 47, 51 and 55; every
one of those was right when written and the section grows whenever a sprint pays into it. **Your
count is the one that will be used.**

## For each entry, record

| field | what goes in it |
|---|---|
| **Heading** | verbatim, plus `file:line` |
| **Claim** | the resolution or status the entry asserts, one sentence, quoted where short |
| **(a) Resolution at HEAD** | `HOLDS` / `PARTIAL` / `DOES NOT RESOLVE` / `NOT CHECKABLE` + the command and its result |
| **(b) At base `3256aac`** | `PRESENT` / `ABSENT` / `CHANGED SHAPE` + the command and its result |
| **Self-declared provenance** | does the entry itself say pre-existing / ours / cite the base? quote it |
| **Proposed classification** | `PRE-EXISTING` / `INTRODUCED-IN-BRANCH` / `MIXED` / `CANNOT TELL` + one line of why |

**`MIXED` is a real answer and is under-used.** A pre-existing bound that this branch's own wrappers
made reachable is both. When you reach for `CANNOT TELL`, say precisely what you could not
establish — that sentence is more useful to the parent than a guess.

## How to run the checks — and the two traps

**Use `git grep` with a pathspec, always.** `git grep -n "subject" 3256aac -- src doc tests` reads
the base directly; there is no need to check anything out, and you must not.

**Never recurse from `/repo` root.** It holds 63 MB of `.git`, 28 MB of binary assets under
`src/assets/`, a tarball, and five nested git repositories. A bare `grep -r` or `find` from the root
is the one command that can make this run expensive.

**Trap 1 — the subject is not the wording.** Entries name their subject in prose that has since
changed. Grep for the *identifier* (`occupy_input`, `PER_SHOW_KEYS`, `discard_draft`), not for the
sentence. If an identifier was renamed inside this branch, the base check must use the **base's**
name, and finding zero hits for today's name proves nothing. Say when you had to hunt for the old
name, and what you searched.

**Trap 2 — absence is the hardest claim here** and it is most of your output. `git grep` finding
nothing at `3256aac` is evidence only if you searched for something that would have existed. Before
writing `ABSENT`, ask what the base *would* have called it, and search that too. Record every
pattern you tried, including the ones that found nothing.

## `lua-lsp` is available, and it under-reports in this workspace

An MCP language server (`lua-lsp`) gives definitions, references and diagnostics over a real AST of
`/repo`. Use it when you have a **symbol in hand** and need to know where it is defined or who calls
it — it beats grep for that. Two rules:

- **Query it serially.** It is one shared server; do not fire parallel queries at it.
- **An empty `references` result is a hint, never proof.** It has produced three confident,
  error-free *"No references found"* answers in this workspace for symbols that demonstrably have
  callers. **Cross-check every negative with `git grep` before writing that nothing uses something.**
- A **`broken pipe`** error means the language server child is dead while the MCP link still reports
  connected. **An errored query is not an empty result.** If you see it, say so in your deliverable
  and fall back to `git grep` — recovery needs the human, so do not try to restart anything.

## Hard constraints on your behaviour

These bind what you *do*, not only what you conclude. Anything not listed here as permitted is not
permitted.

- **Do not use the `Agent` tool. Work sequentially, yourself.** This is not fussiness: on 2026-09-02
  two sub-agent spawns took this container's host to 100% CPU and a hard reboot within ~20 seconds,
  and recursive agent fan-out is the leading explanation. The container has **no CPU or memory
  ceiling**, so a runaway takes the host machine down, not just this box.
- **Write no file except your deliverable.** No edits to the registers, the roadmap or any source
  file — you are the evidence half; the parent applies.
- **Never `git add`, `commit`, `push`, `checkout`, `stash`, `reset` or touch `.git`.** Read-only git
  only: `grep`, `show`, `log`, `diff`.
- **Do not run the test suite** and do not install anything. No `luarocks`, no environment
  bootstrapping. Keep the footprint minimal.
- **Write incrementally.** Work in batches of about eight entries and append each batch to the
  deliverable as you finish it, so an interruption costs one batch rather than the run.

## Deliverable

`doc/development/wip/77-new-input-api/validation/outcomes/S68-FIX-02-05-base-evidence.md`, with YAML
front matter (`description`, `status: sub-agent outcome`, `audience: developer`, `authored: llm`,
`session: 68`, `date: 2026-09-03`).

Open it with: the entry count per file and today's date; how many you propose in each
classification; and — most valuable — **the entries whose resolution claim you could not confirm**,
listed first and by name. That short list is what the parent will work from.

Finish with **what you did not verify**, honestly. An unchecked claim named is worth more than a
checked claim overstated.
