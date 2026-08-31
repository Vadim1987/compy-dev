# session60 — track

## boot — 2026-08-31

- Fresh start: `session60/` held only `prompt.md`; no prior `track.md` → no re-entrance recovery.
- HEAD `b5022530` (`docs(session59): wrap — revalidation closed, report, session60 prompt, pointer`).
- Tree: only the known untracked scratch (`broken-busted/`, `claude.sh`, `input-pr-slices.tar.gz`,
  `repos.txt`, `src/STEPS.md`, `src/examples/{balloons,keyboard,maze}/`, `worklog.md`) — matches
  the anomaly list in `agents/validation.md` §Hard guardrails. No tracked working-tree changes,
  so nothing of the owner's to protect.
- Suite: **1023 / 0 / 0 / 10** — baseline confirmed, matches prompt, report and `ROADMAP.md`.
- Read: `agents/validation.md`, `agents/sessions.md`, `session60/prompt.md`,
  `session59/{report,track}.md`, `ROADMAP.md` (sequence, status, defect-sprint sections).
- Prompt is a **wait-for-human placeholder** (§5: revalidation is followed by one). Not starting a
  sprint on my own reading of the roadmap — briefed the owner on state and options, awaiting the
  session mandate.

## mandate — 2026-08-31

- Owner: **open `BUG-01`**, with **`BUG-01-09` in front**, then the other platform bugs, then the
  examples/games rows. Mode: **execution** (the rows are already sized; each opens with its own
  small analysis).
- Live rows after the closures: **`-09`, `-04`, `-05`** (platform) → **`-11`, `-07`** (examples).
  Closed already: `-01`, `-02`, `-03`, `-06`, `-08`, `-10`.
- Owner: use sub-agents under the token-economy charter (Sonnet for mechanical, Opus for judgment).
- Owner: **when all of BUG-01 is done, run a separate cold sub-agent peer review** of the changes;
  its prompt and report land in the worktree; act on its findings.

## BUG-01-09 — DONE — 2026-08-31

- Two breaking tests written first, both reproducing the row verbatim (previous content standing).
- Fix: the string branch of `UserInputModel:set_text` assigned `self.entered` only when the string
  held one line. Split with `string.lines`, hand every line to `InputText` — what the table branch
  already did. Single-line string → one-element list, so that path is unchanged.
- **Base-checked, and it changes the story: the defect is PRE-EXISTING.** The `== 1` guard is at
  `3256aac` in the same shape. What this feature added is the documented shape and the surface that
  reaches it. Recorded in the CHANGELOG, the debt entry and the roadmap row — the commit message is
  not enough (owner directive 2026-08-10).
- Sizing note: our work grew `set_text` 18 → 24 lines; the fix leaves it at 19. No size refactor of
  another author's function beyond what our own work bloated.
- The debt file's head carries an owner `REVIEW:` remark — **no commit hashes in that file**. The
  base sha is not one of those; it is used six times already as "the PR base".
- Commits: `32f8345d` (fix + 2 tests + CHANGELOG "Fixed") → `4a4e6687` (debt RETIRED + roadmap).
- Suite **1025 / 0 / 0 / 10**.

## BUG-01-04 — DONE — 2026-08-31

- Delegated evidence to **Sonnet** (prompt + report on disk under `validation/{prompts,outcomes}/`).
  Re-verified its claims in code before acting — all held.
- The finding that mattered: **the asymmetry is OURS.** At `3256aac` `src/util/key.lua` is 53 lines
  with no combo machinery and `controller.lua` has neither `combo_string` nor `RESERVED`. Opposite
  provenance to `BUG-01-09`, which was inherited. Both go in the PR narrative.
- Not a design escalation after all: **Decision 8 already ratified case-insensitivity** ("register
  `['Ctrl+S']` and still match"), and `normalize_combo`'s docstring asserted the agreement out loud.
  `combo_string` just did not implement it. So this is a fix, not a ruling.
- Narrower than "deep" looked: only textinput carries a cased trigger; keypressed/keyreleased are
  LÖVE key constants, the reservation tables have no textinput channel, `'*'` lowers to itself.
- Three breaking tests first (serialisation bare + modified, and the end-to-end dispatch).
- The limitation it makes explicit — a shortcut cannot tell `I` from `i` — is written into
  `doc/input_api.md`, not just the commit message.
- **Stale citation caught:** the echo backlog entry claimed the case defect confined its paired-
  shortcut idiom to bare combos. Corrected. Third instance of session59's "a fact written in two
  places, one maintained" pattern — it predicted this.
- Commits: `4a58b996` (fix + 3 tests + guide) → `d5c38d76` (debt RETIRED + roadmap + the citation).
- Suite **1028 / 0 / 0 / 10**.

## BUG-01-05 — DONE — 2026-08-31

- Delegated evidence to **Sonnet** again (prompt + report on disk). Re-verified the three sites,
  the reproduction, the base check and the test-coverage claim in code.
- **The row's own framing was wrong.** It said "which is right has not been decided" — the unit IS
  decided: characters, in `jump_end`, `jump_line_end`, `is_at_limit`, `_update_cursor`,
  `cursor_left/right`, `cursor_vertical_move`, the mouse translation and the view's pixel math.
  Three clamps were the outlier. So there was no design call to put to the owner, only a fix.
  The entry also named neither function; it named "the cursor-setting path".
- **Mixed provenance, a third pattern.** `move_cursor`'s byte bound is pre-existing and was inert
  (18 internal callers all pass character values). `set_cursor_pos` and `_clamp_cursor_pos` are
  ours and copied the byte convention *deliberately* — comments said so — which is what made the
  gap externally reachable. Fixed all three: leaving the outlier would make our two differ from the
  function they were written to match.
- Bound only narrows (`ulen` ≤ `#`), so nothing that passed before is refused. Suite confirms.
- `doc/input_api.md` contradicted itself in consecutive sentences (caret "between characters",
  ranging over `1 .. #line + 1`). Fixed with a multi-byte example — the ASCII one cannot show it.
- Commits: `e75a48d8` (fix + 2 tests + guide) → `311dbd18` (debt RETIRED + roadmap).
- Suite **1030 / 0 / 0 / 10**. **All three platform rows of BUG-01 are now closed.**

## BUG-01-07 — DONE — 2026-08-31

- Fixed in the **balloons repo** (`53f1c52`), which is separate and opens its own PR. Never pushed.
- The shadow had **no second reader** — written and read only inside the `ui_set_hint` →
  `ui_draw_hint` pair — so collapsing them loses nothing. Three named fossils went with it.
- `ISSUES.md` line 1 (owner's untracked scratch) is the same symptom from the user's side, which
  corroborates the fossil reading: "resetting hint does not work unless previous terminal instance
  was flushed and had real input in it".
- **Not runtime-verified** — balloons has no suite and needs a display. Said so in the commit, the
  debt entry and the roadmap rather than letting "done" imply more than it is.
- Found and NOT fixed: `ui_draw_status` reads `ui_messages.results`; nothing sets it (`result`,
  singular). Dead branch, no misbehaviour, unrelated to input, not ours → reported, for the owner.
- Ledger: `c5128f70`.

## BUG-01-11 — weighed, awaiting the owner — 2026-08-31

- The row opens by weighing, and **the premise does not survive the code**. Note written:
  `validation/notes/BUG-01-11-maze-neutralisation-weighing.md`.
- `ctrl_pressed` is maze's **control-mode slot** (`controls.lua`: `keys()` → `handle_key`,
  `plan()` → `plan_key`), not a neutralisation idiom. Clearing it says "no control mode active".
- The row contrasts `draw_main`/`maze_main` with `core_editor.lua` — but `core_editor.lua:147`
  (`arm_editor`) does **the same `ctrl_pressed = nil`**. The contrast inverts.
- And `core_editor.lua:68`'s `is_shown` is a **show-vs-configure branch**, not a double-handling
  guard. Different question, different shape from turtle's whole-handler return.
- Traced the path the cold review could not: hook (tier 2) fires while the field is open →
  `SYSTEM_KEYS[k]` nil → `ctrl_pressed` nil (set by `arm_editor`) → widget alone gets the key.
  No double-handling, by construction.
- Recommendation: **wontfix, and correct the premise** — the entry currently tells a reader maze
  uses the wrong idiom, which is the misleading part. **Owner's call; no code either way yet.**

## owner remarks — 2026-08-31

1. **"Field is open" is self-ratified jargon** — mine, five times in my own note, by a session whose
   prompt states the rule. Corrected in place; `FIX-02-09` widened: **"docs" includes comments in
   `src`, `tests` and the examples on equal footing**, and the row is confirmed **late**, because
   the vocabulary is still being minted while the sweep waits.
2. **`BUG-01-11` wontfix**, with a sharper reading than mine: the pattern is not merely harmless,
   it is the shape the guide advises — *"Perform hardware polling before complex processing"*.
   Named after the keyboard where its role is mode selection; taste, not fixed.
3. **balloons `results`** — investigated: not a typo but a self-consistent **phantom pair** (reset
   clears it, draw reads it; the real field is `result`). Repairing it to `result` would be a no-op
   during play and a **regression** across games. Deleted the dead branch instead (`c2bd9b9`).
   The owner's polling hypothesis is right and worth keeping: `ui_messages` IS the per-frame draw
   buffer, which is why `status`/`result` belong there and `hint` did not.

## cold peer review — 2026-08-31

- Opus, cold: told what NOT to read (my track, my resolutions, my note, the evidence reports) and
  given the **pre-sprint** row text from `git show b5022530:…`. Prompt + report on disk.
- **Verdict: approve with comments.** All three platform fixes fix their rows; all five new tests
  fail pre-fix for the right reason; **all three provenance claims verified correct** against
  `3256aac` — the ones headed for the PR description.
- **Four findings, all verified in code before acting, all real:**
  - **My "by construction" claim on maze was false.** `jump_level` → `start_level` →
    `cur_controls()` re-arms `ctrl_pressed` and hides nothing. The invariant holds by **level
    ordering**. Ruling unaffected; claim corrected in three places; the latent maze bug is
    reported, not fixed.
  - **My guide sentence was false** — "a shortcut cannot tell the two cases apart". `dispatch`
    passes the raw payload, so it can, from its own argument. Fixed and pinned with a test.
  - **`BUG-01-05` had a missed caller and I regressed it.** `_apply_eval` feeds the parser's
    **byte** column into the now-character bound → the caret stopped moving on multi-byte lines.
    Console/editor path. Fixed with `char_col` + a breaking test. My commit message's "nothing that
    passed before is refused now" was wrong.
  - Two wrong facts in `32f8345d`'s message (`configure{text}` **raises**; `apply_config` is gone).
    Messages are immutable, so corrected in the debt entry the PR description reads.
- Lesson: **the sprint's own claims were the weakest part, not its code.** Three of four findings
  are false statements in prose I wrote, none in a fix.
- Suite **1032 / 0 / 0 / 10**.

## owner follow-ups + wrap — 2026-08-31

- **maze bug relocated on the owner's prompt.** It was only in compy's ledger and my note — both
  ephemeral to a maze reader. Now `ISSUES.md` in the **maze repo** (`28213c7`, first tracked one
  there; balloons' is untracked scratch), with both defects and an explicit note that the
  control-mode slot is *not* the defect. Compy's entry repointed at it.
- **View byte/char mismatch → BACKLOG, no slug** (owner: not fixing this release). Names `char_col`
  as the reuse and says not to fix the view alone — the unit belongs settled at the boundary.
- **Filing it caught damage I did.** Retiring `T-MAZE-NEUTRALIZE` sliced to the next `###` and took
  `## BACKLOG` with it; the file sorts by release scope, so ~20 deferred entries had silently
  become ACTIVE. Restored. **Lesson: slice to the next heading of the SAME level, or verify the
  section list after.**
- **UTF-8 doc commissioned and written** — `internals/text_encoding.md`, standalone and
  roadmap-agnostic, indexed in `agents/rules.md`. Load-bearing fact: **three** `utf8`
  implementations selected at load by `util/string/utf.lua`, so suite and app need not exercise the
  same one. Stated the limit rather than hiding it: green here is LuaJIT + `lua-utf8`, not the
  owner's PUC Lua.
- **Wrapped.** Report written, `session61/prompt.md` written (revalidation first, then stand ready
  for the owner's architecture question), pointer repointed, boot-ritual baseline 1023 → 1032.
- Suite **1032 / 0 / 0 / 10**.
