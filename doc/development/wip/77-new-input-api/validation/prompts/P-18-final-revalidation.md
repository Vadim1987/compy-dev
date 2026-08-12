# Prompt of record — cold revalidation of the whole P-18 diff against upstream

**Commissioned:** 2026-08-12, session38, by the owner. **Model:** Opus, passed explicitly.
**Mode:** read-only review. **Deliverable:** `../reviews/S38-P18-final-revalidation.md`.

**RUN TWICE.** The first pass (range `025e858..646674b`) returned *mechanism sound, adoption not
clean* — 4 defects, 7 observations — and reopened the step as `P-18-07 … P-18-13`. The second pass
runs the **same framing** against the range those children produced, `025e858..1498f46`, and reviews
the whole delta again rather than only what changed since. Its deliverable is
`../reviews/S38-P18-final-revalidation-2.md`; the first pass's report is left untouched. Both are
pinned by the four-commit anchor in `doc/development/smoke_checklists.md`, re-pinned before this
run.

**Why this exists:** P-18 (the keyboard deepfix) is fully landed across two sessions. The owner
commissioned a cold pass over the *whole* delta against upstream — not the individual commits —
because the reviewer of one's own work cannot see what it assumed. The predecessor commissioned the
same kind of pass at session37 and it found a live crash; this one covers everything since.

**The four commits it runs against** (same as `doc/development/smoke_checklists.md`, `keyboard`):
branch under test `646674b`, upstream `origin/dsent/dev` = `025e858`, platform `fd0e2c21`, platform
edge upstream `dsent/dsent/dev` = `9ed375d4`.

---

The prompt as given to the agent follows verbatim.

---

You are reviewing, cold, a completed piece of work in a LÖVE2D project. Read-only: **do not edit any
file, do not commit, do not touch git state in any repository.** Your deliverable is one document you
write at the end.

## What you are reviewing

`/repo/src/examples/keyboard` is a **nested, separate git repository** (a children's typing game,
authored by someone outside this project). It has no test suite and cannot be exercised here — this
container cannot inject keystrokes and has no display device. A branch of it has been modified to
adopt the platform's new input API and to fix a defect in how typed characters are accepted.

**Your object of review is the complete diff `025e858..646674b`** in that repo — i.e.
`git -C /repo/src/examples/keyboard diff 025e858..646674b`, where `025e858` is the upstream head
(`origin/dsent/dev`) and `646674b` is the branch's current head. `git log 025e858..646674b` shows the
commits, and their messages carry much of the reasoning. Upstream is an ancestor, so the diff is a
clean forward change set.

The platform side (`/repo`, the LÖVE2D IDE this game runs inside) is context, not the object: read it
to check claims, do not review it.

## The mandate the work must be judged against

1. **`/repo/doc/development/internals/examples/keyboard.md`** — the design of record for the
   acceptance mechanism. Persistent (it outlives the feature's scratch directory).
2. **`/repo/doc/input_api.md`** — the platform input API the game migrates onto. The section
   "Event hooks and shortcuts" carries the argument contract; "Stop hook — `compy.before_exit`" and
   "Held keys" also matter here.
3. **The step's own record**, ephemeral but authoritative on intent:
   `/repo/doc/development/wip/77-new-input-api/validation/reviews/P-18-00-keyboard-deepfix-design.md`
   (§1.1, §1.2, §2.2, §2.3, §7.1's requirements R1–R5, §9's derivation and impossibility result) and
   `/repo/doc/development/wip/77-new-input-api/validation/reviews/P-18-00-triage-and-plan.md`
   (§0's two owner calibrations, §5's four rulings, §§6–8 the execution record).
4. **The strategic frame** (`/repo/agents/validation.md`, "The strategic frame"): stakeholders asked
   for a *simpler and more robust input API*. The question is never "is it approved?" but **"does it
   make the system more predictable, or merely more elaborate?"**

**Three owner rulings constrain the work and therefore your review:**

- **The game's rules are not ours.** The test is *"would a player notice a difference?"* If yes, it
  is out of scope and is a defect of this work — even if the new behaviour is arguably better.
- **Minimise the change.** The game keeps its own names (`GLYPH_CLAIMED`, `spendGlyph`) and its own
  machinery; only what the adoption and the fix require may move.
- **Focus loss is tolerable**, and a risk cleared by repeating a gesture is an inconvenience, not a
  harmful degradation. A finding that rests only on focus loss is weak by ruling.

## What to look for, in priority order

1. **Correctness against the library.** Does any line assume LÖVE behaviour that is not true? The
   previous cold pass on this work found a **live crash** exactly there (`love.keyboard.isDown`
   raises on a string that is not a key constant) and a documented claim that was the opposite of
   what the library does. **Measure rather than reason** where you can: `love` and `luajit` are on
   PATH, `xvfb-run` is available, and a throwaway script under
   `/tmp/claude-1000/-repo/6f512c55-e690-4ef3-9962-d6ea3490f5cb/scratchpad/` that loads a real file
   against stubs is a legitimate and cheap instrument. Say which findings you measured.
2. **Behaviour changes the work did not intend or did not state.** Compare against upstream, not
   against the previous commit. Anything a player could notice that is not written down in the code,
   the design of record, or the smoke checklist is a finding.
3. **Claims in comments and commit messages that are false.** This work has a history of them, and
   they are load-bearing here because the repository has no tests: a comment is the only thing a
   future reader has. Check every factual assertion you can cheaply check, including citations —
   a comment citing a document section must resolve, and the document must say what the comment says
   it says.
4. **Whether the mechanism is more predictable or merely more elaborate.** The strategic frame.
   Name anything that added apparatus without buying predictability.
5. **The smoke checklist's fitness** (`/repo/doc/development/smoke_checklists.md`, `keyboard`
   section). It is the only gate this work has. Does it cover what changed? Is any row now testing a
   mechanism the code no longer has? Are there changes with **no** row?

## Tools

- **`lua-lsp` MCP server** — definitions, references, diagnostics and hover over a real AST of the
  `/repo` workspace, `lua-language-server` behind it. It is the correctness tool for Lua: grep to
  find candidates, then the LSP to resolve a symbol and to prove *who calls this*. Lua is dynamically
  typed, so LSP references can be incomplete — cross-check completeness-critical claims with grep.
  (If you ever edit a `.lua` file, `sleep 1` before querying — the server re-indexes. You are
  read-only, so this should not arise.)
- Plain `git`, `grep`, `love`, `luajit` as above. **Read-only in every repository.**

## What the deliverable must contain

Write **`/repo/doc/development/wip/77-new-input-api/validation/reviews/S38-P18-final-revalidation.md`**
— the ONLY file you create or modify.

- **A verdict in the first three lines.** Sound / unsound, and on what.
- **Findings, ordered by severity**, each with: what is wrong, how it is reachable (a concrete
  keystroke sequence where one exists), the evidence (file:line, and whether you *measured* it or
  reasoned it), and what you would do about it. Distinguish **defects** from **observations**.
- **What you checked and found correct** — briefly. A cold pass that lists only problems cannot be
  distinguished from one that missed the rest.
- **Explicit limits.** What you could not verify, and why. Do not soften this: nothing in this work
  has ever been run in a game scene.
- **No edits to any code or any other document.** Recommendations only; the parent session and the
  owner decide what lands.

Be direct. If the work is sound, say so plainly and do not manufacture findings to justify the pass.
If something is wrong, say how wrong and what it costs.
