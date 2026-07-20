# R4/U4 — vocabulary sweep + example migration + docs (outcome)

**Task of record:** `validation/prompts/R4-U4-sweep-docs.md`. Sources read in full before
touching anything: `delta-design-input-api.md`, `delta-spec-input-api.md`,
`R4-U3-callback-model.md`, and the shipped `src/controller/{projectInputController,
userInputController,consoleController,controller}.lua`, `src/main.lua`.

## Sub-step 1 — Example migration (behavioral)

Files touched: `src/examples/{guess,tixy,valid,repl}/main.lua`. `balloons`/`maze` untouched
(confirmed both excluded per prompt; `balloons` is a nested untracked repo — see "Flagged"
below).

| Example | Old idiom | New idiom chosen | Rationale |
|---|---|---|---|
| `guess` | `after_submit`/`after_cancel` both re-show bare | `callbacks.after_submit = clear()`; `after_cancel` **removed entirely** | Intent (comment + code): fresh empty guess each round. Clear-per-submit covers that; cancel's own new default (clear + stay open) already re-arms the prompt, so nothing left for `after_cancel` to do. |
| `valid` | `after_submit` re-shows bare | `callbacks.after_submit = clear()` | Same fresh-empty-line-per-submit intent as `repl`/`guess`. |
| `repl` | `after_submit` re-shows bare | `callbacks.after_submit = clear()` | Echo loop — fresh line each round. |
| `tixy` | `after_submit`/`after_cancel` both re-show with `text=string.lines(body)` | `after_submit` **removed entirely**; `after_cancel = callbacks.after_cancel` calling `compy.input.set_text(string.lines(body))` | Submit no longer clears the field and the widget stays open, so the just-submitted body is already sitting in the field — nothing to re-inject. Cancel's own default DOES hardwire a clear, so (unlike submit) `after_cancel` still needs to restore the last-good body via the live `set_text` method — the old re-show-with-text idiom doesn't apply post-redesign (a `show()` over an already-shown widget is a suppressed no-op that ignores `text` without `force`), so `set_text` is the correct live-content-replace primitive for this one case. |

All four leaf renames applied (`compy.input.after_submit`/`after_cancel` → `compy.input.callbacks.
after_submit`/`after_cancel`); `show{}` config-table keys (`on_text_entered`, `eval`, `prompt`)
left flat, unchanged, per instructions. Verified via `luajit -e "loadfile(...)"` (no `luac`
binary in this image) — all four parse clean. Examples are not suite-covered; no busted test
exercises them.

**Nothing flagged as unclear** — each example's own comments stated its intent plainly enough to
pick a shape confidently.

## Sub-step 2 — Vocabulary sweep (src comments, complete-or-nothing)

Files touched: `userInputController.lua`, `projectInputController.lua`, `controller.lua`,
`consoleController.lua`, `userInputModel.lua`, `userInputView.lua`, `key.lua`, `main.lua`.

Before/after counts (grep, `src/`, excluding `love.handlers`/`project_natives`/
`keyboard_native`/`natives`):

| term | before | after |
|---|---|---|
| `singleton` (input-related; `Range.singleton` etc. excluded as genuinely different meaning) | 15 | 0 |
| `sink` | 2 | 0 |
| `tier`/`tier-N`/`four-tier` | 17 | 0 |
| `framework handler(s)` | 8 | 0 |
| `generic callback` | 1 | 0 |
| `proxy` (held-key role; `util/table.lua`'s own generic protect-table `proxy` locals and the
  `balloons/LICENSE` text are a genuinely different meaning, left alone) | 4 | 0 |

Notable non-mechanical fixes made along the way (stale prose caught mid-sweep, not just
find/replace):
- `userInputController.lua`'s `:cancel()` docstring described the OLD framework-tier-1 escape
  path calling it; rewritten — that method is now dead for the project widget (Escape runs
  `_cancel_default`) and survives only as console's own debug/test-mode cancel.
- `consoleController.lua`'s `build_widget_api` preamble (lines ~502-509) was leftover
  pre-rename prose (`four-tier`, `handlers.<event>`, `tier-3 generic callbacks`) sitting directly
  above already-correct prose one paragraph below — rewritten to describe the shipped
  `shortcuts`/`hooks` model.
- `userInputController.lua:521`'s `--- @return boolean? limit` LDoc annotation was stale —
  `keypressed` has had no return value since Decision 5 revised retired the limit-flag channel.
  Removed, with a one-line note pointing at `on_limit_reached`/`emit_limit`.
- "Native" disambiguated per the design's rule: `project_natives`/`keyboard_native`/the `natives`
  parameter kept verbatim (capture-path names); the one *role* usage ("native... chain
  participants... a native can consume") in `controller.lua`'s `project_natives` docstring was
  rewritten to "seeded as hooks[event]"/"a seeded hook".
- `love.handlers` occurrences (gateway's own real table) confirmed untouched everywhere.
- No stray "hook" used for submit/cancel (`run_hook` etc.) found anywhere in `src/` — the
  migration hazard the delta-design flagged was already fully resolved by U1-U3.

`busted tests` run after this sub-step: **827/0/0/4** (unchanged).

## Sub-step 3 — main.lua REVIEW disposition

`src/main.lua` (~line 355, the `REVIEW: why could not (or should not) Concols/Editor be rewired
to use the same singleton?` note) replaced with a 6-line dispositioned comment: the reusable seam
now exists (free-function `dispatch` + `build_widget_api` factory), but multiple
`UserInputController` instances remain required because console's `inspect`-mode REPL state must
persist independently of the project's (Decision 12), so migration stays deliberately deferred
(Decision 1) — matching `R4-U3-callback-model.md`'s Implementation-note language exactly.

Cross-checked against the R4-1 inventory's full "resolved-by-redesign" list (8 items, not just
the `main.lua` one): the other 7 (`controller.lua:325`, `userInputController.lua:434/480/482/
669/685/687`) were all REVIEW comments attached to code that U1-U3 already deleted outright
(`_sink`, the old tier-1 duplication, the old UIC-external submit/cancel split, the old
noop-vs-nil teardown check) — none of that text is present in current `src/` any more (verified
by grep). `main.lua:355` was the only one still standing because it was attached to a comment
block, not deleted code.

## Sub-step 4 — Persistent docs updated

- **`doc/development/internals/user_input.md`** — substantial rewrite: the "Data flow" diagram
  and prose (four-tier → three-consumer walk, `handlers`/`on_*` → `shortcuts`/`hooks`); the full
  "Keyboard Handling" dispatch-chain diagram and surrounding prose; the stale "limit reached"
  paragraph rewritten to describe console's *actual* current mechanism (`on_limit_reached`
  wired at `ConsoleController.new`, not a captured return value — the old
  `local limit = input:keypressed(k)` line no longer exists in `consoleController.lua`); the
  "Editor-specific keys" inner-fork paragraph and "UserInputController keypressed (shared)"
  section rewritten to describe the actual `_submit_default`/`_cancel_default` mechanism (see
  "Flagged" below re: one factual correction against `R4-U3-callback-model.md`); the whole
  "Submit and cancel" section renamed to **"Submit and cancel — widget-owned callback
  sequences"** and rewritten around the shipped model (stays-open default, `before_cancel` veto,
  Enter/Escape shadowable, `compy.input.callbacks` IS `self.callbacks`); the `compy.input`
  namespace bullet list and "Key Files" table updated to `shortcuts`/`hooks`/`callbacks`
  vocabulary. All in-code doc-heading citations across `src/` (the `"Submit and cancel — the
  framework tier-1 chains"` quotes in `userInputController.lua`/`userInputModel.lua`/
  `userInputView.lua`) were updated in lockstep to the new heading text.
- **`doc/input_api.md`** — full rewrite (same structure/headings, all content resynced): Quick
  start now shows the migrated `repl` code; the submit lifecycle section describes the
  stays-open default and the `after_submit`/`before_cancel`-veto behaviour; "Two callback
  families" updated to the `compy.input.callbacks.X` leaf-write shape; the whole "continuous-
  session idiom" section rewritten around `clear()`/`configure{prompt=...}`/removal instead of
  bare re-show; the `guess`/`tixy` inline code samples updated to match the migrated examples;
  "Combo key handlers" renamed/expanded into "Combo key handlers" (`shortcuts`) + a new "The
  `hooks` table" section; API reference tables retitled to `shortcuts`/`hooks`/`callbacks`.
- **`doc/development/technical_debt/input.md`** — marked RESOLVED with one-line-pointer history
  (not deleted): `_generic_callback` re-resolution (→ Decision 10 revised, one seeded-once
  `hooks[event]` table); `submit()`'s deliver-then-hide reshow trap (→ auto-close is gone,
  nothing to reshow); `Widget sink reaches the singleton via love.state` (→ RESOLVED-IN-PART:
  the sink is gone, `dispatch` takes the widget as a parameter; the remaining nil-guard/global
  read moved up one layer to `_dispatch`, left open at that new site). Vocabulary-only fixes
  (still-open entries, unresolved by the redesign, renamed in place): "Combo-tier key-repeat
  semantics" → "Shortcuts key-repeat semantics"; "A truthy tier-3 return silently disables
  on_limit_reached" → "A truthy `hooks[event]` return..."; pointer-chain and held-key-proxy
  entries reworded to `shortcuts`/`hooks`/`pressed-keys view`. Historical narrative that
  necessarily names the retired terms as *history* (e.g. "renamed from tier-3/tier-4 to
  hooks/widget") was left as-is, per "do not delete history."

## Sub-step 5 — Gate self-check

**Suite:** `busted tests` → **827 successes / 0 failures / 0 errors / 4 pending** (confirmed
after every prior sub-step and again at the end — unchanged throughout).

**Retired code symbols (must be zero):**
```
grep -rn "framework_handlers|install_tier1|framework_submit|framework_cancel|shown_widget|run_hook|_generic_callback|\b_sink\b|_is_hidden_overlay" src/
→ ZERO HITS (grep exit code 1)
```
LSP cross-check attempted (`mcp__lua-lsp__references`) per instructions, with the required
`sleep 1` after edits — but the LSP's results were **not trustworthy** for this gate: probing a
symbol that genuinely still exists (`seed_hooks`, defined at line 43 of a 158-line file) returned
a "reference" at line 222 — past the end of the file — and `mcp__lua-lsp__definition` returned
"not found" for `ProjectInputController._dispatch`, a real method. This looks like a stale/
mismatched index rather than a real result, so I did not rely on the LSP's specific line numbers;
the grep zero-hit result above is treated as authoritative (per the standing "grep confirms you
missed none" backstop guidance), cross-checked manually by re-reading every touched file's
current content.

**Retired prose terms** (grep `src/`, excluding `love.handlers`/`project_natives`/
`keyboard_native`/`natives`): `singleton`, `\bsink\b`, `tier`, `framework handler`,
`generic callback`, `\bproxy\b` → **all zero**, no exceptions left in place (see Sub-step 2 table
above for before/after counts and the two genuinely-different-meaning exclusions:
`Range.singleton` (an unrelated interval-math helper) and `util/table.lua`'s own generic
protect-table `proxy` locals / `balloons/LICENSE`'s GPL boilerplate).

**Un-dispositioned "resolved" REVIEW:** none remain — see Sub-step 3.

## Flagged for the reader (not blocking, not guessed at)

1. **`src/examples/balloons/*` is untracked, sanctioned scratch with its own nested `.git`, and
   is now stale against the shipped API.** `balloons/terminal.lua` still does
   `compy.input.after_submit = function() compy.input.show({}) end` — a **direct top-level
   field-write**, which the frozen `compy.input` container's `__newindex` now rejects
   unconditionally for *any* key (not routed through `.callbacks`). Running balloons today would
   throw at that assignment. Out of scope per the prompt (balloons explicitly excluded from
   migration) — flagging since `doc/input_api.md` used to cite balloons' code as a "verbatim"
   example; I've re-labeled that citation to make clear it shows the *migrated* shape, not an
   actual quote, rather than silently keep an inaccurate "verbatim" claim.
2. **`R4-U3-callback-model.md` describes an `_is_overlay()` gate that does not exist in the
   shipped code.** The design doc says submit/cancel-default should be "gated on
   `self:_is_overlay()`," but the actual `UserInputController:keypressed` only branches on
   `love.state.app_state == 'editor'` — there is no per-instance overlay-identity check. In
   practice this means console's own always-shown widget instance *also* runs
   `_submit_default`/`_cancel_default` on its own Enter/Escape (harmlessly, since console sets no
   before/after callbacks — verified by reading `ConsoleController.new`/`:keypressed`). Per
   CLAUDE.md's "code wins on facts" rule, `user_input.md` was written to describe this actual
   mechanism rather than the unbuilt `_is_overlay()` gate, with an explicit "Note" callout so the
   drift is visible rather than silently papered over. Not a behavior change on my part — purely
   a documentation-accuracy call.

## Files touched
`src/examples/{guess,tixy,valid,repl}/main.lua`,
`src/controller/{userInputController,projectInputController,controller,consoleController}.lua`,
`src/model/input/userInputModel.lua`, `src/view/input/userInputView.lua`, `src/util/key.lua`,
`src/main.lua`, `doc/development/internals/user_input.md`, `doc/input_api.md`,
`doc/development/technical_debt/input.md`. No `src/` behavior changed; no test file touched.
