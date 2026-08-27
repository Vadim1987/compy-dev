---
description: Outcome of LEDGER-01 — splitting doc/development/decisions/input.md into ACTIVE / RETIRED, plus the unimplemented-decisions list it exists to produce
status: active
audience: developer
authored: llm
reviewed: none
---

# LEDGER-01 — decisions ledger split into ACTIVE / RETIRED

Session49-spawned Sonnet subagent, 2026-08-27. Edited exactly one file:
`doc/development/decisions/input.md`. No other file was touched.

## 1. What moved to RETIRED

Five decisions, in ascending order, each moved with its heading and body byte-for-byte
unchanged (verified by `git diff` — every removed block reappears verbatim under `## RETIRED`,
nothing else in the file changed):

| # | Evidence in the heading |
|---|---|
| Decision 12 | `— NOT A DECISION, de-facto behaviour` |
| Decision 13 | `— SUPERSEDED by Decision 30` |
| Decision 16 | `— SUPERSEDED by Decisions 25 and 27` |
| Decision 20 | `— SUPERSEDED by Decision 30` |
| Decision 29 | `— SUPERSEDED by Decision 30` |

Mechanics: where a retired decision sat between two `---` thematic dividers (16 and 20 both
did), one divider was dropped with it and the other kept, so the ACTIVE stream still reads as
one continuous divider between its new neighbours rather than two dividers back to back.
Decisions 12, 13 and 29 had no dividers around them in the original and needed none removed.
The stray double-blank-line after Decision 20's heading, present in the source before this
edit, was carried over unchanged into RETIRED (visible in the diff) rather than "fixed", per
the never-reword rule.

Everything else — front matter, the Vocabulary section, "The problem this shape solves", the
29 remaining decisions, and the non-decision narrative sections (Implementation note, The
ergonomics payoff, Implementation alignment) — kept its original position and order, now inside
`## ACTIVE`. Cross-references are all prose ("see Decision 30", "SUPERSEDED by Decision 30")
rather than markdown links, so moving entries broke nothing; I grepped for anchor links
(`](#...)`) and found **zero** in the document, so there was nothing to fix or report there.

Before/after: `grep -c "^## Decision" doc/development/decisions/input.md` returns **34 before,
34 after** — every decision is still present, none renumbered.

## 2. Unimplemented decisions (verified in code)

Two, both confirmed by reading the source, not by inference from the doc alone.

### Decision 1 — console/editor convergence onto the shared chain

Decision 1's own consequence text says the console/editor migration onto the project route's
three-component chain (shortcuts/hooks/widget) is "deliberately left as a follow-on, not
attempted." That is still the tree's shape: `src/controller/consoleController.lua:1516`
(`ConsoleController:keypressed(k)`) and `src/controller/editorController.lua:825`
(`EditorController:keypressed(k)`) are their own narrow, single-argument dispatch methods —
`ConsoleController:keypressed` calls `self.editor:keypressed(k)` directly (line 1537) — distinct
from the project route's `dispatch(shortcuts, hooks, widget, event, trigger, ...)` chain that
`compy.input` is built on. Decision 26 and Decision 33's own scope note say the same thing in
different words ("the console/editor route still narrows to `CC:keypressed(k)`... its own
dispatch predates the feature"; "sorted out when those routes are adopted onto the combo
mechanism, not here"). Nothing about this is new information — the decision text is honest
about it — but it is a real, currently-open gap between "three sibling routes" (the decision's
stated model) and the two controllers that still run their own dispatch.

### Decision 35 — the configuration boundary (`show`/`configure` content ownership)

One day old, owner-ruled 2026-08-27, and its own text flags the target as `ARC-02` — a planned,
not-yet-landed pass (confirmed against `ROADMAP.md`: `ARC-01` is marked complete, `ARC-02` is
the next item, and `ARC-02` does not appear anywhere in `src/` or `tests/`). I verified three of
the decision's four concrete statements directly against `src/controller/consoleController.lua`
and `src/controller/userInputController.lua`, and none of them hold yet:

- **Statement 2 says `configure` must refuse `text`/`cursor`.** The code still admits them:
  `PER_SHOW_KEYS = { 'prompt', 'text', 'cursor' }` (consoleController.lua:593) is folded into
  both `SHOW_KEYS` and `CONFIGURE_KEYS` (line 609-613), so `check_keys` does not raise on them
  at `configure`.
- **The "hidden configure no longer retains text/cursor" consequence.** `configure`'s hidden
  branch (line 815-825) still calls `stash_hidden_configure(state, next_cfg)` (line 714-720),
  which writes `text`/`cursor` into `state.pending` for the next `show()` to consume — exactly
  the retained-draft behaviour the decision withdraws.
- **Statement 4 says a forced `show{}` with no `text` must clear the field.** `re_show`
  (userInputController.lua:279-292), the path a `force=true` `show()` takes over an
  already-active widget, only touches `self.model:set_text(...)` `if cfg.text ~= nil` — with no
  `text` given it leaves the existing content standing, i.e. it still preserves rather than
  clears.

In-code comments corroborate this independently: the `configure` closure and `PER_SHOW_KEYS`
comments cite `doc/development/internals/user_input.md, "configure(config)"` and "Cursor
manipulation and reset" — the pre-Decision-35 internals doc — not any post-35 contract. So
`internals/user_input.md` and `input_api.md` likely also need the ARC-02 pass, not just the
code; flagging for whoever picks up ARC-02, since it's outside this task's blast radius.

### Unsure — needs a human

None. Both items above were checked against the actual call sites, not just the decision prose,
so I'm not carrying anything on a "probably" basis. I did look at, and rule *out*, a few
tempting-looking candidates:

- **Decision 28's "forced restore of global device state... belongs here when it is built"** —
  reads like an unimplemented decision, but Decision 28's actual ruling (stopping is the
  framework's, the project's `before_exit` hook runs from inside it) is fully implemented
  (`framework_before_exit` in `consoleController.lua`). The force-reset it gestures at is a
  separate, already-tracked item — it's the standing entry "A project that raises leaves global
  device state dirty; no force-reset exists" in `doc/development/technical_debt/input.md` — so
  listing it again here would just duplicate an existing debt entry rather than surface a new
  one.
- **`UserInputController:wheelmoved`/`touchpressed`/`touchreleased`/`touchmoved`** are `--- TODO`
  no-op stubs in `userInputController.lua`. I could not find any decision that obliges the input
  *widget* to do anything with wheel/touch events — Decision 2/25 require it be invoked as the
  chain's terminal, which an empty method satisfies — so I did not list this as an unfulfilled
  decision. It may still be worth a human's attention as a product gap, just not a ledger one.

## 3. Things a human should look at

- **Decision 9's heading doesn't say what its body says.** Heading: "Decision 9 — uniform
  signatures and `isrepeat` threading" — no supersession marker. First line of the body:
  `**SUPERSEDED, 2026-08-07** — see Decision 26. ... the content below is what was decided, not
  what the code does.` That is functionally identical to Decisions 13/16/20/29, which *do* carry
  `SUPERSEDED by ...` in their heading and were moved to RETIRED. Per the task's literal rule
  ("those whose heading already says SUPERSEDED by ...") I left Decision 9 in ACTIVE, since its
  heading makes no such claim — but a reader scanning headings only will misread it as current.
  Candidates: retrofit the heading to say `— SUPERSEDED by Decision 26` (then it belongs in
  RETIRED too), or leave it and accept the inconsistency. I did not reword it either way, per
  rule 1.
- **No anchor-style links exist in the file** (`](#...)` count: 0), so the cross-reference risk
  named in the prompt didn't materialise — nothing needed fixing.
- Everything else read as internally consistent: no heading found that claims a status the body
  contradicts, and no decision-to-decision reference pointed at a number that turned out to be
  missing or mislabelled.

## 4. Before/after count

`grep -c "^## Decision" doc/development/decisions/input.md`: **34 before this edit, 34 after.**
29 decisions now sit under `## ACTIVE`, 5 under `## RETIRED`. Markdown sanity checked: code-fence
count is even (6, three pairs), the one Decision-24 table is intact, no stray blank-line runs
were introduced beyond the two that pre-existed the edit (before Decision 6 and inside the
now-relocated Decision 20 — both confirmed present, byte-identical, in the pre-edit file too).
