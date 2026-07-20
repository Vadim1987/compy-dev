# Input API — delta design (redesign addendum)

**Status: PROPOSED, pending R3 confirmation.** Addendum to
[`../../decisions/input.md`](../../decisions/input.md) (the 13 ratified decisions,
unedited and still authoritative until this addendum is ratified). Frozen `design/`
untouched — this is a post-implementation refinement, not a rewrite of intent.
Produced by S16 (Fable), synthesising the pressure-test verdict and owner iteration:
[`S16-fable-redesign-pressure-test.md`](../outcomes/S16-fable-redesign-pressure-test.md)
(all code citations verified there; not re-derived here). Written in `decisions/
input.md`'s own voice (Decision / Why / Consequence) so it can be folded in verbatim
once ratified. **Revision note (this pass):** the project's own combo table is
renamed `handlers` → `shortcuts` (owner amendment, below) to stop colliding with
LÖVE's own `love.handlers`.

Scope discipline: this changes **D2, D6, D7, D10** and touches **D5, D8** (D8's
substance is unaffected; only its container's name changes). **D1, D3, D4, D9, D11,
D12, D13 are unaffected** — restated as a checklist at the end so a reviewer can
confirm nothing else moved.

---

## Decision 2 (revised) — a three-component chain with truthy-consume

**Was:** a four-tier chain — framework handlers, project combo handlers, a per-event
generic callback, the sink.

**Now:** three components, same truthy-consume convention, same uniform shape across
`keypressed`/`textinput`/`keyreleased`:

1. `shortcuts[event][combo](...)` — project shortcuts (unchanged from today's
   mechanics, renamed from `handlers`; Decision 8's per-event keying and
   normalisation survive intact).
2. `hooks[event](...)` — project hooks. Absorbs today's tier-3 generic callback
   *and* the legacy native-`love.*` seeding path into one slot (see Decision 10,
   revised, below).
3. the **widget** — terminal, always invoked while the route is active. Its
   *shownness*, not its return value, decides whether it consumed the event:
   shown → the widget runs and the chain reports consumed; hidden → the widget is
   skipped and the chain reports not-consumed (Decision 5, revised, below explains
   why the widget's own return stays chain-meaningless).

**No framework tier.** The old tier-1 (`framework_handlers`, Enter/Escape
non-overridable while shown) is deleted outright — code and tests. It existed
solely to give Enter/Escape special handling *inside the route*; that job is now
done by the widget's own default behaviour (Decision 6, revised) plus the
gateway's **power keys**, which were never part of this chain and are unaffected
(see "What stays the same," below).

**Why.** The four-tier shape special-cased exactly two keys (Enter, Escape) at a
tier that existed for no other purpose — verified in code: `install_tier1`
populated nothing but `keypressed['return']` and `keypressed['escape']`, once, at
construction. Removing it doesn't lose capability; it removes a tier that was
purpose-built for a job the widget can now do itself, uniformly, like any other
chain participant. This is chain-uniformity taken to its conclusion: a project
shortcut can now be registered on Enter/Escape and win, exactly as it can on any
other combo — the DOM-style "handled stops propagation" convention Decision 2
already established now applies without a carve-out.

**Consequence.** The 3-tier `_dispatch` becomes eligible for the uniform
short-circuit shape the codebase's own standing REVIEW note asked for (`return
shortcuts(...) or hooks(...) or widget(...)`), because the widget's participation
now derives from a boolean (shown?) rather than needing a special nil-guard the way
a sparse combo table does. See the delta-spec §2 for a considered — but deferred —
alternative dispatch shape along these exact lines (owner's own further suggestion,
recorded there rather than adopted, per the tradeoff noted).

---

## Decision 5 (touched) — two directions, two surfaces; the limit signal moves fully
## into the output side

**Unaffected in substance:** the chain routes events in; the widget reports results
out through its own outputs; results never travel as chain return values. This
stays exactly as ratified.

**One relocation:** today, `UIC:keypressed`'s return value carries a *second*,
undocumented meaning — a vertical-limit flag — alongside `on_limit_reached` already
firing the same information as a proper widget output. That dual channel is
retired. The return value is freed to carry only the chain-consumption signal
(Decision 2, revised); the limit result travels exclusively through
`on_limit_reached`, which needed no change to its own contract — it already existed
as a widget output under original Decision 5, just underused.

**Why.** The return-value channel was a quiet violation of Decision 5's own rule
("results never travel as chain return values") — verified redundant in code
(`vertical()` sets the flag *and* fires `emit_limit` in the same branch). Retiring
it is a pure simplification: one channel for one kind of information, not two
channels for the same one.

**Consequence.** Console's history navigation (Page-equivalent Up/Down at a
boundary), the one live consumer of the old return-value channel, moves to
configuring its own instance's `on_limit_reached`, filtered to vertical direction.
See the delta-spec for the exact rewiring; no other consumer exists (editor's
search widget reads its own, unrelated return contract and is untouched).

---

## Decision 6 (revised) — submit and cancel are widget-default callback sequences,
## not a framework tier

**Was:** Enter/Escape at a non-overridable framework tier, wrapping call-order hook
chains (`before_submit → validate → deliver → deactivate → after_submit`;
`before_cancel → clear → hide → after_cancel`), with unconditional auto-close on
submit and unconditional dismiss on cancel.

**Now:** Enter/Escape are ordinary chain participants; the widget provides their
*default* behaviour as callback-driven sequences, not framework-owned ones:

```
submit:  before_submit()  →  validate  →  deliver (on_text_entered)  →  after_submit()
cancel:  before_cancel()  →  clear (hardwired)                        →  after_cancel()
```

Three substantive changes from the old shape, each deliberate:

- **`before_cancel` may veto.** A truthy return from `before_cancel` skips the
  clear step entirely — symmetric with the (already-reserved, never-built)
  `before_submit` veto Decision 6 originally set aside. Cheap, and it hands a
  project real control over cancel without a second mechanism.
- **Auto-close default flips to OFF.** `after_submit` and `after_cancel` default
  to no-ops — the widget **stays open** unless a project explicitly hides it.
  This restores the pre-feature convention (`UserInputModel`'s `oneshot=false`
  default — REPL/editor stayed open; verified in the pre-`#77` history), which the
  original implementation deleted and replaced with an unconditional hide baked
  into `UIC:submit()`. A project wanting the old "prompt once, then close"
  behaviour opts in with one line: `after_submit = function() compy.input.hide()
  end`.
- **Enter/Escape are shadowable.** A project shortcut registered on `'return'` or
  `'escape'` now wins over the widget's default, same as any other combo. This is
  a named, deliberate withdrawal of a guarantee — see "Withdrawn guarantee," below.

**Why.** The framework-tier shape existed to solve a problem that no longer exists
in the same form: the pre-feature widget served two incompatible roles (self-owned
submit for the project overlay vs. controller-owned submit for console/editor) with
no shared dispatch layer between them, encoded in a static `oneshot` flag. Once a
uniform chain exists, that problem dissolves without needing a reserved tier — the
"widget owns detection, context owns lifecycle" separation (the thing that actually
fixed the original Escape-can't-dismiss bug) is preserved by making dismissal the
callback's job, not the framework's.

**Withdrawn guarantee — recorded explicitly, not left implicit.** Today, nothing
can prevent Enter from submitting or Escape from dismissing while the widget is
shown. After this change, a project shortcut can shadow both, and a project
overriding `after_submit`/`after_cancel` owns the lifecycle act itself. **This was
never a stakeholder requirement** — `design/requirements.md` records the
cancel/dismiss notification as explicitly left unresolved by stakeholders ("may be
expected — to be confirmed"); the non-overridable shape was a design-team fix
for the `oneshot` two-role problem, not an external mandate. Withdrawing it is
acceptable specifically because it is not the only safety net: the gateway's
**power keys** (Ctrl+Q, Ctrl+Break, etc. — `controller.lua`, pre-dating this
feature) remain unconditional and unshadowable, running before any route dispatch,
chain included. That is the actual, permanent escape hatch; the framework tier was
never it.

**Consequence.** Deactivate-on-submit is no longer even a route-level policy
question (the old Decision 6 consequence text) — it is per-*callback*
configuration, one level more granular, and console/editor inherit "stay open" for
free the day they adopt this shape, rather than needing to fight a hardcoded hide.

---

## Decision 7 (revised) — freeze the container and its sub-table identities;
## leaves are writable

**Was:** an enumerated allowlist of exactly 11 writable field names; everything
else on `compy.input` errors loudly on assignment.

**Now:** `compy.input` itself, and the *identity* of each of its three sub-tables
(`shortcuts`, `hooks`, `callbacks`), are frozen — a project cannot do
`compy.input.shortcuts = {}` or replace the container. Every **leaf** inside those
sub-tables is freely writable: `shortcuts[event][combo] = fn`, `hooks[event] = fn`,
`callbacks[name] = fn`.

`callbacks` carries **eight** members — the original five lifecycle fields
(`on_text_entered`, `before_submit`, `after_submit`, `before_cancel`,
`after_cancel`) plus `on_limit_reached`, `validator`, `highlighter`, unified under
one definition: **a callback is any function the widget itself invokes** (whether
on a lifecycle trigger, at submit-time validation, or at render for highlighting).

**Why.** The old rule required maintaining a hand-enumerated list in sync with the
API surface; the new rule is one sentence and self-enforcing structurally (refuse
all direct-container writes; nothing to enumerate). The guard's *purpose* —
tamper-resistance against a project replacing callable API — is undiminished; it
just moves from a flat allowlist to a shape rule.

**Consequence.** `shortcuts.keypressed`'s normalising behaviour (Decision 8) must
stay reachable only through its combo-keyed leaves, never through wholesale
sub-table replacement — the frozen-identities clause exists specifically to
protect that invariant.

---

## Decision 10 (revised) — one `hooks[event]` table, seeded once at activation

**Was:** an explicit `compy.input.on_*` assignment and a captured native `love.*`
handler compete for one tier-3 slot, re-resolved **on every event** — nil-ing the
explicit assignment resurrects the native.

**Now:** `hooks[event]` is a single table and the single source of truth. At
project activation, any event for which the project has not already set an
explicit hook gets seeded once with its captured native handler (if any); after
that moment, the table **is** the whole story — nil-ing a hook clears it, full
stop, with no fallback resurrection.

**Why.** "One table, one truth" is a strictly more predictable contract than a
precedence rule invisible from the table's own contents — a project (or a debugger)
inspecting `hooks.keypressed` today cannot tell whether a native is silently active
underneath a `nil`. The resurrection-on-nil behaviour was never asked for; it was
an artifact of two separate storage locations being resolved late. This is a
genuine semantic change, not a pure rename, and is recorded as such rather than
assumed to fall out of the table-unification automatically.

**Consequence.** "Read the native once at activation, never re-consult" — the part
of Decision 10 that matters for correctness — is unchanged; only the fallback
mechanics move from per-event resolution to a one-time seed.

---

## Implementation note (non-normative — no project-facing contract change):
## making the mechanism reusable

Two structural extractions are recommended riding this same change, motivated by a
standing gap between the original design's stated intent and what shipped:
`design/roadmap.md` promised a *shared* `dispatch()` reusable by console/editor
"later"; the shipped `_dispatch` is a `ProjectInputController` method reading its
own `self.compy_input`/`self.natives`, not actually reusable. Neither extraction
changes project-facing behaviour — both are pure refactors:

- **Dispatch as a free function.** `dispatch(shortcuts, hooks, widget, event,
  trigger, ...)` over plain tables and a widget reference; `compy.input`'s guarded
  surface becomes a thin project-facing wrapper *over* it, not the mechanism
  itself.
- **The widget-method surface as a factory.** `get_compy_input()`'s methods
  (`show`/`hide`/`configure`/`set_cursor`/`set_text`/`get_cursor`/`clear`) are
  today hardwired to the one global `love.state.user_input_controller`. A
  `build_widget_api(widget)` factory, parameterized by instance, lets any adopter
  (not only the project overlay) get the same ergonomics over its own instance.

Multiple `UserInputController` instances remain required — console's REPL state
must persist independently through `inspect` mode (Decision 12: console route over
a paused project's environment) and would be clobbered by a single shared
instance. What these extractions share is the *wrapper shape*, never the instance.
This resolves a standing in-tree question (`main.lua:360`'s own REVIEW note asking
almost this exact thing) without committing to when — or whether — console/editor
actually migrate. That migration remains deliberately deferred per Decision 1's
original consequence text; this addendum only ensures the seam exists when it's
picked up. Whether to unify this further — one instance-record class holding
`shortcuts`/`hooks`/`callbacks`/methods together, with `dispatch` as a method
rather than a free function — was raised and deliberately left open; see the
delta-spec §4's inline note for the tradeoff (this codebase's stated preference
for functional style, `agents/rules.md:67`, versus the ergonomic appeal of one
cohesive object) rather than resolved here.

---

## Vocabulary (ratified by this addendum — supersedes the postponed jargon cluster)

| retired term | replacement | rule that produced it |
|---|---|---|
| `singleton` | **widget** | one shared instance is an implementation fact, not the name of its role |
| `sink` (tier 4) | **widget** | the terminal chain component *is* the widget; one thing, one name |
| `handlers` (compy.input's own project-combo table) | **`shortcuts`** | **owner amendment:** `handlers` collides with LÖVE's own vocabulary — verified in code, `controller.lua:871`: `local handlers = love.handlers`, a literal local variable bound to LÖVE's real event-dispatch table, sitting in the very same gateway function this redesign discusses. Renaming ours removes the ambiguity outright; the combos are, in effect, project-registered shortcuts (`ctrl+s` etc.), so the new name reads naturally. |
| `on_key_pressed`/`on_text_input`/`on_key_released` (tier-3 field names) | **`hooks[event]`** | one table, symmetric with `shortcuts[event]`, replacing three ad-hoc names |
| `native` (legacy `love.*` seeding) | **hook** (seeded, per Decision 10 revised) | it behaves exactly like a hook once seeded; "native" named the install path, not the role |
| `framework handlers` (old tier 1) | **(retired — no replacement; the tier is gone)** | Decision 2, revised |
| the four `before_*`/`after_*` fields, `on_text_entered`, `on_limit_reached`, `validator`, `highlighter` | **`callbacks[name]`** | "a function the widget itself invokes," one table |
| `proxy` (held-key read-only view) | describe by behaviour: "read-only pressed-keys view" | names the contract, not the mechanism |

**Migration hazard, explicit:** today's code and prose call the submit/cancel
`before_*`/`after_*` fields "hooks" (`run_hook`, Decision 6's own text). Under this
vocabulary they are **callbacks**; "hook" is reserved for the chain-injected tier.
The rename sweep must land completely — a tree where "hook" means both is worse
than either endpoint alone.

`routing` is unchanged and correct as-is.

**A second, adjacent naming collision, resolved:** the gateway's unconditional,
pre-route keys (Ctrl+Q, Ctrl+Break, etc. — already named "Power shortcuts" in an
existing in-code comment, `controller.lua:876`) are called **power keys** in this
addendum's own prose, deliberately avoiding the bare word "shortcuts" for them —
reusing "shortcuts" for both the gateway's unconditional keys and `compy.input`'s
project-registered, fully-overridable table would violate this same taxonomy's own
"reserve each word for one role" principle. The in-code comment is unchanged
(out of scope, low-value to touch); "power keys" is this document's label for
discussing the same concept without the collision.

---

## What stays the same (checklist, for a reviewer to confirm nothing else moved)

- **Decision 1** — route-centric routing. Untouched; reinforced, if anything —
  `routing` now unambiguously means dispatcher selection only.
- **Decision 3** — one boot-provisioned shared widget (the project's). Untouched in
  substance; renamed `singleton` → `widget` per the vocabulary table.
- **Decision 4** — callbacks replace polling. Untouched.
- **Decision 8** — per-event combo tables, canonical serialisation. Untouched in
  substance; its container renamed `handlers` → `shortcuts` (vocabulary table,
  above) to remove the `love.handlers` collision — the per-event keying,
  normalisation-on-assignment, and matcher seam are all unchanged mechanics.
  `hooks[event]` (revised Decision 10) is now symmetric with `shortcuts[event]`.
- **Decision 9** — uniform signatures, `isrepeat` threading. Untouched.
- **Decision 11** — route connects only while running; teardown invariant. Untouched
  in substance. One implementation obligation: teardown must **re-seed** framework
  defaults on `compy.input.callbacks`, not wipe to nil (today's `reset_compy_input`
  wipes; a nil'd `after_cancel` would silently lose dismiss behaviour for the next
  project).
- **Decision 12** — `inspect` is a mode-to-route line. Untouched; it is also *why*
  console/editor can't share the project's widget instance (see the implementation
  note above).
- **Decision 13** — held-key set, read-only. Untouched; `proxy` retired from prose
  only, per the vocabulary table.

**Also unaffected — the gateway.** The gateway's power keys (Ctrl+Q, Ctrl+Break,
Ctrl+S, Ctrl+Shift+R) live in `love.handlers.keypressed` (`controller.lua`), run
unconditionally before any route dispatch, and predate this feature entirely
(verified identical in shape in the pre-feature `devupstream` history). Nothing in
this addendum touches them; they are the permanent recovery path the withdrawn
Decision-6 guarantee (above) leans on.
