# S29 — sub-agent prompt of record: revalidate session28's two production fixes

Spawned: 2026-08-08, session29, part 1 step 2. Model: **Sonnet** (explicit).
**Read-only** apart from the deliverable.

---

## Context you do not have

`/repo` is a LÖVE2D project (Lua 5.1; tests run under **busted** with a
`mock_love` harness, no display needed — `busted tests`). It is finishing a new
input API on branch `feature/77-newapi-analysis-s20260615`, HEAD `d8a15f04`. The
PR base — the commit this whole branch descends from — is **`3256aac`**.

Session28 shipped two production fixes. Each commit message makes **claims**.
Your job is to verify the claims against the code, not to summarise the commits.
A commit message is a hypothesis written by someone who wanted to be finished.

Suite today: `busted tests` → **954 / 0 / 0 / 3**. Green.

### Fix 1 — `8fbcba21`, **partly reverted by `811849e2`**

`fix(input): a click at a shown widget no longer kills the project run`.
Touches `src/controller/projectInputController.lua`,
`src/controller/userInputController.lua`, `tests/input/input_events_spec.lua`.

Read both commits: **`811849e2` reverted the mechanism `8fbcba21` invented** (the
widget's no-ops returned `false` and the widget tier grew a `~= false` check so a
widget could "decline" a channel). The owner rejected that outright — *truthy
consumes, non-truthy does not; no invented special cases* — so the net state in
the tree today is: plain no-ops, widget tier back to shown-means-consumed, and
one test row deleted along with the mechanism it pinned.

**This matters for your reading: `8fbcba21`'s commit message describes behaviour
that no longer exists** (it claims Decision 5 gains "a single exception"). Do not
verify the tree against that message. Verify the *net* of the two commits, and
treat the stale message as a fact about history, not about the code.

Claims to check:

- **The defect was real and reproducible.** A shown widget plus a derived click
  called a nil method (`widget[event](widget, ...)` where the widget implements
  every channel in `EVENTS` *except* `singleclick`/`doubleclick`), the route's
  error boundary swallowed the raise, and the *run* died — `app_state` becoming
  `'snapshot'` — instead of anything crashing visibly.
- **"Not pre-existing."** The claim is that at `3256aac` the click timer resolved
  `CC:get_compy_handler('singleclick')` and there was no widget tier for clicks
  at all, so the branch created this. `git show 3256aac:<path>` is how you check
  this, and **this kind of claim has been overturned four sessions running on
  this feature** — check it, do not accept it.
- **The surviving test row still discriminates.** `811849e2` claims that deleting
  the two no-ops makes `a click at a shown widget does not kill the run` fail.
  That is a mutation check; **re-run it yourself** (see the mutation-check rules
  below). A row that passes with and without the fix is a pin, not a proof.
- **Completeness.** The widget implements every channel in `EVENTS` except two —
  is that still true at HEAD? If a channel were added to `EVENTS` tomorrow, or if
  one exists today that the widget lacks and nobody noticed, the same defect
  returns. Enumerate `EVENTS` and the widget's methods and compare; do not trust
  the commit's list.

### Fix 2 — `493c3cbe`

`fix(input): the widget's key signatures name LÖVE's arguments`. Touches only
`src/controller/userInputController.lua` (+10 −3). `keypressed(k, isr)` had been
receiving `(key, scancode, isrepeat)` since Decision 26 unified the chain's
payload, so `isr` was bound to a **string** while annotated `boolean?`. Renamed
to `keypressed(k, sc, isr)` and `keyreleased(k, sc)`.

Claims to check:

- **"Call sites audited, all of them."** The commit names the chain's
  `widget[event](widget, ...)` plus `consoleController:1497`,
  `editorController:808`, and "the editor and lifecycle specs", and concludes
  every other caller passes the key alone. **This is the claim most likely to be
  incomplete** — Lua is dynamically typed and a missed caller is silent. Use the
  `lua-lsp` MCP server for references, **and** grep as the completeness backstop,
  and cross-check the two: LSP references can be thin on a dynamically-dispatched
  method, and a thin result you trust is exactly how a caller hides. Line numbers
  in the message are from that commit's tree and may have drifted; resolve the
  symbols, don't trust the numbers.
- **"Behaviour is unchanged by construction — the tail is unread."** Verify the
  renamed parameters are genuinely unread in the method bodies at HEAD, and that
  no caller was relying on the old second position.
- **"No new row"**, justified by an existing row (`the widget receives the
  uniform keypressed arguments`) already pinning that `('a', 'scan-a', true)`
  reaches the widget. Find that row, read it, and judge whether it actually pins
  what the commit says it pins.

## Mutation-check rules (read before running one)

A mutation check means: break the production code deliberately, confirm the named
test row fails, then restore. On this feature a session **destroyed its own
uncommitted work** doing this. So:

- Copy the file to `/tmp` **first**; restore from that copy.
- **Never** use `git checkout -- <path>`, `git stash`, `git restore`, or any
  branch operation to undo a mutation.
- After every restore, confirm with `git diff --stat` that the tree is clean, and
  re-run `busted tests` to confirm 954 / 0 / 0 / 3 before starting the next one.
- Mutate one thing at a time. Record, for each: the exact mutation, the exact row
  title that failed (or that nothing failed), and the restore confirmation.
- If a mutation makes a *different* row fail than the one claimed, that is a
  finding worth as much as an outright miss — say which rows failed.

## Rules

- **Read-only on the repository**, apart from the temporary mutations above,
  each of which is restored immediately. No `git add`, no `git commit`, **no
  `git push`**, no `git checkout --`, no stash, no branch switch, no rebase. Do
  not "fix" anything you find — report it. The only file you write and leave
  behind is the deliverable.
- Finish with `git status --porcelain` and `git diff --stat` and record both in
  the deliverable. The tree must end byte-identical apart from your deliverable.
- The tree permanently carries the owner's untracked scratch (`claude.sh`,
  `src/STEPS.md`, `input-pr-slices.tar.gz`, `doc/tall_blocks.md`, some
  `doc/development/wip/` subdirs) and **three nested git repos** under
  `src/examples/`. All expected. Leave it alone; do not enter the nested repos.
- **The `lua-lsp` MCP server is available** — definition / references /
  diagnostics / hover over a real AST of the `/repo` workspace. It is the
  correctness tool for "who calls this"; grep is the completeness backstop.
  After any `.lua` write (including a mutation), `sleep 1` before querying the
  LSP — it re-indexes.
- **Report what is, including nothing-found.** Give the evidence you actually
  produced — the command, the output, the file:line — not the conclusion. "I ran
  X, got Y" beats "verified". If you cannot complete a check, say so and why. A
  clean verdict on a check you really ran is a good result; you will not be
  penalised for confirming someone else's work.

## Deliverable

Write to
**`doc/development/wip/77-new-input-api/validation/reviews/S29-production-fixes-revalidation.md`**.

One section per claim above, each with **CONFIRMED / FINDING / UNCLEAR**, the
evidence, and for findings what is wrong and how severe. Then three closing
lines:

1. Is the defect in fix 1 actually fixed at HEAD, and is the row that guards it a
   proof or a pin? (Say which, with the mutation result.)
2. Is fix 2's call-site audit actually exhaustive? Name the method you used to
   establish that, and what that method could still miss.
3. What did you check that came back clean, so the next reader knows the shape of
   your pass?

Your chat reply should be a short digest: the verdicts, any findings, and the
three closing lines.
