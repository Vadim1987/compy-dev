# S22 G2 -- superseded click-hooks plan

## Ruling

Superseded by the owner on 2026-07-30 after Sol consultation. No click-hook
implementation is planned for #77. Decision 16 retains the existing direct
click callbacks and records future input unification as technical debt.

## Resolution

No code, test, fixture, example, or API change. The current separation stays
because a shared registration table would create a false impression of common
dispatch semantics. Future work requires demonstrated demand and a deliberate
pointer design; it must not be smuggled into this input-API PR.
