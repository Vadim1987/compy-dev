# M8-01 — review note (traps to check)

_Reviewer boot (`agents/review.md`). Milestone id `M8-01`. Review the finished chunk (diff + ledger)
against `spec/M8-02-recut.md` **AC-3, AC-5** (+ AC-6/AC-10) + the rules. **Verify-don't-trust:** re-run
`busted tests` yourself; **headless smoke-load each migrated example yourself** (`xvfb-run -a love src
play src/examples/<name>`), read the diff. Edit ONLY `reviews/M8-01.md` + `technical_debt.md`; NEVER
feature/example code or `design/`. Verdict: approve / corrective-take / escalate + busted counts._

## Baseline / expected end state

- Entering: **806 / 0 / 0 / 4**. Expected exit: **806 + N / 0 / 0 / 4** (N = the continuous-session
  contract row(s); the **4 pending must stay 4** — the routing-gap cells @101/@153/@161/@222; **no
  nil-call rows this chunk** — those are M8-03).
- **No `src/` change should be needed** — this chunk is a *consumer* migration. If the diff touches
  `src/controller/*` or `src/model/*` or `evaluator.lua`, that is a scope-fence break → scrutinise / likely
  **corrective-take** (it belongs to M8-03 or is an unflagged surface gap).

## Traps — the high-value checks

1. **AC-3 tixy: no polling loop remains.** Confirm `love.update` no longer contains
   `if r:is_empty() then … else r() end` — it should keep only time-keeping. `user_input()`,
   `input_code()`, `write_to_input()` calls are **gone from tixy** (grep tixy for all six global names →
   zero). Delivery is via `on_text_entered`; re-prompt via `after_submit`. `write_to_input(body)` →
   `compy.input.set_text(body)`.
2. **The `eval = InputEvalLua` choice — verify it actually renders Lua highlighting.** tixy passes
   `eval = InputEvalLua` through `show{}`. Confirm the ledger flags this surprise-first AND that the
   implementor verified the highlighter renders (not just "no traceback"). A silent fallback to plain text
   (highlighter not applied) is an AC-3 miss ("code entry with highlighter"). If they used `highlighter=`
   on the default plain eval instead, check it genuinely highlights Lua (it likely does **not** — that
   would be a finding).
3. **The continuous-session idiom is wired correctly (the shared recipe).** For every migrated example:
   consume in `on_text_entered`, re-`show` in `after_submit` — NOT a `show()` inside `on_text_entered`
   (that warns; grep the smoke-load output for warn-spam). Verify the contract test actually asserts BOTH
   (a) `on_text_entered` received the assembled text AND (b) the widget re-shows after submit. A test that
   only checks delivery and not the re-prompt leaves the loop unproven.
4. **AC-5 no third state.** repl/guess/valid are EACH explicitly migrated **or** excluded-with-a-reason in
   the ledger — never silently dropped or half-done. PM direction was convert all three; an exclusion must
   carry a genuine recorded blocker, not convenience. Confirm each runs on `compy.input.*` (grep each for
   the six globals → zero) or is clearly marked excluded.
5. **guess/valid validator wiring reproduces legacy behaviour.** Legacy `validated_input({filters})` =
   `input(ValidatedTextEval(filters))`. Confirm the migration's `validator`/`eval` choice actually gates
   the same way (e.g. guess rejects non-naturals with the same message path). Not just "a validator is
   set" — that it validates equivalently. Check the ledger states which wiring was chosen and why.
6. **AC-6 natives untouched.** No pure-native example edited; suite green. (Trivially true if the diff is
   limited to the four example files + tests.)
7. **Scope fence — the big one this chunk.** **No legacy global removed** (`user_input`/`input_text`/
   `input_code`/`validated_input`/`write_to_input`/`astv_input` all STILL EXIST in
   `consoleController.lua` after this chunk — grep-confirm they are untouched; removal is M8-03). No
   `input()`/`input_ref`/`create_input_handle()` change. No `text_input` dead-write removal. **balloons
   untouched** (nested checkout — grep `src/examples/balloons/` unchanged; its `.git` untouched). No
   `evaluator.lua` edit. No routing/dispatch/surface edit. Any of these = finding.
8. **Rules limits** on any new/changed example code + the test: line ≤64, fn body ≤14, params ≤4, nesting
   ≤4. Example code is looser historically, but new `on_text_entered`/`after_submit` closures should be
   tidy; flag egregious bodies (report-don't-fix if pre-existing, corrective if newly introduced).
9. **`after_submit` is a FIELD-WRITE, not a `show{}` key (crash-recovery finding — verify it holds).**
   The prior implementor + this PM confirmed `after_submit`/`before_submit`/`before_cancel`/`after_cancel`
   are in `INPUT_CALLBACKS` (field-write-assignable) but NOT in `OUTPUT_KEYS` (the only keys `show{}`
   merges: `on_text_entered`/`on_limit_reached`/`validator`/`highlighter`) — so `show{ after_submit = fn }`
   silently no-ops. Confirm **every** migrated example wires the re-prompt as a standalone
   `compy.input.after_submit = function() … end` statement, NOT inside a `show{}` cfg. A `show{after_submit=…}`
   that slipped through = a dead re-prompt (the loop never re-arms) = corrective-take. The ledger flags this
   surprise-first; verify the code matches the claim.
10. **Prompt/text persistence across the bare re-show (fidelity trap — weigh, don't assume benign).**
   `prompt`/`text`/`cursor` are `PENDING_KEYS` — **per-show, NOT sticky** (unlike the OUTPUT_KEYS + eval).
   So a bare `after_submit` re-show (`show{}`) drops the prompt: **guess** re-prompts without
   "Guess a number:" on rounds 2+, and **tixy**'s re-show (`show{ text = … }`, no `prompt`) loses the
   "function tixy(t, i, x, y)" label after the first submit. Legacy showed the prompt **every** round
   (`validated_input(…, "Guess a number:")` / `input_code("function tixy…")` called each empty frame).
   Decide whether this is an acceptable cosmetic drift (prompt is a label; the widget still works) or an
   AC-3/AC-5 fidelity miss worth a corrective re-pass (`show{ prompt = P }` in `after_submit`). Check
   whether the ledger even noticed it — if the drift is real and unflagged, that itself is a finding.
   `eval` by contrast IS effectively sticky (persistent model singleton — the ledger traces this); confirm
   that trace rather than taking it on faith.

## Verification you must do yourself (verify-don't-trust)

- Re-run `busted tests` → confirm the count + that the new contract row is real and green.
- Headless smoke-load **each** of tixy/repl/guess/valid (`xvfb-run -a love src play src/examples/<name>`,
  ~a few seconds, `head` the output) → traceback-free, no warn-spam. Note the honest ceiling: you cannot
  inject keystrokes, so real submit/re-prompt stays a **human hand-play gate** — confirm the ledger says
  so and does not overclaim "verified playable."
- `grep -rn -E 'user_input|input_text|input_code|validated_input|write_to_input|astv_input' src/examples/{tixy,repl,guess,valid}`
  → **zero** (proves the migration is complete, no straggler poll calls).

## Report-don't-fix already logged

guess's duplicate `is_natural` (L12 + L26) is pre-existing shadowing — confirm the implementor **noted,
did not refactor** it. tixy's `setupTixy` `setfenv(f, _G)` and any leaking example globals are
pre-existing — noted, not fixed. If the implementor fixed a pre-existing example wrinkle beyond the
migration, that is a (benign) scope-fence break worth a flag.
