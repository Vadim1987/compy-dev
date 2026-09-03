---
description: Commission — cold peer review of session68's own changes, for integrity and sanity
status: sub-agent commission
audience: developer
authored: llm
session: 68
date: 2026-09-03
---

# Commission — session68's peer review (Sonnet worker)

**Step 1 of the closing order** (`agents/validation.md`, *"Closing a session — the three-step review
order"*, owner directive 2026-09-03): commit, **peer-review the changes**, wrap, then the
delivery-level review. This is the first of the two, and it is the one that reads the **diff, not
the plan**.

---

## The question you are answering

**Do this session's changes hold up on their own terms?** Not *was the work worth doing* — that is
the next reviewer's question. Yours is narrower and entirely checkable:

- **Do the factual claims resolve against the code and the tree?** Line citations, function names,
  behaviour descriptions, base-commit claims (`3256aac`), counts.
- **Does the arithmetic close?** Suite numbers, entry counts, marker counts, "N of M" statements.
- **Is anything internally contradictory?** A document saying one thing where its neighbour — or its
  own next paragraph — says another. This session found two such pairs in the CHANGELOG; assume it
  made some of its own.
- **Do citations point at things that exist?** Named sections, slugs, roadmap ids, file paths.

## The range

`git log --oneline 3b93a50c..HEAD` and everything before it back to **`c610805b`** (the session's
base). Roughly twenty commits. `git diff c610805b..HEAD --stat` gives you the shape.

**Read the commit messages** — they carry the claims. A message asserting *"verified at
`controller.lua:67`"* is a claim you can check in one command, and messages here are unusually
specific on purpose.

## What this session did, in one paragraph, so you know what to be suspicious of

It executed nine dispositioned findings from a prior review, then shipped `compy.input.get_text()`
(five tests, one implementation), closed the `FIX-02` sprint's (a) half and the whole `CHG-01`
sprint, and verified all 56 `RETIRED` entries in the two debt registers against the PR base with a
delegated worker. It made a lot of small claims about a lot of files. **Its own stated failure modes
this session were: a set-difference method blind to deletions, an argument made in retired
vocabulary, and a workflow change committed under an unrelated message.** Assume the same class
recurs somewhere you can find.

## Specific claims worth your time (not an exhaustive list — find your own too)

1. **`get_text` returns a string, `nil` when hidden, `''` when empty.** Read the implementation and
   the five cases in `tests/input/input_cursor_text_spec.lua`. Do the tests actually pin what the
   guide and the CHANGELOG say? Is there a case the surface accepts that nothing covers?
2. **"The four evaluator objects were reachable at base and are withheld now."** Check both halves:
   `git show 3256aac:src/controller/consoleController.lua` for the absence of a withholding loop,
   and HEAD for its presence.
3. **"`project_env`'s keys went 23 → 17, and `astv_input` is the sixth removal."** Re-derive the
   two key sets yourself.
4. **"`F.reset()` is eleven executable lines, not nine."** Count them.
5. **The nine `PRE-EXISTING` classifications** listed in
   `validation/outcomes/S68-FIX-02-05-base-evidence.md` — spot-check three at base, your choice.
6. **The `smoke_checklists.md` sweep: "25 grep hits, 21 sites, four are the help overlay."** Verify
   the arithmetic and that no swept sentence changed meaning.
7. **`internals/examples/turtle.md`'s corrected mechanism** against `src/examples/turtle/main.lua`.
8. **Every roadmap row this session ticked** — does the cell describe what the commits actually did?
9. **The retired debt entries added this session** — does each preserve its original filing above
   its `Resolution`, per the register's convention?

## How to check, and the two traps

- **`git grep` with a pathspec**, and `git grep <pattern> 3256aac -- <paths>` to read the base
  directly. **Never recurse from `/repo` root** — 63 MB of `.git`, 28 MB of binary assets under
  `src/assets/`, a tarball and five nested repositories.
- **`busted tests` runs the suite** (mock_love, no display needed) and takes about three seconds.
  Run it once; the claim to check is **1055 / 0 / 0 / 10**.
- **Trap 1 — a citation that resolves to the wrong thing.** Check what a named line *says*, not that
  a line exists. Several ids in this tree resolve to rows that were renumbered.
- **Trap 2 — absence is the hard claim.** Before writing *"nothing does X"*, search for what it
  would be called if it did.

## `lua-lsp` is available and under-reports here

An MCP language server gives definitions, references and diagnostics over a real AST of `/repo`.
Use it when you have a symbol in hand. **Query it serially** — one shared server. **An empty
`references` result is a hint, never proof**: it has returned confident, error-free *"No references
found"* three times in this workspace for symbols with callers. Cross-check every negative with
`git grep`. A **`broken pipe`** means the language server is dead while the link still reports
connected — an errored query is **not** an empty result. Say so in your deliverable and fall back to
grep; recovery needs the human.

## Hard constraints on your behaviour

Anything not listed here as permitted is not permitted.

- **Do not use the `Agent` tool. Do not spawn anything. Work sequentially, yourself.** This is a
  strict rule protecting the host, not a preference: two sub-agent spawns took this container's host
  to 100% CPU and a hard reboot within ~20 seconds on 2026-09-02, and the container has **no CPU or
  memory ceiling**, so a runaway takes the machine rather than the box.
- **Write no file except your deliverable.** Fix nothing. You report; the parent applies.
- **Never `git add`, `commit`, `push`, `checkout`, `stash`, `reset`, or touch `.git`.** Read-only
  git only: `grep`, `show`, `log`, `diff`.
- **Install nothing.** No `luarocks`, no environment bootstrapping.
- **Write incrementally**, so an interruption costs one section rather than the run.

## Deliverable

`doc/development/wip/77-new-input-api/validation/outcomes/S68-cold-peer-review.md`, with YAML front
matter (`description`, `status: sub-agent outcome`, `audience: developer`, `authored: llm`,
`session: 68`, `date: 2026-09-03`).

Open with a **verdict in one line** — does the work hold — then the findings, **most serious first**,
each with: the claim as written, what you ran, what you found, and how sure you are. Then a section
listing **what you checked and found correct**, which is as useful as the findings and is what makes
the verdict weigh anything. Close with **what you did not verify**, honestly.

**A finding that turns out to be wrong costs the parent more than a missed one**, so state your
confidence plainly and separate *"this is wrong"* from *"I could not confirm this"*.
