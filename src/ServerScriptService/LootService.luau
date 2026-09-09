local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Math = require(RS.Modules.LootMath)
local Data = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)
local rng = Random.new()
local LootService = {}
function LootService.Payout(b, killed)
 if b.paid then return end
 b.paid = true
 local rows = {}
 for userId, damage in b.damage do
  table.insert(rows, {userId=userId, name=b.names[userId] or tostring(userId), damage=damage})
 end
 table.sort(rows, function(a,b)
  return a.damage > b.damage or (a.damage == b.damage and a.userId < b.userId)
 end)
 for rank, row in rows do
  local coins, share, chance = Math.Calculate(row.damage, b.maxHP, rank, killed, b.def.CoinPool)
  row.coins, row.share = coins, share
  local player = Players:GetPlayerByUserId(row.userId)
  row.awarded = player ~= nil and Data.Get(player) ~= nil
  if row.awarded then
   Data.AddCoins(player, coins)
   if chance > 0 and #b.def.Drops > 0 and rng:NextNumber() < chance then
    local itemId = b.def.Drops[rng:NextInteger(1, #b.def.Drops)]
    Data.Grant(player, itemId)
    Remotes.RareDrop:FireAllClients(row.name, itemId, row.userId)
   end
  end
 end
 Remotes.Results:FireAllClients(rows, killed)
end
function LootService.Start(Boss) Boss.OnPayout = LootService.Payout end
return LootService
