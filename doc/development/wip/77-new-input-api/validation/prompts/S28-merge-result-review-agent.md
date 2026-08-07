# S28 — sub-agent prompt of record: cold review of the merge RESULT (post-move)

Spawned: 2026-08-07, session28, P8 tail. Model: **Sonnet** (explicit).
**Read-only.** The owner required a cold review of the execution after the move,
as a separate pass from the review of the plan.

---

## Context you do not have

`/repo` is a LÖVE2D project (Lua 5.1) finishing a new input API for a PR. Its
input test suite has just been restructured: two pairs of spec files were merged
into two new files, and the surviving files' root describes were renamed to name
the API's three surfaces (*inbound events*, *widget control*, *widget
callbacks*).

The work was done in three commits by an agent following a written, cold-reviewed
plan. Your job is to check the **result** against the **plan** and the
**inventory** — not to re-litigate the plan, which the owner has approved.

Documents:

- **Plan (the specification):**
  `doc/development/wip/77-new-input-api/validation/reviews/S28-merge-plan.md` —
  §2A and §2B are the target shapes, §5b the revision log naming the only three
  content changes that were authorised.
- **Inventory (what existed before):**
  `doc/development/wip/77-new-input-api/validation/outcomes/S28-merge-inventory.md`
  — every row of the four source files with its describe path and helpers.
- **Pre-move review:**
  `doc/development/wip/77-new-input-api/validation/outcomes/S28-merge-plan-review.md`

The commits, oldest first: `90f632cf` (step 1), `25f70175` (step 2), `b0c9d032`
(a tag fix), `bc5b97ae` (citation repointing), `a246c170` (step 3). The suite was
**954** before and is **952** now; two rows were deliberately deleted.

`git show <sha>` and `git show <sha>:<path>` reach the pre-merge files. **Use
them** — the four source files are deleted in the working tree, so the only way
to compare against the originals is through git.

**The `lua-lsp` MCP server is available** if you need to resolve a symbol.

## What to check

1. **No row was lost or silently altered.** For each of the four source files at
   `90f632cf^`, take every `it(...)` row and find it in the merged files. Two
   rows are legitimately gone (named in the plan §2B). Compare each surviving
   row's **body**, not just its title: a moved row's assertions and comments were
   to come across unchanged. Report any row whose body differs from its
   original, other than the three authorised assertion changes in §5b.
2. **The three authorised content changes are exactly as specified** — the two
   deletions and the assertions added to their two survivors, with the specific
   helper (`F.is_widget_visible()` vs `F.widget:is_shown()`) at the specific
   positions §5b names. Both helpers exist and mean different things; confusing
   them is what the pre-move review caught.
3. **Tags.** The merge lost the `#lifecycle` tag once already (fixed in
   `b0c9d032`). Enumerate every busted tag in the four source files at
   `90f632cf^` (`#input`, `#lifecycle`, `#disputable`, any other) and confirm
   each still selects the same rows. `busted tests --tags=<tag>` gives counts.
   This is the check the row-and-assertion comparison cannot make.
4. **Helpers and requires.** `bare_uic`, `driver`, `open_doc`, `arm`, `open_on`,
   and the `TU` require were to move with their rows. Confirm each exists in the
   file that needs it, and that no row calls a helper that did not come across.
5. **Dangling references.** Four filenames no longer exist
   (`input_widget_lifecycle_spec`, `input_reconfigure_spec`,
   `input_widgets_callbacks_spec`, `input_lifecycle_uniform_spec`). Grep the
   whole repo **outside** `doc/development/wip/` for any surviving mention, in
   comments or docs. Also check the repointed citations actually resolve: a
   comment naming a describe group must name one that exists.
6. **The suite still means what it did.** `busted tests` → 952 / 0 / 0 / 3, and
   each merged file's row count matches the plan (39 and 52). Confirm no file
   ended up with duplicate `describe` titles or two rows with identical titles in
   the same group, which would make a failure report ambiguous.

## Rules

- **Read-only.** Do not edit, create or delete any spec, source, doc or config
  file. No `git add`, no commit, no push. The only file you write is the
  deliverable. Do not "fix" anything you find — report it.
- The tree carries untracked scratch and three nested git repos under
  `src/examples/` — leave all of it alone.
- **Report what is, including nothing-found.** If a check passes, say which
  evidence you actually compared rather than asserting it passed. If you cannot
  complete a check, say so — an honest gap is better than a confident guess.

## Deliverable

Write to
**`doc/development/wip/77-new-input-api/validation/outcomes/S28-merge-result-review.md`**:
each numbered check with a verdict (CONFIRMED / FINDING / UNCLEAR), the evidence
(file:line, or the git command you compared with), and for findings, what is
wrong and where. Finish with one line: does the merged suite preserve the
pre-merge suite's coverage, minus exactly the two authorised deletions?

Your chat reply should be a short digest: the verdicts and the final line.
