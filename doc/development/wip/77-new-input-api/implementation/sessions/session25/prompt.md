# session25 — revalidate session24, then re-evaluate where the feature stands

Read and strictly respect `agents/sessions.md` and `agents/validation.md`. Boot
normally: read this prompt, the complete `../session24/report.md`, the
session24 commissioning prompt and its track, then create `session25/track.md`.
Do not edit any historical session artifact.

## Where things stand

Session24 received the owner's TF2 take-01 (nine smoke reports plus per-file
remarks), triaged it into a five-band plan, and executed all five bands: prose
and composition work, additive coverage, a headless defect hunt, a twelve-item
owner ruling sitting, and its execution. Suite **874 / 0 / 0 / 3**, green at
every commit; `master` untouched, nothing pushed anywhere.

Two production defects were found and fixed — a genuine regression (a stopped
project left the widget's `shown` flag raised, so the *next* project got no
overlay) and a pre-existing gap (an input-only project's overlay was never
painted, which is one cause behind four separate smoke complaints). One new
public API member was ruled and added (`compy.input.is_shown()`, Decision 18).
Three sibling example repos now carry their own local commits.

Details, evidence notes and the ruling sheet: `../session24/report.md`.

**Two things are deliberately unsettled**, and they are the reason this session
exists in this shape — `validation/reviews/S24-contradictions.md`:

- **C1** — the keypressed/textinput race fix (Decision 19, the event-batch
  seal) is in the tree **unratified**. The owner contests it landing without
  design review. The race is verified; the mechanism, its scope, its release
  point and its exclusions are not ruled. Marked contested in the ledger, the
  project guide and the code, with an exact revert surface.
- **C2** — maze's migration was committed with two consequences of our own API
  change handed back to that repo's author. The owner's standard: *we suggest
  migrations, we do not push responsibility on repo authors; sibling PRs are
  prepared exactly as the platform PR is.* The two questions are ours to
  finish, and `pr-assembly-guide.md` §5 still carries the wrong framing.

**C3** is not a contradiction: the overlay-paint fix awaits the owner's smoke
test, by their choice.

## Your task

**A revalidation of session24, per [`agents/rules/revalidation.md`](../../../../../../agents/rules/revalidation.md)** — work the
checklist, frame findings as a structured report, and do **not** start the next
substantive task without the owner's approval. Session24 exercised heavy
judgment across production code, the ratified corpus and three foreign repos;
this session checks it.

Give these priority within the checklist:

1. **C1 first, as an intent-vs-outcome question, not a style one.** Is the seal
   the right mechanism at all? Weigh it against the alternatives the record
   names (key-matched seal; arm only on `keypressed`; a documented project-side
   idiom with no framework change) and against the run loop's actual
   guarantees. Bring the owner a recommendation and the revert surface — the
   ruling is theirs, and until it is given, treat Decision 19 as absent when
   reasoning about anything else.
2. **C2 second, as work to finish.** Complete maze's migration to the standard
   the platform PR is held to (verify what an invalid command now does before
   deciding `need_reopen`'s fate; express "prompt only while idle" explicitly),
   review balloons' two commits end-to-end against the current API, confirm
   keyboard needs nothing, then correct §5's framing. Commit locally in each
   repo; **never push** any of them.
3. **Then re-evaluate where the feature is** — the owner asked for this
   explicitly. The five-band plan is spent; say plainly what remains between
   here and a PR the stakeholders can read from `doc/input_api.md` plus the PR
   description alone. Known open items: the deferred wrapper rename
   (`forward_*`, `userlove`, the `*_native` trio — ruled to happen *just before*
   the PR), the owner's smoke test, Phase G slice regeneration (still last, and
   now with two reasons to be), and the three questions the sitting referred to
   stakeholders rather than settling.

Verify every factual claim in code before acting on it — including this
prompt's and the report's. Two verdicts this phase were overturned exactly that
way, and a third was overturned in session24 (the "wider error-lock exits are
drift" hypothesis, disproven by the frozen design plus commit history).

## Standing constraints

- Suite green and stated at every commit; one concern per commit; a production
  fix is always its own commit with its breaking test.
- `design/` is frozen — read, never edit. It is what ratified the error-lock
  exit set; narrowing that is an owner-gated design change.
- Commit locally at your discretion. **NEVER push**, never rewrite history,
  never sweep the owner's unrelated working-tree changes in.
- The nested example repos are no longer an anomaly to leave alone (owner,
  2026-07-31): commit in them as the work demands, push none of them.
