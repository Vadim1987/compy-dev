# Sub-agent prompt of record — cold peer review of the `BUG-01` sprint

**Spawned:** session60, 2026-08-31 · **Model:** Opus · **Mode:** cold review, read + verify, no edits.

**Why spawned rather than done in-session** (the model-economy charter prefers the parent for
judgment): the owner commissioned a **cold** reader specifically. The parent wrote all five fixes
and cannot review them cold, so this is the case the charter carves out. The prompt therefore names
what the agent must NOT read — the parent's track, report, resolutions and closure notes — so it
reaches its own verdict from the code and the original row text.

---

## Prompt as issued

You are a **cold peer reviewer** on the LÖVE2D project at `/repo` (cwd, a git repo). Another agent
has just executed a five-row bug-fix sprint. Your job is to find what is wrong with it.

### What you must NOT read — this is what makes you cold

Do not open any of these before forming your own verdict. They contain the author's reasoning and
would replace your judgement with theirs:

- `doc/development/wip/77-new-input-api/implementation/sessions/session60/` (track, prompt, report)
- the **RETIRED** section of `doc/development/technical_debt/input.md` (the author's own
  resolutions)
- `doc/development/wip/77-new-input-api/validation/notes/BUG-01-11-maze-neutralisation-weighing.md`
- `doc/development/wip/77-new-input-api/validation/outcomes/BUG-01-0*-evidence.md`
- the closure text in the `BUG-01` section of the current `ROADMAP.md`

Read the **commit messages** — they are the author's claims, and testing a claim against the code
is exactly your job. If you later want one of the forbidden files to settle a disagreement, say so
in your report and read it then, flagging that you did.

### What was asked of the sprint

The five rows as they read BEFORE the sprint touched them are in
`/tmp/claude-1000/-repo/0300de11-b9f4-4385-85b4-566f47ee68cc/scratchpad/bug01-rows-original.md`.
Read that first — it is the specification the work is answerable to.

### The changes

- **Platform repo** (`/repo`): `git diff b5022530..HEAD -- src tests CHANGELOG.md doc/input_api.md`,
  and `git log b5022530..HEAD` for the messages. Nine commits, fixes and ledger work separated.
- **balloons** (`/repo/src/examples/balloons`, a SEPARATE git repo with its own history):
  `git diff 6d6c6e3..HEAD` and `git log 6d6c6e3..HEAD`.
- **maze** (`/repo/src/examples/maze`, also separate): deliberately unchanged — row `BUG-01-11` was
  ruled `wontfix`. Reviewing whether that ruling is defensible IS in scope.

### Tools

- **`lua-lsp` MCP server is available** — `definition`, `references`, `hover`, `diagnostics` over a
  real AST of `/repo`. Grep finds candidates; the LSP resolves a symbol and answers "who calls
  this". Lua is dynamically typed so LSP refs can be **incomplete** — cross-check with grep when
  completeness matters. After any `.lua` edit, `sleep 1` before querying (you should not be
  editing).
- `busted tests` runs the suite. It should report **1030 successes / 0 failures / 0 errors / 10
  pending**. The 10 pending are an owner ruling, not drift — do not "fix" them; an 11th would be a
  finding. Note that the container has **LuaJIT**, while the project owner runs **PUC Lua** — if
  anything you review could behave differently on the two, say so explicitly.
- You may write throwaway probes under
  `/tmp/claude-1000/-repo/0300de11-b9f4-4385-85b4-566f47ee68cc/scratchpad/`, never inside `/repo`.

### What to review — in this order

1. **Does each fix actually fix its row?** Read the row, then the code. Not the test — the code.
   A test written by the same author who wrote the fix can be wrong in the same direction.
2. **Is each fix correct, and is it complete?** Specifically hunt for:
   - a sibling call path the fix missed (the same defect reachable another way);
   - an edge the fix introduces — empty string, `nil`, a single character, a multi-byte character,
     a value at the exact boundary;
   - a behaviour the fix changes that nobody noticed, especially for the **console** and the
     **editor**, which share this input machinery with the project widget. Two of the fixes touch
     `userInputModel.lua`, which all three use.
3. **Are the tests real?** Would each new test fail against the pre-fix code for the RIGHT reason?
   Is any of them asserting the implementation back to itself rather than the contract?
4. **The provenance claims.** The commits assert that `BUG-01-09` was inherited from the PR base,
   `BUG-01-04` was introduced by this feature, and `BUG-01-05` is mixed. The base is `3256aac`.
   **Check all three with `git show 3256aac:<path>`** — these claims are going into a PR
   description and a wrong one is expensive.
5. **The `wontfix` on `BUG-01-11`.** Read `maze`'s `controls.lua`, `maze_main.lua`,
   `draw_main.lua`, `core_editor.lua` yourself and decide whether leaving it alone is right.
   Is double-handling actually prevented while the widget is shown? Trace it; do not accept it.
6. **Documentation truthfulness.** `doc/input_api.md` and `CHANGELOG.md` were edited. Does each
   edit state what the code now does — not more, not less? Is any promise made that the code does
   not keep?
7. **House rules.** Line ≤ 64 chars, function body ≤ 14 lines, params ≤ 4, nesting ≤ 4
   (`agents/rules.md`). Comments must carry information the code cannot, cite canonical `doc/…`
   paths and a **named section** — never a `doc/development/wip/…` path, which rots. Check the new
   comments against this. Also: the term is **widget**, not "field" or "overlay".
8. **Anything the sprint should have caught and did not** — including a defect it walked past.

### Rules

- **Verify in code. Never report a finding you have not read the line for.** Verdicts here have
  been overturned by someone re-reading the code, in both directions.
- **Rank by severity, and say what is NOT wrong too.** A review that lists only problems gives no
  signal about coverage. If a fix is right, say it is right and say what you checked.
- Distinguish **defect** (the code is wrong) from **taste** (you would have written it otherwise).
  Label every finding as one or the other. Taste findings in another repo's working code are
  especially cheap and are usually not worth acting on — say so when that applies.
- Where you are uncertain, say "uncertain" and say what would settle it.

### Deliverable

Write to **`doc/development/wip/77-new-input-api/validation/outcomes/BUG-01-sprint-peer-review.md`**
with, in order: a one-line **verdict** (approve / approve with comments / changes needed), a
findings table ranked by severity with defect-or-taste labels, then a section per numbered question
above including what you checked and found sound. `file:line` citations throughout. That file is
the durable artifact; your chat reply is secondary.
