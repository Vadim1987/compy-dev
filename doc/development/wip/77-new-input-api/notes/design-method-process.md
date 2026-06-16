it was ad-hoc and preceded SDLC. now we need to re-design it around existing artifaccts, possibly as submethod under SDLC or a variation o top of it.

quick mapping (artifact role)

input.md -> goes under notes/ it was supposed to be immutable raw input -- now all notes are immutable inputs, so all good
input/ notes/ -- all the same... 
prompts -- that's the very first ad-hoc implementation of progressive prompts (which then became a part of brainlab) -> worth moving under sessions as session00 (beware: different git repo) or archiving

assessment.md -- artifact of brainstorming but may be kept as context.md
  assessment.md -> context.md (can be renamed) -- frozen, state of system before requirements

decisions.md -- surfaced tension points and resolutions -- should normally be split into inputs (under notes/) and decisions which become part of design
requirements.md -> should be split to requirements.md and constraints.md, both sourced from inputs (requirements are what is requested, constraints are what is prohibited) ! BOTH MUST BE VERSIONED, current state becomes first version (costrints.md empty, requirements.md overfilled), split becomes second

design.md -- coherent resolution (bridges requirements+context+constraints)
scope.md -- this part is missing -- effectively shapes milesones, slicing design into functionally decoupled pieces that form dependency graph
spec.md -- detalization of design to the implementation-shaping level (must be kept coherent internally, could be split per milestone or scope item) -- but still high-level spec should better exist to brieget them all explicitly . Preferrable form: spec.md + spec/<scope-part>.md -- and all those versioned
roadmap.md -- scope turns into ordered milestones, with estimations

summaries -> set of docs for stakeholders approval. SHOULD BE REPLACED: instead, each primary artifact must strat with human-friendly summary before going into details

reevaluations -- attempt to track everything regarding reevaluation rounds. keep now as historical artifact, consider turning into single versioned document
validation  -- another flavour of same idea, reviewable evaluation of changes propagation
goal.md (now missing) -- the goal of current process (derived from inputs -- frames further requirements/constraints/design) -- rather formal artifact but better be 
remarks.md (now missing) -> a sink for inputs which are neither requirement nor constraint


================================
DESIRED FLOW (RESTORES EDGE-VALIDATABLE GRAPH)


goal.md (canonical goal: in this case how statted in the initial ticket)
context.md (purely from system state, with a focus on goal)
(requirements, constraints, remarks) <- all sourced from the inputs

design.md [versioned] <- primary design document, co-editable, may include sub-docs (design/{subdesignA, subdesignB}.md)

spec.md [versioned] <- co-editable, splittable (MUST be split into detailed spec for milestones)

roadmap[versioned] <- plan with estimations (may include intermittend milestones)


status.md <- primary reevaluation artifact, versioned. Must include:
  contradictions
  what is blocked
  if any artifact in chain is converged
  if chain at all is converged


And then reevaluation loop is simple:

chain update propagates:
  inputs > (requirements|constraints|remarks) -> design -> [scopes?] -> (spec + roadmap)
revalidator updates status.md, inspects all the chain parts according to evaluation logic rules from SDLC

Human operator repeats process until all in 'status' converges
  status also holds open decisions to be made, contradictions to resolve etc.

the spec is outcome for the milestones/sprints
outputs are spec and roadmap

sprints take spec outputs as their inputs (context/goal/requierments/constraints) and follow normal SDLC
