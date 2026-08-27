# session50 track — execute ARC-02

## 2026-08-27 — boot

- Fresh start: no prior `track.md`/`report.md` in `session50/`; re-entrance guardrail → begin.
- HEAD `9a27e044` ("docs: reorganize status.md"). Working tree clean of tracked changes;
  untracked = the known anomalies (`claude.sh`, `input-pr-slices.tar.gz`, `src/STEPS.md`,
  `src/examples/{balloons,keyboard,maze}`) plus owner scratch (`repos.txt`, `worklog.md`).
  No `docker/compose.yml` diff present this time.
- Baseline suite: **979 successes / 0 failures / 0 errors / 10 pending** — matches the prompt.
- Read: `agents/sessions.md`, `agents/validation.md`, `session50/prompt.md`,
  `session49/report.md`, the ARC-02 plan, the ARC-02 cold review, `ROADMAP.md` ARC-02 sprint.
- Mode: **execution** (prompt is explicit). Watch the boundary; anything that reopens the
  design goes to the owner as a ruling, not an implementation detail.
- Task understood: nine steps `ARC-02-01`…`-09` in roadmap numbering (plan + cold review use
  the pre-insert numbers; crosswalk on the roadmap sprint).
- Reported the task back to the owner before starting, per their instruction.

## ARC-02-01 — the gate (commit `b325826d`)

- Owner ruled it an **addition**, not an amendment, on the cold review's `force` argument.
- Decision 15 gains a `show`-only category paragraph + status pointer + one sentence closing
  the "hidden `configure{text}` is a runtime-state warn" reading. No sentence withdrawn.
- Decision 35's "what this amends" re-titled/re-argued to match — the two entries contradicted
  each other otherwise. Flag to owner: I edited ratified Decision 35 text, on their ruling.
- ROADMAP row marked ✅ with the framing.

## ARC-02-03 — single-policy move (commit `6923859c`)

- `apply_config` → `configure_core` (project-owned) + `reset_content` (user's content).
- `UserInputController:configure`'s `live` filter table deleted here, not at `-05`: once
  configure_core cannot see `text`, the filter is dead weight and keeping it two commits is worse.
- Behaviour-neutral, no red test — cold review F3 predicted exactly this. Suite 979 throughout.
- Four stale `apply_config` comment citations renamed (1 src, 3 specs).

### Mistake worth keeping: `git add -A src/`

Swept the three nested example repos in as gitlinks **and** `src/STEPS.md` into the commit.
Caught on `git show --stat`, fixed by `git rm --cached` + amend. **Stage explicit paths.**
`-A` over a directory holding untracked anomalies is exactly what the guardrail warns about.

## ARC-02-04 (`af1e8ec6`) — re_show deletes, show composes

- 3 breaking tests seen to fail first. `re_show` gone; refusal warning moved into `show`.
- BUG-01-06 + highlighter-deferral sibling dissolve. 981.

## ARC-02-05 (`7b927249`) — configure refuses text/cursor; pending deletes

- 6 breaking tests seen to fail first. `pending`, `consume_pending`,
  `stash_hidden_configure`, the widget `pending` field, one `WIDGET_STORES` member all gone.
- Cold-review F2 handled: kept `merge_callback_keys` on the hidden path + nil-widget guard.
- F5 confirmed: hidden `configure{prompt}` one-shot → permanent. Third deviation line.
- F8 done: `bad_key_message` gains the show-only branch. **Verified by running it**, not by
  reading the format string. 984.

## ARC-02-06 (`cad0bb25`) — highlighter one home

- Ruled shape (callbacks = truth, evaluator resolves) implemented as `bind_highlighter`.
- **Resolution, not a forwarding closure**: the model branches on the TRUTH of
  `ev.highlighter`; a forwarder is always truthy and would have silently replaced the
  `validation_hl` fallback. The red test's output `{ {} }` is that fallback — visible proof.
- Bound only where the evaluator is the widget's OWN (console/editor share theirs and carry a
  LANGUAGE highlighter). **Probed**: A resolves its fn, fresh widget resolves nil, console
  keeps its Lua highlighter.
- Fixture calls the same production method. 985.
- Discovered, not fixed: `CONFIG_CALLBACKS` and `CALLBACK_KEYS` now duplicate contents across
  two files.

## Unnumbered production fix (`6bb1d7a4`-ish, before -07) — show's raise pointed at the framework

- **Found by probing, not by reading.** `show({nope=1})` reported `consoleController.lua:739`;
  `configure` was correct. Decision 15's Consequence promises the project's own line.
- Cause: `check_keys` uses a fixed error level and the two entry points sat at different call
  depths (`configure` inline, `show` via `api_show`).
- Fix: lift `configure` into `api_configure` so depths match, then level 4 is right for both.
  Levelled the depth rather than passing a level per caller.
- Its own commit — production fix, own cause. 986.

## ARC-02-07 (`3bade47a`) — cursor shapes

- `checked_cursor` at the boundary; `set_cursor` lifted into `api_set_cursor` for the same
  depth rule.
- **Two design calls I made — owner should confirm** (see report):
  (a) malformed shapes (`{}`, `{1}`, `{nil,2}`, scalar, string) **raise** with a framework
      message rather than defaulting to line 1 / col 1;
  (b) `cursor = false` is **unset**, extending Decision 35 statement 3's uniform-unset rule to
      a user-owned field.
- Out-of-range still clamps — that distinction is preserved deliberately.
- **My test expectation was wrong, the code was right**: `cursor = false` leaves the caret at
  col 6 (activation baseline = end of text), not col 1. Rewrote the case to discriminate
  against an explicit `{1,2}`. 990.

## Not done, deliberately

- **BUG-01-09** (`set_text` ignores a multi-line string) — the roadmap says it "belongs with
  ARC-02-03", but it is **not** one of ARC-02's nine steps. Not widening scope unasked.

## ARC-02-08 (`e4748e60`) — docs

- `input_api.md`: ownership rule, `force` as full re-setup, configure's refusal, `false` as
  uniform unset (FIX-02-12), `prompt` persistence (FIX-02-21), cursor shape rule.
- `internals/user_input.md`: configure/force sections rewritten (old text said force
  "ignores every other field" — now the opposite); + "Why `prompt` is sticky" (balloons
  rationale, persistent) and "One home for the highlighter" (the drift -06 replaces).
- debt: 5 ACTIVE retired (10 → 5). T-MULTILINE-STR's Revisit corrected — it expected to ride
  along with this sprint and did not.
- CHANGELOG: 5 bullets added/rewritten.

### Mistake worth keeping: the section-cut script ate `## BACKLOG`

First cut() stopped at the next `\n### ` only, so retiring the LAST ACTIVE entry ran straight
through the section header and deleted it. Caught by `grep -n "^## "` right after, reverted with
`git checkout --`, redone with a boundary that stops at `\n## ` too. **Check section headers
survive after any scripted section surgery.**

## ARC-02-09 (`ddfe8be0`) — sweep

- Mostly pre-absorbed by -03…-07 (suite-green forces it).
- Left: one stale spec preamble; one **pre-existing** wrong citation
  (`"Evaluators"` — no such heading, `git log -S` finds it in no revision).
- Comment gate clean. All 13 cited doc sections resolve.
- **My first citation checker reported all 13 dangling** — obviously wrong (it flagged a heading
  I had just edited). Fixed the checker before believing its output. Same shape as session49's
  loose-grep trap, opposite direction.
- Verified myself (not via the cold review) that no example passes text/cursor/force to
  `configure`: only two calls exist, both `prompt`-only.

## `ee59ccdc` — roadmap/ledger closure

- ARC-02 ✅, 9 steps ✅, status header (suite 990).
- Closed: BUG-01-06 (dissolved), -08, -10, -02 (ratified, no code), FIX-02-12, FIX-02-21.
- Filed to BACKLOG: CONFIG_CALLBACKS/CALLBACK_KEYS duplication.

## Suite arithmetic across the sprint

979 → 981 (-04) → 984 (-05) → 985 (-06) → 986 (trace fix) → 990 (-07). Docs steps added none.
**11 net; the 10 pending never moved.**
