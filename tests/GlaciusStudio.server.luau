-- Run as a temporary Studio server Script with ManualBossTests=true.
local B=require(game.ServerScriptService.BossController)
local G=require(game.ServerScriptService.Glacius)
local p=game.Players:GetPlayers()[1]
B.Finish(B.Current,false)
local b=B.Spawn("Glacius")
assert(B.Damage(p,b.model,999999)==3250,"damage stops exactly at mandatory shield threshold")
assert(b.hp==3250 and b.shielded,"shield phase entered synchronously")
local crystals={};for c in b.crystals do table.insert(crystals,c) end
assert(#crystals==4,"four crystals")
assert(B.Damage(p,b.model,99999)==0,"shield immunity")
for _,c in crystals do assert(B.Damage(p,c,9999)==800,"crystal overkill cap") end
assert(not b.shielded and next(b.crystals)==nil,"all crystals break shield")
assert(b.damage[p.UserId]==6450 and b.bossDamage==3250,"crystal damage counts separately")
assert(b.stunnedUntil>workspace:GetServerTimeNow()+3.5,"four-second shield break stun")
b.stunnedUntil=0
workspace:SetAttribute("ShieldTest","PASS mandatory threshold, immunity, four crystals, contribution and stun")
local targets={};local previews={};local hitTimes={};local onPreview
local function target(id,pos)
 local fakePlayer={Parent=game.Players};local attrs={}
 function fakePlayer:GetAttribute(key)return attrs[key] end
 function fakePlayer:SetAttribute(key,value)attrs[key]=value end
 local t={player=fakePlayer,root={Position=pos},humanoid={Health=1000,WalkSpeed=24,Parent=workspace},damage=0}
 t.humanoid.TakeDamage=function(_,amount)t.damage+=amount;table.insert(hitTimes,workspace:GetServerTimeNow())end
 table.insert(targets,t);return t
end
local T={Active=B.Active,Wait=B.Wait,Hurt=B.Hurt,ArenaPlayers=function()return targets end}
T.Telegraph=function(boss,kind,d)
 table.insert(previews,{kind=kind,time=workspace:GetServerTimeNow(),data=d});if onPreview then onPreview(kind,d) end;B.Telegraph(boss,kind,d)
end
local safe=target(1,Vector3.zero);local unsafe=target(2,Vector3.zero);local base=target(3,Vector3.new(245,3,0))
onPreview=function(kind,d)
 if kind=="Nova" then
  safe.root.Position=d.positions[1]+Vector3.new(0,3,0)
  for i=0,359 do local v=Vector3.new(math.cos(math.rad(i))*110,3,math.sin(math.rad(i))*110);local valid=true;for _,circle in d.positions do if (Vector3.new(v.X,0,v.Z)-Vector3.new(circle.X,0,circle.Z)).Magnitude<=d.radius then valid=false end end;if valid then unsafe.root.Position=v;break end end
  assert(#d.positions==3,"three safe circles before enrage")
 end
end
G.Cast(b,T,"Nova")
assert(safe.damage==0 and unsafe.damage==45 and base.damage==0,"inverted nova safe zones")
assert(hitTimes[1]-previews[1].time>=1.79,"nova telegraph timing")
assert(unsafe.humanoid.WalkSpeed<24,"slow applied")
task.wait(2.1);assert(unsafe.humanoid.WalkSpeed==24,"slow expires")
b.hp=b.maxHP*.20;table.clear(previews)
onPreview=function(kind,d)if kind=="Nova" then assert(#d.positions==2,"two enraged safe circles") end end
G.Cast(b,T,"Nova")
workspace:SetAttribute("NovaTest","PASS inverted safe zones, warning timing, slow expiration and enrage")
table.clear(targets);onPreview=nil
local behind=target(1,Vector3.new(90,3,0));local exposed=target(2,Vector3.new(30,3,30))
G.Cast(b,T,"Sweep")
assert(behind.damage==0,"pillar shadow blocks beam")
assert(exposed.damage>=20,"exposed player hit by sweep")
assert(#game:GetService("CollectionService"):GetTagged("IcePillar")==4,"pillars persist after sweep")
workspace:SetAttribute("SweepTest","PASS rotating sweep damage and pillar cover")
print("Glacius shield, nova and sweep tests passed")
