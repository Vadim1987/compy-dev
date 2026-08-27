# ARC-02 — `show` composes `configure`; the user's content is `show`'s alone

**Session49, 2026-08-27. Plan, owner-settled design.** Predecessor analysis:
[`force-and-configure-intent-recovery.md`](force-and-configure-intent-recovery.md) (§1 intent
recovery, §6 decomposition, §7 empty values, §8 the four-part proposal) and
[`ARC-01-07-reconfiguration-policies.md`](ARC-01-07-reconfiguration-policies.md).
Owner ruling on `prompt`: [`../notes/owner-attestation-prompt-field.md`](../notes/owner-attestation-prompt-field.md).

**Not yet executed.** Two picks are the owner's (§4), and this plan goes to a cold review first.

---

## 1. The design, as settled

> **`configure` runs everything except the user's input, and refuses `text`/`cursor`. `text`/`cursor`
> are `show`'s alone; `show` invokes the text setter, with `text` normalised to empty. Every other
> flag is processed only when non-nil, in both calls.**

Which is the ownership rule with the verbs sorted onto the right side of it:

| | who owns it | who may set it |
|---|---|---|
| `text`, `cursor` | the **user** — they are typing in it | `show` (baseline), `set_text` / `set_cursor` / `clear` (live) |
| `prompt`, `highlighter`, `validator`, `on_text_entered`, `on_limit_reached` | the **project** | `show` and `configure`, set-if-given, sticky until replaced |

```
show(cfg):
  if shown and not cfg.force then warn; return end   -- D-2, unchanged
  reset_content(cfg)                                 -- absent text ⇒ empty
  configure_core(cfg)                                -- set-if-given, project-owned
  if cfg.cursor then set_cursor_pos(...) end
  activate()                                         -- publish handle, shown, render

configure(cfg):
  refuse text/cursor                                 -- §4 pick A: warn or raise
  configure_core(cfg)
  render
```

`show{force = true}` therefore becomes a **full re-setup** — the same path a first call takes. That
restores what the stakeholder was shown and gated (§1 of the predecessor), and it is why this is an
`ARC` row: it dissolves defects rather than patching them.

## 2. Two corrections found while planning — the design holds, the implementation of it changes

**(a) "normalise `text` to `''`" must not be implemented as `set_text('')`.** They are not the same
operation. `UserInputModel:clear_input()` (`userInputModel.lua:344-351`) also runs
`clear_selection()`, sets `custom_status = nil` and calls `history:reset_index()`.
`set_text('')` (`:125-140`) does none of those. Routing an absent `text` through `set_text('')` would
leave a stale selection, a stale custom status and an unreset history index on a fresh activation —
all three observable.

So `reset_content` keeps today's two branches, and the normalisation is a **contract** statement
("absent means empty"), not a literal default value:

```lua
local reset_content = function(self, cfg)
  if cfg.text == nil then self.model:clear_input()
  else self.model:set_text(cfg.text) end
end
```

*(A tidier alternative — give `set_text` the full reset semantics and let `show` pass `''` — is
**not** recommended: `set_text` is also the live public call, where clearing the selection and the
history index on every write would be wrong.)*

**(b) `UserInputModel:reset(history)` already exists** (`:354`). If the owner's `reset()` from §8(d)
of the predecessor is built later, it will sit one layer above a model method of the same name and
different meaning. Not blocking — different layer, and `compy.input.reset()` never reaches it — but
worth knowing before the name is chosen.

## 3. What deletes

- **`re_show`** — the forced path becomes the activation path. With it go **`BUG-01-06`** (a forced
  `show` silently drops `prompt`) and its unfiled sibling (a forced `show` *defers* the callbacks to
  the next activation).
- **`UserInputController:configure`'s hand-built `live` table** — it exists only to keep `text` out
  of `apply_config`. Once `apply_config` cannot see `text`, passing the whole config is safe.
- **`text` from `apply_config`** — which is what leaves one policy where the row started with two.
- **`state.pending` entirely, under pick A(ii)** — with `text`/`cursor` refused, nothing is stashed;
  `prompt` is project-owned and can be written directly while hidden. `WIDGET_STORES` loses a member,
  and `consume_pending` / `stash_hidden_configure` go with it. Under A(i) `pending` shrinks to
  `text`/`cursor` instead.

## 4. Two picks for the owner

**Pick A — how `configure` refuses `text`/`cursor`.**

- **(i) Keep them as accepted keys and warn at runtime.** Fits Decision 15's existing scope sentence
  verbatim — *"a call that is a no-op because of the runtime state is not [a violation], and keeps
  warning"*. Smallest change, no ledger amendment. But it keeps two keys on the surface that
  `configure` will never honour, and keeps `pending`.
- **(ii) Remove them from `CONFIGURE_KEYS` so they raise, with a message naming where they belong.**
  *Recommended.* This is exactly the treatment `before_submit` and friends already get
  (`LIFECYCLE_KEYS` → *"assign it on `compy.input.callbacks`, do not pass it here"*), and `text` in
  `configure` is the same category: **a key that belongs to another call**, not a legitimate call at
  an inconvenient moment. It deletes `pending` outright and makes the closed-table rule uniform.
  **Costs:** it amends Decision 15's scope paragraph (owner-gated, and the gate comes first — the
  `ARC-01-03` pattern), and it is a documented behaviour change (below).

**Pick B — the hidden-`configure` stash.** Under A(ii) it goes. That is a change against a
**stakeholder-seen** sentence: the reviewed spec said *"Safe to call when hidden (takes effect on
next `show()`)"* (`design/spec.versions/version01.md:205-208`), and `doc/input_api.md` says *"When
hidden, `configure` retains `prompt`, `text`, and `cursor` for one later `show`."*

**The argument that it is nevertheless not a broken promise:** the sentence stays true for every
field `configure` still accepts — a hidden `configure{prompt = …}` applies straight away and is
visible at the next `show`. It ceases to be true only for two fields that are no longer `configure`'s
business. **No capability is lost** — a project pre-seeding a draft passes it to `show{text = …}`, or
holds it in its own local. What is lost is a convenience that exists because `show` could not be
called yet.

Per the owner's own criterion (2026-08-27) this is the one item in the plan that is a change against
**intent** rather than against machinery invented in this cycle, so it needs a deviation record in
the workspace, not only in a commit message (owner directive, 2026-08-10).

## 5. Steps

Ordered by blast radius, and by the rule that a gate precedes the code it gates.

| id | step | note |
|---|---|---|
| **ARC-02-01** | **the ledger gate** — amend Decision 15's scope paragraph for pick A(ii) | **owner-gated**, and only if A(ii) is chosen. Decision 15 currently lists what *warns* rather than raises: `show` on an active widget without `force`, and `set_text`/`set_cursor`/`clear` while hidden. `text`/`cursor` at `configure` move to the **raise** side, as keys that belong to another call. Amend, do not reinterpret — the `ARC-01-03` pattern |
| **ARC-02-02** | **breaking tests first**, one per claim | `show{force = true, prompt = …}` applies the prompt; `show{force = true, highlighter = …}` applies it **now**, not at the next activation; `show{force = true}` with no `text` **clears**; `configure{text = …}` refuses (warn or raise per pick A); a hidden `configure{prompt = …}` is visible at the next `show`. Each must fail against today's tree, and be seen to fail |
| **ARC-02-03** | `text` leaves `apply_config`; `reset_content` appears on the activation path | the single-policy move (§2a). `apply_config` becomes `configure_core` in name as well as fact |
| **ARC-02-04** | `re_show` deletes; `show` composes | the payoff commit — `BUG-01-06` and its sibling dissolve here |
| **ARC-02-05** | `configure` refuses `text`/`cursor`; `pending` deletes (A(ii)) or shrinks (A(i)) | touches `consoleController`'s key sets, `consume_pending`, `stash_hidden_configure`, `WIDGET_STORES` |
| **ARC-02-06** | **`BUG-01-08` — the cursor shapes** | `{}`, `{1}`, `{nil, 2}`, a scalar and `false` all raise a raw Lua error today. Fix before any "unset by a reasonable default" rule is documented, since that rule is what makes a scalar cursor a thing a project would write |
| **ARC-02-07** | docs + the deviation record | `doc/input_api.md`: the ownership rule in one line, `prompt` added to the persistence list (**this is `FIX-02-21`**, executed here), `false` documented as the uniform unset with the `computed or false` idiom, `configure`'s refusal, and the hidden-`configure` change. `doc/development/internals/user_input.md`: the balloons rationale for a sticky `prompt`, so it outlives `wip/77`. `technical_debt`/decision notes as the picks require |
| **ARC-02-08** | sweep the fixture and specs for the old shape | the `ARC-01-06` lesson: suite-green-at-every-commit means fixture moves land *with* the behaviour, not after it. Expect this to be partly absorbed by `-03`…`-05` |

**Rows this closes or dissolves:** `BUG-01-06` (+ sibling), `BUG-01-08`, `FIX-02-21`, `FIX-02-12`
(the "callbacks cannot be un-set" doc gap — answered by documenting `false`), and it removes
`BUG-01-02` from the design-escalation column, since `highlighter = false` already works and the row
becomes ratification.

## 6. Risks, stated before starting

- **`force` has no consumers in-tree, so tests are the only guard.** Nothing in `src/examples` uses
  it. If `ARC-02-02`'s breaking tests are thin, nothing else will catch a regression.
- **A green suite is not evidence on the project dispatch path** — `with_canvas_and_errors` xpcalls
  the walk. Any assertion about a *raise* under pick A(ii) reaching a project must observe the error
  channel (`love.state.suspend_msg`, `app_state`), not merely pass.
- **`clear_input` vs `set_text` (§2a) is the trap in this plan.** The three extra effects are easy to
  drop while "simplifying", and two of them (custom status, history index) have no test that would
  notice.
- **Scope creep towards `reset()`.** §8(d) of the predecessor is *not* in this plan. It is a public
  addition needing a justification-table line, and it should be decided separately from a sprint
  whose whole value is deletion.
