# session34 — report

**Commissioned:** open with a choice the owner makes — which of four units runs next — then
execute it. The owner took **A (the docs step) and B (the maze font diagnostic)**, and ruled
one ordering question that was not on the menu.

Suite **955 / 0 / 0 / 3** throughout. Eleven commits, all docs. Nothing pushed. One sub-agent
(Sonnet, read-only, cold, prompt and report on disk).

## The owner's ordering ruling — the platform code precedes the keyboard heal

> *"later C precedes D — otherwise will be fixing D against outdated platform logic (even if it
> not overlaps, doing so would be conceptually wrong)."*

Session33 had put the docs step before the keyboard heal so its design reasoning would be done
against the approved *design*. This extends the same principle to the *code*. **Sequencing is
now docs → tests → platform code → the heal** (`115841cd`, amendment in P9b's step, reasoning
in the plan's new §13).

**Left open on purpose, not extrapolated:** the examples step edits
`examples/keyboard/input.lua` — the same file the heal rewrites — so the owner's argument
applies there *more* directly than to the platform code. Whether it must also precede the heal
was not ruled and is to be raised before the heal starts.

## A — the specification (five commits)

`fb81ecc0` project guide · `90935e2c` internals · `8a879534` ledger · `8cae175f` debt register
· `70eb4842` the dispatch-layers guide.

The project guide teaches asking the device, and teaches the **flag-shortcut pattern** for the
first time in the permanent corpus — plain heading, no ledger reference, per the owner's naming
ruling. The internals guide is written **concretely** against the ruled matcher shape, not at
the "the matcher reads the device" altitude: it is the one document whose job is signatures.

**Three things the step's enumeration did not have:**

1. **A third persistent doc documents the held-key bookkeeping** — `event_dispatch_layers.md`,
   on nobody's list.
2. **Two standing decisions besides the one on the list** still sent readers to the dissolved
   surface: Decision 25's pointer-payload bullet, and Decision 26's own statement of what is
   *not* in the argument list — the latter while defining the rule that made the argument
   unnecessary.
3. **`Key` exports no `gui()`.** The ruled shape calls the helpers per modifier row and the
   fourth row of `mod_triples` has none. Nothing registers a `gui` combo, so nothing is broken
   — but it is now a decision the platform step cannot avoid, and the `gui_k` debt entry no
   longer reads "harmless".

**Two judgement calls worth carrying.** No obituary for the tracked set in the project guide:
it appears nowhere at base `3256aac`, so for a reader of that guide it never existed, and "it
is gone" would advertise a moving part the PR is not asking anyone to review. And the five
dissolving debt entries are **marked, not deleted** — deleting a live defect's record on the
strength of a plan is how a defect goes unrecorded.

Separately: **three statements were false about the tree *today***, not merely after the sprint
(a hook receiving the held table, and two signatures). Corrected rather than marked.

## B — SM3a: the font hypothesis does not reproduce

`f4acdccf`; evidence in `../../../validation/notes/S34-sm3a-runtime-check.md`.

maze → another project → maze, driven through harmony under `xvfb-run` (the only way to get two
runs in one process): **same font object, same metrics, glyphs present, byte-identical
screenshots** — including with `clock` in the middle, which creates a 172px font, sets it and
never puts it back.

The hypothesis was structurally sound — the symbols come from `legend.txt` and are drawn with
the **ambient** `gfx.getFont()`, so maze really does inherit whatever is current. What
stabilises it is that **quitting returns to the console and the console sets its font every
frame**: a consequence of the return path, not a guarantee anyone stated. Session28 was right
that nothing in stop resets it.

**Recorded as unreproduced and deliberately not closed** — the owner saw it interactively, this
drove the app synthetically, and only two of the several font-setting projects were tried. The
framing exists so it cannot authorise a state-reset fix.

## The cold review, and the mistake it caught

Owner-requested at the end: a **Sonnet** sub-agent, briefed cold — given the diffs and the tree,
deliberately not my reasoning. Prompt and report in `validation/prompts|outcomes/`; fixes in
`13f6df5b`.

**It caught a regression I introduced.** Two debt-register bullets asserted **in the present
tense** that the builder asks the device. It does not (`controller.lua:395`). Worse: the
sentence one of them replaced was *true* before my edit. The docs-ahead-of-code discipline
exists precisely to prevent that, and I failed it in the one file whose sibling entries all
carry markers. Also: the key-files table had silently lost two live exports with no marker.

Declined with reasons: the `gui` entry's placement under *"Anticipated — revisit at the named
point"* is right, since naming the point is what that section is for.

## Non-obvious points worth carrying

- **Writing a spec before the code is a tense discipline, not a marker discipline.** Markers
  catch whole passages. What slips through is a *sentence* whose verb quietly moved to the
  present — and in a debt register, where every neighbouring entry is marked, that reads as
  deliberate.
- **The stability the diagnostic found is accidental, and that is the finding.** "It does not
  reproduce" and "it cannot happen" are different claims; only the first is supported.
- **Harmony's two traps, both of which cost a run** and both of which belong to P13: `hasGlyphs`
  on a string containing newlines answers `false`, and `release_keys()` on the line after a
  combo clears the modifier *before* the queued keypress dispatches — so the shortcut silently
  never fires and the scenario keeps typing into a still-running project.
- **A heading rename is a two-file edit.** The internals heading lost its dissolved symbol; its
  one citation in `tests/` was fixed in the same commit, because a citation that no longer
  resolves reads as authoritative.
