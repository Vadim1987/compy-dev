# S22 Terra outcome — persistent R2/R5 contract documentation

## Completed

- Rewrote `doc/input_api.md` around the approved project contract: line-array
  submit values, validator → on_text_entered → after_submit order, display-only
  highlighting, the three project helper globals, and explicit migration rows.
- Documented unknown `show` keys as warned and ignored, including lifecycle
  callbacks that belong on `compy.input.callbacks`.
- Updated the input decision record to mark the warning behavior implemented;
  removed the now-resolved `eval`/`result` and reftable debt entries.
- Updated the internal implementation narrative, example narratives, and the
  unreleased changelog entry.

## Completeness check

Persistent-document sweep leaves evaluator names only where intentional:

- `LuaEditorEval` remains in `internals/user_input.md` and `internals/editor.md`
  as an editor-internal evaluator.
- `doc/input_api.md` names retired evaluator globals only in its migration and
  exclusion text, not as supported project configuration.

The sweep found historical mentions only under the frozen/wip archive, which
was deliberately not edited.
