# M8-02 — review note (traps to check)

_Reviewer boot (`agents/review.md`). Milestone id `M8-02`. Review the finished chunk (diff + ledger)
against `spec/M8-02-recut.md` **AC-4, AC-8, AC-9** (+ AC-6/AC-10) + the rules. **Verify-don't-trust:**
re-run `busted tests` yourself; **headless smoke-load balloons yourself** (`xvfb-run -a love src play
src/examples/balloons`); read the diff (both the committed test/ledger AND the uncommitted balloons
working-tree changes — `git diff` won't show balloons since it's a nested checkout, so read the balloons
files directly + `cd src/examples/balloons && git status` to confirm its `.git` is untouched). Edit ONLY
`reviews/M8-02.md` + `technical_debt.md`; NEVER feature/example code or `design/`. Verdict: approve /
corrective-take / escalate + busted counts._

## Baseline / expected end state

- Entering: **808 / 0 / 0 / 4**. Expected exit: **808 (+N) / 0 / 0 / 4** (N = an optional
  configure-during-session contract row; the **4 pending must stay 4** — routing-gap cells
  @101/@153/@161/@222; **no nil-call rows this chunk** — those are M8-03).
- **No `src/controller|model` or `evaluator.lua` change** — this is a *consumer* migration. Any such edit
  = scope-fence break → scrutinise / likely **corrective-take** (belongs to M8-03 or is an unflagged gap).

## Traps — the high-value checks

1. **AC-4 continuous-session idiom: no per-frame poll, no re-show-per-hint.** Confirm balloons activates
   **once** (`compy.input.show{ on_text_entered = … }` at terminal init) and re-prompts from the submit
   hook (**field-write** `after_submit`, not a `show{}` key — a `show{after_submit=…}` that slipped through
   = dead re-prompt = corrective). The old `terminal:is_empty()`/`terminal()` poll and the
   `input_text(hint)` per-hint re-show are **gone**. Grep balloons for all six legacy globals → **zero**.
2. **The configure-during-session sequence (the headline risk).** balloons sets the hint prompt via
   `configure{prompt=…}` **inside** `on_text_entered` (`game_validate_input → ui_set_hint`), i.e. while the
   session is still active, then `after_submit` re-shows after hide. Verify the ledger **proves** the
   reshown session carries the intended prompt (configure-while-active writes `custom_label` on the
   persistent model; the bare reshow keeps it — but the ledger must show this was verified, not assumed).
   If the implementor hit a stale-prompt problem and worked around it with a surface change or a hack,
   that is a finding (corrective or escalate). If they correctly STOPPED and reported a genuine surface
   gap, honor that — verify it's real, then it's an ESCALATE, not a fault.
3. **`terminal_write` → `configure{prompt}` (not `input_text`, not a re-show).** Confirm the per-hint path
   uses `compy.input.configure{ prompt = msg }` — live-update while active, pending-stash while hidden — so
   no `show()`-while-active warn is produced. Grep the smoke-load output for warn-spam.
4. **AC-9 nested-checkout delivery — the big one this chunk.** balloons must be delivered as **uncommitted
   working-tree changes** with an **untouched `.git`**: (a) the M8-02 commit to THIS repo touches ONLY
   `outcomes/M8-02.md` (+ an optional `tests/input/*` row) — NOT any `src/examples/balloons/` file; (b)
   `cd src/examples/balloons && git status && git log --oneline -1` shows **no new commit** (HEAD unchanged
   from upstream) and the edited files as **unstaged working-tree modifications**; (c) the ledger lists
   every edited balloons file path-by-path. Any balloons file inside the M8-02 repo commit, or any new
   commit / staged change inside balloons `.git`, = **corrective-take** (AC-9 breach).
5. **AC-8 edge cases hold.** stop-while-active (silent hide + full reset), show-while-active (no-op + warn),
   validator-reject lock — confirm the ledger shows these hold for the migrated example (mostly via the
   existing `#input`/`#m7` contract suite, since balloons can't be keystroke-driven headless). Not
   "trivially assumed" — the ledger should point at where each is covered.
6. **AC-6 natives untouched; suite green.** No in-repo example or native edited by this chunk (M8-01 is
   already landed — its files must NOT reappear in the M8-02 diff). Suite 808(+N)/0/0/4.
7. **Rules limits** on any changed balloons code + the optional test: line ≤64, fn body ≤14, params ≤4,
   nesting ≤4. balloons is looser historically (report-don't-fix pre-existing); new `on_text_entered`/
   `after_submit`/terminal-shim closures should be tidy — flag egregious NEW bodies.
8. **Scope fence.** No legacy global removed (all six STILL in `consoleController.lua` — grep-confirm;
   removal is M8-03). No `input()`/`input_ref`/`create_input_handle()` change. No `text_input` dead-write
   removal. No in-repo example / `evaluator.lua` / routing / surface edit. Any of these = finding.

## Verification you must do yourself (verify-don't-trust)

- Re-run `busted tests` → confirm the count + any new contract row is real and green.
- Headless smoke-load balloons (`xvfb-run -a love src play src/examples/balloons 2>&1 | head -60`) →
  traceback-free, no `show()`-while-active warn-spam. Honest ceiling: no keystroke injection → real
  compose/submit/re-prompt stays a **human hand-play gate** — confirm the ledger says so, doesn't overclaim.
- Read the balloons `terminal.lua`/`ui.lua`/`main.lua` **working-tree** files directly (not via parent
  `git diff` — they're untracked in the parent). Confirm the migration matches the ledger's before/after.
- `cd src/examples/balloons && git status --short && git log --oneline -1 && cd -` → prove `.git` untouched,
  no new commit, edits are unstaged working-tree changes (AC-9).
- `grep -rn -E 'user_input|input_text|input_code|validated_input|write_to_input|astv_input'
  src/examples/balloons` → **zero live calls** (comments/README hits OK).

## Report-don't-fix already logged

balloons `main.lua` trailing test-comment cruft (L108-140) is pre-existing — confirm the implementor
**noted, did not clean**. Any leaking example globals / `action_map` quirks are pre-existing — noted, not
fixed. If the implementor fixed a pre-existing balloons wrinkle beyond the migration, that is a
scope-fence break worth a flag.
