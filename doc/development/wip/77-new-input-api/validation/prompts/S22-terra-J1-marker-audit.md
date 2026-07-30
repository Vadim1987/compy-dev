# S22 Terra prompt — J1 persistent-marker audit

Perform a bounded, evidence-only audit; make no production, test, or
documentation edits and make no commits. Inspect only tracked persistent
`src/`, `tests/`, and `doc/` files, excluding `doc/development/wip/`.

Find `{jargon:...}`, `{badspecref:...}`, and `REVIEW`/`DOC` construction
markers. Produce a prioritized, file-grouped minimal cleanup plan. Separate
mechanical plain-language and named-reference work from questions that need a
durable technical-debt home. Do not treat frozen WIP material as authority or
broaden into redesign. Lua LSP is available for concrete source facts; use grep
to find candidates and LSP when a symbol fact is needed.

Write the outcome to
`validation/outcomes/S22-terra-J1-marker-audit.md`.
