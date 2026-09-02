---
description: What the diagrams in this directory are — design-era sketches, kept as a record of intent rather than maintained as a description of the code
status: active
audience: developer
authored: llm
reviewed: none
---

# The diagrams in this directory are historical

**Read them as a record of what the design was reaching for, not as a description of the code.**
Every `.md` beside this one is a sketch from the project's design era. Four were added
2024-07-29 and three — `eval.md`, `input.md`, `scratch.md` — on 2024-12-18, in a commit called
*"unfinished docs"*. They were last meaningfully updated 2025-01-13; the only change since is one
field rename in 2025-10-15. They were never maintained against the code, and by now most of what they draw is
gone.

## Why they are marked rather than corrected or deleted

Three reasons, in order of weight.

1. **They are the clearest surviving record of intent.** A design sketch that was never updated
   says what somebody meant to build. Set beside the code, it shows where the implementation went
   somewhere else — which is a question worth being able to ask, and one nothing else in this
   corpus answers. `eval.md` is the sharpest example: the section headed *"Current"* describes an
   `EvalBase` class hierarchy **that was never built**, while the section headed *"Planned
   refactor"* is the closer of the two to what shipped. Correcting that file would delete the
   evidence that the plan and the build diverged.
2. **Corrected, they would be a maintenance burden nobody signed up for.** Nothing tests a
   diagram. A diagram that claims to be current and is not is worse than one that says it is old,
   and the way this directory got here is that the first kind was created and then not fed.
3. **They are not a description that anything depends on.** No code, test or document reads them.

## What is actually in them, as of 2026-09-02

A field-by-field audit ran over all seven files — 32 class blocks, every member resolved against
the source. In summary:

- **Whole classes that no longer exist** are still drawn, with fields and relationship arrows:
  `InputModel`, `InterpreterModel`, `InterpreterController`, `InputController`, `InputView`,
  `InterpreterView`, `EvalBase`, `EditorInterpreter`.
- `input.md` is headed *"Planned refactor"* and is explicitly a proposal, not a record.
- `eval.md`, `input.md` and `scratch.md` were committed under the message *"unfinished docs"*.
- `fsm.md` and `fsm_f.md` carry no class blocks; they are state diagrams, and they too predate
  several states the code now has.
- The blocks that hold up best are `editor.md`'s `UserInputModel` and `BufferModel`, which were
  the most recently written.

## The one thing that was changed, and why only that one

The input-API feature removed `oneshot` from `UserInputModel`, and `editor.md` still drew it. That
line — and only that line — was a statement **this feature made false**, so it is corrected rather
than left standing behind a historical marker; a marker excuses inherited drift, not drift you
caused yourself.

Everything else was checked against the pre-feature baseline and found identical there. The
diagrams' other errors predate the feature by a long way, and are the original author's to keep
or discard.
