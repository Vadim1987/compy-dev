# Sub-agent prompt of record — LEDGER-01: split the decisions ledger into ACTIVE / RETIRED

**Spawned session49, 2026-08-27. Model: Sonnet (explicit)** — mechanical sectioning of an existing
document, no design judgment. Owner directive: the decisions doc becomes one of three ledgers giving
project-altitude visibility, and is split into **ACTIVE** and **RETIRED**.

---

You are restructuring one document: `/repo/doc/development/decisions/input.md` (1587 lines). This is
the **persistent** decisions ledger for the input subsystem — see
`/repo/doc/development/decisions/README.md` for what the directory is for.

## The task

Split the decision entries into two sections, **without changing the content of any entry**:

- **`## ACTIVE`** — decisions in force.
- **`## RETIRED`** — decisions that no longer rule anything: those whose heading already says
  `SUPERSEDED by ...`, and `Decision 12`, whose heading says `NOT A DECISION`.

Rules that matter more than speed:

1. **Never delete or reword an entry.** Move it, and only it. A retired decision keeps its full text,
   its heading, and its number — readers follow citations into this file and a missing entry is worse
   than a stale one. If you think something should be reworded, put it in your report instead.
2. **Do not renumber anything.** Decision numbers are cited ~165 times in `src/` and `tests/`. The
   headings keep their numbers exactly.
3. **Preserve reading order within each section** — ascending decision number.
4. Keep everything above the first decision (front matter, the vocabulary section, any preamble)
   where it is, ahead of both new sections.
5. Add a short paragraph under each new section heading saying what belongs in it, in the voice of
   the surrounding document.
6. **Cross-references must still resolve.** Several entries point at each other ("see Decision 30",
   "SUPERSEDED by Decision 30"). Moving entries between sections must not break any of these, and
   they are all in-document text references rather than anchors — but check, and report any anchor
   link (`](#...)`) you had to fix.

## The second deliverable — the list this restructuring exists to produce

The owner's rule is: **an unimplemented decision becomes a technical-debt entry.** So as you read,
build a list of decisions that are **ruled but not fully implemented in the tree** — a decision that
says the system does X where the code does not yet do X, or that defers something to a later point
that has not arrived.

For each, give: the decision number, one sentence on what is unfulfilled, and the evidence you
checked. **Verify in code before you list one** — `Decision 16`, for example, says in as many words
that unification is still deferred, so read the entry *and* look. Do not guess; an entry you are
unsure about goes in a separate "unsure, needs a human" list. This list feeds a later debt-register
pass, so a wrong entry costs more than a missing one.

Note `Decision 35` is one day old and describes a shape that is **planned, not implemented**
(`ARC-02`). It belongs on your list, and its own text says as much.

## House rules

- **Do not commit, do not push, do not stage anything.** Edit the file, write your report, stop.
- **Do not touch any other file** — in particular not `ROADMAP.md`, not the technical-debt register,
  not `CHANGELOG.md`. Other agents are working on those. Your blast radius is exactly one document
  plus your report.
- Match the document's existing line width (~90 columns) and heading style.
- If you inspect `.lua` files to verify implementation, the **`lua-lsp` MCP server** is available —
  definitions, references and diagnostics over a real AST of the `/repo` workspace. Grep to find
  candidates, then the LSP to resolve a symbol or answer "who calls this". Treat LSP references as a
  strong hint rather than ground truth (Lua is dynamically typed) and use grep as the completeness
  backstop.
- `| head` on a counting grep lies, and a loose pattern lies too: `grep "Decision 1"` matches
  `Decision 15`.
- After you finish, confirm the file still parses as sensible Markdown and that
  `grep -c "^## Decision" doc/development/decisions/input.md` returns the same count as before your
  edit. State both numbers in your report.

## Deliverable

Write `/repo/doc/development/wip/77-new-input-api/validation/outcomes/LEDGER-01-decisions-split.md`:

1. What you moved to `RETIRED`, listed by number, with the evidence in each heading that put it
   there.
2. **The unimplemented-decisions list** described above, plus the "unsure" list.
3. Anything you noticed that a human should look at — a decision that contradicts another, a
   heading that lies about its own content, a cross-reference that no longer resolves. Report it;
   do not fix it.
4. The before/after decision count.
