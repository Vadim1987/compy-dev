# S42 — P13 `love_key` limit correction outcome

Implemented a minimal extraction in `src/harmony/init.lua`:

- `love_chord` retains chord press/release ordering.
- `love_keypress` retains ordinary-key emission.
- `release_modifiers` retains reverse modifier release.

The public `love_key` API, modifier held-state timing, `patch_isDown`, and
scenario behaviour are unchanged. All extracted functions are within the
14-line limit.

Validation: `busted tests/harmony_input_spec.lua` — 1 success, 0 failures,
0 errors, 0 pending.

The Lua MCP-LSP bridge was not exposed in this session; source inspection and
the focused production-path test were used instead. No commit was made.
