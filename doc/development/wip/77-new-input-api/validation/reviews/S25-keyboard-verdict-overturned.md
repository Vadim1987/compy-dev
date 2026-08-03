---
description: The "keyboard needs nothing" verdict was wrong — it hand-rolls four things the new API provides, and its own comments document two framework limitations the API removed
status: active
audience: developer
authored: llm
reviewed: none
---

# S25 · keyboard: "nothing to migrate" overturned

Session24 answered smoke report 7 — *does keyboard bypass the routes?* — and
carried the answer ("no; its `love.*` handlers are captured as hooks,
Decision 10") into a second, unasked verdict: **nothing to migrate**. The
owner challenged it (2026-08-03): *"I am surprised how keyboard (project most
tied to keyboard input) is not supposedly benefitting from new API. what's the
point and value of API then?"*

They are right, and the record was wrong. keyboard is the **strongest
evidence for the API in the tree**. It hand-rolls four things the framework
now provides, and two of its own comments describe framework limitations that
this feature removed and never told it about.

## What keyboard re-implements

### 1 · Combo dispatch, including the l/r modifier fold

`input.lua`, `reservedChord(k)` and `appChord(k)`: `shift+escape` → back,
`ctrl+alt+up`/`ctrl+alt+down` → notch adjust, `alt+p` → pause. The modifier
state comes from `modHeld("lshift", "rshift")` and friends, folded by hand in
`isMod`/`inputUpdateMods`.

This is `compy.input.shortcuts.keypressed[combo]` (Decision 8) — including
the fold: `Key.mod_triples` maps `lshift`/`rshift` → `shift`, and
`combo_string` emits `ctrl+alt+up` in a fixed precedence. keyboard rebuilt
the normaliser to get to the same string.

### 2 · A key-repeat filter that exists because of a limitation we lifted

`input.lua`'s header comment:

> The IDE keeps key-repeat enabled and **strips the isrepeat flag** before
> calling the game, so repeats are filtered here by edge tracking.

That was **true, and is now stale**. At the pre-feature baseline `3256aac`
the gateway is `local function keypressed(k)` — one parameter, so `isrepeat`
never left the console. Today it is threaded all the way:
`occupy_keyboard` installs `pic:keypressed(k, sc, isr)`, and
`ProjectInputController:keypressed` dispatches
`('keypressed', k, k, Controller.held_keys(), isr)` — a project hook's third
argument.

So `INPUT.held`-as-repeat-filter and `inputStale()` reproduce a flag the
project is now handed. Not all of it: `INPUT.upRecent` / `INPUT_UP_GRACE`
target a trailing *textinput* repeat, and `textinput` carries no such flag in
LÖVE, so that part of the machinery stays whatever we do.

### 3 · A mirror of the held-key set — and the open decision it answers

`INPUT.held`, `INPUT.shift/ctrl/alt`, maintained on every press and release.
The framework hands a read-only held-key view as **argument 2** of every hook
and shortcut (Decision 13).

But the argument is not enough for keyboard, and this is the interesting
part: `keyboard_view.lua:171,178` read `INPUT.shift` **during draw**, to
decide whether to render shifted key labels. A per-event argument cannot
serve a per-frame renderer, which is exactly why the mirror exists.

That makes keyboard the real consumer the standing open decision
*"`compy.keys_pressed` is not exposed to projects"*
(`technical_debt/input.md`) has been waiting for — and it answers it:
**callback-argument access alone is insufficient**. A project that *renders*
held state needs to read it outside an event.

### 4 · An exit hook it believes does not exist

Same comment: *"the runner exposes no project-exit cleanup hook to restore it
on Ctrl+Esc force-exit; see Beads compy-keyboard-exit-hook"* — which is why
keyboard leaves global key-repeat enabled after it quits.

`compy.before_exit` exists (`consoleController.lua:705-728`) and fires on
every stop path that runs a project — Ctrl+Q, Ctrl+S, Ctrl+T and the
Ctrl+Esc/`love.quit` path all reach `stop_project_run` (established in
session24's W4). The cleanup keyboard wanted is available.

## One corroboration worth recording

`input.lua` also states: *"the IDE delivers textinput BEFORE the matching
keypress (the reverse of desktop LÖVE)"*, and describes an arm-a-gate scheme
failing because of it. That is the C1 hazard — the keypressed/textinput
ordering — observed independently by an unrelated project, before we found
it. Whether the *direction* it claims still holds under the current run loop
is untested; the hazard it describes is the one C1 settled.

## Answering the owner's question directly

**"Why would we even encourage doing that outside of the new API?"** We should
not. `love.*` capture (Decision 10) is a **compatibility ramp**, not a
recommendation: it exists so an unmodified LÖVE project runs, and so a project
that wants to stay portable can. keyboard is not portable — `sound.lua:7` is
`sfx = compy.audio` — so the one argument for staying on `love.*` does not
apply to it.

**"What's the point and value of the API then?"** Stated honestly, and
keyboard is the case that shows it rather than the case that undercuts it:

| What keyboard hand-rolls | What the API gives |
|---|---|
| `reservedChord` / `appChord` + the l/r fold | `shortcuts[event][combo]`, normalised (Decision 8) |
| `inputStale` repeat filtering | `isrepeat` as hook argument 3 |
| `INPUT.held` mirror | the held-key view as argument 2 — **and the gap it exposes for draw-time reads** |
| leaked global key-repeat state | `compy.before_exit` |

The overlay — the bulk of the API — genuinely does not apply: keyboard never
solicits text. That is not a hole in the API. It is the difference between an
input *surface* and input *routing*, and keyboard needs the second.

## Executed (owner, 2026-08-03)

> *"sure we want it. the reason why game invented its own equivalents was our
> API not being ready. so its the best demo case and acceptance. and yes lets
> expose the table"*

- **Platform** — `compy.input.keys_pressed`, Decision 20, four pinned rows
  (suite 875 → 879). The debt ledger's open decision is closed.
- **keyboard** — `4814407`: hooks instead of `love.*`, three reserved chords
  as shortcuts, `isrepeat` instead of edge tracking, and `INPUT` reduced to a
  proxy over the framework's held set. Every consumer of `INPUT.shift` /
  `INPUT.held` across five files is untouched.
- **Not migrated, on purpose** — `appChord`. "Every `alt+x` is a chord" is a
  rule about a modifier *class*, and a combo table binds one combo at a time.
  Filed as debt: *"A combo table cannot express a modifier-class rule"*.
- **Two open decisions got their first real consumer**, which is what an
  acceptance case is for: shortcuts' `isrepeat` semantics (keyboard's chords
  hand-write the gate, or a held `ctrl+alt+up` ramps the notch every frame),
  and the held-key exposure, now ruled.
- **Unverified**: none of this is exercised by the platform suite, and the
  game cannot be driven headlessly. It needs the owner's smoke test.

## Recommendation (as it stood before the ruling)

1. **Correct the record.** `pr-assembly-guide.md` §5 said "nothing to
   migrate, nothing to commit". Done in the same commit as this note.
2. **Propose a keyboard migration** — not executed here, because it refactors
   750 lines of another repo's game logic and is the owner's call. Scoped:
   - `love.keypressed/keyreleased/textinput` → `compy.input.hooks.*`
     (three assignments; the wrappers exist only to satisfy LÖVE's global
     convention and disappear);
   - `reservedChord` / `appChord` → four `shortcuts.keypressed[combo]`
     entries, deleting `modHeld`/`isMod` and the hand fold;
   - `inputStale`'s repeat half → the `isrepeat` argument, keeping the
     `upRecent` grace for trailing textinput;
   - key-repeat/text-input restoration → `compy.before_exit`.
3. **Feed finding 3 back into the open decision.** keyboard is evidence that
   the held-key view needs a project-readable form outside the event
   argument. That is a ruling for the owner, and it is the one item here that
   could still change the *platform* before the PR.
