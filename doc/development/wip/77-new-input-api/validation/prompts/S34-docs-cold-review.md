# S34 — cold review of the documentation changes (prompt of record)

**Spawned:** session34, 2026-08-10. **Model: Sonnet, passed explicitly.** Read-only over
`src/` and `tests/`; writes exactly one file, its deliverable.

**Why cold:** the author of these changes should not be the one checking them for
self-consistency. The reviewer is given the diff and the tree, and **not** the author's
reasoning, conclusions, or the plan the changes were written against.

**Deliverable:** `doc/development/wip/77-new-input-api/validation/outcomes/S34-docs-cold-review.md`

---

## The prompt as given

You are reviewing a set of documentation changes in a LÖVE2D/Lua project at `/repo`. Work
**read-only** on all code and tests. You write exactly one file: your report, at
`doc/development/wip/77-new-input-api/validation/outcomes/S34-docs-cold-review.md`.

### What to review

Nine commits, `115841cd..HEAD` on branch `feature/77-newapi-analysis-s20260615`. The
documentation ones are:

- `fb81ecc0` — `doc/input_api.md` (the project-author guide)
- `90935e2c` — `doc/development/internals/user_input.md` (+ one test comment)
- `8a879534` — `doc/development/decisions/input.md` (the decision ledger)
- `8cae175f` — `doc/development/technical_debt/input.md` (the debt register)
- `70eb4842` — `doc/development/internals/event_dispatch_layers.md`

Read the diffs (`git show <sha>`), and read the **current** state of each changed file around
the changes — a diff hides what the surrounding paragraphs still say.

### Background you need, stated flatly

The project is mid-way through removing a framework-maintained held-key table
(`Controller.keys_pressed`, exposed to projects as `compy.input.keys_pressed`). The decision
to remove it is `doc/development/decisions/input.md`, Decision 30. **The code has not changed
yet** — the table still exists and still works. These commits write the *documentation* ahead
of the code, and mark every passage that describes not-yet-existing behaviour with a
`PENDING:` marker naming the step that will remove the marker.

The intended end state of the code: the combo-string builder (`combo_string` / `any_mod` in
`src/controller/controller.lua`) stops taking a held-key table and instead asks the device via
`Key.ctrl()` / `Key.alt()` / `Key.shift()` (`src/util/key.lua`), which wrap
`love.keyboard.isDown`.

### What I want from you

**Inconsistencies.** Anything where the documentation now contradicts the code, contradicts
another document, or contradicts itself. Specifically:

1. **Claims about current behaviour that are false.** Any sentence stating how the code
   behaves *today* which the code does not support. Distinguish these from passages that
   describe the intended end state and carry a `PENDING` marker — those are supposed to
   describe behaviour that does not exist yet. **A false present-tense claim with no marker is
   the highest-value finding here.**
2. **Marker coverage, both directions.** A passage describing not-yet behaviour with **no**
   marker; and a marker on a passage that is actually already true today (a spurious marker is
   noise the later step will delete without checking).
3. **Cross-document contradictions.** The five files above plus `doc/development/tests.md` are
   one corpus. Does any pair of them now disagree?
4. **Dangling or wrong citations.** Documentation comments in `src/` and `tests/` cite doc
   sections **by name** (e.g. `-- doc/input_api.md, "Held keys"`). A heading was renamed in
   `internals/user_input.md`. **Grep `src/` and `tests/` for citations of every heading that
   changed** and report any that no longer resolve. Also check `../`-style relative links
   between docs still resolve as paths.
5. **Code examples that would not run.** The guide gained a new code example. Check its API
   against the real code: do the functions exist, with those names, on those tables, with
   those signatures? The runtime is **LuaJIT / Lua 5.1** — flag any syntax that needs 5.2+.
6. **Internal consistency of the ledger.** Decisions are amended in place and never
   renumbered; superseded ones keep their original text with a supersession header. Did an
   amendment edit something it should have left as history, or leave live something it should
   have amended?

### How to work

- **Verify in the code, not from the prose.** Every factual claim you accept or reject must be
  checked against `src/` or `tests/`. Quote the file and line you checked.
- **The `lua-lsp` MCP server is available** and is the correctness tool for Lua: it gives
  definitions, references and diagnostics over a real AST of the `/repo` workspace. Use grep to
  find candidates, then the LSP to resolve a symbol and to answer "who calls this". **Grep
  remains the completeness backstop** — the LSP has been observed to miss occurrences in this
  codebase (type annotations, comments, computed string keys, proxy paths), so cross-check and
  trust neither alone. (You are read-only, so no re-index waits apply.)
- Do **not** fix anything. Do not edit any file other than your report.
- Do **not** run the test suite; it is green and that is not what you are checking.

### Report format

Findings ranked most-severe first. For each: **what** is inconsistent, **where** (file:line),
**the evidence** (the code or doc you checked, quoted), and **how sure you are**. Separate
"confirmed against code" from "looks wrong, could not confirm". If a section is clean, say so
explicitly — a clean bill on a specific question is a useful result. End with anything you
noticed that fell outside these six questions but that a reader of these docs would trip over.
