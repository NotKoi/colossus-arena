-- Simulated services only: executes the actual DataService module; no live DataStore access.
local fs=require("@lune/fs")
local luau=require("@lune/luau")
local E=require("../src/ReplicatedStorage/Modules/EconomyDefs")
local Armor=require("../src/ReplicatedStorage/Modules/ArmorDefs")
local source=fs.readFile("src/ServerScriptService/DataService.luau")
local function clone(value)
 if type(value)~="table" then return value end
 local result={};for k,v in value do result[k]=clone(v) end;return result
end
local function event()
 local e={callbacks={}}
 function e:Connect(fn) table.insert(self.callbacks,fn);return {Disconnect=function() end} end
 function e:Fire(...) for _,fn in self.callbacks do fn(...) end end
 return e
end
local sequence=0
local function server(storage,options)
 options=options or {};sequence+=1
 local now=0
 local queue={}
 local calls=0
 local inFlight,maxInFlight=0,0
 local warnings={}
 local fail=options.fail or false
 local players={PlayerAdded=event(),PlayerRemoving=event(),list={}}
 function players:GetPlayers() return self.list end
 local function spawn(fn,...)
  local args=table.pack(...)
  local co=coroutine.create(function() fn(table.unpack(args,1,args.n)) end)
  table.insert(queue,{co=co,due=now})
  return co
 end
 local function runFor(seconds)
  local finish=now+seconds
  local count=0
  while true do
   table.sort(queue,function(a,b) return a.due<b.due end)
   local entry=queue[1]
   if not entry or entry.due>finish then break end
   table.remove(queue,1);now=entry.due
   local ok,delay=coroutine.resume(entry.co)
   assert(ok,delay)
   if coroutine.status(entry.co)~="dead" then table.insert(queue,{co=entry.co,due=now+(delay or 0)}) end
   count+=1;assert(count<10000,"scheduler runaway")
  end
  now=finish
 end
 local store={}
 function store:UpdateAsync(key,callback)
  calls+=1
  if fail then error("simulated DataStore failure") end
  inFlight+=1;maxInFlight=math.max(maxInFlight,inFlight)
  if options.delay then coroutine.yield(options.delay) end
  local result=callback(clone(storage[key]))
  if result~=nil then storage[key]=clone(result) end
  inFlight-=1
  return clone(result)
 end
 local snapshots={}
 local sends=0
 local remotes={Profile={FireClient=function(_,player,profile) snapshots[player]=profile;sends+=1 end},Sync={OnServerEvent=event()}}
 local modules={EconomyDefs=E,ArmorDefs=Armor,SwordDefs={WoodenTrainer={},BronzeShortblade={},EmberhornCleaver={}}}
 local guid=0
 local services={Players=players,ReplicatedStorage={Modules=modules},
  DataStoreService={GetDataStore=function() assert(not options.unpublished,"unpublished touched DataStore");return store end},
  HttpService={GenerateGUID=function() guid+=1;return tostring(sequence).."_"..guid end},
  RunService={IsStudio=function() return options.studio==true end}}
 local game={GameId=options.unpublished and 0 or 1,JobId="test"..sequence}
 function game:GetService(name) return assert(services[name],name) end
 function game:BindToClose(fn) self.close=fn end
 local env={game=game,script={Parent={Remotes=remotes}},
  require=function(module) return module end,
  task={spawn=spawn,wait=function(seconds) return coroutine.yield(seconds or .01) end},
  os={clock=function() return now end,time=function() return 100000+math.floor(now) end},
  warn=function(message) table.insert(warnings,message) end}
 local Data=luau.load(source,{environment=env,injectGlobals=true})()
 Data.Start()
 local function join(id)
  local p={UserId=id,Parent=players,attributes={}}
  function p:SetAttribute(key,value) self.attributes[key]=value end
  function p:Kick(message) self.kicked=message end
  table.insert(players.list,p);players.PlayerAdded:Fire(p);runFor(4)
  return p
 end
 local function leave(p)
  p.Parent=nil
  for i,v in players.list do if v==p then table.remove(players.list,i);break end end
  players.PlayerRemoving:Fire(p);runFor(0)
 end
 return {Data=Data,join=join,leave=leave,run=runFor,spawn=spawn,snapshots=snapshots,warnings=warnings,
  calls=function() return calls end,setFail=function(value) fail=value end,
  sync=function(player) remotes.Sync.OnServerEvent:Fire(player) end,sends=function() return sends end,
  maxInFlight=function() return maxInFlight end,
  close=function() spawn(game.close);runFor(E.CloseSeconds+.2) end}
end

local storage={}
local a=server(storage)
local p=a.join(1)
assert(p.attributes.DataReady and p.attributes.Persistence=="Persistent")
a.Data.AddCoins(p,1200)
assert(a.Data.Grant(p,"BronzeShortblade")==false)
a.Data.Get(p).owned.MoltenPlate=true
a.Data.Get(p).equipped="BronzeShortblade"
a.Data.Get(p).armor.MoltenPlate=true
a.Data.Send(p)
a.snapshots[p].owned.BronzeShortblade=false
assert(a.Data.Get(p).owned.BronzeShortblade,"snapshot aliased inventory")
a.spawn(a.Data.Save,p);a.run(0)
assert(storage["1"].profile.coins==1200)
a.leave(p)
assert(storage["1"].lock==nil,"leave did not release lock")
local b=server(storage)
local q=b.join(1)
local profile=b.Data.Get(q)
assert(profile.coins==1200 and profile.owned.BronzeShortblade and profile.equipped=="BronzeShortblade")
assert(profile.armor.MoltenPlate==true,"armor lost across rejoin")
assert(b.Data.Grant(q,"BronzeShortblade")==true)
assert(profile.coins==1700,"duplicate conversion incorrect")
local c=server(storage)
local blocked=c.join(1)
assert(c.Data.Get(blocked)==nil and blocked.kicked,"foreign lock allowed writable profile")

local saved=clone(storage["1"])
local failed=server(storage,{fail=true})
local fallback=failed.join(1)
assert(fallback.attributes.Persistence=="Session only")
failed.Data.AddCoins(fallback,900)
failed.setFail(false)
failed.spawn(failed.Data.Save,fallback);failed.run(0);failed.leave(fallback)
assert(storage["1"].profile.coins==saved.profile.coins and storage["1"].lock.owner==saved.lock.owner,"failed load overwrote data")

local before=b.calls()
b.setFail(true)
b.spawn(b.Data.Save,q);b.run(4)
assert(b.calls()-before==E.RetryAttempts,"save retry count wrong")
assert(storage["1"].profile.coins==1200,"failed save modified storage")
assert(b.Data.Get(q).coins==1700,"failed save lost in-memory changes")
b.setFail(false)
b.spawn(b.Data.Save,q);b.run(0)
assert(storage["1"].profile.coins==1700,"save did not recover")

-- Failed leave must retain the unsaved profile so shutdown can flush it later.
b.Data.AddCoins(q,50)
b.setFail(true);b.leave(q);b.run(E.CloseSeconds+1)
assert(q.attributes.Persistence=="Final save failed")
assert(storage["1"].profile.coins==1700)
b.setFail(false);b.close()
assert(storage["1"].profile.coins==1750 and storage["1"].lock==nil,"close failed to recover retained profile")

local dirty={ ["9"]={profile={coins=12,owned={WoodenTrainer=true,Unknown=true,MoltenPlate=true},equipped="Unknown",armor={MoltenPlate=true,FrostweaveCloak=true,Unknown=true}}}}
local d=server(dirty);local clean=d.Data.Get(d.join(9))
assert(clean.owned.Unknown==nil and clean.equipped=="WoodenTrainer")
assert(clean.armor.MoltenPlate==true and clean.armor.FrostweaveCloak==nil and clean.armor.Unknown==nil)
local unpublished=server({},{unpublished=true,studio=true})
local u=unpublished.join(2)
assert(u.attributes.Persistence=="Session only" and unpublished.calls()==0)
unpublished.leave(u);unpublished.close()
local dp=d.join(10)
local initial=d.sends();d.sync(dp);d.sync(dp)
assert(d.sends()==initial+1,"Sync was not rate limited")
d.run(E.SyncInterval);d.sync(dp)
assert(d.sends()==initial+2,"Sync did not reset after interval")
local slowStorage={}
local slow=server(slowStorage,{delay=2});local sp=slow.join(20)
slow.Data.AddCoins(sp,10);slow.spawn(slow.Data.Save,sp);slow.run(0)
slow.Data.AddCoins(sp,15);slow.spawn(slow.Data.Save,sp);slow.run(4)
assert(slow.maxInFlight()==1,"concurrent saves were not serialized")
assert(slowStorage["20"].profile.coins==25,"queued save lost latest mutation")
slow.Data.AddCoins(sp,5);slow.run(E.AutosaveSeconds)
assert(slowStorage["20"].profile.coins==30,"autosave did not persist")
local loadingStorage={};local loading=server(loadingStorage,{delay=10});loading.join(30)
loading.close()
assert(loadingStorage["30"].lock==nil,"load completing during close leaked its lock")
local lostStorage={};local lost=server(lostStorage);local lp=lost.join(40)
lost.Data.AddCoins(lp,80)
lostStorage["40"].lock.owner="replacement-session"
lost.spawn(lost.Data.Save,lp);lost.run(0)
assert(lostStorage["40"].profile.coins==0 and lostStorage["40"].lock.owner=="replacement-session","save overwrote foreign session")
assert(lost.Data.Get(lp)==nil and lp.attributes.Persistence=="Lock lost")
local outageStorage={};local outage=server(outageStorage);local op=outage.join(50)
outage.Data.AddCoins(op,90);outage.setFail(true);outage.close()
assert(outageStorage["50"].profile.coins==0 and #outage.warnings>0,"shutdown outage was not reported")
print("Persistence simulated-service tests passed: save/rejoin, snapshots, locks, load failure, retries, failed leave recovery, decode, unpublished fallback, Sync throttle, save serialization, autosave, close during load")
