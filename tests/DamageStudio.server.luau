-- Run as a temporary Studio server Script after startup, not included in the game.
local Players=game:GetService("Players")
local Boss=require(game.ServerScriptService.BossController)
local p=Players:GetPlayers()[1]
local b=Boss.Current
assert(b and b.hp==8000,"first boss full HP")
assert(Boss.Damage(p,b.model,10)==10,"valid damage")
assert(b.damage[p.UserId]==10 and b.bossDamage==10,"actual damage ledger")
b.shielded=true
assert(Boss.Damage(p,b.model,10)==0,"shield rejects damage")
b.shielded=false
assert(Boss.Damage(p,Instance.new("Model"),100)==0,"unknown target rejected")
local dealt=Boss.Damage(p,b.model,100000)
assert(dealt==7990 and b.bossDamage==8000,"overkill capped to remaining HP")
assert(not b.active,"death transitions to downtime")
assert(Boss.Damage(p,b.model,10)==0,"dead target rejected")
workspace:SetAttribute("DamageTest","PASS capped damage, shield, invalid target, contribution and death")
