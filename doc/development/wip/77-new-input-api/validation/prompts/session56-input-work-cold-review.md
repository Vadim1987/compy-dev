# Cold review: session56's input-side documentation work against the owner's raw input

**Commissioned 2026-08-30 by the owner**, who asked specifically: *"validate your work on input
processing (recent commits that follow turtle work and my raw input). It has to focus on check: was
something lost, distorted, misinterpreted or bloated beyond necessity?"*

This file is the prompt of record. The reviewer's report goes to
`../outcomes/session56-input-work-cold-review.md`.

---

## What you are reviewing

Commits `a8e25bf3..HEAD` on `feature/77-newapi-analysis-s20260615`, excluding the two `chore(docker)`
and one `chore(gitignore)` commits (infrastructure, out of scope). In scope: the peer-review
artifact, the turtle guard comment, the debt-register entries, Decisions 36 and 37, the conventions
addition, and every `ROADMAP.md` edit.

`git log --oneline a8e25bf3..HEAD` lists them. Read the diffs, not only the messages.

## The four questions, in the owner's words

For each piece of the work, ask:

1. **Lost** — did something the owner said fail to land anywhere?
2. **Distorted** — did it land, but changed in meaning?
3. **Misinterpreted** — was an instruction read as something other than what it says?
4. **Bloated beyond necessity** — is the written result larger, more elaborate, or more
   ceremonious than what the instruction warranted? *This one matters as much as the others.* The
   assistant writes at length; long prose that says little, sections that restate each other, and
   documentation heavier than the thing it documents are all findings.

## The owner's raw input — the source of truth

### Their two hand-written debt commits

`git show 880c45ef` and `git show b6456d61`. The second is in Russian. **Read both in full before
reading anything the session wrote about them.** These are the primary source; the session's
restyled versions are derived work and may have drifted.

### Their instructions, verbatim from the session's chat

**(1) After being asked what the turtle bug was and what trade-offs it left:**

> i guess turtle shortcut for pause historically preceded framework's similar one, so if I got it
> correctly removing it is clearing up, not a defect (DRY principle in action).
>
> is this case worth few lines in documentation? (only true if it highlights some unobvious,
> non-trivial but useful path). if so lets add active debt entry and roadmap task.
>
> regardless, I want the lack of testing for examples to be recorded as backlog debt. while testing
> examples end-to-end is obvious overkill, testing some major conventions and scenarios (reused
> across examples and relied upon due to documentation) may be worth it.
>
> maze neutraluzation patterns should be checked -- worth active debt entry and roadmap step.
> rationale is: if they use suboptimal logic which now is superseded by better framework
> alternative, we may want to rewrite the part, to avoid confusing those devs who would take maze as
> reference implementation. on the other hand we should not overreach into external example and
> overfix it, if nothing breaks and approach itself is legit and does mot contradict with major
> conventions/recommendations. when step is entered it should start with evaluation of pros and
> contras -- may as well become "wontfix" at a closer glance.
>
> in regard to new tech debt entries -- we need a) rewrite them in-place to match the doc style b)
> create/amend ratified decisions c) maybe decide on oneshot design details . d) one of those is
> closed by the doc update -- still separate step.
>
> a+b are operational needs so could be prefixed with OP and do not require parent reference.
> implementation and design of those fixes are FEAT prefix in the roadmap.

**(2) On starting the OP work:**

> OP part can be started now -- it derives decisions from my input and documents them with
> rationale, then. restyling debt entries and rederiving them from written decisions is mechanical

**(3) The three adjustments:**

> a) oneshot *was* legitimately asked by developer of "serial" API and also preceded the feature --
> these two facts together justify it completely. beyond that, oneshot provides DevX ergonomics:
> project not focused on user input can ask user-facing question in just one line
> (oneshot+promt+on_text_entered) with zero boilerplate
>
> b) ensure we have roadmap steps to amend dev-facing documentation about new flag (oneshot) and
> when to choose on_text_entered vs after_submit (developer can choose either or both, but
> recommendation is to use on_text_entered for text-centric operations, and after_submit for generic
> machinery -- not enforced, but supposedly useful for clarity and boilerplate reduction)
>
> c) on namespacing I am not sure -- developer of serial API suggested one-line in Decision 7, you've
> mastered Decision 38... I would make it *not* decision but suggested design practice in some
> dev-facing doc -- generic not only input-focused

## Specific things to test, beyond a general read

- **The Russian entry.** Compare `git show b6456d61` word by word against the retired
  `T-NAMESPACE-CLONE` entry in `doc/development/technical_debt/general.md` and against the new
  section in `doc/development/conventions/architecture_principles.md`. Was any claim added that the
  owner did not make, or dropped that they did? The owner's *"Может, стоит строки в доке рядом с
  Decision 7"* is a **tentative suggestion of a one-liner** — measure what was built against that.
- **Instruction (3c) said "suggested design practice in some dev-facing doc".** Check what actually
  landed against the size of that request.
- **`oneshot`'s justification** was rewritten after correction (3a). Does the current Decision 36
  say what the owner said, or does it still argue the session's own earlier case underneath?
- **Decision 37** derives from `T-PLAINTEXT-ENTERED`. The owner's entry proposes a convention and
  is explicit it is *"recommended convention, not enforced"*. Check that survived, and that no
  enforcement crept in.
- **Roadmap rows.** The owner asked for specific things — an ACTIVE entry and a roadmap task for the
  documentation case; a BACKLOG entry for examples-untested; an ACTIVE entry and a roadmap step for
  maze; `OP`/`FEAT` prefixes; two documentation rows. Check each landed as asked and **that nothing
  extra was invented alongside it**.
- **Verify factual claims made in the new documents against the code.** Several assert things about
  the submit chain, the tier order, reservations and the sandbox clone. Any that is wrong is a
  finding regardless of the four questions.

## Boundaries

- **Do not read** `implementation/sessions/session56/track.md` or the session's chat summaries —
  they carry the session's own account of its work, which is what you are auditing.
- Reading the ledgers, the decisions file, `doc/input_api.md`, the conventions docs, `src/` and
  `tests/` is expected.
- `agents/rules/ledgers.md` and `agents/rules/roadmap.md` are the house rules for the register and
  the roadmap; `agents/rules/commenting.md` governs code comments. Judge house-style conformance
  against those, not against your own preferences.
- **Make no edits.** This is a review. Write findings; do not fix them.

## Tooling

- **`lua-lsp` MCP server** — defs / refs / diagnostics over a real AST of `/repo`. Use it to verify
  any claim about where a function lives or who calls it, rather than trusting a document's word or
  a grep's first hit. (`sleep 1` after any `.lua` write before querying; you should not be writing.)
- `busted tests` from `/repo` runs the suite (mock_love, no display). Baseline **1011 / 0 / 0 / 10**.
- `git show <sha>`, `git log`, `git diff a8e25bf3..HEAD -- <path>` are your primary instruments.

## Deliverable

Write to `/repo/doc/development/wip/77-new-input-api/validation/outcomes/session56-input-work-cold-review.md`:

- findings organised by the four questions (lost / distorted / misinterpreted / bloated), each with
  **file:line or commit sha** evidence and a one-line statement of what the owner said versus what
  was written;
- a short section listing what you checked and found **clean**, so the owner knows the coverage;
- a verdict: **SOUND**, **SOUND WITH CORRECTIONS**, or **NEEDS REWORK**, with the corrections named.

Do not pad. A finding with evidence beats a paragraph of impression, and "bloated beyond necessity"
is a charge you should be willing to make against your own report.
