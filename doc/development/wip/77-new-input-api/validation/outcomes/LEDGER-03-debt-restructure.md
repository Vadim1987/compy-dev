---
description: Outcome of LEDGER-03 — restructuring the technical-debt register into ACTIVE / BACKLOG / RETIRED, the BUG-01 defect mapping, and the two unimplemented-decision entries it adds
status: active
audience: developer
authored: llm
reviewed: none
---

# LEDGER-03 — debt register restructured into ACTIVE / BACKLOG / RETIRED

Session49-spawned Sonnet subagent, 2026-08-27. Edited three files under
`doc/development/technical_debt/`: `input.md`, `general.md`, `README.md`. Did not touch
`ROADMAP.md` or `decisions/input.md` (verified: `git diff --stat` on both is empty).

## 1. The sort

**Method:** every `### `/`## ` entry heading and body was read (all 64 in `input.md`, all 5 in
`general.md` — 69 entries opened, not skimmed). RETIRED was decided on the literal heading
marker only (`RESOLVED`, `RESOLVED-IN-PART`, `— RESOLVED <date>`, `RESOLVED by …`). ACTIVE was
decided by matching each remaining entry's subject against every **live** (not ✅-complete) row
in `ROADMAP.md` — not only `BUG-01`, all of it (`ARC-02`, `FIX-01`, `FIX-02`, `DEC-01`, `CHG-01`,
`FIX-03`). Everything else is BACKLOG.

### `input.md` — RETIRED (21, unchanged from original, heading text untouched)

`wrap`'s error handler wrong arity · `compy.before_exit` absent from docs · Future input
unification · Project-handler wrapping dedup · `love.handlers.userinput` dead code ·
Input-only/pointer-only stay live in `project_open` · `compy.keys_pressed` not exposed ·
Shortcuts key-repeat unsettled · No public `is_active()` · Console route hidden-widget fallback ·
Bare `*` shortcut legal · Multi-trigger combo truncated · Combo table modifier-class · Combo-string
allocates a table per call · `F.reset()` 14-line limit · `submit()` deliver-then-hide · `_generic_
callback` re-resolves precedence · Pointer delivery unstructured broadcast · Widget sink reaches
singleton · `UserInputController:keypressed` `app_state` fork · Comment wip-citation cleanup.

**Note:** "Widget sink reaches the singleton…" is marked `RESOLVED-IN-PART`, and its own
Revisit line still names an open question (inject `self.input` at construction vs. read the
global). I kept it in RETIRED per the literal heading rule — it explicitly says
RESOLVED-IN-PART, which is the pattern the task names — but it is not fully closed. Flagged
again in §5.

### `input.md` — ACTIVE (11: 1 pre-existing entry moved, 10 new)

| Heading | Roadmap row |
|---|---|
| `combo_string` does not normalise the case of a textinput token *(pre-existing, moved)* | BUG-01-04 |
| Decision 1 — console/editor convergence onto the shared chain is unimplemented *(new)* | unimplemented decision (LEDGER-01) |
| Decision 35 — the `show`/`configure` content-ownership boundary is not built *(new)* | unimplemented decision (LEDGER-01); implementing pass is ARC-02 |
| A highlighter cannot be turned off — `false` already does it, unratified *(new)* | BUG-01-02 |
| `turtle` double-handles its own keys *(new)* | BUG-01-03 |
| `set_cursor` clamps by byte offset; boundary event measures characters *(new)* | BUG-01-05 |
| `show{force = true}` applies some keys, drops one, defers another *(new)* | BUG-01-06 |
| balloons keeps a shadow copy of the widget's label, re-pushed every cycle *(new)* | BUG-01-07 |
| `show{cursor = {}}` raises a raw Lua error from inside the framework *(new)* | BUG-01-08 (also ARC-02-06) |
| `set_text` silently ignores a multi-line *string* *(new)* | BUG-01-09 |
| The highlighter has two homes, and one of them lags *(new)* | BUG-01-10 |

### `input.md` — BACKLOG (42, unchanged original order)

The Web build has no coverage · A project that raises leaves global device state dirty; no
force-reset exists · `compy.before_exit` is a closure slot · Truthy `hooks[event]` disables
`on_limit_reached` · Raise from project top-level vs. handler differs · `close_project` bypasses
the run's exit path · Raise at `project_open` swallowed whole · The error lock is hostile ·
`repl` doesn't evaluate · Widget opened from a key receives its own echo · Combo triggers
key-name-only · Keyboard-hooks-only project not interactive · `gui` deliberately unsupported ·
Service keys (`capslock`/`tab`/`lgui`) untreated · Widget-handle shape test exercises a stub ·
`Esc` in turtle · Editor buffer not cleared on Escape · tixy shift+click unclear · Touch delivery
not black-box expressible · maze's Lua-command path not characterizable · Test-fixture standup
boilerplate/naming · Force-path "does not warn" coverage gap · Editor cursor outside project API ·
Per-example internals docs describe retired polling idiom · Untracked scratch examples ·
`update_prompt` declined · PROPOSAL event-sourced held state · PROPOSAL `compy.input.keys` · Chord
gating a held state has no vocabulary · sapper's modifier click path · Modified shortcut families
fall-through · Examples not onboarded onto new API · `compy.input` built once, not per run ·
Console debug hotkeys ad-hoc `if`s · `userlove` naming (CLOSED, ruled to keep) · `set_love_*`
installers isomorphic · De-facto behaviours pinned during the un-fork · Console prompt drawn under
a project (DISPUTABLE, ruled to keep) · paint's `useCanvas(btn)` double meaning · Modifier accessor
truthy/falsy · Console/editor hand-written modifier tests · Gesture-tolerates-modifier
registration cost.

### `general.md`

- **ACTIVE (1):** `` `gfx` implicit global in `controller.lua` `` — matches **FIX-02-15**
  ("`technical_debt/general.md` carries an entry that is not debt"): the `> REMARK:` sitting
  directly above this entry says exactly that ("its not a defect, but convention"), so this is
  the entry FIX-02-15 targets. Moved with its REMARK line, which precedes it.
- **BACKLOG (4):** The test suite passes only in declaration order · Editor submit raises when
  no buffer is open · The console's terminal self-test is unreachable ·
  `table.protect(love.handlers)` is a no-op. None matched any live roadmap row.
- **RETIRED (0):** no entry in `general.md` carries a RESOLVED-shaped heading.

## 2. The `BUG-01` mapping table

| Row | Defect | Existing entry? | Disposition |
|---|---|---|---|
| BUG-01-01 | `state.pending` survives a project stop | **Yes, indirectly** — "`compy.input` is built once for the application, not per project run" (BACKLOG) documents this as its root cause and states it's fixed | Row is ✅ closed already; no new entry. The covering entry stays BACKLOG (accepted architectural note, no further action pending) since the bug itself is done and no other live row targets the entry |
| BUG-01-02 | a highlighter cannot be turned off | No — searched for `highlighter` in the register, zero prior hits | **New ACTIVE entry added** |
| BUG-01-03 | `turtle` double-handles its own keys | No | **New ACTIVE entry added** |
| BUG-01-04 | textinput shortcut can't bind upper-case | **Yes** — "`combo_string` does not normalise the case of a textinput token" (confirmed by the roadmap's own crosswalk: "old `06`(uppercase)→**04**") | Moved existing entry to ACTIVE |
| BUG-01-05 | `set_cursor` clamps bytes vs. boundary measures characters | No | **New ACTIVE entry added** |
| BUG-01-06 | `show{force=true, prompt=…}` drops the prompt (+3-way key behaviour) | No | **New ACTIVE entry added** |
| BUG-01-07 | balloons shadow-copies the widget's label | No | **New ACTIVE entry added** |
| BUG-01-08 | `show{cursor = {}}` raises a raw Lua error | No | **New ACTIVE entry added** |
| BUG-01-09 | `set_text` silently ignores a multi-line string | No | **New ACTIVE entry added** |
| BUG-01-10 | highlighter has two homes, one lags | No | **New ACTIVE entry added** |

**On the prompt's own example — `close_project` bypasses the run's exit path — does NOT map to
any of the ten `BUG-01` rows.** I checked every row's text for "close_project", "exit path" and
"stop_project_run": no hit. This entry predates the `BUG-01` sprint (its own text and the recent
commit history — `docs(debt): close_project bypasses the run's exit path` — show it was filed as
its own standalone item, and `ARC-01`, now complete, fixed only its widget half). It is real,
still partially open, and currently has **no live roadmap row** naming the remainder (the
`before_exit`/handler-teardown half). I sorted it BACKLOG on the strict rule, but flag it in §4 —
the task's own example citation suggests it may deserve a closer look.

## 3. The unimplemented-decision entries added

Both from `LEDGER-01`'s verified list (`validation/outcomes/LEDGER-01-decisions-split.md`), both
new headings in `input.md`'s ACTIVE section, decision text left untouched in
`decisions/input.md`:

- **Decision 1 — console/editor convergence onto the shared chain is unimplemented.** States
  that `ConsoleController:keypressed` / `EditorController:keypressed` still run their own narrow
  dispatch instead of the project route's chain, per Decision 1's own "deliberately left as a
  follow-on" text.
- **Decision 35 — the `show`/`configure` content-ownership boundary is not built.** States the
  three concrete gaps LEDGER-01 verified in code: `configure` still admits `text`/`cursor`, the
  hidden-`configure` stash still writes `state.pending`, and a forced `show{}` with no `text`
  still preserves rather than clears. Points at `ARC-02` as the implementing pass.

I did not add anything for Decision 28 or the wheel/touch stub methods — LEDGER-01 explicitly
ruled those out (Decision 28 is fully implemented; the touch stubs satisfy Decision 2/25 by being
present, even though empty), and I re-checked its reasoning against the code rather than taking
it on faith. Agreed with both.

## 4. Uncertain sorts — for a human

1. **`close_project` bypasses the run's exit path** (input.md, BACKLOG). No live roadmap row
   names it, but the task's own prompt cited it as an example of pre-existing coverage, which
   reads as an expectation that it matters this release. What would settle it: does anyone intend
   to rule on "run the normal exit path vs. confirm the omission deliberate" before ship, or is it
   genuinely deferred? If the former, move to ACTIVE.
2. **"`compy.input` is built once for the application, not per project run"** (BACKLOG). Its body
   is the entry that documents `BUG-01-01` as fixed. It reads as effectively closed (Disposition:
   "Accepted, no action expected") but carries no RESOLVED-shaped heading, so it stayed out of
   RETIRED per the literal rule. A human familiar with the intent behind rule 1 might prefer to
   reword its heading with a resolution marker in a follow-up pass (not done here — no rewording).
3. **"Widget sink reaches the singleton…" (RESOLVED-IN-PART, in RETIRED)** — genuinely partial;
   see §5. Could arguably be BACKLOG instead of RETIRED depending on how strictly "or similar" is
   read.
4. **"Force-path 'does not warn' coverage gap"** (BACKLOG) sits very close to `ARC-02-02`'s
   breaking-test list (which pins several `force`-path claims), but that list is about content
   behaviour, not the specific "does the sanctioned path warn zero times" assertion this entry
   names. I judged it a non-match and left it BACKLOG; a human closer to the `ARC-02` test plan
   may see it differently.
5. **"Console and editor route handlers bind by hand-written modifier tests"** (BACKLOG) is the
   direct symptom of the new Decision 1 ACTIVE entry (both point at the same console/editor
   migration gap, one at the ledger level, one at the code-shape level). I did not merge or
   cross-link them beyond a "see also" sentence in the new Decision 1 entry, since merging would
   have meant rewording an existing entry. A human may want to fold them or at least add a
   cross-reference from this side too.

## 5. Things a human should look at

- **Two entries read as final rulings but carry no RESOLVED-shaped heading**, the same pattern
  the task warned about in reverse (heading claims nothing, body says it's settled):
  - `` `userlove` does not convey its semantics `` — heading says `(CLOSED — ruled to keep,
    2026-08-03)`. "CLOSED" isn't "RESOLVED"; I judged it not "similar" enough to retire and left
    it BACKLOG, but a human may disagree.
  - "The console's prompt is drawn under a project…" — heading says `(DISPUTABLE, ruled to keep
    2026-08-07)`. Same shape: a final ruling, no RESOLVED marker.
  - "An `update_prompt` endpoint was asked for and declined…" — body opens "**Declined, 2026-08-11
    (owner).**" No marker of any kind in the heading.
  - "sapper's modifier click path…" — body's last substantive line is "**Ruling, 2026-08-15:**
    retain the fallback." No marker in the heading.
  These four are all "owner ruled, nothing left to decide" in substance, but none matches the
  literal RETIRED pattern, so all four stayed in BACKLOG. Whether that's right depends on how
  "or similar" in the task's rule 1 is meant to be read — I read it narrowly (must still say
  RESOLVED in some form) rather than broadly (any final ruling counts).
- **`` Widget sink reaches the singleton via `love.state` global + nil-guard `` (RESOLVED-IN-PART)**
  — see §4.3. Its own Revisit line names unfinished work.
- **No duplicate or self-contradicting entries found** among the 43 I hadn't already flagged —
  I read every body, not just headings, specifically hunting for the "heading says nothing, body
  says resolved" and "sorted on heading but body disagrees" failure modes named in the prompt, and
  turned up the four items above plus the one RESOLVED-IN-PART item. Nothing else showed a
  heading/body mismatch.
- **FIX-02 rows beyond `BUG-01` and the two decisions were not turned into new entries** — the
  task scoped the two additions to (a) unimplemented decisions and (b) `BUG-01` defects, so I did
  not add entries for things like `FIX-02-12` ("callbacks cannot be un-set"), `FIX-02-13`
  ("hide() vs teardown singleton"), or `FIX-02-14` ("channel list exists twice"), even though a
  register search turned up no existing entry for any of them either. Flagging in case that scope
  limit was meant to be broader.

## 6. Before/after entry counts

- `grep -c "^### " doc/development/technical_debt/input.md`: **64 before, 74 after** (+10: 8
  `BUG-01` defects + 2 unimplemented decisions; 0 deleted — every original heading verified
  present, byte-identical body, by direct substring check against the pre-edit content).
- `grep -c "^## " doc/development/technical_debt/general.md`: **5 before, 5 after** (0 added, 0
  removed — only resorted into `# ACTIVE` / `# BACKLOG` / `# RETIRED`, one level above the `##`
  entries per the file's existing heading depth).
- `README.md`: rewritten description paragraph and the "remove an entry when paid" line (which
  directly contradicted the new RETIRED-not-deleted model) — no entries to count there.
