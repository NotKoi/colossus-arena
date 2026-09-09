local E = if script then require(script.Parent.EconomyDefs) else require("./EconomyDefs")
local LootMath = {}
function LootMath.Calculate(damage, maxHP, rank, killed, pool)
 if maxHP <= 0 or damage <= 0 or damage ~= damage then return 0, 0, 0 end
 local share = math.clamp(damage / maxHP, 0, 1)
 local multiplier = E.RankMultipliers[rank] or E.DefaultRankMultiplier
 local coins = math.floor(math.max(0, pool) * share * multiplier * (killed and 1 or E.TimeoutMultiplier))
 local chance = 0
 if share >= E.RareMinimumShare then
  chance = math.min(E.RareMaximumChance, E.RareBaseChance + (share - E.RareMinimumShare) * E.RareShareSlope)
 end
 return coins, share, chance
end
return LootMath
