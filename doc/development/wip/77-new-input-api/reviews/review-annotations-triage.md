---
description: PM triage of the 31 in-code REVIEW: annotations (owner's own sweep-time
  questions in controller.lua + projectInputController.lua). Each mapped to a disposition —
  answer-in-comment / answer-in-doc / convert-to-tech-debt / escalate — with its target.
  Sign-off artifact; edits land only after the owner approves this table.
status: proposed
audience: owner / PM
---
# Feature #77 — REVIEW-annotation triage

_PM (Claude Opus 4.8), 2026-07-15. The intent-alignment verdict (item 8) flagged the in-code
`REVIEW:` annotations as the owner's own open questions shipped inside the landed code, to sweep
before release. `grep REVIEW: src/` = **31**, all in `src/controller/controller.lua` (24) and
`src/controller/projectInputController.lua` (7). This doc triages every one._

## Disposition legend

- **(a) in-comment** — the concern is a worthwhile explanation that does *not* change behaviour.
  Replace the `REVIEW:` line with a concise rationale comment + a named pointer, e.g.
  `-- see decisions/input.md #10 "legacy natives pure-wrapped"`. Question closed in place.
- **(b) doc** — the answer belongs in a doc (a settled rationale already recorded in
  `decisions/input.md`, or a one-time historical/process answer). Code gets a short pointer comment;
  the substance lives in the doc. Used where the answer is reassurance to a naive concern OR a
  ratified decision.
- **(c) tech-debt** — valid but cosmetic/improvement; no behaviour change now. Add an entry to
  `technical_debt/input.md` and replace the `REVIEW:` with a `-- TODO(debt: <id>)` marker.
- **(esc) escalate** — a genuinely-unresolved design/owner question; surface to the owner, do not
  close. (Result: **none survive as pure escalations** — all trace to a ratified decision or debt;
  three are marked **Fable-verify** so an independent eye confirms the "already-ratified" call
  before I close them.)

Scope rule (owner-approved 2026-07-15): trivial + obviously-correct fixes may land inline (suite
re-run); anything non-trivial becomes a debt entry. Comment pointers name the decision section, not
a bare number.

---

## controller.lua (24)

### Cluster A — the keyboard/pointer channel split (1)

| Line | Verbatim gist | Disp. | Target / answer |
|---|---|---|---|
| 66 | why split events into `_keyboard` vs `_pointer` classes; why pointer routed separately? | **(a)** — Fable **DEFENSIBLE**, citation corrected | Different install paths **and** different lifecycles (keyboard/text released at `running→project_open`; pointer stays hooked). The #77 lockout only ever existed on keyboard/text; pointer was out of scope. Cite Decision **11** (which forbids unifying the lifecycles) + the scope point. **Fable: drop Decision 5 — its "two directions" is events-in vs results-out, not keyboard-vs-pointer; the "bubble up/down" framing is not ratified.** |

### Cluster B — `occupy_keyboard` / route asymmetry / naming (L186–258)

| Line | Verbatim gist | Disp. | Target / answer |
|---|---|---|---|
| 191 | why a function treating PIC specifically — contradicts swappable-routes assumption? | **(b)** | Decision 1 (consequence): editor is still reached via the console route's fork; full three-sibling symmetry is a deliberate follow-on. `occupy_keyboard` = the project-route connection of Decision 11. In-comment + cite Decisions 1 & 11. |
| 192 | no concept of "occupying" in original design | **(a)** | "occupy" is now ratified vocabulary — Decision 11 uses it verbatim ("the project route **occupies** the keyboard/text slots"). Point the comment there. |
| 193 | what is `userlove`/`project_natives`; why `occupy` activates? strongest semantic confusion | **(a)** + **(c)** | In-comment: `userlove` = the project's sandboxed `love` table; `occupy` = take the keyboard/text slots for the run (Decision 11). Log a debt: **rename `userlove`** → clearer name (`project_love`). "occupy" stays (ratified). |
| 198 | why WRAP functions instead of assigning? looks redundant | **(a)** | Not redundant: the wrap binds `pic` as method receiver — `love.keypressed = pic.keypressed` would drop `self`. Factual in-comment. |
| 208 | when/why is `_keyboard_route` used? | **(a)** | It records which controller currently owns the keyboard slots (restore + inspect handoff). One-line in-comment. |
| 248 | why was this section refactored — functional rebuild or cosmetic? | **(b)** | Historical: structural extraction of `set_handlers` into `occupy_keyboard`/`hook_pointer`/`hook_update`/`hook_draw` (readability of code being touched). One-time answer in this doc; drop from code. |
| 249 | sure this section was covered by tests BEFORE refactoring? | **(b)** | Reassurance: the M4-0 characterization net + `tests/input/` contract suite were built **tests-first** precisely to pin routing before the M5c sweep. Cite `tests.md` / the `#input` suite. Drop from code. |
| 250 | WHAT IS USERLOVE? need better name | **(a)** + **(c)** | Dedup with 193 — clarify in-comment; rename → same debt entry. |

### Cluster C — debug-hotkey if-nav + `forward_*` wrappers (L399–459)

| Line | Verbatim gist | Disp. | Target / answer |
|---|---|---|---|
| 400 | these if-blocks are future 'combos'; worth refactoring/marking | **(c)** | Debt: console debug hotkeys are ad-hoc `if`-nav; candidates to migrate onto the combo-table mechanism (Decision 8). |
| 401 | if-navigation smelly → `toggle_debug_handlers(k)` / table-driven map | **(c)** | Same debt entry as 400. |
| 402 | why refactor now? (self-answered: readability of touched code) | — | Moot — the block was **not** refactored; superseded by the 400/401 debt entry. Drop. |
| 427 | if-nav → should be `forward_keypressed() or CC:keypressed()`? | **(a)** | The two-statement form is deliberate: the console handler is the **terminal love-boundary**; its return is intentionally not propagated (LÖVE ignores handler returns). In-comment. |
| 428 | `forward_keypressed` strange name — forward WHERE/WHY, why bool? | **(a)** + **(c)** | In-comment: forwards to the currently-active keyboard route (e.g. editor fork), returns whether it consumed. Naming → debt (rename `forward_*` family). |
| 429 | why suppress return value instead of returning up? | **(a)** | Factual (pairs with 427): love-boundary is terminal, nothing above consumes. In-comment. |
| 441 | same — useless wrapper, silent drop, strange name (keyreleased) | **(a)** + **(c)** | Dedup 427–429 for keyreleased. In-comment ref + naming debt. |
| 442 | why a dedicated function per event vs name-based routing? | **(c)** | Debt (same as 745): the per-event `set_love_*` installers are lexically isomorphic; candidate for table-driven install. Hygiene, not architecture. |
| 443 | why is CC special vs a first-class routing citizen? | **(b)** | Decision 1: console is the **named restore target / default route**; the three routes are not yet fully symmetric. In-comment + cite Decision 1. |
| 456 | same problems (textinput): silent drop, naming, dispatch-by-name | **(a)** + **(c)** | Dedup 441/442. |

### Cluster D — `set_default_handlers` restore path (L739–780)

| Line | Verbatim gist | Disp. | Target / answer |
|---|---|---|---|
| 742 | console/PIC ties beyond inspect-suppression — pets not cattle? | **(a)** | Reassurance: the only tie is restore **ordering** (`deactivate()` before reinstalling the console). Beyond inspect (Decision 12), no special-casing — it's the generic teardown invariant (Decision 11). In-comment. |
| 745 | 10 isomorphic calls → table + iterator; inject TODO (hygiene) | **(c)** | The canonical hygiene debt entry (author explicitly asks for the TODO). 442/456/169 fold in. |
| 776 | this piece is hard to read; a nearby comment would help (no refactor) | **(a)** | Trivial inline fix: add a clarifying comment on the update/draw/quit restore tail. |

### Cluster E — the gateway core (L895–931)

| Line | Verbatim gist | Disp. | Target / answer |
|---|---|---|---|
| 898 | CORE CHANGE lands. BUT why check `love.keypressed` here? general confusion | **(a)** — Fable **DEFENSIBLE** + a debt rider | `love.keypressed` **is** the route slot; this site is `love.handlers.keypressed` one level above, so forwarding = invoke the current occupant. In-comment + Decisions **1 & 11** (Fable: drop Decision 10, weaker anchor). **Fable rider (verified):** `Controller._keyboard_route` is written at both install sites and **read nowhere** — a write-only field, the very ambiguity behind this confusion. → new debt entry + the L208 comment corrected. |
| 927 | why gateway-style not unified symmetric routing? why touch `user_input` directly? | **(esc)** — Fable **SMELL/LOG**; my "bubble-up mirror" rationale was **wrong** | Verified against code: `handlers.mousepressed` broadcasts — delivers to the widget if present (no bounds/consume check, return discarded) **then unconditionally** to the slot occupant; both fire. There is **no** pointer chain mirroring the keyboard's, and **no decision ratifies pointer routing**. Closed in-comment with the honest scope answer (pointer had no lockout → out of #77 scope; widget needs pointer events, no chain to carry them) + **new debt entry escalating the mirror-chain question to the owner**. |

---

## projectInputController.lua (7)

| Line | Verbatim gist | Disp. | Target / answer |
|---|---|---|---|
| 138 | install natives as callback once on load vs check every time | **(c)** | Debt (minor): `_tier3` re-resolves the precedence `ci[chan] or natives[event]` per event; could memoize at `activate`. |
| 142 | default `cb` to noop-and-call unconditionally would be nicer | **(c)** | Same minor debt entry as 138 (tier-3 resolution shape). |
| 148 | sink should not be invoked if consumed earlier | **(a)** | Naive — already correct: `_dispatch` (L170) short-circuits with `return true` at each tier; `_sink` is only reached on full fall-through. In-comment reassurance. |
| 149 | should UIC be a `self.input` instance property? cleaner | **(c)** | Debt: `_sink` reaches the widget via the `love.state.user_input_controller` global rather than an injected `self.input`; candidate for injection. |
| 150 | `if-then` discouraged; UIC should always exist (singleton) — assert/pcall | **(c)** | Same debt entry as 149 (the nil-guard defends a value the singleton convention says is invariant). |
| 169 | `_dispatch` → `return (fw() or ph() or tier3() or sink())` with noop tiers | **(a)** | The staged form guards **nil** per-tier handlers (`fw and fw(...)`, `ph and ph(...)` — combo tables are sparse); collapsing to a single `or` needs every tier guaranteed-callable. In-comment. |
| 189 | proper moment to wrap natives + install as callbacks | **(a)** | Decision 10: natives are read **once here**, seed tier-3 by **precedence** (never copied onto `compy.input`). The doc-comment already states this; drop the REVIEW, keep the comment. |

---

## Rollup

- **(a) in-comment:** 66*, 192, 193, 198, 208, 250, 427, 428, 429, 441, 456, 742, 776, 898*, 927*, 148, 169, 189 — *starred also cite decisions; 66/898/927 are the Fable-verify set.*
- **(b) doc/decision-pointer:** 191, 248, 249, 443 (+ 66/898/927 cite decisions).
- **(c) tech-debt (new entries):** rename `userlove` (193/250); debug-hotkey if-nav → combos (400/401); `forward_*` naming (428/441/456); table-driven per-event installers (442/456/745); tier-3 per-event resolution (138/142); sink widget-access injection + nil-guard (149/150).
- **Drop (moot/superseded):** 402.
- **Escalations surviving as open owner questions:** **one** — the pointer mirror-chain question
  (927), surfaced by the Fable pass. Every other design WHY traces to a ratified decision (1, 11,
  12) or a logged debt item.

## Fable pass — outcome (completed 2026-07-15)

One tight advisory pass on 66/898/927 (verdict: `reviews/review-triage-fable-verdict.md`). It paid
for itself — it caught two things I would have rubber-stamped:

- **66 — DEFENSIBLE, wrong citation.** My Decision 5 + "keyboard bubbles down / pointer bubbles up"
  framing is not ratified and (for pointer) not what the code does. Correct anchor: Decision 11
  (lifecycle asymmetry) + the out-of-scope scope point. Fixed in the comment.
- **898 — DEFENSIBLE, weaker anchor + a real debt rider.** Cite Decisions 1 & 11 (not 10). Fable
  flagged `Controller._keyboard_route` as write-only; **I verified it in code (2 writes, 0 reads)** —
  my first L208 comment ("used by restore + inspect handoff") was FALSE. Corrected; debt logged.
- **927 — SMELL/LOG, not "already ratified."** **Verified in code:** the pointer path is an
  unstructured broadcast, not a mirror chain. Closed with the honest scope answer + a debt entry
  that escalates the mirror-chain question to the owner.

Net: Fable overturned my disposition on 1 of 3 and corrected the supporting citations on the other
2. Exactly the selective, high-value use intended.

## New tech-debt entries to add (draft ids)

1. `input-debug-hotkeys-adhoc` — console Ctrl+Shift/Ctrl+Alt debug toggles are `if`-nav; migrate to combo tables (Decision 8). (400/401)
2. `input-forward-naming` — `forward_keypressed`/`_keyreleased`/`_textinput` + `userlove` names don't convey semantics; rename. (193/250/428/441/456)
3. `input-per-event-installers` — 10 lexically isomorphic `set_love_*` installers; table-driven install + one iterator. (442/456/745)
4. `input-tier3-resolution` — `_tier3` re-resolves precedence per event; memoize at `activate`. (138/142)
5. `input-sink-widget-injection` — `_sink` reads the `love.state.user_input_controller` global + nil-guards it; inject `self.input`, assert the singleton invariant. (149/150)
6. `keyboard-route-write-only` — `Controller._keyboard_route` written twice, read nowhere; make it the queried registry or delete. (Fable rider on 898)
7. `pointer-broadcast` — pointer delivery is an unstructured broadcast, no consume-chain, no bounds check; **carries an open owner ruling** on whether pointer gets a mirrored chain. (Fable escalation on 927)
</content>
</invoke>
