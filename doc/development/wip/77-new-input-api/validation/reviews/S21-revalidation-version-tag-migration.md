# S21 — revalidation of the S20 version-tag migration

_Session21, 2026-07-29. Commissioned by `sessions/session21/prompt.md` Part 1, worked per
`agents/rules/revalidation.md` (full checklist) plus the owner's in-session widening: **check the
tag calibration outward, not just the transformation's internal consistency.**_

**Subject:** `e254ae7` (bucket→tag migration) + `8a6e95b` (B-I/2 clear-apply), their judgment
record `S20-version-tag-migration-key.md`, and the bookkeeping around them.
**Suite at revalidation:** 841 / 0 / 0 / 4 (unchanged).

**Verdict: substantively sound, correctly executed within the scope it took — but the scope was
never ruled.** Three mechanical corrections (F1–F3), one owner ruling (F4), one adjacent
completeness gap inherited from the same session (F5), two parked nits (F6).

---

## 1. Intent reconstruction

S20 was to close batch **B-I/2** of the marker mop-up; mid-batch the owner expanded it into
replacing the A/B/C/D bucket taxonomy with LÖVE-style **per-version availability** vocabulary,
forked on **behaviour-availability** (new-to-the-feature → `since 1.0.0-rc20260712`; pre-existing →
untagged), thereby resolving RVW-083/084/085/090/094.

## 2. Intent-vs-outcome coherence

**(a) Internal — PASS with F1/F2.** The banners and describes in the two migrated files say what
the key says they should. Two pockets of pre-migration vocabulary survive inside the same file
(F1, F2), one of which is the file head — the first thing a reviewer reads.

**(b) Toward intent — PASS.** The retired taxonomy is genuinely gone as an organising scheme; the
groups are now named by what they assert. The judgment underneath (bucket D = pre-baseline de-facto
behaviour, not "provisional") is right and is the substantive win of the session.

**(c) Toward surrounding context — PARTIAL, see F4.** The convention was adopted as suite-wide
vocabulary but applied only where bucket banners happened to exist. In the two migrated files
"untagged" means *"verified pre-baseline"*; in the other 13 input spec files it means *"nobody
looked"*. Same visual signal, two meanings.

**(d) Updated surroundings — PASS.** `conventions/code.md` and `technical_debt/input.md` are
internally consistent, cross-refer correctly, and cite persistent docs.

## 3. Consistency check

- **Zero `Bucket` refs** in `tests/` and repo-wide outside `wip/` — confirmed (case-sensitive).
- **F1** — lowercase survived: `input_nfr_forward_spec.lua:217` "not this **bucket's** fixtures".
- **F2** — `input_nfr_forward_spec.lua:1` still titles the file *"NFR guards and forward
  contracts"*, and lines 16–19 still summarise it as *"deliberately non-final: **provisional**
  facts about today's implementation (**expected to change**) … and **forward contracts** pending
  the named milestone"*. All three terms are exactly what RVW-083 (drop "forward" jargon) and
  RVW-084 (drop "provisional / expected to change") retired at group level. The head now
  contradicts its own `describe` at line 23 (`NFR and planned changes`) and every banner below it.
  (The filename `input_nfr_forward_spec.lua` likewise still carries "forward" — a rename is
  structural, **B-F territory**, flagged not acted on.)

## 4. Integrity check

- RVW-085 carve-out coherent across test header ↔ `technical_debt/input.md` ↔ inventory. Its
  architecture claims **verified in code**, not taken on trust:
  - `src/controller/controller.lua:21` — `get_user_input()` = `if love.state.app_state ==
    'inspect' then return end` → nil under inspect ✅
  - `src/controller/consoleController.lua:1017` — `ConsoleController:suspend()` sets
    `app_state='inspect'`, `save_user_handlers(runner_env.love)`, then
    `set_default_handlers(self, self.view)` — the physical handler swap ✅
  - env selection under inspect present (`consoleController.lua:865/873/934`) ✅
  - So "changing it reworks the suspend/inspect spine" is a **true** claim, and keeping the
    behaviour as contested status quo is the right call.
- **F3** — the third party to that agreement was **not** updated: the **G-1 row** in
  `validation/notes/collapsed-gate-ledger.md` was last touched at `8bc066f` (B-I/1). It still
  frames G-1 as unexamined, with proposed disposition *"doc-first: cross-check `decisions/input.md`
  + `internals/user_input.md`"* — work S20 actually **did**, in code. Nothing records that
  RVW-111's scope narrowed (a real *run* with a hidden widget already falls through safely; only
  the inspect-mode debugger is contested) or that a CONTESTED tech-debt entry now exists. The
  ledger is the living agenda the collapsed sitting rules over: left stale, the owner would rule
  G-1 from a weaker evidence base than the tree actually holds.
- **wip-citation discipline HELD** (the ruling-8 self-consistency check). The only two `wip/` hits
  in persistent docs are the rule's own anti-pattern illustration (`conventions/code.md:85`) and
  the debt item naming the offending paths (`technical_debt/input.md:624`) — neither is a citation
  used as a source. The 2 real violations (`userInputController.lua:8`,
  `consoleController.lua:511`) still exist and are correctly logged rather than fixed in a
  comments-only pass.
- **Bookkeeping matches the tree** — RVW-026/080/083/084/085/090/091/094 all carry filled
  dispositions consistent with what shipped (spot-checked against the files); `S19-tests-triage-plan.md`
  marks B-I COMPLETE. ✅

## 5. Gap check — the owner's widening (**F4, the substantive finding**)

**`grep -rn "since 1.0.0" tests/` returns nothing. The positive branch of the convention has never
been exercised anywhere in the suite.**

Against that: `doc/input_api.md` tags the **entire** `compy.input` public surface as feature-new —
"supported since 1.0.0-rc20260712" on Methods (327), Sub-tables (341), show/configure config keys
(352), sticky `callbacks` (365), field-write-only `callbacks` (377) — plus the legacy polling
globals "deprecated, removed in 1.0.0-rc20260712". And vs the `devupstream` baseline, **13 of 20
files in `tests/input/` are new**, including `input_widgets_callbacks_spec.lua` (+508),
`input_events_spec.lua` (+473), `input_reconfigure_spec.lua` (+363),
`input_redesign_ac_spec.lua` (+174 — the Phase R acceptance criteria, i.e. behaviour that changed
*during* the feature). That is a large body of unambiguously feature-new coverage carrying no
availability marking at all.

**Is the S20 claim false? No.** The key says "almost nothing **here** earns a fresh `since` tag",
where *here* = the bucketed groups, and explicitly defers: "the genuinely feature-new public
surface is already tagged in `input_api.md`". Both halves check out. The verdict is **correctly
calibrated within its scope**.

**What was never ruled is the scope.** A vocabulary convention adopted suite-wide but applied only
where old banners happened to sit leaves "untagged" ambiguous between *verified pre-baseline* and
*unexamined* — more elaborate without being more predictable, which is the failure mode the
strategic frame names by name. Two clean exits, owner's call:

- **(i) Scope it explicitly** — record in the migration key that the convention governs groups that
  previously carried bucket banners, and that untagged elsewhere is not a verdict. Zero edits.
- **(ii) One availability line per input spec file head** — feature-new files say so once
  ("covers the `compy.input` surface, supported since 1.0.0-rc20260712"), pre-baseline files say
  they are pre-baseline. ~13 one-line edits, comments only, makes untagged mean something.
  **Not** per-group or per-test tags — that would be elaboration.

Recommendation: **(ii)**, since a stakeholder reading the suite is precisely the audience that
cannot tell new from preserved — but (i) is defensible and free.

## 6. Artifact check + adjacent findings

All expected S20 artifacts present and complete (migration key, inventory updates, triage-plan
status, tech-debt + conventions entries, two commits, suite green). No placeholders, nothing
truncated.

- **F5 — half-migrated vocabulary, inherited from `8a6e95b`.** The D1 leftover fix dropped
  `SINK = last consumer` from `input_routing_spec.lua`'s vocabulary block in favour of the ratified
  route/widget vocab. The same block is copy-pasted into five sibling files that **all still say
  `SINK = last consumer`**: `input_widget_lifecycle_spec.lua:6`, `input_widgets_callbacks_spec.lua:6`,
  `input_shortcuts_click_spec.lua:6`, `input_reconfigure_spec.lua:6`, `input_route_lifecycle_spec.lua:6`.
  One fixed, five stale — the "complete or not at all" rule the plan applies to renames. Cheap
  mechanical fix; adjacent to the version-tag migration but from the same session.
- **F6 — dangling file cross-refs (pre-existing, park for B-F).**
  `input_events_spec.lua:21` cites `input_widget_callbacks_spec.lua` (actual name is
  `input_widgets_callbacks_spec.lua`); `input_widgets_callbacks_spec.lua:15` cites
  `input_dispatch_chain_spec.lua`, which does not exist (that content is `input_events_spec.lua`).
  Not S20's doing.

## Proposed corrections

| # | Correction | Kind | Recommendation |
|---|---|---|---|
| F1 | `input_nfr_forward_spec.lua:217` "this bucket's" → "this group's" | mechanical | apply now |
| F2 | Rewrite the nfr file-head (lines 1, 16–19) into migrated vocabulary; keep the RVW-recheck marker for B-F | mechanical | apply now |
| F3 | Append an S20-evidence line to the G-1 row in `collapsed-gate-ledger.md` (code-verified spine, RVW-111 scope narrowed, tech-debt entry exists) | bookkeeping | apply now |
| F4 | Rule the convention's scope: (i) record the limit, or (ii) one availability line per input spec file head | **owner ruling** | (ii) |
| F5 | Sweep `SINK = last consumer` out of the five remaining vocabulary blocks | mechanical | apply, or fold into B-F |
| F6 | Two dangling spec cross-refs | park | B-F |

---

## Disposition (owner, 2026-07-29)

- **F1/F2/F3/F5 — APPLIED**, commit `96d1c78`, suite 841/0/0/4. `SINK` and stray `bucket`
  vocabulary now return zero hits in `tests/` (bar the RVW-076 marker's own text). F2 deliberately
  keeps the "named milestone" phrasing so its `REVIEW/recheck` marker stays live for B-F.
- **F4 — RULED (ii)**: one `-- Availability:` line per file in `tests/input/`, all 20 files,
  classified by *behaviour* against the `devupstream` baseline. Rule + classification table
  recorded as the S21 amendment in `S20-version-tag-migration-key.md`. Per-group / per-test tags
  stay prohibited.
- **F6 — parked for B-F** as proposed.
