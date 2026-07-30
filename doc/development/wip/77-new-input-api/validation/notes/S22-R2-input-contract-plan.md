# S22 R2 -- input-contract correction plan

## Status

Owner-ratified direction on 2026-07-30; execution is deferred until
the remaining pre-TF2 triage is complete. This is a PR-shaping correction
chunk, not post-PR technical debt.

## Contract to implement

- Retire the legacy result reftable route. There is no compatibility
  requirement for the removed polling API.
- Retire eval as a project-facing show config key. An evaluator remains an
  internal implementation detail where console or editor needs one.
- The project overlay exposes optional highlighter and validator functions,
  plus on_text_entered. They all use the widget-native string-array-of-lines
  representation; no joined-string side path remains.
- A highlighter affects display only. A validator accepts or rejects the
  whole line array and returns structured, positioned errors on rejection.
- Submit order is validator, on_text_entered, then after_submit. Rejection
  prevents both callbacks and leaves the input editable with its error shown.
- Ship documented Lua highlighter and Lua syntax-validator conveniences, and
  an adapter that applies the existing simple line validators to every line.
  Their exact public names remain a small owner choice before coding.

## Owner boundaries

- Console retains command compilation and execution after accepting text.
- Editor retains its stricter document validator and its formatter, block
  transaction, and save workflow. Those are not project-overlay API features.
- Search owns query-on-change and selected-result acceptance; reorder remains
  widget-free. Neither expands the overlay contract.

## Execution order

1. Write public-path tests first: result no longer delivers; plain input
   accepts; a line-validator adapter rejects; Lua-invalid input rejects; Lua
   highlighting remains visible; accepted text reaches the callback as lines;
   and the ordered validator/submit/after_submit sequence holds.
2. Make the smallest controller/model change that passes those tests. Remove
   result storage and delivery, and make the overlay submit use the unified
   validator contract. Do not refactor console, editor, Search, or reorder.
3. Migrate shipped examples to highlighter/validator functions and callback
   delivery. They must no longer use eval or depend on evaluator objects.
4. Update the public guide, internals, decisions, migration section, release
   notes, and test map. Explain the line-array convention and provide both
   plain, validated, and Lua examples.
5. Run focused negative checks and the full suite; review each production and
   migration concern as a separate green commit. Then update the authority
   sweep inventory with this owner-ratified correction.

## Acceptance evidence

Tests must use the real project input route and real keystrokes/textinput.
They must prove the replacement contract, not merely inspect callback fields
or evaluator internals. A release note must explicitly call out that the
undocumented result and eval config keys were removed in favour of the
separate highlighter and validator surface.
