local Config = {}

Config.Map = {
	ArenaRadius = 120,
	TopY = 0,
	FloorThickness = 7,
	BaseCount = 6,
	BaseRadius = 245,
	BasePlatformRadius = 34,
	BridgeWidth = 15,
	BridgeLength = 100,
	BridgeThickness = 4,
	RimHeight = 5,
	RimWidth = 4,
	RimSegments = 120,
	OpeningHalfAngle = 5,
	PatternRadius = 88,
	PatternWidth = 0.45,
	PatternSegments = 96,
	CenterRadius = 23,
	SpawnSize = Vector3.new(9, 1, 9),
	KioskOffset = Vector3.new(17, 0, 4),
	KioskSize = Vector3.new(8, 5, 5),
	BannerHeight = 20,
	TreeHeight = 14,
	TreeVisualHeightMultiplier = 1.4,
	FloorPatternRadiusFactors = {0.90, 0.81, 0.55},
	PatternLayerThickness = 0.05,
	PatternLayerStep = 0.04,
	DirectionalMedallionRadius = 6,
	DirectionalMedallionDistance = 80,
	SceneryRadius = 345,
	SceneryCount = 12,
	IslandRadius = 17,
}

Config.BaseColors = {
	Color3.fromRGB(255, 105, 110),
	Color3.fromRGB(255, 190, 63),
	Color3.fromRGB(115, 220, 122),
	Color3.fromRGB(67, 202, 247),
	Color3.fromRGB(163, 122, 248),
	Color3.fromRGB(246, 127, 213),
}

Config.Cycle = { Length = 120, HPPerPlayer = 0.6, CorpseLifetime = 4, TeleportLock = 5, Tick = 0.1 }
Config.Player = { MaxHealth = 100, WalkSpeed = 24, JumpPower = 50, ArenaArrival = Vector3.new(95, 4, 0) }
Config.Combat = { Range = 14, SwingWindow = 0.28, RemoteInterval = 0.08, ContactCooldown = 1 }
Config.Effects = { Lifetime = 3, GroundY = 0.35, RingSegments = 72 }
Config.Shop = { Range = 16, RequestInterval = .25, TeleportInterval = 1, SyncInterval = 1, ItemIdLimit = 64, StrengthTiers = {20,40,60,100,150,200} }
Config.Audio = { Swing="rbxassetid://12222216", Rare="rbxassetid://12222253", Impact="rbxasset://sounds/impact_explosion_03.mp3", Warning="rbxasset://sounds/volume_slider.ogg" }
Config.Polish = { ShakeDuration=.35, ShakeRadius=100, ShakeMagnitude=.35, ParticleCount=30, ParticleLifetime=1, WarningInterval=.5 }
return Config
