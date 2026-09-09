local fs=require("@lune/fs")
local luau=require("@lune/luau")
local roblox=require("@lune/roblox")
local defs=luau.load(fs.readFile("src/ReplicatedStorage/Modules/SwordDefs.luau"),{environment={Color3=roblox.Color3},injectGlobals=true})()
local cases={WoodenTrainer={10,.6,0},BronzeShortblade={18,.5,250},KnightLongsword={35,.8,1200},SunfangGreatsword={70,1.2,5000},EmberhornCleaver={95,1.1},GlacialEdge={60,.55}}
for id,c in cases do assert(defs[id].Damage==c[1] and defs[id].Cooldown==c[2] and defs[id].Cost==c[3],id) end
print("PASS all six sword stats match specification")
