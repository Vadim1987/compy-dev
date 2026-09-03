---
description: the edge remainder analysed by essence rather than by conflict, and the three-way stack (#45 + ours + edge) built and run
status: active
audience: developer
authored: llm
session: 70
date: 2026-09-03
---

# The edge, by essence — and does the stack hold

**Owner, 2026-09-03:** *"did you analyze all drifts by essence? exactly not only
'will it merge cleanly' but 'will the changes interfere/break our tree'?"* — plus
the release order: **#45, then our PR, then the remainder of the edge**, and *"our
goal is to ensure they stack cleanly."*

**Honest starting position.** #45 had been analysed by essence — a merge that was
resolved and **run**, whose failures are behavioural findings. `keyboard` had been,
at its own scale (what the build script emits). `maze` needed none: zero drift.
**The edge remainder had not.** It had a conflict prediction and a reading of commit
subjects. This note closes that gap and then tests the stack.

## 0. One correction to the published count

The remainder is **15 commits, not 16**. `9cb27e0f` — the filesystem durability API
— appears in an *edge-minus-#45* listing but is **already an ancestor of our head**;
it is our merge base with the edge. The correct derivation subtracts both:

```sh
git rev-list --count --no-merges HEAD..dsent-https/dsent/dev ^upstream-pr/45   # 15
```

Corrected in the register entry and in `doc/development/upstream_drift.md`.

## 1. The 15, by what they would do to our tree

| commit | subject | touches us? | essence verdict |
|---|---|---|---|
| `617bbe65` | android: exit through Home before closing the IDE | **yes — `controller.lua`, `consoleController.lua`** | **the one real interference. See §2** |
| `16fe6a7e` | storage: show the internal fallback at the prompt | **yes — the widget's label type** | a **surface widening**, not a break; see §3 |
| `ebc3117c` | perf(input): cut per-character render cost (open PR #41) | **yes — `userInputView:render_input`** | deletes a per-character overflow recomputation and `wrap_reverse`. Our branch edited the same function but not those lines, so it applies. **Risk is visual, not testable here** — no display in this container. Device-pass item |
| `9693779a` | terminal: gate per-frame repaint on a dirty flag | indirectly — the canvas the console draws through | same class: a **draw-path** change whose failure mode is a stale frame, invisible to a headless suite. Device-pass item |
| `d09763a8` `ea6efd1d` `6897d689` `9ed375d4` | the 64-slot palette, black's own bright slot, extended terminal slots, stricter index validation | marginally — `conf/colors.lua` symbols | **additive.** New slots 16–55; our code uses symbolic names (`Color[Color.cyan + Color.bright]`). Two things to look at once: **black's bright slot changes an existing symbolic combination**, and *reject every invalid index* turns a previously tolerated out-of-range index into a raise |
| `331b7eed` `5daf0173` | the colours example, and its layout fix | **collision of shape, not of meaning** | the same file arrives by two routes (ours via the platform merge, theirs on the edge) — an add/add of 245 against 247 lines. Take theirs: it contains the later fix |
| `9cb27e0f` | filesystem durability API | — | **already ours** (see §0) |
| `38d7c754` `2e416662` | filesystem info for checkpoints, and its test | no | editor/filesystem only |
| `9f6114e8` `8242d043` | packaging: zip instead of 7-zip, release signing | no | build and CI |
| `5a52cba2` | **pin the Lua 5.1 Busted runtime** | no, and **it is useful to us** | see §4 |

## 2. The one real interference — Ctrl+Escape stops going Home

**`617bbe65` reroutes every full application exit through a new `util/application`
module**: `Application.request_application_exit()` sets a request, and `love.quit`
consumes it and calls `return_home_before_exit()` so the Android launcher can
replace the locked root task. The typed `quit()` a project can call becomes
`Application.request_exit()`.

**Our branch moved the Ctrl+Escape handler.** At the PR base it was an inline
`if Key.ctrl() and k == 'escape' then love.event.quit() end` inside
`handlers.keyreleased` — which is exactly the line `617bbe65` rewrites. We
restructured it into the privileged reservation table:

```lua
keyreleased = {
  ['ctrl+escape'] = function() love.event.quit() end,
},
```

**What a merge does with that, verified in the stacked tree:**

- `consoleController.prepare_env`'s `quit` **takes their change cleanly** — a
  project's typed `quit()` routes through `Application`. ✅
- `handlers.keyreleased` **conflicts**, visibly, and the architecturally right
  resolution is *ours* — the reservation table is the whole point of
  `D-RESERVE-TABLE`. ✅
- And then **the reservation still calls `love.event.quit()` directly**, which never
  sets the request flag. `love.quit` finds no request; unless the application is
  already in `shutdown`, it exits **without returning Home**. ❌

So the defect is not in the conflict — it is in the **line that does not conflict**,
one screen above it. A merger who resolves the visible hunk correctly still ships
the regression, on a device, where no headless suite can see it.

**The fix is one line**, and it is in the stacked tree as proof:
`['ctrl+escape'] = function() Application.request_application_exit() end`.

*This is the answer to the owner's question in its sharpest form: "does it merge"
and "does it still do what it did" are different questions, and here they give
different answers.*

## 3. The prompt label — a widening that reaches our documented surface

`16fe6a7e` retypes the widget's label from `string` to `PromptLabel`
(`string | { text, tone }`) and teaches the status line to colour the tone. Our
project-facing `prompt` key writes that field directly
(`userInputController`, the `configure` path).

**In the stacked tree the edge's own tests for it pass through our constructor**
once their positional call sites are updated — so a project passing
`prompt = { text = ..., tone = 'warning' }` would work. The question is whether the
guide **admits** it, refuses it, or stays silent. That is a surface decision for
whoever takes the edge merge; it is recorded on the register entry rather than
here.

## 4. One item in the remainder is worth taking *early*, not late

`5a52cba2` adds `util/run-busted`: a launcher that finds the first interpreter
reporting `_VERSION == "Lua 5.1"` (trying `luajit`, `lua5.1`, `lua` in that order),
verifies Busted is installed for it, and runs the suite through it — otherwise it
refuses with an actionable message.

**This phase has a standing caveat that this addresses**: every suite claim in this
workspace states its interpreter, because the container runs LuaJIT 2.1 and the
owner runs PUC Lua, and *container-green is not their-machine-green*. A
repository-owned launcher that pins the runtime is the mechanical version of that
caveat. It touches `justfile`, `.github/`, and a new `util/` file — **our branch
touches `justfile` and `.gitignore` too**, so it is not free, but it is small and it
is the only item in the remainder with a reason to come forward.

## 5. The stack, built and run

Order as the owner stated it: **#45 → ours → the edge remainder.** Built in the
throwaway clone, resolved, run.

| stage | suite |
|---|---|
| ours alone | 1055 / 0 |
| #45 alone | 753 / 0 |
| ours + #45 | 1100 / 22 |
| **ours + #45 + the whole edge** | **1108 / 22** |

**The 22 at the third stage are the same 22 as at the second.** The edge adds
**no new failure** to the stack. Its only casualties were two of its own tests
whose positional call sites assume the constructor shape #45 changed — mechanical,
fixed in the same minute, and then the tone-bearing label test **passes through our
signature**.

Resolutions used at the edge stage: `.gitignore` union; the colours example
**theirs**; the console model **theirs, adapted to our constructor arity**; the
model's annotations **ours plus their `PromptLabel` type**; `controller.lua`
**ours structurally, with their exit routing wired into the reservation** (§2).

**Verdict: they stack.** The residual work is the same editor-route re-pinning that
#45 already owed, plus the one-line exit routing and one surface decision. Nothing
in the edge remainder is *incompatible* with this feature; one thing in it is
**silently lossy** if merged without thought, and that thing is now named.

## 6. What this note does not claim

- The 16 upstream-side `editor_spec` failures are still the probe's `--ours` on
  `controller.lua`'s power-shortcut block at the #45 stage. They are **unchanged**
  by the edge, which is itself informative, but they remain the reconciliation's
  real work.
- Two of the findings above (`ebc3117c`, `9693779a`) are **draw-path** changes whose
  failure mode a headless suite cannot see. They are named for the device pass, not
  cleared.
