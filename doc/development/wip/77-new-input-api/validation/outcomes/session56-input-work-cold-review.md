# Cold review: session56's input-side documentation work against the owner's raw input

Reviewed against the prompt of record
(`validation/prompts/session56-input-work-cold-review.md`), commits `a8e25bf3..HEAD` excluding the
docker/gitignore infra commits. Read `git show 880c45ef` and `git show b6456d61` in full before
anything derived. Did not read `implementation/sessions/session56/track.md` content (viewed only
`--stat`, per the boundary).

## Verdict: SOUND WITH CORRECTIONS

The instruction-fidelity work is faithful: the four owner corrections (3a/3b/3c and the OP-part
sequencing), the OP/FEAT KIND split, the Russian entry's translation, and the "recommended
convention, not enforced" language for `T-PLAINTEXT-ENTERED` all land as the owner asked, with no
invention alongside them. But two claims that made it into ratified, cited documents are wrong when
checked against the actual code, and one cross-reference is stale. None of these require redoing
the judgment calls; they require fixing three passages.

---

## Lost

Nothing the owner said failed to land somewhere. Every explicit ask in the raw commits and the four
chat instructions has a corresponding artifact: `T-ONESHOT`/`T-PLAINTEXT-ENTERED` restyled, Decisions
36/37 written, the namespace note relocated to a convention, the turtle DRY question answered with a
validation note, the maze weighing filed as `BUG-01-11`, the examples-untested backlog entry scoped
exactly as asked (conventions, not end-to-end; no roadmap row), `FEAT-01-05`/`-06` added for the two
documentation asks.

**One small thing did not fully propagate: see "Distorted #3" below** — the *content* of the
Decision 38 correction landed everywhere except one line, which is a propagation miss rather than a
dropped instruction.

## Distorted

**1. Decision 37 / `T-PLAINTEXT-ENTERED` claim "`maze` pays" for the payload split — this is wrong,
verified against the code.**

- `doc/development/decisions/input.md:1531`: *"`repl` loses its `string.unlines`, and **`maze` is
  the one that pays** — `submit_program` genuinely wants lines, so it moves to `after_submit` or
  splits the string itself."*
- `doc/development/technical_debt/input.md:63`: *"**`maze` pays** — `submit_program` genuinely
  wants lines and moves to `after_submit` or splits the string itself."*
- **Code** (`src/examples/maze/core_editor.lua:46-48`):
  ```lua
  function submit_program(lines)
    start_program(string.unlines(lines))
  end
  ```
  `submit_program` is maze's *only* `on_text_entered` consumer (`core_editor.lua:63`). Its **first
  and only** act on `lines` is `string.unlines(lines)` — the exact pattern the same decision credits
  `repl` for having and calls a *beneficiary* of the split (`repl` "loses its `string.unlines`").
  Under the proposed split, `on_text_entered` would hand maze the already-joined string directly,
  and `submit_program` would drop its own `unlines` call — a **simplification**, not a cost. (`maze`
  even round-trips: `start_program` immediately re-splits the string with `string.lines` at
  `core_editor.lua:94` to get `lines` back for validation — confirming the string is what the call
  chain actually wants, not the list.)
- **Effect:** this error appears in two places (the ratified decision and its debt-register
  restyling), inflating the perceived migration cost that `FEAT-01-04` is sized against, and
  misidentifies which example — if any — is actually inconvenienced by the split. On the evidence
  read, **no in-tree consumer is worse off** under the split; three simplify (`turtle`, `valid`,
  `guess`), and both remaining consumers that build the string back up (`repl`, `maze`) lose a call
  rather than gain one.

**2. `T-GUARD-LIVE` / `FIX-02-23` claim a documentation gap that does not exist — the reservation
exemption is already written, in the same file.**

- `doc/development/technical_debt/input.md:80-82`: *"Neither is the exemption written:
  **reservations sit above tier 1 and no project guard can reach them**, so a project that returns
  early from its own handler keeps `ctrl+pause`, `ctrl+s` and the rest working... it is the missing
  half of the advice."* Same claim drives `FIX-02-23` (`ROADMAP.md`), whose whole rationale is this
  gap.
- **Doc, already present, untouched by this session** (`git log a8e25bf3..HEAD -- doc/input_api.md`
  is empty — nothing in the reviewed range touched this file): `doc/input_api.md:420-468`, *"Combos
  the framework keeps"* — a dedicated section with a table row `ctrl+pause | suspends the run |
  development only`, and explicit text: *"the platform does not swallow the key either: **your
  binding still runs**, and the platform's action happens as well"* (`:424`), *"A reserved combo
  never consumes; it acts *and* passes the key on"* (`:428-429`), *"your handler runs, and then the
  project is stopped anyway. **Nothing suppressed you**"* (`:432`). `doc/input_api.md:301-304` states
  the same thing at the top of the dispatch-chain section, before either tier is introduced.
- **Effect:** the entry is right that the *`is_shown` paragraph* and *"Why the widget sits at tier
  3"* (the two locations it cites) don't carry this fact — but a different, dedicated section of the
  very same guide does, comprehensively, with `ctrl+pause` named explicitly. "Neither is the
  exemption written" is the specific claim that is false. `FIX-02-23`'s narrower framing (consolidate
  the advice at the `is_shown` paragraph, point to where the exemption already lives) would be
  accurate; "the missing half of the advice" is not.

**3. `ROADMAP.md:14` still lists a withdrawn decision as one of `OP-01`'s outputs.**

- `ROADMAP.md:14`: *"it produced the decisions (36, 37, 38) that `FEAT-01` now implements"* — this
  line was written by `6218d227` (14:06:59), **before** `96683802` (14:42:13) withdrew Decision 38.
  Every other reference to `OP-01`'s output in the same file was corrected to "Decisions 36 and 37"
  (`:376`, `:413`, `:440`), and `decisions/input.md` no longer has a `## Decision 38` heading at all
  (confirmed: only 35, 36, 37 remain). This one line was missed by the sweep.
- **Effect:** small, mechanical, and cheap to fix — but it is exactly the kind of drift the four
  questions are meant to catch, and it sits in the roadmap's own top-of-file summary, the first
  thing a reader sees.

## Misinterpreted

Nothing rises to a genuine misreading of an instruction. The one candidate, examined and set aside:

- **Decision 38's fate — deleted ("withdrawn"), not retired with a tombstone.** `agents/rules/
  ledgers.md` §2 says retired decisions "keep their number and their full text... a citation that
  resolves to nothing is worse than one that resolves to a tombstone," and vacuuming is allowed only
  for "entries that were not the stakeholder's." Decision 38's *content* derives from the owner's own
  raw entry (`b6456d61`). `96683802`'s commit message argues the rule's rationale doesn't bite here
  (zero citations, same-session, and the *substance* was preserved by relocating it to
  `conventions/architecture_principles.md` — only the "this is a numbered Decision" packaging was
  wrong). That is a defensible reading, stated transparently rather than buried, but it is a
  deviation from the rule's literal text ("keep their number and full text") that the rule itself
  does not carve an exception for. Not scored as a finding on its own — flagging it because the
  owner may want to either bless the exception in `ledgers.md` or restore Decision 38 as a retired
  tombstone.

## Bloated beyond necessity

**One clear case, and it chains from Distorted #2 above.** The `T-GUARD-LIVE`/`FIX-02-23` apparatus —
a debt entry, a roadmap row, and their cross-references — exists specifically to fix a documentation
gap that turns out not to be a gap (the reservation exemption is already written, just not at the
`is_shown` paragraph). That doesn't make the whole chain waste: the *consolidation* case (state it
once, at the paragraph a reader actually hits) still holds. But the entries' own framing — "the
missing half of the advice," "neither is the exemption written" — overstates what's needed, and that
overstatement is what will size `FIX-02-23`'s eventual work larger than it is. **This is not a
sprawling document; it's a mis-sized justification for an otherwise-small row.**

**The BUG-01-03 peer review (`validation/outcomes/BUG-01-03-turtle-fix-peer-review.md`, 351 lines)
reviews a one-line guard.** It earns most of its length: the commissioning prompt
(pre-existing, out of scope) explicitly asked four questions plus a sibling-example sweep plus LSP
tooling checks, and the review answers exactly those, with citations. It is not padded with restated
sections or filler prose — each part does distinct work. What is fair to flag is the **downstream
chain it triggered**: the review's one substantive miss (claiming the guard silently loses the
ability to suspend) required a parent-verification addendum *in the same file*, then a **separate**
42-line validation note (`turtle-pause-duplication.md`) re-deriving the same correction with git
archaeology, plus a debt entry and roadmap row (`T-GUARD-LIVE`/`FIX-02-23`) that — per Distorted #2
— overstate the gap it's nominally fixing. Four artifacts descend from one incorrect claim about one
guard line. Each individual artifact is reasonably sized for what it does; the total apparatus is
heavy for the underlying fact (a duplicate, harmless key binding).

**Checked and found proportionate, not bloated:** Decision 36's length (~50 lines) matches the
existing house style for ratified decisions in the same file (Decisions 35, 37 are comparably
sized), and its structure (Decision / Why / edges / consequence) is the ledger's own template, not
invented for this entry. The corrected "on counting examples — don't" section is a deliberate,
explicit self-correction kept for a future reader's benefit, not the earlier argument smuggled back
in underneath a new headline — it explicitly says the census "measures the wrong thing" and is
subordinate to the two settled facts. The `architecture_principles.md` addition (33 lines) is sized
for what instruction (3c) actually asked for — *"suggested design practice in some dev-facing
doc"* — not for the Russian entry's original tentative "a few lines," which instruction (3c) itself
superseded.

## A moderate, lower-severity note

**The `serial` claims rest entirely on the owner's attestation and are unverifiable in this repo,
but are stated as flat fact rather than hedged.** `grep -rln "compy\.serial"` across `/repo` returns
nothing — no `serial` namespace exists in this codebase. `architecture_principles.md`'s new section
nonetheless states *"the `serial` surface was later built the same way, assignment guard
included"* as established fact, with no "per the owner" qualifier at the point the claim is made
(contrast Decision 36, which explicitly marks the `oneshot` case as resting on "the owner's
device-side attestation, not on the examples"). This is not wrong — the owner said it, in `b6456d61`
— but it is unconfirmable from the code under review and would benefit from the same hedge Decision
36 uses.

**New roadmap KINDs (`OP`, `FEAT`) are not reflected in `agents/rules/roadmap.md` §4's canonical KIND
list**, which still enumerates only `BUG`/`FIX`/`ACC`/`DEC`/`CHG`/`REC`/`MERGE`/`PR`. The owner ruled
both KINDs in during this session, and the roadmap itself documents the ruling, but the rules file
that a future reader would consult for "what does this letter mean" was not updated to match. Minor,
but a real completeness gap given both KINDs are now load-bearing vocabulary.

---

## What was checked and found clean

- **The submit chain**, verified against `src/controller/userInputController.lua:438-448`: both
  `on_text_entered` and `after_submit` currently receive `self.model:get_text()` (`lines`) — exactly
  as Decisions 37 and `T-PLAINTEXT-ENTERED` describe. "Half the fix is already true" is accurate.
- **Dispatch tier order and wording** ("the widget... always consumes"), `doc/input_api.md:306-323`
  — matches every citation of it in the reviewed commits.
- **`ctrl+pause` as a reservation**, `src/controller/controller.lua:812-815` (`reserved_suspend` →
  `CC:suspend_run`) and `:868` (`RESERVED.keypressed['ctrl+pause']`) — exact line numbers cited in
  the peer review's addendum check out precisely.
- **Turtle-pause archaeology**: `suspend_run` traces to 2024-01-23 (`23bc9369`), turtle's bare
  `pause` branch to 2025-01-11 (`a3924173`/`d06a91d1`), `user_break` to 2025-04-15 (`82be3b39`) — all
  confirmed via `git log -S`. The PR-base check (`turtle-pause-duplication.md`) is also exact: at
  `3256aac`, `turtle/main.lua:44-45` and `controller.lua:554` both already exist, pre-dating this
  feature.
- **`compy.input`'s frozen-container / `__index` pattern** (Decision 7's basis): confirmed in
  `src/controller/consoleController.lua:483-488` (`build_frozen_view`) and `:552-573`
  (`build_input_surface`) — `__index` resolves, `__newindex` refuses. Matches the claims in Decision
  38 / the conventions addition for the `compy.input` half (the `serial` half is unverifiable — see
  above).
- **The sandbox deep-clone claim**: `src/util/table.lua:48-61` — `table.clone` is genuinely
  recursive (deep). The referenced doc (`internals/project_sandbox_env.md`) predates this session
  entirely (`55aa0ce8`) and was not touched by it.
- **Decision 36's example census** ("exactly one — `turtle` — closes on submit... `valid`, `repl`,
  `guess` and `balloons` install `after_submit` to `clear()` and stay open"): confirmed by reading
  all five files — `turtle` calls `compy.input.hide()`; the other four call `compy.input.clear()`.
- **`FEAT-01-05`/`-06`** match instruction (3b) closely, including the exact recommendation text
  ("either or both may be used," text-centric vs. generic machinery, "not enforced").
- **The `a`/`b`/`c`/`d` → `OP`/`FEAT` decomposition** (instruction 1, closing paragraph) is followed
  faithfully: `OP-01-02` is exactly "create/amend ratified decisions" (b); `FEAT-01-01`'s
  owner-gated edge ruling is exactly "maybe decide on oneshot design details" (c), correctly left
  unruled by the session per the owner's own hedge.
- **`T-PLAINTEXT-ENTERED`'s "recommended convention, not enforced"** language survives into Decision
  37 verbatim in substance ("a convention, not an enforcement: neither callback is restricted to its
  recommended use") — no enforcement crept in anywhere in the reviewed diff (no code changed in this
  range at all).
- **`T-MAZE-NEUTRALIZE`'s mechanism claims** (`ctrl_pressed = nil` in `maze_main.lua`/`draw_main.lua`
  vs. `core_editor.lua`'s pre-existing `is_shown` guard in `set_prompt`) — confirmed by reading all
  three files.
- **The test-pin citation** `tests/input/input_widget_control_spec.lua:621-637` — exact match, both
  the comment text and the test body.
- **The Russian entry's translation** — checked word-for-word: deep clone, the copy/original
  divergence, "an hour of on-device debugging," the `__index` workaround, the "next person" warning,
  and the tentative "maybe worth a few lines near Decision 7" all land without addition or omission
  across the retired `T-NAMESPACE-CLONE` entry and the conventions section.

---

## Corrections named for the verdict

1. Fix the "maze pays" claim in `decisions/input.md:1531` and `technical_debt/input.md:63` — maze's
   `on_text_entered` simplifies under the split, like `repl`, and should be removed from the list of
   examples the change costs.
2. Soften or retract `T-GUARD-LIVE`'s and `FIX-02-23`'s "neither is the exemption written" framing —
   the reservation exemption is already documented at `doc/input_api.md:420-468`; the real, smaller
   task is consolidating a pointer to it near the `is_shown` paragraph.
3. Fix `ROADMAP.md:14` — "(36, 37, 38)" → "(36, 37)", matching the rest of the file.
4. Optional: hedge the `serial` claims in `architecture_principles.md` and `T-NAMESPACE-CLONE`'s
   retired entry as owner attestation, the way Decision 36 hedges `oneshot`'s.
5. Optional: either restore Decision 38 as a retired tombstone per `agents/rules/ledgers.md` §2's
   literal text, or add the same-session/zero-citation exception it relied on to that rules file.

---

## Addendum — parent verification and dispositions (session56, 2026-08-30)

*Not the reviewer's text. Every finding was re-checked in code before being acted on, per the
charter; the report above is left as delivered.*

**Confirmed and fixed — the two factual errors were real.**

- **"maze pays" was wrong, and the truth is better than the claim.** `core_editor.lua:46-48` —
  `submit_program(lines)` calls `start_program(string.unlines(lines))`, joining as its first
  statement. So do `tixy`'s `submit_body` (`main.lua:177-178`), `balloons`'s `deliver`
  (`terminal.lua:14-16`) and `repl`. The remaining three take `lines[1]`. **Not one in-tree consumer
  wants the list** — four of them perform Decision 37 by hand at the call site. Decision 37 and
  `T-PLAINTEXT-ENTERED` now say that, which strengthens the split instead of costing it a migration
  I invented.
- **The reservation exemption is documented, and I missed the section.** `doc/input_api.md`,
  *"Combos the framework keeps"* — a reservation is *"answered before your project's route exists"*,
  cannot be overridden, and the table names `ctrl+pause`. `T-GUARD-LIVE` and `FIX-02-23` are narrowed
  to the gap that survives: the consequence for a **shown widget**, and the whole-handler guard as the
  named remedy. The corrected entry carries the correction visibly rather than quietly.
- **The stale `36, 37, 38`** in the sequence note is fixed — the one reference the withdrawal missed.
- **`serial`** is attested, not checkable: `grep -rnw serial src/` finds only *serialisation*. Both
  citations now say so, matching the treatment `oneshot`'s grounds already had.

**Disputed, and left standing: Decision 38's removal is not a deviation.**
`agents/rules/ledgers.md` §2 rules the vacuum explicitly and sets two conditions — the entry must
not have been the stakeholder's, and citations must still resolve. Both hold, and not marginally:
the entry was **this session's own**, written and withdrawn the same day at the owner's direction,
and **nothing anywhere ever cited it** (`grep -rn "Decision 38"` outside the session track is
empty). §2 also says in terms that *"the absence of a written vacuum process does not block the
sweep."* A tombstone here would preserve a number no reader has ever followed, and the freed number
goes to the next decision.

**Bloat charge — accepted in part, and worth separating.** Of the four artifacts descending from one
guard line, three were commissioned rather than chosen: the peer review was the predecessor
session's standing prompt, its addendum was the charter's verify-before-acting rule, and the
`turtle-pause-duplication.md` note answered a question the owner asked directly. The one that was
mine to size — `T-GUARD-LIVE` — was mis-sized on a gap that half-existed, which is the reviewer's
point precisely. It is now shorter and narrower. **The lesson kept:** a debt entry claiming the docs
*never* say something is a claim to check against the whole document, not against the section the
work happened to be standing in.
