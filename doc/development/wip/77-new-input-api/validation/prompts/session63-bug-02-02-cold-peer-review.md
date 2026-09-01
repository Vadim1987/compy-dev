# Prompt of record — cold peer review of `BUG-02-02` (the content boundary check)

Spawned 2026-09-01 by session63 (Opus, explicit model), at the owner's direction, as the second
cold review of this session. Deliverable:
`validation/outcomes/session63-BUG-02-02-cold-peer-review.md`.

---

You are a **cold peer reviewer** with no stake in this work. Find what is **wrong, overclaimed, or
missing**. "Looks good" is only a valid verdict if you tried hard to break it and failed.

**The assistant whose work you are reviewing has already been caught making four wrong factual
claims today**, three of them in documents, one refuted by the previous cold review of this same
sprint. Verify everything in code. Do not extend it any benefit of the doubt.

## Environment

- Repo root `/repo`, LÖVE2D/Lua, a git repo. The change under review is commits `9d5cbd41`
  (production fix + tests) and `18250e3e` (docs and ledgers). `git show <sha>` them.
- **`busted tests`** → expect **1043 / 0 / 0 / 10**. The 10 pending are an owner ruling, not drift.
  Note the container runs **LuaJIT 2.1, not the owner's PUC Lua** — say so if any finding could
  differ by interpreter.
- **`lua-lsp` MCP** (`definition` / `references` / `hover` / `diagnostics`) gives AST-level facts;
  it was returning `broken pipe` all day. Try it; if it still fails, say so and fall back to grep
  plus a manual scan for dynamic dispatch, rather than silently skipping what it would have
  answered. `sleep 1` after any `.lua` edit before querying it.
- You may write throwaway probe specs under `tests/`. **Delete them before finishing.** Leave the
  tree clean apart from your one report file. **Commit nothing.** Work in the shared `/repo` tree —
  no worktrees, no luarocks bootstrapping.

## What the change claims to do

`show{text = …}` and `compy.input.set_text` document their argument as *"a string or list of line
strings"*. A list element that was not a string got three unrelated answers: `{'a', 42}` silently
**dropped** the number, `{42}` **wiped** the content to `{''}`, and `{'a', true}` raised
`bad argument #1 to 'len'` from inside `sanitize_utf8`. The first two were introduced **hours
earlier the same day** by `BUG-02-01`'s own fix; the third is pre-existing.

A new `checked_text` at the project boundary (`src/controller/consoleController.lua`) now refuses
all three with one message naming the failing call, following `checked_cursor`'s established shape
(`BUG-01-08`). The surface's `set_text` closure was lifted into an `api_set_text` for the level-4
depth rule, as `api_set_cursor` already was.

## Attack these specifically

1. **Is `checked_text` correct and complete?** Hunt inputs that slip through or are wrongly
   refused: `nil`, `false`, `''`, `{}`, `{''}`, a table with a **`nil` hole** (`{'a', nil, 'b'}`),
   a **sparse** array, a table with **hash keys** (`{'a', foo = 'bar'}`), a nested empty table, a
   string containing `\0`, a very long list, a table with a metatable/`__index`, a string subclass.
   **Specifically: does `{'a', nil, 'b'}` silently lose `'b'`?** `ipairs` stops at a hole, in both
   `checked_text` and `normalized_lines`. If content is silently lost there, that is the same
   defect class this change exists to close, and the change would have missed it.
2. **Is the boundary complete for the project surface?** Every path by which a *project* can set
   content must pass the check. Enumerate them — `show`, `set_text`, anything else (`configure`
   is supposed to refuse `text` via `check_keys`; verify that it does). Framework-internal callers
   (console, editor, history) legitimately bypass it; confirm the split is where it is claimed.
3. **Did lifting `set_text` into `api_set_text` change anything?** The hidden-widget warn path, the
   return value, argument forwarding, `keep_cursor` threading. Compare against `9d5cbd41^`.
4. **Is the error attribution actually right?** `error(…, 4)` is depth-sensitive and the file's own
   comments say both entry points must reach the check at the same depth. Verify the level is
   correct from `show` AND from `set_text` — and say what the message looks like from a *project's*
   call site, not just from a spec.
5. **Does `false` still work as the unset?** Decision 35 statement 3 makes `false` the uniform
   unset. `checked_text` returns `nil` for any falsy value. Is `show{text = false}` handled the way
   the ledger says, and is that consistent with how `cursor` treats `false`?
6. **Are the five new tests good?** Mutate the production code and check each fails for its stated
   reason. A test passing for the wrong reason is a finding. Note they use `pairs` over a table of
   cases — confirm that actually runs four cases and is not silently skipping any.
7. **Are the documents honest?** `doc/input_api.md` ("Live changes"), Decision 38's new boundary
   section, `CHANGELOG.md`, the RETIRED debt entry, and the `BUG-02-02` ROADMAP row. Does any of
   them claim more than the code does? **The CHANGELOG line is deliberately written against the
   last release rather than against this morning** — the drop and the wipe never shipped — judge
   whether that is the right call and whether the entry is accurate about what a stakeholder sees.
8. **Rules compliance:** line ≤ 64 chars, function body ≤ 14 lines, params ≤ 4, nesting ≤ 4
   (`agents/rules.md`); comment payloads and the "a reference is not an annotation" rule
   (`agents/rules/commenting.md`). Note `api_set_text` takes 4 parameters — at the limit, not over
   it; confirm.
9. **Is refusing actually right here?** The alternative considered and rejected was coercion
   (`tostring`). The argument for refusal is that `{'a', 42}` matches
   `insert_text_line(text, li)`'s argument shape, so such a list most likely comes from signature
   confusion. **Push back on that if you think it is weak** — is there a realistic project that
   wants `set_text{1, 2, 3}` to display three numbers? Does refusing break any shipped example?

## Deliverable

Write to **`doc/development/wip/77-new-input-api/validation/outcomes/session63-BUG-02-02-cold-peer-review.md`**:

1. **Verdict** — *approve* / *approve with comments* / *changes needed*, one line.
2. **Point-by-point** on the nine items above: what you did, what you found, evidence
   (file:line, probe output, command results).
3. **Findings**, most severe first — defect / overclaim / omission / style; each with how it is
   reachable and what you recommend.
4. **What you could not check**, explicitly.

Cite evidence, do not pad, and spend your words on what is wrong rather than on what is right.
