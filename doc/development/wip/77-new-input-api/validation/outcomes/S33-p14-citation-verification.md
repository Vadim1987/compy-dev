# S33 — P14 citation verification (mechanical, read-only)

Verifies every citation/line-number/count in §11 (lines 881–1061) of
`../reviews/S27-triage-and-plan.md` against actual code and docs. Read-only:
no file touched except this one. Tooling used: grep (primary sweep) +
`mcp__lua-lsp__references` (cross-check on the completeness question, task 3).

## Summary table

| # | Claim | Verdict |
|---|---|---|
| 1.1 | `doc/input_api.md` §"Held keys" spans `:365-395` | WRONG — heading is at `:365`; next heading (`## Callback assignments`) is at `:398`. Substantive content runs to `:396`, blank line `:397`. True span `:365-397` (content `:365-396`) |
| 1.2 | `:268` false claim re: hook receiving held table as 2nd arg; `:390` contradicts it | `:268` CONFIRMED verbatim. `:390` PARTIALLY WRONG — the contradicting clause ("is **not** passed to handlers") starts at `:389`; `:390` is its continuation, not the sole location |
| 1.3 | `internals/user_input.md` holds 10 `keys_pressed` occurrences | CONFIRMED — 10 lines, 10 occurrences (1 per line; verified with `grep -o \| wc -l`) |
| 1.4 | Decision 21 worked example ("receives the held-key view"); Decision 26 removed it | CONFIRMED — Decision 21 heading `:833`, stale sentence `:881-882`. Decision 26 heading `:1070`, removal stated `:1075-1076` and `:1078-1086` |
| 2.1 | `keys_pressed_spec.lua` first describe `:52-96` (delete) | WRONG — block is `:52-90` (`end)` at 90). `:91-96` is a blank line + a comment belonging to the *next* describe |
| 2.2 | `keys_pressed_spec.lua` second describe `:98-138` (keep, source-blind) | CONFIRMED exact boundaries; CONFIRMED it never references `Controller.keys_pressed` — LSP shows all 10 `keys_pressed` refs in this file sit in `:52-90` |
| 2.3 | `input_nfr_mechanism_spec.lua` `:66-105` (delete) | WRONG — the block of `keys_pressed`-touching `it`s is `:66-112` (4 tests); `:105` is the *first line* of the 4th test, whose body runs to `:112`. Citing `:105` orphans 7 lines |
| 2.4 | `input_nfr_mechanism_spec.lua` `:123-165` (keep) | CONFIRMED — `:123` is `it('the widget keeps identity...`; `:165` is EOF/final `end)` |
| 2.5 | `input_events_spec.lua` `:781-905` (delete) | WRONG — block (`describe('the pressed-keys table'...` through matching `end)`) closes at `:901`. `:902-905` is blank + 2-line comment introducing the *next* describe (`:906`) |
| 2.6 | `input_events_spec.lua` `:557,616,734,857-861` (individual rewrites, some write-before-dispatch) | CONFIRMED — all four quoted and located exactly; `:557,616,734` each assert `keys_pressed[...]` is already true inside a shortcut/hook fired after a prior press, i.e. write-before-dispatch; `:857-861` asserts handler-time view equals outside view |
| 3.1 | `projectInputController.lua:103-110` — `find_shortcut`, single production call site for matching | CONFIRMED (function itself is `:101-111`; `:103-110` is precisely the body that reads/uses `keys_pressed`). Confirmed no other production site performs shortcut *matching* against the tracked set |
| 3.2 | `controller.lua:788,906` (writes), `:498` (field), `held_keys()`+proxy `:420-443,501` | ALL CONFIRMED exact |
| 3.3 | `consoleController.lua:539-540` (sandbox field) | CONFIRMED exact |
| 3.4 | `consoleController.lua:829-834` (held upvalue plumbing) | WRONG — real span is `:829-830` (`local held = Controller.held_keys` / `return build_input_surface(...)`). `:831` is `end`; `:833-834` is a comment belonging to a *different*, unrelated function (`get_compy_namespace`) |
| 3.5 | `combo_string`/`any_mod` need no change — source-blind | CONFIRMED by direct read: neither function body calls any `Key.*` function; both index the passed-in table by raw key name only |
| 3.6 | COMPLETENESS: 22 `keys_pressed` occurrences across 7 files incl. `examples/keyboard/input.lua` | CONFIRMED exact (22 lines, 22 occurrences, 7 files) via grep, cross-checked with LSP |
| 4.1 | `examples/keyboard/input.lua` — `INPUT.__index` held branch | CONFIRMED, located at `:54-62` (metatable block), the `held` check itself at `:57` |
| 4.2 | `keyboard_view.lua:171` and `:178` | CONFIRMED both read `INPUT.shift` |
| 5.1 | `tests/mock.lua` — `mods` `:17-21`, `held` `:5-15`, right-hand slots already present | CONFIRMED exact on both ranges; `held` table has `rctrl`/`rshift`/`ralt` keys at `:7,9,11` |
| 6.1 | Dissolve: `:29,:61,:81,:281,:442` | ALL CONFIRMED (headings match) |
| 6.2 | `:29`/`:281` are duplicate entries for the same defect | CONFIRMED — both describe held-set staleness on focus loss |
| 6.3 | `:396` RESOLVED, "owner ruled to expose it" | CONFIRMED verbatim (`:413`) |
| 6.4 | Rework pair `:664`+`:689` | CONFIRMED — `:689` is inside the `:664` entry and literally reads `Controller.keys_pressed` |
| 6.5 | Rework pair `:738`+`:731` | WRONG — `:731` sits inside the **`:719`** entry ("A multi-trigger combo is silently truncated..."), not `:738`'s. The `:738` entry's own `keys_pressed` line is `:773` |
| 6.6 | Rework pair `:775`+`:773` | WRONG — the `:775` entry ("A keyboard-hooks-only project does not count as interactive") contains **no** `keys_pressed` mention anywhere in its body. `:773` is actually the `:738` entry's line (see above) |
| 6.7 | Survives unchanged: `:795,:178,:988` | ALL CONFIRMED — `:988`'s retired idiom is specifically `r = user_input()` (poll-loop), not device polling, matching the claim |
| 6.8 | `:58,:77` carry now-false "Scheduled: before the PR (P9d/P9e)" wording | CONFIRMED verbatim at both lines |
| 7.1 | `grep -rn 'INTERIM:\|REMARK:' src/ tests/` → 22 platform + 5 examples | CONFIRMED exact — 0 `INTERIM:` hits; 27 `REMARK:` hits total (`src/`=10, of which `src/examples/`=5, plus `tests/`=17 → platform-excluding-examples = 5+17 = 22). The 22 does **not** include the 5; they're disjoint, and 22+5=27 is the true total |
| 7.2 | P8's nine ids cross-checked against §4 (`:580`) and Appendix A W8 (`:660`) | CONFIRMED — §11.3's 9-id list is verbatim the same set as §4's "Left:" list at `:580`; all 9 are members of the 16-id W8 list at `:660-661`; the complementary 7 W8 ids match §4's "PART DONE" sublist exactly (9+7=16). No id missing from any of the three |
| 7.3 | `input_probe.lua` header quote | CONFIRMED verbatim |
| 7.4 | `error_explorer.lua:418` is a `love.keyboard.isDown` call, byte-identical at `3256aac` | CONFIRMED — line quoted correctly; `git show 3256aac:...` diffed byte-identical to current file |

## 1. Doc citations (§11.4 P14a, §11.3 P10)

**"Held keys" spans `:365-395`.** `## Held keys` is at line 365. The next
heading `## Callback assignments` is at line 398. Content: `:365` heading,
substantive prose/example runs through `:396` ("nothing on the shipping
runtime; index it by name."), `:397` blank. **WRONG** — true span is
`:365-397` (or `:365-396` if only counting non-blank content); `:395` cuts
2 lines short of the section's actual end.

**`:268` false claim / `:390` contradicts it.**
- `:268` verbatim: `a hook: it receives the held-key table as its second argument on all three` — CONFIRMED, this is the false claim (continues on `:269`: "keyboard/text channels, and `compy.input.keys_pressed` is readable anywhere.").
- `:390` verbatim: `LÖVE's own arguments and nothing added, so a handler that wants held state reads` — this line alone does not contain the negation. The actual contradicting clause spans `:389-390`: `:389` = "is **not** passed to handlers — every shortcut, hook and widget call receives", `:390` continues it. **PARTIALLY WRONG**: citing only `:390` misses that the operative words ("is **not** passed to handlers") are on `:389`.

**`internals/user_input.md` — 10 `keys_pressed` occurrences.** `grep -n` finds
10 matching lines: `:171, :241, :243, :264, :284, :292, :409, :410, :536, :846`.
`grep -o | wc -l` also returns 10 — every matching line contains exactly one
occurrence (none has two). **CONFIRMED** exact count of 10, matching P14a's claim.

**Decision 21 / Decision 26.** Decision 21 heading is `## Decision 21 — a
combo names modifiers plus one trigger, or a class` at `:833`. Its stale
worked-through passage is at `:881-882`, quoted verbatim: *"A project that
wants them uses a hook, which receives the held-key view on **all three**
keyboard/text channels, and `compy.input.keys_pressed` (Decision 20)
elsewhere."* Decision 26 heading is `## Decision 26 — every consumer
receives LÖVE's own argument list` at `:1070`. Its removal of the argument is
stated at `:1075-1076` ("The held-key set is not among them: a consumer reads
`compy.input.keys_pressed`...") and detailed at `:1078-1086` (the old
`(k, keys_pressed, isrepeat)` triple named and retired). **CONFIRMED**, with
line numbers as given above (§11 itself does not give line numbers for these,
so there is nothing to mark right/wrong on that score — only the location
needed verifying).

## 2. Test citations (§11.4 P14c)

**`keys_pressed_spec.lua` first describe.** Actual block: `:52` (`describe(...)`)
through `:90` (`end)`). Content is 4 `it` blocks (`:58-61, :63-67, :69-77,
:82-89`), all touching `Controller.keys_pressed` directly (LSP confirms all
10 `keys_pressed` refs in this file sit at `:60,64,66,72,73,75,76,85,86,88` —
all inside `:52-90`). **WRONG** — claimed `:52-96`; true end is `:90`.
`:91-97` is a blank line + a 6-line comment (about a *different*, unrelated
serialize-vs-match proposal) that belongs to the section *before* the second
describe, not to the first one.

**`keys_pressed_spec.lua` second describe.** `:98` (`describe(...)`) through
`:138` (`end)`, EOF). **CONFIRMED** exact. Content is 6 `it` blocks
(`:102-104, :106-108, :110-113, :115-118, :120-123, :125-128, :130-137` —
7 tests total testing `combo_string`), each building a local synthetic
`held = { ... }` table and passing it to `Controller.combo_string` directly.
**CONFIRMED load-bearing claim**: zero occurrences of `Controller.keys_pressed`
appear in `:98-138` (LSP's 10 references in this file are all in the *first*
describe, `:52-90`). It is genuinely source-blind.

**`input_nfr_mechanism_spec.lua`.** The `keys_pressed`-touching tests are:
`:66-76` ("the pressed key is in the held set"), `:78-90` ("the released key
is gone before dispatch"), `:92-95` ("reuses the held-key view for one
backing table" — reads `Controller.held_keys()`, not `keys_pressed`
directly), `:105-112` ("left/right names stay raw in the held set"). The
cited delete range `:66-105` ends at the *opening* line of the 4th test,
whose body runs through `:112`. **WRONG** — true end is `:112`; citing `:105`
would leave `:106-112` (6 lines of test body plus its closing `end)`)
orphaned if executed literally. `:123-165` (keep) is **CONFIRMED**: `:123` is
`it('the widget keeps identity across cycles',`, and `:165` is the file's
final line (closing `end)` of the outer describe opened at `:31`).

**`input_events_spec.lua`.** `describe('the pressed-keys table', ...)` opens
at `:781` — start point CONFIRMED. It and the sibling `describe('compy.input.keys_pressed', ...)` (`:825-863`) both concern the held table; two more
`it` blocks follow (`:869-882, :888-899`, about uniform argument delivery,
*not* about `keys_pressed`) before the enclosing describe (opened `:713`)
closes at `:901` (`end)`). **WRONG** — claimed `:905`; true end of the block
is `:901`. `:902-905` is a blank line plus a 2-line comment introducing the
*next* describe (`'defaults and the hidden widget'`, `:906`), unrelated to
this deletion.

Individual rewrite lines, each **CONFIRMED**, quoted verbatim:
- `:557` — `seen = { k, isr, input.keys_pressed['lalt'] }` (inside
  `it('passes the payload through to the wrapped function', ...)`). Asserts
  `keys_pressed['lalt']` is already `true` when the wrapped shortcut fires
  after `lalt` was pressed first — write-before-dispatch.
- `:616` — `seen = { k, isr, input.keys_pressed['lalt'] }` (inside
  `it('hands the invocation arguments to the function', ...)`). Same
  write-before-dispatch assertion, for `stop_here`.
- `:734` — `seen[who] = { k, sc, isr, input.keys_pressed['a'] }` (inside
  `it('every step of the chain receives LOVE arguments', ...)`). Same
  pattern, asserted at every step (shortcut and hook) of the chain.
- `:857-861` — inside `it('agrees with the view a handler receives', ...)`:
  `:857` `from_handler = input.keys_pressed['a']; return true` (captured
  inside a hook), `:860` `assert.equal(from_handler, input.keys_pressed['a'])`,
  `:861` `assert.is_true(input.keys_pressed['a'])`. Asserts the handler-time
  view equals the outside-event view (same live proxy, not a snapshot) — a
  milder but related ordering/identity claim.

## 3. Production-code citations and completeness (§11.4 P14d)

Note: the files live at `src/controller/projectInputController.lua`,
`src/controller/controller.lua`, `src/controller/consoleController.lua` —
**not** `src/model/...` (a `src/model/` directory exists but holds unrelated
model files: `canvasModel.lua`, `consoleModel.lua`, `input/`, etc.). §11's
own text does not actually specify a directory for these files (only bare
filenames), so this is not a §11 citation error — flagged only because the
verification prompt's own task-3 bullets prefix `src/model/`, which is wrong.

**`find_shortcut` (`projectInputController.lua:103-110`).** The function
itself is `:101-111`; `:103` is `local keys = Controller.keys_pressed`, used
through `:110`. **CONFIRMED** as the site and as the *single* production call
site performing shortcut/hook **matching** against the tracked set — no other
call site in `src/` calls `combo_string`/`any_mod` against `keys_pressed`.

**`controller.lua` writes/field/proxy.**
- `:788` — `Controller.keys_pressed[k] = true` (inside `handlers.keypressed`). CONFIRMED.
- `:906` — `Controller.keys_pressed[k] = nil` (inside `handlers.keyreleased`). CONFIRMED.
- `:498` — `keys_pressed = { },` (the field, inside the `Controller` table literal). CONFIRMED.
- `held_keys()` + proxy memoisation `:420-443`: comment `:420-428`, the
  `local held_backing, held_proxy` / `local function held_keys()` block
  `:429-443`. CONFIRMED exact.
- `:501` — `held_keys = held_keys,`. CONFIRMED.

**`consoleController.lua` sandbox field and held upvalue.**
- `:539-540` — `return build_frozen_view(function(k)` / `if k == 'keys_pressed' then return get_keys() end`. CONFIRMED exact.
- `:829-834` — claimed as "held upvalue plumbing". Actual: `:829` `local held = Controller.held_keys`, `:830` `return build_input_surface(state, methods, held)`. **WRONG** — the real span is `:829-830`. `:831` is the closing `end` of that function (`get_compy_input`); `:833-834` is a comment introducing an *unrelated* function (`get_compy_namespace`, starting `:835`) whose own "held as upvalues" phrase (`:837`) refers to different upvalues (`input_surface`/`before_exit_slot`), not the input `held` variable.

**`combo_string`/`any_mod` source-blind claim.** Read both bodies
(`:395-404`, `:411-418`): neither calls `Key.ctrl()`/`Key.alt()`/`Key.shift()`
or any other `Key.*` function; both index their parameter table
(`keys_pressed[m[1]] or keys_pressed[m[2]]`) by raw modifier name only.
**CONFIRMED.**

**COMPLETENESS — the count.** `grep -rn "keys_pressed" src/` returns exactly
**22** matches across exactly **7** files:

```
src/types.lua:251
src/probe/input_probe.lua:81
src/probe/input_probe.lua:124
src/controller/userInputController.lua:490
src/controller/controller.lua:388,393,395,398,409,411,413,420,431,437,498,788,906   (13 lines)
src/controller/consoleController.lua:540
src/controller/projectInputController.lua:103
src/examples/keyboard/input.lua:43,57,109
```
1+2+1+13+1+1+3 = 22. **CONFIRMED** exact, matching "22 occurrences across 7
files, including `src/examples/keyboard/input.lua`".

LSP (`mcp__lua-lsp__references` on `keys_pressed` and `held_keys`) surfaced
the same core production/test sites but, exactly as the incompleteness
warning predicted, **missed** four kinds of occurrence entirely: a type
annotation (`types.lua:251`), a comment (`userInputController.lua:490`), a
computed-string-key indirection (`consoleController.lua:540`, matched via
`if k == 'keys_pressed'`, not a direct field reference), and the
`compy.input.keys_pressed` sandbox-proxy accesses in
`examples/keyboard/input.lua` (`:43,57,109`) — a different table path the
static resolver doesn't follow. Grep-as-backstop was necessary, as warned.

**Which occurrences are NOT accounted for by any P14d/P14e bullet:**
- `src/types.lua:251` — `--- @field keys_pressed table` (type annotation on `CompyInput`). Not named anywhere in P14d or P14e.
- `src/controller/userInputController.lua:490` — comment: "the held set is `compy.input.keys_pressed`." Not named anywhere in P14d or P14e.
- `src/examples/keyboard/input.lua:109` — `local held = compy.input.keys_pressed` inside `function modHeld(a, b)`. This is a **distinct call site** from the `INPUT.__index` "held" branch (`:57`) that P14e names; `modHeld` is a separate top-level function, called *from* the `__index` metamethod for the shift/ctrl/alt cases, not itself the named branch.
- `src/examples/keyboard/input.lua:43` — header-comment prose mentioning `compy.input.keys_pressed`; not code, but not literally named either.
- `src/probe/input_probe.lua:81,124` — **not** inside any P14d/P14e bullet, but they *are* accounted for elsewhere in §11.4, under "Also placed, outside P14 ... `src/probe/input_probe.lua` — DELETE." Flagged per the task's literal wording (P14d/P14e specifically), with that caveat.

## 4. Example citations (§11.4 P14e)

**`INPUT.__index` held branch.** The `setmetatable` block is `:54-62`;
the `__index` function is `:55-61`; the `held` check itself is `:57`:
`if k == "held" then return compy.input.keys_pressed end`. **CONFIRMED**,
located at `:54-62` (or `:57` for the exact branch line).

**`keyboard_view.lua:171` and `:178`.**
- `:171` — `if INPUT.shift then return not CAPS_STATE.on end`, inside `capsEffectiveUpper()`.
- `:178` — `if KB_SHIFTLABEL and INPUT.shift and SHIFT_MAP[name] then`, inside `kbLabel(name)`.
Both **CONFIRMED**.

**Drawing/decoration vs. judgement (facts only, not sorted by me):**
- `kbLabel` (`:178`'s caller) is used by `drawKey` (`:249`, wraps `drawKeycap`) and `kbTargetLabel` (`:293`) — both produce a glyph string for on-screen rendering. Pure drawing/decoration by function.
- `capsEffectiveUpper` (`:171`) is used by `altHintReady` (`alt.lua:229`), which in turn is used only by `altHintDeco` (`alt.lua:238`, sets `bg`/`glow` decoration fields for the keyboard-glow hint) and `altHintFinger` (`alt.lua:256`, positions a pointing-finger hint graphic). Both callers compute visual decoration (what glows, where the finger points), not pass/fail scoring of a keystroke.

## 5. Mock citations (§11.5)

`tests/mock.lua`: `mods` token map is `:17-21` exactly
(`{ C = 'lctrl', S = 'lshift', M = 'lalt' }`), `held` table is `:5-15`
exactly. **CONFIRMED** both ranges. `held`'s right-hand slots quoted
verbatim: `:7 rctrl = false`, `:9 rshift = false`, `:11 ralt = false` —
**CONFIRMED** the slots already exist (all initialised `false`); only `mods`
lacks right-hand tokens.

## 6. Technical-debt register (§11.6)

All headings quoted and cross-checked:

- `:29` "### The held-key set is never cleared on focus loss, so it can go stale" — CONFIRMED, dissolve.
- `:61` "### The gateway asks the device a question about an event" — CONFIRMED, dissolve.
- `:81` "### The held-key surface is a table that cannot be iterated" — CONFIRMED, dissolve.
- `:281` "### `keys_pressed` can go stale on focus loss" — CONFIRMED, dissolve. Content (`:283-292`) genuinely duplicates `:29`'s defect (staleness from missed release on focus loss) — **CONFIRMED** the "two entries, one defect" claim.
- `:442` "### Held-key pressed-keys view iteration is index-only on the shipping runtime" — CONFIRMED, dissolve.
- `:396` "### `compy.keys_pressed` is not exposed to projects (RESOLVED, 2026-08-03)" — **Resolution** quoted verbatim at `:413`: *"owner ruled to expose it — `compy.input.keys_pressed`"*. CONFIRMED.
- `:664` "### Combo triggers are key-name-only; positional bindings have no vocabulary", specific line `:689`: *"set — `Controller.keys_pressed` is key-name-keyed, and `combo_string`"* — both inside the same entry (`:664-692`). CONFIRMED.
- `:738` "### A combo table cannot express a modifier-class rule (RESOLVED, 2026-08-03)", specific line claimed `:731`. **WRONG** — `:731` ("wants \"a and b held together\" reads `compy.input.keys_pressed`") is inside the **preceding** entry, `:719` ("A multi-trigger combo is silently truncated at registration"), which ends at `:737`, one line before `:738`'s heading. The `:738` entry's own `keys_pressed` mention is at `:773` ("case is a hook plus `compy.input.keys_pressed`"), inside its closing paragraph (`:769-773`).
- `:775` "### A keyboard-hooks-only project does not count as interactive", specific line claimed `:773`. **WRONG** — `:773` belongs to the `:738` entry (see above), and the `:775` entry's own body (`:777-793`) contains **no mention of `keys_pressed` at all**. There is no "specific line naming `keys_pressed`" inside this entry to cite.
- `:795` "### Combo-string dispatch allocates a table per call" — content confirms "still allocates" (`table.concat`s a fresh `parts` table per call). Survives unchanged, CONFIRMED.
- `:178` "### A project that raises leaves global device state dirty; no force-reset exists" — matches "dirty global device state on raise" paraphrase. CONFIRMED.
- `:988` "### Per-example internals docs still describe a retired polling idiom" — body (`:990-998`) names the retired idiom explicitly as `r = user_input()` (a poll-loop over a reference), **not** device polling — matches the claim precisely ("does NOT invert"). CONFIRMED.
- `:58` and `:77` — both read `**Scheduled: before the PR** (plan phase P9d)` and `**Scheduled: before the PR** (plan phase P9e), alongside...` respectively, verbatim. CONFIRMED now-false (P9d/P9e withdrawn per §11.3).

**Not asked, but found in the course of checking `:738`/`:775`:** the
`:719` entry ("A multi-trigger combo is silently truncated at registration")
also names `compy.input.keys_pressed` as the recommended answer
(`:731`) — the same pattern §11.6 reworks for `:664`, `:738`. `:719` is not
in §11.6's rework list at all. Whether that's deliberate (perhaps this entry
is RESOLVED and out of scope some other way) or a further gap is the owner's
call, not mine — flagged as fact only.

## 7. Counts and id lists

**`grep -rn 'INTERIM:\|REMARK:' src/ tests/`.** Zero `INTERIM:` hits found
anywhere. `REMARK:` hits: **27 total** — `src/` alone = 10 (5 inside
`src/examples/`, 5 outside it, all in `src/controller/consoleController.lua`),
`tests/` = 17. Platform figure (**5 outside-examples `src/` + 17 `tests/` =
22**) and examples figure (**5**) are **CONFIRMED exact** and are **disjoint
sets** (22 does not include the 5); 22 + 5 = 27 = the true grand total across
`src/` + `tests/`. Full file:line list obtained and cross-summed to confirm
(not reproduced in full here; available in the grep transcript this
verification ran).

**P8's nine ids, cross-checked.** §11.3 (`:942`): `R057, R074, R078, R079,
R047, R063, R064, R069, R075`. §4's P8 row "Left:" list (`:580`): `R057
(three-surface grouping), R074/R078/R079 (merge / dissolve), R047, R063,
R064, R069, R075` — **the identical 9-id set**, same order. Appendix A's W8
membership (`:660-661`): 16 ids total — `R047 R057 R058 R059 R060 R061 R063
R064 R067 R068 R069 R070 R074 R075 R078 R079`. All 9 cited ids are present in
this 16-id set. The remaining 7 (`R058 R059 R060 R061 R067 R068 R070`) match
§4's "PART DONE" sublist exactly. **9 + 7 = 16 — all three agree, no W8 id
is missing from any of them.**

*Side note, outside this task's literal ask but bearing on the ids'
currency:* `S27-triage-and-plan.md:688` (a **session28** amendment,
dated 2026-08-07) reads: *"P8 marked done. R047, R063, R069 answered; R057
landed as three named surfaces; R064/R074/R075/R078 landed as the merge."*
That accounts for 8 of the 9 ids (not R079) as already resolved as of
2026-08-07 — yet §4's row at `:580` carries no `[S28]` amendment marker and
still lists all 9 as "Left," and §11.3 (session32, 2026-08-09) repeats the
same 9-id "remaining" list without addressing the tension. Fact only, not a
citation error in §11 — §11.3 accurately reproduces §4's current text either
way.

**`src/probe/input_probe.lua` header.** `:1-2` verbatim: *"Input clock probe
— DIAGNOSTIC, TEMPORARY. Delete when the polling-vs-tracking question is
ruled on."* **CONFIRMED**, matches the quoted claim exactly.

**`src/lib/error_explorer.lua:418`.** Verbatim: `if key == 'c' and
love.keyboard.isDown('lctrl', 'rctrl') then`. **CONFIRMED** a
`love.keyboard.isDown` call. `git show 3256aac:src/lib/error_explorer.lua`
diffed against the current file: **byte-identical**, zero diff output.
**CONFIRMED.**

---

## Claims that are wrong, in severity order

1. **`input_nfr_mechanism_spec.lua:66-105` (delete)** — real boundary is
   `:66-112`. Citing `:105` stops mid-test (at the opening line of the 4th
   `it` block), orphaning its 7-line body if executed literally.
2. **Technical-debt pair `:775`+`:773`** — the `:775` entry contains no
   `keys_pressed` mention whatsoever; `:773` is misattributed (it belongs to
   the `:738` entry).
3. **Technical-debt pair `:738`+`:731`** — `:731` belongs to the preceding
   `:719` entry, not `:738`'s. `:738`'s own line is `:773`.
4. **`consoleController.lua:829-834`** (held upvalue plumbing) — real span
   is `:829-830`; `:833-834` is an unrelated function's comment.
5. **`input_events_spec.lua:781-905`** (delete) — real block closes at
   `:901`; `:902-905` is the next section's lead-in comment.
6. **`keys_pressed_spec.lua` first describe `:52-96`** (delete) — real block
   closes at `:90`; `:91-96` is blank + an unrelated comment.
7. **`doc/input_api.md` "Held keys" span `:365-395`** — true span is
   `:365-397` (content to `:396`); off by 2.
8. **`doc/input_api.md:390`** "contradicts" the false claim — the operative
   negation ("is **not** passed to handlers") is on `:389`; `:390` is a
   continuation, not the sole locus.

## Sites the plan does not account for

- **`src/types.lua:251`** — `--- @field keys_pressed table` type annotation. Not named in P14d or P14e.
- **`src/controller/userInputController.lua:490`** — comment naming `compy.input.keys_pressed`. Not named in P14d or P14e.
- **`src/examples/keyboard/input.lua:109`** — `modHeld(a, b)`'s own `compy.input.keys_pressed` read, distinct from the `INPUT.__index` "held" branch (`:57`) that P14e does name.
- **`src/examples/keyboard/input.lua:43`** — header-comment prose, not code, but not named either.
- **`src/probe/input_probe.lua:81,124`** — not inside any P14d/P14e bullet (they *are* covered by the separate "outside P14 ... DELETE" bullet in §11.4, so this is a literal-wording gap, not an unaddressed site).
- **`doc/development/technical_debt/input.md:719`** entry ("A multi-trigger combo is silently truncated at registration") also names `compy.input.keys_pressed` as the recommended answer (`:731`), matching the pattern §11.6 reworks elsewhere — but is absent from §11.6's rework list entirely.
