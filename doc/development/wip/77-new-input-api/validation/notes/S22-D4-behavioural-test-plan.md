# S22 D4 -- behavioural-test policy

## Ruling

Owner-ratified 2026-07-30: #77 tests principally prove observable external
behaviour through real framework entry points and public project surfaces.
Coverage is proportionate, not exhaustive: rare or exotic internal edges may
remain untested when they are outside critical paths.

Direct seams, mocks, or interception remain available only for a mechanism
that cannot be practically isolated through the real route. Such a test must
say why it is a unit/mechanism guard rather than a public contract test.

## Deferred execution

Review the concrete D4 fixture markers, especially partial default-handler
setup/reset and project activation. For each, either use the real available
entry point, or retain the seam with a short reason. Do not launch a general
fixture rewrite or add coverage solely for internal completeness.
