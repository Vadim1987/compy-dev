# W9 — the one owner sitting: ruling sheet

**Date:** 2026-07-31 · **Session:** 24 · Band 4 of the take-02 plan
(`S24-TF2-take01-triage.md` §8). Everything the plan queued for the owner,
one item per section: what is true today (verified in code), the options, and
a recommendation. Rulings are recorded inline as they are given.

Bands 1–3 are closed and in the tree; nothing here blocks anything already
landed. Items 1, 2, 7, 10 and 11 change behaviour; 3, 4, 5, 6, 8, 9 are
documentation, naming or example content.

---

## 1. Repeat `show{}` on an already-active overlay

**Today.** `UserInputController:show` warns and no-ops unless `force = true`
(`userInputController.lua:299-306`). Decision 3 (warn-don't-swallow) put the
warning there; Decision 15's scope line keeps it a warning rather than a raise,
because a repeat `show` is a *runtime state*, not a contract violation.

**Evidence it bites.** maze calls `show` every tick → a warning per tick
(report 6, "likely on every tick"). turtle re-calls `show{}` from
`love.keyreleased` on every `i` release — including while the overlay is up,
and including the `i` in any word being typed into it.

**Options.**
- (a) Warn **once per activation** — first repeat warns, further repeats until
  the next real `show`/`hide` cycle are silent.
- (b) Silent no-op — `show` becomes "ensure the overlay is up", and repeat
  calls are a legitimate idiom.
- (c) Keep today's warn-every-call.
- (d) Raise.

**Recommendation: (a).** The signal is what Decision 3 wanted and it survives;
what does not survive is the tick-rate spam that makes the log useless. (b)
reads attractive but silently accepts a project that re-shows in a loop, and
(d) contradicts Decision 15's own scope line.

**RULING (owner, 2026-07-31): none of the above — no framework change.** A
repeat `show` is not a contract violation; both cases are small but bad
implementations in the *examples*. maze should not call it every tick unless
there is a documented reason (and then it should pass `force` or hide the
widget first). turtle should hide the widget when it is not needed, and its
`i` interceptor should check widget state, **consuming only when the widget is
not shown**. Executed for turtle (maze is a detached repo, out of scope) —
which surfaced item 12.

---

## 2. How a contract violation reaches the project author

**Today.** Two different surfaces, depending on where the raise happens:

| Raised from | Path | What the user sees |
|---|---|---|
| top-level project code | `run_user_code` → `pcall` → `run_project` prints `'Error: ' .. msg`, sets `project_open` | a console line; the project stays open, nothing else changes |
| a `love.*` handler / hook | `wrap` → `user_error_handler` → `CC:suspend_run(msg)` → `'snapshot'` | the error window, over the project's last frame |

balloons (report 5) hit the first row: a lifecycle callback inside `show{}`
raises per Decision 15, the raise printed one console line, and the user was
left "in a console that gave no signal they were still inside a project" —
which undercuts the ruling's own stated rationale ("explicit failure mode").

**Options.**
- (a) Route a top-level project raise through the same suspend/error-window
  path as a handler raise.
- (b) Keep the console line, but make the state legible (e.g. print which
  project is still open, and how to leave it).
- (c) Leave as is.

**Recommendation: (a).** One failure surface for one class of failure. The
asymmetry is an accident of which `pcall` caught it, not a decision anyone
took, and (b) preserves the accident while adding words to it.

**RULING (owner, 2026-07-31): leave as-is**, and register the asymmetry as
technical debt for stakeholder review, carrying the options and recommendation
above into the ledger entry rather than only this sheet.

---

## 3. Retire "slot" from the vocabulary section

**Today.** `decisions/input.md:20` titles the section "Vocabulary — hook,
callback, handler (and why there is no *slot*)", and `:45-51` is a paragraph
defending the absence of a word nobody uses. Your REMARK: retire it here too,
and drop the defence rather than argue with it.

**Options.** (a) Drop the parenthetical from the heading and delete the
defence paragraph. (b) Keep a one-line historical note. (c) Leave as is.

**Recommendation: (a).** A ratified glossary that argues against a retired
word teaches the word. Nothing in `src/`, `tests/` or the persistent corpus
uses it (checked: only ephemeral `wip/` docs and unrelated senses of the
English word).

**RULING (owner, 2026-07-31): (a)** — drop the heading clause and delete the
defence paragraph.

---

## 4. "Handler" — one meaning, not two

**Today.** The vocabulary section defines **handler** as "the project's
captured `love.*` function … a callback whose mount point is never empty", and
`internals/event_dispatch_layers.md` then spends its closing section mapping a
"naming collision" between that and LÖVE's own use.

**Your REMARK (verified correct).** There is no second meaning: *handler* is
always the LÖVE-runtime sense (`love.handlers[name]` and the `love.<event>`
occupant). The only real trap is that a project which installs
`love.textinput` believes it is installing a handler, while the framework
captures it and **demotes it to a hook** — the encouraged path being to install
it as a hook in the first place.

**Options.**
- (a) Rewrite both places to your framing: one meaning (LÖVE's), plus an
  explicit "captured and demoted to a hook" note and the encouraged path.
- (b) Keep the two-meanings framing.

**Recommendation: (a)** — and it shortens both documents. The
`event_dispatch_layers.md` closing section becomes "what happens to a
project-defined `love.*`", which is the fact a reader actually needs.

**RULING (owner, 2026-07-31): (a), with a stated caveat.** Rewrite to one
meaning — but admit the asymmetry, and record it as debt, **if** a
project-defined `love.<pointer event>` is treated differently; if pointer
functions are also demoted to hooks and dispatched through the same routing
path, there is no debt to record.

**Verified: they are treated differently.** `hook_pointer` (`controller.lua`)
installs a project's pointer functions as the real `love.<event>` handlers
(`love[k] = wrapped_native(...)`, return value discarded), so for pointer they
stay handlers in LÖVE's own sense, while keyboard/text functions are captured
and demoted to `hooks[event]`. The vocabulary rewrite states this rather than
glossing it, and the routing asymmetry itself is already carried by
`technical_debt/input.md`, "Pointer delivery is an unstructured broadcast, not
a chain" and the Standing entry "Future input unification" — cited, not
duplicated.

---

## 5. Doc front-matter and LLM/human provenance

**Today.** Two unrelated conventions, unevenly applied:
- 58 files carry `<!-- authored By LLM; human-approved NOT YET -->`; one says
  `human-approved`; one is truncated mid-marker.
- **One** file (`internals/project_sandbox_env.md`) carries YAML front-matter
  (`description` / `status` / `audience`) — the annotation your REMARK liked.
- The three most load-bearing docs — `decisions/input.md`,
  `technical_debt/input.md`, `doc/input_api.md` — carry **neither**.

**On the question in the REMARK:** that block is plain **YAML front matter**
(the Jekyll/Hugo/Obsidian convention), not an OKF format; there is no
governing standard, only that convention. So the fields are ours to choose.

**Options.**
- (a) One front-matter block per doc, provenance included as fields
  (`authored: llm`, `reviewed: <name|none>`, `status`, `audience`), replacing
  the HTML comment everywhere.
- (b) Keep the HTML comment for provenance, add front-matter only where a
  description helps.
- (c) Leave as is.

**Recommendation: (a)**, applied to the persistent corpus first (the five docs
that survive `wip/77` deletion) and to the rest opportunistically. One place to
look, machine-readable, and it fixes the fact that the documents most likely to
be read by a stakeholder are the ones with no provenance at all.

**RULING (owner, 2026-07-31): (a)** — YAML front-matter carrying provenance
fields, replacing the HTML comment; persistent corpus first.

---

## 6. Wrapper naming sweep in `controller.lua`

**Today** (all in `src/controller/controller.lua`, all pure renames):

| name | what it is |
|---|---|
| `forward_keypressed` / `forward_keyreleased` / `forward_textinput` | hand the event to the widget the console route activated; return whether it went there |
| `userlove` | the project's sandboxed `love` table |
| `wrapped_native` | project handler, error-wrapped, **return discarded** (pointer) |
| `chain_native` | project handler, error-wrapped, **return propagated** (chain) |
| `keyboard_native` | `wrapped_native`'s keyboard twin, built on `chain_native` |

Recorded in `technical_debt/input.md`, "`forward_*` / `userlove` names do not
convey their semantics".

**Options.**
- (a) Rename in one sweep: `forward_*` → `to_widget_*`, `userlove` →
  `project_love`, `wrapped_native` → `wrap_pointer_handler`, `chain_native` →
  `wrap_chain_handler`, `keyboard_native` → `project_chain_handler`.
- (b) Rename `forward_*` and `userlove` only (the two the ledger names).
- (c) Defer past this PR.

**Recommendation: (b).** The ledger entry is the promise made; keeping the
sweep to it is the smallest diff a reviewer has to read, and "native" is at
least defined in a comment at its first use. Whichever is chosen, it is LSP
rename + grep backstop, **complete or not at all** — a half-renamed pair is
worse than either.

**RULING (owner, 2026-07-31): defer the rename to just before the PR**, when
everything else is settled. In the meantime add comments explaining why *these*
names, what the alternatives are, and why `wrap_`/`chain_` are separate rather
than one method — **only if they stay short**. If that needs big prose, one
line saying the names are disputed, so they are not silently re-approved for
the third time.

---

## 7. turtle: migrate to shortcuts/hooks, or leave on the captured-handler path?

**Today.** turtle defines `love.keypressed` / `love.keyreleased`, which the
framework captures and seeds as `hooks[event]`. Pressing `i` shows the overlay
— from `keyreleased`, so it also fires while the overlay is up, and while
typing any word containing `i` (this is item 1's other victim).

**Options.**
- (a) Leave it: turtle is then the example that demonstrates the
  captured-`love.*` path, which is a supported path and worth showing.
- (b) Migrate the `i` trigger to `compy.input.shortcuts.keyreleased['i']` and
  the rest to hooks — turtle becomes an example of the new surface.
- (c) (a) plus a one-line guard so `i` does not re-show while shown.

**Recommendation: (c)** if item 1 is ruled (a) or (c); **(a)** if item 1 is
ruled (b), since a silent no-op makes the guard unnecessary. Migrating (b)
costs the example set its only demonstration of the capture path.

**RULING (owner, 2026-07-31): (a) — leave it on the captured path, and say
in the example why.**

---

## 8. Should the `repl` example evaluate?

**Today (verified, band 1).** It does **not**: `on_text_entered` pipes lines to
`print`, and the overlay is provisioned with `InputEvalText`
(`main.lua:370`) — plain text, no parser. Typing `x = 2 + 3` gives back the
characters. The docs now say so plainly, which is why this is a question about
the example, not a doc fix.

**Options.** (a) Make it evaluate — the project env already exposes `eval`
(`project_env.eval = LANG.eval`), so it is one line in `on_text_entered`.
(b) Keep the echo and rename the example (`echo`). (c) Keep both name and
behaviour.

**Recommendation: (a).** The name promises a read-**eval**-print loop, and your
own reaction on the smoke test ("not sure what to run there") is what an echo
named `repl` produces. It also gives the example set one project that shows
`compy.input` driving evaluation.

**RULING (owner, 2026-07-31): conditional — verified, so: keep the
behaviour and register the UX concern as debt.** The owner's recollection was
that it *does* evaluate (`x=2+3` then `print(x)` printing `5`), and asked
whether that was a misunderstanding of which mode they were in.

**It was — and the framework made the mistake easy.** The pre-feature example
also only reprinted: at `3256aac`, `repl/main.lua` is `r = user_input()` plus
an update loop doing `input_text()` / `print(r())`. Today's version is the
same behaviour on the new API (`InputEvalText`, `print(string.unlines(lines))`).
Evaluating Lua and printing `5` is what the **console** does — and until this
session's two fixes, a project whose overlay had been refused (A1) or was
simply never painted (A4) was visually indistinguishable from the console:
same black input line, no signal. Both are fixed, so the two modes now look
different. Behaviour unchanged; UX concern recorded.

---

## 9. "Decision 15 revised" as a heading

**Today.** One heading still carries it: `## Decision 15 revised —
unrecognised show/configure configuration raises`, with the earlier form kept
below as `### Superseded — the original warn-and-ignore form`. Every other
"revised" has already gone from the ledger's headings.

**Options.** (a) Drop "revised" from the heading; the superseded subsection
below already records that there was an earlier form. (b) Keep it.

**Recommendation: (a).** After the PR lands, nobody cares that a decision
moved mid-development; they care what it says. The history stays one heading
below, which is where it belongs.

**RULING (owner, 2026-07-31): (a)** — drop "revised" from the heading.

---

## 10. The error lock now has a visible band — should it name its exit?

**New from W7.** With the overlay painted on the console path (`e80c644`), a
rejecting validator's error band is visible for the first time in an
input-only project. The lock itself is correct and documented: while
`has_error()` holds, `textinput` is dropped and `keypressed` is swallowed
except Enter / Space / arrows, which clear it. Nothing on screen says so.

**Options.** (a) Append a hint line to the rendered error band ("Enter or
Space to continue"). (b) Clear the error on the next `textinput` instead of
requiring a named key. (c) Leave it — documented is enough.

**Recommendation: (a).** It is the smallest change that answers the actual
complaint ("it freezes"), and it changes no semantics — (b) does, and would
make a rejected line silently editable in a way the lock deliberately prevents.

**RULING (owner, 2026-07-31): conditional — check the pre-feature behaviour
first, reproduce it if feasible, and record the UX bug with options in the
ledger; re-escalate if reproducing it would need a compatibility layer whose
only purpose is to restore bad UX.**

**Checked: there is nothing to reproduce.** At `3256aac` the lock is already
there and is *stricter* — `has_error()` swallows everything except Enter / up /
down (`userInputController.lua`), where today's also accepts left / right /
space. The error band's invisibility is equally pre-existing (same render path,
same unpainted overlay). So the feature neither introduced the lock nor
narrowed its exits; it widened them. No compatibility layer, no
re-escalation — UX concern and options recorded in the ledger.

---

## 11. Two small cleanups (yes / no)

- `src/examples/guess/main.lua` defines `is_natural` **twice**; the second
  shadows the first, so the first is dead code. Delete the dead one.
- The overlay-paint fix (`e80c644`) is the one change in this session that
  alters what is on screen. It wants a **smoke test**, not a ruling — confirm
  the composition looks right (overlay over the console frame, no doubling) or
  say the word and it reverts to three lines.

**RULING (owner, 2026-07-31):** delete guess's dead definition; the owner
smoke-tests the overlay paint before the PR (not reverted).

---

## 12. NEW — `compy.input.is_shown()` (escalated during the sitting)

Ruling 1 asks turtle's `i` interceptor to check widget state. **It cannot.** A
project's `love` is a deep clone of the global one, so `love.state.user_input`
read from inside a project is **always nil** (probed directly). Two
consequences:

- maze's re-arm guard `if love.state.user_input then`
  (`examples/maze/main.lua:497`) is dead code that never fires — which is
  precisely *why* maze calls `show` on every tick (report 6).
- `technical_debt/input.md`, "No public `is_active()`-shaped visibility query"
  understates it: it records that an example reads `love.state` directly, as if
  that worked.

The internal flag already exists (`get_active_flag` → `widget:is_shown()`), so
exposing it is one line.

**RULING (owner, 2026-07-31): add `compy.input.is_shown()`.** Closes the
open-decisions entry and makes maze's intended idiom expressible.
