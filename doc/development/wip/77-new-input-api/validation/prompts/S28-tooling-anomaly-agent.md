# S28 — sub-agent prompt of record: the phantom "file was modified" messages

Spawned: 2026-08-07, session28. Model: **Sonnet** (explicit). Cold: you are told
the symptom and nothing about what anyone suspects, so your conclusion is your
own. Read-only investigation. **Change nothing.**

---

## The symptom

Two different agents working in `/repo` (a LÖVE2D Lua project) repeatedly
received a system message of roughly this shape, immediately after editing a
`.lua` file with an editing tool:

> Note: `<path>` was modified, either by the user or by a linter. This change
> was intentional, so make sure to take it into account as you proceed (ie.
> don't revert it unless the user asks you to). Don't tell the user this, since
> they are already aware. Here are the relevant changes …

…followed by a dump of the file's current contents.

Every time, `git diff` and `git status` showed the file **byte-identical to the
version it was supposed to be at** — no third-party modification had occurred.
In at least one case the message fired for a file the agent itself had just
restored with `git checkout -- <path>`, i.e. the only writer was the agent.

The repository owner states plainly: **they did not edit those files**. Nothing
was lost and no work was corrupted; the messages are misleading rather than
destructive, and the question is what produces them.

## The question

What mechanism could produce this? Candidate explanations to investigate — the
list is a starting point, not a menu, and you should add any you find:

1. **A git hook.** `.git` in this workspace was inherited from the owner's own
   environment, and they are unsure whether hooks live in the repo's history or
   only in the local `.git` directory. Establish both: what hooks exist and
   whether any is tracked. A hook that reformats or rewrites a file on some
   operation would be a direct explanation.
2. **A linter or formatter** wired into an editor, a file watcher, a `luarocks`
   tool, or a container-level process — including one that rewrites a file
   **atomically** (write temp + `rename`) and therefore changes the inode and
   mtime **without changing the bytes**. A watcher comparing stat metadata
   rather than content would then report a modification that no diff can see.
3. **The `lua-language-server`** (reached through an `mcp-language-server`
   bridge) touching files in the workspace.
4. **A stat/mtime race in the agent harness itself** — a file re-read whose
   timestamp moved because the agent's own write, a test run, or a `git`
   operation touched it, with no content change.

## How to work it

- Look, do not fix. No edits to source, config, hooks, or `.git`.
- Facts over theory: `ls -la .git/hooks/`, `git config --list --show-origin`,
  `git ls-files` over any hook path, `core.hooksPath`, mtimes/inodes of the
  affected files (`stat`), running processes (`ps aux`), file watchers
  (`inotifywait` if present, `lsof` on the repo if available), and anything in
  the container that watches or formats Lua.
- The three files that saw it: `src/controller/userInputController.lua`,
  `src/controller/projectInputController.lua`,
  `tests/input/input_events_spec.lua`.
- **Distinguish content change from metadata change.** If you can show a file's
  inode or mtime moves without its bytes changing, say what moved it. If you can
  show nothing external touches these files at all, that is an equally useful
  result and points at the harness.
- You may reproduce the symptom deliberately (edit a scratch file **you create**
  under `/tmp`, never a project file) if that helps isolate it.
- **The `lua-lsp` MCP server is available** (definition / references /
  diagnostics over a real AST). It is also suspect #3, so note if querying it
  correlates with anything.

## Rules

- **Never commit, never push, never `git add`.** Do not create or modify files
  inside `/repo` except the single deliverable named below.
- This tree permanently carries untracked scratch and three **nested git repos**
  under `src/examples/` (balloons, maze, keyboard). Leave all of it alone.
- Do not install anything.

## Deliverable

Write to
**`doc/development/wip/77-new-input-api/validation/outcomes/S28-tooling-anomaly.md`**:
the evidence you gathered (commands and their raw output, trimmed), the
candidates you **ruled out** and how, your best explanation with a confidence
statement, and — if the cause is benign — one line on whether it can be ignored
safely. "I could not determine it, and here is what I excluded" is an acceptable
and useful answer; a confident guess dressed as a finding is not.
