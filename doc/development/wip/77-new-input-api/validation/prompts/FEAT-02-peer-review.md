# Prompt of record — cold peer review of `FEAT-02`

**Commissioned by session58, 2026-08-30, on the owner's instruction.** Model: Opus (judgment work;
the Fable oracle tier is retired). Deliverable:
`doc/development/wip/77-new-input-api/validation/outcomes/FEAT-02-peer-review.md`.

The prompt below is what the agent received, verbatim.

---

You are reviewing a completed sprint in the **compy** LÖVE2D project (repo root `/repo`, your cwd).
You are a **cold reader**: you did not do this work and you are not here to ratify it. Your job is
to find what is wrong with it, and to say plainly when something is right.

## What the sprint was

`FEAT-02` of feature #77 (a new input API). A config key that closes the input widget after a
successful submit was **renamed and re-categorised**:

- it was `oneshot`, a **`show`-only** key, seated unconditionally at activation and therefore
  cleared by any later `show` that did not name it;
- it is now **`auto_hide`**, a **project-owned** key: settable at `show` **and** `configure`,
  set-if-given, `false` to unset, and **persistent until replaced** — a mode, not a one-off.

The owner ruled it. The ruling and its reasoning are in
`doc/development/wip/77-new-input-api/validation/notes/owner-attestation-oneshot-widget-property.md`;
the five rows are in `doc/development/wip/77-new-input-api/ROADMAP.md` under `FEAT-02`.

## The work under review

Commits `4811a4e5..HEAD` on the current branch (`git log --oneline 4811a4e5~1..HEAD`). That range
includes the ledger amendments, the rename, the code change, the docs, the CHANGELOG, an example
(`src/examples/turtle`) converted to the new key, and a new manual smoke checklist for it.

`git diff 4811a4e5~1..HEAD` is the full diff. **Read the code, not only the diff.**

## What to check — in this order

1. **Does the implementation do what the ruling says?** `auto_hide` set-if-given at both entry
   points, persistent, `false` unsets, and nothing left of the old show-only behaviour. The
   relevant code is `src/controller/consoleController.lua` (`SHOW_ONLY_KEYS`, `WIDGET_KEYS`,
   `CONFIGURE_KEYS`/`SHOW_KEYS`, `api_show`/`api_configure`) and
   `src/controller/userInputController.lua` (`configure_core`, `open_widget`, `submit_flow`).
2. **Is there a reachable case the sprint broke or left inconsistent?** Think about: a `configure`
   between runs, a hidden `configure`, the console and editor widgets (which are `always_shown` and
   refuse `hide()`), a project that never names the key, and the interaction with `force`.
3. **Are the tests worth their green?** Four cases were added or inverted in
   `tests/input/input_widget_{control,callbacks}_spec.lua`. This project is **strongly BDD**: a test
   should assert observable behaviour through the public `compy.input` surface, not internal state.
   Check that each case **discriminates** — that it would fail if the behaviour regressed. Mutate
   the source and re-run if you want proof; **revert any mutation** before you finish.
4. **Do the documents agree with the code?** `doc/input_api.md`, `doc/development/internals/user_input.md`,
   `doc/development/decisions/input.md` (Decisions 35 and 36), `doc/development/technical_debt/input.md`,
   `CHANGELOG.md`, `src/types.lua`. A statement that is now false, or a key list that is missing the
   key, is a finding. So is a **citation that still resolves but no longer means what it did**.
5. **The example and its checklist.** `src/examples/turtle/main.lua` now passes `auto_hide = true`
   and its `after_submit` only re-arms an echo guard. Is that equivalent to what it did before?
   Is the new checklist in `doc/development/smoke_checklists.md` (section *"turtle"*) accurate,
   runnable by a human, and does it actually cover the change?
6. **Anything the sprint should have caught and did not**, anywhere in its blast radius.

## Facts you should verify rather than assume

The sprint asserts these. Check them:

- a project **cannot** read the widget's text through `compy.input` (no getter), so a forced
  re-setup destroys a draft nothing can restore;
- reading the flag **after** the callbacks in `submit_flow` is load-bearing — capturing it before
  them breaks a case that currently passes;
- the token `oneshot` is still legitimately in-tree for the **profiler** and in two historical
  comments about a model field that no longer exists.

## Ground rules

- **Verify every claim in code before reporting it.** Both a previous sub-agent and the parent have
  been wrong on facts in this phase. Quote `file:line`.
- The **`lua-lsp` MCP server** is available: definitions, references, diagnostics and rename over a
  real AST of the `/repo` workspace. Use it for "who calls this" and "does this still resolve";
  grep is the completeness backstop, not the authority. After any `.lua` edit, `sleep 1` before
  querying it — the server re-indexes.
- The suite is `busted tests`, run from `/repo`; it needs no display. The expected result is
  **1023 successes / 0 failures / 0 errors / 10 pending**. The 10 pending are an owner ruling, not
  drift.
- **Do not fix anything.** Report. If you mutate code to test a hypothesis, revert it and say so.
- **Do not push, do not commit.**

## Deliverable

Write `doc/development/wip/77-new-input-api/validation/outcomes/FEAT-02-peer-review.md` yourself —
your final chat message is lost when the context rolls, so the file is the artifact.

Structure it as: a one-line **verdict** (approve / approve with comments / reject), then findings
ordered by severity, each with `file:line`, what is wrong, how you verified it, and what you would
do about it. Separately list what you checked and found **correct** — a review that only lists
problems cannot be distinguished from one that stopped early. State plainly anything you could not
check and why.
