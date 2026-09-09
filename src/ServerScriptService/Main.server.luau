local map = require(script.Parent.MapBuilder).Build()
require(script.Parent.Remotes).Start()
require(script.Parent.BaseAssignment).Start()
local Boss = require(script.Parent.BossController)
local Emberhorn = require(script.Parent.Emberhorn)
local Glacius = require(script.Parent.Glacius)
Boss.BuildModel = function(b) if b.id == "Emberhorn" then Emberhorn.Build(b) else Glacius.Build(b) end end
Boss.RunAbilities = function(b) if b.id == "Emberhorn" then Emberhorn.Run(b, Boss) else Glacius.Run(b, Boss) end end
Boss.OnDamaged = function(b) if b.id == "Glacius" then Glacius.OnDamaged(b, Boss) end end
if game:GetService("RunService"):IsStudio() and workspace:GetAttribute("ManualBossTests") then Boss.RunAbilities = nil end
require(script.Parent.CombatService).Start(Boss)
Boss.Start()
print("Colossus Arena: both bosses ready", #map.Bases:GetChildren())
