# session67 — report

**Date:** 2026-09-02 · **Suite:** 1048 → **1050** / 0 / 0 / 10, LuaJIT 2.1.1703358377 in the
container (the owner runs PUC Lua) · **Mode:** execution, with three owner rulings taken mid-flight
and a **cold peer review of this session's own work** whose findings are applied. Twenty-nine
commits, `2986f028`..`9bc2b0cf`, none pushed. **Two tests added**, both in one new spec.

---

## 1. What this session was

`FIX-02` half (a) from `session67/prompt.md`, in the order the owner confirmed on turn one:
**`-22`+`-13`** → `-25` → `-06`,`-23` → `-03`,`-04`,`-24`. **Eight rows of the eleven closed.**
Left for the successor: `-05` → `-17` → `CHG-01`, then the `smoke_checklists.md` slice of `-09`.

`ACTIVE` in `technical_debt/input.md` is now **empty**, and the section says so in words.

## 2. The verdict, in one line

**Every row was mis-sized, and in both directions** — larger (more sites than named) or smaller
(already fixed) — because each cell was written by someone who could only grep the obvious form.
Eight for eight. The prompt's *"a count in a row is a lower bound"* was not a caution; it was the
operating condition.

## 3. The pattern this sprint actually has — rows answered at design level

**Three times, a row filed as a documentation defect turned out to sit on a design question, and
twice the owner made the move before I did.**

- **`-22`** — I asked *where a finding gets recorded*; the owner ignored the filing question and
  asked **whether the rule was ever any good**: *"neither of existing known scenarios relies on
  hiding and restoring widget with exactly same text/cursor… the requirement as originally written
  is likely useless and batch-approved."* Retired the requirement rather than amending the frozen
  spec to match it.
- **`-06`** — the triage proposed renaming `release_keyboard_route`. **Not done, deliberately:** its
  caller pairs it with `clear_user_handlers`, so naming it accurately means first deciding whether
  the two are one function. A name chosen without that decision is just a second wrong name. Filed
  BACKLOG.
- **`-24`** — the owner: *"old mermaid version is a good artifact to check feature implementation vs
  intent… if it's not the live doc and never was, maybe we should not update it, just mark
  (historical)?"* It never was. Marked, not corrected.

The standing memory is *"defects get answered at design level"*. What is new is that it reached a
**documentation** defect: **a wrong sentence about a rule is a reason to re-examine the rule.**

## 4. The row that would have been fixed backwards

`FIX-02-22`'s cell said three documents claim a hidden widget keeps its content and *"the code
clears it"*. **The code does not.** `hide()` **preserves** — pinned by *"a typed character while
hidden does not mutate it"*. The next bare `show()` clears — pinned by *"a fresh activation with no
text is empty"*. **A fix written from the row's wording would have been wrong in the opposite
direction.**

The premise was then checked in code and holds with one gap: the only two `hide()` call sites in the
tree (`maze_main.lua:126`, `draw_main.lua:233`) both abandon the prompt for a menu and **want** the
clearing; zero want restoration. But the owner's fallback — *"could be done in calling project (i
hope we have accessors to get cursor position)"* — is **half available**: `get_cursor()` exists,
**there is no content getter**.

That gap is the thing that belonged in the permanent ledger, and the ledger question answered itself
one level over: the design-tree finding stays on the roadmap row (subject and record die together),
while the consequence for the **shipped surface** became a BACKLOG entry. The owner then supplied its
real consumer — reading content **outside submit and cancel**, on a timeout or from a
project-launched process off a hotkey. *"Restore a draft across a hide"* is exotic; *"read the field
without forcing a submit"* is not, and sizing it from the hide/show framing alone under-prices it.

**No CHANGELOG line is owed** (owner): preservation was never shipped — at the PR base the widget was
rebuilt per activation — so this is a design requirement not built, not a behaviour anyone could
notice changing.

## 5. The one code change — `FIX-02-25`

A spec pinning that the surface's accepted config keys and the widget's applied keys agree. Suite
1048 → 1050.

**The design call that mattered:** a hand-written list of accepted keys would have been a **third**
copy, and **it cannot fail on a key it does not know about** — which is the entire defect. So the
spec **reads the real set out of the surface**: `show` → `api_show` → `SHOW_KEYS`, two
`debug.getupvalue` hops **by name**, and the `configure` equivalent.

**Mutation-tested both ways, and the second is the important one.** `'ghost'` into `WIDGET_KEYS` →
both cases fail naming the key. Renaming `SHOW_KEYS` → *"upvalue SHOW_KEYS is gone; fix this
reader"*, rather than silently checking an empty set. A reader returning nil on a rename degrades
into a test that passes while checking nothing; hence the asserts and the non-empty guard.

**No production defect behind it.** The commit the prompt reserved for one was not needed, and the
row's placement argument (*"the sitting would run against an unknown"*) is discharged.

## 6. Where the survivors were

`FIX-02-06` named three places and left the third as *"whichever second doc `FIX-02-05` found"* —
nobody had ever identified it. **The survivor was inside `event_dispatch_layers.md` itself**, ~40
lines below the bullets being fixed: a closing paragraph re-asserting the asymmetry and sourcing it
to a debt entry **RESOLVED 2026-08-03**. Then `FIX-02-04`, a row filed for something else entirely,
found a **fourth** site in `project_sandbox_env.md` — after a sweep that believed it was complete.

**The claim spreads by being restated in passing**, which is why annotation and pointer text is as
dangerous as prose. Two function names cited across the corpus also do not exist: `occupy_keyboard`
(now `occupy_input`) and `hook_pointer` (now `mark_pointer_liveness`, and it installs nothing).

## 7. Mistakes made, because they are the transferable part

- **A `python` substitution turned *"keeps its literal meaning for neither"* into *"for either"*** —
  the exact F5 failure session66 recorded. Caught by re-reading the rendered paragraph, not the diff.
- **A mechanism nearly shipped backwards in the guide** (`-23`): the first draft said a blanket
  `is_shown` guard is safe because reserved combos never reach your handler. Backwards — a
  reservation **acts and passes the key on**, never consuming. Same conclusion, opposite mechanism.
- **My own vocabulary slipped twice** — *"lands in the field"*, *"while the prompt is up"* — written
  by the session carrying `FIX-02-09`'s rule. The tell: it happens while writing **about** the
  widget, not while sweeping for it.
- **A fabricated commit hash** written into the roadmap before that commit existed; caught pre-commit.
- **An empty `lua-lsp` `references` result read as dead code.** `UserInputController:set_eval`
  returned zero references; grep proved `editorController` calls it three times. **Second LSP
  under-report this session** — empty is a hint, never proof of absence. The cold reviewer later
  re-confirmed the callers independently.

## 8. The session's own work, cold-reviewed

Commissioned at the owner's instruction:
[`validation/outcomes/S67-cold-peer-review.md`](../../../validation/outcomes/S67-cold-peer-review.md),
commission in `validation/prompts/`.

**Verdict: the work holds.** ~two dozen claims resolved against source — code behaviour, PR-base
comparisons at `3256aac`, line citations, ledger state, git provenance, the one code change — all as
stated, several to the exact line and the exact runtime error string. It re-ran the
`debug.getupvalue` mutation and reproduced both failure messages verbatim. Suite 1050 confirmed; LSP
healthy throughout.

Two low findings, both verified in git before acting, both real:

1. **A date over-generalised from four files to seven.** I wrote all seven mermaid files *"added
   2024-07-29"*; `eval.md`, `input.md`, `scratch.md` were added **2024-12-18** (`fc2490b4`,
   *"unfinished docs"*) — and those three are exactly the trio I separately and correctly described
   as the unfinished ones. **Both facts were in hand and were merged into one wrong sentence.** It
   had reached `doc/mermaid/README.md`, which is persistent corpus. Corrected there, in the retired
   entry, and in the roadmap cell; the disposition is untouched.
2. **The commission miscounted its own summary** — *"two debt entries filed"* where three were.
   Attributed correctly to the commission, not to the commits or roadmap, which claim no count.
   Recorded as a post-execution correction **appended** to the commission, so the prompt the reviewer
   worked from stays readable as what it was.

## 9. The incident that cost this session its context

**Two Opus sub-agent spawns of that review each took the container's host to 100% CPU, maximum disk
read and active swapping within ~20 seconds, requiring a hard reboot.** Neither wrote a line; the
second forced a `/compact`. Full diagnosis:
[`validation/notes/S67-subagent-host-crash.md`](../../../validation/notes/S67-subagent-host-crash.md).

- **The review's workload is innocent** — every prescribed operation measured afterwards: range diff
  3074 lines, `git grep` at base 0.36 s, suite 2.3 s.
- **The control settles the variable.** Three spawns, identical but for the model: the `sonnet`
  mermaid audit ran nine minutes and returned; both `opus` peer reviews died at ~16 s and ~22 s. The
  third attempt, on Sonnet under a hardened commission, ran eleven minutes without incident.
- **Nothing contains a runaway.** `memory.max` and `cpu.max` are both `max` — 2 CPUs, 3819 MB, no
  swap, against a Node heap limit of 2006 MB. **The container ceiling is unfixed and is the owner's
  call** (compose stack under `implementation/docker`).
- **Leading hypothesis, explicitly unproven** (no sidechain records survive a reboot; `dmesg` is
  blocked): recursive agent fan-out. `general-purpose` carries `Tools: *` **including `Agent`**, and
  my spawn message said *"a spawned agent inherits none of the repo's CLAUDE.md"* and then restated
  the LSP, git and suite rules while **omitting sub-agent hygiene** — the one rule forbidding
  parallel spawns.

**The transferable lesson, and it is self-inflicted:** telling a sub-agent *"you inherit none of the
repository's rules"* and then restating a subset is a **licence to do anything unrestated**. I
restated the constraints on the reviewer's *conclusions* and none on its *behaviour*. Every spawn
prompt now carries an explicit leaf-agent clause.

## 10. Non-obvious points worth carrying

- **Run the example, do not reason about it.** The guide's `show`→`hide`→`show` example was executed
  in a scratch spec before being documented. An earlier three-call draft would have been wrong — the
  third `show` lands on an *active* widget and warns. Reasoning produced the bug; running caught it.
- **A marking pass can be worth more than a correction pass.** `eval.md`'s section headed *"Current"*
  describes a hierarchy **never built**, while its *"Planned refactor"* section is closer to what
  shipped. Correcting the diagrams would have deleted the evidence that plan and build diverged —
  precisely the owner's *"good artifact to check implementation vs intent"*.
- **Dropping a slug from a heading is a pass that owes a citation sweep** (`roadmap.md` §5). Doing it
  in the same commit caught three orphans, one of them a spec header written an hour earlier.
- **Check whether the ledger already holds the class before filing.** `event_dispatch_layers.md`'s
  line citations are wrong by ~110 lines and land on unrelated code; `technical_debt/general.md`
  already holds that class at 77 references. A worked instance was added instead of a duplicate.
- **The pass that names a defect class is not immune to it** — session66's lesson, earned again here:
  the session carrying `FIX-02-09`'s vocabulary rule wrote *"the field"* twice.

## 11. Artifacts

- Track: `session67/track.md` — boot, each row, each owner ruling as it arrived, the crash, the review
- **Twenty-nine commits**, `2986f028`..`9bc2b0cf`, suite green and stated at each; **none pushed**
- New code: `tests/input/input_config_key_agreement_spec.lua` (+2 tests, 1048 → 1050)
- New: `validation/outcomes/S67-mermaid-audit.md`, `validation/outcomes/S67-cold-peer-review.md`,
  `validation/notes/S67-subagent-host-crash.md`,
  `validation/notes/FIX-02-22-frozen-design-sites.md`, `doc/mermaid/README.md`, two commissions in
  `validation/prompts/`
- Ledger: three RETIRED in `technical_debt/input.md` (`T-KEYSET-SPLIT`, `T-GUARD-LIVE`,
  `T-MERMAID-MODEL`) — **`ACTIVE` now empty**; three BACKLOG filed (the content-getter proposal, the
  `release_keyboard_route` naming, and `@field` annotations in `general.md`)
- Decisions: `D-CFG-BOUNDARY` gains a third *"what this changes for a project"* item retiring the
  hide/show preservation requirement, quoting both frozen spec sentences verbatim;
  `D-WIDGET-AT-BOOT`'s **Why** rewritten
- Amended: `doc/input_api.md` (a `hide()` section, the `is_shown` guard paragraph),
  `internals/{event_dispatch_layers,user_input,project_sandbox_env}.md`, `controller.lua` (comments
  only), seven `doc/mermaid/` banners, `ROADMAP.md`
- **Recommendation to the owner, not applied:** do not amend `design/` for `FIX-02-22` —
  `validation/notes/FIX-02-22-frozen-design-sites.md`. `D-CFG-BOUNDARY` establishes the deviation by
  quoting the round-2 sentence **verbatim**, so rewriting the spec breaks that citation on purpose.
  Fallback offered: one precedence line at the top of `design/spec.md` instead of five edits.
