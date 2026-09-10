local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Modules.Config)
local Swords=require(RS.Modules.SwordDefs)
local Armor=require(RS.Modules.ArmorDefs)
local Ice=require(RS.Modules.GlaciusDefs)
local Data=require(script.Parent.DataService)
local Remotes=require(script.Parent.Remotes)
local Bases=require(script.Parent.BaseAssignment)
local Shop={}
local requests={}
local combat
local function allowed(player,key,interval)
 local now=workspace:GetServerTimeNow()
 local row=requests[player];if not row then row={};requests[player]=row end
 if now-(row[key] or -math.huge)<interval then return false end
 row[key]=now;return true
end
local function living(player)
 local c=player.Character;local root=c and c:FindFirstChild("HumanoidRootPart");local h=c and c:FindFirstChildOfClass("Humanoid")
 if root and h and h.Health>0 then return root,h end
end
local function itemId(id)return type(id)=="string" and #id<=Config.Shop.ItemIdLimit end
function Shop.NearKiosk(player)
 local root=living(player);if not root then return false end
 for _,base in workspace.ColossusMap.Bases:GetChildren() do
  if (root.Position-base.UpgradeKiosk.Position).Magnitude<=Config.Shop.Range then return true end
 end
 return false
end
function Shop.ApplyArmor(player,fill)
 local profile=Data.Get(player);local root,h=living(player)
 if not profile or not root then return end
 local maxHealth=Config.Player.MaxHealth;local speed=Config.Player.WalkSpeed;local bonus=0
 for id,enabled in profile.armor do
  local def=Armor[id]
  if enabled and profile.owned[id] and def then
   maxHealth+=def.MaxHealth or 0;speed*=def.SpeedMultiplier or 1
   bonus+=(def.MaxHealth or 0)+((def.SpeedMultiplier or 1)-1)*100
  end
 end
 local firstApply=not player.Character:GetAttribute("ArmorInitialized")
 h.MaxHealth=maxHealth;h.Health=(fill or firstApply) and maxHealth or math.min(h.Health,maxHealth)
 player.Character:SetAttribute("ArmorInitialized",true)
 player:SetAttribute("BaseWalkSpeed",speed)
 h.WalkSpeed=speed*((player:GetAttribute("GlaciusSlowUntil") or 0)>workspace:GetServerTimeNow() and Ice.Nova.SlowScale or 1)
 local sword=Swords[profile.equipped] or Swords.WoodenTrainer
 player:SetAttribute("Strength",sword.Damage/sword.Cooldown+bonus)
end
function Shop.Buy(player,id)
 if not itemId(id) or not allowed(player,"Buy",Config.Shop.RequestInterval) then return false end
 local profile=Data.Get(player);local def=Swords[id]
 if not profile or not def or def.Cost==nil or not Shop.NearKiosk(player) then return false end
 if profile.owned[id] then Remotes.Notice:FireClient(player,"You already own this sword.");return false end
 if profile.coins<def.Cost then Remotes.Notice:FireClient(player,"Earn more coins by damaging the boss.");return false end
 profile.coins-=def.Cost;profile.owned[id]=true;profile.equipped=id
 combat.Refresh(player);Shop.ApplyArmor(player,false);Data.Send(player)
 Remotes.Notice:FireClient(player,def.Name.." purchased and equipped!")
 return true
end
function Shop.Equip(player,id)
 if not itemId(id) or not allowed(player,"Equip",Config.Shop.RequestInterval) then return false end
 local profile=Data.Get(player)
 if not profile or not profile.owned[id] or not living(player) then return false end
 if Swords[id] then profile.equipped=id;combat.Refresh(player)
 elseif Armor[id] then profile.armor[id]=not profile.armor[id]
 else return false end
 Shop.ApplyArmor(player,false);Data.Send(player);return true
end
function Shop.Teleport(player)
 if not allowed(player,"Teleport",Config.Shop.TeleportInterval) then return false end
 local root=living(player);if not root then return false end
 local state=RS:FindFirstChild("BossState");if not state then return false end
 local remaining=(state:GetAttribute("Deadline") or 0)-workspace:GetServerTimeNow()
 if not state:GetAttribute("Active") and remaining<=Config.Cycle.TeleportLock then
  Remotes.Notice:FireClient(player,"Teleport locked: the next boss is arriving!");return false
 end
 if Vector3.new(root.Position.X,0,root.Position.Z).Magnitude<=Config.Map.ArenaRadius then Bases.ToBase(player)
 else
  local index=player:GetAttribute("BaseIndex") or 1
  local angle=(index-1)/Config.Map.BaseCount*math.pi*2
  local arrival=Vector3.new(math.cos(angle)*Config.Player.ArenaArrival.X,Config.Player.ArenaArrival.Y,math.sin(angle)*Config.Player.ArenaArrival.X)
  player.Character:PivotTo(CFrame.lookAt(arrival,Vector3.new(0,arrival.Y,0)));root.AssemblyLinearVelocity=Vector3.zero
 end
 return true
end
function Shop.Start(combatService)
 combat=combatService
 Remotes.Buy.OnServerEvent:Connect(Shop.Buy)
 Remotes.Equip.OnServerEvent:Connect(Shop.Equip)
 Remotes.Teleport.OnServerEvent:Connect(Shop.Teleport)
 for _,base in workspace.ColossusMap.Bases:GetChildren() do
  base.UpgradeKiosk.ShopPrompt.Triggered:Connect(function(player)
   if allowed(player,"OpenShop",Config.Shop.RequestInterval) and Shop.NearKiosk(player) then Remotes.OpenShop:FireClient(player) end
  end)
 end
 local function bind(player)
  local function ready(fill)
   if player:GetAttribute("DataReady") then combat.Refresh(player);Shop.ApplyArmor(player,fill);Data.Send(player) end
  end
  player:GetAttributeChangedSignal("DataReady"):Connect(function()ready(false)end)
  player.CharacterAdded:Connect(function(character)
   character:WaitForChild("Humanoid");character:WaitForChild("HumanoidRootPart")
   player:SetAttribute("GlaciusSlowUntil",0)
   task.defer(ready,true)
  end)
  if player.Character then task.defer(ready,true) end
 end
 Players.PlayerAdded:Connect(bind);Players.PlayerRemoving:Connect(function(p)requests[p]=nil end)
 for _,p in Players:GetPlayers() do bind(p) end
end
return Shop
