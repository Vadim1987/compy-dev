# S18 revalidation — mechanical evidence sweep

Purely mechanical evidence gathering, no judgment calls, no edits. cwd `/repo`. Commissioning
docs: `validation/reviews/delta-design-input-api.md`, `validation/reviews/delta-spec-input-api.md`.
Session17 claim: `implementation/sessions/session17/report.md`.

---

## A. Deleted symbols — CONFIRMED (grep); LSP unreliable for this check (see note)

Grep, `src/` + `tests/`, all zero hits for all eight symbols:

```
framework_handlers, install_tier1, _generic_callback, _sink, shown_widget,
run_hook, framework_submit, framework_cancel
```

`ProjectInputController.natives` **field**: zero. The only surviving `natives` token is a local
**parameter** name — `seed_hooks(hooks, natives)` (`src/controller/projectInputController.lua:43`,
used at `:46`) and `ProjectInputController:activate(natives, compy_input)` (`:107`, used at
`:109`) — not a stored field on the controller (`self.compy_input` is the only field; confirmed by
reading the whole 158-line file). This matches delta-spec §5's "no separate `self.natives` field."

**LSP disagreement, reported per charter:** `mcp__lua-lsp__references` and `...definition` returned
apparent "hits" for `_generic_callback`, `_sink`, `run_hook`, `framework_submit`,
`framework_cancel` inside `projectInputController.lua` — but the file is 158 lines total
(`wc -l` confirmed) and the tool reported locations like `L208:C11` and `L209:C15`, which do not
exist in the file (`sed -n '200,215p'` returns nothing). `definition` for `run_hook` returned the
`dispatch` function body (L68–76) and for `framework_handlers` returned the `keypressed` method
body (L136–147) — neither defines those names; grep confirms neither string appears anywhere in
the file. Forcing a re-index via `diagnostics` (which returned fresh, in-range results, e.g.
L96–121, consistent with current file content) did not change the phantom reference output on
re-query. Conclusion: the LSP `references`/`definition` tools are returning stale/bogus data for
these specific deleted-symbol queries in this file — not real matches. Grep is ground truth here:
**zero surviving references for all eight symbols and the `natives` field.**

`shown_widget` and `_sink` LSP queries also returned "hits" pointing at unrelated lines
(`self.compy_input.shortcuts`/`self.compy_input.hooks` at L95, `natives` doc comments at L98–121)
that contain neither string — same phantom-match pattern.

**Verdict: CONFIRMED** (by grep, the reliable tool here). Session17's own "grep-verified zero"
claim holds.

---

## B. Vocabulary sweep — CONFIRMED for src/ and the three actively-resynced docs; DISCREPANCY
## on `decisions/input.md` (see below)

### src/**/*.lua comments
- `sink` — 1 hit, `src/examples/keyboard/hunt.lua:265` ("floor instead of sinking through") —
  **legitimate use**, game-physics prose, unrelated subsystem.
- `singleton` — hits only in `src/util/range.lua:20`, `visibleStructuredContent.lua`,
  `content.lua`, `parser.lua` — all `Range.singleton(...)`, an unrelated range-utility
  constructor — **legitimate, out of scope**.
- `tier`, `framework handler`, `generic callback` — zero hits.
- `proxy` — hits only in `src/util/table.lua` (a generic table-freeze/protect utility, local var
  named `proxy`) and vendored `src/lib/metalua/...` — **legitimate, out of scope** (not the D13
  held-key proxy prose, which the vocabulary table retired to "read-only pressed-keys view").
- `on_key_pressed`/`on_text_input`/`on_key_released` — zero hits.
- Confirmed new names in place: `compy.input.shortcuts`/`.hooks` used consistently
  (`projectInputController.lua:12,15,41,95,109`; `consoleController.lua:381`). No
  `compy.input.handlers` survives.

### Persistent docs — actively resynced (per session17's own claim)
- `doc/input_api.md` — **zero** hits for any retired term; uses `shortcuts`/`hooks`/`callbacks`
  throughout (e.g. lines 20–22, 294–345).
- `doc/development/internals/user_input.md` — hits for `tier`/`sink`/`singleton`-adjacent words
  exist but are all **negation/historical framing** ("There is no framework tier any more" —
  L127, L302, L445) — legitimate, correctly describing the retired state as retired.
- `doc/development/technical_debt/input.md` — hits for `sink`/`tier`/`singleton` are all inside
  explicitly historical sections: `### Widget sink reaches the singleton via love.state global +
  nil-guard (RESOLVED-IN-PART by Phase R4)` (L510) with body text using **"Old state:"** /
  **"Resolution:"** framing (L515–519, "The sink is gone."); L62 "renamed from tier-3/tier-4 to
  hooks/widget"; L86 "(then a non-overridable framework tier, since retired by Phase R4 —
  Decision 2 revised)" — all legitimate, explicitly-historical uses, not current-state claims.

**Combo table named `shortcuts`, tier-3 slot named `hooks`:** confirmed in all three docs above
and in src.

### DISCREPANCY — `doc/development/decisions/input.md` NOT resynced
This file **is** in the task's named corpus (delta-design §B lists it explicitly) but was
**not** included in session17's own "resynced" list (report.md only names `input_api.md`,
`internals/user_input.md`, `technical_debt/input.md`). Grep confirms it retains the **full old
vocabulary as current-tense fact**, unqualified by any "was"/"retired" framing:
- `## Decision 2 — a four-tier dispatch chain with truthy-consume` (L56)
- `4. **the sink** — the widget's text editor; always terminal, permanently configured.` (L66)
- `## Decision 6 — submit and cancel are framework-tier...` (L155), `**tier-1 framework
  handlers**` (L157)
- `3. **a per-event generic callback** — on_key_pressed / on_text_input / on_key_released` (L64,
  also L143, L195)
- `**Decision.** The input widget is a **singleton, created once at load**...` (L92)
- `second argument is a **read-only proxy**` (L302)

**This is very likely intentional, not an oversight** — the delta-design's own preamble states:
"Addendum to `../../decisions/input.md` (the 13 ratified decisions, unedited and still
authoritative until this addendum is ratified). Frozen `design/` untouched..." and "Written in
`decisions/input.md`'s own voice ... so it can be folded in verbatim once ratified." I.e.
`decisions/input.md` is deliberately left as the old, still-authoritative baseline pending formal
ratification of the addendum — the addendum text itself has not yet been folded in. Flagging
this as a discrepancy against a **literal** reading of the B task instruction (which names this
file in the corpus), while noting the commissioning docs' own framing makes the non-resync
look deliberate rather than a miss. Orchestrator judgment call: whether "ratify and fold in" is
still a pending, tracked step or was silently dropped.

**Verdict: CONFIRMED for src/ and the three actively-resynced docs; DISCREPANCY on
`decisions/input.md`** (see DISCREPANCIES list).

---

## C. Acceptance criteria present as tests — CONFIRMED

`tests/input/input_redesign_ac_spec.lua` (177 lines) contains all ten ACs:

| AC | Test(s) | Line |
|---|---|---|
| AC1 | "AC1 — Escape clears and leaves the widget shown" | 73 |
| AC2 | "AC2 — before_cancel veto keeps content, skips after_cancel" | 84 |
| AC3 | "AC3 — submit stays open with no auto-clear" | 99 |
| AC4 | "AC4 — after_submit = hide reproduces auto-close" | 114 |
| AC5 | "AC5 — a shortcut on return shadows the submit" | 124 |
| AC6 | "AC6 — consumption derives from shownness" | 140 |
| AC7 | "AC7 — console Up at the vertical limit navigates history" | 170 |
| AC8 | 2 tests under "AC8 — hook seeding, one-shot" | 23–45 |
| AC9 | 2 tests under "AC9 — D7 guard: frozen container, writable leaves" | 50–69 |
| AC10 | "AC10 — teardown re-seeds, no cross-project callback leak" | 151 |

No AC without a test. 12 `it(...)` blocks total (AC8 and AC9 each have two), matching session17's
report ("12 acceptance-criteria anchors, AC1–10").

`busted tests/input/input_redesign_ac_spec.lua` →
**`12 successes / 0 failures / 0 errors / 0 pending : 0.144423 seconds`**

**Verdict: CONFIRMED.**

---

## D. Persistent-docs resync (spot-check) — CONFIRMED

- `doc/input_api.md` (L20–22): *"`compy.input` is a table on your project's `compy` namespace,
  holding three writable sub-tables — `shortcuts`, `hooks`, `callbacks` — plus **methods**..."*
  — new vocabulary, current-state voice.
- `doc/development/internals/user_input.md` (L124–129): *"The project route runs a per-event
  chain, a dumb three-consumer walk... `shortcuts[event][combo]` → `hooks[event]` → the widget —
  stopping at the first that consumes. There is no framework tier any more..."* — new vocabulary,
  explicitly negates the deleted tier.
- `doc/development/technical_debt/input.md` (L519): *"**Resolution:** The sink is gone. `dispatch`
  (obligation 6a, validation/reviews/delta-spec-input-api.md §2, `projectInputController.lua:74-86`)
  is now a free function that takes the widget **as a parameter** rather than reaching for a
  global itself..."* — describes the old tier-1/sink model explicitly as past/resolved, not
  current.

None of the three describe the deleted tier-1/framework-tier/sink model as *current* state.
(`decisions/input.md` does — see the B discrepancy above; it was out of scope for D's named
files.)

**Verdict: CONFIRMED** (for the three files D names).

---

## E. Open-issue code facts — the session's crux

### E.1 — `userInputController.lua:725` branch, and the standing REVIEW at `:724`

Confirmed exactly at the stated lines:

```
724: -- REVIEW: looking forward, UIC should not be aware if application is in 'editor or
     -- non-editor' mode -- it should be editor that configures it accordingly (via hooks)...
725: if love.state.app_state == 'editor' then
```

Branch bodies (`src/controller/userInputController.lua:725-756`):

```lua
725  if love.state.app_state == 'editor' then
726    removers()
727    horizontal()
728    vertical()
729    newline()
730    modify()
731
732    copypaste()
733    selection()
734  else
735    -- normal behavior
736    removers()
737    vertical()
738    horizontal()
739    newline()
740
741    copypaste()
742    selection()
743
744    -- The widget's own submit/cancel defaults ...
745    if Key.is_enter(k) and not Key.shift() then
746      self:_submit_default(keys_pressed)
747    elseif k == 'escape' and not Key.ctrl() then
748      self:_cancel_default(keys_pressed)
749    end
750  end
```

Exact differences:
1. **Call order**: `horizontal()` before `vertical()` in the editor branch; `vertical()` before
   `horizontal()` in the else branch (order swap, flagged by the REVIEW itself as "purposeful or
   coincidence?").
2. **`modify()`**: called only in the editor branch (line 730); absent from the else branch.
3. **`_submit_default`/`_cancel_default`**: called only in the else (non-editor) branch (lines
   746, 748); the editor branch has no Enter/Escape handling of its own inside this function at
   all — it falls out having only run the shared editing helpers.

### E.2 — `_submit_default`/`_cancel_default` definitions and call sites

- `_submit_default` defined at `src/controller/userInputController.lua:450`.
- `_cancel_default` defined at `src/controller/userInputController.lua:467`.
- Called **only** at `:752` and `:754` (inside the `else`/non-editor branch of `keypressed`,
  which starts at `:533`). No other call sites in the file or elsewhere (grep across
  `src/`/`tests/` for `_submit_default`/`_cancel_default` shows only these definition + call
  pairs plus doc-comment mentions).

**Verdict: CONFIRMED.**

### E.3 — editor fall-through constraint (`editorController.lua`)

- `load()` is a local function inside `EditorController:_normal_mode_keys`, defined at
  **line 716** (matches task's "~716"):
  ```lua
  716  local function load()
  717    if not Key.ctrl() and
  718        not Key.shift()
  719        and k == "escape" then
  720      load_selection()
  721    end
  722    if not Key.ctrl() and
  723        Key.shift() and
  724        k == "escape" then
  725      load_selection(true)
  726    end
  727  end
  ```
  It calls `load_selection()`/`load_selection(true)` on plain/shift-Escape and does **not** call
  `block_input()` anywhere in its body (confirmed by reading the full function; contrast with
  `copycut()`, `paste_k()`, `delete()`, `navigate()` in the same file, which all call
  `block_input()` on their trigger keys).
- `passthrough` defaults `true` at `:513`; `block_input = function() passthrough = false end` at
  `:514`.
- End of `_normal_mode_keys` (confirmed at **lines 803-804**, exact as the task described):
  ```lua
  797  submit()
  798  load()
  799  delete()
  800  navigate()
  801  clear()
  802
  803  if passthrough then
  804    input:keypressed(k)
  805  end
  806  end
  ```
  Since `load()` never flips `passthrough`, plain/shift-Escape falls through to
  `input:keypressed(k)` — i.e. reaches the widget (`UserInputController:keypressed`), which is
  exactly the mechanism the else-branch's `_cancel_default` call depends on for the editor's own
  widget instance.

- Enter/Escape handling by mode, all in `editorController.lua`:
  - **Normal mode** (`_normal_mode_keys`, starts `:507`): Enter → `newline()` (`:518-530`, Enter
    + Shift/Ctrl + not-Alt + empty-input inserts a block newline, calls `block_input()`); Enter →
    `submit()` (`:610-715`, Ctrl+Enter → `add`, plain Enter → `replace`, both via
    `self:_handle_submit(...)`); Escape → `load()` (`:716-727`, as above, no `block_input()`).
  - **Reorg mode** (`_reorg_mode_keys`, `:440`): Escape → `self:_reorg(false)` (`:441-442`);
    Enter → `self:_reorg(true)` (`:444-446`).
  - **Search mode** (`_search_mode_keys`, `:485`): Escape → `self:set_mode('edit')` +
    `self.search:clear()` + `return` (`:486-489`).

**Verdict: CONFIRMED.** This is the constraint: editor's normal-mode Escape has editor-owned
side effects (`load_selection`) but no `block_input()`, so it *also* reaches the widget's own
`_cancel_default` via the else-branch path — meaning **today's editor already relies on the
widget's non-editor cancel path firing underneath its own handling**, which is the crux
justifying why *some* branch-scoping exists at all (removing the `app_state` check outright
would need the editor branch to explicitly suppress or reconcile the widget's own
submit/cancel, not just delete the check).

### E.4 — `love.state.app_state`: every assignment and read site (`src/`)

**Assignment sites (file:line = value):**
| Site | Value |
|---|---|
| `src/main.lua:286` | `'starting'` (table-literal init of `love.state`) |
| `src/main.lua:319` | `'ready'` |
| `src/main.lua:36` | `'shutdown'` |
| `src/controller/consoleController.lua:261` | `'running'` |
| `src/controller/consoleController.lua:265` | `'project_open'` |
| `src/controller/consoleController.lua:280` | `'project_open'` |
| `src/controller/consoleController.lua:870` | `'running'` |
| `src/controller/consoleController.lua:1018` | `'inspect'` |
| `src/controller/consoleController.lua:1036` | `'snapshot'` |
| `src/controller/consoleController.lua:1067` | `'project_open'` |
| `src/controller/consoleController.lua:1093` | `'ready'` |
| `src/controller/consoleController.lua:1133` | `'project_open'` |
| `src/controller/consoleController.lua:1165` | `love.state.prev_state = love.state.app_state` (saves current value into `prev_state`, a *read* of `app_state`, write of `prev_state`) |
| `src/controller/consoleController.lua:1166` | `'editor'` |
| `src/controller/consoleController.lua:1188` | `love.state.prev_state` (restore) |
| `src/controller/controller.lua:768` | `'shutdown'` |

All 16 write sites live in exactly **three** files: `main.lua` (boot/shutdown lifecycle),
`consoleController.lua` (the overwhelming majority — console owns nearly every state
transition: run/stop project, inspect, snapshot, editor enter/exit), `controller.lua` (one
shutdown site). `userInputController.lua` itself never writes `app_state` — only reads it
(`:725`).

**Read sites:** every other `app_state` occurrence in the earlier grep output (≈35 more lines)
is a comparison/read — concentrated in `consoleController.lua` (mode gating for most console
commands, `'editor'` guard repeated at least 9 times: `:1201, :1239, :1305, :1321, :1336, :1348,
:1365, :1382, :1400`), `controller.lua` (routing dispatch, `:22, :711, :762, :781-782, :881-883,
:892, :910, :912, :958`), plus one read each in `view/input/statusline.lua` (`:15, :62`),
`view/input/userInputView.lua` (`:31, :33`), `view/consoleView.lua` (`:64`),
`harmony/scenarios/examples.lua:27` (an assert in test-scenario code), and the one under
discussion, `userInputController.lua:725`.

**Coupling read:** `app_state` is a single global (`love.state.app_state`), read in **8
different files** across controller/view layers, but **written from only 3** (console owns the
state machine almost entirely). `userInputController.lua` is one of many readers, not an
outlier in that respect — but it is the **only** reader among those three (main/console/
controller-owned writers) that is not itself a controller-for-a-route; it's the shared widget
reaching *up* into route-selection state to decide its own default-callback wiring, which is
exactly the "UIC should not be aware if application is in editor or non-editor mode" leak the
REVIEW at `:724` names.

---

## F. Suite baseline — CONFIRMED

`busted tests` →

```
827 successes / 0 failures / 0 errors / 4 pending : 2.349037 seconds
```

Exact match to the expected `827/0/0/4`. The 4 pending are all in
`tests/input/input_routing_spec.lua` (lines 80, 145, 158, 224) — pre-existing pending specs
(console key-release routing, editor pointer routing, editor-search key/text routing, project-run
touch routing), unrelated to the redesign's own ACs.

**Verdict: CONFIRMED.**

---

## DISCREPANCIES / SURPRISES

1. **`doc/development/decisions/input.md` was not resynced** and still describes the four-tier
   chain, framework handlers, the sink, the singleton, `on_key_pressed`/`on_text_input`/
   `on_key_released`, and the "proxy" term as *current* fact — in full, unqualified prose (not
   historical framing). This file is explicitly named in the S18 task's own corpus list (§B), but
   session17's report only claims resync of `input_api.md`/`internals/user_input.md`/
   `technical_debt/input.md`. The delta-design's own preamble frames this as deliberate
   ("unedited and still authoritative until this addendum is ratified" — the addendum's prose is
   meant to "fold in verbatim once ratified," not yet done). Net: not a code defect, but an
   unresolved **process** step (formal ratification + fold-in) that is easy to mistake for a
   completed resync if only session17's report is read. Orchestrator should confirm whether
   ratifying/folding-in `decisions/input.md` is a tracked open step or was dropped.

2. **The `lua-lsp` MCP `references`/`definition` tools returned fabricated results** for several
   of the deleted-symbol queries in `src/controller/projectInputController.lua` (`_generic_callback`,
   `_sink`, `run_hook`, `framework_submit`, `framework_cancel`, `shown_widget`) — line numbers
   beyond the file's actual length (158 lines; tool cited `L208`/`L209`), and `definition` results
   whose quoted context provably does not contain the queried symbol name at all. This persisted
   even after forcing a re-index via a `diagnostics` call on the same file (which itself returned
   correct, in-range results). Grep is unambiguous ground truth for section A; **this is a tooling
   reliability finding worth flagging to whoever maintains the MCP bridge**, independent of the
   redesign's correctness.

3. **E.3 finding worth surfacing explicitly to the orchestrator (not a contradiction of
   session17, but sharpens the crux):** the editor's own normal-mode Escape handling
   (`load()`, `editorController.lua:716-727`) does *not* call `block_input()`, so Escape already,
   today, falls through to the widget's own `_cancel_default` (else-branch path) underneath the
   editor's `load_selection()` side effect — i.e. the editor was already implicitly relying on
   the widget's non-editor cancel behaviour before this redesign, not something newly introduced
   by U3. This supports session17's "nothing is functionally broken" framing but confirms the
   `app_state` branch is load-bearing today, not just a smell — removing it without reconciling
   what the editor branch does NOT suppress would change editor Escape behaviour.

4. Everything else — sections A (via grep), B (src + 3 docs), C, D, E.1, E.2, E.4, F — matches
   the commissioning spec and session17's report exactly, including the precise line numbers
   session17/the task prompt cited (`:724`, `:725`, `:716`, `:803-804`).

---

## ORCHESTRATOR CORRECTION (session18, 2026-07-20) — E.3 interpretation is BACKWARDS

The worker's **factual** E.3 verification is correct and matches the open-issue doc (load() has no
`block_input()`; Escape passes through at :803-804 to `input:keypressed`; line numbers exact). But
its **interpretive conclusion** — "the editor already relies on the widget's non-editor
`_cancel_default` firing" (verdict E.3 + discrepancy #3) — is **wrong**, verified in code:

- The editor is entered by `consoleController.lua:1166` setting `love.state.app_state = 'editor'`
  (restored only at `:1188` `finish_edit`). So throughout editor use, `app_state == 'editor'`.
- Therefore when editor's Escape passes through to `input:keypressed`, the widget hits `:725`,
  takes the **editor branch**, which has **no** `_submit_default`/`_cancel_default` (those are in
  the `else` branch only, :752/:754).
- So the editor relies on `_cancel_default` **NOT firing** — exactly because `model:cancel()` would
  wipe the just-loaded selection from `load_selection()`. The `app_state == 'editor'` check exists
  precisely to *prevent* the widget cancel path for the editor, not to feed it. (Pre-U3 the point
  is even sharper: `_cancel_default` didn't exist at all — submit/cancel was the now-deleted tier-1
  `framework_submit`/`framework_cancel`.)

**Consequence for the options:** this *supports*, not undercuts, option B-proper. An instance flag
(editor's two UIC instances defer lifecycle keys) reproduces exactly what the editor branch does
today — skip `_cancel_default`/`_submit_default` — so B-proper is **behaviour-preserving**, not a
behaviour change. Discrepancy #3's closing clause ("removing the `app_state` check without
reconciling what the editor branch does NOT suppress would change editor Escape behaviour") is only
true of a *naive* deletion; B-proper does the reconciliation (the flag). Instance→branch mapping:
editor's 2 instances → defer=true (today's editor branch); console + project overlay → defer=false
(today's else branch), since only the editor ever runs under `app_state=='editor'`.
