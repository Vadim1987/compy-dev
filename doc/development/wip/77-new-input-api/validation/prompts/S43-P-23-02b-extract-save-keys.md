# P-23-02b — keep our addition out of an over-limit function (prompt of record)

Commissioned by session43, 2026-08-16, immediately after `cb6b867e`. Worker:
Sonnet, model passed explicitly. Deliverable: append to
`../outcomes/S43-P-23-02-editor-half.md` under a marked section.

## Why

`cb6b867e` added a 7-line Ctrl+S block inside `EditorController:keypressed`
(`src/controller/editorController.lua:813`). That function's body was **already
28 lines** against a 14-line hard limit — pre-existing debt the step correctly
did not restructure — but our addition took it to **35**. The standing rule is
that a function *we* bloated is ours to split; one that arrived long stays long.
So: leave the pre-existing 28 lines exactly as they are, and take **our** seven
back out.

## The change

Extract only the block `cb6b867e` added into a private method, leaving a single
call in `keypressed`. The file already has the idiom — `_reorg_mode_keys`,
`_search_mode_keys`, `_normal_mode_keys` — so follow it: same naming shape, same
`--- @param` annotation style, placed near its siblings.

Semantics must not change by one branch: Ctrl+S closes the buffer, Ctrl+Shift+S
finishes the edit, Alt excluded, and the whole thing still gated by the
surrounding `Key.ctrl()`. Decide deliberately whether the `Key.ctrl()` test moves
into the new method or stays at the call site, and say which you chose and why —
either is defensible, but the call site must read correctly beside `ctrl+m` and
`ctrl+f`, which stay where they are.

**Do not touch anything else in the file.** Not the other branches, not the
comments, not `controller.lua`, not the tests.

## Gate

- The new method's body must be **≤ 14 lines**; `keypressed` must end up at
  **29 lines** — the 28 it had plus our one call — and no more.
- Suite is **968 / 0 / 0 / 10**; it must stay exactly that. The existing cases
  already cover both meanings, so this is behaviour-preserving and needs no new
  test — if you think it does, say why rather than adding one.
- Hard limits otherwise: line ≤ 64 chars, params ≤ 4, nesting ≤ 4.
- One commit, `refactor(...)`, touching only
  `src/controller/editorController.lua`, staged by path. Never `git add .`,
  never `git add doc/`. **NEVER push.** Leave the owner's untracked scratch
  alone (`claude.sh`, `worklog.md`, `src/STEPS.md`, `doc/tall_blocks.md`,
  `repos.txt`, `input-pr-slices.tar.gz`).
- Trailer: `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`
- **The `lua-lsp` MCP server is available**; `sleep 1` after the edit before
  querying diagnostics, and check them before committing.

## Deliverable

The before/after line counts for both functions, which way you took the
`Key.ctrl()` decision and why, the suite line, and the commit hash.
