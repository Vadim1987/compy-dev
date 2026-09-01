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
