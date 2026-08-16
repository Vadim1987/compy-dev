# P-23-03 — cold review of the Ctrl+S relocation (prompt of record)

Commissioned by session43, 2026-08-16, per the standing directive that every
execution step gets one. Worker: Sonnet, model passed explicitly, **read-only**.
Deliverable: `../outcomes/S43-P-23-03-cold-review.md`.

The session that analysed this also wrote the commission and then narrowed its
own recommendation twice. A shared blind spot between analysis and execution is
what you exist to catch.

## What landed

- **`cb6b867e`** — the gate's `k == "s"` block reduced to one exact run-stop
  reservation; the editor's two meanings moved to `EditorController`.
- **`5e6ad8c2`** — the seven added lines extracted into
  `EditorController:_save_keys`, so the step's contribution to an already
  over-limit function is one call rather than seven.

Its record: `../reviews/S43-P-23-00a-…` (feasibility, committed as P-23-00),
`../reviews/S43-P-23-00b-liveness-and-boundary.md` (**read its Amendment
section** — the owner chose option A there), the commissions
`S43-P-23-02-editor-half.md` and `S43-P-23-02b-extract-save-keys.md`, and the
worker's report `../outcomes/S43-P-23-02-editor-half.md`.

## What to check

1. **Is it a move, or did semantics drift?** In the editor, Ctrl+S must close
   the buffer and Ctrl+Shift+S must finish the edit, with Alt excluded, exactly
   as before. Compare the pre-change gate block (`git show cb6b867e^:src/controller/controller.lua`)
   against `_save_keys` + its call site, branch by branch. Anything that changed
   — including *when* the branch is reached, not just what it does — is a
   finding.
2. **The one intended behaviour change, and its reach.** Ctrl+Shift+S no longer
   stops a running project. Confirm that is the *only* behavioural difference:
   check `ctrl+alt+s`, `ctrl+alt+shift+s`, and plain `ctrl+s` in every state the
   gate can see (`running`, `project_open`, `editor`, `ready`, `inspect`).
3. **Pen-and-paper projects.** Option A was chosen partly because it leaves
   `project_open` untouched. Verify that is true: a non-blocking project keeps
   the route in `project_open`, and its own `ctrl+s` binding must still fire
   there, exactly as before both commits.
4. **Did anything else depend on the old arrangement?** Grep `doc/` and the
   tests for claims about Ctrl+S — the guide, the internals docs, the debt
   register, the plan. A doc that still says the gate closes buffers is now
   wrong, and a stale claim reads as authoritative.
5. **Who calls what.** Use the LSP: confirm `finish_edit` / `close_buffer` have
   no caller that relied on being reached from the gate, and that
   `EditorController` reaches them by the same idiom the file already used.
6. **Limits and hygiene.** `agents/rules.md` (body ≤ 14 lines, line ≤ 64,
   params ≤ 4, nesting ≤ 4) on both changed files — note that
   `EditorController:keypressed` is **29 lines of pre-existing debt plus our one
   call** and must not be restructured; `agents/rules/commenting.md` on any
   comment touched. Suite must read **968 / 0 / 0 / 10** with the seven
   `pending(...)` outlines untouched.

## How to work

- **The `lua-lsp` MCP server is available** — defs / refs / diagnostics over a
  real AST of `/repo`. Grep to find candidates, LSP to resolve a symbol or prove
  who calls it; cross-check with grep where completeness matters.
- **Read-only.** No edits, commits or pushes. Do not touch the owner's untracked
  scratch (`claude.sh`, `worklog.md`, `src/STEPS.md`, `doc/tall_blocks.md`,
  `repos.txt`, `input-pr-slices.tar.gz`).
- Verify in code, not prose. Cite file:line or commit. Where a document and the
  code disagree, the code wins and the disagreement is a finding.
- Severity: S1 = broken behaviour or a claim its evidence does not support;
  S2 = rule or contract violation; S3 = bookkeeping drift.

## Deliverable

Verdict first — **is this a faithful move with exactly one intended behaviour
change?** — then findings by severity with evidence, then what you verified
clean, then what you could not check. If it is sound, say so plainly and stop.
