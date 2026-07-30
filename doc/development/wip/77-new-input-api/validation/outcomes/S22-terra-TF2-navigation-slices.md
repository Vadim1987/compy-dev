# S22 Terra — TF2 navigation slices outcome

## Scope

Generated the owner-approved review-navigation batch, not final Phase-G PR
assembly. Source was `BASE=3256aac` to committed tip
`7b9920c1ab525615db93680290ca0295e6395264`. Nested example repositories and
owner scratch were not read or captured.

## Guide correction

The guide's `OUT=./pr-slices` was stale. It now writes to the tracked
`doc/development/wip/77-new-input-api/implementation/pr-slices/` directory.
Its exhaustive pathspec contract also gained seven previously uncovered
committed paths: the event-dispatch and changelog docs, editor controller,
evaluator, two editor tests, and the already-tracked input test artifact.

## Regenerated slices

| Slice | Files | Added | Removed | Bytes |
| --- | ---: | ---: | ---: | ---: |
| 1-generic-docs | 23 | 345 | 74 | 42,129 |
| 2-agentic | 14 | 877 | 0 | 57,232 |
| 3a-routing-core | 3 | 561 | 36 | 30,514 |
| 3b-widget-surface | 3 | 790 | 149 | 41,808 |
| 3c-model-view-util | 6 | 214 | 60 | 14,792 |
| 3d-tests | 26 | 4,424 | 5 | 178,085 |
| 3e-examples-tracked | 5 | 77 | 43 | 5,792 |
| 3f-input-docs | 9 | 2,091 | 39 | 152,802 |

## Verification

- Guide §4: `OK: complete + disjoint`, 89 WIP-excluded changed files and 89
  sliced files; `diff -u /tmp/_all.txt /tmp/_sliced.txt` was empty.
- `git diff --check` for the newly authored guide and prompt was clean. A
  whole-tree check is intentionally not a gate for this generated-artifact
  commit: patch payloads faithfully contain historical whitespace from the
  baseline-to-tip diff, so checking their text reports payload lines rather
  than an artifact defect.
- `busted tests`: 862 successes, 0 failures, 0 errors, 3 intentional pending.

These files are navigation only. Regenerate them again after the tree settles
for final Phase-G assembly.
