# S22 Terra C1 authority/provenance sweep — prompt of record

Independently inspect the persistent #77 documentation corpus against the
current committed implementation and the post-session owner rulings. This is
an evidence-only cold audit: do not edit product code or persistent docs, and
do not commit.

Inspect `doc/input_api.md`, `doc/development/decisions/input.md`,
`doc/development/internals/user_input.md`,
`doc/development/technical_debt/input.md`,
`doc/development/technical_debt/general.md`, `doc/development/tests.md`,
`CHANGELOG.md`, and persistent example narratives. Use `git log` and the
actual source/tests to establish facts; do not rely on earlier agent claims.
Do not edit the frozen `wip/77/design/` input.

Check the shipping contract specifically: `highlighter`, `validator`, and
`on_text_entered` take line arrays; the project helpers are
`LuaHighlighter`, `LuaSyntaxValidator`, and `LineValidators`; `eval` and
`result` are retired; unknown `show` keys warn and are ignored.

Write a detailed, severity-ranked outcome to
`validation/outcomes/S22-terra-C1-authority-sweep.md`. Identify every
persistent claim that is stale, ambiguous, lacks authority/status, or relies
on `wip`; identify in-flight decisions needing canonical marking; propose
exact minimal corrections; and conclude whether the persistent corpus stands
alone for stakeholder TF2. No Lua edit is expected; if inspecting Lua symbol
facts, use grep to locate it then the available Lua LSP where possible.
