# S44 — W9(a): one verdict per challenged decision

**Owner-gated.** W9(a) challenges five ledger entries against the owner's test:
*if the behaviour is what the platform always did, there was no decision to
record.* Below is one verdict each, with the evidence. **Nothing is edited until
the owner rules.**

**The hard constraint applies to every row: tombstone in place, never renumber.**
179 comments cite decisions by number (69 in `src/`, 110 in `tests/`); deleting a
section renumbers everything above it and silently invalidates an unknown subset
of them. `decisions/input.md` already holds the precedent — Decision 11 was
retired in place, number kept, content marked *SUPERSEDED IN PART*.

The five split three ways, and only one is a clean "not a decision".

## Verdicts

| # | Verdict | Ground |
|---|---|---|
| **6** — submit/cancel are widget-owned flows | **KEEP, compress hard** (~145 lines → ~35) | It **did** change behaviour, so the owner's test keeps it: `before_cancel` may veto, the auto-close default flipped to OFF, and Enter/Escape became shadowable — a named withdrawal of a guarantee. What is bloat is the archaeology: the `oneshot` two-role history, the "later refinement" the widget briefly had, and the per-context walkthrough. Keep the three changes, the withdrawn guarantee and its justification; cut the rest |
| **7** — freeze the container, leaves writable | **KEEP, compress** (~30 → ~12) | Not pre-existing behaviour — the whole `compy.input` surface is this feature's. So it is a decision, and the remark asks for length, not deletion. The cut is the "Why": it narrates the earlier 11-name allowlist, an in-flight shape that never shipped |
| **12** — `inspect` is a mode-to-route line | **TOMBSTONE — not a decision** | The entry's own words: *"it matches the implementation exactly (suspending a project restores all handlers to the console)"*. Confirmed at this branch's base — `consoleController.lua` already drove `app_state == 'inspect'` through the console's handlers there. It documents a de-facto standard, which is the owner's test exactly. The content is worth keeping as *documentation*: point the tombstone at `internals/user_input.md` rather than dropping the explanation |
| **15** — unrecognised config raises | **KEEP; cut the superseded half; fix a stale status line** | A genuine owner ruling that changed behaviour (warn-and-ignore → raise) and is visible in the project-facing contract. Two corrections owed regardless of the prune: its header still says **"Status: in-flight"** though it is implemented and enforced (`check_keys` / `bad_key_message`, `consoleController.lua:594-621`, which cites the decision back); and §"Superseded — the original warn-and-ignore form" is an in-flight form invented and dissolved inside this feature, which the entry's own second remark and W10's no-historical-contrast rule both say to drop |
| **16** — defer future input unification | **TOMBSTONE — inverted, not merely stale** | The strongest case. It says *"do not add click entries to the hooks table and do not route pointer events through keyboard/text dispatching"*. The shipped feature does **both**: `hooks.singleclick` / `hooks.doubleclick` are documented in `doc/input_api.md`, and pointer channels run the same `dispatch` with a shortcuts tier (Decisions 25, 27). An entry describing the opposite of what shipped is worse than a stale one |

## What the two tombstones should say

Following Decision 11's form — heading keeps its number, gains a marker, body
stays readable underneath.

- **Decision 12** → `## Decision 12 — inspect is a mode-to-route line — NOT A DECISION, de-facto behaviour`, with one line: this documents what the platform did before the feature and still does; the description lives in `internals/user_input.md`, and the entry is kept only so the number and its citations resolve.
- **Decision 16** → `## Decision 16 — defer future input unification — SUPERSEDED by Decisions 25 and 27`, with the distinction the owner's own remark draws and nothing else does: **the event axis was unified** (clicks are first-class events, pointer carries a shortcuts tier), while **routing unification across console / editor / project remains deferred** (Decision 1). Anyone reading "unification is deferred" needs to know which half.

## Recommended order, if the answer is yes

1. **16 and 12** (tombstones) — mechanical, no prose judgment, and 16 is the one that actively misinforms.
2. **15** (cut the superseded half, fix the status line) — the status line is a factual defect and can go even if the prune does not.
3. **7**, then **6** (compressions) — prose work, biggest last. Decision 6 also carries the "unconditional and unshadowable" wording the S44 revalidation left alone (§4 there), which is best settled inside this rewrite rather than as a separate edit.

**Estimated effect on the ledger:** ~1556 lines → ~1400, with every decision
number still resolving.

## Executed, 2026-08-25 — owner ruled "go" on all five

Applied in the recommended order. Ledger **1567 → 1500 lines**, every decision
number still resolving, suite untouched at 968 / 0 / 0 / 10.

> **Corrected in session45.** This said *1556 → 1500*. 1556 was measured earlier
> in session44, before `b52e217f` added the F1–F7 resolutions to the same file;
> at `4add9897`'s parent the ledger is 1567 lines, so the prune removed 67.

| # | What landed |
|---|---|
| **16** | Tombstoned in place: heading keeps the number, gains *SUPERSEDED by Decisions 25 and 27*, body states that the entry says the opposite of what shipped and carries the distinction it is kept for — event axis unified, routing across console/editor/project still deferred (Decision 1). **No comment in `src/` or `tests/` cites Decision 16**, so nothing downstream moved |
| **12** | Tombstoned as *NOT A DECISION, de-facto behaviour*, with the base evidence named. Its **seven citations keep resolving**, which is the whole reason for tombstoning rather than deleting; the description is kept and points at `internals/user_input.md` for the narrative |
| **15** | Status corrected — **"in-flight" → "implemented"**, naming `check_keys` / `bad_key_message`, which cite the decision back. §"Superseded — the original warn-and-ignore form" deleted (17 lines): an in-flight shape that never shipped |
| **7** | "Why" compressed to the shape rule and the metatable's placement; the 11-name-allowlist history removed |
| **6** | **81 → 44 lines**, prose roughly halved, the flow diagrams and every claim its ~20 citations rest on kept: both flows, the veto, auto-close OFF, shadowability, `hide()` fires no cancel flow, the one-path-per-instance rule |

**Two defects the compression surfaced, both fixed in passing:**

1. **Decision 6 still contained the `before_submit` claim session36 corrected elsewhere.** Its
   consequence read *"a `before_submit` veto return remains a deliberately reserved extension —
   ignored today"*, while the bullet above it described the veto as live. The veto **is** built:
   `submit_flow` opens with `if run_callback(self, 'before_submit') then return end`
   (`userInputController.lua:406`). Session36 fixed one instance of this claim; this was a second,
   in the same entry, contradicting its own bullet. Removed.
2. **A dangling cross-reference created mid-edit** — the `before_cancel` bullet said "symmetric
   with the `before_submit` veto below" after the paragraph it pointed at was gone. Both vetoes are
   now stated in one bullet.

**Also settled here rather than separately:** the "unconditional and unshadowable" wording flagged
as a watch item in `S44-decisions-33-34-revalidation.md` §4. Decision 6 now says
**non-overridable, not indiscriminate**, naming Decision 33 — and `internals/user_input.md`'s copy
of the same phrase was corrected with it, since the two are read together.

**Marker side-effect:** six `REMARK:`s in the ledger were answered by this work and removed with
it (30 → 24), which is a real reduction in P11's backlog rather than a deferral.
