# RS2 — annotate opaque interim refs for TF legibility — OUTCOME

_Sonnet worker, additive-only comment annotation. No commit made._
_Prompt of record: `validation/prompts/RS2-annotate-interim-prompt.md`._

## Result summary

- `busted tests`: **815 successes / 0 failures / 0 errors / 4 pending** — unchanged
  from the pre-existing baseline (comment-only edits, no `src/`/`tests/` logic touched).
- `mcp__lua-lsp__diagnostics` run on every edited `.lua` file: all reported diagnostics
  are pre-existing (duplicate-set-field / undefined-field / lowercase-global / etc., all
  on code lines untouched by this pass) — **no new diagnostics** introduced by the
  comment edits.
- Every `{badspecref: X}` ref and its wrapper is intact (verified by re-grep after
  editing — same ref strings present, only glosses/pointers added beside them).
- No `{jargon: ...}` tag touched. `doc A` and already-root-relative corpus refs
  untouched. No owner `REVIEW:`/`REVIEW/DOC:` remark edited.

---

## Phase 1 — decode-map (built before any edit)

| Ref | Site(s) (file:line, pre-edit) | Decoded meaning | SOURCE doc:line + quote | Persistent home |
|---|---|---|---|---|
| `A5` | `src/main.lua:365,376`; `src/controller/userInputController.lua:274,317` | M2-review agenda item A5 — singleton lifecycle & the `love.state.user_input` overlay-draw-flag contract (M/V/C constructed separately, controller parked in global state, whether that's a sane contract or should be refactored) | `implementation/reviews/M2-human-review.md:60-70` — "### A5 — Singleton lifecycle & the `love.state.user_input` draw contract (overlay flag contract) ▲ · `durable`... The biggest cluster. `M`/`C`/`V` are constructed separately in `main.lua`... **Decide:** document the contract as intentional, or refactor" | none pinned (still `open`, tracked in the M2 review doc itself) |
| `A8` | `tests/input/keys_pressed_spec.lua:5,47,61` | M2-review agenda item A8 — "test strategy: behaviour vs. internals (test the contract)" — many M2 tests assert implementation internals rather than observable behaviour; isolation/dedup gaps | `implementation/reviews/M2-human-review.md:88-98` — "### A8 — Test strategy: behaviour vs. internals (test the contract) ▲ · `durable`... Pervasive: many M2 tests assert **implementation internals**... rather than **observable behaviour**" | none pinned (`open`) |
| `A2` / `m4/m5 A2` | `src/controller/userInputController.lua:472` | M2-review agenda item A2 — whether the bottom text sink should also receive `keys_pressed` as a 2nd arg (modifier proxy); deferred to the M4/M5 dispatch design, resolved there (Decision 9) | `implementation/reviews/M2-human-review.md:62-70` — "### A2 — Passing `keys_pressed` to text handlers (modifier proxy) ▲ DEFERRED (0.1.0-m4/m5)... **To be resolved in the m4/m5 design session**, not settled now." | resolved by `doc/development/decisions/input.md`, Decision 9 (already cited inline at the site) |
| `M2-human-review.md` (bare refs) | `tests/input/keys_pressed_spec.lua:6,65`; `src/main.lua:366`; `src/controller/userInputController.lua:275,318` | Same doc as above; each bare ref ties to the A# tag in the same comment block (A8, A5) | (doc exists at path below) | `implementation/reviews/M2-human-review.md` (full repo path: `doc/development/wip/77-new-input-api/implementation/reviews/M2-human-review.md`) |
| `reviews/M4-0-04.md finding 1` | `tests/input/input_contracts_spec.lua:155` | Finding 1 of the M4-0-04 review: the claimed "sibling coverage" for keypressed-EXCLUSIVE across console/project/editor is **not actually there** — the editor row exercises `textinput`, not `keypressed`, so editor route had zero keypressed-EXCLUSIVE regression protection | `implementation/reviews/M4-0-04.md:60` — "## Finding 1 — editor keypressed EXCLUSIVE has no regression test (spec-completeness, non-blocking to merge but must close before M4)" | `implementation/reviews/M4-0-04.md` |
| `E30` | `tests/input/input_contracts_spec.lua:730,1158` | Cold architectural session (E30) resolving two escalated M5c contradictions: (a) route-restoration lexicon → binding concept is active route/mode, not slot restoration; (b) assign-replaces-capture → resolved to precedence-not-replace | `entrypoints.md:31` — "E30 \| **Cold architectural session — resolve two escalated M5c contradictions against frozen design**... ✓ Resolved (session37, 2026-07-07): **(a)** the frozen contract already speaks route/mode and is correct... **(b)** resolved to **precedence, not replace**" | `design/spec/M5c-dispatch-chain.md:108-124` ("Resolved (E30, session37...)" block) |
| `Scope-10(a)` / `Scope item 10(a)` | `tests/input/input_contracts_spec.lua:730,740` | Same E30 resolution (a) above, filed as M5c Scope item 10(a) — the disposition of the "stop names console as restored route" suite row | `design/spec/M5c-dispatch-chain.md:110-117` — "**(a) Route-restoration lexicon.** ... The landed `stop names the console as restored route` row is **retargeted to AC-29 teardown**..." | `design/spec/M5c-dispatch-chain.md` §"Resolved (E30...)" |
| `M5c-dispatch-chain.md` (bare) | `tests/input/input_contracts_spec.lua:738-739` | Second mention of the same design doc, same "Resolved (E30...)" section | (as above) | `design/spec/M5c-dispatch-chain.md` |
| `C23` *(found during Phase-1 research, not in the enumerated target list — same comment cluster as E30/Scope-10(a); glossed on the same-accuracy standard)* | `tests/input/input_contracts_spec.lua:743` | QUALITY-remark id from the M4 architect-pushback review: "no unconsumed public surface" — the `active_keyboard_route()` accessor is dropped because its only reader was this test row | `reviews/m4-architect-pushback.md:125` — "\| C23 \| `active_keyboard_route`: \"humans did not request it… not called from anywhere\" \| **QUALITY(nuanced)**..." | `reviews/m4-architect-pushback.md` (C23 row) |
| `spec §10` *(found during Phase-1 research, not in the enumerated target list — same style, same file)* | `tests/input/input_contracts_spec.lua:1731-1732` | `design/spec.md` §10 edge-case row: "Project stops while widget shown — silent hide; callbacks reset; no observable teardown event" | `design/spec.md:342-347` — "## §10 Edge cases ... **Project stops while widget shown** — silent hide; callbacks reset; no observable teardown event (the project is gone)." | `design/spec.md` §10 |
| `ratified-model ruling 3` | `tests/input/input_contracts_spec.lua:1679-1680` | Ratified-model ruling: the project's keyboard/text route connects only while `app_state == 'running'` | `design/notes/ratified-model.md:82` — "The project route (keyboard/text) is connected **only while `'running'`** (ruling 3); pointer natives remain slot-hooked until stop" | `design/notes/ratified-model.md` (ruling 3) |
| `ratified-model R11` | `tests/input/input_contracts_spec.lua:1774-1775` | Ratified-model remark R11: `inspect` is a mode→route line, nothing more — console route active, bound over the project env; project route disconnects | `design/notes/ratified-model.md:108-110` — "`inspect` is a mode→route line, nothing more (ruled R11): inspect = the **console route active, bound over the project environment**; project route disconnected" | `design/notes/ratified-model.md` (R11) — persistent-home pointer requested: `doc/development/decisions/input.md`, Decision 11/12 (already cited inline at both sites) |
| `M6-02` / `M6-02-before-exit.md` | `tests/input/input_contracts_spec.lua:1669,1791,1811` | Spec slice for `compy.before_exit` — project-stop lifecycle hook (Layer-1 fix for the T3 device-state leak); fires once on stop before framework cleanup, resets to noop after stop | `design/spec/M6-02-before-exit.md:1-24` — "# M6-02 — `compy.before_exit` project-stop hook ... specifies the `compy.before_exit` project-stop hook — the Layer 1 mechanism..." | `design/spec/M6-02-before-exit.md` |
| `M4-0-04.md finding 1` | (same as `reviews/M4-0-04.md finding 1` above) | — | — | — |
| `M7-01` | `tests/input/input_contracts_spec.lua:1991` | Supplementary slice closing the "active-session re-target boundary" — can a running session's `result` sink / evaluator be re-targeted? | `design/spec/M7-01-retarget.md:1-19` — "# M7-01 — close the active-session re-target boundary (supplementary slice)... An open boundary surfaced at M2 that **M7's own work forces a decision on**" | `design/spec/M7-01-retarget.md` |
| `M7-02-recut` | `tests/input/input_contracts_spec.lua:1994` | Re-cut M7 implementation target (Gate 3, E29) — extended widget-surface API: configure/clear/get_cursor/set_cursor/set_text; supersedes frozen `M7.md` | `design/spec/M7-02-recut.md:1-14` — "# M7-02 — extended widget-surface API (re-cut implementation target, E29 Gate 3)... **Supersedes `M7.md`** as the implementation target" | `design/spec/M7-02-recut.md` |
| `M8-01` | `tests/input/input_contracts_spec.lua:2226,2294`; `src/examples/{tixy,guess,valid,repl}/main.lua` | "M8-01 — in-repo example migrations — OUTCOME": the surprise-first ledger from migrating tixy/repl/guess/valid to the continuous-session idiom. Surprise #1: `after_submit` is a field-write on `compy.input`, NOT a `show{}`/`configure{}` merge key — passing it inside `show{...}` is silently dropped. Surprise #2: a prompt set via `configure()` inside `on_text_entered` must survive the bare `after_submit` re-show (model-sticky), not the show()-time prompt | `implementation/outcomes/M8-01.md:8-20` — "## What will surprise the architect (surprise-first) 1. **`after_submit` is a field-write, not a `show{}` key**..."; `:84` "across the `after_submit` re-show (surprise #2)." | `implementation/outcomes/M8-01.md` |
| `AC-17..26` | `src/controller/userInputController.lua:411` | Acceptance criteria range AC-17 through AC-26 in the M5c dispatch-chain spec — "Submit and cancel" cluster: Enter/Escape framework entries, validator reject/lock, `before_/after_submit`/`cancel` hook order, Shift+Return passthrough, `hide()`/`show({force=true})` semantics, continuous-session idiom, `oneshot` removal, hook defaults | `design/spec/M5c-dispatch-chain.md:215-243` — "**AC-17** Enter with the widget shown runs: `before_submit(keys_pressed)` → validator → on accept... **AC-26** All four hooks... default to..." | `design/spec/M5c-dispatch-chain.md` §"Submit and cancel" |
| `commit 7b4422c` | `src/view/input/userInputView.lua:292` | Real, unambiguous commit: `feat(uiv): render before draw on non-oneshot inputs` — a transitional workaround (quoted verbatim in the adjacent prose already) until per-frame rerenders are properly worked out | `git show --stat 7b4422c` — "feat(uiv): render before draw on non-oneshot inputs\n\nThis is a transitional workaround until rerenders are worked out." | n/a (git history is the source of record) |

**Milestone marks — assessed for the light-touch rule** (gloss only if the mark stands
alone with no adjacent explanation): `0.1.0-m2a` (`key.lua:15` — explained: "it was
previously a duplicate COMBO_MODS literal in controller.lua"), `M4`
(`input_contracts_spec.lua:333`(orig) — explained via the adjacent `{jargon: rewires the
handler slots}`), `0.1.0-mN` (`:718`(orig) — explained by the surrounding Bucket-B block
intro), `0.1.0-m5c` (`:773`,`:1649`(orig) — explained by the adjacent section headings),
`chunk 4` (`:1650`(orig) — same block), `0.1.0-m4` (`keys_pressed_spec.lua:64`(orig) —
"test-strategy pass"; `userInputController.lua:276`(orig) — "architect pass, not changed
here"), `0.1.0-m7` (`consoleController.lua:365` — "DEFERRED... unsettled..."). **All of
these already carry adjacent explanation → left untouched**, per the prompt's rule.

---

## Phase 2 — edits applied (file:line → gloss added)

All edits are comment-only, additive, keep every `{badspecref:}` wrapper intact.

### `tests/input/input_contracts_spec.lua`
- `:155` — added `— editor keypressed-EXCLUSIVE had zero regression coverage; see .../implementation/reviews/M4-0-04.md, "Finding 1"`
- `:730-747` block (E30/Scope-10(a)/M5c-dispatch-chain.md/Scope item 10(a)/C23) — added inline glosses: cold-session summary for E30/Scope-10(a); "same doc, same 'Resolved (E30...' section" for the repeat M5c-dispatch-chain.md/Scope-item-10(a) mentions; "QUALITY item, reviews/m4-architect-pushback.md" for C23
- `:1158` — added `— cold session resolving assign-replaces-capture to precedence-not-replace` beside `E30`
- `:1669` — added `— Layer-1 T3-leak restore hook spec, design/spec/M6-02-before-exit.md` beside `M6-02-before-exit.md`
- `:1679-1680` — added `— Gate-1 ratified-model.md: project route connects only while 'running'` beside `ratified-model ruling 3`
- `:1731-1732` — added `(design/spec.md §10 "Project stops while widget shown" row)` beside `spec §10`
- `:1774-1775` — added `— design/notes/ratified-model.md, "inspect is a mode→route line, nothing more"` beside `ratified-model R11`
- `:1791`, `:1811` — added `(design/spec/M6-02-before-exit.md)` beside both bare `M6-02` refs
- `:1991-1994` — added `(design/spec/M7-01-retarget.md: can an active session's result sink / evaluator be re-targeted?)` and `(design/spec/M7-02-recut.md, extended widget-surface API)` beside `M7-01` and `M7-02-recut`
- `:2226` — added `, implementation/outcomes/M8-01.md, surprise #1` beside `M8-01`
- `:2294` — added `(implementation/outcomes/M8-01.md)` beside `M8-01` (surprise #2 site)

### `tests/input/keys_pressed_spec.lua`
- `:5-7` — added `(M2 agenda A8, "test the contract": behaviour vs. internals)` beside `A8`, and `(implementation/reviews/M2-human-review.md)` beside the bare `M2-human-review.md` ref
- `:49` — added `— M2 agenda A8, test-the-contract theme` beside `A8`
- `:64-68` — added `(implementation/reviews/M2-human-review.md, agenda item A8)` beside the bare `M2-human-review.md` ref

### `src/main.lua`
- `:365-370` — added `(M2 agenda A5, singleton lifecycle / overlay-draw-flag contract)` beside `A5`, and the repo-root-relative path beside the `M2-human-review.md` ref
- `:380` — added `— M2 agenda A5` beside the second `A5`

### `src/view/input/userInputView.lua`
- `:292-294` — added `— "feat(uiv): render before draw on non-oneshot inputs"` beside `commit 7b4422c` (verified unambiguous via `git show --stat`)

### `src/controller/userInputController.lua`
- `:274-277` — added `(M2 agenda A5, singleton lifecycle contract; ...)` beside `A5`, root-relative pointer beside `M2-human-review.md`
- `:319-322` — same pattern for the second `A5`/`M2-human-review.md` pair (at `hide()`)
- `:411-413` — added `— design/spec/M5c-dispatch-chain.md, submit/cancel acceptance criteria` beside `AC-17..26`
- `:472-474` — added `— M2 agenda A2, keys_pressed-as-2nd-arg to text handlers, closed by M4/M5 dispatch design` beside `m4/m5 A2`

### `src/examples/tixy/main.lua`, `src/examples/guess/main.lua`, `src/examples/valid/main.lua`, `src/examples/repl/main.lua`
- Each file's `Continuous-session idiom ({badspecref: M8-01})` header — added `— implementation/outcomes/M8-01.md, example migrations`

No edits to: `src/util/key.lua` (milestone, adjacent-explained, left per rule);
`src/controller/consoleController.lua:365` (`0.1.0-m7`, adjacent-explained, left).

---

## FLAGGED — not edited, for owner disposition

| Ref | Site | Why flagged |
|---|---|---|
| empty `{badspecref:}` | `tests/input/input_contracts_spec.lua:76` | Not itself a ref — it's the owner's `REVIEW/DOC:` meta-comment describing the wrapping convention ("I will wrap them into `{badspecref:}` wherever I see them"). Left untouched per both the "don't edit REVIEW: remarks" rule and because there's nothing to decode. |
| `{badspecref: #77's blast radius}` | `tests/input/input_contracts_spec.lua:175` (orig `:172`) | Feature self-reference / vague wording, not a pointer to an ephemeral doc — matches the prompt's explicit flag list verbatim. |
| `{badspecref: this feature}` | `tests/input/input_contracts_spec.lua:180` (orig `:177`) | Same — feature self-reference, not an ephemeral-doc ref. |
| `{badspecref: #77}` | `src/controller/userInputController.lua:493` (orig `:486`) | Same — feature self-reference ("_G.web... not part of #77"). |
| `{badspecref: commit 7b4422c}` | `src/view/input/userInputView.lua:292` | **Resolved, not flagged** — `git show --stat 7b4422c` was unambiguous (single commit, one-line summary matching the adjacent quoted text exactly); glossed in Phase 2. Listed here only because it was in the prompt's FLAG bucket as conditional. |
| `{badspecref: m7 design session}` | `src/controller/consoleController.lua:368` | Could **not** be pinned to a specific document. A prior sweep (`implementation/sessions/session08/cosmetic-a.md:65`) already looked for this and concluded: *"`0.1.0-m7`, `m7 design session`, `M7` — `doc/input_api.md` §'Live reconfigure…' (the M7 feature, already landed) — drop the milestone id itself"* — i.e. no discrete "m7 design session" artifact exists; the only landed trace is the general M7 feature doc. Per the prompt's own instruction ("gloss if locatable in `design/`, else flag"), this is flagged rather than guessed. |

---

## Notes for the reviewer

- Two refs were found during Phase-1 research that weren't in the prompt's enumerated
  target list but sit in the exact same comment clusters as enumerated E30/Scope-10(a)
  refs and were decodable with the same source-quote rigor: `C23`
  (`input_contracts_spec.lua:743`) and `spec §10` (`:1731-1732`). Both are glossed in
  Phase 2 and fully sourced in the decode-map above — flagging for your awareness in
  case you want a second look, since they were outside the original inventory.
- Line numbers in the "Phase 2" section are **post-edit** (current file state); the
  decode-map table uses **pre-edit** line numbers where noted `(orig)`, matching the
  prompt's original grep inventory, to make cross-checking against the prompt easier.
