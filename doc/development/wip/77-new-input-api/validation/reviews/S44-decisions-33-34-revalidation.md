# S44 — revalidation of Decisions 33 and 34

**Session44, 2026-08-16.** Scope set by `session44/prompt.md`: the *decisions*,
not the code. Every execution step behind them had its own cold review; what no
one outside session43 has checked is the two ledger entries themselves. Worked
against `agents/rules/revalidation.md`.

**Sources:** `doc/development/decisions/input.md` (Decisions 8, 13, 20, 21, 27,
29, 30, 31, 32, 33, 34), `src/controller/controller.lua` at HEAD `8c0c410d`,
`src/controller/projectInputController.lua`, `tests/input/input_global_shortcuts_spec.lua`,
`doc/input_api.md`, `doc/development/internals/user_input.md`,
`doc/development/technical_debt/input.md`, `session43/track.md`, and the commits
`77aed369`, `b20a4c35`, `cb6b867e`, `f31bd312`.

## 1. Intent

Session43 was to record two owner rulings made that day: that a framework
reservation matches its modifier set **exactly** (33), and that the gate's
reservations are **canonical combo strings in a privileged table** (34) — each
as a ledger entry a later reader can act on without the session's context.

## 2. What is clean

**Both rest on rulings that actually happened, with the owner's own reasoning.**
The track records the owner ruling option A ("tighten, all framework cases, with
the reasoning ratified as a decision") and both grounds — a project's richer
combo must not dissolve into a framework one, and least privilege as the
stronger — before any `controller.lua` edit. For 34 the track records the owner
correcting the session's reading of Decision 30 point 3 (*declines to commit*,
not *prohibits*) and supplying the chain the entry now presents as its own
reasoning. Neither entry claims ratification it does not have. The analytical
paragraphs (33's "Cost", 34's "Device reads") are not dressed as rulings.

**Decision 33 says what the code does.** Exactness is real: every reservation is
a canonical combo key, so an unnamed modifier cannot match. A reservation naming
no modifier is claimed only when none is held — `f10` becomes `ctrl+f10` under
Ctrl and misses (`controller.lua:401-409`, `:860`). The gate does run at the raw
pump entry, before any route (`handlers.keypressed`, `:869`). The scope clause
holds as written: `set_love_keypressed`'s console debug hotkeys (`:503`, `:520`)
are still tolerant, and they are route-level, which is exactly what the clause
leaves out.

**Decision 34 says what the code does, and Decision 30's condition on it is
met.** `RESERVED.keypressed` / `.keyreleased`, one named function per
reservation (`:850-867`); the table is structurally separate from a project's
`compy.input.shortcuts`; non-overridability *and* the never-consumes contract
are both stated at the table in code (`:841-849`), and non-consumption is true
in the flow — both handlers call the reservation and forward regardless
(`:876-891`, `:899-905`). Decision 30 point 3 demanded the first of those if the
table were ever built; it is there. "No test needed editing" is confirmed
mechanically: `f31bd312` touches `src/controller/controller.lua` only.

**No conflict with Decisions 21, 27, 30, 31.** 21 (a combo is its modifier set
exactly) is the rule 33 extends to the gate, correctly cited; 31 (three
modifiers) is untouched and is what `COMBO_MODS` implements; 30's device-read
rule is precisely what `combo_string` does, so 34 inherits it rather than
competing with it; 27 is unaffected — the gate has no pointer reservations.

## 3. Findings

Seven, ordered by consequence. F1–F5 are ledger edits and therefore
**owner-gated**; F6 and F7 are corpus work that belongs to P10/P11.

### F1 — Decision 30 point 3 is amended by Decision 34 and carries no in-place note

Decision 34 opens "**Amends Decision 30 point 3**". Point 3 itself
(`decisions/input.md:1276-1282`) still reads: the gate "**could** build its own
table … **That is not committed to** (owner, 2026-08-09) … building one is out of
scope for this feature's PR and **may never be done**."

This breaks the ledger's own convention, and it is the one place it is broken:
Decision 8 carries a blockquote for Decision 31 (`:1358` amender, `:391` note);
Decision 30 point 3 already carries one for Decision 32 (`:1263-1267`);
Decisions 13, 20 and 29 carry supersession in their headings. A reader arriving
at point 3 — which is where the question is asked — is told the table does not
exist. **Recommend** one blockquote at point 3 in the established form, naming
Decision 34 and stating that what is withdrawn is only the *not committed to*.

### F2 — Decision 33's "What this changes" miscounts its own list

`:1481-1485` lists four combos — Ctrl+Shift+Escape, Ctrl+Shift+T, Ctrl+Shift+S,
Ctrl+Alt+Shift+R — then says "the first two become the project's, and **the
third** stops firing `restart` and `reset` in one event". The double-fire is
Ctrl+Alt+Shift+R, the **fourth**; the third (Ctrl+Shift+S) belongs with the ones
that become the project's. The suite states both plainly:
`input_global_shortcuts_spec.lua:211` (ctrl+shift+s no longer stops the run; the
project's binding runs), `:233` (it finishes the edit in the editor — route
level, after `cb6b867e`), `:298-318` (ctrl+alt+shift+r fires neither).

Provenance, so it is not read as a deeper error: the list was three items and
grew to four when session43 fixed an omission it had found itself ("Decision
33's example list omitted Ctrl+Shift+S", track, 2026-08-16). The ordinal was not
re-counted. **Recommend** "the first three become the project's, and the fourth
stops firing `restart` and `reset` in one event."

### F3 — a persistent decision cites `P15`, an ephemeral plan row

`:1474`: "A project cannot take a reserved combo back (the property `P15`
pinned)". `P15` is a row in `validation/reviews/S27-triage-and-plan.md`, inside
the tree whose deletion is owner-gated but expected. After that deletion the
citation resolves to nothing while still reading as authoritative — the exact
rot `agents/validation.md` §"Comment References" forbids for comments, and the
reasoning does not stop at the `src/` boundary.

The claim has a durable referent already: the framework-shortcuts suite, which
is how Decision 34 words the same property (`:1537-1538`). **Recommend** citing
`tests/input/input_global_shortcuts_spec.lua`. The same wip citation appears
once in the debt register ("already noted in the P15 suite") and should go with
it.

### F4 — two illustrative clauses now describe code that was deleted the same day

- `:1458-1460` — "A reservation written as a device poll must therefore exclude
  the modifiers it does not name — `Key.ctrl() and not Key.alt() and not
  Key.shift() and k == 'escape'` — **which is the form `quickswitch` already
  uses for Alt**." True when written (`77aed369^` has `Key.ctrl() and not
  Key.alt() and k == 't'`), and untrue two commits later: `f31bd312` deleted
  `only_mods` and the whole predicate cascade.
- `:1273` — Decision 30 point 3's "the block in `controller.lua` … tests its own
  universal set of key combinations **by direct polling**" is stale for the same
  reason, and would be repaired by F1's note in passing.

Neither is *wrong* as a conditional ("a reservation written as a device poll
must…"), and the rule they state is intact — 34 makes it a property of the
representation, which is the better outcome. But an example pointing at deleted
code is the class W10 batch 2 exists to remove. **Recommend** dropping the
`quickswitch` clause and keeping the form as an illustration of the rule.

### F5 — Decision 34 understates the route's device reads

`:1552`: "The route asks three of its own." True on an exact-combo hit only. On
a miss `find_shortcut` builds the class key with a second `combo_string` call
(`projectInputController.lua:104-114`), so the honest figure is **three or six**
— which session43 established (track: "3 **or 6**… the honest answer is 3 unless
that second build can reuse the first read") and its report carried ("route
unchanged at 3, 6 on a `'*'` fallthrough"). Only the ledger dropped the
qualifier. It does not disturb the paragraph's point — the gate went from ~20 to
3 either way — and the remainder is already named in the debt register.
**Recommend** "three, or six when the exact combo misses and the class key is
built".

### F6 — execution residue in the debt register, not in the ledger

`technical_debt/input.md`, "A modifier accessor answers truthy/falsy, not a
boolean", was updated on 2026-08-16 for harmony's `patch_isDown` and still rests
on `only_mods`, which `f31bd312` deleted hours later:

- **Why it stands** — "the one place that compares normalises with `not not` and
  says why". There is no such place: `grep -rn 'not not' src/controller src/util/key.lua`
  is empty.
- **Shape, if it is answered** — "the `not not` at comparison sites can go".
  Nothing to go.
- **Revisit** — "the first time a **third** comparison site is written" counts
  from two live sites; there are zero.

The entry's substance survives — the six splice sites in `editorController` /
`searchController` are real and unchanged, and they are the reason it stands —
but its stated evidence has been removed underneath it. This is the deviation
rule running in reverse: the behaviour change landed with its own documentation,
and the *neighbouring* document that depended on the deleted code was not
reconciled. **Recommend** rewriting the three bullets around the splice sites,
with the `only_mods` observation kept in the past tense or dropped.

### F7 — Decision 34 has no presence in the corpus outside the ledger (gap)

`grep` over `doc/` (excluding `wip/`) finds Decision 34 only in its own entry.
`internals/user_input.md:199-203` is the doc that explains the gate; it
enumerates the reservations, cites Decision 33 for exactness, and never mentions
the privileged table that Decision 34 calls "the load-bearing part" — nor the
non-consumption contract's other half being the same shape as a project's. Its
anchors also drifted with the rewrite (`controller.lua:889+` for
`handlers.keyreleased`, now `:899`; the enumeration omits the two profiler
reservations and `f10`, which the project guide does list).

Under-done rather than wrong. It is P10/P11 doc territory, recorded here so the
docs rows pick it up rather than rediscovering it.

## 4. Watch item, no action proposed

Decision 6 (`:300-301`) calls the gateway's power keys "unconditional and
unshadowable". Beside Decision 33 "unconditional" now reads as *claims any
modifier set*, which is precisely what stopped being true; in context it means
*not conditioned on the route*, which is still true. Decision 6 is one of W9(a)'s
prune candidates, so the wording may be settled there rather than separately.

## 5. Calibration

Nothing over-done: neither entry is longer than its subject, and both state
their costs. Nothing silently dropped between the ruling and the record — the
track's rulings all appear. The two entries hang together (33 is 34's stated
prerequisite, and that dependency is real: while `ctrl+alt+shift+r` matched two
gates a combo-keyed table had no well-defined entry) and they agree with the
project guide's new §"Combos the framework keeps", which teaches exactness and
non-consumption in the same terms.

**Verdict: sound, with five wording/citation corrections owed to the ledger (F1–F5,
owner-gated) and two corpus items owed to the docs rows (F6, F7).** F1 is the one
that would mislead a reader today.

## 6. Resolution — all seven applied, 2026-08-25

**Owner ruling:** these are inconsistencies with unambiguous resolutions, not
calls to make; resolve them and report. Executed in one commit; no ruling was
needed and none was assumed. Suite unchanged at 968 / 0 / 0 / 10 (docs only).

| # | Resolution |
|---|---|
| **F1** | Blockquote added at Decision 30 point 3, in the file's established amend-in-place form: the table **is built**, only the *not committed to* is withdrawn, the separateness requirement stands as a build instruction `RESERVED` satisfies. It also disposes of F4's second half by stating that the predicate cascade the point describes is gone |
| **F2** | "the first **three** become the project's, and the **fourth** stops firing `restart` and `reset`" |
| **F3** | `P15` → the framework-shortcuts suite by path, in the decision **and** at the debt register's "already noted in the P15 suite". No wip path remains in the persistent corpus |
| **F4** | The `quickswitch` clause dropped; the poll form kept as an illustration of the rule, which is what it was for |
| **F5** | "three of its own, **or six** when the exact combo misses and the class key is built after it" |
| **F6** | The truthy/falsy entry re-grounded on the six splice sites that are live. The comparison form is now stated as observed **once**, in the deleted `only_mods`, with the consequence spelled out — *no site in the tree compares a modifier read today* — and "Why it stands" / "Shape" / "Revisit" re-worded off the vanished `not not` site |
| **F7** | `internals/user_input.md` §gate rewritten: `RESERVED` named as the second privileged table with its Decision 34 citation, the enumeration completed (the profiler pair and bare `f10` were missing), the two stale line anchors replaced by symbol names, exactness restated as a property of the representation, and the per-entry state conditions (playback, profiling build) named |

**One item fixed beyond the seven,** same paragraph class, disclosed rather than
folded in: Decision 33's reason 1 said `examples/maze`'s "restored Shift+Escape
family" was torn down, where only its **two Ctrl-bearing members** ever reached
the reservation (`draw_main.lua:361-368`, `maze_main.lua:217-224` register four:
`shift+escape`, `alt+shift+escape`, `ctrl+shift+escape`, `ctrl+alt+shift+escape`).
Narrowed to the two.

**Not changed, and why:** Decision 6's "unconditional and unshadowable" (§4)
stays as it is — it is true in the sense it means, and Decision 6 is a W9(a)
prune candidate whose wording is settled there or not at all.
