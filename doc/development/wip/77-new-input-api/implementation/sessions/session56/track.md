# session56 — track

**Date:** 2026-08-28  
**HEAD:** `71c8069c`  
**Tree State:** Clean  
**Suite Count:** 1011 successes / 0 failures / 0 errors / 10 pending  

---

## Session Log

* **Boot**: Session 56 booted. Reconciled platform merge performed by human (commit `f4913833`) and FS mock fix (commit `75a7e5b3`). Suite updated from 992 to 1011 tests (19 upstream tests added).
* **ROADMAP Update**: Updated `ROADMAP.md` to reflect `MERGE-01-04` completion, platform `REC-01` completion, and new baseline suite count (1011/0/0/10). Committed as `7cd26a26`.
* **FIX-02-02**: Confirmed `tixy` legend clearing on submit (`legend = ""`) is example design per `validation/notes/S24-W7-A4-A5-invisible-overlay.md`. Formally closed `FIX-02-02` in `ROADMAP.md`. Committed as `ca33c1d1`.
* **BUG-01-03 / T-TURTLE-DUP**: Added `if compy.input.is_shown() then return end` guard to `src/examples/turtle/main.lua:love.keypressed`. Formally closed `BUG-01-03`, `FIX-02-11`, and retired debt entry `T-TURTLE-DUP`. Tested suite (1011/0/0/10 green). Committed as `71c8069c`.
* **Peer review of the turtle fix — commissioned, never run.** Prompt written to `validation/prompts/BUG-01-03-turtle-fix-peer-review.md` and committed with the track as `a8e25bf3` ("unfinished"); the incarnation hit its limit before spawning the reviewer. `validation/outcomes/BUG-01-03-turtle-fix-peer-review.md` does not exist.

---

## Re-entrance — 2026-08-30

* **Boot (second incarnation).** HEAD `a8e25bf3`; tree carries only the known scratch anomalies plus new untracked `broken-busted/`, `repos.txt`, `worklog.md` (owner's, not touched). Suite re-run: **1011 / 0 / 0 / 10** — matches the track baseline.
* **Housekeeping (owner-directed):** committed the owner's `.gitignore` change (`docker-data`) as `2548ee08`.
* **Owner housekeeping, directed in-session:** committed their `compose.yml` change (`b29e6cf3` — named volume → `./docker-data/agent` bind mount, pairs with the gitignore entry); recorded their three hand-filed debt entries (`880c45ef`, `b6456d61` — `T-ONESHOT`, `T-PLAINTEXT-ENTERED`, `T-NAMESPACE-CLONE`) as a roadmap **intake block deliberately not filed into a sprint** (`0aa9b637`), since KIND and placement are theirs to rule. Two placements are not obvious and are flagged there: `T-ONESHOT` **grows** the public surface and so meets the strategic frame head-on, and `T-PLAINTEXT-ENTERED` is a candidate *answer* to `FIX-02-01` rather than a row beside it — `FIX-02-01` now carries that cross-reference.
* **BUG-01-03 revalidation — RUN and CLOSED.** Cold Sonnet reviewer against the predecessor's prompt, told what not to read. **Approve with comments** (`45b95af8`). Guard confirmed as the documented idiom, not a symptom patch — `doc/input_api.md` "Why the widget sits at tier 3" puts the onus on the project explicitly, and `input_widget_control_spec.lua:621-637` pins the shape. **Parent verification corrected the review's main comment:** the blanket return does not remove suspend-while-typing, because `ctrl+pause` is a framework reservation above tier 1 (`controller.lua:812-815, 868`) that no project guard reaches; what is lost is the example's convenience duplicate. Disposition: comment, not narrowing — landed at the guard (`c80b9638`), satisfying the deviation-not-in-the-commit-message-alone directive. Second comment (no test pins the fix) recorded as-is: no example anywhere in this codebase carries spec coverage.
* **Trigger fired:** the intake block's filing ruling was gated on this revalidation closing. It has. Roadmap updated; **waiting on the owner** for KIND + sprint.
* **Owner rulings on the revalidation's residue (2026-08-30), all executed:**
  * *turtle's `pause`* — owner reads its removal as DRY cleanup, not a lost affordance. **Conclusion right, premise inverted**: both paths already exist at the PR base, and the framework's `suspend_run` (2024-01) is the *elder*, not turtle's key (2025-01). Materialized: `validation/notes/turtle-pause-duplication.md`.
  * *documentation gate* — owner's test is "only if it highlights an unobvious, non-trivial, useful path". **Passes**, on two counts the guide never states: a project's own keys stay live while the field is up, and reservations are exempt from any project guard (which is what makes a blanket guard cheap). → `T-GUARD-LIVE` ACTIVE + `FIX-02-23`.
  * *examples untested* → **BACKLOG** in `general.md`, scoped by the owner to the shared conventions the docs rely on, **not** end-to-end example tests. **No roadmap row on purpose**, and the entry says so.
  * *maze neutralisation* → `T-MAZE-NEUTRALIZE` ACTIVE + `BUG-01-11`, which **opens with the weighing** and may close `wontfix`; owner's framing: reference-implementation quality vs. not overfixing a separate repo's working code.
  * *the three hand-filed entries* → filed as **two new KINDs the owner ruled**: `OP` (operational, no parent decision — `ledgers.md` §4) and `FEAT` (design + implementation). `FEAT-01` **leads the remaining sequence** by blast radius; `OP-01` follows because two of its rows write the decisions `FEAT-01`'s rulings produce — the same reason `OP-01-01`'s style rewrite is ordered *after* `OP-01-02` instead of done immediately.
* **OP-01 EXECUTED (owner directed it to start immediately, and named the order):** decisions first, entries re-derived from them — the inverse of the sprint's own filing note, which is now corrected on the board rather than left describing a plan that did not run.
  * **Decisions 36, 37, 38** written (`71d1f260`). 36 `oneshot` and 37 the payload split are *ruled in, not implemented* — the shape `ledgers.md` §4 names for an unimplemented decision plus a debt-entry pointer. 38 is the live-table/`__index` rule.
  * **Two findings the writing surfaced, neither of them mine to rule on.** (i) `oneshot`'s in-tree case is **thin**: only `turtle` closes on submit, and it keeps `after_submit` regardless to re-arm its echo guard, so in this tree the sugar removes one call from one example — the case rests on the owner's microbit attestation, and Decision 36 says so plainly so the justification table can. (ii) **Half of the payload split already exists** — `after_submit(lines)` is what the submit chain passes today and what the guide documents, so only `on_text_entered` moves.
  * **`T-NAMESPACE-CLONE` retired** (`84882f01`) — obligation was documentation; Decision 38 plus a pointer from Decision 7 is the payment. Placement flagged in the decision itself: the rule is platform-wide and sits in the *input* ledger only because that is where Decision 7 is.
  * **Entries restyled** (`f819d19b`) into `Decision` / `Where` / `State` / `Why it stands` / `Revisit`, each citing the decision it derives from.
* **Judgment superseded, same turn:** `OP-01-01` was first left unworked on the reasoning that an entry must cite a decision that did not exist yet. The owner's answer was to write the decisions *now* — which dissolves the objection rather than overriding it, and is the better order. Recorded because the reasoning was right and the conclusion (defer) was not.
* **Outstanding at re-entrance:** (a) the commissioned peer review of the BUG-01-03 turtle fix, (b) session56 has no `report.md` — the wrap never ran. Noted for the human: the turtle fix landed **without a breaking test first**, contrary to `agents/development.md`; examples carry no spec coverage, which is the likely reason, but it is the reviewer's first question.
