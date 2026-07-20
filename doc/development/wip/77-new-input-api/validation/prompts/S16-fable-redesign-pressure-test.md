# S16 — Fable commission of record: redesign pressure-test

**Process deviation (owner directive, S16 boot, 2026-07-20):** Fable runs session16
in the main seat rather than being spawned as an oracle subagent — the owner wants
iterative discussion over the topic and outcomes. The commission below is therefore
executed in-session; this file is the prompt-of-record per hygiene (c).

**The commission** (verbatim scope from `implementation/sessions/session16/prompt.md`,
task 2): pressure-test `validation/notes/input-api-redesign-proposal.md` against
`validation/notes/input-api-redesign-evaluation.md`, grounded in
`doc/development/decisions/input.md` and the live code — chiefly:

1. the **Decision-6 layering seam** — is "widget owns Enter/Esc" safe *only* if the
   controller (UIC), not the model, owns detect+propagate while the parent context
   owns lifecycle?
2. the **D10 hook-unification precedence** (explicit > sandboxed-love seed > no-op);
3. the **loosened-D7 guard boundary** (freeze container, keys writable);
4. whether the **vocabulary** (handler / hook / callback / routing) is internally
   consistent and complete.

Charter rule applied: every factual claim verified in code (`projectInputController.lua`,
`userInputController.lua`, `consoleController.lua` compy.input surface,
`controller.lua` gateway + route wiring), not taken from the notes on faith.

**Verdict:** `validation/outcomes/S16-fable-redesign-pressure-test.md`.
