local D=require(game.ServerScriptService.DataService)
local L=require(game.ServerScriptService.LootService)
local p=game.Players:GetPlayers()[1]
local deadline=os.clock()+5
repeat task.wait(.1) until D.Get(p) or os.clock()>deadline
local profile=D.Get(p);assert(profile and profile.owned.WoodenTrainer,"starter profile")
assert(p:GetAttribute("Persistence")=="Session only","unpublished safe fallback")
profile.coins=0
assert(D.Grant(p,"MoltenPlate")==false and profile.owned.MoltenPlate,"new armor reward")
assert(D.Grant(p,"MoltenPlate")==true and profile.coins==500,"duplicate converts500 coins")
profile.coins=0
local function fight()return {damage={[p.UserId]=4000},names={[p.UserId]=p.DisplayName},maxHP=8000,def={CoinPool=1000,Drops={}}}end
local killed=fight();L.Payout(killed,true)
assert(profile.coins==750,"1000*.5*1.5=750")
L.Payout(killed,true);assert(profile.coins==750,"payout idempotent")
L.Payout(fight(),false);assert(profile.coins==1125,"timeout adds375")
L.Payout({damage={},names={},maxHP=8000,def={CoinPool=1000,Drops={}}},false)
assert(profile.coins==1125,"zero contribution earns zero")
assert(D.AddCoins(p,-100)==false and profile.coins==1125,"invalid grant rejected")
D.Save(p);D.Send(p)
workspace:SetAttribute("EconomyTest","PASS starter, duplicate500, kill750, timeout375, no participation, idempotence")
print("Economy runtime tests passed")
