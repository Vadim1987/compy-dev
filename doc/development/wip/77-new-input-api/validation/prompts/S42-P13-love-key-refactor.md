# S42 — P13 `love_key` limit correction

Apply a surgical, behaviour-preserving extraction in
`src/harmony/init.lua` only. The cold review found that P13 enlarged
`love_key` beyond the repository function-size rule.

Keep the existing event ordering, simulated modifier held-state timing,
`patch_isDown`, public API, and scenarios unchanged. Extract only meaningful
helpers needed to bring every new function within the 14-line limit. Do not
change tests, scenarios, or plan documents. Run
`busted tests/harmony_input_spec.lua`; do not commit.
