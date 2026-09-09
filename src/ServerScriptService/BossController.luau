local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local Config = require(RS.Modules.Config)
local Defs = require(RS.Modules.BossDefs)
local Remotes = require(script.Parent.Remotes)
local Boss = { Current = nil, Cycle = 0 }
local state
function Boss.Active(b)
 return Boss.Current == b and b.active and workspace:GetServerTimeNow() < b.deadline
end
function Boss.Wait(b, seconds)
 local finish = math.min(workspace:GetServerTimeNow() + seconds, b.deadline)
 repeat task.wait(Config.Cycle.Tick) until not Boss.Active(b) or workspace:GetServerTimeNow() >= finish
 return Boss.Active(b)
end
function Boss.ArenaPlayers()
 local list = {}
 for _, p in Players:GetPlayers() do
  local c = p.Character; local root = c and c:FindFirstChild("HumanoidRootPart"); local h = c and c:FindFirstChildOfClass("Humanoid")
  if root and h and h.Health > 0 and Vector3.new(root.Position.X, 0, root.Position.Z).Magnitude <= Config.Map.ArenaRadius then table.insert(list, {player=p, root=root, humanoid=h}) end
 end
 return list
end
function Boss.Telegraph(b, kind, data)
 data.kind=kind; data.cycle=b.cycle; data.start=workspace:GetServerTimeNow(); Remotes.Telegraph:FireAllClients(data)
end
function Boss.Hurt(b, target, amount, knockback)
 if not Boss.Active(b) then return end
 local root=target.root
 if Vector3.new(root.Position.X,0,root.Position.Z).Magnitude > Config.Map.ArenaRadius then return end
 target.humanoid:TakeDamage(amount)
 if knockback then root.AssemblyLinearVelocity=knockback end
end
function Boss.Damage(player, model, amount)
 local b=Boss.Current
 if not b or not Boss.Active(b) or not model or model:GetAttribute("Cycle")~=b.cycle then return 0 end
 local crystal = model:GetAttribute("ShieldCrystal")
 if model~=b.model and not (crystal and b.crystals and b.crystals[model]) then return 0 end
 if model==b.model and b.shielded then return 0 end
 local hp=model:GetAttribute("HP") or 0
 local dealt=math.min(math.max(amount,0),hp)
 if dealt<=0 then return 0 end
 model:SetAttribute("HP",hp-dealt)
 b.damage[player.UserId]=(b.damage[player.UserId] or 0)+dealt
 b.names[player.UserId]=player.DisplayName
 if model==b.model then b.hp=hp-dealt; b.bossDamage+=dealt; state:SetAttribute("HP",b.hp)
 else
  if hp-dealt<=0 then
   b.crystals[model]=nil; model:Destroy()
   if next(b.crystals)==nil then b.shielded=false; b.stunnedUntil=workspace:GetServerTimeNow()+4; state:SetAttribute("Shielded",false) end
  end
 end
 Remotes.Damage:FireAllClients(model==b.model and b.root.Position or (model:GetAttribute("Position") or Vector3.zero),dealt,player.UserId)
 if b.hp<=0 then Boss.Finish(b,true) end
 return dealt
end
function Boss.Finish(b,killed)
 if not b.active then return end
 b.active=false; b.killed=killed; state:SetAttribute("Active",false); state:SetAttribute("HP",math.max(0,b.hp)); state:SetAttribute("Shielded",false)
 Boss.Telegraph(b,"Clear",{})
 if Boss.OnPayout then Boss.OnPayout(b,killed) end
 if b.effects then b.effects:Destroy() end
 if killed then Boss.Telegraph(b,"Burst",{position=b.root.Position,color=b.def.Color,radius=20,duration=1}) end
 if b.model then Debris:AddItem(b.model,killed and Config.Cycle.CorpseLifetime or 0) end
end
function Boss.Spawn(id)
 Boss.Cycle+=1
 local d=Defs[id]; local hp=d.BaseHP*(1+Config.Cycle.HPPerPlayer*(math.max(1,#Players:GetPlayers())-1))
 local model=Instance.new("Model"); model.Name=id
 local root=Instance.new("Part");root.Name="Core";root.Size=Vector3.new(14,20,14);root.Position=Vector3.new(0,10,0);root.Color=d.Color;root.Material=Enum.Material.Neon;root.Anchored=true;root.CanCollide=false;root.Parent=model
 model.PrimaryPart=root;model:SetAttribute("HP",hp);model:SetAttribute("MaxHP",hp);model:SetAttribute("Cycle",Boss.Cycle);model.Parent=workspace
 CollectionService:AddTag(model,"BossTarget")
 local effects=Instance.new("Folder");effects.Name="FightEffects";effects.Parent=workspace
 local b={id=id,def=d,model=model,root=root,hp=hp,maxHP=hp,damage={},names={},bossDamage=0,cycle=Boss.Cycle,active=true,deadline=workspace:GetServerTimeNow()+Config.Cycle.Length,effects=effects,crystals={},stunnedUntil=0}
 Boss.Current=b
 if Boss.BuildModel then Boss.BuildModel(b) end
 state:SetAttribute("Boss",id);state:SetAttribute("NextBoss",id=="Emberhorn" and "Glacius" or "Emberhorn");state:SetAttribute("HP",hp);state:SetAttribute("MaxHP",hp);state:SetAttribute("Active",true);state:SetAttribute("Deadline",b.deadline);state:SetAttribute("Cycle",b.cycle);state:SetAttribute("Shielded",false)
 Boss.Telegraph(b,"Burst",{position=root.Position,color=d.Color,radius=20,duration=1})
 if Boss.RunAbilities then task.spawn(Boss.RunAbilities,b) end
 return b
end
function Boss.Start()
 state=Instance.new("Folder");state.Name="BossState";state.Parent=RS
 RunService.Heartbeat:Connect(function()
  local b=Boss.Current
  if b and b.active then
   local p=b.root.Position;local flat=Vector3.new(p.X,0,p.Z)
   if flat.Magnitude>Config.Map.ArenaRadius-10 then b.model:PivotTo(CFrame.new(flat.Unit*(Config.Map.ArenaRadius-10)+Vector3.new(0,p.Y,0))*b.root.CFrame.Rotation) end
  end
 end)
 task.spawn(function()
  while true do
   local id=Boss.Cycle%2==0 and "Emberhorn" or "Glacius"
   local b=Boss.Spawn(id)
   repeat task.wait(Config.Cycle.Tick) until workspace:GetServerTimeNow()>=b.deadline
   if b.active then Boss.Finish(b,false) end
   if b.model then b.model:Destroy() end
  end
 end)
end
return Boss
