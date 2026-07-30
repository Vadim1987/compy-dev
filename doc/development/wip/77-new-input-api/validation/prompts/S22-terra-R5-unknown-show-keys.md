# S22 Terra task — R5 unknown `show` keys

## Objective

Make the project-facing `compy.input.show(config)` surface warn and
ignore keys outside its accepted configuration table.

## Contract to characterize first

- Accepted show keys remain usable without a warning.
- Unknown keys, including retired `eval` and `result`, warn and do not
  alter widget behaviour.
- Callbacks that are only installed through `compy.input.callbacks`
  (for example `after_submit`) also warn when supplied to `show`.
- The warning names the rejected key and points callers to the show
  table or callback surface.

## Boundaries

Exercise the real project namespace and widget lifecycle.  Do not add
compatibility aliases, alter pointer routing, or change direct callback
assignment.  Keep Lua code within the project style limits.  Record
the evidence and test command in a matching outcome note.
