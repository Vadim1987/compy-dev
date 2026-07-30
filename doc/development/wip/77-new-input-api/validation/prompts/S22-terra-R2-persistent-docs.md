# S22 Terra task — persistent R2/R5 contract documentation

Update only persistent documentation for the approved project-overlay
contract. Do not edit source, examples, tests, session tracking, frozen
design inputs, or owner-owned working-tree changes. Do not commit.

The implemented contract is:

- `show` accepts `highlighter`, `validator`, and `on_text_entered`;
  `eval` and `result` are retired and have no compatibility path.
- `show` warns and ignores unknown keys, including field-write-only
  lifecycle callbacks; those callbacks belong on `compy.input.callbacks`.
- Submitted text is `string[]` for `validator`, `on_text_entered`, and
  `after_submit`. Submit order is validator, on_text_entered, after_submit.
- A validator returns true, or false plus positioned `Error[]`.
  A highlighter is display-only.
- Project helpers are `LuaHighlighter(lines)`,
  `LuaSyntaxValidator(lines)`, and `LineValidators(filters)`.

Bring the public guide, relevant internals, decisions, technical-debt
ledger, example narratives, and changelog into agreement. The public guide
must include concrete migration mappings. Persistent docs must not refer to
the wip workspace. Record an outcome with changed files and intentional
internal evaluator mentions.
