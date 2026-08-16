# P-23-02 — the editor's Ctrl+S meanings leave the gate (prompt of record)

Commissioned by session43, 2026-08-16. Owner chose **option A** of
`../reviews/S43-P-23-00b-liveness-and-boundary.md` (see its Amendment section).
Worker: Sonnet, model passed explicitly. **This step writes framework code.**
Deliverable: `../outcomes/S43-P-23-02-editor-half.md`.

## What is being fixed, and what is deliberately not

One key currently carries two unrelated meanings in the **pre-dispatch gate**
(`src/controller/controller.lua:810-822`): stop a running project, and — when
`app_state == 'editor'` — close the buffer or finish the edit. The second has no
business being decided before any route exists: it is the editor's own business,
and the editor already owns Ctrl-gated branches of exactly this kind.

**Not in scope, deliberately:** moving the *run-stop* meaning. It belongs with
its family — Ctrl+Escape, Ctrl+Q, Ctrl+T all stop or tear down a run, all
non-overridable, all in the gate. That was analysed and set aside by the owner.
Do not touch `ProjectInputController`.

## The change

**1. The gate keeps only the run-stop reservation, and becomes exclusive.**
The `k == "s"` block reduces to: while `app_state == 'running'`, an **exact**
Ctrl+S stops the run — `only_mods(true, false, false)`, the predicate already in
that file. The editor branch goes away entirely. The comment above the block
about Shift staying meaningful goes with it, since it no longer does *here*.

This is a deliberate behaviour change, and the only one in this step:
**Ctrl+Shift+S no longer stops a running project.** It is the least-privilege
ground of Decision 33 applied to the one reservation P-21 had to leave loose.

**2. `EditorController:keypressed` takes the two editor meanings.**
Beside the existing `ctrl+m` / `ctrl+f` block (`editorController.lua:817-823`):
Ctrl+S closes the buffer, Ctrl+Shift+S finishes the edit. **Preserve today's
semantics exactly** — Alt excluded, Shift selecting between the two — so this is
a move, not a redesign. Call the same `CC` methods the gate called
(`close_buffer`, `finish_edit`); find how the editor reaches them and follow the
file's existing idiom rather than inventing a path.

Shortcut-syntax migration is **not** in scope; the owner named it as a later
option.

## Tests

The existing editor cases in `tests/input/input_global_shortcuts_spec.lua` (from
P-21-06) assert *behaviour* — press Ctrl+Shift+S in editor state, the edit
finishes — not layering, so they should keep passing **unchanged** across this
move. That is a property worth checking explicitly: if they break, understand
why before touching them, and say so in your report. Do not weaken them to fit.

Add:

- **Ctrl+Shift+S while `running` no longer stops the project** — the one
  behaviour this step changes. It must fail against the pre-change tree; record
  that failing output.
- Anything the move leaves uncovered on the editor side that was covered before.

Suite is **967 / 0 / 0 / 10** before your change; state the arithmetic after.
Do not touch the seven `pending(...)` outlines; the pending count stays 10.

## Constraints

- `agents/rules.md` hard limits (body ≤ 14 lines, line ≤ 64 chars, params ≤ 4,
  nesting ≤ 4). `EditorController:keypressed` is already a long function — if
  your addition would breach a limit, **stop and report**; do not restructure it,
  and do not "improve" surrounding code.
- Comments per `agents/rules/commenting.md`: canonical `doc/…` paths with named
  sections, never `wip/…`, and only where they carry what the code cannot.
- Commit only the files you actually change, explicitly by path. Never
  `git add .`, never `git add doc/`. **NEVER push.** Leave the owner's untracked
  scratch alone (`claude.sh`, `worklog.md`, `src/STEPS.md`, `doc/tall_blocks.md`,
  `repos.txt`, `input-pr-slices.tar.gz`).
- Trailer: `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`
- **The `lua-lsp` MCP server is available**; `sleep 1` after a `.lua` edit before
  querying it. Use it to confirm who calls `close_buffer` / `finish_edit` before
  you wire anything.

## Deliverable

What moved, what the gate now claims, the failing output for the new case before
the change, whether the P-21-06 cases survived untouched, the suite arithmetic,
and the commit hash. Do not commit the report.
