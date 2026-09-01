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
