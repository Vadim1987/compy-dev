# session38 — finish the keyboard deepfix (P-18-04 … P-18-06), then the next step the owner names

Read and strictly respect `agents/sessions.md` and `agents/validation.md`.
Boot normally: this prompt, then `../session37/report.md` in full, then the
session37 commissioning prompt and its track. Create `session38/track.md`.
Do not edit any historical session artifact.

Baseline: `busted tests` → **946 / 0 / 0 / 10**. It has not moved for two
sessions and should not move here either: **all remaining work is in a nested
example repo with no test suite.** The 10 pending are sanctioned (three
routing-grid gaps, seven reserved-combo outlines); an **eleventh** is a finding.

## Where the work stands

**P18 decomposed and is two-thirds done.** The step is
`../../../validation/reviews/S27-triage-and-plan.md` §15.4; its analysis pass produced two
documents you must read before touching code:

- **`../../../validation/reviews/P-18-00-keyboard-deepfix-design.md`** — why the mechanism is what it
  is. §1.1 (the game's rules are not ours), §1.2 (the delivery order is not a guarantee), §2.2 (the
  inter-channel assumption, exactly), §2.3 (what the example built because the platform withheld it),
  §7.1 (requirements R1–R5), §9 (the derivation, the impossibility result, and the settled shape).
- **`../../../validation/reviews/P-18-00-triage-and-plan.md`** — the plan. §0 holds two owner
  calibrations that govern everything, §5 holds the four rulings (all closed), §6 is the execution
  record.

**Landed in `src/examples/keyboard` (nothing pushed):** the upstream merge `17289e9` and its
correction `ca6d5df`; **P-18-01** `c60b818` (the heal — a glyph claim is released by a device poll in
`love.update`, not by an event); **P-18-01b** `c1ee63c` (three restorations of gestures the combo
conversion had narrowed); **P-18-02 + P-18-03** `c3388de` (the `INPUT` proxy dissolved) and
`9a20433` (the `isMod` alias deleted, its six call sites ask `Key.is_mod`).

**Then a cold Opus revalidation was commissioned and returned *sound in design, unsound as landed*.**
Three corrections followed and they are the most important thing to read before you touch this code
(§7 of the triage, and `../../../validation/reviews/S37-P18-revalidation.md`):

- **`52a8d69`** — the claim poll could **raise**: `love.keyboard.isDown` errors on a string that is
  not a LÖVE key constant, so a shifted symbol typed in Words crashed the game on the next frame.
  `glyphBaseKey` now lives in `input.lua` and a claim that cannot be polled is never taken.
- **`42d1a8b`** — a chord claims its trigger for **every** chord, not just the swallowed Alt class,
  and `alt+shift+*` restores a fourth narrowing.
- **`ece2c1b`** — `indicators.lua`'s comment no longer says the Shift state is "edge-tracked".

**And the design of record is rewritten** — `doc/development/internals/examples/keyboard.md` now
describes the shipped mechanism, both consumers, and a smoke checklist of cases only a human can
reach. §15.4 wanted that revision *before* the code; it arrived after, which is recorded.

## Your task — the last three children, then stop and ask

Each is small, independent of the others, and gets its own commit.

**P-18-04 — `Ctrl+Alt+H` becomes a real shortcut.** Ruled (owner, 2026-08-12): the hand-match in
`alt.lua`'s `altKeypressed` is *"clear boilerplate, nothing unique to preserve — and exactly the type
of construction we want to get rid of"*. Register `sc['ctrl+alt+h']` in `input.lua` and dispatch it
through a new **`onHint`** scene-descriptor entry that only `alt.lua` defines — **the shape `onNotch`
already has in that file**, which is why no `leave` hook and no restructuring is needed. Two things
this must get right, both recorded in the triage's §5: **`fn.ignore_repeat` is mandatory** (shortcuts
see every repeat, where the hand-match inherited the hook's `isrepeat` filter for free — an unwrapped
binding re-arms the hint every repeat frame, which is a rule change hiding inside a mechanical
conversion), and **the handler claims its trigger key**, as `alt+*` does.

**P-18-05 — `compy.before_exit` restores the pointer mode.** `main.lua` calls
`love.mouse.setRelativeMode(true)` at boot with a comment claiming *"the runner restores it on
exit"*. **That is false** — verified: `ConsoleController:stop_project_run` makes no `love.mouse` call,
and the only `setRelativeMode(false)` in the platform is `error_explorer.lua`, on the crash path. The
project can close it itself now. The framework-side question (should the platform tear down device
modes a project changed?) is **promoted, not answered here**.

**P-18-06 — comments only, and it SHRANK.** The capslock comment and `indicators.lua` are already
done (`ece2c1b` and the design-note rewrite). What remains: **`bubble.lua` gets the focus-loss caution
its hold judge earns** (owner ruling: do not convert it — its own timeout absorbs the failure), and a
line noting the **Shift/Alt asymmetry** that `P-18-01b`'s intro guard leaves in place on purpose.

**Then stop.** The sprint's remaining steps are the owner's to sequence: **P-17-00** (maze: merge,
evaluate, plan — the same three moves keyboard had, and `pr-assembly-guide.md` §5.1 says its slice
ref changes when it lands), **P-19** (sapper, which owns a live defect older than this feature),
**P-16**'s one ruling and `paint`, **P-10**'s docs, the probe deletion, **P-9c**'s two
order-dependent cases, **P-13** harmony revalidation, and **P-11**'s comment sweep.

## What a human owes, and you cannot do it

**The checklist exists now: `doc/development/smoke_checklists.md`, `keyboard`'s section.** It is
persistent (it outlives `wip/77`), it lists the eight menu entries by number, and **ten cases are
marked `[new]`** — they exercise the acceptance mechanism and have never been run by a human. This
container cannot inject keystrokes and has no device, so every smoke pass so far verified **loading**,
never a game scene. Ask the owner to run it; do not claim any of it.

**If you change an example's input mechanism, update its list in the same commit** — that rule is
written into the document, and a checklist that tests a mechanism the code no longer has is worse than
none, because it passes. **P-18-04 and P-18-05 both add cases**: the hint re-arm through its new
shortcut, and the pointer mode being restored on exit (row G1 is currently written as *known open*).

## Standing constraints

- **Smoke with `stdbuf -oL`**: `timeout 25 xvfb-run -a stdbuf -oL -eL love src play src/examples/keyboard`.
  Without line buffering the kill discards the output and a raising project looks healthy.
- **The game's rules are not ours** (§1.1). The test is *"would a player notice a difference?"* If
  yes, it is out of scope — raise it, do not do it.
- **Keep the project's names.** `GLYPH_CLAIMED`, `spendGlyph`, `isMod` all kept theirs deliberately.
- One concern per commit; a deviation lives in the workspace, not only in a commit message; suite
  stated at every commit even when untouched. **NEVER push** — not this repo, not the nested three.
- **Delegate the mechanical down.** A supervised Sonnet worker did `P-18-02`/`P-18-03` well against a
  written prompt (`../../../validation/prompts/P-18-02-03-proxy-and-ismod.md`); the parent reviewed
  the diff site by site and committed. **One worker at a time**, prompt of record on disk, and it
  never touches git state.
- The owner works in this tree: never sweep their unrelated changes or their in-code `REMARK:`
  markers into your commits. One marker was retired in `c3388de` **because the change answered it**;
  that is the only licence.
