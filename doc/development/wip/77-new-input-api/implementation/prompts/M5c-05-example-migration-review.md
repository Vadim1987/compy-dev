# Review — M5c-05: example migration turtle + maze (chunk 5 review boot)

_For the **Opus reviewer** (`agents/review.md`). Milestone id `M5c-05`. Final chunk of
the M5c carve — Scope 6 [examples], **AC-32**. Verdict only — **never rewrite feature
code**; edit only your review + `technical_debt.md`. lua-lsp is **restored** this
session — use it; grep as backstop, don't fabricate LSP output._

## Verify-don't-trust (do these yourself, first)

- **Re-run `busted tests`** — must be **779 / 0 / 0 / 5** (unchanged; this chunk adds no
  contract rows — AC-31/32/33/36 rows already existed and stay green). If it moved,
  something outside the examples was touched — investigate.
- **`git status` / the diff** — the committed diff must be **turtle + the ledger only**.
  Confirm **nothing was committed inside `src/examples/maze/`** and its `.git` is
  untouched (guardrail 7). The maze changes must exist as **uncommitted working-tree**
  edits and be **enumerated in the ledger**; cross-check the ledger's file list against
  the actual working-tree changes under `src/examples/maze/`.
- **`grep -rn "input_text\|user_input()" src/examples/turtle src/examples/maze`** — the
  legacy solicitation/poll idiom should be **gone from both examples' migrated paths**
  (replaced by `compy.input.show{…}` / `on_text_entered`). The globals themselves must
  **still exist** elsewhere (they die in M8) — confirm the chunk did not delete them.

## The traps (rank the review around these)

1. **R1 once-per-submit — THE headline correctness check.** turtle's old code polled the
   reftable every `love.update` (`eval(r())` each frame). The migration must call the
   command handler **once per submit from `on_text_entered`**, NOT re-run it every frame.
   A migration that re-polls or re-evaluates per-tick has recreated a bug the new model
   removes — **finding**. Verify the same for maze's command flow.
2. **Scope fence.** The diff must touch **only** the two examples (turtle committed, maze
   uncommitted) + the ledger. No dispatch-chain / `controller.lua` / `projectInputController`
   edits; no AC-31/33/36 row changes; **legacy globals not removed** (that is M8); tixy/
   balloons untouched. Pointer (`love.mousepressed` in maze) and the natives
   (`love.keypressed`/`keyreleased`) **left in place** (AC-28/AC-31). Any of these
   violated ⇒ finding.
3. **Migration is faithful to the ratified surface.** `show{prompt=…, text=…,
   on_text_entered=…}` uses only landed M5c config keys (no invented surface, no true M7
   dependency). maze's pre-filled `input_text("Commands:", string.lines(text))` maps to
   `text=…`; each maze solicitation's result reaches the same handler it did before, now
   via the callback. Confirm no command path was silently dropped.
4. **Guardrail 7 hand-off is complete and honest.** Every changed maze file is listed in
   the ledger; none committed. The `.git` under `src/examples/maze/` is pristine.
5. **Verification honesty (report-don't-overclaim).** AC-32 is "hand-playable
   afterwards." If the implementor could only smoke-load headless, the ledger must **say
   so** and flag human hand-play as the final gate — it must not claim "verified
   playable" from a load-without-traceback. Assess whether the claimed verification
   matches what was actually done.
6. **Hard limits + hygiene.** line ≤64, fn body ≤14, params ≤4, nesting ≤4 on any new
   example code; no string-tag dispatch; AC-34 remark dispositions present + citable.

## Escalation check

If the implementor **stopped and escalated** on a real seam (an example needing a
`show{}` capability the M5c surface lacks — a genuine M7 dependency — or maze's flow
needing a route-model change), assess whether it is real (the landed surface truly can't
express it) or whether the migration was in fact achievable with `prompt`/`text`/
`on_text_entered` as spec'd. A "the old feel differs" is **not** an escalation — the
design sanctions the behaviour change.

## Verdict

`approve` / `corrective-take` (exact findings: file:line + the AC/rule each violates) /
`escalate` (a real surface/route gap). Report the busted counts. Write `reviews/M5c-05.md`
and commit it locally (never push).
