# session37 — track

## 2026-08-11 — boot

- Booted per `agents/validation.md` → `agents/sessions.md`. **Fresh start**: `session37/` held only
  `prompt.md`, no `track.md` / `report.md` (sessions §2 row 1). Track opened now.
- HEAD `785aeca3` "docs(session36): wrap — report, session37 prompt, repointed pointer", branch
  `feature/77-newapi-analysis-s20260615`. Working tree: **no tracked modifications**; only the known
  untracked scratch (`claude.sh`, `src/STEPS.md`, `input-pr-slices.tar.gz`, `doc/tall_blocks.md`,
  `worklog*`, `repos.txt`, `doc/development/wip/{clarification,personal-notes,pull-26}/`) and the
  three nested example repos.
- **Baseline confirmed: `busted tests` → 946 / 0 / 0 / 10.** Matches the prompt; the 10 pending are
  the sanctioned count (3 routing-grid + 7 reserved-combo outlines), not drift.
- Read in full: `agents/validation.md`, `agents/sessions.md`, this prompt, session36's `report.md`,
  `prompt.md` and `track.md`, the step (`S27-triage-and-plan.md` §15.4) with its §4 P18/P9b rows,
  §16.3, and the parent plan's Phase U + its example-half ordering note.
- **Mode: execution** (P18, the keyboard deepfix absorbing the `textinput` heal). A design question
  appearing is a reason to stop and raise it, not to decide it.
- **Owner orientation at boot:** `repos.txt` (untracked) names the upstreams that matter —
  keyboard's is `origin/dsent/dev`, maze's is `dsent/dsent/dev`; *"appropriate origins are fetched,
  but not checked out."*

### The prerequisite, measured rather than assumed — it has NOT been reconciled

The step is gated on Phase U's example half (parent plan; owner intent 2026-08-11: pull each
upstream into **its own branch**). State of `src/examples/keyboard` at boot:

- On `newinput` at `05cedec`, clean. Local branches include `dsent/dev` (**8 behind**
  `origin/dsent/dev`) and a fresh `newinput-backup-copy-20260811` — so the fetch happened; the
  reconciliation did not.
- `newinput` vs `origin/dsent/dev`: **13 ahead / 36 behind**, merge-base `c904338`.
- Upstream since the base: **24 files, +5227 / −804**, including `hunt.lua` deleted and
  `hide.lua`/`props.lua`/`stream.lua`/`train.lua`/`words*.lua`/`markov.lua` added.
- **Material to P18:** upstream did **not** touch `input.lua` or `help.lua`, but **did** touch
  `alt.lua` (+28/−…) and `keyboard_view.lua` (**509 lines**) — two of the step's ten `INPUT` sites
  live in `keyboard_view.lua:171,178` and one in `alt.lua:203` (the hand-matched Ctrl+Alt+H).
  So the stale-base argument is not hypothetical here.
- `maze` likewise: on `newinput` at `a045fdb`, clean, with its own backup copy dated today and
  `dsent/dsent/dev` fetched.

Task restated to the owner with this blocker before any design work — awaiting their ruling on who
performs the reconciliation and whether P18 proceeds.

## 2026-08-11 — owner rules: I own the merge; but first, read the upstream for input

Owner: *"yes, you rule — new branch, merge ruled deliberately. And then we'd have to
review/reprocess updated code because there could be more places for new API adoption. But first
of all I need your evaluation of what's new in the origin commits since merge-base: did the author
invent new input mechanisms, reconsider old input practices? This validation is important to do
before any merges."* Written to disk on their instruction.

- **Mode named and held: research + analysis.** Nothing checked out, merged or edited; the trial
  merge was computed **in memory only** (`git merge-tree --write-tree` → tree `c0a1e100`,
  **exit 0, no conflict**). Deliverable:
  `../../../validation/reviews/S37-keyboard-upstream-input-assessment.md`.
- **Did NOT delegate.** The mechanical half (enumerating input touchpoints across 5227 new lines)
  was a candidate for a Sonnet worker, but the briefing cost matched doing it, and every fact here
  is one I would have had to re-verify before ruling a merge on it. Noted because the charter's
  default is to delegate down.
- **Q1 — new mechanisms: exactly one.** `bubble.lua` judges a key by **how long it is held**
  (`BUB.key` set at keypressed, cleared at keyreleased, `BUB.t` accumulated in update, popped on
  timeout). Event-derived held state, but with **bounded drift** — a lost release pops the bubble
  rather than wedging a flag. **Not writable with anything the API has**, and an independent
  second use case for the register's *"a chord that gates a state while it is held has no
  vocabulary"* — written by the author with no knowledge of that discussion. Recommend: leave it,
  cite it.
- **Q2 — reconsidered practices: no, the reverse.** Upstream's `input.lua` is **byte-identical to
  the merge-base**; `INPUT.held` and `inputStale` are still the model there, and the new
  `words.lua` was written **on** `inputStale` — the "drop the glyph if its key is held" scheme our
  own header names as what made the Alt scene deaf on hardware. The practice was propagated, not
  revisited.
- **THE FINDING: the clean merge produces a broken tree.** `words.lua:221` calls `inputStale`,
  which our branch deleted for `spendGlyph`; in the merged tree the name matches only its own
  comment and call, with no definition. Git cannot see it — no hunk touches both files. Words
  raises at the first glyph typed.
- **And it widens the heal's ratified design:** `internals/examples/keyboard.md` assumes **one**
  `textinput` judge (Alt). After the merge there are **two**. Whatever replaces `spendGlyph` must
  serve both — so `words.lua` must NOT be hand-fixed during reconciliation; that is P18's single
  planning pass, or an explicitly interim commit P18 deletes. Owner's call, raised not decided.
- Smaller, all verified in-tree: the `INPUT` dissolution shrinks **ten sites → eight** (upstream
  `619c8cf` deleted the shift-label read); `isMod` grows **3 files → 6 call sites**, each paired
  with a hand-written `capslock` test; upstream added `love.mouse.setRelativeMode(true)` at boot
  claiming *"the runner restores it on exit"* — **checked in the platform and it is false**
  (`stop_project_run` makes no `love.mouse` call; only `error_explorer` does, on crash), which
  splits into a cheap example-side fix and a release-shaped question about framework teardown of
  device modes; upstream also hand-reformatted `main.lua` (13 trailing-whitespace lines) and
  deleted the two comments naming Alt+P pause and held Alt+H help.
- **No new hand-matched chords** (the teacher chord still routes via `onNotch` into our
  `ctrl+alt+up/down` shortcuts), **no `love.keyboard.isDown` anywhere upstream**, and no `love.*`
  input callbacks in the eight new/changed scenes — they all register scene descriptors, which is
  the seam the migration already owns. That is why 5227 new lines cost so little input-wise.
- **`maze` was not examined** — its own upstream, its own pull, gating P17; it needs the same pass.
- Nothing was run: no smoke, no keystrokes. Said in the document's limits section rather than left
  to be assumed.

## 2026-08-11 — owner rules the merge shape; EXECUTION: the merge lands, with its correction

Owner, on the ancestry question: *"in practice at the end I would prepare a diff against upstream
and will create a brand new branch off upstream with a single new commit or two. Given that, let's
still do a traditional merge, because I may want re-merges if upstream updates again — so better
preserve ancestry for now. Separate correction commit after merge with a comment
describing/explaining the defect is fine."*

- **The delivery shape and the working shape are decoupled**, and that is the ruling's substance:
  ancestry here buys cheap **re-merges**, not the PR's shape, which is assembled fresh off upstream
  regardless. So the usual argument against merge commits does not apply.
- **Mode: execution.**
- **A correction to my own boot entry:** the local branch named `dsent/dev` is **not** a tracking
  mirror of upstream — I read `8 36` as "8 behind" and it is a **divergence**: those 8 commits are
  the first eight of our own migration. The upstream snapshot was therefore taken from
  `origin/dsent/dev` directly, onto a new branch `upstream-dsent-dev-20260811`. Recorded in the
  parent plan so the maze pull does not repeat it.
- **Merge `17289e9`** (`--no-ff`, message carries the known defect and the reason for merging
  rather than rebasing/squashing). **Verified the merged tree is byte-identical to the trial tree
  `c0a1e100`** computed before the owner ruled — so the analysis they ruled on describes the tree
  that exists.
- **Correction `ca6d5df`** — `words.lua` routed from the deleted `inputStale` to `spendGlyph`. The
  comment carries what the commit cannot: why restoring the call is not restoring the intent (the
  held-key premise is order-dependent and is what made the Alt scene deaf), and that the line is
  **expected to be deleted** by the heal rather than preserved. Deliberately not marked with the
  `INTERIM:` token — the marker gate greps `src/`, and the nested repos live under it.
- **Smoke, line-buffered per the standing constraint:** `timeout 25 xvfb-run -a stdbuf -oL -eL love
  src play src/examples/keyboard` → *"Running 'play'"*, no raise, killed by the timeout (exit 124).
  The channel is known to carry errors: an earlier run with a wrong path surfaced its failure on
  the same pipe. **The Words scene itself was NOT exercised** — reaching it needs keystrokes this
  container cannot inject, so the judge is reasoned and read, not run.
- **Completeness backstop beyond the one known orphan:** extracted every defined function name and
  every called identifier across the merged tree and diffed them; the only unresolved names are
  method/field calls (`SOUND.match`, `s.keypressed`, `fn.stop_here`). No second orphan hid behind
  the first.
- **Bound into the plans, per the rule that an amendment lives in the step that acts on it:**
  §15.4 gains an [S37] block (two `textinput` judges now, the interim call to delete, `INPUT`
  ten→eight sites, `isMod` six call sites, `bubble` recommended out of scope, the relative-mode
  item), and the parent plan's Phase U records the example half as done for `keyboard` with the
  local-branch trap. **`maze` still owes both steps** — the input reading, then the merge.
