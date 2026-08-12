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

## 2026-08-11 — owner opens P18 with three instructions, and corrects my vocabulary

Owner: focus on P18; **cascading step ids** (`P-18-01`, `P-18-02`…, with `-00` deliberately
marking the initial analysis/planning pass), so `P-17-00` is maze's merge+evaluate+plan; the
**agenda stored on disk**, not in chat; walk through **every** decision rather than rubber-stamp
one ("not touching bubble" named as the example); and the heal is **not mechanical** — they need to
see how `textinput` is used in the second project before design.

- **Terminology correction, and it is a real one.** *"Using the word 'judge' as a load-bearing term
  confuses me — I would speak in well-defined non-ambiguous terminology: code, functions, calls,
  variables. 'Glyph' is also vague — let's speak in terms of specific LÖVE2D events and their
  payloads."* Both words came from the example's own comments and the design note, and I had
  carried them into planning prose. The exposition is written in `love.textinput(text)` /
  `love.keypressed(key, scancode, isrepeat)` and named functions; `spendGlyph` / `GLYPH_CLAIMED`
  appear **as identifiers only**. Checklist item "unratified terminology" — caught by the owner,
  not by me.
- **Mode named and raised before starting:** this session has run research → execution (the merge)
  → and now analysis+design, which is the transition their own discipline says to name. Recommended
  continuing here rather than handing cold, on the grounds that the design's central input is the
  upstream code I have just read and they have not; the risk (a design built inside a long
  heterogeneous context) stated rather than hidden. They said go.
- **THE FINDING, and it decides the heal's shape.** The ratified design's rule 2 is a **content**
  test (`text == lastText`), and its own document states the precondition it rests on — *"every
  target is a single character… if a later stage ever asks the player to type a word, this design
  must be revisited, `lastText` would be deduplicating the letters of the answer against each
  other"*. **`words.lua` is exactly that, and the merge put it in the tree.** Typing `"all"` loses
  its second `l`; the player unsticks it only by typing a wrong character, which knocks and costs
  the word its gauge unit. Measured, not asserted: **224 corpus words carry a doubled letter** and
  the generator is order-2 over that corpus.
- **`spendGlyph` is a press-identity test** — has this KEY had one `love.textinput` accepted since
  its last `love.keyreleased` — and does not have that failure. Its cost is the one the design
  document names: a `love.textinput` arriving after its own `love.keyreleased` is rejected, so a
  very fast tap is lost. So the first open question is which property the shared layer provides,
  and it is genuinely open — the design note was right about Alt and is wrong about the tree it now
  lives in.
- **Second-order consequences enumerated in the document, not decided:** `ALT_JUDGE` is named and
  scoped for one scene; `blocked` exists for a target transition Words does not have (its advance
  is `WORDS.pos + 1`, within a line); `wordsBad` has **no** idempotence guard where `altWrong` has
  `ALT.fumbled`; `words.lua` uses `love.keypressed` **only on its end screen**, so it has no
  key-name targets at all.
- Written: `../../../validation/reviews/P-18-00-keyboard-deepfix-design.md` (agenda §0, exposition
  §2–§7, open questions §8, nothing decided). Plan amended in the steps that act on it: the
  numbering convention under §4, `P-17-00` as a minimal note in §15.3, and a `P-18-00` block in
  §15.4 pointing at the document.

## 2026-08-11 — owner ruling: the game's rules are not ours to change

Owner, after I described what a wrong character does in Words: *"we are **never** changing game
rules in 'keyboard'. What we do is tweaking the **implementation** to use appropriate underlying
mechanisms, trying to find exact fit."* (Self-corrected in the same breath from "tweaking them" to
"tweaking implementation" — the distinction is the whole point.)

- **The test it imposes:** would a player notice a difference? Yes → rule change, out of scope.
  No → implementation fit, which is what the step is for.
- **It kills two proposals of mine, and it is right to.** "Words could take the OS repeat as
  typing" is a rule change — a held `l` would show `lll` where the authored game shows one — and
  the knock guard in `wordsBad` existed only to mitigate that. Both withdrawn **in the document**,
  with the reason, so a reader of the outcome does not wonder why they are absent.
- **The authored rule, read from the code rather than assumed:** both scenes accept **one character
  per physical press** with OS repeat suppressed. `alt.lua` states it (*"a held wrong key … cannot
  knock continuously"*), `words.lua` states it by reference to Alt, and upstream's `inputStale`
  implements it under the delivery order the author develops on. **So repeat-suppression is a rule,
  not an artifact.** What IS an artifact — and in scope — is the dependence on delivery order, the
  dependence on a release arriving, and the frame counter borrowed from the debug logger.
- **It nearly settles §8.1.** Content-identity (`lastText`) is not a trade-off under this ruling but
  a rule change: `"all"` becomes untypeable without an intervening wrong character. What remains
  live is (a) keep press-identity and fix its two artifacts, or (b) revise the ratified design so
  its rule is press-scoped rather than content-scoped, keeping its virtue of no frame counter and
  no claim table — if such a formulation exists without consulting held state or delivery order.
  Written into §8.1 as pending the owner's confirmation, not as taken.
- **The one place the current implementation FAILS the authored rule:** a very fast tap, where
  `love.textinput` arrives after its own `love.keyreleased` and is dropped. A press produced a
  character and the player does not get it. Fixing that is fit, not rule change.
- Precedent named in the document: sapper's reverted conversion — mechanically faithful, purpose
  destroyed. This ruling is that lesson generalised to the whole example.

## 2026-08-11 — owner attestation: deaf on nodejs/linux; and the principle that outranks it

Owner: *"well, game is deaf on nodejs/linux. I suspect it's fine on Android. But relying on the
order the library does not guarantee is wrong anyway (any release of love2d could break both games,
irrecoverably)."*

- **First-hand evidence this session cannot reproduce** — no device, no keystroke injection — so it
  is recorded as an attestation in §1.2 rather than folded in as if I had measured it.
- **The principle is the stronger half and it is now a hard constraint (R2):** a mechanism that
  produces the authored rule on one delivery order is not correct, it is lucky, and the luck is
  held by someone else's release notes. **"Irrecoverably" is precise** — the failure is total
  silence, with no player-side workaround, and it hits BOTH scenes at once since they share the
  helper.
- **A discrepancy I flagged rather than resolved:** the design of record says *"desktop LÖVE sends
  `keypressed` first; the web build sends `textinput` first"* and the sprint's record says the Alt
  scene was *"deaf on hardware"* while working in the IDE. The owner's attestation orients it the
  other way (deaf on desktop Linux, suspected fine on Android). Both cannot be right as written.
  Nothing in the step may rest on either orientation — which is the principle itself — but the
  design document makes a platform claim, and if this step revises that document the sentence must
  be settled or struck, not copied forward.
- **Consequence: the requirements are now derivable, and I wrote them as §7.1 (R1–R5).** One
  character per physical press; order-agnostic; no loss when `textinput` trails its own
  `keyreleased`; survives a MISSED `keyreleased` (focus loss, and `capslock` whose release is
  already exempted by hand); serves both scenes without either carrying the other's special cases.
- **No candidate on the table satisfies all five.** `inputStale` fails R1+R2; `spendGlyph` fails R3
  and R4; the ratified `lastText` fails R1 in Words. Stated plainly instead of picking the least
  bad and calling it a design — the mechanism should now be derived from R1–R5, which is §8.2.

## 2026-08-11 — the attestation is made precise, and the corpus's platform prose is struck

Owner: *"'deaf on desktop Linux' — which is nodejs setup, run as `love src`. I attest that. I also
suspect game code should work as intended on Android (run from assembled .apk), because author uses
it on Android. Whatever else was hallucinated before (about what 'hardware' and 'device' are) is a
speculation of little value."*

- **Attested vs suspected, kept apart in the document.** Attested: deaf on desktop Linux under
  `love src`. Suspected, and labelled so with its ground: Android from an `.apk` works, because the
  author uses it there.
- **The design of record's platform sentence is now to be STRUCK, not reconciled.** I had filed it
  as a discrepancy to settle; the owner's ruling is that the "hardware"/"IDE" claims never had
  provenance. R2 makes the platform question irrelevant to the mechanism anyway, and an unsourced
  platform claim in a persistent document is worse than none because it reads as measurement.
  Corrected in §1.2 — my "both cannot be right, settle it" framing granted the claim a standing it
  never had.
- **A distinction I had let blur, and it changes what is left to do.** The attested deafness is a
  property of the `inputStale` code, not of the tree as it stands: `alt.lua` has been order-agnostic
  since this branch's `3a9d48c`, and `words.lua` since `ca6d5df` routed it to the same mechanism.
  **R1 and R2 hold in the merged tree today; what remains open is R3 and R4.** The deafness is what
  motivated the heal, not what the heal still has to fix — worth being exact about, since "the heal
  fixes a deaf game" would overstate the remaining work.

## 2026-08-11 — the derivation pass: an impossibility result, and three mechanisms

Owner asked for a derivation from R1–R5 rather than a choice between the two candidates. Written as
§9 of the design document.

- **The result that shapes everything: R1 + R2 + R4 cannot be satisfied by a decision taken at the
  moment each `love.textinput` arrives.** Proof by indistinguishability — in the `textinput`-first
  order, with a release missing, the event history before a *repeat* character and before the
  *first character of the next press* is identical (`keypressed(k,false)` then zero or more
  `keypressed(k,true)`), yet the required decisions are opposite. **So R4 forces deferral**, and
  that is why every previous attempt patched an edge instead of solving it.
- **Ruled out before someone proposes it:** `love.keyboard.setKeyRepeat(false)` during play. LÖVE's
  flag governs `love.keypressed` only, so it would remove `isrepeat` — the one authoritative signal
  — while leaving the OS producing repeat `love.textinput`. **And the repeats exist because the
  framework enables them** (`src/main.lua:297`, for the console and editor); LÖVE's own default is
  off.
- **Three mechanisms, scored against R1–R5:**
  - **A**, the status quo: claim cleared at `love.keyreleased` + the frame-stamp grace. Fails R3
    (the grace window rejects exactly the character R3 is about) and R4 (bounded, self-healing).
  - **A″**, the same claim **cleared at the frame boundary** instead of inside the release handler.
    **Deletes `INPUT.upRecent`, `INPUT_UP_GRACE` and the `DBG_FRAME` dependency**, and **fixes R3 as
    a side effect** rather than as an addition. Still fails R4.
  - **B**, pairing `love.textinput` events with fresh `love.keypressed` events **once per frame** —
    the deferral the impossibility result points at. Satisfies all five and deletes the claim table
    too, at the cost of a dispatch-architecture change (scene `textinput` runs at update time,
    same frame, before draw — invisible to a player but real).
- **Recommended A″, with R4 taken as its own decision** — its size matches the defect, and R4 may
  have a cheaper mitigation than B: `controller.lua:731` lists focus/mousefocus as **SKIPPED** by
  the framework, which suggests a project may define `love.focus` itself and clear its claims there.
  **Not verified** that a project-defined `love.focus` survives the framework's handler management,
  and said so rather than assumed.
- **The ratified design is revised, not implemented, either way** — its rule is content-scoped and
  fails R1 in Words. A″ and B both keep its intent (subtract the apparatus, stop inferring) while
  keying on the press rather than the character.

## 2026-08-11 — the owner's correction, and it is better than anything I derived

Owner: *"Words looks like a series of Alt levels with minor adjustment. Can we take the approach
suggested for Alt, with one correction: as soon as a win is registered we start listening to
`keyreleased`; the `keyreleased` of the last won character just clears `lastText` and deactivates
itself."*

- **Assessed before agreeing, and it wins on the scoring.** Accept iff `text ~= lastText`; on
  accepting, arm a release watch for that character's key; the release clears the field. It keeps
  the ratified design's shape — one remembered character, no table, no counter — and **replaces the
  content test's broken premise with a press boundary**, so `"all"` works and the *"one target, one
  keystroke"* precondition is dissolved rather than worked around. R1 ✓ R2 ✓ R3 ✓ R5 ✓, and R4's
  residue is the **smallest of any option**: one stranded character, freed by the next *different*
  keystroke, where the claim table strands the whole key.
- **It deletes more than my A″ did:** `INPUT.upRecent`, `INPUT_UP_GRACE`, the `DBG_FRAME`
  dependency, `GLYPH_CLAIMED`, **and the ratified design's own `blocked` field** — whose job the
  content test already does. Recommendation moved from A″ to C; A″ is C with a table and without the
  content test.
- **Two questions raised rather than assumed, both real:**
  - **(a) arm on wins only, or on every accepted character?** Arming on wins alone changes Words:
    a wrong key pressed twice would knock once, where the authored game knocks twice (`alt.lua`
    would not notice — `ALT.fumbled` already makes repeated wrong answers no-ops). §1.1 forbids
    that, so **arm on every accepted character**; only the arming point moves.
  - **(b) one slot or one per key?** The single slot has a **rollover hole** — hold `a`, press `b`,
    and `a`'s repeats no longer match the field. Reachability depends on OS auto-repeat following
    the most recent key and not resuming on the earlier one, **which nobody guarantees** — the same
    class of assumption R2 refuses. Left as the decision worth taking deliberately.
- **A finding that affects EVERY option including the status quo:** `wordsBaseKey` is incomplete
  where `altBaseKey` is not — it lacks the `SHIFT_MAP` inversion, so a shifted symbol maps to itself
  and its release never matches. Under `spendGlyph` today (which `ca6d5df` routed Words to) typing
  `"!"` claims key `"!"`, the release delivers `"1"`, and **that character can never be typed again
  in the session**. The shared `textBaseKey` must live in `input.lua`, not `alt.lua`: `ALT_BASE` is
  built in a **lazy-loaded** scene file, so a Words-only session would find it nil — the exact bug
  class upstream hit at `6d14723`. `SHIFT_MAP` is in `config.lua`, which loads first.

## 2026-08-11 — owner pushes on release loss; the timer is declined, a poll replaces it

Owner: *"it's still vulnerable to `keyreleased` loss. But `keypressed` of anything else than
last-won could do the same. Plus a timer after win."*

- **The diagnosis is right and is R4.** One clearing path is not enough. Both proposed extra clears
  assessed in §9.5c rather than adopted.
- **Clear #2 (any other `keypressed` clears) works for its case but WIDENS the rollover hole:**
  while a key is held and repeating, any other press — `lshift` and `capslock` included, which
  produce no text — frees the field, so the held key's next repeat is taken as a fresh character.
  Reachability rests on whether the OS keeps repeating the first key after a second is pressed —
  the unguaranteed behaviour R2 refuses to lean on.
- **Clear #3 (a timer after a win) has a failure that cannot be tuned away, so I declined it.** To
  free a stranded field the timeout must be short; while it runs the key may still be legitimately
  held; any timeout shorter than the hold lets the next OS repeat through as a new character. **That
  is a rule change by §1.1's own test** — holding a key would start typing again. It also
  reintroduces a clock, the one thing the ratified design was proud of not having.
- **Recommended in their place — ask the device once per frame:** `if watch and not
  Key.any_pressed(watch) then clear end`, keeping the release-clear as the immediate path (needed
  for a re-tap inside one event batch).
  - **R4 closes completely** — the backstop consults no event, so no event can be lost.
  - **It is NOT `inputStale` returning.** That asked *"is this key held?"* at `love.textinput` time,
    where the answer depends on which channel arrived first. This asks *"is the key of the character
    I already accepted still down?"* at frame time, about a press that is already history — no
    ordering for it to depend on. Decision 32's own distinction, and `helpHeld` is the precedent it
    already ruled correct.
  - **It lands `Key.any_pressed` in the example**, which is P18's onboarding half — the poll and the
    migration become one edit rather than two.
- **Consequence: Option C + the poll satisfies R1–R5 in full**, which no option managed before, and
  **B is no longer needed** — the impossibility result forbids settling it *at character arrival*,
  and this resolves the press boundary later, from the device, for the cost of one poll. The
  `love.focus` mitigation is superseded and needs no verification.
- **Untouched: the rollover hole** (§9.5b, one slot vs per-key). It is a property of the slot, not of
  the clearing paths, and still wants a deliberate decision.

## 2026-08-11 — the task-tagged cache is a near-miss; and the poll already asks what they wanted

Owner: *"can we use a 'cache-busting technique' by storing 'last seen' (or some other caches) per
task number? I feel it could help some rearming. Also not sure why should we poll `any_pressed`
instead of asking 'that specific last one, is it still pressed'?"*

- **The generation trick fails on the one repeat the games care about, and the failure is a rule
  change.** Hold `l` while typing `"all"`: the first `l` is accepted at `WORDS.pos == 2`, the
  position advances to 3 — a NEW task — so a task-tagged cache no longer matches the still-held
  key's next repeat and accepts it. **The player has typed `"ll"` by holding one key**, which is the
  withdrawn "repeat as typing" outcome arriving by another road. Alt has the same shape one level
  up: the design document's own text says a repeat of the winning character arrives with a
  *different target displayed*, which is what `blocked` exists for. **The block must survive the
  task change; a task tag invalidates exactly when the state is most needed.**
- **The general form, and it is worth keeping:** §9.2 proves that identifying *which press a
  character belongs to* AT ARRIVAL is impossible under R2 + R4. Every tagging scheme — by task, by
  press counter, by generation — is an attempt at that identification and inherits the proof. A
  per-key press counter fails most directly: in the `textinput`-first order the character arrives
  before the `keypressed` that would increment its generation.
- **Where a task number IS the right tool, and is already used:** idempotence per presentation —
  `ALT.fumbled` / `st.fumbled`, several wrong answers reading as one miss, reset when the target
  advances. That cache exists; it is not the state under discussion.
- **The poll already asks their question.** `Key.any_pressed` is variadic over
  `love.keyboard.isDown`, whose multi-name form is an OR; with one name it *is* "is that specific
  key still down". The OR lives in the name because session36 ruled it there — `pressed` stays
  reserved for a future AND-shaped chord predicate, and shipping the wrapper as `pressed` would have
  claimed the name for the wrong semantics. **The single-key case reading oddly is a real wart**,
  recorded as such: the alternatives are `love.keyboard.isDown` directly (keeps the example on the
  surface the migration removes) or a new single-key alias (new API against a mandate to simplify).
  Flagged for the console/editor migration, which will read it the same way.

## 2026-08-12 — the two remaining decisions written out in full (§9.5f)

Owner asked for the options in more detail before ruling. Written into the document rather than
only answered in chat.

- **(a) When the field is written and the watch armed — three readings, one survives.** Writing only
  on a win leaves a held WRONG key knocking every repeat (`wordsBad` has no guard); writing the field
  but arming only on wins makes a wrong key pressed twice silent the second time. **Both are rule
  changes visible in Words and masked in Alt** (`ALT.fumbled` hides them there), which is why the
  second scene keeps earning its place in this analysis. **Survivor: field and watch move together,
  always** — hit, miss, and the chord record alike. It also improves the chord record, which no
  longer needs the ratified design's argument that *"the next judged character overwrites it anyway"*.
- **(b) One slot vs one entry per key — the real difference is WHAT IDENTIFIES A PRESS.** With a
  single slot the identity is the character, and the rollover hole follows: hold `a`, press `b`, the
  slot moves to `b`, `a`'s repeats match nothing. Reachability rests on auto-repeat following the
  most recent key — *"usually"*, which is the class of assumption R2 refuses.
  **With per-key entries the identity is the key, and the content test disappears entirely**: one
  concept (a key stays consumed while held) replaces two, and the ratified design's delicate
  invariant — `lastText` must never equal the live target — has nothing left to protect.
- **Recommended (b-ii)**, on predictability rather than elegance: it removes the hole instead of
  betting on OS behaviour, needs one concept, and is a **smaller diff than it looks** since it keeps
  `GLYPH_CLAIMED`'s structure and replaces only its clearing rule (release + frame-stamp grace →
  release + device poll). Honest cost stated: the promised subtraction shrinks — `upRecent`,
  `INPUT_UP_GRACE`, `DBG_FRAME` and `blocked` still go, the table stays.
- **Shared by both variants, recorded before it is discovered:** `textBaseKey` cannot always name the
  physical key (IME, dead keys, AltGr), so an entry may be keyed by a name no `keyreleased` matches.
  **The poll rescues it** next frame, at the cost that such a character, if truly held, could repeat
  once per frame. Neither game has such a target, and the alternative — no poll — strands it forever.

## 2026-08-12 — owner's filter/judgement split, and the mechanism collapses again (§9.5g)

Owner: *"I see how it can become a filtering mechanism separate from judgement. The filter judges
whether new text was already registered. If it was — noop. If not: register and fire
`on_new_text()` — the hook of judgement, different on two games. Registration activates a watcher
that polls the keyboard (and caps lock state?) to understand when registered text stops being sent.
The `keyreleased` event may fill its own track with timestamps, that could be consulted by the
poller."*

- **The architecture is right and costs NO new surface.** `on_new_text` already exists: it is the
  scene descriptor's `textinput` entry that `input.lua` already dispatches to. The filter moves
  ABOVE the scene handlers instead of being called BY them, so `altTextinput` and `wordsTextinput`
  each lose their first line and are otherwise untouched.
- **Taking the watcher seriously made `love.keyreleased` drop out of the mechanism entirely** — not
  as an optimisation but because clear-on-release is **worse**: a release followed by a trailing
  repeat and a release followed by a re-press are the same shape, so clearing at the release admits
  a **phantom character** (the exact case `INPUT_UP_GRACE` was invented for). Clearing only in the
  watcher blocks it. The one thing clear-on-release buys is a release-and-re-press inside a single
  frame — under 16 ms, not a human act. **R4 is then satisfied by construction: an event never
  consulted cannot be missed.**
- **The timestamp track is declined with its reason:** it distinguishes trailing repeat from
  deliberate re-press by AGE, which works and is `INPUT_UP_GRACE` rebuilt — a duration constant tuned
  against timings nobody guarantees, deciding judgement. The frame boundary gives the same protection
  and is a boundary we already have rather than a number we had to pick.
- **Caps Lock: the watcher does not need it, and it is a SECOND independent argument for per-key.**
  Hold `a`, toggle Caps mid-hold: repeats now carry `"A"`, whose base key is still `"a"`, so they
  stay registered and stay ignored — matching upstream, which also keyed on the held key. **The
  single-slot content variant leaks here**: `"A"` ~= `"a"`, so holding one key types a second
  character. Alongside rollover, that is two independent leaks the slot has and the table does not.
- **What Caps Lock still requires is unchanged:** `capsReconcile` runs ABOVE the filter, on every
  character including discarded ones — repeats are valid evidence of a lock state nobody reported.
  It is the one line in the mechanism whose position is load-bearing.
- **The whole thing in one sentence:** a key whose character has been delivered to the scene stays
  registered until the device says it is no longer down. One table, one frame-time poll, one hook —
  no content test, no timestamps, no clock, no grace constant, no release handler, no ordering
  assumption anywhere.

## 2026-08-12 — owner scopes the change down, and keeps the project's vocabulary (§9.5h)

Owner: minimize changes to `keyboard` — bubble keeps its keypressed/keyreleased, alt keeps judging
play keys on its own channel, and **only textinput processing changes** in alt and words, to
surgically remove the inter-channel assumption. *"I would even keep the names the original uses, as
long as machinery stays project's own."*

- **Correction to the premise, recorded because it narrows the step:** `alt.lua` has **no
  `keyreleased` handler at all** — it registers `keypressed` + `textinput`. The only scene in the
  game with a release handler is `bubble.lua`. So alt's play-key path is `keypressed` alone, and it
  was never exposed to the inter-channel problem: `appKeypressed` drops OS repeats at source via
  `isrepeat`.
- **Names are the project's.** The register already exists as `GLYPH_CLAIMED` and the filter as
  `spendGlyph`; both keep name and meaning — **only how a claim is RELEASED changes**. My working
  names (`CONSUMED`, `textBaseKey`, `on_new_text`) were scaffolding and are dropped from the design.
- **The whole diff:** `spendGlyph` loses its `upRecent` branch; a new `inputTick()` clears claims
  whose key the device reports up; `INPUT.upRecent`, `INPUT_UP_GRACE`, their reset and the two claim
  lines in `appKeyreleased` are deleted (that handler keeps its scene dispatch, which bubble needs);
  `main.lua` calls `inputTick()` in `updateStep` **above** the PAUSED/help returns, beside
  `pastelTick`, which is already there for the same reason; and the `SHIFT_MAP` inversion moves from
  lazy-loaded `alt.lua` down to `input.lua`, with `altBaseKey`/`wordsBaseKey` keeping their names and
  delegating — which is also what fixes Words' missing shifted-symbol case.
- **A real choice, and I recommended the smaller side:** leave `spendGlyph`'s call at the two scene
  call sites rather than hoisting it into `appTextinput`. Hoisting expresses the filter/judgement
  separation structurally and stops a future scene forgetting it; leaving it means **no scene-file
  changes at all** and keeps the authors' code recognisable, which is the reading of "minimize
  changes" that matches the owner's naming instruction.
- **The delayed poll is declined, and the owner doubted it themselves.** The structural reason is
  worth keeping: **the poll cannot run between a release and a `textinput` trailing it** — LÖVE
  drains the whole event queue before `love.update`, so the entire batch lands before the frame's
  poll. The delay would guard a case the OS does not produce, while swallowing a **deliberate
  re-press inside its window** — which is exactly the doubled-letter keystroke in Words — and it puts
  back a tuned constant.

## 2026-08-12 — owner challenges the baseline; §2.1 added, and the answer holds either way

Owner: *"are you judging against current patched form or upstream form? I am not interested in
analysing our half-done machinery applied before we saw updated upstream. I am analysing how a clean
patch towards upstream would look."*

- **The specific claim holds in both baselines, verified rather than asserted:** upstream's
  `alt.lua` registers `keypressed` + `textinput` only (`origin/dsent/dev:alt.lua:308-317`); it has no
  `keyreleased` handler, exactly as the merged tree. `bubble.lua` is the only scene with one, in
  both.
- **But the challenge lands on the document's method**, and §2.1 now fixes it: §2 described the
  MERGED tree, which is what P18 edits, while the deliverable is a **diff against upstream**. Both
  baselines are now stated, and claims about *authored behaviour* are checked at
  `origin/dsent/dev`. Files this branch never touched (`words.lua`, `bubble.lua`, `findkey.lua`,
  `gauge.lua`, `config.lua`) are identical in both, so only `alt.lua`, `help.lua`, `input.lua` and
  `main.lua` needed re-checking.
- **A finding that came out of doing it: `inputStale` has TWO callers upstream and only one is
  broken.** Inside `appKeypressed` it filters OS repeats and is **sound** — a repeat `keypressed`
  always arrives while its key is genuinely held, and a fresh press always follows the release that
  cleared `held`, so no delivery order can confuse it (its only flaw is the `upRecent` tail dropping
  a fresh press within a frame of a release). The defect lives **only** in the two scenes'
  `textinput` guard. **So the heal is confined to that one call and does not depend on the
  migration**; replacing upstream's repeat filter with the API's `isrepeat` is feature #77's work,
  not the heal's — two changes that happen to touch the same file.
- **The mechanism as an upstream-relative delta** is now tabulated in §2.1: `INPUT.held`,
  `inputUpdateMods`, `inputStale`, `INPUT.upRecent` and `INPUT_UP_GRACE` out; `GLYPH_CLAIMED`,
  `spendGlyph` and `inputTick` in; one line changed in each of the two scenes; the release handler
  reduced to dispatch. **Two tables and a tuned constant become one table cleared by the device.**

## 2026-08-12 — the assumption named exactly; the poll stays plain LÖVE; ignore_repeat is blocked

Three owner questions, all answered from code and written up (§2.2, §9.5h, §9.5i).

- **What the inter-channel assumption WAS, exactly:** `inputStale` reads `INPUT.held[k]` — state
  owned by the **keypressed** channel — while being called from the **textinput** handler. The
  proposition the code needs is *"at `love.textinput` time, `INPUT.held[baseKey(t)]` is false for the
  first character of a press and true for a repeat"*, which holds **iff `textinput` is delivered
  before its own `keypressed`**. Under the other order the first character of every press reads as
  stale and is dropped — total deafness, which is what the owner attested. **A second, smaller
  assumption sits in the same function and is about TIMING, not order:** `upRecent` +
  `INPUT_UP_GRACE` assumes a trailing repeat lands within one frame of the keyup and that nothing
  deliberate arrives that fast — the half that produces R3's dropped press. **Both go, and neither
  is replaced by another assumption:** the claim is taken by the character on its own channel and
  released by the device.
- **The poll stays `love.keyboard.isDown`, with a comment recommending `Key.any_pressed`** (owner).
  A second argument for it, which I had not made: **upstream's `keyboard` is a standalone LÖVE
  program**, so a heal written in plain LÖVE can be offered to its author independently of the #77
  migration — writing the poll as `Key.any_pressed` would drag the platform into a bugfix that does
  not need it. It also matches the nearest precedent: `helpHeld` already polls
  `love.keyboard.isDown("h")` and Decision 32 ruled that correct.
- **`fn.ignore_repeat` on the keypressed hook: mechanically legal, blocked by one exemption.** The
  wrapper takes `(k, sc, isr)` and hooks receive exactly that. But repeat filtering is **not
  universal here** — `capslock` is exempt in BOTH baselines (`k ~= "capslock"`), because its release
  is unreliable, so its next press can arrive flagged as a repeat and dropping it would freeze the
  app-wide Caps estimate. A blanket wrapper breaks the decal for every scene. It could be unblocked
  by moving `capsToggle` to a bare `shortcuts.keypressed['capslock']` (legal — `capslock` is not a
  modifier), but that is restructuring, not minimisation; **recorded, not recommended in this step.**
- **No, the game is not avoiding `isrepeat` deliberately** — upstream never received it
  (`main.lua` forwards `love.keypressed(k)`, one argument), and filtered by held state instead;
  `f938fbc` widened the signature. **And the OS-settings worry does not bite:** if repeat is
  disabled no repeat events are generated, so `isrepeat` is never true and the filter is a no-op —
  the flag does not become unreliable, the events stop existing.

## 2026-08-12 — owner challenges the capslock reason, and the challenge lands on a live question

Owner: *"'capslock's release isn't reliably delivered' — why such a conclusion? I think the reason is
different: capslock is tracked because it TOGGLES caps state on every new press."*

- **Provenance checked rather than defended.** The phrase is the **author's**, from upstream's own
  comment — *"capslock is exempt from the stale filter (its release may not arrive, wedging the set
  and freezing Caps)"* — and it is **sound about upstream's mechanism**: a release that never arrives
  leaves `INPUT.held['capslock']` true forever, so every later press is stale, `capsToggle` never
  runs again, and the estimate freezes for the session.
- **The owner's reading is the purpose underneath it and is the better statement:** the exemption
  exists so the repeat filter cannot **eat a toggle**. Upstream's filter genuinely could — via the
  wedged flag, and via the one-frame `upRecent` window on a fast re-press.
- **Under `isrepeat` the filter cannot eat a toggle at all** — a fresh press is never flagged as a
  repeat, whatever events were missed. **So this branch's comment re-justifies an inherited exemption
  with a claim the new mechanism does not support** (*"its next press can come in flagged as a
  repeat"*). That comment is wrong and is owed a correction regardless of what else is decided.
- **And the exemption's effect has INVERTED.** It no longer protects a toggle; all it now decides is
  what happens to capslock **repeats**. If the OS emits them while the key is held and does not
  toggle the lock on each one, letting them through makes `capsToggle` flip the estimate every
  repeat — **the exemption would now cause the drift it was written to prevent**.
- **Settled by one observation, not by argument:** hold `capslock` for a second on the target
  platform and watch the OS lock and the decal. Owed by a human — this container cannot inject
  keystrokes. Either outcome is cheap: inert → drop it for tidiness; repeating without toggling →
  it is a live defect and must go.
- **This is what actually gates the owner's `ignore_repeat` idea**, so my earlier "blocked" verdict
  is revised: drop the exemption and `fn.ignore_repeat(appKeypressed)` becomes exactly equivalent to
  the handler's first line, which is the owner's suggestion landing.
- **Scope: all of it is on the `keypressed` channel, outside the heal** (which is confined to
  `textinput`). Recorded so the step does not absorb it by proximity.

## 2026-08-12 — owner checks the signature fix; confirmed, with one wrong turn in its history

Owner: *"'main.lua forwards love.keypressed(k)' — but we fixed it in the feature, correct?"*

- **Correct.** `4814407` (the migration) deleted `main.lua`'s three forwarding wrappers entirely;
  the game registers `compy.input.hooks.keypressed = appKeypressed` and the framework calls it with
  LÖVE's own arguments. My statement was about **upstream** and stands there.
- **The signature took two further commits, and the middle one was wrong** — recorded because it
  would have been a live defect: `5de5a6d` narrowed `(k, _, isr)` to `(k, isr)`, assuming the hook
  delivers `(key, isrepeat)`; it delivers LÖVE's three, so `isr` bound to **`scancode`**, always
  truthy, and `if isr and k ~= "capslock" then return end` would have dropped **every** non-capslock
  keypress. `f938fbc` restored `(k, _, isr)` the same day.
- **The contract is documented** so nobody re-derives it: *"Every shortcut, hook and callback
  receives exactly the arguments LÖVE delivers for that event — `keypressed(key, scancode,
  isrepeat)`"* (`doc/input_api.md`, "Event hooks and shortcuts"). Current signature is right.
- **For the eventual patch:** the two commits cancel out, so a branch assembled off upstream as "one
  commit or two" carries neither — noted so the intermediate state is not preserved in the name of
  history.

## 2026-08-12 — the best evidence of the step: the author's own header lists the platform's gaps

Owner: *"the receiving side in the upstream game does not expect `isr` to be delivered, right? If we
deliver it now, would it remove any machinery built exclusively to work around the lack of the
flag?"*

- **Yes, and upstream's `input.lua` header SAYS SO** — *"The IDE keeps key-repeat enabled and strips
  the isrepeat flag before calling the game, so repeats are filtered here by edge tracking: a key
  already in `INPUT.held` is a repeat and is ignored completely."* **Verified at the PR base rather
  than trusted:** `3256aac:src/controller/controller.lua:162` is `local function keypressed(k)` —
  one parameter. The platform did strip it.
- **This corrects §2.2's tone, and fairly.** The inter-channel assumption was **not an oversight**:
  the same header documents it (*"the IDE delivers textinput BEFORE the matching keypress"*), reasons
  about it, and **rejects the gate scheme for exactly the reason this session re-derived**. What made
  it a defect is that the behaviour was never guaranteed — and the platform it was true of is the one
  this feature changes.
- **Attribution table written into §2.3**, because "what the flag removes" is narrower than "what
  the feature removes": the flag retires the **keypressed-side edge tracking** outright;
  `Key.shift/ctrl/alt` retires the modifier mirror; shortcuts retire `reservedChord`/`appChord`;
  `Key.is_mod` retires `isMod`; a poll retires `help.lua`'s held read; `compy.before_exit` answers
  the header's own complaint that the runner had no exit hook to restore key-repeat.
- **And the row that justifies this whole step:** `INPUT.upRecent` + `INPUT_UP_GRACE` exist because
  **`love.textinput` carries no repeat flag in ANY LÖVE version**. No platform change can retire
  them — only the new mechanism can. That is why the heal is separable from the migration and why
  delivering `isr` does not make it unnecessary.
- **For the PR description:** the example's header is a list of six gaps in the pre-feature platform,
  written by the author who worked around each one deliberately. **Four are closed by this feature.**
  That is stronger testimony than anything the sprint could write about itself.

## 2026-08-12 — the Alt+H concern, cleared: the leak is live, and the fix lands where the chord is eaten

Owner's precondition before commissioning the cold agent: *"how does the current feature process 'h'
from Alt-H? I'd expect it to claim the glyph (without judgement) from within the handler that opens
the help widget. And for closing of the help widget — I'd close when either or all of its initiating
keys are unpressed physically."*

- **Closing already works exactly as they describe, and it is ruled.** `helpHeld()` polls
  `love.keyboard.isDown("h")` and `Key.alt()` (through the proxy) — the overlay is up for exactly as
  long as **both** keys are, and vanishes when **either** goes up. Upstream did the same with
  `INPUT.held.h`, an event mirror; ours asks the device. Decision 32 ruled this poll correct.
- **Nothing claims 'h' today, and the leak is live.** `sc["alt+*"] = fn.stop_here()` swallows the
  chord's keypress and runs nothing. Alt+H produces no character while Alt is held (the chord filter
  in `appTextinput` drops any that appear), but **release Alt while keeping H down** and the OS
  repeats now produce plain `'h'`, which passes the filter and is judged as a typed answer — a miss
  in Alt, a wrong character in Words. The ratified design named this as a residual it did not solve,
  precisely because the scene never sees a swallowed chord's keypress.
- **The new mechanism fixes it at the swallow point, in one line**, and the API already carries what
  is needed: a class handler **receives the actual key as its first argument** (`doc/input_api.md`,
  "Event hooks and shortcuts"). So `sc["alt+*"] = fn.stop_here(function(k) spendGlyph(k) end)` claims
  the trigger without judging it, and the claim is released when the key physically comes up. Same
  for `alt+p`, and for `Ctrl+Alt+H` wherever that ends up being handled.
- **Which yields a rule worth stating in the design:** *whoever consumes a chord claims its trigger
  key.* It is strictly better than the ratified design's version — that one asked the SCENE to record
  the character, which is impossible for chords the scene never sees. The claim belongs where the
  knowledge is, and the device releases it.
- **The owner's expectation was right on both halves**, and the one they were unsure about is the one
  that was missing.

## 2026-08-12 — the cold inventory returns; its headline claims verified in code

Commissioned per the owner: Opus, model passed explicitly, read-only, baselined on
`origin/dsent/dev` and told nothing about what landed. Prompt of record
`../../../validation/prompts/P-18-00-adoption-inventory.md`, deliverable
`../../../validation/outcomes/P-18-00-adoption-inventory.md` (701 lines).

- **It stayed cold and said so where it mattered:** it noticed `GLYPH_CLAIMED`/`spendGlyph` **do not
  exist upstream** (they are this branch's names) and named the upstream sites instead of assuming
  our shape. **No tree was touched** — nested repo still clean at `ca6d5df`, no `.lua` edited.
- **Counts:** 26 sites across 11 files; 7 platform gaps (4 closed by the feature); 14 leave-alone;
  9 raised-not-recommended; 5 ordering waves plus 4 smoke items.
- **Verified myself before relaying, per the charter:**
  - `isrepeat` **is** delivered end to end — `controller.lua:766` is
    `handlers.keypressed = function(k, sc, isr)` and `:872` forwards all three. (Consistent with the
    base being different: `3256aac`'s handler took one parameter.)
  - **The platform does not reorder the channels** — `handlers.textinput` (`:877-881`) forwards
    straight through. So the author's *"the IDE delivers textinput BEFORE the matching keypress"* was
    an assumption about the environment, **never a platform guarantee**. That is the fault the
    settled fix exists for, stated better than I had it.
  - Shortcuts see every repeat (the guide says so), so `fn.ignore_repeat` is **mandatory** on
    converted chords — which is what this branch already does.
- **Findings that bear on what LANDED, i.e. the triage's raw material:**
  - **Two narrowings nobody ruled**, both already in the tree since `ced8f40`/`e00430b`:
    `'alt+*'` cannot swallow a **bare Alt press** (a modifier's own press names no combo), so Alt
    alone now finishes the intro typewriter as lone Shift already did; and `shift+escape` /
    `ctrl+alt+up` are **exact** modifier sets, so **Alt+Shift+Esc and Ctrl+Alt+Shift+Up stopped
    working**. Agent recommends accepting the first and says the second must be stated. **Owner's
    word on both.**
  - **`help.lua:11` is the highest-value line in the game**, and it gives our change a far better
    justification than the consistency argument we used: upstream, a release for `h` lost to a focus
    change **wedges the overlay ON**, and `main.lua` freezes the game behind it with no recovery but
    a fresh press-and-release. A poll cannot wedge.
  - **The capslock exemption is vestigial and currently harmful** — it lets every repeat reach
    `capsToggle`, so a *held* capslock flickers the estimate. Same conclusion I reached from the
    other side; the agent read the path rather than waiting on the observation.
  - **A constraint I had missed, and it blocks agenda item 5:** `compy.input.shortcuts` is
    **project-global** while `Ctrl+Alt+H` is **scene-local**, and `scene.lua`'s registry has `enter`
    but **no `leave`** — so there is nowhere to unregister. Converting it needs a restructuring, and
    the same question governs every scene-scoped binding in the game.
  - **`Key.is_mod` is exported but undocumented** in `doc/input_api.md` — a platform doc gap, P10's.
- **Sequencing honoured (owner's insistence):** no triage started while the agent ran, and none
  begun yet. Part 2 is next and is mine.

## 2026-08-12 — the triage, and P-18 decomposes into six children

Owner cleared the way with two calibrations and a technique, then said run it. Written to
`../../../validation/reviews/P-18-00-triage-and-plan.md`.

- **Calibration (a): focus loss is not catastrophic, and is not on its own a reason to change code**
  — *"many examples tolerate this risk … if the said risk is the only reason, I'd rather leave a
  comment with a warning."* **Calibration (b): a risk cleared by repeating the chord is an
  inconvenience, not a harmful degradation.**
- **They move exactly one item and re-justify two.** `bubble.lua`'s hold judge is **downgraded from
  convert to comment-only** — its only failure is a lost release, and `bubbleGrow`'s timeout pops the
  bubble by itself, so the cost is a pop the child can retry. `helpHeld` **keeps its change but loses
  the wedge argument**: it stands because `INPUT.held` is deleted by the adoption and a poll is the
  sanctioned answer, not because of focus. And **the heal must NOT be argued from focus at all** —
  its case is ordinary typing, where clearing a claim on release admits a trailing repeat as a
  **wrong answer the player did not type**, which is exactly what `INPUT_UP_GRACE` was built for.
- **The scene-scoping blocker dissolves, and the precedent is in the file itself.** The owner named
  the technique (balloons swaps handlers by mode); balloons does it as `game_state_router` →
  `map[game_state](...)`, pong as `key_actions[S.state][k]` — and **`notchAdjust` in this very
  `input.lua` already does it**: a globally-registered shortcut whose action is looked up on the
  active scene through `onNotch`. So `Ctrl+Alt+H` needs no `leave` hook and no restructuring: register
  globally, dispatch through an `onHint` descriptor entry. §4.3's objection does not apply.
- **Triage verdicts:** 7 KEEP, 5 COMPLETE, 6 DO, 2 REVISE, 4 RULE. The cold pass **independently
  reproduced** what landed for the reserved chords — same three shortcuts, same
  `stop_here(ignore_repeat(...))` — which is the strongest evidence yet that the migration's shape
  was right.
- **A correction to my own §9.5h:** the release poll belongs in `love.update`, **not** in
  `updateStep` beside `pastelTick`. `updateStep` returns early on `PAUSED` and on
  `helpOverlayShown()`, and the help overlay is *held* Alt+H — so a claim would outlive its key in
  the ordinary way that overlay is used, not in a corner case. The cold pass caught it.
- **P-18 now has six children**, dependency-ordered: **01** the heal (with the chord claim, which is
  the same mechanism and not a follow-up) · **02** dissolve the proxy (8 readers) · **03** `isMod` ·
  **04** `Ctrl+Alt+H` · **05** `before_exit` · **06** comments. Bound into §15.4.
- **Four rulings wanted before P-18-01 starts:** the two landed-but-unruled narrowings (Alt+Shift+Esc
  and Ctrl+Alt+Shift+Up stopped working), the bare-Alt delta in the intro, the capslock exemption
  (settled by one observation), and whether Ctrl+Alt+H becomes a shortcut.

## 2026-08-12 — the PR-assembly guide learns about the detached repos' upstreams

Owner asked for it while planning, so the knowledge lands before the slices are regenerated.

- **New §5.1 in `pr-assembly-guide.md`**, plus warnings at the three Set-4 commands. The rule it
  states is a trap otherwise: **`diff <upstream>..HEAD` is a reviewable change only while
  `<upstream>` is an ANCESTOR of `HEAD`.** If upstream has moved and is unmerged, the patch also
  contains the *reversal* of everything upstream added — it reads as *"and delete the author's last
  26 commits"*. The check is one line: `git merge-base --is-ancestor <ref> HEAD`.
- **Measured, not assumed:** `keyboard`'s `origin/dsent/dev` **is** an ancestor since the merge
  `17289e9`, so that line was already right and is now also *meaningful* — before the merge the same
  command would have emitted a patch deleting 36 upstream commits' work. `maze` is 4 ahead of
  `origin/v3.4` (its current, correct, pre-pull base) and **26 behind `dsent/dsent/dev`** from
  merge-base `12f675f` — so the guide keeps `origin/v3.4` and says **switch to `dsent/dsent/dev` only
  when P-17-00 merges it**. `balloons` is untouched by Phase U.
- **`repos.txt` is named as the source** for which upstream matters per repo, including the detail
  that maze's is the **`dsent`** remote and not `origin` (which is `nagydani/Compy-maze`).
- **Recorded why the patch, not `format-patch`, remains the artifact:** the delivery is a fresh branch
  off upstream carrying one commit or two, so the local graph is working state — and a `format-patch`
  would ship churn including commits that cancel out, of which `keyboard` has a pair (`5de5a6d` /
  `f938fbc`).

## 2026-08-12 — ruling 4 settled: Ctrl+Alt+H becomes a shortcut; all four rulings are closed

Owner: *"I see no reason to lean to B. The existing code is clear boilerplate, nothing unique to
preserve — and exactly the type of construction we want to get rid of."*

- **P-18-04 is option (A):** `sc['ctrl+alt+h']` with an `onHint` scene-descriptor entry that only
  `alt.lua` defines, mirroring `onNotch`; `altKeypressed` loses its first four lines and the game
  keeps no hand-matched combo.
- **Recorded as the trap to avoid in that step:** `fn.ignore_repeat` is **mandatory**. The hand-match
  inherited the hook's `isrepeat` filter for free; shortcuts see every repeat, so an unwrapped binding
  would re-arm the hint every repeat frame — a rule change hiding inside a mechanical conversion,
  which is exactly what the cold pass caught in the reserved chords.
- **P-18-04 also stops depending on P-18-02**, since the `Key.ctrl()/alt()` form it would have needed
  is no longer on the table.
- **All four rulings closed.** The plan is unblocked end to end: 01, 01b, 03, 04, 05, 06 can start
  immediately; 02 waits only on 01 (which deletes `upRecent`).

## 2026-08-12 — EXECUTION: four children land, one of them delegated

Owner approved the recommendation (do P-18-01 and P-18-01b here, then wrap), and mid-flight reminded
me that **cold Sonnet workers are available for mechanical work, one at a time, supervised** — which
is why two more children landed than planned.

- **`c60b818` — P-18-01, the heal.** `spendGlyph` loses its grace branch; `INPUT.upRecent`,
  `INPUT_UP_GRACE` and the release bookkeeping are gone; `inputTick` polls the claims once a frame in
  **`love.update`** (not `updateStep` — it returns early while the help overlay is *held*, which is
  ordinary use); `alt+*` and `alt+p` **claim their trigger key**, closing the Alt+H leak the game has
  always had. Two comments in `alt.lua`/`words.lua` that described the old release rule were corrected
  in the same commit — they explain the mechanism it changes.
- **`c1ee63c` — P-18-01b, the restorations.** `alt+shift+escape` and `ctrl+alt+shift+up/down` bound to
  the same hoisted handler values, and `Key.is_alt(k)` restores the bare-Alt swallow. **No new
  behaviour: all three gestures work as they did before the combo conversion.** The Shift/Alt
  asymmetry is left alone deliberately and says so in the comment.
- **`c3388de` — P-18-02 + P-18-03, delegated.** Sonnet, model explicit, prompt of record
  `../../../validation/prompts/P-18-02-03-proxy-and-ismod.md`, forbidden from touching git state, told
  to leave the edits uncommitted. It did exactly the nine sites, deleted the proxy, retired **only**
  the marker inside it, and gave `isMod` `Key.is_mod`'s body. **I reviewed the diff site by site
  before committing** and checked the marker set and the residual greps myself. Its report is in
  `../../../validation/outcomes/P-18-02-03-execution.md`.
- **Committed as one concern**, with the reason stated: the proxy and `isMod` were both local copies
  of what `Key` answers.
- **A verification limit I did not paper over:** every smoke run reaches the intro and no further, so
  the scene-level paths are reasoned. That `Key` resolves from project code is not new — the proxy
  proved it, and one environment serves all of a project's files.
- **WRAP:** report written; `session38/prompt.md` written (P-18-04/05/06, the two traps in P-18-04,
  the human smoke items, and the Sonnet-worker pattern that worked); pointer repointed.
