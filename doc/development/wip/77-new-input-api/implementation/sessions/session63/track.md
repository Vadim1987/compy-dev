# session63 — track

## 2026-09-01 — boot

- Fresh start: no `track.md`, no `report.md` on disk before this entry → §2 "fresh start" branch.
- HEAD `3dd14192` (session62 wrap). Working tree: only the known untracked anomalies
  (`broken-busted/`, `claude.sh`, `input-pr-slices.tar.gz`, `repos.txt`, `src/STEPS.md`,
  `src/examples/{balloons,keyboard,maze}/`, `worklog.md`). Nothing of the owner's staged.
- Baseline confirmed: **1032 / 0 / 0 / 10** — matches the prompt. Go-signal.
- Read: `agents/sessions.md`, `agents/validation.md`, `session63/prompt.md`,
  `session62/report.md` (predecessor, side-track, closed), `ROADMAP.md` in full,
  the BACKLOG debt entry behind `BUG-02-01`.
- Predecessor kept a track and a report; no reconstruction needed.
- Owner asked for a **briefing on roadmap status and the task before execution** — briefed, waiting.

## 2026-09-01 — BUG-02-01, evidence gathered

- Owner reframed the row's question: *effect of the bug; any sane reason to want an unsplit
  element; lean to normalisation unless it complicates code or handcuffs the user.*
- Characterised in code + probe (probe in scratchpad, never committed). Note:
  `validation/notes/BUG-02-01-list-branch-weighing.md`.
- Three findings beyond the BACKLOG entry: `after_submit` payload differs (Decision 37's line
  list), the validator sees one line where two were meant, and the rendering is now read from
  the draw code — **the two draw paths disagree with each other**, both via `gfx.print`.
- The state is unreachable by typing, by paste, by any in-tree caller, and there is **no content
  getter on `compy.input`** — so no round-trip to preserve. Not a capability.
- Fix candidate is ONE call: `InputText(string.lines(clean))`. `string.lines` is already
  polymorphic and `split_array` preserves empty lines. Applied → suite 1032/0/0/10 green,
  re-probed identical to the string branch, then **reverted**. Tree clean; ruling is the owner's.
- Base check: non-splitting pre-existing, but the sanitising loop and the choice of what to
  normalise are ours.
- Parked finding: string/table branches disagree on `_update_cursor`, and `jump_end` may make it
  redundant. Not this row.

## 2026-09-01 — BUG-02-01 ruled FIX, executed, closed

- Owner ruling: **fix**, and the reason is the rule — *"same as for utf-8 sanitization: we need
  cursor to be set without ambiguity"*. Recorded as a rule, not a preference: `(line, column)`
  addressing is what both normalisations protect. This is the design-level answer pattern again
  — the category, not the patch.
- Tests first: 4 breaking cases, **all seen to fail** (1032/4 fail) before the fix. Then one call.
  1032 → **1036**, green at every commit.
- Three commits at the seam: `2986fd80` production fix · `dd19cf64` guide + internals + CHANGELOG
  · `99ad8150` debt retirement + roadmap.
- **lua-lsp bridge was DOWN** (broken pipe, twice) — no diagnostics pass. Stated in the fix
  commit rather than left implied; the suite and the probe are what back the change.
- The guide's rule went into "Live changes" right after *"Characters, not bytes"* — same rule
  about the same thing, so it reads as one paragraph rather than a bolt-on.
- Two stale sibling claims found and corrected while landing, both saying the list form was fine:
  the CHANGELOG's *"the list form always worked"* and `T-MULTILINE-STR`'s *"which is what the
  table branch already did"*. **A fix that makes a neighbouring claim false is a two-place edit.**
- Entry retired **unslugged** — BACKLOG → RETIRED without passing ACTIVE, per the register's rule.
- Weighing note cited from ROADMAP only, NOT from the debt register: a `wip/` path in the
  persistent corpus would add a site to `FIX-01-02`.
- Parked, still not investigated: string/table branches disagree on `_update_cursor`, and
  `jump_end` may make it redundant.

## 2026-09-01 — Decision 38, the unification, and a standing rule

- **Owner rule (standing, behavioural):** *never leave debt in the track without registering it
  with the ledger.* A track dies with the session; the ledger is persistent corpus. Applied
  immediately — the cursor fossil got its own RETIRED entry (`64441d69`) rather than staying a
  track line. Saved to memory.
- **Decision 38** created (`c7c6b151`): content is normalised so the cursor address is
  unambiguous. Written as the general rule, not as the fix — the owner's reason generalises past
  `set_text`. Bounded twice on purpose: not about return payloads (Decision 37's), and
  **normalisation is not validation**.
- **The cursor disagreement, answered:** the call was **inert**, in *every* revision. `472c6bba`
  (the transitional triplet, the commit that introduced it) already ended `set_text` with an
  unconditional `jump_end`. `_update_cursor` sets `.c` from the old cursor line in the new text
  and `.l` to `#t` — incoherent by construction — then `init_visible` replaces the visible object
  and `jump_end` overwrites the cursor. Nothing survives.
- Mutation-tested **before** deleting: 5 cases × both spellings, byte-identical snapshots.
  The shape was copied from `_set_text_line`, where it IS live. `_update_cursor` stays.
- **Unified** (`9c718a56`): `normalized_lines` + one storage path, body 19 → 10 lines. 1036 → 1038.
- Ledger gate went FIRST (decision, then code), matching `ARC-01-03` / `ARC-02-01` precedent.

## 2026-09-01 — owner challenges the fossil framing, and is right

- Owner: *"function named update_cursor but effectively doing jump_end looks broken -- maybe its
  intent is to move cursor to desired position, not the end -- and this intent is mistakenly not
  implemented?"* **The instinct was right; my framing stopped one question early.** I answered
  *was it ever live* and never asked *what was it for*.
- **Archaeology:** pre-multiline the whole body was `self.cursor.c = utf8.len(t) + 1` over a
  **string** `entered` — seat the caret at end of content, correct then, and literally what
  `jump_end` does now for a line list. `19351528` (2023-07-17, multiline) rewrote it to index a
  list and **measured the wrong line**: needed `t[#t]`, used `t[cl]`.
- **Probe:** `{'one','twotwo','xx'}`, caret on l2 → `_update_cursor(true)` gives **(3,7)**.
  Line 3 is `"xx"` — positions 1..3. **Out of range on the line it names.**
- The empty `else` is **not** the missing intent (the other half of the challenge): pre-multiline
  was `if destructive then … end` with no else; the migration wrote the no-op longhand.
- **Mechanism:** it writes `cursor.l`/`.c` as raw fields, bypassing `move_cursor`, which validates
  range and measures on the line it moves to. `_update_cursor` and `_advance_cursor` are the only
  raw writers.
- **THREE of my own claims from earlier today were wrong and are corrected** (`cd56778b`):
  `_set_text_line` does NOT call it live — guarded by `if not keep_cursor` and **all 7 callers
  pass true**; "the line it reads is the line it just wrote" was asserted unchecked and is false;
  and Decision 38 read as if leaving the function in place ratified it.
- Filed BACKLOG unslugged: unobservable today (`clear_input`'s content is empty, so every line
  measures zero → (1,1) correct *by accident*). Repair-vs-delete is the owner's call.
- **Pattern worth carrying:** the fix that deletes a call site is not the end of the enquiry —
  ask what the callee was *for*. Also: "X calls it live" is a reachability claim and needs the
  callers checked, not just the call site.

## 2026-09-01 — owner rules: register, don't fix; comment at the site

- Ruling: **keep it registered, do not fix.** Owner's reading: *"makes no harm unless some other
  code tries to use it or call sites change"* → **subject for pure refactoring**, which will
  likely remove it. Matches the entry's own delete option.
- Asked for a **one-line comment at the place of the defect**: name it, cite the entry, say it is
  **postponed, not fixed**.
- **Deliberately NOT an `INTERIM:`/`REMARK:` marker** — those must be zero before release and are
  removed by the gate; this one must *survive* release, which is exactly when a reader needs it.
  So: durable payload-2 comment. Marker gate re-run, still clean.
- Carries the defect itself, not a bare pointer (`commenting.md`, *"A reference is not an
  annotation"*). Costs 3 lines at the 64-char limit, not 1 — the citation path is long.
- Shortened the entry heading to *"measures the column on the wrong line"* so the citation fits
  un-truncated, and updated its **two** existing citations in the same commit (Decision 38,
  `internals/user_input.md`). Old wording greps clean — the pass that causes an orphan owes the fix.
