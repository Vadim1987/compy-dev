# Sub-agent prompt of record — session62, environment-lifecycle code map

> **SIDE-DRAFT — NOT PART OF `#77`'s DELIVERY.** This document belongs to an architecture discussion
> that ran alongside the feature's pre-PR phase (session62, 2026-08-31), opened at the project
> owner's initiative. It is exploratory: **nothing in it is ratified**, no production code was
> changed for it, none of it ships with `#77`, and nothing in the persistent documentation corpus
> was modified. Its subject — the console/project environment lifecycle, and the dispatch
> unification that followed from it — is expected to become **its own ticket, after** the feature is
> released.

**Model:** Sonnet (explicit). **Mode:** mechanical evidence-gathering, read-only. No edits to
`src/`, no commits. Deliverable path is fixed (below).

---

You are mapping, **from code**, how the Compy console's Lua environments relate to a running
project. This is evidence-gathering for an architecture discussion; you are not proposing designs
and not judging anything. Every claim must carry `file:line`. If something is ambiguous, say so —
"unclear" is a legitimate finding; a confident guess is not.

The repo is `/repo` (LÖVE2D, Lua). The relevant sources are
`src/controller/consoleController.lua`, `src/controller/controller.lua`,
`src/model/project/project.lua`, `src/util/table.lua`, `src/main.lua`.

**Tools.** The `lua-lsp` MCP server (defs / refs / diagnostics over a real AST of the `/repo`
workspace) is available and is the correctness tool: grep to find candidates, then LSP
`definition`/`references` to resolve a symbol and to prove "who calls this". Lua refs can be thin —
use grep as the completeness backstop and cross-check. Do not rely on any doc under
`doc/development/` for facts: several of its line citations have already drifted. Read the code.

## What to answer

1. **The environments.** Enumerate every Lua environment table the console builds
   (`getfenv()` capture, `pre_env`, `main_env`, `base_env`, `project_env`, any runner env), where
   each is constructed, what it is cloned from, when it is (re)built, and which is `_G` for the
   process. State exactly which table a REPL line is compiled into in each app state
   (`ready`, `project_open`, `running`, `inspect`, `editor`), citing the code that chooses it.
2. **`table.clone` semantics as used here** — deep or shallow, metatable handling, cycles, what
   happens to functions and userdata (`src/util/table.lua`). One paragraph, cited.
3. **`dofile` from the console.** Find every `dofile`-shaped entry point reachable by a user typing
   at the REPL and by project code (`dofile`, `project_dofile`, `require`/`package.loaders`
   registration, `codeload`, `run_user_code`, anything else). For each: which env the chunk is
   `setfenv`'d into, whether globals it assigns are visible at the REPL afterwards, and what is
   restored on return.
4. **`run()` / `run("name")`.** The full call path from the REPL symbol to `main.lua` executing:
   which env, built when, from what, and whether anything from before the run can reach it
   (leftover globals, `package.loaded`, custom loaders, the `compy` namespace, `love` table).
5. **Stop / quit / close / restart.** For each of `stop_project_run`, `suspend_run`, `continue`,
   `quit_project`, `close_project`, `restart`, `_reset_executor_env`, `_set_base_env`,
   `evacuate_required`: what happens to (a) the environment tables, (b) `package.loaded`,
   (c) the interaction callbacks (`love.draw`/`update`/`keypressed`/…), (d) anything else that
   persists. A table is the right shape. Include the **crash path** (a project that raises) —
   which of these it does and does not reach.
6. **The interaction callbacks specifically.** Where a project's `love.*` callbacks are harvested
   from its env, where they are stored, where they are re-installed, and where they are reset to
   the console's own. Name the functions and their call sites.
7. **What survives a run today.** Concretely: after a project runs and stops, which of these are
   still observable from the REPL — globals the project assigned, modules it `require`d, its
   `compy` namespace state, `love` subsystem state (cursor, key-repeat, relative mouse), the
   project env itself? Cite the code for each answer.
8. **Anything that contradicts the docs.** `doc/development/internals/project_sandbox_env.md` and
   `doc/development/internals/console.md` describe this machinery. Where the code disagrees with
   them, record the disagreement with both sides cited. Do **not** edit those docs.

## Deliverable

Write your report to **`doc/development/wip/77-new-input-api/validation/outcomes/session62-env-lifecycle-code-map.md`**
— that file is the artifact; a chat summary is not. Structure it by the eight questions above,
`file:line` throughout, with an explicit "uncertain / could not determine" section at the end.
Do not commit. Do not touch any other file.
