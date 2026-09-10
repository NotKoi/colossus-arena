local map = require(script.Parent.MapBuilder).Build()
require(script.Parent.Remotes).Start()
require(script.Parent.BaseAssignment).Start()
local Boss = require(script.Parent.BossController)
local Emberhorn = require(script.Parent.Emberhorn)
local Glacius = require(script.Parent.Glacius)
Boss.BuildModel = function(b) if b.id == "Emberhorn" then Emberhorn.Build(b) else Glacius.Build(b) end end
Boss.RunAbilities = function(b) if b.id == "Emberhorn" then Emberhorn.Run(b, Boss) else Glacius.Run(b, Boss) end end
Boss.OnDamaged = function(b) if b.id == "Glacius" then Glacius.OnDamaged(b, Boss) end end
local Data = require(script.Parent.DataService)
Data.Start()
require(script.Parent.LootService).Start(Boss)
local Combat = require(script.Parent.CombatService)
Combat.Start(Boss, Data.Get)
require(script.Parent.ShopService).Start(Combat)
Boss.Start()
print("Colossus Arena: shop and inventory ready", #map.Bases:GetChildren())
