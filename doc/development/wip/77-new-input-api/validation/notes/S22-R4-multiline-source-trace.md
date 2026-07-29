# S22 R4 — multiline source trace

## Question

Was a `show{multiline = ...}` option requested by stakeholders, and in
what exact form?

## Verified source trail

1. The verbatim round-two stakeholder note
   (`design/notes/input/stakeholder2_notes.md`, item 5) says the vertical
   boundary is the first/last line and that left/right can be for the whole
   input or the line. The structured rendering says the same thing. Neither
   document mentions `multiline`, Shift+Enter, a configuration field, or a
   default.
2. The frozen requirements carry that stakeholder ruling forward only as
   the `on_limit_reached` line-versus-input scope contract
   (`design/requirements.md`, FR-7). It assumes a multiline edit area; it
   does not demand that projects opt into multiline editing.
3. `spec.versions/version01.md` is the first retained design record that
   names the field: ``multiline | boolean | Allow Shift+Enter newlines
   (default false)``. The current frozen `spec.md` retains the same field.
   The July 6 `design/spec redone` commit that wrote the current wording is
   authored by Hleb Rubanau; no stakeholder record attributes this choice to
   a stakeholder.
4. The old implementation already inserted a newline for Shift+Enter with
   no flag: `updev:src/controller/userInputController.lua` calls
   `input:line_feed()` whenever Shift and Enter are held. It also already
   carried the unrelated `TODO multiline` in the model.

## Result

Multiline *capability* is consistent with the stakeholder's editor-like
boundary use case and was pre-existing. The public `multiline` switch,
its default-false semantics, and Shift+Enter gating are a design-stage
promise, not a verbatim stakeholder request. R4 remains an owner choice:
implement that additional public policy or deliberately replace it with
the established always-multiline contract.
