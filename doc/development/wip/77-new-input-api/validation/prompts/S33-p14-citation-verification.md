# S33 — verify every citation and count in the P14 plan (mechanical, read-only)

**Model:** Sonnet (explicit). **Mode:** read-only verification. **Deliverable:**
`/repo/doc/development/wip/77-new-input-api/validation/outcomes/S33-p14-citation-verification.md`
(write that file; it is the only file you may create or modify).

## Context you do not have

You are a cold sub-agent in a Lua/LÖVE2D project at `/repo`. A planning document was
written last session; a revalidation session is now checking it. **Your job is fact-checking
its citations — not judging the plan.** Do not propose plan changes, do not edit any file
except your deliverable, do not run the app.

The document under check is
`/repo/doc/development/wip/77-new-input-api/validation/reviews/S27-triage-and-plan.md`,
**§11 only** (lines 881–1061). Read it first, in full.

Many of §11's line numbers were inherited from an earlier agent's report and were **never
verified in code**. One number already known wrong: three successive documents claimed
`doc/development/internals/user_input.md` holds 12 `keys_pressed` occurrences; it holds 10.
**Assume nothing in §11 is verified.** Your finding of "correct" is as valuable as a
correction — but each must be backed by what you actually saw.

## Tooling — this matters

- **The `lua-lsp` MCP server is available** (`mcp__lua-lsp__definition`, `references`,
  `hover`, `diagnostics`) — a real AST over the `/repo` workspace. Use grep to find
  candidates, then **LSP to resolve a symbol and to answer "who calls this"**. It is the
  correctness tool for the completeness question in task 3. Its refs can be *incomplete* in
  a dynamically typed language, so **grep is the backstop — cross-check, trust neither
  alone**. (If you edited a `.lua` file you would `sleep 1` before querying; you are
  read-only, so this will not arise.)
- **The LSP cannot disambiguate a method name shared across tables.** Where a name is
  ambiguous, read the receiver manually.
- Line numbers drift. When a citation is off, report **where the cited thing actually is**,
  not merely that the number is wrong.

## Tasks

For every item below: quote the claim as §11 states it, then state **CONFIRMED /
WRONG (with the true location or number) / UNVERIFIABLE (say why)**.

### 1. Doc citations (§11.4 P14a, §11.3 P10)

- `doc/input_api.md` §"Held keys" spans `:365-395`.
- `doc/input_api.md:268` is a **false claim** that a hook receives the held table as a second
  argument, and `:390` contradicts it. Quote both lines.
- `doc/development/internals/user_input.md` holds **10** `keys_pressed` occurrences (exact
  count, `grep -c` is not enough if a line holds two — count occurrences, and say which).
- **Decision 21** in `doc/development/decisions/input.md` contains a worked example saying a
  hook "receives the held-key view", and **Decision 26** removed that argument. Give the line
  numbers of both, and quote the stale sentence verbatim.

### 2. Test citations (§11.4 P14c)

For each range: does it exist, does it end where claimed, and does its content match the
description? Report the actual `describe`/`it` boundaries.

- `tests/input/keys_pressed_spec.lua` — first describe at `:52-96` (marked **delete**);
  second describe at `:98-138` (marked **keep UNCHANGED**, described as driving the
  *source-blind* matcher against a **synthetic** table). For the second: **verify it truly
  never touches `compy.input.keys_pressed`** — i.e. it builds its own table and passes it in.
  That claim is load-bearing.
- `tests/input/input_nfr_mechanism_spec.lua` — `:66-105` (delete), `:123-165` (keep).
- `tests/input/input_events_spec.lua` — `:781-905` (delete); `:557`, `:616`, `:734`,
  `:857-861` (individual rewrites; some said to assert a write-before-dispatch ordering).
  For each single-line citation, quote the line and say what it asserts.

### 3. Production-code citations AND the completeness question (§11.4 P14d)

Verify each site, then answer the completeness question, which is the most important part of
this task:

- `src/model/projectInputController.lua:103-110` — `find_shortcut`, claimed to be the
  **single production call site** that reads the tracked set for matching.
- `src/model/controller.lua` — `:788` and `:906` (the two **writes**), `:498` (the field),
  `held_keys()` + proxy memoisation at `:420-443` and `:501`.
- `src/model/consoleController.lua:539-540` (sandbox field) and `:829-834` (the `held`
  upvalue plumbing).
- Claim: **`combo_string` / `any_mod` need no change — they are source-blind** (they take a
  plain table and index it by raw key name, never calling `Key.*`). Verify in code.
- **COMPLETENESS:** enumerate **every** occurrence of `keys_pressed` under `src/`
  (file:line, with the enclosing function). An earlier count said **22 occurrences across 7
  files, including `src/examples/keyboard/input.lua`**. Confirm or correct that count, then
  state explicitly: **which occurrences are NOT accounted for by any P14d/P14e bullet?** Use
  LSP references as well as grep — a site the plan does not name is the finding this task
  exists to produce.

### 4. Example citations (§11.4 P14e)

- `src/examples/keyboard/input.lua` — the `INPUT.__index` held branch (give its lines).
- `src/examples/keyboard/keyboard_view.lua:171` and `:178`.
- Note (do not judge): for each of these reads, is it **drawing/decoration** or a
  **judgement**? Report what the code does; the sorting is the owner's, not yours.

### 5. Mock citations (§11.5)

- `tests/mock.lua` — the `mods` token map at `:17-21`, the `held` table at `:5-15`. Confirm
  the claim that `held` "already has the slots" for right-hand variants (`rctrl`/`rshift`/
  `ralt`) — quote the table.

### 6. Technical-debt register (§11.6) — every line number

`doc/development/technical_debt/input.md`. For **each** cited line, quote the entry's title
and state whether it matches the description §11.6 gives it:

`:29`, `:61`, `:81`, `:281`, `:442` (claimed **dissolve**) · `:396` (claimed a RESOLVED entry
reading "owner ruled to expose it") · `:664`+`:689`, `:738`+`:731`, `:775`+`:773` (claimed
**rework** — each pair is an entry and the specific line naming `keys_pressed`) · `:795`,
`:178`, `:988` (claimed **survive unchanged**) · `:58`, `:77` (claimed to carry a now-false
*"Scheduled: before the PR (plan phase P9d/P9e)"* wording).

Also check the claim that **`:29` and `:281` are two entries for the same defect**.

### 7. Counts and id lists

- **`grep -rn 'INTERIM:\|REMARK:' src/ tests/`** — §11.3 P11 claims **22** in the platform and
  **5** in `src/examples/`. Give exact numbers and the file:line list. (Note `src/examples/`
  sits *inside* `src/` — state clearly whether 22 includes the 5 or not, since that ambiguity
  is itself worth reporting.)
- §11.3's **P8** row names nine remaining ids: R057, R074, R078, R079, R047, R063, R064,
  R069, R075. Cross-check against **§4's P8 row** ("Left:" list, line 580) and **Appendix A's
  W8 membership** (line 660). Do all three agree? Is any W8 id missing from all of them?
- §11.1 claims `src/probe/input_probe.lua` declares itself *"DIAGNOSTIC, TEMPORARY. Delete
  when the polling-vs-tracking question is ruled on."* Quote its header.
- §11.4 claims `src/lib/error_explorer.lua:418` is a `love.keyboard.isDown` call. Quote it,
  and confirm it is **byte-identical at the PR base**: `git show 3256aac:src/lib/error_explorer.lua`.

## Deliverable format

One section per task, findings first. Open with a **summary table**: claim → CONFIRMED /
WRONG / UNVERIFIABLE, with the correction inline. Close with **"Claims that are wrong, in
severity order"** and **"Sites the plan does not account for"** — those two lists are what
the parent session acts on. Be terse; no praise, no plan advice.

Do not run `busted` (the parent owns the baseline). Do not `git checkout` anything. Do not
modify any file other than your deliverable.
