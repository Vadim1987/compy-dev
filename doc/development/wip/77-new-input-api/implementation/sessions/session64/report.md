# session64 — report

**Date:** 2026-09-01 · **Suite:** 1048 / 0 / 0 / 10 throughout — no test changed hands
**Mode:** revalidation (delivery level), then execution of the owner's rulings on the findings.
Seven commits, none pushed. Persistent corpus touched: `internals/user_input.md`,
`decisions/input.md` (Decision 38), both debt registers, `ROADMAP.md`.

---

## 1. What this session was

A **delivery-level** revalidation of the last delivery sessions — *did the outcome match the need,
was anything overlooked, was anything unnecessary delivered* — deliberately not a code review.

**The owner cut the scope on boot.** The prompt proposed sessions 60, 61 and 63; the ruling was
**61 and 63 max**, because 61 was itself the revalidation of 60 and re-checking it is a recursion.
For 61 the subject became *what it delivered beyond its own verdicts* — its nine durable document
edits. That reframing is worth carrying: **a revalidation session still has a delivery surface, and
it is the edits, not the findings.**

## 2. What was clean, and it was most of it

- **All nine of session61's post-revalidation edits still stand** — verified in code and docs, not
  taken from its report. One was overtaken by later work (§3).
- **Session63's seven corrected claims are now right.** `_set_text_line` has exactly seven callers,
  all passing `true`; `clear_input` is `_update_cursor`'s only reachable caller; `is_line_list`
  genuinely closes the hole `ipairs` left; the guide's *"the refusal leaves the current content
  untouched"* holds on both paths.
- **Marker gate clean**; the single `DEBT:` marker is exemplary and its cited section resolves; the
  ACTIVE/BACKLOG slug convention survived six new entries (ACTIVE 3 slugged, BACKLOG 46 none).
- **`BUG-02`'s three-way filing closed consistently** in all three homes.
- **No second instance of the "shipped then re-done" shape** the prompt named as the worked example.

## 3. The findings, and what happened to each

| # | finding | outcome |
|---|---|---|
| F1 | the programmatic-cursor census omitted `insert_text_line` | **fixed** (`61119177`) |
| F2 | six line citations into `userInputModel.lua` stale on arrival | **fixed** (`2e2cd1dc`, `d6f9ed76`) |
| F3 | `FIX-02-09` sized by one file; the corpus is `#77`'s own | **row note amended** (`da0def9d`) |
| F4 | the boundary validates 2 keys of 9 | **wontfix — premise refuted** (`c8b947cb`) |
| F5 | 77 line citations corpus-wide, 23% of the checkable ones stale | **registered**, unslugged |

**F1** is the shape the pass was hunting: session63's cold review established that `insert_text_line`
writes the cursor raw on every Shift+Enter, recorded it in the register, and nobody returned to the
census session61 had corrected one day earlier — on the argument that *a sweep consults it instead
of re-deriving*. Fixed by stating **two populations** (callers of the cursor API vs writers of the
field) rather than lengthening one list, because conflating them is what let a site fall between.

**F3** verified at the merge base: `doc/development/` holds **five entries** there and there is no
`CHANGELOG.md`. The whole persistent corpus is this feature's own creation, so none of it is
another author's to leave alone — and `smoke_checklists.md:215` carries the banned idiom verbatim.

## 4. The two things that cost the most, and neither was in the plan

**F2 was wrong twice before it was right.** I named the wrong mechanism (an *inserted* comment;
it was a *trimmed* one, three lines, at `:157`) and undercounted four when it was six — because I
"verified" a citation by printing a range around it, seeing the expected call in the output, and
reading that as a hit. It was `end`. The correction is `d6f9ed76`, and it registered what the
mistake exposed: **77 line citations in the persistent corpus, and of the 62 resolvable to a unique
`src/` basename, 14 — 23% — land on a blank line or a bare `end`.** That is a floor, not the count.

**F4 was refuted at its premise by the owner, not merely declined.** I read the two checked keys as
one class closed one key at a time. It is **Decision 35**'s ratified line — `text` and `cursor` are
the *user's content*, everything else is *project-owned* — and the boundary checks the content class
completely. The consequence argument is the part unavailable from code: *a bad `text` confuses the
user, who did not write it and cannot fix it; a bad `validator` confuses its own author, and the
raise names `validator`, the key they set.* Ruled: **no more input-checking ceremony** — *"its edu
project, not space rocket navigation."*

## 5. Two rulings that outlive this session

- **Documentation volume is not a defect** and is not weighed before the compaction step. Verbose
  docs support ongoing development; compaction is one pass over stabilised material. Recorded on
  the ROADMAP beside Phase L's retirement.
- **`DOC-01` — the documentation compaction sweep — is a roadmap row again.** Raised because the
  ruling relied on a step that was scheduled for *comments* only, Phase L being retired. Five steps,
  new KIND (the `DEC`/`CHG` precedent), placed **after `FIX-03`** — that sweep's deletions are
  mechanical and cheap, so they shrink the floor `DOC-01` exercises judgement over — and **before
  `ACC-02`**, so the cold reviewer reads the prose that ships. Phase L is **not** un-retired.

## 6. Non-obvious points worth carrying

- **Before filing a surface finding, ask whether a decision already draws the line.** Twice the
  owner has answered a defect-shaped question by reopening its category, and both times the category
  was ratified and unconsulted. Reading the commit trail instead of the ledger produces patch
  archaeology that looks like a finding.
- **A line citation is verified by resolving the exact line, or not at all.** Printing a range and
  spotting the expected symbol is how the wrong answer survived a check inside this pass.
- **The failure this pass was hunting reproduced inside the pass** — the code survived every attack,
  the document written to record the failure did not, on the first try.
- **`lua-lsp` is back** (`references` returned real AST hits); session63 ran without it all day.

## 7. Artifacts

- Track: `session64/track.md` — boot, the scope ruling, the pass results, each ruling as it landed
- Seven commits, `da0def9d`..`c8b947cb`, suite green and stated at each
- No new `validation/` documents: every finding landed in a ledger or a roadmap row by design,
  per the standing rule that a finding goes to the register rather than a session artifact
- **Environment caveat qualifying every suite claim here:** the container runs **LuaJIT 2.1**, not
  the owner's PUC Lua
