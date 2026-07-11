# M8-01 — RESUME note (crash recovery; layers onto `M8-01-in-repo-migrations.md`)

_Written by the opus-sweeper PM, session05, 2026-07-11, after the previous PM died mid-run. The prior
M8-01 implementor **crashed partway**; its output survives **uncommitted** on disk (the session05 prompt
anticipated this: "a long synchronous implementor run can hit a mid-response API error; the changes
survive on disk"). You are a **fresh cold implementor** finishing M8-01 from that partial state. **Read
`prompts/M8-01-in-repo-migrations.md` in full first — it is the authority; this note only says what is
already done and what remains.**_

## What already survives on disk (DONE — verify, do NOT redo)

1. **Test-first `#m8` rows** — `tests/input/input_contracts_spec.lua` (bottom of file, the
   `describe('continuous-session idiom #m8', …)` block, 2 tests). They are **green**. They pin the recipe:
   `on_text_entered` consumes, field-write `after_submit` re-shows, the re-armed session observes a 2nd
   submit. **Read them — they encode the corrected recipe (next section).**
2. **tixy migration** — `src/examples/tixy/main.lua`: `write_to_input(body)`→`compy.input.set_text(body)`;
   the `user_input()` + `love.update` poll loop deleted; an initial
   `compy.input.show{ prompt=…, text=…, eval = InputEvalLua, on_text_entered = submit_body }` at the tail
   + a field-write `compy.input.after_submit = function() compy.input.show{ text = … } end` re-show.

**Baseline on disk right now: `busted tests` = 808 / 0 / 0 / 4** (806 original + the 2 new rows; the 4
pending @101/@153/@161/@222 are the routing-gap cells — leave them). Confirm this before you touch anything.

## The CORRECTED recipe — `after_submit` is a FIELD-WRITE, not a `show{}` key (PINNED FINDING)

The prior implementor found — and I (PM) confirmed live — that the recipe in
`M8-01-in-repo-migrations.md` §"migration recipe" and in `M8-chunk-plan.md` is **wrong on one point**:
`after_submit`/`before_submit`/`before_cancel`/`after_cancel` are in `INPUT_CALLBACKS`
(`consoleController.lua:357-369`, field-write-assignable on `compy.input`) but are **NOT** in `OUTPUT_KEYS`
(`consoleController.lua:403-408`) — the only keys `show{}`/`configure{}` merge/sticky are
`on_text_entered`, `on_limit_reached`, `validator`, `highlighter`. **So `show{ after_submit = fn }` is
silently dropped.** Wire the re-prompt as a **direct field-write** instead:

```lua
compy.input.after_submit = function() compy.input.show{ … } end   -- re-prompt AFTER hide
compy.input.show{ prompt = P, on_text_entered = function(t) <consume> end, … }  -- on_text_entered IS a show{} key
```

`on_text_entered`/`validator`/`highlighter`/`eval` still flow through `show{}` as the commission says —
only the `*_submit`/`*_cancel` callbacks need the field-write. **Pin this surprise-first in the ledger**
(it corrects the commission's recipe and touches all four examples). It is **not** a design gap — the
mechanism exists; the recipe just named the wrong delivery — so it does **not** trigger a STOP.

## What REMAINS (the crash cut here — do this, then wrap)

1. **Verify the existing tixy migration actually works** — headless smoke-load
   (`xvfb-run -a love src play src/examples/tixy 2>&1 | head -40`, traceback-free = pass; no keystroke
   injection). **Specifically check the re-armed session still Lua-highlights:** `eval` is NOT in
   `OUTPUT_KEYS`, so a bare `after_submit` re-show may lose `InputEvalLua`. Confirm the model keeps the
   eval sticky across show/hide; **if it does not, re-pass `eval = InputEvalLua` in the `after_submit`
   re-show** (the conservative fix) and note it. Do not overclaim — real compose/submit is a human gate.
2. **Migrate repl, guess, valid** — the same corrected recipe (see the per-example section of the
   original commission for line refs + the `validated_input`→validator/eval mapping for guess/valid).
   Field-write `after_submit`; consume in `on_text_entered`; delete the `user_input()`/`is_empty()` poll.
   guess's duplicate `is_natural` (L12+L26) is **pre-existing — report-don't-fix**, wire the effective one.
   Smoke-load each headless.
3. **Full suite + LSP diagnostics** on every `.lua` you edited (`sleep 1` first). Expect **808 / 0 / 0 / 4**
   still (no new rows required for the three trivial migrations unless you add one; no legacy global removed
   → no nil-call rows — those are M8-03).
4. **Write `outcomes/M8-01.md`** per the original commission's ledger shape — **open surprise-first** with
   (a) the `after_submit` field-write correction above, (b) the tixy `eval = InputEvalLua` mechanism-key
   choice + whether eval stayed sticky on re-show, (c) the guess/valid validator-vs-eval wiring choice.
   Then per-AC (AC-3/AC-5/AC-6/AC-10), per-example before/after, the contract-test note, before/after
   busted counts, headless results + the honest human-hand-play ceiling (list tixy+repl+guess+valid),
   scope-fence confirmation (no global removed, balloons + evaluator.lua untouched), tech debt.
5. **Commit locally** — all four are in-repo (commit normally, no push). One Conventional Commit for the
   chunk (`feat(input): migrate tixy/repl/guess/valid off legacy poll idiom (M8-01)`), or tixy-then-rest if
   cleaner — your call, keep it independently revertible.

## Scope fence (unchanged — overreach = STOP + record)

All of `M8-01-in-repo-migrations.md` §"Scope fence" holds verbatim: **remove NO legacy global**
(`user_input`/`input_text`/`input_code`/`validated_input`/`write_to_input`/`astv_input` + the
`input()`/`input_ref`/`create_input_handle()` machinery + the `text_input` dead write — **all M8-03**);
do **NOT** touch `balloons` (M8-02), `evaluator.lua`, or any `src/controller/*` routing/dispatch/surface.
Expected files: `src/examples/{tixy,repl,guess,valid}/main.lua` + `tests/input/*`. Anything else = STOP +
record. If a migration seems to need a surface change, that is likely a real gap — **STOP and report**,
do not rule in-slice.
