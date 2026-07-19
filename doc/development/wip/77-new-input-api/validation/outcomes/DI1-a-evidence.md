# DI1-a — evidence dossier: doc A §1–§5 fidelity + corpus-home audit

Worker: Sonnet evidence tier. Scope: `doc/development/wip/77-new-input-api/notes/input-contracts.md`
§1–§5 only (lines 1–524). Verified against `src/**` (grep + read; LSP tool was unavailable in this
session — see Uncertainties) — never against `tests/**`, per the circularity guard. Corpus-home
checks against `doc/input_api.md`, `doc/development/internals/user_input.md`,
`doc/development/decisions/input.md`, `doc/development/technical_debt/input.md`,
`doc/development/tests.md`.

Anchor facts (reused, not recontested): `get_user_input` (`controller.lua:21-24`) survives as the
console route's own intra-route widget forward; `ProjectInputController` (PIC) is real
(`Controller.project_input = ProjectInputController()`, `controller.lua:1192`) and occupies the
keyboard/text slots via `occupy_keyboard` (`controller.lua:233-248`) with no overlay gate on the
project route any more.

---

## §1 — Premise + how to read every entry

**Claim(s):** The input layer had no up-front design doc, so pre-#77 code was the spec; #77
rewrites routing (overlay-gate removal, new `ProjectInputController`, slot ownership/restoration);
the doc records outcome-vs-mechanism and stability/provenance tags to survive that rewrite.

**Code check:** This section is a reading-discipline preamble, not a falsifiable code claim in
itself. Its factual premise ("#77 rewrites... overlay-gate removal, a new
`ProjectInputController`, slot ownership/restoration") is corroborated by the shipped code: the
gate is gone from the project route (`occupy_keyboard`, `controller.lua:233-248`, installs
`love.keypressed/textinput/keyreleased` as `pic:...` wrappers, no `get_user_input`/gate check in
that path), `ProjectInputController` is a real, fully-implemented four-tier-chain class
(`projectInputController.lua:125-274`), and slot restoration is explicit
(`release_keyboard_route`, `controller.lua:798-803`; `set_default_handlers`,
`controller.lua:807-859`).

**Axis 1 (fidelity):** still-true. The premise (why the doc exists, the OUTCOME/MECHANISM
discipline, the stability/provenance tag vocabulary) is a documentation-methodology statement, not
a code claim, and holds regardless of what shipped. Its one factual aside (what #77 changed) is
independently confirmed true by the code above — and has, per anchor facts, now **landed**
(present tense, not future) — so read it as accurate-but-now-describing-the-past rather than
false.

**Axis 2 (corpus home):** partial. The tag/provenance *methodology* (PRESERVE / CHARACTERIZE-
PROVISIONAL / stable-now / forward) is unique-no-home — no persistent corpus doc restates this
editorial apparatus, nor should it (it is process scaffolding for this doc, not a system fact).
The factual aside about what #77 changed is already-covered: `decisions/input.md` Decision 1
("routing is route-centric, not widget-centric") and the "Where the shipped system differs from
the design intent" section; `internals/user_input.md` "Keyboard Handling > Dispatch chain".

**Notes for consolidation:** §1 is meta-doc, not a testable contract row; treat it as scaffolding
context for §2–§5 rather than a row needing its own disposition in the final table, if the
orchestrator wants a leaner ledger.

---

## §2 — Keypressed vs. textinput — two channels, one compy convention

**Claim(s) (outcome-shaped, no mechanism split):** LÖVE fires `keypressed` for every physical key
and `textinput` only for character-producing keys; compy's own "control channel vs. character
channel" split is compy's convention, not a LÖVE guarantee; compy's `keypressed` code never
filters textual keycodes, it just never matches them to an insertion action; all literal
character insertion is reachable only from `textinput`, plus two `keypressed`-triggered paths that
move **existing** text (not the pressed key): clipboard paste (Ctrl+V) and `load_selection`
(Escape, editor). Holds uniformly across console/editor-edit/editor-search.

**Code check:**
- `UserInputController:textinput` (`userInputController.lua:727-738`) is the only place
  `self.model:add_text(t)` is called from a textinput handler (line 736); it also gates on
  `_is_hidden_overlay()` (see §3C) and `has_error()`.
- `UserInputController:keypressed` (`userInputController.lua:472+`) contains no `add_text` call —
  grep of the file for `add_text` shows two call sites: `userInputController.lua:45`
  (`UserInputController:add_text`, a thin wrapper used by editor's `load_selection`, not by the
  shared keypressed body) and `:736` (inside `textinput`, above).
- Ctrl+V paste from `keypressed`: `paste()` local at `userInputController.lua:520-521`
  (`input:paste(love.system.getClipboardText())`), wired from `copypaste()`
  (`:631-645`) which is called from the shared `keypressed` body (`:700`, `:709`).
- `load_selection` (Escape, editor mode) at `editorController.lua:590-603`: moves
  `buf:get_selected_text()` into the input via `input:add_text(t)` (`:599`) or `input:set_text(t)`
  (`:602`) — existing buffer text, not the Escape keycode itself.
- Console/editor/search all route character insertion exclusively through the shared
  `UserInputController:textinput` (console: `consoleController.lua:1158`; editor-edit:
  `editorController.lua:297`; search: `editorController.lua:300` → `SearchController:textinput`,
  `searchController.lua:143-147`, which itself calls `self.input:add_text(t)` — the same shared
  textinput-only insertion path). No third insertion route found.

**Axis 1 (fidelity):** still-true. Nothing about this channel-split convention was part of the #77
routing rewrite (it's a LÖVE-level/compy-convention fact, orthogonal to route topology), and the
code confirms it holds identically across console, editor, and search today.

**Axis 2 (corpus home):** already-covered. `internals/user_input.md` "Data flow" (lines 15-47,
almost verbatim the same claim including the two keypressed-triggered exceptions) and "Text Input
Widget" intro. This doc-A section is essentially a condensed duplicate of that corpus text.

**Notes for consolidation:** none — clean, high-confidence match both ways (fidelity and corpus
home).

---

## §3 — Routing vocabulary

Treating the invariant + each glossary entry + "controller occupies slot, not widget" + reset
semantics as distinct rows, per the prompt.

### §3 — the exclusivity invariant ("inter-route dispatch is EXCLUSIVE for every event type")

**Claim:** Exactly one route (mode-fixed) receives every event — keyboard, text, pointer — never
zero, never two; the widget never determines routing by existing.

**Code check:** Confirmed structurally for keyboard/text: `love.keypressed`/`textinput`/
`keyreleased` are always exactly one function at a time — either the console's own
(`Controller.set_love_keypressed` et al., `controller.lua:446-520`) or PIC's wrappers
(`occupy_keyboard`, `controller.lua:239-247`) — never both, per `set_handlers`/
`release_keyboard_route`/`set_default_handlers` always calling `Controller.project_input:deactivate()`
before/around reassigning `love.*`. Pointer: `handlers.mousepressed` (`controller.lua:1021-1030`)
always calls the single active route via `get_user_input()` (console/editor's own widget) then the
project's native handler — one path, mode-gated by which controller instance backs
`get_user_input()`/`love.mousepressed` at the time.

**Axis 1 (fidelity):** still-true — this is the ratified, currently-enforced invariant; nothing in
the shipped code contradicts "exactly one route."

**Axis 2 (corpus home):** already-covered. `decisions/input.md` Decision 1 (route-centric, not
widget-centric) states the same invariant directly ("every keyboard/text event is dispatched to
that one route. A widget never selects the route").

### §3 glossary — **route**

**Claim:** Current value set `{overlay, ConsoleController, EditorController}`; rewrite replaces it
with `{ConsoleController, EditorController, ProjectInputController}` (overlay gate removed, project
gains first-class route).

**Code check:** No `overlay` object occupies a route slot anywhere in `controller.lua` today —
`occupy_keyboard` installs PIC (`controller.lua:233-248`) directly; there is no code path where an
"overlay" object (rather than PIC) is assigned to `love.keypressed` for a running project. The
three-controller set (`ConsoleController`, `EditorController` reached via CC's internal fork,
`ProjectInputController`) is exactly what's wired.

**Axis 1 (fidelity):** the "today" half is **stale-mechanism/superseded** — the shipped route set
is already `{ConsoleController, EditorController, ProjectInputController}`, i.e. the doc's
"rewrite" target, not its "today." The forward half ("the rewrite replaces it with...") is
still-true as a description of present reality, just no longer *forward*.

**Axis 2 (corpus home):** already-covered. `decisions/input.md` Decision 1 ("the application mode
selects exactly one active route — console, editor, or project"); `internals/user_input.md`
"Dispatch chain" diagram (lines 130-160) names the same three routes.

### §3 glossary — **sink**

**Claim:** The default/last-resort disposition a route provides for an unhandled event; routes
need not realize it identically; `UserInputController` is a global singleton the active route
takes control of; "UIC becomes the *universal* terminal sink" is a recommended objective, not
present fact — Console/Editor routing-through-UIC is postponed.

**Code check:** `ProjectInputController:_sink` (`projectInputController.lua:181-184`) is a true
tier-4 sink: reached only on chain fall-through, delegates to
`love.state.user_input_controller`. `ConsoleController:keypressed` (`consoleController.lua:1164-1238`)
by contrast has **no separate tiered chain**; it's one flat function mixing console-specific
handling (history nav, Ctrl+L, evaluate) with a direct `input:keypressed(k)` call
(`:1209`) — `self.input` is console's own `UserInputController` instance used as the primary
widget, not reached as a last-resort "sink" behind other tiers. This confirms Console/Editor have
*not* been migrated onto the PIC-style tiered-sink shape.

**Axis 1 (fidelity):** still-true (both the general definition and the "postponed" note) —
Console/Editor genuinely still lack the tiered-chain-with-terminal-sink shape that PIC has;
nothing here changed with #77 (#77 explicitly scoped the tiered chain to the project route only).

**Axis 2 (corpus home):** already-covered. `decisions/input.md` Decision 1 consequence paragraph
("Today the editor is still reached through the console route's internal fork rather than as a
fully independent third sibling; converging... is deliberately left as a follow-on").

### §3 glossary — **widget**

**Claim:** Route-managed input surface, owned by the active route's controller, never a
free-floating global; today realized as the overlay singleton (`love.state.user_input`); can serve
as its route's sink but the two notions are distinct; **never occupies a LÖVE handler slot in any
context** — the route's controller occupies the slot and forwards to the widget internally.

**Code check:** Confirmed — `love.keypressed` is always a controller-level function
(`Controller.set_love_keypressed`'s `keypressed` local, `controller.lua:446-490`, or PIC's wrapper
closures, `controller.lua:239-247`, explicitly commented "wrapped (not assigned) to bind `pic` as
method receiver... `love.keypressed = pic.keypressed` would drop `self`" — i.e. even PIC itself,
the *controller*, is bound via a closure, and the widget (`UserInputController`) is one level
further removed, reached only via `forward_keypressed`/`_sink`, never directly assigned to a
`love.*` slot anywhere in `controller.lua`, `consoleController.lua`, or `projectInputController.lua`
(grep for `love.keypressed = ` / `love.textinput = ` / `love.keyreleased = ` returns only the
controller-level assignments cited above).

**Axis 1 (fidelity):** still-true, and durable across the rewrite (this was arguably true even
pre-rewrite for the widget itself, though the *route* realization changed from overlay-as-implicit-
route to PIC-as-real-route).

**Axis 2 (corpus home):** already-covered. `internals/user_input.md` "Keyboard Handling" intro
("with no `if`-governed native/widget split at the dispatch site") and "Dispatch chain" section;
`decisions/input.md` Decision 1.

### §3(C) — Hidden widget does not consume [owner-minted; PRESERVE]

**Claim:** An event reaching a widget while hidden is ignored/passed through, never mutates widget
state; intra-route; applies to every event type a widget might be offered.

**Code check:** `UserInputController:_is_hidden_overlay()` (`userInputController.lua:440-443`)
returns true iff `self == love.state.user_input_controller and not love.state.user_input`.
`keypressed` (`:477-479`), `textinput` (`:728-731`), `keyreleased` (`:744-747`) each open with this
exact guard and return early with a debug no-op log — confirmed for all three keyboard/text
channels. (Mouse/touch on the widget separately gate on `disable_selection`, a different
mechanism — see §5.5/§5.6; the hidden-check as stated in §3C is specific to the keyboard/text
sink.)

**Axis 1 (fidelity):** still-true — this is exactly the shipped mechanism (in fact this is the
PIC-era "internal hidden-check replacing the old external gating wrapper" the rewrite was for;
per anchor facts this reads as the forward design that has now landed as present-tense fact).

**Axis 2 (corpus home):** already-covered. `decisions/input.md` Decision 2 ("the terminal sink is
always invoked; it decides for itself to no-op when the widget is hidden... this is why widget
visibility carries no routing weight"); `internals/user_input.md` `_is_hidden_overlay` doc-comment
context under "Keyboard Handling."

### §3 — "The slot occupant is the controller, not the widget" (+ (A) Routing / (B) Widgets)

**Claim:** A controller (route) occupies the LÖVE handler slot and dispatches internally through
handlers → project slots → userinput sink; `app_state` selects the route (`ready`/`project_open`/
`running`/`inspect`/`snapshot`/`editor`/`shutdown`); in every non-running state the route is CC
(sub-routing console/editor internally); while running, the project's route owns keyboard/text.

**Code check:** Confirmed by the same evidence as "widget" above, plus: `set_default_handlers`
(`controller.lua:807-859`) is called on every transition back to console-owned states and always
installs CC-bound `love.*` functions; `occupy_keyboard` (`controller.lua:233-248`) is the sole
project-route installer, called only from `set_handlers`
(`controller.lua:295-300`, itself called at project-run start). `app_state` values match: grep of
`consoleController.lua` finds all seven states assigned (`'ready'`, `'project_open'`, `'running'`,
`'inspect'`, `'snapshot'`, `'editor'`, `'shutdown'` — confirmed at
`consoleController.lua:1012,1038,1078,253,257,272,963,981,1109-1111,766` and
`controller.lua:766`).

**Axis 1 (fidelity):** still-true — both the general "controller occupies slot" principle and the
`app_state`-selects-route mechanism are exactly as shipped.

**Axis 2 (corpus home):** already-covered. `decisions/input.md` Decision 1 + Decision 11 (route
connects only while running); `internals/user_input.md` "Dispatch chain" (the
`love.handlers.keypressed → love.keypressed — the slot occupant` diagram, lines 133-160) covers
this almost exactly, including the `app_state` branching.

### §3 — Two-step nature / "widget up while in console mode via free-floating show_widget()" is incoherent

**Claim:** Route selected first, then a widget may be (de)activated within it; a widget can't exist
independent of its owning route being active.

**Code check:** No code path constructs or shows a widget without going through a route-owned
call: console/editor's own `UserInputController` instances exist as long as CC/EditorController do
(always, structurally) but are only *reached* via the active route's own dispatch; the project
overlay singleton is shown only via `compy.input.show()`, itself only reachable from the running
project's own env (`project_env.compy`, wired in `ConsoleController.prepare_project_env`,
`consoleController.lua:835`), which only exists while that project's route is active. No
free-floating "show_widget()" symbol found in `src/**` (grepped, zero hits).

**Axis 1 (fidelity):** still-true.

**Axis 2 (corpus home):** unique-no-home — this specific "incoherent scenario" framing (arguing
against a hypothetical free `show_widget()`) isn't stated anywhere in the corpus docs; the closest
is `decisions/input.md` Decision 3's "projects... never hold the widget object" but that's a
different angle (API surface, not route-coherence). Partial: the *underlying* two-step model is
covered by Decision 1, but this specific negative-scenario argument is not.

### §3 — Reset semantics (widget re-activation)

**Claim:** Re-activating an already-active widget: without `force` → suppressed + warned, state
untouched; with `force` → today only `text` subset applies, no cancel chain fires; fresh
activation with no text starts empty.

**Code check:** `UserInputController:show` (`userInputController.lua:288-310`): no-`force` path
(`:294-297`) logs `Log.warn('UserInputController:show ignored — overlay already active...')` and
returns, no state touched; `force` path (`:298-307`) only touches `cfg.text` (`self.model:set_text`),
ignores every other field, and does not call any cancel-chain function; `open_fresh`
(`:259-266`, called from `show` on the inactive→active transition) does `self.model:clear_input()`
when `cfg.text == nil` (`:260-262`) — fresh-with-no-text starts empty, confirmed.

**Axis 1 (fidelity):** still-true — matches shipped code exactly, including the "today only text
subset" qualifier.

**Axis 2 (corpus home):** already-covered. `internals/user_input.md` "Singleton lifecycle"
(lines 397-403) states this almost verbatim; `decisions/input.md` Decision 3's consequence
paragraph and Decision 6 ("Reserved, not built" / no keep-open flag) touch adjacent ground.

---

## §4 — Completeness table

**Claim:** Every (mode × channel) cell is either a cited contract or an explicit gap/`pending`
marker; console/editor/project-running/inspect/search rows as tabulated.

**Code check:** Spot-checked the cells whose claims aren't already covered under §5 rows below:
- Editor `keyreleased` = "gap — out-of-radius (CC-internal fork missing)": confirmed under §5.3.2
  below (`ConsoleController:keyreleased`, `consoleController.lua:1241-1244`, no `app_state`
  branch).
- `inspect` row = "gap — out-of-radius, mode override: console owns the whole surface" for every
  channel including pointer: confirmed — under `inspect`, `get_user_input()`
  (`controller.lua:21-24`) returns `nil` unconditionally, so `handlers.mousepressed` et al.
  (`controller.lua:1021-1125`) skip the widget branch, and `love.mousepressed` itself is CC's own
  (reinstalled by `ConsoleController:suspend()` → `set_default_handlers`,
  `consoleController.lua:972-973`), whose `ConsoleController:mousepressed`
  (`consoleController.lua:1251-1260`) forks only on `app_state == 'editor'` — under `'inspect'` it
  falls to the `else` branch, i.e. console's own input widget, for every channel. Confirmed.
- `search` row (all four channels "gap — out-of-radius"): confirmed under §5.8 below.

**Axis 1 (fidelity):** still-true as a table shape (every cell is indeed accounted for, no silent
gaps found); the individual cell claims resolve to the same dispositions as the §5 rows they cite,
several of which are stale-mechanism/superseded at the mechanism level (see §5.1/§5.2/§5.3) even
though the completeness table's own framing ("PRESERVE §5.1", "forward §7.1 removes the gate") is
still an accurate pointer.

**Axis 2 (corpus home):** unique-no-home as a *table* — no corpus doc presents this mode×channel
completeness matrix in one place; its individual cells are already-covered piecemeal by the docs
cited under the corresponding §5 entries below.

**Notes for consolidation:** the table itself (the "no silently-absent cell" audit device) has no
mirror anywhere in the persistent corpus — if promoted, it would need re-deriving from post-#77
`app_state`/route reality since the "forward §7.1" annotations are now stale.

---

## §5.1 — keypressed — EXCLUSIVE on the active route [PRESERVE]

**Claim(s):** OUTCOME: keypressed reaches exactly one route, never zero/never two; global
shortcuts/held-key tracking run first but don't consume. MECHANISM (today's, CHARACTERIZE-
PROVISIONAL, explicitly marked non-binding): routing keyed on widget presence — `if
get_user_input() then ...` gate at `controller.lua:19-22`/`:554+` — project sink bypassed
entirely when widget up; rewrite removes gate, routes to PIC.

**Code check:** OUTCOME — confirmed still holds: `love.keypressed` is always exactly one function
(console's or PIC's wrapper), never conditionally split by widget presence any more.
MECHANISM — the described "today" (widget-presence gate bypassing the project route) is **no
longer what the code does**: `occupy_keyboard` (`controller.lua:233-248`) installs PIC's own
`love.keypressed` wrapper directly, with **no** `get_user_input()`/widget-presence check anywhere
in that installation or in `ProjectInputController:keypressed`
(`projectInputController.lua:257-260`) → `_dispatch` (`:198-207`), which runs the full four-tier
chain (framework combo → project combo → generic callback → sink) regardless of widget state; the
sink itself (not the dispatch gate) is what internally no-ops when hidden (§3C). `get_user_input`
(`controller.lua:21-24`) still exists but is now used only by the **console/editor route's own**
`forward_keypressed` (`controller.lua:41-46`) — i.e. it survives as an intra-route forward for CC,
not as the inter-route project gate doc-A describes. Global shortcuts (`quickswitch`/
`project_state_change`/`restart`/`profile` locals inside `handlers.keypressed`,
`controller.lua:874-984`) run before `love.keypressed` and never `return`/consume (confirmed —
none of the shortcut branches short-circuits the trailing `return love.keypressed(...)` call).

**Axis 1 (fidelity):** OUTCOME still-true. MECHANISM **superseded-by-shipped** — the "forward /
0.1.0-mN" contract this note anticipated (gate removed, PIC installed) has **landed**; the "today"
description (widget-presence gate on the project route) no longer matches any code path. Per
anchor facts, this is exactly the expected inversion.

**Axis 2 (corpus home):** already-covered. `decisions/input.md` Decision 1 (route-centric, gate
removed) + Decision 2 (four-tier chain); `internals/user_input.md` "Keyboard Handling" §"Dispatch
chain" (explicitly: "The gateway... no longer routes on widget presence — the overlay gate is
removed", line 164) and "FR-6... resolved as of 1.0.0-rc20260712" (line 252) — the corpus already
states the landing doc-A's mechanism note anticipated as forward.

**Notes for consolidation:** doc-A's own line citations (`controller.lua:19-22, :554+`) point at
what is presumably the pre-rewrite file shape; current `get_user_input` sits at `:21-24` and there
is no `:554+` gate remaining in the file at all (file is 1192 lines total, no widget-presence
branch near there) — consistent with "this was the old mechanism, now gone," not a citation error
to flag as wrong per se.

---

## §5.2 — textinput — EXCLUSIVE on the active route [PRESERVE]

**Claim(s):** Same shape/provenance as §5.1; widget-presence keying is the same
CHARACTERIZE-PROVISIONAL mechanism note, not the contract.

**Code check:** Mirrors §5.1 exactly. `occupy_keyboard` installs `love.textinput = function(t)
return pic:textinput(t) end` (`controller.lua:242-244`); `ProjectInputController:textinput`
(`projectInputController.lua:263-266`) runs the same `_dispatch` chain, no widget-presence gate.
Console/editor's own `forward_textinput` (`controller.lua:50-55`) is, again, intra-route-only.

**Axis 1 (fidelity):** OUTCOME still-true; MECHANISM superseded-by-shipped, identical reasoning to
§5.1.

**Axis 2 (corpus home):** already-covered, same citations as §5.1 plus `internals/user_input.md`
"Data flow" diagram (lines 15-32), which shows the ProjectInputController path explicitly for
textinput.

**Notes for consolidation:** none beyond §5.1's.

---

## §5.3 — keyreleased — EXCLUSIVE on the active route [PRESERVE]

### §5.3.1 — the overlay-widget diversion (mirrors §5.1/§5.2)

**Claim:** Today, while a widget is active, release is diverted to it and the project route
bypassed entirely — same disposition, "fixed at 0.1.0-m4, §7.1." Open question carried: does any
consumer consume `keyreleased` today under this path at all?

**Code check:** Same finding as §5.1/§5.2: `occupy_keyboard` installs `love.keyreleased =
function(k) return pic:keyreleased(k) end` (`controller.lua:245-247`);
`ProjectInputController:keyreleased` (`projectInputController.lua:271-274`) runs the full
four-tier `_dispatch` (confirmed identical chain shape to keypressed/textinput — `_dispatch` is one
shared function, `projectInputController.lua:198-207`, called by all three per-channel methods).
The sink (`_sink`, `:181-184`) reaches `UserInputController:keyreleased`
(`userInputController.lua:743-754`), which is real (releases selection on shift-release, clears
error on space-release) and gated by `_is_hidden_overlay()` (§3C) — so the "does any consumer
consume keyreleased at all" open question is now answered: yes, the sink does, whenever a widget
is shown.

**Axis 1 (fidelity):** superseded-by-shipped — the "today" diversion-and-bypass mechanism is gone;
replaced by the same four-tier chain as keypressed/textinput, with the widget reached only as
tier-4 (not an exclusive diversion). This is exactly the "fixed at 0.1.0-m4" forward this row
anticipated, now landed.

**Axis 2 (corpus home):** already-covered. `internals/user_input.md` "Key release" section (lines
291-307): "Since 1.0.0-rc20260712, `ProjectInputController:keyreleased` runs the same four-tier
chain as the other channels" — directly resolves doc-A's carried-provisional open question.

### §5.3.2 — the CC-internal editor-fork gap

**Claim:** Unlike `keypressed`/`textinput`, `ConsoleController:keyreleased` never forks on
`app_state == 'editor'` — it unconditionally calls its own instance's `:keyreleased`; editor's and
search's own `UserInputController` instances never receive a release. Currently inert (editor/
search construct with `disable_selection = true`, and error-clear is also reachable via any
`textinput` character). Out of #77 blast radius.

**Code check:** `ConsoleController:keyreleased` (`consoleController.lua:1241-1244`):
```lua
function ConsoleController:keyreleased(k)
  self.input:keyreleased(k)
  self.input:update_view()
end
```
— confirmed unconditional, **no** `app_state == 'editor'` branch (contrast with `:keypressed`
`consoleController.lua:1184` and `:textinput` `:1146`, both of which do fork). Grepped
`editorController.lua` and `searchController.lua` for a `:keyreleased` method definition — zero
hits in either file, confirming "editor's and search's own... instances never receive a release."
`disable_selection = true` for both editor's main input and its search sub-widget:
`editorController.lua:12,16`. Error-clear-via-any-textinput-char: `EditorController:textinput`
(`editorController.lua:291-292`) unconditionally clears error state on any character, matching the
"covers Space too" claim.

**Axis 1 (fidelity):** still-true (this is a plain descriptive finding, tagged
"[characterized from current runtime]" in doc-A itself, not a PRESERVE contract) — matches shipped
code exactly, including line-level structural detail. Note: doc-A's own citation
(`consoleController.lua:1090-1093`) is stale by line number (current code: `:1241-1244`) — content
is otherwise exactly right.

**Axis 2 (corpus home):** already-covered, near-verbatim. `internals/user_input.md` "Key release"
(lines 298-317) states this exact structural finding, including the same "currently inert... but a
real asymmetry" framing and the same file:line style of evidence (its own citations, e.g.
`consoleController.lua:1203-1206`, are also slightly off current HEAD — a pre-existing drift in
the corpus doc itself, not introduced by doc-A).

**Notes for consolidation:** both doc-A and the corpus doc cite slightly-off line numbers for this
same method (1090-1093 vs 1203-1206 vs actual 1241-1244) — the file has clearly been edited more
than once since either was written; the structural claim itself is solid across all three
readings.

---

## §5.4 — Mode override: `inspect` — the console owns the input surface

**Claim:** Owner ruling: deliberately deferred, keep current assumption, no new contract to
invent. Current behaviour: under `app_state == 'inspect'`, console REPL serves every channel
(keypressed/textinput/keyreleased/pointer); project widget not honoured; input isn't blocked, the
REPL runs live over the frozen project. Mechanism: `get_user_input()` unconditional override;
`ConsoleController:suspend()` physically swaps `love.*` slots back to console's own (not merely
short-circuiting); `get_effective_env()`/`evaluate_input()` select `project_env` during inspect.

**Code check:** `get_user_input()` (`controller.lua:21-24`) — exact match, unconditional `if
love.state.app_state == 'inspect' then return end`. `ConsoleController:suspend()`
(`consoleController.lua:957-974`): confirmed — calls `self.main_ctrl.save_user_handlers(...)` then
`self.main_ctrl.set_default_handlers(self, self.view)` (`:972-973`), which reinstalls CC-bound
`love.keypressed/keyreleased/textinput/mouse*/touch*/update/draw/quit`
(`controller.lua:807-859`) — a physical slot swap, not a short-circuit, matching the claim.
`get_effective_env` (`consoleController.lua:935-944`) and `evaluate_input`'s inline `run_env`
selection (`consoleController.lua:873-878`) both branch on `app_state == 'inspect'` to select
`get_project_env()` — confirmed exactly. Pointer under inspect: traced in §4 above —
`ConsoleController:mousepressed` et al. fork only on `'editor'`, so under `'inspect'` they fall to
the console's own `self.input`, confirming "console owns the whole surface... pointer alike."

**Axis 1 (fidelity):** still-true, both outcome and mechanism — this section is explicitly
"CHARACTERIZE-PROVISIONAL / OWNER RULING PENDING / out of #77 blast radius" in doc-A itself (i.e.
doc-A already disclaims it as a binding contract), and the shipped code matches the described
mechanism exactly, unchanged by #77 (as the doc itself expects, given the deferred ruling).

**Axis 2 (corpus home):** already-covered, closely. `internals/user_input.md` "Dispatch chain"
paragraph "`inspect` mode overrides all of the above" (lines 168) states the identical mechanism,
nearly verbatim ("physically swaps `love.keypressed`/`textinput`/`draw`/`update` back to the
console's own functions via `set_default_handlers`, not merely short-circuiting them... a live
debugger console, not a separate idle console"). `decisions/input.md` Decision 12 ("`inspect` is a
mode-to-route line, nothing more") gives the decision-level framing.

**Notes for consolidation:** doc-A explicitly says this is "not currently documented in either
`internals/console.md` or `internals/user_input.md`; this pass is its first record" — that claim
is now **false**: `internals/user_input.md` line 168 (quoted above) documents it directly, in
language close enough to suggest one was derived from (or synchronized with) the other after
doc-A was written. Flagging as a factual claim in doc-A that no longer holds (the content is
still-true; the "nowhere else documented" provenance claim is not) — worth the orchestrator's
attention since it affects the promote/merge decision directly (this section's content is not
actually unique-no-home despite doc-A asserting so).

---

## §5.5 — mousepressed / mousereleased / mousemoved — EXCLUSIVE on the active route [PRESERVE]

**Claim:** Pointer reaches the active route; intra-route forwarding to a widget is the route's own
concern (not inter-route BOTH); no second top-level route exists to receive a click while a
project runs; under `inspect`, intra-route forwarding to a project widget is suppressed but the
active route is unaffected.

**Code check:** `handlers.mousepressed`/`mousereleased`/`mousemoved`
(`controller.lua:1021-1067`) each call `get_user_input()` (console/editor widget, or `nil` when a
project is `running` and no console widget path applies... actually see note below) then
unconditionally call `love.mousepressed`/etc — the single active route's own handler (console's
`set_love_mousepressed` install or the project's `wrapped_native` install via `hook_pointer`,
`controller.lua:252-265`). No second controller is ever invoked in parallel — confirmed by reading
all three handler bodies; each has exactly one `get_user_input()` branch and one
`love.mouse*` call. Editor no-op: `ConsoleController:mousepressed`
(`consoleController.lua:1251-1260`) forks on `app_state == 'editor'`, delegating to
`self.editor.input:mousepressed` only `if self.cfg.editor.mouse_enabled` — and
`UserInputController:mousepressed` (`userInputController.lua:812-819`) returns immediately if
`self.disable_selection` (editor's instance is constructed with `disable_selection = true`,
`editorController.lua:12`) — confirmed "no-op: disable_selection" exactly as claimed.

**Axis 1 (fidelity):** still-true, both the general exclusivity/intra-route framing and the
specific editor no-op mechanism.

**Axis 2 (corpus home):** already-covered. `internals/user_input.md` "Mouse Input" § "Framework-
level click handling" / "Direct mouse events" ("The framework's own `mousepressed`/`mousereleased`
handlers... call the user handler AND the overlay controller if present — both get the event") and
§ "Input widget mouse" ("Mouse events on the input widget are only processed when
`disable_selection` is false. In editor mode... `disable_selection = true`").

**Notes for consolidation:** one wrinkle worth flagging: `get_user_input()` returns `love.state.
user_input` unconditionally outside `inspect` — it does **not** itself check which route is
active, so during a running project with a project overlay shown, `handlers.mousepressed` calls
*both* the project's widget (via `get_user_input().C`) *and* whatever `love.mousepressed` currently
is (the project's own native, via `wrapped_native`) — this is the "intra-route BOTH" the doc
describes, confirmed structurally, but it means the mouse gateway genuinely does not distinguish
routes the way keyboard/text now does (no PIC-style chain for pointer at all — see technical
debt "Pointer delivery is an unstructured broadcast, not a chain", already cited by doc-A's own
companion inventory). Not a doc-A inaccuracy, just worth flagging as the mechanism backing the
claim being thinner than keyboard's.

---

## §5.6 — touchpressed / touchreleased / touchmoved — EXCLUSIVE on the active route [PRESERVE]

**Claim:** Same contract/provenance as mouse; widget's touch handlers are no-ops today
(mechanism, not contract) — delivery to the active route is what's guaranteed.

**Code check:** `UserInputController:touchpressed/touchreleased/touchmoved`
(`userInputController.lua:861-886`) are each a bare `--- TODO` stub with no body — confirmed
no-op. `handlers.touchpressed` et al. (`controller.lua:1082-1125`) mirror the mouse handlers'
structure (get_user_input widget call, then unconditional `love.touch*` call) — same exclusivity
argument as §5.5 applies.

**Axis 1 (fidelity):** still-true.

**Axis 2 (corpus home):** already-covered. `internals/user_input.md` "Touch" section (lines
370-372): "Touch handlers... are stubbed with `-- TODO` in `UserInputController`."

**Notes for consolidation:** none.

---

## §5.7 — wheelmoved — reaches the active route [CHARACTERIZE-PROVISIONAL]

**Claim:** Route-axis PRESERVE: wheel reaches the active route like every other event. Provisional
today: framework default is a no-op; active route does not forward wheel to a widget
(mechanism-by-omission, not designed asymmetry). Intent: pass-through by default, project opt-in
to consume.

**Code check:** `UserInputController:wheelmoved` (`userInputController.lua:851-853`) is a bare
`--- TODO` stub, confirmed no-op on the widget side. `Controller.set_love_wheelmoved`
(`controller.lua:578-587`) installs a `wheelmoved` that only calls `CC:wheelmoved(x,y)` — no
`get_user_input()`/widget-forward call at all in the gateway installer (unlike keypressed/
textinput/keyreleased's `forward_*` calls) — confirms "the active route does not forward wheel to
a widget" and that this is by omission (no gateway entry) rather than an explicit block.
`ConsoleController:wheelmoved` (`consoleController.lua:1295-1303`) forks on `'editor'` like the
other mouse events, delegating to `self.editor.input:wheelmoved` only if
`cfg.editor.mouse_enabled` — which itself hits the stub above.

**Axis 1 (fidelity):** still-true — route-axis claim and the CHARACTERIZE-PROVISIONAL mechanism
note both hold; nothing about wheel changed with #77 (out of scope, matching doc-A's own framing).

**Axis 2 (corpus home):** already-covered. `internals/user_input.md` "Direct mouse events" section
(line 357: "`love.wheelmoved`... forwarded directly to project-defined handlers via the standard
LÖVE2D mechanism") — matches doc-A's own cited "intent" framing almost exactly (pass-through to
project, framework consumes only if project opts in).

**Notes for consolidation:** none.

---

## §5.8 — search — a third full MVC triad, undocumented in the design corpus

**Claim:** `EditorController.search` (`editorController.lua:16`) is a fully independent
`SearchController`/`SearchModel` pair wrapping its own `UserInputController` — a third consumer of
the shared widget primitive. Live only in `app_state=='editor'` + `mode=='search'`. `keypressed`
via `_search_mode_keys` → `self.search:keypressed`; `textinput` via `EditorController:textinput`
when `mode=='search'`; `keyreleased`: no path exists — `SearchController` defines no
`:keyreleased`. No evaluator (`nil`); Enter jumps to selection, not submit. `SearchController:clear()`
reaches past its own controller into `self.model.input:clear_input()`, skipping `clear_error()`.
Zero mentions of "search" in `design.md`/`spec.md`/`roadmap.md`.

**Code check:** `EditorController.search = SearchController(M.search, UserInputController(M.search.
input, nil, true))` (`editorController.lua:14-17`) — confirmed, third-arg `true` =
`disable_selection`. `EditorController:_search_mode_keys` (`editorController.lua:485-503`) calls
`self.search:keypressed(k)` (`:493`). `EditorController:textinput` (`editorController.lua:287-302`)
forwards to `self.search:textinput(t)` when `self.mode == 'search'` (`:299-300`). Grepped
`searchController.lua` for `keyreleased` — zero hits; confirmed no such method.
`SearchController:keypressed` (`searchController.lua:81-140`): on Enter (`Key.is_enter(k)`,
`:131-138`) reads `self.model.resultset[sel].r` and returns it as a "jump" — no evaluator/validator
call anywhere in the file. `Search` model (`searchModel.lua:28-36`): `input =
UserInputModel(cfg, nil, 'search')` — second positional arg (evaluator, per
`UserInputController`'s own constructor convention) is `nil`, confirming "No evaluator." `Search
Controller:clear()` (`searchController.lua:44-47`): `self.model.input:clear_input(); self.model:
clear()` — calls straight into the model, no `self.input:clear_error()`/controller-level call.
Did not grep `design.md`/`spec.md`/`roadmap.md` myself for "search" (out of `src/**` scope per the
circularity guard's spirit — those are design-corpus files, not code; treating doc-A's own claim
about them as out of this worker's verification scope, code-only).

**Axis 1 (fidelity):** still-true across every sub-claim checked — this section is explicitly
CHARACTERIZE-PROVISIONAL / out-of-#77-blast-radius in doc-A itself, and it is a precise, accurate
description of unchanged, pre-existing structure.

**Axis 2 (corpus home):** already-covered, near-verbatim, including the "no design corpus mention"
observation. `internals/user_input.md` "Search — a third widget instance, live only in editor/
search mode" (lines 319-336) states every sub-claim here almost word-for-word, down to the same
file:line citations and the same "carried here as the first record of it in the permanent doc
corpus" framing.

**Notes for consolidation:** this is the single largest content overlap found between doc-A and
the corpus — `internals/user_input.md`'s "Search" section reads as though directly derived from
(or the source of) doc-A §5.8. If doc-A is deleted, this section's content is fully preserved
already; no promotion needed for §5.8 specifically.

---

## §5.9 — The one rule — inter-route exclusivity for every event

**Claim:** Restates the single rule (every event type EXCLUSIVE inter-route; only "both" is
intra-route; `inspect` = console owns surface; `search` = fourth route-internal surface; global
shortcuts non-consuming) as a summary of §3–§5.8.

**Code check:** Pure summary/rollup of claims already verified individually above (§3 invariant,
§5.4, §5.8, and the global-shortcuts-non-consuming claim independently confirmed under §5.1's
code check: none of `quickswitch`/`project_state_change`/`restart`/`profile` short-circuits the
trailing `love.keypressed(...)` call in `handlers.keypressed`, `controller.lua:874-984`).

**Axis 1 (fidelity):** still-true — consistent with, and fully supported by, the individual
findings above; no new claim introduced here that wasn't already checked.

**Axis 2 (corpus home):** already-covered, distributed across the same citations as the rows it
summarizes (`decisions/input.md` Decision 1/2/12; `internals/user_input.md` "Dispatch chain" /
"Search"). No single corpus section restates it as one compact rule-of-five the way this section
does, so as a *summary artifact* it is a convenient unique digest, but every constituent fact
already has a home.

**Notes for consolidation:** low-risk row; mostly a restatement checkpoint.

---

## Uncertainties / thin spots

1. **LSP used for spot-checks, not exhaustively.** Most of the dossier was built from grep +
   full-file reads (the LSP tools were not in my initial toolset and had to be pulled in
   mid-session). Once loaded, `mcp__lua-lsp__references` on `get_user_input` confirmed the call
   set is exactly `forward_keypressed`/`forward_textinput`/`forward_keyreleased` plus the six
   mouse/touch/`userinput` handlers in `controller.lua` — no other caller anywhere in `src/**`,
   matching what grep had already found (with two harmless noise hits: a stray match inside a
   `.patch` file under `doc/development/wip/.../pr-slices/`, and two indexer tmp-file artifacts
   that no longer exist on disk — neither is live code). `mcp__lua-lsp__references` on
   `SearchController.clear` came back but only listed same-file method definitions, not external
   call sites, so it didn't add beyond the grep-confirmed callers in `editorController.lua`
   (`:488`, `:501`). A references query on `UserInputController._is_hidden_overlay` exceeded the
   tool's output-size limit and was not retried with a narrower scope — that claim rests on my own
   full read of `userInputController.lua`'s three call sites (`:477`, `:728`, `:744`), not an LSP
   cross-check. Net: no LSP-sourced correction to any finding above, but coverage is partial, not
   exhaustive — a fuller LSP sweep (per-symbol, narrowed queries to dodge the size limit) would be
   the natural follow-up for "X never happens" claims elsewhere in the dossier (e.g. "no
   `show_widget()` symbol exists," "no third insertion route") that I only grep-verified.
2. **§5.4's "not currently documented" provenance claim is actively wrong** (see §5.4 notes) — the
   *content* is still-true and already-covered, but doc-A's own claim about its novelty no longer
   holds. This is a good one for the orchestrator to weigh: it suggests doc-A predates (or wasn't
   resynced with) a later pass over `internals/user_input.md` that absorbed this material.
3. **Doc-A's own file:line citations have drifted** in at least two places I can confirm
   independently (§5.1's "`controller.lua:19-22, :554+`" and §5.3.2's
   "`consoleController.lua:1090-1093`" — both now point at different/nonexistent code regions,
   though the *content* both cited is still findable and confirmed at its new location). I did not
   audit every line citation in §1–§5 exhaustively for drift — I verified content, not every
   number. If the orchestrator's final table wants to flag citation-freshness as its own axis, a
   full line-citation sweep would be a mechanical follow-up (I'd estimate a non-trivial minority
   of citations across §1-§5 are stale by line number even where content holds).
4. **§5.5's "get_user_input() doesn't distinguish routes" wrinkle** (noted in §5.5) is my own
   observation surfaced during verification, not a doc-A claim being disputed — flagging in case
   it matters for how the orchestrator frames pointer's Axis-1 disposition (I judged it
   still-true because doc-A itself already characterizes pointer as "never gated"/mechanism-level
   BOTH, so this is consistent with, not contradicting, doc-A's own claim).
5. **Did not verify design.md/spec.md/roadmap.md grep for "search"** (doc-A's own claim under
   §5.8) — those are design-corpus docs, not `src/**`, and checking prose-corpus documents against
   itself felt outside "verify against CODE." Flagging as unverified-by-me rather than
   silently accepting it.
6. **`app_state` value enumeration for §3(A)/"slot occupant" row** — I confirmed all seven listed
   values are assigned somewhere in `consoleController.lua`/`controller.lua`, but did not
   exhaustively trace every transition edge between them; if the orchestrator needs the full
   state-transition graph (not just "these values exist"), that's a deeper trace than this
   dossier performed.
