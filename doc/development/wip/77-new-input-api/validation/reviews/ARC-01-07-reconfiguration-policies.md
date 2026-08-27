# ARC-01-07 — the two reconfiguration policies: provenance, balance, predictability

**Session49, 2026-08-27. Research + analysis. A finding, not a plan — the calls at the end are the
owner's.**

> **AMENDED IN PART, same day** — the owner attested that `prompt` was ruled into FR-1 by them
> against a real balloons defect, and that a label surviving a bare `show()` is *wanted*. §5's
> verdict and §6's options are revised in **§7**, which supersedes them; §§1–4 stand as evidence.
> Attestation: [`../notes/owner-attestation-prompt-field.md`](../notes/owner-attestation-prompt-field.md).

Evidence: [`../notes/ARC-01-07-behaviour-probes.md`](../notes/ARC-01-07-behaviour-probes.md)
(ten probes through the project-facing `compy.input` surface, plus the PR-base check).

The question as the owner reframed it (2026-08-27) is behavioural, not internal: the stakeholder
asked for *some* distinction between what `show` and `configure` may set; prompt configuration was
never part of that ask and was bolted onto the mechanism. **Was the initial requirement balanced,
what motivated it, and is the result predictable?**

---

## 1. What the stakeholder actually asked for

**On this axis, exactly one thing, and it is not a per-field rule.**

The original ticket (`design/notes/input.md`) asks for "calls … for setting up an edit area (with an
optional initial text, cursor position, highlighter and verifier) and for removing the edit area, for
querying and changing the cursor's position, and changing the text." Round 2
(`design/notes/input/stakeholder2_structured.md` §1 item 2, §3) adds the one distinction that exists:

> *"Block it: the second (new) call does nothing by default. Offer a flag for 'I know what I'm doing
> — override the existing one.'"*

That became **D-2**. Its axis is **call state** — is a session already active — not **which field**.
The stakeholder ruled on *whether a second setup call may act at all*, and said nothing about some
fields being settable one way and some another.

**Two things in today's surface have no stakeholder origin:**

- **`configure()` itself.** It does not appear in the ticket, in the clarification, or in round 2,
  and the symbol does not exist at the PR base. It was introduced by the design as a consequence of
  making the widget persistent — `design/notes/decisions-record.md:107-114`, addressing NFR-1
  (no per-session allocation): *"Projects call `show`, `hide`, and `configure` on it rather than
  creating it. … makes dynamic prompt changes (such as updating a label mid-run) straightforward."*
- **`prompt` as a configuration field.** The ticket lists initial text, cursor position, highlighter,
  verifier — **no label**. "Prompt label" enters at `design/requirements.md` FR-1, during
  normalization. Its real origin is the pre-existing signature `input_text(prompt, init)`: the label
  was already argument 1 of the legacy call, so it was carried across as a field without being asked
  for.

Note the collision: the field the stakeholder never mentioned is the **motivating example** the
design cites for the surface the stakeholder never asked for. That is the bolt-on, precisely located.

## 2. What was built: two coherent groups, and one field in neither

The code names two groups (`src/controller/consoleController.lua:574-593`):

- **PER-SHOW** — `prompt`, `text`, `cursor`. *"Spent by the show() that reads them."*
- **STICKY** — `on_text_entered`, `on_limit_reached`, `validator`, `highlighter`. One `state` entry
  each, *"kept across shows until overwritten"*, and reachable by a second route
  (`compy.input.callbacks`), which is why absent-means-leave-alone is **required** there: a bare
  `show{}` must not wipe a slot the project assigned directly. `doc/input_api.md`, "Callback
  assignments", documents exactly these four as persisting.

Both groups are defensible on their own terms, and `text` in particular is right: absent means
*clear* on a fresh show, which matches pre-feature `input_text(prompt, nil)` and serves NFR-1's
"reconfigure the existing instance" without carrying the last session's draft into the next.

**`prompt` is declared in the first group and implemented in the second.** `apply_config`
(`src/controller/userInputController.lua:254-270`) writes `model.custom_label` only when
`cfg.prompt ~= nil`, and nothing ever clears it — so the field the surface calls "per-show" is in
fact sticky for the widget's whole life. Probe 1: `show{prompt='first:', text='hello'}` → `hide()` →
`show{}` leaves **the label standing and the text gone**.

So there is no designed two-policy split with a rationale behind it. There is one coherent split
(data vs. behaviour slots) and one field on the wrong side of it. The two policies "coexisting in
`apply_config`" are the symptom; the misfiling of `prompt` is the cause.

**Against pre-feature behaviour**, this is a real change: at the base, `prompt` and `text` were the
two arguments of a single call and behaved identically — per invocation, absent meaning none. The
feature kept that for `text` and silently changed it for `prompt`.

## 3. Was the requirement balanced?

The stakeholder's own requirement (D-2) is balanced and well-motivated: it protects a live editing
session from being clobbered, and provides a named escape hatch. It was asked for concretely, twice.

The per-field distinction that exists today was **not required by anyone**. It is a design artefact,
and it grew in the gap between two things the stakeholder did ask for: a persistent widget (NFR-1)
and per-call setup parameters (FR-1). A persistent object needs a rule for "what does absent mean",
and the feature answered it **per field, implicitly, at three different sites** — `open_widget`'s
clear-on-no-text, `apply_config`'s set-if-given, and `consoleController`'s sticky/pending stores —
instead of once, explicitly.

## 4. Is the result predictable? Six observable surprises

Each is reproducible from the probes and reachable by an ordinary project.

1. **`show{}` keeps the old label but drops the old text** (probe 1). One call, two opposite answers
   to "what happens to what I didn't mention". This is the cross-project leak's mechanism, now
   confined to a run — but *within* a run it is unchanged and undocumented.
2. **`doc/input_api.md` contradicts the code.** "Callback assignments" enumerates what persists —
   `on_text_entered`, `on_limit_reached`, `validator`, `highlighter` — and `prompt` is deliberately
   not in that list. It persists anyway. A reader following the doc will expect a bare `show{}` to
   present an unlabelled field.
3. **`force` silently defers the highlighter instead of applying or refusing it** (probes 2, 6).
   *(Corrected 2026-08-27: this said "three keys". The cold review checked and only the
   `highlighter` defers — `validator` / `on_text_entered` / `on_limit_reached` land immediately,
   because `merge_callback_keys` writes into the widget's own `callbacks` table. Re-probed and
   confirmed. The defect is one key, not four; the shape of the complaint is unchanged.)*
   `show{force=true, highlighter=hl2}` on an active widget does not change the highlighter — and
   then changes it at the *next* activation, because the sticky store was written on the way past.
   The documented promise is "replace `text` instead of warning"; that a *closed* config table
   (unknown keys raise, `doc/input_api.md`) accepts a known key it will honour later and never says
   so is the least predictable behaviour in this surface.
4. **`text` has three policies inside one function** (probes 1, 3, 4): absent → clear (fresh show),
   absent → keep (forced re-show), present → ignored (`configure` while active).
5. **Nothing set-if-given can be unset** (probes 9, 10). `configure{highlighter=nil}` cannot remove a
   highlighter, because under set-if-given `nil` is indistinguishable from absent. This is
   **`BUG-01-02`** — and `prompt` has the same defect: a label cannot be removed, only replaced. The
   only escape is `prompt = ''` (probe 7), which works, is asymmetric with every other field, and is
   undocumented.
6. **A stashed prompt can be spent by a call that ignores it.** `consume_pending` clears the pending
   store on every `show`, including a forced re-show whose `prompt` `re_show` then drops (probes 2,
   5). Narrow, but it is a value the project supplied that vanishes without a warning.

Surprises 1, 3 and 5 fail the strategic frame's test directly: they make the system *more elaborate*
without making it more predictable — and a student, per NFR-4, is exactly the reader who will assume
that what they did not pass is not set.

## 5. Answering the two questions

**Is the split intentional?** The *sticky-callbacks* half is, and is documented and justified. The
per-field split as a whole is not: it is the unexamined residue of giving a persistent widget
per-call parameters, and no document states a rule for what absent means.

**Is `prompt` on the right side?** **No.** By provenance (a per-call argument at base), by its own
declaration in the code (`PER_SHOW_KEYS`), by the documentation (absent from the persistence list),
and by what a project author would expect from `show{}` — `prompt` belongs with `text`. It is
implemented with the callbacks. The defect that motivated the row is closed by the run lifetime;
**this inconsistency is not**, and it is visible from the public surface alone.

## 6. What the owner may want to rule on

Ordered by blast radius, smallest first. Each is a ruling, not a plan; 1–2 are cheap and
self-contained, 3–4 touch the public contract and neighbour `BUG-01-02`.

1. **Document the truth as it stands.** Add `prompt` to the persistence list in `doc/input_api.md`
   and state the `force` deferral. No code change; the contradiction goes away, the surprise stays.
2. **Make `prompt` per-show** — clear `custom_label` on a fresh activation that does not supply one,
   as `text` already does. Small, restores pre-feature parity and the code's own declared grouping.
   Breaking for any project relying on a label surviving a `hide`/`show` — the examples need a check.
3. **State the absent-means rule once, in the doc, and make the three sites obey it**: per-show data
   (`prompt`, `text`, `cursor`) resets on activation; behaviour slots persist until replaced.
4. **Give the set-if-given fields an unset** (this is `BUG-01-02`, generalised): a sentinel — e.g.
   `false` — meaning "remove", uniform across `highlighter`, `validator`, the widget outputs and
   `prompt`. Largest surface change; worth deciding **together with `BUG-01-02`** rather than twice.

The one thing I would not recommend is closing the row as "intentional and fine". The sticky-callback
policy is fine and should be written down as such; `prompt` sitting inside it is not, and the reason
it got there is legible enough to be worth one sentence in the PR description's deviation table
either way.

---

## 7. Revision after the owner's attestation (2026-08-27) — supersedes §5 and §6

The attestation ([`../notes/owner-attestation-prompt-field.md`](../notes/owner-attestation-prompt-field.md))
supplies the premise §1 lacked: `prompt` entered FR-1 by **owner ruling**, against a real balloons
defect (no way to change the label mid-run), and the label surviving a bare `show()` is **wanted** —
the label is decoration surface the project owns, where content is user-owned and must reset.

### What changes

- **§5's verdict is withdrawn.** "`prompt` is on the wrong side" was inferred from provenance,
  declared grouping and documentation — all three now read as *evidence that the intent was never
  written down*, not as evidence of a misplacement. On behaviour, which is the only test that
  ranks, `prompt` is on the **right** side.
- **The bolt-on is not the field, it is the unstated policy.** `prompt` is a ruled requirement and
  `configure()`'s live path serves it. What was bolted on without analysis is the *assignment* — the
  field acquired sticky semantics by falling into `apply_config`'s set-if-given branch, and no
  document, and not even the constant it is declared in, says that was the intent.
- **Option 2 (make `prompt` per-show) is declined.** It would break balloons' idiom and contradicts
  the ruling.
- **Option 4 (unset sentinel) is de-scoped from this row.** The owner calls separate machinery for a
  hypothetical case overkill; `prompt` already has `prompt = ''`. `BUG-01-02` should be ruled on the
  highlighter's own merits, without `prompt` widening it.

### What survives unchanged

- **The documentation contradiction (§4.2)** — `doc/input_api.md`'s persistence list omits `prompt`
  while the code persists it. Now strictly a doc defect, and a cheap one.
- **The code's own mislabelling** — `PER_SHOW_KEYS` in `src/controller/consoleController.lua`
  contains `prompt` under the comment *"spent by the show() that reads them"*, which is false for
  `prompt` and true for `text`/`cursor`. A reader is told the opposite of the ruling.
- **The `force` deferral (§4.3)** — `show{force=true, highlighter=X}` on an active widget neither
  applies nor refuses `X`, then applies it at the next activation. (Highlighter only — see §4.3's
  correction.) Independent of `prompt`; the
  attestation does not touch it. Still the least predictable behaviour in this surface.
- **The pending-consumed-by-an-ignoring-`show` edge (§4.6)** — minor, unchanged.

### The rule that can now be stated

The attestation supplies the principle the design never wrote down, and it is teachable in one line:

> **Content resets; everything the project sets persists until it is replaced.** `text` (and the
> `cursor` that positions it) is the user's — a fresh `show()` starts clean. `prompt`, `highlighter`,
> `validator` and the widget-output callbacks are the project's — they survive until the project
> says otherwise.

That is one policy plus one deliberate exception, not two coexisting policies. `apply_config`'s
set-if-given branch is then the **normal** case and `open_widget`'s clear-on-no-text the **stated**
exception — which is already how the code is shaped, and only ever needed saying.

### Revised recommendation — one small unit, one open ruling

1. **Write the rule down and fix the two places that contradict it** (no behaviour change): add
   `prompt` to `doc/input_api.md`'s persistence list, state the content-vs-project-surface rule where
   `show`/`configure` are described, and correct the `PER_SHOW_KEYS` comment (or split `prompt` out of
   that constant, which would make the code say it structurally). Record the owner's balloons
   rationale in `doc/development/internals/user_input.md` so the reason outlives `wip/77`.
2. **Still open, and a separate call: the `force` deferral.** Apply the other keys, refuse them, or
   document the deferral. Not a `prompt` question and not settled by this attestation.
