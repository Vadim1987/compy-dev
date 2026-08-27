# session49 report — a cold question closed ARC-01, and the ledgers got a shape

Booted cold to answer **`ARC-01-07`**. Answered it, and the answer grew into a ratified decision, a
planned sprint, and — at the owner's direction — a restructuring of how the project records its own
state. **17 commits, suite green at every one (979 throughout — no test was added or changed),
nothing pushed.**

## What the commissioned question turned out to be

`ARC-01-07` asked why two reconfiguration policies coexist in `apply_config` and whether `prompt` is
on the wrong one. **There is no designed split.** There are two coherent groups and one rule nobody
wrote down:

> **Content resets; everything the project sets persists until it is replaced.**

`prompt` is on the **right** side of it. My first verdict said otherwise, inferred from the field's
absence from the stakeholder ticket, from `PER_SHOW_KEYS`, and from the doc's persistence list. The
owner supplied the premise all three lacked — they ruled `prompt` into FR-1 themselves, against a
real balloons defect — which turns those three facts into evidence that **the intent was never
recorded**, not evidence of a misplacement. The row closed with a written reason and no code, and
`ARC-01` closed with it.

Details: [`validation/reviews/ARC-01-07-reconfiguration-policies.md`](../../../validation/reviews/ARC-01-07-reconfiguration-policies.md)
(§7 supersedes §5–6) · attestation: [`validation/notes/owner-attestation-prompt-field.md`](../../../validation/notes/owner-attestation-prompt-field.md)
· ten probes: [`validation/notes/ARC-01-07-behaviour-probes.md`](../../../validation/notes/ARC-01-07-behaviour-probes.md)

## What followed from it

**Stakeholder intent for `show{force}` is recoverable exactly**, because the stakeholder was
responding to a spec paragraph and that paragraph fixes their sentence. They gated *"reconfigured
in-place with the new config"*; the implementation kept only that sentence's parenthetical, so
`force` applies content and **nothing else** — the complement of what was specified, and the reason
it ends up weaker than `configure`.
[`validation/reviews/force-and-configure-intent-recovery.md`](../../../validation/reviews/force-and-configure-intent-recovery.md)

**Decision 35** ratifies the shape: content is the user's, everything else the project's; `show` is
`configure` plus the content baseline plus activation. It is in the **persistent** ledger, and it
doubles as the deviation record. **`ARC-02`** is the sprint that builds it — planned, cold-reviewed
(*approve with changes*, all folded in), not started.

**`highlighter = false` already works.** The unset `BUG-01-02` was going to design machinery for
exists: every consumer tests truthiness, so a stored `false` takes the same branch as absent. That
row dropped from design-escalation to ratification.

## The ledger trip (owner-directed, mid-session)

Changelog, decisions and debt become three ledgers answering *where are we* at project altitude.
Changelog gained `CURRENT_SCOPE`; decisions split `ACTIVE`/`RETIRED`; debt split
`ACTIVE`/`BACKLOG`/`RETIRED` by release scope. Three Sonnet workers, prompts and reports on disk
under `validation/`. The contract is **[`agents/rules/ledgers.md`](../../../../../agents/rules/ledgers.md)**;
the bookmark page is [`status.md`](../../../status.md).

**All three workers needed correcting, and none of the errors was test-visible** — see the commits
for each. The cross-check the contract prescribes found a real mis-sort on its first run, and then
**came back green for the wrong reason** on its first grep: a loose `T-[A-Z]` matched the convention
being *described* in prose on both sides. Anchored to `^### T-` now, with the trap recorded beside
the command.

## Non-obvious points for the successor

- **`ARC-02` is next and it is execution**, not analysis. The design is settled and ratified; do not
  reopen it. The plan's §4 records both picks as settled and §6 the shape.
- **`ARC-02` was renumbered today.** `BUG-01-10` folded in as `-06`, so the old `-06`/`-07`/`-08` are
  now `-07`/`-08`/`-09`. **The plan document and the cold review use the pre-insert numbers**;
  the crosswalk is on the roadmap sprint.
- **Three traps are already known and written down**: `clear_input()` is not `set_text('')` (it also
  clears the selection, the custom status and the history index); `ARC-02-02` cannot be its own
  commit under suite-green-at-every-commit; and a green suite is not evidence on the project
  dispatch path, because `with_canvas_and_errors` xpcalls the walk.
- **My examples proved less reliable than my rules.** Four claims of mine were overturned this
  session — one by the owner, two by the cold review, one by a Sonnet worker checking an example I
  had asserted in its own prompt. The recurring shape is a conclusion drawn from one instance and
  generalised to its neighbours.
- **`BUG-01` grew from 6 rows to 10**, all found by probing rather than by reading: `-07` balloons'
  shadow label, `-08` the cursor shapes, `-09` `set_text` silently ignoring a multi-line string,
  `-10` the highlighter's two homes.
