# S43-P-20-02 — cold revalidation of session39's tail

Worker: Sonnet, model passed explicitly, read-only. Scope: platform `faedac15`,
`c3b74959`, `56c0c26f`, `230cb32e` (P-17-16), `f45a2588` (track), `5b6eebc0`
(wrap + report); nested `maze` `da9d1c2`.

## Verdict: SOUND

The tail's one code change (`da9d1c2`) correctly and completely implements the
owner's ruling on the cold review's finding — not more, not less — and every
re-runnable factual claim in the wrap checks out. The process finding stands
independently of the code being right: **nothing reviewed the tail before this
task.** `S43-agent-authorship-audit.md` already says so; this task is the first
thing to actually check the tail's substance, and it holds up.

## Findings

### S2 — the tail was never reviewed before now (confirmed, not just alleged)

`S39-P17-cold-review.md` (`P-17-15`) reviewed the migration through `37b996a`/
`bef4258` and was commissioned at `a1842a2f`. Everything after that — the
`P-17-16` planning docs, the `da9d1c2` fix, and the wrap — landed with **no
second pair of eyes**, cold or otherwise. Corroborated independently of the
authorship audit's commit-trailer method: `git log -1 --format=%B faedac15`
and `5b6eebc0` both show literal `\n` escapes in the body and no
`Co-Authored-By: Claude` trailer, while `a1842a2f`'s message has real
newlines and the trailer. The handover fell exactly where the audit says —
between commissioning the cold review and acting on its finding — and the
acting half went out without review until now. This is the useful thing to
report, per the prompt: it is now closed by this task, not before.

### S3 — `session39/report.md:9-11` over-attributes the Ctrl+Alt case to the cold review

The wrap says *"The cold review found one player-visible narrowing: the exact
Shift+Escape shortcut omitted held Alt, Ctrl, and Ctrl+Alt."* `S39-P17-cold-review.md:14-16`
only names Alt and Ctrl separately (*"Thus Alt+Shift+Escape and Ctrl+Shift+Escape
leave a direct-control game level..."*) — it never writes the phrase "Ctrl+Alt".
`session39/track.md`'s own entry is accurate here (*"I verified that the
Ctrl+Alt+Shift form was also in the upstream predicate"* — self-attributed,
correctly). The report's phrasing folds the tail's own follow-on verification
into "the cold review found," which is a small credit-attribution slip, not a
factual error — the Ctrl+Alt+Shift case is real (see below) and the fix covers
it. Severity capped at S3 because the resulting code and test claims are
unaffected.

### Everything else checked clean

**1. Finding → ruling → code chain — verified end to end.**
- Upstream predicate, read directly (not from the assessment doc): both
  `is_shift_down()` copies at `dsent/dsent/dev` (`maze_main.lua:145-148`,
  `draw_main.lua:305-308`) test only `lshift`/`rshift` via
  `love.keyboard.isDown`, with **no** reference to ctrl or alt state anywhere
  in the function. So the upstream gesture family is exactly the 2×2 cross of
  {Shift alone, +Ctrl, +Alt, +Ctrl+Alt} — confirming the report's "Alt, Ctrl,
  and Ctrl+Alt" characterization is factually correct, even though (per the S3
  finding above) the cold review itself only named two of the three.
- Owner ruling, `P-17-04-triage-and-substeps.md` (added by `c3b74959`, widened
  by `56c0c26f`, closed by `230cb32e`): register all three missing variants,
  same consuming handler, restoring but not deciding the family.
- Code, `da9d1c2` (`maze_main.lua:216-224`, `draw_main.lua:360-368`): adds
  `alt+shift+escape`, `ctrl+shift+escape`, `ctrl+alt+shift+escape`, each bound
  to `compy.input.fn.stop_here(on_escape)` — the identical wrapper the
  pre-existing `shift+escape` binding already used. Confirmed present in the
  **emitted** programs too (`.compy/build` output, `maze/main.lua:217-224`,
  `draw/main.lua:361-368`), not just the source. This is exactly the ruling:
  not more (no other combo added), not less (all three present, in both
  programs).
- Combo-string sanity: `src/util/key.lua`'s `normalize_combo` canonicalises
  modifiers in fixed order `ctrl, alt, shift`, trigger last. All three
  registered strings are already in that order, so they register and dispatch
  as written — no silent mis-registration.

**2. Player-visible behaviour — narrowing closed, no new narrowing.**
`compy.input.fn.stop_here` (`src/controller/consoleController.lua:494-499`)
runs the handler then returns `true`, which stops propagation before the
shown widget is reached — the same behaviour the original `shift+escape`
binding already had. Before the fix, the three unregistered variants fell
through to the widget's plain-Escape path and cleared the draft without
exiting (the cold review's second observation, lines 26-30); after the fix
they are consumed at the shortcut layer exactly like `shift+escape`, so that
asymmetry is gone, not shifted elsewhere. All four bindings route to the same
`on_escape()` → `to_menu()`/`toDrawMenu()`, which already calls
`compy.input.hide()` (the `P-17-07`/`R2` teardown), so the new variants
inherit that teardown and do not reopen the "field left shown over the menu"
class of bug. The typed `<` exit is untouched (`draw_main.lua:129`, kept per
the owner) and out of this fix's scope, as intended.

**3. The wrap's factual claims — re-run, all confirmed.**
- `busted tests` from `/repo`, HEAD `95f9255f` (current tip, past this scope):
  **947 / 0 / 0 / 10** — one more success than session39's `946`, exactly the
  session42 addition the prompt of record says to expect, not a finding.
- Maze suite, `PATH=<luajit shim>:$PATH ./verify.sh` at `da9d1c2`:
  **29 + 10 + 3 = 42 / 0 / 0**, matching the commit message and the wrap.
- Both emitted programs launch headless and clean:
  `timeout 25 xvfb-run -a stdbuf -oL -eL love src play <emit>/maze` and
  `.../draw` both print `Project play opened` / `Running 'play'` before the
  timeout kill (exit 124), no Lua exception. Matches the wrap's claim.
- "P-17 code work is complete through P-17-16" — verified against
  `P-17-04-triage-and-substeps.md`: every substep `P-17-06`…`P-17-16` (except
  the removed `P-17-13` tombstone) carries a `✅ DONE <hash>` marker; `P-17-15`
  (the cold review) and `P-17-05` (the owner walkthrough, run as conversation)
  are also closed. Nothing left dangling.
- `da9d1c2` is unpushed and is the tip of `newinput-edge`; not present on
  `dsent` or `origin` remotes. Working tree clean.

**4. LSP/diagnostics sanity.** `mcp__lua-lsp__diagnostics` on `maze_main.lua`
and `draw_main.lua` shows only pre-existing `lowercase-global` INFOs (this
codebase's deliberate global-based convention) and a handful of pre-existing
warnings unrelated to and on lines far from the four added registrations in
each file (`maze_main.lua:216-224`, `draw_main.lua:360-368`) — no new
diagnostic introduced by `da9d1c2`.

**5. Revalidation checklist (`agents/rules/revalidation.md` §Checklist),
applied to the tail's documentary output (`P-17-04` rows, `track.md`,
`report.md`):**
- *Internal coherence*: the `P-17-16` section's three edits (`c3b74959` →
  `56c0c26f` → `230cb32e`) read as one settling narrative — first draft names
  two variants, is corrected to three, is marked done — no leftover
  contradiction between the final text and the `✅ DONE` marker.
- *Coherence toward intent*: the ruling was "make every supported variant
  visible"; the code registers exactly the supported family, confirmed
  against upstream source directly (§1 above), not the assessment doc's
  paraphrase.
- *Coherence toward surrounding context*: `S27-triage-and-plan.md`'s P17 row
  and the P-20-02 commissioning row already describe this tail accurately;
  no drift found against them.
- *Consistency*: the `✅ **DONE `<hash>`**` marker style matches every other
  closed `P-17-xx` row.
- *Integrity*: cross-links (`da9d1c2`, file paths) resolve; nothing dropped.
- *Gap*: no over-reach — the tail's four docs commits stay inside the
  already-ratified "register the variants" ruling; no scope creep into
  unrelated `P-17` items or into `P11`'s deferred compaction.
- *Artifact*: `S39-P17-cold-review.md` itself was committed by the tail
  (`faedac15`) alongside starting the `P-17-16` planning — a minor commit-
  hygiene note (two purposes, one commit) rather than a defect; the content
  is unedited from what the (already-validated) cold review produced.

## Not checked, and why

- No live keystroke injection was possible in this container (same limit the
  cold review itself notes), so the Escape gestures are verified by exact
  source/emitted-code registration and the platform's own combo-dispatch
  logic, not by pressing the key in a running game scene. Human smoke remains
  the only way to close that gap, as both the cold review and session39 say.
- Did not re-derive the S27 sprint-plan narrative beyond confirming its P17/
  P-20-02 rows are consistent with what was found here — out of this task's
  scope.
