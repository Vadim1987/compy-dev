-- Continuous-session idiom (doc/input_api.md, "Submit
-- lifecycle"): consume the text in on_text_entered;
-- the widget stays open by default now, so after_submit just clears
-- the field for the next line instead of re-showing.
compy.input.callbacks.after_submit = function()
  compy.input.clear()
end

compy.input.show{
  on_text_entered = function(text) print(text) end,
}
