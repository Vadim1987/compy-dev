We're in validation phase -- design converged, code landed, tests are green. But now we are cleaning up and testing the design/implementation against original intent and clarity/stability/accuracy considerations.

Naive attempts to review code, sprawl 'REVIEW' and 'badrefspec/jargon' remarks and process them with some ad-hoc planning, lead to several consequences:
1) concerns of different altitude mixed altogether
2) lots of tokens burned in attempts to naively fix stuff in-place
3) it was revealed that some decisions not necessary optimal and not necessary best in implementation of stakeholder intents were smuggled in and rubber-stamped at design/spec phase. this is repeatable partial-failure mode
4) now we have another corrective plan produced, which again suggests to make more than dozen of decisions/rulings -- in different contexts, sometimes with weird language, sometimes self-justifying against rubber-stamped fillers which are now canonicalized


So, my suggestion is

1) Fix formal information integrity -- ensure comments in test and code reference final persistent documentation with named sections, not intermediary drafts and milestone marks
2) temporary mitigate 'jargon' problem by explaining all jargon in the top of the file -- literally introducing terminology in the opening comments section
3) Ensure that tests are testing what they claim -- eliminate any 'step-by-step reproducing of framework methods' instead of using real methods, etc. Ensure tests still hold together
4) Ensure that solution delivered (tests and docs) still holds against design and original stakeholder intent -- i.e. satisfies the requirements and does not violate them
5) critically reassess the implementation -- were the best (most simple/clear/robust) solutions chosen? do they increase system stability/clarity or decrease it? are there better variants? could this better variants be applied as focused fixes/refactoring over existing prototype implementation? NOTE: consider persistent docs as the part of the feature outcome, and intermittent docs (doc/development/wip/77-new-input-api/), in particular, its './design' subdirectory as the *source* of information regarding stakeholder intents, decision-making and implementation history. The directory with 'wip' will *not* be part of the final PR, it will be gone as intermittent/ephemeral.
6) discuss any 'architecture strengthening/clarifying' rulings -- in informed, step-by-step interaction, with ability to ask extra questions. no rubber-stamping, no jargon smuggled.
7) plan final brush-up steps and spec
8) run through this plan
9) reevaluate solution once again against both original stakeholder intent and meta-requirements (clarity, stability, robustness, minimalism)
10) greenlight the PR, assemble it according to ../implementatio/prompts/pr-assembly-guide.md


Why this way?

Currently suggested list of rulings is overwhelming -- I aim to move to higher levels of abstraction and make a smaller number of well-justified informed decisions which would dissolve most open concerns by providing clear justifications and guidelines for lower-level choices.


Current workflow

1. Governed by agents/pr-prep.md
2. current session points to doc/development/implementation/sessions/session10/prompt.md 
3. We respect this workflow and prompt in their *mechanics*, but alter the *goals* a bit
4. The text above expresses my concerns and suggest a pivot to the plan suggested in current prompt, to address existing mix of concerns in more structured, modular, layered way -- protecting decisions quality and avoiding rubber-stamping chaos

