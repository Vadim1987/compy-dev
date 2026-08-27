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
`prompt` and `cursor` are dropped; `highlighter`, `validator` and the widget outputs are written to
the sticky store by `merge_callback_keys` and then ignored, landing at the **next** activation.

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
expect, and it is why `BUG-01-06` and its deferral sibling exist at all.

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
     (callbacks applied at the *next* activation), the pending-consumed-by-an-ignoring-`show` edge,
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

## 6. Found while doing this — the `hide()` contract says something the code does not do

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
