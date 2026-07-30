# S22 Terra prompt — J1 test cleanup

Perform the tests-only J1 persistent-marker cleanup in tracked
`tests/input/*.lua` and `tests/helpers/input_fixture.lua`. Remove
construction-era `{jargon:...}`, `{badspecref:...}`, `REVIEW`/`DOC` markers,
and WIP or milestone citations. Preserve asserted behaviour and use plain
present-tense explanation or permanent named documentation where useful.

Do not alter production source, test assertions, or the tracked swap file.
Remove D4-superseded fixture questions. Record an exact outcome, run focused
and full `busted tests`, check the diff, and commit the isolated wording
change only while green. Lua LSP is available for concrete Lua facts; grep
first, then LSP for symbols, with a one-second pause after Lua edits.
