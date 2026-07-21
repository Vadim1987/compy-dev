# S18 — UIC context-fork: analysis + options (for owner ruling)

Decides the disposition of the open issue in
[`R4-open-issue-uic-mode-leak.md`](R4-open-issue-uic-mode-leak.md), under the owner's sharpened
bar ([`../notes/S18-owner-concern-uic-context-behaviour.md`](../notes/S18-owner-concern-uic-context-behaviour.md)):
**not "is the global read gone?" but "is UIC concept-uniform enough that the editor could later
adopt the API without UIC knowing it's the editor?"** — i.e. does the API *make editor migration
possible* (a feature requirement), without doing that migration now (deferred, Decision 1).

## What the fork actually is (verified in code, `userInputController.lua`)
One condition — `if love.state.app_state == 'editor'` at **:725** — wraps **two independent
behaviour forks**:

- **Axis 1 — editing keymap (PRE-#77).** Editor branch runs `horizontal()` before `vertical()`
  and adds `modify()` (Ctrl+D duplicate-line); normal branch runs `vertical()` before
  `horizontal()`, no `modify()`. Flagged since before this feature by the standing REVIEW at
  **:724** ("UIC should not be aware if application is in editor/non-editor mode — it should be
  editor that configures it accordingly… it's all *combos* editor can set itself").
- **Axis 2 — lifecycle keys (NEW in R4/U3, `f1050d8`).** `_submit_default` (:752) / `_cancel_default`
  (:754) run **only in the `else` branch**, to keep the editor's Escape from wiping a just-loaded
  selection. This scoping rule ("submit/cancel only outside editor mode") is **not in the ratified
  delta-design/spec** — delta-spec §3 specified uniform widget submit/cancel with *no* app_state
  branch. It is an implementation addition.

**Consequence that reshapes the options:** lifting only Axis 2 out (the open-issue doc's
"option B" as written) does **NOT remove the global read** — Axis 1 keeps `app_state` at :725.
To remove the symptom you must retire the whole `app_state` condition, which touches the
pre-existing Axis-1 fork too.

## The decisive precedent — UIC already has the pattern the owner wants
Every *other* behaviour fork in UIC is already driven by **owner-injected per-instance config,
with zero global reads**:
- `UserInputController(model, result, disable_selection)` — constructor takes a **behaviour-named
  flag**; `disable_selection` forks behaviour at `:715/:838/:856/:870/:884`.
- `:always_shown()` — chained construction-time config.
- The editor constructs exactly this way: `UserInputController(M.input, nil, true):always_shown()`
  (`editorController.lua:12,16`) — it **already** tells its instance "selection off, always shown."
- Console: `UserInputController(M.input):always_shown()` (`consoleController.lua:44`).

`disable_selection` is, in practice, "am I the editor?" expressed **as a behaviour**, injected by
the owner — no global reach. The `app_state == 'editor'` read is the **sole** global-context fork
in UIC: the odd one out, inconsistent with UIC's own established pattern. And `app_state` itself is
a legitimate app-mode state machine (set in `main.lua` + console transitions) — the layering fault
is not the global's existence, it's a *reusable input widget* branching on app-mode instead of on
its own injected config.

## Why this matters for the owner's bar (migration possibility)
A future editor migration onto the new API needs a **seam** to inject its own keymap + lifecycle
handling. If suppression stays a global read, migration must *rip it out* — a dead-end. If
suppression is owner-injected instance config (like `disable_selection`), migration *extends the
seam* (editor already configures its instance; it registers more, per REVIEW-724's "it's all
combos" endgame). So the test "does the API make migration possible?" is passed precisely by
converting the global read into the instance-config pattern UIC already uses everywhere else.

## Options

### A — Full uniform, migrate editor now
UIC lifecycle + keymap become uniform; editor's controller consumes its own Enter/Escape across
normal/reorg/search modes and its own editing-key order so its widget never forks. Reaches the
clean combos end-state. **Cost:** does the deferred editor-migration work *now* — large editor
surface, real regression risk, and Decision 1 explicitly parked it. **Over-scoped for R.**

### B-narrow — instance flag for submit/cancel only
Gate only Axis 2 on a construction flag (editor opts out). **Does not remove the `app_state` read**
(Axis 1 keeps it at :725). Removes half the new debt, leaves the symptom. Weakest — fails the
owner's "symptom is a symptom, but don't leave the fork" framing while also not even clearing the
global read.

### B-proper (RECOMMENDED) — retire the `app_state` read; whole fork becomes owner-injected config
Replace `if love.state.app_state == 'editor'` at :725 with an instance flag set at construction,
mirroring `disable_selection` — editor's two instances already pass constructor config, they gain
one honest, behaviour-named flag (not `editor_mode`; name it for what differs, e.g. the editing
profile / "manages its own lifecycle keys"). Covers **both** axes: global read **gone**; the fork
remains but is now the *same kind* as `disable_selection` — per-instance, injected, testable, no
global reach. Zero editor/console/overlay behaviour change (suite stays green). Migration path
clear: a future editor replaces the flag with registered combos (REVIEW-724) without ever having
introduced a global dead-end. **Adopts the pre-existing Axis-1 REVIEW-724 item into R's scope** —
that's the one judgment cost, but the fix is small (one condition + thread one constructor arg)
and it's the only option that actually clears the symptom while proving migration possibility.

### C — Leave + document as deferred tech debt
Keep the `app_state` read, record it adjacent to REVIEW-724. No code change. The owner has already
signalled discomfort with this: it risks rubber-stamping the fork into the future. Only defensible
if we conclude the read does **not** block migration and honestly bound it — but B-proper removes
it for roughly the cost of writing that justification.

### D — Move the fork out of UIC entirely (the owner's "wrong place" angle)
Neither UIC nor a global decides; the *caller* configures the widget. For the project overlay this
already exists (delta-design D6: shortcuts shadow Enter/Escape via `dispatch`). For the editor,
`editorController` would own the decision (it already intercepts keys before passthrough). This is
the principled end-state and largely **converges with B-proper** (B-proper *is* "caller configures
the widget, at construction") — the difference is whether the lifecycle default lives in UIC gated
by a flag (B-proper) or is injected by the editor as combos (D/A). D-as-combos-now = A's cost;
D-as-construction-config-now = B-proper. So D is best read as the *direction* B-proper points at,
not a separate immediate option.

### Behaviour-preservation of B-proper (verified in code, S18)
Only the editor ever runs under `app_state=='editor'` (entered `consoleController.lua:1166`,
restored `:1188`). So the flag maps cleanly onto today's split: **editor's two instances →
defer=true** (reproduces today's editor branch: no `_submit_default`/`_cancel_default`); **console +
project overlay → defer=false** (today's else branch). The editor relies on `_cancel_default`
*not* firing (else `model:cancel()` wipes the `load_selection()` block) — B-proper's flag preserves
exactly that. Suite stays green; no widget changes observable behaviour. (This corrects a backwards
interpretation in the S18 evidence sweep's E.3 — see the orchestrator correction appended to
[`../outcomes/S18-revalidation-evidence.md`](../outcomes/S18-revalidation-evidence.md).)

### E — Intercept Enter/Escape in the editor; DELETE UIC's lifecycle branch (owner re:4/5, S18)
The owner's angle: if the editor intercepts Enter/Escape *before* UIC:keypressed is reached, UIC
never fires its flows in editor mode — no branch, no flag, no global read; UIC runs submit/cancel
uniformly (delta-spec §3 as originally written) and the widget stays unaware that events can be
intercepted upstream (re:3). Per-mode interception status **today** (verified S18):

| Editor mode | Escape | Enter | Reaches UIC main input? |
|---|---|---|---|
| **Reorg** (`_reorg_mode_keys` :440) | handled :441 `_reorg(false)` | handled :444 `_reorg(true)` | **No** — no `input:keypressed` in this path at all. Fully intercepted. |
| **Search** (`_search_mode_keys` :485) | handled :486-490, `return` | falls to :493 `self.search:keypressed(k)` (the SEPARATE search widget) | Escape: no. Enter: reaches search widget, whose editor-branch no-ops lifecycle → harmless. |
| **Normal** (`_normal_mode_keys` :507) | `load()` :716 — **no `block_input()`** | `submit()` :610 (plain + Ctrl) — **no `block_input()`** | **YES** — falls through at :803-804 `input:keypressed(k)`. The `app_state` branch is the SOLE thing preventing the flows here. |

So the problem does **not** dissolve today — normal-mode `submit()`/`load()` don't block, so plain
Enter, Ctrl+Enter and Escape fall through, and only the `app_state` check stops the flows. But it
**would** dissolve if normal-mode `submit()`/`load()` called `block_input()` on the Enter/Escape
variants they handle. Then UIC's `app_state` **lifecycle** branch (:744-749) becomes dead code →
delete it → UIC runs submit/cancel uniformly.

**Nuance (must be preserved):** Shift+Enter on a *non-empty* input is deliberately NOT handled by
the editor (`newline()` :518 only fires on empty) — it falls through to UIC's `newline()` →
`line_feed` (multiline). This must keep falling through. Safe, because UIC's submit is guarded
`Key.is_enter(k) and not Key.shift()` — Shift+Enter never triggers submit. So the editor blocks
only plain Enter + Ctrl+Enter + plain/Shift Escape; everything else (arrows, text, backspace,
selection, Shift+Enter-line-feed) keeps falling through to UIC unchanged.

**What E buys over B-proper:** true concept-unification — UIC has *no* lifecycle fork of any kind
(not a global read, not a flag); the context owner (editor) decides interception, exactly the
REVIEW-724 endgame and the re:3 principle. **Cost:** touches editor `submit()`/`load()` (add
`block_input()` calls) and needs tests-first coverage for the now-suppressed fall-through side
effects (UIC's `selection()` release + `update_view` no longer run on those keys — verify no
editor regression; likely nil since submit does `input:clear()`+`load_selection` and load does
`set_text`+`jump_home`, but assert it). Larger than the flag, still far short of Decision-1's full
editor-API migration (moves 3 key-handlers, not the whole input surface).

For the residual **axis-1** (editing-order swap + `modify()`/Ctrl+D): per re:2, the order swap is
coincidental (unify freely); `modify()` (Ctrl+D) is editor-only and currently editor relies on
falling through to UIC's editor-branch for it. To fully empty the branch, move Ctrl+D to an editor
handler (block_input) too — then UIC's `app_state` branch is deleted **entirely**, UIC fully
uniform. That is the complete end-state; it can be one unit with E or a follow-on.

## Recommendation (revised after owner re:2/3/4/5, S18)
**Option E** — intercept Enter/Escape in the editor, delete UIC's lifecycle branch, run UIC
submit/cancel uniformly. This supersedes the earlier B-proper recommendation: B-proper removes the
global read but keeps a *fork* inside UIC (a flag); E removes the fork itself, which is the owner's
actual bar ("the real smell is context-dependent behaviour inside UIC," not the state read). E also
directly satisfies re:3 (widget unaware of interception — the route/editor owns that, not the
widget) and re:2 (the branch shrinks toward nothing). B-proper drops to fallback: take it only if
the editor-side interception proves to carry hidden regressions the tests can't cheaply cover.

**Rename (re:3), do it as part of E:** `_submit_default`/`_cancel_default` → drop the "default" —
it encodes the widget's awareness of an override layer, which is the leak. Recommend
**`submit_flow`/`cancel_flow`** ("flow" names the callback sequence before→validate→deliver→after);
`submit`/`cancel` risk colliding with existing verbs (`model:cancel()` exists; check for a UIC
`submit`/`cancel` before choosing). 2 call sites + defs + doc-comments; grep-backed (LSP unreliable).

## R-close question
If the owner takes **E**: execute tests-first — (1) editor `submit()`/`load()` block_input on their
Enter/Escape; (2) delete UIC's `app_state` lifecycle branch, uniform submit/cancel + rename; (3)
optionally move Ctrl+D `modify` to the editor to empty the branch entirely (axis-1) — then R closes
with UIC genuinely concept-uniform, nothing rubber-stamped. If **B-proper** (fallback): one flag
unit, R closes with the fork honestly owner-injected. If **C**: R should NOT close without an
evidence-backed argument the fork doesn't block migration. If **A**: out of R's scope.

**Also on the R-close checklist (independent of the fork):** the delta-design/spec are still status
"PROPOSED, pending R3 confirmation," and `decisions/input.md` is deliberately un-resynced pending
that ratification (S18 evidence B). Folding the ratified addendum into `decisions/input.md` is a
real outstanding step — decide with the owner whether it lands in this session or is tracked.
