-- Continuous-session idiom (validation/reviews/delta-spec-input-api.md
-- §3, R4-U4 example migration): consume the line in on_text_entered;
-- the widget stays open by default now, so after_submit just clears
-- the field for the next line instead of re-showing.
compy.input.callbacks.after_submit = function()
  compy.input.clear()
end

compy.input.show{
  on_text_entered = function(text) print(text) end,
}
