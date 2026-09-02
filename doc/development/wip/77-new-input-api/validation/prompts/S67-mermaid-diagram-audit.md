---
description: Commission — field-by-field audit of doc/mermaid/ against the real classes (FIX-02-24 / T-MERMAID-MODEL)
status: prompt of record
audience: sub-agent (Sonnet)
authored: llm
session: 67
date: 2026-09-02
---

# Commission — audit `doc/mermaid/` against the classes as they exist today

**You are producing EVIDENCE, not edits.** Do not modify any file under `doc/` or `src/`. Your
single deliverable is one new file (path below). Dispositions are the parent session's call, not
yours — where you are unsure whether something is wrong, record both readings and say which facts
you verified.

## Context, in one paragraph

The repo is a LÖVE2D project at `/repo` (cwd). A feature branch reworked the input API. A debt
entry (`doc/development/technical_debt/input.md`, `T-MERMAID-MODEL`) says the mermaid class
diagrams still show `oneshot: boolean` on `InputModel` / `UserInputModel` — a constructor argument
the feature deleted — and that `custom_label` is missing from the same blocks. **Nobody has walked
these diagrams since the input work.** So the row is *verify all three against the current
classes*, not *delete one line*. That is your job.

## Scope — re-derive it, do not trust the row's list

The row names `doc/mermaid/input.md`, `doc/mermaid/editor.md`, `doc/mermaid/classes.md`. **Audit
every `.md` under `doc/mermaid/`** — there are seven — because a count in a row is a lower bound
written by someone who could only grep the obvious form. If a file carries no class block, say so
in one line and move on.

## What to produce, per class block

For **every** `class X { ... }` block in every diagram, a table with one row per member:

| member as written | exists in code? | where (file, symbol) | verdict |

`verdict` is one of: **OK** · **STALE** (named in the diagram, absent from the class) ·
**RENAMED** (give the current name) · **MISSING** (present in code, absent from the diagram) ·
**MALFORMED** (a syntax problem in the diagram itself, e.g. a misplaced colon) ·
**UNVERIFIABLE** (say precisely why).

Also, per block: does the **class itself** still exist under that name? Several diagrams may name
types that were renamed or dissolved. And per file: are the relationship arrows
(`A --* B`, `A --|> B`) still true?

## How to establish "exists in code" — this is the part that must be right

- **`lua-lsp` (MCP) is available to you and is the correctness tool.** It runs
  `lua-language-server` over a real AST of the `/repo` workspace. Use `definition` and `hover` to
  resolve a symbol you already have; use `references` to ask who uses it. **grep is the right
  opening move** to find candidates, then switch to the LSP to resolve them.
- **Cross-check with grep as a backstop.** Lua is dynamically typed and LSP references can be
  incomplete; a thin result you trust will hide a caller. LSP is a strong hint, grep confirms.
- **Failure mode you must report, not work around:** a `broken pipe` error means the
  `lua-language-server` child is dead even though the MCP connection still reports "connected".
  **An errored query is NOT an empty result.** If that happens, say so plainly at the top of your
  deliverable and note which findings were reached by grep alone. Do not silently substitute.
- After any edit to a `.lua` file, `sleep 1` before querying the LSP (it re-indexes). You should
  not be editing any, so this is unlikely to apply.
- Fields on these models are typically assigned in a constructor or `new`/`init` function and via
  `self.<name> =`. Check both the assignment sites and the type annotations (`--- @field`,
  `--- @class`), and say which of the two you used when they disagree — **a disagreement between
  an annotation and an assignment is itself a finding.**

## Two things to flag rather than resolve

1. **`doc/mermaid/input.md` is headed "### Planned refactor"** and its prose describes an intended
   change ("Interpreter is out, instead create a History triplet…"). It may be a **design sketch,
   not a class reference** — in which case "shows a field that no longer exists" is the wrong test
   for it entirely. **Do not decide this.** Report: what the file claims, whether the refactor it
   describes actually happened (check whether `InterpreterModel` and a history triplet exist
   today), and note that the disposition is the parent's.
2. Any file that looks like scratch or a dated record rather than a live reference — say so and
   give your reason. Do not apply a live-reference test to something that is not one.

## Deliverable

Write **one** file: `doc/development/wip/77-new-input-api/validation/outcomes/S67-mermaid-audit.md`

Structure it as: a one-paragraph verdict up top (how many blocks, how many members, how many not
OK, and whether the LSP was healthy throughout), then one section per diagram file, then a closing
list of **the specific edits you would recommend**, each with the evidence line that justifies it.
Recommendations only — the parent applies them.

Add YAML front matter matching this repo's convention:

```
---
description: <one line>
status: audit report
audience: developer
authored: llm
session: 67
date: 2026-09-02
---
```

## Rules that apply to you

- **Do not edit anything.** Evidence only, one new file.
- **Do not run `git add`, `git commit`, or `git push`.** The parent commits.
- **Verify a line citation by resolving the exact line, or do not give one.** An unsupported or
  errored query is not an empty result.
- Markdown is not bound by any line-length limit here. Be precise over brief: a table row that
  says which symbol you resolved is worth more than a summary sentence.
- If you find something outside this scope that looks wrong, **note it in a final "Out of scope,
  seen in passing" section** rather than chasing it.
