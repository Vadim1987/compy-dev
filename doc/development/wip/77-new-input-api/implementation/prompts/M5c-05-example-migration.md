# M5c-05 — example migration: turtle + maze (chunk 5 of the M5c carve)

_Implementor commission (`agents/dev.md`). Milestone id `M5c-05`. Final chunk of the
M5c carve — **Scope 6 [examples]**. Delivers **AC-32** (turtle + maze migrated onto
`compy.input.*`, hand-playable afterwards). The native-wrap / AC-31 / AC-33 / AC-36
dispatch semantics are **already landed and green** — you do NOT re-touch them. Suite
baseline entering this chunk: **779 / 0 / 0 / 5**._

## Read first (authority chain — higher wins)

1. `design/notes/ratified-model.md` — R1 (`on_text_entered` = submit output, fires
   **once** at Enter with the full assembled text, NOT per-char), R7 (natives are
   pure-wrap tier-3 participants).
2. `design/design.md §5` (esp. L255-268) — **the migration mandate**: turtle + maze
   have *both* natives *and* widget solicitation; they **change behaviour** and are
   migrated under the **SR1 break mandate**. Per the ruling, breaking-and-fixing these
   two is *expected* and **preserving their old blocking/poll behaviour is explicitly
   not required** (D-9 "zero example changes" is *formally lifted* for these two). Do
   not burn effort re-creating the old feel — migrate to the idiomatic new callback
   shape.
3. `design/spec/M5c-dispatch-chain.md` — **Scope item 6** (L63-72, delivery mechanics)
   + **AC-32** (L267-268). Note also L64: the `native_split`/lifecycle-split wrapper is
   already deleted (verified — do not look for it).
4. `internals/user_input.md` — cross-component input usage, for the runtime picture.

`design/` is **frozen** — read, never edit. Repo-root `CLAUDE.md` auto-loads
`rules.md` + `development.md`: hard limits (line ≤64 chars, fn body ≤14 lines, params
≤4, nesting ≤4), no string-tag dispatch, KISS, tests-first-where-testable,
report-don't-fix, Conventional Commits, **commit locally, NEVER push**.

## The landed surface you migrate ONTO (confirmed in code, post-chunk-4)

`compy.input.show{…}` accepts these **show-time config keys today** (no M7 dependency —
M7 only adds the *live-reconfigure* API for an already-shown widget):

- `prompt` → the widget's label (`userInputController.lua:197-198`, sets
  `model.custom_label`).
- `text` → initial widget content, pre-fills via `set_text`
  (`userInputController.lua:200-201, 263-264`); multi-line accepted.
- `on_text_entered = fn` → **the submit output** (one of the four AC-16 widget
  outputs): fires **once** at Enter with the full assembled text (R1). This is the
  replacement for the old blocking-return / poll-a-reftable result.
- (also available if needed: `validator`, `highlighter`, `on_limit_reached`,
  `multiline`, `before_/after_submit|cancel` route hooks — use only what the example
  actually needs; do not gold-plate.)

There is **no already-migrated template example** — turtle/maze are the first. Model the
call on the spec/design vocabulary above, not on any legacy idiom.

## What each example uses today (surveyed) and the migration

### turtle (`src/examples/turtle/main.lua`) — **tracked in /repo, commits normally**

Current legacy idiom (the **poll-a-reftable** pattern):
- L12 `local r = user_input()` — legacy reftable.
- L51 (inside `love.keyreleased`, key `i`) `r = input_text("TURTLE")` — legacy blocking
  solicitation that fills the reftable.
- L65-66 (inside `love.update`) `if not r:is_empty() then eval(r()) end` — **polls the
  reftable every frame**.

Migrate to the callback shape:
- Remove `user_input()`, the reftable `r`, and the per-frame poll in `love.update`.
- On key `i`, call `compy.input.show{ prompt = "TURTLE", on_text_entered = function(text)
  eval(text) end }`.
- **Crux of the behaviour change (get this right):** `on_text_entered` fires **once per
  submit** — `eval` must run once from the callback, **not** re-run every
  `love.update` tick as the old poll did. This is the visible behaviour change the
  mandate sanctions.
- The natives (`love.keypressed`/`keyreleased`/`update`) **stay** — they auto-provision
  as tier-3 participants (AC-31, already landed). Leave the non-input logic
  (`drawing.lua`, `action.lua`) alone.

### maze (`src/examples/maze/`) — **NESTED CHECKOUT, guardrail 7**

`src/examples/maze/` has its **own `.git`** and is **not tracked by this repo** (from
/repo its contents are shielded — a plain `git status` shows only `?? src/examples/maze/`).
Solicitation call sites (surveyed):
- `controls.lua:21` `input_text("Commands:", string.lines(""))`
- `main.lua:458` `input_text("Commands:", string.lines(""))`
- `main.lua:474` `input_text("Commands:", string.lines(text))` — pre-filled initial text.
- `main.lua:527` `love.mousepressed = SYSTEM_KEYS.menu` — **pointer, LEAVE IT** (AC-28:
  pointer slots are not part of the route disconnect; stays hooked).
- `main.lua:534/546` `love.keypressed`/`keyreleased` natives — **stay** (tier-3, AC-31).

Migrate each `input_text(prompt, initial_lines)` call to `compy.input.show{ prompt =
<prompt>, text = <initial>, on_text_entered = <handler> }`, rewiring maze's
command-consumption from the poll/blocking result to the `on_text_entered` callback.
Trace maze's command flow carefully (multiple call sites; `controls.lua` +
`main.lua`) — each solicitation's result must reach the same command handler it does
today, now via the callback.

**Delivery mechanics (Gate-3 ruling, guardrail 7 — NON-NEGOTIABLE):** edit maze files
**in place** but deliver them as **uncommitted working-tree changes**. **NEVER** run
`git add`/`git commit` inside `src/examples/maze/`, **never** touch its `.git`. (From
/repo you cannot accidentally commit them anyway — the nested repo shields them — but do
not `cd` in and commit either.) The **outcome ledger must list every changed maze file**
so the human carries the patch upstream.

## Tests / verification

The examples are **not** covered by `busted tests` (that suite is the contract suite,
already green at 779 and must **stay** 779/0/0/5 — you are not adding contract rows for
this chunk; AC-31/32/33/36 rows already exist and stay green). AC-32's acceptance is
**hand-playable afterwards**. So verify by:

1. **Run the full contract suite** before and after — it must remain **779/0/0/5** (you
   changed only examples + possibly nothing under `src/` proper; if it moves, something
   is wrong — investigate).
2. **Headless load-without-traceback** of each migrated example (`xvfb-run -a love src`
   and drive to the example, or the project's smoke path) — no load-time error, the
   `compy.input.show{…}` call is well-formed against the landed surface.
3. **Drive the input path as far as headless allows** and **code-review the migrated
   flow** line-by-line against R1 (`on_text_entered` once-per-submit) and the config
   keys above.
4. **Be honest in the ledger** about what still needs **human hand-play** as the final
   AC-32 gate (interactive submit/cancel feel) — do not overclaim "verified playable" if
   you could only smoke-load it. Report-don't-overclaim.

Use the **lua-lsp MCP** (restored this session) for correctness — `references` on any
symbol you touch, `diagnostics` on changed files (`sleep 1` after a `.lua` edit before
calling it, so it re-indexes). Grep as the completeness backstop.

## Scope fence (do NOT)

- Do **not** touch the dispatch chain, `projectInputController`, `controller.lua` route
  code, or any AC-31/33/36 rows — that surface is landed and out of scope.
- Do **not** remove the legacy globals themselves (`input_text`, `user_input`,
  `validated_input`, `write_to_input`, poll-reftable) — they die in **M8** (tixy +
  balloons still use them until then). You migrate the *consumers* turtle/maze **off**
  them; the globals stay.
- Do **not** migrate tixy/balloons (that is M8) or any other example.
- Do **not** commit inside `src/examples/maze/` or touch its `.git` (guardrail 7).
- Do **not** pursue the deferred console/editor migration (named follow-on, out of
  slice).

## Ledger (guardrail 2/3 — `outcomes/M5c-05-example-migration.md`)

Open with **"what will surprise the architect"** (esp.: the exact behaviour change in
each example; anything that needed a judgement call; the honest verification ceiling —
smoke-load vs. true hand-play). Then: **AC-32 checklist**, the **per-remark disposition**
table (AC-34 — any `-- REVIEW:`/`>> REVIEW`/SCOPE remarks you touched), the **list of
changed maze files** (guardrail 7 hand-off), and the before/after **busted counts**
(expect 779/0/0/5 unchanged). Every non-obvious bullet cites a corpus ref; uncitable ⇒ a
judgement call that should have been a stop.

Commit **turtle + the ledger** locally (Conventional Commits, no push). Report back to
me: per-example summary, commit hash(es), the maze changed-file list, and the
before/after busted counts.

## Escalation boundary

The migration is a **mechanical application of the ratified `show{…}` API** — the design
**sanctions** the behaviour change, so it is NOT a design ruling. But if you find a real
seam — e.g. an example genuinely needs a `show{}` capability the landed M5c surface does
**not** provide (a true M7 dependency, not merely "the old feel differs"), or maze's
command flow cannot reach the callback without a route-model change — **STOP and report
it as an escalation** rather than inventing surface or a route ruling. For a small,
reversible ambiguity: most-conservative choice + loud surprise-first flag + continue.
