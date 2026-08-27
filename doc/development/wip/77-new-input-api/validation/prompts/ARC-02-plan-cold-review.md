# Sub-agent prompt of record — cold sanity review of the ARC-02 plan

**Spawned session49, 2026-08-27. Model: Opus (explicit).** Judgment work on a design plan, and the
owner asked for a *cold* reader — the one case where validation.md prefers a spawn over doing it in
the parent. Deliverable path given to the agent: `validation/outcomes/ARC-02-plan-cold-review.md`.

---

You are reviewing a **plan**, not code that has landed. Nothing in it has been executed. Your job is
a sanity check by someone who did not sit through the conversation that produced it.

Repo root is `/repo` (a LÖVE2D project, Lua). Read these, in this order:

1. `/repo/doc/development/wip/77-new-input-api/validation/reviews/ARC-02-configure-boundary-plan.md`
   — **the plan under review**.
2. `/repo/src/controller/userInputController.lua` — the "widget API" section (roughly `:236-365`):
   `apply_config`, `re_show`, `open_widget`, `show`, `hide`, `configure`.
3. `/repo/src/controller/consoleController.lua` — roughly `:570-830`: the key sets
   (`CALLBACK_KEYS`, `PER_SHOW_KEYS`, `CONFIGURE_KEYS`, `SHOW_KEYS`, `LIFECYCLE_KEYS`), `check_keys`,
   `merge_callback_keys`, `consume_pending`, `stash_hidden_configure`, `api_show`, and the
   `build_widget_api` table.
4. `/repo/doc/input_api.md` — "The input widget — opening it and changing it", "Live changes",
   "Callback assignments". This is the **project-facing** contract.
5. `/repo/doc/development/decisions/input.md` — **Decision 15** only (`:568-605`), whose scope
   paragraph the plan proposes to amend.

**Do NOT read** the session track
(`implementation/sessions/session49/track.md`) or the two predecessor reviews
(`force-and-configure-intent-recovery.md`, `ARC-01-07-reconfiguration-policies.md`) **until you have
formed your own view of the plan**. They contain the reasoning that produced it, and the point of
your spawn is that you did not sit through it. Afterwards, consult them only to check a specific
claim you doubt — and say in your report which ones you opened and why.

## What to check, in priority order

1. **Does the plan's §2(a) correction hold?** It claims `UserInputModel:clear_input()` and
   `set_text('')` are not equivalent, and names three effects the second one misses. Verify in
   `src/model/input/userInputModel.lua`. If it is wrong, that is the most valuable thing you can
   report.
2. **Is anything load-bearing missed?** The plan deletes `re_show`, removes `text` from
   `apply_config`, and (under pick A(ii)) deletes `state.pending`. Use the LSP to establish who
   actually calls each of these, then grep as the completeness backstop. A caller nobody accounted
   for is the classic failure here.
3. **Do the proposed steps preserve suite-green at every commit?** The project's standing rule is
   that every commit leaves `busted tests` green (currently **979 / 0 / 0 / 10**). Steps `-03`,
   `-04` and `-05` change behaviour that existing specs pin. Say which existing specs each step
   breaks and whether the ordering can actually hold, or whether two steps must merge.
4. **Pick A (warn vs raise) — argue the side the plan did not.** The plan recommends raising. Make
   the strongest case for warning that you can, then say which you would choose. Decision 15's scope
   paragraph is the text that matters.
5. **Pick B — is the reasoning honest?** The plan argues that removing the hidden-`configure` stash
   is not a broken promise because the spec sentence stays true for the fields `configure` still
   accepts. Is that a real argument or a rationalisation? Is any project capability actually lost?
   Check `src/examples/` for anything that would break.
6. **Scope.** Is `ARC-02` one sprint or two? Is anything in it that should be a separate row, or
   anything left out that this plan cannot avoid touching?

## House rules you must follow

- **Verify every factual claim in the code before you rely on it** — including the plan's. Three
  verdicts in this project have been overturned by someone checking. Cite `file:line`.
- **The `lua-lsp` MCP server is available and you should use it**: definitions, references,
  diagnostics and rename over a real AST of the `/repo` workspace. Grep to find candidates, then the
  LSP to resolve a symbol and to answer "who calls this". Treat LSP references as a strong hint, not
  ground truth — Lua is dynamically typed — and grep as the completeness backstop. If you edit any
  `.lua` file, `sleep 1` before querying refs/diagnostics so the server can re-index.
- **Do not change any file except your deliverable.** No code edits, no doc edits, no commits. You
  may run `busted tests` read-only to see the baseline.
- **A green suite is not evidence on the project dispatch path**: `with_canvas_and_errors` xpcalls
  the walk, so a raise there is swallowed and printed. If you reason about a raise reaching a
  project, say what would have to be asserted (`love.state.suspend_msg`, `app_state`).
- `| head` on a counting grep lies, and a loose pattern lies too (`grep "Decision 1"` matches
  `Decision 15`).

## Deliverable

Write `/repo/doc/development/wip/77-new-input-api/validation/outcomes/ARC-02-plan-cold-review.md`.

Open with a one-line verdict — **approve / approve with changes / do not proceed** — then the
findings, most severe first, each with its evidence at `file:line`. Then a short section listing
what you checked and found **correct**, so the parent can tell verified ground from unexamined
ground. End with the two picks and your recommendation on each.

Say plainly where you ran out of confidence. An honest "I did not verify this" is worth more than a
verdict that reads as authoritative and is not.
