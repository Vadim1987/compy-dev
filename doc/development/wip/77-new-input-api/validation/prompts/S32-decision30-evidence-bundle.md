# S32 — Decision 30 evidence bundle (cold check 1, mechanical)

**Model:** Sonnet (explicit). **Mode:** read-only verification. **Commissioned by:**
session32 parent, `implementation/sessions/session32/prompt.md` Part 1.

## Context you need (you do not inherit any)

You are working in the LÖVE2D project **compy**, repo root `/repo`, on branch
`feature/77-newapi-analysis-s20260615`. A large input-API feature is in pre-PR
validation. An owner ruling — **Decision 30**, in
`doc/development/decisions/input.md` — has just reversed the feature's central
implementation decision: device polling becomes the single source of held-modifier
truth, and the event-tracked set `compy.input.keys_pressed` is to be dissolved
everywhere.

Before any work is built on that ruling, its load-bearing **factual** claims must be
re-verified in code. That is your entire job. **You are not asked to judge the
ruling** — a separate judgement-heavy check does that. Report facts.

The PR base commit is **`3256aac`**. "Pre-existing" always means: present at
`3256aac`, checked with `git show 3256aac:<path>`. This distinction has overturned
conclusions in seven consecutive sessions — never infer it, always run the command.

## Hard constraints

- **Read-only.** Do not edit, create or delete any file except your deliverable.
  Do not modify tests. Do not run `git` commands that write (no checkout, no stash,
  no commit). `git show` / `git log` / `git diff` are fine.
- You may run `busted tests` to observe, but **do not change** the suite. Current
  baseline is **955 / 0 / 0 / 3**; report it if you see anything different.
- **The `lua-lsp` MCP server is available to you** (`definition`, `references`,
  `hover`, `diagnostics` over a real AST of the `/repo` workspace). Use it for
  correctness whenever you have a concrete symbol in hand: grep to find candidates,
  then LSP to resolve a symbol and to answer "who calls this". Grep is the
  completeness backstop — Lua is dynamically typed and LSP refs can be incomplete,
  so cross-check and trust neither alone.
- **The LSP cannot disambiguate a method name shared across tables.** If a name is
  a method on more than one table, grep and read the receiver type manually.
- Where a claim is about a **nested example repo** (`src/examples/keyboard`,
  `maze`, `balloons` — separate repos with their own history), say so explicitly and
  scope your verification to that repo's own git history.

## Task 1 — `tests/mock.lua` single-argument `isDown`, and its blast radius

**Claim to verify:** `tests/mock.lua:30` defines `isDown = function(k) return held[k] end`
— single-argument — while `Key.shift()` / `Key.ctrl()` / `Key.alt()` in
`src/util/key.lua` (around `:141-164`) call `love.keyboard.isDown` **variadically**
with a left/right pair. Consequence claimed: **every modifier assertion in the suite
consults only the left key of the pair**, so no suite result about modifiers can
currently be trusted.

Establish:

1. The exact current definitions, with line numbers, on both sides.
2. Whether the claim is true as stated, and whether it is true for **all three**
   modifier accessors or only some.
3. **Blast radius, enumerated.** Which test files and which test cases reach a
   `Key.*` accessor through code under test while driving modifier state through the
   mock? Distinguish two populations:
   - tests that set modifier state via the mock's **poll-shaped** path
     (`keystroke` at `mock.lua:60-70`, `release_keys` at `:49`, or direct `held`
     manipulation), and
   - tests that set `Controller.keys_pressed` (or the fixture at
     `tests/helpers/input_fixture.lua`, reportedly around `:272`) **directly**.
   Report counts and give the file list with line numbers. Note explicitly where a
   single test file uses both.
4. **The consequential question:** if `isDown` were made variadic
   (`return held[k1] or held[k2] or …`), which currently-passing test cases would
   change result, and in which direction? Reason it through statically; you may
   **not** edit `mock.lua` to find out. If you cannot determine this statically for
   some cases, say which and why — an honest "undetermined" is worth more than a
   guess.
5. Does any test case assert on a **right-hand** modifier (`rshift`, `rctrl`,
   `ralt`) at all? If none does, say so — it bounds the blast radius.

## Task 2 — the gate layer in `controller.lua`

Decision 30 rule 3 says `Key.*` at a call site is a smell to be replaced by
shortcuts, with **one standing exception: the framework's own gate for global
power-like combos, upstream of route dispatch.** The owner has since corrected the
characterisation: this exception is **a layer, not an exempt list** — a block that
runs *before* dispatch and tests its own universal set of key combinations by
direct polling. What it lacks is claimed to be a **mechanism**, not a
justification: **no shortcuts table exists at that position.**

Establish, in `src/controller/controller.lua` (and anywhere else the gate lives):

1. **Where the gate is.** The block(s) that poll modifiers and test combinations
   *before* project dispatch is reached. Give line numbers and quote the conditions.
2. **The complete enumeration** of combinations the gate implements today — every
   one, with its line, its combination (e.g. Ctrl+T), and what it does. Include the
   `keyreleased` side if it has one.
3. **Every direct modifier read in that layer**: `Key.ctrl()` / `Key.alt()` /
   `Key.shift()` / raw `love.keyboard.isDown`. Line numbers.
4. **Verify the mechanism claim**: is there in fact no shortcuts table at that
   position? Show what *is* there, and where the nearest shortcuts table lives
   relative to it in the control flow (which function, called from where). Use the
   LSP for the call chain.
5. **Where exactly the gate sits relative to `dispatch`** — trace the flow from
   the LÖVE callback entry to project dispatch and state where the gate interposes.
6. Report any modifier-polling site in the platform that is **outside** both this
   gate and `src/util/key.lua`'s three accessors — a bypass of the seam. One is
   claimed to exist at `src/lib/error_explorer.lua:418`; verify it and find any
   others. Exclude `src/examples/` (project code, exempt by ruling) but say what
   you excluded.

## Task 3 — "pre-existing" checks against `3256aac`

For each claim below, run the check and give a verdict of
**pre-existing / new-in-this-feature / mixed**, with the evidence command and the
relevant lines:

1. **All the gate's modifier polls exist verbatim at base.** Session31 recorded ten
   `Key.ctrl/alt/shift()` sites in `controller.lua` at base lines 163, 180, 531,
   553, 564, 571, 580, 585, 586, 643. Verify the count, the lines, and whether they
   are the *same* sites as today's gate (byte-for-byte where possible).
2. **`compy.input.keys_pressed` does not exist at `3256aac`** — verify across the
   whole base tree, not just `controller.lua`.
3. **`tests/mock.lua`'s poll-shaped fake predates the feature** — `keystroke`
   (`:60-70`) and `release_keys` (`:49`). Verify against base, and report whether
   the single-argument `isDown` is itself pre-existing or was introduced/edited on
   this branch.
4. **`src/util/key.lua`'s three one-line accessors predate the feature** and all
   platform call sites go through them at base too.

## Task 4 — sizing counts for the dissolution

The session prompt quotes a dissolution surface of `keys_pressed`: **22× `src/`**
(7 files, incl. `examples/keyboard/input.lua`), **38× `tests/`**, 15× in
`doc/development/decisions/input.md`, 12× in
`doc/development/internals/user_input.md`, 15× in `technical_debt/`, 8× in
`doc/input_api.md`. **Re-count all of these** and report actual numbers with a
per-file breakdown for `src/` and `tests/`. Note where a "reference" is a mention
in prose versus a live code read/write — the distinction matters for sizing.

## Deliverable

Write your report to
**`doc/development/wip/77-new-input-api/validation/outcomes/S32-decision30-evidence-bundle.md`**
— that file is the durable artifact; your final chat message is secondary and will
be lost. Structure it by task, lead each task with a one-line verdict, then the
evidence. Quote code with `path:line`. Where you could not establish something,
say so plainly under its own heading — do not fill a gap with inference presented
as fact. If you find that one of the claims above is **wrong**, that is a valuable
result, not a failure: state it prominently.
