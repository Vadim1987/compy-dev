---
description: >
  Independent second-opinion on the PM's "close in-comment, cite the
  ratified decision" disposition for REVIEW annotations at
  controller.lua:66, :898 and :927 — rules each DEFENSIBLE or SMELL/LOG.
status: active
audience: owner/PM
---

# Fable verdict — the three "WHY" REVIEW annotations

Scope: `src/controller/controller.lua` lines 66, 898, 927 (+
`src/controller/projectInputController.lua`), checked against
`doc/development/decisions/input.md` and
`doc/development/internals/user_input.md`. Read in full before ruling.

## Item 1 — `controller.lua:66` (`_keyboard` / `_pointer` split)

**Ruling: DEFENSIBLE — but the citation must change.**

The split is real and load-bearing: the two lists drive genuinely
different install paths (`occupy_keyboard` routes keyboard/text through
the ProjectInputController chain; `hook_pointer` pure-wraps pointer
natives straight into `love.*`) and genuinely different lifecycles
(`release_keyboard_route`, controller.lua:730, restores only the three
keyboard/text slots at `running → project_open`; pointer stays hooked).
Decision 11 ratifies exactly this asymmetry and explicitly forbids
"tidying up" by unifying it — that is the correct citation, and the WHY
answer: **the #77 problem (widget lockout, four-tier chain) only ever
existed on keyboard/text; pointer never had the gate and was
deliberately out of scope** (internals doc, FR-6 note: "Mouse never had
this problem... touch/mouse needed no separate #77 scope item").

**Decision 5 is the wrong citation.** Its "two directions, two
surfaces" are *events-in-via-chain* vs *results-out-via-widget-outputs*
— it says nothing about keyboard-vs-pointer. The "keyboard bubbles
down, pointer bubbles up" framing is not ratified anywhere and (see
Item 3) is not what the pointer code actually does. Close in-comment
citing **Decision 11 + the scope point**; drop Decision 5.

## Item 2 — `controller.lua:898` (gateway forwards to `love.keypressed`)

**Ruling: DEFENSIBLE.** Confirmed in code: `love.keypressed` **is** the
route slot. `set_love_keypressed` (line 435) installs the console
route's handler into it; `occupy_keyboard` (line 199) installs the
project route's. The gateway at line 899 is `love.handlers.keypressed`
— the raw event-pump entry one level *above* the slot — so forwarding
to `love.keypressed` after quickswitch/state-change means "invoke
whoever currently occupies the slot." This also mirrors stock LÖVE's
own `love.handlers[name] → love[name]` convention, and the decisions
doc itself speaks in slot vocabulary ("the project route occupies the
keyboard/text slots"; "every slot restores to framework defaults").
Confusing to read, correct in fact — your call stands. Cite **Decision
1 + Decision 11** (Decision 10 is about pure-wrapping natives as
tier-3; it does not speak to the slot mechanism and is a weaker anchor).

**One LOG rider, small but real:** `Controller._keyboard_route` is
assigned at both install sites (lines 209 and 434) and **read nowhere**
— grep finds only the two writes. So the codebase carries two
representations of "active route": the live one (the global slot) and a
dead, write-only field — precisely the ambiguity that confused the
owner. Debt entry: *"`Controller._keyboard_route` is write-only; either
make it the queried route registry or delete it — a field that looks
authoritative but is never read invites exactly the :898 confusion."*

## Item 3 — `controller.lua:927` (pointer path reaches `user_input` directly)

**Ruling: SMELL / LOG — do not close with the proposed rationale; it is
wrong on the facts.**

The pointer path is **not** "the mirror bubble-up chain the owner
intuited." It is an unstructured **broadcast**: `handlers.mousepressed`
(and `-released`, `-moved`, `touch*`) delivers to the widget whenever
one is present — no bounds check, no consume semantics — and then
*unconditionally* forwards to the slot occupant (the project's native).
Both fire; a shown widget cannot swallow a click aimed at it, and a
project's click handler fires even for clicks inside the widget. The
internals doc states this plainly ("call the overlay conditionally but
call the project's own handler **unconditionally**... both get the
event"). And **no decision ratifies pointer routing** — the decisions
doc touches pointer only in Decision 11's lifecycle clause. Citing
Decision 5 + Decision 2 here would tell the owner a symmetric structure
exists when it does not. This is the rubber-stamp you asked me to guard
against.

What *is* defensible: the WHY of touching `user_input` (the widget
needs pointer events for click-to-cursor / drag-selection, and with no
pointer chain to travel, the gateway hands them over directly), and the
scope call (pointer had no lockout, so #77 deliberately left its
delivery as pre-existing behaviour). Close the comment with **that**
honest answer, and log:

> **Debt assertion:** Pointer delivery is an unstructured broadcast,
> not a chain: each gateway pointer handler delivers to the input
> widget (whenever present; no bounds or consume check) and then
> unconditionally to the slot occupant. The keyboard four-tier chain
> has no pointer mirror; a shown widget cannot consume a click, so
> widget-directed clicks also reach the project. Deliberately out of
> #77 scope. **Owner ruling needed:** should pointer get a mirrored
> consume-chain (the ":927 two symmetrically mirrored chains" idea,
> analogous to Decision 1's deferred console/editor convergence), and
> should a shown widget consume pointer events inside its bounds?

## Bottom line

Items 1 and 2 close in-comment as you proposed (fix the citations:
Decision 11 not 5 on item 1; Decision 11 not 10 on item 2; plus a
one-line `_keyboard_route` debt entry) — item 3 must **not** be closed
as "already ratified": pointer routing is unratified legacy broadcast,
so close it with the honest scope answer and a debt entry escalating
the mirror-chain question to the owner.
