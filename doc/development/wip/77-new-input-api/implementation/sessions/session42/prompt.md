# session42 — execute P13 revalidation and re-check P9c

Read `agents/sessions.md`, `agents/validation.md`, and `../session41/report.md`
before work. Boot normally, create `session42/track.md`, and preserve unrelated
scratch and nested repositories. Baseline: `busted tests` → 946 / 0 / 0 / 10.

P19 is complete (`c08350e7`). Do not reopen P17/P18: their human smoke gates
remain pending. Do not choose a further sprint task after this prompt without
owner direction.

## Your task

Execute these units in order. They are expected to be evidence-led and should
not need a new owner ruling unless the current tree contradicts the plan.

1. **P13 — harmony revalidation.** Read the P13 sections of
   `validation/reviews/S27-triage-and-plan.md` and the current harmony code.
   Prove that harmony drives a real shortcut combo under the device-read
   matcher. If it does, remove the now-redundant `release_keys()` discipline
   and its commented auto-release only with breaking tests first; keep
   `patch_isDown` and the simulated held table. If the proof fails or the
   manual release has another live purpose, record the evidence and stop that
   unit rather than inventing a replacement.
2. **P9c — first re-check the premise.** Run the two named #77 test cases
   under shuffled execution enough to establish whether their order dependence
   still reproduces on the current tree. If it no longer reproduces, record
   the evidence and close P9c as overtaken. If it does reproduce, identify the
   retained state and its owner, then apply the smallest tests-first correction
   or durable documentation disposition.

Use grep to locate candidates, then Lua LSP for concrete symbols, references,
and diagnostics; sleep one second after a Lua edit before querying the server.
Use tests-first for any behavioural change, keep commits unit-sized, state the
suite count in each message, and never push. Amend the operative sprint row
and detailed step in place as each status changes.
