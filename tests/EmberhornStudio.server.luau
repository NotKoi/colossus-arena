-- Temporary Studio server Script; run with Workspace.ManualBossTests=true.
local Real=require(game.ServerScriptService.BossController)
local Ember=require(game.ServerScriptService.Emberhorn)
local b=Real.Current
local targets={};local events={};local hitTimes={};local rainTarget
local function target(id,pos)
 local t={player={UserId=id,GetAttribute=function()return nil end},root={Position=pos},humanoid={Health=1000},damage=0}
 t.humanoid.TakeDamage=function(_,amount) t.damage+=amount;table.insert(hitTimes,workspace:GetServerTimeNow()) end
 table.insert(targets,t);return t
end
local B={Active=Real.Active,Wait=Real.Wait,ArenaPlayers=function()return targets end,Hurt=Real.Hurt}
B.Telegraph=function(boss,kind,d)
 table.insert(events,{kind=kind,time=workspace:GetServerTimeNow(),data=d})
 if rainTarget and kind=="Circle" and d.radius==10 then rainTarget.root.Position=d.position+Vector3.new(0,3,0);rainTarget=nil end
 Real.Telegraph(boss,kind,d)
end
local function clear() table.clear(targets);table.clear(events);table.clear(hitTimes);b.model:PivotTo(CFrame.new(0,10,0)) end
clear()
local near=target(1,Vector3.new(20,3,0));local far=target(2,Vector3.new(60,3,0));local safe=target(3,Vector3.new(140,3,0))
Ember.Cast(b,B,"Slam")
assert(near.damage==40 and far.damage==0 and safe.damage==0,"slam geometry/safe zone")
assert(hitTimes[1]-events[1].time>=1.49,"slam telegraph before damage")
clear()
local grounded=target(1,Vector3.new(20,3,0));local jumping=target(2,Vector3.new(20,10,0));local base=target(3,Vector3.new(140,3,0))
Ember.Cast(b,B,"Ring");task.wait(4)
assert(grounded.damage==75 and jumping.damage==0 and base.damage==0,"three rings, jump and safe-zone counters")
clear()
local locked=target(1,Vector3.new(90,3,0));local inLine=target(2,Vector3.new(35,3,0));local side=target(3,Vector3.new(35,3,8))
Ember.Cast(b,B,"Charge")
assert(locked.damage==55 and inLine.damage==55 and side.damage==0,"charge line hit and sidestep")
assert(b.stunnedUntil>workspace:GetServerTimeNow()+2.5,"charge stun")
clear()
local meteor=target(1,Vector3.new(0,3,0));local remoteBase=target(2,Vector3.new(245,3,0));rainTarget=meteor
Ember.Cast(b,B,"Rain")
assert(meteor.damage>=30 and remoteBase.damage==0,"meteor areas and safe zone")
assert(hitTimes[1]-events[1].time>=1.19,"meteor preview timing")
workspace:SetAttribute("EmberhornTest","PASS slam, three rings/jump, charge/sidestep/stun, meteors and safe zones")
print("Emberhorn ability tests passed")
