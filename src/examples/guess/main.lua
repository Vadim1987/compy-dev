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

-- Continuous-session idiom (validation/reviews/delta-spec-input-api.md
-- §3, R4-U4 example migration): the widget stays open by default now
-- (no auto-close), so there is nothing to re-show after submit — just
-- clear the field for the next guess. The line validator keeps invalid
-- guesses out of the submit callback. Cancel's own default (clear +
-- stay shown) already re-arms the prompt, so no after_cancel callback
-- is needed.
compy.input.callbacks.after_submit = function()
  compy.input.clear()
end

init()

-- TODO: guess is input-only/live now (project_open ruling
-- a); rework check()'s print() feedback to go through the
-- on-screen input API / draw instead of the console terminal.
compy.input.show{
  prompt = "Guess a number:",
  validator = LineValidators({ is_natural }),
  on_text_entered = function(lines) check(tonumber(lines[1])) end,
}
