# S37 — the keyboard upstream, read for input: what 36 commits did to the input model

**Session:** 37 (validation phase). **Mode:** research + analysis. **Date:** 2026-08-11.
**Author:** assistant, at the owner's instruction, **before any merge is performed**.
**Gates:** Phase U's example half for `src/examples/keyboard` (parent plan), which in turn gates
**P18** (`S27-triage-and-plan.md` §15.4, the keyboard deepfix absorbing the `textinput` heal).

**The owner's question, in their words:** *"what's new in the origin commits since merge-base — did
the author invent new input mechanisms, reconsider old input practices?"* This document answers
that, and reports the merge facts that answering it turned up.

---

## 1. What was examined, and how

- **Refs.** Ours: `newinput` @ `05cedec`. Upstream: `origin/dsent/dev` (per `repos.txt`, the
  upstream this repo works against). Merge-base: **`c904338`** *"Keyboard: Alt-characters fold,
  press-count engine, input hardening"*.
- **Divergence:** `newinput` is **13 ahead / 36 behind**. Upstream since the base is **24 files,
  +5227 / −804**: `hunt.lua` deleted; `astro.lua`, `astrocore.lua`, `bubble.lua`, `hide.lua`,
  `train.lua`, `words.lua`, `words_corpus.lua`, `markov.lua`, `props.lua`, `stream.lua` added.
- **Method.** All 36 commit messages read in full; then the code, on the ref rather than a
  checkout (`git show origin/dsent/dev:<file>`, `git grep … origin/dsent/dev`) — nothing was
  checked out, merged or modified. Every claim below is from the tree, not from a commit message;
  where a commit message is the source it is named as such.
- **A trial merge was computed in memory only** (`git merge-tree --write-tree`), producing tree
  **`c0a1e100`**. It is not written to any branch; it is used here as evidence about what the
  merge would produce.
- **Not examined:** `src/examples/maze` (its own upstream, its own pull, gating P17 — it needs the
  same pass and has not had one), and anything requiring the app to run. Nothing here was smoked.

---

## 2. The answer to the two questions

### 2.1 New input mechanisms — **yes, exactly one**, and it is a held-key mechanism

**`bubble.lua` ("Blow the bubble", commit `4fc3cc5`) judges a key by how long it is held.** The
child holds the target key to inflate a bubble and releases while the edge is inside a ring band.

The implementation is an **event-derived held-key state with a duration accumulator**:

- `BUB = { key = nil, t = 0, fx = nil }` — *"the key held right now (nil = nothing inflating); t:
  how long it has been held"* (the file's own comment).
- `bubbleKeypressed` sets `BUB.key = k; BUB.t = 0`; `bubbleKeyreleased` clears it via
  `bubbleRelease`, which scores by `BUB.t < BUBBLE_RIPE`.
- `bubbleUpdate` accumulates `BUB.t` per frame; `bubbleGrow` pops the bubble once
  `BUBBLE_RIPE + window < BUB.t`.

**Assessment.**

- This is **the pattern Decision 32 / P6 names** (do not reconstruct held state from events) — and
  it is also the case that decision's own escape clause was written for. It is *not* a mirror of
  the whole keyboard: it is one key, held for a purpose, with a **timeout that bounds the drift**
  — a lost `keyreleased` (focus loss, a swallowed event) does not wedge the state, it pops the
  bubble, which reads to the child as "too slow". The failure is a false miss, not a stuck flag.
- **It cannot be written with anything the API offers today.** A shortcut is a transition; a poll
  answers *"is it down now"*, not *"for how long"*. The missing vocabulary is exactly the register
  entry *"A chord that gates a state while it is held has no vocabulary"*
  (`technical_debt/input.md`) — and this is an **independent second use case for it, written by
  the example's author without knowledge of that discussion**, which is stronger evidence than
  anything the sprint has generated for itself. It is one key rather than a chord, and it needs
  **duration**, which that sketch does not currently cover.
- **Recommendation (not a ruling):** record it against that register entry as corroboration, and
  **leave the code alone in P18** — converting it needs a surface that does not exist and that the
  strategic frame keeps out of this release.

### 2.2 Reconsidered old practices — **no. The opposite: the practice we retired was propagated**

The upstream tip still runs the **pre-migration input model**: `input.lua` is **byte-identical to
the merge-base** (upstream never touched it), so `INPUT.held`, `inputUpdateMods`, `reservedChord`,
`appChord` and `inputStale` are all still live there, and `help.lua:11` still reads
`INPUT.held.h`.

**And a new game was written on it.** `words.lua` (commit `cd93102`, "Words & phrases") judges
typing through `textinput` and guards it with the base's staleness filter:

```lua
-- words.lua:218-221 (upstream)
-- The inputStale guard drops a held/released or chord glyph,
-- exactly as Alt does.
function wordsTextinput(ch)
  if inputStale(wordsBaseKey(ch)) then return end
```

`inputStale` (base `input.lua:112`) is *"drop the glyph if its producing key is HELD or was just
released"* — **the scheme our own `input.lua` header names as the bug that made the Alt scene deaf
on the device**, because `keypressed` and `textinput` have no fixed order: where the keypress
arrives first, the key is already held at its own first glyph and every fresh target is thrown
away. Our branch deleted `inputStale` and replaced it with the claim-based `spendGlyph`
(`input.lua:147`).

So: **the author did not revisit the model; they extended it to a second scene.** Nothing in the 36
commits argues about held state, key repeat, or event ordering. Two smaller reconsiderations did
happen, and they are real but orthogonal (§2.3, §2.4).

**This is the finding that matters most to P18**, and its consequence is in §4.1.

### 2.3 A genuine reconsideration: which key names are legitimate input at all

Two commits change what the game accepts *as a key*, which is an input-practice change even though
no mechanism moved:

- **`1c60884`:** *"A stray key press can no longer become a falling target. The old engine booked
  whatever key was pressed into its review set, so a key the keyboard reports as `select`, `f5` or
  `printscreen` became a cap no child could answer, and missing it booked it straight back."*
- **`c4c324f`:** a key the board cannot draw *"is knocked for and not drawn"*, with the boundary
  stated deliberately in `keyboard_view.lua:190-199` — `capKnown(name)` is *"the test for ECHOING A
  KEY THE CHILD PRESSED… NOT a licence to clamp a cap the game itself chose to present: an unmapped
  name on a TARGET still has to draw wrong and loud"*.

This is project-side judgement about the key namespace, and it is sound. It touches no framework
surface and needs nothing from the input API. **No action.**

### 2.4 A new device-level practice, with a claim the platform does not honour

`main.lua` gained, at boot (commit `ac7fe79`):

```lua
-- Suppress the system pointer: relative mode keeps it off the
-- screen edges so the Android nav/status bars never reveal.
-- The keyboard uses no mouse; the runner restores it on exit.
-- TODO(root-access): replace with trackpad disable on entry.
love.mouse.setRelativeMode(true)
```

**"The runner restores it on exit" is false against this branch.** Verified in the platform, not
assumed: `ConsoleController:stop_project_run` (`src/controller/consoleController.lua:1339`)
restores handlers, hides the overlay and clears user handlers — **it makes no `love.mouse` call**.
The only `setRelativeMode(false)` in the framework is `src/lib/error_explorer.lua:303`, on the
*crash* path. So a child who plays keyboard and exits normally returns to a console whose pointer
is in relative mode. The in-repo comparison is `pong`, which sets and clears the mode itself
(`src/examples/pong/main.lua:274, 248, 306`).

The project *could* fix this on its own — `compy.before_exit` fires on every stop path including
Ctrl+Esc, which our own `input.lua` header already notes — but the keyboard registers no
`before_exit`.

**Two separable questions, neither of them mine to rule:**

1. **Sprint-shaped, small:** the example should restore the mode (a `before_exit` that clears it),
   or the comment should stop claiming someone else does. Candidate for P18, cheap either way.
2. **Release-shaped, promoted not decided:** *should the framework restore device-level input modes
   when a project stops?* A project that dies before its own cleanup leaves the console in a mode
   it never chose, and the framework already does this class of teardown for handlers, routes and
   overlays. Raising it, not answering it.

### 2.5 What did **not** happen — checked, and worth recording

- **No new hand-matched chords.** The teacher's notch chord is still routed through the scene
  descriptor's `onNotch` (`gauge.lua:312`, `words.lua:263`), which our `input.lua` drives from the
  `ctrl+alt+up` / `ctrl+alt+down` shortcuts. The one hand-matched combo is the pre-existing
  `alt.lua:217` (`k == "h" and INPUT.ctrl and INPUT.alt`) — unchanged upstream, still P18's.
- **No `love.keyboard.isDown` anywhere upstream.** The only occurrence of the word is a comment in
  `indicators.lua` (*"edge-tracked, not isDown"*), and that file is unchanged since the base.
- **No `love.*` input callbacks in the new scenes.** Every new game registers a scene descriptor
  (`keypressed` / `keyreleased` / `textinput` / `update` / `draw` / `onNotch`) and is dispatched
  by `input.lua` — the seam our migration already owns. This is why 5227 new lines cost so little
  input-wise.
- **Upstream leans on the framework's reserved exit chord.** `findkey.lua:175` draws
  `drawChordHint({ "lshift", "escape" })` as two caps on the win screen (commit `7c535f4`) — a
  *picture* of Shift+Esc, with no handler behind it, which is correct: our `input.lua` binds
  `shift+escape` and the platform reserves it.
- **The wrong-key guard became an idiom, and it duplicates a framework predicate.**
  `not isMod(k) and k ~= "capslock"` now appears in **five scene files** (`findkey.lua:132`,
  `astrocore.lua:145`, `hide.lua:275`, `train.lua:240`, `bubble.lua:147`) besides `alt.lua:204`.
  `isMod` is `input.lua`'s own re-implementation of `Key.is_mod`. P18's register entry says *"used
  from three files"*; **after the merge it is six call sites**, and the `capslock` half is
  hand-listed alongside it.

---

## 3. The merge, measured

**The merge is textually clean.** `git merge-tree --write-tree newinput origin/dsent/dev` produces
tree `c0a1e100` with **exit 0 and no conflict**. Only two files are *changed in both*:

| File | Ours | Theirs | Outcome |
|---|---|---|---|
| `alt.lua` | the glyph-judging fix (`spendGlyph`) | target *drawing* (engraved caps, gauge/end screens) | disjoint hunks, both apply |
| `main.lua` | love.* callbacks removed, header rewritten for hooks | new scene registrations, relative mode, reformatting | disjoint hunks, both apply |

`input.lua` and `help.lua` — the two files our migration rewrote hardest — **upstream never
touched**, so ours survive whole. `hunt.lua` is dropped (upstream deleted it; we never modified
it).

### 3.1 The clean merge produces a broken tree — one orphan call

**`words.lua:221` calls `inputStale`, which does not exist after the merge.** Confirmed against the
merged tree: `inputStale` matches exactly two lines in `c0a1e100`, both in `words.lua` (its comment
and its call); there is no definition anywhere. The first glyph typed in the Words game raises
*attempt to call a nil value*.

Git cannot see this — it is a semantic break across two files that no hunk touches jointly. It is
also the sharpest possible vindication of the ordering ruling: had P18 been designed against our
current base, this defect would have arrived *after* the design and invalidated part of it.

### 3.2 Two smaller merge observations

- **One of P18's ten `INPUT` sites evaporates.** Upstream's `619c8cf` removed the board's
  live-case/shift-label behaviour, so our `keyboard_view.lua:178`
  (`KB_SHIFTLABEL and INPUT.shift and SHIFT_MAP[name]`) is gone in the merged tree; one
  `INPUT.shift` read remains there (`:286`). Post-merge the proxy has **eight** production read
  sites (`alt.lua` ×3, `help.lua` ×1, `keyboard_view.lua` ×1, plus the three proxy branches
  themselves), not ten.
- **Upstream reformatted `main.lua` by hand and lost two comments.** `updateStep` / `love.update`
  gained broken-out `if` bodies with **13 trailing-whitespace lines**, and the comments naming
  *"a modal pause (Alt+P, timed games only)"* and *"an open help overlay (held Alt+H)"* were
  deleted — the two sentences in that file that document what the input model does there. Worth
  restoring during reconciliation; the pause/help semantics are unchanged.

---

## 4. What this means for P18

### 4.1 The heal's design of record now has **two** clients, not one

`doc/development/internals/examples/keyboard.md` ratifies: *`textinput` is the only judge; two
fields (`lastText`, `blocked`); writes blocked across the win transition; subtract `spendGlyph`,
`GLYPH_CLAIMED`, `INPUT.upRecent`, `INPUT_UP_GRACE`.* It was written when **Alt was the only
`textinput`-judging scene**. After the merge, **Words is a second**, and it arrives calling a
function neither the design nor the current code has.

This is not a detail — it is the design's central premise widened:

- Whatever replaces `spendGlyph` must serve **both** judges, or each scene must carry its own
  judgement state and the design must say so.
- The heal's subtraction list (`spendGlyph`, `GLYPH_CLAIMED`, `upRecent`, `INPUT_UP_GRACE`) is what
  `words.lua` would otherwise be repaired *onto*. Repairing Words by pointing it at `spendGlyph`
  first, then deleting `spendGlyph` in the heal, is exactly the churn the P9b/P18 absorption
  exists to prevent.
- **Therefore the reconciliation must not "fix" `words.lua` by hand.** The honest options are: land
  the merge with the break recorded and let P18's single planning pass resolve both judges
  together; or, if the tree must be runnable at every commit, apply the minimal
  `inputStale → spendGlyph` restoration **as an explicitly interim commit** that P18 is expected to
  delete. Owner's call; the first is cheaper and truer to the absorption, the second keeps the
  smoke gate meaningful in between.

### 4.2 The onboarding half grows slightly, and one item shrinks

- `isMod`: **3 files → 6 call sites** across five scene files. Still mechanical, still
  `Key.is_mod`, but the sweep is wider and each site pairs it with a hand-written `capslock` test
  that deserves one decision rather than six.
- `INPUT` dissolution: **ten sites → eight** (§3.2). Unchanged in character.
- `alt.lua:217`'s hand-matched Ctrl+Alt+H: **unchanged upstream**, still exactly as the step
  describes it.
- **New, and out of the step's current text:** `bubble.lua`'s hold judge (§2.1 — recommend leave),
  and the relative-mode question (§2.4 — recommend the example-side half be considered here).

### 4.3 What P18 must NOT inherit uncritically

The merge brings 5227 lines of *game* code written against the old input model's idioms. The step
is a **deepfix of the input architecture**, not an adoption sweep of eight games. The register's
own cap applies: take a conversion only where it is small and obviously behaviour-preserving; the
rest is `P16`-shaped or debt. `bubble.lua` in particular looks convertible and is not.

---

## 5. Recommendation on sequencing (for the owner to rule)

1. **Merge as planned** — upstream into its own branch, then a deliberate merge, per Phase U's
   mechanic. The trial says there is no conflict to fight; the work is *semantic* reconciliation,
   which is precisely why it should be its own inspectable step and not a side effect of P18.
2. **Record the `inputStale` break as the merge's known outcome** (§3.1) rather than patching it
   reflexively, and decide the interim question there and then.
3. **Then re-run the adoption read the owner already anticipated** — over the merged tree, not over
   upstream: §2.5's `isMod` idiom, §2.4's relative mode, and confirmation that no other new file
   reaches a framework surface. This document is the input to that pass, not a substitute for it.
4. **`maze` needs the same pass before P17.** It has its own upstream (`dsent/dsent/dev`), its own
   divergence, and nothing here says anything about it.

## 6. Confidence and limits

- **High confidence, verified in the tree:** everything in §2.1–§2.5, §3 and §4.2. Each was read at
  the ref or in the merged tree; the `inputStale` orphan was confirmed by grepping the merged tree
  itself, not inferred from the two branches.
- **Verified in the platform, not assumed:** the relative-mode claim (§2.4) — read in
  `consoleController.lua` and `error_explorer.lua`.
- **Not verified — nothing was run.** No app was launched, no game entered, no smoke pass. The
  `words.lua` break is a static fact about a nil global; that it *raises at the first glyph* is
  read from the code path, not observed. The keyboard example has no suite, and this container
  cannot inject keystrokes.
- **Out of scope, stated so it is not mistaken for a clean bill:** `maze`; the platform half of
  Phase U; and any judgement about upstream's *game* design, which is the author's.
