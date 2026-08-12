# Prompt of record — P-18-02 and P-18-03: dissolve the `INPUT` proxy, and point `isMod` at the platform

**Commissioned:** 2026-08-12, session37. **Model: Sonnet, passed explicitly.** **Mechanical.**
Supervised: the parent verifies the diff and commits. **Do not commit anything yourself.**

**HARD SAFETY RULE:** do not `checkout`, `switch`, `stash`, `merge`, `reset`, `commit` or otherwise
touch git state in **any** repository. Both `/repo` and `/repo/src/examples/keyboard` are mid-work on
live branches. Edit files only.

## Context you need and nothing more

`/repo/src/examples/keyboard` is a LÖVE2D game, a separate repo nested in this one, running as a
project on the Compy platform. It used to keep a table called `INPUT` mirroring which keys were down.
That mirror is gone; what remains is a **metatable proxy** in `input.lua` whose only job is to answer
three names by calling the platform's `Key`:

```lua
INPUT = setmetatable({ }, {
  __index = function(_, k)
    if k == "shift" then return Key.shift() end
    if k == "ctrl" then return Key.ctrl() end
    if k == "alt" then return Key.alt() end
  end,
})
```

Every read of `INPUT.shift` / `.ctrl` / `.alt` is therefore already a `Key` call wearing a disguise.
Your job is to remove the disguise. `Key` is a platform global available to the project (this game
already calls `Key.shift()` and `Key.is_alt()` directly in `input.lua`).

## P-18-02 — replace the nine reads, then delete the proxy

Exactly these sites, verified 2026-08-12 (`grep -n "INPUT\.[a-zA-Z]" *.lua` in the game directory):

| file:line | now | becomes |
|---|---|---|
| `alt.lua:215` | `if k == "h" and INPUT.ctrl and INPUT.alt then` | `Key.ctrl()` and `Key.alt()` |
| `alt.lua:242` | `return INPUT.shift` | `return Key.shift()` |
| `alt.lua:252` | `if INPUT.shift then` | `if Key.shift() then` |
| `help.lua:18` | `return h and INPUT.alt and not INPUT.ctrl` | `Key.alt()`, `Key.ctrl()` |
| `input.lua:237` | `if INPUT.alt then return end` | `if Key.alt() then return end` |
| `input.lua:238` | `if INPUT.ctrl then return end` | `if Key.ctrl() then return end` |
| `input.lua:240` | `tostring(INPUT.shift)` | `tostring(Key.shift())` |
| `input.lua:242` | `capsReconcile(t, INPUT.shift)` | `capsReconcile(t, Key.shift())` |
| `keyboard_view.lua:286` | `if INPUT.shift then return not CAPS_STATE.on end` | `if Key.shift() then …` |

Then **delete the `INPUT` table and its `setmetatable` block** from `input.lua`, and **retire the
in-code marker sitting inside it** — the line reading
`---> REMARK: WHY WOULD WE DO IT AND WHY USE custom 'INPUT' at all?`. That marker asked exactly this
question and this change answers it, so it goes with the code it was attached to. **It is the only
marker you may touch. Leave every other `REMARK:` / `INTERIM:` line in the repository alone.**

**Comments are part of the edit, not decoration.** Wherever a comment near a changed line describes
the reads as going "through the INPUT proxy", make it describe what the code now does. `input.lua`'s
file header has a paragraph about the proxy (search for `INPUT proxy`) — rewrite that paragraph so it
states the fact that survives: held modifier state is asked of the keyboard through `Key`, which folds
each l/r pair the way a combo string does, and a draw-time reader needs that because it has no event
argument to consult. **Do not** add new claims, and do not lengthen the header overall.

## P-18-03 — `isMod` keeps its name and gains the platform's body

`input.lua:132` defines `isMod(k)` by hard-coding six key names. Replace **the body only**:

```lua
function isMod(k)
  return Key.is_mod(k)
end
```

`Key.is_mod` (`/repo/src/util/key.lua`) tests membership of a fold table built from exactly the same
six names — verified equivalent. **The six call sites do not move** (`alt.lua:205`,
`astrocore.lua:145`, `findkey.lua:132`, `hide.lua:275`, `bubble.lua:147`, `train.lua:240`): the point
of keeping the name is that five other files stay untouched. Adjust the function's own comment if it
enumerates the names.

## Constraints

1. **Behaviour must not change.** Every edit above is the same question asked of the same source; the
   proxy already called `Key`. If you find a site where the replacement would NOT be equivalent, stop
   and report it instead of adapting it.
2. **Do not restructure, rename, reorder or tidy anything.** No changes beyond the sites listed and
   their comments.
3. **Line length in this game's files is ≤ 64 characters for comments** — match the surrounding
   style; do not reflow untouched lines.
4. **Do not touch** `words.lua`, `bubble.lua`'s logic, `main.lua`, any scene's judging code, or any
   other repository.

## Verify before you report

- `grep -rn "INPUT\." *.lua` in the game directory returns **nothing** but comments you wrote
  deliberately, and `grep -rn "setmetatable" input.lua` no longer shows the proxy.
- `grep -rn "REMARK:\|INTERIM:" *.lua` shows the same set as before **minus** the one marker named
  above. Report the before and after counts.
- The app still loads: from `/repo`, run
  `timeout 25 xvfb-run -a stdbuf -oL -eL love src play src/examples/keyboard`. Expect the three
  framework lines (`Project play opened`, `Press Ctrl-Esc to exit`, `INFO : Running 'play'`) and no
  Lua error; the run is killed by the timeout, which is success. **`stdbuf -oL` is not optional** —
  without it LÖVE's output is block-buffered and the kill discards it, so a crashed project looks
  exactly like a healthy one.
- Note plainly that reaching a game scene needs keystrokes this container cannot inject, so the load
  is what you verified and the scenes are not.

## Report

Write a short note to
`/repo/doc/development/wip/77-new-input-api/validation/outcomes/P-18-02-03-execution.md`: the sites
changed, the marker counts before and after, the smoke result, anything you found that did not match
this prompt, and anything you could not verify. Leave the working tree with the edits **uncommitted**.
