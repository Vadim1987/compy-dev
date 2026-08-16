# P-09 — formal closure

Owner, 2026-08-16: the nested repo changes were in fact committed; close P9.
Verified before closing rather than taken on the word.

## What P9 asked for, and where each part stands

**(1) The changes committed, one commit per repo — DONE.** Each nested repo
carries its own local history and none of it is pushed:

| Repo | Branch / upstream | Head | Ahead |
|---|---|---|---|
| `maze` | `newinput-edge` ← `dsent/dsent/dev` | `c23cb59` | 10 |
| `keyboard` | `newinput`, **no upstream configured** | `e568961` | nothing pushed, nothing to push |
| `balloons` | ← `origin/main` | `cb1dd26` | 4 |

Working trees are clean apart from balloons' untracked `ISSUES.md` and two
`docs/` files, which are the owner's, not ours.

**(2) The smoke gate — the part that is not ours to close.** The row's `[REV]`
note is that committing is not verification: the three repos carry **no runnable
suite**, so the gate is a human smoke re-pass on the channels W1/W2/W3 touched,
`examples/keyboard` at minimum. That remains outstanding and is the same human
pass P17 and P18 wait on. **Closing P9 does not discharge it**, and this
document exists partly so that is not later misread.

**(3) SM3a — reported not reproduced, and deliberately not "fixed".** Session34
drove maze → another project → maze through harmony and found the legend font
identical each time: same object, same height, same glyph coverage,
byte-identical screenshots, including with `clock` in between (which sets a
172px font and never restores it).

The row is careful, and the care is worth preserving in the closure: the
observation was interactive, only two intervening projects were tried, and what
stabilises the font is that the console draws between runs and sets its own font
every frame — **a consequence of the return path, not a stated guarantee**. So
the hypothesis is *unreproduced*, not *disproved*, and it must not authorise a
state-reset fix. That is how the `wrap_handler` mistake happened once already.

## The closure

**P9 is closed as "the work it named is done; no reproduced defect remains".**
Nothing here is a fix, because nothing was reproduced. What the sprint carries
forward instead:

- the human smoke pass, already owed by P17/P18 — P9 adds `examples/keyboard` as
  a named minimum;
- SM3a as an **open observation**, not an open defect. If a future session sees
  a wrong legend font, `../notes/S34-sm3a-runtime-check.md` is the starting
  point and the console's per-frame font set is the first thing to check.

## What this closure is not

It is not a claim that the examples are verified. It is a claim that **the work
P9 named is done and the residue is named** — one human pass and one
observation, both belonging to someone with a display.
