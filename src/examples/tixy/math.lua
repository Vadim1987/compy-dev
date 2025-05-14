--- import math namespace into global
for k, v in pairs(math) do
  _G[k] = v
end

function hypot(a, b)
  return math.sqrt(a ^ 2 + b ^ 2)
end
