local B=require(game.ServerScriptService.BossController)
local G=require(game.ServerScriptService.Glacius)
local p=game.Players:GetPlayers()[1]
B.Finish(B.Current,false);local b=B.Spawn("Glacius")
local h=p.Character:FindFirstChildOfClass("Humanoid");local root=p.Character.HumanoidRootPart
p.Character:PivotTo(CFrame.new(90,3,0));root.Anchored=true;h.MaxHealth=1000;h.Health=1000
local damage=0;local previous=h.Health
local healthConnection=h.HealthChanged:Connect(function(value) if value<previous then damage+=previous-value end;previous=value end)
local wall=Instance.new("Part");wall.Name="IcePillar";wall.Size=Vector3.new(8,30,60);wall.Position=Vector3.new(45,15,0);wall.Anchored=true;wall.Parent=b.effects
game:GetService("CollectionService"):AddTag(wall,"IcePillar")
G.Cast(b,B,"Orbs");task.wait(4)
assert(damage==0,"pillars block homing orbs")
for _,v in b.effects:GetChildren() do assert(v.Name~="HomingOrb","blocked orbs shatter") end
wall:Destroy()
G.Cast(b,B,"Orbs");task.wait(4)
assert(damage==105,"three unobstructed orbs deal35 each")
h.Health=1000;damage=0
G.Cast(b,B,"Orbs");p.Character:PivotTo(CFrame.new(245,3,0));task.wait(1)
assert(damage==0,"safe-zone retreat invalidates orb target")
for _,v in b.effects:GetChildren() do assert(v.Name~="HomingOrb","orbs with no valid target expire") end
healthConnection:Disconnect();root.Anchored=false;h.MaxHealth=100;h.Health=100
workspace:SetAttribute("OrbTest","PASS obstacle shatter, three hits and safe-zone retreat")
print("Glacius orb tests passed")
