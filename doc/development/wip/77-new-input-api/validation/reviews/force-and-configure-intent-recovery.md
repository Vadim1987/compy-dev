# `show`, `show{force}`, `configure` — recovering stakeholder intent, and the shape it recommends

**Session49, 2026-08-27. Research + analysis, commissioned by the owner** after the ARC-01-07
finding: *"we will not override the stakeholder ruling, but we can recommend a better shape **and**
remove as much accidental complexity as possible without violating their instruction."*

Companion to [`ARC-01-07-reconfiguration-policies.md`](ARC-01-07-reconfiguration-policies.md) and the
ruling in [`../notes/owner-attestation-prompt-field.md`](../notes/owner-attestation-prompt-field.md).
**A finding. The calls are the owner's.**

---

## 1. What the stakeholder said, and what they were looking at

Their instruction is one sentence, but it was a response to a specific spec paragraph, and the
paragraph is what fixes its meaning.

**The text they reviewed** (`design/spec.versions/version01.md:174-186` — the pre-E29 spec, kept
expressly as the round-2 record):

> Calling `show()` while the singleton is already visible is a **no-op by default** … To deliberately
> re-activate over an active session, pass `force = true`: **the singleton is then reconfigured
> in-place with the new config** (content replaced if `text` is provided, preserved otherwise), still
> with no cancel chain.
>
> To change `prompt`, `validator`, or `highlighter` on a *running* session without re-activating, use
> `configure()` — that is the live-update path and needs no flag.

**What they said** (`design/notes/input/stakeholder2_structured.md` §1.2 and §3):

> *"Block it: the second (new) call does nothing by default. Offer a flag for 'I know what I'm doing
> — override the existing one.'"*
>
> *"The spec says: 'Calling `show()` while already active reconfigures in-place.' … the stakeholder
> would gate this behind a 'force' flag."*

**So the recovered intent is exact.** The thing being gated is *in-place reconfiguration with the new
config*. `force` is permission to **re-set-up the edit area over a live session**. First call =
setup. Subsequent call = refused. Subsequent call with `force` = setup again, in full.

Nothing in the record suggests `force` was meant to be *narrower* than the default path. "Override
the existing one" is the widest reading available, not the narrowest.

## 2. What was built instead

`re_show` (`src/controller/userInputController.lua:279-292`) applies **`text` and nothing else**.
`prompt` and `cursor` are dropped. The **`highlighter`** is written by `merge_callback_keys` and then
ignored by `re_show`, landing at the **next** activation.

*(Corrected 2026-08-27 by the cold review, re-probed: `validator`, `on_text_entered` and
`on_limit_reached` do **not** defer — `merge_callback_keys` writes them into the widget's own
`callbacks` table, which is where `apply_config` would put them, so they take effect at once. Only
the `highlighter`, stored on `model.evaluator`, is left behind. Three behaviours across the call's
keys, not four keys deferred.)*

Set the three layers side by side:

| layer | what `force` does |
|---|---|
| stakeholder | re-set-up the edit area — *"override the existing one"* |
| spec (reviewed **and** current, `design/spec.md:148-151`) | reconfigures in-place with the new config; **content** replaced only if `text` is given |
| implementation | replaces **content** if `text` is given; **everything else** ignored or deferred |

The implementation kept the spec's *parenthetical* and dropped its *main clause* — it is not a
weakened version of the flag the stakeholder asked for, it is the complement of it. The spec
narrows content; the code narrows everything **but** content.

That inversion is the source of every oddity on this path: `force` ends up **weaker than
`configure`** (one field versus five), which inverts what "I know what I'm doing" leads a reader to
expect, and it is why `BUG-01-06` and its highlighter-deferral sibling exist at all.

## 3. Did the stakeholder assume `show` would be enough, with no separate configuration channel?

**No — and the record settles it.** `configure()` was already in the spec they reviewed
(`version01.md:200-211`), in the same section as `show`, and that spec **told them in as many words**
that live changes go through `configure` and need no flag (quoted in §1 above). They read that
section closely enough to quote a sentence from it and to object to the `keys_pressed` proxy two
paragraphs away. They constrained `show`; they did not object to `configure`.

So a separate configuration channel is **stakeholder-seen and unobjected**, in the very round where
they tightened the other channel. It is not stakeholder-*asked* — nothing they wrote requires two
entry points — but combined with the owner's later ruling that mid-run label change is a real
requirement (the balloons defect), `configure()` is about as earned as a design-invented surface
gets. The honest summary: **the need is ratified, the two-entry-point shape is ours.**

## 4. Would "`configure` owns everything invisible, `show` owns the visible parts" be better?

**No.** Two objections, the first decisive.

**It breaks the use case that created `configure`.** The prompt label is *visible*, so under this
cut `prompt` belongs to `show` — and changing a label mid-run would require `show{force}`, which
under the recovered intent (§1) is a full re-setup that takes the user's in-progress text with it.
Balloons writes to the label as its output channel while the player is typing a command; every
message would wipe the half-typed command. The split fails its own founding requirement.

**The line is not crisp in this domain.** The highlighter is literally colouring — visible. The
validator is invisible, but *its errors are displayed in the field*. Sorting these would need a
per-field table with a rationale column, which is the accidental complexity we are trying to delete,
re-introduced under a new name.

**The cut that does work is the one the owner already stated** — it is about **ownership**, not
visibility:

> **Content is the user's. Everything else is the project's.**

- `show` — lifecycle, and it decides the **user's** content baseline (absent `text` = start clean).
- `configure` — changes anything the **project** owns; never touches the user's content.
- `force` — permission to overrule the user: re-set-up over their live session.

Every key's home follows from one question — *does the user own this?* — instead of from two
hand-maintained lists. It is also the only cut under which `force` being the *strongest* verb makes
sense, because the only thing that needs permission is destroying someone else's work.

## 5. Recommended shape — no stakeholder instruction violated

D-2 stands in full: a second `show()` is blocked by default, `force` opts in.

1. **`force` becomes a full re-setup** — `show{force = true, …}` behaves exactly as a fresh
   activation, including `text` absent ⇒ clear. Deletes `re_show`'s bespoke branch; the forced path
   becomes `open_widget`, the same code the first call runs.
   - **Dissolves rather than patches:** `BUG-01-06` (dropped `prompt`), its deferral sibling
     (the **highlighter** applied at the *next* activation), the pending-consumed-by-an-ignoring-`show` edge,
     and `force`'s third content policy (absent ⇒ keep).
   - **Cost:** `show{force = true}` with no `text` would clear where today it keeps. **`force` has
     zero consumers in-tree** — it appears in no example — so the blast radius is tests and docs.
   - This *restores* the reviewed spec rather than departing from it.
2. **`configure` stops silently ignoring `text`/`cursor` on an active session.** Today they are
   accepted and dropped without a word, which the closed-table rule (unknown keys **raise**) makes
   inconsistent: a key that does nothing is as much an authoring error as a key that does not exist.
   Warn on an active session, keep the hidden-session stash (there the fields are legitimately
   seeding the next `show`). One rule, stated: *`text`/`cursor` are for the next `show`, never for
   the session in front of you — use `set_text`/`set_cursor`.*
3. **`prompt` moves to the sticky list** with its comment corrected, and the ownership rule above is
   written once in `doc/input_api.md` — this is `FIX-02-21`, unchanged by anything here.

Net effect: three content policies collapse to **one rule and one deliberate exception**, and three
filed rows dissolve instead of being patched — the `ARC` pattern, at a much smaller scale.

## 6. The shape that falls out — `show` built from `configure` (owner's question, 2026-08-27)

> *"Then `configure` and `show{force}` become identical in behaviour, the only difference being that
> `show` also activates visibility? Does it mean `show()` should simply invoke `.configure()`
> (guarding by the force flag before, and activating visibility after)?"*

**The decomposition is right; the differentiator is not visibility, it is content.** On an
already-active widget, activation is a no-op — so under §5.1 `show{force}` and `configure` differ by
exactly one thing: `show` resets the **user's** content baseline (`text` given ⇒ set, absent ⇒
clear) and `configure` never touches it. That *is* the ownership rule, expressed as code rather than
as prose:

```
show(cfg):
  if shown and not cfg.force then warn; return end   -- D-2, the stakeholder's gate
  reset_content(cfg)                                 -- USER-owned:   given ⇒ set, absent ⇒ clear
  apply_project_config(cfg)                          -- PROJECT-owned: set-if-given (== configure)
  place_cursor(cfg)                                  -- after text, as today
  activate()                                         -- publish handle, shown = true, render

configure(cfg):
  apply_project_config(cfg)
  render
```

**The enabling move is smaller than it looks, and it is the one this row started from.** Take `text`
out of `apply_config`. Today that function carries `prompt`, `text`, `highlighter` and the callbacks,
which is *why* it holds two policies — `text` is the user-owned exception living inside the
project-owned rule, and `open_widget`'s `clear_input` is its other half, sitting one level up. Move
content handling wholly onto the activation path and `apply_config` becomes single-policy: pure
set-if-given over project-owned fields. **It then *is* the configure core**, and `show` composes it
rather than duplicating it.

`reset_content` is the whole exception, in four lines that read as the rule:

```lua
local reset_content = function(self, cfg)
  if cfg.text == nil then self.model:clear_input()
  else self.model:set_text(cfg.text) end
end
```

**Three pieces of machinery then delete themselves** rather than needing rules written about them:

- **`re_show`'s bespoke branch** — the forced path becomes `open_widget`, the same code the first
  call runs. With it go BUG-01-06 and the highlighter-deferral sibling.
- **`UserInputController:configure`'s hand-built `live` table** (`{ prompt = …, highlighter = … }`
  plus the `CONFIG_CALLBACKS` loop) — it exists *only* to keep `text` out of `apply_config`. Once
  `apply_config` cannot see `text`, passing the whole config is safe and the filter is redundant.
- **`prompt`'s slot in `state.pending`** — a hidden `configure{prompt = …}` currently stashes the
  label for the next `show`, but `prompt` is project-owned and sticky, so it can simply be written.
  Only `text`/`cursor` need a pending store at all. That also removes the edge where a `show` that
  ignores a `prompt` still consumes the pending one.

Containment is good: `apply_config`, `re_show` and `open_widget` are file-local to
`src/controller/userInputController.lua` and have no callers outside it (`apply_config`: two, both
in that file). The `compy.input` layer changes only where `pending` shrinks.

**What does not decompose, and is a real call rather than a mechanical one:** hidden
`configure{text = …}`. There is no session to apply content to, so it either stashes for the next
`show` (today's behaviour, documented in `doc/input_api.md`) or it warns and refuses, as `set_text`
already does while hidden. Both are defensible; refusing is the simpler story and deletes the last
of `pending`, but it is a documented behaviour change and belongs with the `FIX-02-22` disposition
rather than being folded in silently. **Settled in §7: keep the stash** — the reviewed spec promised
it, so refusing would contradict stakeholder intent, not just our own machinery.

## 7. Empty values — what they do today, and what the record says they should (owner, 2026-08-27)

> *"Behaviour change against what? Baseline, stakeholder intent, our own machinery emerged within
> this development cycle? The latter is not a concern unless it blasts half of the system."*

**The owner is right, and it retires one of §5's two caveats.** Measured against the three baselines
that matter:

| proposed change | vs PR base `3256aac` | vs stakeholder intent | vs our own machinery |
|---|---|---|---|
| `force` = full re-setup | **no change** — `force` does not exist at base | **restores it** (§1) | changes `re_show`, invented this cycle, **zero consumers in-tree** |
| hidden `configure{text}` refuses instead of stashing | no change — `configure` does not exist at base | **contradicts it** — see below | would delete `pending` |

So `force` is not a behaviour change in any sense that ranks; calling it one was overstating.
**And the same criterion settles the other caveat against the tidier option:** the spec the
stakeholder reviewed says of `configure`, *"Safe to call when hidden (takes effect on next
`show()`)"* (`spec.versions/version01.md:205-208`). The stash is stakeholder-seen, so refusing would
be a change against intent, not merely against our machinery. **Keep the stash;** `pending` shrinks
to `text`/`cursor` (§6) but does not go away.

### What empty values do today — all verified by probe

| value | effect | verdict |
|---|---|---|
| `force = false` | identical to absent | fine — it is the documented default |
| `text = ''` | empty content | **converges with absent**, which is the ideal |
| `prompt = ''` | empty label | fine, and it is `prompt`'s "off" |
| `prompt = false` | **falls back to the evaluator's default label** (`text input`) | a *second*, distinct meaning: "give me the default back" |
| `highlighter = false` | **exactly absent** | see below |
| `validator = false` | **exactly absent** — a rejecting validator is lifted, submit proceeds | as above |
| `on_text_entered = false` | not called, no crash | as above |
| `cursor = {}` / `{1}` / `{nil, 2}` | **raises a raw Lua error** | defect — **`BUG-01-08`** |

**The `false` result is a genuine finding, and it dissolves `BUG-01-02`.** `apply_config` guards on
`~= nil`, so `false` is *stored*; every consumer then guards on **truthiness** —
`if ev.highlighter then` (`userInputModel.lua:384/393`), and the same shape for the validator and the
outputs — so a stored `false` takes **the same branch as absent**. Not an approximation: the same
line of code. So the unset this feature was about to design machinery for **already exists**, is
uniform across every function-valued field, and is idiomatic Lua.

*(This corrects a claim made earlier in this same session — that no user-space value reproduces
absent, so the row needed machinery or nothing. It reasoned about `nil` and missed that the code
tests truthiness. `BUG-01-02`'s roadmap row carries the correction.)*

### What the stakeholder expects of empty values

**Nothing — the record is silent.** Empty and false values appear in no part of the ticket, the
clarification, round 2, or the spec. There is no intent to recover here, so this is an **unruled
area**, and it should be ruled rather than discovered.

Two standing rules point the same way, though, and neither is a stakeholder ask being stretched:

- **Decision 14** — *de-facto contracts: reverse-engineered behaviour is preserved and formalised,
  not silently changed.* `false` meaning "no such thing" is exactly that situation: behaviour that
  already exists, uniformly, and has never been written down.
- **NFR-3** — fit existing Compy and LÖVE conventions. In Lua, `false` for "off" and `nil` for
  "don't touch" is the idiom, and `nil` already means "don't touch" everywhere in this config table.

**The recommendation is therefore to ratify what the code does, not to change it:** document
`false` as the uniform "unset" across `highlighter`, `validator`, `on_text_entered` and
`on_limit_reached`; document `prompt = ''` for an empty label and `prompt = false` for the default
one; and fix `cursor`, which is the only empty value that misbehaves rather than merely being
undocumented.

## 8. The owner's four-part proposal, assessed (2026-08-27)

> **(a)** `show()` calls `configure` with the same arguments (after checking visibility and the force
> flag), then activates visibility. **(b)** `configure` acts on the flags it was passed, never on
> flags it was not; invocable directly, which makes both hidden and lifetime configuration possible.
> **(c)** To unset a flag, the caller passes either a falsey value or a reasonable default (e.g.
> cursor as 1). **(d)** To unset *all* flags, expose a new `reset()` which calls `configure` with
> platform-defined defaults.

**Consistent with stakeholder intent overall, and better than what is there.** Four qualifications,
one of which is a correction and one of which is a scope warning.

### (a) — yes, with one step that must not be dropped

`show` cannot be *only* `configure` + activate, because `configure` leaves unnamed flags alone and
`show` must **reset the user's content**: a fresh `show()` with no `text` starts empty. That is the
owner's own ruling (2026-08-27), it is what turtle depends on in a comment
(`src/examples/turtle/main.lua:63-66`), and it is the one deliberate exception to the ownership rule.
So the layering is:

```
show(cfg):  force gate  ->  reset_content(cfg)  ->  configure(cfg)  ->  cursor  ->  activate
```

Equivalently, `show` may normalise `cfg.text` to `''` before delegating, which keeps (a) literally
true — *"calls configure with the same arguments"* — at the cost of hiding the exception inside a
default. Cosmetic choice; the explicit `reset_content` line reads as the rule and is preferred.

**`cursor` must not be defaulted in that normalisation.** `show{text = 'hello'}` with no cursor lands
the caret at `(1, 6)` — the end of the text, set by `set_text` itself. Defaulting `cursor` to `{1,1}`
would move it to the start, a behaviour change against both today and the base.

### (b) — yes; one field pair is the stated exception, and it should say so out loud

Already true for the project-owned fields. Two adjustments make it uniform:

- **Hidden `configure{prompt = …}` should apply directly, not stash.** `prompt` is project-owned and
  lives on the widget; it needs no session. Only `text`/`cursor` need `pending` at all. (Between
  runs there is no widget and therefore no store — the surface already reads that as "nothing to
  remember", so ARC-01 is unaffected.)
- **`configure{text = …}` on an *active* session should warn, not silently drop.** It cannot apply:
  `configure` never touches the user's content — that is what `set_text`/`set_cursor` are for. The
  reviewed spec already says it has "no effect"; a warning is still no effect, plus a diagnostic,
  and silent no-ops are exactly the accidental complexity being removed here.

The **hidden** `configure{text = …}` stash stays: the reviewed spec promised *"safe to call when
hidden (takes effect on next `show()`)"* (§7).

### (c) — yes for the fields that have an "off"; **no** for `cursor` today, and `text` has no unset

Verified by probe:

| field | unset value | status |
|---|---|---|
| `highlighter`, `validator`, `on_text_entered`, `on_limit_reached` | `false` | **works exactly** — consumers guard on truthiness, so a stored `false` takes the same branch as absent |
| `prompt` | `''` = empty label; `false` = back to the platform default (`text input`) | works, two distinct meanings, both useful |
| `text` | — | **has no unset distinct from empty**: absent already means clear, and `''` converges with it. `text = false` does not raise but is off-contract; do not document it |
| `cursor` | `1`, `{1,1}` | **raises today.** `cursor = 1` and `cursor = false` both die at `userInputController.lua:309` (`attempt to index field 'cursor' (a number value)`), and `{}` / `{1}` die at `:171`. This is **`BUG-01-08`**, which must be fixed before (c) can be stated as a rule |

**One usability wart worth a documented sentence:** with `false` meaning *off* and `nil` meaning
*leave alone*, a project that computes a value which may be `nil` gets "leave alone" when it meant
"off". The idiom to document is `configure{ highlighter = computed or false }`.

### (d) — yes, but the justification the proposal gives is not its strongest, and the frame requires one

**The strongest argument is a symmetry the proposal does not claim.** `clear()` already exists and is
stakeholder-seen; probed, it empties the content and **keeps** the label and highlighter. So:

> `clear()` resets what the **user** owns. `reset()` resets what the **project** owns.

That is the ownership rule with a verb on each side, and it makes `reset()` principled rather than
merely convenient. It also settles what `reset()` must *not* do: it must not clear content — that is
`clear()`'s job, and a `reset()` that did both would make `clear()` redundant and the pair
asymmetric.

**Two cautions.**

1. **The strategic frame applies.** `reset()` is a public moving part nobody asked for, so it needs a
   line in the PR description's justification table. The honest justification is the symmetry above
   plus the multi-field case — **not** defensive cleanup between projects, which `ARC-01` dissolved
   structurally when the widget got a run lifetime. Justifying it by a problem that no longer exists
   is how a surface grows without anyone noticing.
2. **One ambiguity to settle before it is built:** do the *lifecycle* callbacks (`before_submit`,
   `after_submit`, `before_cancel`, `after_cancel`) fall to `reset()`? They are assignable only on
   `compy.input.callbacks`, never through `show`/`configure`, so *"calls `configure` with
   platform-defined defaults"* leaves them standing. That is defensible — `reset()` resets the config
   surface, not every slot — but it must be said, or the name will over-promise.

### Net

(a)+(b) delete machinery and contradict nothing. (c) is already true where it matters and needs
`BUG-01-08` fixed to be true where it is not. (d) is a genuine addition and the only part that
enlarges the public surface — worth doing on the symmetry argument, worth stating in the
justification table, and worth defining precisely enough that "all flags" is not read as "everything".

## 9. Found while doing this — the `hide()` contract says something the code does not do

Not part of the force question; surfaced by the same intent recovery and filed as **`FIX-02-22`**.

Three documents say a hidden widget keeps its content:

- `design/spec.versions/version01.md:191-194` (the round-2 reviewed text) — *"Input content is
  preserved (subsequent `show()` will display it unless `text` is provided)"*;
- `design/spec.md:155` (current, frozen) — *"Content preserved for the next `show()` without
  `text`"*, which contradicts its own §3 five lines earlier (*"Fresh activation with no `text` starts
  empty"*);
- `doc/development/decisions/input.md`, Decision 3 (**persistent** corpus, amended last session) —
  *"keeps 'hide and bring back with state intact' free"*.

**The code clears** (`open_widget`: `if cfg.text == nil then self.model:clear_input() end`),
the suite pins the clearing (`input_widget_control_spec.lua`, *"a fresh activation with no text is
empty"*), and **turtle depends on it** with a comment saying so (`src/examples/turtle/main.lua:63-66`:
*"The field comes up empty next time because `show()` with no `text` clears it"*).

**Disposition: fix the documents, not the code.** The owner ruled the behaviour today — content is
the user's and resets. The stakeholder requirement is *not* violated: FR-3/FR-4 and the sapper
complaint are about not having to tear the widget down, and configuration does survive a hide. What
drifted is the sub-documents overstating "state" into "content". Decision 3's clause needs one
qualifier — it survives *with everything but the draft text* — and it is in the persistent corpus,
so it outlives `wip/77` if left wrong.
