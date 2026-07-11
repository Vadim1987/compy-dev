-- Continuous-session idiom (M8-01): consume the line in
-- on_text_entered, re-show (bare) from after_submit.
compy.input.after_submit = function()
  compy.input.show{}
end

compy.input.show{
  on_text_entered = function(text) print(text) end,
}
