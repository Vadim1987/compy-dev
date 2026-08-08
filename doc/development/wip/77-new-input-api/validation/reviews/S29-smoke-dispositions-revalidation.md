# S29 — revalidation of the SM1–SM5 smoke-finding dispositions

Sub-agent, read-only, per
`doc/development/wip/77-new-input-api/validation/prompts/S29-smoke-dispositions-agent.md`.
Checked against `feature/77-newapi-analysis-s20260615`, HEAD `e1e5e740`. Question
throughout: does the code say what
`doc/development/wip/77-new-input-api/validation/notes/S28-smoke-findings.md`
("the note") says it says. One mutation performed (SM4), restored from a `/tmp`
copy before continuing; everything else is reading.

---

## SM1 — paint, right-click does nothing. Ruled not a defect.

- **CONFIRMED** — paint binds only `hooks.singleclick`/`hooks.doubleclick`, no
  `mousepressed`. `src/examples/paint/main.lua:356-361`:
  `compy.input.hooks.singleclick = function(x, y) point(x, y, 1) end` /
  `hooks.doubleclick = function(x, y) point(x, y, 2) end`. `grep -n
  "mousepressed" src/examples/paint/main.lua` → no match.
- **CONFIRMED** — the click timer counts left-button releases only.
  `src/controller/controller.lua:936-938`: `handlers.mousereleased = function(x,
  y, btn, touch, presses) if btn == 1 then click_count = click_count + 1 ...`.
- **CONFIRMED** — `btn` in `setColor`/`useCanvas` is paint's own literal, not a
  framework-supplied value. `main.lua:298` (`setColor(x, y, btn)`, branches on
  `btn == 1`/`btn > 1`), `main.lua:325` (`useCanvas(x, y, btn)`, branches on
  `btn == 1`/`btn == 2`); both literals (`1`, `2`) are written at the two hook
  bindings above, and the hooks themselves receive only `(x, y)` from the
  framework.
- **CONFIRMED** — the right button is used on the drag path.
  `main.lua:364-374`: `love.mousemoved` loops `for btn = 1, 2 do if
  love.mouse.isDown(btn) then useCanvas(x, y, btn) end end`.
- **CONFIRMED** — base-commit comparison. `git show
  3256aac:src/examples/paint/main.lua`: click path bound `function
  compy.singleclick(x, y) point(x, y, 1) end` / `compy.doubleclick` identically;
  same `btn` 1/2 literals in `setColor`/`useCanvas`; no `mousepressed`; drag path
  byte-identical. Right-click did nothing at the base too.
- **CONFIRMED** — the technical-debt entry exists and says what the note
  claims. `doc/development/technical_debt/input.md:1148-1217`, "paint's
  `useCanvas(btn)` means a mouse button on one path and a click count on the
  other (pre-existing)" — states the two-meanings-of-`btn` trap, the "not a
  receiver misreading a sent value" point, the pre-existing-not-migration
  claim, the "why not simply bind the button" reasoning (Decision 27), the
  owner's ruling not to change paint, and the three numbered recommendations
  for whenever paint is next opened.

No findings on SM1. All five premises hold.

---

## SM2 — sapper, inert console prompt under the game. Ruled keep.

- **CONFIRMED** — sapper defines no `love.draw`. `grep -n "love\.draw"
  src/examples/sapper/main.lua` → no match (only file in that directory besides
  `README.md`).
- **CONFIRMED** — the gateway replaces the console draw path only when a
  project supplies its own `love.draw`. Lives inside `set_love_update`'s
  update closure (not a separately named function, but exactly the site the
  note cites): `src/controller/controller.lua:590-607`. `local ldr =
  love.draw` (the project's current handler) compared against `View.prev_draw`
  (the console's own default draw closure); only `if ldr ~= ddr` does
  `love.draw` get reassigned, and the reassignment wraps `ldr` itself
  (`wrap(ldr, CC)`), not `View.draw`. A project that never assigns its own
  `love.draw` leaves `ldr == ddr`, so the console's draw path (which calls
  `View.draw(CC, CV)` → `CV:draw(...)`) stays installed.
- **CONFIRMED** — `ConsoleView:draw` paints the input strip whenever the
  screen mode is not `editor`. `src/view/consoleView.lua:43-70`: `if
  love.state.app_state == 'editor' then drawEditor() else drawConsole() end`,
  and `drawConsole` (line 48-57) calls `self.input:draw()` gated by
  `ViewUtils.conditional_draw('show_input')`. Nuance not in the note:
  `conditional_draw` (`src/util/view.lua:57-62`) returns `true` unconditionally
  when `love.DEBUG` is false (the normal case) — so in the default,
  non-debug run the note's simplification is exactly right; it only softens
  under `love.DEBUG` + an explicit `show_input` toggle-off
  (`controller.lua:527`, `table.toggle(love.debug, 'show_input')`), which
  doesn't touch the disposition.
- **CONFIRMED (verified precisely, not just read)** — the fixture stubs
  `view.view` wholesale, and `ConsoleView:draw` is exercised by no row.
  `tests/helpers/input_fixture.lua:13-22`:
  `package.preload['view.view'] = function() View = { ..., draw = function()
  end, ... } end`, set before any other require in the fixture. The only call
  site of `View.draw` in `src/` is `controller.lua:652` (`View.draw(CC, CV)`,
  inside `set_love_draw`), which the stub turns into a no-op — so `CV:draw`
  (`ConsoleView:draw`) is never reached from that path in tests. `grep -rln
  "ConsoleView" tests/` → only `tests/helpers/input_fixture.lua`, in a comment
  (`-- view.view stub: ...`), never a direct instantiation or call. No spec
  file references `ConsoleView`.

No findings on SM2. All premises hold, including the harder-to-verify fixture
claim.

---

## SM3a — maze nav glyphs after a project→project transition. Left open.

- **CONFIRMED** — no explicit font or graphics-state reset exists on the path
  from `stop_project_run` to the next run's start.
  `src/controller/consoleController.lua:1349-1361` (`stop_project_run`):
  `evacuate_required`, `framework_before_exit`, `set_default_handlers`,
  `set_love_update`, `hide_overlay`, `View.clear_snapshot`, `set_love_draw`,
  `clear_user_handlers`, `report` — none touches a font or `love.graphics`
  state. `close_project` (`consoleController.lua:1308-1325`) calls
  `_reset_executor_env` (`:1183-1185`, rebuilds `project_env` from
  `table.clone(self.base_env)`, no graphics call), `self.model.output:clear_canvas()`,
  `View.clear_snapshot()`, sets `app_state = 'ready'` — no font/graphics reset
  either. `grep -rn "setFont\|newFont\|getFont" src/controller/ src/main.lua`
  → only `controller.lua:664` (`gfx.setFont(CC.cfg.view.font)`, inside
  `View.end_draw`) and `main.lua:51-67,389` (one-time boot font creation /
  initial `gfx.setFont`). `grep -rn "end_draw" src/` confirms `View.end_draw`
  is assigned once (`controller.lua:661`) and called from exactly one site
  (`controller.lua:687`), on the quit path — never on an ordinary
  project-to-project transition.
- **Note change confirmed**: `git diff --stat` shows nothing under
  `src/controller/consoleController.lua` or `src/controller/controller.lua`;
  nothing was altered for this finding, consistent with "left open."

No findings on SM3a. The negative claim holds as stated.

---

## SM3b — maze, "Ctrl dims the screen". Ruled explained, no change.

- **CONFIRMED** — the dim overlay is Shift-gated by design.
  `src/examples/maze/macro.lua:5-8` (`SHIFT_KEYS = { lshift = true, rshift =
  true }`), `:72-83` (`handle_key`: the only branch touching `shift_held` is
  `if SHIFT_KEYS[k] then macro_state.shift_held = true`), `:87-92`
  (`release_shift`: `if SHIFT_KEYS[k] then macro_state.shift_held = false`).
  `src/examples/maze/graphics.lua:344-346`: `if macro_state.shift_held then
  draw_dim() end` — the only call site of `draw_dim` (`graphics.lua:317-321`).
- **CONFIRMED** — no path ties it to Ctrl. `grep -rin "ctrl"
  src/examples/maze/*.lua` → only `keyboard_graphics.lua:125,260` (a cosmetic
  on-screen key-cap label, `key("lctrl", "Ctrl")`) and the
  `ctrl_pressed`/`ctrl_update` *variable names* in `controls.lua`/`main.lua`
  (per-level control-mode callbacks — `controls.lua:11` sets `ctrl_pressed =
  handle_key` for the `keys()` control mode; `main.lua:568-578` calls
  `ctrl_pressed(k)` for any non-system key, Shift included, regardless of the
  physical Ctrl key). No `SHIFT_KEYS`-equivalent table or branch exists for
  Ctrl anywhere in `macro.lua`.
- **CONFIRMED** — nothing in the platform dims anything. `grep -rn "dim\b\|Dim\b"
  src/controller/ src/view/ src/util/ src/main.lua` → no output.

No findings on SM3b. Both halves hold.

---

## SM4 — keyboard, Ctrl+Alt+arrow. Ruled not a platform defect; a row added.

### Mutation check (rules followed: copied to `/tmp` first, restored, never
`git checkout --`/`restore`/`stash`)

- Backup: `cp /repo/src/util/key.lua
  /tmp/claude-1000/-repo/7df95d55-3cb7-48c8-9fcc-af9f345cc2ac/scratchpad/key.lua.orig`;
  `md5sum` of both matched before mutating
  (`0f430eb0251e88c2eb895f7d6287bcf0`).
- Baseline: `busted tests` → `955 successes / 0 failures / 0 errors / 3
  pending` (matches the brief's stated baseline).
- **Mutation**: `src/util/key.lua:30`, `local mod_order = { 'ctrl', 'alt',
  'shift', 'gui' }` → `local mod_order = { 'alt', 'ctrl', 'shift', 'gui' }`.
  This is the exact mutation the note describes: `mod_order` feeds
  `normalize_combo` (registration-time canonicalisation, `key.lua:66-74`),
  while dispatch's `combo_string` (`controller.lua:395-404`) walks `COMBO_MODS
  = Key.mod_triples` (`controller.lua:382`) — a *separate* table
  (`key.lua:16-21`) left untouched by this edit — so registration and dispatch
  now canonicalise two-modifier combos in different orders.
- **Result**: `busted tests/input/input_events_spec.lua` →
  `86 successes / 3 failures / 0 errors / 0 pending`. Failing rows (exact
  titles):
  1. `input surface: inbound events — dispatch #input the combo registration
     contract accepts a trigger, a combo, and a class` (`input_events_spec.lua:336`)
  2. `input surface: inbound events — dispatch #input combo classes a
     two-modifier combo fires on the real chord` (`input_events_spec.lua:411`)
     — **this is the SM4 pin row**, and it does fail as the note says.
  3. `input surface: inbound events — dispatch #input combo classes the class
     handler receives the real trigger` (`input_events_spec.lua:425`)
- **Restore confirmed**: copied the `/tmp` backup back over
  `src/util/key.lua`; `git diff --stat -- src/util/key.lua` → empty; `md5sum`
  matches original again. Re-ran `busted tests` → `955 successes / 0 failures
  / 0 errors / 3 pending` (back to baseline).

### FINDING — a different (additional) row fails than the note's framing implies

The note says the mutation "fails it" (the pin row, singular), and separately
that "nothing in the suite could previously catch [the asymmetry]: the
neighbouring rows bind one modifier plus a trigger, or two modifiers plus the
class marker" — i.e., it characterises the "two modifiers plus the class
marker" shape as *not* a prior catch for this failure mode.

Under the actual mutation, row 3 above —
`input_events_spec.lua:425`, "the class handler receives the real trigger",
exactly the "two modifiers plus the class marker" shape the note names — also
fails, and it is **not new**: `git log -1 --format=%H -S"the class handler
receives the real trigger" -- tests/input/input_events_spec.lua` →
`edb6321bce5657b53f6b31ac35aac26dc04d4dfc`, dated 2026-08-03, four days before
the SM4 pin commit `73dae3f5` (2026-08-07). `git merge-base --is-ancestor
edb6321b 73dae3f5` confirms `edb6321b` is an ancestor (older). Mechanically,
row 425 fails for the identical reason row 411 does: `find_shortcut`'s class
lookup (`src/controller/projectInputController.lua:101-111`) builds its key
via `Controller.combo_string('*', keys)` — using the unmutated `COMBO_MODS`
order — while the class binding itself was stored under `normalize_combo`'s
mutated order at registration, so the two spellings ('ctrl+alt+\*' vs
'alt+ctrl+\*') no longer match.

Row 1 (`:336`) fails for a related but distinct reason: it does a direct table
read (`sc['ctrl+alt+s']`), and `Key.new_handler_table` only normalises on
*write* (`__newindex`, `key.lua:111-118`) — there is no `__index` — so this
row pins the literal spelling `normalize_combo` produces, not a
registration/dispatch match. It would also fail under a *self-consistent*
reordering of both `mod_order` and `mod_triples` together (i.e. it isn't
proof of the specific asymmetry), unlike rows 411 and 425.

**Net effect on the disposition**: the pin row does fire as claimed (row 411
fails as stated), so SM4's core empirical claim is not undermined. But the
note's supporting claim that the pre-existing suite had no row shaped to catch
this — "the neighbouring rows bind one modifier plus a trigger, or two
modifiers plus the class marker" (implying the class-marker shape doesn't
catch it) — is not accurate: a pre-existing class-marker row already would
have failed on this exact mutation, four days before the SM4 commit. This
doesn't change "not a platform defect," but it means the coverage-gap framing
("nothing in the suite could previously catch it") overstates the gap by one
row.

- **CONFIRMED** — no other row in the suite binds an exact two-modifier
  chord. `grep -rn "sc\[\|shortcuts\.\(keypressed\|mousepressed\|mousemoved\)\[\|bind_class("
  tests/input/*.lua tests/helpers/*.lua | grep -iE "'[a-z0-9]+\+[a-z0-9]+\+"`
  → only `:318` (`'ctrl+a+b'`, a rejection test), `:325` (`'a+b+*'`, a
  rejection test), `:340/341/343/344` (`'Ctrl+Alt+S'`/`'ctrl+alt+*'`,
  acceptance-only, discussed above), `:414` (the pin row, exact chord),
  `:427` (the class-marker row, discussed above). Confirmed: no row besides
  411 drives an *exact* two-modifier chord end to end — that half of the
  note's framing is correct even though the "class marker" half is not.

---

## SM5 — keyboard, subgame 4 accepts no glyph. Fixed in the nested repo.

Nested repo (`src/examples/keyboard`) confirmed on commit `3a9d48c` (`git -C
src/examples/keyboard log --oneline -1`), clean (`git -C
src/examples/keyboard status --porcelain` → empty). Read only inside it, no
git write commands run there.

- **CONFIRMED** — `inputStale` (the old, buggy mechanism) is gone.
  `grep -rn "inputStale" src/examples/keyboard/*.lua` → no match. `git -C
  src/examples/keyboard show 3a9d48c` confirms the diff: `inputStale` removed
  from `input.lua`, replaced by `spendGlyph`/`GLYPH_CLAIMED`; `alt.lua:173`
  now calls `spendGlyph(altBaseKey(ch))` where it called `inputStale(...)`
  before.
- **CONFIRMED** — the platform documents no ordering guarantee between
  `keypressed` and `textinput`. `doc/development/internals/user_input.md:56`:
  "(LÖVE2D does not guarantee the relative *order* the two arrive in for the
  same physical key.)"
- **CONFIRMED** — the claim mechanism as described: "a glyph is claimed, one
  per press, released at keyup." `src/examples/keyboard/input.lua:154-160`
  (`spendGlyph`): `if GLYPH_CLAIMED[k] then return true end`, checks the
  post-release grace window, else `GLYPH_CLAIMED[k] = true; return false`.
  `input.lua:177-183` (`appKeyreleased`): `GLYPH_CLAIMED[k] = nil` on every
  key release.
- **CONFIRMED** — the key-cap renderer reads the held set live at draw time,
  unaffected by the claim mechanism. `src/examples/keyboard/alt.lua:228-240`
  (`altHintReady`/`altHintDeco`): read `INPUT.shift` directly (`input.lua:58`,
  `modHeld("lshift","rshift")` against `compy.input.keys_pressed`), no
  `spendGlyph`/`GLYPH_CLAIMED` involvement.

### FINDING — the fix's "same answer in both orders" claim does not extend to
a third, undocumented-but-unexcluded ordering: `textinput` arriving after its
own `keyreleased`

The header comment (`input.lua:30-33`) and commit message both frame the fix
as answering "has this key's glyph been judged since its last release... the
same answer in both orders" — where "both orders" means
keypressed-before-textinput vs. textinput-before-keypressed. Traced what
happens if, for a single (non-repeat) press, `keyreleased` is processed
*before* the press's own `textinput` — a case the platform's documented
guarantee (`user_input.md:56`) does not exclude, since it speaks only to
keypressed/textinput relative order, not to keyreleased:

1. `appKeypressed(k, _, false)` — for a printable target, `altPlayKey`
   (`alt.lua:188-196`) returns at line 190 (`if not altIsKeyTarget(...) then
   return end`) without touching `GLYPH_CLAIMED`.
2. `appKeyreleased(k)` (`input.lua:177-183`) fires next: `INPUT.upRecent[k] =
   DBG_FRAME` (say frame N); `GLYPH_CLAIMED[k] = nil` (was already nil — no
   claim to clear).
3. `appTextinput(ch)` finally arrives, within `INPUT_UP_GRACE` (`= 1`,
   `input.lua:66`) frames of N. `spendGlyph(k)` (`input.lua:154-160`):
   `GLYPH_CLAIMED[k]` is nil (step 2 didn't set it, nothing else did) → falls
   to `local up = INPUT.upRecent[k]` (= N from step 2) → `DBG_FRAME - up <=
   INPUT_UP_GRACE` is true (same or adjacent frame) → **returns `true`: the
   glyph is dropped**, even though it was never claimed by any earlier
   `textinput` for this press.

This is the same failure *shape* SM5 fixed (a legitimate, never-before-seen
glyph misclassified as a repeat/trailing artifact and discarded) — just
reached through the release-grace window instead of the held-key check. It is
**not new to this fix**: the grace-window line (`up and DBG_FRAME - up <=
INPUT_UP_GRACE`) is carried over unchanged from the old `inputStale`
(`git -C src/examples/keyboard show 3a9d48c` diff on `input.lua` shows the
grace check is the one piece of logic *not* rewritten — the commit message
says as much: "The post-keyup grace stays as it was"). `DBG_FRAME` increments
once per `love.update` call (`src/examples/keyboard/main.lua:99-100`), and
LÖVE's event pump delivers queued input events before `update` runs each
frame, so a fast tap where `textinput` is merely queued behind `keyreleased`
within the same frame (`DBG_FRAME - up == 0`) hits this unconditionally.

So: **the fix is correct on its own terms for the two orderings its own
comment names (keypressed-vs-textinput), but the "reads the same in both
orders" claim overstates its reach** — it does not cover, and was not written
to cover, the case where `textinput` trails its own `keyreleased`, which the
platform's documented guarantee does not rule out. This is inherited,
pre-existing grace-window behavior the fix left untouched, not a regression
introduced by `3a9d48c` — but it means the mechanism is not fully
order-independent as claimed.

- **Supersession noted, not flagged as a finding** per the brief's
  instruction:
  `doc/development/internals/examples/keyboard.md:10,147,152` confirms this
  fix is explicitly documented there as interim and superseded by a later
  design that removes the claim mechanism entirely — consistent with the
  brief's framing, not raised as a conflict.

---

## Closing lines

1. **Do any of the three no-change rulings (SM1, SM2, SM3b) rest on a premise
   the code does not support?** No. Every premise checked under SM1, SM2, and
   SM3b is CONFIRMED against the code, including the two harder-to-verify
   claims (the paint/base-commit comparison for SM1, and the "no suite row
   exercises `ConsoleView:draw`" claim for SM2). No wrong premise found under
   any no-change ruling.

2. **Is SM5's fix correct on its own terms, in both delivery orders?** Correct
   for the two orderings its own header comment names (keypressed-before-
   textinput and textinput-before-keypressed) — traced both and the claim
   mechanism produces the right outcome in each. It is **not** correct against
   a third ordering the brief asked to check and the platform's documented
   guarantee does not exclude: `textinput` arriving within the
   `INPUT_UP_GRACE` window after its own `keyreleased`, which the unchanged
   release-grace check misclassifies as a trailing repeat and drops. This gap
   predates the fix (inherited from the old grace-window logic, untouched by
   `3a9d48c`) rather than being introduced by it.

3. **What did you verify that came back clean, so the next reader knows the
   shape of your pass?** All code-location and quote claims in SM1
   (hooks/mousereleased/btn-literal/drag-path/base-commit/debt-entry), SM2
   (no-`love.draw`/`set_love_update`'s draw-swap condition/`ConsoleView:draw`
   mode gating/fixture stub and its one call site), SM3a (the negative
   font/graphics-reset claim across `stop_project_run`, `close_project`,
   `_reset_executor_env`, and the one `setFont` call site being quit-only),
   SM3b (`SHIFT_KEYS`-only gating, the full `ctrl`/`Ctrl` grep across the
   example, and the platform-wide `dim` grep), and SM5's non-mutation premises
   (removal of `inputStale`, the platform's documented no-ordering-guarantee
   quote, the claim/release mechanism, the live-read key-cap renderer, and the
   supersession doc) all read exactly as the note states. Both git working
   trees (`/repo` and the nested `src/examples/keyboard`) end byte-identical
   to how they started, apart from this deliverable; the nested `maze` and
   `balloons` repos were read but not touched (`balloons` carries pre-existing
   untracked scratch unrelated to this pass). `busted tests` returns to
   955/0/0/3 after the one mutation-and-restore cycle.
