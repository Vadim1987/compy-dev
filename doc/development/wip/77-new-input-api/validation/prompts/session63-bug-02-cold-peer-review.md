# Prompt of record — cold peer review of session63's `BUG-02` work

Spawned 2026-09-01 by session63 (Opus, explicit model), at the owner's direction. Deliverable path
given to the agent: `validation/outcomes/session63-BUG-02-cold-peer-review.md`.

---

You are a **cold peer reviewer**. You did not do this work and you owe it no deference. Your job is
to find what is **wrong, overclaimed, or missing** in a change that has already been committed, and
to say so plainly. "Looks good" is a valid verdict only if you tried hard to break it and failed.

## Environment and tools

- Repo root `/repo`, a LÖVE2D project in Lua. It is a git repo; the work under review is the last
  ~14 commits on the current branch. `git log --oneline -16` and `git show <sha>` are your friends.
- **Run the suite with `busted tests`** (uses mock_love; no display needed). Expected: **1038
  successes / 0 failures / 0 errors / 10 pending**. The 10 pending are an owner ruling, not drift.
- **An `lua-lsp` MCP server is available** (`mcp__lua-lsp__definition`, `references`, `hover`,
  `diagnostics`) giving defs/refs over a real AST of the workspace. Use it for "who calls this" and
  "where is this defined" — it is the correctness tool, and grep is your completeness backstop
  because Lua is dynamically typed and LSP refs can be thin. **It was returning `broken pipe`
  during the work under review**; if it still is, say so in your report and fall back to grep, but
  do not silently skip the question it would have answered.
- After editing any `.lua`, `sleep 1` before asking the LSP anything — it re-indexes.
- You may write throwaway probe specs into `tests/` to characterise behaviour (that is how the
  work under review was validated). **Delete them before you finish** and leave the tree clean —
  `git status` must show no modifications you did not intend. Do not commit anything.

## What was done (the claims, so you can attack them)

`BUG-02-01`: `UserInputModel:set_text` accepted "a string or list of line strings" but only the
string branch split embedded newlines, so `set_text{"a\nb"}` produced one line holding a raw
newline. The owner ruled *fix*, giving the reason: **the cursor addresses content as (line,
column), so un-normalised content makes that address ambiguous** — the same rule the existing UTF-8
sanitisation serves. Then, on the owner's further direction, the two branches were **unified into
one path preceded by a normalisation step**, and a **dead `_update_cursor` call** in the string
branch was deleted. A **Decision 38** was written. A `DEBT:` comment convention was introduced.

## Verify these specific factual claims IN CODE. Several are load-bearing.

Do not take any of them on trust; each was asserted by the author, and **three of the author's
earlier claims in this same session were already found wrong and corrected**, so the prior here is
not good.

1. `string.lines` is polymorphic over `string | string[]` and delegates a list to
   `string.split_array`, which splits each element **and preserves empty elements**.
2. **All seven** callers of `_set_text_line` pass `keep_cursor = true`, making its
   `_update_cursor` call unreachable. Count them yourself.
3. `clear_input` is therefore the only reachable caller of `_update_cursor`, and it yields `(1,1)`
   only because empty content makes every line measure zero — "correct by accident".
4. `_update_cursor(true)` can produce an **out-of-range** cursor: claimed `(3,7)` on
   `{'one','twotwo','xx'}` with the caret on line 2, where line 3 has caret positions 1..3.
5. The deleted `set_text` call was **inert in every revision it existed in** — the introducing
   commit `472c6bba` already ended `set_text` with an unconditional `jump_end()`. Check the history.
6. `_update_cursor`'s pre-multiline form was `self.cursor.c = utf8.len(t) + 1` over a **string**
   `entered`, and commit `19351528` (2023-07-17) broke it by indexing a list with the **old cursor
   line** (`t[cl]`) while setting `.l` to `#t`.
7. `_update_cursor` is a **partial, unvalidated duplicate of `jump_end`** — and `jump_end` is *not*
   a drop-in replacement at `clear_input` because it also calls `end_selection` and
   `visible:to_end()`.
8. `after_submit` receives the **line list itself** while `on_text_entered` receives the joined
   string, so the two spellings of the content shape used to hand a project different payloads.
9. There is **no content getter** on the `compy.input` surface, so normalising breaks no
   set/get round-trip.
10. Both draw paths reach `gfx.print`, which honours `\n`, and they corrupt an embedded newline
    **differently** (`ViewUtils.write_line` whole-string vs the per-character highlighted path).

## Then judge these, which are not facts but calls

- **Does the unification change behaviour anywhere it should not?** Compare `normalized_lines`
  against the two branches it replaced, at `3dd14192` (session base) and `dd19cf64`. Hunt edge
  cases: `nil`, numbers, booleans, nested tables, empty table, sparse arrays, a table with a
  `nil` hole, very long lines, multi-byte content, `keep_cursor` true and false.
  **A known one is listed under "open item" below — find others.**
- **Is Decision 38 sound, and is it correctly scoped?** Read
  `doc/development/decisions/input.md`, Decision 38. Does it claim more than the code does? Does
  it contradict any earlier decision (35, 36, 37 especially)? Is the "normalisation is not
  validation" boundary actually respected by the implementation?
- **Are the tests any good?** Would they catch a regression, or do they pass for the wrong reason?
  Try mutating the production code and see which tests fail. A test that survives the mutation it
  was written to catch is a finding.
- **Is the `DEBT:` marker convention sound?** It is defined in `agents/rules/commenting.md`.
  Note that the release gate is `grep -rnE 'INTERIM|REMARK|^[[:space:]]*--(->|>)' src/ tests/`
  and must return nothing before the PR; `DEBT:` is deliberately outside it. Is that defensible,
  and is the guard against a future sweep folding it in adequate?
- **Are the ledger entries honest?** `doc/development/technical_debt/input.md` — the RETIRED
  entries for `BUG-02` and for the cursor fossil, and the new BACKLOG entry for `_update_cursor`.
  Is anything overstated, under-stated, or filed in the wrong section? House rule: a debt entry is
  slugged (`T-XXX`) only when `ACTIVE`, a slug being the commitment to fix.
- **Rules compliance**: line length ≤ 64 chars, function body ≤ 14 lines, params ≤ 4, nesting ≤ 4
  (`agents/rules.md`); comment content rules in `agents/rules/commenting.md` — especially "a
  reference is not an annotation" and the size rule.

## Known open item — assess it, do not just confirm it

The author found, after committing, that `set_text{'a', 42}` **silently drops** the `42`: at
session base `3dd14192` it produced `{"a","42"}`, and since the `BUG-02` fix it produces `{"a"}`
(because `string.split` type-checks and returns `{}` for a non-string). Meanwhile Decision 38 says
*"nothing here rejects, truncates, escapes or re-flows what is set"*. **Is this a real defect, a
contract question, or a non-issue?** Note the input is arguably out of contract already, and the
base behaviour — storing a raw *number* in a list of "line strings" — was not obviously better.
Give a recommendation: fix the code, narrow the decision's wording, or record and leave. Say what
you would do and why. Also check whether `true` / nested-table elements raising from inside
`sanitize_utf8` is acceptable or is its own defect.

## Deliverable

Write your report to **`doc/development/wip/77-new-input-api/validation/outcomes/session63-BUG-02-cold-peer-review.md`**.

Structure it as:

1. **Verdict** — one of *approve* / *approve with comments* / *changes needed*, in one line.
2. **Claim check table** — each numbered claim above: CONFIRMED / REFUTED / COULD NOT VERIFY, with
   the evidence (file:line, command output, or probe result). Refutations are the most valuable
   thing you can produce.
3. **Findings**, most severe first. For each: what is wrong, how it is reachable, and what you
   recommend. Mark each as defect / overclaim / omission / style.
4. **The open item** — your recommendation with reasoning.
5. **What you could not check**, and why. Be explicit; an unchecked thing named is worth more than
   a gap papered over.

Be concrete and cite evidence. Do not pad. If you think a piece of the reasoning is *right*, say so
briefly and move on — spend your words on what is wrong.
