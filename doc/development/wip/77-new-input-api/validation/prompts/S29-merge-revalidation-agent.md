# S29 — sub-agent prompt of record: revalidate the S28 suite merge, from outside the previous checks' shape

Spawned: 2026-08-08, session29, part 1 step 1. Model: **Sonnet** (explicit).
**Read-only** apart from the deliverable.

---

## Context you do not have

`/repo` is a LÖVE2D project (Lua 5.1, tests run under **busted** with a
`mock_love` harness — no display needed). It is finishing a new input API for a
PR. Branch `feature/77-newapi-analysis-s20260615`, HEAD `8ed4093b`.

In session28 the input test suite was restructured: **four spec files were merged
into two**, along the API's three named surfaces (*inbound events*, *widget
control*, *widget callbacks*). Commits, oldest first:

- `90f632cf` step 1 — `input_widget_lifecycle_spec.lua` + `input_reconfigure_spec.lua` (part) → `tests/input/input_widget_control_spec.lua` (39 rows)
- `25f70175` step 2 — `input_widgets_callbacks_spec.lua` + `input_lifecycle_uniform_spec.lua` + `input_reconfigure_spec.lua` (rest) → `tests/input/input_widget_callbacks_spec.lua` (52 rows); **two rows deliberately deleted**, five assertions added to their survivors
- `b0c9d032` — restored a `#lifecycle` tag the merge had lost
- `bc5b97ae` — repointed 13 citations of the four now-deleted filenames
- `a246c170` step 3 — renamed the **root describe titles** of six other spec files to name their surface

The four source files no longer exist in the working tree. Reach them with
`git show 90f632cf^:tests/input/<name>`.

Suite today: `busted tests` → **954 / 0 / 0 / 3**.

## Why you are being asked, and what makes this hard

The merge was **already cold-reviewed twice** — once on the written plan before
the move, once on the result after it. Both reviews came back clean. Their
deliverables:

- plan: `doc/development/wip/77-new-input-api/validation/reviews/S28-merge-plan.md` (§2A/§2B are the target shapes, §5b the only authorised content changes)
- pre-move review: `doc/development/wip/77-new-input-api/validation/outcomes/S28-merge-plan-review.md`
- post-move review: `doc/development/wip/77-new-input-api/validation/outcomes/S28-merge-result-review.md`
- inventory of every pre-merge row: `doc/development/wip/77-new-input-api/validation/outcomes/S28-merge-inventory.md`

Between those reviews, the merge was verified by comparing **all 43 row titles**
and **all 76 assertion lines** against the originals, byte for byte — and it
**still lost a documented busted tag**, because a tag is neither a row title nor
an assertion line. That loss was found by accident.

**Your job is not to redo those checks.** Assume rows, titles, assertion lines,
the two deletions, the five added assertions, helper *names*, requires and
dangling filename citations have been compared and are clean. Your job is to find
**the next thing that shape of check cannot see** — a property of the suite that
survives a row-by-row textual comparison yet was changed by moving rows between
files.

Do not take the three documents above as ground truth about the code. They tell
you what was *intended* and what was *claimed*; the tree tells you what is.

## Where to look — leads, not a closed list

Rank your own effort. These are the classes of thing a title/assertion diff is
blind to; the tag loss was one of them.

1. **Enclosing context per row.** A row's meaning is its body *plus* every
   `setup` / `teardown` / `before_each` / `after_each` / `lazy_setup` /
   `strict_setup` in every describe enclosing it, at both files' scope. The plan
   claims these were "identical across all four files". Verify that per row, at
   the nesting level that actually applies: a row whose source describe had its
   own nested `before_each` and whose destination describe does not (or has a
   different one) is now a different test with identical text.
2. **Insulation and cross-row state.** busted insulates each *file*. Two rows
   that lived in separate files could not see each other's leaked state; merged
   into one file they can. Look for file-scope upvalues, module-level `require`
   caches, `package.loaded` manipulation, mock/spy/stub installation, monkey-
   patched methods restored in `finally` vs restored by hand, and globals
   (`love.*`, `_G`) touched by a row without restoration.
3. **Order dependence introduced by the merge.** Cheap and decisive experiment:
   compare `busted tests --shuffle` (and/or `--sort`) at HEAD against the same
   command at `90f632cf^`. Run each several times if shuffle is seeded randomly.
   A failure at HEAD that does not reproduce at `90f632cf^` is a finding; a
   failure at both is pre-existing and is **not** yours to fix. Also run each
   merged file alone (`busted tests/input/input_widget_control_spec.lua`) and
   confirm it is green in isolation as well as in the whole suite.
4. **Helper *bodies*, not helper names.** The pre-move review grep-verified that
   no helper *names* collided. Check the stronger property: for every helper a
   moved row calls (`bare_uic`, `driver`, `open_doc`, `arm`, `open_on`, and any
   others), the body it resolves to in the merged file is the body it resolved to
   in its source file. Two same-named helpers with different bodies is the
   failure mode a name-collision grep reports as clean.
5. **Test-runner selection surfaces.** `/repo/.busted` sets
   `exclude-tags = "delay"` on the default profile, so a `#delay`-tagged row is
   silently excluded from every `busted tests` run anyone has done. Confirm
   whether any tag in this suite is excluded by configuration, and whether the
   pre-merge files carried tags the post-merge files do not (the `#lifecycle`
   fix addressed one; enumerate *all* tags on both sides, including tags on
   `describe`s rather than rows, and tags that appear only inside a nested
   describe). `busted --run=all` uses the non-excluding profile.
6. **`pending`, `finally`, and non-assert verification.** Three rows are pending;
   confirm the same three, in the same places, before and after. Rows verify
   things through means other than `assert.*` lines — `spy`/`mock`/`stub`
   expectations, `finally(...)`, error boundaries. An assertion-line diff does
   not see those.
7. **Citations of the six *renamed root describes*** (`a246c170`). The citation
   sweep chased the four deleted *filenames*. A comment, doc or tooling file that
   named one of those six files' **old root describe title** would still dangle.
   Search `src/`, `tests/` and `doc/` (including `doc/development/`) for such
   references.

If you find a *different* blind spot not in this list, that is the most valuable
thing you can return. Say plainly how you found it.

## Rules

- **Read-only.** Do not edit, create or delete any spec, source, doc or config
  file, and do not "fix" anything you find — report it. The only file you write
  is your deliverable. No `git add`, no `git commit`, **no `git push`**, no
  `git checkout --`, no branch or stash operations.
- If an experiment requires mutating the tree (e.g. checking out an old commit),
  **do not**: use `git show <sha>:<path>` to read, and if you must run an old
  version, copy it to `/tmp` and run it there. Leave `/repo` byte-identical to
  how you found it — verify with `git status --porcelain` at the end and state
  the result in your deliverable.
- The tree permanently carries the owner's untracked scratch (`claude.sh`,
  `src/STEPS.md`, `input-pr-slices.tar.gz`, `doc/tall_blocks.md`, some
  `doc/development/wip/` subdirs) and **three nested git repos** under
  `src/examples/`. All of it is expected. Leave it alone; do not enter the nested
  repos.
- **The `lua-lsp` MCP server is available** — defs / refs / diagnostics / hover
  over a real AST of the `/repo` workspace. Use grep to find candidates and the
  LSP to resolve a symbol or prove who calls what; string search gives guesses,
  the LSP gives facts. (After any `.lua` write, `sleep 1` before querying it —
  the server re-indexes. You are read-only, so this should not arise.)
- **Report what is, including nothing-found.** For each check, state the evidence
  you actually compared — the git command, the file:line, the command output —
  not a conclusion. "I ran X and got Y" beats "this is clean". If you cannot
  complete a check, say so and say why; an honest gap is worth more than a
  confident guess. A clean verdict on a check you actually ran is a good outcome
  and you will not be penalised for finding nothing.

## Deliverable

Write to
**`doc/development/wip/77-new-input-api/validation/reviews/S29-merge-revalidation.md`**.

Structure: one section per check attempted (including any you invented), each
with **CONFIRMED / FINDING / UNCLEAR**, the evidence, and for findings what is
wrong, where, and how you would characterise its severity. Then two closing
lines:

1. Did the merge change the *meaning* of any surviving row — its enclosing
   context, its isolation, its selectability, or what it can distinguish — while
   leaving its text intact?
2. What did you look for and *not* find? (Name the checks that came back clean,
   so the next reader knows the shape of your own pass and what it could not
   see.)

Your chat reply should be a short digest: verdicts, the findings if any, and the
two closing lines.
