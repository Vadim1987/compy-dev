# S24 — TF2 human take 01: evaluation, triage, plan

Source: `validation/reviews/TF2-human-take01.md` (commit `786e8e4`) plus the
owner's direct interventions in the same commit and the comment-policy move in
`e9a7ccd`. The take is explicitly **incomplete** ("there could be more"), so
everything below is written to be resumable per take.

Status of this document: triage + plan. §6 is **superseded by §8** (owner
direction, 2026-07-31). Only §8's W0 has been executed.

## 0. Tree state and the one thing that is broken right now

- The two commits arrived by `push` into this checked-out repo, so HEAD moved
  while index/worktree stayed at `26127bf`. The owner has since resynced; tree
  now equals HEAD. **No content was lost** (the stale worktree was byte-identical
  to `26127bf`).
- **The suite was RED: 859 / 2 / 0 / 3** — the owner's two new assertions in
  `input_cursor_text_spec.lua`. **Resolved in `5356355`** (§8 W0); back to
  861 / 0 / 0 / 3.

**Evaluation (verified in code, not inferred).** The added probes are right in
intent — `get_cursor` returning what was set proves nothing about where the caret
actually sits — but their expected values are off by one against the framework's
caret convention:

- `UserInputModel:backspace()` (`userInputModel.lua:287`) splices
  `usub(line, 1, cc - 2) .. usub(line, cc)`: it deletes the character **before**
  the caret. `col` is a caret position between characters, valid `1..len+1`.
- The neighbouring passing row proves the same convention independently:
  `set_cursor(1, 999)` on `'hello'` clamps to **6**, i.e. `len + 1`.
- So `set_cursor(1, 3)` on `'lemon'` + backspace ⇒ `'lmon'` (not `'leon'`), and
  `'world'` ⇒ `'wrld'` (not `'wold'`). The framework is behaving correctly.

**But the mistake is evidence of a real gap:** `doc/input_api.md` documents
`cursor` as "Initial `{line, col}`" and `set_cursor(line, col)` as "moves" and
**never states that `col` is a caret position in `1..len+1`**. A project author
has to reverse-engineer it exactly the way this test did.

Proposed: keep the probes, correct the expectations, and state the convention in
`doc/input_api.md` (+ the mechanism line in `internals/user_input.md`). An
alternative probe that reads better than backspace is insertion —
`set_cursor(1,3)` then typing `X` on `'lemon'` ⇒ `'leXmon'` — because it shows
the caret's side unambiguously.

## 1. How the take splits

| Kind | Items | Nature |
| --- | --- | --- |
| A. Live-run defects in examples | 9 reports | feature evidence — the only release-blocking class |
| B. Test-suite actualization | ~12 files + one global rule | mechanical + some judgment (TF3) |
| C. Persistent-doc REMARKs | 9 blocks now sitting in tracked docs | half factual, half owner-ruling |
| D. Composition / process | slice split, commit carving, naming | Phase G + one ruling |

Nothing in the take lands in the **decisions corpus** as a new decision yet;
two items *revise* existing ones (Decision 15 strictness surfacing, Decision 6
consequence for examples). Two land in the **debt ledger** (wrapper naming —
already there; error-lock discoverability — new).

## 2. Class A — the example reports, clustered

Reports 1–9 are not nine independent bugs. They resolve into three clusters plus
three singles. Verdicts below are marked **verified** (proven in code here),
**hypothesis** (needs a live run), or **by design**.

### A1 — "no overlay when a project starts after Ctrl+Q from another project"
tixy (3), turtle (8), valid (9, "runs inconsistently — first project after boot"),
and plausibly the black-vs-blue input bar in (9) — a black bar means the console
input, i.e. the project overlay was never activated.

**Hypothesis, highest priority.** This is the one report class that looks like a
genuine feature regression rather than a migration gap. Note the nuance: the
rehomed teardown row (`input_route_lifecycle_spec.lua`,
"re-seeds the default callbacks for the next project") already drives
activate → `stop_project_run` → activate → `show` and **passes**, so the fault is
not in the route/callback re-seed. That points at the layer above — the
`run_project` / `love.state.user_input` publication path after a Ctrl+Q exit —
which the fixture does not exercise. Test-first target once reproduced.

### A2 — "input is not cleared after Enter"
turtle (8), maze (6.1).

**Verified, by design, examples not migrated.** Decision 6 removed the auto-clear;
continuity is now the default and a project opts into clearing from its own
`after_submit`. `src/examples/turtle/main.lua` sets **no** `after_submit` and no
`clear()` — while `guess`, `repl`, `valid` and `tixy` all carry the migrated
idiom. So turtle is simply un-migrated, and maze (detached) almost certainly the
same. Fix = migrate the example, not the framework.

### A3 — strictness and how violations reach the author
balloons (5, `'after_submit' is not assignable` at load, no stacktrace window),
maze (6, `show` warnings "likely on every tick").

**Verified as behaviour, needs one ruling on the surface.** Both are the
strict-contract work from session23:

- balloons passes a lifecycle callback inside `show{}` → Decision 15 revised
  (in-flight) now **raises**. `doc/input_api.md` documents exactly this case as
  "Wrong: raises". The example is un-migrated. What the report adds is that the
  raise did **not** surface as the expected snapshot/stacktrace window and left
  the user in a console that gave no signal they were still inside a project —
  which undercuts the ruling's own rationale ("explicit failure mode").
- maze calls `show` on an already-active overlay every tick → each call warns and
  no-ops (Decision 15's deliberate scope line: runtime states warn, contract
  violations raise). Correct per the ruling, unusable in practice at tick rate.

Ruling needed: (i) repeat-`show` policy — warn once per session / silent no-op /
raise; (ii) whether a project-facing contract violation must surface as the
framework's error window rather than a console line.

### A4 — "it freezes" (guess 1, valid 9)
**Hypothesis with a strong code-level candidate.** A rejecting validator puts the
widget into the error state, and while `has_error()` holds, `textinput` is
dropped (`userInputController.lua:715-717`) and `keypressed` is swallowed except
Enter / Space / arrows, which clear it (`:526-534`). That is documented, tested
("a rejecting validator locks input without delivering") — and **indistinguishable
from a freeze** if the error is not visible. `UserInputView:render_error` exists
(`view/input/userInputView.lua:232`), so the live question is whether it is
actually drawn over a project's own screen. guess (numeric line validator, "froze
after entering a symbol") and valid ("entering '1' stops processing any input,
no visible error reporting") fit this exactly.
→ New debt-ledger entry candidate: *error lock has no discoverable exit*.

### A5 — singles
- tixy (3): "the explanation text top-right disappears on Enter" — project redraw
  vs overlay interaction; investigate after A1.
- keyboard (7): "does it bypass our routes and talk to love directly?" —
  answerable statically from the example source; cheap, do it in the A-pass.
- sapper (4): "can we suppress the unused input widget in pen-and-paper mode?" —
  design question, not a defect → C/D ruling.
- UX asks across guess/repl/valid ("no prompt", "I don't see what I typed", "no
  signal that I left the console") — example quality + a possible API demo; C/D.

**Scope question for the owner:** balloons, maze and keyboard are detached repos
(untracked nested trees, sanctioned by guardrail 3). Their regressions are
unconfirmed by the owner's own note. Are they in scope for this PR at all, or do
they get a follow-up issue?

## 3. Class B — test-suite actualization (this is TF3)

The take's global rule: **every test reads for a cold reader** — no "this
feature", "feature-new", "pre-baseline", "#77", no milestone tags, no commit
hashes, no "Decision N *revised*", no TF1 provenance. Version boundary is
`1.0.0-rc20260712`, feature name is "the Compy input API".

| File | Items | Nature |
| --- | --- | --- |
| *(all)* | availability headers → "input API introduced in `<version>`" | mechanical |
| `tests/editor/editor_spec_fwd.lua` | delete everywhere — an unintended copy from unrelated work. **It is tracked** (`git ls-files` confirms), so it is currently in the PR diff; `agents/validation.md` guardrail 3 mislabels it as untracked scratch and must be corrected | mechanical + guardrail fix |
| `cursor_spec`, `history_spec` | drop the "this feature" comment, tests intact | mechanical |
| `highlight_regression_spec` | drop the commit hash `1a2a9a3`; drop the wrong "highlight is memoized" message (it asserts non-nilness) | mechanical |
| `input_cursor_text_spec` | de-"feature-new" the header; name Decision 7 in 2–3 words; de-duplicate the opening comment; **plus the two failing expectations from §0** | mechanical + §0 |
| `input_events_spec` | owner rates it "very good"; add the missing **selectivity** coverage: a shortcut fires/consumes only for its own key, while hook and widget see every key. Likely 2–3 rows across channels | judgment (new tests) |
| `input_lifecycle_uniform_spec` | owner deferred review pending the reframe — **the reframe has since landed** (`88fa83f`); re-submit for take 02 | done, awaiting review |
| `input_nfr_forward_spec` | reframe (no "planned"/"forward"/"non-final"/"pre-baseline"/"#77"); **verified**: its "pending until implemented" group holds a row that is live and passing, and a trailing comment block with no test attached | mechanical |
| `input_reconfigure_spec` | drop `#m7`, `#m8` | mechanical |
| `input_shortcuts_click_spec` | reframe the last row — "legacy solicitation is REMOVED" | mechanical |
| `input_widget_lifecycle_spec` | mark "console receives input while the widget is hidden" as **disputable**, and cite the persistent-doc home of that concern if one exists (else create one) | judgment |
| `input_widgets_callbacks_spec` | drop "revised"/"no-longer" dev-time jargon; explain why `love.state.user_input` is read directly and consider factoring it into a fixture `is_widget_visible()`; clarify the prose preceding the custom-validator row; **correct the Shift+Return framing** (the claim "never intercepted" is wrong and is not what the row tests — it tests what the widget does *if* the event reaches it) and consider a paired interceptability row | judgment |

Delegation: the mechanical column is one Sonnet batch under a written style
contract; the four judgment rows stay in-session.

## 4. Class C — the nine REMARK blocks in tracked docs

They currently ship. Each must end as either a doc change or a recorded ruling.

**Factual — answerable now, no ruling needed:**
- `project_sandbox_env.md` "did we drop `before_exit`?" — **no, it exists**:
  `consoleController.lua:697-720` (default + assignment guard), fired at `:1193`,
  reset at `:1200`, and covered by `input_route_lifecycle_spec`. Document it
  properly. (Side note for the ruling below: the implementation variable is
  literally `before_exit_slot`.)
- `examples/repl.md` + `examples/index.md`: "echoes" → **evaluates**.
- `examples/index.md`: "pen-and-paper" is wrong for guess/repl — they draw
  nothing; say "terminal only".
- `project_sandbox_env.md` + others: drop `#77`, cite the version.
- `event_dispatch_layers.md`: the "D6" reference is ephemeral and the
  `decisions/input.md` citation lacks its full path.
- `project_sandbox_env.md`: the clone/leaf-sharing paragraph needs rewording — the
  owner's objection ("aren't those captured and wrapped by the controller?") is
  about *project-defined* `love.*`, which is a different thing from the shared C
  functions the paragraph is describing; both facts are true and the prose
  conflates them.

**Ruling needed:**
- Retire the word **slot** from `decisions/input.md` and delete the paragraph
  defending its non-use (owner's own framing: "no need to defend against not
  using it"). Sweep: the word survives only in that prose and in
  `before_exit_slot` in the implementation.
- The **handler/hook "self-induced confusion"** rewrite: the owner's position is
  that "handler" has exactly one meaning (LÖVE runtime), and the only real
  confusion is that a project defining `love.keypressed` gets it captured and
  demoted into a *hook*. That is a vocabulary correction to `decisions/input.md`
  and `event_dispatch_layers.md`, and it partially contradicts the current text.
- `project_sandbox_env.md` front-matter: is the `description/status/audience`
  block the intended standard, and how do "LLM-authored / human-approved" markers
  fit it? (Applies repo-wide, not just here.)
- turtle's three remarks ("why not a combo for `i`", "why `love.keyboard.isDown`
  instead of a combo", "why `love.keyreleased` instead of
  `compy.input.hooks.keyreleased`") are really **example-migration** questions —
  they belong with A2, and their answer is likely "yes, migrate", which then
  doubles as the demo the API deserves.

## 5. Class D — composition and naming

- **Slice 1a / 1b** — split the docs patch into rubber-stamping (the
  "LLM generated" line only) and meaningful changes, reproducing commit `6c766`
  as `1a`. The owner already did this by hand; the durable step is writing the
  recipe into `pr-assembly-guide.md` §1 so Phase-G regeneration reproduces it.
  Same for "always do it this way" as a standing rule.
- **Carve the highlight-regression protection + its test into its own commit** —
  same place, same mechanism.
- **Naming**: `forward_keypressed`, `chain_native` / `wrap_native` /
  `keyboard_native` are opaque to a cold reader. The debt ledger already carries
  this ("Project-handler wrapping: dedup the guard, drop the misleading
  `keyboard_` name") as deferred; the owner is now asking for it. Needs a naming
  ruling, then an LSP rename with a grep backstop, complete or not at all.

## 6. Proposed plan — SUPERSEDED by §8

Kept for the record; the owner's direction of 2026-07-31 (§8) replaces the
ordering and the intervention model. The package contents below still hold.


Ordering rationale: the suite must be green before anything else is judged
against it; live defects can change the API and must not be discovered *after* a
prose sweep re-touches the same files; rulings are batched into one sitting;
slice regeneration stays last.

| # | Package | Gate / owner input | Model |
| --- | --- | --- | --- |
| **P0** | Correct the two cursor expectations, keep the probes; document the caret convention (`col` ∈ `1..len+1`, backspace deletes before the caret) | none — needs only the §0 verdict confirmed | in-session |
| **P1** | Live-defect pass: reproduce A1, A4, A5 under a driven run; classify each as regression / migration / by-design; write `validation/notes/` evidence per report | **owner: who drives the app?** I cannot see the screen; I can script `xvfb-run` probes with log assertions, but a human eye is faster for A1/A4 | in-session + Sonnet for scripted probes |
| **P2** | Ruling sitting (small, C/D-style, one at a time): repeat-`show` policy · violation surfacing (error window vs console line) · detached-example scope · "slot" retirement · handler/hook vocabulary · doc front-matter standard · wrapper naming | **owner-gated, all of it** | in-session |
| **P3** | Example migration + fixes: turtle `after_submit`, turtle's three remarks, balloons/maze if in scope, plus whatever P1 proves | after P1 + P2 | Sonnet under a written contract |
| **P4** | TF3 test actualization: mechanical batch (style contract) then the four judgment rows; delete `editor_spec_fwd.lua` and fix guardrail 3 | after P0; independent of P1 | Sonnet batch + in-session judgment |
| **P5** | Doc REMARK resolution: factual set immediately, ruling set after P2 | P2 for the second half | Sonnet + in-session |
| **P6** | Composition: write the 1a/1b and highlight-carve recipes into `pr-assembly-guide.md`; naming sweep per P2's ruling | after P2 | Sonnet, LSP + grep backstop |
| **P7** | Phase G regeneration — unchanged, still last | after everything settles | — |

Against the standing plan (`validation/plan.md`): **P4 is TF3** as written; P2/P5
are the C/D principle-and-ruling machinery arriving early because TF2 surfaced
them; P1 is new — a live-defect pass the plan never had, and I propose it **gates
the owner's DI+TF+R acceptance**, since that gate should not be signed while
shipped examples are broken. P6/P7 are Phase G.

## 7. Questions blocking the plan

1. **Who drives the live runs** for P1 — you, or do I build a scripted harness?
2. **Detached examples** (balloons, maze, keyboard): in scope for this PR, or
   follow-up issue?
3. **The §0 verdict** — correct the test expectations to caret semantics (my
   recommendation), or is a change to `set_cursor` semantics on the table?
4. Anything in take 02 that should re-order P1–P6 before I start P0.

## 8. Revised plan (owner direction, 2026-07-31) — certainty first, one sitting

The owner's three instructions reshape §6:

1. **P1 becomes headless bug-hunting, not a driven run.** No `xvfb`. I form the
   hypothesis, express it as a busted test (mocking/intercepting as
   troubleshooting requires), localize the fault, and prepare the fix. The
   owner's manual smoke test comes later and confirms — it does not gate the
   investigation.
2. **`keyboard`, `maze`, `balloons` are OUT of bug-fixing scope** — they were not
   smoke-tested properly, so their reports are unconfirmed evidence. In-scope
   examples: `guess`, `repl`, `tixy`, `turtle`, `valid`, `sapper` (tracked).
3. **Minimal owner intervention, no destabilization.** Low-risk, high-certainty
   work goes first; everything needing a ruling is queued into **one** sitting.

### Ordering principle

Each band is strictly less certain and more destabilizing than the one before
it. A band never depends on a later band, so take 02 can land at any boundary
without unwinding work.

| Band | Package | Risk | Owner input |
| --- | --- | --- | --- |
| **1. Settled** | **W0 ✅ DONE** — caret probes corrected + convention documented (`5356355`). Suite back to **861 / 0 / 0 / 3** | none | answered (Q3) |
| | **W1** — prose actualization, mechanical half of TF3: availability headers → "input API introduced in `1.0.0-rc20260712`"; drop `#77`, `feature-new`, `pre-baseline`, `#m5c`/`#m7`/`#m8`, TF1 provenance, commit hash `1a2a9a3`, "Decision N *revised*"; fix the wrong "highlight is memoized" message; de-duplicate the cursor-spec header; name Decision 7 in passing; reframe `shortcuts_click`'s last row; `nfr_forward` reframe + un-name its "pending until implemented" group (its row is live) + drop the orphan comment block | none — comments and descriptions only, test bodies untouched, count must not move | none |
| | **W2** — delete `tests/editor/editor_spec_fwd.lua` (tracked, therefore in the PR diff) and correct guardrail 3 in `agents/validation.md`, which calls it untracked scratch. Count drops by that file's rows; arithmetic stated in the message | low, isolated | none |
| | **W3** — composition recipes into `pr-assembly-guide.md`: the 1a rubber-stamping / 1b meaningful split (reproducing `6c766`) as a standing rule, and the highlight-regression carve-out | none — a doc | none |
| | **W4** — doc REMARKs, factual half: `before_exit` exists → document it; "echoes" → **evaluates**; drop the "pen-and-paper" mislabel for terminal-only examples; `#77` → version; fix the ephemeral `D6` reference and the path-less `decisions/input.md` citations; reword the clone/handler paragraph that conflates shared C functions with project-defined `love.*` | low — prose in persistent docs | none |
| **2. Additive** | **W5** — coverage the take asked for, as new rows only: shortcut **selectivity** (fires/consumes only for its own key; hook and widget still see every key) across channels, and the paired Shift+Return **interceptability** row that the corrected framing implies | low — additions cannot destabilize existing rows; a red here is a finding | none |
| | **W6** — judgment prose: mark "console receives input while the widget is hidden" as **disputable** with a persistent-doc home (creating the ledger entry if none exists); correct the Shift+Return framing; factor the direct `love.state.user_input` read into a fixture `is_widget_visible()` — its own commit, since the fixture is shared by every input spec | low/medium — fixture change touches all input specs | none |
| **3. Investigative** | **W7** — headless defect hunt, test-first, one cluster at a time. Deliverable per report: an evidence note under `validation/notes/`, a characterization test, and — where it is a regression — a localized fix as its own commit. Order by expected yield: **A1** (second project after a Ctrl+Q exit gets no overlay; the seam is above the route layer, since activate→stop→activate already passes — drive `run_project`/`stop_project_run` and assert `love.state.user_input`), **A4** (the error lock: prove the exit path and whether an error is observable at all while a project owns the screen), **A5-tixy** (top-right text vanishing on submit), **guess** (reject-path freeze under its real validator). Out of scope: keyboard, maze, balloons | medium — this is where real bugs live; every fix lands test-first with the suite green | none until a fix needs a ruling |
| | **W8** — in-scope example migration: turtle's missing `after_submit` clear (A2, verified), plus anything W7 proves | low | none |
| **4. Ruling** | **W9** — ONE sitting, everything queued with evidence and a recommendation, one item at a time: repeat-`show` policy · how a contract violation surfaces (error window vs console line) · retire "slot" + delete its defence paragraph · the handler/hook vocabulary rewrite · doc front-matter and LLM/human provenance standard · wrapper naming (`forward_keypressed`, `chain_native`/`wrap_native`/`keyboard_native`) · turtle's combo/hook migration (changes what the example demonstrates) · any W7 finding that needs a call | — | **the only intervention this plan asks for** |
| **5. Post-ruling** | **W10** — execute W9: vocabulary and doc rewrites, the naming sweep (LSP rename + grep backstop, complete or not at all), strictness changes | medium | none |
| | **W11** — Phase G regeneration, unchanged, still last | — | owner accepts the PR |

### Invariants across all bands

- Suite green and stated at every commit; one concern per commit.
- No production behaviour changes outside W7/W10, and none without a breaking
  test first.
- Take 02 lands cleanly at any band boundary; W1–W6 are pure prep and cannot be
  invalidated by new findings, only extended.
- Model economy: W1, W4, W8 and the mechanical part of W10 are Sonnet batches
  under a written contract; W5–W7 and W9 stay in-session.
