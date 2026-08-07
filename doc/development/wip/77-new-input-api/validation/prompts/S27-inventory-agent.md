# S27 sub-agent prompt of record — remark inventory (mechanical extraction)

**Model:** Sonnet. **Spawned:** 2026-08-07, session27. **Nature:** mechanical,
read-only extraction. Triage/severity is the parent's job, NOT this agent's.

---

You are working in the LÖVE2D project **compy**, repo root `/repo` (your cwd).
This is a purely mechanical, **read-only** extraction task. Do not edit any
source, test, or doc file. Do not commit. Your single deliverable is one
markdown file you write at the end.

## Context you need

The project owner has just done a full code review of a large feature branch
(the "new input API", feature #77) and left **inline remarks scattered through
the codebase** as comments. They were added in these commits:

- main repo: `9cc0ef50` ("human(TF-2): code review"), and anything else newer
  than `89ae831d` that adds inline annotations;
- nested repo `src/examples/balloons`: commit `cb1dd26` ("human(TF2): code review");
- nested repo `src/examples/maze`: commit `aeabb73` ("human(TF2): code review");
- nested repo `src/examples/keyboard`: commit `6eb7919` ("human(TF2): code review feedback").

**The three `src/examples/{balloons,maze,keyboard}` directories are separate git
repositories** nested inside `/repo` (they are untracked from the parent's point
of view). Use `git -C src/examples/<name> show <sha>` to inspect their review
commits. They are in scope.

My job after you finish is to triage these remarks by severity and build a plan.
I cannot do that without a complete, verbatim, addressable inventory. **Your
value is completeness and fidelity, not interpretation.**

## What to extract

Every inline annotation the owner left. The dominant marker is `REMARK`, usually
written as `--> REMARK: ...` in Lua or as a line in markdown, but **do not assume
that is the only form**. Before extracting, spend a few minutes establishing the
full set of marker shapes actually present:

- diff the review commits (`git show 9cc0ef50`, and the three nested ones) and
  read the **added lines** — every added comment line is a candidate, whether or
  not it says "REMARK";
- also grep for other plausible markers: `REVIEW`, `TODO`, `FIXME`, `QUESTION`,
  `NOTE:`, `XXX`, `???`, `!!`, and any bare added comment that reads as a review
  note rather than as documentation.

Report which marker forms you found, and how many of each.

## Scope boundaries

- **IN scope:** `src/`, `tests/`, `doc/` (EXCEPT `doc/development/wip/`),
  `CHANGELOG.md`, `agents/`, and the three nested example repos.
- **OUT of scope:** everything under `doc/development/wip/` — that is the
  feature's own ephemeral working tree and its `REMARK` hits are historical
  records from earlier sessions, not the owner's current review. Do not extract
  them. (Mention the count you skipped, nothing more.)

## Deliverable

Write **`/repo/doc/development/wip/77-new-input-api/validation/outcomes/S27-remark-inventory.md`**.

Structure it as follows.

### Part 1 — summary

- Total remarks found, broken down by marker form and by area (src / tests /
  permanent docs / agents / CHANGELOG / each nested repo).
- Any file that carries an unusually dense cluster (say 5+), called out by name.

### Part 2 — the inventory

One numbered entry per remark, grouped by file, files ordered: `src/`, then
`tests/`, then `doc/`, then `agents/`, then `CHANGELOG.md`, then each nested
repo. Give every entry a **stable id** of the form `R001`, `R002`, … in the
order they appear in the document — I will refer to these ids in the plan.

Each entry:

```
#### R0NN — `path/to/file.lua:LINE`

> verbatim text of the remark, exactly as written, no paraphrase, no
> spelling correction, multi-line remarks reproduced in full

**Context:** 1–5 lines of the surrounding code or prose it attaches to
(enough that I can tell what it is talking about without opening the file).

**Asks for:** one factual sentence — what the remark literally requests or
questions. Where the remark is a question rather than an instruction, say so.

**Provisional kind:** one of `mechanical` / `prose` / `question` /
`architectural` / `unclear` — see below. This is a hint for me, explicitly
provisional; when torn between two, write both and say why.
```

Provisional kinds, loosely:

- `mechanical` — a rename, a move, a deletion, a formatting fix; no judgment needed.
- `prose` — the comment or doc text is wrong, stale, too verbose, or misplaced.
- `question` — the owner is asking something, not directing a change.
- `architectural` — it proposes or contests a change in the shape of the
  solution (routing, signatures, what is unified with what, what the API
  surface is).
- `unclear` — you genuinely cannot tell what is being asked.

**Do not assign severity or priority. Do not propose fixes. Do not judge whether
a remark is right.** If you notice something alarming, put it in Part 3.

### Part 3 — observations for the parent

A short list of things you noticed that I should know: remarks that appear to
contradict each other, remarks that reference a file/symbol/section that does
not exist, remarks whose subject you could not locate, clusters that clearly
belong to one theme. Facts and pointers only.

## Tools and correctness

- **The `lua-lsp` MCP server is available to you** — defs / refs / hover /
  diagnostics over a real AST of the `/repo` workspace. Use grep to find
  candidates, then the LSP to resolve a concrete symbol (where is it defined,
  who calls it). For this task you mostly need grep and `git show`, but if a
  remark names a symbol and you need to say what it attaches to, ask the LSP
  rather than guessing. (If you ever edit a `.lua` file — you should not on this
  task — `sleep 1` before querying the LSP, it re-indexes.)
- Verbatim means verbatim. Preserve the owner's typos, informal register, and
  line breaks. A paraphrase that "cleans up" a remark destroys its value to me.
- Line numbers must be correct as of the current working tree (`HEAD` =
  `c6a0778f` or later). Cite `file:line`.
- Do not run `busted`, do not modify the tree, do not commit, do not push.

Report back, briefly: total count, marker forms found, the path you wrote, and
anything from Part 3 that you think is urgent.
