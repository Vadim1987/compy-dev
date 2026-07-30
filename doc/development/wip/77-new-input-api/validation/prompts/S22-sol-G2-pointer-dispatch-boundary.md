# S22 Sol consultation -- G2 pointer-dispatch boundary

## Question

Feature #77 has a project keyboard/text route with the ordered consumers:
shortcuts, hooks, then shown text widget. Derived pointer notifications are
currently different: a click timer later calls project aliases
compy.singleclick or compy.doubleclick directly.

The owner has tentatively ruled that those aliases should seed structural
compy.input.hooks.singleclick/doubleclick when the hook is unset. Before
execution, assess whether G2 should stop there or extend the existing dispatch
model to derived clicks without a widget consumer.

## Evidence to inspect

- src/controller/controller.lua: click accounting, timer, liveness, delivery.
- src/controller/projectInputController.lua: keyboard/text dispatch and seed.
- src/examples/paint/main.lua and src/examples/sapper/main.lua.
- src/controller/userInputController.lua pointer methods, editor selection,
  and any drag/touch paths that must remain unchanged.
- doc/development/internals/user_input.md pointer sections.

## Required judgment

Recommend one bounded choice and explain its consequences:

1. Alias-to-hook installation only; delayed delivery remains a pointer-local
   mechanism reading hooks directly.
2. A narrow reusable hook-dispatch helper for derived clicks, explicitly no
   shortcuts and no widget consumer.
3. Extend the full three-consumer dispatch to pointer events.

Assess M1 versus M2 (or the actual button information), modifiers such as
Alt+M1, dragging/selection/touch preservation, event timing, and the risk of
inventing a general pointer abstraction not requested by stakeholders.

Do not edit production or persistent docs. Use Lua LSP for concrete symbol
facts when available, with grep as a backstop. Write the outcome verbatim to
validation/outcomes/S22-sol-G2-pointer-dispatch-boundary.md, then report a
concise recommendation. No commit.
