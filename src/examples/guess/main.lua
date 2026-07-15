math.randomseed(os.time())
N = 100
-- number_to_guess
ntg = 0

function init()
  print("Welcome to the guessing game!")
  ntg = math.random(N)
end

function is_natural(s)
  local n = tonumber(s)
  if not n then
    return false, "NaN"
  end
  if n <= 0 then
    return false, "Not a positive number!"
  end
  if math.floor(n) ~= n then
    return false, "Not an integer!"
  end
  return true
end

function is_natural(s)
  local digits = string.usub(s, 1)
  local ok, err_c = string.forall(digits, Char.is_digit)
  if ok then
    return true
  end
  return false, Error("The guess should be a positive number", err_c)
end

function check(n)
  if not n then
    return
  end
  if ntg < n then
    print("The number is lower")
  elseif n < ntg then
    print("The number is higher")
  else
    print("Correct!")
    print("\n\n")
    init()
  end
end

-- Continuous-session idiom (M8-01): consume the guess in
-- on_text_entered, re-show (bare) from after_submit. eval
-- reuses the legacy validated_input->ValidatedTextEval path
-- (least new logic); wires the effective (L26) is_natural —
-- the L12 duplicate is pre-existing shadowing, not touched.
compy.input.after_submit = function()
  compy.input.show{}
end

-- ESC cancels the widget; re-arm it so the prompt can't be
-- dismissed with no way to guess again.
compy.input.after_cancel = function()
  compy.input.show{}
end

init()

compy.input.show{
  prompt = "Guess a number:",
  eval = ValidatedTextEval({ is_natural }),
  on_text_entered = function(t) check(tonumber(t)) end,
}
