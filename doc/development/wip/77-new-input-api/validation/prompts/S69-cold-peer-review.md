---
description: Commissioning prompt — cold Sonnet peer review of session69's own changes (step 1 of the closing order)
status: active
audience: developer
authored: llm
session: 69
date: 2026-09-03
---

# Cold peer review — session69's changes

You are reviewing **one session's diff** in the `compy` repository (LÖVE2D, Lua).
Repo root `/repo` is your cwd. This is step 1 of a three-step closing order:
**you read the diff, not the plan.** A later, separate reviewer reads the plan.

## Hard operating rules — read these first

- **You are a leaf agent. Do NOT use the `Agent` tool. Do not spawn sub-agents
  of any kind. Work sequentially, yourself.** This is host protection, not
  style: this container has **no CPU or memory ceiling**, so a fan-out of agent
  processes takes the *host machine* down rather than dying inside the box. It
  has happened three times — twice on 2026-09-02 (hard reboot within ~20
  seconds) and again on 2026-09-03. If you spawn agents, you will very likely
  kill the machine this repository is on.
- **Do not push. Do not commit.** Do not edit any file under `src/`, `tests/` or
  `doc/` — you produce a report, nothing else.
- Keep your search footprint small: prefer `git grep` and `git show` over
  recursive greps from `/repo` root (63 MB `.git`, 28 MB `src/assets`, and five
  nested example repositories live under it).
- **`lua-lsp` MCP is available** — defs / refs / diagnostics / hover over a real
  AST of the `/repo` workspace. Use it when you need to resolve a Lua symbol or
  prove who calls what; `git grep` is the right opening move for finding
  candidates. After any `.lua` edit (there should be none) the server needs a
  beat to re-index. **A `broken pipe` error means the language server child is
  dead — that is an outage, not an empty result.** Surface it in your report
  rather than working around it; recovery needs the human.
- Query `lua-lsp` **serially**, one call at a time. It is one shared server.

## What to review

`git log --oneline 1a864137..HEAD` — **28 commits**, all documentation. Read the
full diff (`git diff 1a864137..HEAD`) or commit by commit, as you prefer.

The session had two halves:

1. **Dispositions on a prior review** plus five owner rulings (commits up to
   `9eb91de2`), led by a different agent that then crashed mid-flight.
2. **`FIX-01`, a citation-hygiene sprint** — three rows, executed by the current
   session after reconciling the crashed one's leftovers.

Read `implementation/sessions/session69/track.md` for what the session believed
it was doing. **Treat it as a claim under review, not as context you accept.**

## The question you are answering

**Integrity and sanity.** Not "was this the right work" — that is the next
reviewer's. Yours is narrower and entirely checkable:

1. **Do the claims hold against the code and the tree?** Every factual assertion
   in a commit message, a ledger entry, a roadmap cell or a rewritten paragraph.
   Resolve it. The session rewrote prose about `SearchController`,
   `EditorController`, `UserInputController` and the `compy.input` surface —
   **verify those against `src/`**, not against the prose they replaced.
2. **Do the citations resolve?** Section names cited from `src/`, `tests/` and
   `doc/` must name headings that exist. The session **kept** two headings
   (`show(config)`, `configure(config)`) specifically because ten citations name
   them — check that claim, and check that nothing it *did* rename left an
   orphan.
3. **Does the arithmetic close?** The session states counts constantly: 3 live
   sites of 8, 20 paths, 12 session numbers, 7 `FR-n`, 119 sprint ids, 24
   markers across 10 files, 29 at boot. **Re-derive each one.** A count that is
   a snapshot must say so. Where a count disagrees with yours, say which grep
   you ran — the previous session was burned by a character class that silently
   filtered its input, and by a case-sensitivity assumption.
4. **Is anything internally contradictory?** Between two commits, between a
   commit message and its diff, between the roadmap and the ledgers, between the
   track and what landed.
5. **Did anything get lost?** The session *deleted* prose: an inventory of the
   `compy.input` surface, `show`/`configure` field lists, evidence-document
   links, `FR-n` ids, session numbers. For each, the claim is that the
   information survives elsewhere (`doc/input_api.md`, an inline count, a
   commit id, a spelled-out requirement). **Check that it actually does.**

## Two specific things to be suspicious of

- **Deleting a pointer is not the same as preserving what it pointed at.** The
  session removed links to documents under `wip/` on the grounds that the
  surrounding prose already carried the substance. Sample a few and confirm.
- **A rewrite that answers a reviewer's remark re-reads the code, and the
  session found one drifted claim that way.** There may be more it did not
  notice, in the same paragraphs it touched.

## Deliverable

Write your report to
**`doc/development/wip/77-new-input-api/validation/outcomes/S69-cold-peer-review.md`**
with a YAML front-matter block (`description`, `status: active`,
`audience: developer`, `authored: llm`, `session: 69`, `date: 2026-09-03`).

Structure: a one-paragraph verdict, then numbered findings **F1…Fn**, each with
**what is claimed / what is true / how you checked (the exact command) /
severity**. Severity is `blocking` (a false statement now shipping),
`correction` (wrong but harmless), or `note`. **If you find nothing in a
category, say so explicitly** — a silent category reads as unchecked.

End with a short **"What I could not check"** section. That section is not a
failure; an unstated gap is.

Do not fix anything. Report.
