# session67 — track

## 2026-09-02 — boot

- Fresh start: no `track.md`, no `report.md` in `session67/`. Guardrail → begin.
- Read `agents/sessions.md`, `agents/validation.md`, `session67/prompt.md`,
  `session66/report.md`.
- HEAD `4a0b4dd0` *(docs(session66): re-wrap — the cold read of this session…)*.
- **Suite: 1048 / 0 / 0 / 10** — matches the stated baseline. **LuaJIT 2.1.1703358377** in the
  container; no `lua` binary present, so the PUC-Lua result is unverified here, as always.
- Working tree: the known untracked scratch (`claude.sh`, `src/STEPS.md`, `input-pr-slices.tar.gz`,
  `src/examples/{balloons,keyboard,maze}`, `worklog.md`, `repos.txt`, `broken-busted/`).

### Boot finding — session66's cold-read artifacts are on disk but never committed

`validation/outcomes/S66-cold-revalidation.md` and
`validation/prompts/S66-cold-revalidation-commission.md` are **untracked**. Both are cited from
`session66/report.md` §8 and §9, which *is* committed (`4a0b4dd0`), and from `session67/prompt.md`.
So the committed record points at two files that a fresh clone would not have. Sibling
`validation/reviews/S66-session65-delivery-revalidation.md` **is** tracked — this is a miss, not a
policy. Hygiene (c) is satisfied on disk and not in git. Raised with the owner; not swept
unilaterally, since committing another session's deliverable is theirs to confirm.

### Citations resolved before proposing (prompt: "resolve the exact line, or not at all")

`FIX-02-22`'s three sites, all live:

- `design/spec.md:155` — *"Content preserved for the next `show()` without `text`."* **FROZEN.**
- `design/spec.versions/version01.md:191-194` — *"Input content is preserved (subsequent `show()`
  will display it unless `text` is provided)."* **FROZEN.**
- `decisions/input.md:194` — *"…keeps 'hide and bring back with state intact' free…"*, inside
  `D-WIDGET-AT-BOOT`'s **Why**. Ours to fix. Note the row's cell says "Decision 3"; the ledger has
  been on names since `DEC-01`, and `:1786` is the crosswalk row `Decision 3 → D-WIDGET-AT-BOOT`.

## 2026-09-02 — owner confirms the first pick

- Order for half (a) proposed and accepted: **`-22`+`-13`** → `-25` → `-06`,`-23` →
  `-03`,`-04`,`-24` → `-05`→`-17`→`CHG-01` → the `-09` smoke slice.
  Rationale that carried it: `-22` is the only row in the half with an **owner-gated** part, so
  raising the proposal on turn one unblocks it early. Second: the `-09` slice goes **last in the
  half** because it is a vocabulary sweep and rows 1–5 are still writing prose onto that floor.
- Owner also confirmed committing session66's two untracked artifacts → `2986f028`.

## 2026-09-02 — `FIX-02-22` + `-13` executed. The row was wrong three ways.

Commits: `f3a41997` (decisions), `86f73731` (guide), `c49ac041` (roadmap + proposal note).
Suite 1048 held at every one; docs only, no `.lua` touched.

**The three corrections, and none came from reading the row:**

1. **Persistent corpus: two sites, not one.** `decisions/input.md:76` is the *source* of the
   phrase `:194` quotes. The row named only `:194`. Fixed as one — `FIX-02-06`'s rule.
2. **Frozen tree: five sites, two claims, not two sites and one.** `design/spec/M2.md:33` unnamed;
   and the *forced*-`show` variant (`spec.md:149`, `version01.md:179-180`, `:534-535`) is the same
   sentence one clause over, already reversed by `D-CFG-BOUNDARY` statement 4.
3. **"The code clears it" names the wrong call.** `hide()` **preserves** — pinned by *"a typed
   character while hidden does not mutate it"*. The next bare `show()` clears — pinned by *"a fresh
   activation with no text is empty"*. **A fix written from the row's wording would have been wrong
   in the opposite direction**, and this is the sitting's one real lesson.

**Method note worth keeping:** the guide example (`show{prompt,text}` → `hide` → bare `show`) was
**run** in a scratch spec before being documented, not reasoned about. It passed. An earlier draft
of that example had three calls and would have been wrong — the third `show` lands on an *active*
widget and warns instead of re-opening. Reasoning produced the bug; running caught it.

**Deliberate omission:** no new "draft" vocabulary in the guide paragraph. `FIX-02-20`'s ruling on
the word is still owed and `FEAT-02` already widened its spread once while it waited.

**Recommendation to the owner, not applied:** do **not** amend `design/`.
[`validation/notes/FIX-02-22-frozen-design-sites.md`](../../../validation/notes/FIX-02-22-frozen-design-sites.md).
Ground: `D-CFG-BOUNDARY` establishes the deviation by quoting the round-2 sentence **verbatim**, so
rewriting the spec breaks that citation on purpose. Fallback offered: one precedence line at the
top of `design/spec.md` instead of five edits.

**Open question for the owner:** does §1's extra-sites finding belong in the debt ledger? Kept on
the roadmap row instead — the row is live and cited, `design/` dies with `wip/77`, and an entry
retired in the same breath is noise. Flagging rather than deciding, since three sessions running
have mis-called exactly this boundary.

## 2026-09-02 — owner rules, and reframes the question I asked

- **Behavioural note, the one worth keeping from this session.** I asked *"where does this finding
  get recorded"*. The owner ignored the filing question and asked **whether the rule was ever any
  good**: *"neither of existing known scenarios relies on hiding and restoring widget with exactly
  same text/cursor… the requirement as originally written is likely useless and batch-approved."*
  Same disposition, better ground — and it is the third time this phase has gone this way. The
  memory is *"defects get answered at design level"*; this is that, applied to a **documentation**
  defect, which I had not seen it reach before. A wrong sentence about a rule is a reason to
  re-examine the rule.
- The owner also pre-authorised the honest outcome: *"if rationale is weak and decision is not
  justified, tell it was by mistake but not fixed in release because cost of urgent repair outweighs
  cost of failure."* Judged **not** weak — evidence below — so it is recorded as a retirement.
- **Second correction to my framing:** I asked about a "line in decisions/changelog"; **no CHANGELOG
  line is owed.** Preservation was never shipped — at the PR base the widget was rebuilt per
  activation — so this is a design requirement not built, not a behaviour anyone could notice
  changing. Stated in the decision so the next reader does not re-ask.
- `design/spec/M2.md` out of scope by owner ruling: historical spec subslice, the period's analogue
  of a roadmap row.

**The premise was checked in code and holds, with one gap.** The only two `hide()` call sites in
the tree — `maze_main.lua:126`, `draw_main.lua:233` — both abandon the prompt for a menu and
**want** the clearing. Zero want restoration. But the owner's fallback (*"could be done in calling
project (i hope we have accessors to get cursor position)"*) is **half available**: `get_cursor()`
exists; **there is no content getter**. Surface is `show, hide, is_shown, get_cursor, set_cursor,
set_text, configure, clear`.

- Landed as `D-CFG-BOUNDARY`'s third *"what this changes for a project"* item (`b6394761`), which
  quotes both frozen spec sentences **verbatim** so the record survives `wip/77`'s deletion.
- The gap is **registered** (`2acd6a9e`) — *"PROPOSAL: a read-only content getter"*, BACKLOG,
  unslugged. It had been cited as background in **three** unrelated entries and filed as none; the
  three-unrelated-routes signature is what earned it the entry, not the third instance.
- **So the ledger question answered itself, one level over.** The design-tree finding stays on the
  row (subject and record die together); the thing that *did* belong in the permanent ledger was the
  consequence for the **shipped surface**, which I had not separated from it when I asked.

`FIX-02-22` closes. Next: `-25`.

- Owner then added the getter proposal's **real consumer** (`b28dbe26`): reading content **outside
  submit and cancel** — on a timeout, or from a project-launched process off a hotkey. Today those
  two moments are the entire read surface. Reframes the entry: *"restore a draft across a hide"* is
  exotic, *"read the field without forcing a submit"* is not, and sizing it from the hide/show
  framing alone would under-price it.

## 2026-09-02 — `FIX-02-25`. The test reads the real set; no defect behind it.

Commits `a3097082` (spec), `16e2c100` (ledger retirement + citation sweep). **Suite 1048 → 1050.**

- **The design call that mattered.** A hand-written list of the accepted keys would have been a
  **third** copy — and it cannot fail on a key it does not know about, which is the entire defect.
  So the spec **reads the real set out of the surface**: `show` → `api_show` → `SHOW_KEYS`, two
  upvalue hops **by name**, and the `configure` equivalent. Probed first (scratch spec) to confirm
  reachability before committing to the design.
- **Mutation-tested both ways, and the second one is the important one.** `'ghost'` into
  `WIDGET_KEYS` → both cases fail naming the key. Renaming `SHOW_KEYS` → *"upvalue SHOW_KEYS is
  gone; fix this reader"* rather than **silently checking an empty set**. A reader that returns nil
  on a rename would have degraded to a test that passes while checking nothing; hence the asserts
  and the non-empty guard.
- **No production defect.** `CALLBACK_KEYS` and `CONFIG_CALLBACKS` hold the same four strings;
  `prompt`/`auto_hide` → `configure_core`, `text`/`cursor` → `open_widget`, `force` gates in the
  widget's own `show`. The prompt reserved a separate commit for a defect here; not needed, and the
  row's placement argument (*"the sitting would run against an unknown"*) is now discharged.
- **`lua-lsp` is HEALTHY** — its health was unverified since session65. `diagnostics` clean on the
  new spec, and `references` on `configure_core` returned the two real call sites. Reported because
  the prompt asked for it either way.
- **Ledger: retired, and the slug sweep done in the same commit.** `roadmap.md` §5 makes the pass
  that causes an orphan owe the fix, and dropping a slug from a heading *is* that pass —
  `T-HL-TWO-HOMES` is the standing example. Swept: the roadmap's renumber REMARK, the row, **and my
  own spec header written an hour earlier**. The filing text is kept and labelled rather than
  rewritten (*"No such test exists"* was true when written).
