# session28 — observations

Self-assessment, outside the workflow. Not a source of project fact; the report
is. Kept because session27's equivalent was worth reading.

## Three failures worth naming

**1. I built a mechanism to satisfy an ideal.** The owner's ruling on the click
fix said the widget "should have a noop that *ideally* does not consume" and
that an unconsumed event "should not trigger any error". I read the parenthesis
as the requirement and shipped a decline protocol — a sentinel return value only
one caller produces, plus a branch in the dispatcher — inside a fix that had been
approved without it. The owner's response was blunt and correct. The check I now
have: when a ruling contains an ideal and a requirement, implement the
requirement and *ask* about the ideal, because the ideal is the part that
tempts machinery.

**2. I proposed a fix that the platform's own doc forbids.** For SM5 I nearly
took the sub-agent's proposal, which relied on `keypressed` arriving before
`textinput` — the exact assumption that caused the bug, mirrored. Caught it only
because I had just read "no ordering guarantee" in `internals/user_input.md`
while writing about something else. A proposed fix inherits the bug's own
premise more often than it feels like it should.

**3. I destroyed my own uncommitted work.** Ran a mutation check with
`git checkout -- <file>` while the fix under test was uncommitted, and discarded
it. Noticed within a minute, but only because a follow-up grep came back empty.

## Two things that worked and are worth repeating

**The owner's process for the merge.** Inventory every case, write the plan, cold
review *before* moving anything, execute, cold review again. It felt heavy for a
test reorganisation and it was not: the pre-move review caught a deletion that
would have dropped an assertion and an arithmetic self-contradiction that would
have misdirected execution. Both were mine.

**Verifying beyond the obvious signal.** A green suite would have survived a
silently rewritten row, so the merge was checked by comparing all row titles and
all assertion lines against the originals. That found nothing — and then the
`#lifecycle` tag turned out to be lost anyway, because it is neither a title nor
an assertion. The lesson is not "check harder", it is that **every verification
has a shape, and things outside that shape pass through it invisibly.** The
question to ask of any check is what it cannot see.

## On the sub-agents

Five spawned, all Sonnet, all with prompts and deliverables on disk. The two cold
reviews were the highest-value ones by a distance. The inventory agent's
paren-depth-aware row parser was better than my grep, and it said so; the
mutation-check agent reported a PIN verdict it could have dressed up as a pass.
Both behaved well when the honest answer was the inconvenient one, which is
mostly a function of the prompt saying so explicitly.
