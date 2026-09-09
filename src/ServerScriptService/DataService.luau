local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local DSS = game:GetService("DataStoreService")
local Http = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local E = require(RS.Modules.EconomyDefs)
local Swords = require(RS.Modules.SwordDefs)
local Armor = require(RS.Modules.ArmorDefs)
local Remotes = require(script.Parent.Remotes)
local DataService = {}
local records = {}
local lastSync = {}
local started, closing = false, false
local closeDeadline
local store
local owner = game.JobId .. ":" .. Http:GenerateGUID(false)

local function copy(profile)
 return {coins=profile.coins, owned=table.clone(profile.owned), equipped=profile.equipped, armor=table.clone(profile.armor)}
end

local function decode(raw)
 local p = {coins=E.InitialCoins, owned={WoodenTrainer=true}, equipped="WoodenTrainer", armor={}}
 if type(raw) ~= "table" then return p end
 if type(raw.coins)=="number" and raw.coins==raw.coins and math.abs(raw.coins)<math.huge then p.coins=math.max(0,math.floor(raw.coins)) end
 if type(raw.owned)=="table" then
  for id, value in raw.owned do if type(id)=="string" and value==true and (Swords[id] or Armor[id]) then p.owned[id]=true end end
 end
 if type(raw.equipped)=="string" and p.owned[raw.equipped] and Swords[raw.equipped] then p.equipped=raw.equipped end
 if type(raw.armor)=="table" then
  for key, value in raw.armor do
   if type(key)=="string" and value==true and Armor[key] and p.owned[key] then p.armor[key]=true end
  end
 end
 return p
end

local function retry(callback, deadline)
 local lastError
 for attempt=1,E.RetryAttempts do
  if deadline and os.clock()>=deadline then break end
  local ok, result = pcall(callback)
  if ok then return true, result end
  lastError=result
  if attempt<E.RetryAttempts then task.wait(E.RetrySeconds * attempt) end
 end
 return false, lastError
end

function DataService.Get(player)
 local r=records[player]
 return r and not r.leaving and r.profile or nil
end
function DataService.Send(player)
 local p=DataService.Get(player)
 if p and player.Parent==Players then Remotes.Profile:FireClient(player,copy(p)) end
end
function DataService.AddCoins(player, amount)
 local p=DataService.Get(player)
 if not p or type(amount)~="number" or amount~=amount or math.abs(amount)==math.huge or amount<0 then return false end
 p.coins+=math.floor(amount)
 DataService.Send(player)
 return true
end
function DataService.Grant(player,itemId)
 local p=DataService.Get(player)
 if not p or type(itemId)~="string" or not (Swords[itemId] or Armor[itemId]) then return false end
 local duplicate=p.owned[itemId]==true
 if duplicate then p.coins+=E.DuplicateCoins else p.owned[itemId]=true end
 DataService.Send(player)
 return duplicate
end

local function save(player, release, deadline)
 local r=records[player]
 if not r then return end
 if release then
  r.leaving=true; r.release=true
  r.deadline=math.min(r.deadline or math.huge, deadline or os.clock()+E.CloseSeconds)
 end
 if r.busy then
  r.pending=true
  return
 end
 if r.release and r.deadline and r.deadline<=os.clock() then r.deadline=closeDeadline or os.clock()+E.CloseSeconds end
 if not r.persistent then if release then records[player]=nil end; return end
 r.busy=true
 repeat
  r.pending=false
  local releasing=r.release==true
  local snapshot=copy(r.profile)
  local lost=false
  local activeDeadline=math.min(r.deadline or math.huge,closeDeadline or math.huge)
  local ok=retry(function()
   return store:UpdateAsync(tostring(player.UserId),function(old)
    -- Never overwrite a record whose lock changed or expired.
    if type(old)~="table" or type(old.lock)~="table" or old.lock.owner~=r.owner or type(old.lock.expires)~="number" or old.lock.expires<=os.time() then
     lost=true; return nil
    end
    return {version=E.SchemaVersion, profile=snapshot,
     lock=not releasing and {owner=r.owner,expires=os.time()+E.LockSeconds} or nil}
   end)
  end,activeDeadline)
  if lost then
   r.persistent=false; r.leaving=true
   player:SetAttribute("DataReady",false)
   player:SetAttribute("Persistence","Lock lost")
   if player.Parent==Players and not RunService:IsStudio() then player:Kick("Your data session expired. Please rejoin to protect your progress.") end
   warn("Colossus profile could not save because session ownership was lost for user "..player.UserId)
   if r.leaving then records[player]=nil end
   break
  end
  if not ok then
   player:SetAttribute("Persistence","Save delayed")
   warn("Colossus profile save delayed for user "..player.UserId)
  elseif not releasing then player:SetAttribute("Persistence","Persistent") end
  if releasing then
   if ok then records[player]=nil; break end
   activeDeadline=math.min(r.deadline or math.huge,closeDeadline or math.huge)
   if os.clock()+E.FinalRetrySeconds>=activeDeadline then
    player:SetAttribute("Persistence","Final save failed")
    warn("Colossus final profile save failed; retained in server memory for user "..player.UserId)
    break
   end
   task.wait(E.FinalRetrySeconds)
   r.pending=true
  end
 until not r.pending
 r.busy=false
end

function DataService.Save(player) save(player,false) end

local function load(player)
 if records[player] or closing then return end
 -- Reserve the slot before the first yielding API call.
 local r={profile=nil,persistent=false,busy=false,owner=owner..":"..Http:GenerateGUID(false)}
 records[player]=r
 player:SetAttribute("DataReady",false)
 local profile
 if store then
  local blocked=false
  local ok, result=retry(function()
   return store:UpdateAsync(tostring(player.UserId),function(old)
    blocked=false
    if type(old)=="table" and type(old.lock)=="table" and old.lock.owner~=r.owner and type(old.lock.expires)=="number" and old.lock.expires>os.time() then
     blocked=true;return nil
    end
    return {version=E.SchemaVersion,profile=decode(type(old)=="table" and (old.profile or old) or nil),lock={owner=r.owner,expires=os.time()+E.LockSeconds}}
   end)
  end)
  if ok and blocked then
   records[player]=nil
   player:SetAttribute("Persistence","Session locked")
   if not RunService:IsStudio() then player:Kick("Your profile is active in another server. Please wait a moment and rejoin.") end
   return
  elseif ok and type(result)=="table" and result.lock and result.lock.owner==r.owner then
   profile=decode(result.profile);r.persistent=true
  end
 end
 -- API/load failures are session-only forever; this record may never save defaults.
 r.profile=profile or decode(nil)
 player:SetAttribute("Persistence",r.persistent and "Persistent" or "Session only")
 if player.Parent~=Players or closing or r.leaving then
  save(player,true,closeDeadline)
  return
 end
 player:SetAttribute("DataReady",true)
 DataService.Send(player)
end

function DataService.Start()
 if started then return end
 started=true
 -- An unpublished Studio place never touches DataStore APIs, including GetDataStore.
 if game.GameId~=0 then
  local ok,result=pcall(function() return DSS:GetDataStore(E.DataStoreName) end)
  if ok then store=result end
 end
 Players.PlayerAdded:Connect(function(player) task.spawn(load,player) end)
 Remotes.Sync.OnServerEvent:Connect(function(player)
  local now=os.clock()
  if lastSync[player] and now-lastSync[player]<E.SyncInterval then return end
  lastSync[player]=now
  DataService.Send(player)
 end)
 Players.PlayerRemoving:Connect(function(player)
  lastSync[player]=nil
  local r=records[player]
  if r and not r.profile then r.leaving=true;return end
  task.spawn(save,player,true)
 end)
 for _,player in Players:GetPlayers() do task.spawn(load,player) end
 task.spawn(function()
  while not closing do
   task.wait(E.AutosaveSeconds)
   if closing then break end
   for player,r in records do if r.profile then task.spawn(save,player,false) end end
  end
 end)
 game:BindToClose(function()
  closing=true
  local deadline=os.clock()+E.CloseSeconds
  closeDeadline=deadline
  for player,r in records do
   r.leaving=true
   if r.profile then task.spawn(save,player,true,deadline) end
  end
  repeat task.wait(E.ClosePollSeconds) until next(records)==nil or os.clock()>=deadline
  if next(records)~=nil then warn("Colossus shutdown deadline reached with unsaved or loading profiles; previous persisted data was preserved.") end
 end)
end
return DataService
