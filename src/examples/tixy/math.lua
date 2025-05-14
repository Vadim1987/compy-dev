--- import math namespace into global
for k, v in pairs(math) do
  _G[k] = v
end
