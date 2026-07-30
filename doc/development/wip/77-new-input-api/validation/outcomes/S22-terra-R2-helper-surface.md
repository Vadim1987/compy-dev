# S22 R2 — helper-surface recommendation

## Scope and verdict

This is an inspection-only recommendation for the owner-ratified R2
correction in `validation/notes/S22-R2-input-contract-plan.md`. No
production code, public API, examples, or existing documentation was edited.

Recommend three globals in the project environment, all based on the
widget-native `string[]` representation:

```lua
LuaHighlighter(lines)          --> SyntaxColoring
LuaSyntaxValidator(lines)      --> true | false, Error[]
LineValidators(filters)        --> function(lines) -> true | false, Error[]
```

`filters` accepts the existing legacy shape: one
`function(line) -> true | false, string|Error`, or an array of those
functions. On failure, `LineValidators` applies every filter to every
line, wraps string errors as `Error`, and supplies the current 1-based
line number if an error has none. Returning `Error[]` makes positioned
multi-error rejection explicit and matches model error storage; the
controller must pass that array through, rather than wrapping it once
more. `LuaSyntaxValidator` returns either `true` or the parser's
positioned `Error` in a one-element array. These PascalCase names fit
the shipped convenience globals (`InputEvalLua`, `ValidatedTextEval`)
while saying exactly what each callable produces. `LineValidators` is
plural because it deliberately preserves the old function-or-list
filter convention.

The set is intentionally small: project authors set
`highlighter = LuaHighlighter` and/or `validator = LuaSyntaxValidator`
or `LineValidators({...})`; no evaluator object or `eval` show key is
needed. The highlighter is display-only. The validator and
`on_text_entered` each receive the same line array, without a
`string.unlines` conversion.

## Existing implementation facts

- `src/model/interpreter/eval/evaluator.lua:20-44` already implements
  the required per-line loop, error wrapping, and missing-line-number
  fill; it is private inside evaluator machinery. `Filters.validators_only`
  (`src/model/interpreter/eval/filter.lua:25-39`) already normalizes a
  single filter or list. Extract/reuse that logic behind `LineValidators`,
  rather than duplicating it in examples or retaining `ValidatedTextEval`.
- The Lua parser factory exposes `parse` and `highlighter` in
  `src/model/lang/lua/parser.lua:272-304,458-464`; the evaluator owns the
  shared parser in `src/model/interpreter/eval/evaluator.lua:132-143`.
  `LuaHighlighter` can directly delegate to that parser highlighter;
  `LuaSyntaxValidator` can call its parser and normalize a failed result
  to `Error[]`.
- Project helpers presently leak into the sandbox because
  `ConsoleController.new` clones `getfenv()` (`src/controller/consoleController.lua:38-41`)
  after evaluator globals have been loaded. `prepare_project_env`
  starts from that clone (`:813-819`) and clones it into base/project
  environments (`:900-903`). This is implicit, not an intentional export
  mechanism. R2 should install the three names explicitly in
  `prepare_project_env` (or a dedicated small public-helper table copied
  there), so documentation and source agree on the export boundary.
- The overlay starts with `InputEvalText` at `src/main.lua:374-375`.
  `apply_config` currently accepts `cfg.eval`, mutates the evaluator's
  `highlighter`, and stores `cfg.result`
  (`src/controller/userInputController.lua:241-264`). Submission joins
  `InputText` to a string before the validator, result sink, and
  callbacks (`:426-465`). That is the exact divergence from R2.
- The only live `result` implementation sites are the constructor field
  (`userInputController.lua:21-54`), `apply_config` (`:251-257`),
  `deliver` (`:426-429`), controller teardown
  (`src/controller/controller.lua:332-339`), and the fixture reset
  (`tests/helpers/input_fixture.lua:325`). A source sweep found no
  caller that supplies `show{result=...}`.

## Minimal implementation impact

1. Add the explicit helpers close to the existing evaluator/parser
   primitives, retaining console/editor evaluator construction as an
   internal concern. Export only the three project conveniences from
   `src/controller/consoleController.lua`'s project-environment setup.
2. In `src/controller/userInputController.lua`, remove the `result`
   constructor/config/delivery route and reject/remove `eval` from
   project `show` configuration. Keep internal `set_eval` for console
   and editor callers (`src/controller/editorController.lua:55,74,76`;
   `src/model/consoleModel.lua:15`).
3. Change `submit_flow` to obtain the model's lines and call, in order,
   `validator(lines)`, `on_text_entered(lines)`, then
   `after_submit(lines)`. On rejection set the returned `Error[]`, do
   not deliver callbacks, and retain editability with the displayed
   error. This removes the current string-only `gate`/`deliver` seam.
4. Preserve `UserInputModel` error positioning. Its evaluator path
   (`src/model/input/userInputModel.lua:865-893`) is still needed by
   console/editor; overlay submit must not force an evaluator just to
   validate lines.
5. Migrate the only evaluator-using shipped overlay examples:
   `src/examples/guess/main.lua:53-71`,
   `src/examples/valid/main.lua:77-88`, and
   `src/examples/tixy/main.lua:177-216`. The first two become
   `validator = LineValidators(...)`; tixy becomes
   `highlighter = LuaHighlighter, validator = LuaSyntaxValidator`.
   Their `on_text_entered` callbacks already expect lines in tixy but
   guess/valid must stop assuming joined strings.

Documentation sweep: update the stale evaluator/result statements in
`doc/input_api.md:71-73,181-240,358,399-400,418` and
`doc/development/internals/user_input.md:13,72,600-625`; then cover the
removal in the R2-required decisions, migration, release notes, and test
map. Do not alter the frozen `design/` directory.

## Test-first sequence

Use the real project route fixture in `tests/helpers/input_fixture.lua`
(`F.activate_project`, `F.session.press`, `F.session.type`) and add
public-path rows alongside `tests/input/input_widgets_callbacks_spec.lua`:

1. A plain overlay submits a `{'a', 'b'}` line array to
   `on_text_entered`; verify `after_submit` receives the same shape and
   ordered callbacks are validator → entered → after.
2. `LineValidators` adapts legacy single-line validators across two
   lines, returning a positioned `Error[]`; a rejecting submit invokes
   neither output callback and leaves the widget editable/error-visible.
3. `LuaSyntaxValidator` rejects invalid multi-line Lua with a positioned
   error through the same real Enter path; valid Lua reaches the callback
   unchanged as lines.
4. `LuaHighlighter` remains visible through `show{highlighter=...}`;
   retain/extend the model regression coverage in
   `tests/input/highlight_regression_spec.lua` for the no-nil-highlight
   invariant.
5. Add negative public-contract rows: `eval` cannot select an evaluator
   and legacy `result` receives no delivery. Update/remove existing
   assumptions in `tests/input/input_reconfigure_spec.lua` and
   `tests/input/input_route_lifecycle_spec.lua`; remove the fixture's
   dead `widget.result` reset only with the production removal.
6. Keep evaluator unit coverage in `tests/input/input_spec.lua` and add
   focused helper tests if the helpers are factored to a module; then run
   the focused input files and `busted tests`.

## Tooling note

Grep was used for discovery and the impact backstop. `lua-lsp` is not
exposed in this session: the enabled tool list contains no Lua
definition/reference/diagnostic endpoint. No Lua file was edited, so no
LSP re-index wait was applicable.
