# S32 — Decision 30 challenged (Fable, cold check 2, judgement)

**Scope note on method.** Everything below not marked *(unverified)* was checked this
session against the working tree (branch `feature/77-newapi-analysis-s20260615`) and, where
"pre-existing" is claimed, against `3256aac` directly. Grep was the primary tool; the
`lua-lsp` MCP server's `references` was used to confirm `combo_string`'s production call
sites (one call site: `find_shortcut`, `projectInputController.lua:106,108,110`) — grep and
LSP agree, no divergence found. I inherit and rely on, but re-derive rather than merely
trust, the cold-check-1 evidence bundle (`../outcomes/S32-decision30-evidence-bundle.md`).

---

## Verdict, first

**Decision 30 survives the attack.** It rests on three legs, and I could only find code
support for two of them cleanly — the third needs a correction, given below, that narrows
but does not remove it. My first draft of the "sharpest objection" (rule 3 leaves a project
with nothing but a smell, rule 4 as a patch over the hole) was itself wrong and has been
corrected: rule 4 is the *mechanism*, not an escape hatch — a non-consuming flag-shortcut
plus a hook that branches on flags keeps hardware contact confined to exactly one place (the
matcher, rule 2), so there is no forced-poll gap and no asymmetry of the kind I first
described. Tested against the code rather than re-argued from the prompt: the honest residual
is narrower — a project-maintained flag, set on `keypressed` and cleared on `keyreleased`, is
itself a small event-tracked boolean and inherits the *same kind* of drift Decision 30 rejects
at framework scale (no framework focus-loss hook exists for a project to hang a clear on
either), though at a categorically smaller, per-project, per-flag blast radius rather than the
framework set's system-wide one — and the flag mechanism has a genuinely new fragility of its
own the raw tracked set never had, because it piggybacks on the modifier-sensitive combo
matcher rather than tracking a key unconditionally. Both are given in full below (A3). Neither
is severe enough to reverse the ruling; both belong in the PR description.

**What it actually rests on**, in order of strength:

1. **The tracked set was already failing to be self-consistent, independent of this
   decision, and the failure was already documented.** `doc/development/technical_debt/input.md`
   ("The gateway asks the device a question about an event") records, *before* Decision 30
   existed, that the gate's `Key.*` polls and `dispatch`'s event-tracked `combo_string` reads
   were **two clocks answering the same question**, found "by reading, not by failing" — and
   a second entry ("The held-key set is never cleared on focus loss") records a real,
   non-self-healing staleness bug, scheduled for a pre-PR fix (plan phase P9d/P9e). Decision
   30's "a cache that needs the authority to validate it is strictly more machinery than
   asking the authority" is not a hypothetical raised for the first time in the decision —
   it is the generalisation of two defects this project's own paper trail had already found
   and scheduled to patch piecemeal. Choosing the authority over the cache resolves both at
   once instead of patching each. This is the strongest leg and it is code/doc-verified, not
   argued from first principles.

2. **No stakeholder requirement asked for the tracked set, and the combo/dispatch value is
   provably separable from where modifier truth comes from.** Verified in code, not just
   read in the decision's prose: `combo_string`/`any_mod` (`controller.lua:395-418`) take a
   plain table and index it by raw key name — `keys_pressed[m[1]] or keys_pressed[m[2]]` —
   they never call `Key.ctrl()`/`.alt()`/`.shift()`. Their **only** production caller is
   `find_shortcut` (`projectInputController.lua:101-111`, confirmed exhaustively via
   `mcp__lua-lsp__references` on `combo_string`, cross-checked with grep — no other call
   site exists). This means the matcher is source-blind by construction: swapping what table
   `find_shortcut` passes changes nothing inside the matcher. Decision 8/21/26/27 standing
   unchanged is not asserted, it is structurally forced by this shape.

3. **The stakeholder mandate does not require the tracked set either.**
   `design/requirements.md` FR-5/6/7 (§2.3, "Event Notifications") sit inside a document whose
   entire subject is the edit-area/widget replacement (§1, "Context and Purpose" — the
   `input_text`/`input_code`/`validated_input` polling-reference pattern). NFR-2's "rather than
   requiring the project to poll a reference for results" reads, in that context, as "don't
   make a project poll a variable for *submission* results the way the old API did" — not a
   ban on `love.keyboard.isDown`. FR-6 is satisfied by the shortcuts/hooks surface regardless
   of where modifier truth comes from. Nothing in the frozen requirements document asks for a
   project-readable held-key set at all; that capability entered the feature later, from
   Decision 20/21, answering a question the *assistant/owner exchange* raised, not the
   stakeholders.

**The one leg that needed correcting:** Decision 30's own "Consequence — a prerequisite, not
an option" paragraph (claiming `tests/mock.lua`'s single-argument `isDown` **must** become
variadic before the suite can trust modifiers) is not just overstated in its *consequence*, as
cold-check-1 found — it may be aimed at the wrong subsystem. See the dedicated section below;
it changes what ships in Q2, not whether Decision 30 stands.

---

## The attack, item by item

### A1 — "the cache needs the authority to validate it" (core rationale)

**Strength: structural argument, code-corroborated.** Covered above (leg 1). I looked for a
way this could be phantom — i.e., that the gate/dispatch clock mismatch was never actually
reachable — and could not construct one: the gate runs on *every* keypress before dispatch
(confirmed, `controller.lua:787-897`), `dispatch` runs on every routed keypress after it
(`projectInputController.lua:132-142`), and both read modifier state independently. The two
clocks are both live on the same physical keystroke, not on disjoint code paths. This is not
a contrived scenario.

### A2 — the refuted "mock must become variadic" paragraph, and what it actually implies

**Strength: code-verified, and I extend cold-check-1's finding.** Cold-check-1 established
the paragraph's *consequence* is false: no test can currently reach the right-hand branch
through `Key.*`, so making `isDown` variadic changes zero test outcomes today. I went
further and checked what the paragraph would even be a prerequisite *for*, post-dissolution.

Given leg 2 above — `combo_string`/`any_mod` read a **table indexed by raw key name**, never
`Key.ctrl()`'s variadic `isDown(unpack(pair))` form — the natural device-backed
implementation of "the matcher reads the device" (Decision 30 rule 2) is a small proxy table:
`{ __index = function(_, k) return love.keyboard.isDown(k) end }`, handed to `find_shortcut`
in place of `Controller.keys_pressed`. Under `tests/mock.lua`, this resolves through
`mock.lua:30`'s **single-key** `isDown(k)` — which is exactly the granularity `combo_string`
already needs (it looks up `m[1]` and `m[2]` **separately**, not through a paired variadic
call). The mock's single-argument limitation therefore **does not bite the shortcut matcher
at all** under this implementation shape. It only bites direct `Key.ctrl()`/`.alt()`/`.shift()`
call sites (the gate, `error_explorer.lua`, decoration reads) — places Decision 30 rule 3
already calls a smell or exempts for other reasons.

The actual prerequisite for trustworthy combo tests post-dissolution is narrower and cheaper
than what Decision 30 states: `tests/mock.lua`'s `held` table (`:5-15`) **already has**
`rctrl`/`rshift`/`ralt`/`rgui` slots — only `keystroke`'s `mods` token map (`:17-21`, today
`C`/`S`/`M` → left variants only) needs new tokens for the right-hand variants. That is a
few-line addition to a test helper, not a semantic change to a production accessor. **Caveat
for the implementer:** this correction holds only if modifier-reading inside the matcher is
built as a per-key table lookup, as recommended in Q2. If it is instead routed through
`Key.ctrl()`/`.alt()`/`.shift()` for symmetry with the gate, the original variadic-`isDown`
concern reattaches for real — this is a design fork, not a settled fact, and belongs to the
implementer's judgement call, named explicitly in Q2 below.

### A3 — the sharpest objection: does rule 4 actually answer what rule 3 breaks?

**My first framing of this ("rule 4 as a patch over a hole rule 3 opens", "projects left with
nothing else") was corrected mid-session and was substantially wrong. Retested in code rather
than re-argued.** Rule 4 is the mechanism, not an escape hatch: a non-consuming flag-shortcut
plus a hook that branches on the flag keeps hardware contact confined to exactly one place —
the matcher (rule 2) — so there is no gap where a project is forced to poll, and the
"framework may poll, projects may not" asymmetry I first described does not hold as stated.
Two sub-findings from the corrected framing, then the honest residual, all checked in code:

- **Rule 3's "smell" was never an enforced capability gate, either before or after Decision
  30.** I checked whether a project's sandboxed `love` withholds `love.keyboard.isDown` the
  way Decision 20 says it withholds the framework's tracked set ("a project's love is a
  sandboxed deep clone, so it cannot reach the real held set on its own" — note this
  specifically contrasts the *tracked set* against `love.keyboard.isDown`, a stateless engine
  call that clones and works fine). Confirmed in shipped code: `src/examples/paint/main.lua:407`,
  `tixy/main.lua:197`, and `sapper/main.lua:672,690,697,701` already call `Key.shift()` /
  `Key.ctrl()` / `Key.alt()` directly from project code, and the evidence bundle separately
  confirmed `turtle`, `pong`, `maze` poll `love.keyboard.isDown` directly. Nothing structurally
  prevents a project from polling for a judgement, unaffected by Decision 30 either way — rule
  3 calls it a smell, correctly, but never blocked it.

- **Decision 21's own worked example is stale prose, independent of Decision 30, and should
  not be read as describing current capability.** Decision 21 (standing) says a project
  needing multi-key state "uses a hook, which receives the held-key view... and
  `compy.input.keys_pressed` elsewhere." Decision 26 (also standing) already removed the
  held-key argument from every chain call — confirmed in code:
  `dispatch(shortcuts, hooks, widget, event, trigger, ...)`
  (`projectInputController.lua:132`) calls `sc(...)` and `hk(...)` with **only** the varargs
  threaded in from LÖVE's own channel arguments; no keys-table is ever passed. This is a
  documentation-consistency defect in the decisions log (two supersessions compounding onto
  one uncorrected sentence), not a defect in Decision 30's reasoning — but a reader following
  Decision 21 today is misled about current capability regardless of how question 1 resolves.

- **The honest residual, tested rather than assumed.** I built the flag pattern out concretely
  for the case Decision 21 actually motivates — a hook wanting to know "is `a` held" where `a`
  is an ordinary, non-modifier key (so rule 2's device-read carve-out, which is
  modifier-specific, does not apply): `shortcuts.keypressed['a']` sets `a_held = true` and
  returns falsy (non-consuming, so `hooks.keypressed` still runs for that same event);
  `shortcuts.keyreleased['a']` clears it; any hook (e.g. one bound to `space`) reads `a_held`.
  This works, declaratively, with the device touched nowhere in project code. Two real
  properties fall out of building it, though:
  - **The flag is itself a small, project-owned, event-tracked boolean, and inherits drift of
    the same *kind* Decision 30 rejects at framework scale.** `controller.lua:752` marks the
    focus channel `SKIPPED` — there is no framework hook a project could hang a clear on
    either, so a modifier or key released while unfocused leaves a stuck-true project flag for
    exactly the reason the old `keys_pressed` could. The blast radius is real but
    categorically smaller: one project's one flag, not (per the counterweights) every
    unmodified shortcut on every channel system-wide. This is a mitigation, not a refutation —
    the structural critique the ruling makes of the framework's own tracked set applies,
    scaled down, to any project that reinvents the pattern, and the framework's own scheduled,
    centralised fix for it disappears along with the set it was fixing.
  - **A genuinely new fragility, not present in the old `keys_pressed`.** The flag-shortcut
    piggybacks on the combo matcher, which is exact-match-then-class, and is
    modifier-sensitive: `find_shortcut` (`projectInputController.lua:101-111`) looks up
    `combo_string(trigger, keys)` first — for `'a'` that is `'a'` only when *no* modifier is
    incidentally held, `'ctrl+a'` if Ctrl happens to also be down — then falls back to a class
    key (`'ctrl+*'`) only when the trigger is not itself a modifier. A bare `shortcuts.keypressed['a']`
    entry therefore silently fails to fire, and the flag silently fails to update, whenever an
    unrelated modifier happens to be held at the moment of the press or release. Raw
    `keys_pressed['a']` had no such interaction — it tracked the key unconditionally,
    independent of what else was held. This is a real, code-derivable way rule 4's mechanism
    is not a strict drop-in for what it replaces, separate from the drift question.
  - **Modifier-as-trigger flags are moot, not broken.** I checked whether the matcher even
    lets a project track a *modifier's own* held-state via rule 4 (the owner's question about
    whether "modifier-only keyboard triggers can even carry such a shortcut"). It technically
    can (`'ctrl+lctrl'` on press), but press and release do not serialise symmetrically — at
    release-dispatch time the modifier is already not-held, so the combo string is bare
    `'lctrl'`, not `'ctrl+lctrl'` — confirmed this is **pre-existing, not new**:
    `controller.lua:788` writes `Controller.keys_pressed[k]=true` and `:906` writes `nil`,
    both **before** their respective dispatch calls (`:894-896`, `:912-913`), so the identical
    asymmetry existed under the event-tracked design too. It is moot in practice either way,
    because rule 2 already gives modifier truth directly — nobody needs a hand-rolled flag for
    Ctrl/Alt/Shift/Gui.

  **Verdict on A3:** the objection as I first stated it is answered. The residual that
  survives testing is narrower and more precise than my draft: drift moves from framework
  scale to project scale rather than being eliminated, and the flag mechanism trades the old
  surface's "always correct, always available" property for a new modifier-interaction
  fragility. Neither is a hole rule 4 fails to notice — rule 4 is doing exactly what it was
  designed to do — but Decision 30 does not name either consequence, and should.

---

## Checklist judgements

- **Self-inflicted constraints.** Decision 20/21's expansion of `keys_pressed` into a
  globally-readable, argument-independent surface was itself a response to a question the
  assistant/owner exchange raised mid-thread, not a stakeholder ask — Decision 30 says this
  about itself and the self-diagnosis checks out against `design/requirements.md`, which asks
  for none of it. **Judgement: accurately diagnosed, correctly reverted.**

- **Phantom problems.** None found on the "for" side — the core rationale is corroborated by
  two independently-documented, pre-existing tech-debt entries (A1). My own first pass on the
  "against" side (A3 as originally framed — "projects left with nothing else") **was** a
  phantom problem, and testing it in code is what dissolved it: rule 4 closes the gap I
  described. The residual that survives testing (project-scale flag drift, the
  modifier-interaction fragility) is real, smaller, and named honestly above, not manufactured.
  **Judgement: the one phantom problem found in this review was mine, caught by building the
  mechanism out rather than assuming; nothing phantom survives in the final analysis on either
  side.**

- **Unratified terminology.** `compy.input`, `keys_pressed`, and "the gate" as a name are all
  absent from `3256aac` (confirmed: `git grep -c "keys_pressed\|compy.input" 3256aac` returns
  zero). "The gate" is validation-session vocabulary for pre-existing *code*, not an invented
  architecture — the code it names is byte-identical to base. **Judgement: no defect; naming
  a pre-existing thing is not minting a requirement.**

- **Solutions expanding commitment scope.** Rule 4, applied to A3's honest residual case
  (a project tracking one non-modifier key's held-state via a flag), redistributes a small,
  bounded amount of scope **to affected projects**, not the framework — the framework's own
  commitment shrinks (the focus-loss fix, the gateway-gate reconciliation, and the whole
  `held_keys()`/proxy machinery all become unnecessary rather than deferred, per Decision 30's
  own closing paragraph, which I independently confirmed: `held_keys()`'s memoisation
  machinery, `controller.lua:420-443`, has no reason to exist once there is no backing table
  whose identity can change). **Judgement: net commitment scope shrinks; the residual cost
  handed to projects is real but small per-instance (A3), not a large fix disguised as a small
  one.**

- **Deviation from intent / stakeholder mandate.** None found; if anything Decision 30 removes
  a capability the mandate never asked for, which is the opposite of deviation.

- **Deviation from pre-feature functionality.** None found that constitutes a regression in
  the strict sense. The gate (12 combos), `error_explorer.lua`, and the example projects using
  `Key.*` directly are all untouched or migrate to a form (direct polling) they already use
  elsewhere. `examples/keyboard`'s key-cap renderer requires an actual code edit (not
  zero-cost, and the decision's own text says the adoption saving shrinks because of it) but
  ends up doing exactly what `paint`/`tixy`/`sapper`/`turtle`/`pong`/`maze` already do — not a
  capability loss, a style convergence.

---

## Question 2 — implementation recommendations

### Ordering

1. **Land the device-backed modifier source first**, at the one production call site: change
   `find_shortcut` (`projectInputController.lua:103-110`) to build the table it hands
   `combo_string`/`any_mod` from `love.keyboard.isDown` per key name (a static, never-reallocated
   proxy — simpler than the old `held_keys()` scheme, since a poll-backed table has no backing
   identity to track at all). Per A2, this requires **no change** to `combo_string`/`any_mod`
   themselves. **Decide explicitly, in the PR, whether this reads the device via a plain
   `love.keyboard.isDown(key)` table lookup (recommended — matches the matcher's existing
   per-key indexing exactly, sidesteps the whole variadic-mock question) or via
   `Key.ctrl()/.alt()/.shift()` for uniformity with the gate (costs a real, then-load-bearing
   mock fix per A2's caveat).** This is the single highest-leverage decision in the whole
   dissolution and the source of the corrected "prerequisite" in A2 — get it in writing before
   touching tests.
2. **Remove the write side and the dead machinery**: `Controller.keys_pressed[k] = true/nil`
   (`controller.lua:788,906`), the `keys_pressed = { }` field (`:498`), `held_keys()` and its
   proxy caching (`:420-443,501`), and the `compy.input.keys_pressed` sandbox field
   (`consoleController.lua`'s `build_input_surface` `k == 'keys_pressed'` branch, `:539-540`,
   and the `held` upvalue plumbing at `:829-834`).
3. **Migrate `src/examples/keyboard`** (`input.lua`'s `INPUT.__index` `held` branch,
   `keyboard_view.lua:171,178`) to direct device polling — small, contained, and it is part
   of the quoted dissolution-surface count, so leaving it half-migrated would misstate the
   PR's own claimed scope.
4. **Test migration** (below) rides on step 1's decision and should follow it, not precede it.
5. **`src/probe/input_probe.lua`: delete now**, independent of the above ordering — see below.
6. **The gate's own shortcuts table (rule 3): do not do in this PR** — see below.

### The test migration

**Right end state: one source, not two.** Collapse to whichever table `find_shortcut` now
reads (step 1 above) — `tests/mock.lua`'s poll-shaped `held` — because that is what the
shipped code will actually consult. `Controller.keys_pressed`-direct assertions have nothing
left to assert on.

- **`tests/input/keys_pressed_spec.lua`, first `describe`** (`:52-96`, 4 its, testing the
  event-tracked writes themselves) — **delete**. The mechanism under test no longer exists.
- **`tests/input/keys_pressed_spec.lua`, second `describe`** (`:98-138`, 7 its, calling
  `Controller.combo_string`/`cs` against a **synthetic, locally-built table literal**) —
  **keep, unchanged**. These test the matcher, which per A2 is source-blind and does not
  change. This is a good sanity check that Decision 30 is cleanly implementable: the tests
  that matter most for combo correctness need zero edits.
- **`tests/input/input_nfr_mechanism_spec.lua`** — its four "mechanism/NFR guard" its
  (`:66-105`, testing write-ordering into `Controller.keys_pressed` and `held_keys()` proxy
  identity) test properties of the dissolved mechanism — **delete**. The widget-identity and
  teardown-wiring its (`:123-165`) are unrelated — keep.
- **`tests/input/input_events_spec.lua`** — delete the dedicated "the pressed-keys table" /
  `compy.input.keys_pressed` `describe` blocks (`:781-905` region). A handful of other its use
  `input.keys_pressed['lalt']` purely as an incidental oracle for "did the hook already see
  this key before running" (`:557,616,734,857-861`) — these need individual rewrites against
  something that survives (capture the argument the hook itself received, or read the
  device-backed source if the timing question still makes sense post-dissolution; some of
  these test an ordering guarantee — "write happens before dispatch" — that is itself a
  property of the tracked set and simply ceases to be a meaningful assertion, matching
  Decision 30's own "debt that ceases to exist" list).
- **The corrected prerequisite** (per A2): add right-hand modifier tokens to `tests/mock.lua`'s
  `mods` table (`:17-21`) alongside step 1 of ordering, **only if** step 1 chooses the per-key
  device-poll shape. If the implementer instead routes through `Key.*`, then making
  `mock.lua:30`'s `isDown` variadic becomes the real prerequisite, and it is worth doing
  before the migrated combo tests are trusted — but name which fork was taken in the PR, since
  the two forks need different mock fixes and Decision 30's text currently names the wrong one
  for the recommended fork.

### Rule 3's gate table

**Follow-up, not this PR.** The gate's polls are pre-existing, byte-identical to base, and
functionally uncontested — there is no defect forcing a change now. It holds
shutdown/exit/quickswitch, deliberately non-overridable; replacing a hand-checked `if`-chain
with a table is a real but modest cost (12 combos, already fully enumerated in the evidence
bundle) but carries a distinct risk: a shortcuts table invites the reader to assume it is
overridable/introspectable the way `compy_input.shortcuts` is. If built, it must be visibly a
**second, privileged table**, structurally separate from the project's own, with that
non-overridability stated where the table lives — otherwise the win (introspectability)
comes with a new footgun (an apparent, false promise of override). Bundling this into the
dissolution PR would also mix "revert an implementation-time decision" with "add a new piece
of architecture" in one diff, which works against the mandate's own reviewability bar
("reviewable from `doc/input_api.md` + the PR description alone"). Ship dissolution now; open
a tracked follow-up citing Decision 30 rule 3.

### `src/probe/input_probe.lua`

**Delete now.** Its own header is unambiguous: "DIAGNOSTIC, TEMPORARY. Delete when the
polling-vs-tracking question is ruled on." It postdates `3256aac`, is opt-in from the console,
and is not on the dispatch chain. The question is ruled. There is no reason to carry it into
the PR that answers the exact question it exists to measure.

### `error_explorer.lua:418`

**Out of scope.** Pre-existing at `3256aac`, already correctly variadic (unlike the mock), and
structurally outside `compy.input`'s dispatch chain entirely — it is a crash-screen's own
`keypressed` closure, not a project/console/editor route. Rule 2/3 govern the shortcut matcher
and project call sites; this is neither. Recommend naming it explicitly in the PR description
as "pre-existing, out of scope" so a reviewer checking the dissolution-surface count against
`grep -rn love.keyboard.isDown src/` does not mistake it for a missed occurrence.

### What the PR description must say

- **Removal, not deprecation.** `keys_pressed` and the tracked-set mechanism are gone; no
  compatibility shim.
- **Where device polling now lives, and why it is not symmetric with projects**: the shortcut
  matcher (framework-internal) and decoration/rendering reads (project-legal, per the
  owner's decoration-vs-judgement rule) both poll the device legitimately; judgement code at a
  project call site remains discouraged style, not a blocked capability — say this explicitly,
  since A3 shows the capability was never blocked either way.
- **Name the gate and `error_explorer.lua:418` explicitly** as known, pre-existing, unchanged
  exceptions with a stated reason each, so neither reads as an oversight.
- **Retract `doc/input_api.md:372/390`'s "Held keys" section in the same PR** — it currently
  documents a contract (`compy.input.keys_pressed`, "the same way a `love.draw` does") that no
  longer exists. Replace it with: reach for a shortcut first; for what a shortcut cannot
  express, the flag-shortcut pattern (rule 4); for decoration/rendering, poll the device
  directly. This doc is explicitly named in the mandate as what a reviewer judges the PR
  against — leaving it stale would fail that bar on its own terms.
- **State the accepted regression plainly, not silently**: batch-skew is a new, unmeasured,
  accepted risk (was ephemeral staleness before, is now ephemeral batch-skew); the suite loses
  the ability to express the old failure mode as a test; `examples/keyboard` requires an actual
  code migration, not a no-op.
- **Flag the A3 residual, precisely, not as a gap.** Rule 4 is a complete, declarative
  mechanism for "is key X held while key Y fires" (non-modifier X) — say so, so a reviewer
  does not independently rediscover my first, wrong framing and think the API has a hole.
  Then name the two real, smaller consequences honestly: (1) a flag set on `keypressed` and
  cleared on `keyreleased` is itself a small tracked boolean and can go stale on focus loss
  the same way the framework's set could, just per-project and per-flag rather than
  system-wide, since the framework's own focus channel stays unhooked either way; (2) unlike
  raw `keys_pressed[k]`, a flag-shortcut is filtered through the modifier-sensitive combo
  matcher, so it silently fails to update if an unrelated modifier happens to be held at the
  moment of the press/release. Both are real, both are minor, and both are new information a
  reviewer relying only on `doc/input_api.md` + this description would otherwise have no way
  to know.

---

## The strongest argument against my own conclusion

I want to be honest that my first attempt at this section leaned on a stronger, cleaner claim
("projects reimplement the identical bug, the framework disclaims it entirely") that the
owner's correction, and then building the mechanism out myself, cut down to something more
modest. The modest version is still the strongest thing I have against my own verdict, and it
still uses the same mandate I used to support Decision 30: "stakeholders asked for a simpler
and more robust input API," measured at the level of the platform as students actually
experience it, not at the level of `compy`'s own internal line count.

`compy`'s own shipped examples (`paint`, `tixy`, `sapper`, `turtle`, `pong`, `maze`) are
exactly the class of program — student games — where "is this key held while that one fires"
is not an edge case, it is the ordinary shape of interactive-input logic, far more than
edit-area text handling is. Rule 4 genuinely answers this declaratively, with the device
touched nowhere in project code (A3, corrected) — that much is not in dispute. What survives
is smaller: every project that builds this pattern re-derives, unassisted, a version of the
exact focus-loss staleness bug the technical-debt register had already found and scheduled to
fix **once, centrally**, in the framework's own tracked set (`SKIPPED focus`,
`controller.lua:752`, unchanged by Decision 30, and no successor hook offered to a project that
wants to clear its own flag on the same event the framework itself never wires). It is smaller
in blast radius than the original bug, and it is optional — nothing forces a project to build
the pattern in the first place. But "smaller and optional" is not "absent," and a platform
whose stated goal is *simpler and more robust* has, in this one corner, moved a known,
fixable-once bug from a place its own maintainers could patch it for everyone to a place only
each student author can patch it for themselves, and most will not know it needs patching
until it happens to them once, silently, mid-project. That is a real, if narrow, cost the
ruling's rationale does not itself have to weigh, because rule 1's premise — "no stakeholder
requirement asks for it" — is true of the *edit-area* mandate it is judged against, but the
constituency that will feel this (every project author who needs multi-key held-state) is a
real, if non-stakeholder, part of who `compy` serves.
